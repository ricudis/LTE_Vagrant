#!/bin/bash
if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

export LD_LIBRARY_PATH=${LTE_BASEDIR}/srsRAN/lib/:$LD_LIBRARY_PATH

# Wait for mongo to start
mongotest=""
while [ "$mongotest" != "1" ] ; do
	mongotest=`mongo --eval 'db.runCommand("ping").ok' mongodb://localhost/ --quiet`
done

# Reset users
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl reset
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000000001 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA 6598933650
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000000002 465B5CE8B199B49FAA5F0A2EE238A6BD E8ED289DEBA952E4283B54E88E6183CB 6598933651
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000000003 465B5CE8B199B49FAA5F0A2EE238A6BE E8ED289DEBA952E4283B54E88E6183CC 6598933652
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000000004 465B5CE8B199B49FAA5F0A2EE238A6BF E8ED289DEBA952E4283B54E88E6183CD 6598933653
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000021491 2F9249275BAB908C16572D98B2B37EA0 A29D36D61B75F3606E8294DBC5F53A9B 6598933654
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000021492 2F9249275BAB908C16572D98B2B37EA1 A29D36D61B75F3606E8294DBC5F53A9C 6598933655
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000021493 2F9249275BAB908C16572D98B2B37EA2 A29D36D61B75F3606E8294DBC5F53A9D 6598933656
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700000021494 2F9249275BAB908C16572D98B2B37EA3 A29D36D61B75F3606E8294DBC5F53A9E 6598933657
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700100001111 8baf473f2f8fd09487cccbd7097c6862 e734f8734007d6c5ce7a0508809e7e9c 6598933658
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700100001112 8baf473f2f8fd09487cccbd7097c6863 e734f8734007d6c5ce7a0508809e7e9d 6598933659
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700100001113 8baf473f2f8fd09487cccbd7097c6864 e734f8734007d6c5ce7a0508809e7e9e 6598933660
${LTE_BASEDIR}/open5gs/bin/open5gs-dbctl addisdn 901700100001114 8baf473f2f8fd09487cccbd7097c6865 e734f8734007d6c5ce7a0508809e7e9f 6598933661

mkdir -p ${LTE_BASEDIR}/open5gs/etc/freeDiameter
for id in hss mme pcrf smf ; do
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/open5gs/freeDiameter/${id}.conf.in ${LTE_BASEDIR}/open5gs/etc/freeDiameter/${id}.conf
done

mkdir -p ${LTE_BASEDIR}/open5gs/etc/open5gs
for id in amf ausf bsf hss mme nrf nssf pcf pcrf sgwc sgwu smf udm udr upf ; do 
	${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/open5gs/open5gs/${id}.yaml.in ${LTE_BASEDIR}/open5gs/etc/open5gs/${id}.yaml
done

mkdir -p ${LTE_BASEDIR}/radvd/etc
mkdir -p ${LTE_BASEDIR}/radvd/var/log
${LTE_BASEDIR}/scripts/subst.sh ${LTE_BASEDIR}/config_templates/radvd/etc/radvd.conf.in ${LTE_BASEDIR}/radvd/etc/radvd.conf
