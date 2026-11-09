; ============================================================
;  Saytarly — Windows Installer (Inno Setup 6)
;  Built by tool\release.ps1 — it passes:
;    /DMyAppVersion="1.0.0.0"
;    /DMyAppBuild="1"
;    /DMyAppOutputDir="<repo>\build_export"
;
;  The [Files] section takes everything from the release build:
;    ..\build\windows\x64\runner\Release\*
; ============================================================

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0.0"
#endif
#ifndef MyAppBuild
  #define MyAppBuild "1"
#endif
#ifndef MyAppName
  #define MyAppName "Saytarly"
#endif
#ifndef MyAppExeName
  #define MyAppExeName "saytarly.exe"
#endif
#ifndef MyAppOutputDir
  #define MyAppOutputDir "..\build_export"
#endif

#ifexist "compiler:Languages\Unofficial\Arabic.isl"
  #define HasArabic
#endif

[Setup]
; GUID جديد عشان التثبيت الجديد (per-user) مايورثش مجلد Program Files القديم
AppId={{9E2F1A6B-4C7D-4E1F-8B3A-1D6C5E7A9F04}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=Saytarly
AppPublisherURL=https://github.com/COACHIKO/saytarly_releases
AppSupportURL=https://github.com/COACHIKO/saytarly_releases
AppUpdatesURL=https://github.com/COACHIKO/saytarly_releases
AppCopyright=Copyright (C) 2026 Saytarly
DefaultDirName={localappdata}\Programs\Saytarly
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
DisableDirPage=no
OutputDir={#MyAppOutputDir}
OutputBaseFilename=saytarly_windows_{#MyAppVersion}_setup
SetupIconFile=..\assets\images\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
WizardSizePercent=100
MinVersion=10.0
; تثبيت لكل مستخدم من غير صلاحيات أدمن — وده بيخلي التحديث الذاتي شغال
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; ملحوظة: بنقفل النسخة الشغالة في PrepareToInstall تحت — من غير
; CloseApplications عشان الـ silent install ميفشلش لما التطبيق شغال.
UsePreviousAppDir=yes
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany=Saytarly
VersionInfoDescription={#MyAppName} installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
#ifdef HasArabic
Name: "arabic"; MessagesFile: "compiler:Languages\Unofficial\Arabic.isl"
#endif

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; كل ملفات نسخة الـ Release — الـ exe والـ DLLs ومجلد الـ assets
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; runasoriginaluser: يفتح التطبيق بحساب المستخدم العادي مش بصلاحيات الـ setup
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent runasoriginaluser

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"

[Code]
// التطبيق بيخفي نفسه في التراي بدل ما يقفل — فبنقفل أي نسخة شغالة
// بالقوة قبل التثبيت عشان الملفات تتستبدل من غير أخطاء.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';
  Exec(ExpandConstant('{cmd}'), '/c taskkill /F /IM saytarly.exe /T', '', SW_HIDE,
       ewWaitUntilTerminated, ResultCode);
end;
