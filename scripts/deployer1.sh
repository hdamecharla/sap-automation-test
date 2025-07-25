# Install az-cli, terraform, ansible
set -x
source config.sh

cd $DEPLOYER_CONFIG_DIR

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_controlplane.sh  \
    --deployer_parameter_file "${deployer_parameter_file}"         \
    --library_parameter_file "${library_parameter_file}"           \
    --subscription "${ARM_SUBSCRIPTION_ID}"                        \
    --spn_id "${DEPLOYER_VM_CLIENT_ID}"                            \
    --spn_secret "${DEPLOYER_VM_CLIENT_SECRET}"                    \
    --tenant_id "${ARM_TENANT_ID}"                                 \
    --msi                                                          \
    --auto-approve