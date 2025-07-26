#!/bin/bash
# Install az-cli, terraform, ansible
set -x
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo zypper install -y ansible
sudo zypper install -y jq
sudo zypper update && sudo zypper install -y gnupg software-properties-common
wget https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip
unzip terraform*.zip
sudo mv terraform /usr/local/bin/

sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
sudo chmod a+rwx /opt
sudo chmod a+rwx /opt/terraform
sudo chmod a+rwx /opt/terraform/.terraform.d
sudo chmod a+rw /opt/terraform/.terraform.d/plugin-cache
DEPLOYMENT_DIR=Azure_SAP_Automated_Deployment
#rm -r -f $DEPLOYMENT_DIR
mkdir  ~/$DEPLOYMENT_DIR
cd ~/$DEPLOYMENT_DIR
git clone https://github.com/Azure/sap-automation.git
git clone https://github.com/Azure/SAP-automation-samples.git
git clone https://github.com/Azure/SAP-automation-bootstrap.git
git clone https://github.com/rsponholtz/sap-automation-test.git

cd sap-automation-test; git pull; cd -