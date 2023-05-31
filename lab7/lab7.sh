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

function listselect {
	local -n list=$1
	list+=("Справка" "Выход")
	select opt in "${list[@]}"; do
	case $opt in
		Выход) return 0;;
		Справка) echo $2;;
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

function first_choose {
read -p "Введите путь до файла/устройства: " filepath
		if [ ! -b $filepath ] && [ ! -f $filepath ]; then
			echo "not exist or not a blockdevice or file"
			return 0
		fi

		read -p "Введите каталог монтирования: " mountpath

		if [ ! -e $mountpath ]; then
			mkdir $mountpath
			if [ $? -ne 0 ]; then
				echo "creating $mountpath"
				return 0
			fi
		fi
		
		if [ -d $mountpath ]; then
			if [ -z "$(ls -A $mountpath)" ]; then
				:
			else
				echo "dir exists and not empty"
				return 0
			fi
		else
			echo "Not a directory"
			return 0
		fi

		if [ -f $filepath ]; then
			device=$(losetup --find --show $filepath);
			mount $device $mountpath
		else
			echo ok;
			mount $filepath $mountpath
		fi
		check $? "Успешно примонтировано" "Ошибка монтирования";
}

function second_choose {
read -p "Введите путь до файловой системы (пропустите для списка): " filesyspath #считать с консоли или дать выбрать
		if [ -z $filesyspath ]; then
			readarray -t mounts < <(df -x proc -x sys -x tmpfs -x devtmpfs --output=target | tail -n +2)
			listselect mounts "Введите число, соответствующее папке, которую хотите отмонтировать"
			res=$?
			[ $res == 0 ] && return 0
			filesyspath=${mounts[res - 1]}
		fi
		if [ ! -z $filesyspath ]; then
			umount $filesyspath
			check $? "Успешно отмонтировано" "Ошибка отмнотирования"
		fi
}

function third_choose {
    readarray -t mounts < <(df -x proc -x sys -x tmpfs -x devtmpfs --output=target | tail -n +2)
		listselect mounts "Введите число, соответствующее папке, параметры которой хотите изменить"
		res=$?
		[ $res == 0 ] && return 0
		filesyspath=${mounts[res - 1]}
		select opt in "только чтение" "чтение и запись"; do
		case $opt in
			"только чтение")
				mount -o remount,ro $filesyspath
				check $? "Изменения применены" "Ошибка изменения параметров"
				break
				;;
			"чтение и запись")
				mount -o remount,rw $filesyspath
				check $? "Изменения применены" "Ошибка изменения параметров"
				break
				;;
			*)
				echo "Отмена"
				break
				;;
		esac
	done
}

function fourth_choose {
    readarray -t mounts < <(df -x proc -x sys -x tmpfs -x devtmpfs --output=target | tail -n +2)
	listselect mounts "Введите число, соответствующее папке, параметры которой хотите изменить"
	res=$?
	[ $res == 0 ] && return 0
	filesyspath=${mounts[res - 1]}
	if [ ! -z $filesyspath ]; then
		mount | grep $filesyspath
	fi
}

function fifth_choose {
    echo "Имеются следующие файловые системы ext*:"
	readarray -t exts < <(df -t ext2 -t ext3 -t ext4 -t extcow --output=source,target | tail -n +2 | sed "s/ \+/ on /g")
	readarray -t devices < <(df -t ext2 -t ext3 -t ext4 -t extcow --output=source | tail -n +2)
	listselect exts "Введите число, соответствующее интересующей файловой системе"
	res=$?
	[ $res == 0 ] && return 0
	device=${devices[res - 1]}
	tune2fs -l $device | tail -n +2
}



PS3='Пожалуйста, выберите действие: '
options=("Вывести таблицу файловых систем" "Монтировать файловую систему" "Отмонтировать файловую систему" 
         "Изменить параметры монтирования примонтированной файловой системы" 
         "Вывести параметры монтирования примонтированной файловой системы"
         "Вывести детальную информацию о файловой системе ext*" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Вывести таблицу файловых систем")
            df -x proc -x sys -x tmpfs -x devtmpfs --output=source,fstype,target
            ;;
        "Монтировать файловую систему")
            first_choose
            ;;
        "Отмонтировать файловую систему")
            second_choose
            ;;
        "Изменить параметры монтирования примонтированной файловой системы")
            third_choose
            ;;
        "Вывести параметры монтирования примонтированной файловой системы")
            fourth_choose
            ;;
        "Вывести детальную информацию о файловой системе ext*")
            fifth_choose
            ;;
        "Выход")
            break
            ;;
        *) echo "Некорректный выбор $REPLY";;
    esac
done
