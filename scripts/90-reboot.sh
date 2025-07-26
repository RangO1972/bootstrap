#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

echo "$TAG - Rebooting in 5 seconds..."
sleep 1
echo "$TAG - Rebooting in 4 seconds..."
sleep 1
echo "$TAG - Rebooting in 3 seconds..."
sleep 1
echo "$TAG - Rebooting in 2 seconds..."
sleep 1
echo "$TAG - Rebooting in 1 seconds..."
sleep 1
echo "$TAG - Rebooting..."
reboot
