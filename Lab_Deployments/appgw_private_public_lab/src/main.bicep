param certname string  

param keyvault_managed_ID string 

param dnsServers array = []

param subnet_Names array = [
  'AGSubnet_noNSG'
  'VMSubnet'
]

param virtualNetworkPrefix string = '10.0.0.0/16'

param virtualNetworkName string = 'webappappgw_vnet'
param publicIPAddressName string = 'webappappgw_vip'
param applicationGateWayName string = 'dwwebapp-appgw'
param VMName string = 'WinServ2022'
param VMSize string = 'Standard_D2s_v3'
param VMAdminUsername string
@secure()
param VMAdminPassword string
param VMNICName string = 'VMNIC'
param VMSubnetName string = 'VMSubnet'
param vmscriptlocation string = 'https://raw.githubusercontent.com/Azure-Samples/windowsvm-custom-script-extension/master/vmextension/ConfigureRemotingForAnsible.ps1'
param vmscriptfilename string = 'ConfigureRemotingForAnsible.ps1'
param keyVaultName string = ''

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    dnsServers: dnsServers
    subnet_Names: subnet_Names
  }
}

module appgw '../../../modules/Microsoft.Network/ApplicationGateway_v2.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet_noNSG')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: certname
    isWAF: false
    isE2ESSL: false
    backendPoolFQDNs: []
    backendpoolIPAddresses: [
      '10.0.0.5'
    ]
    useBothPrivateAndPublicFrontend: true
    privatefrontendIP: '10.0.0.254'
    tagValues: {}
  }
}

module VM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM'
  params: {
    acceleratedNetworking: false
    virtualMachine_Name: VMName
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name: VMNICName
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File ${vmscriptfilename}'
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

