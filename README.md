# eulab-poc
> simple early userspace lab proof-of-concept for linux kernel dev with qemu and busybox

[![Generate ramdisk](https://github.com/deomorxsy/eulab-poc/actions/workflows/ramdisk-builder.yml/badge.svg)](https://github.com/deomorxsy/eulab-poc/actions/workflows/ramdisk-builder.yml)
[![Generate bzImage](https://github.com/deomorxsy/eulab-poc/actions/workflows/kernel-builder.yml/badge.svg)](https://github.com/deomorxsy/eulab-poc/actions/workflows/kernel-builder.yml)

## Lab setup

Combine a kernel bzImage piggy and a initramfs ramdisk and boot it into QEMU. For actual boot into a machine, you will need a bootloader.

Usage:
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

4. The networking part is being handled by the TUN/TAP device method, using iproute2. The main idea is to run the network scripts as root but not the VM. Also, most of the QEMU documentation references debian-related networking scripts such as ifup, ifdown and ifconfig, which depends on the net-tools package that isn't covered here, and that can be replaced by iproute2.

5. Finally, the VLAN is handled using iproute2. This repo explores these two ways for Bridges:
- iptables bridge routing
- tun/tap bridge

## Booting the VM

The tricky part is the networking. As I've wrote [here](https://deomorxsy.github.io/tech/tap-virtual-networking-for-qemu/), there are 4 main points to grasp it fully:

- The relation between devices and interfaces under Linux (specifically for networking)
- The different packages to achieve this: the old net-tools and iproute2. This guide tries to use iproute2 tooling.
- Distro-specific scripts that wraps around tooling for virtual network setups. An example is Debian’s ifup(8) and ifdown(8) which is used by LFS (Linux From Scratch) and referenced by the QEMU networking docs. These are cited by a lot of QEMU guides for bridging, also having some late versions distributing similar scripts under /var
- Deprecated tools that were used in tutorials the last 15 years or so, like brctl that wraps around net-tools.


For the host OS: there are multiple ways to configure, and this repo goes with the tap network interface using the TUN/TAP module, where the packets are routed by a bridge network interface. By default QEMU uses SLIRP, but have problems with performance that are improved with tap/bridge.

For the guest OS: since busybox is used along with runit in init systems like openrc on gentoo or on alpine, these usually leans towards the [ifupdown-ng](https://manpages.debian.org/testing/ifupdown-ng/interfaces.5.en.html) package for network management alongside iproute2, which is also used in [debian](https://manpages.debian.org/testing/ifupdown-ng/interfaces.5.en.html).

This means

In [qemu-myifup.sh](./scripts/qemu-myifup.sh) are the commands to setup the network in the host os considering the environment described above.

The first thing is to configure the bridge:
```sh
# create bridge, set NIC as part of bridge,
# assign IP with CIDR subnet, bring up the bridge
ip link add name vmbr0 type bridge
ip link set enp4s0 master vmbr0
ip addr add "192.168.0.20/24" dev vmbr0
ip link set dev vmbr0 up
```

If in any moment the host connection goes down, bring it back and reassign the bridge master again:
```sh
ip link set enp4s0 nomaster
ip link set enp4s0 master vmbr0
```

At last, on the host OS side, the option ```-net bridge``` automatically uses the helper argument i.e. ```helper=/usr/lib/qemu/qemu-bridge-helper```, but it will raise an error if the user don't have access for its execution.

Permit user to use the bridge helper so you can run rootless QEMU
```
chmod +s  /usr/lib/qemu/qemu-bridge-helper
```

Now for the last setup:

```sh
cat << EOF > ./scripts/custom.sh
random_mac

qemu-system-x86_64 \
    -M pc \
    -kernel ./artifacts/bzImage \
    -initrd ./artifacts/initramfs.cpio.gz \
    -enable-kvm \
    -m 1024 \
    -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
    -nographic \
    -no-reboot \
    -drive file="./utils/storage/eulab-hd",format=raw \
    -net nic,model=virtio,macaddr="$macaddr" \
    -net bridge,br=vmbr0
EOF

chmod +x ./scripts/custom.sh
```

