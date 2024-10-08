locals  {
  # Define the common connection block
  connection_config = {
    type          = "ssh"
    user          = var.user
    bastion_host  = var.gateway_ip
    bastion_user  = var.user
    password      = var.password_vm
    private_key   = file("~/.ssh/id_rsa")
    timeout       = "5m"
  }
}

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
    type          = local.connection_config.type
    host          = each.value # Host IP from the map
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
  }
}

provisioner "remote-exec" {
  inline = [
    "chmod 700 /root/.ssh",
    "chmod 600 /root/.ssh/authorized_keys",
  ]
  connection {
    type          = local.connection_config.type
    host          = each.value # Host IP from the map
    user          = local.connection_config.user
    bastion_host  = local.connection_config.bastion_host
    bastion_user  = local.connection_config.bastion_user
    password      = local.connection_config.password
    private_key   = local.connection_config.private_key
    timeout       = local.connection_config.timeout
    }
  }
  depends_on = [var.gateway_vm_id]
}