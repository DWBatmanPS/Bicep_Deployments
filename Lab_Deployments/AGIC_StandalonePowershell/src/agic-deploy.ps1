Write-Output "THIS IS A POWERSHELL SCRIPT INTENDED TO DEPLOY AND CONFIGURE AN AGIC ENVIRONMENT WITH AN AKS CLUSTER, AN APPLICATION GATEWAY AND ALL NEEDED VALUES. THE SCRIPT IS CAPABLE OF GENERATING A SELF SIGNED CERTIFICATE CHAIN OR USING A REAL EXISTING CERTIFICATE AS A PFX FILE. IF YOU ARE USING A PFX FILE THE SCRIPT ASSUMES THAT YOU ARE USING MODEN ENCRYPTION FOR YOUR PFX FILE. PLEASE SEE FOR https://aka.ms/openssl-install and https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/export-certificate-private-key#export-a-certificate-from-the-windows-certificate-stores-with-the-private-key MORE INFORMATION ON ENCRYPTION ON PFX FILES. 

THE SCRIPT ALSO ASSUMES THAT YOU HAVE ALREADY AUTHENTICATED YOUR POWERSHELL SESSION TO AZURE USING Connect-AzAccount. 

THE SCRIPT ASSUMES THAT YOU HAVE THE FOLLOWING TOOLS INSTALLED AND REGISTERED IN YOUR POWERSHELL ENVIRONMENT:
    Helm
    Kubectl
    OpenSSL

THE SCRIPT IS PROVIDED AS IS AND MAY STOP WORKING DUE TO CHANGES ON AZURE, LOCALLY OR YOUR POWERSHELL PROFILE."

## Define these variables
$resourceGroupName= "EndtoEndAGICDeployment"
$location="centralus"
$deploymentName="ingressappgwaks"
$frontendfqdn="example.contoso.com"
$sshkey  = 'Insert your public SSH Key here'
$useRealCert = $false

## Define the PFX password if you are using a local cert.
$PFXPassword="certpfxpassword"

## Define the path to the pfx file if you are using a local cert. If placing the file in the same directory as the script, you can use the following line.
$pfxFilePath = ("C:\path\to\your\cert.pfx")

## Load location into variable
$Loc = Get-Location

## DeploymentParams
$VnetName  = 'agic_vnet'
$VnetPrefix  = '10.0.0.0/8'
$AKSsubnetPrefix  = '10.0.0.0/23'
$AppgwsubnetPrefix  = '10.0.2.0/24'
$aksClusterNodeCount = 2
$aksClusterName  = 'agicaks'
$aksClusterNodeSize  = 'Standard_D2_v2'
$aksClusterKubernetesVersion  = '1.30.0'
$aksdnsPrefix  = 'agicaksdns'
$linuxadmin  = 'exampleadmin'
$akspodCidr  = '192.168.0.0/20'
$aksserviceCidr  = '192.168.16.0/20'
$aksinternalDNSIP  = '192.168.16.10'
$applicationGateWayName  = 'agic-appgw'
$publicIPAddressName  = 'agicappgwvip'
$AGICNamespace  = 'agic'
$AGICIDName  = 'ingress-azure'
$appgwsubnetname  = 'appgw'
$akssubnetname  = 'default'
$agicmanagedid = 'agicmanagedid'
$bicepfile = 'agic.bicep'
$biceppath = "$Loc\$bicepfile"

# Check if you are authenticated to Azure
$context = Get-AzContext

if ($null -eq $context) {
    Write-Output "You are not authenticated to Azure. Exiting script."
    Exit
} else {
    Write-Output "You are authenticated to Azure."
    Write-Output "Subscription: $($context.Subscription.Name)"

}

#Check for tls folder logic

# Define the file path
$filePath = "$loc\tls"

