#!/bin/bash
#
set_bridge() {
    instantiate
    #
    # create new bridge and change its state to up
    ip link add name "$BRIDGE" type bridge
    ip link set dev "$BRIDGE" up

    ip link set "$INTERFACE" master "$BRIDGE"
    #bridge link
    #
}

clean_bridge() {
    instantiate
    #
    # remove interface from bridge
    ip link set "$INTERFACE" nomaster
    ip link delete "$BRIDGE" type bridge
}

instantiate() {
show_int=$(ip link show | awk 'NR==3 {print $2}')
show_up=$(ip link show | awk 'NR==3 {print $9}')

if [ "$show_int" == "enp4s0:" ] && \
    [ "$show_up" == "UP" ]; then
    INTERFACE="enp4s0"
    BRIDGE="eulab_bridge"

elif [ -z  "$show_int" ] && \
    [ -z "$show_up" ]; then
    echo uai
fi
}
