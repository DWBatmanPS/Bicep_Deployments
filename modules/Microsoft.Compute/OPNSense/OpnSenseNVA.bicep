param NVAName string = 'OPNSenseNVA'
param VMSize string = 'B2ms'
param untrustnic_objectid string
param trustnic_objectid string
param mgmtnic_objectid string
param virtualMachine_AdminUsername string
@secure()
param virtualMachine_AdminPassword string
param OPNScriptURI string
param ShellScriptName string
param ShellScriptObj object = {}
param windowsvmsubnet object = {}

resource trustedSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = if (!empty(ShellScriptObj.TrustedSubnetName)){
  name: ShellScriptObj.TrustedSubnetName
}

resource OPNsense 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: NVAName
  location: resourceGroup().location
  properties: {
    osProfile: {
      computerName: NVAName
      adminUsername: virtualMachine_AdminUsername
      adminPassword: virtualMachine_AdminPassword
      linuxConfiguration: {
      disablePasswordAuthentication: false
      provisionVMAgent: true
      patchSettings: {
        patchMode: 'ImageDefault'
        assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    hardwareProfile: {
      vmSize: VMSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: 'thefreebsdfoundation'
        offer: 'freebsd-14_1'
        sku: '14_1-release-amd64-gen2-zfs'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: trustnic_objectid
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
        {
          id: untrustnic_objectid
          properties: {
            deleteOption: 'Delete'
            primary: false
          }
        }
        {
          id: mgmtnic_objectid
          properties: {
            deleteOption: 'Delete'
            primary: false
          }
        }
      ]
    }
  }
  plan: {
    name: '14_1-release-amd64-gen2-zfs'
    publisher: 'thefreebsdfoundation'
    product: 'freebsd-14_1'
  }
}

resource vmext 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: OPNsense
  name: 'CustomScript'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: false
    settings:{
      fileUris: [
        '${OPNScriptURI}${ShellScriptName}'
      ]
      commandToExecute: 'sh ${ShellScriptName} ${ShellScriptObj.OpnScriptURI} ${ShellScriptObj.OpnVersion} ${ShellScriptObj.WALinuxVersion} ${ShellScriptObj.OpnType} ${!empty(ShellScriptObj.TrustedSubnetName) ? contains(trustedSubnet.properties, 'addressPrefixes') ? trustedSubnet.properties.addressPrefixes[0] : trustedSubnet.properties.addressPrefix : ''} ${!empty(ShellScriptObj.WindowsSubnetName) ? contains(windowsvmsubnet.properties, 'addressPrefixes') ? windowsvmsubnet.properties.addressPrefixes[0] : windowsvmsubnet.properties.addressPrefix : '1.1.1.1/32'} ${ShellScriptObj.publicIPAddress} ${ShellScriptObj.opnSenseSecondarytrustedNicIP}'
    }
  }
}
