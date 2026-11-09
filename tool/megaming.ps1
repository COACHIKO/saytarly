# ============================================================
#  SaytarlyMind — Release Control Center (local web app)
#  Runs a small HTTP server on 127.0.0.1 and opens the browser.
#  The page drives tool\release.ps1 (CLI) for builds/upload and
#  talks to the GitHub API directly for release management.
# ============================================================
param([int]$Port = 0, [switch]$NoBrowser)

$ErrorActionPreference = 'Stop'

$script:Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:WebDir = Join-Path $PSScriptRoot 'web'
$script:ExportDir = Join-Path $script:Root 'build_export'
$script:Jobs = @{}
$script:KeepAlive = $true

# ============================ HELPERS ============================
function Get-EnvValue {
  param([string]$Key, [string]$Default = '')
  $envPath = Join-Path $script:Root '.env'
  if (Test-Path -LiteralPath $envPath) {
    foreach ($line in Get-Content -LiteralPath $envPath) {
      $t = $line.Trim()
      if ($t -eq '' -or $t.StartsWith('#')) { continue }
      $i = $t.IndexOf('=')
      if ($i -le 0) { continue }
      if ($t.Substring(0, $i).Trim() -eq $Key) { return $t.Substring($i + 1).Trim() }
    }
  }
  return $Default
}

function Find-Iscc {
  $candidates = @()
  if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe') }
  if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe') }
  if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe') }
  $candidates += 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
  $candidates += 'C:\Program Files\Inno Setup 6\ISCC.exe'
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return ''
}

function Write-Response {
  param($Response, [int]$Code, [string]$ContentType, [string]$Body)
  $Response.StatusCode = $Code
  $Response.ContentType = $ContentType
  $Response.Headers.Add('Access-Control-Allow-Origin', '*')
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
  $Response.ContentLength64 = $bytes.Length
  $Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $Response.Close()
}

function Get-EnvJson {
  $iscc = Find-Iscc
  $payload = @{
    mobileVersion = Get-EnvValue 'MOBILE_VERSION_NUMBER' '1.0.0'
    mobileBuild = Get-EnvValue 'MOBILE_BUILD_NUMBER' '1'
    windowsVersion = Get-EnvValue 'WINDOWS_VERSION_NUMBER' '1.0.0.0'
    windowsBuild = Get-EnvValue 'WINDOWS_BUILD_NUMBER' '1'
    repo = Get-EnvValue 'RELEASES_REPO' ''
    token = Get-EnvValue 'RELEASES_TOKEN' ''
    mode = Get-EnvValue 'APP_MODE' 'online'
    iscc = $iscc
    isccFound = ($iscc -ne '')
    exportDir = $script:ExportDir
  }
  return $payload | ConvertTo-Json -Depth 5
}

# ============================ LISTENER ============================
$listener = $null
$port = $Port
if ($port -le 0) { $port = 4570 }

for ($attempt = 0; $attempt -lt 10; $attempt++) {
  $l = New-Object System.Net.HttpListener
  try {
    $l.Prefixes.Add("http://127.0.0.1:$port/")
    $l.Start()
    $listener = $l
    break
  } catch {
    $l.Close()
    $port++
  }
}
if (-not $listener) {
  Write-Host 'SaytarlyMind: could not open a local port.'
  exit 1
}

Write-Host ''
Write-Host '  SAYTARLYMIND Release Control Center'
Write-Host "  Running at http://127.0.0.1:$port/  (browser opened automatically)"
Write-Host '  Press Ctrl+C in this window, or use the Shutdown button, to stop.'
Write-Host ''

if (-not $NoBrowser) {
  Start-Process "http://127.0.0.1:$port/"
}