# Check if the file exists
if (-Not (Test-Path -Path $filePath)) {
    # If the file does not exist, create it
    New-Item -Path $filePath -ItemType Directory
    Write-Output "TLS Directory created: $filePath"
} else {
    Write-Output "TLS Directory already exists: $filePath"
}

$Biceptemplatecontents = "param VnetName string = 'agic_vnet'
param VnetPrefix string = '10.0.0.0/8'
param AKSsubnetPrefix string = '10.0.0.0/23'
param AppgwsubnetPrefix string = '10.0.2.0/24'
param aksClusterNodeCount int = 2
param aksClusterName string = 'agicaks'
param aksClusterNodeSize string = 'Standard_D2_v2'
param aksClusterKubernetesVersion string = '1.30.0'
param aksdnsPrefix string = 'agicaksdns'
param linuxadmin string = 'exampleadmin'
param sshkey string 
param akspodCidr string = '192.168.0.0/20'
param aksserviceCidr string = '192.168.16.0/20'
param aksinternalDNSIP string = '192.168.16.10'
param applicationGateWayName string = 'bicepappgw'
param publicIPAddressName string = 'appgwvip'
param AGICNamespace string = 'agic'
param AGICIDName string = 'ingress-azure'
param appgwsubnetname string = 'appgw'
param akssubnetname string = 'default'
param rootcertdata string = '' 
param rootcertname string = 'backend-tls'
param managedidentity_name string = 'agicmanagedid'

param publiccertexists bool 

var location = resourceGroup().location
var federated_id_subject = 'system:serviceaccount:`${AGICNamespace}:`${AGICIDName}'
var readerid = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var netcontribid = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var contribid = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var AppgwsubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, appgwsubnetname)
var AKSsubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, akssubnetname)
var trustedrootcertid = resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates/', applicationGateWayName, rootcertname)
var randomString = uniqueString(resourceGroup().id, managedidentity_name)

resource default_vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VnetPrefix
      ]
    }
    subnets: [
      {
        name: akssubnetname
        properties: {
          addressPrefix: AKSsubnetPrefix
        }
      }
      {
        name: appgwsubnetname
        properties: {
          addressPrefix: AppgwsubnetPrefix
        }
      }
    ]
  }
}

resource k8s 'Microsoft.ContainerService/managedClusters@2024-03-02-preview' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksdnsPrefix
    kubernetesVersion: aksClusterKubernetesVersion
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: aksClusterNodeCount
        vmSize: aksClusterNodeSize
        vnetSubnetID: AKSsubnetId
        osType: 'Linux'
        mode:'System'
      }
    ]
    linuxProfile: {
      adminUsername: linuxadmin
      ssh: {
        publicKeys: [
          {
            keyData: sshkey
          }
        ]
      }
    }
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      outboundType: 'loadBalancer'
      podCidr: akspodCidr
      serviceCidr: aksserviceCidr
      dnsServiceIP: aksinternalDNSIP
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' ={
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource applicationGateWay 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: applicationGateWayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: AppgwsubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: '10.0.0.1'              
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaultHTTPSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    trustedRootCertificates: (publiccertexists ? null : [
      {
        id: trustedrootcertid
        name: rootcertname
        properties: {
          data: rootcertdata
        }
      }
    ])
    httpListeners: [
      {
        name: 'defaultFrontend'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'defaultFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'defaultBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'defaultHTTPSetting')
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
  dependsOn: [
    default_vnet
  ]
}

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedidentity_name
  location: location
}

resource contributorroledef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: contribid
}

resource readerroledef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: readerid
}

resource networkcontributorroledef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: netcontribid
}

resource ManagedIdFederation 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: managedidentity_name
  parent: ManagedID
  dependsOn: [
    ManagedID
    k8s
  ]
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: k8s.properties.oidcIssuerProfile.issuerURL
    subject: federated_id_subject
  }
}

resource agic_contrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedidentity_name, contribid, randomString)
  scope: applicationGateWay
  properties: {
    principalId: ManagedID.properties.principalId
    roleDefinitionId: contributorroledef.id
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    applicationGateWay
  ]
}

