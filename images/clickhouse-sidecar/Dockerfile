FROM yandex/clickhouse-client:20.1

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.9/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85

COPY cleanup-clickhouse-partitions.sh /usr/local/bin/cleanup-clickhouse-partitions.sh

RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/cleanup-clickhouse-partitions.sh \
    && mkdir /app && chmod 777 /app \
    && adduser --disabled-password --system --home /app --shell /bin/bash --no-create-home --uid 7000 app

WORKDIR /app
USER app
CMD /usr/local/bin/supercronic ${SUPERCRONIC_ARGS}