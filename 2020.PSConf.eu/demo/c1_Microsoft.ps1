# So, we built a query in the Web UI. What's next? 
$uri = 'https://query.wikidata.org/sparql?query=SELECT%20%3FcompanyLabel%20WHERE%20%7B%0A%20%20SERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%2Cen%22.%20%7D%0A%20%20%0A%20%20%3Fcompany%20wdt%3AP112%20wd%3AQ162005%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20wd%3AQ5284.%0A%7D%0ALIMIT%20100%0A'

# Getting in touch
curl.exe $uri
curl.exe $uri -H 'Accept: application/json' 
curl.exe $uri -H 'Accept: text/csv'

# PowerShell: wget style 
Invoke-WebRequest -Uri $uri | Select-Object -ExpandProperty Content 

# Let's do it the "PowerShell" way 
$result = Invoke-RestMethod -Uri $uri
$result.Save('c:\demo\result.xml')
Get-Content -Path 'C:\demo\result.xml'

Invoke-RestMethod -Uri $uri -Headers @{'Accept' = 'text/csv' } | ConvertFrom-Csv
