param serviceprincipal_client_Id string

param appgwname string
param vnetName string



var VnetId = resourceId('Microsoft.Network/virtualNetworks', vnetName)
var reader_role = 'fbc52c3f-28ad-4303-a892-8a056630b8f1'
var netcontrib_role = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var contrib_roleid = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var appgwID = resourceId('Microsoft.Network/applicationGateways', appgwname)

resource reader_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: reader_role
}

resource netcontrib_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: netcontrib_role
}

resource contrib_role 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: contrib_roleid
}


resource appgwcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceprincipal_client_Id, contrib_roleid)
  properties: {
    condition: appgwID
    conditionVersion: '2.0'
    principalId:  serviceprincipal_client_Id
    roleDefinitionId: contrib_role.id
    principalType: 'ServicePrincipal'
  }
}

resource agic_networkcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceprincipal_client_Id, netcontrib_role)
  properties: {
    condition: VnetId
    conditionVersion: '2.0'
    principalId:  serviceprincipal_client_Id
    roleDefinitionId: netcontrib_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}

resource agic_reader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceprincipal_client_Id, reader_role)
  properties: {
    condition: resourceGroup().id
    conditionVersion: '2.0'
    principalId:  serviceprincipal_client_Id
    roleDefinitionId: reader_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}
