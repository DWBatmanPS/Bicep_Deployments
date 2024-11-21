param policyname string = 'azfwpolicy'
param dnsenabled bool = true
param azfwsku string = 'Standard'
param learnprivaterages string = 'Enabled'
param aksnet_rule_pri int = 100

var location = resourceGroup().location

resource azfwpolicy 'Microsoft.Network/firewallPolicies@2023-11-01' = {
  name: policyname
  location: location
  properties: {
    dnsSettings: {
      enableProxy: dnsenabled
    }
    sku: {
      tier: azfwsku
    }
    snat: {
      autoLearnPrivateRanges: learnprivaterages
    }
  }
}

resource AKS_rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = {
  name: 'AKSRules'
  parent:azfwpolicy
  properties: {
    priority: aksnet_rule_pri
    ruleCollections: [
      {
        name: 'aksfwnr'
        priority: 100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'allow'
        }
        rules: [
          {
            description: 'AZFW_Network_Rules_Allow'
            name: 'apiudp'
            ruleType: 'NetworkRule'
            destinationAddresses: [
              'AzureCloud.${location}'
            ]
            destinationPorts: [
              '1194'
            ]
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
          }
          {
            description: 'AZFW_Network_Rules_Allow'
            name: 'apitcp'
            ruleType: 'NetworkRule'
            destinationAddresses: [
              'AzureCloud.${location}'
            ]
            destinationPorts: [
              '9000'
            ]
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
          }
          {
            description: 'AZFW_Network_Rules_Allow'
            name: 'time'
            ruleType: 'NetworkRule'
            destinationFqdns: [
              'ntp.ubuntu.com'
            ]
            destinationPorts: [
              '123'
            ]
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
          }
          {
            description: 'AZFW_Network_Rules_Allow'
            name: 'ghcr'
            ruleType: 'NetworkRule'
            destinationFqdns: [
              'ghcr.io'
              'pkg-containers.githubusercontent.com'
            ]
            destinationPorts: [
              '443'
            ]
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
          }
          {
            description: 'AZFW_Network_Rules_Allow'
            name: 'docker'
            ruleType: 'NetworkRule'
            destinationFqdns: [
              'docker.io'
              'registry-1.docker.io'
              'production.cloudflare.docker.com'
            ]
            destinationPorts: [
              '443'
            ]
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
          }
        ]
      }
      {
        name: 'aksfwar'
        priority: 105
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            description: 'AKS_ApplicationRules_Allow'
            name: 'fqdn'
            ruleType: 'ApplicationRule'
            fqdnTags: [
              'AzureKubernetesService'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'http'
              }
              {
                port: 443
                protocolType: 'https'
              }
            ]
            sourceAddresses: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

output firewallpolicyid string = azfwpolicy.id
