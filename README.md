##Подготовка тенанта для devspace

#1. Сети
```
git clone https://github.com/Dreyko-net/devspace_tenant.git
cd devspace_tenant/tf_network/
terraform init
terraform plan
```
Указать код клиента  
Для удаления удалить в файле network.tf строки **lifecycle { prevent_destroy = true }**


#2. Сервера