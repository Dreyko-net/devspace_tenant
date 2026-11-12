# Подготовка тенанта для devspace

## 1. Сети
Должны быть указаны переменные окружения, необходимые для подключения к системе виртуализации

```
git clone https://github.com/Dreyko-net/devspace_tenant.git
cd devspace_tenant/
bash setup_client.sh
```
Указать код клиента (3-5 символов)
Есть сеть отсутствует, будут созданы сети для клиента


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