resource network_contrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedidentity_name, netcontribid, randomString)
  scope: default_vnet
  properties: {
    principalId: ManagedID.properties.principalId
    roleDefinitionId: networkcontributorroledef.id
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    default_vnet
  ]
}

resource agic_reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedidentity_name, readerid, randomString)
  scope: resourceGroup()
  properties: {
    principalId: ManagedID.properties.principalId
    roleDefinitionId: readerroledef.id
    principalType: 'ServicePrincipal'
  }
}

output aksClusterName string = k8s.name
output aksClusterFQDN string = k8s.properties.fqdn
output aksworkloadoidcissuer string = k8s.properties.oidcIssuerProfile.issuerURL
output managedidclientid string = ManagedID.properties.clientId
output subid string = subscription().subscriptionId
output appgw string = applicationGateWay.name
"

#Create the Bicep template.
Set-Content -Path $biceppath -Value $Biceptemplatecontents

if ($useRealCert) {

    $publiccert = $true
    $serverKeyPath = ("$Loc\tls\tls.key")
    $certPath = ("$Loc\tls\tls.cer")
    $caCertPath = ("$Loc\tls\roottls.pem")
    $chainPath = ("$Loc\tls\fronttls-chain.cer")

    #Extracting the key file from the PFX
    openssl pkcs12 -in $pfxFilePath -nocerts -out $Loc\tls\encrypttls.key -passin pass:$PFXPassword -passout pass:$PFXPassword
    #Decrypting the key file
    openssl rsa -in $Loc\tls\encrypttls.key -out $serverKeyPath -passin pass:$PFXPassword
    #Extracting the public key from the PFX file
    openssl pkcs12 -in $pfxFilePath -nokeys -out $certPath -passin pass:$PFXPassword

    openssl pkcs12 -in $pfxFilePath -cacerts -nokeys -out $caCertPath -passin pass:$PFXPassword

    $LeafCert = Get-Content $certPath -Raw
    $RootchainCert = Get-Content $caCertPath -Raw
    $ChainCert = $LeafCert + $RootchainCert

    #Remove existing leaf cert file
    Remove-Item -Path $certPath -Force

    #Remote existing encrypted key file
    Remove-Item -Path ("$Loc\tls\encrypttls.key") -Force

    #Write the chain cert to the tls cert file
    Set-Content -path $chainPath -Value $ChainCert

    $Ingressconfig = "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: website-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: 'true'
    appgw.ingress.kubernetes.io/backend-protocol: 'https'
    appgw.ingress.kubernetes.io/backend-hostname: $frontendfqdn
spec:
  tls:
    - secretName: frontend-tls
      hosts:
        - $frontendfqdn
  rules:
    - host: $frontendfqdn
      http:
        paths:
        - path: /
          backend:
            service:
              name: website-service
              port:
                number: 8443
          pathType: Exact"


Set-Content -Path .\ingressconfig.yaml -Value $Ingressconfig
}

