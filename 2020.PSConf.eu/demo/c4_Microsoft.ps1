# Microsoft's IPv4 prefixes
$sparql4 = @'
SELECT ?IPv4_routing_prefix WHERE {
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
    ?company wdt:P112 wd:Q5284, wd:Q162005.
    OPTIONAL { ?company wdt:P3761 ?IPv4_routing_prefix. }
  }
'@

Invoke-RestMethod -Uri "https://query.wikidata.org/sparql?query=$sparql4" -Headers @{'Accept'='text/csv' } | ConvertFrom-Csv
