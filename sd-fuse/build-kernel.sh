#!/bin/bash
set -eu

# Copyright (C) Guangzhou FriendlyARM Computer Tech. Co., Ltd.
# (http://www.friendlyarm.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can access it online at
# http://www.gnu.org/licenses/gpl-2.0.html.

true ${SOC:=h5}
true ${DISABLE_MKIMG:=0}

KERNEL_REPO=https://github.com/friendlyarm/linux
KERNEL_BRANCH=sunxi-4.14.y

ARCH=arm64
true ${KCFG:=sunxi_arm64_defconfig}
KIMG=arch/${ARCH}/boot/Image
KDTB=arch/${ARCH}/boot/dts/allwinner/sun50i-h5-nanopi*.dtb
KALL="Image dtbs"
CROSS_COMPILE=aarch64-linux-gnu-

# 
# kernel logo:
# 
# convert logo.jpg -type truecolor /tmp/logo.bmp 
# convert logo.jpg -type truecolor /tmp/logo_kernel.bmp
# LOGO=/tmp/logo.bmp
# KERNEL_LOGO=/tmp/logo_kernel.bmp
#

TOPPATH=$PWD
OUT=$TOPPATH/out
if [ ! -d $OUT ]; then
	echo "path not found: $OUT"
	exit 1
fi
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"
true ${KERNEL_SRC:=${OUT}/kernel-${SOC}}

function usage() {
       echo "Usage: $0 <friendlycore-xenial_4.14_arm64|openwrt_4.14_arm64|eflasher>"
       echo "# example:"
       echo "# clone kernel source from github:"
       echo "    git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}"
       echo "# or clone your local repo:"
       echo "    git clone git@192.168.1.2:/path/to/linux.git --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}"
       echo "# then"
       echo "    ./build-kernel.sh friendlycore-xenial_4.14_arm64"
       echo "    ./mk-emmc-image.sh friendlycore-xenial_4.14_arm64"
       echo "# also can do:"
       echo "    KERNEL_SRC=~/mykernel ./build-kernel.sh friendlycore-xenial_4.14_arm64"
       exit 0
}

if [ $# -ne 1 ]; then
    usage
fi

# ----------------------------------------------------------
# Get target OS
true ${TARGET_OS:=${1,,}}
PARTMAP=./${TARGET_OS}/partmap.txt

case ${TARGET_OS} in
friendlycore-xenial_4.14_arm64 | openwrt_4.14_arm64 | eflasher)
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 1
esac

download_img() {
    if [ ! -f ${PARTMAP} ]; then
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image not found for ${1}
----------------
you may download them from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called images-for-eflasher, for example:
    tar xvzf /path/to/NETDISK/images-for-eflasher/${ROMFILE}
----------------
Or, download from http (Y/N)?
EOF
        while read -r -n 1 -t 3600 -s USER_REPLY; do
            if [[ ${USER_REPLY} = [Nn] ]]; then
                echo ${USER_REPLY}
                exit 1
            elif [[ ${USER_REPLY} = [Yy] ]]; then
                echo ${USER_REPLY}
                break;
            fi
        done

        if [ -z ${USER_REPLY} ]; then
            echo "Cancelled."
            exit 1
        fi
        ./tools/get_rom.sh ${1} || exit 1
    fi
}

if [ ! -d ${KERNEL_SRC} ]; then
	git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}
fi

if [ ! -d /opt/FriendlyARM/toolchain/6.4-aarch64 ]; then
	echo "please install aarch64-gcc-6.4 first, using these commands: "
	echo "\tgit clone https://github.com/friendlyarm/prebuilts.git -b master --depth 1"
	echo "\tcd prebuilts/gcc-x64"
	echo "\tcat toolchain-6.4-aarch64.tar.gz* | sudo tar xz -C /"
	exit 1
fi

export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH

cd ${KERNEL_SRC}
make distclean
touch .scmversion
make ARCH=${ARCH} ${KCFG}
if [ $? -ne 0 ]; then
	echo "failed to build kernel."
	exit 1
fi
make ARCH=${ARCH} ${KALL} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
if [ $? -ne 0 ]; then
        echo "failed to build kernel."
        exit 1
fi

rm -rf ${KMODULES_OUTDIR}
mkdir -p ${KMODULES_OUTDIR}
make ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules -j$(nproc) CROSS_COMPILE=${CROSS_COMPILE}
if [ $? -ne 0 ]; then
	echo "failed to build kernel modules."
        exit 1
fi
make ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules_install CROSS_COMPILE=${CROSS_COMPILE}
if [ $? -ne 0 ]; then
	echo "failed to build kernel modules."
        exit 1
fi
(cd ${KMODULES_OUTDIR} && find . -name \*.ko | xargs ${CROSS_COMPILE}strip --strip-unneeded)

if [ ! -d ${KMODULES_OUTDIR}/lib ]; then
	echo "not found kernel modules."
	exit 1
fi

if [ x"$DISABLE_MKIMG" = x"1" ]; then
    exit 0
fi

echo "building kernel ok."
if ! [ -x "$(command -v simg2img)" ]; then
    sudo apt update
    sudo apt install android-tools-fsutils
fi

cd ${TOPPATH}
download_img ${TARGET_OS}
KCFG=${KCFG} ./tools/update_kernel_bin_to_img.sh ${OUT} ${KERNEL_SRC} ${TARGET_OS} ${TOPPATH}/prebuilt


if [ $? -eq 0 ]; then
    echo "updating kernel ok."
else
    echo "failed."
    exit 1
fi
