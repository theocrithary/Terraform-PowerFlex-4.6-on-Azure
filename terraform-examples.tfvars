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

### cluster
cluster_node_count      = 6          # Minimum of 5. If is_multi_az = true, then minimum of 6
deployment_type         = "balanced" # balanced, optimized_v1 or optimized_v2
enable_bastion          = false
enable_jumphost         = false
enable_sql_workload_vm  = false # If enabled, will deploy Standard_D4ds_v5.
subscription_id         = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
existing_resource_group = "xxxxx"  # If null, a new RG will be created, else provide an existing "RG name"
is_multi_az             = true
location                = "xxxxx"
prefix                  = "xxxxx"
ssh_key                 = {
    public  = "./keys/xxxxx.pub"
    private = "./keys/xxxxx.pem"
  }
storage_instance_gallery_image = {
    name                = "latest"
    image_name          = "xxxxx"
    gallery_name        = "xxxxx"
    resource_group_name = "xxxxx"
}
installer_gallery_image = {
    name                = "latest"
    image_name          = "xxxxx"
    gallery_name        = "xxxxx"
    resource_group_name = "xxxxx"
}
vnet_address_space      = "x.x.x.x/24"
subnets                 = [
    {
      name   = "xxxxx"
      prefix = "x.x.x.x/28"
    },
    {
      name   = "xxxxx"
      prefix = "x.x.x.x/28"
    },
    {
      name   = "xxxxx"
      prefix = "x.x.x.x/28"
    }
]

### data disk
### the following value won't take effect on optimized_v1 and optimized_v2 deployment
### it will always be:
###     data_disk_count = 4 data_disk_size_gb=1966.08 for optimized_v1
###     data_disk_count = 8 data_disk_size_gb=1966.08 for optimized_v2
data_disk_count   = 3
data_disk_size_gb = 512