data "vsphere_datacenter" "dc" {
  name = var.vcenter.dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vcenter.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vcenter.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMgt" {
  name = var.vcenter.networkMgmt
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMaster" {
  count = length(var.vmw.kubernetes.clusters)
  name = var.vmw.kubernetes.clusters[count.index].master.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkWorker" {
  count = length(var.vmw.kubernetes.clusters) * var.vmw.kubernetes.workers.count
  name = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folder" {
  path          = var.vcenter.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

