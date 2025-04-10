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

variable "prefix" {
  type        = string
  description = "Prefix for Azure resource names."
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "Azure subscription to use for deployment"
}

variable "existing_resource_group" {
  type        = string
  default     = null
  description = "Name of existing resource group to use. If not set, a new resource group will be created."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Location for Azure resources."
}

variable "cluster_node_count" {
  type        = number
  default     = 5
  description = "PowerFlex cluster node number."
}

variable "is_multi_az" {
  type        = bool
  default     = false
  description = "Whether to deploy the PowerFlex cluster in single or multiple availability zones."
}

variable "deployment_type" {
  type        = string
  default     = "balanced"
  description = "PowerFlex cluster deployment type, Possible values are: 'balanced', 'optimized_v1' or 'optimized_v2'."
}

variable "data_disk_count" {
  type        = number
  default     = 20
  description = "The number of data disks attached to each PowerFlex cluster node."
}

variable "data_disk_size_gb" {
  type        = number
  default     = 512
  description = "The size of each data disk in GB."
}

variable "data_disk_logical_sector_size" {
  type        = number
  default     = 512
  description = "Logical Sector Size. Possible values are: 512 and 4096."
}

variable "login_credential" {
  type = object({
    username = string
    password = string
  })
  sensitive = true
  default = {
    username = "pflexuser"
    password = "PowerFlex123!"
  }
  description = "Login credential for Azure VMs."
}

variable "ssh_key" {
  type = object({
    public  = string
    private = string
  })
  default = {
    public  = "./ssh/azure.pem.pub"
    private = "./ssh/azure.pem"
  }
  description = "SSH key pair for Azure VMs."
}

variable "storage_instance_gallery_image" {
  type = object({
    name                = string
    image_name          = string
    gallery_name        = string
    resource_group_name = string
    publisher           = string
    offer               = string
    sku                 = string
  })
  default     = null
  description = "PowerFlex storage instance image in local gallary. If set, the storage instance vm will be created from this image."
}

variable "installer_gallery_image" {
  type = object({
    name                = string
    image_name          = string
    gallery_name        = string
    resource_group_name = string
    publisher           = string
    offer               = string
    sku                 = string
  })
  default     = null
  description = "PowerFlex installer image in local gallary. If set, the installer vm will be created from this image."
}

variable "vnet_name" {
  type        = string
  default     = ""
  description = "Virtual network name."
}

variable "vnet_resource_group" {
  type        = string
  default     = ""
  description = "Virtual network name."
}

variable "vnet_address_space" {
  type        = string
  default     = ""
  description = "Virtual network address space."
}

variable "subnet_zone1" {
  type = string
  default = ""
  description = "Subnet for zone 1 for the virtual network."
}

variable "subnet_zone2" {
  type = string
  default = ""
  description = "Subnet for zone 2 for the virtual network."
}

variable "subnet_zone3" {
  type = string
  default = ""
  description = "Subnet for zone 3 for the virtual network."
}