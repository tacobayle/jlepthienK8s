data "template_file" "jumpbox_userdata" {
  template = file("${path.module}/userdata/jump.userdata")
  vars = {
    pubkey        = file(var.jump["public_key_path"])
    avisdkVersion = var.jump["avisdkVersion"]
    ansibleVersion = var.ansible["version"]
    vsphere_user  = var.vsphere_user
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    username = var.jump["username"]
    privateKey = var.jump["private_key_path"]
  }
}

data "vsphere_virtual_machine" "jump" {
  name          = var.jump["template_name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "jump" {
  name             = var.jump["name"]
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
                      network_id = data.vsphere_network.networkMgt.id
  }

  num_cpus = var.jump["cpu"]
  memory = var.jump["memory"]
  wait_for_guest_net_timeout = var.jump["wait_for_guest_net_timeout"]
  guest_id = data.vsphere_virtual_machine.jump.guest_id
  scsi_type = data.vsphere_virtual_machine.jump.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.jump.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.jump.scsi_controller_scan_count

  disk {
    size             = var.jump["disk"]
    label            = "jump.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.jump.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.jump.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.jump.id
  }

  vapp {
    properties = {
     hostname    = "jump"
     public-keys = file(var.jump["public_key_path"])
     user-data   = base64encode(data.template_file.jumpbox_userdata.rendered)
   }
 }

  connection {
   host        = vsphere_virtual_machine.jump.default_ip_address
   type        = "ssh"
   agent       = false
   user        = var.jump.username
   private_key = file(var.jump["private_key_path"])
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }

  provisioner "file" {
    source      = var.jump["private_key_path"]
    destination = "~/.ssh/${basename(var.jump["private_key_path"])}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/${basename(var.jump.private_key_path)}"
    ]
  }
}


//resource "null_resource" "add_nic_to_jump" {
//  depends_on = [null_resource.ansible_avi, null_resource.ansible_bootstrap_cluster]
//
//  provisioner "local-exec" {
//    command = <<-EOT
//      export GOVC_USERNAME=${var.vsphere_user}
//      export GOVC_PASSWORD=${var.vsphere_password}
//      export GOVC_DATACENTER=${var.vcenter.dc}
//      export GOVC_URL=${var.vsphere_server}
//      export GOVC_CLUSTER=${var.vcenter.cluster}
//      export GOVC_INSECURE=true
//      govc vm.network.add -vm ${var.jump["name"]} -net ${var.vmw.network_vip.name}
//    EOT
//  }
//}
//
//resource "null_resource" "update_ip_to_jump" {
//  depends_on = [null_resource.add_nic_to_jump]
//
//  connection {
//    host        = vsphere_virtual_machine.jump.default_ip_address
//    type        = "ssh"
//    agent       = false
//    user        = var.jump.username
//    private_key = file(var.jump["private_key_path"])
//  }
//
//  provisioner "remote-exec" {
//    inline = [
//      "ifaceFirstName=`ip -o link show | awk -F': ' '{print $2}' | head -2 | tail -1`",
//      "macFirst=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -2 | tail -1`",
//      "ifaceLastName=`ip -o link show | awk -F': ' '{print $2}' | tail -1`",
//      "macLast=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}'| tail -1`",
//      "sudo cp ${var.jump.netplan_file_path} ${var.jump.netplan_file_path}.old",
//      "echo \"network:\" | sudo tee ${var.jump.netplan_file_path}",
//      "echo \"    ethernets:\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"        $ifaceFirstName:\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            dhcp4: false\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            addresses: [${var.jump.ip_mgmt}]\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            gateway4: ${var.jump.gw}\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            match:\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"                macaddress: $macFirst\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            set-name: $ifaceFirstName\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"        $ifaceLastName:\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            dhcp4: false\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            addresses: [${var.jump.ip_vip}/${split("/", var.vmw.network_vip.cidr)[1]}]\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            match:\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"                macaddress: $macLast\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            set-name: $ifaceLastName\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"            nameservers:\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"              addresses: [${cidrhost(var.vmw.network_vip.cidr, var.vmw.network_vip.ipStartPool)}]\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "echo \"    version: 2\" | sudo tee -a ${var.jump.netplan_file_path}",
//      "sudo netplan apply"
//    ]
//  }
//
////  provisioner "remote-exec" {
////    inline = [
////      "ifaceLastName=`ip -o link show | awk -F': ' '{print $2}' | tail -1`",
////      "sudo ip addr add ${var.jump.ip_vip}/${split("/", var.vmw.network_vip.cidr)[1]} dev $ifaceLastName"
////    ]
////  }