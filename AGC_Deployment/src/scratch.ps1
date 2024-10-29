$RG = "agc_test"
$template = ".\main2.bicep"
$params = ".\main.bicepparam"

New-AzResourceGroup -Name $RG -Location "Central US"

New-AzResourceGroupDeployment -ResourceGroupName $RG -TemplateFile $template -TemplateParameterFile $params -DeploymentDebugLogLevel All -Mode Complete | Out-File ".\deploymentoutput.log"

New-AzResourceGroupDeployment -ResourceGroupName $RG -TemplateFile $template -DeploymentDebugLogLevel All | Out-File ".\deploymentoutput.log"
current output is fcc7cb27-f2fc-4af2-a5d2-b0a6cd8c57d0


az aks show --name "akscluster" --resource-group "agc_test" --query "oidcIssuerProfile.issuerUrl" --output tsv



$agc = get-azresource -resourceid/subscriptions/19eafc06-e068-4019-86b1-c203a3f0b12b/resourcegroups/agc_test/providers/Microsoft.ServiceNetworking/trafficControllers/agc

az network alb association delete --association-name agcassociation-AGCSubnet --resource-group agc_test --alb-name agc

az network alb update --resource-group agc_test -n agc --tags @{}