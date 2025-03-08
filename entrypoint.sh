#!/bin/sh
set -e

# Locate Kestra
KESRA_BIN=""

if [ -f "/app/bin/kestra" ]; then
    KESRA_BIN="/app/bin/kestra"
elif [ -f "/app/kestra/bin/kestra" ]; then
    KESRA_BIN="/app/kestra/bin/kestra"
fi

if [ -z "$KESRA_BIN" ]; then
    echo "ERROR: Kestra binary not found!"
    exit 127
fi

# Start Kestra
exec $KESRA_BIN server standalone
