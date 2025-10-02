param aksClusterName1 string = 'aks1'
param aksClusterName2 string = 'aks2'
param aksClusterNodeCount int = 3
param aksClusterNodeSize string = 'Standard_D2s_v3'
param aksClusterKubernetesVersion string = '1.31'
param aksdnsPrefix1 string 
param aksdnsPrefix2 string 
param linuxadmin string
param sshkey string = ''
param VnetName string 
param virtualNetwork_AddressPrefix string = '10.0.0.0/16'
param subnet_Names array = [
  'AKSSubnet'
  'AppGatewaySubnet'
]
param akspodcidr1 string = '10.244.0.0/16'
param aksserviceCidr1 string = '192.168.16.0/20'
param aksinternalDNSIP1 string = '192.168.16.10'
param akspodcidr2 string = '10.244.0.0/16'
param aksserviceCidr2 string = '192.168.16.0/20'
param aksinternalDNSIP2 string = '192.168.16.10'
param appgwname string = 'agic-appgw'
param publicIP_ApplicationGateway_Name string = 'agic-appgwip'
param AGICNamespace string = 'default'
param DeployName1 string = 'agic-controller'
param DeployName2 string = 'agic-controller'
param shared string = 'true'
param AGICVersion string = '1.9.1'
param guid1 string = newGuid()
param guid2 string = newGuid()
param guid3 string = newGuid()
param guid4 string = newGuid()
param guid5 string = newGuid()
param guid6 string = newGuid()
//param serviceprincipal_client_Id string


module AKSCluster1 '../../../modules/Microsoft.ContainerService/aks_cluster.bicep' = {
  name: 'aks_deployment1'
  params: {
    aksClusterName: aksClusterName1
    aksClusterNodeCount: aksClusterNodeCount
    aksClusterNodeSize: aksClusterNodeSize
    aksClusterKubernetesVersion: aksClusterKubernetesVersion
    VnetName: VnetName
    aksdnsPrefix: aksdnsPrefix1
    linuxadmin: linuxadmin
    sshkey: sshkey
    akspodCidr: akspodcidr1
    aksserviceCidr: aksserviceCidr1
    aksinternalDNSIP: aksinternalDNSIP1
    aksClusterSubnetname: subnet_Names[0]
  }
  dependsOn: [
    Vnet
  ]
}

module AKSCluster2 '../../../modules/Microsoft.ContainerService/aks_cluster.bicep' = {
  name: 'aks_deployment2'
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
    aksClusterSubnetname: subnet_Names[0]
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
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, subnet_Names[1])
    applicationGateway_Name: appgwname
    publicIP_ApplicationGateway_Name: publicIP_ApplicationGateway_Name
    backendPoolFQDNs: []
    nossl: true
  }
  dependsOn: [
    Vnet
  ]
}

module ManagedID1 '../../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
  name: 'managed_identity1'
  params: {
    managedidentity_name: 'id-agic-${aksClusterName1}'
    aks_oidc_issuer: AKSCluster1.outputs.aks_oidc_issuer
    federated_id_subject: 'system:serviceaccount:${AGICNamespace}:${DeployName1}-sa-ingress-azure'
  }
}

module ManagedID2 '../../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
  name: 'managed_identity2'
  params: {
    managedidentity_name: 'id-agic-${aksClusterName2}'
    aks_oidc_issuer: AKSCluster2.outputs.aks_oidc_issuer
    federated_id_subject: 'system:serviceaccount:${AGICNamespace}:${DeployName2}-sa-ingress-azure'
  }
}

module NetContribRole1 '../../../modules/Microsoft.Authorization/net_contrib_role.bicep' = {
  name: 'net_contrib_role1'
  params: {
    vnetName: VnetName
    Subnetname: subnet_Names[1]
    managedidentity_name: 'id-agic-${aksClusterName1}'
    randomstring: uniqueString(guid1)
  }
  dependsOn: [
    ManagedID1
  ]
}

module AGICRole1 '../../../modules/Microsoft.Authorization/agic_role.bicep' = {
  name: 'agic_role1'
  params: {
    serviceprincipal: 'id-agic-${aksClusterName1}'
    appgwname: appgwname
    randomstring: uniqueString(guid2)
    randomstring2: uniqueString(guid3)
  }
  dependsOn: [
    AppGateway
    Vnet
    NetContribRole1
  ]
}


module NetContribRole2 '../../../modules/Microsoft.Authorization/net_contrib_role.bicep' = {
  name: 'net_contrib_role2'
  params: {
    vnetName: VnetName
    Subnetname: subnet_Names[1]
    managedidentity_name: 'id-agic-${aksClusterName2}'
    randomstring: uniqueString(guid4)
  }
  dependsOn: [
    ManagedID2
  ]
}

module AGICRole2 '../../../modules/Microsoft.Authorization/agic_role.bicep' = {
  name: 'agic_role'
  params: {
    serviceprincipal: 'id-agic-${aksClusterName1}'
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

module AGIC_Helm_Install1 '../../../modules/Microsoft.Resources/AGIC_Helm_Deployment.Bicep' = {
  name: 'agic_helm_install1'
  params: {
    aksName: AKSCluster1.outputs.aks_cluster_name
    helmRepo: ''
    helmRepoURL: ''
    helmApp: 'ingress-azure'
    helmAppName: 'agic1'
    helmAppParams: ''
    helmAppValues: ''
    AGICIDName: ManagedID1.outputs.ManagedID_Name
    AGICNamespace: AGICNamespace
    AppGatewayID: appgwname
    ClientID: ManagedID1.outputs.clientID
    DeployName: DeployName1
    subResourceNamePrefix: 'clst1-'
    shared: shared
    AGICVersion: AGICVersion
  }
  dependsOn: [
    AppGateway
    Vnet
    AGICRole1
    NetContribRole1
  ]
}

module AGIC_Helm_Install2 '../../../modules/Microsoft.Resources/AGIC_Helm_Deployment.Bicep' = {
  name: 'agic_helm_install2'
  params: {
    aksName: AKSCluster2.outputs.aks_cluster_name
    helmRepo: ''
    helmRepoURL: ''
    helmApp: 'ingress-azure'
    helmAppName: 'agic2'
    helmAppParams: ''
    helmAppValues: ''
    AGICIDName: ManagedID2.outputs.ManagedID_Name
    AGICNamespace: AGICNamespace
    AppGatewayID: appgwname
    ClientID: ManagedID2.outputs.clientID
    DeployName: DeployName2
    subResourceNamePrefix: 'clst2-'
    shared: shared
    AGICVersion: AGICVersion
  }
  dependsOn: [
    AppGateway
    Vnet
    AGICRole2
    NetContribRole2
  ]
}
