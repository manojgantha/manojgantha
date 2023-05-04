
# Below parameters are needed by the script
[CmdletBinding()]
Param (
    # The subscription name
    [Parameter(Mandatory = $true)]
    [string] $InputFolderPath,
    
    # FOlder path where the output CSVs will be created
    [Parameter(Mandatory = $true)]
    [string] $OutputFolderPath,

    # [Parameter(Mandatory = $true)]
    # [string]$AzTenantID,

    # Name of the subscription where validation needs to be performed
    # [Parameter(Mandatory = $true)]
    # [string] $SubscriptionName,

    # Allowed values are VM or VNET
    [Parameter(Mandatory = $true)]
    [string] $ResourceType,

    # Confirmation for sending an email
    [Parameter(Mandatory = $true)]
    [bool] $SendEmail
)

#
# Get Data for VM
#
Function Get-VM-Data {
    [hashtable]$DataFromAzure = @{}

    # Fetch data from azure
    $VM = Get-AzVM -Name $ResourceName
    $VmSize = Get-AzVMSize -VMName $VM.Name -ResourceGroupName $VM.ResourceGroupName | Where-Object { $_.Name -eq $VM.HardwareProfile.VmSize }
    $Nics = $VM.NetworkProfile.NetworkInterfaces
    $Sql = Get-AzSqlServer -ServerName $VM 
    $BackupVaults = Get-AzRecoveryServicesVault
    $Nic = $VM.NetworkProfile.NetworkInterfaces.id.split('/') | Select-Object -Last 1
    $NicDetails = Get-AzNetworkInterface -Name $Nic
    $VnetName = ($NicDetails.IpConfigurations.subnet.Id -split '/')[-3]
    $SubnetName = ($NicDetails.IpConfigurations.subnet.Id -split '/')[-1]

    # Add values to hash table
    $DataFromAzure.Add("VMName", $VM.name)
    $DataFromAzure.Add("CPU", $VmSize.NumberOfCores)
    $DataFromAzure.Add('MemoryinGB', ($VmSize.MemoryInMB * 1mb / 1gb))
    $DataFromAzure.Add('AzureVMType', ($VM.HardwareProfile.VmSize))
    $DataFromAzure.Add('ManagedDisk', "$(if ($VM.StorageProfile.OsDisk.ManagedDisk) { $true } else { $false })")
    $DataFromAzure.Add('OSDiskInGB', $VM.StorageProfile.OsDisk.DiskSizeGB)
    $DataFromAzure.Add('DataDiskInGB', $VM.StorageProfile.dataDisks.diskSizeGB)
    $DataFromAzure.Add("TempDisk", ($VmSize.ResourceDiskSizeInMB * 1mb / 1gb))
    $DataFromAzure.Add('Operating System', ($VM.StorageProfile.ImageReference.Offer + " $($vm.StorageProfile.ImageReference.Sku)"))
    $DataFromAzure.Add('Tag - product | product-name', $VM.Tags.'product | product-name')
    $DataFromAzure.Add('Tag - business-unit', $VM.Tags.'business-unit')
    $DataFromAzure.Add('Tag - team', $VM.Tags.team)
    $DataFromAzure.Add('Tag - billing', $VM.Tags.billing)
    $DataFromAzure.Add('Tag - environment', $VM.Tags.environment)
    $DataFromAzure.Add('Tag - primary-contact-email', $VM.Tags.'primary-contact-email')
    $DataFromAzure.Add('Tag - primary-contact-name', $VM.Tags.'primary-contact-name')
    $DataFromAzure.Add('Tag - customer | customer-name', $VM.Tags.'customer | customer-name')
    $DataFromAzure.Add('Tag - automation-opt-in', $VM.Tags.'automation-opt-in')
    $DataFromAzure.Add('RGLock', "$(if (Get-AzResourceLock -ResourceGroupName $VM.ResourceGroupName) { $true } else { $false })")
    $DataFromAzure.Add('IPAddress', ((Get-AzNetworkInterface -Name $Nic).ipconfigurations.privateipaddress))
    $DataFromAzure.Add('GuestLevelMonitoring', "$(if ($VM.DiagnosticsProfile.BootDiagnostics.Enabled) { $true }else { $false })")
    $DataFromAzure.Add('Storage account', "$(if ($VM.DiagnosticsProfile.BootDiagnostics.Enabled) { if ($VM.DiagnosticsProfile.BootDiagnostics.StorageUri) { $VM.DiagnosticsProfile.BootDiagnostics.StorageUri.split('/')[2].split('.')[0] }else { 'VmManaged' } } else { '' })")
    $DataFromAzure.Add('vNet', $VnetName)
    $DataFromAzure.Add('SubnetName', $subnetName)
    $DataFromAzure.Add('HybridBenefit', "$(if ($null -eq $VM.LicenseType) { $false }else { $true })")
    $DataFromAzure.Add('ResourceGroup', $VM.ResourceGroupName)
    $DataFromAzure.Add('LBRule', "$($NicDetails.IpConfigurations.LoadBalancerBackendAddressPools.id).Split('/')[-1])")

    IF ($Status = Get-AzRecoveryServicesBackupStatus -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Type "AzureVM" -ErrorAction SilentlyContinue) {
        If ($Status.VaultId) {
            $Rsv = $Status.VaultId.Split('/')[-1]
            $DataFromAzure.Add('BackupVault', $Rsv)
        }
    }
    ELSE {
        Write-Host "Unable to get Recovery Service Status for $($VM.Name)"
    }
    return $DataFromAzure
}

