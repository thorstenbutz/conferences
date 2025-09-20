################################
## Follow along: Part A
## First contact (anonymously)
## "Hello world!"
###############################

## Querying a server (anonymously)
curl.exe -X GET 'https://bsky.social/xrpc/com.atproto.server.describeServer'
Invoke-RestMethod -Uri 'https://bsky.social/xrpc/com.atproto.server.describeServer'
 
## If you want more granular control
$iwrResponse = Invoke-WebRequest -Uri 'https://bsky.social/xrpc/com.atproto.server.describeServer'
$iwrResponse.StatusCode
$iwrResponse.StatusDescription

## Retrieving a user profile
$handle = 'jay.bsky.team'
$did = (irm "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=$handle").did
Invoke-RestMethod -Uri  "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=$did"

## NOTE ##########################################################################
## → A Bluesky user: Handle or DID
## DID stands for Decentralized ID. DIDs are a W3C specification.
## DIDs are universally-unique identifiers , permanent and non-human-readable. 
## Handles are domain names which are used to identify users in a simple way. 
## More than one handle may be assigned to a user, handles must not be permanent. 
##################################################################################

## Try another user account (aka handle)
$handle = 'psconf.eu'

## Do you use your own custom handle? 
Resolve-DnsName -Type TXT -Name _atproto.psconf.eu

## Try another one: complete!
# Resolve-DnsName -Type TXT -Name _atproto._________________