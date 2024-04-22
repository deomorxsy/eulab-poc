SHELL=/bin/bash

getkernel=$(shell source ./initramfs.sh; getkernel)
bubo=$(shell source ./initramfs.sh; bubo)
distro_artifact=$(shell source ./initramfs.sh; distro_artifact)
sparse=$(shell source ./initramfs.sh; sparse)
qemuit=$(shell source ./initramfs.sh; qemuit)
vacuum=$(shell source ./initramfs.sh; vacuum)

build: kernel busybox
	@echo "Building..."

kernel:
	@echo "invoking linux..."
	source ./scripts/ccr.sh; checker && \
	source ./initramfs.sh; getkernel

busybox:
	@echo "invoking busybox..."
	source ./scripts/ccr.sh; checker && \
	#chmod +rx ./initramfs.sh ./scripts/ccr.sh && \
	./scripts/ccr.sh checker && \
    ./initramfs.sh bubo
	#source ./initramfs.sh; bubo

distro_artifact:
	@echo "Generating initramfs..."
	source ./scripts/ccr.sh; checker && \
	source ./initramfs.sh; distro_artifact

boot: initramfz.cpio.gz bzImage
	@echo "Booting on QEMU..."
	source ./initramfs.sh; qemuit
	# boots the kernel with the initramfs on QEMU

.PHONY: build
clean:
	@echo "Cleaning..."
	source ./initramfs.sh; vacuum
	#@$(call vacuum) # cleans the build files


# build into OCI containers. The docker-compose is being run as a Podman Service
# systemd's socket unit file. There is no need for "--file=" flag because of
# the build context that is being specified into the compose.yml. Without this,
# the COPY build context would be difficult because there would be the need of a
# script workaround since the build context for the container runtimes is the same
# as where the Dockerfile is located, passed by the "--file=" argument flag.
#
# btw, the same is true for the context of the .dockerignore. So, the OCI build
# context affects at least: dockerfile COPY build context and .dockerignore
containerize: build_linux build_bubo
build_bubo:
	@echo "Building busybox container..."
	source ./scripts/ccr.sh; checker && \
	docker compose -f ./compose.yml --progress=plain build busybox
build_linux:
	@echo "Building the Linux kernel container..."
	source ./scripts/ccr.sh; checker && \
	docker compose -f ./compose.yml build linux


up_bubo:
	@echo "Running the busybox container entrypoint..."
	source ./scripts/ccr.sh; checker && \
		docker compose -f ./compose.yml up busybox

down_bubo:
	@echo "Shutting down the busybox container entrypoint..."
	source ./scripts/ccr.sh; checker && \
		docker compose -f ./compose.yml down busybox
