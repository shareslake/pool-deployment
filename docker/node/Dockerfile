FROM docker.io/bitnami/minideb:bullseye AS downloader
RUN install_packages wget libpq5 libedit2 netbase
COPY download-files.sh /tmp/download-files.sh
RUN /tmp/download-files.sh

ENV LD_LIBRARY_PATH="/opt/shareslake/lib" \
    PATH="/opt/shareslake/bin:$PATH"

USER 1001

ENTRYPOINT ["/opt/shareslake/bin/shareslake-node"]

CMD ["run","--config", "/opt/shareslake/configuration/configuration-mainnet.yaml", "--topology", "/opt/shareslake/configuration/topology.json", "--database-path", "/opt/shareslake/node-db","--socket-path", "/opt/shareslake/node-ipc/node.sock", "--port", "3001"]

