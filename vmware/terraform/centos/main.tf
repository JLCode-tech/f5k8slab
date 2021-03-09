provider "vsphere" {
  vsphere_server = var.vsphere_vcenter
  user           = var.vsphere_user
  password       = var.vsphere_password

  allow_unverified_ssl = var.vsphere_unverified_ssl
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_port_group
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_tag_category" "category" {
  name = var.vsphere_tag_category
}
data "vsphere_tag" "tag" {
  name        = var.vsphere_tag_name
  category_id = data.vsphere_tag_category.category.id
}
data "vsphere_resource_pool" "target-resource-pool" {
  name          = "${var.vsphere_cluster}/Resources/${var.resource_pool_designator}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}