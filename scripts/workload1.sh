#!/bin/bash                                                                                                                                                                                                                                                            
set -x
source config.sh

cd $LANDSCAPE_CONFIG_DIR

export DEPLOYMENT_REPO_PATH=~/Azure_SAP_Automated_Deployment/sap-automation

#these operations should all work
az storage blob list --account-name $storageAccount  --container-name tfstate --output table --auth-mode login
az keyvault show  --name $keyvault --output table
az keyvault secret list  --vault-name $keyvault --output table

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_workloadzone.sh \
                           --parameterfile DEVSA-SECE-SAP04-INFRASTRUCTURE.tfvars  \
                           --msi \
                           --keyvault $keyvault                                   \
                           --state_subscription $ARM_SUBSCRIPTION_ID            \
                           --storageaccountname $storageAccount                   \
                           --subscription $ARM_SUBSCRIPTION_ID                         \
                           --spn_id $ARM_CLIENT_ID                                 \
                           --tenant_id $tenantId \
                           --auto-approve  \                                                                                                                                                                                                                          \
                           --deployer_environment CSI

date