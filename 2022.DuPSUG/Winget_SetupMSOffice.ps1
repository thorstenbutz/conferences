##########################
## Setup Microsoft Office
##########################

## Get the OfficeDeploymentTool
winget install --id Microsoft.OfficeDeploymentTool 

## Setup Microsoft Office with the OfficeDeploymentTool
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /configure 'C:\Program Files\OfficeDeploymentTool\configuration-Office2019Enterprise.xml'