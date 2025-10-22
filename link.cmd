@echo off
setlocal
cd "%Scoop%\\apps\\luanti\\current\\clientmods"
for /f "delims=" %%A in ('dir /AL /B ^| findstr /X "renegade"') do (
	echo.removing dead dir %%A
	rmdir "%%A"
	mklink /D "%Scoop%\apps\luanti\current\clientmods\renegade" "%~dp0"
)
endlocal
