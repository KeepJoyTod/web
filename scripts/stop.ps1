[CmdletBinding()]
param(
  [switch]$StopInfrastructure,
  [switch]$WithMonitoring
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$PidsDir = Join-Path $Root ".pids"

foreach ($name in @("backend", "frontend", "admin")) {
  $metadataFile = Join-Path $PidsDir "$name.pid.json"
  $legacyPidFile = Join-Path $PidsDir "$name.pid"
  if (-not (Test-Path -LiteralPath $metadataFile)) {
    if (Test-Path -LiteralPath $legacyPidFile) {
      Write-Warning "${name}: legacy PID file has no process identity metadata; refusing to stop it automatically."
    } else {
      Write-Host "${name}: no managed process metadata"
    }
    continue
  }

  try {
    $metadata = Get-Content -LiteralPath $metadataFile -Raw | ConvertFrom-Json
  } catch {
    Write-Warning "${name}: invalid metadata file; refusing to stop any process."
    continue
  }

  if ($metadata.schema -ne 2 -or $metadata.name -ne $name -or $metadata.projectRoot -ne $Root -or "$($metadata.pid)" -notmatch '^\d+$') {
    Write-Warning "${name}: metadata identity mismatch; refusing to stop any process."
    continue
  }

  $processId = [int]$metadata.pid
  $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
  if (-not $process) {
    Write-Host "${name}: PID $processId is no longer running"
    Remove-Item -LiteralPath $metadataFile -Force
    continue
  }

  try {
    $expectedStart = [DateTimeOffset]::Parse($metadata.startedUtc).UtcDateTime
    $actualStart = $process.StartTime.ToUniversalTime()
    $startDeltaSeconds = [Math]::Abs(($actualStart - $expectedStart).TotalSeconds)
  } catch {
    Write-Warning "${name}: unable to verify process start time; refusing to stop PID $processId."
    continue
  }

  if ($startDeltaSeconds -gt 2) {
    Write-Warning "${name}: PID $processId was reused by another process; refusing to stop it."
    continue
  }

  $nativeProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $processId"
  if (-not $nativeProcess -or $nativeProcess.ExecutablePath -ne $metadata.executable -or $nativeProcess.CommandLine -ne $metadata.commandLine) {
    Write-Warning "${name}: executable or command line identity changed; refusing to stop PID $processId."
    continue
  }

  $taskkill = Get-Command taskkill.exe -ErrorAction SilentlyContinue
  if ($taskkill) {
    & $taskkill.Source /PID $processId /T /F | Out-Host
  } else {
    Stop-Process -Id $processId -Force
  }
  Start-Sleep -Milliseconds 500
  if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
    throw "${name}: failed to stop verified PID $processId."
  }

  Remove-Item -LiteralPath $metadataFile -Force
  Write-Host "${name}: stopped verified PID $processId"
}

if ($StopInfrastructure) {
  $docker = Get-Command docker -ErrorAction SilentlyContinue
  if (-not $docker) { throw "Docker was not found in PATH." }
  Push-Location $Root
  try {
    if ($WithMonitoring) {
      & $docker.Source compose --profile monitoring stop | Out-Host
    } else {
      & $docker.Source compose stop mysql redis | Out-Host
    }
    if ($LASTEXITCODE -ne 0) { throw "docker compose stop failed" }
  } finally {
    Pop-Location
  }
}
