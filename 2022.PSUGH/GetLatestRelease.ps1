###############################################
## WinGet-CLI: show latest release from Github
###############################################

$baseUri = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
(Invoke-RestMethod -uri $baseUri).assets.browser_download_url 