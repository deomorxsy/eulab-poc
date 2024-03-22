# eulab-poc
> simple early userspace lab setup for linux kernel dev with qemu

## Prerequisites
1. Get the [kernel](kernel.org) source and place it inside the ./kernel directory.
2. for the ramdisk, decide between the different ways. Then get busybox source.
3. for qemu, get the version specific for the architecture of your current CPU.

## Lab setup

Usage: build with the makefile subcommands.

1. initramfs setup
```
make initramfs
```

2. initrd setup
```
make initrd
```

3. mkinitcpio setup
```
make mkinitcpio
```
