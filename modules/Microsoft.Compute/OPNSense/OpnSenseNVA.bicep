param NVAName string = 'OPNSenseNVA'
param VMSize string = 'B2ms'
param imageReference_Id string
param untrustnic_objectid string
param trustnic_objectid string
param mgmtnic_objectid string
param tagValues object = {}
param virtualMachine_AdminUsername string
@secure()
param virtualMachine_AdminPassword string

resource virtualMachine_Linux 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: NVAName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: VMSize
    }
    storageProfile: {
      imageReference: {
        id: imageReference_Id
      }
      osDisk: {
        osType: 'Linux'
        name: '${NVAName}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
      }
      dataDisks: []
    }
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: tagValues
}
