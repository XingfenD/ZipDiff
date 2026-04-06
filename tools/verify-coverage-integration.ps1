param(
    [string]$ProjectRoot = "E:\Project\ZipDiff"
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [string]$Title,
        [string]$Command
    )
    Write-Host $Title
    Invoke-Expression $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $Command"
    }
}

$zipDiffDir = Join-Path $ProjectRoot "zip-diff"
if (!(Test-Path $zipDiffDir)) {
    throw "zip-diff directory not found: $zipDiffDir"
}

Write-Host "[1/3] Running hash ignore tests..."
Push-Location $zipDiffDir
Invoke-Step "[1/3] cargo test hash::tests::" "cargo test hash::tests:: -- --nocapture"

Write-Host "[2/3] Running coverage parser tests..."
Invoke-Step "[2/3] cargo test --bin fuzz execute::tests::" "cargo test --bin fuzz execute::tests:: -- --nocapture"

Write-Host "[3/3] Running compile check..."
Invoke-Step "[3/3] cargo check --bin fuzz" "cargo check --bin fuzz"
Pop-Location

Write-Host "Verification finished."
Write-Host "- Hash ignore for coverage files: validated"
Write-Host "- Coverage format parse (with/without %): validated"
Write-Host "- Fuzz binary compile: validated"
