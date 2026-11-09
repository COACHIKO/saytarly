# ============================================================
#  Saytarly Release Builder
#  Runs:  powershell -ExecutionPolicy Bypass -File tool\release.ps1
#
#  GUI mode (default): choose Mobile/Desktop, edit versions &
#  build numbers, pick outputs (apk / installer / zip), optional
#  GitHub release upload + release management.
#
#  CLI mode (for CI / automation):
#    -Cli -Platform windows -Version 2.1.1.0 -Build 43
#         -Action installerzip [-Upload] [-IncreaseBuild] [-NoBuild]
#    -Cli -Platform mobile -Version 1.2.9 -Action apkzip [-Upload]
#    -Cli -CheckGithub
# ============================================================
param(
  [switch]$Cli,
  [string]$Platform = '',
  [string]$Version = '',
  [int]$Build = -1,
  [string]$Action = '',
  [switch]$IncreaseBuild,
  [switch]$Upload,
  [switch]$NoBuild,
  [string]$ReleaseName = '',
  [string]$Notes = '',
  [switch]$CheckGithub,
  [string]$ParamsFile = '',
  [string]$IsccPath = '',
  [switch]$CreateOnly,
  [switch]$EnsureInno,
  [string]$Mode = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:EnvPath = Join-Path $script:RepoRoot '.env'
$script:PubspecPath = Join-Path $script:RepoRoot 'pubspec.yaml'
$script:VersionInfoPath = Join-Path $script:RepoRoot 'lib\core\updater\version_info.dart'
$script:UpdateConfigPath = Join-Path $script:RepoRoot 'lib\core\updater\update_config.dart'
$script:ExportDir = Join-Path $script:RepoRoot 'build_export'
$script:LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$script:DirectLog = $false

# ============================ LOG ============================
function Add-Log {
  param([string]$Message)
  $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
  if ($script:DirectLog) {
    Write-Host $line
    [Console]::Out.Flush()
  } else {
    $script:LogQueue.Enqueue($line)
  }
}

# ============================ ENV ============================
function Get-EnvMap {
  $map = @{}
  if (Test-Path $script:EnvPath) {
    foreach ($line in Get-Content -LiteralPath $script:EnvPath) {
      $t = $line.Trim()
      if ($t -eq '' -or $t.StartsWith('#')) { continue }
      $i = $t.IndexOf('=')
      if ($i -le 0) { continue }
      $map[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim()
    }
  }
  return $map
}

function Save-EnvFile {
  param(
    [string]$MobileVersion,
    [string]$MobileBuild,
    [string]$WindowsVersion,
    [string]$WindowsBuild,
    [string]$GithubToken,
    [string]$ReleasesRepo,
    [string]$ReleasesToken,
    [string]$AppMode
  )
  $mode = $AppMode.ToLower()
  if ($mode -ne 'offline') { $mode = 'online' }
  $content = @"
# --- App Version ---
MOBILE_VERSION_NUMBER=$MobileVersion
MOBILE_BUILD_NUMBER=$MobileBuild
WINDOWS_VERSION_NUMBER=$WindowsVersion
WINDOWS_BUILD_NUMBER=$WindowsBuild

# --- App Mode: online | offline ---
# online  = GitHub updates + device registration/licenses
# offline = no cloud services at all
APP_MODE=$mode

# --- GitHub Auto-Update Configuration ---
# Personal Access Token with read permissions for private GitHub repository
GITHUB_TOKEN=$GithubToken

# --- Self-Update (releases repository) ---
RELEASES_REPO=$ReleasesRepo
RELEASES_TOKEN=$ReleasesToken
"@
  [System.IO.File]::WriteAllText($script:EnvPath, $content, (New-Object System.Text.UTF8Encoding($false)))
}

# ============================ FILES ============================
function Update-PubspecVersion {
  param([string]$Version, [string]$BuildNumber)
  # قراءة وكتابة UTF-8 صريحة — Get-Content الافتراضي بيقرا ANSI وبيكسّر
  # النصوص العربية (والملف بيكبر كل مرة لدرجة تكسير الذاكرة)
  $content = [System.IO.File]::ReadAllText(
    $script:PubspecPath,
    [System.Text.UTF8Encoding]::new($false)
  )
  $content = [regex]::Replace($content, '(?m)^version:\s*.*$', "version: $Version+$BuildNumber")
  [System.IO.File]::WriteAllText($script:PubspecPath, $content, (New-Object System.Text.UTF8Encoding($false)))
  Add-Log "pubspec.yaml -> version: $Version+$BuildNumber"
}

function Update-VersionInfoDart {
  param(
    [string]$MobileVersion,
    [string]$MobileBuild,
    [string]$WindowsVersion,
    [string]$WindowsBuild
  )
  $content = @"
// GENERATED FILE — rewritten by tool/release.ps1 before every build.
// Do not edit by hand.
//
/// نسخة التطبيق الحالية اللي بتتظبط من `.env` وقت البناء.
class VersionInfo {
  VersionInfo._();

  /// نسخة الموبايل (Android) — بتتقارن بـ tags اللي بتبدأ بـ `mobile-`.
  static const String mobileVersion = '$MobileVersion';

  /// رقم بناء الموبايل (= Android versionCode).
  static const int mobileBuildNumber = $MobileBuild;

  /// نسخة الويندوز (4 أجزاء) — بتتقارن بـ tags اللي بتبدأ بـ `windows-`.
  static const String windowsVersion = '$WindowsVersion';

  /// رقم بناء الويندوز (بيستخدم كرابع جزء في خصائص الملف).
  static const int windowsBuildNumber = $WindowsBuild;
}
"@
  [System.IO.File]::WriteAllText($script:VersionInfoPath, $content, (New-Object System.Text.UTF8Encoding($false)))
  Add-Log 'lib/core/updater/version_info.dart updated'
}

function Update-UpdateConfigDart {
  param([string]$ReleasesRepo, [string]$ReleasesToken)
  $tokenLiteral = $ReleasesToken.Replace("'", "\'")
  $content = @"
// GENERATED FILE — rewritten by tool/release.ps1 before every build.
// Do not edit by hand.
//
/// إعدادات الاتصال بريبو التحديثات على GitHub.
///
/// القيم بتتاخد من ملف `.env` وقت البناء (`RELEASES_REPO` و `RELEASES_TOKEN`).
class UpdateConfig {
  UpdateConfig._();

  /// المستودع بصيغة `owner/repo`.
  static const String repo = '$ReleasesRepo';

  /// Personal Access Token للوصول للريبو الخاص.
  static const String token =
      '$tokenLiteral';

  /// اسم ملف الـ zip اللي بيستخدمه التحديث الذاتي على ويندوز.
  static const String windowsAssetName = 'saytarly_windows';
}
"@
  [System.IO.File]::WriteAllText($script:UpdateConfigPath, $content, (New-Object System.Text.UTF8Encoding($false)))
  Add-Log 'lib/core/updater/update_config.dart updated'
}

function Update-AppModeDart {
  param([string]$AppMode)
  $mode = $AppMode.ToLower()
  if ($mode -ne 'offline') { $mode = 'online' }
  $isOnline = if ($mode -eq 'online') { 'true' } else { 'false' }
  $isOffline = if ($mode -eq 'offline') { 'true' } else { 'false' }
  $appModePath = Join-Path $script:RepoRoot 'lib\core\updater\app_mode.dart'
  $content = @"
// GENERATED FILE — rewritten by tool/release.ps1 before every build.
// Do not edit by hand.
//
/// وضع التطبيق — بيتاخد من `.env` (`APP_MODE`) وقت البناء.
///
/// `online`  = التحديثات من GitHub + تسجيل الأجهزة والتراخيص.
/// `offline` = من غير أي خدمات سحابية (مفيش تحديثات ولا تسجيل أجهزة).
class AppMode {
  AppMode._();

  static const String mode = '$mode';

  static const bool isOnline = $isOnline;
  static const bool isOffline = $isOffline;
}
"@
  [System.IO.File]::WriteAllText($appModePath, $content, (New-Object System.Text.UTF8Encoding($false)))
  Add-Log "lib/core/updater/app_mode.dart -> $mode"
}

function Test-VersionFormat {
  param([string]$Version)
  return $Version -match '^\d+(\.\d+){0,3}$'
}

function Get-SemverParts {
  param([string]$Version)
  $parts = $Version.Split('.')
  $major = [int]$parts[0]
  $minor = if ($parts.Length -ge 2) { [int]$parts[1] } else { 0 }
  $patch = if ($parts.Length -ge 3) { [int]$parts[2] } else { 0 }
  return "$major.$minor.$patch"
}

function Update-RunnerRc {
  param([string]$Version, [string]$BuildNumber)
  $rc = Join-Path $script:RepoRoot 'windows\runner\Runner.rc'
  $content = [System.IO.File]::ReadAllText($rc, [System.Text.UTF8Encoding]::new($false))
  $semver = Get-SemverParts -Version $Version
  $numbers = ($semver -replace '\.', ',') + ",$BuildNumber"
  $stringVersion = "$semver.$BuildNumber"
  $blockPattern = '(?s)#if defined\(FLUTTER_VERSION_MAJOR\).*?VERSION_AS_STRING "1\.0\.0"\r?\n#endif'
  if ($content -match $blockPattern) {
    # القالب الأصلي بتاع Flutter — استبدل الكتلة كلها بقيم ثابتة
    $new = [regex]::Replace($content, $blockPattern, "#define VERSION_AS_NUMBER $numbers`r`n#define VERSION_AS_STRING `"$stringVersion`"")
  } else {
    # الملف اتحدّث قبل كده — عدّل السطرين مباشرة
    $new = [regex]::Replace($content, '(?m)^#define VERSION_AS_NUMBER .*$', "#define VERSION_AS_NUMBER $numbers")
    $new = [regex]::Replace($new, '(?m)^#define VERSION_AS_STRING .*$', "#define VERSION_AS_STRING `"$stringVersion`"")
  }
  if ($new -eq $content) {
    Add-Log 'windows/runner/Runner.rc already up to date'
    return
  }
  [System.IO.File]::WriteAllText($rc, $new, (New-Object System.Text.UTF8Encoding($false)))
  Add-Log "windows/runner/Runner.rc -> $stringVersion"
}

function Copy-VcRuntimeDlls {
  param([string]$ReleaseDir)
  # Flutter 3.24+ مبقاش يضم DLLs الـ VC++ runtime في البناء — بنحطها
  # جنب الـ exe عشان التطبيق يشتغل على أي ويندوز من غير redist مثبت.
  $sys = Join-Path $env:SystemRoot 'System32'
  $names = @(
    'vcruntime140.dll', 'vcruntime140_1.dll', 'vcruntime140_2.dll',
    'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll',
    'msvcp140_atomic_wait.dll', 'msvcp140_codecvt_ids.dll',
    'concrt140.dll'
  )
  $copied = 0
  foreach ($n in $names) {
    $src = Join-Path $sys $n
    if (Test-Path -LiteralPath $src) {
      Copy-Item -LiteralPath $src -Destination (Join-Path $ReleaseDir $n) -Force
      $copied++
    }
  }
  Add-Log "VC++ runtime DLLs bundled: $copied"
}

# ============================ TOOLS ============================
function Find-InnoSetup {
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

function Ensure-InnoSetup {
  param([string]$IsccPath)
  if ($IsccPath -and (Test-Path -LiteralPath $IsccPath)) { return $IsccPath }
  $found = Find-InnoSetup
  if ($found) { return $found }

  Add-Log 'Inno Setup not found — downloading & installing it silently...'
  $installer = Join-Path $env:TEMP 'innosetup_installer.exe'
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri 'https://jrsoftware.org/download.php/is.exe' -OutFile $installer -UseBasicParsing
  } catch {
    throw "Failed to download Inno Setup: $($_.Exception.Message)"
  }
  $proc = Start-Process -FilePath $installer -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/SP-','/CURRENTUSER' -Wait -PassThru
  Add-Log "Inno Setup installer exit code: $($proc.ExitCode)"
  $found = Find-InnoSetup
  if ($found) { return $found }
  throw 'Inno Setup (ISCC.exe) not found — install it manually from https://jrsoftware.org/isdl.php'
}

# ============================ BUILD ============================
function Start-FlutterBuild {
  param([string]$Arguments)
  Add-Log "flutter $Arguments"
  # عبر cmd عشان الـ stderr يتدمج في stdout وميوقفش التنفيذ
  $output = & cmd.exe /c "flutter $Arguments 2>&1"
  foreach ($line in $output) { Add-Log ($line.ToString()) }
  return $LASTEXITCODE
}

function Build-Mobile {
  param(
    [string]$Version,
    [string]$BuildNumber,
    [bool]$MakeZip,
    [bool]$SkipFlutterBuild
  )
  $pubVersion = Get-SemverParts -Version $Version
  Update-PubspecVersion -Version $pubVersion -BuildNumber $BuildNumber
  $envMap = Get-EnvMap
  Update-VersionInfoDart -MobileVersion $Version -MobileBuild $BuildNumber `
    -WindowsVersion $envMap['WINDOWS_VERSION_NUMBER'] -WindowsBuild $envMap['WINDOWS_BUILD_NUMBER']
  Update-UpdateConfigDart -ReleasesRepo $envMap['RELEASES_REPO'] -ReleasesToken $envMap['RELEASES_TOKEN']
  Update-AppModeDart -AppMode $envMap['APP_MODE']

  $apkSource = Join-Path $script:RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
  $apkName = "saytarly_mobile_${Version}_build${BuildNumber}.apk"
  $apkTarget = Join-Path $script:ExportDir $apkName

  if (-not $SkipFlutterBuild) {
    if (-not (Test-Path $script:ExportDir)) { New-Item -ItemType Directory -Path $script:ExportDir | Out-Null }
    $code = Start-FlutterBuild -Arguments 'build apk --release'
    if ($code -ne 0) { throw "flutter build apk failed (exit $code)" }
    if (-not (Test-Path -LiteralPath $apkSource)) { throw 'APK output not found' }
    Copy-Item -LiteralPath $apkSource -Destination $apkTarget -Force
    Add-Log "APK copied -> build_export\$apkName"
  }

  if ($MakeZip -and (Test-Path -LiteralPath $apkTarget)) {
    $zipPath = Join-Path $script:ExportDir "saytarly_mobile_${Version}_build${BuildNumber}.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path $apkTarget -DestinationPath $zipPath -CompressionLevel Optimal -Force
    Add-Log "ZIP created -> build_export\$(Split-Path $zipPath -Leaf)"
  }
  return @{ Apk = $apkTarget; Zip = if ($MakeZip) { Join-Path $script:ExportDir "saytarly_mobile_${Version}_build${BuildNumber}.zip" } else { '' } }
}

function Build-Windows {
  param(
    [string]$Version,
    [string]$BuildNumber,
    [bool]$MakeInstaller,
    [bool]$MakeZip,
    [string]$IsccPath,
    [bool]$SkipFlutterBuild
  )
  $pubVersion = Get-SemverParts -Version $Version
  Update-PubspecVersion -Version $pubVersion -BuildNumber $BuildNumber
  Update-RunnerRc -Version $Version -BuildNumber $BuildNumber
  $envMap = Get-EnvMap
  Update-VersionInfoDart -MobileVersion $envMap['MOBILE_VERSION_NUMBER'] -MobileBuild $envMap['MOBILE_BUILD_NUMBER'] `
    -WindowsVersion $Version -WindowsBuild $BuildNumber
  Update-UpdateConfigDart -ReleasesRepo $envMap['RELEASES_REPO'] -ReleasesToken $envMap['RELEASES_TOKEN']
  Update-AppModeDart -AppMode $envMap['APP_MODE']

  $releaseDir = Join-Path $script:RepoRoot 'build\windows\x64\runner\Release'
  $installerPath = ''
  $zipPath = ''

  if (-not $SkipFlutterBuild) {
    if (-not (Test-Path $script:ExportDir)) { New-Item -ItemType Directory -Path $script:ExportDir | Out-Null }
    $code = Start-FlutterBuild -Arguments 'build windows --release'
    if ($code -ne 0) { throw "flutter build windows failed (exit $code)" }
    if (-not (Test-Path -LiteralPath (Join-Path $releaseDir 'saytarly.exe'))) { throw 'Windows release output not found' }
  }

  # خطوة مهمة: ضمّ DLLs الـ VC++ runtime جنب الـ exe — عشان التطبيق
  # يشتغل على أجهزة ما عليهاش Visual C++ Redistributable.
  if (Test-Path -LiteralPath $releaseDir) {
    Copy-VcRuntimeDlls -ReleaseDir $releaseDir
  }

  if ($MakeInstaller) {
    $IsccPath = Ensure-InnoSetup -IsccPath $IsccPath
    $issFile = Join-Path $PSScriptRoot 'installer.iss'
    Add-Log "Inno Setup -> $IsccPath"
    $cmd = "`"$IsccPath`" /DMyAppVersion=$Version /DMyAppBuild=$BuildNumber /DMyAppOutputDir=$script:ExportDir `"$issFile`" 2>&1"
    $output = & cmd.exe /c $cmd
    foreach ($line in $output) { Add-Log ($line.ToString()) }
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compile failed' }
    $installerPath = Join-Path $script:ExportDir "saytarly_windows_${Version}_setup.exe"
    if (-not (Test-Path -LiteralPath $installerPath)) { throw 'Installer output not found' }
  }

  if ($MakeZip) {
    if (-not (Test-Path -LiteralPath $releaseDir)) { throw 'Release folder not found — build first' }
    $zipPath = Join-Path $script:ExportDir "saytarly_windows_${Version}.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force
    Add-Log "ZIP created -> build_export\$(Split-Path $zipPath -Leaf)"
  }
  return @{ Installer = $installerPath; Zip = $zipPath }
}

# ============================ GITHUB ============================
function Get-GithubHeaders {
  param([string]$Token)
  return @{
    'Authorization' = "Bearer $Token"
    'Accept' = 'application/vnd.github+json'
    'User-Agent' = 'saytarly-release-tool'
  }
}

function Send-GithubJson {
  param(
    [string]$Method,
    [string]$Uri,
    [hashtable]$Headers,
    [hashtable]$BodyMap
  )
  # بنبعت الـ JSON كـ UTF-8 bytes — عشان النصوص العربية والرموز
  # ماتبوظش (Invoke-RestMethod في PS 5.1 بيحول النص لـ Latin-1)
  $json = $BodyMap | ConvertTo-Json -Depth 5
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body $bytes -ContentType 'application/json; charset=utf-8'
}

function Test-GithubConnection {
  param([string]$Repo, [string]$Token)
  try {
    $headers = Get-GithubHeaders -Token $Token
    $null = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo" -Headers $headers -Method Get
    return $true
  } catch {
    Add-Log "GitHub error: $($_.Exception.Message)"
    return $false
  }
}

function Get-GithubReleaseByTag {
  param([string]$Repo, [string]$Token, [string]$Tag)
  try {
    $headers = Get-GithubHeaders -Token $Token
    return Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/tags/$Tag" -Headers $headers -Method Get
  } catch {
    return $null
  }
}

function New-Or-Update-GithubRelease {
  param(
    [string]$Repo,
    [string]$Token,
    [string]$Tag,
    [string]$Name,
    [string]$Body,
    [bool]$ReplaceIfExists
  )
  $headers = Get-GithubHeaders -Token $Token
  $existing = Get-GithubReleaseByTag -Repo $Repo -Token $Token -Tag $Tag
  $payload = @{ tag_name = $Tag; name = $Name; body = $Body; draft = $false; prerelease = $false }
  if ($existing) {
    if ($ReplaceIfExists) {
      $release = Send-GithubJson -Method Patch -Uri "https://api.github.com/repos/$Repo/releases/$($existing.id)" -Headers $headers -BodyMap $payload
      Add-Log "Release updated -> $Tag"
    } else {
      Add-Log "Release $Tag exists and ReplaceIfExists is off — reusing it."
      $release = $existing
    }
  } else {
    $release = Send-GithubJson -Method Post -Uri "https://api.github.com/repos/$Repo/releases" -Headers $headers -BodyMap $payload
    Add-Log "Release created -> $Tag"
  }
  return $release
}

function Set-GithubReleaseAsset {
  param([string]$Repo, [string]$Token, [object]$Release, [string]$FilePath)
  $headers = Get-GithubHeaders -Token $Token
  $fileName = Split-Path $FilePath -Leaf
  # delete existing asset with the same name
  foreach ($asset in $Release.assets) {
    if ($asset.name -eq $fileName) {
      Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/assets/$($asset.id)" -Headers $headers -Method Delete | Out-Null
      Add-Log "Old asset removed -> $fileName"
    }
  }
  $uri = "https://uploads.github.com/repos/$Repo/releases/$($Release.id)/assets?name=$fileName"
  $webHeaders = Get-GithubHeaders -Token $Token
  $webHeaders['Content-Type'] = 'application/octet-stream'
  Invoke-WebRequest -Uri $uri -Headers $webHeaders -Method Post -InFile $FilePath -UseBasicParsing | Out-Null
  Add-Log "Asset uploaded -> $fileName"
}

function Get-GithubReleases {
  param([string]$Repo, [string]$Token)
  $headers = Get-GithubHeaders -Token $Token
  return Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=30" -Headers $headers -Method Get
}

function Update-GithubReleaseNotes {
  param([string]$Repo, [string]$Token, [int]$ReleaseId, [string]$Name, [string]$Body)
  $headers = Get-GithubHeaders -Token $Token
  $payload = @{ name = $Name; body = $Body }
  Send-GithubJson -Method Patch -Uri "https://api.github.com/repos/$Repo/releases/$ReleaseId" -Headers $headers -BodyMap $payload | Out-Null
}

function Remove-GithubRelease {
  param([string]$Repo, [string]$Token, [int]$ReleaseId)
  $headers = Get-GithubHeaders -Token $Token
  Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/$ReleaseId" -Headers $headers -Method Delete | Out-Null
}

function Invoke-UploadStep {
  param(
    [string]$PlatformType,
    [string]$Version,
    [string]$BuildNumber,
    [string]$ZipPath,
    [string]$ApkPath,
    [string]$Repo,
    [string]$Token,
    [string]$Name,
    [string]$Body,
    [bool]$ReplaceIfExists
  )
  if (-not (Test-GithubConnection -Repo $Repo -Token $Token)) {
    throw 'GitHub connection failed — check RELEASES_REPO / RELEASES_TOKEN in .env'
  }
  $tag = if ($PlatformType -eq 'windows') { "windows-$Version" } else { "mobile-$Version" }
  if (-not $Name) {
    $Name = if ($PlatformType -eq 'windows') { "Saytarly Windows $Version" } else { "Saytarly Mobile $Version (build $BuildNumber)" }
  }
  if (-not $Body) {
    $Body = "Saytarly $PlatformType release`n`n- version: $Version`n- build: $BuildNumber"
  }
  $release = New-Or-Update-GithubRelease -Repo $Repo -Token $Token -Tag $tag -Name $Name -Body $Body -ReplaceIfExists $ReplaceIfExists
  if ($ZipPath -and (Test-Path -LiteralPath $ZipPath)) {
    Set-GithubReleaseAsset -Repo $Repo -Token $Token -Release $release -FilePath $ZipPath
  } elseif ($ApkPath -and (Test-Path -LiteralPath $ApkPath)) {
    Set-GithubReleaseAsset -Repo $Repo -Token $Token -Release $release -FilePath $ApkPath
  }
  Add-Log "GitHub release ready: $tag"
}

# ============================ PIPELINE ============================
function Invoke-ReleasePipeline {
  param(
    [string]$PlatformType,
    [string]$Version,
    [int]$BuildNumber,
    [string]$ActionName,
    [string]$IsccPath,
    [bool]$DoUpload,
    [string]$ReleaseName,
    [string]$ReleaseNotes,
    [bool]$ReplaceIfExists,
    [bool]$SkipBuild
  )
  # قفل بناء — مفيش بنائين في نفس الوقت (بيحمي pubspec.yaml من الكتابة المتزامنة).
  # لو في بناء شغال: بيمسح القفل لو صاحبه مات، أو بيستنى (حد أقصى 15 دقيقة)
  # وبعدين يكمل — بدل ما يرفض فورًا.
  if (-not (Test-Path -LiteralPath $script:ExportDir)) {
    New-Item -ItemType Directory -Path $script:ExportDir | Out-Null
  }
  $lockFile = Join-Path $script:ExportDir '.build.lock'
  $lockDeadline = (Get-Date).AddMinutes(15)
  $announced = $false
  while (Test-Path -LiteralPath $lockFile) {
    # لو اللي حاطط القفل خلص/مات — نمسح القفل ونكمل
    $ownerAlive = $true
    try {
      $lockText = [System.IO.File]::ReadAllText($lockFile).Trim()
      if ($lockText -match '^\d+$') {
        $ownerAlive = $null -ne (Get-Process -Id ([int]$lockText) -ErrorAction SilentlyContinue)
      }
    } catch {
      $ownerAlive = $false
    }
    if (-not $ownerAlive) {
      Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
      continue
    }
    # لو القفل قديم بكتير (بصيغة قديمة من غير PID) — نعتبره متعلق ونشيله
    try {
      $lockAge = (Get-Date) - (Get-Item -LiteralPath $lockFile).LastWriteTime
      if ($lockAge.TotalMinutes -gt 30 -and -not ($lockText -match '^\d+$')) {
        Add-Log 'Stale lock detected — cleaning it up.'
        Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
        continue
      }
    } catch {}
    if ((Get-Date) -gt $lockDeadline) {
      throw 'Another build is still running for too long — try again later.'
    }
    if (-not $announced) {
      Add-Log 'A build is already running — waiting for it to finish...'
      $announced = $true
    }
    Start-Sleep -Seconds 5
  }
  [System.IO.File]::WriteAllText($lockFile, "$PID")
  try {
    Invoke-ReleasePipelineInner -PlatformType $PlatformType -Version $Version -BuildNumber $BuildNumber `
      -ActionName $ActionName -IsccPath $IsccPath -DoUpload $DoUpload -ReleaseName $ReleaseName `
      -ReleaseNotes $ReleaseNotes -ReplaceIfExists $ReplaceIfExists -SkipBuild $SkipBuild
  } finally {
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-ReleasePipelineInner {
  param(
    [string]$PlatformType,
    [string]$Version,
    [int]$BuildNumber,
    [string]$ActionName,
    [string]$IsccPath,
    [bool]$DoUpload,
    [string]$ReleaseName,
    [string]$ReleaseNotes,
    [bool]$ReplaceIfExists,
    [bool]$SkipBuild
  )
  $envMap = Get-EnvMap
  $mobileVersion = $envMap['MOBILE_VERSION_NUMBER']
  $mobileBuild = $envMap['MOBILE_BUILD_NUMBER']
  $windowsVersion = $envMap['WINDOWS_VERSION_NUMBER']
  $windowsBuild = $envMap['WINDOWS_BUILD_NUMBER']
  $appMode = $envMap['APP_MODE']
  if (-not $appMode) { $appMode = 'online' }
  if ($script:ModeOverride) { $appMode = $script:ModeOverride }

  if ($PlatformType -eq 'mobile') {
    $mobileVersion = $Version
    if ($BuildNumber -ge 0) { $mobileBuild = $BuildNumber }
  } else {
    $windowsVersion = $Version
    if ($BuildNumber -ge 0) { $windowsBuild = $BuildNumber }
  }

  Save-EnvFile -MobileVersion $mobileVersion -MobileBuild "$mobileBuild" `
    -WindowsVersion $windowsVersion -WindowsBuild "$windowsBuild" `
    -GithubToken $envMap['GITHUB_TOKEN'] -ReleasesRepo $envMap['RELEASES_REPO'] -ReleasesToken $envMap['RELEASES_TOKEN'] `
    -AppMode $appMode
  Add-Log '.env updated'

  $zipPath = ''
  $apkPath = ''
  if ($PlatformType -eq 'mobile') {
    $makeZip = $ActionName -eq 'apkzip'
    $result = Build-Mobile -Version $mobileVersion -BuildNumber "$mobileBuild" -MakeZip $makeZip -SkipFlutterBuild $SkipBuild
    $apkPath = $result.Apk
    $zipPath = $result.Zip
  } else {
    $makeInstaller = $ActionName -eq 'installer' -or $ActionName -eq 'installerzip'
    $makeZip = $ActionName -eq 'zip' -or $ActionName -eq 'installerzip'
    $result = Build-Windows -Version $windowsVersion -BuildNumber "$windowsBuild" -MakeInstaller $makeInstaller -MakeZip $makeZip -IsccPath $IsccPath -SkipFlutterBuild $SkipBuild
    $zipPath = $result.Zip
  }

  if ($DoUpload) {
    try {
      Invoke-UploadStep -PlatformType $PlatformType -Version $(if ($PlatformType -eq 'windows') { $windowsVersion } else { $mobileVersion }) `
        -BuildNumber $(if ($PlatformType -eq 'windows') { "$windowsBuild" } else { "$mobileBuild" }) `
        -ZipPath $zipPath -ApkPath $apkPath -Repo $envMap['RELEASES_REPO'] -Token $envMap['RELEASES_TOKEN'] `
        -Name $ReleaseName -Body $ReleaseNotes -ReplaceIfExists $ReplaceIfExists
    } catch {
      # الرفع على GitHub اختياري — فشله ميوقفش نجاح البناء
      Add-Log "GitHub upload skipped/failed (artifacts are fine): $($_.Exception.Message)"
    }
  }
  Add-Log 'Done.'
}

# ============================ GUI ============================
function Show-ReleaseGui {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  $envMap = Get-EnvMap

  # قيم افتراضية لو الملف ناقص مفاتيح
  if (-not $envMap['MOBILE_VERSION_NUMBER']) { $envMap['MOBILE_VERSION_NUMBER'] = '1.2.8' }
  if (-not $envMap['MOBILE_BUILD_NUMBER']) { $envMap['MOBILE_BUILD_NUMBER'] = '42' }
  if (-not $envMap['WINDOWS_VERSION_NUMBER']) { $envMap['WINDOWS_VERSION_NUMBER'] = '2.1.0.0' }
  if (-not $envMap['WINDOWS_BUILD_NUMBER']) { $envMap['WINDOWS_BUILD_NUMBER'] = '42' }
  if (-not $envMap['RELEASES_REPO']) { $envMap['RELEASES_REPO'] = 'COACHIKO/saytarly_releases' }

  $form = New-Object System.Windows.Forms.Form
  $form.Text = 'Saytarly Release Builder'
  $form.Size = New-Object System.Drawing.Size(700, 860)
  $form.StartPosition = 'CenterScreen'
  $form.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
  $form.RightToLeftLayout = $true
  $form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)

  $y = 10

  # ── نوع البناء ──
  $grpType = New-Object System.Windows.Forms.GroupBox
  $grpType.Text = 'نوع البناء'
  $grpType.Location = New-Object System.Drawing.Point(12, $y)
  $grpType.Size = New-Object System.Drawing.Size(660, 55)
  $form.Controls.Add($grpType)

  $radMobile = New-Object System.Windows.Forms.RadioButton
  $radMobile.Text = 'موبايل (Android)'
  $radMobile.Location = New-Object System.Drawing.Point(30, 24)
  $radMobile.Size = New-Object System.Drawing.Size(160, 22)
  $radMobile.Checked = $true
  $grpType.Controls.Add($radMobile)

  $radWindows = New-Object System.Windows.Forms.RadioButton
  $radWindows.Text = 'ويندوز (Desktop)'
  $radWindows.Location = New-Object System.Drawing.Point(230, 24)
  $radWindows.Size = New-Object System.Drawing.Size(180, 22)
  $grpType.Controls.Add($radWindows)
  $y += 65

  # ── وضع التطبيق ──
  $grpMode = New-Object System.Windows.Forms.GroupBox
  $grpMode.Text = 'وضع التطبيق'
  $grpMode.Location = New-Object System.Drawing.Point(12, $y)
  $grpMode.Size = New-Object System.Drawing.Size(660, 55)
  $form.Controls.Add($grpMode)

  $radOnline = New-Object System.Windows.Forms.RadioButton
  $radOnline.Text = 'Online — تحديثات GitHub + تسجيل الأجهزة والتراخيص'
  $radOnline.Location = New-Object System.Drawing.Point(220, 24)
  $radOnline.Size = New-Object System.Drawing.Size(400, 22)
  $radOnline.Checked = $true
  $grpMode.Controls.Add($radOnline)

  $radOffline = New-Object System.Windows.Forms.RadioButton
  $radOffline.Text = 'Offline — من غير أي خدمات سحابية'
  $radOffline.Location = New-Object System.Drawing.Point(30, 24)
  $radOffline.Size = New-Object System.Drawing.Size(200, 22)
  $grpMode.Controls.Add($radOffline)

  $envMode = $envMap['APP_MODE']
  if ($envMode -and $envMode.ToLower() -eq 'offline') {
    $radOffline.Checked = $true
    $radOnline.Checked = $false
  }
  $y += 65

  # ── النسخة والبناء ──
  $grpVer = New-Object System.Windows.Forms.GroupBox
  $grpVer.Text = 'النسخة ورقم البناء'
  $grpVer.Location = New-Object System.Drawing.Point(12, $y)
  $grpVer.Size = New-Object System.Drawing.Size(660, 130)
  $form.Controls.Add($grpVer)

  $lblMv = New-Object System.Windows.Forms.Label
  $lblMv.Text = 'نسخة الموبايل:'
  $lblMv.Location = New-Object System.Drawing.Point(520, 28)
  $lblMv.Size = New-Object System.Drawing.Size(110, 20)
  $grpVer.Controls.Add($lblMv)

  $txtMv = New-Object System.Windows.Forms.TextBox
  $txtMv.Text = $envMap['MOBILE_VERSION_NUMBER']
  $txtMv.Location = New-Object System.Drawing.Point(400, 26)
  $txtMv.Size = New-Object System.Drawing.Size(110, 23)
  $grpVer.Controls.Add($txtMv)

  $lblMb = New-Object System.Windows.Forms.Label
  $lblMb.Text = 'بناء الموبايل:'
  $lblMb.Location = New-Object System.Drawing.Point(180, 28)
  $lblMb.Size = New-Object System.Drawing.Size(100, 20)
  $grpVer.Controls.Add($lblMb)

  $txtMb = New-Object System.Windows.Forms.TextBox
  $txtMb.Text = $envMap['MOBILE_BUILD_NUMBER']
  $txtMb.Location = New-Object System.Drawing.Point(60, 26)
  $txtMb.Size = New-Object System.Drawing.Size(110, 23)
  $grpVer.Controls.Add($txtMb)

  $btnMbPlus = New-Object System.Windows.Forms.Button
  $btnMbPlus.Text = '+1'
  $btnMbPlus.Location = New-Object System.Drawing.Point(20, 25)
  $btnMbPlus.Size = New-Object System.Drawing.Size(35, 25)
  $btnMbPlus.Add_Click({
    $txtMb.Text = ([int]$txtMb.Text + 1).ToString()
  })
  $grpVer.Controls.Add($btnMbPlus)

  $lblWv = New-Object System.Windows.Forms.Label
  $lblWv.Text = 'نسخة الويندوز:'
  $lblWv.Location = New-Object System.Drawing.Point(520, 68)
  $lblWv.Size = New-Object System.Drawing.Size(110, 20)
  $grpVer.Controls.Add($lblWv)

  $txtWv = New-Object System.Windows.Forms.TextBox
  $txtWv.Text = $envMap['WINDOWS_VERSION_NUMBER']
  $txtWv.Location = New-Object System.Drawing.Point(400, 66)
  $txtWv.Size = New-Object System.Drawing.Size(110, 23)
  $grpVer.Controls.Add($txtWv)

  $lblWb = New-Object System.Windows.Forms.Label
  $lblWb.Text = 'بناء الويندوز:'
  $lblWb.Location = New-Object System.Drawing.Point(180, 68)
  $lblWb.Size = New-Object System.Drawing.Size(100, 20)
  $grpVer.Controls.Add($lblWb)

  $txtWb = New-Object System.Windows.Forms.TextBox
  $txtWb.Text = $envMap['WINDOWS_BUILD_NUMBER']
  $txtWb.Location = New-Object System.Drawing.Point(60, 66)
  $txtWb.Size = New-Object System.Drawing.Size(110, 23)
  $grpVer.Controls.Add($txtWb)

  $btnWbPlus = New-Object System.Windows.Forms.Button
  $btnWbPlus.Text = '+1'
  $btnWbPlus.Location = New-Object System.Drawing.Point(20, 65)
  $btnWbPlus.Size = New-Object System.Drawing.Size(35, 25)
  $btnWbPlus.Add_Click({
    $txtWb.Text = ([int]$txtWb.Text + 1).ToString()
  })
  $grpVer.Controls.Add($btnWbPlus)

  $lblHint = New-Object System.Windows.Forms.Label
  $lblHint.Text = 'غيّر النسخة أو رقم البناء، أو استخدم +1 لزيادة البناء الحالي.'
  $lblHint.ForeColor = [System.Drawing.Color]::Gray
  $lblHint.Location = New-Object System.Drawing.Point(30, 98)
  $lblHint.Size = New-Object System.Drawing.Size(600, 20)
  $grpVer.Controls.Add($lblHint)
  $y += 140

  # ── المخرجات ──
  $grpOut = New-Object System.Windows.Forms.GroupBox
  $grpOut.Text = 'المخرجات'
  $grpOut.Location = New-Object System.Drawing.Point(12, $y)
  $grpOut.Size = New-Object System.Drawing.Size(660, 120)
  $form.Controls.Add($grpOut)

  $radBuildOnly = New-Object System.Windows.Forms.RadioButton
  $radBuildOnly.Text = 'بناء فقط'
  $radBuildOnly.Location = New-Object System.Drawing.Point(500, 28)
  $radBuildOnly.Size = New-Object System.Drawing.Size(130, 22)
  $radBuildOnly.Checked = $true
  $grpOut.Controls.Add($radBuildOnly)

  $radInstaller = New-Object System.Windows.Forms.RadioButton
  $radInstaller.Text = 'بناء + Installer (Inno Setup)'
  $radInstaller.Location = New-Object System.Drawing.Point(250, 28)
  $radInstaller.Size = New-Object System.Drawing.Size(220, 22)
  $grpOut.Controls.Add($radInstaller)

  $radInstallerZip = New-Object System.Windows.Forms.RadioButton
  $radInstallerZip.Text = 'بناء + Installer + ZIP'
  $radInstallerZip.Location = New-Object System.Drawing.Point(60, 28)
  $radInstallerZip.Size = New-Object System.Drawing.Size(180, 22)
  $grpOut.Controls.Add($radInstallerZip)

  $lblInno = New-Object System.Windows.Forms.Label
  $lblInno.Text = 'مسار ISCC.exe (Inno Setup):'
  $lblInno.Location = New-Object System.Drawing.Point(480, 62)
  $lblInno.Size = New-Object System.Drawing.Size(160, 20)
  $grpOut.Controls.Add($lblInno)

  $txtInno = New-Object System.Windows.Forms.TextBox
  $detectedInno = Find-InnoSetup
  $txtInno.Text = $detectedInno
  $txtInno.Location = New-Object System.Drawing.Point(120, 60)
  $txtInno.Size = New-Object System.Drawing.Size(350, 23)
  $grpOut.Controls.Add($txtInno)

  $btnBrowseInno = New-Object System.Windows.Forms.Button
  $btnBrowseInno.Text = 'استعراض...'
  $btnBrowseInno.Location = New-Object System.Drawing.Point(20, 58)
  $btnBrowseInno.Size = New-Object System.Drawing.Size(90, 27)
  $btnBrowseInno.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'ISCC.exe|ISCC.exe|All files|*.*'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
      $txtInno.Text = $dlg.FileName
    }
  })
  $grpOut.Controls.Add($btnBrowseInno)

  $lblZipNote = New-Object System.Windows.Forms.Label
  $lblZipNote.Text = 'ملحوظة: الموبايل بيتعمل له APK (اختياري مع ZIP) — الـ Installer للويندوز بس.'
  $lblZipNote.ForeColor = [System.Drawing.Color]::Gray
  $lblZipNote.Location = New-Object System.Drawing.Point(30, 94)
  $lblZipNote.Size = New-Object System.Drawing.Size(600, 20)
  $grpOut.Controls.Add($lblZipNote)
  $y += 130

  # ── GitHub ──
  $grpGit = New-Object System.Windows.Forms.GroupBox
  $grpGit.Text = 'GitHub (اختياري)'
  $grpGit.Location = New-Object System.Drawing.Point(12, $y)
  $grpGit.Size = New-Object System.Drawing.Size(660, 220)
  $form.Controls.Add($grpGit)

  $chkUpload = New-Object System.Windows.Forms.CheckBox
  $chkUpload.Text = 'ارفع التحديث على GitHub بعد البناء'
  $chkUpload.Location = New-Object System.Drawing.Point(430, 24)
  $chkUpload.Size = New-Object System.Drawing.Size(220, 22)
  $grpGit.Controls.Add($chkUpload)

  $lblRepo = New-Object System.Windows.Forms.Label
  $lblRepo.Text = 'الريبو:'
  $lblRepo.Location = New-Object System.Drawing.Point(600, 52)
  $lblRepo.Size = New-Object System.Drawing.Size(45, 20)
  $grpGit.Controls.Add($lblRepo)

  $txtRepo = New-Object System.Windows.Forms.TextBox
  $txtRepo.Text = $envMap['RELEASES_REPO']
  $txtRepo.Location = New-Object System.Drawing.Point(380, 50)
  $txtRepo.Size = New-Object System.Drawing.Size(215, 23)
  $grpGit.Controls.Add($txtRepo)

  $btnCheckToken = New-Object System.Windows.Forms.Button
  $btnCheckToken.Text = 'اختبر الاتصال'
  $btnCheckToken.Location = New-Object System.Drawing.Point(240, 48)
  $btnCheckToken.Size = New-Object System.Drawing.Size(120, 27)
  $btnCheckToken.Add_Click({
    if (Test-GithubConnection -Repo $txtRepo.Text -Token $envMap['RELEASES_TOKEN']) {
      [System.Windows.Forms.MessageBox]::Show('الاتصال ناجح ✓', 'GitHub', 'OK', 'Information')
    } else {
      [System.Windows.Forms.MessageBox]::Show('الاتصال فشل — راجع التوكن والريبو', 'GitHub', 'OK', 'Error')
    }
  })
  $grpGit.Controls.Add($btnCheckToken)

  $lblRelName = New-Object System.Windows.Forms.Label
  $lblRelName.Text = 'اسم الريليس:'
  $lblRelName.Location = New-Object System.Drawing.Point(560, 82)
  $lblRelName.Size = New-Object System.Drawing.Size(85, 20)
  $grpGit.Controls.Add($lblRelName)

  $txtRelName = New-Object System.Windows.Forms.TextBox
  $txtRelName.Location = New-Object System.Drawing.Point(120, 80)
  $txtRelName.Size = New-Object System.Drawing.Size(430, 23)
  $grpGit.Controls.Add($txtRelName)

  $lblNotes = New-Object System.Windows.Forms.Label
  $lblNotes.Text = 'ملاحظات التحديث:'
  $lblNotes.Location = New-Object System.Drawing.Point(530, 112)
  $lblNotes.Size = New-Object System.Drawing.Size(115, 20)
  $grpGit.Controls.Add($lblNotes)

  $txtNotes = New-Object System.Windows.Forms.TextBox
  $txtNotes.Multiline = $true
  $txtNotes.ScrollBars = 'Vertical'
  $txtNotes.Text = 'نسخة جديدة — تحسينات وإصلاحات.'
  $txtNotes.Location = New-Object System.Drawing.Point(120, 110)
  $txtNotes.Size = New-Object System.Drawing.Size(405, 60)
  $grpGit.Controls.Add($txtNotes)

  $chkReplace = New-Object System.Windows.Forms.CheckBox
  $chkReplace.Text = 'استبدل الريليس لو التاج موجود (تحديث بدل إنشاء)'
  $chkReplace.Checked = $true
  $chkReplace.Location = New-Object System.Drawing.Point(300, 178)
  $chkReplace.Size = New-Object System.Drawing.Size(345, 22)
  $grpGit.Controls.Add($chkReplace)
  $y += 230

  # ── أزرار ──
  $btnGo = New-Object System.Windows.Forms.Button
  $btnGo.Text = 'ابدأ البناء 🚀'
  $btnGo.Location = New-Object System.Drawing.Point(460, $y)
  $btnGo.Size = New-Object System.Drawing.Size(210, 42)
  $form.Controls.Add($btnGo)

  $btnManage = New-Object System.Windows.Forms.Button
  $btnManage.Text = 'إدارة الريليسيز'
  $btnManage.Location = New-Object System.Drawing.Point(240, $y)
  $btnManage.Size = New-Object System.Drawing.Size(200, 42)
  $btnManage.Add_Click({
    Show-ReleaseManager -Repo $txtRepo.Text -Token $envMap['RELEASES_TOKEN']
  })
  $form.Controls.Add($btnManage)

  $btnClose = New-Object System.Windows.Forms.Button
  $btnClose.Text = 'إغلاق'
  $btnClose.Location = New-Object System.Drawing.Point(150, $y)
  $btnClose.Size = New-Object System.Drawing.Size(80, 42)
  $btnClose.Add_Click({ $form.Close() })
  $form.Controls.Add($btnClose)
  $y += 52

  # ── السجل ──
  $txtLog = New-Object System.Windows.Forms.TextBox
  $txtLog.Multiline = $true
  $txtLog.ReadOnly = $true
  $txtLog.ScrollBars = 'Vertical'
  $txtLog.Location = New-Object System.Drawing.Point(12, $y)
  $txtLog.Size = New-Object System.Drawing.Size(660, 200)
  $txtLog.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
  $txtLog.ForeColor = [System.Drawing.Color]::LightGreen
  $form.Controls.Add($txtLog)

  $timer = New-Object System.Windows.Forms.Timer
  $timer.Interval = 300
  $timer.Add_Tick({
    $drained = $false
    while (-not $script:LogQueue.IsEmpty) {
      $line = $null
      if ($script:LogQueue.TryDequeue([ref]$line)) {
        $txtLog.AppendText($line + "`r`n")
        $drained = $true
      }
    }
    if ($drained) {
      $txtLog.SelectionStart = $txtLog.TextLength
      $txtLog.ScrollToCaret()
    }
  })
  $timer.Start()

  # ── العمل ──
  $worker = New-Object System.ComponentModel.BackgroundWorker
  $worker.WorkerSupportsCancellation = $false
  $worker.Add_DoWork({
    param($sender, $e)
    $params = $e.Argument
    try {
      if (-not (Test-VersionFormat -Version $params.Version)) { throw "صيغة النسخة غلط: $($params.Version)" }
      Invoke-ReleasePipeline -PlatformType $params.Platform -Version $params.Version `
        -BuildNumber $params.BuildNumber -ActionName $params.Action -IsccPath $params.IsccPath `
        -DoUpload $params.DoUpload -ReleaseName $params.ReleaseName `
        -ReleaseNotes $params.ReleaseNotes -ReplaceIfExists $params.ReplaceIfExists -SkipBuild $false
    } catch {
      Add-Log "ERROR: $($_.Exception.Message)"
      $e.Result = $_.Exception.Message
    }
  })
  $worker.Add_RunWorkerCompleted({
    param($sender, $e)
    $btnGo.Enabled = $true
    if ($e.Result) {
      [System.Windows.Forms.MessageBox]::Show("فشل البناء:`r`n$($e.Result)", 'Saytarly', 'OK', 'Error')
    } else {
      [System.Windows.Forms.MessageBox]::Show('خلص البناء بنجاح ✓ — الملفات في build_export', 'Saytarly', 'OK', 'Information')
    }
  })

  $btnGo.Add_Click({
    $p = ''
    if ($radWindows.Checked) { $p = 'windows' } else { $p = 'mobile' }
    $ver = if ($p -eq 'windows') { $txtWv.Text.Trim() } else { $txtMv.Text.Trim() }
    $buildTxt = if ($p -eq 'windows') { $txtWb.Text.Trim() } else { $txtMb.Text.Trim() }
    $action = 'build'
    if ($p -eq 'windows') {
      if ($radInstaller.Checked) { $action = 'installer' }
      elseif ($radInstallerZip.Checked) { $action = 'installerzip' }
    } else {
      if ($radInstaller.Checked -or $radInstallerZip.Checked) { $action = 'apkzip' }
    }
    $script:ModeOverride = if ($radOffline.Checked) { 'offline' } else { 'online' }
    $params = @{
      Platform = $p
      Version = $ver
      BuildNumber = [int]$buildTxt
      Action = $action
      IsccPath = $txtInno.Text.Trim()
      DoUpload = $chkUpload.Checked
      ReleaseName = $txtRelName.Text.Trim()
      ReleaseNotes = $txtNotes.Text
      ReplaceIfExists = $chkReplace.Checked
    }
    $btnGo.Enabled = $false
    $worker.RunWorkerAsync($params)
  })

  $form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
  })

  [System.Windows.Forms.Application]::Run($form) | Out-Null
}

function Show-ReleaseManager {
  param([string]$Repo, [string]$Token)
  Add-Type -AssemblyName System.Windows.Forms

  $frm = New-Object System.Windows.Forms.Form
  $frm.Text = 'إدارة الريليسيز على GitHub'
  $frm.Size = New-Object System.Drawing.Size(760, 560)
  $frm.StartPosition = 'CenterParent'
  $frm.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
  $frm.RightToLeftLayout = $true

  $lst = New-Object System.Windows.Forms.ListBox
  $lst.Location = New-Object System.Drawing.Point(12, 12)
  $lst.Size = New-Object System.Drawing.Size(300, 420)
  $frm.Controls.Add($lst)

  $lblName = New-Object System.Windows.Forms.Label
  $lblName.Text = 'اسم الريليس:'
  $lblName.Location = New-Object System.Drawing.Point(600, 12)
  $lblName.Size = New-Object System.Drawing.Size(120, 20)
  $frm.Controls.Add($lblName)

  $txtName = New-Object System.Windows.Forms.TextBox
  $txtName.Location = New-Object System.Drawing.Point(330, 12)
  $txtName.Size = New-Object System.Drawing.Size(260, 23)
  $frm.Controls.Add($txtName)

  $lblBody = New-Object System.Windows.Forms.Label
  $lblBody.Text = 'الملاحظات:'
  $lblBody.Location = New-Object System.Drawing.Point(560, 42)
  $lblBody.Size = New-Object System.Drawing.Size(90, 20)
  $frm.Controls.Add($lblBody)

  $txtBody = New-Object System.Windows.Forms.TextBox
  $txtBody.Multiline = $true
  $txtBody.ScrollBars = 'Vertical'
  $txtBody.Location = New-Object System.Drawing.Point(330, 42)
  $txtBody.Size = New-Object System.Drawing.Size(400, 250)
  $frm.Controls.Add($txtBody)

  $script:releaseList = @()

  $loadReleases = {
    $script:releaseList = @(Get-GithubReleases -Repo $Repo -Token $Token)
    $lst.Items.Clear()
    foreach ($r in $script:releaseList) {
      $null = $lst.Items.Add("$($r.tag_name) | $($r.name)")
    }
  }

  $btnRefresh = New-Object System.Windows.Forms.Button
  $btnRefresh.Text = 'تحديث القائمة'
  $btnRefresh.Location = New-Object System.Drawing.Point(12, 442)
  $btnRefresh.Size = New-Object System.Drawing.Size(140, 30)
  $btnRefresh.Add_Click({ & $loadReleases })
  $frm.Controls.Add($btnRefresh)

  $btnOpen = New-Object System.Windows.Forms.Button
  $btnOpen.Text = 'فتح في المتصفح'
  $btnOpen.Location = New-Object System.Drawing.Point(160, 442)
  $btnOpen.Size = New-Object System.Drawing.Size(140, 30)
  $btnOpen.Add_Click({
    $i = $lst.SelectedIndex
    if ($i -ge 0) { Start-Process $script:releaseList[$i].html_url }
  })
  $frm.Controls.Add($btnOpen)

  $lst.Add_SelectedIndexChanged({
    $i = $lst.SelectedIndex
    if ($i -ge 0) {
      $txtName.Text = $script:releaseList[$i].name
      $txtBody.Text = $script:releaseList[$i].body
    }
  })

  $btnSave = New-Object System.Windows.Forms.Button
  $btnSave.Text = 'حفظ التعديل (الاسم + الملاحظات)'
  $btnSave.Location = New-Object System.Drawing.Point(330, 300)
  $btnSave.Size = New-Object System.Drawing.Size(240, 34)
  $btnSave.Add_Click({
    $i = $lst.SelectedIndex
    if ($i -lt 0) {
      [System.Windows.Forms.MessageBox]::Show('اختار ريليس الأول')
      return
    }
    Update-GithubReleaseNotes -Repo $Repo -Token $Token -ReleaseId $script:releaseList[$i].id -Name $txtName.Text -Body $txtBody.Text
    [System.Windows.Forms.MessageBox]::Show('تم الحفظ ✓')
  })
  $frm.Controls.Add($btnSave)

  $btnDelete = New-Object System.Windows.Forms.Button
  $btnDelete.Text = 'حذف الريليس'
  $btnDelete.Location = New-Object System.Drawing.Point(330, 342)
  $btnDelete.Size = New-Object System.Drawing.Size(240, 34)
  $btnDelete.ForeColor = [System.Drawing.Color]::Firebrick
  $btnDelete.Add_Click({
    $i = $lst.SelectedIndex
    if ($i -lt 0) { return }
    $confirm = [System.Windows.Forms.MessageBox]::Show("هتحذف الريليس `"$($script:releaseList[$i].tag_name)`" نهائيًا؟", 'تأكيد', 'YesNo', 'Warning')
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
      Remove-GithubRelease -Repo $Repo -Token $Token -ReleaseId $script:releaseList[$i].id
      & $loadReleases
    }
  })
  $frm.Controls.Add($btnDelete)

  & $loadReleases
  [System.Windows.Forms.Application]::Run($frm) | Out-Null
}

