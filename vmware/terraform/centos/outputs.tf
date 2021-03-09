output "masterIPAddress" {
  value = var.vsphere_ipv4_address
}

output "nodeIPAddresses" {
  value = vsphere_virtual_machine.k8snode.*.default_ip_address
}