else {

    $publiccert = $false
  #Set Cert Variables
    $caKeyPath = ("$Loc\tls\roottls.key")
    $caCSRPath = ("$Loc\tls\roottls.csr")
    $caCertPath = ("$Loc\tls\roottls.pem")
    $txtfile = ("$Loc\tls\v3.txt")
    $ServerExtfile = ("$Loc\tls\serverext.cnf")
    $serverKeyPath = ("$Loc\tls\fronttls.key")
    $serverCsrPath = ("$Loc\tls\fronttls.csr")
    $serverCertPath  = ("$Loc\tls\fronttls.cer")
    $chainPath = ("$Loc\tls\fronttls-chain.cer")
    $rootcnffile = ("$Loc\tls\root.cnf")

    $rootcnf = "[ req ]
distinguished_name       = req_distinguished_name
extensions               = v3_ca
req_extensions           = v3_ca
prompt                   = no

[ v3_ca ]
basicConstraints         = CA:TRUE

[ req_distinguished_name ]
countryName                 = US
stateOrProvinceName         = WA
localityName               = Seattle
organizationName           = Contoso
organizationName		= Root Cert"
    Set-Content -Path $rootcnffile -Value $rootcnf

    $ServerExtContents = "[ req ]
distinguished_name = req_distinguished_name
prompt=no 
[ req_distinguished_name ]
countryName                 = US
stateOrProvinceName         = WA
localityName               = SEATTLE
organizationName           = Contoso
commonName                 = $frontendfqdn"
    
     Set-Content -Path $ServerExtfile -Value $ServerExtContents

    $txtFileContents = "subjectAltName         = DNS:$frontendfqdn
extendedKeyUsage = serverAuth, clientAuth"
    Set-Content -Path $txtfile -Value $txtFileContents

     #Generate Root Cert
    openssl ecparam -out $caKeyPath -name prime256v1 -genkey
    openssl req -new -noenc -key $caKeyPath -out $caCSRPath -config $rootcnffile
    openssl x509 -req -sha256 -days 365 -extfile $rootcnffile -extensions v3_ca -in $caCSRPath -signkey $caKeyPath -out $caCertPath

    #Generate Frontend Server Cert
    openssl ecparam -out $serverKeyPath -name prime256v1 -genkey
    openssl req -new -noenc -key $serverKeyPath -out $serverCsrPath -config $ServerExtfile
    openssl x509 -req -in $serverCsrPath -CA $caCertPath -CAkey $caKeyPath -CAcreateserial -out $serverCertPath -days 30 -sha256 -extfile $txtfile

    #Build Frontend Cert chain
    $LeafCert = Get-Content $serverCertPath -Raw
    $RootCert = Get-Content $caCertPath -Raw
    $ChainCert = $LeafCert + $RootCert
    Set-Content -path $chainPath -Value $ChainCert

    $rootcertname = 'rootcert'
    $Ingressconfig = "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: website-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: 'true'
    appgw.ingress.kubernetes.io/backend-protocol: 'https'
    appgw.ingress.kubernetes.io/backend-hostname: $frontendfqdn
    appgw.ingress.kubernetes.io/appgw-trusted-root-certificate: $rootcertname
spec:
  tls:
    - secretName: frontend-tls
      hosts:
        - $frontendfqdn
  rules:
    - host: $frontendfqdn
      http:
        paths:
        - path: /
          backend:
            service:
              name: website-service
              port:
                number: 8443
          pathType: Exact"


Set-Content -Path .\ingressconfig.yaml -Value $Ingressconfig
}

if ($publiccert) {

    #Manipulate Boolean values to format correctly for Bicep
    $publiccertlower = $publiccert.ToString().ToLower()

    # Define these variables for usage as a Bicep parameters template.
    $params = "using '$bicepfile'

    param VnetName = '$VnetName'
    param VnetPrefix = '$VnetPrefix'
    param AKSsubnetPrefix = '$AKSsubnetPrefix'
    param AppgwsubnetPrefix = '$AppgwsubnetPrefix'
    param aksClusterNodeCount = $aksClusterNodeCount
    param aksClusterName = '$aksClusterName'
    param aksClusterNodeSize = '$aksClusterNodeSize'
    param aksClusterKubernetesVersion = '$aksClusterKubernetesVersion'
    param aksdnsPrefix = '$aksdnsPrefix'
    param linuxadmin = '$linuxadmin'
    param sshkey = '$sshkey'
    param akspodCidr = '$akspodCidr'
    param aksserviceCidr = '$aksserviceCidr'
    param aksinternalDNSIP = '$aksinternalDNSIP'
    param applicationGateWayName = '$applicationGateWayName'
    param publicIPAddressName = '$publicIPAddressName'
    param AGICNamespace  = '$AGICNamespace'
    param AGICIDName = '$AGICIDName'
    param appgwsubnetname = '$appgwsubnetname'
    param akssubnetname = '$akssubnetname'
    param publiccertexists = $publiccertlower
    param managedidentity_name = '$agicmanagedid'"

    $paramsfile = ("$Loc\azuredeploy.parameters.bicepparam")

    Set-Content -Path $paramsfile -Value $params

}
else {
    # Convert the root cert data to a base64 string
$RootCertbase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($RootCert))

