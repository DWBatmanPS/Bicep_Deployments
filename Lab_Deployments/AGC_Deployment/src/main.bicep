param VnetName string = 'default'
param aksClusterName string = 'akscluster'
param aksClusterNodeCount int = 2
param aksClusterNodeSize string = 'Standard_D2_v2'
param aksClusterKubernetesVersion string = '1.29'
param aksdnsPrefix string = 'danagcaksdns'
param linuxadmin string = 'danadmin'
param sshkey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDSKkXzsOth/cxH5mCb/xbJY00viNN3X2GOQ7bx6lgqyLZsYaIXWfUdj37E9cN5ZFP/UOev6wuKqRscqixHh4NJ7HMRTmbx53Pu13p+iXHoSN5rULK5+y5LREUnfiqSgGBY3UhYVtBYtMKRjPFIL+8mVxze5cpH64Vt4HwL13EXd7fQtEBiaNtB6lc43mIGV/UX69qPHzPKr/GSct2S0yLQMG7sv3NizKsDajxG7E94Qn77K/euFzDT/piEN3U+4qvshMe92m07puRfIooF4xXQpA0ScDIQruKGjmomkpNwehyZbGCjUhUXWmt6sNy/04/hSp1eQEsqzMA1et3JzcvazMogtAvjRpDwAhMETesFx7GL7fN21P1fyTDIiL3W43qX9VibndrE7/Ugkyq/M2QhNvYJgSojuBElDU2uJtRhqfrFrpcy8+mBB9TD4PmKvonVvunfkQX5vr9tcctWkfKsyGSvLtUQ4bQXH3wCJJjJ579hDWS1PBuNJWEZ51GnmPZWL4QOaWZyPi+uThYhiWBCAQ7j8Iq1kTEJyHpjHGlGfXamu0EUR8Q0cIWM8TUWyILBKbdsKQ/MtP6FVJsso4BCWCrCCQEGQAnSZ9fhBw87v8zkBzW0iRblgGP+fhDFQLdqMtBMLHMwbZbXA/GbHx35K951mA1xQ4R39zFMQ+9ZoQ== danwheeler@LAPTOP-3DALUHP4'
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


var managedidentity_name = 'aksmanagedidentity'
var federated_id_subject = 'system:serviceaccount:azure-alb-system:alb-controller-sa'

module vnet_module '../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: VnetName
  params: {
    virtualNetwork_Name: VnetName
    dnsServers: dnsServers
    virtualNetwork_AddressPrefix: virtualNetwork_AddressPrefix
    subnet_Names: subnet_Names
  }
}

module agc_module '../../modules/Microsoft.ServiceNetworking/appgw_for_containers.bicep' = {
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
}

module aks_module '../../modules/Microsoft.ContainerService/aks_cluster.bicep' = {
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

module managed_identity '../../modules/Microsoft.ManagedIdentity/managed_ID_and_federation.bicep' = {
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

module authorizations '../../modules/Microsoft.Authorization/agc_roles.bicep' = {
  name: 'agc_roles'
  params: {
    managedidentity_name: managedidentity_name
    agcSubnetname: subnet_Names[1]
    vnetName: VnetName
    managedidentity_principalid: managed_identity.outputs.PrincipalID
  }
  dependsOn: [
    vnet_module
    agc_module
  ]
}

output oidc_issuer string = aks_module.outputs.aks_oidc_issuer
