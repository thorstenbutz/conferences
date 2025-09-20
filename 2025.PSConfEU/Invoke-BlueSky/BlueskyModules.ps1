###################
## Bluesky modules
###################

## Jeff Hicks: https://github.com/jdhitsolutions/PSBluesky
Find-Module -Name 'PSBlueSky' | Install-Module -Scope CurrentUser -WhatIf

## James Brundage: https://github.com/StartAutomating/PSA
Find-Module -Name 'PSA'   | Install-Module -Scope CurrentUser -WhatIf

## There is more (to come)
Find-Module -Name '*bluesky*'