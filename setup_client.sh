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


# Действие 1. Определяем систему виртуализации
virt_system=""
case "1" in
  $([[ -n "${VCD_ORG:-}" ]] && echo 1))     virt_system="vcd"  ;;
  $([[ -n "${OS_USERNAME:-}" ]] && echo 1)) virt_system="vkcs" ;;
esac
if [[ -z "$virt_system" ]]; then
  echo "ERROR: не заданы переменные окружения для подключения к системе виртуализации" >&2
  exit 1
fi

# Действие 2. Проверяем существование сетей и получаем значение net_exists из плана
terraform -chdir="$virt_system/tf_data_net" init
terraform -chdir="$virt_system/tf_data_net" plan -var "var__cs_code=$client_code" -out=tfplan.bin


net_exists=$(terraform -chdir="$virt_system/tf_data_net" show -json tfplan.bin | python3 -c 'import sys, json; print(json.load(sys.stdin)["planned_values"]["outputs"]["net_exists"]["value"])')

new_gateway_a=$(terraform -chdir="$virt_system/tf_data_net" show -json tfplan.bin | python3 -c 'import sys, json; print(json.load(sys.stdin)["planned_values"]["outputs"]["new_gateway_a"]["value"]);')
rm -f $virt_system/tf_data_net/tfplan.bin

# Действие 3. Если сетей клиента нет, то создаём сети.
if [[ "$net_exists" == "True" ]]; then
  echo "Сети для такого клиента существуют. Дальнейшие действия с сетями не требуются."
else
  echo "Создаём сети дня нового клиента."
  terraform -chdir="$virt_system/tf_network" init
  terraform -chdir="$virt_system/tf_network" plan -var "var__cs_code=$client_code" -var "var__cs_gateway_a=$new_gateway_a"
fi

