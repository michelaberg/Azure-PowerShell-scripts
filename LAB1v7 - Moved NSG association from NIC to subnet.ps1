﻿# Authenticate to Azure
Connect-AzAccount

# Define parameters
$resourceGroupName = "MyResourceGroup"
$location = "swedencentral"
$vnetName = "MyVNet"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetName = "MySubnet"
$subnetAddressPrefix = "10.0.0.0/24"
$nsgName = "MyNSG"
$nicName = "MyNIC"
$publicIpName = "MyPublicIP"
$vmName = "MyVM"
$vmSize = "Standard_B2s"
$osDiskName = "MyVMOSDisk" 
$osDiskType = "StandardSSD_LRS"
$adminCredential = Get-Credential -Message "Enter the credentials for the VM admin account"

# Create ResourceGroup.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create Virtual Network (VNet)
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $vnetName `
    -AddressPrefix $vnetAddressPrefix

# Create Network Security Group (NSG)
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $nsgName

# Create NSG rule - Note that ALL IPs are allowed for RDP.
# Change the -SourceAdressPrefix to a trusted IP if you want to use the script.
# I use my WAN-IP or VPN-IP, but you can set any scope you like. The Emperor protects - sometimes.
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-RDP" `
    -Description "Allow RDP" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 100 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "3389"

# Add NSG rule to NSG
$nsg.SecurityRules.Add($nsgRuleRDP)

# Update NSG with the new rules
$nsg = Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

# Add Subnet to VNet with NSG association
$subnet = Add-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix `
    -VirtualNetwork $vnet `
    -NetworkSecurityGroup $nsg

# Apply the configuration to the VNet
$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet

# Create Public IP Address
$publicIp = New-AzPublicIpAddress `
    -Name $publicIpName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AllocationMethod Static

# Create Network Interface (NIC) with Public IP
$nic = New-AzNetworkInterface `
    -Name $nicName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $publicIp.Id

# Define VM configuration
$vmConfig = New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize |
    Set-AzVMOperatingSystem `
    -Windows `
    -ComputerName $vmName `
    -Credential $adminCredential |
    Set-AzVMSourceImage `
    -PublisherName "MicrosoftWindowsServer" `
    -Offer "WindowsServer" `
    -Skus "2019-Datacenter" `
    -Version "latest" |
    Add-AzVMNetworkInterface `
    -Id $nic.Id

# Configure the OS Disk
$vmConfig = Set-AzVMOSDisk `
    -VM $vmConfig `
    -Name $osDiskName `
    -CreateOption "FromImage" `
    -Caching "ReadWrite" `
    -StorageAccountType $osDiskType

# Disable Boot Diagnostics
$vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Enable $false

# Deploy the VM
New-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -VM $vmConfig

# Output the created resources details
Write-Output "VM '$vmName' with VNet '$vnetName', Subnet '$subnetName', NIC '$nicName', and NSG '$nsgName' created successfully in resource group '$resourceGroupName'. For the Emperor."
