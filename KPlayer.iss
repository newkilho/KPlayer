#define MySrcDir           "D:\Vendor\KPlayer"
#define MyAppExe           MySrcDir + "\KPlayer.exe"
#define MyAppName          "KPlayer"
#define MyAppAuthor        "Kilhonet"
#define MyAppPublisherURL  "https://kilho.net"
#define StartYearCopyright "2026"
#define CurrentYear        GetDateTimeString('yyyy','','')

#define MyAppVersion() \
   ParseVersion(MyAppExe, Local[0], Local[1], Local[2], Local[3]), \
   Str(Local[0]) + "." + Str(Local[1]) + "." + Str(Local[2]) + "." + Str(Local[3])

[Files]
Source: "{#MyAppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MySrcDir}\KPlayer.lua"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MySrcDir}\Icon\*.ico"; DestDir: "{app}\Icon"; Flags: ignoreversion
Source: "{#MySrcDir}\libmpv-2.dll"; DestDir: "{app}"

[Setup]
AppId={#MyAppName}
AppName={cm:MyAppName}
AppVersion={#MyAppVersion}
AppVerName={cm:MyAppName} {#MyAppVersion}

AppPublisher={#MyAppAuthor}
AppPublisherURL={#MyAppPublisherURL}
AppSupportURL={#MyAppPublisherURL}
AppUpdatesURL={#MyAppPublisherURL}
AppCopyright=Copyright (C) {#StartYearCopyright}-{#CurrentYear} {#MyAppAuthor}

VersionInfoDescription={#MyAppName} installer
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppAuthor}
VersionInfoCopyright={#MyAppAuthor}
VersionInfoProductName={#MyAppName}

WizardStyle=modern

ShowLanguageDialog=no
UsePreviousLanguage=no

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={cm:MyAppName}
OutputDir="Z:\Release"
OutputBaseFilename={#MyAppName}Setup
UninstallDisplayIcon={app}\{#MyAppName}.exe
UninstallDisplayName={cm:MyAppName}

PrivilegesRequired=admin
DisableStartupPrompt=true
DisableProgramGroupPage=true
Compression=lzma/ultra64
UsePreviousAppDir=true
DisableDirPage=auto
UserInfoPage=false
ShowTasksTreeLines=false
AlwaysShowDirOnReadyPage=false
AlwaysShowGroupOnReadyPage=false
FlatComponentsList=true
WindowVisible=false
DisableFinishedPage=True
InternalCompressLevel=ultra64
SolidCompression=true
UninstallFilesDir={app}
AllowCancelDuringInstall=false
CreateUninstallRegKey=true
UninstallLogMode=overwrite
UpdateUninstallLogAppName=false
RestartIfNeededByRun=true
WizardImageStretch=true
SetupLogging=false
AppendDefaultDirName=false
DisableReadyPage=True

[Languages]
Name: en; InfoBeforeFile: "KPlayer(en).txt"; MessagesFile: "compiler:Default.isl"
Name: ko; InfoBeforeFile: "KPlayer(ko).txt"; MessagesFile: "compiler:Languages\Korean.isl"

[CustomMessages]
en.MyAppName=KPlayer
ko.MyAppName=케이플레이어

[Icons]
Name: {group}\{cm:MyAppName}; Filename: {app}\KPlayer.exe

[Run]
Filename: "{app}\KPlayer.exe"; Flags: nowait postinstall skipifsilent runasoriginaluser; Description: "KPlayer"

[UninstallDelete]
Name: "{app}"; Type: filesandordirs

[Code]
const
  WM_CLOSE = $0010;
  WM_QUERYENDSESSION = $0011;

procedure TaskKill(FileName: String);
var
  ErrorCode: Integer;
begin
  Exec(ExpandConstant('taskkill.exe'), '/f /im "'+FileName+'"', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
end;

procedure ProcKill(ClassName: String);
var
  Handle: HWND;
  Loop: integer;
begin
  for Loop := 0 to 20 do
  begin
    Handle := FindWindowByClassName(ClassName);
    if Handle>0 then
    begin
      PostMessage(Handle, WM_QUERYENDSESSION, 100, 0);
      Sleep(100);
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';

  TaskKill('KPlayer.exe');
  ProcKill('TFrmKPlayer');
end;

function InitializeUninstall(): Boolean;
var
  ErrorCode: Integer;
begin
  Result := True;

  TaskKill('KPlayer.exe');
  ProcKill('TFrmKPlayer');

  ExecAsOriginalUser(ExpandConstant('{app}') + '\KPlayer.exe', '/uninst', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
end;
