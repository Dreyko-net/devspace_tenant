#!/usr/bin/env bash
set -euo pipefail

# Действие 0. Ввод данных от пользователя
client_code=""
while [[ ! "${client_code}" =~ ^[A-Z0-9]{3,5}$ ]]; do
  read -r -p "Введите client_code (3-5 символов, A-Z и 0-9): " client_code
  if [[ ! "${client_code}" =~ ^[A-Z0-9]{3,5}$ ]]; then
    echo "Некорректно: '$client_code'. Нужно 3-5 символов, только заглавные буквы A-Z и цифры 0-9." >&2
  fi
done

# Выбор действия
echo "Что сделать?"
echo "  1) Создать  [по умолчанию]"
echo "  2) Удалить"
read -r -p "Выбор [1]: " choice
choice="${choice:-1}"

case "$choice" in
  1) action="create"  ;;
  2) action="destroy" ;;
  *) echo "ERROR: неверный выбор: '$choice'. Допустимо: 1 или 2" >&2; exit 2 ;;
esac

# Действие 1. Определяем систему виртуализации
virt_system=""
if [[ -n "${VCD_ORG:-}" ]]; then
  virt_system="vcd"
elif [[ -n "${OS_USERNAME:-}" ]]; then
  virt_system="vkcs"
fi

if [[ -z "$virt_system" ]]; then
  echo "ERROR: не заданы переменные окружения для подключения к системе виртуализации" >&2
  exit 1
fi

# Действие 2. Проверяем существование сетей и получаем значения из плана
terraform -chdir="$virt_system/tf_data_net" init
terraform -chdir="$virt_system/tf_data_net" plan \
  -var "var__cs_code=${client_code^^}" \
  -out=tfplan.bin

net_exists=$(terraform -chdir="$virt_system/tf_data_net" show -json tfplan.bin \
  | python3 -c 'import sys, json; v=json.load(sys.stdin)["planned_values"]["outputs"]["net_exists"]["value"]; print("true" if v else "false")')

final_gateway=$(terraform -chdir="$virt_system/tf_data_net" show -json tfplan.bin \
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["planned_values"]["outputs"]["final_gateway"]["value"])')

rm -f "$virt_system/tf_data_net/tfplan.bin"

# Действие 3. Если сетей клиента нет, то создаём сети. Если есть и выбрано удаление, то удаляем.
if [[ "$net_exists" == "true" ]]; then
  if [[ "$action" == "destroy" ]]; then
    echo "Удаляем инфраструктуру клиента: ${client_code^^}. Для действий требуется ручное подтверждение."
    #Удаляем сервера по очереди
    # terraform -chdir="$virt_system/tf_gw" init
    # terraform -chdir="$virt_system/tf_gw" destroy \
    # -var "var__cs_code=${client_code^^}" \
    # -var "var__vm_name=gw.${client_code,,}.devspace.lan" \
    # -var "var__cs_gateway_a=$final_gateway"

    terraform -chdir="$virt_system/tf_idm" init
    terraform -chdir="$virt_system/tf_idm" destroy \
        -var "var__cs_code=${client_code^^}" \
        -var "var__vm_name=idm.${client_code,,}.devspace.lan" 
    
    terraform -chdir="$virt_system/tf_idp" init
    terraform -chdir="$virt_system/tf_idp" destroy \
        -var "var__cs_code=${client_code^^}" \
        -var "var__vm_name=idp.${client_code,,}.devspace.lan"

    terraform -chdir="$virt_system/tf_app" init
    terraform -chdir="$virt_system/tf_app" destroy \
        -var "var__cs_code=${client_code^^}" \
        -var "var__vm_name=app-01.${client_code,,}.devspace.lan"    
    
    #Удаление сетей.
    terraform -chdir="$virt_system/tf_network" init
    terraform -chdir="$virt_system/tf_network" destroy \
        -var "var__cs_code=${client_code^^}" 
    exit 0
  else
    echo "Сети для такого клиента существуют. Дальнейшие действия с сетями не требуются."
  fi  
  
else
  echo "Создаём сети для нового клиента. Для действий требуется ручное подтверждение."
  terraform -chdir="$virt_system/tf_network" init
  terraform -chdir="$virt_system/tf_network" apply \
    -var "var__cs_code=${client_code^^}" \
    -var "var__cs_gateway_a=$final_gateway"
fi

# Действие 4. Создание серверов
# 4.1 GW

# echo "Создаём сервер GW для нового клиента. Для действий требуется ручное подтверждение."
# terraform -chdir="$virt_system/tf_gw" init
# terraform -chdir="$virt_system/tf_gw" apply \
#     -var "var__cs_code=${client_code^^}" \
#     -var "var__vm_name=gw.${client_code,,}.devspace.lan" \
#     -var "var__cs_gateway_a=$final_gateway"


# 4.2 Контроллер
var__dc_ip=$(python3 -c '
import sys, ipaddress
ip = ipaddress.IPv4Address(sys.argv[1])
print(ip + int(sys.argv[2]))
' "$final_gateway" "2")

echo "Создаём сервер DC (FreeIPA) для нового клиента. Для действий требуется ручное подтверждение."
terraform -chdir="$virt_system/tf_idm" init
terraform -chdir="$virt_system/tf_idm" apply \
    -var "var__cs_code=${client_code^^}" \
    -var "var__vm_name=idm.${client_code,,}.devspace.lan" \
    -var "var__vm_ip=$var__dc_ip"

# 4.3 IDP
var__idp_ip=$(python3 -c '
import sys, ipaddress
ip = ipaddress.IPv4Address(sys.argv[1])
print(ip + int(sys.argv[2]))
' "$final_gateway" "3")

echo "Создаём сервер IDP для нового клиента. Для действий требуется ручное подтверждение."
terraform -chdir="$virt_system/tf_idp" init
terraform -chdir="$virt_system/tf_idp" apply \
    -var "var__cs_code=${client_code^^}" \
    -var "var__vm_name=idp.${client_code,,}.devspace.lan" \
    -var "var__vm_ip=$var__idp_ip"


# 4.4 APP
var__app_ip=$(python3 -c '
import sys, ipaddress
ip = ipaddress.IPv4Address(sys.argv[1])
print(ip + int(sys.argv[2]))
' "$final_gateway" "30")

echo "Создаём сервер APP для нового клиента. Для действий требуется ручное подтверждение."
terraform -chdir="$virt_system/tf_app" init
terraform -chdir="$virt_system/tf_app" apply \
    -var "var__cs_code=${client_code^^}" \
    -var "var__vm_name=app-01.${client_code,,}.devspace.lan" \
    -var "var__vm_ip=$var__app_ip"

# роки все сервера кроме GW
#     bld + GW