

@description('Name of the Application Gateway')
param applicationGateway_Name string

@description('Name of the Public IP Address resource of the Applciation Gateway')
param publicIP_ApplicationGateway_Name string = '${applicationGateway_Name}_PIP'

param applicationGateway_SubnetID string

@description('Name of the Web Application Firewall of the Application Gateway')
param applicationGatewayWAF_Name string = '${applicationGateway_Name}_WAF'

@description('FQDN of the website in the backend pool of the Application Gateway')
param backendPoolFQDNs array = []

param certname string = 'danwheeler-rocks-wildcard' 

param keyvault_managed_ID string = 'DWKeyVaultManagedIdentity'


param keyVaultName string = 'DanWheelerVaultStr'
var keyVaultDnsSuffix = environment().suffixes.keyvaultDns
var keyVaultUrl = 'https://${keyVaultName}${keyVaultDnsSuffix}'
param isWAF bool = false

param isE2ESSL bool = false
param backendpoolIPAddresses array = []
param nossl bool = false
param pathmap bool = false
param path string = '/path'
param backendpoolpathIPAddresses array = []
param useCustomProbe bool = false

param tagValues object = {}

@description('Application Gateway sub resource IDs')
var frontendID = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateway_Name, 'fip_pub')
var frontendPortID = (nossl) ? resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateway_Name, 'port_80') : resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateway_Name, 'port_443')
var httpListenerID = (nossl) ? resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateway_Name, 'http_listener') : resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateway_Name, 'https_listener')
var backendAddressPoolID = resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateway_Name, 'backend_pool')
var backendHTTPSettingsID = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateway_Name, 'http-settings')
var backendHTTPSSettingsID = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateway_Name, 'https-settings')
var location = resourceGroup().location
var backendAddressesFromIP = [
  for backendpoolIPAddress in backendpoolIPAddresses: {
    ipAddress: backendpoolIPAddress
  }
]

var backendAddressesFromFQDN = [
  for backendPoolFQDN in backendPoolFQDNs: {
    fqdn: backendPoolFQDN
  }
]

var backendAddresses = (backendPoolFQDNs == []) ? backendAddressesFromIP : backendAddressesFromFQDN

var pathbackendaddresses = [
  for backendpoolpathIPAddress in backendpoolpathIPAddresses: {
    ipAddress: backendpoolpathIPAddress
  }
]

resource applicationGatewayWAF 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-11-01' = if (isWAF) {
  name: applicationGatewayWAF_Name
  location: location
  properties: {
    customRules: []
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Detection'
      requestBodyInspectLimitInKB: 128
      fileUploadEnforcement: true
      requestBodyEnforcement: true
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '0.1'
          ruleGroupOverrides: []
        }
      ]
      exclusions: []
    }
  }
  tags: tagValues
}


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
        name: 'danwheelerrockswildcard'
        properties: {
          keyVaultSecretId: '${keyVaultUrl}/secrets/${certname}'
        }
      }
    ]
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101'
    }
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
    backendAddressPools: (pathmap) ? [
      {
        name: 'backend_pool'
        properties: {
          backendAddresses: backendAddresses
        }
      }
      {
        name: 'backend_pool_path'
        properties: {
          backendAddresses: pathbackendaddresses
        }
      }
    ] : [      {
      name: 'backend_pool'
      properties: {
        backendAddresses: backendAddresses
      }
    }]
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
          probe: (useCustomProbe) ? {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGateway_Name, 'custom-probe')
          } : null
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
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGateway_Name, 'danwheelerrockswildcard')
          }
        }
      }
    ]
    listeners: []
    urlPathMaps: (pathmap) ? [
      {
        name: 'urlPathMap'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateway_Name, 'backend_pool')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateway_Name, 'http-settings')
          }
          defaultRedirectConfiguration: null
          pathRules: [
            {
              name: 'pathRule'
              properties: {
                paths: [
                  path
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateway_Name, 'backend_pool_path')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateway_Name, 'http-settings')
                }
                redirectConfiguration: null
              }
            }
          ]
        }
      }
    ]:null
    requestRoutingRules: (pathmap) ? [
      {
        name: (nossl) ? 'httproutingrule' : 'httpsroutingrule'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 100
          httpListener: {
            id: httpListenerID
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', applicationGateway_Name, 'urlPathMap')
          }
        }
      }
    ] : [
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
    probes: (useCustomProbe) ? [
      {
        name: 'custom-probe'
        properties: {
          pickHostNameFromBackendHttpSettings: true
          interval: 20
          match: {
            statusCodes: [
              '200'
              '302'
            ]
          }
          path: '/'
          port: (isE2ESSL) ? 443 : 80
          protocol: (isE2ESSL) ? 'Https' : 'Http'
          timeout: 30
          unhealthyThreshold: 2
        }
      }
    ] : []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
    firewallPolicy: (isWAF) ?{
      id: applicationGatewayWAF.id
    } : null
  }
  tags: tagValues
}
