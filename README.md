# eulab-poc
> simple early userspace lab proof-of-concept for linux kernel dev with qemu and busybox

[![Generate bzImage](https://github.com/deomorxsy/eulab-poc/actions/workflows/kernel-builder.yml/badge.svg)](https://github.com/deomorxsy/eulab-poc/actions/workflows/kernel-builder.yml)
[![Build busybox](https://github.com/deomorxsy/eulab-poc/actions/workflows/bubo-builder.yml/badge.svg)](https://github.com/deomorxsy/eulab-poc/actions/workflows/bubo-builder.yml)

## Lab setup

Usage: build with the Makefile subcommands.

1. initramfs setup
```
make build
```

1. build and boot on QEMU:
```
make all
```

## Prerequisites and cases

1. For QEMU, get the version specific for the architecture of your current CPU.

2. The build environment will compile a statically compiled busybox with musl-gcc, which usually means that kernel headers suited for musl are needed. In arch, [kernel-headers-musl](https://archlinux.org/packages/extra/x86_64/kernel-headers-musl/) is the [PKGBUILD](https://gitlab.archlinux.org/archlinux/packaging/packages/kernel-headers-musl/-/blob/main/PKGBUILD?ref_type=heads) porting the kernel headers provided by the [Sabotage linux](https://github.com/sabotage-linux/kernel-headers) distro.

3. The previous statement also means that to be able to build this in a OCI container means that the container have to be running under a linux distro with previously installed kernel headers, be it a host or a virtual machine. If the compilation is not the point, but the use cases of the binary, just use the [official image](https://hub.docker.com/_/busybox)

