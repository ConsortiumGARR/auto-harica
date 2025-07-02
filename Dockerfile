ARG TCS_VERSION=0.24.0
FROM ghcr.io/consortiumgarr/tcs-garr:${TCS_VERSION}

ARG USER=tcs
ARG GROUP=tcs

ENV ANS=""
ENV CERT_TYPE=OV
ENV CHECK_FREQ=12
ENV ENVIRONMENT=production
ENV FORCE_RENEWAL=false
ENV HARICA_OUTPUT_FOLDER=/app/harica_cerificates
ENV SECTIGO_BACKWARD_COMPATIBILITY=false
ENV USE_EXISTING_CSR=false

COPY --chown=$USER:$GROUP init.sh env.sh sectigo.sh utils.sh harica.sh ./
RUN chmod +x /app/*.sh && mkdir /app/hooks

ENTRYPOINT [ "/app/init.sh" ]
