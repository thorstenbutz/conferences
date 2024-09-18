###############################################################
## Deepl-Free API
## https://www.deepl.com/docs-api/documents/translate-document
###############################################################

$API_KEY = ''
$uri = 'https://api-free.deepl.com/v2/translate'
$text = @'
Space, the final frontier
These are the voyages of the Starship Enterprise
Its five year mission
To explore strange new worlds
To seek out new life
And new civilizations
To boldly go where no man has gone before
'@

$headers = @{    
    'Authorization' = "DeepL-Auth-Key $API_KEY"       
} 

$body = @{
    'text'=$text
    'target_lang'='DE'
}

$request = Invoke-RestMethod -Method 'Post' -Headers $headers -Uri $uri -Body $body 
$request.translations.text