@description('Name of the Virtual Network')
param virtualNetwork_Name string

@description('Name of the General Network Security Group')
var networkSecurityGroup_Default_Name = '${virtualNetwork_Name}_NSG_General'

param virtualNetwork_AddressPrefix string

param subnet_Names array = [
  'General'
  'PrivateEndpoints'
]

param customsourceaddresscidr string = ''

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
param storageAccount_Name string
param storagepenam string = 'stopedeploy'

@description('Name of the Private Endpoint')
param privateEndpoint_Name string


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

@description('Name of the Virtual Machines Network Interface')
param networkInterface_Name string = '${virtualMachine_Name}_NetworkInterface'

@description('True enables Accelerated Networking and False disabled it.  Not all virtualMachine sizes support Accel Net')
param acceleratedNetworking bool

@description('''Location of the file to be ran while the Virtual Machine is being created.  Ensure that the path ends with a /
Example: https://example.com/scripts/''')
param virtualMachine_ScriptFileLocation string = 'https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/'

@description('''Name of the file to be ran while the Virtual Machine is being created
Example: Ubuntu20_DNS_Config.sh''')
param virtualMachine_ScriptFileName string
// param virtualMachine_ScriptFileName string = 'Ubuntu20_WebServer_Config.sh'

param commandToExecute string

param tagValues object = {}

@description('Joins the file path and the file name together')
var virtualMachine_ScriptFileUri = '${virtualMachine_ScriptFileLocation}${virtualMachine_ScriptFileName}'

var storageAccount_lower = toLower(storageAccount_Name)

var baseAddress = split(virtualNetwork_AddressPrefix, '/')[0]
var baseOctets = [int (split(baseAddress, '.')[0]), int(split(baseAddress, '.')[1]), int (split(baseAddress, '.')[2]), int (split(baseAddress, '.')[3])]

var subnetAddressPrefixes = [
  for (subnet_Name, index) in subnet_Names: {
    name: subnet_Name
    addressPrefix: '${baseOctets[0]}.${baseOctets[1]}.${baseOctets[2] + index}.0/24'
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: virtualNetwork_Name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_AddressPrefix
      ]
    }
    subnets: [
      for (subnet_Name, index) in subnet_Names: {
        name: subnetAddressPrefixes[index].name
        properties: {
          addressPrefix: subnetAddressPrefixes[index].addressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: networkSecurityGroup_Default_Name
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'AllowCustomInbound')
        name: 'AllowCustomInbound'
        properties: {
          description: 'Allow Custom Inbound'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: customsourceaddresscidr
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
    ]
  }
  tags: tagValues
}


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccount_lower
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
    isHnsEnabled: true
  }
  tags: tagValues
}

resource storageAccount_BlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' ={
  parent: storageAccount
  name: 'default'
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpoint_Name
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpoint_Name}_to_${storageAccount_lower}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'Blob'
          ]
        }
      }
    ]
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
  }
  tags: tagValues
  dependsOn: [
    storageAccount
    virtualNetwork
  ]
}

resource networkInterfaceWithPubIP 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: networkInterface_Name
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig0'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
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

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' ={
  name: '${networkInterface_Name}_PIP'
  location: resourceGroup().location
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
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
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

resource vm_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
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

