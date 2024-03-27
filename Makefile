SHELL=/bin/bash

getkernel=$(shell source ./initramfs.sh; getkernel)
bubo=$(shell source ./initramfs.sh; bubo)
initgen=$(shell source ./initramfs.sh; initgen)
qemuit=$(shell source ./initramfs.sh; qemuit)
vacuum=$(shell source ./initramfs.sh; vacuum)

build: kernel busybox
	@echo "Building..."

kernel:
	@echo "invoking linux..."
	@$(call getkernel) # builds the kernel and generates bzImage

busybox:
	@echo "invoking busybox..."
	@$(call bubo) # builds a static busybox ELF with musl-gcc

artifact:
	@echo "Generating initramfs..."
	@$(call initgen)

boot: initramfz.cpio.gz bzImage
	@echo "Booting on QEMU..."
	@$(call qemuit) # boots the kernel with the initramfs on QEMU

.PHONY: build
clean:
	@echo "Cleaning..."
	@$(call vacuum) # cleans the build files
