#######
## Git
#######

winget search git
winget install --id Git.Git 

## First restart the shell (git.exe => 'C:\Program Files\Git\cmd\git.exe')
git.exe clone 'https://github.com/microsoft/winget-cli'
git.exe clone 'https://github.com/microsoft/winget-pkgs'