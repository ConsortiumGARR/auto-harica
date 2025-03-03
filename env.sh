#!/bin/bash

# Check mandatory envs

if [ -z "$DOMAIN" ]; then
    echo "No domain set, please fill -e 'DOMAIN=example.com'"
    exit 1
fi

if [ -z "$HARICA_USERNAME" ]; then
    echo "No username set, please fill -e 'HARICA_USERNAME=your@email.tld'"
    exit 1
fi

if [ -z "$HARICA_PASSWORD" ]; then
    echo "No password set, please fill -e 'HARICA_PASSWORD=yourpassword'"
    exit 1
fi

if [ -z "$HARICA_TOTP_SEED" ]; then
    echo "No totp set, please fill -e 'HARICA_TOTP_SEED=otpauth://totp/HARICA.....'"
    exit 1
fi

if [ "$ENVIRONMENT" != "production" ] && [ "$ENVIRONMENT" != "stg" ]; then
    echo "No valid environment set, please fill -e 'ENVIRONMENT=production' or -e 'ENVIRONMENT=stg'"
    exit 1
fi

if [ "$CERT_TYPE" != "OV" ] && [ "$CERT_TYPE" != "DV" ]; then
    echo "No valid cert type set, please fill -e 'CERT_TYPE=OV' or -e 'CERT_TYPE=DV'"
    exit 1
fi
