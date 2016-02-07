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
 * Main project file
 *
 ****************************************************************************)

library JFLirc;

uses
  Windows,
  SysUtils,
  Classes,
  Common2,
  JFBase in 'JFBase.pas',
  JFGeneral in 'JFGeneral.pas',
  ThisCall in 'ThisCall.pas',
  JDefine in 'JDefine.pas',
  JetAudio6_API in 'JetAudio6_API.pas',
  UserHook in 'UserHook.pas',
  ApiHook in 'ApiHook.pas',
  JetAudioUtil in 'JetAudioUtil.pas',
  JFLircPluginClass in 'JFLircPluginClass.pas',
  JetAudio6_Const in 'JetAudio6_Const.pas',
  JFLircCommands in 'JFLircCommands.pas';

{$R Version.res}

function JPluginCreate(pszStoreRoot: PAnsiChar): Pointer; cdecl;
var
  Plugin: TJFLircPlugin;
begin
  Result := nil;
  try
    Plugin := TJFLircPlugin.Create;
    {if not Assigned(Plugin.ThisCallThunks) then
      Plugin.ThisCallThunks := TThisCallThunks.Create(Plugin, 13);}
    Result := Plugin;
    if not ApiHooked then
      ApiHooked := HookModule(GetModuleHandle(nil), ParamStr(0), True);
    // prevent dll from unloading
    LockModuleIntoProcess(hInstance);
  except
    MessageBox(0, 'Error while initializing WinLIRC Plug-in.', PluginName,
        MB_ICONSTOP or MB_TASKMODAL);
  end;
end;

exports
  JPluginCreate;

begin
  DisableThreadLibraryCalls(hInstance);
  Set8087CW($133f);
  IsMultiThread := True;
end.
