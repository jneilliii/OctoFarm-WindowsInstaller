#define public Dependency_NoExampleSetup
#include "CodeDependencies.iss"
#ifndef OctoFarmSetupVersion
  #define OctoFarmSetupVersion "unknown"
#endif
#define MyAppName "OctoFarm"
#define MyAppVersion OctoFarmSetupVersion
#define MyAppPublisher "OctoFarm"
#define MyAppURL "https://www.octoprint.org/"
#define MyAppSupportURL "https://github.com/jneilliii/OctoPrint-WindowsInstaller/issues"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppCopyright=2023
DefaultDirName=C:\OctoFarm
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
UninstallDisplayIcon={uninstallexe}
OutputBaseFilename=OctoFarm Setup {#MyAppVersion}
WizardImageFile=WizModernImage-OctoFarm*.bmp
WizardSmallImageFile=WizModernSmallImage-OctoFarm*.bmp
WizardStyle=modern
DisableWelcomePage=False

[Run]
Filename: "powershell"; Parameters: "-command ""Expand-Archive {app}\dependencies\mongodb-windows-x86_64-4.4.17.zip {app}\dependencies"""; Flags: runascurrentuser runhidden; Description: "Extract MongoDB"; StatusMsg: "Extracting MongoDB"
Filename: "powershell"; Parameters: "-command ""New-Item -Path '{app}\data' -ItemType Directory"""; Flags: runascurrentuser runhidden; Description: "Create data folder"; StatusMsg: "Creating data folder"
Filename: "powershell"; Parameters: "-command ""New-Item -Path '{app}\data\db' -ItemType Directory"""; Flags: runascurrentuser runhidden; Description: "Create db folder"; StatusMsg: "Creating db folder"
Filename: "powershell"; Parameters: "-command ""New-Item -Path '{app}\data\logs' -ItemType Directory"""; Flags: runascurrentuser runhidden; Description: "Create logs folder"; StatusMsg: "Creating logs folder"
Filename: "{app}\dependencies\mongodb-win32-x86_64-windows-4.4.17\bin\mongod.exe"; Parameters: "--install --logpath {app}\data\logs\mongod.log --dbpath {app}\data\db\"; WorkingDir: "{app}\dependencies\mongodb-win32-x86_64-windows-4.4.17\bin"; Flags: runascurrentuser runhidden; Description: "Add MongoDB Service"; StatusMsg: "Adding MongoDB Service" 
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""MongoDB"" dir=in protocol=TCP localport=27017 action=allow"; WorkingDir: "{sys}"; Flags: runascurrentuser runhidden; Description: "Add MongoDB Firewall Exception"; StatusMsg: "Adding firewall exception rule for MongoDB"; 
Filename: "net.exe"; Parameters: "start MongoDB"; WorkingDir: "{sys}"; Flags: runascurrentuser runhidden; Description: "Start MongoDB Service"; StatusMsg: "Starting MongoDB Service"
Filename: "msiexec.exe"; Parameters: "/i {app}\dependencies\node-v18.14.0-x64.msi /qn ADDLOCAL=ALL"; WorkingDir: "{app}\dependencies"; Flags: runascurrentuser shellexec waituntilterminated runhidden; Description: "Install Node JS"; StatusMsg: "Installing Node JS"
Filename: "powershell"; Parameters: "-command ""Expand-Archive {app}\dependencies\OctoFarm.zip {app}"""; Flags: runascurrentuser runhidden; Description: "Extract OctoFarm"; StatusMsg: "Extracting OctoFarm"
Filename: "{pf}\nodejs\npm"; Parameters: "install pm2 -g"; Flags: shellexec waituntilterminated runhidden runascurrentuser; Description: "Install pm2"; StatusMsg: "Installing pm2 (this will take a while)"
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""OctoFarm"" dir=in protocol=TCP localport=4000 action=allow"; WorkingDir: "{sys}"; Flags: runascurrentuser runhidden; Description: "Add OctoFarm Firewall Exception"; StatusMsg: "Adding firewall exception rule for OctoFarm";
Filename: "{pf}\nodejs\npm"; Parameters: "--prefix {app}\OctoFarm-master run start"; WorkingDir: "{app}\OctoFarm-master"; Flags: shellexec waituntilterminated runasoriginaluser runhidden; Description: "Start OctoFarm"; StatusMsg: "Installing node dependencies and starting OctoFarm (this will take a while)"
Filename: "http://localhost:4000/"; Flags: nowait postinstall shellexec; Description: "Open OctoFarm in default browser"; StatusMsg: "Opening OctoFarm"

[Files]
Source: "{tmp}\mongodb-windows-x86_64-4.4.17.zip"; DestDir: "{app}\dependencies\"; Flags: external
Source: "{tmp}\node-v18.14.0-x64.msi"; DestDir: "{app}\dependencies\"; Flags: external
Source: "{tmp}\OctoFarm.zip"; DestDir: "{app}\dependencies\"; Flags: external

[UninstallRun]
Filename: "{app}\dependencies\mongodb-win32-x86_64-windows-4.4.17\bin\mongod.exe"; Parameters: "--remove"; WorkingDir: "{app}\dependencies\mongodb-win32-x86_64-windows-4.4.17\bin"; Flags: runhidden
Filename: "pm2"; Parameters: "delete OctoFarm"; Flags: shellexec runhidden

[Code]
var
  DownloadPage: TDownloadWizardPage;

function InitializeSetup: Boolean;
begin
  // VS Code Dependency Install
  Dependency_AddVC2015To2022;
  // ...

  Result := True;
end;

function OnDownloadProgress(const Url, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  if Progress = ProgressMax then
    Log(Format('Successfully downloaded file to {tmp}: %s', [FileName]));
  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), @OnDownloadProgress);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if CurPageID = wpReady then begin
    DownloadPage.Clear;
    DownloadPage.Add('https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-4.4.17.zip', 'mongodb-windows-x86_64-4.4.17.zip', '');
    DownloadPage.Add('https://nodejs.org/dist/v18.14.0/node-v18.14.0-x64.msi', 'node-v18.14.0-x64.msi', '944eff6104be19d1dc24f3940ab365aa972c47ee2a6b7cfee49dd436e748bd99');
    DownloadPage.Add('https://github.com/OctoFarm/OctoFarm/archive/refs/heads/master.zip', 'OctoFarm.zip', '');
    DownloadPage.Show;
    try
      try
        DownloadPage.Download; // This downloads the files to {tmp}
        Result := True;
      except
        if DownloadPage.AbortedByUser then
          Log('Aborted by user.')
        else
          SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);
        Result := False;
      end;
    finally
      DownloadPage.Hide;
    end;
  end else
    Result := True;
end;
