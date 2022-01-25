#######################################################
## Display installed appx packages in a meaningful way
#######################################################

## Define function
function Show-InstalledAppxPackage {
  [CmdletBinding()]
  param (
   [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
   [string[]] $PackageNames = 'Microsoft.VCLibs.140.00.UWPDesktop'
  )
  begin {}
  process {
    foreach ($PackageName in $PackageNames) {
      ## System scope
      try       {
          Get-AppxProvisionedPackage -Online | Where-Object -FilterScript { $_.Displayname -like $PackageName } |  
              Select-Object -Property @{
                l = 'CPUArch'
                e = { $env:PROCESSOR_ARCHITECTURE.Replace('AMD64', 'x64') }
              },
              @{
                l = 'Scope'
                e = { 'System' }
              }, 
              @{
                l = 'Architecture'
                e = { $_.Architecture -replace 9, 'x64' -replace 11, 'neutral' }
              }, PublisherID , @{
                l = 'Name'
                e = { $_.Displayname }
              }, Version    
      }
      catch {
          $GetAppxProvisionedPackageFailed = $true
      }
            
      ## User scope
      Get-AppxPackage | Where-Object -FilterScript { $_.name -like $PackageName } | Select-Object -Property @{
        l = 'CPUArch'
        e = { $env:PROCESSOR_ARCHITECTURE.Replace('AMD64', 'x64') }
      }, @{
        l = 'Scope'
        e = { 'User' }        
      }, Architecture, PublisherID, Name, Version
    }
  }
  end {
    if ($GetAppxProvisionedPackageFailed) {
        Write-Warning -Message 'Partial results: Get-AppxProvisionedPackage requires admin privs!'
    }
  }
} 

## Use function 
Show-InstalledAppxPackage -PackageNames 'Microsoft.VCLibs.140.00.UWPDesktop','Microsoft.DesktopAppInstaller'  | Format-Table -AutoSize

## Display inventory 
# $inventory = (Get-AppxPackage).name | Show-InstalledAppxPackage 
# $inventory | Format-Table -AutoSize
# $inventory | ConvertTo-Json | Out-File -Encoding utf8 -FilePath inventory.json
