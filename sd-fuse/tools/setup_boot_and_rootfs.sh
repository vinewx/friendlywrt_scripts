#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

true ${SOC:=h5}
ARCH=arm64
KIMG=arch/${ARCH}/boot/Image
KDTB=arch/${ARCH}/boot/dts/allwinner/sun50i-h5-nanopi*.dtb
KOVERLAY=arch/${ARCH}/boot/dts/allwinner/overlays
OUT=${PWD}/out

UBOOT_DIR=$1
KERNEL_DIR=$2
BOOT_DIR=$3
ROOTFS_DIR=$4
PREBUILT=$5

KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

# boot
rsync -a --no-o --no-g ${KERNEL_DIR}/${KIMG} ${BOOT_DIR}
rsync -a --no-o --no-g ${KERNEL_DIR}/${KDTB} ${BOOT_DIR}
rsync -a --no-o --no-g ${PREBUILT}/boot/* ${BOOT_DIR}

mkdir -p ${BOOT_DIR}/overlays
rsync -a --no-o --no-g ${KERNEL_DIR}/${KOVERLAY}/*.dtbo ${BOOT_DIR}/overlays/
rsync -a --no-o --no-g ${KERNEL_DIR}/${KOVERLAY}/sun50i-h5-fixup* ${BOOT_DIR}/overlays/
rsync -a --no-o --no-g ${KERNEL_DIR}/${KOVERLAY}/README.sun50i-h5-overlays ${BOOT_DIR}/overlays/README.md

# rootfs
rm -rf ${ROOTFS_DIR}/lib/modules/*
cp -af ${KMODULES_OUTDIR}/* ${ROOTFS_DIR}/

# 3rd drives
if [ ! -z "$PREBUILT" ]; then
    if [ -d ${ROOTFS_DIR}/lib/modules/4.14.111 ]; then
        cp -af ${PREBUILT}/kernel-module/4.14.111/* ${ROOTFS_DIR}/lib/modules/4.14.111/
    fi
    if [ -d ${PREBUILT}/wifi_firmware ]; then
        cp -rd ${PREBUILT}/wifi_firmware/wifi/lib/firmware/xr819 ${ROOTFS_DIR}/lib/firmware
        cp -rd ${PREBUILT}/wifi_firmware/ap6xxx/lib/firmware/* ${ROOTFS_DIR}/lib/firmware
    fi
fi

exit 0
