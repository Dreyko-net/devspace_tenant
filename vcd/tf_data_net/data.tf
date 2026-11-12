locals {
  # Полное имя искомой сети, например NET-CS202-A
  net_name = "NET-${var.var__cs_code}-A"

  # Список имён сетей, найденных по маске NET-{3-5 символов}-A
  matched_names = [
    for entry in data.vcd_resource_list.nets_a.list :
    element(split(";", entry), 0)
  ]

  # Существует ли уже сеть с нужным кодом
  net_exists = contains(local.matched_names, local.net_name)

  # Разбор списка "имя;id" -> карта {id => имя}
  matched_nets = {
    for entry in data.vcd_resource_list.nets_a.list :
    element(split(";", entry), 1) => element(split(";", entry), 0)
  }

  # Все gateway существующих сетей
  gateways = [for d in data.vcd_network_isolated_v2.nets : d.gateway]

  # "172.16.20.1" -> "172.016.020.001" — для корректного лексического сравнения
  padded = sort([
    for gw in local.gateways :
    format("%03d.%03d.%03d.%03d",
      parseint(split(".", gw)[0], 10),
      parseint(split(".", gw)[1], 10),
      parseint(split(".", gw)[2], 10),
      parseint(split(".", gw)[3], 10))
  ])

  # Максимальный gateway; если сетей нет — берём дефолт
  max_gw_padded = length(local.padded) > 0 ? element(local.padded, length(local.padded) - 1) : format(
    "%03d.%03d.%03d.%03d",
    parseint(split(".", var.default_gateway)[0], 10),
    parseint(split(".", var.default_gateway)[1], 10),
    parseint(split(".", var.default_gateway)[2], 10),
    parseint(split(".", var.default_gateway)[3], 10)
  )

  o = split(".", local.max_gw_padded)

  max_gateway = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10))

  # Новый gateway: ко второму октету максимального прибавляем 2
  # 172.16.20.1 -> 172.16.22.1
  new_gateway_a = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10) + 2, parseint(local.o[3], 10))
  new_gateway_b = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10) + 2, parseint(local.o[3], 10) + 64)
  new_gateway_c = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10) + 2, parseint(local.o[3], 10) + 128)
  new_gateway_d = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10) + 3, parseint(local.o[3], 10))

  # Gateway уже существующей сети с нашим кодом (или null, если её нет)
  existing_gateway = local.net_exists ? one([
    for id, name in local.matched_nets :
    data.vcd_network_isolated_v2.nets[id].gateway
    if name == local.net_name
  ]) : null

  # Итоговое значение: существующий gateway, либо вычисленный новый
  final_gateway = local.net_exists ? local.existing_gateway : local.new_gateway_a
}


# ------------------------------------------------------------
# Поиск всех isolated-сетей по маске NET-{3-5 символов}-A
# ------------------------------------------------------------

#Собираем информацию по всем сетям "A"
data "vcd_resource_list" "nets_a" {
  name          = "nets_a"
  resource_type = "vcd_network_isolated_v2"   # или "vcd_network_routed_v2", если сети маршрутизируемые
  list_mode     = "name_id"
  name_regex    = "^NET-[^-]{3,5}-A$"
  name_id_separator = ";"
}

# ------------------------------------------------------------
# Чтение gateway каждой найденной сети
# ------------------------------------------------------------

data "vcd_network_isolated_v2" "nets" {
  for_each = local.matched_nets
  name     = each.value
}


# ------------------------------------------------------------
# Выходные значения
# ------------------------------------------------------------

output "net_exists" {
  description = "Сеть уже существует?"
  value       = local.net_exists
}

output "new_gateway_a" {
  description = "Вычисленный gateway новой сети"
  value       = local.new_gateway_a
}

