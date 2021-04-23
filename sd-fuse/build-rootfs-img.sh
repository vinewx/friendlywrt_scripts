#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img filename> "
    echo "example:"
    echo "    tar xvzf NETDISK/H5/rootfs/rootfs-friendlycore-20190603.tgz"
    echo "    ./build-rootfs-img.sh friendlycore/rootfs friendlycore"
	exit 0
fi

ROOTFS_DIR=$1
TARGET_OS=$2
IMG_FILE=$TARGET_OS/rootfs.img
if [ $# -eq 3 ]; then
	IMG_SIZE=$3
else
	IMG_SIZE=0
fi

TOP=$PWD
true ${MKFS:="${TOP}/tools/make_ext4fs"}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
        echo "Re-running script under sudo..."
        sudo "$0" "$@"
        exit
fi

if [ ${IMG_SIZE} -eq 0 ]; then
    # calc image size
    ROOTFS_SIZE=`du -s -B 1 ${ROOTFS_DIR} | cut -f1`
    # MAX_IMG_SIZE=7100000000
    MAX_IMG_SIZE=3000000000
    TMPFILE=`tempfile`
    ${MKFS} -s -l ${MAX_IMG_SIZE} -a root -L rootfs /dev/null ${ROOTFS_DIR} > ${TMPFILE}
    IMG_SIZE=`cat ${TMPFILE} | grep "Suggest size:" | cut -f2 -d ':' | awk '{gsub(/^\s+|\s+$/, "");print}'`
    rm -f ${TMPFILE}

    if [ ${ROOTFS_SIZE} -gt ${IMG_SIZE} ]; then
            echo "IMG_SIZE less than ROOTFS_SIZE, why?"
            exit 1
    fi

    # make fs
    ${MKFS} -s -l ${IMG_SIZE} -a root -L rootfs ${IMG_FILE} ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to  make rootfs.img."
            exit 1
     fi
else
    ${MKFS} -s -l ${IMG_SIZE} -a root -L rootfs ${IMG_FILE} ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to  make rootfs.img."
            exit 1
     fi
fi

if [ ${TARGET_OS} != "eflasher" ]; then
    ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
fi

echo "generating ${IMG_FILE} done."
echo 0

