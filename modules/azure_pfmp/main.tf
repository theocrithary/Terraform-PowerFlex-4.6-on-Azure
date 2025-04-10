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

locals {
  vm_size = var.cluster.deployment_type == "balanced" ? var.vm_size.balanced : (var.cluster.deployment_type == "optimized_v1" ? var.vm_size.optimized_v1 : var.vm_size.optimized_v2)

  is_balanced = var.cluster.deployment_type == "balanced" ? true : false

  data_disk_count = var.cluster.deployment_type == "balanced" ? var.cluster.data_disk_count : (var.cluster.deployment_type == "optimized_v1" ? 4 : 8)

  availability_zones = var.cluster.is_multi_az ? var.availability_zones : [element(var.availability_zones, 0)]

  invalid_rg_name = "!!i_am_not_a_valid_name!!"
  resource_group  = coalesce(var.existing_resource_group, local.invalid_rg_name) == local.invalid_rg_name ? azurerm_resource_group.pflex_rg[0] : data.azurerm_resource_group.pflex_rg[0]
}

## Create resource group
resource "azurerm_resource_group" "pflex_rg" {
  count    = coalesce(var.existing_resource_group, local.invalid_rg_name) == local.invalid_rg_name ? 1 : 0
  name     = "${var.prefix}-rg"
  location = var.location
}

data "azurerm_resource_group" "pflex_rg" {
  count = coalesce(var.existing_resource_group, local.invalid_rg_name) != local.invalid_rg_name ? 1 : 0
  name  = var.existing_resource_group
}

## Get existing virtual network
data "azurerm_virtual_network" "pflex_network" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group
}

## Get subnet for zone 1
data "azurerm_subnet" "pflex_subnet_zone1" {
  name                = var.subnet_zone1
  virtual_network_name = data.azurerm_virtual_network.pflex_network.name
  resource_group_name = data.azurerm_virtual_network.pflex_network.resource_group_name
}

## Get subnet for zone 2
data "azurerm_subnet" "pflex_subnet_zone2" {
  name                = var.subnet_zone2
  virtual_network_name = data.azurerm_virtual_network.pflex_network.name
  resource_group_name = data.azurerm_virtual_network.pflex_network.resource_group_name
}

## Get subnet for zone 3
data "azurerm_subnet" "pflex_subnet_zone3" {
  name                = var.subnet_zone3
  virtual_network_name = data.azurerm_virtual_network.pflex_network.name
  resource_group_name = data.azurerm_virtual_network.pflex_network.resource_group_name
}


