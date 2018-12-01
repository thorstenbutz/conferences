Start-UDDashboard -Wait -Dashboard (
    New-UDDashboard -Title "Hello, IIS" -Content { 
        New-UDCard -Title "Hello, IIS" 
    }
    
) -Endpoint @(
    New-UDEndpoint -Url /process -Method GET -Endpoint {
        Get-Process | Select-Object Name, Id, @{
            Name = 'Uri'
            Expression = { '/api/process/byId/{0}' -f $_.Id }
        } | ConvertTo-Json
    }

    New-UDEndpoint -Url /process/byId/:id -Method GET -Endpoint {
        param (
            [Int]$id
        )
        Get-Process -Id $id |
            Select-Object Name, Id, Handles, NPM, PM, WS, CPU, SI |
            ConvertTo-Json
    }

    New-UDEndpoint -Url /process/byName/:name -Method Get -Endpoint {
        param (
            [Parameter(Mandatory)]
            [String]$Name
        )
        Get-Process -Name $Name |
            Select-Object Name, Id, Handles, NPM, PM, WS, CPU, SI |
            ConvertTo-Json

    }

    New-UDEndpoint -Url /process/byId/:id -Method DELETE -Endpoint {
        param (
            [Parameter(Mandatory)]
            [Int]$Id
        )
        Stop-Process -Force -Id $Id -PassThru | Select-Object Id, Name | ConvertTo-Json
    }

    New-UDEndpoint -Url /process/byName/:name -Method DELETE -Endpoint {
        param (
            [Parameter(Mandatory)]
            [String]$Name
        )
        Stop-Process -Force -Name $Name -PassThru | 
            Select-Object Id, Name | ConvertTo-Json
    }
    
    New-UDEndpoint -Url /process -Method POST -Endpoint {
        param (
            [Parameter(Mandatory)]
            [string]$Path
        )

        Start-Process -FilePath $Path -PassThru |
            Select-Object -Property Id, Name |
            ConvertTo-Json
    }

    New-UDEndpoint -Url /dsc/test -Method GET -Endpoint {
        Test-DscConfiguration -Detailed |
            ConvertTo-Json -Depth 10
    }

    New-UDEndpoint -Url /dsc/testEx -Method GET -Endpoint {
        Invoke-Command -ConfigurationName dsc -ComputerName . -ScriptBlock {
            Test-DscConfiguration -Detailed
        } | ConvertTo-Json -Depth 10
    }
)
