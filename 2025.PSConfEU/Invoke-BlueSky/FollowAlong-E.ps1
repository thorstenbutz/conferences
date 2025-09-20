############################################################
## Follow along: Part E
## Working with user data and cleanup operations
############################################################

## Working with a real Bluesky user
$handle = 'dev.butz.io'

## First, resolve the handle to get the DID
$userInfo = Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=$handle"
$did = $userInfo.did

## Working with actual Bluesky API data
## Get the last post from the user's feed
$irmData = Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=$handle"
$lastPost = $irmData.feed.post[0]
$lastPost.record.text

## If you have authenticated access, you could delete the last post
## (This would require the post URI and proper authentication)

$postUri = $lastPost.uri
$deleteUri = "https://bsky.social/xrpc/com.atproto.repo.deleteRecord"
$deleteHeaders = @{
    'Authorization' = 'Bearer ' + $mySession.accessJwt
    'Content-Type'  = 'application/json'    
}
$deleteData = @{
    'repo'       = $handle
    'collection' = 'app.bsky.feed.post'
    'rkey'       = $postUri.Split('/')[-1]
} | ConvertTo-Json

## Uncomment to actually delete (use with caution!)
## Invoke-WebRequest -Method 'Post' -Uri $deleteUri -Headers $deleteHeaders -Body $deleteData

### All
$irmData = Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=$handle"
$posts = $irmData.feed.post
$posts.record.text

foreach ($post in $posts) { 
    $postUri = $post.uri
    $deleteUri = "https://bsky.social/xrpc/com.atproto.repo.deleteRecord"
    $deleteHeaders = @{
        'Authorization' = 'Bearer ' + $mySession.accessJwt
        'Content-Type'  = 'application/json'    
    }
    $deleteData = @{
        'repo'       = $handle
        'collection' = 'app.bsky.feed.post'
        'rkey'       = $postUri.Split('/')[-1]
    } | ConvertTo-Json  
    Invoke-WebRequest -Method 'Post' -Uri $deleteUri -Headers $deleteHeaders -Body $deleteData
}