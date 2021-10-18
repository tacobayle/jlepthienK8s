# Outputs for Terraform

output "master" {
  value = vsphere_virtual_machine.master.*.default_ip_address
}

output "workers" {
  value = vsphere_virtual_machine.worker.*.default_ip_address
}

output "jump" {
  value = vsphere_virtual_machine.jump.default_ip_address
}

output "client" {
  value = split("/", var.client.ip_mgmt)[0]
}

output "controllers" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "avi_password" {
  value = var.avi_password
  description = "avi_password"
}

output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.jump.private_key_path)} -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'cd ${split("/", var.ansible.aviPbAbsentUrl)[4]} ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve"
  description = "command to destroy the infra"
}

output "ako_install" {
  value = "helm --debug install ako/ako --generate-name --version ${var.vmw.kubernetes.clusters[0].ako.version} -f values.yml --namespace=${var.vmw.kubernetes.clusters[0].ako.namespace} --set avicredentials.username=admin --set avicredentials.password=$avi_password"
}