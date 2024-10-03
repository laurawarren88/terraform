# Infrastructure - vCenter / vSPhere environment
variable "vsphere_datacenter" {
  description = "vSphere datacenter in which the VMs will be deployed"
} 

variable "vsphere_datastore" {
  description = "Datastore in which the VMs will be deployed"
}

variable "vsphere_compute_cluster" {
  description = "vSPhere cluster in which the VMs will be deployed"
}

variable "vsphere_host" {
  description = "vSPhere host in which the VMs will be deployed"
}

variable "gateway_network" {
  description = "Portgroup to which the gateway VM will be connected"
}

variable "internal_network" {
  description = "Portgroup to which the DNS & DHCP VM will be connected"
}

variable "template_name" {
  description = "Name of template the VMs will be built from"
}

variable "folder_path" {
  description = "Where the VMs, once created, will be stored"
}

variable "vms" {
  type = map(any)
  description = "List of virtual machines to be deployed"
}

variable "firmware" {
  description = "Firmware of virtual machine, if templates is different from default"
}

variable "vm_cpu_n" {
  description = "The number of virtual processors to assign to this virtual machine."
    type = number
}

variable "vm_ram_mb" {
  description = "The size of the virtual machine's memory in MB"
  type = number
}

variable "vm_disk_label" {
  description = "Disk label of the created virtual machine"
}

variable "vm_disk_size" {
  description = "Disk size of the created virtual machine in GB"
  type = number
}

variable "vm_disk_thin" {
  description = "Disk type of the created virtual machine , thin or thick"
  type = bool
}

variable "vm_adapter_type" {
  description = "Adapter used to setup the network"
}

variable "vm_domain" {
  description = "Domain name of VM"
}

variable "netmask" {
  description = "The IPv4 subnet mask"
  type = number
}

variable "internal_gateway_ip" {
  description = "IP for the internal gateway to connect"
}

variable "vm_dns_servers" {
  description = "The list of DNS servers to configure on the virtual machine"
}