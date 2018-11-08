#!/bin/bash
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
	UBOOT_DTB=fsl-imx8mm-evk.dtb
	UBOOT_DTB=imx8mm-nitrogen8mm.dtb
	UBOOT_DTB=imx8mq-nitrogen8m.dtb
fi

if [ -z ${SOC} ]; then
	if [[ ${UBOOT_DTB} =~ "imx8mm" ]]; then
		SOC=iMX8MM
	else
		SOC=iMX8MQ
	fi
fi

if [ "${SOC}" = "iMX8MM" ] ; then
ATF_LOAD_ADDR=0x00920000
ext=nohdmibin
else
ATF_LOAD_ADDR=0x00910000
ext=hdmibin
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
make SOC=${SOC} dtbs=${UBOOT_DTB} u-boot-lpddr4-${SOC}-${sz}.${ext} && cp iMX8M/u-boot-lpddr4-${SOC}-${sz}.${ext} iMX8M/flash.bin;
echo ATF_LOAD_ADDR=${ATF_LOAD_ADDR}

cd iMX8M && ATF_LOAD_ADDR=${ATF_LOAD_ADDR} ./print_fit_hab.sh 0x60000 bl31-${SOC}-${sz}.bin ${UBOOT_DTB} ; cd ..
echo "Next: dd if=iMX8M/u-boot-lpddr4-${SOC}-${sz}.${ext} of=/dev/sd[x] bs=1K seek=33 skip=0"
