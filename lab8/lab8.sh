#!/bin/bash

echo "Made by M. Sukhov B20-515"


if [ "$EUID" -ne 0 ]; then
	echo "Запустите программу с правами администратора"
	exit
fi

function check {
	if [ $1 -ne 0 ]; then
		echo ${@:3}
		exit
	else
		echo $2
	fi
}

function getunit() {
	local path=$(systemctl status $1 | sed -n 2p | cut -f2 -d"(" | cut -f1 -d";" | cut -f1 -d")")
	if [ -f "$path" ]; then
		echo "$path"
	else
		return 1
	fi
}

function listselect {
	local -n list=$1
	list+=("Выход")
	select opt in "${list[@]}"; do
	case $opt in
		Выход) return 0;;
		*)
			if [[ -z $opt ]]; then
				echo "Ошибка: введите число из списка" >&2
			else
				return $REPLY
			fi
			;;
	esac
	done
}

function second_choose {
    readarray -t services < <(systemctl list-units --type=service | tail -n +2 | head -n -7 | cut -c 3- | cut -d ' ' -f 1)
	listselect services "Введите число, соответствующее интересующему сервису"
	res=$?
	[ $res == 0 ] && return 0
	service=${services[res - 1]}
	select opt in "Включить службу" "Отключить службу" "Запустить/перезапустить службу" "Остановить службу" "Вывести содержимое юнита службы" "Отредактировать юнит службы" "Назад"; do
	case $opt in
        "Включить службу")
            systemctl enable "$service"
            check $? "Служба включена" "Ошибка включения службы"
            ;;
        "Отключить службу")
            systemctl disable "$service"
            check $? "Служба выключена" "Ошибка выключения службы"
            ;;
        "Запустить/перезапустить службу")
            systemctl restart "$service"
            check $? "Служба перезапущена" "Ошибка перезапуска службы"
            ;;
        "Остановить службу")
            systemctl stop "$service"
            check $? "Служба остановлена" "Ошибка остановки службы"
            ;;
        "Вывести содержимое юнита службы")
            cat "$(getunit $service)"
            ;;
        "Отредактировать юнит службы")
            nano "$(getunit $service)"
            ;;
        "Назад")
            return 0
            ;;
        *) echo "Неправильная команда $REPLY";;
	esac
	done
}

function third_choose {
    read -p "Введите имя службы или его часть: " servicename
	read -p "Введите степень важности: " priority
	read -p "Введите строку поиска: " query
	journalctl -p "$priority" -u "$servicename" -g "$query"
}



PS3='Пожалуйста, выберите действие: '
options=("Поиск системных служб" "Вывести список процессов и связанных с ними systemd служб" "Управление службами" 
         "Поиск событий в журнале" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Поиск системных служб")
            read -p "Введите имя службы или его часть: " filepath
            echo "$(systemctl list-units --type=service | tail -n +2 | head -n -7 | grep "$filepath")"
            ;;
        "Вывести список процессов и связанных с ними systemd служб")
            echo "$(ps xaww -o'pid,unit,args' | grep -P '^\s+\d+\s+(\w|[@-])*\.service ')"
            ;;
        "Управление службами")
            second_choose
            ;;
        "Поиск событий в журнале")
            third_choose
            ;;
        "Выход")
            break
            ;;
        *) echo "Некорректный выбор $REPLY";;
    esac
done
