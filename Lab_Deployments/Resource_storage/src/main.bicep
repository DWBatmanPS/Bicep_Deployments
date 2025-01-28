param AccountName string
param publicaccess bool = true
param blob bool = true
param file bool = true
param queue bool = false
param table bool = false
param web bool = false
param enableHttpsTrafficOnly bool = true


module StorageAccount '../../../modules/Microsoft.Storage/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    storageAccount_Name: AccountName
    publicAccess: publicaccess
    blob: blob
    file: file
    queue: queue
    table: table
    web: web
    enableHttpsTrafficOnly: enableHttpsTrafficOnly
  }
}
