export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
cp -vt iMX8M/ ../u-boot-imx6/spl/u-boot-spl.bin \
	../u-boot-imx6/u-boot-nodtb.bin \
	../u-boot-imx6/u-boot.bin \
	../u-boot-imx6/arch/arm/dts/imx8mq-nitrogen8m.dtb
cp -v ../u-boot-imx6/tools/mkimage iMX8M/mkimage_uboot
make clean
make SOC=iMX8M DTBS=imx8mq-nitrogen8m.dtb flash_hdmi_spl_uboot

cd iMX8M && ./print_fit_hab.sh 0x60000 imx8mq-nitrogen8m.dtb ; cd ..
echo "Next: dd if=iMX8M/flash.bin of=/dev/sd[x] bs=1K seek=33 skip=0"

