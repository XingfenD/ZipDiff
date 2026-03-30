Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Set-UnixTextContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $normalized = $Content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText(
        $Path,
        $normalized,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Convert-ShebangFileToUnix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $raw = Get-Content -LiteralPath $Path -Raw
    if ($raw.StartsWith("#!")) {
        Set-UnixTextContent -Path $Path -Content $raw
    }
}

function Convert-ToComposePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    return $resolved -replace "\\", "/"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path -Parent $scriptDir
$scriptsBase = Join-Path $base "tools/scripts_for_parsers"

$inputDir = if ($env:INPUT_DIR) { $env:INPUT_DIR } else { Join-Path $base "evaluation/input" }
$outputDir = if ($env:OUTPUT_DIR) { $env:OUTPUT_DIR } else { Join-Path $base "evaluation/output" }

$parsersDir = Join-Path $base "parsers"
$composeFile = Join-Path $parsersDir "docker-compose.yml"
$scriptsEnvFile = Join-Path $scriptsBase "app.env"

$null = New-Item -ItemType Directory -Path $inputDir -Force
$null = New-Item -ItemType Directory -Path $outputDir -Force

$composeInputDir = Convert-ToComposePath -Path $inputDir
$composeOutputDir = Convert-ToComposePath -Path $outputDir

Set-Location -LiteralPath $parsersDir

"services:" | Set-Content -LiteralPath $composeFile -Encoding ascii
"ROOT_DIR=$base" | Set-Content -LiteralPath $scriptsEnvFile -Encoding ascii

$scriptSources = @(
    Join-Path $scriptsBase "unzip-all.sh"
    Join-Path $scriptsBase "parallel-unzip-all.sh"
    Join-Path $scriptsBase "testcase.sh"
    $scriptsEnvFile
)

$parserDirs = Get-ChildItem -Directory | Sort-Object Name
foreach ($parserDir in $parserDirs) {
    foreach ($src in $scriptSources) {
        Copy-Item -LiteralPath $src -Destination $parserDir.FullName -Force
    }

    # Keep shell/env files in LF format for Linux containers.
    foreach ($name in @("unzip-all.sh", "parallel-unzip-all.sh", "testcase.sh", "app.env")) {
        $dst = Join-Path $parserDir.FullName $name
        $content = Get-Content -LiteralPath $dst -Raw
        Set-UnixTextContent -Path $dst -Content $content
    }

    # Normalize parser-provided executable scripts (e.g. unzip, unzip-wrapper, coverage.sh).
    foreach ($file in Get-ChildItem -LiteralPath $parserDir.FullName -File) {
        if ($file.Name -eq "src.tar.gz") {
            continue
        }
        Convert-ShebangFileToUnix -Path $file.FullName
    }

    $srcTarGz = Join-Path $parserDir.FullName "src.tar.gz"
    if (Test-Path -LiteralPath $srcTarGz) {
        $srcDir = Join-Path $parserDir.FullName "src"
        if (-not (Test-Path -LiteralPath $srcDir)) {
            tar -zxf $srcTarGz -C $parserDir.FullName
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to extract $srcTarGz"
            }
        }
    }

    $parserEnv = Join-Path $parserDir.FullName "app.env"
    "PARSER_RELATIVE_PATH=$($parserDir.Name)" | Add-Content -LiteralPath $parserEnv -Encoding ascii

    @(
        "  $($parserDir.Name):"
        "    build: $($parserDir.Name)"
        "    volumes:"
        "      - ${composeInputDir}:/input:ro"
        "      - ${composeOutputDir}/$($parserDir.Name):/output"
    ) | Add-Content -LiteralPath $composeFile -Encoding ascii
}
