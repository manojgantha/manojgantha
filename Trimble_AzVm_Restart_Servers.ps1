##############################################################################
# File Name: Trimble_AzVm_Restart_Servers.ps1
# Author: Naresh Vanamala
# Date: 25th Jan 2022
# Version: 1.0
# Notes : Script is useful for Restarting the Trimble project Servers 
#         once after the configuration activity
##############################################################################

############## Reading the Values from the CSV file ###########################
Param(
    [parameter(Mandatory = $true)]
    $CsvFilePath
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$ErrorActionPreference = "Stop"

$scriptsPath = $PSScriptRoot
if ($PSScriptRoot -eq "") {
    $scriptsPath = "."
}

. "$scriptsPath\Trimble_AzVm_CommonMethods\TrimbleMigrateAutomation_Logger.ps1"
. "$scriptsPath\Trimble_AzVm_CommonMethods\TrimbleMigrateAutomation_CSV_Processor.ps1"

Function ProcessItemImpl($processor, $csvItem, $reportItem) {
    
    $reportItem | Add-Member NoteProperty "AdditionalInformation" $null
    
    try {
        $AzTenantID = $csvItem.AZURE_TENANT_ID.Trim()
        if ([string]::IsNullOrEmpty($AzTenantID)) {
            $processor.Logger.LogError("AZURE_TENANT_ID is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_TENANT_ID is not mentioned in the csv file" 
            return
        }
        $AzSubscriptionID = $csvItem.AZURE_SUBSCRIPTION_ID.Trim()
        if ([string]::IsNullOrEmpty($AzSubscriptionID)) {
            $processor.Logger.LogError("AZURE_SUBSCRIPTION_ID is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_SUBSCRIPTION_ID is not mentioned in the csv file" 
            return
        }
        $AzLocation = $csvItem.AZURE_LOCATION.Trim()
        if ([string]::IsNullOrEmpty($AzLocation)) {
            $processor.Logger.LogError("AZURE_LOCATION is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_LOCATION is not mentioned in the csv file" 
            return
        }
        $AzResourceGroupName = $csvItem.AZURE_PROJ_RESOURCE_GROUP_NAME.Trim()
        if ([string]::IsNullOrEmpty($AzResourceGroupName)) {
            $processor.Logger.LogError("AZURE_PROJ_RESOURCE_GROUP_NAME is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_PROJ_RESOURCE_GROUP_NAME is not mentioned in the csv file" 
            return
        }
        $AzVmDC = $csvItem.AZURE_VM_DC.Trim()
        if ([string]::IsNullOrEmpty($AzVmDC)) {
            $processor.Logger.LogError("AZURE_VM_DC is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_DC is not mentioned in the csv file" 
            return
        }
        $AzVmSQL = $csvItem.AZURE_VM_SQL.Trim()
        if ([string]::IsNullOrEmpty($AzVmSQL)) {
            $processor.Logger.LogError("AZURE_VM_SQL is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_SQL is not mentioned in the csv file" 
            return
        }
        $AzVmDB2 = $csvItem.AZURE_VM_DB2.Trim()
        if ([string]::IsNullOrEmpty($AzVmDB2)) {
            $processor.Logger.LogError("AZURE_VM_DB2 is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_DB2 is not mentioned in the csv file" 
            return
        }
        $AzVmAPP = $csvItem.AZURE_VM_APP.Trim()
        if ([string]::IsNullOrEmpty($AzVmAPP)) {
            $processor.Logger.LogError("AZURE_VM_APP is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_APP is not mentioned in the csv file" 
            return
        }
        $AzVmVDC = $csvItem.AZURE_VM_VDC.Trim()
        if ([string]::IsNullOrEmpty($AzVmVDC)) {
            $processor.Logger.LogError("AZURE_VM_VDC is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_VDC is not mentioned in the csv file" 
            return
        }
        $AzVmAGT = $csvItem.AZURE_VM_AGT.Trim()
        if ([string]::IsNullOrEmpty($AzVmAGT)) {
            $processor.Logger.LogError("AZURE_VM_AGT is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_AGT is not mentioned in the csv file" 
            return
        }
        $AzVmTM = $csvItem.AZURE_VM_TM.Trim()
        if ([string]::IsNullOrEmpty($AzVmTM)) {
            $processor.Logger.LogError("AZURE_VM_TM is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_TM is not mentioned in the csv file" 
            return
        }
        $AzVmPUBWEB = $csvItem.AZURE_VM_PUBWEB.Trim()
        if ([string]::IsNullOrEmpty($AzVmPUBWEB)) {
            $processor.Logger.LogError("AZURE_VM_PUBWEB is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_PUBWEB is not mentioned in the csv file" 
            return
        }
        $AzVmSYN = $csvItem.AZURE_VM_SYN.Trim()
        if ([string]::IsNullOrEmpty($AzVmSYN)) {
            $processor.Logger.LogError("AZURE_VM_SYN is not mentioned in the csv file")
            $reportItem.AdditionalInformation = "AZURE_VM_SYN is not mentioned in the csv file" 
            return
        }
    }
    catch {
        $processor.Logger.LogTrace("Input Values are not provided properly in the csv file ")
    }
    ############## Get Details of Azure resource group ###################
    $AzResourceGroupName
    $AzResourceGroup = Get-AzResourceGroup -Name $AzResourceGroupName -Location $AzLocation

    ############## Restarting DC Servers from the Input List ##############
    $processor.Logger.LogTrace("1. Restarting DC Servers from the Input List - Started")
    try {
        $AzVmDCValues = @()
        $AzVmDCValues = $AzVmDC.Split(",")
        if ($AzVmDCValues.count -ge 1) {
            $processor.Logger.LogTrace("Get Azure DC Virtual Machines from the resource group")
            foreach ($AzVmDCId in $AzVmDCValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmDCId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure DC Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The DC Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The DC Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The DC Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("1. Restarting DC Servers from the Input List - Completed")

    ############## Restarting SQL Servers from the Input List ##############
    $processor.Logger.LogTrace("2. Restarting SQL Servers from the Input List - Started")
    try {
        $AzVmSQLValues = @()
        $AzVmSQLValues = $AzVmSQL.Split(",")
        if ($AzVmSQLValues.count -ge 1) {
            $processor.Logger.LogTrace("Get Azure SQL Virtual Machines from the resource group")
            foreach ($AzVmSQLId in $AzVmSQLValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmSQLId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure SQL Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The SQL Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The SQL Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The SQL Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("2. Restarting SQL Servers from the Input List - Completed")

    ############## Restarting DB2 Servers from the Input List ##############
    $processor.Logger.LogTrace("3. Restarting DB2 Servers from the Input List - Started")
        
    try {
        $AzVmDB2Values = @()
        $AzVmDB2Values = $AzVmDB2.Split(",")
        if ($AzVmDB2Values.count -ge 1) {
            foreach ($AzVmDB2Id in $AzVmDB2Values) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure DB2 Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmDB2Id
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure DB2 Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The DB2 Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The DB2 Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The DB2 Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("3. Restarting DB2 Servers from the Input List - Completed")

 
    ############## Restarting App Servers from the Input List ##############
    $processor.Logger.LogTrace("4. Restarting APP Servers from the Input List - Started")
    try {
        $AzVmAppValues = @()
        $AzVmAppValues = $AzVmAPP.Split(",")
        if ($AzVmAppValues.count -ge 1) {
            foreach ($AzVmAppId in $AzVmAppValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure APP Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmAppId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure App Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The APP Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The APP Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The APP Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("4. Restarting APP Servers from the Input List - Completed")

    ############## Restarting VDC Servers from the Input List ##############
    $processor.Logger.LogTrace("5. Restarting VDC Servers from the Input List - Started")
    try {
        $AzVmVDCValues = @()
        $AzVmVDCValues = $AzVmVDC.Split(",")
        if ($AzVmVDCValues.count -ge 1) {
            foreach ($AzVmVDCId in $AzVmVDCValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure VDC Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmVDCId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure VDC Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The VDC Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The VDC Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The VDC Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("5. Restarting VDC Servers from the Input List - Completed")

    ############## Restarting AGT Servers from the Input List ##############
    $processor.Logger.LogTrace("6. Restarting AGT Servers from the Input List - Started")
    try {
        $AzVmAGTValues = @()
        $AzVmAGTValues = $AzVmAGT.Split(",")
        if ($AzVmAGTValues.count -ge 1) {
            foreach ($AzVmAGTId in $AzVmAGTValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure AGT Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmAGTId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure AGT Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The AGT Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The AGT Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The AGT Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("6. Restarting AGT Servers from the Input List - Completed")

    ############## Restarting TM Servers from the Input List ##############
    $processor.Logger.LogTrace("7. Restarting TM Servers from the Input List - Started")
    try {
        $AzVmTMValues = @()
        $AzVmTMValues = $AzVmTM.Split(",")
        if ($AzVmTMValues.count -ge 1) {
            foreach ($AzVmTMId in $AzVmTMValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure TM Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmTMId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure TM Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The TM Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The TM Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The TM Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("7. Restarting TM Servers from the Input List - Completed")
 
    ############## Restarting PUBWEB Servers from the Input List ##############
    $processor.Logger.LogTrace("8. Restarting PUBWEB Servers from the Input List - Started")
    try {
        $AzVmPUBWEBValues = @()
        $AzVmPUBWEBValues = $AzVmTM.Split(",")
        if ($AzVmPUBWEBValues.count -ge 1) {
            foreach ($AzVmPUBWEBId in $AzVmPUBWEBValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure PUBWEB Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmPUBWEBId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure PUBWEB Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The PUBWEB Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The PUBWEB Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The PUBWEB Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("8. Restarting PUBWEB Servers from the Input List - Completed")

    ############## Restarting SYN Servers from the Input List ##############
    $processor.Logger.LogTrace("9. Restarting SYN Servers from the Input List - Started")
    try {
        $AzVmSYNValues = @()
        $AzVmSYNValues = $AzVmSYN.Split(",")
        if ($AzVmSYNValues.count -ge 1) {
            foreach ($AzVmSYNId in $AzVmSYNValues) {
                ############## Get Az Virtual Machines from the resource group ###################
                $processor.Logger.LogTrace("Get Azure SYN Virtual Machines from the resource group")
                $VirtualMachine = Get-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $AzVmSYNId
                if ($VirtualMachine.Name) {
                    ####################### Restart the Azure Virtual Machine Name ######################
                    $processor.Logger.LogTrace("Restart the Azure SYN Virtual Machine Name: $($VirtualMachine.Name) at $((Get-Date).ToString(‘yyyy_MM_dd_HH:mm:ss’))")
                    Restart-AzVM -ResourceGroupName $AzResourceGroup.ResourceGroupName -Name $VirtualMachine.Name
                }
                else {
                    $processor.Logger.LogTrace("The SYN Virtual Machine Name is invalid..!")
                }
            }
        }
        else {
            $processor.Logger.LogTrace("The SYN Virtual Machine Name is not provided in input sheet..!")
        }
    }
    catch {
        $processor.Logger.LogTrace("The SYN Virtual Machine Name is invalid..!")
    }
    $processor.Logger.LogTrace("9. Restarting SYN Servers from the Input List - Completed")
}

Function ProcessItem($processor, $csvItem, $reportItem) {
    try {
        ProcessItemImpl $processor $csvItem $reportItem
    }
    catch {
        $exceptionMessage = $_ | Out-String
        $reportItem.Exception = $exceptionMessage
        $processor.Logger.LogErrorAndThrow($exceptionMessage)        
    }
}

$logger = New-TrimbleAutomation_LoggerInstance -CommandPath $PSCommandPath
$processor = New-CsvProcessorInstance -logger $logger -processItemFunction $function:ProcessItem
$processor.ProcessFile($CsvFilePath)

############### Set Azure Location ###########################################
$azContext = Get-AzContext
If ($azContext) {
    If ($azContext.Subscription.Name -eq $SubscriptionName) {
        $Azlocation = $azLocationName
        Write-Host
        $processor.Logger.LogTrace("Location for Azure Resources is set to " + $Azlocation)
    }
}
##################################################################################################