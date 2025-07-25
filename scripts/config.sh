#!/bin/bash
# Configure environment variables
export   ARM_SUBSCRIPTION_ID="<your subscription-id>"
export DEPLOYER_VM_CLIENT_ID="<your deployer vm client-id>"
export         ARM_TENANT_ID="<your tenant-id>"
export     deployer_env_code="<your environment code>"
export     workload_env_code="<your workload environment code>"
export           region_code="<your region code>"
export             vnet_code="<your vnet code>"

#fill in after stage 1
export CREATED_MSI_CLIENT_ID="<your created msi client-id>"
#fill in after stage 2
export              keyvault="<your keyvault name>"
export        storageAccount="<your storage account name>"


export AZURE_USER=$USER
export DEPLOYMENT_DIR=Azure_SAP_Automated_Deployment
export CONFIG_REPO=sap-automation-test

export TF_LOG=TRACE
export     DEPLOYMENT_REPO_PATH="/home/$AZURE_USER/$DEPLOYMENT_DIR/sap-automation"
export         CONFIG_REPO_PATH="/home/$AZURE_USER/$DEPLOYMENT_DIR/$CONFIG_REPO/config/WORKSPACES"
export SAP_AUTOMATION_REPO_PATH="/home/$AZURE_USER/$DEPLOYMENT_DIR/sap-automation"
export DEPLOYER_CONFIG_DIR="${CONFIG_REPO_PATH}/DEPLOYER/${env_code}-${region_code}-${vnet_code}-INFRASTRUCTURE"
export LIBRARY_CONFIG_DIR="${CONFIG_REPO_PATH}/LIBRARY/${env_code}-${region_code}-SAP_LIBRARY"
export LANDSCAPE_CONFIG_DIR="${CONFIG_REPO_PATH}/LANDSCAPE/${env_code}-${region_code}-INFRASTRUCTURE"


export deployer_parameter_file="${DEPLOYER_CONFIG_DIR}/${env_code}-${region_code}-${vnet_code}-INFRASTRUCTURE.tfvars"
export library_parameter_file="${LIBRARY_CONFIG_DIR/${env_code}-${region_code}-SAP_LIBRARY.tfvars"
