FROM debian:12.1 AS debian-builder
ARG BUSYBOX_VERSION=1.36.1

# build dependencies

RUN <<"EOF"
apt-get update
apt-get install build-essential wget musl-tools tree make -y
EOF

WORKDIR /app/
COPY ["initramfs.sh", "Makefile", "."]

RUN mkdir -p ./utils/busybox/ && \
    make busybox && \
    cp -r ./utils/busybox/busybox-${BUSYBOX_VERSION}/_install ./_install
    rm -rf ./utils/busybox/busybox-*


#RUN ls -allht
#RUN tree -C -L 3

FROM alpine:3.18 as relay

WORKDIR /app/

COPY --from=debian-builder /app/ /app/
RUN tar -zcvf ./bubo.tar.gz ./_install/*

ENTRYPOINT ["/bin/sh"]
