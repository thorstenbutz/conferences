##########################################
# Setup Windows Terminal "all users mode"
##########################################

# Get release
$latest = 'https://api.github.com/repos/microsoft/terminal/releases/latest'
$uri = (Invoke-RestMethod -UseBasicParsing -Uri $latest).assets.browser_download_url[0]

# Add package
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath $uri.Split('/')[-1] 

# Remove package
# Get-AppxProvisionedPackage -Online | Where-Object -FilterScript { $_.Displayname -like '*terminal*' } | Remove-ProvisionedAppxPackage -Online -AllUsers 