FROM ubuntu:24.04 AS builder

ARG TELEGRAM_BOT_API_REF=adfd7f6a8e990272851777eeb3ae0def4216f161

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        g++ \
        git \
        gperf \
        libssl-dev \
        make \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /src \
    && git -C /src checkout --detach "$TELEGRAM_BOT_API_REF" \
    && git -C /src submodule update --init --recursive

WORKDIR /src

RUN cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
    && cmake --build build --target install --parallel

FROM ubuntu:24.04 AS runtime

ARG TELEGRAM_BOT_API_REF=adfd7f6a8e990272851777eeb3ae0def4216f161

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libgcc-s1 \
        libssl3t64 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 101 telegram-bot-api \
    && useradd --system --uid 101 --gid 101 --home-dir /var/lib/telegram-bot-api --shell /usr/sbin/nologin telegram-bot-api \
    && mkdir -p /var/lib/telegram-bot-api \
    && chown -R telegram-bot-api:telegram-bot-api /var/lib/telegram-bot-api

COPY --from=builder /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
COPY --from=builder /src/LICENSE_1_0.txt /usr/share/doc/telegram-bot-api/LICENSE_1_0.txt
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

LABEL org.opencontainers.image.source="https://github.com/tdlib/telegram-bot-api" \
      org.opencontainers.image.revision="$TELEGRAM_BOT_API_REF" \
      org.opencontainers.image.licenses="BSL-1.0"

WORKDIR /var/lib/telegram-bot-api
USER telegram-bot-api
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
