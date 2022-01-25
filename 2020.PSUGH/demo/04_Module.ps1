################################
# Modules: CompatiblePSEditions
################################

Get-Module -ListAvailable | 
    Sort-Object -Property Name |  
        Select-Object -Property ModuleType, Version, PreRelease, Name, CompatiblePSEditions, Modulebase  | 
            Format-Table -AutoSize