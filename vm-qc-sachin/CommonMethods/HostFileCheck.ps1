# Get the Host File Content Details
$HostFilePath = $env:windir + "\System32\drivers\etc\hosts"
$HostFileContent = $null
# $HostFilePathFolder = $env:windir + "\System32\drivers\etc"
# $DesktopPathFolder = [Environment]::GetFolderPath("Desktop")
# Copy-Item -Path $HostFilePath -Destination $DesktopPathFolder -Force
# $DesktopFile = $DesktopPathFolder + "\hosts"
$HostFileContent = Get-Content $HostFilePath | Where-Object { $_ -NotMatch "^#" }

# # Delete the copied host file
# Remove-Item $DesktopFile
$HostFileContent
