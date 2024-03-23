FROM ubuntu:23.10

WORKDIR /app
#COPY ["./Makefile", "./ramdisk-labs/initrd/", "/app"]

RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y make musl

RUN wget https://www.busybox.net/downloads/busybox-1.36.1.tar.bz2 \
    tar -xvjf ./busybox-1.36.1.tar.bz2 \
    cd ./busybox-1.36.1/ \
    make defconfig \
    sed -i 's/^.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/g' ./.config \
    make -j2 CC="musl-gcc -static" busybox

USER apprunner
