@description('Name of the Virtual Machines Network Interface')
param networkInterface_Name string

param location string = resourceGroup().location

@description('True enables Accelerated Networking and False disabled it.  Not all virtualMachine sizes support Accel Net')
param acceleratedNetworking bool

@description('Sets the allocation mode of the IP Address of the Network Interface to either Dynamic or Static.')
@allowed([
  'Dynamic'
  'Static'
])
param privateIPAllocationMethod string = 'Dynamic'

@description('Enter the Static IP Address here if privateIPAllocationMethod is set to Static.')
param privateIPAddress string = ''

@description('The Resource ID of the subnet to which the Network Interface will be assigned.')
param subnet_ID string

param tags object = {}

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

@description('''Location of the file to be ran while the Virtual Machine is being created.  Ensure that the path ends with a /
Example: https://example.com/scripts/''')
param virtualMachine_ScriptFileLocation string = ''

@description('''Name of the file to be ran while the Virtual Machine is being created
Example: WinServ2022_ConfigScript_General.ps1''')
param virtualMachine_ScriptFileName string = ''

@description('Joins the file path and the file name together')
var virtualMachine_ScriptFileUri = '${virtualMachine_ScriptFileLocation}${virtualMachine_ScriptFileName}'

@description(''''Command to execute while the Virtual Machine is being created.
Example:
'powershell.exe -ExecutionPolicy Unrestricted -File <file name.ps1>'
''')
param commandToExecute string = ''

var tagValues = tags

resource networkInterfaceWithPubIP 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: networkInterface_Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig0'
        properties: {
          privateIPAllocationMethod: privateIPAllocationMethod
          subnet: {
            id: subnet_ID 
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: privateIPAddress
          publicIPAddress: { 
            id: publicIPAddress.id 
          }
        }
      }
    ]
    enableAcceleratedNetworking: acceleratedNetworking
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
  }
  tags: tagValues
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: '${networkInterface_Name}_PIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
  tags: tagValues
}

resource virtualMachine_Windows 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: virtualMachine_Name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachine_Size
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${virtualMachine_Name}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
      dataDisks: []
      diskControllerType: 'NVMe'
    }
    osProfile: {
      computerName: virtualMachine_Name
      adminUsername: virtualMachine_AdminUsername
      adminPassword: virtualMachine_AdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceWithPubIP.id
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
  parent: virtualMachine_Windows
  name: 'AzureNetworkWatcherExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
  }
  tags: tagValues
}

resource virtualMachine_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (virtualMachine_ScriptFileName != '') {
  parent: virtualMachine_Windows
  name: 'installcustomscript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
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

output publicIPAddress string = publicIPAddress.properties.ipAddress
