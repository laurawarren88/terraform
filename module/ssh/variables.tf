variable "vm_ips" {
  type = map(string)
  description = "List of VM IPs"
}

variable "gateway_ip" {
  description = "Static IP for the gateway"
}

variable "user" {
  description = "The user for the VMs"
}

variable "password_vm" {
  description = "Password to access the VM"
}

variable "gateway_vm_id" {
  description = "The ID of the Gateway VM"
  type        = string
}