# ============================ CLI ============================
function Invoke-CliMode {
  $script:DirectLog = $true
  $script:ModeOverride = $Mode

  # وضع ملف المعاملات — بيستخدمه موقع SaytarlyMind
  if ($ParamsFile -and (Test-Path -LiteralPath $ParamsFile)) {
    $jsonText = [System.IO.File]::ReadAllText($ParamsFile, [System.Text.UTF8Encoding]::new($false))
    $p = $jsonText | ConvertFrom-Json
    $Platform = "$($p.platform)"
    $Version = "$($p.version)"
    $Build = [int]$p.build
    $Action = "$($p.action)"
    $Upload = [bool]$p.upload
    $ReleaseName = "$($p.releaseName)"
    $Notes = "$($p.notes)"
    $IsccPath = "$($p.iscc)"
    $CreateOnly = [bool]$p.createOnly
    $NoBuild = [bool]$p.noBuild
    $Mode = "$($p.mode)"
  }

  if ($EnsureInno) {
    $path = Ensure-InnoSetup -IsccPath $IsccPath
    Add-Log "Inno Setup ready: $path"
    return
  }

  if ($CheckGithub) {
    $envMap = Get-EnvMap
    $ok = Test-GithubConnection -Repo $envMap['RELEASES_REPO'] -Token $envMap['RELEASES_TOKEN']
    if ($ok) {
      Add-Log 'GitHub connection OK'
      $releases = Get-GithubReleases -Repo $envMap['RELEASES_REPO'] -Token $envMap['RELEASES_TOKEN']
      foreach ($r in $releases | Select-Object -First 10) {
        Add-Log "$($r.tag_name) | $($r.name)"
      }
    } else {
      throw 'GitHub connection failed'
    }
    return
  }

  if ($Platform -ne 'mobile' -and $Platform -ne 'windows') {
    throw 'CLI: -Platform must be "mobile" or "windows"'
  }
  if (-not (Test-VersionFormat -Version $Version)) {
    throw "CLI: bad -Version format: $Version"
  }
  $action = $Action.ToLower()
  if ($action -eq '') {
    $action = if ($Platform -eq 'windows') { 'installerzip' } else { 'apk' }
  }
  $envMap = Get-EnvMap
  $buildNum = $Build
  if ($buildNum -lt 0) {
    $buildNum = if ($Platform -eq 'windows') { [int]$envMap['WINDOWS_BUILD_NUMBER'] } else { [int]$envMap['MOBILE_BUILD_NUMBER'] }
  }
  if ($IncreaseBuild) { $buildNum = $buildNum + 1 }

  $iscc = $IsccPath
  if (-not $iscc) { $iscc = Find-InnoSetup }

  Invoke-ReleasePipeline -PlatformType $Platform -Version $Version -BuildNumber $buildNum `
    -ActionName $action -IsccPath $iscc `
    -DoUpload $Upload -ReleaseName $ReleaseName -ReleaseNotes $Notes `
    -ReplaceIfExists (-not $CreateOnly) -SkipBuild $NoBuild
}

# ============================ ENTRY ============================
if ($Cli) {
  Invoke-CliMode
  # flush the log
  while (-not $script:LogQueue.IsEmpty) {
    $line = $null
    if ($script:LogQueue.TryDequeue([ref]$line)) { Write-Host $line }
  }
} else {
  Show-ReleaseGui
}
