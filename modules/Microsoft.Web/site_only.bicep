param appName string

param appServicePlan string

var location = resourceGroup().location

resource app 'Microsoft.Web/sites@2021-01-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan
    httpsOnly: true
    siteConfig: {
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      ipSecurityRestrictions: [
        {
          ipAddress: 'Any'
          action: 'Allow'
          priority: 100
          name: 'Allow traffic from All'
        }
      ]
    } 
  }
}
