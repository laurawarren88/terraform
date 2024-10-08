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
    host          = var.dns_ip 
    user          = var.user
    bastion_host  = var.gateway_ip
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
}

# Creates the DNS and DHCP VMs
resource "vsphere_virtual_machine" "vm" {
  name                        = var.vm_name_dns
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

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = var.vm_name_dns
        domain    = var.vm_domain
      }
      network_interface {
        ipv4_address  = var.dns_ip
        ipv4_netmask  = var.netmask
      }
      ipv4_gateway    = var.internal_gateway_ip
      dns_server_list = var.vm_dns_servers
    }
  }

# Set hostname
provisioner "remote-exec" {
  inline = [
    "hostnamectl set-hostname ${var.vm_domain}"
  ]
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

# Add 127.0.0.1 and other entries to /etc/hosts
provisioner "file" {
  content     = <<EOF
    127.0.0.1 lmw.local localhost
    10.0.0.3 lmw.local
    ::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
    EOF
  destination = "/etc/hosts"
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

# Install BIND DNS
provisioner "remote-exec" {
  inline = [
    "yum install bind -y"
  ]
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}
  
provisioner "file" {
  content     = file("${path.module}/templates/named.tftpl")
  destination = "/etc/named.conf"
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

# Add forward and reverse zone templates
provisioner "file" {
  source      = "${path.module}/templates/fwd.zone.tftpl"
  destination = "/var/named/fwd.lmw.local"
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

provisioner "file" {
  source      = "${path.module}/templates/rev.zone.tftpl"
  destination = "/var/named/rev.lmw.local"
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

# Restart and enable the named service
provisioner "remote-exec" {
  inline = [
    "systemctl restart named",
    "systemctl enable named"
  ]
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

# Open necessary firewall ports
provisioner "remote-exec" {
  inline = [
    "firewall-cmd --permanent --add-port=53/tcp",
    "firewall-cmd --permanent --add-port=53/udp",
    "firewall-cmd --permanent --add-port=22/tcp",
    "firewall-cmd --permanent --add-port=80/tcp",
    "firewall-cmd --permanent --add-port=80/udp",
    "firewall-cmd --permanent --add-port=3000/tcp",
    "firewall-cmd --permanent --add-port=443/tcp",
    "firewall-cmd --reload"
  ]
  connection {
    type          = local.connection_config.type
    host          = local.connection_config.host
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
    }
  }
}