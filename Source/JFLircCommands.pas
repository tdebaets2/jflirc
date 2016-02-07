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
 * Hotkey command implementations
 *
 ****************************************************************************)

unit JFLircCommands;

interface

uses Windows, Messages, Classes, SysUtils, Common2, JetAudioUtil,
    JFLircPluginClass;

type
  TJACommand = class
  public
    constructor Create(Owner: TJFLircPlugin);
    procedure Execute; virtual; abstract;
  private
    fOwner: TJFLircPlugin;
  end;

  TModeJACommand = class(TJACommand)
  public
    constructor Create(Owner: TJFLircPlugin; Mode: TJAMode);
    procedure Execute; override;
  private
    fMode: TJAMode;
  end;

  TStandardJACommand = class(TJACommand)
  public
    constructor Create(Owner: TJFLircPlugin; LParam: Integer);
    procedure Execute; override;
  private
    fLParam: Integer;
  end;

  TMenuJACommand = class(TJACommand)
  public
    constructor Create(Owner: TJFLircPlugin; MenuId: Integer);
    procedure Execute; override;
  private
    fMenuId: Integer;
  end;

  TSwitchMonitorCommand = class(TJACommand)
  public
    constructor Create(Owner: TJFLircPlugin; MonitorIdx: Integer);
    destructor Destroy; override;
    procedure Execute; override;
  private
    fMonitors: TList;
    fMonitorIdx: Integer;
  end;

implementation

uses JetAudio6_API, MonitorFunc, MultiMon;

constructor TJACommand.Create(Owner: TJFLircPlugin);
begin
  fOwner := Owner;
end;

constructor TModeJACommand.Create(Owner: TJFLircPlugin; Mode: TJAMode);
begin
  inherited Create(Owner);
  fMode := Mode;
end;

procedure TModeJACommand.Execute;
begin
  if fOwner.hWndRemocon <> 0 then begin
    SendMessage(fOwner.hWndRemocon, WM_REMOCON_CHANGE_COMPONENT,
        JAModes[fMode], 0);
  end;
end;

constructor TStandardJACommand.Create(Owner: TJFLircPlugin; LParam: Integer);
begin
  inherited Create(Owner);
  fLParam := LParam;
end;

procedure TStandardJACommand.Execute;
begin
  if fOwner.hWndRemocon <> 0 then
    SendMessage(fOwner.hWndRemocon, WM_REMOCON_SENDCOMMAND, 0, fLParam);
end;

constructor TMenuJACommand.Create(Owner: TJFLircPlugin; MenuId: Integer);
begin
  inherited Create(Owner);
  fMenuId := MenuId;
end;

procedure TMenuJACommand.Execute;
var
  hWndVideo: HWND;
begin
  if fOwner.hWndRemocon <> 0 then begin
    hWndVideo := JAGetVideoWindow(fOwner.hWndRemocon);
    if (hWndVideo <> 0) and ApiHooked then begin
      fOwner.FakeContextMenuId := fMenuId;
      try
        SendMessage(hWndVideo, WM_CONTEXTMENU, 0, 0);
      finally
        fOwner.FakeContextMenuId := 0;
      end;
    end;
  end;
end;

constructor TSwitchMonitorCommand.Create(Owner: TJFLircPlugin;
    MonitorIdx: Integer);
begin
  inherited Create(Owner);
  fMonitors := TList.Create;
  fMonitorIdx := MonitorIdx;
end;

destructor TSwitchMonitorCommand.Destroy;
begin
  FreeAndNil(fMonitors);
end;

procedure TSwitchMonitorCommand.Execute;
  procedure ToggleFullScreen;
  begin
    SendMessage(fOwner.hWndRemocon, WM_REMOCON_SENDCOMMAND, 0,
        MAKELPARAM(JRC_ID_CHANGE_SCREEN_SIZE, 0));
  end;
var
  hWndVideo: HWND;
  FullScreen: Boolean;
  CurrentMon: HMONITOR;
  CurrentMonIdx, NewMonIdx: Integer;
  MonInfo: MonitorInfo;
  VideoRect: TRect;
  MonitorWidth, MonitorHeight, VideoWidth, VideoHeight: Integer;
begin
  if fOwner.hWndRemocon = 0 then
    Exit;
  hWndVideo := JAGetVideoWindow(fOwner.hWndRemocon);
  if hWndVideo = 0 then
    Exit;
  if not GetDisplayMonitors(fMonitors) then
    Exit;
  if fMonitors.Count <= 1 then
    Exit;
  if fMonitorIdx >= fMonitors.Count then
    Exit;
  CurrentMon := MonitorFromWindow(hWndVideo, MONITOR_DEFAULTTOPRIMARY);
  CurrentMonIdx := fMonitors.IndexOf(Pointer(CurrentMon));
  if fMonitorIdx = -1 then
    NewMonIdx := CurrentMonIdx + 1
  else
    NewMonIdx := fMonitorIdx;
  if NewMonIdx >= fMonitors.Count then
    NewMonIdx := 0;
  if CurrentMonIdx = NewMonIdx then
    Exit;
  FillChar(MonInfo, SizeOf(MonInfo), 0);
  MonInfo.cbSize := SizeOf(MonInfo);
  if not GetMonitorInfo(HMONITOR(fMonitors[NewMonIdx]), @MonInfo) then
    Exit;
  if not GetWindowRect(hWndVideo, VideoRect) then
    Exit;
  FullScreen := (SendMessage(fOwner.hWndRemocon, WM_REMOCON_GETSTATUS, 0,
      GET_STATUS_SCREEN_MODE) = 1);
  if FullScreen then
    ToggleFullScreen;
  try
    MonitorWidth := MonInfo.rcWork.Right - MonInfo.rcWork.Left;
    MonitorHeight := MonInfo.rcWork.Bottom - MonInfo.rcWork.Top;
    VideoWidth := VideoRect.Right - VideoRect.Left;
    VideoHeight := VideoRect.Bottom - VideoRect.Top;
    { For some reason, SetWindowPos doesn't seem to work correctly when in full
      screen mode }
    {SetWindowPos(hWndVideo, 0,
        Round(MonInfo.rcWork.Left + (MonitorWidth - VideoWidth) / 2),
        Round(MonInfo.rcWork.Top + (MonitorHeight - VideoHeight) / 2),
        0, 0,
        SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);}
    MoveWindow(hWndVideo,
        Round(MonInfo.rcWork.Left + (MonitorWidth - VideoWidth) / 2),
        Round(MonInfo.rcWork.Top + (MonitorHeight - VideoHeight) / 2),
        VideoWidth, VideoHeight, True);
  finally
    if FullScreen then
      ToggleFullScreen;
  end;
end;

end.
