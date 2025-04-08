# auto-harica

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
![Contributions welcome](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)
![GitHub License](https://img.shields.io/github/license/ConsortiumGARR/auto-harica)
![GitHub Release](https://img.shields.io/github/v/release/ConsortiumGARR/auto-harica)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ConsortiumGARR/auto-harica/docker-image.yml)

``auto-harica`` is a Docker image designed to automate the issuance and renewal of
SSL/TLS certificates from [Harica](https://cm.harica.gr) using
[tcs-garr](https://pypi.org/project/tcs-garr/). It serves as a temporary solution to
compensate for the absence of certbot and ACME. Additionally, this Docker container can
be used as a drop-in replacement for the previously used
[certbot-sectigo](docker/certbot-sectigo) solution internally used by GARR.

## Warning ⚠️

**Consortium GARR is not affiliated with HARICA, and the present work has not been
endorsed by or agreed with HARICA.**

**Consortium GARR provides this code to the community for sharing purposes but does not
commit to providing support, maintenance, or further development of the code. Use it at
your own discretion.**

## Requirements

To use the Docker image, you need:

- Read [prerequisites](https://github.com/ConsortiumGARR/tcs-garr/blob/main/README.md#prerequisites)
- Knowledge of and familiarity with the
  [harica-cli README](https://github.com/ConsortiumGARR/tcs-garr/blob/main/README.md)
- Familiarity with [certbot-sectigo](docker/certbot-sectigo)
  if you intend to use ``auto-harica`` as a replacement

## Docker

Docker image is available at GitHub container [registry](https://github.com/ConsortiumGARR/auto-harica/pkgs/container/auto-harica).
You can pull them via:

```bash
docker pull ghcr.io/consortiumgarr/auto-harica:<your_desired_version>
```

## Image tags

- X.Y.Z-a.b.c: release containing X.Y.Z version of
  [tcs-garr](https://pypi.org/project/tcs-garr/) and a.b.c version of auto-harica.
- latest: latest is latest for both tcs-garr and auto-harica

### Build

Example of docker image build command:

```bash
docker build -t auto-harica:latest .
```

## Environment Variables

|          env variable          |                                                                                description                                                                                |      default value      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| DOMAIN                         | Common name of the certificate                                                                                                                                            |                         |
| ANS                            | Alternative names for the certificate (comma-separated)                                                                                                                   | stringa vuota           |
| CERT_TYPE                      | Type of certificate. Choose between DV (Domain Validation) or OV (Organization Validation)                                                                                | OV                      |
| HARICA_USERNAME                | Harica account email                                                                                                                                                      |                         |
| HARICA_PASSWORD                | Harica account password                                                                                                                                                   |                         |
| HARICA_TOTP_SEED               | TOTP seed used for 2FA                                                                                                                                                    |                         |
| HARICA_HTTP_PROXY              | HTTP Proxy (e.g. use when you don't have direct internet access)                                                                                                          | None                    |
| HARICA_HTTPS_PROXY             | HTTPS Proxy (e.g. use when you don't have direct internet access)                                                                                                         | None                    |
| HARICA_OUTPUT_FOLDER           | Destination folder for generated certificates                                                                                                                             | /app/harica_cerificates |
| ENVIRONMENT                    | Specify which Harica environment to use (production or stg)                                                                                                               | production              |
| SECTIGO_BACKWARD_COMPATIBILITY | Searches for expiring certificates belonging to $DOMAIN in the volume previously created by Sectigo                                                                       | false                   |
| USE_EXISTING_CSR               | Uses an existing CSR (not applicable to Sectigo)                                                                                                                          | false                   |
| FORCE_RENEWAL                  | Forces renewal before 30 days. It will create a file named `renewal_forced` under HARICA_OUTPUT_FOLDER. If you want to reforce renewal again, you must delete file first. | false                   |
| CHECK_FREQ                     | Certificate expiration check frequency (in hours)                                                                                                                         | 12                      |

## Hooks

It is possible to use hooks that should be mounted in the /app/hooks directory inside
the container. A basic example is provided in this repository, but multiple scenarios
are possible (container restart, permission changes, etc.).

## Notes

- The container runs with a non-root user. If necessary, you can enable the root user
  (see the example ``docker-compose`` file)
- If you are not using the Sectigo-related part, remember to add a bind volume for
  ``HARICA_OUTPUT_FOLDER``
- If you are using the Sectigo-related part, it is recommended to set
  ``HARICA_OUTPUT_FOLDER`` to the following path:
  ``HARICA_OUTPUT_FOLDER=/app/certbot/certs/archive/\<domain\>``

## Example of cert generation

Generating certificates is simple as using this docker-compose.

```yaml
services:
  auto-harica:
    container_name: harica
    image: auto-harica:test
    build:
      context: .
      dockerfile: Dockerfile
    # user: root
    restart: unless-stopped
    environment:
      - DOMAIN=testah.garr.it
      - ANS=testah-an1.garr.it,testah-an2.garr.it
      - HARICA_USERNAME=<your_email>
      - HARICA_PASSWORD=<your_password>
      - HARICA_TOTP_SEED=<your_totp_seed>
      - HARICA_OUTPUT_FOLDER=/app/certificates/testah.garr.it
    volumes:
      - ./certificates:/app/certificates
```

## Example of replacing Sectigo with Harica

### Before

```yaml
  certbot:
    container_name: certbot-sectigo
    image: docker/certbot-sectigo:latest
    restart: always
    env_file:
      - .env.certbot
    environment:
      - DOMAINS={{ satosa_certbot_fqdn_aliases | join(',') }}
    healthcheck:
      test: find /etc/letsencrypt/live/{{ satosa_certbot_fqdn_aliases | first }}/fullchain.pem
      interval: 10s
      retries: 30
      start_period: 45s
      timeout: 10s
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - {{ ansible_env.HOME }}/certbot/certs:/etc/letsencrypt:rw
      - {{ ansible_env.HOME }}/certbot/hooks/chmod_hook.sh:/etc/letsencrypt/renewal-hooks/deploy/chmod_hook.sh:rw
```

### After

If necessary, add:

- FORCE_RENEWAL=true

When mounting a volume, keep in mind that the script will start looking from:
CERT_DIR="/app/certbot/certs"

```yaml
  harica:
    container_name: auto-harica
    image: docker/auto-harica:latest
    restart: always
    environment:
      - SECTIGO_BACKWARD_COMPATIBILITY=true
      - DOMAIN={{ satosa_certbot_fqdn_aliases | first }}
      - ANS={{ satosa_certbot_fqdn_aliases | join(',') }}
      - HARICA_USERNAME={{ vault_harica_username }}
      - HARICA_PASSWORD={{ vault_harica_password }}
      - HARICA_TOTP_SEED={{ vault_harica_totp_seed }}
      - HARICA_OUTPUT_FOLDER=/app/certbot/certs/archive/{{ satosa_certbot_fqdn_aliases | first }}
    healthcheck:
      test: find /app/certbot/certs/live/{{ satosa_certbot_fqdn_aliases|first }}/fullchain.pem
      interval: 10s
      retries: 30
      start_period: 45s
      timeout: 10s
    volumes:
      - {{ ansible_env.HOME }}/certbot:/app/certbot:rw
      - {{ ansible_env.HOME }}/certbot/hooks/chmod_hook.sh:/app/hooks/chmod_hook.sh:rw
```

### Directory tree that clarifies mounting points

On host:

```bash
certbot
├── certs
│   ├── accounts
│   │   └── acme.sectigo.com
│   ├── archive
│   │   └── ds-test.garr.it
│   │       ├── cert1740425410.pem
│   │       ├── cert3.pem
│   │       ├── chain3.pem
│   │       ├── fullchain1740425410.pem
│   │       ├── fullchain3.pem
│   │       ├── harica.log
│   │       ├── privkey1740425410.pem
│   │       ├── privkey3.pem
│   │       ├── ds-test.garr.it.csr
│   │       ├── ds-test.garr.it.csr.id
│   │       ├── ds-test.garr.it.key
│   ├── csr
│   ├── keys
│   ├── live
│   │   └── ds-test.garr.it
│   │       ├── cert.pem -> ../../archive/ds-test.garr.it/cert1740425410.pem
│   │       ├── chain.pem -> ../../archive/ds-test.garr.it/chain3.pem
│   │       ├── fullchain.pem -> ../../archive/ds-test.garr.it/fullchain1740425410.pem
│   │       ├── privkey.pem -> ../../archive/ds-test.garr.it/privkey1740425410.pem
│   │       └── README
│   ├── renewal
│   └── renewal-hooks
└── hooks
```

Inside docker container (check also `HARICA_OUTPUT_FOLDER` var)

```bash
/app
|-- certbot
|   |-- certs
|   |   |-- accounts
|   |   |   `-- acme.sectigo.com
|   |   |-- archive
|   |   |   `-- ds-test.garr.it
|   |   |       |-- cert1740425410.pem
|   |   |       |-- cert3.pem
|   |   |       |-- chain3.pem
|   |   |       |-- fullchain1740425410.pem
|   |   |       |-- fullchain3.pem
|   |   |       |-- harica.log
|   |   |       |-- privkey1740425410.pem
|   |   |       |-- privkey3.pem
|   |   |       |-- ds-test.garr.it.csr
|   |   |       |-- ds-test.garr.it.csr.id
|   |   |       `-- ds-test.garr.it.key
|   |   |-- csr
|   |   |-- keys
|   |   |-- live
|   |   |   `-- ds-test.garr.it
|   |   |       |-- README
|   |   |       |-- cert.pem -> ../../archive/ds-test.garr.it/cert1740425410.pem
|   |   |       |-- chain.pem -> ../../archive/ds-test.garr.it/chain3.pem
|   |   |       |-- fullchain.pem -> ../../archive/ds-test.garr.it/fullchain1740425410.pem
|   |   |       `-- privkey.pem -> ../../archive/ds-test.garr.it/privkey1740425410.pem
|   |   |-- renewal
|   |   `-- renewal-hooks
|   `-- hooks
|-- env.sh
|-- harica.sh
|-- hooks
|   `-- chmod_hook.sh
|-- init.sh
|-- sectigo.sh
`-- utils.sh
```
