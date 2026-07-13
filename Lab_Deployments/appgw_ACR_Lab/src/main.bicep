 

param keyvault_managed_ID string 

param dnsServers array = []

param subnet_Names array = [
  'AGSubnet'
  'PESubnet'
]

param virtualNetworkPrefix string = '10.0.0.0/16'

param virtualNetworkName string = 'appgw_vnet'
param publicIPAddressName string = 'appgw_vip'
param applicationGateWayName string = 'dwwebapp-appgw'
param acrName string = 'acr${uniqueString(resourceGroup().id)}'
param vanityDomainName string = 'acr.com'
param subscriptionId string 
param kvrgname string

param keyVaultName string = ''
param keyvault_cert string = 'cert'
param rewriteRuleSets array = []

var acrNameString = '${acrName}${uniqueString(resourceGroup().id)}'
module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    dnsServers: dnsServers
    subnet_Names: subnet_Names
  }
}

module appgw '../../../modules/Microsoft.Network/ApplicationGateway_v2_exactRewrites.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: keyvault_cert
    isWAF: false
    isE2ESSL: true
    backendPoolFQDNs: [
      acr.outputs.acrFqdn
    ]
    useCustomProbe: true
    backendURL: acrNameString
    vanityDomainName: vanityDomainName
    rewriteRuleSets: rewriteRuleSets
    tagValues: {}
  }
  dependsOn: [
    kvpe
    acr
  ]
}

module acr '../../../modules/Microsoft.ContainerRegistry/registries.bicep' = {
  name: acrNameString
  params: {
    acrName: acrNameString
    sku: 'Premium'
    vnetName: virtualNetworkName
    subnetName: 'PESubnet'
    deployPrivateEndpoint: true
    publicNetworkAccess: 'Disabled'
  }
}

module kvpe '../../../modules/Microsoft.KeyVault/KeyVaultPrivateEndpoint.bicep' = {
  name: 'kvpe'
  params: {
    keyVaultName: keyVaultName
    privateEndpointName: '${keyVaultName}-pe'
    vnetName: virtualNetworkName
    subnetName: 'PESubnet'
    kvResourceGroupName: kvrgname
    remoteSubscriptionId: subscriptionId
  }
  dependsOn: [
    virtualNetwork
  ]
}
