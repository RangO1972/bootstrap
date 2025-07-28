#!/bin/bash

# Logging con livelli
log() {
    local level="$1"
    local message="$2"
    local timestamp
    local caller_file

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    caller_file=$(basename "${BASH_SOURCE[1]}")
    caller_file="${caller_file%.sh}"

    case "$level" in
        info)
            color="\033[1;32m[INFO ]\033[0m"
            ;;
        warn)
            color="\033[1;33m[WARN ]\033[0m"
            ;;
        error)
            color="\033[1;31m[ERROR]\033[0m"
            ;;
        *)
            color="\033[1;37m[LOG  ]\033[0m"
            ;;
    esac

    echo -e "\033[1;37m[${caller_file}]\033[0m $timestamp $color $message"
}
