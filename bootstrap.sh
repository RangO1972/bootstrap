#!/bin/bash
set -e

WORKDIR="/opt/stradcs-bootstrap/scripts"

echo "### Running bootstrap scripts..."
for script in $(ls $WORKDIR | sort); do
   echo "### Executing $script..."
   bash "$WORKDIR/$script"
done
