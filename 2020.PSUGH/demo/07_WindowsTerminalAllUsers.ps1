##########################################
# Setup Windows Terminal "all users mode"
##########################################

# Get release
$uri = 'https://github.com/microsoft/terminal/releases/download/v1.0.1401.0/Microsoft.WindowsTerminal_1.0.1401.0_8wekyb3d8bbwe.msixbundle'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $uri.Split('/')[-1] 

# Add package
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath $uri.Split('/')[-1] 

# Remove package
# Get-AppxProvisionedPackage -Online | Where-Object -FilterScript { $_.Displayname -like '*terminal*' } | Remove-ProvisionedAppxPackage -Online -AllUsers 