$sparql5 = @'
SELECT ?item ?itemLabel ?GitHub_username (group_concat(?notable_workLabel;separator=",") as ?arrNotableWork) WHERE {
    SERVICE wikibase:label { 
      bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". 
      ?item rdfs:label ?itemLabel.    
      ?notable_work rdfs:label ?notable_workLabel.       
    }
    ?item wdt:P108  wd:Q2283;            
          wdt:P2037 ?GitHub_username;   
          wdt:P800  ?notable_work.      
  }
  GROUP BY ?item ?itemLabel ?GitHub_username having(count(?notable_workLabel) >= 2) 
'@
    
Invoke-RestMethod -Uri "https://query.wikidata.org/sparql?query=$sparql5" -Headers @{'Accept'='text/csv' } | ConvertFrom-Csv
