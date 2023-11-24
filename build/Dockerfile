FROM alpine:3.18.4
ADD --chmod=750 https://storage.yandexcloud.net/final-homework/bingo /usr/bin
RUN mkdir -p /opt/bongo/logs/c863ac3e8e && chown 1001:1001 /opt/bongo/logs/c863ac3e8e && chmod 775 /opt/bongo/logs/c863ac3e8e
USER 1001
ENTRYPOINT ["/usr/bin/bingo"]