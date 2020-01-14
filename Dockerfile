FROM alpine:3.11 AS builder

COPY ./patches /mtproxy/patches

RUN apk add --no-cache --virtual .build-deps \
      git make gcc musl-dev linux-headers openssl-dev zlib-dev libcrypto1.1 \
    && git clone --single-branch --depth 1 https://github.com/TelegramMessenger/MTProxy.git /mtproxy/sources \
    && cd /mtproxy/sources \
    && echo "Patch [randr_compat]:" \
    && patch -p0 -i /mtproxy/patches/01-randr_compat.patch \
    && echo "Patch [timer]:" \
    && patch -p1 -i /mtproxy/patches/02-timer.patch \
    && make -j$(getconf _NPROCESSORS_ONLN)

FROM alpine:3.11
LABEL maintainer="Evgeniy Kulikov <im@kulikov.im>" \
      description="Telegram Messenger MTProto zero-configuration proxy server."

RUN apk add --no-cache libcrypto1.1 curl

WORKDIR /mtproxy

COPY --from=0 /mtproxy/sources/objs/bin/mtproto-proxy .
COPY docker-entrypoint.sh /

VOLUME /data
EXPOSE 2398 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ \
  "--port", "2398", \
  "--http-ports", "443", \
  "--slaves", "2", \
  "--max-special-connections", "60000", \
  "--allow-skip-dh" \
]
