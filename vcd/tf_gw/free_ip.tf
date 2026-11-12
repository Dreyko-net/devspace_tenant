# ------------------------------------------------------------
# Список всех VM в VDC: формат "org;vdc;vapp;vm"
# ------------------------------------------------------------

data "vcd_resource_list" "all_vms" {
  name              = "all_vms"
  resource_type     = "vcd_all_vm"
  list_mode         = "name_id"
  name_id_separator = ";"
}

locals {
  trunk_cidr = cidrsubnet("${var.trunk_gateway}/${var.trunk_prefix}", 0, 0)

  # VM внутри vApp: "org;vdc;vapp;vm"
  vm_map = {
    for entry in data.vcd_resource_list.all_vms.list :
    "${element(split(";", entry), 2)}::${element(split(";", entry), 3)}" => {
      vapp = element(split(";", entry), 2)
      vm   = element(split(";", entry), 3)
    }
    if element(split(";", entry), 2) != ""
  }

  # Standalone-VM: "org;vdc;;vm" — vApp пустая
  standalone_map = {
    for entry in data.vcd_resource_list.all_vms.list :
    element(split(";", entry), 3) => element(split(";", entry), 3)
    if element(split(";", entry), 2) == ""
  }

  # Безопасные списки сетей: null -> []
  vapp_networks = {
    for k, d in data.vcd_vapp_vm.vms : k => (d.network != null ? d.network : [])
  }
  standalone_networks = {
    for k, d in data.vcd_vm.standalone : k => (d.network != null ? d.network : [])
  }

  # Занятые IP в Trunk-GW: из vApp-VM ...
  used_ips_vapp = toset(flatten([
    for _, nets in local.vapp_networks :
    [
      for n in nets :
      n.ip
      if n.name == var.trunk_network && n.ip != null && n.ip != ""
    ]
  ]))

  # ... и из standalone-VM
  used_ips_standalone = toset(flatten([
    for _, nets in local.standalone_networks :
    [
      for n in nets :
      n.ip
      if n.name == var.trunk_network && n.ip != null && n.ip != ""
    ]
  ]))

  used_ips = setunion(local.used_ips_vapp, local.used_ips_standalone)

  # Все usable-адреса /22 без сети и broadcast
  all_usable = [
    for i in range(1, pow(2, 32 - var.trunk_prefix) - 1) :
    cidrhost(local.trunk_cidr, i)
  ]

  # Список всех свободных адресов (шлюз исключён)
  free_ips = [
    for ip in local.all_usable :
    ip
    if !contains(local.used_ips, ip) && ip != var.trunk_gateway
  ]

  # Первый свободный; если список пуст (сеть забита) — ошибка плана
  free_ip = length(local.free_ips) > 0 ? element(local.free_ips, 0) : null

}

# ------------------------------------------------------------
# Чтение vApp-VM
# ------------------------------------------------------------

data "vcd_vapp_vm" "vms" {
  for_each  = local.vm_map
  name      = each.value.vm
  vapp_name = each.value.vapp
}

# ------------------------------------------------------------
# Чтение standalone-VM
# ------------------------------------------------------------

data "vcd_vm" "standalone" {
  for_each = local.standalone_map
  name     = each.value
}

###local.free_ip