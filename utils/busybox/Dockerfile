#FROM cgr.dev/chainguard/rust as build

#RUN echo 'fn main() { println!("Hello Rust users!"); }' > hello.rs
#RUN rustc -C target-feature=+crt-static hello.rs

#FROM alpine:3.18 as distro

#WORKDIR /app/
#COPY ["./initramfs.sh", "./Makefile", "."]
#COPY ./scripts/ccr.sh ./scripts/


#RUN mkdir -p ./utils/busybox
#RUN chmod +rx ./initramfs.sh ./scripts/ccr.sh
#RUN ./scripts/ccr.sh checker
#RUN ./initramfs.sh bubo

#RUN apk add make gcc
#RUN source ./scripts/ccr.sh; checker
#RUN source ./initramfs.sh; bubo

#FROM cgr.dev/chainguard/static:latest

#COPY --from=build /work/hello /hello
#CMD ["/hello"]
FROM busybox:1.36.1-musl as builder

#FROM alpine:3.18 as relay
# get ci artifact
#COPY ./utils/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage ./app/artifacts/
FROM alpine:3.18 as relay

WORKDIR /ramdisk/
RUN mkdir -p ./{bin,dev,etc,lib,mnt/root,proc,root,sbin,sys,tmp,var}
COPY --from=builder /* .
#RUN ln -s /bin/busybox ./linuxrc
RUN <<"EOF"
cp ./utils/busybox/busybox-1.36.1/busybox ./ramdisk/
for binary in $(./ramdisk/busybox --list); do
    #ln -s /bin/busybox ./ramdisk/bin/"$binary"
    ln -s /bin/busybox ./ramdisk/sbin/"$binary"
    ln -s /bin/busybox ./ramdisk/usr/bin/"$binary"
    ln -s /bin/busybox ./ramdisk/usr/sbin/"$binary"
done
EOF

RUN cat > ./init <<EOF
#!/bin/busybox sh
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       none        /proc
mount -t sysfs      none       /sys
mount -t tmpfs      tmpfs       /tmp

sysctl -w kernel.printk="2 4 1 7"

printf "\nASCIIart didn't go well...
Boot took $(cut -d' ' -f1 /proc/uptime) seconds btw\n
"

# get a shell
sh
EOF

FROM alpine:3.18 as packer

WORKDIR /app/

COPY --from=relay /ramdisk/ /app/ramdisk/

RUN chmod +x ./ramdisk/init && \
    cd ./ramdisk || return && \
    find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz && \
    cd - || return


#FROM scratch as empty
FROM alpine:3.18 as empty

COPY --from=packer /app/initramfs.cpio.gz .

ENTRYPOINT ["/bin/sh"]
