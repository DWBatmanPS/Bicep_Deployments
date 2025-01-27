

@description('Name of the Application Gateway')
param applicationGateway_Name string

@description('Name of the Public IP Address resource of the Applciation Gateway')
param publicIP_ApplicationGateway_Name string = '${applicationGateway_Name}_PIP'

param applicationGateway_SubnetID string

@description('FQDN of the website in the backend pool of the Application Gateway')
param backendPoolFQDNs array

param certname string

param keyvault_managed_ID string


param keyVaultName string
var keyVaultDnsSuffix = environment().suffixes.keyvaultDns
var keyVaultUrl = 'https://${keyVaultName}${keyVaultDnsSuffix}'
param isWAF bool = false

param isE2ESSL bool = false

param nossl bool = false

param tagValues object = {}

@description('Application Gateway sub resource IDs')
var frontendID = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateway_Name, 'fip_pub')
var frontendPortID = (nossl) ? resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateway_Name, 'port_80') : resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateway_Name, 'port_443')
var httpListenerID = (nossl) ? resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateway_Name, 'http_listener') : resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateway_Name, 'https_listener')
var backendAddressPoolID = resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateway_Name, 'backend_pool')
var backendHTTPSettingsID = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateway_Name, 'http-settings')
var backendHTTPSSettingsID = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateway_Name, 'https-settings')
var location = resourceGroup().location

resource publicIP_ApplicationGateway 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: publicIP_ApplicationGateway_Name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
  tags: tagValues
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2022-11-01' = {
  name: applicationGateway_Name
  location: location
  identity: (nossl) ? null :{
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Domain_resources_RG_2','Microsoft.ManagedIdentity/userAssignedIdentities/',keyvault_managed_ID)}': {}
    }
  }
  properties: {
    sku: (isWAF) ?{
      name: 'WAF_v2'
      tier: 'WAF_v2'
    } : {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: applicationGateway_SubnetID
          }
        }
      }
    ]
    sslCertificates: (nossl) ? null : [
      {
        name: certname
        properties: {
          keyVaultSecretId: '${keyVaultUrl}/secrets/${certname}'
        }
      }
    ]
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'fip_pub'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP_ApplicationGateway.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backend_pool'
        properties: {
          backendAddresses: [ for backendPoolFQDN in backendPoolFQDNs: {
              fqdn: backendPoolFQDN
            }
          ]
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'http-settings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
      {
        name: 'https-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: (nossl) ? 'http_listener' : 'https_listener'
        properties: {
          frontendIPConfiguration: {
            id: frontendID
          }
          frontendPort: {
            id: frontendPortID
          }
          protocol: (nossl) ? 'Http' : 'Https'
          hostNames: []
          requireServerNameIndication: false
          sslCertificate: (nossl) ? null :{ 
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGateway_Name, certname)
          }
        }
      }
    ]
    listeners: []
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: (nossl) ? 'httproutingrule' : 'httpsroutingrule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: httpListenerID
          }
          backendAddressPool: {
            id: backendAddressPoolID
          }
          backendHttpSettings: (isE2ESSL) ? {
            id: backendHTTPSSettingsID
          } :{
            id: backendHTTPSettingsID
          }
        }
      }
    ]
    routingRules: []
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
    webApplicationFirewallConfiguration: (isWAF) ?{
      enabled: true
      firewallMode: 'Detection'
      requestBodyCheck: true
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    } : null
  }
  tags: tagValues
}
