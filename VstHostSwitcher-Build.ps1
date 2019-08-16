###################################################################################
# Script to build the VstHostSwitcher.exe file.
# IMPORTANT: ps2exe.ps1 script has to be available from your PATH.
# https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-9b4b0493
###################################################################################
ps2exe.ps1 VstHostSwitcher.ps1 VstHostSwitcher.exe -verbose -noConsole -iconfile VstHostSwitcher.ico
#$NULL = Read-Host "Press enter to exit"
