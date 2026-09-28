@echo off
setlocal EnableDelayedExpansion
REM ==========================================================================
REM  KPlayer build script  (rules: D:\Source\Lazarus\INIT.md - 64-bit only, Release -> Z:\Release)
REM
REM    build              Release build -> Z:\Release\KPlayer.exe
REM    build debug        Debug build   -> KPlayer.exe (project folder)
REM    build both         Debug + Release
REM    build clean        remove build output (lib\, release\)
REM
REM  Options
REM    /b      full rebuild (lazbuild -B)
REM    /nogen  skip resource regeneration (KPlayerResource.res)
REM
REM  KPlayerResource.res (translate.txt, KPlayer.lua, Res\*.png) is rebuilt by
REM  Tools\MakeRes.py when a source is newer - windres is not used, the copy that
REM  ships with Lazarus has no C preprocessor and dies with "preprocessing failed".
REM  KPlayerIcons.res (Icon\*.ico) and Res\*.png are NOT rebuilt here - run
REM  Tools\MakeIconRes.py / Tools\MakeListIcons.py by hand and commit the output.
REM  After a Release build copy Z:\Release\KPlayer.exe to D:\Vendor\KPlayer before
REM  compiling KPlayer.iss (the installer reads the exe and its version from there).
REM  Keep this file ASCII only - cmd misreads UTF-8 batch files.
REM ==========================================================================

cd /d "%~dp0"
set "PROJ=KPlayer.lpi"
set "RELDIR=release"
set "DODBG=0"
set "DOREL=1"
set "ALL="
set "GEN=1"

:args
if "%~1"=="" goto args_done
set "A=%~1"
if /i "!A!"=="debug" (
  set "DODBG=1"
  set "DOREL=0"
) else if /i "!A!"=="release" (
  set "DODBG=0"
  set "DOREL=1"
) else if /i "!A!"=="both" (
  set "DODBG=1"
  set "DOREL=1"
) else if /i "!A!"=="clean" (
  goto clean
) else if /i "!A!"=="/b" (
  set "ALL=-B"
) else if /i "!A!"=="-b" (
  set "ALL=-B"
) else if /i "!A!"=="/nogen" (
  set "GEN=0"
) else if /i "!A!"=="/?" (
  goto usage
) else (
  echo [!] unknown argument: !A!
  goto usage
)
shift
goto args
:args_done

REM ---- locate lazbuild -----------------------------------------------------
set "LAZBUILD="
if defined LAZARUSDIR if exist "%LAZARUSDIR%\lazbuild.exe" set "LAZBUILD=%LAZARUSDIR%\lazbuild.exe"
if not defined LAZBUILD if exist "D:\lazarus\lazbuild.exe" set "LAZBUILD=D:\lazarus\lazbuild.exe"
if not defined LAZBUILD if exist "C:\lazarus\lazbuild.exe" set "LAZBUILD=C:\lazarus\lazbuild.exe"
if not defined LAZBUILD for %%P in (lazbuild.exe) do if not "%%~$PATH:P"=="" set "LAZBUILD=%%~$PATH:P"
if not defined LAZBUILD (
  echo [FAIL] lazbuild.exe not found. Set LAZARUSDIR or install Lazarus in D:\lazarus.
  exit /b 1
)

REM ---- generated resources -------------------------------------------------
if "%GEN%"=="1" (
  call :res
  if errorlevel 1 exit /b 1
)

REM ---- build ---------------------------------------------------------------
if "%DODBG%"=="1" (
  call :build Debug
  if errorlevel 1 exit /b 1
  call :report "KPlayer.exe"
)

if "%DOREL%"=="1" (
  if not exist "%RELDIR%" mkdir "%RELDIR%"
  call :build Release
  if errorlevel 1 exit /b 1
  call :symbols "%RELDIR%\KPlayer.exe"
  if errorlevel 1 exit /b 1
  call :deploy "%RELDIR%\KPlayer.exe" "Z:\Release"
  if errorlevel 1 exit /b 1
  call :report "Z:\Release\KPlayer.exe"
)

echo.
echo Build done.
exit /b 0

REM ==========================================================================
:build
echo.
echo === %~1 build ===
"%LAZBUILD%" --build-mode=%~1 %ALL% "%PROJ%"
if errorlevel 1 (
  echo.
  echo [FAIL] %~1 build failed.
  exit /b 1
)
exit /b 0

