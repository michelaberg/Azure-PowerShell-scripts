# Create ResourceGroup.
New-AzResourceGroup -Name "MyResourceGroup" -Location "swedencentral"

# Define general parameters
$resourceGroupName = "MyResourceGroup"
$location = "EastUS"
$vmName = "MyVM"
$vmSize = "Standard_B1s"  # Use Standard_B1s for the Azure free tier
$adminCredential = Get-Credential -Message "Enter the credentials for the VM admin account"
$vnetName = "MyVNet"
$subnetName = "MySubnet"
$nicName = "MyNIC"

# OS Disk parameters (using defaults provided by the image)
$osDiskName = "MyVMOSDisk"
$osDiskType = "Standard_LRS" # Set to Standard_LRS for Standard HDD

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix "10.0.0.0/16"

# Add a subnet configuration to the virtual network
Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet

# Commit the changes to the virtual network
$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet

# Validate the subnet
if ($vnet.Subnets.Count -eq 0) {
    Write-Error "No subnets found in the virtual network. Please check subnet creation."
    return
} else {
    Write-Output "Subnet ID: $($vnet.Subnets[0].Id)"
}

# Create a public IP address
$publicIp = New-AzPublicIpAddress -Name "MyPublicIP" -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static

# Create a network interface card with the valid subnet ID
if ($vnet.Subnets.Count -gt 0) {
    $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id
} else {
    Write-Error "Cannot create NIC because the subnet ID is null or empty."
    return
}

# Define the VM configuration without specifying custom OS disk size
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $adminCredential |
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic.Id |
    Set-AzVMOSDisk -Name $osDiskName -CreateOption FromImage -StorageAccountType $osDiskType

# Disable Boot Diagnostics
$vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Enable $false

# Deploy the VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
