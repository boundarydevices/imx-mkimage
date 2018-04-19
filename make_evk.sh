export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
cp -v ../u-boot-imx6/spl/u-boot-spl.bin iMX8M/
cp -v ../u-boot-imx6/u-boot-nodtb.bin iMX8M/
cp -v ../u-boot-imx6/arch/arm/dts/fsl-imx8mq-evk.dtb iMX8M/
make clean
make SOC=iMX8M flash_hdmi_spl_uboot_evk
echo "Next: dd if=iMX8M/flash.bin of=/dev/sd[x] bs=1K seek=33 skip=0"

