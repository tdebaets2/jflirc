@echo off

rem **************************************************************************
rem *
rem *            WinLIRC plug-in for jetAudio
rem *
rem *            Copyright (c) 2016 Tim De Baets
rem *
rem **************************************************************************
rem *
rem * Licensed under the Apache License, Version 2.0 (the "License");
rem * you may not use this file except in compliance with the License.
rem * You may obtain a copy of the License at
rem *
rem *     http://www.apache.org/licenses/LICENSE-2.0
rem *
rem * Unless required by applicable law or agreed to in writing, software
rem * distributed under the License is distributed on an "AS IS" BASIS,
rem * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem * See the License for the specific language governing permissions and
rem * limitations under the License.
rem *
rem **************************************************************************
rem *
rem * Compile script
rem *
rem **************************************************************************

setlocal

set CFGFILE=
set OLDCFGFILE=

rem  Quiet compile / Build all / Output warnings
set DCC32OPTS=-Q -B -W

rem  Generate semi-unique string for temporary file renames
for /f "delims=:., tokens=1-4" %%t in ("%TIME: =0%") do (
    set UNIQUESTR=%%t%%u%%v%%w
)

rem  Retrieve user-specific compile settings from file

if exist usercompilesettings.bat goto usercompilesettingsfound
:usercompilesettingserror
echo usercompilesettings.bat is missing or incomplete. It needs to be created
echo with the following lines, adjusted for your system:
echo.
echo   set DELPHIROOT=c:\delphi4              [Path to Delphi 4 (or later)]
goto failed2

:usercompilesettingsfound
set DELPHIROOT=
call .\usercompilesettings.bat
if "%DELPHIROOT%"=="" goto usercompilesettingserror

for /F %%i in ('dir /b /a "common\*"') do (
    rem common submodule folder not empty, ok
    goto commonok
)

echo The common subdirectory is still empty; did you run postclone.bat yet?
goto failed2

:commonok
set LIB_PATH=..\common\Delphi\LibFixed;%DELPHIROOT%\lib;..\common\Delphi\LibUser;..\common\Delphi\Imports

rem -------------------------------------------------------------------------

rem  Compile each project separately because it seems Delphi carries some
rem  settings (e.g. $APPTYPE) between projects if multiple projects are
rem  specified on the command line.

rem  Always use 'master' .cfg file when compiling from the command line to
rem  prevent user options from hiding compile failures in official builds.
rem  Temporarily rename any user-generated .cfg file during compilation.

cd Source
if errorlevel 1 goto failed

echo - JFLirc.dpr

rem  Rename user-generated .cfg file if it exists
if not exist JFLirc.cfg goto jflirc
ren JFLirc.cfg JFLirc.cfg.%UNIQUESTR%
if errorlevel 1 goto failed
set OLDCFGFILE=JFLirc.cfg

:jflirc
ren JFLirc.cfg.main JFLirc.cfg
if errorlevel 1 goto failed
set CFGFILE=JFLirc.cfg
"%DELPHIROOT%\bin\dcc32.exe" %DCC32OPTS% %1 ^
    -U"%LIB_PATH%" ^
    -R"%DELPHIROOT%\lib" ^
    -E..\Output ^
    JFLirc.dpr
if errorlevel 1 goto failed
ren %CFGFILE% %CFGFILE%.main
set CFGFILE=
if not "%OLDCFGFILE%"=="" ren %OLDCFGFILE%.%UNIQUESTR% %OLDCFGFILE%
set OLDCFGFILE=

echo Success!
cd ..
goto exit

:failed
if not "%CFGFILE%"=="" ren %CFGFILE% %CFGFILE%.main
if not "%OLDCFGFILE%"=="" ren %OLDCFGFILE%.%UNIQUESTR% %OLDCFGFILE%
echo *** FAILED ***
cd ..
:failed2
exit /b 1

:exit
