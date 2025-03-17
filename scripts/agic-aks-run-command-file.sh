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

if [ -f $shared eq "true" ]
then
    cat <<EOF > $helmValuesFileName
appgw:
  name: '${AppgwID}'
  resourceGroup: '${RG}'
  subscriptionId: '${subscriptionID}'
  subResourceNamePrefix: '${subResourceNamePrefix}'
  shared: ${shared}
armAuth:
  type: workloadIdentity
  identityClientID: '${ClientID}'
rbac:
  enabled: true
verbosityLevel: '${verbosityLevel}'
EOF
else
    cat <<EOF > $helmValuesFileName
appgw:
  name: '${AppgwID}'
  resourceGroup: '${RG}'
  subscriptionId: '${subscriptionID}'
  shared: ${shared}
armAuth:
  type: workloadIdentity
  identityClientID: '${ClientID}'
rbac:
  enabled: true
verbosityLevel: '${verbosityLevel}'
EOF
fi



#echo -n $helmAppValues | base64 -d > $helmValuesFileName
echo "Helm values file created and stored at $helmValuesFileName"

echo "Helm values are as follows:
AppgwID: ${AppgwID}
RG: ${RG}
subscriptionID: ${subscriptionID}
ClientID: ${ClientID}
verbosityLevel: ${verbosityLevel}"

echo "Sending command to AKS Cluster $aksName in $RG"
cmdOut=$(az aks command invoke -g $RG -n $aksName --command "helm install '${DeployName}' 'oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure' --namespace ${AGICNamespace} --version 1.7.5 --create-namespace -f ${helmValuesFileName} --debug" --file $helmValuesFileName -o json)
echo $cmdOut

jsonOutputString=$cmdOut
echo $jsonOutputString > $AZ_SCRIPTS_OUTPUT_PATH