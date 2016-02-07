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
 * Helper class to make stdcall virtual methods callable as thiscall
 *
 ****************************************************************************)

unit ThisCall;

interface

uses Windows, Classes;

type
  PPointer = ^Pointer;
  
  // thunk for translating thiscall calls to stdcall (ECX -> stack)
  TThisCallThunk = record
    PopEAX: Byte;       // $58, pop ret address from stack
    PushECX: Byte;      // $51, push 'this' argument
    PushEAX: Byte;      // $50, push ret address back to stack
    Jmp: Byte;          // $E9, relative jump
    JmpAddress: DWORD;  // original proc - addr(TThisCallThunk) - sizeof(TThisCallThunk)
  end;
  PThisCallThunk = ^TThisCallThunk;

  TThisCallThunks = class
  public
    constructor Create(Obj: TObject; NumVirtualMethods: Integer);
    destructor Destroy; override;
  private
    fThunks: TList;
    procedure PatchMethod(PVTable: Pointer; MethodIdx: Integer);
    procedure FreeThunks;
  end;

implementation

constructor TThisCallThunks.Create(Obj: TObject; NumVirtualMethods: Integer);
var
  i: Integer;
begin
  inherited Create;
  fThunks := TList.Create;
  for i := 0 to NumVirtualMethods - 1 do
    PatchMethod(PPointer(Obj)^, i);
end;

destructor TThisCallThunks.Destroy;
begin
  FreeThunks;
  fThunks.Free;
  inherited Destroy;
end;

procedure TThisCallThunks.PatchMethod(PVTable: Pointer; MethodIdx: Integer);
var
  pThunk: PThisCallThunk;
  pTableEntry: Pointer;
  OrigAddress: Pointer;
  Bytes: Cardinal;
begin
  pTableEntry := Pointer(Integer(PVTable) + MethodIdx * SizeOf(Pointer));
  OrigAddress := PPointer(pTableEntry)^;
  // DEP compatible!
  pThunk := VirtualAlloc(nil, SizeOf(TThisCallThunk), MEM_COMMIT,
      PAGE_EXECUTE_READWRITE);
  pThunk.PopEAX := $58;
  pThunk.PushECX := $51;
  pThunk.PushEAX := $50;
  pThunk.Jmp := $E9;
  pThunk.JmpAddress := Integer(OrigAddress) - Integer(pThunk) -
      SizeOf(TThisCallThunk);
  if WriteProcessMemory(GetCurrentProcess, pTableEntry, @pThunk, SizeOf(Pointer),
      Bytes) then
    fThunks.Add(pThunk)
  else
    VirtualFree(pThunk, SizeOf(TThisCallThunk), MEM_DECOMMIT);
end;

procedure TThisCallThunks.FreeThunks;
var
  pThunk: PThisCallThunk;
begin
  while fThunks.Count > 0 do begin
    pThunk := fThunks.First;
    fThunks.Delete(0);
    VirtualFree(pThunk, SizeOf(TThisCallThunk), MEM_DECOMMIT);
  end;
end;

end.
