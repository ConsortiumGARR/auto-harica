#!/bin/bash

source "$(dirname "$0")/utils.sh"

CERT_PATH="$HARICA_OUTPUT_FOLDER/$DOMAIN.pem"
RENEWAL_FORCED_FILE="$HARICA_OUTPUT_FOLDER/renewal_forced"

renew_certificate() {
    FULLCHAIN_FILENAME=${DOMAIN}_fullchain.pem
    CERT_FILENAME=$DOMAIN.crt

    generate_and_download_certificate $FULLCHAIN_FILENAME $CERT_FILENAME

    # Post-request hook
    if [ -d "${HOOKS_DIR}" ]; then
        run-parts -a "post-request" --reverse --exit-on-error "${HOOKS_DIR}"
    fi

    echo "Certificate renewed for $DOMAIN."
}

if [ "$FORCE_RENEWAL" = true ] && [ ! -f "$RENEWAL_FORCED_FILE" ]; then
    echo "Force renewal enabled. Renewing certificate for $DOMAIN..."
    renew_certificate
    # Create a file that indicates that renewal was forced
    touch $RENEWAL_FORCED_FILE
elif check_certificate_expiration "$CERT_PATH"; then
    renew_certificate
else
    echo "No renewal needed for $DOMAIN."
fi
