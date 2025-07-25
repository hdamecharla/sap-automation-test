#!/bin/bash
# Install az-cli, terraform, ansible
set -x
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt install -y ansible
sudo apt install -y jq
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get install terraform
sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
sudo chmod a+rwx /opt
sudo chmod a+rwx /opt/terraform
sudo chmod a+rwx /opt/terraform/.terraform.d
sudo chmod a+rw /opt/terraform/.terraform.d/plugin-cache
DEPLOYMENT_DIR=Azure_SAP_Automated_Deployment
#rm -r -f $DEPLOYMENT_DIR
mkdir  $DEPLOYMENT_DIR
cd $DEPLOYMENT_DIR
git clone https://github.com/Azure/sap-automation.git
git clone https://github.com/Azure/SAP-automation-samples.git
git clone https://github.com/Azure/SAP-automation-bootstrap.git
git clone https://github.com/rsponholtz/sap-automation-test.git

cd sap-automation-test; git pull; cd -