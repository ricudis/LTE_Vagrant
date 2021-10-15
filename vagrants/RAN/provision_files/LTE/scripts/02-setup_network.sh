#!/bin/bash

if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

# Create bridges
brctl addbr brran0
ifconfig brran0 ${LTE_IP_brran}/24 up
ifconfig ${LTE_VM_BRIDGE_INTERFACE} 0.0.0.0 up
brctl addif brran0 ${LTE_VM_BRIDGE_INTERFACE}

# Setup RAN namespace network
for nvf in gnb0 ; do
	ip netns add ran-${nvf}
	ip link add vethran netns ran-${nvf} type veth peer name vethran-${nvf}
	brctl addif brran0 vethran-${nvf}
	declare -n ipvar="LTE_IP_ran_${nvf}"
	ip netns exec ran-${nvf} ifconfig vethran ${ipvar}/24 up
	ip netns exec ran-${nvf} ifconfig lo 127.0.0.1/8 up
	ifconfig vethran-${nvf} 0.0.0.0 up
done

# Setup UE namespaces network 
for ue in 5gue1 5gue2 5gue3 5gue4 4gue1 4gue2 4gue3 4gue4 ; do
	ip netns add ue-${ue}
	ip link add vethran netns ue-${ue} type veth peer name vethran-${ue}
	brctl addif brran0 vethran-${ue}
	declare -n ipvar="LTE_IP_ran_${ue}"
	ip netns exec ue-${ue} ifconfig vethran ${ipvar}/24 up
	ip netns exec ue-${ue} ifconfig lo 127.0.0.1/8 up
	ifconfig vethran-${ue} 0.0.0.0 up
done
