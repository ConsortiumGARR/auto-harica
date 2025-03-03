#!/bin/bash
set -Eeo pipefail
trap "exit" SIGHUP SIGINT SIGTERM

echo -e "\n* Starting renew loop in $CHECK_FREQ hours"

while true; do
    echo -e "\n* Running renew loop at $(date '+%Y-%m-%d %H:%M:%S')..."

    $(dirname "$0")/env.sh

    if [ "$SECTIGO_BACKWARD_COMPATIBILITY" = true ]; then
        $(dirname "$0")/sectigo.sh
    else
        $(dirname "$0")/harica.sh
    fi

    echo "* Next check in $CHECK_FREQ hours"
    sleep ${CHECK_FREQ}h
done
