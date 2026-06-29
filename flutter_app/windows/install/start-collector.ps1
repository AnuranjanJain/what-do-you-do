$ErrorActionPreference = "Stop"

$collectorDir = Join-Path $PSScriptRoot "collector"
$collectorScript = Join-Path $collectorDir "local-activity-collector.mjs"
$dataDir = Join-Path $env:LOCALAPPDATA "What Do You Do\data"
$logDir = Join-Path $env:LOCALAPPDATA "What Do You Do\logs"
$outLog = Join-Path $logDir "collector.out.log"
$errLog = Join-Path $logDir "collector.err.log"

if (-not (Test-Path -LiteralPath $collectorScript)) {
  throw "Collector script not found at $collectorScript"
}

try {
  $health = Invoke-WebRequest -Uri "http://127.0.0.1:17321/health" -UseBasicParsing -TimeoutSec 2
  if ($health.StatusCode -eq 200) {
    exit 0
  }
} catch {
  # Collector is not running yet.
}

New-Item -ItemType Directory -Force -Path $dataDir, $logDir | Out-Null
$env:WDYD_DATA_DIR = $dataDir

Start-Process -FilePath "node.exe" -WindowStyle Hidden -WorkingDirectory $collectorDir -ArgumentList "`"$collectorScript`"" -RedirectStandardOutput $outLog -RedirectStandardError $errLog
