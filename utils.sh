#!/bin/bash

EXPIRY_DAYS=30
HOOKS_DIR="/app/hooks"
if [ -d "${HOOKS_DIR}" ]; then
    on_error() {
        run-parts -a "error" "${HOOKS_DIR}"
    }
    trap 'on_error' ERR
fi

# tcs-garr options
ENV_OPTS="--environment $ENVIRONMENT"
CERT_TYPE_OPTS="--profile $CERT_TYPE"

check_certificate_expiration() {
    CERT_PATH="$1"

    if [ ! -f "$CERT_PATH" ]; then
        echo "No existing certificate found at $CERT_PATH."
        return 0
    fi

    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
    CURRENT_TIMESTAMP=$(date +%s)
    REMAINING_DAYS=$(((EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400))

    if [ "$REMAINING_DAYS" -le "$EXPIRY_DAYS" ]; then
        echo "Certificate at $CERT_PATH is expiring in $REMAINING_DAYS days. Renewal required."
        return 0
    else
        echo "Certificate at $CERT_PATH is valid for $REMAINING_DAYS more days. No renewal needed."
        return 1
    fi
}

# Takes fullchain and certificate names as input
generate_and_download_certificate() {
    # Pre-request hook
    if [ -d "${HOOKS_DIR}" ]; then
        run-parts -a "pre-request" --exit-on-error "${HOOKS_DIR}"
    fi

    echo "Requesting new certificate for $DOMAIN..."

    CSR_FILE="$HARICA_OUTPUT_FOLDER/$DOMAIN.csr"
    CSR_ID_FILE="$HARICA_OUTPUT_FOLDER/$DOMAIN.csr.id"
    PRIVKEY_FILE="$HARICA_OUTPUT_FOLDER/$DOMAIN.key"

    # Remove existing CSR ID file if it exists
    rm -f "$CSR_ID_FILE"

    # Check if a previous CSR exists
    if [ "$USE_EXISTING_CSR" = true ] && [ -f "$CSR_FILE" ]; then
        echo "Requesting certificate using previous CSR..."
        tcs-garr $ENV_OPTS request $CERT_TYPE_OPTS --csr $CSR_FILE
    else
        # Generate CSR, privkey and CSR.id
        echo "Generating CSR and requesting certificate..."
        if [ -n "$ANS" ]; then
            tcs-garr $ENV_OPTS request $CERT_TYPE_OPTS --cn $DOMAIN --alt_names $ANS
        else
            tcs-garr $ENV_OPTS request $CERT_TYPE_OPTS --cn $DOMAIN
        fi
    fi

    if [ ! -f "$CSR_ID_FILE" ]; then
        echo "CSR ID file not generated. Aborting."
        exit 1
    fi

    # Wait for approval
    CERT_ID=$(cat "$CSR_ID_FILE")
    FULLCHAIN_FILENAME=$1
    CERT_FILENAME=$2

    echo -e "Waiting for approval of certificate request...\n"

    while true; do
        OUTPUT=$(tcs-garr $ENV_OPTS download --id $CERT_ID --output-filename $FULLCHAIN_FILENAME --force 2>&1)

        if echo "$OUTPUT" | grep -q "has not been approved yet"; then
            echo "Waiting for certificate approval..."
            sleep 10
        elif echo "$OUTPUT" | grep -q "Certificate saved to"; then
            # Certificate downloaded. Exit.
            break
        else
            echo "Unexpected error: $OUTPUT" >&2
            exit 1
        fi
    done

    tcs-garr $ENV_OPTS download --id $CERT_ID --output-filename $CERT_FILENAME --force --download-type certificate

    echo "Certificates downloaded..."
}
