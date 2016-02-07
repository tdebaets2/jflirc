;****************************************************************************
;*
;*            WinLIRC plug-in for jetAudio
;*
;*            Copyright (c) 2016 Tim De Baets
;*
;****************************************************************************
;*
;* Licensed under the Apache License, Version 2.0 (the "License");
;* you may not use this file except in compliance with the License.
;* You may obtain a copy of the License at
;*
;*     http://www.apache.org/licenses/LICENSE-2.0
;*
;* Unless required by applicable law or agreed to in writing, software
;* distributed under the License is distributed on an "AS IS" BASIS,
;* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;* See the License for the specific language governing permissions and
;* limitations under the License.
;*
;****************************************************************************
;*
;* Inno Setup install script
;*
;****************************************************************************

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
AppId={{E825D7B1-1898-44D8-8043-B4A5CBA44B2A}
AppName=WinLIRC plug-in for jetAudio
AppVerName=WinLIRC plug-in for jetAudio 1.0
AppVersion=1.0
AppPublisher=BM-productions
AppPublisherURL={cm:URL}
AppSupportURL={cm:URL}
AppUpdatesURL={cm:URL}
DefaultDirName={pf}\WinLIRC plug-in for jetAudio
DefaultGroupName=WinLIRC plug-in for jetAudio
OutputBaseFilename=jetAudioWinLIRC-1.0
OutputDir=..\Output
Compression=lzma
SolidCompression=true
VersionInfoVersion=1.0
VersionInfoCompany=BM-productions
VersionInfoDescription=WinLIRC plug-in for jetAudio
VersionInfoTextVersion=1.0
VersionInfoCopyright=Copyright © 2009 BM-productions - All rights reserved
MinVersion=0,5.01
AppCopyright=Copyright © 2009 BM-productions - All rights reserved
DisableProgramGroupPage=true
UsePreviousGroup=false
ShowLanguageDialog=no
WizardImageFile=compiler:WizModernImage-IS.bmp
WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp

[Languages]
Name: english; MessagesFile: compiler:Default.isl

[Files]
Source: ..\Output\JFLirc.dll; DestDir: {code:GetJAPluginPath}; Flags: replacesameversion; Languages: 
Source: ..\JFLirc.ini; DestDir: {userappdata}\COWON\JetAudio; Flags: onlyifdoesntexist; Languages: 
Source: ..\Readme.htm; DestDir: {app}; Flags: ignoreversion; Languages: 
Source: ..\LICENSE; DestDir: {app}; Flags: ignoreversion; Languages: 

[CustomMessages]
URL=http://www.bm-productions.tk
JAPluginPathNotFound=Setup was unable to find jetAudio on this computer.%nAt least version 7 of jetAudio needs to be installed, this is required to use the WinLIRC plug-in.%n%nDo you want to download jetAudio now?
JADownloadURL=http://www.cowonamerica.com/download/
RunNow=&Run jetAudio now
ViewReadme=&View readme

[InstallDelete]
Name: {userappdata}\COWON\JetAudio\*.cache; Type: files; Languages:

[UninstallDelete]
Name: {userappdata}\COWON\JetAudio\*.cache; Type: files

[Run]
Filename: {app}\Readme.htm; Description: {cm:ViewReadme}; Flags: nowait postinstall skipifsilent shellexec
Filename: {code:GetJAExePath}; Description: {cm:RunNow}; Flags: nowait postinstall skipifsilent 

[ThirdParty]
CompileLogMethod=append

[Code]
const
  ISKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{E825D7B1-1898-44D8-8043-B4A5CBA44B2A}_is1';
  ISVal = 'UninstallString';
  JAPathKey = 'Software\COWON\Jet-Audio';
  JAMainPathValue = 'InstallPath_Main';
  JAPluginPathValue = 'InstallPath_Plugin';
  JAClass = 'COWON Jet-Audio MainWnd Class';
  JAExeFile = 'JetAudio.exe';

var
  Reinstall: Boolean;
  JAExePath, JAPluginPath: String;

function CheckJARunning: Boolean;
var
  JARunningMsg: String;
begin
  Result := True;
  if IsUninstaller then
    JARunningMsg := SetupMessage(msgUninstallAppRunningError)
  else
    JARunningMsg := SetupMessage(msgSetupAppRunningError);
  while True do begin
    if FindWindowByClassName(JAClass) = 0 then
      Exit;
    else begin
      if MsgBox(FmtMessage(JARunningMsg, ['jetAudio']), mbError, MB_OKCANCEL) = IDCANCEL then begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

function JAPluginPathExists: Boolean;
begin
  Result := (JAPluginPath <> '') and DirExists(JAPluginPath)
      and (JAExePath <> '') and FileExists(JAExePath);
end;

function InitializeSetup: Boolean;
var
  InstDir: String;
  ErrCode: Integer;
begin
  Result := CheckJARunning;
  if not Result then
    Exit;
  Reinstall := False;
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, ISKey, ISVal, InstDir) then
    RegQueryStringValue(HKEY_CURRENT_USER, ISKey, ISVal, InstDir);
  if Trim(InstDir) <> '' then
    InstDir := ExtractFilePath(RemoveQuotes(InstDir));
  if (InstDir <> '') and DirExists(InstDir) then
    Reinstall := True;
  JAExePath := '';
  RegQueryStringValue(HKEY_LOCAL_MACHINE, JAPathKey, JAMainPathValue, JAExePath);
  if JAExePath <> '' then
    JAExePath := AddBackslash(JAExePath) + JAExeFile;
  JAPluginPath := '';
  RegQueryStringValue(HKEY_LOCAL_MACHINE, JAPathKey, JAPluginPathValue, JAPluginPath);
  if not JAPluginPathExists then begin
    if MsgBox(CustomMessage('JAPluginPathNotFound'), mbError, MB_YESNO) = IDYES then
      ShellExec('', CustomMessage('JADownloadURL'), '', '', SW_SHOWNORMAL, ewNoWait, ErrCode);
    Result := False;
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if PageID = wpSelectDir then
    Result := Reinstall;
end;

function GetJAPluginPath(Param: String): String;
begin
  Result := JAPluginPath;
end;

function GetJAExePath(Param: String): String;
begin
  Result := JAExePath;
end;

function InitializeUninstall(): Boolean;
begin
  Result := CheckJARunning;
end;
