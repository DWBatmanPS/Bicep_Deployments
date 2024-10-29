using './main.bicep' /*Provide a path to a bicep template*/

param applicationGatewayWAF_Name = 'Appgw_waf_Policy'
param wafState = 'Enabled'
param wafMode = 'Detection'
param fileupload = 128
param maxRequest = 128
param bodyInspectsize = 128
param inspectBody = true
param enforceFileLimit = true
@allowed([
  '2.1'
  '3.2'
  '3.1'
  '3.0'
])
param ruleSet = '3.2'
param botManager = true
param ruleNames = [
  'hyphen-rule'
  'nohyphenrule'
]
param matchVariables = [
  'string1'
  'string2'
]
param tagValues = {}
