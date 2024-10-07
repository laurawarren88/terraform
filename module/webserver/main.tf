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

# Creates the Gateway VM
resource "vsphere_virtual_machine" "webserver_vm"{
    name                        = var.vm_name_webserver
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
    network_id   = data.vsphere_network.laura.id
    adapter_type = var.vm_adapter_type
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = var.vm_name_webserver
        domain    = var.vm_domain
      }
      network_interface {
        ipv4_netmask  = var.netmask
      }
      ipv4_gateway    = var.internal_gateway_ip
      dns_server_list = var.vm_dns_servers
    }
  }

  # Retrieve the dynamic IP from the VM
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for IP address...'"
    ]

   connection {
      type          = "ssh"
      host          = self.default_ip_address
      user          = var.user
      bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
      bastion_user  = var.user
      password      = var.password_vm
      private_key   = file("~/.ssh/id_rsa")
      timeout       = "5m"
    }
  }

  # Provisioning Steps (install packages, clone repo, etc.)
  provisioner "remote-exec" {
    inline = [
      "yum remove -y nodejs",
      "yum install -y curl git httpd",
      "curl -o nodesource_setup.sh https://rpm.nodesource.com/setup_18.x",
      "bash nodesource_setup.sh",
      "yum install nodejs -y",
      "yum install npm -y",
      "npm install -g npm@10.9.0",
      "systemctl restart httpd",
      "systemctl enable httpd"
    ]
  connection {
      type          = "ssh"
      host          = self.default_ip_address
      user          = var.user
      bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
      bastion_user  = var.user
      password      = var.password_vm
      private_key   = file("~/.ssh/id_rsa")
      timeout       = "5m"
    }
  }

# Copy SSH Public Key to the webserver VM
provisioner "remote-exec" {
  inline = [
    "mkdir -p ~/.ssh",
    "echo '${file("~/.ssh/id_rsa.pub")}' >> ~/.ssh/authorized_keys",
    "chmod 600 ~/.ssh/authorized_keys"
  ]
   connection {
      type          = "ssh"
      host          = self.default_ip_address
      user          = var.user
      bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
      bastion_user  = var.user
      password      = var.password_vm
      private_key   = file("~/.ssh/id_rsa")
      timeout       = "5m"
    }
}

# Ensure the destination directory exists
provisioner "remote-exec" {
  inline = [
    "mkdir -p /var/www/trainee_challenge",
    "chmod 0755 /var/www/trainee_challenge"
  ]
  connection {
      type          = "ssh"
      host          = self.default_ip_address
      user          = var.user
      bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
      bastion_user  = var.user
      password      = var.password_vm
      private_key   = file("~/.ssh/id_rsa")
      timeout       = "5m"
    }
}

provisioner "remote-exec" {
  inline = [
    "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"
  ]
  connection {
    type          = "ssh"
    host          = self.default_ip_address
    user          = var.user
    bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
}

provisioner "remote-exec" {
  inline = [
    "git clone git@github.com:Enterprise-Automation/trainee-challenge-node-app.git /var/www/trainee_challenge"
  ]
  connection {
    type          = "ssh"
    host          = self.default_ip_address
    user          = var.user
    bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
}

# Create .env file with necessary variables
provisioner "remote-exec" {
  inline = [
    "cat <<EOL > /var/www/trainee_challenge/.env",
    "PORT=3000",
    "TARGET_URL=\"https://jsonplaceholder.typicode.com/todos\"",
    "EOL"
  ]
 connection {
    type          = "ssh"
    host          = self.default_ip_address
    user          = var.user
    bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
}

# Install npm dependencies
provisioner "remote-exec" {
  inline = [
    "cd /var/www/trainee_challenge && npm install",
    "npm init"
  ]
 connection {
    type          = "ssh"
    host          = self.default_ip_address
    user          = var.user
    bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
}

# Ensure pm2 is installed globally
# provisioner "remote-exec" {
#   inline = [
#     "npm install -g pm2"
#   ]
#  connection {
#     type          = "ssh"
#     host          = self.default_ip_address
#     user          = var.user
#     bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
#     bastion_user  = var.user
#     password      = var.password_vm
#     private_key   = file("~/.ssh/id_rsa")
#     timeout       = "5m"
#   }
# }

# # Start the web application using pm2
# provisioner "remote-exec" {
#   inline = [
#     # "cd /var/www/trainee_challenge && pm2 start index.js --name trainee_app -f"
#     "cd /var/www/trainee_challenge && npm init"
#   ]
#   connection {
#     type          = "ssh"
#     host          = self.default_ip_address
#     user          = var.user
#     bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
#     bastion_user  = var.user
#     password      = var.password_vm
#     private_key   = file("~/.ssh/id_rsa")
#     timeout       = "5m"
#   }
# }

# Save pm2 process list to start on reboot
# provisioner "remote-exec" {
#   inline = [
#     "pm2 save"
#   ]
#   connection {
#     type          = "ssh"
#     host          = self.default_ip_address
#     user          = var.user
#     bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
#     bastion_user  = var.user
#     password      = var.password_vm
#     private_key   = file("~/.ssh/id_rsa")
#     timeout       = "5m"
#   }
# }

# Ensure pm2 restarts the app on reboot
# provisioner "remote-exec" {
#   inline = [
#     "pm2 startup systemd"
#   ]
#   connection {
#     type          = "ssh"
#     host          = self.default_ip_address
#     user          = var.user
#     bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
#     bastion_user  = var.user
#     password      = var.password_vm
#     private_key   = file("~/.ssh/id_rsa")
#     timeout       = "5m"
#   }
# }

# # # Enable pm2 to start on boot
# provisioner "remote-exec" {
#   inline = [
#     "systemctl enable pm2-root",
#     "systemctl start pm2-root"
#   ]
#   connection {
#     type          = "ssh"
#     host          = self.default_ip_address
#     user          = var.user
#     bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
#     bastion_user  = var.user
#     password      = var.password_vm
#     private_key   = file("~/.ssh/id_rsa")
#     timeout       = "5m"
#   }
# }

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
      "firewall-cmd --permanent --add-port=67/tcp",
      "firewall-cmd --permanent --add-port=67/udp",
      "firewall-cmd --reload"
    ]

    connection {
    type          = "ssh"
    host          = self.default_ip_address
    user          = var.user
    bastion_host  = var.gateway_ip # Gateway VM as the ProxyJump host
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
  }
}