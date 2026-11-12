
variable "var__cs_gateway_a" {
  type    = string
}

variable "var__cs_code" {
  type    = string
}

locals {
  o = split(".", var.var__cs_gateway_a)

  new_gateway_a = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10))
  new_gateway_b = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10) + 64)
  new_gateway_c = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10), parseint(local.o[3], 10) + 128)
  new_gateway_d = format("%d.%d.%d.%d",
    parseint(local.o[0], 10), parseint(local.o[1], 10),
    parseint(local.o[2], 10) + 1, parseint(local.o[3], 10))

}