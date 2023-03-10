@echo off

if not exist "chdman.exe" title ERROR&echo CHDMAN.EXE WAS NOT FOUND&pause&exit

if exist "%programfiles%\7-Zip\7z.exe" set "_7zip=%programfiles%\7-Zip\7z.exe"
if exist "%programfiles(x86)%\7-Zip\7z.exe" set "_7zip=%programfiles(x86)%\7-Zip\7z.exe"
if exist "c:\windows\system32\7z.exe" set "_7zip=7z"
if exist "7z.exe" set "_7zip=7z"
if "%_7zip%"=="" title ERROR&echo 7ZIP WAS NOT FOUND&pause&exit

for %%g in (*.dat *.xml) do set "_dat=%%g"
if "%_dat%"=="" echo NO DATAFILE .XML .DAT FOUND&title ERROR&pause&exit

set /a _total_lines=0
set /a _count_lines=0
for %%g in (*.chd *.zip *.7z) do set /a _total_lines+=1
title Overall Progress: %_count_lines% / %_total_lines% ^( 0 %% ^)

(echo "Zip File","CHD File","Version","SHA1","%_dat%","Raw SHA1","Overall SHA1")>output.csv

for %%g in (*.chd *.zip *.7z) do (
	echo %%g
	call :progress
	if not "%%~xg"==".chd" (
		call :unzip_verify "%%g"
	)else (
		call :verify_chd "%%g"
	)
	cls
)

del chdman.tmp
title FINISHED&pause&exit

:progress
set /a _count_lines+=1
set /a "_percent=(%_count_lines%*100)/%_total_lines%
title Overall Progress: %_count_lines% / %_total_lines% ^( %_percent% %% ^)
exit /b

:verify_chd

set "_verify[0]="&set "_verify[1]="&set "_verify[2]="
set "_sha1="&set "_version="

for /f "tokens=1,2,3" %%i in ('chdman info -i "%~1"^|findstr /bl /c:"SHA1:" /c:"File Version:"') do (
	if "%%i"=="SHA1:" (
		set "_sha1=%%j"
		>nul findstr /li /c:"sha1=""%%j""" "%_dat%"&&set "_verify[0]=ok"
	)else (
		set "_version=%%k"
	)
)


chdman verify --input "%~1" >chdman.tmp
>nul findstr /bl /c:"Raw SHA1 verification successful" chdman.tmp&& set "_verify[1]=ok"
>nul findstr /bl /c:"Overall SHA1 verification successful" chdman.tmp&& set "_verify[2]=ok"

(echo "","%~1","%_version%","%_sha1%","%_verify[0]%","%_verify[1]%","%_verify[2]%")>>output.csv

exit /b

:unzip_verify

rem //no exclamation marks on files!!
setlocal enabledelayedexpansion

rem //supports multiple chd in one zip file
"%_7zip%" e -y -spd -- "%~1" >nul
for /f "tokens=1,* delims== " %%g in ('^("%_7zip%" l -slt -spd -- "%~1"^)^|findstr /xir /c:"Path =..*\.chd"') do (
	set "_verify[0]="&set "_verify[1]="&set "_verify[2]="
	set "_sha1="&set "_version="

	for /f "tokens=1,2,3" %%i in ('chdman info -i "%%h"^|findstr /bl /c:"SHA1:" /c:"File Version:"') do (
		if "%%i"=="SHA1:" (
			set "_sha1=%%j"
			>nul findstr /li /c:"sha1=""%%j""" "%_dat%"&&set "_verify[0]=ok"
		)else (
			set "_version=%%k"
		)
	)
	
	chdman verify --input "%%h" >chdman.tmp
	>nul findstr /bl /c:"Raw SHA1 verification successful" chdman.tmp&& set "_verify[1]=ok"
	>nul findstr /bl /c:"Overall SHA1 verification successful" chdman.tmp&& set "_verify[2]=ok"
	
	(echo "%~1","%%h","!_version!","!_sha1!","!_verify[0]!","!_verify[1]!","!_verify[2]!")>>output.csv
	del "%%h"
)

setlocal disabledelayedexpansion

exit /b