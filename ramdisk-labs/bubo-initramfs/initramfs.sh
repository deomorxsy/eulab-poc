#!/usr/bin/bash

#
## 1. enter fakeroot context
## 2. create rootfs directories
## 3. generate init script from bash heredoc
## 4. exit fakeroot

initgen() {
    fakeroot sh -c '

    mkdir -p ramdisk/{bin,dev,etc,lib,mnt/root,proc,root,sbin,sys,tmp,var}

    cat > ./ramdisk/init << EOF
    #!/bin/busybox sh
    mount -t devtmpfs   devtmpfs    /dev
    mount -t proc       proc        /proc
    mount -t sysfs      sysfs       /sys
    mount -t tmpfs      tmpfs       /tmp

    sh
    EOF

    cd ./ramdisk || exit
    chmod +x ./init
    find . -print0 | busybox cpio --null --create --verbose --format=newc | gzip --best > ../initramfz.cpio.gz
    cd - || exit
    '
    # exit fakeroot context
    exit
}

