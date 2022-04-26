########################
## Disable auto updates
########################

## Store updates
reg.exe add HKLM\SOFTWARE\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 2 /f

##  Windows Update# reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f# reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v AUOptions /t REG_DWORD /d 2 /f