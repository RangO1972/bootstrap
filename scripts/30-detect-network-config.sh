#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

CONFIGDIR="$WORKDIR/interfaces"

log info "Detecting hardware..."

VENDOR=$(cat /sys/class/dmi/id/sys_vendor | tr -c '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]')
MODEL=$(cat /sys/class/dmi/id/product_name | tr -c '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]')
NIC_COUNT=$(ls -1 /sys/class/net | grep -E '^(en|eth)' | wc -l)

NAMEBASE="${MODEL}-${NIC_COUNT}"

log info "Vendor: $VENDOR"
log info "Model: $MODEL"
log info "NIC count: $NIC_COUNT"

VENDORDIR="${CONFIGDIR}/${VENDOR}"
if [[ ! -d "$VENDORDIR" ]]; then
   log warn "No directory for vendor '$VENDOR', creating: $VENDORDIR"
   mkdir -p "$VENDORDIR"
fi

log info "Looking for configuration files matching: ${NAMEBASE}*.csv"
MATCHING_FILES=$(find "$VENDORDIR" -maxdepth 1 -type f -name "${NAMEBASE}*.csv" | sort)

if [[ -z "$MATCHING_FILES" ]]; then
   log warn "No configuration found for ${NAMEBASE}, falling back to default + auto NIC detection."

   DEFAULT="$CONFIGDIR/default/interfaces-default.csv"
   OUTFILE="$WORKDIR/interfaces.csv"
   cp "$DEFAULT" "$OUTFILE"
   log info "Copied default config to $OUTFILE"

   # Conta le righe già presenti (escludi intestazione)
   EXISTING_LINES=$(tail -n +2 "$DEFAULT" | wc -l)

   # Ottieni interfacce reali
   REAL_IFACES=($(ls /sys/class/net | grep -E '^(en|eth)'))
   REAL_COUNT=${#REAL_IFACES[@]}

   if [[ "$REAL_COUNT" -gt "$EXISTING_LINES" ]]; then
      log info "Adding $((REAL_COUNT - EXISTING_LINES)) extra NICs to $OUTFILE"
      idx=$((EXISTING_LINES + 1))
      for ((i=EXISTING_LINES; i<REAL_COUNT; i++)); do
         iface="${REAL_IFACES[$i]}"
         echo "$iface,nic${idx},dhcp,," >> "$OUTFILE"
         log info "Appended: $iface,nic${idx},dhcp,,"
         ((idx++))
      done
   fi

   TEMPLATE="${VENDORDIR}/${NAMEBASE}-$(date +%Y%m%d_%H%M).csv"
   log info "Generating template: $TEMPLATE"
   echo "OriginalName,Alias,Role,Group,Address" > "$TEMPLATE"
   idx=1
   for iface in "${REAL_IFACES[@]}"; do
      echo "$iface,nic${idx},dhcp,," >> "$TEMPLATE"
      ((idx++))
   done

   log info "Template created. Edit and rerun if needed."
   exit 0
fi

log info "Found configuration files:"
i=1
declare -A OPTIONS
for file in $MATCHING_FILES; do
   fname=$(basename "$file")
   log info "  [$i] $fname"
   OPTIONS[$i]="$file"
   ((i++))
done
log info "  [0] Use default configuration"

read -t 30 -p "Select configuration [0-$((i-1))] (default 0): " choice
if [[ -z "$choice" ]]; then
   choice=0
   log info "No selection made, using default."
else
   log info "Selected option: $choice"
fi

if [[ "$choice" == "0" ]]; then
   cp "$CONFIGDIR/default/interfaces-default.csv" "$WORKDIR/interfaces.csv"
   log info "Copied default configuration to $WORKDIR/interfaces.csv"
else
   SELECTED="${OPTIONS[$choice]}"
   cp "$SELECTED" "$WORKDIR/interfaces.csv"
   log info "Copied selected config: $SELECTED → $WORKDIR/interfaces.csv"
fi

TEMPLATE="${VENDORDIR}/${NAMEBASE}-$(date +%Y%m%d_%H%M).csv"
log info "Generating template: $TEMPLATE"
echo "OriginalName,Alias,Role,Group,Address" > "$TEMPLATE"
idx=1
for iface in $(ls /sys/class/net | grep -E '^(en|eth)'); do
   echo "$iface,nic${idx},dhcp,," >> "$TEMPLATE"
   ((idx++))
done

log info "Template created for reference at $TEMPLATE"
