#####################################################
## Auphonic: Publish video, file upload via OneDrive
#####################################################

#Requires -Version 7

[string] $username = ''
[string] $strPassword = ''
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $username, $strPassword)))
$uri = 'https://auphonic.com/api/simple/productions.json' 
$Form = @{        
    preset          = 'nH6HVudQdd5mXenr7BCRJo' ## CIM Lingen
    service         = 'nhkZwYtq2DoKrS2pRHxXUf' ## OneDrive
    title           = 'Windows Server Container -  Thorsten Butz - cim lingen 2017 (remastered)'
    input_file      = 'Windows Server Container - Thorsten Butz - cim lingen 2017.mkv'
    output_basename = 'cimlingen'
    action          = 'start'
}
$params = @{
    UseBasicParsing = $true
    Uri             = $Uri
    Method          = 'Post'
    Form            = $Form
    Headers         = @{Authorization = "Basic $base64AuthInfo" }
}

Invoke-RestMethod @params