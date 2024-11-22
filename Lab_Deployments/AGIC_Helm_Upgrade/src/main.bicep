param aksClusterName string = 'aks'
param aksClusterNodeCount int = 3
param aksClusterNodeSize string = 'Standard_D2s_v3'
param aksClusterKubernetesVersion string = '1.29.4'
param aksdnsPrefix string 
param linuxadmin string
param sshkey string = ''
param VnetName string 
param virtualNetwork_AddressPrefix string = '10.0.0.0/16'
param subnet_Names array = [
  'AKSSubnet'
  'AppGatewaySubnet'
]
param akspodcidr string = '10.244.0.0/16'
param aksserviceCidr string = '192.168.16.0/20'
param aksinternalDNSIP string = '192.168.16.10'
param appgwname string = 'agic-appgw'
param publicIP_ApplicationGateway_Name string = 'agic-appgwip'
//param serviceprincipal_client_Id string


module AKSCluster '../../../modules/Microsoft.ContainerService/aks_cluster.bicep' = {
  name: 'aks_deployment'
  params: {
    aksClusterName: aksClusterName
    aksClusterNodeCount: aksClusterNodeCount
    aksClusterNodeSize: aksClusterNodeSize
    aksClusterKubernetesVersion: aksClusterKubernetesVersion
    VnetName: VnetName
    aksdnsPrefix: aksdnsPrefix
    linuxadmin: linuxadmin
    sshkey: sshkey
    akspodCidr: akspodcidr
    aksserviceCidr: aksserviceCidr
    aksinternalDNSIP: aksinternalDNSIP
    aksClusterSubnetname: subnet_Names[0]
  }
}

module Vnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: VnetName
  params: {
    virtualNetwork_Name: VnetName
    virtualNetwork_AddressPrefix: virtualNetwork_AddressPrefix
    subnet_Names: subnet_Names
  }
}

module AppGateway '../../../modules/Microsoft.Network/ApplicationGateway_v2.bicep' = {
  name: 'appgateway_deployment'
  params: {
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, subnet_Names[1])
    applicationGateway_Name: appgwname
    publicIP_ApplicationGateway_Name: publicIP_ApplicationGateway_Name
    backendPoolFQDNs: []
    nossl: true
  }
}

/*  module authorization '../../../modules/Microsoft.Authorization/agic_role.bicep' = {
  name: 'agic_role'
  params: {
    serviceprincipal_client_Id: serviceprincipal_client_Id 
    appgwname: appgwname
    vnetName: VnetName
  }
  dependsOn: [
    AppGateway
    Vnet
  ]
}  */
