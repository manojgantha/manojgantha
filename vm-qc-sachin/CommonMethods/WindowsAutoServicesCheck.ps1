# $computer = (Get-Item env:\Computername).Value

$Services = Get-Service

# $stoppedServices = $Services | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -ne "Running" } | Select-Object -expand DisplayName

# Write-Host "$computer : Stopped Services: $stoppedServices"

$stoppedServicesCount = ($Services | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -ne "Running" } | Measure-Object).Count

$stoppedServicesCount