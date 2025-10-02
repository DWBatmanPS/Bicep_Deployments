param aksClusterName string = 'aks'
param aksClusterName2 string = 'aks2'
param aksClusterNodeCount int = 3
param aksClusterNodeSize string = 'Standard_D2s_v3'
param aksClusterKubernetesVersion string = '1.31'
param aksdnsPrefix string
param aksdnsPrefix2 string 
param linuxadmin string
param sshkey string = ''
param VnetName string 
param virtualNetwork_AddressPrefix string = '10.0.0.0/16'
param subnet_Names array = [
  'AKSSubnet'
  'AKSSubnet2'
  'AppGatewaySubnet'
]
param akspodcidr string = '10.244.0.0/16'
param aksserviceCidr string = '192.168.16.0/20'
param aksinternalDNSIP string = '192.168.16.10'
param akspodcidr2 string = '10.245.0.0/16'
param aksserviceCidr2 string = '192.168.32.0/20'
param aksinternalDNSIP2 string = '192.168.32.10'
param appgwname string = 'agic-appgw'
param publicIP_ApplicationGateway_Name string = 'agic-appgwip'
param AGICNamespace string = 'default'
param DeployName string = 'agic-controller'
param guid1 string = newGuid()
param guid2 string = newGuid()
param guid3 string = newGuid()
param guid4 string = newGuid() 
param guid5 string = newGuid()
param guid6 string = newGuid()
//param serviceprincipal_client_Id string


module AKSCluster '../../../modules/Microsoft.ContainerService/aks_cluster_azurecnioverlay.bicep' = {
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
  dependsOn: [
    Vnet
  ]
}

module AKSCluster2 '../../../modules/Microsoft.ContainerService/aks_cluster_azurecnioverlay.bicep' = {
  name: 'ak2s_deployment'
  params: {
    aksClusterName: aksClusterName2
    aksClusterNodeCount: aksClusterNodeCount
    aksClusterNodeSize: aksClusterNodeSize
    aksClusterKubernetesVersion: aksClusterKubernetesVersion
    VnetName: VnetName
    aksdnsPrefix: aksdnsPrefix2
    linuxadmin: linuxadmin
    sshkey: sshkey
    akspodCidr: akspodcidr2
    aksserviceCidr: aksserviceCidr2
    aksinternalDNSIP: aksinternalDNSIP2
    aksClusterSubnetname: subnet_Names[1]
  }
  dependsOn: [
    Vnet
  ]
}

module Vnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: VnetName
  params: {
    virtualNetwork_Name: VnetName
    virtualNetwork_AddressPrefix: virtualNetwork_AddressPrefix
    subnet_Names: subnet_Names
    deployudr: false
  }
}

module AppGateway '../../../modules/Microsoft.Network/ApplicationGateway_v2.bicep' = {
  name: 'appgateway_deployment'
  params: {
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, subnet_Names[2])
    applicationGateway_Name: appgwname
    publicIP_ApplicationGateway_Name: publicIP_ApplicationGateway_Name
    backendPoolFQDNs: []
    nossl: true
  }
  dependsOn: [
    Vnet
  ]
}

module ManagedID '../../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
  name: 'managed_identity'
  params: {
    managedidentity_name: 'id-agic-${aksClusterName}'
    aks_oidc_issuer: AKSCluster.outputs.aks_oidc_issuer
    federated_id_subject: 'system:serviceaccount:${AGICNamespace}:${DeployName}-sa-ingress-azure'
  }
}

module ManagedID2 '../../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
  name: 'managed_identity2'
  params: {
    managedidentity_name: 'id-agic-${aksClusterName2}'
    aks_oidc_issuer: AKSCluster2.outputs.aks_oidc_issuer
    federated_id_subject: 'system:serviceaccount:${AGICNamespace}:${DeployName}-sa-ingress-azure'
  }
}


module NetContribRole '../../../modules/Microsoft.Authorization/net_contrib_role.bicep' = {
  name: 'net_contrib_role'
  params: {
    vnetName: VnetName
    Subnetname: subnet_Names[2]
    managedidentity_name: 'id-agic-${aksClusterName}'
    randomstring: uniqueString(guid1)
  }
  dependsOn: [
    ManagedID
  ]
}

module AGICRole '../../../modules/Microsoft.Authorization/agic_role.bicep' = {
  name: 'agic_role'
  params: {
    serviceprincipal: 'id-agic-${aksClusterName}'
    appgwname: appgwname
    randomstring: uniqueString(guid2)
    randomstring2: uniqueString(guid3)
  }
  dependsOn: [
    AppGateway
    Vnet
    NetContribRole
  ]
}

module NetContribRole2 '../../../modules/Microsoft.Authorization/net_contrib_role.bicep' = {
  name: 'net_contrib_role2'
  params: {
    vnetName: VnetName
    Subnetname: subnet_Names[2]
    managedidentity_name: 'id-agic-${aksClusterName2}'
    randomstring: uniqueString(guid4)
  }
  dependsOn: [
    ManagedID2
  ]
}

module AGICRole2 '../../../modules/Microsoft.Authorization/agic_role.bicep' = {
  name: 'agic_role2'
  params: {
    serviceprincipal: 'id-agic-${aksClusterName2}'
    appgwname: appgwname
    randomstring: uniqueString(guid5)
    randomstring2: uniqueString(guid6)
  }
  dependsOn: [
    AppGateway
    Vnet
    NetContribRole2
  ]
}
