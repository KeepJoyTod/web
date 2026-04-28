param(
  [string]$BaseUrl = "http://127.0.0.1:8080/api",
  [string]$K6Script = "k6/api-load.js",
  [string]$RunId = "",
  [string]$Title = "K6 API 鍘嬫祴",
  [string]$Environment = "local-windows",
  [string]$ResultsDir = "k6/results",
  [string]$ReportDir = "docs/performance-test-records",
  [string]$SkillRecorder = "",
  [string]$PythonCmd = "python",
  [string]$K6Cmd = "k6",
  [string]$Notes = "",
  [string[]]$ExtraK6Args = @(),
  [switch]$FailOnThreshold,
  [switch]$ContinueIfK6Failed
)

if (-not $PSBoundParameters.ContainsKey("Title")) {
  $Title = "K6 API Load"
}

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-ProjectRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Resolve-UnderRoot([string]$Root, [string]$PathValue) {
  if ([System.IO.Path]::IsPathRooted($PathValue)) {
    return [System.IO.Path]::GetFullPath($PathValue)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $Root $PathValue))
}

function Command-Exists([string]$Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Quote-Arg([string]$Value) {
  if ($Value -match "\s") {
    return ('"' + ($Value -replace '"', '\"') + '"')
  }
  return $Value
}

$Root = Get-ProjectRoot
if (-not $RunId) {
  $RunId = "PERF-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

if (-not $SkillRecorder) {
  $SkillRecorder = Join-Path $env:USERPROFILE ".codex\skills\k6-pressure-record\scripts\record_k6_run.py"
}

$ResultsDirAbs = Resolve-UnderRoot $Root $ResultsDir
$ReportDirAbs = Resolve-UnderRoot $Root $ReportDir
$K6ScriptAbs = Resolve-UnderRoot $Root $K6Script

if (-not (Test-Path $K6ScriptAbs)) {
  throw "K6 script not found: $K6ScriptAbs"
}

if (-not (Test-Path $SkillRecorder)) {
  throw "Skill recorder script not found: $SkillRecorder"
}

if (-not (Command-Exists $K6Cmd)) {
  throw "k6 command not found: $K6Cmd"
}

if (-not (Command-Exists $PythonCmd)) {
  throw "python command not found: $PythonCmd"
}

New-Item -ItemType Directory -Force -Path $ResultsDirAbs | Out-Null
New-Item -ItemType Directory -Force -Path $ReportDirAbs | Out-Null

$SummaryPath = Join-Path $ResultsDirAbs "$RunId-summary.json"
$LogPath = Join-Path $ResultsDirAbs "$RunId.log"
$ReportPath = Join-Path $ReportDirAbs "$RunId.md"

$k6Args = @("run", "-e", "BASE_URL=$BaseUrl", "--summary-export", $SummaryPath)
if ($ExtraK6Args.Count -gt 0) {
  $k6Args += $ExtraK6Args
}
$k6Args += $K6ScriptAbs

$k6CommandText = ($K6Cmd + " " + (($k6Args | ForEach-Object { Quote-Arg $_ }) -join " "))

Write-Host ""
Write-Host "Project root: $Root"
Write-Host "Run ID: $RunId"
Write-Host "K6 script: $K6ScriptAbs"
Write-Host "Summary: $SummaryPath"
Write-Host "Log: $LogPath"
Write-Host "Report: $ReportPath"
Write-Host ""
Write-Host "Running K6 ..."

Push-Location $Root
try {
  & $K6Cmd @k6Args 2>&1 | Tee-Object -FilePath $LogPath
  $k6Exit = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($k6Exit -ne 0) {
  $msg = "K6 run failed with exit code $k6Exit"
  if (-not $ContinueIfK6Failed) {
    throw $msg
  }
  Write-Warning "$msg; continue to report generation."
}

if (-not (Test-Path $SummaryPath)) {
  throw "Summary JSON not generated: $SummaryPath"
}

Write-Host ""
Write-Host "Generating markdown report ..."

$recordArgs = @(
  $SkillRecorder,
  "--summary", $SummaryPath,
  "--report-dir", $ReportDirAbs,
  "--run-id", $RunId,
  "--title", $Title,
  "--target", $BaseUrl,
  "--script", $K6ScriptAbs,
  "--command", $k6CommandText,
  "--environment", $Environment,
  "--log", $LogPath
)

if ($Notes) {
  $recordArgs += @("--notes", $Notes)
}
if ($FailOnThreshold) {
  $recordArgs += "--fail-on-threshold"
}

& $PythonCmd @recordArgs
$recordExit = $LASTEXITCODE
if ($recordExit -ne 0) {
  throw "Record generation failed with exit code $recordExit"
}

Write-Host ""
Write-Host "Done."
Write-Host "Summary JSON: $SummaryPath"
Write-Host "Raw log:      $LogPath"
Write-Host "Report:       $ReportPath"
