
data "vsphere_datacenter" "dc" {
    name = var.datacenter_name
}

data "vsphere_datastore" "datastore" {
    name            = var.vsphere_datastore
    datacenter_id   = data.vsphere_datacenter.dc.id 
}

data "vsphere_compute_cluster" "cluster" {
    name            = var.vsphere_cluster 
    datacenter_id   = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "gateway_network" {
    name = var.gateway_network
    datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "laura" {
    name = var.internal_network
    datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Where the VMs will be stored - already created above
data "vsphere_folder" "dev_folder" {
    path = var.folder_path
}

# Creates the VM
resource "vsphere_virtual_machine" "gateway_vm"{
    name = var.vm_name_gateway 
    resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
    datastore_id = data.vsphere_datastore.datastore.id
    folder = data.vsphere_folder.dev_folder.path
    firmware = "efi"
    num_cpus = var.vm_cpu_n
    memory = var.vm_ram_mb
    guest_id = data.vsphere_virtual_machine.template.guest_id
    wait_for_guest_net_timeout = 0

    disk {
        label = "disk0"
        size = 40
        thin_provisioned = true
    }

    network_interface {
      network_id = data.vsphere_network.gateway_network.id
      adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
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
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.internal_gateway_ip
        ipv4_netmask = var.netmask
      }

      network_interface {
        ipv4_address = var.gateway_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.external_gateway_ip
    }
  }
}

resource "vsphere_virtual_machine" "dns_vm" {
  name             = var.vm_name_dns
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.vm_cpu_n
  memory           = var.vm_ram_mb
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  folder           = data.vsphere_folder.dev_folder.path

  network_interface {
    network_id   = data.vsphere_network.laura.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vm_name_dns
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.dns_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.external_gateway_ip
    }
  }
}

resource "vsphere_virtual_machine" "dhcp_vm" {
  name             = var.vm_name_dhcp
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.vm_cpu_n
  memory           = var.vm_ram_mb
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  folder           = data.vsphere_folder.dev_folder.path

  network_interface {
    network_id   = data.vsphere_network.laura.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vm_name_dhcp
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.dhcp_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.external_gateway_ip
    }
  }
}
