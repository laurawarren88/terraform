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
    firmware                    = var.firmware
    num_cpus                    = var.vm_cpu_n
    memory                      = var.vm_ram_mb
    guest_id                    = data.vsphere_virtual_machine.template.guest_id
    wait_for_guest_net_timeout  = 300
    disk {
        label             = var.vm_disk_label
        size              = var.vm_disk_size
        thin_provisioned  = var.vm_disk_thin
    }
    network_interface {
      network_id    = data.vsphere_network.gateway_network.id
      adapter_type  = var.vm_adapter_type
    }
    network_interface {
    network_id   = data.vsphere_network.laura.id
    adapter_type = var.vm_adapter_type
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
      }

      network_interface {
        ipv4_address  = var.internal_gateway_ip
        ipv4_netmask  = var.netmask
      }
      ipv4_gateway    = var.external_gateway_ip
      dns_server_list = var.vm_dns_servers
    }
  }
  # Use a remote-exec provisioner to fix the network config
    provisioner "remote-exec" {
    inline = [
      # Remove gateway from ens34 (internal interface)
      "sed -i '/GATEWAY/d' /etc/sysconfig/network-scripts/ifcfg-ens34",
      # Enable IP forwarding
      "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf",
      "sysctl -p",

      # Set up NAT on the gateway's external interface (ens33 assumed as external)
      "iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE",

      # Save iptables rules
      "iptables-save > /etc/sysconfig/iptables",

      # Restart services
      "systemctl restart NetworkManager"
    ]
    connection {
      type        = "ssh"
      host        = var.gateway_ip  # Use the external IP to connect
      user        = var.user
      password    = var.password_vm
      private_key = file("~/.ssh/id_rsa")
      timeout     = "5m"
    }
  }
}

# Creates the DNS and DHCP VMs
resource "vsphere_virtual_machine" "vm" {
  for_each                    = var.vms
  resource_pool_id            = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id                = data.vsphere_datastore.datastore.id
  folder                      = data.vsphere_folder.dev_folder.path
  firmware                    = var.firmware
  num_cpus                    = var.vm_cpu_n
  memory                      = var.vm_ram_mb
  guest_id                    = data.vsphere_virtual_machine.template.guest_id
  wait_for_guest_net_timeout  = 300
    disk {
    label		          = var.vm_disk_label
    size		          = var.vm_disk_size
    thin_provisioned	= var.vm_disk_thin
  }
  network_interface {
    network_id   = data.vsphere_network.laura.id
    adapter_type = var.vm_adapter_type
  }

  name = each.value.name

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = each.value.name
        domain    = var.vm_domain
      }
      network_interface {
        ipv4_address  = each.value.vm_ip
        ipv4_netmask  = var.netmask
      }
      ipv4_gateway  = var.internal_gateway_ip
      dns_server_list = var.vm_dns_servers
    }
  }
}

# resource "tls_private_key" "ssh_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }
# resource "terraform_data" "setup_ssh" {
#    provisioner "file" {
#     content = file("~/.ssh/id_rsa.pub")
#     destination = "/root/.ssh/authorized_keys"
#   connection {
#     type        = "ssh"
#     host        = var.gateway_ip
#     user        = var.user 
#     password    = var.password_vm
#     private_key = file("~/.ssh/id_rsa") 
#     timeout     = "10m"
#   }
# }
#   provisioner "remote-exec" {
#     inline = [
#       "chmod 700 /root/.ssh",
#       "chmod 600 /root/.ssh/authorized_keys",
#     ]
#   connection {
#     type        = "ssh"
#     host        = var.gateway_ip
#     user        = var.user
#     private_key = file("~/.ssh/id_rsa")
#     timeout     = "5m"
#     }
#   }
#   depends_on = [vsphere_virtual_machine.gateway_vm] # Ensure VM is created first
# }

# output "ssh_public_key" {
#   value = tls_private_key.ssh_key.public_key_openssh
# }

# Generate SSH key (same key used for multiple VMs)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Loop over the VMs to apply SSH key setup
# resource "terraform_data" "setup_ssh" {
  resource "null_resource" "setup_ssh" {
    for_each = var.vm_ips
  
  provisioner "file" {
    content     = file("~/.ssh/id_rsa.pub")
    # content     = tls_private_key.ssh_key.public_key_openssh
    destination = "/root/.ssh/authorized_keys"

    connection {
      type          = "ssh"
      host          = each.value # Host IP from the map
      user          = var.user
      bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
      bastion_user  = var.user
      password      = var.password_vm
      private_key   = file("~/.ssh/id_rsa")
      timeout       = "10m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /root/.ssh",
      "chmod 600 /root/.ssh/authorized_keys",
    ]

    connection {
      type          = "ssh"
      host          = each.value # Host IP from the map
      user          = var.user
      bastion_host  = var.gateway_ip # ProxyJump via gateway
      bastion_user  = var.user
      password      = var.password_vm
      private_key   = file("~/.ssh/id_rsa")
      timeout       = "10m"
    }
  }

  depends_on = [vsphere_virtual_machine.gateway_vm]
}

# output "ssh_public_key" {
#   value = tls_private_key.ssh_key.public_key_openssh
# }