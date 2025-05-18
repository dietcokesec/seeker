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
echo Looking at interfaces
ipconfig /all

:: Fetch the arp table
echo Looking at arp table
arp -a

:: Routing table
echo Looking at routing table
route print

:: Find any good environment variables
echo Looking at environment variables
set

:: Get any running tasks
echo Looking at running tasks
tasklist /svc

:: Checking Patches and HotFixes
echo Looking at patches and hotfixes
wmi qfe

:: Installed products
echo Looking at installed products
wmi product get name

:: Running processes bound to ports
echo Looking at running processes bound to ports
netstat -ano

:: Get logged-in users
echo Looking at logged-in users
query user

:: Get scheduled tasks (filtered to non-Microsoft tasks and showing only task name, next run time, and status)
echo Looking at scheduled tasks (non-Microsoft)
schtasks /query /fo table /nh | findstr /v "Microsoft\\" | findstr /v "\\Microsoft"

:: Alternative: Get tasks that are set to run today
echo Looking at tasks scheduled to run today
for /f "tokens=1-3 delims=/" %%a in ("%date%") do (
    set today=%%c/%%a/%%b
)
schtasks /query /fo table /nh | findstr "%today%"

:: My user's privileges
echo Looking at user privileges
whoami /priv

:: All Groups
echo Looking at all groups
net localgroup