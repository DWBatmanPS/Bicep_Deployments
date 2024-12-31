#!/bin/bash

set -e +H
# -e to exit on error
# +H to prevent history expansion

# Set the script's locale to UTF-8 to ensure proper handling of UTF-8 encoded text
export LANG=C.UTF-8

if [ "$initialDelay" != "0" ]
then
    echo "Waiting on RBAC replication ($initialDelay)"
    sleep $initialDelay

    #Force RBAC refresh
    az logout
    az login --identity
fi

# Define the filename for the Helm values
helmValuesFileName="$(dirname "$0")/helmvalues.yaml"

echo "Creating Helm values file..."
echo -n $helmAppValues | base64 -d > $helmValuesFileName
echo "Helm values file created and stored at $helmValuesFileName"

echo "Sending command to AKS Cluster $aksName in $RG"
cmdOut=$(az aks command invoke -g $RG -n $aksName --command "helm install '${DeployName}' 'oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure' --namespace ${AGICNamespace} --version 1.7.5 --create-namespace  --set 'appgw.name=${AppgwID}' --set 'appgw.resourceGroup=${RG}' --set 'appgw.subscriptionId=${SubscriptionID}' --set 'appgw.shared=false' --set 'armAuth.type=workloadIdentity'  --set 'armAuth.identityClientID=${ClientID}' --set 'rbac.enabled=true' --set 'verbosityLevel=5'" -o json)
echo $cmdOut

jsonOutputString=$cmdOut
echo $jsonOutputString > $AZ_SCRIPTS_OUTPUT_PATH