while ($script:KeepAlive) {
  $ctx = $null
  try {
    $ctx = $listener.GetContext()
  } catch {
    if (-not $script:KeepAlive) { break }
    Start-Sleep -Milliseconds 200
    continue
  }

  $req = $ctx.Request
  $res = $ctx.Response
  $path = $req.Url.AbsolutePath

  try {
    if ($path -eq '/' -or $path -eq '/index.html') {
      $html = [System.IO.File]::ReadAllText((Join-Path $script:WebDir 'index.html'), [System.Text.UTF8Encoding]::new($false))
      Write-Response -Response $res -Code 200 -ContentType 'text/html; charset=utf-8' -Body $html
    }
    elseif ($path -eq '/api/env') {
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (Get-EnvJson)
    }
    elseif ($path -eq '/api/build' -and $req.HttpMethod -eq 'POST') {
      $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd()
      $data = $body | ConvertFrom-Json
      $id = [guid]::NewGuid().ToString('N').Substring(0, 8)
      if (-not (Test-Path -LiteralPath $script:ExportDir)) {
        New-Item -ItemType Directory -Path $script:ExportDir | Out-Null
      }
      $paramsFile = Join-Path $script:ExportDir ".megaming_$id.json"
      $payload = @{
        platform = "$($data.platform)"
        version = "$($data.version)"
        build = [int]$data.build
        action = "$($data.action)"
        upload = [bool]$data.upload
        releaseName = "$($data.releaseName)"
        notes = "$($data.notes)"
        iscc = "$($data.iscc)"
        createOnly = [bool]$data.createOnly
        noBuild = [bool]$data.noBuild
        mode = "$($data.mode)"
      } | ConvertTo-Json -Depth 5
      [System.IO.File]::WriteAllText($paramsFile, $payload, (New-Object System.Text.UTF8Encoding($false)))

      $logFile = Join-Path $script:ExportDir ".megaming_$id.log"
      $releaseScript = Join-Path $PSScriptRoot 'release.ps1'
      $psi = New-Object System.Diagnostics.ProcessStartInfo
      $psi.FileName = 'cmd.exe'
      $psi.Arguments = "/c powershell -NoProfile -ExecutionPolicy Bypass -File `"$releaseScript`" -Cli -ParamsFile `"$paramsFile`" > `"$logFile`" 2>&1"
      $psi.UseShellExecute = $false
      $psi.CreateNoWindow = $true
      $proc = New-Object System.Diagnostics.Process
      $proc.StartInfo = $psi
      [void]$proc.Start()
      $script:Jobs[$id] = @{
        Proc = $proc
        Started = Get-Date
        Platform = "$($data.platform)"
        Version = "$($data.version)"
        Action = "$($data.action)"
      }
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (@{ id = $id } | ConvertTo-Json)
    }
    elseif ($path -eq '/api/log') {
      $id = $req.QueryString['id']
      $logFile = Join-Path $script:ExportDir ".megaming_$id.log"
      $text = ''
      if (Test-Path -LiteralPath $logFile) {
        $text = [System.IO.File]::ReadAllText($logFile, [System.Text.UTF8Encoding]::new($false))
      }
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (@{ text = $text } | ConvertTo-Json)
    }
    elseif ($path -eq '/api/status') {
      $id = $req.QueryString['id']
      $job = $script:Jobs[$id]
      $running = $false
      $exitCode = 0
      if ($job) {
        $job.Proc.Refresh()
        $running = -not $job.Proc.HasExited
        if (-not $running) { $exitCode = $job.Proc.ExitCode }
      }
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (@{ running = $running; exitCode = $exitCode } | ConvertTo-Json)
    }
    elseif ($path -eq '/api/jobs') {
      # ملحوظة: المتغير اسمه jobList مش jobs — عشان PowerShell مش بيفرق
      # بين حالة الحروف، و$jobs كانت بتدوس على $script:Jobs!
      $jobList = @()
      foreach ($key in @($script:Jobs.Keys)) {
        $job = $script:Jobs[$key]
        $job.Proc.Refresh()
        $jobList += @{
          id = $key
          running = (-not $job.Proc.HasExited)
          exitCode = if ($job.Proc.HasExited) { $job.Proc.ExitCode } else { 0 }
          started = $job.Started.ToString('o')
          platform = $job.Platform
          version = $job.Version
          action = $job.Action
        }
      }
      $lock = @{ active = $false; pid = 0; ownerAlive = $false }
      $lockFile = Join-Path $script:ExportDir '.build.lock'
      if (Test-Path -LiteralPath $lockFile) {
        $lock.active = $true
        try {
          $txt = [System.IO.File]::ReadAllText($lockFile).Trim()
          if ($txt -match '^\d+$') {
            $lock.pid = [int]$txt
            $lock.ownerAlive = $null -ne (Get-Process -Id $lock.pid -ErrorAction SilentlyContinue)
          } else {
            # بصيغة قديمة (من غير PID) — نعتبرها شغالة إلا لو قديمة بكتير
            $lockAge = (Get-Date) - (Get-Item -LiteralPath $lockFile).LastWriteTime
            $lock.ownerAlive = $lockAge.TotalMinutes -lt 30
          }
        } catch {
          $lock.ownerAlive = $false
        }
      }
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (@{ jobs = $jobList; lock = $lock } | ConvertTo-Json -Depth 5)
    }
    elseif ($path -eq '/api/cancel' -and $req.HttpMethod -eq 'POST') {
      $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd()
      $data = $body | ConvertFrom-Json
      $id = "$($data.id)"
      $job = $script:Jobs[$id]
      $killed = $false
      if ($job -and -not $job.Proc.HasExited) {
        $pidToKill = $job.Proc.Id
        $null = & cmd.exe /c "taskkill /PID $pidToKill /T /F" 2>&1
        $job.Proc.Refresh()
        $killed = $job.Proc.HasExited
      }
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (@{ killed = $killed } | ConvertTo-Json)
    }
    elseif ($path -eq '/api/stop') {
      Write-Response -Response $res -Code 200 -ContentType 'application/json; charset=utf-8' -Body (@{ ok = $true } | ConvertTo-Json)
      $script:KeepAlive = $false
    }
    else {
      Write-Response -Response $res -Code 404 -ContentType 'application/json; charset=utf-8' -Body (@{ error = 'not found' } | ConvertTo-Json)
    }
  } catch {
    try { Write-Response -Response $res -Code 500 -ContentType 'application/json; charset=utf-8' -Body (@{ error = $_.Exception.Message; stack = $_.ScriptStackTrace } | ConvertTo-Json) } catch {}
  }
}

$listener.Stop()
$listener.Close()
