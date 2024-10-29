openssl req -new -noenc -keyout root.key -out root.csr -config root.cnf -newkey rsa:4096
openssl x509 -req -sha256 -days 365 -extfile root.cnf -extensions v3_ca -in root.csr -signkey root.key -out root.cer

#Generate Frontend Server Cert
openssl genrsa -out leaf.key 4096
openssl req -new -noenc -key leaf.key -out leaf.csr -config serverext.cnf
openssl x509 -req -in leaf.csr -CA root.cer -CAkey root.key -CAcreateserial -out leaf.cer -days 30 -sha256 -extfile extension.txt

openssl pkcs12 -export -out chain.pfx -inkey leaf.key -in bundled.cer

https://danwheelervaultstr.vault.azure.net/secrets/LargerRSACert/

$AppGwName = "VMSS-backend-AppGw" 
$RGName = "appgwWAF-lab"

#This is where you input manually the secretID to be used in the AppGw SSL config 
$secretId = "https://danwheelervaultstr.vault.azure.net/secrets/LargerRSACert/"

$AppGw = Get-AzApplicationGateway -Name $AppGwName -ResourceGroupName $RGName

Add-AzApplicationGatewaySslCertificate -ApplicationGateway $AppGw -Name "LargecertKeyvault" -KeyVaultSecretId $secretId 
Set-AzApplicationGateway -ApplicationGateway $AppGw


 


This will swap the data for the  cert on the appgw from the "bad" secret to a good secret for that cert which doesn't use a version 



