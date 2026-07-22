[CmdletBinding()]
param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SqlPath = Join-Path $Root "back/sql/init_db.sql"

function Import-DotEnv([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { continue }
    $name = $Matches[1]
    $value = $Matches[2].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    if (-not (Test-Path "env:$name")) { Set-Item -Path "env:$name" -Value $value }
  }
}

function Get-EnvironmentSetting([string]$Name, [string]$DefaultValue) {
  $value = [Environment]::GetEnvironmentVariable($Name, "Process")
  if ([string]::IsNullOrWhiteSpace($value)) { return $DefaultValue }
  return $value
}

function Resolve-MySqlCommand {
  $command = Get-Command mysql.exe -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  return $null
}

function ConvertTo-NativeArgument([AllowEmptyString()][string]$Argument) {
  if ($Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') { return $Argument }

  $builder = [System.Text.StringBuilder]::new()
  [void]$builder.Append('"')
  $backslashes = 0
  foreach ($character in $Argument.ToCharArray()) {
    if ($character -eq '\') {
      $backslashes++
      continue
    }
    if ($character -eq '"') {
      [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
      [void]$builder.Append('"')
      $backslashes = 0
      continue
    }
    if ($backslashes -gt 0) {
      [void]$builder.Append(('\' * $backslashes))
      $backslashes = 0
    }
    [void]$builder.Append([string]$character)
  }
  if ($backslashes -gt 0) { [void]$builder.Append(('\' * ($backslashes * 2))) }
  [void]$builder.Append('"')
  return $builder.ToString()
}

function Set-NativeProcessArguments([System.Diagnostics.ProcessStartInfo]$ProcessInfo, [string[]]$Arguments) {
  if ($null -ne $ProcessInfo.PSObject.Properties["ArgumentList"]) {
    foreach ($argument in $Arguments) { $ProcessInfo.ArgumentList.Add($argument) }
  } else {
    $ProcessInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join " ")
  }
}

function New-MySqlProcessInfo([string[]]$Arguments, [bool]$RedirectInput) {
  $processInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $processInfo.FileName = $script:MySql
  $processInfo.WorkingDirectory = $Root
  $processInfo.UseShellExecute = $false
  $processInfo.CreateNoWindow = $true
  $processInfo.RedirectStandardInput = $RedirectInput
  $processInfo.RedirectStandardOutput = $true
  $processInfo.RedirectStandardError = $true
  $processInfo.EnvironmentVariables["MYSQL_PWD"] = $script:DbPassword
  Set-NativeProcessArguments $processInfo $Arguments
  return $processInfo
}

function Invoke-MySqlCapture([string[]]$Arguments, [string]$FailureMessage) {
  $process = [System.Diagnostics.Process]::Start((New-MySqlProcessInfo $Arguments $false))
  $outputTask = $process.StandardOutput.ReadToEndAsync()
  $errorTask = $process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  $output = $outputTask.Result
  $errorOutput = $errorTask.Result
  if ($process.ExitCode -ne 0) {
    throw "$FailureMessage MySQL error: $errorOutput"
  }
  return $output.Trim()
}

Import-DotEnv (Join-Path $Root ".env")
$DbHost = Get-EnvironmentSetting "DB_HOST" "127.0.0.1"
$DbPortText = Get-EnvironmentSetting "DB_PORT" "3306"
$DbName = Get-EnvironmentSetting "DB_NAME" "web"
$DbUser = Get-EnvironmentSetting "DB_USER" "root"
$script:DbPassword = Get-EnvironmentSetting "DB_PASSWORD" "123456"

$DbPort = 0
if (-not [int]::TryParse($DbPortText, [ref]$DbPort) -or $DbPort -lt 1 -or $DbPort -gt 65535) {
  throw "DB_PORT must be an integer between 1 and 65535."
}
if ([string]::IsNullOrWhiteSpace($DbHost)) { throw "DB_HOST must not be empty." }
if ($DbName -notmatch '^[A-Za-z0-9_]+$') { throw "DB_NAME may contain only letters, numbers, and underscores." }
if ($DbUser -notmatch '^[A-Za-z0-9_]+$') { throw "DB_USER may contain only letters, numbers, and underscores." }
if (-not (Test-Path -LiteralPath $SqlPath)) { throw "SQL file not found: $SqlPath" }

$script:MySql = Resolve-MySqlCommand
if (-not $script:MySql -and -not $DryRun) {
  throw "mysql.exe was not found in PATH. Install or expose a compatible MySQL client, then retry."
}

$BaseArguments = @(
  "--protocol=TCP",
  "--host=$DbHost",
  "--port=$DbPort",
  "--user=$DbUser",
  "--default-character-set=utf8mb4"
)

if ($DryRun) {
  if ($script:MySql) {
    Write-Host "[dry-run] mysql.exe: $script:MySql"
  } else {
    Write-Warning "[dry-run] mysql.exe is not currently available in PATH; a real run would stop before connecting."
  }
  Write-Host "[dry-run] target: ${DbHost}:$DbPort database=$DbName user=$DbUser"
  Write-Host "[dry-run] create the database if missing, require zero existing tables, then stream back/sql/init_db.sql as raw bytes"
  Write-Host "[dry-run] no database connection or write was attempted; the password was not printed"
  return
}

$createSql = "CREATE DATABASE IF NOT EXISTS $DbName DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
Invoke-MySqlCapture ($BaseArguments + @("--execute=$createSql")) "Unable to create or inspect database '$DbName'." | Out-Null

$dbNameHex = [BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes($DbName)).Replace("-", "")
$countSql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=CONVERT(0x$dbNameHex USING utf8mb4);"
$tableCount = Invoke-MySqlCapture ($BaseArguments + @("--batch", "--skip-column-names", "--execute=$countSql")) "Unable to count tables in database '$DbName'."
if ($tableCount -notmatch '^\d+$') { throw "Unable to parse table count for database '$DbName'." }
if ([int]$tableCount -gt 0) {
  throw "Database '$DbName' is not empty. Initialization was refused and no data was removed."
}

Write-Host "Importing schema and seed data into empty database '$DbName'..."
$process = [System.Diagnostics.Process]::Start((New-MySqlProcessInfo ($BaseArguments + @($DbName)) $true))
$outputTask = $process.StandardOutput.ReadToEndAsync()
$errorTask = $process.StandardError.ReadToEndAsync()
$sqlStream = [System.IO.File]::OpenRead($SqlPath)
try {
  $sqlStream.CopyTo($process.StandardInput.BaseStream)
} finally {
  $sqlStream.Dispose()
  $process.StandardInput.Close()
}
$process.WaitForExit()
$output = $outputTask.Result
$errorOutput = $errorTask.Result
if ($process.ExitCode -ne 0) {
  throw "Database import failed. Database '$DbName' may now be partially initialized. Keep it for inspection and set DB_NAME to a new unused database before retrying; no cleanup was performed. MySQL error: $errorOutput$output"
}

Write-Host "Database '$DbName' initialized successfully."
