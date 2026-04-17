param(
  [ValidateSet("dev", "prod")]
  [string]$Mode = "dev",
  [switch]$NoInstall,
  [switch]$SkipDb,
  [switch]$InitDb,
  [switch]$SkipBuild,
  [switch]$DryRun,
  [string]$DbName = "web",
  [string]$DbUser = "root",
  [string]$DbPassword = "123456",
  [string]$MysqlContainer = "projectku-mysql"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FrontendDir = Join-Path $Root "frontend"
$BackendDir = if (Test-Path (Join-Path $Root "back")) { Join-Path $Root "back" } else { Join-Path $Root "backend" }
$LogsDir = Join-Path $Root "logs"
$PidsDir = Join-Path $Root ".pids"

New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null
New-Item -ItemType Directory -Force -Path $PidsDir | Out-Null

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host $Message
}

function Command-Exists([string]$Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-External([string]$FilePath, [string[]]$Args, [string]$WorkingDirectory = $Root) {
  if ($DryRun) {
    Write-Host ("[dry-run] " + $FilePath + " " + ($Args -join " "))
    return
  }
  $p = Start-Process -FilePath $FilePath -ArgumentList $Args -WorkingDirectory $WorkingDirectory -NoNewWindow -Wait -PassThru
  if ($p.ExitCode -ne 0) {
    throw ("Command failed: " + $FilePath + " " + ($Args -join " "))
  }
}

function Get-JavaMajorVersion {
  if (-not (Command-Exists "java")) { return $null }
  $out = & cmd /c "java -version 2>&1"
  $line = ($out | Select-Object -First 1)
  if ($line -match '"(?<ver>\d+)(\.\d+)?') {
    return [int]$Matches["ver"]
  }
  return $null
}

function Ensure-Winget {
  if (Command-Exists "winget") { return }
  throw "winget not found. Please install App Installer from Microsoft Store (or use -NoInstall)."
}

function Ensure-Tool([string]$CommandName, [string]$WingetId) {
  if (Command-Exists $CommandName) { return }
  if ($NoInstall) { throw ("Missing dependency: " + $CommandName) }

  Ensure-Winget
  Write-Step ("Installing " + $CommandName + " ...")
  Invoke-External "winget" @("install", "--id", $WingetId, "-e", "--accept-package-agreements", "--accept-source-agreements") $Root
  if (-not (Command-Exists $CommandName)) {
    throw ("Install finished but " + $CommandName + " is still not found. Restart your terminal and re-run.")
  }
}

function Ensure-Java17 {
  $major = Get-JavaMajorVersion
  if ($major -eq 17) { return }
  if ($NoInstall) { throw "Missing dependency: JDK 17" }
  Ensure-Winget
  Write-Step "Installing JDK 17 (Temurin) ..."
  Invoke-External "winget" @("install", "--id", "EclipseAdoptium.Temurin.17.JDK", "-e", "--accept-package-agreements", "--accept-source-agreements") $Root
  $major2 = Get-JavaMajorVersion
  if ($major2 -ne 17) {
    throw "JDK 17 is required. Restart your terminal (or log out/in) and re-run."
  }
}

function Ensure-Node18Plus {
  if (-not (Command-Exists "node")) {
    if ($NoInstall) { throw "Missing dependency: Node.js" }
    Ensure-Winget
    Write-Step "Installing Node.js (LTS) ..."
    Invoke-External "winget" @("install", "--id", "OpenJS.NodeJS.LTS", "-e", "--accept-package-agreements", "--accept-source-agreements") $Root
  }

  $v = (& node -v 2>$null) -replace "^v", ""
  $major = ($v -split "\.")[0]
  if ([int]$major -lt 18) {
    throw ("Node.js 18+ is required. Current: v" + $v)
  }
}

function Ensure-Docker {
  if (Command-Exists "docker") { return }
  if ($NoInstall) { throw "Missing dependency: Docker Desktop (docker)" }
  Ensure-Winget
  Write-Step "Installing Docker Desktop ..."
  Invoke-External "winget" @("install", "--id", "Docker.DockerDesktop", "-e", "--accept-package-agreements", "--accept-source-agreements") $Root
  if (-not (Command-Exists "docker")) {
    throw "Docker is required. Open Docker Desktop and ensure 'docker' is available in PATH, then re-run."
  }
}

function Start-Compose {
  if ($SkipDb) { return }
  Ensure-Docker

  Write-Step "Starting MySQL (docker compose) ..."
  if ($DryRun) {
    Write-Host ("[dry-run] (cd `"$Root`" && docker compose up -d) or docker-compose up -d")
    return
  }

  Push-Location $Root
  try {
    & docker compose up -d | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }
  } catch {
    & docker-compose up -d | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "docker-compose up failed" }
  } finally {
    Pop-Location
  }
}

function Wait-For-MySQL {
  if ($SkipDb) { return }
  if ($DryRun) { return }

  Write-Step "Waiting for MySQL to be ready ..."
  $max = 60
  for ($i = 0; $i -lt $max; $i++) {
    & docker exec $MysqlContainer mysqladmin ping "-u$DbUser" "-p$DbPassword" "--silent" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { return }
    Start-Sleep -Seconds 2
  }
  throw "MySQL is not ready. Check docker logs: docker logs $MysqlContainer"
}

function Import-DbSchema {
  if ($SkipDb -or (-not $InitDb)) { return }
  Ensure-Docker
  Wait-For-MySQL

  Write-Step "Importing database schema and seed data ..."
  $sqls = @(
    "back/sql/schema_v1.sql",
    "back/sql/schema_v2_address.sql",
    "back/sql/schema_v3_payment.sql",
    "back/sql/schema_v4_marketing_aftersales.sql",
    "back/sql/schema_v5_products_tags.sql",
    "back/sql/seed_demo.sql",
    "back/sql/seed_products_categories_1_8.sql"
  )

  foreach ($rel in $sqls) {
    $f = Join-Path $Root $rel
    if (-not (Test-Path $f)) { throw ("SQL file not found: " + $f) }

    if ($DryRun) {
      Write-Host ("[dry-run] import " + $rel)
      continue
    }

    $sql = Get-Content $f -Raw
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sql)
    $ms = New-Object System.IO.MemoryStream(,$bytes)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "docker"
    $psi.ArgumentList = @("exec", "-i", $MysqlContainer, "mysql", "-u$DbUser", "-p$DbPassword", $DbName)
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $ms.CopyTo($p.StandardInput.BaseStream)
    $p.StandardInput.Close()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) {
      throw ("DB import failed: " + $rel + "`n" + $stderr + $stdout)
    }
  }
}

function Ensure-FrontendDeps {
  if (-not (Test-Path (Join-Path $FrontendDir "package.json"))) { return }
  Ensure-Node18Plus
  if ($DryRun) {
    Write-Host ("[dry-run] (cd `"$FrontendDir`" && npm ci)")
    return
  }
  Push-Location $FrontendDir
  try {
    & npm ci | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }
  } finally {
    Pop-Location
  }
}

function Ensure-BackendDeps {
  if (-not (Test-Path (Join-Path $BackendDir "pom.xml"))) { return }
  Ensure-Java17
  Ensure-Tool "mvn" "Apache.Maven"
}

function Build-IfNeeded {
  if ($SkipBuild) { return }

  Ensure-BackendDeps
  Ensure-FrontendDeps

  if ($DryRun) {
    Write-Host ("[dry-run] (cd `"$BackendDir`" && mvn -DskipTests package)")
    if ($Mode -eq "prod") {
      Write-Host ("[dry-run] (cd `"$FrontendDir`" && npm run build)")
    }
    return
  }

  if (Test-Path (Join-Path $BackendDir "pom.xml")) {
    Write-Step "Building backend (Maven) ..."
    Push-Location $BackendDir
    try {
      & mvn -DskipTests package | Out-Host
      if ($LASTEXITCODE -ne 0) { throw "mvn package failed" }
    } finally {
      Pop-Location
    }
  }

  if ($Mode -eq "prod" -and (Test-Path (Join-Path $FrontendDir "package.json"))) {
    Write-Step "Building frontend (Vite) ..."
    Push-Location $FrontendDir
    try {
      & npm run build | Out-Host
      if ($LASTEXITCODE -ne 0) { throw "npm run build failed" }
    } finally {
      Pop-Location
    }
  }
}

function Start-ServiceProcess([string]$Name, [string]$WorkingDirectory, [string]$CommandLine) {
  $log = Join-Path $LogsDir ($Name + ".log")
  $pidfile = Join-Path $PidsDir ($Name + ".pid")

  if ($DryRun) {
    Write-Host ("[dry-run] start " + $Name + ": " + $CommandLine)
    return
  }

  $full = "cd `"$WorkingDirectory`"; " + $CommandLine
  $p = Start-Process -FilePath "powershell" -ArgumentList @("-NoExit", "-Command", $full) -WorkingDirectory $WorkingDirectory -PassThru
  Set-Content -Path $pidfile -Value $p.Id -Encoding ASCII
  Set-Content -Path $log -Value "" -Encoding UTF8
  Write-Host ("Started " + $Name + " (pid=" + $p.Id + ")")
}

function Start-App {
  Write-Step "Starting services ..."

  if (Test-Path (Join-Path $BackendDir "pom.xml")) {
    Ensure-BackendDeps
    if ($Mode -eq "dev") {
      Start-ServiceProcess "backend" $BackendDir "mvn spring-boot:run"
    } else {
      $jar = Get-ChildItem -Path (Join-Path $BackendDir "target") -Filter "*.jar" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if (-not $jar) { throw "Backend jar not found. Run with -SkipBuild:$false or build backend first." }
      Start-ServiceProcess "backend" $BackendDir ("java -jar `"" + $jar.FullName + "`"")
    }
  }

  if (Test-Path (Join-Path $FrontendDir "package.json")) {
    Ensure-FrontendDeps
    if ($Mode -eq "dev") {
      Start-ServiceProcess "frontend" $FrontendDir "npm run dev"
    } else {
      Start-ServiceProcess "frontend" $FrontendDir "npm run preview -- --host 0.0.0.0 --port 5173"
    }
  }

  Write-Host ""
  Write-Host "Frontend: http://localhost:5173"
  Write-Host "Backend:  http://localhost:8080/api"
}

Write-Step "Project root: $Root"
Start-Compose
Import-DbSchema
Build-IfNeeded
Start-App
