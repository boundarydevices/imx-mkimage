MKIMG = mkimage_imx8
DCD_CFG_SRC = imx8mq_dcd.cfg
DCD_CFG = imx8mq_dcd.cfg.tmp

CC ?= gcc
CFLAGS ?= -O2 -Wall -std=c99 -static
INCLUDE = ./lib

WGET = /usr/bin/wget
N ?= latest
SERVER=http://yb2.am.freescale.net
DIR = build-output/Linux_IMX_4.9_morty_trunk_next_mx8/$(N)/common_bsp
FW_DIR = imx-boot/imx-boot-tools/imx8mq

$(MKIMG): mkimage_imx8.c
	@echo "Compiling mkimage_imx8"
	$(CC) $(CFLAGS) mkimage_imx8.c -o $(MKIMG) -lz

$(DCD_CFG): $(DCD_CFG_SRC)
	@echo "Converting iMX8M DCD file" 
	$(CC) -E -Wp,-MD,.imx8mq_dcd.cfg.cfgtmp.d  -nostdinc -Iinclude -I$(INCLUDE) -x c -o $(DCD_CFG) $(DCD_CFG_SRC)

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

u-boot-atf-%.bin: bl31_%.bin u-boot.bin
	@cp $< $@
	@dd if=u-boot.bin of=$@ bs=1K seek=128

u-boot-atf-tee-%.bin: bl31_%.bin u-boot.bin tee.bin
	@cp $< $@
	@dd if=tee.bin of=$@ bs=1K seek=128
	@dd if=u-boot.bin of=$@ bs=1M seek=1

.PHONY: clean
clean:
	@rm -f $(MKIMG) $(DCD_CFG) .imx8mq_dcd.cfg.cfgtmp.d flash.bin u-boot-atf-*.bin  *.itb *.its *.hdmibin *.nohdmibin *.splbin

u-boot-lpddr4-%.itb u-boot-ddr3l-%.itb u-boot-ddr4-%.itb: bl31_%.bin $(dtbs)
	BL31=$< ./mkimage_fit_atf.sh $(dtbs) > $(*F).its
	./mkimage_uboot -E -p 0x3000 -f $(*F).its $@
	@rm -f $(*F).its

%.hdmibin: %.splbin %.itb $(MKIMG) signed_hdmi_imx8m.bin
	./mkimage_imx8 -fit -signed_hdmi signed_hdmi_imx8m.bin -loader $(*F).splbin 0x7E1000 -second_loader $(*F).itb 0x40200000 0x60000 -out $@

%.nohdmibin: %.splbin %.itb $(MKIMG)
	./mkimage_imx8 -fit -loader $(*F).splbin 0x7E1000 -second_loader $(*F).itb 0x40200000 0x60000 -out $@

print_fit_hab_%: bl31%.bin u-boot-nodtb.bin $(dtbs)
	./print_fit_hab.sh 0x60000 $< $(dtbs)

nightly :
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_1d_dmem.bin -O lpddr4_pmu_train_1d_dmem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_1d_imem.bin -O lpddr4_pmu_train_1d_imem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_2d_dmem.bin -O lpddr4_pmu_train_2d_dmem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_2d_imem.bin -O lpddr4_pmu_train_2d_imem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/bl31-imx8mq.bin -O bl31.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/u-boot-spl.bin -O u-boot-spl.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/u-boot-nodtb.bin -O u-boot-nodtb.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/${dtbs} -O ${dtbs}
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/signed_hdmi_imx8m.bin -O signed_hdmi_imx8m.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/mkimage_uboot -O mkimage_uboot