## Create Network Security Group and rule
resource "azurerm_network_security_group" "pflex_nsg" {
  name                = "${var.prefix}-nsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      source_port_range          = security_rule.value.source_port_range
      destination_address_prefix = security_rule.value.destination_address_prefix
      destination_port_range     = security_rule.value.destination_port_range
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "pflex_nsg_association" {
  network_security_group_id = azurerm_network_security_group.pflex_nsg.id
  subnet_id           = data.azurerm_subnet.pflex_subnet_zone1.id
}

data "azurerm_shared_image" "storage_image" {
  name                = var.storage_instance_gallery_image.name
  gallery_name        = var.storage_instance_gallery_image.gallery_name
  resource_group_name = var.storage_instance_gallery_image.resource_group_name
}

data "azurerm_shared_image" "installer_image" {
  name                = var.installer_gallery_image.name
  gallery_name        = var.installer_gallery_image.gallery_name
  resource_group_name = var.installer_gallery_image.resource_group_name
}

## Create storage instance
# https://www.dell.com/support/manuals/zh-hk/scaleio/flex-cloud-azure-deploy-45x/create-the-virtual-machine-for-the-storage-instance?guid=guid-c87fe065-5e65-4c96-84b9-a8f5065230cd&lang=en-us
resource "azurerm_network_interface" "storage_instance_nic" {
  count                          = var.cluster.node_count
  name                           = "${var.prefix}-nic-${count.index}"
  location                       = local.resource_group.location
  resource_group_name            = local.resource_group.name
  accelerated_networking_enabled = var.enable_accelerated_networking

  ip_configuration {
    name                          = "nic_configuration"
    subnet_id                     = data.azurerm_subnet.pflex_subnet_zone1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "storage_instance" {
  count                 = var.cluster.node_count
  name                  = "${var.prefix}-vm-${count.index}"
  location              = local.resource_group.location
  resource_group_name   = local.resource_group.name
  network_interface_ids = [azurerm_network_interface.storage_instance_nic[count.index].id]
  size                  = local.vm_size
  zone                  = local.availability_zones[count.index % length(local.availability_zones)]

  os_disk {
    name                 = "${var.prefix}-vm-${count.index}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  plan {
    name      = var.storage_instance_gallery_image.sku
    publisher = var.storage_instance_gallery_image.publisher
    product   = var.storage_instance_gallery_image.offer
  }

  source_image_id = data.azurerm_shared_image.storage_image.id

  disable_password_authentication = false
  admin_username                  = var.login_credential.username
  admin_password                  = var.login_credential.password
  admin_ssh_key {
    username   = var.login_credential.username
    public_key = file("${var.ssh_key.public}")
  }

  # https://learn.microsoft.com/en-us/azure/virtual-machines/custom-data
  # cloud-init. By default, this agent processes custom data.
  # It doesn't wait for custom data configurations from the user 
  #   to finish before reporting to the platform that the VM is ready.
  custom_data = filebase64("${path.module}/disable_firewall.sh")
  # custom_data = index < 3 ? filebase64("${path.module}/init_pfmp_config.sh") : null

  # TODO:
  # May not be needed when https://github.com/hashicorp/terraform-provider-azurerm/issues/20723 is implemented
  provisioner "local-exec" {
    command = count.index > 2 ? "whoami" : <<-EOT
      az disk update -n ${var.prefix}-vm-${count.index}-os-disk -g ${local.resource_group.name} --set tier=P40 --no-wait
      az disk wait --updated -n ${var.prefix}-vm-${count.index}-os-disk -g ${local.resource_group.name}
    EOT
  }
}

resource "azurerm_managed_disk" "data_disks" {
  for_each = {
    for i in range(local.is_balanced ? (var.cluster.node_count * var.cluster.data_disk_count) : 0) : i => {
      vm_index   = floor(i / var.cluster.data_disk_count)
      disk_index = i % var.cluster.data_disk_count
    }
  }
  name                 = "${var.prefix}-vm-${each.value.vm_index}-data-disk-${each.value.disk_index}"
  location             = local.resource_group.location
  resource_group_name  = local.resource_group.name
  storage_account_type = "PremiumV2_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.cluster.data_disk_size_gb
  zone                 = local.availability_zones[each.value.vm_index % length(local.availability_zones)]
  disk_iops_read_write = var.data_disk_iops_read_write
  disk_mbps_read_write = var.data_disk_mbps_read_write
  logical_sector_size  = var.data_disk_logical_sector_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_data_disk_attachment" {
  for_each = {
    for i in range(local.is_balanced ? (var.cluster.node_count * var.cluster.data_disk_count) : 0) : i => {
      vm_index   = floor(i / var.cluster.data_disk_count)
      disk_index = i % var.cluster.data_disk_count
    }
  }
  managed_disk_id    = azurerm_managed_disk.data_disks[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.storage_instance[each.value.vm_index].id
  lun                = each.value.disk_index
  caching            = "None"
}


## Create Installer
resource "azurerm_network_interface" "installer_nic" {
  name                = "${var.prefix}-installer-nic"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  ip_configuration {
    name                          = "nic_configuration"
    subnet_id                     = data.azurerm_subnet.pflex_subnet_zone1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "installer" {
  name                  = "${var.prefix}-installer-vm"
  location              = local.resource_group.location
  resource_group_name   = local.resource_group.name
  network_interface_ids = [azurerm_network_interface.installer_nic.id]
  size                  = var.vm_size.installer
  zone                  = local.availability_zones[0]

  os_disk {
    name                 = "${var.prefix}-installer-vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  plan {
    name      = var.installer_gallery_image.sku
    publisher = var.installer_gallery_image.publisher
    product   = var.installer_gallery_image.offer
  }

  source_image_id = data.azurerm_shared_image.installer_image.id

  disable_password_authentication = false
  admin_username                  = var.login_credential.username
  admin_password                  = var.login_credential.password
  admin_ssh_key {
    username   = var.login_credential.username
    public_key = file("${var.ssh_key.public}")
  }

  custom_data = base64encode(templatefile("${path.module}/init_pfmp_config.sh", {
    nodes_name      = join(",", azurerm_linux_virtual_machine.storage_instance[*].name)
    nodes_ip        = join(",", azurerm_network_interface.storage_instance_nic[*].ip_configuration.0.private_ip_address)
    lb_ip           = var.pfmp_lb_ip
    login_username  = var.login_credential.username
    login_password  = var.login_credential.password
    sshkey          = file("${var.ssh_key.private}")
    data_disk_count = local.data_disk_count
    is_multi_az     = var.cluster.is_multi_az
    is_balanced     = local.is_balanced
  }))

  extensions_time_budget = "PT2H"
}

# TODO:
# According to https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command-managed,
# it supports for long running (hours/days) scripts, but it still seems to have 90 minutes limit.
# Raised https://github.com/hashicorp/terraform-provider-azurerm/issues/27428
resource "azurerm_virtual_machine_run_command" "wait_pfmp_installation1" {
  location           = local.resource_group.location
  name               = "wait_pfmp_installation1"
  virtual_machine_id = azurerm_linux_virtual_machine.installer.id

  source {
    script = file("${path.module}/wait_pfmp_installation.sh")
  }

  timeouts {
    create = "2h"
  }
}

# The installation would take around 2 ~ 2.5hours, add a second wait to ensure the installation finishes.
resource "azurerm_virtual_machine_run_command" "wait_pfmp_installation2" {
  location           = local.resource_group.location
  name               = "wait_pfmp_installation2"
  virtual_machine_id = azurerm_linux_virtual_machine.installer.id

  source {
    script = azurerm_virtual_machine_run_command.wait_pfmp_installation1.instance_view[0].output == "true\n" ? "whoami" : file("${path.module}/wait_pfmp_installation.sh")
  }

  timeouts {
    create = "2h"
  }
}

# # https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux
# # The script is allowed 90 minutes to run. Anything longer results in a failed provision of the extension.
# resource "azurerm_virtual_machine_extension" "installer_script" {
#   name                 = "init_pfmp_config"
#   virtual_machine_id   = azurerm_linux_virtual_machine.installer.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#       "script": "${base64encode(templatefile("${path.module}/init_pfmp_config.sh", {
#   nodes_name     = "${join(",", var.nodes_name)}"
#   nodes_ip       = "${join(",", var.nodes_ip)}"
#   lb_ip          = "${var.lb_ip}"
#   login_username = "${var.login_username}"
#   login_password = "${var.login_password}"
# }))}"
#     }
# SETTINGS
# }


## Create Load Balancer
resource "azurerm_lb" "load_balancer" {
  name                = "${var.prefix}-lb"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${var.prefix}-lb-ip"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.pfmp_lb_ip
    subnet_id                     = data.azurerm_subnet.pflex_subnet_zone1.id
    zones                         = local.availability_zones
  }
}

resource "azurerm_lb_probe" "pfmp_probe" {
  loadbalancer_id     = azurerm_lb.load_balancer.id
  name                = "pfmp-probe"
  port                = 30400
  interval_in_seconds = 5
  protocol            = "Tcp"
}

resource "azurerm_lb_backend_address_pool" "lb_be_pool" {
  name            = "pfmp-pool"
  loadbalancer_id = azurerm_lb.load_balancer.id
}

resource "azurerm_lb_rule" "lb-rules" {
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "pfmp-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 30400
  frontend_ip_configuration_name = "${var.prefix}-lb-ip"
  probe_id                       = azurerm_lb_probe.pfmp_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_be_pool.id]

}

resource "azurerm_network_interface_backend_address_pool_association" "lb_be_pool_association" {
  count                   = 3
  network_interface_id    = azurerm_network_interface.storage_instance_nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.storage_instance_nic[count.index].ip_configuration.0.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_be_pool.id
}

output "sds_nodes" {
  value = [
    for i in range(var.cluster.node_count) :
    {
      "hostname" = azurerm_linux_virtual_machine.storage_instance[i].name
      "ip"       = azurerm_network_interface.storage_instance_nic[i].ip_configuration.0.private_ip_address
    }
  ]
}

output "pfmp_ip" {
  value = var.pfmp_lb_ip
}
