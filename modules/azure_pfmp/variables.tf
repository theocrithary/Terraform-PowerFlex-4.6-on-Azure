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

variable "vnet_name" {
  type        = string
  default     = ""
  description = "Virtual network name."
}

variable "vnet_resource_group" {
  type        = string
  default     = ""
  description = "Virtual network resource group."
}

variable "vnet_address_space" {
  type        = string
  default     = "10.2.0.0/16"
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

# TODO: Add more validation according to:
# https://infohub.delltechnologies.com/en-us/l/dell-apex-block-storage-for-microsoft-azure/azure-storage-considerations/
variable "cluster" {
  type = object({
    node_count        = number
    is_multi_az       = bool
    deployment_type   = string
    data_disk_count   = number
    data_disk_size_gb = number
  })

  default = {
    node_count        = 5
    is_multi_az       = false
    deployment_type   = "balanced"
    data_disk_count   = 20
    data_disk_size_gb = 512
  }

  validation {
    condition     = var.cluster.is_multi_az ? var.cluster.node_count >= 6 : var.cluster.node_count >= 5
    error_message = "The minimum node count is 5 for single availability zone and 6 for multiple availability zone."
  }

  validation {
    condition     = var.cluster.node_count <= 128
    error_message = "Maximum SDSs per protection domain is 128."
  }

  validation {
    condition     = var.cluster.deployment_type == "balanced" ? var.cluster.data_disk_count * var.cluster.data_disk_size_gb <= 160 * 1024 : true
    error_message = "Maximum raw capacity per SDS is 160TB."
  }

  validation {
    condition     = var.cluster.deployment_type == "balanced" ? var.cluster.data_disk_count * var.cluster.node_count <= 300 : (var.cluster.deployment_type == "optimized_v1" ? 4 * var.cluster.node_count <= 300 : 8 * var.cluster.node_count <= 300)
    error_message = "Maximum devices per storage pool is 300."
  }

  validation {
    condition = var.cluster.deployment_type == "balanced" ? (
      (var.cluster.data_disk_count * var.cluster.data_disk_size_gb * var.cluster.node_count <= 4 * 1024 * 1024) &&
      (var.cluster.data_disk_count * var.cluster.data_disk_size_gb * var.cluster.node_count >= 720)
      ) : (
      var.cluster.deployment_type == "optimized_v1" ? 4 * 1.92 * 1024 * var.cluster.node_count <= 4 * 1024 * 1024
      : 8 * 1.92 * 1024 * var.cluster.node_count <= 4 * 1024 * 1024
    )
    error_message = "Total size of all volumes per storage pool is 4PB and Minimum storage pool size is 720GB."
  }

  validation {
    condition     = contains(["balanced", "optimized_v1", "optimized_v2"], var.cluster.deployment_type)
    error_message = "Deployment type must be \"balanced\", \"optimized_v1\" or \"optimized_v2\"."
  }

  validation {
    condition = var.cluster.deployment_type == "balanced" ? (
      var.cluster.data_disk_count >= 1 &&
      var.cluster.data_disk_count <= 24
    ) : true
    error_message = "Data disk count must be between 1 and 24."
  }

  validation {
    condition     = contains([256, 512, 1024, 2048], var.cluster.data_disk_size_gb)
    error_message = "Data disk size must be 256, 512, 1024 or 2048 GB."
  }

  description = "PowerFlex cluster configuration, including: node number, deploy in single or multiple availability zones, deployment type can be 'balanced', 'optimized_v1' or 'optimized_v2', the number of data disks attached to a single node and the size of each."
}

variable "enable_accelerated_networking" {
  type        = bool
  default     = true
  description = "Enable accelerated networking for the cluster."
}

variable "availability_zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "Azure availability zones."
}

# https://www.dell.com/support/manuals/zh-hk/scaleio/flex-cloud-azure-deploy-45x/create-the-virtual-machine-for-the-storage-instance?guid=guid-c87fe065-5e65-4c96-84b9-a8f5065230cd&lang=en-us
variable "vm_size" {
  type = object({
    jumphost     = string
    installer    = string
    sqlvm        = string
    balanced     = string
    optimized_v1 = string
    optimized_v2 = string
  })
  default = {
    jumphost     = "Standard_D2s_v3"
    installer    = "Standard_D4s_v3"
    sqlvm        = "Standard_D4ds_v5"
    balanced     = "Standard_F48s_v2"
    optimized_v1 = "Standard_L32as_v3"
    optimized_v2 = "Standard_L64as_v3"
  }
  description = "Azure VM size."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 512
  description = "Azure VM OS disk size in GB."
}

# https://azuremarketplace.microsoft.com/en-us/marketplace/apps/dellemc.dell_apex_block_storage
# az vm image list --all --publisher "dellemc"
# az vm image show --publisher "dellemc" --offer "dell_apex_block_storage" --sku "apexblockstorage-4_6_0" --version "4.6.0" --json
# sku: apexblockstorage, installer45, apexblockstorage-4_6_0, apexblockstorageinstaller-4_6_0
# version: 4.5.0, 4.6.0

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
  description = "PowerFlex storage instance image in local gallery. If set, the storage instance vm will be created from this image."
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
  description = "PowerFlex installer image in local gallery. If set, the installer vm will be created from this image."
}

variable "login_credential" {
  type = object({
    username = string
    password = string
  })
  sensitive   = true
  description = "Login credential for Azure VMs."
}

variable "ssh_key" {
  type = object({
    public  = string
    private = string
  })
  description = "SSH key pair for Azure VMs."
}

variable "data_disk_iops_read_write" {
  type        = number
  default     = 4000
  description = "The number of IOPS allowed for this disk. Please refer to https://www.dell.com/support/manuals/en-hk/scaleio/flex-cloud-azure-deploy-45x/create-the-virtual-machine-for-the-storage-instance?guid=guid-c87fe065-5e65-4c96-84b9-a8f5065230cd&lang=en-us."
}

variable "data_disk_mbps_read_write" {
  type        = number
  default     = 125
  description = "The bandwidth allowed for this disk. Please refer to https://www.dell.com/support/manuals/en-hk/scaleio/flex-cloud-azure-deploy-45x/create-the-virtual-machine-for-the-storage-instance?guid=guid-c87fe065-5e65-4c96-84b9-a8f5065230cd&lang=en-us."
}

variable "data_disk_logical_sector_size" {
  type    = number
  default = 512

  validation {
    condition     = contains([512, 4096], var.data_disk_logical_sector_size)
    error_message = "Data disk logical sector size must either be 512 or 4096."
  }
  description = "Logical Sector Size. Possible values are: 512 and 4096. Please refer to https://www.dell.com/support/manuals/en-hk/scaleio/flex-cloud-azure-deploy-45x/create-the-virtual-machine-for-the-storage-instance?guid=guid-c87fe065-5e65-4c96-84b9-a8f5065230cd&lang=en-us."
}