variable "var__cs_code" {
  type    = string
}

variable "vm_hw" {
  type = map
  default = {
    "cpus" = 2
    "memory" = 4096
  }
}
variable "var__vm_ip" {
  type    = string
  default = ""
}


variable "ssh_public_key" {
  type        = string
  description = "Содержимое публичного ключа для авторизации"
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEiaD8cDUz4SHZkmyPAeG1VE37YUNVRHX8Uk+HzcnK7U awx-admin@template-ubuntu-nox11"
}

variable "var__vm_name" {
  type    = string
}
variable "vm_image" {
  type = map
  default =  { catalog_name = "Master", template_name = "template-ubuntu-nox11" }
}


