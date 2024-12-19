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
param AGICNamespace string = 'default'
param DeployName string = 'agic-controller'
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

module ManagedID '../../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
  name: 'managed_identity'
  params: {
    managedidentity_name: 'id-agic-${aksClusterName}'
    aks_oidc_issuer: AKSCluster.outputs.aks_oidc_issuer
    federated_id_subject: 'system:serviceaccount:${AGICNamespace}:${DeployName}-sa-ingress-azure'
  }
}

module RandomString '../../../modules/Microsoft.Resources/Random_String.Bicep' = {
  name: 'GenerateRandomString'
  params: {
  }
}

module RandomString2 '../../../modules/Microsoft.Resources/Random_String.Bicep' = {
  name: 'GenerateRandomString2'
  params: {}
  dependsOn: [
    RandomString
  ]
}

module RandomString3 '../../../modules/Microsoft.Resources/Random_String.Bicep' = {
  name: 'GenerateRandomString3'
  params: {}
  dependsOn: [
    RandomString2
  ]
}

module NetContribRole '../../../modules/Microsoft.Authorization/net_contrib_role.bicep' = {
  name: 'net_contrib_role'
  params: {
    vnetName: VnetName
    Subnetname: subnet_Names[1]
    managedidentity_name: 'id-agic-${aksClusterName}'
    randomstring: RandomString3.outputs.randomString
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
    randomstring: RandomString.outputs.randomString
    randomstring2: RandomString2.outputs.randomString
  }
  dependsOn: [
    AppGateway
    Vnet
    NetContribRole
  ]
}

/* resource Sleep 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'Sleep'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.0'
    retentionInterval: 'P1D'
    scriptContent: '''
    Start-Sleep -Seconds 120
    '''
  }
  dependsOn: [
    AGICRole
    AKSCluster
    AppGateway
    Vnet
    ManagedID
  ]
} */

module AGIC_Helm_Install '../../../modules/Microsoft.Resources/AGIC_Helm_Deployment.Bicep' = {
  name: 'agic_helm_install'
  params: {
    aksName: AKSCluster.outputs.aks_cluster_name
    helmRepo: ''
    helmRepoURL: ''
    helmApp: 'ingress-azure'
    helmAppName: 'agic'
    helmAppParams: ''
    helmAppValues: ''
    AGICIDName: ManagedID.outputs.ManagedID_Name
    AGICNamespace: AGICNamespace
    AppGatewayID: appgwname
    ClientID: ManagedID.outputs.clientID
    DeployName: DeployName
  }
  dependsOn: [
    AppGateway
    Vnet
    AGICRole
    NetContribRole
  ]
}
