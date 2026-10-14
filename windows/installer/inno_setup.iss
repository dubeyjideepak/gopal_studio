; Inno Setup Script for StudioBill Pro (Windows Desktop Installer)
; To compile: Download Inno Setup (https://jrsoftware.org/isdl.php)
; Command line: iscc windows/installer/inno_setup.iss

#define MyAppName "StudioBill Pro"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Gopal Studio"
#define MyAppExeName "StudioBillPro.exe"

#ifndef ReleaseDir
  #define ReleaseDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
; Unique GUID for uninstaller / upgrade detection
AppId={{E61A132C-4A23-488F-9B6C-77E596CEB442}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
DisableDirPage=no
OutputDir=..\..\build\windows\installer
OutputBaseFilename=StudioBillPro_v{#MyAppVersion}_Setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\app_icon.ico
UninstallDisplayName={#MyAppName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
AlwaysShowDirOnReadyPage=yes
AlwaysShowGroupOnReadyPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Copy main binary and all Flutter DLLs, plugins, and data folders
Source: "{#ReleaseDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#MyAppExeName}"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
