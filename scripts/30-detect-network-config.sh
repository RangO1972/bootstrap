#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

WORKDIR="/opt/stradcs-bootstrap"
CONFIGDIR="$WORKDIR/interfaces"

echo "$TAG - Detecting hardware..."
VENDOR=$(cat /sys/class/dmi/id/sys_vendor | tr -c '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]')
MODEL=$(cat /sys/class/dmi/id/product_name | tr -c '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]')
NIC_COUNT=$(ls -1 /sys/class/net | grep -E '^(en|eth)' | wc -l)

NAMEBASE="${MODEL}-${NIC_COUNT}"

echo "Vendor: $VENDOR"
echo "Model: $MODEL"
echo "NIC count: $NIC_COUNT"

VENDORDIR="${CONFIGDIR}/${VENDOR}"
if [[ ! -d "$VENDORDIR" ]]; then
   echo "No directory for vendor $VENDOR, creating..."
   mkdir -p "$VENDORDIR"
fi

MATCHING_FILES=$(find "$VENDORDIR" -maxdepth 1 -type f -name "${NAMEBASE}*.csv" | sort)

if [[ -z "$MATCHING_FILES" ]]; then
   echo "No configuration found, using default."
   cp "$CONFIGDIR/default/interfaces-default.csv" "$WORKDIR/interfaces.csv"

   TEMPLATE="${VENDORDIR}/${NAMEBASE}-$(date +%Y%m%d_%H%M).csv"
   echo "Generating template: $TEMPLATE"
   echo "OriginalName,Alias,Role,Group,Address" > "$TEMPLATE"
   idx=1
   for iface in $(ls /sys/class/net | grep -E '^(en|eth)'); do
      echo "$iface,nic${idx},dhcp,," >> "$TEMPLATE"
      ((idx++))
   done
   echo "Template created, edit and rerun."
   exit 0
fi

echo "$TAG - Found configurations:"
i=1
declare -A OPTIONS
for file in $MATCHING_FILES; do
   fname=$(basename "$file")
   echo "  [$i] $fname"
   OPTIONS[$i]="$file"
   ((i++))
done
echo "  [0] default"

read -t 30 -p "Select configuration [0-$((i-1))] (default 0): " choice
if [[ -z "$choice" ]]; then
   choice=0
fi

if [[ "$choice" == "0" ]]; then
   cp "$CONFIGDIR/default/interfaces-default.csv" "$WORKDIR/interfaces.csv"
else
   SELECTED="${OPTIONS[$choice]}"
   cp "$SELECTED" "$WORKDIR/interfaces.csv"
fi

TEMPLATE="${VENDORDIR}/${NAMEBASE}-$(date +%Y%m%d_%H%M).csv"
echo "$TAG - Generating template: $TEMPLATE"
echo "OriginalName,Alias,Role,Group,Address" > "$TEMPLATE"
idx=1
for iface in $(ls /sys/class/net | grep -E '^(en|eth)'); do
   echo "$iface,nic${idx},dhcp,," >> "$TEMPLATE"
   ((idx++))
done

echo "$TAG - Template created for reference."
