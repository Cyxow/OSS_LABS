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

function second_choose {
    options=("добавить каталог/файл в список наблюдения" "удалить из списка наблюдения"
         "отчёт по наблюдению" "Выход")
    select opt in "${options[@]}"
    do
        case $opt in
            "добавить каталог/файл в список наблюдения")
                read -p "Введите путь до файла/каталога: " filepath
        		if [ "$filepath" == "" ]; then
        			err "путь не может быть пустой"
        			continue 
        		fi
        		if [ ! -е ]; then
        			err "пути не существует"
        			continue
        		elif [ -d $filepath ]; then
        			auditctl -a exit,always -F dir=$filepath -F perm=warx
        		else
        			auditctl -w $filepath -p warx
        		fi
                ;;
            "удалить из списка наблюдения")
                echo "Выберите интересующий вас путь"
    			readarray -t paths < <(auditctl -l | cut -d " " -f2)
    			readinput paths
    			res=$?
    			[ $res == 0 ] && continue
    			path=${paths[res - 1]}
    			auditctl -W $path
                ;;
            "отчёт по наблюдению")
                echo "Выберите интересующий вас путь"
    			readarray -t paths < <(auditctl -l | cut -d " " -f2)
    			readinput paths
    			res=$?
    			[ $res == 0 ] && continue
    			path=${paths[res - 1]}
    			res=$(aureport --file | grep $path)
    			[ "$res" == "" ] && res="нет событий" 
    			echo "${res}"
                ;;
            "Выход")
                break
                ;;
            *) echo "ERROR $REPLY";;
        esac
    done
}


PS3='Пожалуйста, выберите действие: '
options=("Поиск событий аудита" "Отчёты аудита"
         "Настройка подсистемы аудита для наблюдения за файлами" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Поиск событий аудита")
            read -p "Введите тип события (или ALL): " eventtype
    		if [ "$eventtype" == "" ]; then
    			eventtype=ALL
    		fi
    		read -p "Введите uid пользователя: " userid
    		read -p "Введите строку поиска: " searchstring
    		[ "$searchstring" == "" ] && searchstring="="
    		[ "$userid" == "" ] && ausearch -m $eventtype | grep $searchstring -B 2 && continue
    		ausearch -m $eventtype -ui $userid | grep $searchstring -B 2
            ;;
        "Отчёты аудита")
            echo "Сгенерирован отчёт о входе пользователей за день, неделю, месяц, год:"
			aureport -au -ts today
			aureport -au -ts this-week
			aureport -au -ts this-month
			aureport -au -ts this-year
			echo "Сгенерирован отчёт о нарушениях за день, неделю, месяц, год:"
			aureport --failed --user -ts today
			aureport --failed --user -ts this-week
			aureport --failed --user -ts this-month
			aureport --failed --user -ts this-year
            ;;
        "Настройка подсистемы аудита для наблюдения за файлами")
            second_choose
            ;;
        "Выход")
            break
            ;;
        *) echo "ERROR $REPLY";;
    esac
done
