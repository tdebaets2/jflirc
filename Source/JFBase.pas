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
 * jetAudio plug-in base class
 *
 ****************************************************************************)

unit JFBase;

interface

{$ALIGN ON}
{$MINENUMSIZE 4}

uses Windows, JDefine;

type
  TJFInfo = record
    // Filter does not use this variable. This is used internally by Host.
    m_szFileName: array[0..256-1] of Char;
    m_bActive: BOOL;

    // Filter should fill the following variables
    m_szFilterName: array[0..80-1] of Char;
    m_szFilterWriter: array[0..80-1] of Char;
    m_szFilterDesc: array[0..256-1] of Char;
    m_szFileExts: array[0..256-1] of Char;      // *.wav;*.avi; ...
    m_szFileExtsString: array[0..256-1] of Char;    // Windows Sounds (*.wav)|*.wav|

    m_uSDKVersion: UINT;          // Currently, this is 0x100

    m_uCategory: UINT;

    m_uInputDeviceType: UINT;
    m_uOutputDeviceType: UINT;

    m_uInputStreamType: UINT;
    m_uOutputStreamType: UINT;

    m_uCaps: UINT;

    m_bUnvisible: BOOL;          // Typically, this is "0"

    m_dwReserved: array[0..128-1] of DWORD;
  end;
  PJFInfo = ^TJFInfo;


type
  TJFBase = class
  public
    procedure CDestroy(Val: Integer); virtual; stdcall; abstract;
    procedure GetInfo(pInfo: PJFInfo); virtual; stdcall; abstract;
    function SetPropertyPTR(pszPropName: PAnsiChar; pVal: PAnsiChar;
        iValSize: Integer): BOOL; virtual; stdcall; abstract; { return FALSE; }
    function GetPropertyPTR(pszPropName: PAnsiChar; pVal: PAnsiChar;
        iValSize: Integer): BOOL; virtual; stdcall; abstract; { return FALSE; }
    function SetPropertyINT(pszPropName: PAnsiChar; nVal: Integer): BOOL;
        virtual; stdcall; abstract; { return FALSE; }
    function GetPropertyINT(pszPropName: PAnsiChar; pnVal: PInteger): BOOL;
        virtual; stdcall; abstract; { return FALSE; }

    procedure Config(hWnd: HWND); virtual; stdcall; abstract; { return; }
    procedure About(hWnd: HWND); virtual; stdcall; abstract; { return; }

    function GetErrorString(pszBuffer: PAnsiChar;
        nBufferSize: Integer): JERROR_TYPE;
        virtual; stdcall; abstract; { return JERROR_UNKNOWN; }
  end;

implementation

end.
