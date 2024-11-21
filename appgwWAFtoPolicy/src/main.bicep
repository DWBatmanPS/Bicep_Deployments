param certname string = '' 

param keyvault_managed_ID string = ''

param dnsServers array = []

param subnet_Names array = [
  'AGSubnet'
]

param virtualNetworkPrefix string = '10.0.0.0/16'

param virtualNetworkName string = 'webappappgw_vnet'
param publicIPAddressName string = 'webappappgw_vip'
param applicationGateWayName string = 'appgw'
param isWAF bool = true

param keyVaultName string = ''

module virtualNetwork '../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    dnsServers: dnsServers
    subnet_Names: subnet_Names
    deployudr: false
  }
}

module appgw '../../modules/Microsoft.Network/ApplicationGateway_v2_wafconfig.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: certname
    isWAF: isWAF
    backendPoolFQDNs: []
    tagValues: {}
  }
}
