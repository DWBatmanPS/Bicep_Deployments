using './main.bicep' /*Provide a path to a bicep template*/

param applicationGateWayName = 'rewriteappgw'
param publicIPAddressName = 'rewriteappgw-vip'
param virtualNetworkName = 'rewriteappgw_vnet'
param virtualNetworkPrefix  = '192.168.0.0/16'
param subnet_Names = [
  'AGSubnet'
  'VMSubnet'
]
param keyvault_managed_ID  = 'DWKeyVaultManagedIdentity'
param certname = 'danwheeler-rocks-wildcard'
param VMName = 'WinServ2022'
param VMSize = 'Standard_D2s_v3'
param VMAdminUsername = 'danwheeler'
param VMAdminPassword = 'Password123456!'
param VMNICName = 'VMNIC'
param VMSubnetName = 'VMSubnet'
