#!/bin/bash
cat bash.txt | grep "000000" > /tmp/zeros
cat bash.txt | grep -v "000000" > /tmp/nonzeros
cat /tmp/zeros | head -n10
tail -n10
cat /tmp/nonzeros | head -n10
tail -n10
