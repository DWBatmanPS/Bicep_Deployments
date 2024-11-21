param applicationGatewayWAF_Name string = 'Appgw_waf_Policy'
param wafState string = 'Enabled'
param wafMode string = 'Detection'
param fileupload int = 128
param maxRequest int = 128
param bodyInspectsize int = 128
param inspectBody bool = true
param enforceFileLimit bool = true
@allowed([
  '2.1'
  '3.2'
  '3.1'
  '3.0'
])
param ruleSet string = '3.2'
param botManager bool = true
param ruleNames array = []
param matchVariables array = []
param tagValues object = {}


var location = resourceGroup().location
var rulesettype = ruleSet == '2.1' ? 'DRS' : 'OWASP'
var botManagedRuleSet = (botManager) ? {
  ruleSetType: 'Microsoft_BotManagerRuleSet'
  ruleSetVersion: '0.1'
  ruleGroupOverrides: []
} : null
var ruleSets = concat([
  {
    ruleSetType: rulesettype
    ruleSetVersion: ruleSet
    ruleGroupOverrides: []
  }
], botManagedRuleSet != null ? [botManagedRuleSet] : [])
resource applicationGatewayWAF 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-11-01' = {
  name: applicationGatewayWAF_Name
  location: location
  properties: {
    customRules: [
      for (ruleName, i) in ruleNames: {
      name: ruleName
      priority: i + 10
      ruleType: 'MatchRule'
      matchConditions: [
        {
          matchVariables: [
            {
              variableName: 'RequestHeaders'
              selector: matchVariables[i]
            }
          ]
          operator: 'Contains'
          matchValues: [
            'BadBot'
          ]
          negationConditon: false
          transforms: [
            'Lowercase'
          ]
        }
      ]
      action: 'Block'
    }]
    policySettings: {
      requestBodyCheck: inspectBody
      maxRequestBodySizeInKb: maxRequest
      fileUploadLimitInMb: fileupload
      state: wafState
      mode: wafMode
      requestBodyInspectLimitInKB: bodyInspectsize
      fileUploadEnforcement: enforceFileLimit
      requestBodyEnforcement: true
    }
    managedRules: {
      managedRuleSets: ruleSets
      exclusions: []
    }
  }
  tags: tagValues
}
