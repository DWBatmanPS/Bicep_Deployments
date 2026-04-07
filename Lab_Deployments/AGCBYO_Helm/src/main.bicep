targetScope = 'subscription'

param sshkey string = ''
param linuxadmin string
param aksClusterName string = 'akscluster'
param managedidentity_name string = 'albmanagedid'
param RGName1 string = 'AGCBYO_HELM'
var location = 'Canada Central'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: RGName1
  location: location
}

module resources './resources.bicep' = {
  name: 'resourcesDeployment'
  scope: resourceGroup
  params: {
    sshkey: sshkey
    linuxadmin: linuxadmin
    aksClusterName: aksClusterName
    managedidentity_name: managedidentity_name
    location: location
  }
}

module reader_module './readermodule.bicep' = {
  name: 'reader_module_deployment'
  scope: subscription()
  params: {
    managedidentity_name: managedidentity_name
    managedid_RG: RGName1
    nodeResourceGroup: resources.outputs.nodeResourceGroup
  }
}
