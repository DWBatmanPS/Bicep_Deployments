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


module wafPolicy '../../../modules/Microsoft.Network/appgw_Waf_policy.bicep' = {
  name: 'wafPolicy'
  params: {
    applicationGatewayWAF_Name:applicationGatewayWAF_Name
    wafState:wafState
    wafMode: wafMode
    fileupload: fileupload
    maxRequest: maxRequest
    bodyInspectsize: bodyInspectsize
    inspectBody: inspectBody
    enforceFileLimit: enforceFileLimit
    ruleSet: ruleSet
    botManager: botManager
    ruleNames: ruleNames
    matchVariables: matchVariables
  }
}
