# eulab-poc
> simple early userspace lab proof-of-concept for linux kernel dev with qemu and busybox

[![Generate ramdisk](https://github.com/deomorxsy/eulab-poc/actions/workflows/ramdisk-builder.yml/badge.svg)](https://github.com/deomorxsy/eulab-poc/actions/workflows/ramdisk-builder.yml)
[![Generate bzImage](https://github.com/deomorxsy/eulab-poc/actions/workflows/kernel-builder.yml/badge.svg)](https://github.com/deomorxsy/eulab-poc/actions/workflows/kernel-builder.yml)

## Lab setup

Combine a kernel bzImage piggy and a initramfs ramdisk and boot it into QEMU. For actual boot into a machine, you will need a bootloader.

Use cases:
1. To get Dockerfile and build context in separate directories, use compose.
2. To tinker with the builds, use any OCI container runtime
3. To check how automated build fits into this, use Makefile.
4. Want to locally test the CI? Check [@nektos/act](https://github.com/nektos/act)
5. Want to test the artifacts? Download them into the artifacts directory and feed them into QEMU with the [qemuit function](https://github.com/deomorxsy/eulab-poc/blob/194ade5144640d079efdbc27fe25314ea56c70dd/initramfs.sh#L145) or with ```make boot```
6. You have built any artifact with the shellscript or make and now want to get rid of it? ```make clean```.

## Prerequisites and cases

1. For QEMU, get the version specific for the architecture of your current CPU.

2. The build environment calling the shellscript will compile a statically compiled busybox with musl-gcc instead of glibc, which heavily depends on kernel headers suited for musl. In arch, [kernel-headers-musl](https://archlinux.org/packages/extra/x86_64/kernel-headers-musl/) is the [PKGBUILD](https://gitlab.archlinux.org/archlinux/packaging/packages/kernel-headers-musl/-/blob/main/PKGBUILD?ref_type=heads) porting the kernel headers provided by the [Sabotage linux](https://github.com/sabotage-linux/kernel-headers) distro.

3. The previous statement also means that to be able to build this in a OCI container, it have to be running under a linux distro with previously installed kernel headers, be it a host OS or a guest OS virtual machine. If the compilation is not the point, but the use cases of the binary (get an initramfs ramdisk working) just use the [official image](https://hub.docker.com/_/busybox) as previous step with multi-stage containerfile build.

## Booting the VM

```sh
cat << EOF > ./scripts/run.sh
qemu-system-x86_64 \
    -kernel ./artifacts/bzImage \
    -initrd ./artifacts/initramfs.cpio.gz \
    -m 1024 \
    -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
    -nographic \
    -no-reboot \
    -drive file=./utils/storage/eulab-hd,format=raw \
    #-net nic -net user \
    #-nic user,ipv6=off,model=rtl8139,mac=52:54:XX:XX:XX:XX \
    -net nic,macaddr=52:54:XX:XX:XX:XX -net vde
EOF

chmod +x ./scripts/run.sh
```

