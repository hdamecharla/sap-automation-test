# Install az-cli, terraform, ansible
set -x
source config.sh

#control plane
export TF_LOG=TRACE

cd $LIBRARY_CONFIG_DIR
ls -l
DEPLOYER_TFSTATE_KEY="${deployer_env_code}-${region_code}-${vnet_code}-INFRASTRUCTURE.terraform.tfstate"

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh  \
--type sap_library \
        --parameterfile $library_parameter_file      \
       --storageaccountname $storageAccount      \
              --deployer_tfstate_key $DEPLOYER_TFSTATE_KEY \
      --auto-approve
echo "return code is $?"
