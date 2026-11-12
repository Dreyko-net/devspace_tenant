resource "vcd_vapp_vm" "vm_freeipa" {

  vapp_name     = var.vapp_name
  name          = var.vm_name
  computer_name = var.vm_name
  power_on      = true

  cpus = var.vm_hw["cpus"]
  memory = var.vm_hw["memory"]

  catalog_name  = var.vm_image["catalog_name"]
  template_name = var.vm_image["template_name"]

  network {
    name = var.network_name
    type = "org"
    ip_allocation_mode = "DHCP"
    is_primary = true
  }

  customization {
    initscript = <<-EOF
#!/bin/bash

if [ "$1" = "postcustomization" ]; then

  mkdir -p /home/awx-admin/.ssh
  echo "${var.ssh_public_key}" >> /home/awx-admin/.ssh/authorized_keys
  chown -R awx-admin:awx-admin /home/awx-admin/.ssh
  chmod 700 /home/awx-admin/.ssh
  chmod 600 /home/awx-admin/.ssh/authorized_keys

fi
EOF

  }

}