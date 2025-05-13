@echo off
setlocal EnableDelayedExpansion

:: Run systeminfo once and save the output to a temporary file
echo Running systeminfo (this may take a moment)...
set "temp_file=%TEMP%\systeminfo_temp.txt"
systeminfo > "%temp_file%"

:: Extract OS information
echo.
echo System Information:
findstr /B /C:"OS Name" /C:"OS Version" "%temp_file%"

:: Extract user information
echo.
echo User Information:
findstr /B /C:"Host Name" /C:"Domain" /C:"Logon Server" "%temp_file%"

:: Clean up the temporary file
del "%temp_file%"

endlocal

:: Fetch the interfaces
ipconfig /all

:: Fetch the arp table
arp -a

:: Routing table
route print