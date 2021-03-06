#!/bin/bash
if [ -z "${BASH_VERSION}" ] ; then
	echo Please run under bash
	exit 1
fi 

LTE_BASEDIR=/opt/LTE/

source ${LTE_BASEDIR}/env

cp $1 $2

export LTE_MCC3=`echo ${LTE_MCC} | awk '{printf "%03u", $1}'`
export LTE_MNC3=`echo ${LTE_MNC} | awk '{printf "%03u", $1}'`

if [ "`arch`" = "aarch64" ] ; then
        export LTE_BUILD_ARCH=aarch64-linux-gnu
else
        export LTE_BUILD_ARCH=x86_64-linux-gnu
fi

for VAR in `printenv | grep ^LTE_ | cut -f1 -d=` ; do
        VAL=${!VAR}
        sed -i "s|${VAR}|${VAL}|g" $2
done
