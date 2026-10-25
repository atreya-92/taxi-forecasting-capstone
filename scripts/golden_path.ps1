param(
    [switch]$Verify,
    [switch]$Train,
    [switch]$SkipTests,
    [string]$ApiUrl = ""
)

$ErrorActionPreference = "Stop"
$Py = ".\.venv\Scripts\python.exe"
$results = @()

function Step {
    param([string]$Name, [scriptblock]$Cmd)
    Write-Host "==> $Name" -ForegroundColor Cyan
    $sw = [Diagnostics.Stopwatch]::StartNew()
    & $Cmd
    if ($LASTEXITCODE -ne 0) { throw "$Name failed" }
    $script:results += [pscustomobject]@{ Stage = $Name; Seconds = [int]$sw.Elapsed.TotalSeconds; Status = "PASS" }
}

if (-not $Verify) {
    Step "Lint (ruff)" { & $Py -m ruff check . }
    if (-not $SkipTests) {
        Step "Tests (pytest)" { & $Py -m pytest -q }
    }
    Step "Phase 1 data pipeline" { & $Py -m scripts.run_pipeline --year 2024 --month 1 --skip-download }
    if ($Train) {
        Step "Phase 2 training" { & $Py -m scripts.train_models --n-trials 25 }
    }
    Step "Phase 3 batch forecast" { & $Py -m scripts.batch_forecast --horizon 3 }
    Step "Phase 6 responsible AI analysis" { & $Py -m scripts.responsible.run_analysis }
    Step "Phase 5 drift report" { & $Py -m scripts.monitoring.demo_drift_report --problem all --mode drift }
    Write-Host ""
    Write-Host "Stage summary" -ForegroundColor Green
    $results | Format-Table -AutoSize
}

Write-Host ""
Write-Host "Evidence check" -ForegroundColor Green

$evidence = @(
    "data\processed\pipeline_summary.json",
    "data\features\demand_train.parquet",
    "data\features\fare_train.parquet",
    "mlflow.db",
    "predictions.db",
    "artifacts\responsible",
    "artifacts\drift",
    "docs\model_cards"
)

$missing = 0
foreach ($p in $evidence) {
    if (Test-Path $p) {
        Write-Host "  OK       $p"
    }
    else {
        Write-Host "  MISSING  $p" -ForegroundColor Red
        $missing++
    }
}

if ($ApiUrl) {
    $h = Invoke-RestMethod "$ApiUrl/health" -TimeoutSec 60
    Write-Host "  API health: $($h.status) | demand loaded: $($h.demand_model_loaded) | fare loaded: $($h.fare_model_loaded) | zones: $($h.zones)"
    if ($h.status -ne "ok") { $missing++ }
}

Write-Host ""
if ($missing -eq 0) {
    Write-Host "GOLDEN PATH: ALL REQUIRED STAGES VERIFIED" -ForegroundColor Green
}
else {
    Write-Host "GOLDEN PATH: $missing item(s) missing" -ForegroundColor Red
    exit 1
}