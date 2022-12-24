#!/bin/bash
touch /tmp/files.txt
find ~ -maxdepth 1 -type f -name "*.txt" > /tmp/files.txt
cat /tmp/files.txt | wc -l
cat /tmp/files.txt
du -bc /tmp/files.txt | tail -n1 | cut -f1
rm /tmp/files.txt
