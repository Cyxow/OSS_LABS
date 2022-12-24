#!/bin/bash

echo "Процессов пользователя:"
echo ${USER}
ps -fu ${USER} | wc -l
echo "Процессов пользователя root:"
ps -fu root | wc -l
