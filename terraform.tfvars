# Variables for vsphere
vsphere_datacenter  = "Development"
vsphere_datastore   = "VM_STORAGE"

# VM variables for all
gateway_network = "VM Network"
template_name   = "CentOS9_Blank"
firmware        = "efi"
vm_cpu_n        = 2
vm_ram_mb       = 2048
vm_disk_label   = "disk0"
vm_disk_size    = 50
vm_disk_thin    = true
vm_domain       = "lmw.local"
vm_adapter_type = "vmxnet3" 
netmask         = 24

# SSH variables
user = "root"

# Gateway specific variables
vm_name_gateway     = "gatewaytf"
gateway_ip          = "172.16.6.193"
internal_gateway_ip = "10.0.0.1"
external_gateway_ip = "172.16.0.1"
vm_dns_servers      = ["8.8.8.8", "8.8.4.4"]

# Variables for DNS
vm_name_dns           = "dnstf"
dns_ip                = "10.0.0.3"

# Variables for DHCP
vm_name_dhcp  = "dhcptf"
dhcp_ip       = "10.0.0.2"

vm_ips = {
  gateway_ip = "172.16.6.193"
  dns_ip     = "10.0.0.3"
  dhcp_ip    = "10.0.0.2"
}

# webserver variables
vm_name_webserver = "webservertf"

vcenter_username        = "laura@easlab.co.uk"
vcenter_password        =  "Renegade187!"
vcenter_server          = "vcenter.easlab.co.uk"
password_vm             = "Renegade187!"
vsphere_compute_cluster = "EAS-DEV"
vsphere_host            = "dev-esxi1.dev.easlab.co.uk"
internal_network        = "Laura"
folder_path             = "Development/vm/Laura"