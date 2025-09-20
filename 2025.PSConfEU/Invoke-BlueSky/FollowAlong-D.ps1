############################################################
## Acessing the Bluesky API: Authenticated API access
## Create a post
## https://docs.bsky.app/docs/get-started#create-a-post
## Some unicode characters (if you want to to play with it)
## "`u{1F98B}" = 🦋
## "`u{1F499}" = 💙
############################################################

<#
Example from https://docs.bsky.app/docs/get-started#create-a-post

curl -X POST $PDSHOST/xrpc/com.atproto.repo.createRecord \
    -H "Authorization: Bearer $ACCESS_JWT" \
    -H "Content-Type: application/json" \
    -d "{\"repo\": \"$BLUESKY_HANDLE\", \"collection\": \"app.bsky.feed.post\", \"record\": {\"text\": \"Hello world! I posted this via the API.\", \"createdAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}"
#>

## Let's create a new post
$pdsHost = 'bsky.social'
$uri = "https://$pdsHost/xrpc/com.atproto.repo.createRecord"
$headers = @{
    'Authorization' = 'Bearer ' + $mySession.accessJwt
    'Content-Type'  = 'application/json'    
}
$data = @{        
    'repo'       = $handle
    'collection' = 'app.bsky.feed.post'
    'record'     = @{
        'text'      = 'Yet another post! ' + (Get-Date -UFormat '%R') + " `u{1F98B}"
        'createdAt' = Get-Date -Format o 
    }
} | ConvertTo-Json

    $iwrData = Invoke-WebRequest -Method 'Post' -Uri $Uri -Headers $Headers -Body $Data 
    $iwrData

## PowerShell💙 Pipelining
@{        
    'repo'       = $handle
    'collection' = 'app.bsky.feed.post'
    'record'     = @{
        'text'      = 'PowerShell loves Pipeling! ' + (Get-Date -UFormat '%R') 
        'createdAt' = Get-Date -Format o 
    }
} | ConvertTo-Json | Invoke-WebRequest -Method 'Post' -Uri $uri -Headers $headers 
