# Подготовка тенанта для devspace

## 1. Сети
```
git clone https://github.com/Dreyko-net/devspace_tenant.git
cd devspace_tenant/tf_network/
terraform init
terraform plan
```
Указать код клиента  
Для удаления удалить в файле network.tf строки **lifecycle { prevent_destroy = true }**


## 2. Сервер 

В файле image вписать параметры образов из виртуализации


1. GW
2. FreeIPA
3. KeyCloak
4. VPN + Radius
5. Gitea
6. S3
7. App 1C + Postgres
8. Трекер
9. AWX
10. Samba
11. Rancher (возможно на 5м пункте)