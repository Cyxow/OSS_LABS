#!/bin/bash


echo "Made by M Sukhov B20-515"


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
	list+=("Назад")
	select opt in "${list[@]}"; do
	case $opt in
		Выход) return 0;;
		*)
			if [[ -z $opt ]]; then
				echo "ERROR" >&2
			else
				return $REPLY
			fi
			;;
	esac
	done
}

index() {
	local -n list=$1
	for i in "${!list[@]}"; do
		if [[ "${list[$i]}" = "$2" ]]; then
			return "$((i+1))"
		fi
	done
	return 0
}

partselect() {
	read -p "$2" name
	index $1 "$name"
	res=$?
	if [ $res == 0 ]; then
		local -n list=$1
		readarray -t filtered < <(printf -- '%s\n' "${list[@]}" | grep "$name")
		listselect filtered "$3"
		res=$?
		if [ $res == 0 ]; then
			return 0
		else
			index $1 "${filtered[res - 1]}"
			return $?
		fi
	else
		return $res
	fi
}

function first_choose {
    readarray -t services < <(semanage port -l -n | cut -d' ' -f1)
	partselect services "Введите имя службы или его часть: " "Введите число"
	res=$?
	[ $res == 0 ] && continue
	service=${services[res - 1]}
	select opt in "Добавить новый порт для службы" "Удалить порт службы" "Изменить существующий порт службы" "Справка" "Назад"; do
	case $opt in
        "Добавить новый порт для службы")
			read -p "Введите номер порта: " port
			semanage port -a -t "$service" -p tcp "$port"
            check $? "Порт добавлен" "Ошибка добавления порта"
            ;;
        "Удалить порт службы")
			readarray -t ports < <(semanage port -l | grep -E "^$service\s" | awk '{$1=$2=""; print $0}' | sed 's/,/\n/g' | sed 's/\s//g')
			listselect ports "Введите число, соответствующее интересующему порту"
			res=$?
			if [ $res -ne 0 ]; then
				port=${ports[res - 1]}
				semanage port -d -t "$service" -p tcp "$port"
            	check $? "Порт удален" "Ошибка удаления порта"
			fi
            ;;
        "Изменить существующий порт службы")
			readarray -t ports < <(semanage port -l | grep -E "^$service\s" | awk '{$1=$2=""; print $0}' | sed 's/,/\n/g' | sed 's/\s//g')
			listselect ports "Введите число, соответствующее интересующему порту"
			res=$?
			if [ $res -ne 0 ]; then
				port=${ports[res - 1]}
				read -p "Введите номер нового порта: " port2
				semanage port -d -t "$service" -p tcp "$port"
            	check $? "Порт удален" "Ошибка удаления порта"
				semanage port -a -t "$service" -p tcp "$port2"
				check $? "Порт добавлен" "Ошибка добавления порта"
			fi
            ;;
        "Назад")
            break;;
        *) echo "ERROR $REPLY";;
	esac
	done
}

function second_choose {
    select opt in "Переразметка каталога" "Запустить полную переразметку файловой системы во время перезагрузке" "Изменить домен файла или каталога" "Справка" "Назад"; do
	case $opt in
        "Переразметка каталога")
			read -e -p "Введите имя каталога: " path
			restorecon -Rvv "$path"
            check $? "Переразметка успешна" "Ошибка переразметки"
            ;;
        "Запустить полную переразметку файловой системы во время перезагрузке")
            touch /.autorelabel
            check $? "Успешно" "Неуспешно"
            ;;
        "Изменить домен файла или каталога")
			read -e -p "Введите имя файла/каталога: " path
			path=$(realpath "$path")
			read -p "Введите новый домен: " newtype
			semanage fcontext -a -t "$newtype" "$path(/.*)?"
            check $? "" "Ошибка назначения домена"
			restorecon -Rv "$path"
            check $? "Переразметка успешна" "Ошибка переразметки"
            ;;
        "Назад")
            break
            ;;
        *) echo "ERROR $REPLY";;
	esac
	done
}

function third_choose {
    select opt in "Вывести список переключателей с описанием и состоянием" "Изменить переключатель" "Справка" "Назад"; do
	case $opt in
        "Вывести список переключателей с описанием и состоянием")
            getsebool -a
            ;;
        "Изменить переключатель")
			readarray -t booleans < <(getsebool -a | cut -d' ' -f1)
			partselect booleans "Введите имя переключателя или его часть: " "Введите число, соответствующее интересующему переключателю"
			res=$?
			if [ $res -ne 0 ]; then
				boolean=${booleans[res - 1]}
				state=$(getsebool "$boolean" | awk -F '--> ' '{print $2}')
				echo "Текущее состояние: $state"
				read -p "Переключить (y/n)? " answer
				case ${answer:0:1} in
					y|Y )
						state=$(echo "$state" | sed -e 's/off/o_n/' -e 's/on/o_ff/' -e 's/_//')
						setsebool -P "$boolean" "$state"
           		 		check $? "Успешно: $boolean := $state" "Ошибка переключения"
					;;
				esac
			fi
		;;
        "Назад")
            break
            ;;
        *) echo "ERROR $REPLY";;
	esac
	done
}



PS3='Пожалуйста, выберите действие: '
options=("Управление связыванием пользователей" "Управление портами" "Управление файлами" 
         "Управление переключателями" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Управление связыванием пользователей")
            ;;
        "Управление портами")
            first_choose
            ;;
        "Управление файлами")
            second_choose
            ;;
        "Управление переключателями")
            third_choose
            ;;
        "Выход")
            break
            ;;
        *) echo "ERROR $REPLY";;
    esac
done
