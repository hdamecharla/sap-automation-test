# Deployer Configuration File
environment = "DEVR"
location = "swedencentral"

management_network_logical_name = "DEP01"
management_network_address_space = "10.170.20.0/24"
management_subnet_address_prefix = "10.170.20.64/28"
firewall_deployment = true
management_firewall_subnet_address_prefix = "10.170.20.0/26"
bastion_deployment = true
management_bastion_subnet_address_prefix = "10.170.20.128/26"
webapp_subnet_address_prefix = "10.170.20.192/27"
deployer_assign_subscription_permissions = true
public_network_access_enabled = true
deployer_count = 0
use_service_endpoint = true
use_private_endpoint = true
enable_firewall_for_keyvaults_and_storage = true

#additional_network_id = ""

use_spn = false
#user_assigned_identity_id=""

deployer_image = {
  os_type         = "LINUX",
  type            = "marketplace",
  source_image_id = ""
  publisher       = "Canonical",
  offer           = "0001-com-ubuntu-server-jammy",
  sku             = "22_04-lts-gen2",
  version         = "latest"
}

# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults
custom_random_id="c58"
