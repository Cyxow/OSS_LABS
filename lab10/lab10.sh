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

function first_choose {
    options=("Добавить новый репозиторий" "Отключить репозиторий"
         "Включить репозиторий" "Выход")
    select opt in "${options[@]}"
    do
        case $opt in
            "Добавить новый репозиторий")
                read -p "Введите путь до репозитория: " repo_path
                dnf config-manager --add-repo "$repo_path"
                echo "Репозиторий '$repo_path' успешно добавлен"
                ;;
            "Отключить репозиторий")
                dnf repolist enabled
                read -p "Введите репозиторий, который необходимо отключить: " repo_number
                dnf config-manager --disable "$repo_number"
                ;;
            "Включить репозиторий")
                dnf repolist disabled
                read -p "Введите репозиторий, который необходимо включить: " repo_number
                sudo dnf config-manager --enable "$repo_number"
                ;;
            "Выход")
                break
                ;;
            *) echo "ERROR $REPLY";;
        esac
    done
}

function second_choose {
    options=("Добавить новый репозиторий" "Отключить репозиторий"
         "Включить репозиторий" "Выход")
    select opt in "${options[@]}"
    do
        case $opt in
            "Добавить новый репозиторий")
                read -p "Введите путь до репозитория: " repo_path
                dnf config-manager --add-repo "$repo_path"
                echo "Репозиторий '$repo_path' успешно добавлен"
                ;;
            "Отключить репозиторий")
                dnf repolist enabled
                read -p "Введите репозиторий, который необходимо отключить: " repo_number
                dnf config-manager --disable "$repo_number"
                ;;
            "Включить репозиторий")
                dnf repolist disabled
                read -p "Введите репозиторий, который необходимо включить: " repo_number
                sudo dnf config-manager --enable "$repo_number"
                ;;
            "Выход")
                break
                ;;
            *) echo "ERROR $REPLY";;
        esac
    done
}


PS3='Пожалуйста, выберите действие: '
options=("Поиск пакета по ключевому слову" "Установить пакет"
         "Удалить пакет" "Настройка репозиториев" "Управление ключами" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Поиск пакета по ключевому слову")
            read -p "Введите ключевое слово для поиска пакета: " keyword
            echo "Результаты поиска с использованием команды rpm:"
            rpm -qa | grep "$keyword"
            echo "Результаты поиска с использованием команды yum:"
            yum search "$keyword"
            ;;
        "Установить пакет")
            read -p "Введите имя пакета для установки: " package
            yum install "$package"
            ;;
        "Удалить пакет")
            read -p "Введите имя пакета для удааления: " package
            yum remove "$package"
            ;;
        "Настройка репозиториев")
            first_choose
            ;;
        "Управление ключами")
            second_choose
            ;;
        "Выход")
            break
            ;;
        *) echo "ERROR $REPLY";;
    esac
done
