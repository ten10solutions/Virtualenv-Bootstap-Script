@ECHO OFF
PowerShell.exe -NoProfile -NonInteractive -ExecutionPolicy unrestricted -Command "& %~d0%~p0%~n0.ps1" %*
echo Powershell exited %errorlevel%
pause
EXIT /B %errorlevel%