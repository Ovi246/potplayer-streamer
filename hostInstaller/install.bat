@echo off
:: Self-elevate the script if not running as admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
setlocal

REM Set install directory and manifest name
set "INSTALL_DIR=C:\PotPlayerExtension"
set "MANIFEST_NAME=com.potplayer.launcher"

REM Create install directory if it doesn't exist
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy host scripts
copy /Y "%~dp0launch.ps1" "%INSTALL_DIR%"
copy /Y "%~dp0launch_potplayer.bat" "%INSTALL_DIR%"

REM Update manifest with correct path
powershell -Command "(Get-Content '%~dp0com.potplayer.launcher.json') -replace 'INSTALL_PATH', '%INSTALL_DIR:\=\\%' | Set-Content '%INSTALL_DIR%\%MANIFEST_NAME%.json'"

REM Debug: Show manifest path
echo Manifest path: %INSTALL_DIR%\%MANIFEST_NAME%.json

REM Ensure manifest exists
if not exist "%INSTALL_DIR%\%MANIFEST_NAME%.json" (
    echo ERROR: Manifest file not found at "%INSTALL_DIR%\%MANIFEST_NAME%.json"
    pause
    exit /b 1
)

REM Register native messaging host for Chrome (64-bit)
echo Registering for Chrome (64-bit)...
%SystemRoot%\System32\reg.exe add "HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\%MANIFEST_NAME%" /ve /t REG_SZ /d "%INSTALL_DIR%\%MANIFEST_NAME%.json" /f

REM Register native messaging host for Edge (64-bit)
echo Registering for Edge (64-bit)...
%SystemRoot%\System32\reg.exe add "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%MANIFEST_NAME%" /ve /t REG_SZ /d "%INSTALL_DIR%\%MANIFEST_NAME%.json" /f

REM Register native messaging host for Chrome (32-bit)
echo Registering for Chrome (32-bit)...
%SystemRoot%\System32\reg.exe add "HKLM\SOFTWARE\WOW6432Node\Google\Chrome\NativeMessagingHosts\%MANIFEST_NAME%" /ve /t REG_SZ /d "%INSTALL_DIR%\%MANIFEST_NAME%.json" /f

REM Register native messaging host for Edge (32-bit)
echo Registering for Edge (32-bit)...
%SystemRoot%\System32\reg.exe add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge\NativeMessagingHosts\%MANIFEST_NAME%" /ve /t REG_SZ /d "%INSTALL_DIR%\%MANIFEST_NAME%.json" /f

echo PotPlayer Native Host installed successfully!
pause