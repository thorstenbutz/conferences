#########################################
## Install specific version of PowerToys
#########################################

winget search powertoys 
winget show --id Microsoft.PowerToys # e.g. v0.53.3

## Install legacy app version
winget install --id Microsoft.PowerToys --version 0.53.1

## Show state
winget list --id Microsoft.PowerToys 
winget upgrade # Show available updates

## Upgrade
winget upgrade --id Microsoft.PowerToys 
winget upgrade --all

## Uninstall
# winget uninstall --id Microsoft.PowerToys 
