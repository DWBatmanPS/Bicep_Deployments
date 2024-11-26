param managedidentity_name string
param agcSubnetname string
param vnetName string
param managedidentity_principalid string

var agcSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, agcSubnetname)
var agc_role = 'fbc52c3f-28ad-4303-a892-8a056630b8f1'
var netcontrib_role = '4d97b98b-1d4f-4787-a291-c67834d212e7'

resource agc_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: agc_role
}

resource netcontrib_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: netcontrib_role
}

resource agcconfig_mgr 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedidentity_name, agc_role)
  properties: {
    principalId:  managedidentity_principalid
    roleDefinitionId: agc_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}

resource agcSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  scope: resourceGroup()
  name: agcSubnetId
}

resource agc_subnet_networkcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedidentity_name, netcontrib_role)
  scope: agcSubnet
  properties: {
    principalId:  managedidentity_principalid
    roleDefinitionId: netcontrib_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}
 
