@description('VPN Shared Key used for authenticating VPN connections')
@secure()
param vpn_SharedKey string

@description('Source Virtual Network Gateway ID')
param virtualNetworkGateway_ID string

param virtualNetworkGateway_ID2 string

param tagValues object = {}

var virtualNetworkGateway_ID_Split = split(virtualNetworkGateway_ID, '/')
var virtualNetworkGateway_Name = virtualNetworkGateway_ID_Split[8] 
var virtualNetworkGateway_ID2_Split = split(virtualNetworkGateway_ID2, '/')
var virtualNetworkGateway_Name2 = virtualNetworkGateway_ID2_Split[8] 
var location = resourceGroup().location

resource connection 'Microsoft.Network/connections@2022-11-01' = {
    name: '${virtualNetworkGateway_Name}_to_${virtualNetworkGateway_Name2}_Connection'
    location: location
    properties: {
      virtualNetworkGateway1: {
        id: virtualNetworkGateway_ID
        properties: {
          
        }
      }
      virtualNetworkGateway2: {
        id: virtualNetworkGateway_ID2
        properties: {
          
        }
      }
      connectionType: 'Vnet2Vnet'
      connectionProtocol: 'IKEv2'
      routingWeight: 0
      sharedKey: vpn_SharedKey
      enableBgp: true
      useLocalAzureIpAddress: false 
      usePolicyBasedTrafficSelectors: false
    //                      Default is used with the following commented out
    // ipsecPolicies: [
    // // These settings will work for connecting to Azure Virtual WAN.  Default will not.
    //   {
    //     saLifeTimeSeconds: 3600
    //     saDataSizeKilobytes: 102400000
    //     ipsecEncryption: 'AES256'
    //     ipsecIntegrity: 'SHA256'
    //     ikeEncryption: 'AES256'
    //     ikeIntegrity: 'SHA256'
    //     dhGroup: 'DHGroup14'
    //     pfsGroup: 'None'
    //   }
    // ]
      dpdTimeoutSeconds: 45
      connectionMode: 'Default'
  }
  tags: tagValues
}
