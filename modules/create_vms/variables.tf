variable "datacenter_name" {
  default = "Development"
} 

variable "folder_path" {
  default = "Development/vm/Laura"
}

variable "vsphere_datastore" {
  default = "VM_STORAGE"
}

variable "vsphere_cluster" {
  default = "EAS-DEV"
}

variable "gateway_network" {
  default = "VM Network"
}

variable "internal_network" {
  default = "Laura"
}

variable "template_name" {
  default = "CentOS8_Blank"
}

variable "vm_name_gateway" {
    default = "gatewaytf"
}

variable "vm_ram_mb" {
    default = "2048"
}

variable "vm_cpu_n" {
    default = "2"
}

variable "domain" {
  default = "lmw.local"
}

variable "internal_gateway_ip" {
  default = "10.0.0.1"
}

variable "netmask" {
  default = "24"
}

variable "gateway_ip" {
  default = "172.16.6.193"
}

variable "external_gateway_ip" {
  default = "172.16.0.1"
}

variable "vm_name_dns" {
  default = "dnstf"
}

variable "dns_ip" {
  default = "10.0.0.3"
}

variable "vm_name_dhcp" {
  default = "dhcptf"
}

variable "dhcp_ip" {
  default = "10.0.0.2"
}

