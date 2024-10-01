provider "vsphere" {
    user                    = var.vcenter_username
    password                = var.vcenter_password 
    vsphere_server          = var.vcenter_server 
    allow_unverified_ssl    = true
}

data "vsphere_datacenter" "dc" {
    name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
    name            = var.vsphere_datastore
    datacenter_id   = data.vsphere_datacenter.dc.id 
}

data "vsphere_compute_cluster" "cluster" {
    name            = var.vsphere_compute_cluster 
    datacenter_id   = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "gateway_network" {
    name          = var.gateway_network
    datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "laura" {
    name          = var.internal_network
    datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Local OVF/OVA Source
# data "vsphere_ovf_vm_template" "ovfLocal" {
#   name              = "CentOS9_test"
#   resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id      = data.vsphere_datastore.datastore.id
#   host_system_id    = data.vsphere_host.host.id
#   local_ovf_path    = "/Users/laurawarren/Downloads/CentOS9_test.ovf"
#   ovf_network_map = {
#     "VM Network" : data.vsphere_network.gateway_network.id
#   }
# } 

# Where the VMs will be stored
data "vsphere_folder" "dev_folder" {
    path = var.folder_path
}

# Creates the Gateway VM
resource "vsphere_virtual_machine" "gateway_vm"{
    name                        = var.vm_name_gateway 
    resource_pool_id            = data.vsphere_compute_cluster.cluster.resource_pool_id
    datastore_id                = data.vsphere_datastore.datastore.id
    folder                      = data.vsphere_folder.dev_folder.path
    # firmware                    = var.firmware
    num_cpus                    = var.vm_cpu_n
    memory                      = var.vm_ram_mb
    guest_id                    = data.vsphere_virtual_machine.template.guest_id
    
#     dynamic "network_interface" {
#         for_each = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
#         content {
#             network_id = network_interface.value
#     }
#   }

    wait_for_guest_net_timeout  = 0

#     ovf_deploy {
#         allow_unverified_ssl_cert = false
#         local_ovf_path            = data.vsphere_ovf_vm_template.ovfLocal.local_ovf_path
#         disk_provisioning         = data.vsphere_ovf_vm_template.ovfLocal.disk_provisioning
#         ovf_network_map           = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
#   }

    disk {
        label             = var.vm_disk_label
        size              = var.vm_disk_size
        thin_provisioned  = var.vm_disk_thin
    }

    network_interface {
      network_id    = data.vsphere_network.gateway_network.id
      adapter_type  = data.vsphere_virtual_machine.template.network_interface_types[0]
    }

    network_interface {
    network_id   = data.vsphere_network.laura.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vm_name_gateway
        domain    = var.vm_domain
      }

      network_interface {
        ipv4_address    = var.gateway_ip
        ipv4_netmask    = var.netmask
        dns_server_list	= var.vm_dns_servers
      }

      network_interface {
        ipv4_address = var.internal_gateway_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.external_gateway_ip
    }
  }
}

#Creates the DNS and DHCP VMs
# resource "vsphere_virtual_machine" "vm" {
#   for_each         = var.vms
 
#   resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id     = data.vsphere_datastore.datastore.id
#   guest_id         = data.vsphere_virtual_machine.template.guest_id
#   folder           = data.vsphere_folder.dev_folder.path
  
#   network_interface {
#     network_id   = data.vsphere_network.laura.id
#     adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
#   }

#   name             = each.value.name

#   num_cpus         = var.vm_cpu_n
#   memory           = var.vm_ram_mb
# #   firmware         = var.firmware
#   disk {
#     label		          = var.vm_disk_label
#     size		          = var.vm_disk_size
#     thin_provisioned	= var.vm_disk_thin
#   }
#   clone {
#     template_uuid = data.vsphere_virtual_machine.template.id
#     customize {
#       linux_options {
#         host_name = each.value.name
#         domain    = var.vm_domain
#       }
#       network_interface {
#         ipv4_address  = each.value.vm_ip
#         ipv4_netmask  = var.netmask
#       }

#       ipv4_gateway = var.internal_gateway_ip
#     }
#   }
# }
