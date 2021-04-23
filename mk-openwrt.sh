#!/bin/bash

set -eu

SCRIPTS_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        SCRIPTS_DIR=$(dirname $CMD)
fi
cd $SCRIPTS_DIR
cd ../
TOP_DIR=$(pwd)

TARGET_OPENWRT_CONFIG=$1
OPENWRT_SRC_PATHNAME=$2
echo "============Start building openwrt============"
echo "TARGET_OPENWRT_CONFIG = $TARGET_OPENWRT_CONFIG"
echo "OPENWRT_SRC_PATHNAME = $OPENWRT_SRC_PATHNAME"
echo "=========================================="

cd ${TOP_DIR}/${OPENWRT_SRC_PATHNAME}
./scripts/feeds update -a
./scripts/feeds install -a
if [ ! -f .config ]; then
	cp ${TOP_DIR}/configs/${TARGET_OPENWRT_CONFIG} .config
	make defconfig
else
	echo "using .config file"
fi

if [ ! -d dl ]; then
	echo "dl directory doesn't  exist. Will make download full package from openwrt site."
fi
make download -j$(nproc)
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

USING_DATE=$(date +%Y%m%d)
#echo "${USING_DATE}" > ./package/base-files/files/etc/rom-version

make -j$(nproc) V=s
RET=$?
if [ $RET -eq 0 ]; then
	exit 0
fi

make -j1 V=s
RET=$?
if [ $RET -eq 0 ]; then
    exit 0
fi

exit 1
