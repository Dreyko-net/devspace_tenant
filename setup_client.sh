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

new_gateway_a=$(terraform -chdir="$virt_system/tf_data_net" show -json tfplan.bin \
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["planned_values"]["outputs"]["final_gateway"]["value"])')

rm -f "$virt_system/tf_data_net/tfplan.bin"

# Действие 3. Если сетей клиента нет, то создаём сети. Если есть и выбрано удаление, то удаляем.
if [[ "$net_exists" == "true" ]]; then
  if [[ "$action" == "destroy" ]]; then
    echo "Удаляем инфраструктуру клиента: ${client_code^^}. Для действий требуется ручное подтверждение."
    #Удаляем сервера по очереди
    terraform -chdir="$virt_system/tf_freeipa" init
    terraform -chdir="$virt_system/tf_freeipa" destroy \
    -var "var__cs_code=${client_code^^}" \
    -var "var__vm_name=dc.${client_code,,}.devspace.lan" \
    -var "var__vm_ip=$var__freeipa_ip"
    #Удаление сетей.
    terraform -chdir="$virt_system/tf_network" init
    terraform -chdir="$virt_system/tf_network" destroy \
        -var "var__cs_code=${client_code^^}" \
        -var "var__cs_gateway_a=172.16.200.1"
    exit 0
  else
    echo "Сети для такого клиента существуют. Дальнейшие действия с сетями не требуются."
  fi  
  
else
  echo "Создаём сети для нового клиента. Для действий требуется ручное подтверждение."
  terraform -chdir="$virt_system/tf_network" init
  terraform -chdir="$virt_system/tf_network" apply \
    -var "var__cs_code=${client_code^^}" \
    -var "var__cs_gateway_a=$new_gateway_a"
fi

# Действие 4. Создание серверов

var__freeipa_ip=$(python3 -c '
import sys, ipaddress
ip = ipaddress.IPv4Address(sys.argv[1])
print(ip + int(sys.argv[2]))
' "$new_gateway_a" "2")

echo "Создаём сервер FreeIPA для нового клиента. Для действий требуется ручное подтверждение."
terraform -chdir="$virt_system/tf_freeipa" init
terraform -chdir="$virt_system/tf_freeipa" apply \
-var "var__cs_code=${client_code^^}" \
-var "var__vm_name=dc.${client_code,,}.devspace.lan" \
-var "var__vm_ip=$var__freeipa_ip"


