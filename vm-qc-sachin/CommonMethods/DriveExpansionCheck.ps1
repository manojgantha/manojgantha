Param(
    [parameter(Mandatory = $true)]$DriveId
)
$cvalue = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property DeviceID, @{'Name' = 'Size (GB)'; Expression = { [int]($_.Size / 1GB) } } 
$cvalue = $cvalue | Where-Object { $_.DeviceID -eq $DriveId } | Select-Object -Property 'Size (GB)'
$cvalue.'Size (GB)'