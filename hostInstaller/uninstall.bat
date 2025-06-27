@echo off
setlocal
set "INSTALL_DIR=C:\PotPlayerExtension"
set "MANIFEST_NAME=com.potplayer.launcher"

echo Removing registry keys...
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\%MANIFEST_NAME%" /f 2>nul
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%MANIFEST_NAME%" /f 2>nul
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\WOW6432Node\Google\Chrome\NativeMessagingHosts\%MANIFEST_NAME%" /f 2>nul
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge\NativeMessagingHosts\%MANIFEST_NAME%" /f 2>nul

REM Remove any incorrect default value on the parent key (cleanup)
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts" /ve /f 2>nul
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts" /ve /f 2>nul
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\WOW6432Node\Google\Chrome\NativeMessagingHosts" /ve /f 2>nul
%SystemRoot%\System32\reg.exe delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge\NativeMessagingHosts" /ve /f 2>nul

echo Removing files...
if exist "%INSTALL_DIR%" (
    rmdir /S /Q "%INSTALL_DIR%"
) else (
    echo Directory "%INSTALL_DIR%" does not exist.
)

echo PotPlayer Native Host uninstalled.
pause