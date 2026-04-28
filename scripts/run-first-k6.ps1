param(
  [string]$BaseUrl = "http://127.0.0.1:8080/api",
  [int]$Vus = 20,
  [string]$Duration = "3m",
  [string]$Account = "user@example.com",
  [string]$Password = "123456",
  [string]$Environment = "local-windows",
  [switch]$FailOnThreshold
)

$runner = Join-Path $PSScriptRoot "run-k6-and-record.ps1"
$extraArgs = @("--vus", $Vus.ToString(), "--duration", $Duration)

$params = @{
  BaseUrl = $BaseUrl
  K6Script = "k6/api-load.js"
  Title = "K6 API mixed browse load"
  Environment = $Environment
  Notes = "Baseline mixed browse load for categories, product list, detail, and authenticated reads."
  ExtraK6Args = $extraArgs
}

if ($FailOnThreshold) {
  $params.FailOnThreshold = $true
}

$env:ACCOUNT = $Account
$env:PASSWORD = $Password

& $runner @params
