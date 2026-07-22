[CmdletBinding()]
param(
  [ValidateSet("dev", "prod")]
  [string]$Mode,
  [Alias("SkipDb")]
  [switch]$SkipInfrastructure,
  [switch]$InitDb,
  [switch]$SkipBuild,
  [switch]$DryRun,
  [switch]$OpenWindow,
  [switch]$WithMonitoring,
  [switch]$NoInstall,
  [string]$DbName,
  [string]$DbUser,
  [string]$DbPassword
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$BackendDir = Join-Path $Root "back"
$FrontendDir = Join-Path $Root "frontend"
$AdminDir = Join-Path $Root "frontend-admin"
$LogsDir = Join-Path $Root "logs"
$PidsDir = Join-Path $Root ".pids"
$ScriptParameters = $PSBoundParameters

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
    if (-not (Test-Path "env:$name")) {
      Set-Item -Path "env:$name" -Value $value
    }
  }
}

function Get-Setting([string]$ParameterName, [string]$Value, [string]$EnvironmentName, [string]$DefaultValue) {
  if ($ParameterName -and $ScriptParameters.ContainsKey($ParameterName)) { return $Value }
  $environmentValue = [Environment]::GetEnvironmentVariable($EnvironmentName, "Process")
  if (-not [string]::IsNullOrWhiteSpace($environmentValue)) { return $environmentValue }
  return $DefaultValue
}

Import-DotEnv (Join-Path $Root ".env")

$Mode = Get-Setting "Mode" $Mode "MODE" "dev"
$DbName = Get-Setting "DbName" $DbName "DB_NAME" "web"
$DbUser = Get-Setting "DbUser" $DbUser "DB_USER" "root"
$DbPassword = Get-Setting "DbPassword" $DbPassword "DB_PASSWORD" "123456"
$BackendPort = Get-Setting "" "" "BACKEND_PORT" "8080"
$FrontendPort = Get-Setting "" "" "FRONTEND_PORT" "5173"
$AdminPort = Get-Setting "" "" "ADMIN_PORT" "5174"

if ($Mode -notin @("dev", "prod")) { throw "MODE must be dev or prod." }
if ($DbName -notmatch '^[A-Za-z0-9_]+$') { throw "DB_NAME may contain only letters, numbers, and underscores." }
if ($DbUser -notmatch '^[A-Za-z0-9_]+$') { throw "DB_USER may contain only letters, numbers, and underscores." }
if (-not $SkipInfrastructure -and $DbUser -ne "root") {
  throw "The Compose workflow requires DB_USER=root. Use -SkipInfrastructure for an existing non-root MySQL account."
}

$env:MODE = $Mode
$env:DB_NAME = $DbName
$env:DB_USER = $DbUser
$env:DB_PASSWORD = $DbPassword
$env:BACKEND_PORT = $BackendPort
$env:FRONTEND_PORT = $FrontendPort
$env:ADMIN_PORT = $AdminPort

if (-not $DryRun) {
  New-Item -ItemType Directory -Force -Path $LogsDir, $PidsDir | Out-Null
}

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host "==> $Message"
}

function Resolve-Command([string[]]$Names) {
  foreach ($name in $Names) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
  }
  return $null
}

