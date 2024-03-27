#!/usr/bin/bash

KERNEL_VERSION=6.6.22
BUSYBOX_VERSION=1.36.1

function getkernel() {
	version="./utils/kernel/linux-${KERNEL_VERSION}/"

	if [ ! -e $version ]; then
		wget -P ./utils/kernel/ https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
		tar -xvf ./utils/kernel/linux-${KERNEL_VERSION}.tar.xz -C ./utils/kernel/
	else
		echo "linux source already downloaded"
	fi
	# or simply make -f
	cd ./utils/kernel/linux-${KERNEL_VERSION}/ || exit
	make defconfig
	make kvmconfig
	make olddefconfig
	make bzImage
	make -j2
	cd - || return
}

function bubo() {
	#dirbusy="../../utils/busybox/busybox-1.36.1.tar.bz2"
	dirbusy="busybox-${BUSYBOX_VERSION}.tar.bz2"

	if [ ! -e ./utils/busybox/${dirbusy} ]; then
		wget -P ./utils/busybox/ https://www.busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
		tar -xvjf ./utils/busybox/${dirbusy} -C ./utils/busybox/

	else
		printf "\n===== busybox already downloaded =====\n"
	fi

	cd "./utils/busybox/busybox-${BUSYBOX_VERSION}" || exit
	#cd ./busybox-1.36.1/ || exit
	make defconfig
	sed -i 's/^.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/g' ./.config
	make -j2 CC="musl-gcc -static" busybox || exit
    make install
	cd - || return
}

function initgen() {
cp ./utils/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage ./

mkdir -p ./ramdisk/{bin,dev,etc,lib,mnt/root,proc,root,sbin,sys,tmp,var}

#cp ./utils/busybox/busybox-1.36.1/busybox ./ramdisk/
#for binary in $(./ramdisk/busybox --list); do
#    ln -s /bin/busybox ./ramdisk/bin/"$binary"
#done

# the previous loop didn't do it with sbin and usr
#
cp -a ./utils/busybox/busybox-1.36.1/_install/* ./ramdisk/


#fakeroot sh -c '
cat > ./ramdisk/init <<EOF
#!/bin/busybox sh
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       proc        /proc
mount -t sysfs      sysfs       /sys
mount -t tmpfs      tmpfs       /tmp

sysctl -w kernel.printk="2 4 1 7"

EOF
# get a shell with sh before the EOF if needed.
# exit fakeroot context
#exit
#'

# append ASCII art
cat >> ./ramdisk/init <<EOF
/***
 *      _ _
 *     | (_)
 *     | |_ _ __  _   ___  __
 *     | | | '_ \| | | \ \/ /
 *     | | | | | | |_| |>  <
 *     |_|_|_| |_|\__,_/_/\_\
 *
 *
 */ Boot took $(cut -d' ' -f1 /proc/uptime) seconds btw

# get a shell
sh
EOF

chmod +x ./ramdisk/init
find ./ramdisk/ -print0 | busybox cpio --null --create --verbose --format=newc | gzip --best > ./initramfz.cpio.gz
#printf "cadeeeeeeeee\n"

}

function qemuit() {
	# run vm
	# initramfs-custom2.img created with arch-mkinitcpio.
	qemu-system-x86_64 \
		-kernel ./bzImage \
		-initrd ./initramfz.cpio.gz \
		-m 1G \
		-append 'console=ttyS0' \
		-no-reboot \
	#-action panic=-1
}

function vacuum() {
    rm -rf ./utils/kernel/lin*
    rm -rf .utils/busybox/busy*
}

# path to utils passed by the Makefile
#bubo "$1"
