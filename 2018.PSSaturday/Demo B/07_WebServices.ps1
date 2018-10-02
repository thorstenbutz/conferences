# REST based web service, e.g. the  ECB
[xml] $data = Invoke-WebRequest 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
$data.Envelope.Cube.Cube.Cube 
$data.Envelope.Cube.Cube.Cube  | Where-Object { $_.currency -eq 'USD'}

# B: Bitcoincharts: https://bitcoincharts.com/about/markets-api/
$bitcoincharts = Invoke-WebRequest -Method Get -uri 'http://api.bitcoincharts.com/v1/markets.json'
$json = $bitcoincharts.Content | ConvertFrom-Json 
$json | Where-Object { $_.symbol -like 'kraken*' } | Sort-Object -Property volume -Descending |  
  Format-Table -Property currency, high, weighted_price, volume

# Make it nice:
$bitcoincharts = Invoke-WebRequest -Method Get -uri 'http://api.bitcoincharts.com/v1/markets.json' -UseBasicParsing
$json = $bitcoincharts.Content | ConvertFrom-Json 
$json | Where-Object { $_.symbol -like 'kraken*' -and $_.volume -gt 0} | Sort-Object volume -Descending | Format-Table -AutoSize -Property `
    @{l='Currency'; e={$_.currency} },
    @{l='High'; e={[Math]::Round($_.high,2)} },
    @{l='Low'; e={[Math]::Round($_.low,2)} },
    @{l='Weighted_price'; e={[Math]::Round($_.weighted_price,2)} },
    @{l='Volume'; e={[Math]::Round($_.volume,2)} }
  
# The fun stuff: https://api.tronalddump.io/
(Invoke-RestMethod 'https://api.tronalddump.io/random/quote').value
