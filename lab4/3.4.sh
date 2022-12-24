#!/bin/bash
echo "1.Каталоги:"
ls -l "$1" | grep ^d
echo "2.Обычные файлы:"
ls -l "$1" | grep ^-
echo "3.Символьные ссылки:"
ls -l "$1" | grep ^l
echo "4.Символьные устройства:"
ls -l "$1" | grep ^c
echo "5.Блочные устройства:"
ls -l "$1" | grep ^b
