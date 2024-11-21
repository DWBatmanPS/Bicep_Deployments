param (
    [Parameter(Mandatory)]
    [string]$OldProjectName,

    [Parameter(Mandatory)]
    [string]$NewProjectName
)

Rename-Item -Path ".\Lab_Deployments\${OldProjectName}" -NewName $NewProjectName
Remove-Item -Path ".\Lab_Deployments\${NewProjectName}\${OldProjectName}-deployment.ps1"
New-Item -ItemType File -Path ".\Lab_Deployments\${NewProjectName}\${NewProjectName}-deployment.ps1"
Set-Content -Path ".\Lab_Deployments\${NewProjectName}\${NewProjectName}-deployment.ps1" -Value ".\Tools\deployment.ps1 -DeploymentName `"${NewProjectName}`" -Location `"eastus2`""


.\Tools\Update-BicepProjectList.ps1 -ProjectName $OldProjectName -Operation "Remove"
.\Tools\Update-BicepProjectList.ps1 -ProjectName $NewProjectName -Operation "Add"
