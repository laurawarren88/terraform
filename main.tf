provider "vsphere" {
    user                    = var.vcenter_username
    password                = var.vcenter_password 
    vsphere_server          = var.vcenter_server 
    allow_unverified_ssl    = true
}

module "gateway_vm" {
  source                  = "./module/gateway"
  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_compute_cluster = var.vsphere_compute_cluster
  vsphere_host            = var.vsphere_host
  gateway_network         = var.gateway_network
  internal_network        = var.internal_network
  folder_path             = var.folder_path
  template_name           = var.template_name
  vm_name_gateway         = var.vm_name_gateway
  firmware                = var.firmware
  vm_cpu_n                = var.vm_cpu_n
  vm_ram_mb               = var.vm_ram_mb
  vm_disk_label           = var.vm_disk_label
  vm_disk_size            = var.vm_disk_size
  vm_disk_thin            = var.vm_disk_thin
  vm_adapter_type         = var.vm_adapter_type
  vm_domain               = var.vm_domain
  gateway_ip              = var.gateway_ip
  internal_gateway_ip     = var.internal_gateway_ip
  netmask                 = var.netmask
  external_gateway_ip     = var.external_gateway_ip
  vm_dns_servers          = var.vm_dns_servers
  user                    = var.user
  password_vm             = var.password_vm
}

module "dns_vm" {
  source                  = "./module/dns"
  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_compute_cluster = var.vsphere_compute_cluster
  vsphere_host            = var.vsphere_host
  gateway_network         = var.gateway_network
  internal_network        = var.internal_network
  folder_path             = var.folder_path
  template_name           = var.template_name
  vm_name_dns             = var.vm_name_dns
  firmware                = var.firmware
  vm_cpu_n                = var.vm_cpu_n
  vm_ram_mb               = var.vm_ram_mb
  vm_disk_label           = var.vm_disk_label
  vm_disk_size            = var.vm_disk_size
  vm_disk_thin            = var.vm_disk_thin
  vm_adapter_type         = var.vm_adapter_type
  vm_domain               = var.vm_domain
  dns_ip                  = var.dns_ip
  netmask                 = var.netmask
  internal_gateway_ip     = var.internal_gateway_ip
  vm_dns_servers          = var.vm_dns_servers
  user                    = var.user
  password_vm             = var.password_vm
  gateway_ip              = var.gateway_ip
}

module "dhcp_vm" {
  source                  = "./module/dhcp"
  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_compute_cluster = var.vsphere_compute_cluster
  vsphere_host            = var.vsphere_host
  gateway_network         = var.gateway_network
  internal_network        = var.internal_network
  folder_path             = var.folder_path
  template_name           = var.template_name
  vm_name_dhcp            = var.vm_name_dhcp
  firmware                = var.firmware
  vm_cpu_n                = var.vm_cpu_n
  vm_ram_mb               = var.vm_ram_mb
  vm_disk_label           = var.vm_disk_label
  vm_disk_size            = var.vm_disk_size
  vm_disk_thin            = var.vm_disk_thin
  vm_adapter_type         = var.vm_adapter_type
  vm_domain               = var.vm_domain
  dhcp_ip                 = var.dhcp_ip
  netmask                 = var.netmask
  internal_gateway_ip     = var.internal_gateway_ip
  vm_dns_servers          = var.vm_dns_servers
  user                    = var.user
  password_vm             = var.password_vm
  gateway_ip              = var.gateway_ip
}

# Setup SSH Keys
module "ssh_setup" {
  source        = "./module/ssh"
  vm_ips        = var.vm_ips
  user          = var.user
  gateway_ip    = var.gateway_ip
  password_vm   = var.password_vm
  gateway_vm_id = module.gateway_vm.gateway_vm_id
}

module "webserver_vm" {
  source                  = "./module/webserver"
  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_compute_cluster = var.vsphere_compute_cluster
  vsphere_host            = var.vsphere_host
  gateway_network         = var.gateway_network
  internal_network        = var.internal_network
  folder_path             = var.folder_path
  template_name           = var.template_name
  vm_name_webserver       = var.vm_name_webserver
  firmware                = var.firmware
  vm_cpu_n                = var.vm_cpu_n
  vm_ram_mb               = var.vm_ram_mb
  vm_disk_label           = var.vm_disk_label
  vm_disk_size            = var.vm_disk_size
  vm_disk_thin            = var.vm_disk_thin
  vm_adapter_type         = var.vm_adapter_type
  vm_domain               = var.vm_domain
  netmask                 = var.netmask
  internal_gateway_ip     = var.internal_gateway_ip
  vm_dns_servers          = var.vm_dns_servers
  user                    = var.user
  password_vm             = var.password_vm
  gateway_ip              = var.gateway_ip
}