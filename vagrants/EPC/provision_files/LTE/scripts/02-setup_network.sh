#!/bin/bash

if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

# Create bridges
brctl addbr brepc0
ifconfig brepc0 ${LTE_IP_brepc}/24 up
ifconfig ${LTE_VM_BRIDGE_INTERFACE} 0.0.0.0 up
brctl addif brepc0 ${LTE_VM_BRIDGE_INTERFACE}

# Setup GRE TAP to mirror all EPC traffic through a GRE tunnel to ncore
# running on a VM with an interface with MAC address LTE_TAP_TARGET_MAC
# All IPs are dummy.
#

modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

if [ "$LTE_TAP_ENABLE" = "1" ] ; then
	arp -s ${LTE_TAP_TARGET_IP} ${LTE_TAP_TARGET_MAC} 
	ip link add name gretap1 type gretap local ${LTE_LOCAL_IP} remote ${LTE_TAP_TARGET_IP} okey 9.9.9.9
	ifconfig gretap1 ${LTE_TAP_DUMMY_GRE_IP1}/24 hw ether ${LTE_TAP_DUMMY_GRE_MAC}
	arp -s ${LTE_TAP_DUMMY_GRE_IP2} ${LTE_TAP_DUMMY_GRE_MAC}
	iptables -t mangle -A FORWARD -i brepc0 -j TEE --gateway ${LTE_TAP_DUMMY_GRE_IP2}
fi

# Alternatively, setup direct tap to a capture interface
#

if [ "$LTE_TAP_ENABLE" = "2" ] ; then
	ifconfig ${LTE_CAPTURE_INTERFACE} ${LTE_TAP_DUMMY_GRE_IP1} netmask 255.255.255.0
	arp -s ${LTE_TAP_DUMMY_GRE_IP2} 5a:7f:e6:60:bd:55
	iptables -t mangle -A FORWARD -i brepc0 -j TEE --gateway ${LTE_TAP_DUMMY_GRE_IP2}
fi

# Setup EPC namespaces networking
for nvf in mme sgwc smf amf sgwu upf hss pcrf nrf ausf udm pcf nssf bsf udr; do
	ip netns add epc-${nvf}0 
	ip link add vethepc netns epc-${nvf}0 type veth peer name vethepc-${nvf}0
	brctl addif brepc0 vethepc-${nvf}0
	declare -n ipvar="LTE_IP_epc_${nvf}0"
	ip netns exec epc-${nvf}0 ifconfig vethepc ${ipvar}/24 up
	ip netns exec epc-${nvf}0 ifconfig lo 127.0.0.1/8 up
	ifconfig vethepc-${nvf}0 0.0.0.0 up
done

# Setup networking on UPF namespace
ip netns exec epc-upf0 ip tuntap add name ogstun mode tun
ip netns exec epc-upf0 ip addr add 10.45.0.1/16 dev ogstun
ip netns exec epc-upf0 ip addr add fd01:230:cafe::1/48 dev ogstun
ip netns exec epc-upf0 ip link set ogstun up
ip netns exec epc-upf0 sysctl -w net.ipv4.ip_forward=1
ip netns exec epc-upf0 sysctl -w net.ipv6.conf.all.forwarding=1
ip netns exec epc-upf0 sysctl -w net.ipv4.conf.all.rp_filter=2
ip netns exec epc-upf0 sysctl -w net.ipv4.conf.default.rp_filter=2
ip netns exec epc-upf0 /usr/sbin/radvd -C /opt/LTE/radvd/etc/radvd.conf -m logfile -l /opt/LTE/radvd/var/log/radvd.log
if [ "$LTE_PUBLIC_ROUTE_ENABLE" = "1" ] ; then
	# Get IP and netmask of public interface
	# XXX Fix for IPv6 too
	PUBLIC_IF_IP=`ip -j addr show dev ${LTE_PUBLIC_ROUTE_INTERFACE} | jq -r '.[0].addr_info[] | select(.family == "inet") | .local'`
	PUBLIC_IF_PREFIXLEN=`ip -j addr show dev ${LTE_PUBLIC_ROUTE_INTERFACE} | jq -r '.[0].addr_info[] | select(.family == "inet") | .prefixlen'`
	# Move public interface into epc-upf namespace and setup NAT
	ip link set ${LTE_PUBLIC_ROUTE_INTERFACE} netns epc-upf0
	# Reconfigure interface, it has lost its IP address when moved to a new namespace
	ip netns exec epc-upf0 ifconfig ${LTE_PUBLIC_ROUTE_INTERFACE} ${PUBLIC_IF_IP}/${PUBLIC_IF_PREFIXLEN}
	ip netns exec epc-upf0 iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
	ip netns exec epc-upf0 ip6tables -t nat -A POSTROUTING -s fd01:230:cafe::/48 ! -o ogstun -j MASQUERADE
	ip netns exec epc-upf0 route add -net default gw ${LTE_PUBLIC_ROUTE_GATEWAY}
fi
	
	