#
# Get Data for network
#
Function Get-Network-Data {
    [hashtable]$DataFromAzure = @{}

    # Fetch data from azure
    $VNet = Get-AzVirtualNetwork -Name $ResourceName
    $Peerings = $Vnet.VirtualNetworkPeerings
    $PeerInfo = $Peerings.Name
    $Subnet = $VNet.Subnets #| Where-Object { $_.name -eq $SubnetName }

    # Add values to hash table
    $DataFromAzure.Add("Resource Group", $Vnet.ResourceGroupName)
    $DataFromAzure.Add("Vnet Name", $VNet.Name)
    $DataFromAzure.Add("Subnet Name", $Subnet.Name)
    $DataFromAzure.Add('Vnet Address', "$($VNet.AddressSpace.AddressPrefixes -join ',')")
    $DataFromAzure.Add('Subnet Address', "$($Subnet.AddressPrefix -join ',')")
    $DataFromAzure.Add('Peering1', "$($PeerInfo | Select-String -Pattern 'To-Core')")
    #$DataFromAzure.Add('Peering2', "$($PeerInfo | Select-String -Pattern 'To-Core')")
    $DataFromAzure.Add('NSG FrontEnd', "$(if ($subnet.NetworkSecurityGroup) { $subnet.NetworkSecurityGroup.Id.split('/')[-1] }else { '' })")

    return $DataFromAzure
}

