#!/usr/bin/env pwsh
# ablation-study.ps1 — Windows version of ablation-study.sh
#
# Five configurations (see thesis Chapter 4):
#   A  (full)       : divergence-weighted coverage UCB + structural mutations  [--coverage-ucb-alpha 0.7]
#   B0 (baseline)   : reproduce original paper code with default alpha          [--coverage-ucb-alpha 0.0]
#   B  (no-coverage): UCB without coverage signal                              [--coverage-ucb-alpha 0.0 --argmax-ucb ... same as B0 but UCB1 pure]
#   C  (argmax-ucb) : greedy UCB, no exploration                               [--argmax-ucb]
#   D  (byte-only)  : byte-level mutations only                                [--byte-mutation-only]
#
# Usage:
#   .\tools\ablation-study.ps1                         # full ablation, 5 rounds x 24h each config
#   .\tools\ablation-study.ps1 -Times 1 -Hours 0.1    # smoke test: 1 round, ~6 minutes each config
#   .\tools\ablation-study.ps1 -Configs A,D            # run only specific configs
#   .\tools\ablation-study.ps1 -Times 1 -Hours 24 -Configs A,B0  # single round, two configs

param(
    [int]    $Times            = 5,
    [double] $Hours            = 24,
    [int]    $BatchSize        = 500,
    [int]    $BatchTimeoutSecs = 600,
    [string] $ConfigsStr       = 'A,B0,B,C,D'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Support both -Configs A,B0,C and -ConfigsStr A,B0,C
[string[]]$Configs = @($ConfigsStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

# ── Paths ──────────────────────────────────────────────────────────────────────
$Base        = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Base        = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FuzzExe     = Join-Path $Base "zip-diff\target\release\fuzz.exe"
$ParsersDir  = Join-Path $Base "parsers"
$EvalDir     = Join-Path $Base "evaluation"
$InputDir    = Join-Path $EvalDir "input"
$OutputDir   = Join-Path $EvalDir "output"
$SessionsDir = Join-Path $EvalDir "sessions"
$StatsDir    = Join-Path $EvalDir "stats"

# ── Preflight ──────────────────────────────────────────────────────────────────
if (-not (Test-Path $FuzzExe)) {
    Write-Error "fuzz.exe not found at $FuzzExe`nRun: cd zip-diff; cargo build --release"
}
if (-not (Test-Path (Join-Path $ParsersDir "docker-compose.yml"))) {
    Write-Error "docker-compose.yml not found in $ParsersDir`nRun: tools\prepare.sh"
}
foreach ($dir in @($InputDir, $OutputDir, $SessionsDir, $StatsDir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# ── Config definitions ─────────────────────────────────────────────────────────
$ConfigArgs = @{
    'A'  = @('--coverage-ucb-alpha', '0.7')                       # full: divergence-weighted coverage
    'B0' = @('--coverage-ucb-alpha', '0.0')                       # baseline: no coverage signal (closest to original paper)
    'B'  = @('--coverage-ucb-alpha', '0.0')                       # no-coverage UCB (same args as B0; distinguished by label)
    'C'  = @('--argmax-ucb')                                       # argmax UCB, no exploration
    'D'  = @('--byte-mutation-only')                               # byte-level only
}

$StopSeconds = [int]($Hours * 3600)

Write-Host "============================================================"
Write-Host " ZipDiff Ablation Study (Windows)"
Write-Host "============================================================"
Write-Host " Rounds   : $Times"
Write-Host " Duration : $Hours h ($StopSeconds s) per run"
Write-Host " Batch    : size=$BatchSize  timeout=$BatchTimeoutSecs s"
Write-Host " Configs  : $($Configs -join ', ')"
Write-Host " Fuzz bin : $FuzzExe"
Write-Host " Parsers  : $ParsersDir"
Write-Host "============================================================"
Write-Host ""

$TotalRuns = $Times * $Configs.Count
$RunIndex  = 0

for ($Round = 1; $Round -le $Times; $Round++) {
    foreach ($Cfg in $Configs) {
        if (-not $ConfigArgs.ContainsKey($Cfg)) {
            Write-Warning "Unknown config '$Cfg' — skipping (valid: A, B0, B, C, D)"
            continue
        }

        $RunIndex++
        $Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
        $Key        = "$Timestamp-$Cfg"
        $SessionDir = Join-Path $SessionsDir $Key
        $StatsFile  = Join-Path $StatsDir "$Key.json"

        New-Item -ItemType Directory -Force -Path (Join-Path $SessionDir "samples") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $SessionDir "results") | Out-Null

        Write-Host "------------------------------------------------------------"
        Write-Host " Run $RunIndex / $TotalRuns  |  Round $Round / $Times  |  Config $Cfg"
        Write-Host " Session : $Key"
        Write-Host " Started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "------------------------------------------------------------"

        $ExtraArgs = $ConfigArgs[$Cfg]

        $FuzzArgs = @(
            '--batch-size',          $BatchSize,
            '--batch-timeout-secs',  $BatchTimeoutSecs,
            '--stop-after-seconds',  $StopSeconds,
            '--parsers-dir',         $ParsersDir,
            '--input-dir',           $InputDir,
            '--output-dir',          $OutputDir,
            '--samples-dir',         (Join-Path $SessionDir "samples"),
            '--results-dir',         (Join-Path $SessionDir "results"),
            '--stats-file',          $StatsFile
        ) + $ExtraArgs

        Write-Host " Args: $($FuzzArgs -join ' ')"
        Write-Host ""

        try {
            & $FuzzExe @FuzzArgs
            $ExitCode = $LASTEXITCODE
        } catch {
            Write-Warning "fuzz.exe threw an exception: $_"
            $ExitCode = 1
        }

        Write-Host ""
        if ($ExitCode -eq 0) {
            Write-Host " [OK] Config $Cfg round $Round completed — stats: $StatsFile"
        } else {
            Write-Warning " [FAIL] Config $Cfg round $Round exited with code $ExitCode"
        }

        # Bring containers down between runs to free resources
        Push-Location $ParsersDir
        try {
            docker compose down --timeout 30 2>&1 | Out-Null
        } catch {
            Write-Warning "docker compose down failed (non-fatal): $_"
        }
        Pop-Location

        Write-Host " Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host ""
    }
}

Write-Host "============================================================"
Write-Host " All runs complete."
Write-Host " Sessions : $SessionsDir"
Write-Host " Stats    : $StatsDir"
Write-Host "============================================================"
