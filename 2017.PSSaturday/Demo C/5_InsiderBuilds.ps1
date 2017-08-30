<#
    microsoft/nanoserver                                 
    microsoft/nanoserver-insider                       
    microsoft/windowsservercore-insider                         
    microsoft/nanoserver-insider-dotnet                        
    microsoft/nanoserver-insider-powershell   
#>

docker search nanoserver-insider | Select-String -Pattern '^microsoft/*'

docker pull microsoft/nanoserver-insider-powershell
docker run -it microsoft/nanoserver-insider-powershell powershell