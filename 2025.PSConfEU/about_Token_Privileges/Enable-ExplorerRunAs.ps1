<#
.Synopsis
   Enable-ExplorerRunAs.ps1 modifies the registry to allow elevated Explorer processes to run as the current user.

.DESCRIPTION
    The Registry path "HKEY_CLASSES_ROOT\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}" is used to control the 
    behavior of the Explorer process. The "RunAs" property is used to allow elevated Explorer processes to 
    run as the current user. This script modifies the registry to allow elevated Explorer processes to run as the 
    current user. The "RunAs" property is set to "RunA_".    
    To modify the registry, the script will take ownership of the registry key and set the owner to the current user.
    It will then add a full control rule to the current user.     
    The script requires the SeTakeOwnershipPrivilege and SeRestorePrivilege privileges, it must be run as administrator.    

.EXAMPLE
    .\Enable-ExplorerRunAs.ps1 -showDetails

.EXAMPLE
    .\Enable-ExplorerRunAs.ps1 -showDetails  -restoreDefaults

.EXAMPLE
   .\Enable-ExplorerRunAs.ps1  -showDetails -whatif

.NOTES
    The script is primarily based on code snipptes and explanations from Lee Holmes and Guy Leech.
    Thank you for your work!

    Check out updates and further explanation on my homepage and github account:
    - https://www.thorsten-butz.de
    - https://github.com/thorstenbutz    

.LINK
    https://www.leeholmes.com/adjusting-token-privileges-in-powershell/
    https://www.leeholmes.com/powershell-pinvoke-walkthrough/
    https://github.com/guyrleech/Microsoft/blob/master/Set%20Key%20Owner.ps1

#>