#
# Compare the expected and actual values
#
Function ValidateValues() {
    $Result = @();
    FOREACH ($Item in $ExpectedValues.GetEnumerator()) {
        IF ($($Item.ExpectedValue) -ne 'NA') {
            $Obj = New-Object PSObject
            $Obj | Add-Member -Name Parameter -MemberType NoteProperty -Value $($Item.Parameter)
            $Obj | Add-Member -Name ExpectedValue -MemberType NoteProperty -Value $($Item.ExpectedValue)
            $Obj | Add-Member -Name ActualValue -MemberType NoteProperty -Value $DataFromAzure.Get_Item($($Item.Parameter))
            $Obj | Add-Member -Name Result -MemberType NoteProperty -Value "$(if ($($Item.ExpectedValue) -eq $DataFromAzure.Get_Item($($Item.Parameter))) { 'Pass' } else { 'Fail' })";    
            $Obj | Add-Member -Name PerformedAt -MemberType NoteProperty -Value $([System.DateTime]::UtcNow)
            $Result += $Obj            
        }
        ELSEIF ($($Item.ExpectedValue) -eq 'NA') {
            $Obj = New-Object PSObject
            $Obj | Add-Member -Name Parameter -MemberType NoteProperty -Value $($Item.Parameter)
            $Obj | Add-Member -Name ExpectedValue -MemberType NoteProperty -Value $($Item.ExpectedValue)
            # $Obj | Add-Member -Name ActualValue -MemberType NoteProperty -Value $DataFromAzure.Get_Item($($Item.Parameter))
            $Obj | Add-Member -Name ActualValue -MemberType NoteProperty -Value $($Item.ExpectedValue)
            $Obj | Add-Member -Name Result -MemberType NoteProperty -Value "$(if ($($Item.ExpectedValue) -eq $DataFromAzure.Get_Item($($Item.Parameter))) { 'Pass' } else { 'Pass' })";    
            $Obj | Add-Member -Name PerformedAt -MemberType NoteProperty -Value $([System.DateTime]::UtcNow)
            $Result += $Obj
        }
    }

    IF ($Result.Result -contains 'Fail') {
        Write-Host "$($ResourceName): QC validation failed"
    }

    return $Result
}

#
# Send Email
#
Function SendEmail([string] $attachmentPath) {
    $From = ""
    $To = ""
    $Attachment = $attachmentPath
    $Subject = "$($ResourceName) : QC validation result"
    $Body = "Insert body text here"
    $SMTPServer = "smtp.live.com"
    $SMTPPort = "587"
    Send-MailMessage -From $From -to $To -Subject $Subject `
        -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
        -Credential (Get-Credential) -Attachments $Attachment
}

#
# Send Email
#
Function ValidateArgs {
    IF (-not ($ResourceType -eq "VM" -or $ResourceType -eq "VNET")) {
        Write-Host "Invalid resource type provided. Accepted values are:  VM / VNET"
        Exit
    }
}

# Main - Clear the console before doing anything...
Clear-Host
ValidateArgs
Connect-AzAccount -Subscription 'CSS'
# $AzSubscription = Get-AzSubscription -SubscriptionName $SubscriptionName
# If (-not $AzSubscription) {
#     Write-Host("Unable to get the Subscription details")
#     Write-Host("Please verify the input values and try to run it again.")
#     Return
# }
# If ($AzSubscription) {
#     Set-AzContext -Name $SubscriptionName -TenantId $AzTenantID -ErrorAction Stop | Out-Null
# }

# Get a list of all files in the folder
Get-ChildItem $InputFolderPath -Filter '*.csv' -Name | ForEach-Object { 
    # Combines source folder path and file name
    $FilePath = "$($InputFolderPath)\$($_)"
    $File = Get-Item $FilePath
    $ResourceName = $File.Basename
    $OutputPath = "$($OutputFolderPath)\$($ResourceName)-$((Get-Date).ToUniversalTime().ToString(‘yyyyMMddTHHmmss’)).csv"

    # Imports CSV file
    $ExpectedValues = Import-Csv -Path $FilePath | Select-Object 'Parameter', 'ExpectedValue'

    Write-Host "$($ResourceName): Validation started!!" "`r`n"

    IF ($ResourceType -eq "VM") {
        $DataFromAzure = Get-VM-Data
    }
    ELSEIF ($ResourceType -eq "VNET") {
        $SubnetName = $($ExpectedValues | Where-Object { $_.Parameter -eq 'Subnet Name' }).ExpectedValue
        $DataFromAzure = Get-Network-Data
    }

    $Result = ValidateValues
    $Result | Export-Csv $OutputPath -NoTypeInformation
    # if ($SendEmail) {
    #     SendEmail($OutputPath)
    #     Write-Host "Email sent for $($ResourceName)" "`r`n"
    # }

    Write-Host "$($ResourceName): Validation completed!!" "`r`n"
}

