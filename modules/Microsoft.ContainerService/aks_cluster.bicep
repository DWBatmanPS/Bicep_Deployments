param aksClusterName string
param aksClusterNodeCount int
param aksClusterNodeSize string
param aksClusterKubernetesVersion string

param VnetName string
param aksClusterSubnetname string
param aksdnsPrefix string
param sshkey string
param akspodCidr string
param aksserviceCidr string
param aksinternalDNSIP string
param linuxadmin string = 'AKSAdmin'

var aksClusterLocation = resourceGroup().location
var aksClusterSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, aksClusterSubnetname)
var aksagentpoolname = '${aksClusterName}-agentpool'

resource k8s 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: aksClusterName
  location: aksClusterLocation
  identity: {
    type: 'SystemAssigned'}
  properties: {
    dnsPrefix: aksdnsPrefix
    kubernetesVersion: aksClusterKubernetesVersion
    agentPoolProfiles: [
      {
        name: aksagentpoolname
        count: aksClusterNodeCount
        vmSize: aksClusterNodeSize
        vnetSubnetID: aksClusterSubnetId
        osType: 'Linux'
        mode:'System'
      }
    ]
    linuxProfile: {
      adminUsername: linuxadmin
      ssh: {
        publicKeys: [
          {
            keyData: sshkey
          }
        ]
      }
    }
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      outboundType: 'loadBalancer'
      podCidr: akspodCidr
      serviceCidr: aksserviceCidr
      dnsServiceIP: aksinternalDNSIP
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}



output controlPlaneFQDN string = k8s.properties.fqdn
output aks_oidc_issuer string = k8s.properties.identityProfile.kubeletidentity.objectId
output aks_cluster_id string = k8s.id
