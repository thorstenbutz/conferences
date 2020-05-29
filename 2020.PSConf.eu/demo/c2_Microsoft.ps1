# Let's get rid of those unreadable long URIs!
$sparql1 = @'
SELECT ?companyLabel WHERE {
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }    
    ?company wdt:P112 wd:Q162005,
                      wd:Q5284.
  }
'@

# XML
Invoke-RestMethod -Uri "https://query.wikidata.org/sparql?query=$sparql1" 

# CSV
Invoke-RestMethod -Uri "https://query.wikidata.org/sparql?query=$sparql1" -Headers @{'Accept'='text/csv' } | ConvertFrom-Csv