[CmdletBinding(SupportsShouldProcess = $true)]
[Alias()]
param (
    [switch] $showDetails,
    [bool] $enableTokenPrivileges = $True,
    [switch] $restoreDefaults
)
begin {
    #Requires -RunAsAdministrator
    
    function Set-TokenPrivilege {
        param(         
            # The privilege to adjust: http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
            [ValidateSet(
                'SeAssignPrimaryTokenPrivilege', 'SeAuditPrivilege', 'SeBackupPrivilege',
                'SeChangeNotifyPrivilege', 'SeCreateGlobalPrivilege', 'SeCreatePagefilePrivilege',
                'SeCreatePermanentPrivilege', 'SeCreateSymbolicLinkPrivilege', 'SeCreateTokenPrivilege',
                'SeDebugPrivilege', 'SeEnableDelegationPrivilege', 'SeImpersonatePrivilege', 'SeIncreaseBasePriorityPrivilege',
                'SeIncreaseQuotaPrivilege', 'SeIncreaseWorkingSetPrivilege', 'SeLoadDriverPrivilege',
                'SeLockMemoryPrivilege', 'SeMachineAccountPrivilege', 'SeManageVolumePrivilege',
                'SeProfileSingleProcessPrivilege', 'SeRelabelPrivilege', 'SeRemoteShutdownPrivilege',
                'SeRestorePrivilege', 'SeSecurityPrivilege', 'SeShutdownPrivilege', 'SeSyncAgentPrivilege',
                'SeSystemEnvironmentPrivilege', 'SeSystemProfilePrivilege', 'SeSystemtimePrivilege',
                'SeTakeOwnershipPrivilege', 'SeTcbPrivilege', 'SeTimeZonePrivilege', 'SeTrustedCredManAccessPrivilege',
                'SeUndockPrivilege', 'SeUnsolicitedInputPrivilege')]
            $Privilege,

            ## The process on which to adjust the privilege. Defaults to the current process.
            $ProcessId = $pid,

            ## Switch to disable the privilege, rather than enable it.
            [Switch] $Disable

        )

        ## Taken from P/Invoke.NET with minor adjustments.
        $definition = @’
    using System;
    using System.Runtime.InteropServices;
    public class AdjPriv
    {
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
    ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid
    {
    public int Count;
    public long Luid;
    public int Attr;
    }

    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
   
    public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
    {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = new IntPtr(processHandle);
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    if(disable)
    {
    tp.Attr = SE_PRIVILEGE_DISABLED;
    }
    else
    {
    tp.Attr = SE_PRIVILEGE_ENABLED;
    }
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
    }
    }
‘@

        $processHandle = (Get-Process -id $ProcessId).Handle
        $type = Add-Type $definition -PassThru
        $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
    }

    ## You could also Load Set-TokenPrivilege from a separate file
    ## . .\SetTokenPrivilege.ps1   

    function checkStatus {

        ## User accounts        
        $ti = [System.Security.Principal.NTAccount]::new('NT Service\TrustedInstaller')
        # $me = [System.Security.Principal.NTAccount]::new("$env:USERDOMAIN\$env:USERNAME")

        ## RegKey
        $baseKey = [Microsoft.Win32.Registry]::ClassesRoot ## 'HKEY_CLASSES_ROOT'
        $subKey = 'AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}'
        
        $regKey = $baseKey.OpenSubKey(
            $subKey, 
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, 
            [System.Security.AccessControl.RegistryRights]::TakeOwnership         
        )     
        
        ## Getting the current ACL
        $acl = $regKey.GetAccessControl()

        ## Check configuration
        if ((Get-Item -Path "Registry::$($regKey.Name)").Property -contains 'RunAs' -and $acl.Owner -eq $ti) { 
            $true
        }
        elseif ((Get-Item -Path "Registry::$($regKey.Name)").Property -contains 'RunA_' -and $acl.Owner -ne $ti) {
            $false
        }
        else { 
            Write-Warning -Message 'Unknown configuration'         
        }    
    }    

}
process {

    ## Gather output
    $output = @{}

    ## Enable the SeTakeOwnershipPrivilege
    if ($enableTokenPrivileges) {
        ## Enable the required privilege
        if (!(Set-TokenPrivilege -Privilege 'SeTakeOwnershipPrivilege' -ProcessId $pid)) { 
            throw 'Cannot enable SeTakeOwnershipPrivilege!'
        }
    }

    ## User accounts (designated owners)
    $me = [System.Security.Principal.NTAccount]::new("$env:USERDOMAIN\$env:USERNAME")
    $ts = [System.Security.Principal.NTAccount]::new('NT Service\TrustedInstaller')

    ## Since Set-ACL does not work here ...
    $baseKey = [Microsoft.Win32.Registry]::ClassesRoot ## 'HKEY_CLASSES_ROOT'
    $subKey = 'AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}'
        
    $regKey = $baseKey.OpenSubKey(
        $subKey, 
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, 
        [System.Security.AccessControl.RegistryRights]::TakeOwnership         
    )     
      
    ## Getting the current ACL
    $acl = $regKey.GetAccessControl()
    $acl.owner | Write-Verbose 
    $acl.Sddl | Write-Verbose

    ## Define new rule: Allow "me" fullow control
    $rule = [System.Security.AccessControl.RegistryAccessRule]::new(
        $me,
        [System.Security.AccessControl.RegistryRights]::FullControl,
        [System.Security.AccessControl.InheritanceFlags]'ObjectInherit,ContainerInherit',
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow 
    ) 
    
    ## Is explorer.exe currently restricted (sytem default)? 
    $isRestricted = checkstatus
    $output.add('isRestricted(Pre)', $isRestricted)
    
    ## Restore system default
    if ($restoreDefaults -and !$isRestricted) {        
        
        if ($enableTokenPrivileges) {
            ## Enable the required privilege
            if (!(Set-TokenPrivilege -Privilege 'SeRestorePrivilege' -ProcessId $pid)) { 
                throw 'Cannot enable SeRestorePrivilege!'
            }
        }
                
        if ($PSCmdlet.ShouldProcess("Registry key $($regKey.Name)", 'Rename property RunA_ to RunAs')) {
            Rename-ItemProperty -Path "Registry::$($regKey.Name)" -Name 'RunA_' -NewName 'RunAs'
        }
                
        ## Restore 'Trusted Installer' as owner
        $acl.SetOwner($ts)
        
        if ($PSCmdlet.ShouldProcess("Registry key $($regKey.Name)", 'Restore owner')) {
            $regKey.SetAccessControl($acl)
        }
        
        ## Remove custom rule
        [void] $acl.RemoveAccessRule($rule)
        
        if ($PSCmdlet.ShouldProcess("Registry key $($regKey.Name)", 'Remove ACL')) {
            $regKey.SetAccessControl($acl)
        }       
        $output.add('Action', 'Restore defaults')
    }
    elseif (!$restoreDefaults -and $isRestricted) {    
        
        ## Let the calling account become the owner and grant full controll    
        try { 
            ## Set new owner
            $acl.SetOwner($me)  
            if ($PSCmdlet.ShouldProcess("Registry key $($regKey.Name)", 'Set owner')) {
                $regKey.SetAccessControl($acl)
            }

            ## Add full control  
            $acl.AddAccessRule($rule)            
            if ($PSCmdlet.ShouldProcess("Registry key $($regKey.Name)", 'Add ACL')) {
                $regKey.SetAccessControl($acl)
            }
        }
        catch { 
            $_.Exception.Message
            return
        }

        ## Rename property 'RunAs' to allow elevated Explorer processes
        if ($PSCmdlet.ShouldProcess("Registry key $($regKey.Name)", 'Rename property RunAs to RunA_')) {
            Rename-ItemProperty -Path "Registry::$($regKey.Name)" -Name 'RunAs' -NewName 'RunA_'
        }
        $output.add('Action', 'Remove restriction')
    }  
    else {                
        $output.add('Action', 'No change needed')
    }     

}
end {
    $privs = whoami /priv /fo csv | ConvertFrom-Csv   
    $output.Add('isRestricted(Post)', $(checkstatus))
    $output.add('SeTakeOwnershipPrivilege', ($privs | Where-Object -FilterScript { $_.'Privilege Name' -eq 'SeTakeOwnershipPrivilege' }).State)
    $output.add('SeRestorePrivilege', ($privs | Where-Object -FilterScript { $_.'Privilege Name' -eq 'SeRestorePrivilege' }).State)    
    $output.add('RegKeyProperties', (Get-Item -Path "Registry::$($regKey.Name)").Property)
    $output.add('RegKey', $regKey.Name )    
    $output.add('RegKeyOwner', $acl.Owner)
    
    if ($showDetails) {
        [PSCustomObject] $output | Select-Object -Property Se*, RegKey, RegKeyProperties, RegKeyOwner, 'isRestricted(Pre)', 'isRestricted(Post)', Action
    }
    
    ## Clean up
    $regKey.Close()    
    $regKey.Dispose()
}