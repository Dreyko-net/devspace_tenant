# ------------------------------------------------------------
# Создание сети — только если сети с нужным кодом ещё нет
# ------------------------------------------------------------

resource "vcd_network_isolated_v2" "cs_net_a" {
  count   = local.net_exists ? 0 : 1
  name    = "NET-${var.var__cs_code}-A"
  gateway = local.new_gateway_a
  prefix_length = 26
  lifecycle { prevent_destroy = true }
}

resource "vcd_network_isolated_v2" "cs_net_b" {
  count   = local.net_exists ? 0 : 1
  name    = "NET-${var.var__cs_code}-B"
  gateway = local.new_gateway_b
  prefix_length = 26
  lifecycle { prevent_destroy = true }
}

resource "vcd_network_isolated_v2" "cs_net_c" {
  count   = local.net_exists ? 0 : 1
  name    = "NET-${var.var__cs_code}-C"
  gateway = local.new_gateway_c
  prefix_length = 25
  lifecycle { prevent_destroy = true }
}

resource "vcd_network_isolated_v2" "cs_net_d" {
  count   = local.net_exists ? 0 : 1
  name    = "NET-${var.var__cs_code}-D"
  gateway = local.new_gateway_d
  prefix_length = 24
  lifecycle { prevent_destroy = true }
}