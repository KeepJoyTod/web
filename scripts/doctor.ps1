[CmdletBinding()]
param(
  [switch]$SkipDocker,
  [switch]$Json
)

$ErrorActionPreference = "Continue"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Results = [System.Collections.Generic.List[object]]::new()

function Add-Result([string]$Name, [string]$Status, [string]$Detail) {
  $Results.Add([pscustomobject]@{
    check = $Name
    status = $Status
    detail = $Detail
  })
}

function Resolve-Command([string[]]$Names) {
  foreach ($name in $Names) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
  }
  return $null
}

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

function Get-PortSetting([string]$Name, [int]$DefaultValue) {
  $rawValue = Get-EnvironmentSetting $Name "$DefaultValue"
  $parsedValue = 0
  if (-not [int]::TryParse($rawValue, [ref]$parsedValue) -or $parsedValue -lt 1 -or $parsedValue -gt 65535) {
    Add-Result "config-$Name" "FAIL" "$Name must be an integer between 1 and 65535."
    return $null
  }
  return $parsedValue
}

function Test-TcpEndpoint([string]$HostName, [int]$Port, [int]$TimeoutMilliseconds = 2000) {
  $client = [System.Net.Sockets.TcpClient]::new()
  $asyncResult = $null
  try {
    $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)
    if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) { return $false }
    $client.EndConnect($asyncResult)
    return $true
  } catch {
    return $false
  } finally {
    if ($asyncResult -and $asyncResult.AsyncWaitHandle) { $asyncResult.AsyncWaitHandle.Close() }
    $client.Close()
  }
}

function Add-LocalPortResult([string]$Name, [int]$Port) {
  $listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($listener) {
    Add-Result $Name "INFO" "Configured local port $Port is already in use by PID $($listener.OwningProcess). Verify that it is the intended service before deployment."
  } else {
    Add-Result $Name "PASS" "Configured local port $Port is available."
  }
}

function Test-JdkHome([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
  try {
    return [System.IO.File]::Exists([System.IO.Path]::Combine($Path, "bin", "javac.exe"))
  } catch {
    return $false
  }
}

$requiredFiles = @(
  "back/pom.xml",
  "back/mvnw.cmd",
  "back/sql/init_db.sql",
  "frontend/package.json",
  "frontend-admin/package.json",
  "docker-compose.yml",
  ".env.example",
  "scripts/init-local-db.ps1"
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Root $_)) })
if ($missingFiles.Count -eq 0) {
  Add-Result "project-files" "PASS" "Required deployment files are present."
} else {
  Add-Result "project-files" "FAIL" ("Missing: " + ($missingFiles -join ", "))
}

$java = Resolve-Command @("java.exe", "java")
if (-not $java) {
  Add-Result "java" "FAIL" "JDK 17 was not found in PATH."
} else {
  $javaVersion = (& $java -version 2>&1 | Select-Object -First 1).ToString()
  $javaStatus = if ($javaVersion -match '"17(?:\.|\")') { "PASS" } else { "FAIL" }
  Add-Result "java" $javaStatus $javaVersion
}

if (-not (Test-JdkHome $env:JAVA_HOME)) {
  $javaHomeLine = if ($java) { & $java -XshowSettings:properties -version 2>&1 | Where-Object { $_ -match '^\s*java\.home\s*=' } | Select-Object -First 1 } else { $null }
  $detectedJavaHome = if ($javaHomeLine -and $javaHomeLine -match '^\s*java\.home\s*=\s*(.+?)\s*$') { $Matches[1] } else { "unknown" }
  Add-Result "JAVA_HOME" "WARN" "JAVA_HOME is unset or invalid. deploy.ps1 will use the detected JDK for its process: $detectedJavaHome"
} else {
  Add-Result "JAVA_HOME" "PASS" $env:JAVA_HOME
}

$node = Resolve-Command @("node.exe", "node")
if (-not $node) {
  Add-Result "node" "FAIL" "Node.js ^20.19.0 or >=22.12.0 was not found."
} else {
  $nodeVersion = (& $node --version).TrimStart("v")
  $parts = $nodeVersion.Split(".")
  $major = [int]$parts[0]
  $minor = [int]$parts[1]
  $supported = ($major -eq 20 -and $minor -ge 19) -or ($major -eq 22 -and $minor -ge 12) -or ($major -gt 22)
  Add-Result "node" $(if ($supported) { "PASS" } else { "FAIL" }) "v$nodeVersion"
}

$npm = Resolve-Command @("npm.cmd", "npm")
Add-Result "npm" $(if ($npm) { "PASS" } else { "FAIL" }) $(if ($npm) { $npm } else { "npm was not found in PATH." })

Import-DotEnv (Join-Path $Root ".env")
$DbHost = Get-EnvironmentSetting "DB_HOST" "127.0.0.1"
$DbPort = Get-PortSetting "DB_PORT" 3306
$DbName = Get-EnvironmentSetting "DB_NAME" "web"
$DbUser = Get-EnvironmentSetting "DB_USER" "root"
$DbPassword = Get-EnvironmentSetting "DB_PASSWORD" "123456"
$RedisHost = Get-EnvironmentSetting "REDIS_HOST" "127.0.0.1"
$RedisPort = Get-PortSetting "REDIS_PORT" 6379
$BackendPort = Get-PortSetting "BACKEND_PORT" 8080
$FrontendPort = Get-PortSetting "FRONTEND_PORT" 5173
$AdminPort = Get-PortSetting "ADMIN_PORT" 5174
if ($DbName -notmatch '^[A-Za-z0-9_]+$') { Add-Result "config-DB_NAME" "FAIL" "DB_NAME may contain only letters, numbers, and underscores." }
if ($DbUser -notmatch '^[A-Za-z0-9_]+$') { Add-Result "config-DB_USER" "FAIL" "DB_USER may contain only letters, numbers, and underscores." }

