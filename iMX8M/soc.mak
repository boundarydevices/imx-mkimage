MKIMG = mkimage_imx8

CC ?= gcc
CFLAGS ?= -O2 -Wall -std=c99 -static
INCLUDE = ./lib

BITBUCKET_SERVER=https://bitbucket.sw.nxp.com

ifeq ($(SOC),iMX8MM)
PLAT = imx8mm
HDMI = no
TEE_LOAD_ADDR = 0xbe000000
ATF_LOAD_ADDR = 0x00920000
VAL_BOARD = val
#define the F(Q)SPI header file
QSPI_HEADER = ../scripts/fspi_header
QSPI_PACKER = ../scripts/fspi_packer.sh
else
PLAT = imx8mq
HDMI = yes
TEE_LOAD_ADDR = 0xfe000000
ATF_LOAD_ADDR = 0x00910000
VAL_BOARD = arm2
#define the F(Q)SPI header file
QSPI_HEADER = ../scripts/qspi_header
QSPI_PACKER = ../scripts/fspi_packer.sh
endif


$(MKIMG): mkimage_imx8.c
	@echo "PLAT="$(PLAT) "HDMI="$(HDMI)
	@echo "Compiling mkimage_imx8"
	$(CC) $(CFLAGS) mkimage_imx8.c -o $(MKIMG) -lz

u-boot-lpddr4-%.splbin: u-boot-spl.bin lpddr4_pmu_train_1d_imem.bin lpddr4_pmu_train_1d_dmem.bin lpddr4_pmu_train_2d_imem.bin lpddr4_pmu_train_2d_dmem.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 lpddr4_pmu_train_1d_imem.bin lpddr4_pmu_train_1d_imem_pad.bin
	@objcopy -I binary -O binary --pad-to 0x4000 --gap-fill=0x0 lpddr4_pmu_train_1d_dmem.bin lpddr4_pmu_train_1d_dmem_pad.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 lpddr4_pmu_train_2d_imem.bin lpddr4_pmu_train_2d_imem_pad.bin
	@cat lpddr4_pmu_train_1d_imem_pad.bin lpddr4_pmu_train_1d_dmem_pad.bin > lpddr4_pmu_train_1d_fw.bin
	@cat lpddr4_pmu_train_2d_imem_pad.bin lpddr4_pmu_train_2d_dmem.bin > lpddr4_pmu_train_2d_fw.bin
	@cat u-boot-spl.bin lpddr4_pmu_train_1d_fw.bin lpddr4_pmu_train_2d_fw.bin > $@
	@rm -f lpddr4_pmu_train_1d_fw.bin lpddr4_pmu_train_2d_fw.bin lpddr4_pmu_train_1d_imem_pad.bin lpddr4_pmu_train_1d_dmem_pad.bin lpddr4_pmu_train_2d_imem_pad.bin

u-boot-ddr4-%.splbin: u-boot-spl.bin ddr4_imem_1d.bin ddr4_dmem_1d.bin ddr4_imem_2d.bin ddr4_dmem_2d.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 ddr4_imem_1d.bin ddr4_imem_1d_pad.bin
	@objcopy -I binary -O binary --pad-to 0x4000 --gap-fill=0x0 ddr4_dmem_1d.bin ddr4_dmem_1d_pad.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 ddr4_imem_2d.bin ddr4_imem_2d_pad.bin
	@cat ddr4_imem_1d_pad.bin ddr4_dmem_1d_pad.bin > ddr4_1d_fw.bin
	@cat ddr4_imem_2d_pad.bin ddr4_dmem_2d.bin > ddr4_2d_fw.bin
	@cat u-boot-spl.bin ddr4_1d_fw.bin ddr4_2d_fw.bin > $@
	@rm -f ddr4_1d_fw.bin ddr4_2d_fw.bin ddr4_imem_1d_pad.bin ddr4_dmem_1d_pad.bin ddr4_imem_2d_pad.bin

u-boot-ddr3l-%.splbin: u-boot-spl.bin ddr3_imem_1d.bin ddr3_dmem_1d.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 ddr3_imem_1d.bin ddr3_imem_1d.bin_pad.bin
	@cat ddr3_imem_1d.bin_pad.bin ddr3_dmem_1d.bin > ddr3_pmu_train_fw.bin
	@cat u-boot-spl.bin ddr3_pmu_train_fw.bin > $@
	@rm -f ddr3_pmu_train_fw.bin ddr3_imem_1d.bin_pad.bin

u-boot-atf-%.bin: bl31-%.bin u-boot.bin
	@cp $< $@
	@dd if=u-boot.bin of=$@ bs=1K seek=128

u-boot-atf-tee-%.bin: bl31-%.bin u-boot.bin tee.bin
	@cp $< $@
	@dd if=tee.bin of=$@ bs=1K seek=128
	@dd if=u-boot.bin of=$@ bs=1M seek=1

.PHONY: clean
clean:
	@rm -f $(MKIMG) flash.bin u-boot-atf-*.bin  *.itb *.its *.hdmibin *.nohdmibin *.splbin

u-boot-lpddr4-%.itb u-boot-ddr3l-%.itb u-boot-ddr4-%.itb: bl31-%.bin $(dtbs)
	TEE_LOAD_ADDR=$(TEE_LOAD_ADDR) ATF_LOAD_ADDR=$(ATF_LOAD_ADDR) BL31=$< ./mkimage_fit_atf.sh $(dtbs) > $(*F).its
	./mkimage_uboot -E -p 0x3000 -f $(*F).its $@
	@rm -f $(*F).its

%.hdmibin: %.splbin %.itb $(MKIMG) signed_hdmi_imx8m.bin
	./mkimage_imx8 -fit -signed_hdmi signed_hdmi_imx8m.bin -loader $(*F).splbin 0x7E1000 -second_loader $(*F).itb 0x40200000 0x60000 -out $@

%.nohdmibin: %.splbin %.itb $(MKIMG)
	./mkimage_imx8 -fit -loader $(*F).splbin 0x7E1000 -second_loader $(*F).itb 0x40200000 0x60000 -out $@

%.dpbin: %.splbin %.itb $(MKIMG) signed_dp_imx8m.bin
	./mkimage_imx8 -fit -signed_hdmi signed_dp_imx8m.bin -loader $(*F).splbin 0x7E1000 -second_loader $(*F).itb 0x40200000 0x60000 -out $@

%.flexspibin: %.splbin %.itb $(MKIMG)
	./mkimage_imx8 -dev flexspi -fit -loader $(*F).splbin 0x7E2000 -second_loader $(*F).itb 0x40200000 0x60000 -out $@
	./$(QSPI_PACKER) $(QSPI_HEADER)

print_fit_hab_%: bl31%.bin u-boot-nodtb.bin $(dtbs)
	TEE_LOAD_ADDR=$(TEE_LOAD_ADDR) ATF_LOAD_ADDR=$(ATF_LOAD_ADDR) ./print_fit_hab.sh 0x60000 $< $(dtbs)
