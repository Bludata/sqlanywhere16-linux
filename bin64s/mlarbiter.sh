#!/bin/sh
SAROOT=`dirname "$0"`/..
. "$SAROOT/bin64/sa_config.sh" >/dev/null 2>&1
exec "$SAROOT/bin64/mlarbiter.sh" "$@"
