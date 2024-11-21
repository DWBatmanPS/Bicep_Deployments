# Bicep Deployments

This repository contains Bicep modules, deployment scripts, and lab deployments to help you manage your Azure infrastructure as code.

## Contents

- **Bicep Modules**: Reusable Bicep modules for various Azure resources.
- **Deployment Scripts**: Scripts to automate the deployment of Bicep templates.
- **Lab Deployments**: Sample lab environments to demonstrate Bicep deployments.

## Getting Started

To get started with deploying Bicep templates, follow these steps:

1. **Clone the repository**:
    ```sh
    git clone https://github.com/yourusernameDWBatmanPS
    ```

2. **Install Bicep CLI**:
    Follow the instructions [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) to install the Bicep CLI.

## Deploying Bicep Templates

There are preexisting powershell scripts built to create, update, deploy and manage individual Bicep Labs. The scripts assume that you are running PowerShell 5.1 and have Azure Powershell and Bicep installed. There are several shell scripts and Powershell scripts as well.

## Repository Structure

```plaintext
Bicep_Deployments/
│
├── Lab_Deployments/
|   ├── AFDx_Deployment/
|   |   ├──src/
|   │   |   ├── main.bicep
|   |   |   ├── main.bicepparam
|   │   └── ...
|   ├── AGIC_Helm_Upgrade/
|   |   ├──src/
|   |   └── ...
|   └── ...
|
├── modules/
│   ├── Microsoft.Authorization/
|   |   ├── agc_roles.bicep
│   |   ├── agic_role.bicep
|   |   └── ...
|   ├── Microsoft.Automation/
|   |   ├── automation_account.bicep
|   |   └── ...
│   └── ...
│
├── scripts/
│   ├── capture_and_upload_server.sh
│   ├── capture_and_upload.sh
│   └── ...
│
└── Tools/
|   ├── Create-BicepDeployButton.ps1
|   ├── Create-BicepProject.ps1
|   └── ...
```

## Contributing

We welcome contributions! Please read our [contributing guidelines](CONTRIBUTING.md) to get started.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

