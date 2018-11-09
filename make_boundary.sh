#!/bin/sh

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

if [ -z $1 ] ; then
	sz="2g"
else
	sz=$1
fi

if [ -z ${UBOOT_PATH} ]; then
	UBOOT_PATH=../u-boot-imx6
fi

if [ -z ${UBOOT_DTB} ]; then
	UBOOT_DTB=imx8mq-nitrogen8m.dtb
fi

cp -vt iMX8M/ ${UBOOT_PATH}/spl/u-boot-spl.bin \
	${UBOOT_PATH}/u-boot-nodtb.bin \
	${UBOOT_PATH}/u-boot.bin \
	${UBOOT_PATH}/arch/arm/dts/${UBOOT_DTB}
cp -v ${UBOOT_PATH}/tools/mkimage iMX8M/mkimage_uboot
if ! [ $? -eq 0 ] ; then
	echo "Failed to copy files from ${UBOOT_PATH}";
	exit 1;
fi

make clean
make SOC=iMX8M DTBS=${UBOOT_DTB} u-boot-lpddr4-${sz}.hdmibin && cp iMX8M/u-boot-lpddr4-${sz}.hdmibin iMX8M/flash.bin;

cd iMX8M && ./print_fit_hab.sh 0x60000 bl31_${sz}.bin ${UBOOT_DTB} ; cd ..
echo "Next: dd if=iMX8M/u-boot-lpddr4-${sz}.hdmibin of=/dev/sd[x] bs=1K seek=33 skip=0"
