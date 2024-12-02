# This file simplifies Bicep deployment by doing the following:
#   Creates unique Resource Group names
#   Verifies that the Context is set for Azure PowerShell deployments
#   Correctly formulates the deployment command to include all template and parameter files
#   Provides timestamps and timespans to help track the length of time it takes to deploy the resources
#   Provides links to the newly created Resource Group in the Azure Portal
#   Manages the Tenant and Subscription that the resources will be deployed to

param(
    [Parameter(Mandatory)]

    [string]$DeploymentName,

    [Parameter(Mandatory)]
    [string]$Location,

    [bool]$subleveldeployment = $false,
    
    [bool]$DeployWithParamFile = $true,

    [bool]$Debuglog = $false
)

# Verifies that AzContext is set and displays the subscription information to where this deployment will be completed.
if (!($context = Get-AzContext)) {
    Write-Host "Run both Connect-AzAccount and Set-AzContext -Tenant <TenantId> and -Subscription <SubscriptionId>"
    Write-Host "Once both have been completed, run this script again."
    return
}

Write-Host "AzContext is set to the following:"
Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id)) | Tenant: $($context.Tenant.Id)`n"

$deploymentFilePath = ".\Lab_Deployments\${DeploymentName}"
$mainBicepFile = "${deploymentFilePath}\src\main.bicep"
$mainParameterFile = "${deploymentFilePath}\src\main.bicepparam"
$iterationFile = "${deploymentFilePath}\iteration.txt"

# Define the search string for a sub level deployment
$subscriptioncontextsearchString = "targetScope = 'subscription'"

# Use Select-String to search for the string in the file
$searchResult = Select-String -Path $mainBicepFile -Pattern $subscriptioncontextsearchString

# Check if the string was found and output the result
if ($searchResult) {
    Write-Host "This deployment is a subscription level deployment"
	$subleveldeployment = $true
} else {
    Write-Output "This deployment is a resource group level deployment"
	$subleveldeployment = $false
}

if ($subleveldeployment) {
    # Switches off the Parameter file option in the deployment if the parameter file does not exist
    if (!(Test-Path $mainParameterFile)) {
        Write-Host "Parameters file does not exist. This is required for subscription level deployments. Please create the parameters file and try again."
        Exit
    }

    if (Test-Path $iterationFile) {
        $iteration = [int](Get-Content $iterationFile)
        $rgName = "${DeploymentName}_RG_${iteration}"
    }
    else {
        $iteration = 0
        New-Item -ItemType File -Path $iterationFile
        Set-Content -Path $iterationFile -Value "${iteration}"
    }

    # Define the regex pattern to match all RGName parameters
    $pattern = "param RGName\d+ = '([^']*)'"

    # Define the additional text to append
    $iterationnumber = "-${iteration}"

    # Read the content of the parameters file
    $content = Get-Content -Path $mainParameterFile -Raw

    # Find all matches of the pattern
    $regexmatches = [regex]::Matches($content, $pattern)

    # Iterate through each match and update the value
    foreach ($match in $regexmatches) {
        # Extract the existing value within the quotes
        $existingValue = $match.Groups[1].Value

        # Create the new value by appending the additional text
        $newValue = "$existingValue$iterationnumber"

        # Replace the matched string with the new value in the content
        $content = $content -replace [regex]::Escape($match.Value), $match.Value -replace $existingValue, $newValue
        Write-Host "Checking if ${match.Value} exists."
        $RGExists = Get-AzResourceGroup -Name $match.Value -ErrorAction SilentlyContinue
        
        if (-not $RGexists) {
            Write-Output "Resource group ${match.Value} does not exist."
            exit 1
        }
        else {
            Write-Output "Resource group ${match.Value} exists. Exiting deployment. Please try again."
            Set-Content -Path $iterationFile -Value "$($iteration + 1)"
            exit
        }
    }

    # Save the updated content back to the file
    Set-Content -Path $mainParameterFile -Value $content

    Write-Output "Parameter values updated successfully."

    $DeploymentVersion = "${DeploymentName}-${iteration}"

    Set-Content -Path $iterationFile -Value "$($iteration + 1)"


    New-AzResourceGroup -Name $rgName -Location $Location

    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    Write-Host "`nStarting Bicep Deployment.  Process began at: $(Get-Date -Format "HH:mm K")`n"

    if ($Debuglog -eq $true) {
        Write-Host "Deployment Version: $DeploymentVersion"
        Write-Host "Location: $Location"
        Write-Host "Template File: $mainBicepFile"
        Write-Host "Parameter File: $mainParameterFile"

        New-AzDeployment -name $DeploymentVersion -Location $Location -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile -AsJob -DeploymentDebugLogLevel All
    }
    else {
            New-AzDeployment -name $DeploymentVersion -Location $Location -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile -AsJob

    }
    Write-Host "The deployment can be monitored by navigating to the URL below: "
    Write-Host -ForegroundColor Blue "https://portal.azure.com/#@/subscriptions/$($context.Subscription.Id)/providers/Microsoft.Resources/deployments/${DeploymentVersion}`n"
}

