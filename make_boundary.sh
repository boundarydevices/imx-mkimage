#!/bin/sh
export SOC=iMX8MM

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

if [ -z ${UBOOT_PATH} ]; then
	UBOOT_PATH=../u-boot-imx6
fi

if [ -z ${UBOOT_DTB} ]; then
	UBOOT_DTB=imx8mq-nitrogen8m.dtb
	UBOOT_DTB=fsl-imx8mm-evk.dtb
fi


if [ "${SOC}" = "iMX8MM" ] ; then
ATF_LOAD_ADDR=0x00920000
else
ATF_LOAD_ADDR=0x00910000
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
make SOC=${SOC} dtbs=${UBOOT_DTB} flash_lpddr4
echo ATF_LOAD_ADDR=${ATF_LOAD_ADDR}
cd iMX8M && ATF_LOAD_ADDR=${ATF_LOAD_ADDR} ./print_fit_hab.sh 0x60000 ${UBOOT_DTB} ; cd ..
echo "Next: dd if=iMX8M/flash.bin of=/dev/sd[x] bs=1K seek=33 skip=0"
