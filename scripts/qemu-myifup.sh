#!/bin/sh
#
# allow all instead. virtbr0 is an arbitrary name for the virtual bridge
echo "allow vmbr0" | sudo tee "/etc/qemu/${USER}.conf"
echo "include /etc/qemu/${USER}.conf" | sudo tee --append "/etc/qemu/bridge.conf"

# permit user to use the bridge to run rootless QEMU
chmod +s  /usr/lib/qemu/qemu-bridge-helper

# create the network bridge, deprecated brctl
#brctl addbr vmbr0
#brctl addif vmbr0 enp3s0

# create bridge, set NIC as part of bridge,
# assign IP with CIDR subnet, bring up the bridge
ip link add name vmbr0 type bridge
ip link set enp4s0 master vmbr0
ip addr add "192.168.0.20/24" dev vmbr0
ip link set dev vmbr0 up

# bring back connection to the host
ip link set enp4s0 nomaster
ip link set enp4s0 master vmbr0

# on the guest os vm
#
# 1. statically via udhcpc
ip addr add "$(udhcpc 2>&1 | awk 'NR==4 {print $4}')" dev eth0
#
# 2. statically via iproute2
#/sbin/ip a add 192.168.0.27/24 dev "$1" DOES NOT WORK, USE UDHCPC
#
#
# 3. dinamically, just run udhcpc
# run these two before udhcpc if raising error:
#
# udhcpc: sendto: Network is down
# udhcpc: read error: Network is down, reopening socket

#/sbin/ip link set eth0 up
#/sbin/ip link set lo up
# udhcpc
#
# if enp4s0 is down on host, run:
#; sudo ip link set enp4s0 nomaster
#; ip link set enp4s0 master vmbr0