function Test-JdkHome([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
  try {
    return [System.IO.File]::Exists([System.IO.Path]::Combine($Path, "bin", "javac.exe"))
  } catch {
    return $false
  }
}

function Get-LockHash([string]$Directory) {
  return (Get-FileHash -LiteralPath (Join-Path $Directory "package-lock.json") -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-ManagedProcessIdentity([string]$Name) {
  $metadataFile = Join-Path $PidsDir "$Name.pid.json"
  if (-not (Test-Path -LiteralPath $metadataFile)) { return $false }
  try {
    $metadata = Get-Content -LiteralPath $metadataFile -Raw | ConvertFrom-Json
    if ($metadata.schema -ne 2 -or $metadata.name -ne $Name -or $metadata.projectRoot -ne $Root -or "$($metadata.pid)" -notmatch '^\d+$') { return $false }
    $process = Get-Process -Id ([int]$metadata.pid) -ErrorAction Stop
    $actualStart = $process.StartTime.ToUniversalTime()
    $expectedStart = [DateTimeOffset]::Parse($metadata.startedUtc).UtcDateTime
    if ([Math]::Abs(($actualStart - $expectedStart).TotalSeconds) -gt 2) { return $false }
    $nativeProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($metadata.pid)"
    if (-not $nativeProcess) { return $false }
    return $nativeProcess.ExecutablePath -eq $metadata.executable -and $nativeProcess.CommandLine -eq $metadata.commandLine
  } catch {
    return $false
  }
}

function Test-ProcessDescendsFrom([int]$ProcessId, [int]$AncestorProcessId) {
  $visited = @{}
  while ($ProcessId -gt 0 -and -not $visited.ContainsKey($ProcessId)) {
    if ($ProcessId -eq $AncestorProcessId) { return $true }
    $visited[$ProcessId] = $true
    $nativeProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
    if (-not $nativeProcess) { return $false }
    $ProcessId = [int]$nativeProcess.ParentProcessId
  }
  return $false
}

function Get-PortListeners([int]$Port) {
  return @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue)
}

function Test-ManagedServiceIdentity([string]$Name, [int]$Port) {
  if (-not (Test-ManagedProcessIdentity $Name)) { return $false }
  try {
    $metadataFile = Join-Path $PidsDir "$Name.pid.json"
    $metadata = Get-Content -LiteralPath $metadataFile -Raw | ConvertFrom-Json
    foreach ($listener in (Get-PortListeners $Port)) {
      if (Test-ProcessDescendsFrom ([int]$listener.OwningProcess) ([int]$metadata.pid)) { return $true }
    }
  } catch {
    return $false
  }
  return $false
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

function Invoke-Checked([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory = $Root) {
  if ($DryRun) {
    Write-Host ("[dry-run] {0} {1}" -f $FilePath, ($Arguments -join " "))
    return
  }

  Push-Location $WorkingDirectory
  try {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $FilePath @Arguments | Out-Host
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($exitCode -ne 0) {
      throw ("Command failed ({0}): {1} {2}" -f $exitCode, $FilePath, ($Arguments -join " "))
    }
  } finally {
    $ErrorActionPreference = "Stop"
    Pop-Location
  }
}

function Assert-Java17 {
  $java = Resolve-Command @("java.exe", "java")
  if (-not $java) { throw "JDK 17 is required, but java was not found in PATH." }
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $versionLine = (& $java -version 2>&1 | Select-Object -First 1).ToString()
  $ErrorActionPreference = $previousErrorAction
  if ($versionLine -notmatch '"17(?:\.|\")') {
    throw "JDK 17 is required. Current: $versionLine"
  }

  if (-not (Test-JdkHome $env:JAVA_HOME)) {
    $ErrorActionPreference = "Continue"
    $javaHomeLine = & $java -XshowSettings:properties -version 2>&1 | Where-Object { $_ -match '^\s*java\.home\s*=' } | Select-Object -First 1
    $ErrorActionPreference = $previousErrorAction
    if ($javaHomeLine -and $javaHomeLine -match '^\s*java\.home\s*=\s*(.+?)\s*$') {
      $detectedJavaHome = $Matches[1]
      if (Test-JdkHome $detectedJavaHome) {
        $env:JAVA_HOME = $detectedJavaHome
        Write-Host "Using JAVA_HOME=$detectedJavaHome for this deployment process."
      }
    }
  }
  if (-not (Test-JdkHome $env:JAVA_HOME)) {
    throw "A JDK 17 installation was found, but JAVA_HOME could not be resolved to a JDK root."
  }
}

function Assert-NodeVersion {
  $node = Resolve-Command @("node.exe", "node")
  if (-not $node) { throw "Node.js ^20.19.0 or >=22.12.0 is required." }
  $version = (& $node --version).TrimStart("v")
  $parts = $version.Split(".")
  $major = [int]$parts[0]
  $minor = [int]$parts[1]
  $supported = ($major -eq 20 -and $minor -ge 19) -or ($major -eq 22 -and $minor -ge 12) -or ($major -gt 22)
  if (-not $supported) { throw "Node.js ^20.19.0 or >=22.12.0 is required. Current: v$version" }
}

function Get-MavenCommand {
  $wrapper = Join-Path $BackendDir "mvnw.cmd"
  if (Test-Path -LiteralPath $wrapper) { return $wrapper }
  $maven = Resolve-Command @("mvn.cmd", "mvn")
  if ($maven) { return $maven }
  throw "Maven was not found. Restore back/mvnw.cmd or install Maven 3.8+."
}

function Get-NpmCommand {
  $npm = Resolve-Command @("npm.cmd", "npm")
  if (-not $npm) { throw "npm was not found in PATH." }
  return $npm
}

function Start-Infrastructure {
  if ($SkipInfrastructure) { return }
  $docker = Resolve-Command @("docker.exe", "docker")
  if (-not $docker) { throw "Docker is required unless -SkipInfrastructure is used." }

  Write-Step "Starting MySQL and Redis"
  $arguments = @("compose")
  if ($WithMonitoring) { $arguments += @("--profile", "monitoring") }
  $arguments += @("up", "-d", "mysql", "redis")
  if ($WithMonitoring) { $arguments = @("compose", "--profile", "monitoring", "up", "-d") }
  Invoke-Checked $docker $arguments $Root
}

function Wait-ForMySql {
  if ($SkipInfrastructure -or $DryRun) { return }
  $docker = Resolve-Command @("docker.exe", "docker")
  Write-Step "Waiting for MySQL"
  for ($attempt = 1; $attempt -le 60; $attempt++) {
    Push-Location $Root
    try {
      & $docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqladmin ping -uroot --silent' 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { return }
    } finally {
      Pop-Location
    }
    Start-Sleep -Seconds 2
  }
  throw "MySQL did not become ready. Run 'docker compose logs mysql' from the repository root."
}

function Initialize-Database {
  if (-not $InitDb) { return }
  if ($SkipInfrastructure) {
    throw "-InitDb requires Compose MySQL. For local MySQL, run scripts/init-local-db.ps1 separately."
  }
  if ($DryRun) {
    Write-Host "[dry-run] create database $DbName if missing, verify it has zero tables, then import back/sql/init_db.sql"
    return
  }

  Wait-ForMySql
  $docker = Resolve-Command @("docker.exe", "docker")
  $createCommand = 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot -e "CREATE DATABASE IF NOT EXISTS {0} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"' -f $DbName
  Invoke-Checked $docker @("compose", "exec", "-T", "mysql", "sh", "-c", $createCommand) $Root

  $dbNameHex = [BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes($DbName)).Replace("-", "")
  $countCommand = 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot --batch --skip-column-names -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=CONVERT(0x{0} USING utf8mb4);"' -f $dbNameHex
  Push-Location $Root
  try {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $tableCountOutput = & $docker compose exec -T mysql sh -c $countCommand 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
  } finally {
    $ErrorActionPreference = "Stop"
    Pop-Location
  }
  if ($exitCode -ne 0) { throw "Unable to inspect database $DbName. $($tableCountOutput -join [Environment]::NewLine)" }
  $tableCount = ($tableCountOutput | Select-Object -Last 1).ToString().Trim()
  if ($tableCount -notmatch '^\d+$') { throw "Unable to parse table count for database $DbName." }
  if ([int]$tableCount -gt 0) {
    throw "Database $DbName is not empty. Omit -InitDb to preserve existing data."
  }

  Write-Step "Importing database schema and seed data"
  $sqlPath = Join-Path $BackendDir "sql/init_db.sql"
  $processInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $processInfo.FileName = $docker
  $processInfo.WorkingDirectory = $Root
  $importCommand = 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot --default-character-set=utf8mb4 {0}' -f $DbName
  Set-NativeProcessArguments $processInfo @("compose", "exec", "-T", "mysql", "sh", "-c", $importCommand)
  $processInfo.RedirectStandardInput = $true
  $processInfo.RedirectStandardError = $true
  $processInfo.UseShellExecute = $false
  $process = [System.Diagnostics.Process]::Start($processInfo)
  $errorTask = $process.StandardError.ReadToEndAsync()
  $sqlStream = [System.IO.File]::OpenRead($sqlPath)
  try {
    $sqlStream.CopyTo($process.StandardInput.BaseStream)
  } finally {
    $sqlStream.Dispose()
    $process.StandardInput.Close()
  }
  $process.WaitForExit()
  $errorOutput = $errorTask.Result
  if ($process.ExitCode -ne 0) {
    throw "Database import failed. Database '$DbName' may now be partially initialized. Keep the existing data for inspection and set DB_NAME to a new unused database before retrying; no cleanup was performed. MySQL error: $errorOutput"
  }
}

function Install-NodeDependencies([string]$Directory, [string]$Name, [int]$Port, [string]$Url, [string]$Marker) {
  $lockHash = Get-LockHash $Directory
  $lockMarker = Join-Path $Directory "node_modules/.projectku-package-lock.sha256"
  if (Test-Frontend $Url $Marker) {
    $recordedHash = if (Test-Path -LiteralPath $lockMarker) { (Get-Content -LiteralPath $lockMarker -Raw).Trim() } else { "" }
    if ((Test-ManagedServiceIdentity $Name $Port) -and $recordedHash -eq $lockHash) {
      Write-Host "$(Split-Path $Directory -Leaf) is already running with the current lockfile; skipping npm ci."
      return
    }
    throw "$(Split-Path $Directory -Leaf) is running without matching process/lockfile metadata. Stop it before deployment."
  }
  $npm = Get-NpmCommand
  Write-Step "Synchronizing dependencies: $(Split-Path $Directory -Leaf)"
  Invoke-Checked $npm @("ci") $Directory
  if (-not $DryRun) { Set-Content -LiteralPath $lockMarker -Value $lockHash -Encoding ascii }
}

function Build-Projects {
  Assert-Java17
  Assert-NodeVersion
  Install-NodeDependencies $FrontendDir "frontend" ([int]$FrontendPort) "http://127.0.0.1:$FrontendPort/" 'content="projectku-user"'
  Install-NodeDependencies $AdminDir "admin" ([int]$AdminPort) "http://127.0.0.1:$AdminPort/" 'content="projectku-admin"'
  if ($SkipBuild) { return }

  $maven = Get-MavenCommand
  Write-Step "Compiling backend"
  Invoke-Checked $maven @("-DskipTests", "compile") $BackendDir

  Write-Step "Building user frontend"
  Invoke-Checked (Get-NpmCommand) @("run", "build") $FrontendDir

  Write-Step "Building admin frontend"
  Invoke-Checked (Get-NpmCommand) @("run", "build") $AdminDir
}

function Test-BackendHealth([string]$Url) {
  try {
    $health = Invoke-RestMethod -Uri $Url -TimeoutSec 3
    return $health.status -eq "UP" -and $health.components.db.status -eq "UP" -and $health.components.redis.status -eq "UP"
  } catch {
    return $false
  }
}

function Test-Frontend([string]$Url, [string]$Marker) {
  try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
    return $response.StatusCode -eq 200 -and $response.Content.Contains($Marker)
  } catch {
    return $false
  }
}

function Start-ManagedProcess([string]$Name, [string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory) {
  if ($DryRun) {
    Write-Host ("[dry-run] start {0}: {1} {2}" -f $Name, $FilePath, ($Arguments -join " "))
    return
  }

  $start = @{
    FilePath = $FilePath
    ArgumentList = $Arguments
    WorkingDirectory = $WorkingDirectory
    PassThru = $true
  }
  if (-not $OpenWindow) {
    $start.RedirectStandardOutput = Join-Path $LogsDir "$Name.out.log"
    $start.RedirectStandardError = Join-Path $LogsDir "$Name.err.log"
    $start.WindowStyle = "Hidden"
  }
  $process = Start-Process @start
  $process.Refresh()
  $nativeProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)"
  if (-not $nativeProcess) { throw "Unable to capture process identity for $Name (PID $($process.Id))." }
  $metadata = [ordered]@{
    schema = 2
    name = $Name
    pid = $process.Id
    startedUtc = $process.StartTime.ToUniversalTime().ToString("o")
    projectRoot = $Root
    executable = $nativeProcess.ExecutablePath
    commandLine = $nativeProcess.CommandLine
  }
  $metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PidsDir "$Name.pid.json") -Encoding utf8
  Remove-Item -LiteralPath (Join-Path $PidsDir "$Name.pid") -Force -ErrorAction SilentlyContinue
  Write-Host "Started $Name (PID $($process.Id))."
}

function Wait-ForService([string]$Name, [string]$Url, [int]$TimeoutSeconds, [scriptblock]$Probe) {
  if ($DryRun) { return }
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (& $Probe) { Write-Host "$Name ready: $Url"; return }
    Start-Sleep -Seconds 2
  }
  throw "$Name did not become ready: $Url. Check logs/$Name.err.log and logs/$Name.out.log."
}

function Test-ServiceCanBeReused([string]$Name, [int]$Port, [string]$Url, [scriptblock]$Probe) {
  if (& $Probe) {
    if (Test-ManagedServiceIdentity $Name $Port) {
      Write-Host "$Name already running from this repository: $Url"
      return $true
    }
    throw "$Name URL is healthy at $Url, but PID metadata cannot prove that its listener belongs to this repository. The port is occupied by a non-managed service."
  }

  if (Test-ManagedProcessIdentity $Name) {
    throw "$name has valid PID metadata for this repository but is not healthy at $Url. Inspect its logs or stop it with scripts/stop.ps1 before retrying."
  }
  $listeners = @(Get-PortListeners $Port)
  if ($listeners.Count -gt 0) {
    $owners = (($listeners | Select-Object -ExpandProperty OwningProcess -Unique) -join ", ")
    throw "$Name is not healthy at $Url and port $Port is occupied by a non-managed listener (PID: $owners)."
  }
  return $false
}

function Start-Applications {
  Write-Step "Starting application services"
  $maven = Get-MavenCommand
  $npm = Get-NpmCommand

  $backendHealth = "http://127.0.0.1:$BackendPort/api/actuator/health"
  if (-not (Test-ServiceCanBeReused "backend" ([int]$BackendPort) $backendHealth { Test-BackendHealth $backendHealth })) {
    Start-ManagedProcess "backend" $maven @("spring-boot:run") $BackendDir
  }

  $frontendUrl = "http://127.0.0.1:$FrontendPort/"
  if (-not (Test-ServiceCanBeReused "frontend" ([int]$FrontendPort) $frontendUrl { Test-Frontend $frontendUrl 'content="projectku-user"' })) {
    $frontendArgs = if ($Mode -eq "dev") { @("run", "dev", "--", "--host", "0.0.0.0", "--port", $FrontendPort) } else { @("run", "preview", "--", "--host", "0.0.0.0", "--port", $FrontendPort) }
    Start-ManagedProcess "frontend" $npm $frontendArgs $FrontendDir
  }

  $adminUrl = "http://127.0.0.1:$AdminPort/"
  if (-not (Test-ServiceCanBeReused "admin" ([int]$AdminPort) $adminUrl { Test-Frontend $adminUrl 'content="projectku-admin"' })) {
    $adminArgs = if ($Mode -eq "dev") { @("run", "dev", "--", "--host", "0.0.0.0", "--port", $AdminPort) } else { @("run", "preview", "--", "--host", "0.0.0.0", "--port", $AdminPort) }
    Start-ManagedProcess "admin" $npm $adminArgs $AdminDir
  }

  Wait-ForService "backend" $backendHealth 120 { Test-BackendHealth $backendHealth }
  Wait-ForService "frontend" $frontendUrl 60 { Test-Frontend $frontendUrl 'content="projectku-user"' }
  Wait-ForService "admin" $adminUrl 60 { Test-Frontend $adminUrl 'content="projectku-admin"' }
}

if ($NoInstall) {
  Write-Verbose "-NoInstall is accepted for backward compatibility; this script never installs system software."
}

Write-Step "Project root: $Root"
Start-Infrastructure
Initialize-Database
Build-Projects
Start-Applications

Write-Host ""
Write-Host "User frontend:  http://localhost:$FrontendPort"
Write-Host "Admin frontend: http://localhost:$AdminPort"
Write-Host "Backend:        http://localhost:$BackendPort/api"
Write-Host "Health:         http://localhost:$BackendPort/api/actuator/health"