else{
    # Switches off the Parameter file option in the deployment if the parameter file does not exist
    if (!(Test-Path $mainParameterFile)) {
        $DeployWithParamFile = $false
    }

    if (Test-Path $iterationFile) {
        $iteration = [int](Get-Content $iterationFile)
        $rgName = "${DeploymentName}_RG_${iteration}"
    }
    else {
        $iteration = 0
        New-Item -ItemType File -Path $iterationFile
        Set-Content -Path $iterationFile -Value "${iteration}"
    }

    if (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue) {
        $response = Read-Host "Resource Group ${rgName} already exists.  How do you want to handle this?  Below are the options.  Type the corresponding number and enter to choose.

        1 - Delete this Resource Group and create another Resource Group with a higher iteration number.
        2 - Leave this Resource Group alone and create another Resource Group with a higher iteration number.
        3 - Update this Resource Group with the latest changes.
        
        Response: "

        if ($response -eq "1") {
            Write-Host "`nDeleting $rgName"
            Remove-AzResourceGroup -Name $rgName -Force -AsJob
            Set-Content -Path $iterationFile -Value "$($iteration + 1)"
            $iteration = [int](Get-Content $iterationFile)
            $rgName = "${DeploymentName}_RG_${iteration}"
            Write-Host "Creating $rgName"
        } 
        elseif ($response -eq "2") {
            Write-Host "`nDisregarding $rgName"
            Set-Content -Path $iterationFile -Value "$($iteration + 1)"
            $iteration = [int](Get-Content $iterationFile)
            $rgName = "${DeploymentName}_RG_${iteration}"
            Write-Host "Creating $rgName"
        } 
        elseif ($response -eq "3") {
            Write-Host "`nUpdating $rgName"
        } 
        else {
            Write-Host "Invalid response.  Canceling Deploment.."
            return
        }
    } 
    else {
        Set-Content -Path $iterationFile -Value "$($iteration + 1)"
        $iteration = [int](Get-Content $iterationFile)
        $rgName = "${DeploymentName}_RG_${iteration}"
    }

    New-AzResourceGroup -Name $rgName -Location $Location

    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    Write-Host "`nStarting Bicep Deployment.  Process began at: $(Get-Date -Format "HH:mm K")`n"

    Write-Host "The deployment can be monitored by navigating to the URL below: "
    Write-Host -ForegroundColor Blue "https://portal.azure.com/#@/resource/subscriptions/$($context.Subscription.Id)/resourceGroups/${rgName}/deployments`n"

    if ($DeployWithParamFile) {

        if ($Debuglog -eq $true) {
            Write-Host "Location: $Location"
            Write-Host "Template File: $mainBicepFile"
            Write-Host "Parameter File: $mainParameterFile"

            New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile -DeploymentDebugLogLevel All
        }
        else {
            New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile
        }

    }
    else {
        if ($Debuglog -eq $true) {
            Write-Host "Location: $Location"
            Write-Host "Template File: $mainBicepFile"
            Write-Host "Parameter File: $mainParameterFile"

            New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile -DeploymentDebugLogLevel All
        }
        else {
            New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile
        }
        
    }
}

$stopwatch.Stop()

Write-Host "Process finished at: $(Get-Date -Format "HH:mm K")"
Write-Host "Total time taken in minutes: $($stopwatch.Elapsed.TotalMinutes)"

if ($subleveldeployment) {}
else {
Write-Host "Below is a link to the newly created/modified Resource Group: "
Write-Host -ForegroundColor Blue "https://portal.azure.com/#@/resource/subscriptions/$($context.Subscription.Id)/resourceGroups/${rgName}`n"
}