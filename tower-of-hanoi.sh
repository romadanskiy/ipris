#!/bin/bash

trap 'echo -e "\nЧтобы завершить работу сценария, введите q или Q."' SIGINT

max_size=8
move_count=1
declare -A stacks=( [a]="87654321" [b]="" [c]="" )

print_stacks() {
    for ((i = max_size - 1; i >= 0; i--)); do
        printf "|%1s|  |%1s|  |%1s|\n" "${stacks[a]:i:1}" "${stacks[b]:i:1}" "${stacks[c]:i:1}"
    done
    echo "+-+  +-+  +-+"
    echo " A    B    C "
}

print_stacks
while true; do
    read -p "Ход № $move_count (откуда, куда): " user_input

    if [[ "$user_input" == "q" || "$user_input" == "Q" ]]; then
        exit 1
    fi

    user_input=$(echo "$user_input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    if [[ -z "$user_input" || ${#user_input} -ne 2 || ! "$user_input" =~ ^[abc][abc]$ ]]; then
        echo "Ошибка: Введите два имени стека."
        continue
    fi

    from="${user_input:0:1}"
    to="${user_input:1:1}"

    from_stack=${stacks[$from]}
    to_stack=${stacks[$to]}

    from_stack_top=${from_stack: -1}
    to_stack_top=${to_stack: -1}

    if [[ "$from" == "$to" ]] || \
       [[ -z "$from_stack" ]] || \
       [[ -n "$to_stack_top" && "$from_stack_top" -gt "$to_stack_top" ]]; then
        echo "Такое перемещение запрещено!"
        continue
    fi

    ((move_count++))

    stacks[$from]=${from_stack%?}
    stacks[$to]=$to_stack$from_stack_top

    if [[ "${stacks[b]}" == "87654321" || "${stacks[c]}" == "87654321" ]]; then
        echo "Победа!"
        exit 0
    fi

    echo
    print_stacks
done
