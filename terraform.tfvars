# Variables for vsphere
vsphere_datacenter = "Development"
vsphere_datastore = "VM_STORAGE"
vsphere_compute_cluster = "EAS-DEV"
vsphere_host = "dev-esxi1.dev.easlab.co.uk"

# VM variables for all
gateway_network = "VM Network"
internal_network = "Laura"
template_name = "CentOS9_Blank"
folder_path = "Development/vm/Laura"
firmware = "uefi"
vm_cpu_n = 2
vm_ram_mb = 2048
vm_disk_label  = "disk0"
vm_disk_size  = 50
vm_disk_thin = true
netmask = 24
vm_domain = "lmw.local"

# local_ovf_path = "/Users/laurawarren/Downloads/CentOS9_test.ovf"

# Gateway specific variables
vm_name_gateway = "gatewaytf"
gateway_ip = "172.16.6.193"
internal_gateway_ip = "10.0.0.1"
external_gateway_ip = "172.16.0.1"
vm_dns_servers = ["8.8.8.8", "8.8.4.4"]

# Variables for internal VMs
# vms = {
#   dns_vm  = {
#     name  = "dnstf"
#     vm_ip = "10.0.0.3"
#   },
#   dhcp_vm   = {
#     name    = "dhcptf"
#     vm_ip   = "10.0.0.2"
#   }
# }