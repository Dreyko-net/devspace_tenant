variable "trunk_network" {
  type    = string
  default = "Trunk-GW"
}

variable "trunk_gateway" {
  type    = string
  default = "172.16.8.1"
}

variable "trunk_prefix" {
  type    = number
  default = 22
}

variable "var__cs_code" {
  type    = string
}

variable "vm_hw" {
  type = map
  default = {
    "cpus" = 1
    "memory" = 1024
  }
}
variable "var__cs_gateway_a" {
  type    = string
  default = ""
}


variable "ssh_public_key" {
  type        = string
  description = "Содержимое публичного ключа для авторизации"
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETgvm9sT0ghbgaodR8pQexmkCum4Z4emg4XtTBsj9cX awx-admin@tmplt-rl-nox11"
}

variable "var__vm_name" {
  type    = string
}
variable "vm_image" {
  type = map
  default =  { catalog_name = "Master", template_name = "template-gw" }
}

## Расчёт ip адреса на основе var__cs_gateway_a
locals {
  o = split(".", var.var__cs_gateway_a)

  ip_net_a = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10) + 1)
  ip_net_b = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10) + 65)
  ip_net_c = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10) + 129)
  ip_net_d = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10) + 1, parseint(local.o[3], 10) + 1)

}