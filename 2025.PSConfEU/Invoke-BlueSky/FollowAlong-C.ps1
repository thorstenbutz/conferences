###########################################################
## Follow along: Part C
## Acessing the Bluesky API: Authenticated API access
## Creating an access token
## https://docs.bsky.app/docs/get-started#create-a-session
###########################################################

## First try ("Don't do this @home")
curl.exe -X POST 'https://bsky.social/xrpc/com.atproto.server.createSession' `
    -H 'Content-Type: application/json' `
    -d '{
           "identifier": "your.handle",  
           "password": "your-password"
        }'

## The PowerShell way: use your own handle and app password       
$handle = 'dev.butz.io' 
$appPW = Get-Content -path "$home\bsky-apppw.txt"

$uri = 'https://bsky.social/xrpc/com.atproto.server.createSession'
$headers = @{
    'Content-Type' = 'application/json'    
}
$data = @{
    'identifier' = $handle
    'password'   = $appPW
} | ConvertTo-Json 

$iwrData = Invoke-WebRequest -Method 'Post' -Headers $headers -Uri $uri -Body $Data
$mySession = $iwrData.Content | ConvertFrom-Json

## Refresh token: 90 days lifetime
$mySession.refreshJwt # | Set-Clipboard

## Access token: 2 hours lifetime
$mySession.accessJwt

## Check the details (also try: jwt.ms)
Find-Module -Name 'JWTDetails' | Install-Module -Scope CurrentUser -WhatIf
Get-Command -Module 'JWTDetails'
Get-JWTDetails -token $mySession.refreshJwt
Get-JWTDetails -token $mySession.accessJwt
