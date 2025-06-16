@maxLength(15)
@description('Name of the Virtual Machine')
param virtualMachine_Name string

@description('''Size of the Virtual Machine
Examples:
B2ms - 2 Core 8GB Ram - Cannot use Accelerated Networking
D2as_v5 2 Core 8GB Ram - Uses Accelerated Networking''')
param virtualMachine_Size string

@description('True enables Accelerated Networking and False disabled it.  Not all virtualMachine sizes support Accel Net')
param acceleratedNetworking bool

@description('Sets the allocation mode of the IP Address of the Network Interface to either Dynamic or Static.')
@allowed([
  'Dynamic'
  'Static'
])
param privateIPAllocationMethod string = 'Static'

@description('Adds a Public IP to the Network Interface of the Virtual Machine')
param addPublicIPAddress bool = false

@description('Uri of the existing VHD for Untangle')
param osDiskVhdUri string

param vnetId string
param subnet1Name string
param subnet2Name string
param subnet1PrivateAddress string
param subnet2PrivateAddress string


var networkInterface1_Name = '${virtualMachine_Name}_Red_NetworkInterface'
var networkInterface2_Name = '${virtualMachine_Name}_Green_NetworkInterface'


var subnet1Id = '${vnetId}/subnets/${subnet1Name}'
var subnet2Id = '${vnetId}/subnets/${subnet2Name}'

module nic1_Red '../../Microsoft.Network/NetworkInterface.bicep' = {
  name: networkInterface1_Name
  params: {
    acceleratedNetworking: acceleratedNetworking
    IPForward: true
    networkInterface_Name: networkInterface1_Name
    subnet_ID: subnet1Id
    privateIPAddress: subnet1PrivateAddress
    addPublicIPAddress: addPublicIPAddress
    privateIPAllocationMethod: privateIPAllocationMethod
  }
}

module nic2_Green '../../Microsoft.Network/NetworkInterface.bicep' = {
  name: networkInterface2_Name
  params: {
    acceleratedNetworking: acceleratedNetworking
    networkInterface_Name: networkInterface2_Name
    subnet_ID: subnet2Id
    privateIPAddress: subnet2PrivateAddress
    addPublicIPAddress: false
    privateIPAllocationMethod: privateIPAllocationMethod
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  location: resourceGroup().location
  name: virtualMachine_Name
  properties: {
    hardwareProfile: {
      vmSize: virtualMachine_Size
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1_Red.outputs.networkInterface_ID 
          properties: {
            primary: true
          }
        }
        {
          id: nic2_Green.outputs.networkInterface_ID 
          properties: {
            primary: false
          }
        }
      ]
    }
    storageProfile: {
      osDisk: {
        name: '${virtualMachine_Name}-osDisk'
        osType: 'Linux'
        caching: 'ReadWrite'
        vhd: {
          uri: osDiskVhdUri
        }
        createOption: 'Attach'
      }
    }
    evictionPolicy: 'Deallocate'
    priority: 'Spot'
  }
}

