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
 * jetAudio general plug-in base class
 *
 ****************************************************************************)

unit JFGeneral;

interface

uses Windows, JFBase;

type
  TJFGeneral = class(TJFBase)
  public
    function Open(hWnd: HWND; pszRootDir: PAnsiChar; dwReserved1: DWORD;
        dwReserved2: DWORD): BOOL; virtual; stdcall; abstract;
    function Close: BOOL; virtual; stdcall; abstract;

    function OnTimer(nCounter: Integer): BOOL; virtual; stdcall; abstract;
    function OnEvent(uEvent: UINT; wParam: WPARAM; lParam: LPARAM): UINT;
        virtual; stdcall; abstract;
  end;

implementation

end.
