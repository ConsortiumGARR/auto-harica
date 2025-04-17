#!/bin/bash

source "$(dirname "$0")/utils.sh"

CERT_FILENAME=$DOMAIN.crt
FULLCHAIN_FILENAME=${DOMAIN}_fullchain.pem
CERT_PATH="$HARICA_OUTPUT_FOLDER/$FULLCHAIN_FILENAME"
RENEWAL_FORCED_FILE="$HARICA_OUTPUT_FOLDER/renewal_forced"

renew_certificate() {
    generate_and_download_certificate $FULLCHAIN_FILENAME $CERT_FILENAME

    # Post-request hook
    if [ -d "${HOOKS_DIR}" ]; then
        run-parts -a "post-request" --reverse --exit-on-error "${HOOKS_DIR}"
    fi

    echo "Certificate renewed for $DOMAIN."
}

if [ "$FORCE_RENEWAL" = true ]; then
    if [ ! -f "$RENEWAL_FORCED_FILE" ]; then
        echo "Force renewal enabled. Renewing certificate for $DOMAIN..."
        renew_certificate
        # Create a file that indicates that renewal was forced
        touch "$RENEWAL_FORCED_FILE"
    else
        echo -e "\nForce renewal was requested, but renewal was already forced previously."
        echo -e "If you want to force renewal again, please remove: $RENEWAL_FORCED_FILE\n"
    fi
elif check_certificate_expiration "$CERT_PATH"; then
    renew_certificate
else
    echo "No renewal needed for $DOMAIN."
fi
