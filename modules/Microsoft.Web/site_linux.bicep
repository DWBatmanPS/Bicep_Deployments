@description('Name of the App Service Plan')
param appServicePlan_Name string

@description('''Name of the App Service.
App names only allow alphanumeric characters and hyphens, cannot start or end in a hyphen, and must be less than 60 chars.''')
param site_Name string

@description('Name of the link between App Service Enviornment and Virtual Network')
var appService_to_VirtualNetwork_Link_Name = '${site_Name}_to_${virtualNetwork_Name}'

@description('Name of the Virtual Network for both the Application Gateway and App Service Environment')
param virtualNetwork_Name string = ''

@description('Subnet ID of the Subnet that the App Service will be vnet injected into')
param appServiceSubnet_ID string = ''

param image string =  'ghcr.io/example/example:latest'

param kind string = 'app,linux'

param setenvvars bool = false
param envvarnames array = []

param envvarvalues array = []

param tagValues object = {}

var virtualNetwork_Nameexists = empty(virtualNetwork_Name) ? false : true
var location = resourceGroup().location

var envvars = [ 
  for (envvarname, index) in envvarnames: {
    name: envvarname
    value: envvarvalues[index]
  }
]

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlan_Name
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
  tags: tagValues
}


resource site_ftp_cred 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: site
  name: 'ftp'
  properties: {
    allow: true // was false and I couldn't connect to github
  }
}

resource site_scm_cred 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: site
  name: 'scm'
  properties: {
    allow: true // was false and I couldn't connect to github
  }
}

resource site_config 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: site
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'sitecontainers'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$jamesgbicepwebsite'
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetName: empty(virtualNetwork_Name) ? null : '${appService_to_VirtualNetwork_Link_Name}'
    vnetRouteAllEnabled: empty(virtualNetwork_Name) ? null : true
    vnetPrivatePortsCount: empty(virtualNetwork_Name) ? null : 0
    publicNetworkAccess: 'Enabled'
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    ipSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    elasticWebAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
  }
}

resource site_hostnameBinding 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = {
  parent: site
  name: '${site_Name}.azurewebsites.net'
  // location: location
  properties: {
    siteName: 'gbicepwebsite'
    hostNameType: 'Verified'
  }
}

resource sites_danwresponseapp_name_main 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: site
  name: 'main'
  properties: {
    image: image
    
    targetPort: '3000'
    isMain: true
    authType: 'Anonymous'
    volumeMounts: []
    environmentVariables: (setenvvars) ? envvars : null
  }
}

resource site 'Microsoft.Web/sites@2024-04-01' = {
  name: site_Name
  location: location
  kind: kind
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${site_Name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${site_Name}.scm.canadacentral-01.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlan.id
    reserved: true
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: empty(virtualNetwork_Name) ? false : true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'sitecontainers'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    ipMode: 'IPv4'
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    virtualNetworkSubnetId: empty(virtualNetwork_Name) ? null : appServiceSubnet_ID // might not need this one since
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
  tags: tagValues
}

resource appServiceEnvironment_Subnet_Link 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = if (virtualNetwork_Nameexists) {
  parent: site
  name: appService_to_VirtualNetwork_Link_Name
  properties: {
    vnetResourceId: appServiceSubnet_ID
    isSwift: true
  }
}

output website_FQDN string = site_hostnameBinding.name
