# include shellscripts
include ./ramdisk-labs/bubo-initramfs/initramfs.sh
include ./ramdisk-labs/bubo-initramfs/qemustart.sh

build:
	@echo "Building...\n"
	@echo "=== initgen ==="
	@$(call initgen) # function inside initramfs.sh script

	@echo "=== setup sparse file ==="
	@$(call sparse) # function inside qemustart.sh script

	@echo "=== run qemu lab ==="
	@$(call qemuit) # function inside qemustart.sh script

.PHONY:
	build
