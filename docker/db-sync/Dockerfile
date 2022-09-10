FROM bitnami/postgresql:14 AS postgres

FROM docker.io/bitnami/minideb:bullseye AS downloader
RUN install_packages wget libpq5 libedit2
RUN wget --no-check-certificate -O /usr/local/bin/shareslake-db-sync https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.3/shareslake-db-sync && \
    chmod +x /usr/local/bin/shareslake-db-sync && \
    wget --no-check-certificate -O /usr/local/lib/libsodium.so.23 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.34.1/libsodium.so.23 && \
    wget --no-check-certificate -O /usr/local/lib/libsecp256k1.so.0 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/libsecp256k1.so.0

COPY --from=postgres /opt/bitnami/postgresql/bin/psql /usr/local/bin/psql

ENV LD_LIBRARY_PATH="/usr/local/lib"

RUN mkdir -p /ledger-state/mainnet && chmod -R g+rwX /ledger-state

USER 1001

ENTRYPOINT ["/usr/local/bin/shareslake-db-sync"]