#Manipulate Boolean values to format correctly for Bicep
$publiccertlower = $publiccert.ToString().ToLower()

# Define these variables for usage as a Bicep parameters template.
$params = "using '$bicepfile'

param VnetName = '$VnetName'
param VnetPrefix = '$VnetPrefix'
param AKSsubnetPrefix = '$AKSsubnetPrefix'
param AppgwsubnetPrefix = '$AppgwsubnetPrefix'
param aksClusterNodeCount = $aksClusterNodeCount
param aksClusterName = '$aksClusterName'
param aksClusterNodeSize = '$aksClusterNodeSize'
param aksClusterKubernetesVersion = '$aksClusterKubernetesVersion'
param aksdnsPrefix = '$aksdnsPrefix'
param linuxadmin = '$linuxadmin'
param sshkey = '$sshkey'
param akspodCidr = '$akspodCidr'
param aksserviceCidr = '$aksserviceCidr'
param aksinternalDNSIP = '$aksinternalDNSIP'
param applicationGateWayName = '$applicationGateWayName'
param publicIPAddressName = '$publicIPAddressName'
param AGICNamespace  = '$AGICNamespace'
param AGICIDName = '$AGICIDName'
param appgwsubnetname = '$appgwsubnetname'
param akssubnetname = '$akssubnetname'
param rootcertdata = '$RootCertbase64'
param rootcertname = '$rootcertname'
param publiccertexists = $publiccertlower
param managedidentity_name = '$agicmanagedid'"

$paramsfile = ("$Loc\azuredeploy.parameters.bicepparam")

Set-Content -Path $paramsfile -Value $params
}

Write-Output "Templating is done and the parameters file is created. Moving on to deployment"

New-AzResourceGroup -Name $resourceGroupName -Location $location

Start-Sleep -s 30

Write-Output "Resource Group $resourceGroupName created. Moving on to deployment."


$deployment = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $biceppath -TemplateParameterFile $paramsfile

Write-Output "Deployment is complete. Sleeping for three minutes while identities replicate."

Start-Sleep -s 180

Import-AzAksCredential -ResourceGroupName $resourceGroupName -Name $aksClusterName -Force

Write-Output "AKS Cluster credentials are imported. Starting AGIC pod deployments."

helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update
helm install --version 1.7.4 $AGICIDName application-gateway-kubernetes-ingress/ingress-azure --namespace $AGICNamespace --create-namespace --set "appgw.name=$($deployment.outputs.appgw.value)" --set "appgw.resourceGroup=$resourceGroupName" --set "appgw.subscriptionId=$($deployment.outputs.subid.value)" --set "appgw.shared=false" --set "armAuth.type=workloadIdentity"  --set "armAuth.identityClientID=$($deployment.outputs.managedidclientid.value)" --set "rbac.enabled=true" --set "verbosityLevel=3"  --set "aksClusterConfiguration.apiServerAddress=$($deployment.outputs.aksClusterFQDN.value)"

Write-Output "AGIC pod deployment is completed. Deploying applications to AKS and AGIC."

kubectl create secret tls frontend-tls --key=$serverKeyPath --cert=$chainPath
kubectl create secret tls backend-tls --key=$serverKeyPath --cert=$chainPath
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-https-backend.yaml

kubectl apply -f .\ingressconfig.yaml

Write-Output "Deployment is completed. Script is done and exiting. "