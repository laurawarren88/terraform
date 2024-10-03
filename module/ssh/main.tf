# Generate SSH key (same key used for multiple VMs)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Loop over the VMs to apply SSH key setup
  resource "null_resource" "setup_ssh" {
    for_each = var.vm_ips
  
  provisioner "file" {
    content     = file("~/.ssh/id_rsa.pub")
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
  depends_on = [var.gateway_vm_id]
}