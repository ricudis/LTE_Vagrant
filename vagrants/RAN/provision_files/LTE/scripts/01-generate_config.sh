#!/bin/bash
if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

export LD_LIBRARY_PATH=${LTE_BASEDIR}/srsRAN/lib/:$LD_LIBRARY_PATH

mkdir -p ${LTE_BASEDIR}/ueransim/etc

for id in gnb ; do 
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/ueransim/etc/open5gs-${id}.yaml.in ${LTE_BASEDIR}/ueransim/etc/open5gs-${id}.yaml
done

for id in 1 2 3 4 ; do
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/ueransim/etc/open5gs-5gue${id}.yaml.in ${LTE_BASEDIR}/ueransim/etc/open5gs-5gue${id}.yaml
done

mkdir -p ${LTE_BASEDIR}/srsRAN/etc

for id in drb epc mbms rr sib ; do
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/srsRAN/etc/${id}.conf.in ${LTE_BASEDIR}/srsRAN/etc/${id}.conf
done

for id in 1 2 3 4 ; do
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/srsRAN/etc/enb-4gue${id}.conf.in ${LTE_BASEDIR}/srsRAN/etc/enb-4gue${id}.conf
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/srsRAN/etc/ue-4gue${id}.conf.in ${LTE_BASEDIR}/srsRAN/etc/ue-4gue${id}.conf
done
