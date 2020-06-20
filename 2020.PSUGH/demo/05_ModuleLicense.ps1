################################
# PowerShell Modules: Licensing
################################

<#  POWERSHELL MODULE PATHs

    $env:PSModulePath.Split(';')
    
    C:\Program Files\PowerShell\Modules
    c:\program files\powershell\7\Modules
    C:\Program Files\WindowsPowerShell\Modules
    C:\Windows\system32\WindowsPowerShell\v1.0\Modules
    $home\Documents\PowerShell\Modules
    $home\.vscode-insiders\extensions\ms-vscode.powershell-preview-2020.6.1\modules

#>

# Lets have a look at a sample manifest
psedit (Get-Module -ListAvailable -name ThreadJob).Path

# Is there anything undefined?
Get-Module -ListAvailable -name ThreadJob | Select-Object -Property *

# What about the builtin modules? 
Get-Module  -ListAvailable | 
    Where-Object -FilterScript { $_.path -like 'C:\Program Files\PowerShell\7\*' } | 
        Select-Object -Property Name, CompatiblePSEditions, Companyname, Copyright, ProjectUri, LicenseUri, Path | 
            Format-Table -AutoSize 


# All the modules? 
Get-Module  -ListAvailable | 
    Select-Object -Property Name, CompatiblePSEditions, Companyname, Copyright, ProjectUri, LicenseUri, Path | 
        Format-Table -AutoSize 

Get-Module -ListAvailable | Where-Object -FilterScript { $_.path -like 'C:\Windows\System32\WindowsPowerShell\v1.0\*' }| Format-Table -AutoSize -Property Name, CompatiblePSEditions, Companyname, Copyright, Path 

<#  Sample licenses
 
    # PSThreadJob
    https://github.com/PaulHigin/PSThreadJob

    # PowerShell Get
    https://go.microsoft.com/fwlink/?LinkId=829061

    # AZ module
    https://github.com/Azure/azure-powershell

 #>