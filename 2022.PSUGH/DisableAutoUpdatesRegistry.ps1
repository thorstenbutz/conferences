﻿########################
## Disable auto updates
########################

## Store updates
reg.exe add HKLM\SOFTWARE\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 2 /f

##  Windows Update