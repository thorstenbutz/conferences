Get-Module -ListAvailable | Select-String nx    # Check if nx module is unique

Import-Module -Name nx

Configuration ExampleConfiguration {
   
    Import-DscResource -module nx

}