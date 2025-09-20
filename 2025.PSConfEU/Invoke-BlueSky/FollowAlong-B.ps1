#############################################
## Follow along: Part B
## Getting posts from blue sky (anonymously)
#############################################

## From "Handle" to "Decentralized Identifiers" (DID)
$handle = 'dev.butz.io'
Invoke-RestMethod -Method GET -Uri  "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=$handle"

## Saving the DID
$handle = 'jay.bsky.team'
$did = (Invoke-RestMethod -Method GET -Uri  "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=$handle").did

## Getting the profile
Invoke-RestMethod -Method GET -Uri "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=$did"

## Searching for a user
$keyword = 'psconfeu'
$actors = (Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/app.bsky.actor.searchActors?q=$keyword").actors
$actors | Select-Object  -Property DID, Handle, DisplayName #,Description

## Try another keyword - do you find yourself ? Your favourite topic? 

## Getting posts from a specific user
$irmData = Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=$handle"
$irmData.feed.post
$irmData.feed.post[-1].record.text  ## The oldest post

## Yet another post from another user
$handle = 'jay.bsky.team'
$irmData = Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=$handle"
$irmData.feed.post[0]
$irmData.feed.post[0].record.text ## The latest post