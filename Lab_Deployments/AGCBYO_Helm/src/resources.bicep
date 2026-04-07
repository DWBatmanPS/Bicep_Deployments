param sshkey string = ''
param linuxadmin string
param aksClusterName string
param managedidentity_name string
param location string

var agc_role = 'fbc52c3f-28ad-4303-a892-8a056630b8f1'
var netcontrib_role = '4d97b98b-1d4f-4787-a291-c67834d212e7'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-cpq-network-prd-we-1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.112.74.0/25'
        '10.113.118.0/23'
        '10.113.222.0/23'
        '10.114.174.0/23'
      ]
    }
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.113.119.0/24'
        }
      }
      {
        name: 'appgw-subnet-nonprod'
        properties: {
          addressPrefix: '10.113.223.0/24'
          delegations: [
            {
              name: 'Microsoft.ServiceNetworking/trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource k8s 'Microsoft.ContainerService/managedClusters@2024-06-02-preview' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'green'
    kubernetesVersion: '1.34.3'
    agentPoolProfiles: [
      {
        name: 'npgreenwe1'
        count: 2
        vmSize: 'Standard_E4as_v4'
        vnetSubnetID: virtualNetwork.properties.subnets[0].id
        osType: 'Linux'
        mode: 'System'
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
      networkPolicy: 'cilium'
      networkPluginMode: 'overlay'
      outboundType: 'loadBalancer'
      podCidr: '192.168.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
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

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'dwAKSKeyVault'
  location: resourceGroup().location
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 60
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource applicationGatewayForContainers 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: 'testagc'
  location: location
}

resource agc_frontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01' = {
  parent: applicationGatewayForContainers
  location: location
  name: 'testagcfrontend'
  properties: {}
}

resource agc_subnet_association 'Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01' = {
  parent: applicationGatewayForContainers
  location: location
  name: 'agcassociation'
  properties: {
    associationType: 'subnets'
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
  }
}

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedidentity_name
  location: location
}

resource ManagedIdFederation 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: '${managedidentity_name}-federation'
  parent: ManagedID
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: k8s.properties.oidcIssuerProfile.issuerURL
    subject: 'system:serviceaccount:azure-alb-system:alb-controller-sa'
  }
}

resource agc_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: agc_role
}

resource agcconfig_mgr 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedidentity_name, 'agc_role')
  properties: {
    principalId: ManagedID.properties.principalId
    roleDefinitionId: agc_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}

resource netcontrib_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: netcontrib_role
}

resource subnet_networkcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedidentity_name, 'net_module')
  scope: virtualNetwork
  properties: {
    principalId: ManagedID.properties.principalId
    roleDefinitionId: netcontrib_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}

output nodeResourceGroup string = k8s.properties.nodeResourceGroup
