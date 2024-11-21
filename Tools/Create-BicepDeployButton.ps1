param(
    [Parameter(Mandatory)]
    [string]$BranchName = "main",
    [Parameter(Mandatory)]
    [string]$DirectoryName
)

$originalURL = "https://github.com/DWBatmanPS/Bicep_Deployment/Lab_Deployments/blob/${BranchName}/${DirectoryName}/src/main.json"
$removeBlob = $originalURL.Remove($originalURL.IndexOf("/blob"), 5)
$shortURL = $removeBlob.Substring(14)
$rawURL = "https://raw.githubusercontent${shortURL}"
$encodedURL = [uri]::EscapeDataString($rawURL)

return "[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/${encodedURL})"
