@allowed([ 'OnSuccess', 'OnExpiration', 'Always' ])
@description('When the script resource is cleaned up')
param cleanupPreference string = 'OnSuccess'

resource RandomString 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'GenerateRandomString'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.0'
    retentionInterval: 'P1D'
    scriptContent: '''
    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    $length = 10
    $randomString = -join ((1..$length) | ForEach-Object { $characters[(Get-Random -Maximum $characters.Length)] })
  
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['RandString'] = $randomString
    '''
    cleanupPreference: cleanupPreference
  }
}

output randomString string = RandomString.properties.outputs.RandString
