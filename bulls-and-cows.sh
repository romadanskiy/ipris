#!/bin/bash

trap 'echo -e "\nЧтобы завершить работу сценария, введите q или Q."' SIGINT

echo "********************************************************************************"
echo "* Я загадал 4-значное число с неповторяющимися цифрами. На каждом ходу делайте *"
echo "* попытку отгадать загаданное число. Попытка - это 4-значное число с           *"
echo "* неповторяющимися цифрами.                                                    *"
echo "********************************************************************************"

generate_number() {
    digits=($(shuf -i 0-9))
    result=$([[ ${digits[0]} -eq 0 ]] && echo "${digits[@]:1:4}" || echo "${digits[@]:0:4}")
    echo "$result" | tr -d ' '
}

secret_number=$(generate_number)
attempt=0
history=()

while true; do
    ((attempt++))

    echo
    read -p "Попытка $attempt: " user_input

    if [[ "$user_input" == "q" || "$user_input" == "Q" ]]; then
        exit 1
    fi

    if [[ ! "$user_input" =~ ^[1-9][0-9]{3}$ ]] || [[ $(echo "$user_input" | grep -o . | sort | uniq | wc -l) -ne 4 ]]; then
        echo "Ошибка: Введите 4-значное число с неповторяющимися цифрами."
        ((attempt--))
        continue
    fi

    bulls=0
    cows=0
    for i in {0..3}; do
        digit="${user_input:i:1}"
        if [[ "${digit}" == "${secret_number:i:1}" ]]; then
            ((bulls++))
        elif [[ "$secret_number" == *"$digit"* ]]; then
            ((cows++))
        fi
    done

    if [[ "$user_input" == "$secret_number" ]]; then
        echo "Вы угадали загаданное число!"
        exit 0
    fi

    echo "Коров - $cows, Быков - $bulls"

    history+=("$attempt. $user_input (Коров - $cows Быков - $bulls)")

    echo -e "\nИстория ходов:"
    for entry in "${history[@]}"; do
        echo "$entry"
    done
done
