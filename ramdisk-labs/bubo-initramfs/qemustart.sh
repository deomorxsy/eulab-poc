#!/usr/bin/bash

sparse() {
    # prepare sparse file
    vdisk="./kernel-hd"

    if [ ! -e "$vdisk" ]; then
        dd if=/dev/zero of="$vdisk" bs=1M count=2048
        echo "file created"
    else
        echo "output already exists. Skipping..."
    fi
}

qemuit() {
    # run vm
    # initramfs-custom2.img created with arch-mkinitcpio.
    qemu-system-x86_64 \
        -kernel ../../kernel/linux-6.6.22/arch/x86/boot/bzImage \
        -initrd ./initramfs-custom2.img \
        -m 1G \
        -nographic \
        -append 'console=ttyS0' \
        -no-reboot \
        #-action panic=-1
}
