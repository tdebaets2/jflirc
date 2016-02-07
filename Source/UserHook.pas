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
 * jetAudio User32.dll API hook
 *
 ****************************************************************************)

unit UserHook;

interface

uses Windows, Messages, SysUtils, Common2;

type
  TTrackPopupMenuEx = function(hMenu: HMENU; Flags: UINT; x, y: Integer;
      hWnd: HWND; TPMParams: Pointer): BOOL; stdcall;

type
  TUserFunc = (TrackPopupMenuEx);
  TUserFuncAddresses = array[TUserFunc] of Pointer;

const
  UserFuncNames: array[TUserFunc] of PChar = ('TrackPopupMenuEx');

var
  PrevUserFuncs: TUserFuncAddresses;
  UserFuncs: TUserFuncAddresses;

implementation

uses ApiHook, JFLircPluginClass;

function NewTrackPopupMenuEx(hMenu: HMENU; Flags: UINT; x, y: Integer;
    hWnd: HWND; TPMParams: Pointer): BOOL; stdcall;
var
  MenuId: Integer;
begin
  Result := False;
  try
    if Assigned(JFLircPlugin) then begin
      MenuId := JFLircPlugin.FakeContextMenuId;
      if MenuId <> 0 then begin
        Result := BOOL(MenuId);
        SetLastError(0);
        Exit;
      end;
    end;
    Result := TTrackPopupMenuEx(PrevUserFuncs[TrackPopupMenuEx])(hMenu, Flags,
        x, y, hWnd, TPMParams);
  except
    on E: Exception do
      OutException(E, 'NewTrackPopupMenu');
  end;
end;

initialization
  FillChar(PrevUserFuncs, SizeOf(PrevUserFuncs), 0);
  UserFuncs[TrackPopupMenuEx] := @NewTrackPopupMenuEx;

end.
