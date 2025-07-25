set -x
source config.sh

#control plane
#export TF_LOG_CORE=TRACE
#export TF_LOG_PROVIDER=TRACE
#export TF_LOG=TRACE

#mkdir -p $
cd $DEPLOYER_CONFIG_DIR

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_controlplane.sh  \
    --deployer_parameter_file "${deployer_parameter_file}"         \
    --library_parameter_file "${library_parameter_file}"           \
    --subscription "${ARM_SUBSCRIPTION_ID}"                        \
    --spn_id "${CREATED_MSI_CLIENT_ID}"                            \
    --spn_secret "${ARM_CLIENT_SECRET}"                            \
    --tenant_id "${ARM_TENANT_ID}" \
    --msi \
    --auto-approve