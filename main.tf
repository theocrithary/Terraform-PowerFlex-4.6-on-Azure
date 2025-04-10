# /*
# Copyright (c) 2024 Dell Inc., or its subsidiaries. All Rights Reserved.

# Licensed under the Mozilla Public License Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://mozilla.org/MPL/2.0/


# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */

module "azure_pfmp" {
  # Here the source points to the a local instance of the submodule in the modules folder, if you have and instance of the modules folder locally.
  # source         = "../../modules/azure_pfmp"

  source  = "./modules/azure_pfmp"

  cluster = {
    node_count        = var.cluster_node_count
    is_multi_az       = var.is_multi_az
    deployment_type   = var.deployment_type
    data_disk_count   = var.data_disk_count
    data_disk_size_gb = var.data_disk_size_gb
  }
  data_disk_logical_sector_size  = var.data_disk_logical_sector_size
  existing_resource_group        = var.existing_resource_group
  installer_gallery_image        = var.installer_gallery_image
  location                       = var.location
  login_credential               = var.login_credential
  prefix                         = var.prefix
  ssh_key                        = var.ssh_key
  storage_instance_gallery_image = var.storage_instance_gallery_image
  subnet_zone1                   = var.subnet_zone1
  subnet_zone2                   = var.subnet_zone2
  subnet_zone3                   = var.subnet_zone3
  vnet_name                      = var.vnet_name
  vnet_resource_group            = var.vnet_resource_group
  vnet_address_space             = var.vnet_address_space
}

output "pfmp_ip" {
  value = module.azure_pfmp.pfmp_ip
}

output "sds_nodes" {
  value = module.azure_pfmp.sds_nodes[*].ip
}