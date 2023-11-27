FROM alpine:3.18.4
ADD https://storage.yandexcloud.net/final-homework/bingo /usr/bin
RUN chown 1001:1001 /usr/bin/bingo && \
    chmod 750 /usr/bin/bingo && \
    mkdir -p /opt/bongo/logs/c863ac3e8e && \
    chown 1001:1001 /opt/bongo/logs/c863ac3e8e && \
    chmod 775 /opt/bongo/logs/c863ac3e8e
HEALTHCHECK --start-period=60s --interval=1s --timeout=1s --retries=1 CMD wget -qO - http://localhost:13526/ping || exit 1
USER 1001
ENTRYPOINT ["/usr/bin/bingo"]
