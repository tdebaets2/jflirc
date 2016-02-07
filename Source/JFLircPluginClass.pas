(****************************************************************************
 *
 *            WinLIRC plug-in for jetAudio
 *
 *            Copyright (c) 2016 Tim De Baets
 *
 ****************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ****************************************************************************
 *
 * Main plug-in implementation
 *
 ****************************************************************************)

unit JFLircPluginClass;

interface

uses Windows, Messages, SysUtils, Classes, JFBase, JFGeneral, JDefine, ThisCall,
    ScktComp, Common2, EzdslHsh, IniFiles, CmnFunc2;

const
  PluginName = 'WinLIRC plug-in for jetAudio';
  PluginDesc =
      'Control jetAudio with a remote controller through the WinLIRC protocol.';

type

  TJFLircPlugin = class(TJFGeneral)
  private
    fSocket: TClientSocket;
    fFields: TStringList;
    fModeCommands: THashTable;
    fStandardCommands: THashTable;
    fMenuCommands: THashTable;
    fMonitorCommands: THashTable;
    fMappedCommands: THashTable;
    fMappedKeys: TStringList;

    fIniFile: TIniFile;
    fWinLircHost: String;
    fWinLircPort: Integer;
    fWinLircServer: String;
    fMaxRetries: Integer;
    fNoConnectFailedWarning: Boolean;

    fhWndMain: HWND;

    fWindow: HWND;

    fConnected: Boolean;
    fTries: Integer;

    procedure csConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure csDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure csError(Sender: TObject; Socket: TCustomWinSocket;
        ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure csRead(Sender: TObject; Socket: TCustomWinSocket);

    procedure WndProc(var Message: TMessage);

    procedure StartServer;
    procedure TryConnect;

    procedure FillModeCommands;
    procedure FillStandardCommands;
    procedure FillMenuCommands;
    procedure FillMonitorCommands;
    procedure CreateAndOpenIniFile;
    procedure ReadWriteSettings(Write: Boolean);
    procedure ResolveMappings;

    procedure ClearMappedKeys;

    procedure HandleException(E: Exception);
  public
    FakeContextMenuId: Integer;
    hWndRemocon: HWND;
    
    constructor Create;
    destructor Destroy; override;

    procedure CDestroy(Val: Integer); override; stdcall;
    procedure GetInfo(pInfo: PJFInfo); override; stdcall;
    function SetPropertyPTR(pszPropName: PAnsiChar; pVal: PAnsiChar;
        iValSize: Integer): BOOL; override; stdcall;
    function GetPropertyPTR(pszPropName: PAnsiChar; pVal: PAnsiChar;
        iValSize: Integer): BOOL; override; stdcall;
    function SetPropertyINT(pszPropName: PAnsiChar; nVal: Integer): BOOL;
        override; stdcall;
    function GetPropertyINT(pszPropName: PAnsiChar; pnVal: PInteger): BOOL;
        override; stdcall;

    procedure Config(hWnd: HWND); override; stdcall;
    procedure About(hWnd: HWND); override; stdcall;

    function GetErrorString(pszBuffer: PAnsiChar;
        nBufferSize: Integer): JERROR_TYPE; override; stdcall;

    function Open(hWnd: HWND; pszRootDir: PAnsiChar; dwReserved1: DWORD;
        dwReserved2: DWORD): BOOL; override; stdcall;
    function Close: BOOL; override; stdcall;

    function OnTimer(nCounter: Integer): BOOL; override; stdcall;
    function OnEvent(uEvent: UINT; wParam: WPARAM; lParam: LPARAM): UINT;
        override; stdcall;
  end;

var
  JFLircPlugin: TJFLircPlugin = nil;
  ApiHooked: Boolean = False;

implementation

uses JetAudio6_API, JetAudio6_Const, JetAudioUtil, PathFunc, ShFolder,
    JFLircCommands;

var
  // TODO: better way than keeping this in a global var?
  ThisCallPatched: Boolean = False;

const
  DefaultHost = 'localhost';
  DefaultPort = 8765;
  DefaultMaxRetries = 3;

const
  IniSection = 'Settings';
  KeysSection = 'Keys';

procedure DisposeCommand(pData: Pointer);
begin
  if Assigned(pData) then
    FreeAndNil(TObject(pData));
end;

constructor TJFLircPlugin.Create;
begin
  try
    inherited Create;
    fHwndMain := 0;
    fWindow := 0;
    FakeContextMenuId := 0;
    hWndRemocon := 0;
    if not ThisCallPatched then begin
      TThisCallThunks.Create(Self, 13);
      ThisCallPatched := True;
    end;
    fFields := TStringList.Create;
    fModeCommands := THashTable.Create(False);
    // default hash function causes integer overflows
    fModeCommands.HashFunction := HashELF;
    fStandardCommands := THashTable.Create(False);
    fStandardCommands.HashFunction := HashELF;
    fMenuCommands := THashTable.Create(False);
    fMenuCommands.HashFunction := HashELF;
    fMonitorCommands := THashTable.Create(False);
    fMonitorCommands.HashFunction := HashELF;
    fMappedCommands := THashTable.Create(True);
    fMappedCommands.HashFunction := HashELF;
    fMappedCommands.DisposeData := DisposeCommand;
    fMappedKeys := TStringList.Create;
    fMappedKeys.Sorted := True;
    fIniFile := nil; // gets created in Open-method
    fSocket := TClientSocket.Create(nil);
    with fSocket do begin
      Active := False;
      OnConnect := csConnect;
      OnDisconnect := csDisconnect;
      OnRead := csRead;
      OnError := csError;
    end;
    JFLircPlugin := Self;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

destructor TJFLircPlugin.Destroy;
begin
  JFLircPlugin := nil;
  FreeAndNil(fSocket);
  FreeAndNil(fMonitorCommands);
  FreeAndNil(fMenuCommands);
  FreeAndNil(fStandardCommands);
  FreeAndNil(fModeCommands);
  FreeAndNil(fMappedCommands); // DisposeCommand frees mapped commands
  ClearMappedKeys;
  FreeAndNil(fMappedKeys);
  FreeAndNil(fFields);
  if Assigned(fIniFile) then
    FreeAndNil(fIniFile);
  inherited Destroy;
  // don't free the thunks because they are shared among all object instances
  {if Assigned(ThisCallThunks) then
    FreeAndNil(ThisCallThunks);}
end;

procedure TJFLircPlugin.CDestroy(Val: Integer);
begin
  try
    Free;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

procedure TJFLircPlugin.GetInfo(pInfo: PJFInfo); stdcall;
begin
  try
    FillChar(pInfo^, SizeOf(TJFInfo), 0);
    pInfo.m_uSDKVersion := $100;  // 1.00
    pInfo.m_szFilterName := PluginName;
    pInfo.m_szFilterDesc := PluginDesc;
    pInfo.m_szFilterWriter := 'BM-productions';
    pInfo.m_uInputDeviceType  := JDEVICE_UNKNOWN;
    pInfo.m_uOutputDeviceType := JDEVICE_UNKNOWN;
    pInfo.m_uInputStreamType  := JSTREAM_UNKNOWN;
    pInfo.m_uOutputStreamType := JSTREAM_UNKNOWN;
    pInfo.m_uCategory := JCATEGORY_GENERAL;
    pInfo.m_uCaps := JCAPS_HAS_CONFIG {or JCAPS_HAS_ABOUTBOX};
    pInfo.m_bUnvisible := FALSE;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

function TJFLircPlugin.SetPropertyPTR(pszPropName: PAnsiChar; pVal: PAnsiChar;
    iValSize: Integer): BOOL;
begin
  Result := False;
end;

function TJFLircPlugin.GetPropertyPTR(pszPropName: PAnsiChar; pVal: PAnsiChar;
    iValSize: Integer): BOOL;
begin
  Result := False;
end;

function TJFLircPlugin.SetPropertyINT(pszPropName: PAnsiChar;
    nVal: Integer): BOOL;
begin
  Result := False;
end;

function TJFLircPlugin.GetPropertyINT(pszPropName: PAnsiChar;
    pnVal: PInteger): BOOL;
begin
  Result := False;
end;

procedure TJFLircPlugin.Config(hWnd: HWND);
var
  F: TextFile;
begin
  if not Assigned(fIniFile) then
    CreateAndOpenIniFile;
  if not NewFileExists(fIniFile.FileName) then begin
    AssignFile(F, fIniFile.FileName);
    Rewrite(F);
    CloseFile(F);
  end;
  ExecuteFile(fhWndMain, fIniFile.FileName, '', '', SW_SHOWNORMAL);
end;

procedure TJFLircPlugin.About(hWnd: HWND);
begin
  // not called
end;

function TJFLircPlugin.GetErrorString(pszBuffer: PAnsiChar;
    nBufferSize: Integer): JERROR_TYPE;
begin
  Result := JERROR_UNKNOWN;
end;

function TJFLircPlugin.Open(hWnd: HWND; pszRootDir: PAnsiChar;
    dwReserved1: DWORD; dwReserved2: DWORD): BOOL;
begin
  Result := True;
  try
    fWindow := AllocateHWND(WndProc);
    fhWndMain := hWnd;
    hWndRemocon := JAGetRemoconWindow;
    FillModeCommands;
    FillStandardCommands;
    FillMenuCommands;
    FillMonitorCommands;
    CreateAndOpenIniFile;
    ReadWriteSettings(False);
    fSocket.Host := fWinLircHost;
    fSocket.Port := fWinLircPort;
    TryConnect;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

function TJFLircPlugin.Close: BOOL;
begin
  Result := True;
  try
    fConnected := False;
    fSocket.Close;
    if fWindow <> 0 then begin
      DeallocateHWND(fWindow);
      fWindow := 0;
    end;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

function TJFLircPlugin.OnTimer(nCounter: Integer): BOOL;
begin
  Result := True;
end;

function TJFLircPlugin.OnEvent(uEvent: UINT; wParam: WPARAM;
    lParam: LPARAM): UINT;
begin
  Result := 0;
end;

procedure TJFLircPlugin.csConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  {$IFDEF Debug}
  OutputDebugString('Status: Connected');
  {$ENDIF}
  fConnected := True;
  KillTimer(fWindow, 0);
end;

procedure TJFLircPlugin.csDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  {$IFDEF Debug}
  OutputDebugString('Status: Disconnected');
  {$ENDIF}
  if fConnected then begin
    MessageBox(fhWndMain, 'Connection with the WinLIRC server lost.' + CrLf2
        + 'Please verify that the server is still running and '
        + 'restart jetAudio to reconnect.', PluginName, MB_ICONWARNING);
  end;
  fConnected := False;
end;

procedure TJFLircPlugin.csError(Sender: TObject; Socket: TCustomWinSocket;
    ErrorEvent: TErrorEvent; var ErrorCode: Integer);
var
  ServerCfged: Boolean;
begin
  if ErrorEvent = eeConnect then begin
    ServerCfged := (fWinLircServer <> '');
    if not ServerCfged or (fTries = fMaxRetries) then begin
      if not fNoConnectFailedWarning then begin
        MessageBox(fhWndMain,
            'Unable to connect to the WinLIRC server. ' + CrLf2
            + 'Check if the WinLIRC plug-in is configured correctly and '
            + 'verify that the server is running. '
            + 'Restart jetAudio to try again.', PluginName, MB_ICONWARNING);
      end;
      fTries := 0;
    end
    else if ServerCfged then begin
      if fTries = 0 then
        StartServer
      else if fTries < fMaxRetries then begin
        Inc(fTries);
        SetTimer(fWindow, 0, 1000, nil);
      end;
    end;
  end
  else
    OutputDebugString(PChar('Status: Error ' + IntToStr(ErrorCode)));
  { don't raise an exception, because this will occur in jetAudio's message loop
    -> unhandled exception -> crash }
  ErrorCode := 0;
end;

procedure TJFLircPlugin.csRead(Sender: TObject; Socket: TCustomWinSocket);
var
  Data: String;
  Command: Pointer;
begin
  fFields.Clear;
  Data := Socket.ReceiveText;
  Split(Data, ' ', fFields);
  if fFields.Count <> 4 then
    Exit;
  fFields[2] := Trim(fFields[2]);
  if fMappedCommands.Search(fFields[2], Command) then begin
    if Assigned(Command) then
      TJACommand(Command).Execute;
  end
  else begin
    fIniFile.WriteString(KeysSection, fFields[2], '');
    fMappedCommands.Insert(fFields[2], nil);
    fMappedKeys.AddObject(fFields[2], nil);
  end;
end;

procedure TJFLircPlugin.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_TIMER then begin
    TryConnect;
    KillTimer(fWindow, 0);
    Message.Result := 0;
  end;
end;

procedure TJFLircPlugin.StartServer;
begin
  if not ExecuteFile(0, fWinLircServer, '', '', SW_SHOWNORMAL) then begin
    MessageBox(fhWndMain, 'Unable to start the WinLIRC server. ' + CrLf2
        + 'Review the WinLIRC plug-in settings and '
        + 'check if the server filename points to a valid executable.',
        PluginName, MB_ICONWARNING);
    Exit;
  end;
  fTries := 1;
  TryConnect;
end;

procedure TJFLircPlugin.TryConnect;
begin
  if fWinLircHost <> '' then
    fSocket.Active := True;
end;

procedure TJFLircPlugin.FillModeCommands;
begin
  fModeCommands.Insert('discmode', Pointer(jamDisc));
  fModeCommands.Insert('filemode', Pointer(jamFile));
end;

const
  RepeatModeNames: array[eRepeatMode] of String =
      ('none', 'this', 'all');
  RandomModeNames: array[eRandomMode] of String =
      ('normal', 'random', 'program');

procedure TJFLircPlugin.FillStandardCommands;
  procedure AddCommand(const Name: String; Command, Param: Word);
  begin
    fStandardCommands.Insert(Name, Pointer(MAKELPARAM(Command, Param)));
  end;
var
  RepMode: eRepeatMode;
  RandMode: eRandomMode;
begin
  AddCommand('stop', JRC_ID_STOP, 0);
  AddCommand('play', JRC_ID_PLAY, 0);
  AddCommand('playresume', JRC_ID_PLAY_RESUME, 0);
  AddCommand('prevtrack', JRC_ID_PREV_TRACK, 0);
  AddCommand('nexttrack', JRC_ID_NEXT_TRACK, 0);
  AddCommand('cyclerepeatmode', JRC_ID_REPEATMODE, 0);
  for RepMode := Low(eRepeatMode) to High(eRepeatMode) do begin
    AddCommand('setrepeat' + RepeatModeNames[RepMode], JRC_ID_REPEATMODE,
        Integer(RepMode) + 1);
  end;
  AddCommand('backward', JRC_ID_BACKWARD, 0);
  AddCommand('forward', JRC_ID_FORWARD, 0);
  AddCommand('cycleplaymode', JRC_ID_RANDOMMODE, 0);
  for RandMode := Low(eRandomMode) to High(eRandomMode) do begin
    AddCommand('setplaymode' + RandomModeNames[RandMode], JRC_ID_RANDOMMODE,
        Integer(RandMode) + 1);
  end;
  AddCommand('playslower', JRC_ID_PLAY_SLOW, 0);
  AddCommand('playfaster', JRC_ID_PLAY_FAST, 0);
  AddCommand('volumedown', JRC_ID_VOL_DOWN, 0);
  AddCommand('volumeup', JRC_ID_VOL_UP, 0);
  AddCommand('exit', JRC_ID_EXIT, 0);
  AddCommand('togglemute', JRC_ID_ATT, 0);
  {AddCommand('muteon', JRC_ID_ATT, 1);
  AddCommand('muteoff', JRC_ID_ATT, $FFFF);} // doesn't work
  AddCommand('screen1x', JRC_ID_SCREEN_1X, 0);
  AddCommand('screen2x', JRC_ID_SCREEN_2X, 0);
  AddCommand('screenfull', JRC_ID_SCREEN_FULL, 0);
  AddCommand('togglefullscreen', JRC_ID_CHANGE_SCREEN_SIZE, 0);
  AddCommand('minimizerestore', JRC_ID_MINIMIZE, 0);
  AddCommand('togglewidemode', JRC_ID_CHANGE_SFX_WIDE, 0);
  AddCommand('togglexbassmode', JRC_ID_CHANGE_SFX_XBASS, 0);
  AddCommand('togglebbemode', JRC_ID_CHANGE_SFX_BBE, 0);
  AddCommand('togglebbevivamode', JRC_ID_CHANGE_SFX_B3D, 0);
  // for some reason, JRC_ID_CHANGE_SFX_XFADE and JRC_ID_CHANGE_SFX_XSR got
  // mixed up in the API
  AddCommand('togglecrossfade', JRC_ID_CHANGE_SFX_XSR, 0);
  AddCommand('togglexsurround', JRC_ID_CHANGE_SFX_XFADE, 0);
  AddCommand('eject', JRC_ID_EJECT_DRIVE, 0);
  AddCommand('toggletray', JRC_ID_GOTO_TRAY, 0);
  AddCommand('refreshalbum', JRC_ID_ALBUM_REFRESH, 0);
  AddCommand('sortalbum', JRC_ID_ALBUM_SORT, 0);
  AddCommand('goup', JRC_ID_GOUP, 0);
  AddCommand('cyclelang', JRC_ID_DVD_CHANGE_LANGUAGE, 0);
  AddCommand('cyclesubtitle', JRC_ID_DVD_CHANGE_SUBTITLE, 0);
  AddCommand('cycleangle', JRC_ID_DVD_CHANGE_ANGLE, 0);
  AddCommand('togglesubtitle', JRC_ID_DVD_SUBTITLE_FLAG, 0);
  AddCommand('titlemenu', JRC_ID_DVDMENU_TITLE, 0);
  AddCommand('rootmenu', JRC_ID_DVDMENU_ROOT, 0);
  AddCommand('up', JRC_ID_DVD_BUTTON, VK_UP);
  AddCommand('down', JRC_ID_DVD_BUTTON, VK_DOWN);
  AddCommand('left', JRC_ID_DVD_BUTTON, VK_LEFT);
  AddCommand('right', JRC_ID_DVD_BUTTON, VK_RIGHT);
  AddCommand('enter', JRC_ID_DVD_BUTTON, VK_RETURN);
end;

const
  AspectModeCommands: array[eAspectMode] of String =
      ('aspectoriginal', 'aspect43', 'aspect169', 'aspect1851', 'aspect2351');

procedure TJFLircPlugin.FillMenuCommands;
var
  Aspect: eAspectMode;
begin
  for Aspect := Low(eAspectMode) to High(eAspectMode) do begin
    fMenuCommands.Insert(AspectModeCommands[Aspect],
        Pointer(AspectMenuId + Integer(Aspect)));
  end;
end;

procedure TJFLircPlugin.FillMonitorCommands;
const
  MaxMonitorIdx = 9;
var
  i: Integer;
begin
  fMonitorCommands.Insert('cyclemonitor', Pointer(-1));
  for i := 1 to MaxMonitorIdx do // start from 1 (most users aren't programmers)
    fMonitorCommands.Insert('setmonitor' + IntToStr(i), Pointer(i - 1));
end;

procedure TJFLircPlugin.CreateAndOpenIniFile;
var
  IniDir: String;  
begin
  IniDir := AddBackSlash(GetShellFolderByCSIDL(CSIDL_APPDATA, True))
      + 'COWON\JetAudio';
  if not CreateDirectory(PChar(IniDir), nil)
      and (GetLastError <> ERROR_ALREADY_EXISTS) then
    IniDir := '';
  fIniFile := TIniFile.Create(AddBackSlash(IniDir) + 'JFLirc.ini');
end;

procedure TJFLircPlugin.ReadWriteSettings(Write: Boolean);

  procedure ReadWriteInteger(const Ident: String; var Value: Integer;
      Default: Integer);
  begin
    if Write then
      fIniFile.WriteInteger(IniSection, Ident, Value)
    else
      Value := fIniFile.ReadInteger(IniSection, Ident, Default);
  end;
  procedure ReadWriteString(const Ident: String; var Value: String;
      Default: String);
  begin
    if Write then
      fIniFile.WriteString(IniSection, Ident, Value)
    else
      Value := fIniFile.ReadString(IniSection, Ident, Default);
  end;
  procedure ReadWriteBool(const Ident: String; var Value: Boolean;
      Default: Boolean);
  begin
    if Write then
      fIniFile.WriteBool(IniSection, Ident, Value)
    else
      Value := fIniFile.ReadBool(IniSection, Ident, Default);
  end;

var
  i: Integer;
begin
  if Assigned(fIniFile) then begin
    ReadWriteString('WinLircHost', fWinLircHost, DefaultHost);
    ReadWriteInteger('WinLircPort', fWinLircPort, DefaultPort);
    ReadWriteString('WinLircServer', fWinLircServer, '');
    ReadWriteInteger('MaxRetries', fMaxRetries, DefaultMaxRetries);
    ReadWriteBool('NoConnectFailedWarning', fNoConnectFailedWarning, False);
    if not Write then begin
      ClearMappedKeys;
      fIniFile.ReadSection(KeysSection, fMappedKeys);
      for i := 0 to fMappedKeys.Count - 1 do begin
        fMappedKeys.Objects[i] :=
            RefString(fIniFile.ReadString(KeysSection, fMappedKeys[i], ''));
      end;
      ResolveMappings;
    end;
  end
  else if not Write then begin
    fWinLircHost := DefaultHost;
    fWinLircPort := DefaultPort;
    fWinLircServer := '';
    fMaxRetries := DefaultMaxRetries;
    fNoConnectFailedWarning := False;
  end;
end;

procedure TJFLircPlugin.ResolveMappings;
var
  i: Integer;
  pCommandStr: Pointer;
  CommandStr: String;
  Command: TJACommand;
  CommandParam: Pointer;
begin
  fMappedCommands.Empty;
  for i := 0 to fMappedKeys.Count - 1 do begin
    Command := nil;
    pCommandStr := fMappedKeys.Objects[i];
    if Assigned(pCommandStr) then begin
      CommandStr := String(pCommandStr);
      if fStandardCommands.Search(CommandStr, CommandParam) then
        Command := TStandardJACommand.Create(Self, Integer(CommandParam));
      if fModeCommands.Search(CommandStr, CommandParam) then
        Command := TModeJACommand.Create(Self, TJAMode(CommandParam));
      if fMenuCommands.Search(CommandStr, CommandParam) then
        Command := TMenuJACommand.Create(Self, Integer(CommandParam));
      if fMonitorCommands.Search(CommandStr, CommandParam) then
        Command := TSwitchMonitorCommand.Create(Self, Integer(CommandParam));
    end;
    fMappedCommands.Insert(fMappedKeys[i], Command);
  end;
end;

procedure TJFLircPlugin.ClearMappedKeys;
var
  P: Pointer;
begin
  while fMappedKeys.Count > 0 do begin
    P := fMappedKeys.Objects[0];
    fMappedKeys.Delete(0);
    if Assigned(P) then
      ReleaseString(P);
  end;
end;

procedure TJFLircPlugin.HandleException(E: Exception);
var
  Info: String;
begin
  if Assigned(E) then
    Info := CrLf + '(' + E.ClassName + ' : ' + E.Message + ')';
  MessageBox(fHwndMain, PChar('An unexpected error occurred.' + Info + CrLf2
      + 'Please contact the author if the problems persists.'),
      PluginName, MB_ICONERROR);
end;

end.
