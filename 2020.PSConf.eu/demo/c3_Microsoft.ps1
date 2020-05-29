$sparql2 = @'
 SELECT ?founder ?founderLabel WHERE {   
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }            
    wd:Q2283 wdt:P112 ?founder. 
}
'@

Invoke-RestMethod -Uri "https://query.wikidata.org/sparql?query=$sparql2" -Headers @{'Accept'='text/csv' } | ConvertFrom-Csv
