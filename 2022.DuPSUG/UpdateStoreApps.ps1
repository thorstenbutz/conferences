#####################
## Update store apps 
#####################

Invoke-CimMethod -MethodName 'UpdateScanMethod' -InputObject (Get-CimInstance -Namespace 'Root\cimv2\mdm\dmmap' -ClassName 'MDM_EnterpriseModernAppManagement_AppManagement01') 
Get-CimInstance -Namespace 'Root\cimv2\mdm\dmmap' -ClassName 'MDM_EnterpriseModernAppManagement_AppManagement01' | Invoke-CimMethod -MethodName 'UpdateScanMethod'

## Mind the gap: this will not work (you need the instance of the WMI class first) 
Invoke-CimMethod -Namespace 'Root\cimv2\mdm\dmmap' -ClassName 'MDM_EnterpriseModernAppManagement_AppManagement01' -MethodName 'UpdateScanMethod'
