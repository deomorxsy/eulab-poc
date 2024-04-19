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
    #make kvmconfig removed after Linux 5.10
    make kvm_guest.config
    echo "kvm_guest.config done"
	make olddefconfig
    echo "olddefconfig done"
	make bzImage
    echo "bzImage done"
    make -j"$(nproc)"
    echo "final kernel make done"
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

    if command -v musl-gcc &>/dev/null; then
        make -j"$(nproc)" CC="musl-gcc -static" busybox || return
    else
        make -j"$(nproc)" busybox || return
    fi

    make install
	cd - || return
}

function setbridge() {
    sudo brctl addbr br0
    sudo brctl addif br0 eth0
    sudo ip link set dev br0 up
    sudo brctl show
}

function distro_artifact() { #generates the initramfs ramdisk
# CI todo: copy bzImage artifact from context and place it into current
cp ./utils/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage ./artifacts/

mkdir -p ./ramdisk/{bin,dev,etc,lib,mnt/root,proc,root,sbin,sys,tmp,var}

#cp ./utils/busybox/busybox-1.36.1/busybox ./ramdisk/
#for binary in $(./ramdisk/busybox --list); do
#    ln -s /bin/busybox ./ramdisk/bin/"$binary"
#done

# the previous loop didn't do it with sbin and usr
#

#
# CI todo: get busybox build from context and place it on current
cp -a ./utils/busybox/busybox-1.36.1/_install/* ./ramdisk/


#fakeroot sh -c '
cat > ./ramdisk/init <<EOF
#!/bin/busybox sh
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       none        /proc
mount -t sysfs      none       /sys
mount -t tmpfs      tmpfs       /tmp

sysctl -w kernel.printk="2 4 1 7"

EOF
# get a shell with sh before the EOF if needed.
# exit fakeroot context
#exit
#'

# append ASCII art
cat >> ./ramdisk/init <<"EOF"

printf "\nASCIIart didn't go well...
Boot took $(cut -d' ' -f1 /proc/uptime) seconds btw\n
"

# get a shell
sh
EOF

chmod +x ./ramdisk/init
cd ./ramdisk/ || return
#find . -print0 | busybox cpio --null --create --verbose --format=newc | gzip --best > ./initramfz.cpio.gz
find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../artifacts/initramfs.cpio.gz
cd - || return

# ci todo: release as artifact
}

function sparseFile() {
    SPARSE="./utils/storage/eulab-hd"
    dd if=/dev/zero of=$SPARSE bs=1M count=2048
    mkfs.ext4 $SPARSE
}

function virtstoraged() {
    QCOW_FILE="./utils/storage/eulab.qcow2"

    if [ ! -e $QCOW_FILE ]; then
        echo "Creating qcow2 image..."
        qemu-img create -f qcow2 $QCOW_FILE 1G
        guestmount -a $QCOW_FILE -i --ro /mnt
    elif [ -e $QCOW_FILE ]; then
        echo "Mounting qcow2 image into /mnt..."
        guestmount -a $QCOW_FILE -i --ro /mnt
    fi

}

function qemuit() {
	# run vm
	# initramfs-custom2.img created with arch-mkinitcpio.
	qemu-system-x86_64 \
		-kernel ./artifacts/bzImage \
		-initrd ./artifacts/initramfs.cpio.gz \
		-m 1024 \
		-append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
		-no-reboot \
        -drive file=./utils/storage/eulab--hd,format=raw \
        -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10021-:22 \
        -net nic,model=e1000 \
        #-netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9,restrict=yes \
        #-object filter-dump,id=f1,netdev=mynet0,file=dump.dat \
        #-nic user,ipv6=off,model=rtl8139,mac=10:10:10:10:10:11
        #--enable-kvm \
	#-action panic=-1
}

function vacuum() {
    KERNEL_ART_PATH="./utils/kernel/lin*"
    BUBO_ART_PATH="./utils/busybox/busy*"
    SPARSE_ART_PATH="./utils/storage/kernel-hd"

    # kernel
    if [ -e "$KERNEL_ART_PATH" ] || [ -d "$KERNEL_ART_PATH" ]; then
        echo "Kernel assets found. Cleaning now..."
        rm -rf "./utils/kernel/lin*"
    else
        echo "No build assets found in the kernel directory."
    fi

    # busybox
    if [ -e "$BUBO_ART_PATH" ] || [ -d "$BUBO_ART_PATH" ]; then
        echo "Busybox assets found. Cleaning now..."
        rm -rf "./utils/busybox/busy*"
    else
        echo "No build assets found in the busybox directory"
    fi

    # sparse file
    if [ -e $SPARSE_ART_PATH ]; then
        shred -z -n 3 $SPARSE_ART_PATH
        rm $SPARSE_ART_PATH
    else
        echo "No sparse file asset found in the storage directory"
    fi

    # qcow2 disk image
    QCOW_FILE="./utils/storage/eulab.qcow2"

    if [ -e "$QCOW_FILE" ]; then
        guestunmount /mnt
        shred -z -n 3 $QCOW_FILE
        rm $QCOW_FILE
    fi

}

# path to utils passed by the Makefile
#bubo "$1"
