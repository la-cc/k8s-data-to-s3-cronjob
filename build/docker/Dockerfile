# First stage: Install tools as root
FROM python:3.11-alpine as builder

LABEL MAINTAINER="la-cc@github"
LABEL org.opencontainers.image.source="https://github.com/la-cc/k8s-pg-to-s3-cronjob"
LABEL EMAIL="artem@lajko.dev"

# Install build dependencies
RUN apk add --no-cache \
    postgresql-client \
    openssl \
    zip \
    p7zip \
    git \
    curl \
    groff \
    less \
    && apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    python3-dev \
    cargo \
    && pip install --upgrade pip \
    && pip install awscli \
    && pip install awscli awscli-plugin-endpoint \
    && apk del .build-deps

# Second stage: Setup with non-root user
FROM python:3.11-alpine

# Metadata as defined in OCI image spec annotations
LABEL MAINTAINER="la-cc@github"
LABEL org.opencontainers.image.source="https://github.com/la-cc/k8s-pg-to-s3-cronjob"
LABEL EMAIL="artem@lajko.dev"

# Set environment variables
## AWS S3
ENV AWS_S3_ENDPOINT_URL=""
ENV AWS_S3_ACCESS_KEY_ID=""
ENV AWS_S3_SECRET_ACCESS_KEY=""
ENV AWS_S3_BUCKET=""


## Webhook
ENV WEBHOOK_ENDPOINT=""
ENV ENABLE_WEBHOOK_ENDPOINT=true

## Encryption key
ENV ENCRYPTION_KEY=""

## File path or paths of files to be backed up
ENV FILE_PATH=""
ENV DIRECTORY_PATH=""


# Install runtime dependencies
RUN apk add --no-cache \
    postgresql-client \
    openssl \
    curl \
    zip \
    libstdc++ \
    libgcc


# Copy installed binaries and libraries from the builder stage
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/bin/pg_dump /usr/bin/pg_dump
COPY --from=builder /usr/bin/openssl /usr/bin/openssl
COPY --from=builder /usr/bin/curl /usr/bin/curl
COPY --from=builder /usr/bin/zip /usr/bin/zip
COPY --from=builder /usr/bin/7z /usr/bin/7z


# Create a non-root user 'backupuser'
RUN addgroup -S backupuser && adduser -S backupuser -G backupuser

# Set work directory and switch to non-root user
WORKDIR /home/backupuser
COPY /build/docker/scripts/entrypoint.sh  .

USER backupuser

# Adjust the ENTRYPOINT as needed, for now, it's set to keep the container running
ENTRYPOINT [ "./entrypoint.sh", "-f"]

# For debugging purposes, keep the container running
#ENTRYPOINT ["tail", "-f", "/dev/null"]
