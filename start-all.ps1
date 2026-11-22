# Starts the whole ScopeGuard stack, gently (below-normal CPU priority, no file watchers):
#   1. ScopeGuard core API + website   http://localhost:4000 / http://localhost:5173   (React + Node, unchanged)
#   2. private Postgres 18 for Serverpod on port 8090   (from the PostgreSQL already installed; Serverpod's
#      embedded-Postgres download is NOT used, because unpacking it blue-screened this laptop twice)
#   3. Serverpod backend + Flutter web app  http://localhost:8080 (API) / http://localhost:8082 (app)
#
#   .\start-all.ps1          start everything
#   .\start-all.ps1 -Web     also rebuild the Flutter web app first (~1-2 min)
#   .\start-all.ps1 -Public  also open a temporary public https link for phones (Cloudflare quick tunnel);
#                            it lives only while this laptop runs it. -Stop closes it.
#   .\start-all.ps1 -Stop    stop everything this script started
param([switch]$Web, [switch]$Stop, [switch]$Public)
$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$logs    = Join-Path $root 'logs'
$pod     = Join-Path $root 'scopeguard_app\scopeguard_app_server'
$app     = Join-Path $root 'scopeguard_app\scopeguard_app_flutter'
$pgBin   = 'C:\Program Files\PostgreSQL\18\bin'
$pgData  = Join-Path $pod '.pgdev'
$flutter = 'E:\flutter\flutter-sp4\bin\flutter.bat'
$dart    = 'E:\flutter\flutter-sp4\bin\cache\dart-sdk\bin\dart.exe'
New-Item -ItemType Directory -Force $logs | Out-Null

function Stop-Pid($name) {
  $f = Join-Path $logs "$name.pid"
  if (Test-Path $f) {
    $id = Get-Content $f
    # Kill the whole process tree (npm -> concurrently -> node).
    & taskkill /PID $id /T /F 2>$null | Out-Null
    Remove-Item $f
  }
}
function Wait-Port($port, $seconds) {
  for ($i = 0; $i -lt $seconds; $i++) {
    if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) { return $true }
    Start-Sleep 1
  }
  return $false
}
function Start-Low($name, $file, $argList, $dir) {
  $p = Start-Process $file -ArgumentList $argList -WorkingDirectory $dir -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $logs "$name.out.log") -RedirectStandardError (Join-Path $logs "$name.err.log")
  Start-Sleep 1
  try { $p.PriorityClass = 'BelowNormal' } catch {}
  $p.Id | Set-Content (Join-Path $logs "$name.pid")
  return $p
}

if ($Stop) {
  Stop-Pid 'tunnel'
  Stop-Pid 'gateway'
  Stop-Pid 'serverpod'
  Stop-Pid 'core'
  & "$pgBin\pg_ctl.exe" -D $pgData stop -m fast 2>$null | Out-Null
  Write-Host 'Stopped ScopeGuard core, Serverpod and its database.'
  return
}

# 1. ScopeGuard core API + website
if (-not (Get-NetTCPConnection -State Listen -LocalPort 4000 -ErrorAction SilentlyContinue)) {
  Start-Low 'core' 'cmd.exe' '/c npm run dev' $root | Out-Null
  if (-not (Wait-Port 4000 90)) { throw 'ScopeGuard core API did not start - see logs\core.err.log' }
}
Write-Host 'ScopeGuard core API + website: http://localhost:4000 / http://localhost:5173'

