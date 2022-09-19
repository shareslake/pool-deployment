FROM docker.io/bitnami/minideb:bullseye

RUN install_packages wget

RUN wget --no-check-certificate -O /usr/local/bin/shareslake-submit-api https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.3/shareslake-submit-api && \
    chmod +x /usr/local/bin/shareslake-submit-api && \
    wget --no-check-certificate -O /usr/local/lib/libsodium.so.23 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.34.1/libsodium.so.23 && \
    wget --no-check-certificate -O /usr/local/lib/libsecp256k1.so.0 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/libsecp256k1.so.0

ENV LD_LIBRARY_PATH="/usr/local/lib"

COPY ./config.yaml /config.yaml

USER 1001

ENTRYPOINT ["/usr/local/bin/shareslake-submit-api"]
CMD ["--config", "config.yaml", "--mainnet", "--socket-path", "/node-ipc/node.socket", "--listen-address", "0.0.0.0"]
