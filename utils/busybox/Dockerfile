#FROM alpine:3.18 as builder
FROM debian:12.1 AS debian-builder

# 2. build dependencies

#FROM debian-builder AS dependencies
RUN <<"EOF"
apt-get update
apt-get install build-essential wget musl-tools tree make -y
EOF

WORKDIR /app/
COPY ["initramfs.sh", "Makefile", "."]
COPY ["./utils/busybox/busybox-*/", "./utils/busybox/_install/"]

#RUN apk update && apk add build-base libelf make gcc musl-dev

#BUSYBOX_VERSION=1.36.1
CMD ["make", "busybox"]
#CMD ["make", "clean"]

RUN ls -allht
RUN tree -C -L 3

FROM alpine:3.18 as relay

WORKDIR /app/
COPY --from=debian-builder /app/ /app/

#COPY --from=debian-builder ./utils/busybox/_install/ ./utils/busybox/_install/

RUN tar -zcvf ./bubo.tar.gz ./utils/busybox/_install/* && \
    rm -rf ./utils/*

ENTRYPOINT ["/bin/sh"]
