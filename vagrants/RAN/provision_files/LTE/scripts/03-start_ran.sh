#!/bin/bash
if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

export LD_LIBRARY_PATH=${LTE_BASEDIR}/srsRAN/lib/:$LD_LIBRARY_PATH

mkdir -p ${LTE_BASEDIR}/ueransim/var/log
mkdir -p ${LTE_BASEDIR}/srsRAN/var/log

# Clean up old logs 
rm -rf ${LTE_BASEDIR}/ueransim/var/log/*
rm -rf ${LTE_BASEDIR}/srsRAN/var/log/*

# Start nr-gnb
for nvf in gnb ; do
	echo Starting ueransim ${nvf}...
	ip netns exec ran-${nvf}0 ${LTE_BASEDIR}/ueransim/bin/nr-gnb -c ${LTE_BASEDIR}/ueransim/etc/open5gs-gnb.yaml >> ${LTE_BASEDIR}/ueransim/var/log/${nvf}.log 2>&1 &
done
