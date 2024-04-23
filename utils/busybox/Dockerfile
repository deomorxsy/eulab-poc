FROM busybox:1.36.1-musl as builder
# just to get the statically compiled files

FROM alpine:3.18 as relay

WORKDIR /ramdisk/
RUN mkdir -p bin dev etc lib mnt/root proc root sbin sys tmp var
COPY --from=builder / .
#RUN ln -s /bin/busybox ./linuxrc
RUN <<"EOF"
cp ./utils/busybox/busybox-1.36.1/busybox ./ramdisk/
for binary in $(./ramdisk/busybox --list); do
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
echo && echo

cat << 'asciiart'
  .-"``"-.
 /  _.-` (_) `-._
 \   (_.----._)  /
  \     /    \  /            _       _
   `\  \____/  /`           | |     | |
     `-.____.-`   ____ _   _| | ____| | _
      /      \   / _  ) | | | |/ _  | || \
     /        \ ( (/ /| |_| | ( ( | | |_) )
    /_ |  | _\   \____)\____|_|\_||_|____/
      |  | |                              deomorxsy/eulab-poc
      |__|__|  ----------------------------------------------
      /_ | _\   Reboot (01.00.0, r3500-0f87d95)
               ----------------------------------------------
asciiart

printf "Boot took $(cut -d' ' -f1 /proc/uptime) seconds btw\n"

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

