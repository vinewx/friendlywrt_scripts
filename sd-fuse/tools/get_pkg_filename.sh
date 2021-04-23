#!/bin/bash

TARGET_OS=${1,,}
case ${TARGET_OS} in
friendlycore-xenial_4.14_arm64 | friendlywrt_4.14_arm64 | eflasher)
    ROMFILE="${TARGET_OS}.tgz"
        ;;
*)
    if [ ${TARGET_OS} = "openwrt_4.14_arm64" ];then
        ROMFILE="friendlywrt_4.14_arm64.tgz"
    else
        ROMFILE=
    fi
esac
echo $ROMFILE

