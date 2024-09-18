##########################################
## Basic tests with plain text passwords
##########################################

## Your username and password
[string] $username = ''
[string] $strPassword = ''

## Simple test with curl.exe
curl.exe https://auphonic.com/api/presets.json -u  "$username`:$strPassword"

## Simple test with Invoke-Restmethod 
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$strPassword)))
$uri = 'https://auphonic.com/api/presets.json' 
$request = Invoke-RestMethod -UseBasicParsing -Uri $uri -Headers @{Authorization = "Basic $base64AuthInfo" }
$request.data | Format-List -Property 'preset_name','uuid'