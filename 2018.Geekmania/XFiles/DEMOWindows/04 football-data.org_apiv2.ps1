####################
# football-data.org 
# API v2
####################

# Authorization: You need to add your own API KEY BELOW
$header = @{ "X-Auth-Token" = 'YOUR API KEY HERE' }  # Example Token 

# Reset 
$data = @()

# Get competition
$competitions = (Invoke-RestMethod -UseBasicParsing -Uri "http://api.football-data.org/v2/competitions" -Headers $header).competitions
$competitions.Count
$competitions.Where({$_.name -like "*World Cup*"})  # WC 2018 in Russia: id = 2000 

# Get teams
$teams2000 = (Invoke-RestMethod -UseBasicParsing -Uri  "http://api.football-data.org/v2/competitions/2000/teams" -Headers $header).teams
$teams2000
 
# Single team: Deutschland WC 2018
(Invoke-RestMethod -UseBasicParsing -Uri  "http://api.football-data.org/v1/teams/759/players" -Headers $header).players

# Multiple teams
# foreach ($team in $teams2000[0],$teams2000[1]) {    
foreach ($team in $teams2000) {    
    "$($team.name) ($($team.id))" | Write-Host -ForegroundColor Yellow
    $ou = Get-ADOrganizationalUnit -Filter "name -eq `"$($team.name)`"" | Select-Object -First 1
    if (!$ou) {
        New-ADOrganizationalUnit -Name $team.name -Description $team.clubColors -ProtectedFromAccidentalDeletion $false
        $ou = Get-ADOrganizationalUnit -Filter "name -eq `"$($team.name)`"" 
      } 

    $currentteam =  (Invoke-RestMethod -UseBasicParsing -Uri  "http://api.football-data.org/v1/teams/$($team.id)/players" -Headers $header).players

    foreach ($player in $currentteam) {
        if ($player.jerseyNumber) {
            $params = @{            
                path = $ou 
                Name = $player.name 
                Department =  $player.position 
                Description =  $player.dateOfBirth  `             
                Enabled = $true 
                AccountPassword = ConvertTo-SecureString -AsPlainText -String 'Pa$$w0rd' -Force
                SamAccountName = $team.tla.tolower() + $player.jerseyNumber
                OtherAttributes =  @{employeeNumber = "Number $($player.jerseyNumber)";'msDS-cloudExtensionAttribute1' = $player.dateOfBirth } 
            }
            New-ADUser @params -ea:0 
            
        } 
        else {
            Write-Warning -message $player.name
        }
    }
    $data += $currentteam
}

# $data | Format-Table name, nationality
    
# (Get-ADUser -SearchBase $ou  -Filter { samaccountname -like "uru*" }).Distinguishedname | Remove-ADUser -Confirm:$false

