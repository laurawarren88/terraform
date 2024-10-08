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

locals  {
  # Define the common connection block
  connection_config = {
    type          = "ssh"
    host          = var.gateway_ip
    user          = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
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
    "sed -i '/GATEWAY/d' /etc/sysconfig/network-scripts/ifcfg-ens34",
    "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf",
    "sysctl -p",
    "iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE",
    "iptables-save > /etc/sysconfig/iptables",
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

# Open necessary firewall ports
provisioner "remote-exec" {
  inline = [
    "firewall-cmd --permanent --zone=public --add-masquerade",
    "firewall-cmd --permanent --zone=public --add-icmp-block-inversion",
    "firewall-cmd --permanent --add-port=80/tcp",
    "firewall-cmd --permanent --add-port=80/udp",
    "firewall-cmd --permanent --add-port=3000/tcp",
    "firewall-cmd --permanent --add-port=443/tcp",
    "firewall-cmd --reload"
  ]
  connection {
    type        = local.connection_config.type
    host        = local.connection_config.host
    user        = local.connection_config.user
    password    = local.connection_config.password
    private_key = local.connection_config.private_key
    timeout     = local.connection_config.timeout
    }
  }
}
output "gateway_vm_id" {
  value = vsphere_virtual_machine.gateway_vm.id
}