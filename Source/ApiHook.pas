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
 * jetAudio API hooking code
 *
 ****************************************************************************)

unit ApiHook;

interface

uses Windows, Classes, SysUtils, TlHelp32, PEStruct;

function HookModule(hMod: HMODULE; const Filename: String;
    IsExeModule: Boolean): Boolean;
procedure OutException(const E: Exception; ProcName: String);

implementation

uses UserHook;

var
  Thunk: PImageThunkData = nil;
  OrigUserProcs: TUserFuncAddresses;

function GetRealProcAddress(ProcAddr: Pointer): Pointer;
var
  P: PByte;
begin
  Result := ProcAddr;
  try
    P := ProcAddr;
    if P^ = $68 then
      Result := Pointer(PDWORD(DWORD(P) + 1)^);
  except
  end;
end;

function PatchModule(Filename: String; hMod: HMODULE;
    IsExeModule: Boolean): Shortint;
var
  OldProt: Integer;
  pNewExeHeader: Pointer;
  pNtHeaders: PImageNtHeaders;
  pImportDirectory: Pointer;
  pImpDesc: PImageImportDescriptor;
  pName: PChar;
  pThunk: PImageThunkData;
  i: Integer;
  UserPatched: Boolean;

  function RVAToAbsolute(Address: Pointer): Pointer;
  begin
    Result := PEStruct.RVAToAbsolute(Pointer(hMod), Address);
  end;

  function PatchFunctions(const OrigProcs, NewAddresses: array of Pointer;
      const ProcNames: array of PChar;
      var PrevAddresses: array of Pointer): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    pThunk := RVAToAbsolute(pImpDesc.FirstThunk);
    while pThunk.Ordinal <> 0 do begin
      for i := 0 to Integer(High(OrigProcs)) do begin
        if not Assigned(OrigProcs[i]) then
          Continue;
        if GetRealProcAddress(pThunk.AddressOfData) = OrigProcs[i] then begin
          Win32Check(VirtualProtect(@pThunk.AddressOfData, SizeOf(Pointer),
              PAGE_EXECUTE_READWRITE, @OldProt));
          try
            PrevAddresses[i] := pThunk.AddressOfData;
            pThunk.AddressOfData := NewAddresses[i];
            Result := True;
          finally
            Win32Check(VirtualProtect(@pThunk.AddressOfData, SizeOf(Pointer),
                OldProt, @OldProt));
          end;
          Thunk := pThunk;
          Break;
        end;
      end;
      Inc(pThunk);
    end;
  end;

begin
  Result := 10;
  UserPatched := False;
  try
    if hMod = 0 then
      Exit;
    Result := -18;
    if hMod = hInstance then // don't hook ourselves
      Exit;
    Result := -11;
    pNewExeHeader := Pointer(PImageDosHeader(hMod)^.E_lfanew);
    if not Assigned(pNewExeHeader) then
      Exit;
    pNtHeaders := PImageNtHeaders(RVAToAbsolute(pNewExeHeader));
    Result := -12;
    pImportDirectory :=
        Pointer(pNtHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress);
    if not Assigned(pImportDirectory) then
      Exit;
    pImpDesc := RVAToAbsolute(pImportDirectory);
    Result := -14;
    if IsExeModule then
       OutputDebugString(PChar('Patching ' + ParamStr(0)));
    for i := 0 to Integer(High(OrigUserProcs)) do begin
      OrigUserProcs[TUserFunc(i)] :=
          GetRealProcAddress(GetProcAddress(GetModuleHandle(User32),
          UserFuncNames[TUserFunc(i)]));
    end;
    Result := -15;
    while pImpDesc.FirstThunk <> nil do begin
      Result := -16;
      pName := RVAToAbsolute(pImpDesc.Name);
      Result := -17;
      if lstrcmpi(pName, User32) = 0 then begin
        if PatchFunctions(OrigUserProcs, UserFuncs, UserFuncNames,
            PrevUserFuncs) then
          UserPatched := True;
      end;
      Inc(pImpDesc);
    end;
    Result := Byte(UserPatched) * 2;
  except
    on E: Exception do
      OutException(E, 'PatchModule');
  end;
end;

function HookModule(hMod: HMODULE; const Filename: String;
    IsExeModule: Boolean): Boolean;
var
  ResultVal: ShortInt;
begin
  ResultVal := PatchModule(ExtractFileName(Filename), hMod, IsExeModule);
  OutputDebugString(PChar('Hooking of ' + Filename + ' : ' + IntToStr(ResultVal)));
  Result := (ResultVal > 0);
end;

procedure OutException(const E: Exception; ProcName: String);
begin
  OutputDebugString(PChar('Exception in ' + ProcName + ': ' + E.ClassName +
      ': ' + E.Message));
end;

end.