REM :deploy exe destdir  - put the release exe in the deliverable folder
REM   Link into %RELDIR% (local), never straight into Z:\Release - the linker writes a
REM   ~28MB .dbg next to the exe. Symbols are filed first, then only the exe is copied.
REM   Copy + compare: a running KPlayer.exe locks the target and the copy fails -
REM   printing "Build done." then would pass an old build off as a new one.
:deploy
set "DSRC=%~1"
set "DDIR=%~2"
if not exist "!DSRC!" (
  echo [ERROR] release exe not found: !DSRC!
  exit /b 1
)
if not exist "!DDIR!\" (
  echo [ERROR] !DDIR! not found. Check the drive mapping ^(INIT.md^).
  exit /b 1
)
copy /y "!DSRC!" "!DDIR!\%~nx1" >nul
if errorlevel 1 (
  echo [ERROR] copy failed: !DDIR!\%~nx1
  echo         It may be running, or !DDIR! may be full.
  exit /b 1
)
fc /b "!DSRC!" "!DDIR!\%~nx1" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] !DDIR!\%~nx1 differs from the build output.
  exit /b 1
)
exit /b 0

REM :symbols exe  - file the -Xg symbols in the archive (INIT.md)
REM   release\KPlayer.dbg  ->  D:\Vendor\KPlayer\KPlayer-<version>.dbg
REM   MOVE, not copy, and BEFORE :deploy - a stale .dbg must not be filed after a
REM   build that did not relink. Fails the build when the symbols cannot be filed.
REM   D:\Vendor\KPlayer is also the installer source folder: KPlayer.iss lists its
REM   [Files] one by one (no wildcard), so the .dbg never gets packed.
:symbols
set "SEXE=%~1"
set "SDBG=%~dpn1.dbg"
set "SSTORE=D:\Vendor\%~n1"
set "SVER="
for /f "delims=" %%V in ('powershell -NoProfile -Command "$v=(Get-Item '!SEXE!').VersionInfo; '{0}.{1}.{2}.{3}' -f $v.FileMajorPart,$v.FileMinorPart,$v.FileBuildPart,$v.FilePrivatePart"') do set "SVER=%%V"
if not defined SVER (
  echo [ERROR] could not read the version resource of !SEXE!
  exit /b 1
)
if "!SVER!"=="0.0.0.0" (
  echo [ERROR] !SEXE! carries no version - the archived file name would be meaningless.
  exit /b 1
)
set "SDEST=!SSTORE!\%~n1-!SVER!.dbg"
if not exist "!SDBG!" (
  if exist "!SDEST!" (
    echo [dbg] nothing relinked - symbols already filed: !SDEST!
    exit /b 0
  )
  echo [ERROR] no !SDBG! and none in the archive.
  echo         Check ^<UseExternalDbgSyms^> / -Xg in the Release mode of %PROJ%.
  exit /b 1
)
if not exist "!SSTORE!\" mkdir "!SSTORE!" 2>nul
if not exist "!SSTORE!\" (
  echo [ERROR] cannot create !SSTORE! - symbols left at !SDBG!
  exit /b 1
)
move /y "!SDBG!" "!SDEST!" >nul
if errorlevel 1 (
  echo [ERROR] could not move the symbols - left at !SDBG!
  exit /b 1
)
if exist "!SDBG!" (
  echo [ERROR] !SDBG! is still in the build folder.
  exit /b 1
)
echo [dbg] symbols -^> !SDEST!
exit /b 0

REM :res  - rebuild KPlayerResource.res when the .rc or a file it lists is newer
:res
set "NEED=0"
REM No pipes in here: a caret does not escape "|" inside the quoted command, powershell gets "^|".
for /f %%R in ('powershell -NoProfile -Command "$t='KPlayerResource.res'; $s=@('KPlayerResource.rc','translate.txt','KPlayer.lua') + (Get-ChildItem 'Res' -File).FullName; if(-not (Test-Path $t)){'1'}else{$tt=(Get-Item $t).LastWriteTime; if(@($s.Where({(Test-Path $_) -and ((Get-Item $_).LastWriteTime -gt $tt)})).Count -gt 0){'1'}else{'0'}}"') do set "NEED=%%R"
if not "!NEED!"=="1" exit /b 0
where python >nul 2>&1
if errorlevel 1 (
  echo [FAIL] python not found - KPlayerResource.res is out of date.
  exit /b 1
)
echo [res] KPlayerResource.res
python "Tools\MakeRes.py"
if errorlevel 1 (
  echo [FAIL] Tools\MakeRes.py failed.
  exit /b 1
)
exit /b 0

:report
if exist %1 (
  for %%F in (%1) do echo      %%~fF   %%~zF bytes   %%~tF
) else (
  echo [!] %1 was not produced.
)
exit /b 0

:clean
echo [clean] removing lib\, %RELDIR%\
if exist "lib" rmdir /s /q "lib"
if exist "%RELDIR%" rmdir /s /q "%RELDIR%"
del /q *.o *.ppu *.or *.compiled 2>nul
echo Done.
exit /b 0

:usage
echo.
echo   build [release ^| debug ^| both ^| clean] [/b] [/nogen]
echo.
echo     release   Release build (default) - Z:\Release\KPlayer.exe
echo     debug     Debug build - KPlayer.exe
echo     both      both modes
echo     clean     remove build output
echo     /b        full rebuild
echo     /nogen    do not regenerate KPlayerResource.res
exit /b 1
