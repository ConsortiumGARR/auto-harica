#!/bin/bash

source "$(dirname "$0")/utils.sh"

CERT_DIR="/app/certbot/certs"
CERT_PATH="$CERT_DIR/live/$DOMAIN/cert.pem"

renew_certificate() {
    FILES_SUFFIX=$(date +%s)
    CERT_FILENAME=cert$FILES_SUFFIX.pem
    FULLCHAIN_FILENAME=fullchain$FILES_SUFFIX.pem

    generate_and_download_certificate $FULLCHAIN_FILENAME $CERT_FILENAME

    echo "Moving certificates and key in 'sectigo' position..."

    CERT_PATH="$CERT_DIR/archive/$DOMAIN/$CERT_FILENAME"
    FULLCHAIN_PATH="$CERT_DIR/archive/$DOMAIN/$FULLCHAIN_FILENAME"
    PRIVKEY_FILENAME=privkey$FILES_SUFFIX.pem
    PRIVKEY_PATH="$CERT_DIR/archive/$DOMAIN/$PRIVKEY_FILENAME"

    mv $HARICA_OUTPUT_FOLDER/$CERT_FILENAME $CERT_PATH
    mv $HARICA_OUTPUT_FOLDER/$FULLCHAIN_FILENAME $FULLCHAIN_PATH
    # Copy privatekey instead of moving
    cp $PRIVKEY_FILE $PRIVKEY_PATH

    # Replace old symlinks
    LIVE_DIR="$CERT_DIR/live/$DOMAIN"
    RELATIVE_PATH="../../archive/$DOMAIN"
    mkdir -p "$LIVE_DIR"

    ln -sf "$RELATIVE_PATH/$FULLCHAIN_FILENAME" "$LIVE_DIR/fullchain.pem"
    ln -sf "$RELATIVE_PATH/$CERT_FILENAME" "$LIVE_DIR/cert.pem"
    ln -sf "$RELATIVE_PATH/$PRIVKEY_FILENAME" "$LIVE_DIR/privkey.pem"

    # Post-request hook
    if [ -d "${HOOKS_DIR}" ]; then
        run-parts -a "post-request" --reverse --exit-on-error "${HOOKS_DIR}"
    fi

    echo "Certificate renewed and symlinks updated for $DOMAIN."
}

if [ "$FORCE_RENEWAL" = true ]; then
    echo "Force renewal enabled. Renewing certificate for $DOMAIN..."
    renew_certificate
elif check_certificate_expiration "$CERT_PATH"; then
    renew_certificate
else
    echo "No renewal needed for $DOMAIN."
fi
