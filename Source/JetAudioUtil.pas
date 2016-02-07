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
 * jetAudio-related utility code
 *
 ****************************************************************************)

unit JetAudioUtil;

interface

uses Windows, JetAudio6_API;

type
  TJAMode = (jamDisc, jamFile);

const
  JAModes: array[TJAMode] of Integer = (CMP_CDP, CMP_DGA);

const
  AspectMenuId = 6570;

function JAGetRemoconWindow: HWND;
function JAGetVideoWindow(JAWindow: HWND): HWND;

implementation

const
  RemoconClass = 'COWON Jet-Audio Remocon Class';
  RemoconTitle = 'Jet-Audio Remote Control';

function JAGetRemoconWindow: HWND;
begin
  Result := FindWindow(RemoconClass, RemoconTitle);
end;

const
  VideoWndClass = 'COWON Jet-Audio Video Viewer Window';
  VideoWndTitle = 'Jet-Audio Video Viewer Window';

function EnumJAThreadWndProc(hWin: HWND; PhJAVideoWnd: PInteger): BOOL; stdcall;
var
  hWndVideo: HWND;
begin
  Result := True;
  hWndVideo := FindWindowEx(hWin, 0, VideoWndClass, VideoWndTitle);
  if hWndVideo <> 0 then begin
    if Assigned(PhJAVideoWnd) then
      PhJAVideoWnd^ := GetParent(hWndVideo);
    Result := False;
  end;
end;

function JAGetVideoWindow(JAWindow: HWND): HWND;
var
  ThreadID: Integer;
begin
  Result := 0;
  ThreadID := GetWindowThreadProcessId(JAWindow, nil);
  EnumThreadWindows(ThreadID, @EnumJAThreadWndProc, Integer(@Result));
end;

end.
