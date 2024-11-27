param VnetName string = 'default'
param aksClusterName string = 'akscluster'
param aksClusterNodeCount int = 2
param aksClusterNodeSize string = 'Standard_D2_v2'
param aksClusterKubernetesVersion string = '1.30'
param aksdnsPrefix string = 'agcaksdns'
param linuxadmin string = 'admin'
param sshkey string
param akspodcidr string = '192.168.0.0/20'
param aksserviceCidr string = '192.168.16.0/20'
param aksinternalDNSIP string = '192.168.16.10'
param AGCname string = 'agc'
param AssociationName string = 'agcassociation'
param subnet_Names array = [
  'aks_nodes'
  'AGCSubnet'
]
param dnsServers array = []
param virtualNetwork_AddressPrefix string = '10.0.0.0/8'
param managedidnamebase string = 'aksmanagedidentity'
param currentUtcTime string = utcNow()

var agcSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, subnet_Names[1])
var utctimehash = uniqueString(currentUtcTime)
var managedident_fullname = '${utctimehash}${managedidnamebase}'
var managedidentity_name = substring(managedident_fullname, 0, 15)
var federated_id_subject = 'system:serviceaccount:azure-alb-system:alb-controller-sa'

module randomstring1 '../../../modules/Microsoft.Resources/Random_String.Bicep' = {
  name: 'randomstring1'
}

module randomstring2 '../../../modules/Microsoft.Resources/Random_String.Bicep' = {
  name: 'randomstring2'
}

module vnet_module '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: VnetName
  params: {
    virtualNetwork_Name: VnetName
    dnsServers: dnsServers
    virtualNetwork_AddressPrefix: virtualNetwork_AddressPrefix
    subnet_Names: subnet_Names
  }
}

/* module agc_module '../../../modules/Microsoft.ServiceNetworking/appgw_for_containers.bicep' = {
  name: AGCname
  params: {
    FrontendName: 'agcFrontend'
    AGCname: AGCname
    AssociationName: AssociationName
    VnetName: VnetName
    subnetNames: subnet_Names
  }
  dependsOn: [
    vnet_module
  ]
} */

module aks_module '../../../modules/Microsoft.ContainerService/aks_cluster.bicep' = {
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
    vnet_module
  ]
}

module managed_identity '../../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
  name: 'managed_identity_deployment'
  params: {
    managedidentity_name: managedidentity_name
    aks_oidc_issuer: aks_module.outputs.aks_oidc_issuer
    federated_id_subject: federated_id_subject
  }
  dependsOn: [
    aks_module
  ]
}

module authorizations '../../../modules/Microsoft.Authorization/agc_roles.bicep' = {
  name: 'agc_roles'
  params: {
    managedidentity_name: managedidentity_name
    randomstring: randomstring1.outputs.randomString
  }
  dependsOn: [
    resourceGroup()
    managed_identity
    randomstring1
  ]
}

resource Sleep 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'Sleep'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.0'
    retentionInterval: 'P1D'
    scriptContent: '''
    Start-Sleep -Seconds 60
    '''
  }
  dependsOn: [
    authorizations
  ]
}

module net_authorizations '../../../modules/Microsoft.Authorization/net_contrib_role.bicep' = {
  name: 'net_contrib_role'
  params: {
    managedidentity_name: managedidentity_name
    Subnetname: subnet_Names[1]
    vnetName: VnetName
    randomstring: randomstring2.outputs.randomString
    resourcetype: 'subnet'
  }
  dependsOn: [
    resourceGroup()
    managed_identity
    randomstring2
    authorizations
    vnet_module
    Sleep
  ]
}
