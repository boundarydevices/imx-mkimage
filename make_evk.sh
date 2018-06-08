export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
cp -vt iMX8M/ ../u-boot-imx6/spl/u-boot-spl.bin \
	../u-boot-imx6/u-boot-nodtb.bin \
	../u-boot-imx6/u-boot.bin \
	../u-boot-imx6/arch/arm/dts/fsl-imx8mq-evk.dtb
cp -v ../u-boot-imx6/tools/mkimage iMX8M/mkimage_uboot
make clean
make SOC=iMX8M DTBS=fsl-imx8mq-evk.dtb flash_hdmi_spl_uboot

cd iMX8M && ./print_fit_hab.sh 0x60000 fsl-imx8mq-evk.dtb ; cd ..
echo "Next: dd if=iMX8M/flash.bin of=/dev/sd[x] bs=1K seek=33 skip=0"

