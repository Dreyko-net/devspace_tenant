resource "vcd_vm" "vm_gw" {

  name          = var.var__vm_name
  computer_name = var.var__vm_name
  power_on      = true

  cpus = var.vm_hw["cpus"]
  memory = var.vm_hw["memory"]

  catalog_name  = var.vm_image["catalog_name"]
  template_name = var.vm_image["template_name"]

  network {
    type               = "org"
    name               = var.trunk_network
    is_primary         = true
    ip_allocation_mode = "MANUAL"
    ip                 = local.free_ip
  }
  lifecycle {
    ignore_changes = [
      network[0].ip,          # игнорируем изменение IP первого NIC
    ]
  }
  customization {
    initscript = <<-EOF
#!/bin/bash

if [ "$1" = "postcustomization" ]; then

  # Проверяем, существует ли пользователь. Если нет — создаём
  if ! id -u awx-admin >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" awx-admin
  fi
  # Добавляем пользователя в группу sudo (если ещё не добавлен)
  usermod -aG sudo awx-admin
  # Разрешаем awx-admin выполнять sudo без пароля
  echo "awx-admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/awx-admin
  chmod 0440 /etc/sudoers.d/awx-admin

  mkdir -p /home/awx-admin/.ssh
  echo "${var.ssh_public_key}" >> /home/awx-admin/.ssh/authorized_keys
  chown -R awx-admin:awx-admin /home/awx-admin/.ssh
  chmod 700 /home/awx-admin/.ssh
  chmod 600 /home/awx-admin/.ssh/authorized_keys

fi
EOF

  }

}