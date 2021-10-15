#!/bin/bash
if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

export LD_LIBRARY_PATH=${LTE_BASEDIR}/srsRAN/lib/:$LD_LIBRARY_PATH

# Clean up old logs 
rm -rf ${LTE_BASEDIR}/open5gs/var/log/*
rm -rf ${LTE_BASEDIR}/ueransim/var/log/*

# Wait for mongo to start
mongotest=""
while [ "$mongotest" != "1" ] ; do
	mongotest=`mongo --eval 'db.runCommand("ping").ok' mongodb://localhost/ --quiet`
done

# Start Open5GS EPC
mkdir -p ${LTE_BASEDIR}/open5gs/var/log/open5gs/
for nvf in nrf mme sgwc amf sgwu upf smf hss pcrf ausf udm pcf nssf bsf udr ; do
	echo -n Starting Open5GS ${nvf}...
	ip netns exec epc-${nvf}0 ${LTE_BASEDIR}/open5gs/bin/open5gs-${nvf}d -D -c ${LTE_BASEDIR}/open5gs/etc/open5gs/${nvf}.yaml >> ${LTE_BASEDIR}/open5gs/var/log/open5gs/${nvf}.out 2>&1 &
	sleep 2
	echo ""
done