if (-not $SkipDocker) {
  $docker = Resolve-Command @("docker.exe", "docker")
  if (-not $docker) {
    Add-Result "docker-cli" "FAIL" "Docker was not found in PATH."
  } else {
    Add-Result "docker-cli" "PASS" $docker
    & $docker info *> $null
    if ($LASTEXITCODE -eq 0) {
      Add-Result "docker-daemon" "PASS" "Docker daemon is reachable."
    } else {
      Add-Result "docker-daemon" "FAIL" "Docker CLI is installed, but the daemon is not reachable. Start Docker Desktop or Docker Engine."
    }

    Push-Location $Root
    try {
      & $docker compose config --quiet *> $null
      $composeExitCode = $LASTEXITCODE
    } finally {
      Pop-Location
    }
    Add-Result "compose-config" $(if ($composeExitCode -eq 0) { "PASS" } else { "FAIL" }) $(if ($composeExitCode -eq 0) { "docker-compose.yml is valid." } else { "docker compose config failed." })
  }
}

if ($SkipDocker) {
  if ($null -ne $DbPort) {
    $dbReachable = Test-TcpEndpoint $DbHost $DbPort
    Add-Result "mysql-tcp" $(if ($dbReachable) { "PASS" } else { "FAIL" }) $(if ($dbReachable) { "MySQL endpoint ${DbHost}:$DbPort accepts TCP connections." } else { "MySQL endpoint ${DbHost}:$DbPort is not reachable. Start the configured local service or fix .env." })
    if ($dbReachable) {
      $mysql = Resolve-Command @("mysql.exe", "mysql")
      if ($mysql) {
        $previousMysqlPassword = [Environment]::GetEnvironmentVariable("MYSQL_PWD", "Process")
        try {
          $env:MYSQL_PWD = $DbPassword
          & $mysql --protocol=TCP "--host=$DbHost" "--port=$DbPort" "--user=$DbUser" --batch --skip-column-names --execute="SELECT 1" *> $null
          $mysqlExitCode = $LASTEXITCODE
        } finally {
          if ($null -eq $previousMysqlPassword) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue } else { $env:MYSQL_PWD = $previousMysqlPassword }
        }
        Add-Result "mysql-protocol" $(if ($mysqlExitCode -eq 0) { "PASS" } else { "FAIL" }) $(if ($mysqlExitCode -eq 0) { "MySQL connection and credentials were accepted." } else { "MySQL rejected the connection or credentials." })
      } else {
        Add-Result "mysql-client" "WARN" "mysql CLI was not found; protocol and credentials were not checked."
      }
    }
  }
  if ($null -ne $RedisPort) {
    $redisReachable = Test-TcpEndpoint $RedisHost $RedisPort
    Add-Result "redis-tcp" $(if ($redisReachable) { "PASS" } else { "FAIL" }) $(if ($redisReachable) { "Redis endpoint ${RedisHost}:$RedisPort accepts TCP connections." } else { "Redis endpoint ${RedisHost}:$RedisPort is not reachable. Start the configured local service or fix .env." })
    if ($redisReachable) {
      $redisCli = Resolve-Command @("redis-cli.exe", "redis-cli")
      if ($redisCli) {
        $redisReply = (& $redisCli -h $RedisHost -p $RedisPort --raw ping 2>$null | Select-Object -Last 1)
        $redisExitCode = $LASTEXITCODE
        Add-Result "redis-protocol" $(if ($redisExitCode -eq 0 -and $redisReply -eq "PONG") { "PASS" } else { "FAIL" }) $(if ($redisExitCode -eq 0 -and $redisReply -eq "PONG") { "Redis PING returned PONG." } else { "Redis PING did not return PONG." })
      } else {
        Add-Result "redis-client" "WARN" "redis-cli was not found; protocol was not checked."
      }
    }
  }
} else {
  if ($null -ne $DbPort) { Add-LocalPortResult "mysql-port" $DbPort }
  if ($null -ne $RedisPort) { Add-LocalPortResult "redis-port" $RedisPort }
}

if ($null -ne $BackendPort) { Add-LocalPortResult "backend-port" $BackendPort }
if ($null -ne $FrontendPort) { Add-LocalPortResult "frontend-port" $FrontendPort }
if ($null -ne $AdminPort) { Add-LocalPortResult "admin-port" $AdminPort }

if (Test-Path -LiteralPath (Join-Path $Root ".env")) {
  Add-Result ".env" "PASS" "Local .env exists; values were not printed."
} else {
  Add-Result ".env" "INFO" "No .env file. Built-in local defaults will be used."
}

if ($Json) {
  $Results | ConvertTo-Json -Depth 3
} else {
  $Results | Format-Table -AutoSize
}

if ($Results.Status -contains "FAIL") { exit 1 }
