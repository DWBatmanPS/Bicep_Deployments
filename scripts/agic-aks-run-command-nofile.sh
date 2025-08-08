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

echo "Helm values are as follows:
AppgwID: ${AppgwID}
RG: ${RG}
subscriptionID: ${subscriptionID}
ClientID: ${ClientID}
verbosityLevel: ${verbosityLevel}"

echo "Sending command to AKS Cluster $aksName in $RG"
cmdOut=$(az aks command invoke -g $RG -n $aksName --command "helm install '${DeployName}' 'oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure' --namespace ${AGICNamespace} --version ${AGICVersion} --create-namespace--set appgw.name=${AppgwID} --set appgw.resourceGroup=${RG} --set appgw.subscriptionId=${subscriptionID} --set appgw.shared=${shared} --set armAuth.type=workloadIdentity --set armAuth.identityClientID=${ClientID} --set rbac.enabled=true --set verbosityLevel=${verbosityLevel} --debug" -o json)
echo $cmdOut

jsonOutputString=$cmdOut
echo $jsonOutputString > $AZ_SCRIPTS_OUTPUT_PATH