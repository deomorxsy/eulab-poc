# include shellscripts
include ./ramdisk-labs/bubo-initramfs/initramfs.sh
include ./ramdisk-labs/bubo-initramfs/qemustart.sh
include ./ramdisk-labs/initrd/bubo.sh
include ./ramdisk-labs/initrd/getkernel.sh

.PHONY:
	build
	boot

all:
	build

build:
	@echo "Building...\n"

	@echo "=== linux ==="
    @$(call getkernel)

	@echo "=== busybox ==="
    @$(call bubo $(BUBO_PATH)) # function inside bubo.sh script

	@echo "=== initgen ==="
	@$(call initgen) # function inside initramfs.sh script

	@echo "=== setup sparse file ==="
	@$(call sparse) # function inside qemustart.sh script


boot:
	@echo "Booting on QEMU...\n"
	@$(call qemuit) # function inside qemustart.sh script

clean:
	rm -rf ./utils/kernel/linux-*
	rm -rf ./utils/busybox/*

