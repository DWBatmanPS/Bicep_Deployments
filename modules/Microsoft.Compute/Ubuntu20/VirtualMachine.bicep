@maxLength(15)
@description('Name of the Virtual Machine')
param virtualMachine_Name string

@description('''Size of the Virtual Machine
Examples:
B2ms - 2 Core 8GB Ram - Cannot use Accelerated Networking
D2as_v5 2 Core 8GB Ram - Uses Accelerated Networking''')
param virtualMachine_Size string

@description('Admin Username for the Virtual Machine')
param virtualMachine_AdminUsername string

@description('Password for the Virtual Machine Admin User')
@secure()
param virtualMachine_AdminPassword string

@secure()
param SSHKey string = ''

@description('Name of the Virtual Machines Network Interface')
param networkInterface_Name string = '${virtualMachine_Name}_NetworkInterface'

@description('True enables Accelerated Networking and False disabled it.  Not all virtualMachine sizes support Accel Net')
param acceleratedNetworking bool

@description('The Resource ID of the subnet to which the Network Interface will be assigned.')
param subnet_ID string

@description('Sets the allocation mode of the IP Address of the Network Interface to either Dynamic or Static.')
@allowed([
  'Dynamic'
  'Static'
])
param privateIPAllocationMethod string = 'Dynamic'

@description('Enter the Static IP Address here if privateIPAllocationMethod is set to Static.')
param privateIPAddress string = ''

@description('Adds a Public IP to the Network Interface of the Virtual Machine')
param addPublicIPAddress bool = false

@description('''Location of the file to be ran while the Virtual Machine is being created.  Ensure that the path ends with a /
Example: https://example.com/scripts/''')
param virtualMachine_ScriptFileLocation string = 'https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/'

@description('''Name of the file to be ran while the Virtual Machine is being created
Example: Ubuntu20_DNS_Config.sh''')
param virtualMachine_ScriptFileName string = ''
// param virtualMachine_ScriptFileName string = 'Ubuntu20_WebServer_Config.sh'

param commandToExecute string = ''

param tagValues object = {}

@description('Joins the file path and the file name together')
var virtualMachine_ScriptFileUri = '${virtualMachine_ScriptFileLocation}${virtualMachine_ScriptFileName}'

module networkInterface '../../Microsoft.Network/NetworkInterface.bicep' = {
  name: networkInterface_Name
  params: {
    acceleratedNetworking: acceleratedNetworking
    networkInterface_Name: networkInterface_Name
    subnet_ID: subnet_ID
    privateIPAddress: privateIPAddress
    addPublicIPAddress: addPublicIPAddress
    privateIPAllocationMethod: privateIPAllocationMethod
    tagValues: tagValues
  }
}

resource virtualMachine_Linux 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine_Name
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachine_Size
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachine_Name}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: virtualMachine_Name
      adminUsername: virtualMachine_AdminUsername
      adminPassword: virtualMachine_AdminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
        ssh: {
          publicKeys: [
            {
              keyData: SSHKey
              path: '/home/${virtualMachine_AdminUsername}/.ssh/authorized_keys'
            }
          ]
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.outputs.networkInterface_ID
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    evictionPolicy: 'Deallocate'
    priority: 'Spot'
  }
  tags: tagValues
}

resource virtualMachine_NetworkWatcherExtension 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  parent: virtualMachine_Linux
  name: 'AzureNetworkWatcherExtension'
  location: resourceGroup().location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
  tags: tagValues
}

resource vm_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (commandToExecute != '') {
  parent: virtualMachine_Linux
  name: 'installcustomscript'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        virtualMachine_ScriptFileUri
      ]
    }
    protectedSettings: {
      commandToExecute: commandToExecute
    }
  }
  tags: tagValues
}

output virtualMachine_Name string = virtualMachine_Linux.name

output networkInterface_Name string = networkInterface.outputs.networkInterface_Name
output networkInterface_ID string = networkInterface.outputs.networkInterface_ID

output networkInterface_IPConfig0_Name string = networkInterface.outputs.networkInterface_IPConfig0_Name
output networkInterface_IPConfig0_ID string = networkInterface.outputs.networkInterface_IPConfig0_ID
output networkInterface_PrivateIPAddress string = networkInterface.outputs.networkInterface_PrivateIPAddress

output networkInterface_PublicIPAddress string = addPublicIPAddress ? networkInterface.outputs.networkInterface_PublicIPAddress : ''
