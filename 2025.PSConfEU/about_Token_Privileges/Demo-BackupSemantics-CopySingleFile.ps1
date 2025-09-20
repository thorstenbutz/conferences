#########################################
## Howto mimic the "robocopy /b" feature
#########################################

## P/Invoke
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public class BackupCopy {
    const uint GENERIC_READ = 0x80000000;
    const uint GENERIC_WRITE = 0x40000000;
    const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;
    const uint OPEN_EXISTING = 3;
    const uint CREATE_ALWAYS = 2;
    const uint CREATE_NEW = 1;
    const uint FILE_ATTRIBUTE_NORMAL = 0x80;

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern SafeFileHandle CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

    public static void CopyFileWithBackupSemantics(string source, string dest, bool overwrite = true) {
        uint creationMode = overwrite ? CREATE_ALWAYS : CREATE_NEW;

        var srcHandle = CreateFile(source, GENERIC_READ, 0, IntPtr.Zero, OPEN_EXISTING,
                                   FILE_FLAG_BACKUP_SEMANTICS, IntPtr.Zero);
        if (srcHandle.IsInvalid)
            throw new IOException("Failed to open source file: " + source, Marshal.GetLastWin32Error());

        var dstHandle = CreateFile(dest, GENERIC_WRITE, 0, IntPtr.Zero, creationMode,
                                   FILE_ATTRIBUTE_NORMAL, IntPtr.Zero);
        if (dstHandle.IsInvalid)
            throw new IOException("Failed to create destination file: " + dest, Marshal.GetLastWin32Error());

        using (var src = new FileStream(srcHandle, FileAccess.Read))
        using (var dst = new FileStream(dstHandle, FileAccess.Write)) {
            src.CopyTo(dst);
        }
    }
}
"@

## Enlightment
. .\SetTokenPrivilege.ps1
Set-TokenPrivilege -Privilege 'SeBackupPrivilege' -ProcessId $pid
Set-TokenPrivilege -Privilege 'SeRestorePrivilege' -ProcessId $pid

## Action: Copy a single file (set overwrite to true or false)
$src = 'C:\users\BarberJ\Desktop\Jen-created-this-file.txt'
$dst = 'C:\backup\jen-created-this-file.txt'
[BackupCopy]::CopyFileWithBackupSemantics($src,$dst,$true)

## Check file
Get-ChildItem -Path 'C:\backup' -file # | Remove-Item -Force