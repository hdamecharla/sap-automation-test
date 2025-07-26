#!/bin/bash                                                                                                                                                                                                                                                            
set -x
source config.sh

cd $LANDSCAPE_CONFIG_DIR

#these operations should all work
az storage blob list --account-name $storageAccount  --container-name tfstate --output table --auth-mode login
az keyvault show  --name $keyvault --output table
az keyvault secret list  --vault-name $keyvault --output table

cd $LANDSCAPE_CONFIG_DIR

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_workloadzone.sh \
                           --parameterfile $landscape_parameter_file  \
                           --msi \
                           --keyvault $keyvault                                   \
                           --state_subscription $ARM_SUBSCRIPTION_ID            \
                           --storageaccountname $storageAccount                   \
                           --subscription $ARM_SUBSCRIPTION_ID                         \
                           --spn_id $DEPLOYER_VM_CLIENT_ID                                 \
                           --tenant_id $ARM_TENANT_ID \
                           --auto-approve  \                                                                                                                                                                                                                          \
                           --deployer_environment $deployer_env_code 