# 2. Private Postgres for Serverpod
if (-not (Test-Path "$pgData\PG_VERSION")) {
  & "$pgBin\initdb.exe" -D $pgData -U postgres -A trust --locale=C -E UTF8 | Out-Null
}
& "$pgBin\pg_isready.exe" -h localhost -p 8090 -q
if ($LASTEXITCODE -ne 0) {
  Start-Process "$pgBin\pg_ctl.exe" -WindowStyle Hidden -ArgumentList @('-D', "`"$pgData`"", '-l', "`"$pgData\server.log`"",
    '-o', '"-p 8090 -c listen_addresses=localhost -c shared_buffers=64MB -c max_connections=30"', 'start')
  for ($i = 0; $i -lt 30; $i++) { Start-Sleep 1; & "$pgBin\pg_isready.exe" -h localhost -p 8090 -q; if ($LASTEXITCODE -eq 0) { break } }
}
$exists = & "$pgBin\psql.exe" -h localhost -p 8090 -U postgres -tAc "select 1 from pg_database where datname='scopeguard_app'"
if (-not $exists) { & "$pgBin\psql.exe" -h localhost -p 8090 -U postgres -c 'create database scopeguard_app' | Out-Null }
Write-Host 'Serverpod database: localhost:8090'

# 3. Optional Flutter web build, then Serverpod
if ($Web) {
  Push-Location $app
  cmd /c "start /belownormal /wait /b $flutter build web --release --base-href / --no-wasm-dry-run > `"$logs\webbuild.log`" 2>&1"
  if (-not (Test-Path 'build\web\main.dart.js')) { Pop-Location; throw 'Flutter web build failed - see logs\webbuild.log' }
  Pop-Location
  $dest = Join-Path $pod 'web\app'
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  Copy-Item -Recurse (Join-Path $app 'build\web') $dest
}
Stop-Pid 'serverpod'
$p = Start-Low 'serverpod' $dart 'run bin/main.dart --apply-migrations' $pod
for ($i = 0; $i -lt 90; $i++) {
  Start-Sleep 2
  if ((Get-Content (Join-Path $logs 'serverpod.out.log') -Raw -ErrorAction SilentlyContinue) -match 'Webserver listening') { break }
  if ($p.HasExited) { throw 'Serverpod stopped - see logs\serverpod.err.log' }
}
$ip = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress
Write-Host ''
Write-Host 'ScopeGuard is running:'
Write-Host '  Website (React):        http://localhost:5173'
Write-Host '  Flutter app (web):      http://localhost:8082'
if ($ip) { Write-Host "  Flutter app on phones:  http://${ip}:8082  (same Wi-Fi; see README for the firewall step)" }
Write-Host '  Serverpod API:          http://localhost:8080'

# 4. Optional public link for phones on any network (college Wi-Fi blocks phone-to-laptop traffic).
if ($Public) {
  Stop-Pid 'tunnel'
  Stop-Pid 'gateway'
  Start-Low 'gateway' 'node.exe' "`"$root\tools\mobile-gateway.mjs`"" $root | Out-Null
  if (-not (Wait-Port 8088 20)) { throw 'Mobile gateway did not start - see logs\gateway.err.log' }
  Start-Low 'tunnel' (Join-Path $root 'tools\cloudflared.exe') 'tunnel --no-autoupdate --protocol http2 --url http://localhost:8088' $root | Out-Null
  $url = $null
  for ($i = 0; $i -lt 45 -and -not $url; $i++) {
    Start-Sleep 1
    # Wait until the tunnel is really connected, not just until a URL is assigned.
    $m = Select-String -Path (Join-Path $logs 'tunnel.err.log') -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -ErrorAction SilentlyContinue | Select-Object -First 1
    $ok = Select-String -Path (Join-Path $logs 'tunnel.err.log') -Pattern 'Registered tunnel connection' -ErrorAction SilentlyContinue
    if ($m -and $ok) { $url = $m.Matches[0].Value }
  }
  if ($url) {
    $url | Set-Content (Join-Path $logs 'public-url.txt')
    Write-Host ''
    Write-Host "  PUBLIC LINK (any phone, any network):  $url" -ForegroundColor Green
    Write-Host '  Anyone with this link can open the app while it runs. Stop it with .\start-all.ps1 -Stop'
  } else {
    Write-Host '  Public link did not come up - see logs\tunnel.err.log' -ForegroundColor Yellow
  }
}
