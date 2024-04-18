# 1. add deb-src
FROM debian:12.1 AS debian-builder

COPY <<EOF /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main
deb-src http://deb.debian.org/debian bookworm main

deb http://deb.debian.org/debian-security/ bookworm-security main
deb-src http://deb.debian.org/debian-security/ bookworm-security main

deb http://deb.debian.org/debian bookworm-updates main
deb-src http://deb.debian.org/debian bookworm-updates main
EOF

# 2. build dependencies

FROM debian-builder AS dependencies
RUN <<"EOF"
apt-get update
apt-get install build-essential wget git -y
apt-get build-dep linux -y
EOF


# 3. fetch kernel config

FROM dependencies AS download-boot
ARG KERNEL_VERSION=6.6.22

RUN <<"EOF"

WORKDIR /app
mkdir -p ./utils/kernel/
version="./utils/kernel/linux-${KERNEL_VERSION}/"

if [ ! -e $version ]; then
    wget -P ./utils/kernel/ https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
    tar -xvf ./utils/kernel/linux-${KERNEL_VERSION}.tar.xz -C ./utils/kernel/
    rm ./utils/kernel/linux-${KERNEL_VERSION}.tar.xz
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
EOF


