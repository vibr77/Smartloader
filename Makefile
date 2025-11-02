# ------------------------------------------------
# Generic Makefile (based on gcc)
#
# ChangeLog :
#	2017-02-10 - Several enhancements + project update mode
#   2015-07-22 - first version
# ------------------------------------------------

######################################
# target
######################################
TARGET=				smartloader
TARGET_S0=  		$(TARGET)_s0
TARGET_S09= 		$(TARGET)_s09

CASM_SOURCES_S0 = 	./main_T0S0.s
CASM_SOURCES_S09 = 	./main_T0S09.s 

BUILD_DIR=	 		build

#DOS_IMG=			img_DiversiDos41C
#DOS_IMG=			img_ProntoDos
DOS_IMG=			img_ProntoDOS
DSK_FILE= 			blank.dsk

linux=1

PYTHON= 			python3

OS_NAME = $(shell uname -s | tr A-Z a-z)

ifeq ($(OS_NAME),linux)
AS=					../99.Merlin32Devlinux/src/merlin32
else
AS=					../99.Merlin32Dev/src/merlin32
endif

AS_ARG= 			-v
AS_INCLUDES 		=~/SynologyDrive/20.Pro/41.TechProjects/02.Apple_II/devenvtool/Merlin32_v1.2_b1/Library
SMARTDISK			=~/SynologyDrive/20.Pro/41.TechProjects/02.Apple_II/06.Apple_SDISK_II/AppleIISDiskII_stm32f411_sdio

all:  | $(BUILD_DIR)
	-killall "Virtual ]["
	$(AS) $(AS_ARG) $(AS_INCLUDES) $(CASM_SOURCES_S0)
	$(AS) $(AS_ARG) $(AS_INCLUDES) $(CASM_SOURCES_S09)

	mv $(TARGET_S0).bin $(BUILD_DIR)/$(TARGET_S0).bin
	mv $(TARGET_S09).bin $(BUILD_DIR)/$(TARGET_S09).bin

	mv $(TARGET_S0).bin_S01_Segment1_Output.txt $(BUILD_DIR)/$(TARGET_S0)_Symbols_.txt 			
	mv $(TARGET_S09).bin_S01_Segment1_Output.txt $(BUILD_DIR)/$(TARGET_S09)_Symbols.txt
	-mv _FileInformation.txt $(BUILD_DIR)/

	mv $(TARGET_S0).bin_Symbols.txt $(BUILD_DIR)/$(TARGET_S0)_lbl.txt 			
	mv $(TARGET_S09).bin_Symbols.txt $(BUILD_DIR)/$(TARGET_S09)_lbl.txt
	$(PYTHON) scp_initBlankDsk.py $(BUILD_DIR)/$(TARGET).dsk
#	cp $(DSK_FILE) $(BUILD_DIR)/$(TARGET).dsk
	$(PYTHON) scp_extractBlock.py $(DOS_IMG).dsk $(BUILD_DIR)/$(DOS_IMG).bin 6 2
	$(PYTHON) scp_writeBlock.py $(BUILD_DIR)/$(DOS_IMG).bin $(BUILD_DIR)/$(TARGET).dsk 1
	$(PYTHON) scp_writeBlock.py $(BUILD_DIR)/$(TARGET_S0).bin $(BUILD_DIR)/$(TARGET).dsk 0

	$(PYTHON) scp_writeBlock.py $(BUILD_DIR)/$(TARGET_S09).bin $(BUILD_DIR)/$(TARGET).dsk 9
	$(PYTHON) scp_addFakeDataBlock.py $(BUILD_DIR)/$(TARGET).dsk 16
	$(PYTHON) scp_extractBlock.py $(BUILD_DIR)/$(TARGET).dsk $(BUILD_DIR)/$(TARGET).bin 30 0
	cp $(BUILD_DIR)/$(TARGET).bin $(SMARTDISK)/$(TARGET).bin
ifneq ($(OS_NAME),linux)
	-open -a "Virtual ][.app"
endif

# cd /home/vincent/SynologyDrive/20.Pro/41.TechProjects/02.Apple_II/90.Asmcode/01.smartloader
	
clean:
	-rm -fR $(BUILD_DIR)

$(BUILD_DIR):
	mkdir $@

	