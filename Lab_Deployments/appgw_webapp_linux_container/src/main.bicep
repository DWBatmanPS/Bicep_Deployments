param appServicePlan string 
param certname string  

param keyvault_managed_ID string 

param dnsServers array = []

param subnet_Names array = [
  'AGSubnet'
]

param virtualNetworkPrefix string = '10.0.0.0/16'

param virtualNetworkName string = 'webappappgw_vnet'
param publicIPAddressName string = 'webappappgw_vip'
param applicationGateWayName string = 'dwwebapp-appgw'
param image string = 'ghcr.io/example/example:latest'


param keyVaultName string = ''

@description('The name of the App Service application to create. This must be globally unique.')
var appName = 'DW-${uniqueString(resourceGroup().id)}'

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    dnsServers: dnsServers
    subnet_Names: subnet_Names
  }
}

module appgw '../../../modules/Microsoft.Network/ApplicationGateway_v2.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: certname
    isWAF: false
    isE2ESSL: true
    backendPoolFQDNs: [
      '${Webapp.outputs.website_FQDN}'
    ]
    useCustomProbe: true
    tagValues: {}
  }
}

module Webapp '../../../modules/Microsoft.Web/site_linux.bicep' = {
  name: 'Webapp'
  params: {
    site_Name: appName
    appServicePlan_Name: appServicePlan
    image: image
  }
}

