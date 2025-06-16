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

#echo -n $helmAppValues | base64 -d > $helmValuesFileName


echo "Sending command to AKS Cluster $aksName in $RG"
cmdOut=$(az aks command invoke -g $RG -n $aksName --command "helm install '${DeployName}' 'oci://mcr.microsoft.com/application-lb/charts/alb-controller' --namespace azure-alb-system --version ${AGCVersion} --create-namespace --debug --set albController.namespace=${CONTROLLER_NAMESPACE} --set albController.podIdentity.clientID=${ALBClientID}" -o json)
echo $cmdOut

jsonOutputString=$cmdOut
echo $jsonOutputString > $AZ_SCRIPTS_OUTPUT_PATH