resource "null_resource" "ansible_hosts_avi_header_1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts_avi; echo 'all:' | tee -a hosts_avi ; echo '  children:' | tee -a hosts_avi; echo '    controller:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_controllers" {
  depends_on = [null_resource.ansible_hosts_avi_header_1]
  count            = (var.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.controller[count.index].default_ip_address}:' | tee -a hosts_avi "
  }
}


resource "null_resource" "ansible_avi" {
  depends_on = [vsphere_virtual_machine.jump, vsphere_virtual_machine.master, vsphere_virtual_machine.worker, null_resource.ansible_hosts_avi_header_1, null_resource.ansible_bootstrap_cluster]
  connection {
    host = vsphere_virtual_machine.jump.default_ip_address
    type = "ssh"
    agent = false
    user = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "file" {
    source = "hosts_avi"
    destination = "hosts_avi"
  }


  provisioner "remote-exec" {
    inline = [
      "git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag}",
      "git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag}",
      "cd ${split("/", var.ansible.aviConfigureUrl)[4]}",
      "ansible-playbook -i ../hosts_avi local.yml --extra-vars '{\"vmw\": ${jsonencode(var.vmw)}, \"avi_vsphere_password\": ${jsonencode(var.avi_vsphere_password)}, \"avi_vsphere_server\": ${jsonencode(var.avi_vsphere_server)}, \"avi_vsphere_user\": ${jsonencode(var.avi_vsphere_user)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_version\": ${split("-", var.controller.version)[0]}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.controller)}}'"
    ]
  }
}