# Authenticate to Azure
Connect-AzAccount

# Define parameters
$resourceGroupName = "MyResourceGroup"
$nsgName = "MyNSG"

# Get the existing NSG
$nsg = Get-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Name $nsgName

# Find the existing "Allow-RDP" rule
$existingRule = $nsg.SecurityRules | Where-Object { $_.Name -eq "Allow-RDP" }

# Check if the rule exists
if ($existingRule) {
    # Modify the rule properties
    $existingRule.Access = "Deny"  # Change Access from Allow to Deny
    $existingRule.Name = "Deny-RDP"  # Optionally change the rule name
    $existingRule.Description = "Deny RDP"  # Optionally change the description

    # Update the NSG with the modified rule
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

    Write-Host "The RDP rule has been updated to deny access."
} else {
    Write-Host "The rule 'Allow-RDP' was not found in the NSG."
}
