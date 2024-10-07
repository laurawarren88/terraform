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

# Where the VMs will be stored
data "vsphere_folder" "dev_folder" {
  path = var.folder_path
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Creates the DNS and DHCP VMs
resource "vsphere_virtual_machine" "vm" {
  name                        = var.vm_name_dhcp
  resource_pool_id            = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id                = data.vsphere_datastore.datastore.id
  folder                      = data.vsphere_folder.dev_folder.path
  firmware                    = var.firmware
  num_cpus                    = var.vm_cpu_n
  memory                      = var.vm_ram_mb
  guest_id                    = data.vsphere_virtual_machine.template.guest_id
  wait_for_guest_net_timeout  = 300
    disk {
    label		     = var.vm_disk_label
    size		     = var.vm_disk_size
    thin_provisioned = var.vm_disk_thin
  }
  network_interface {
    network_id   = data.vsphere_network.laura.id
    adapter_type = var.vm_adapter_type
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = var.vm_name_dhcp
        domain    = var.vm_domain
      }
      network_interface {
        ipv4_address  = var.dhcp_ip
        ipv4_netmask  = var.netmask
      }
      ipv4_gateway    = var.internal_gateway_ip
      dns_server_list = var.vm_dns_servers
    }
  }
}