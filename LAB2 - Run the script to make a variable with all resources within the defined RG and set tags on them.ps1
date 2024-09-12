# Define the resource group name
$resourceGroupName = "MyResourceGroup" 

# Retrieve and store all resources in the specified resource group into a variable
$resourcesList = Get-AzResource -ResourceGroupName $resourceGroupName

# Loop through each resource and apply a tag
foreach ($resource in $resourcesList) {
    # Get existing tags (if any)
    $currentTags = $resource.Tags
    
    # Add or update the 'Owner' tag
    $newTags = @{"Owner" = "Michel"}

    # If there are existing tags, merge them with the new tag
    if ($currentTags) {
        $newTags = $currentTags + $newTags
    }

    # Set the new tags on the resource
    Set-AzResource -ResourceId $resource.ResourceId -Tag $newTags -Force

    # Output the result
    Write-Output ("Tagged resource: " + $resource.Name + " with Owner=Michel")
}