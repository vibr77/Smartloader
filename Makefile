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
TARGET = PRG.SYSTEM
CASM_SOURCES = smartloader.s 
BUILD_DIR = build
PO_FILE = blank.po
PO_FILE_DEST = smartloader.po
PO_VOL_NAME= blank

AS=Merlin32
CADIUS_PATH=~/SynologyDrive/20.Pro/41.TechProjects/02.Apple_II/devenvtool/cadius-1.4.5
CADIUS=cadius
CP2_PATH=~/SynologyDrive/20.Pro/41.TechProjects/02.Apple_II/devenvtool/cp2_1
CP2=cp2

F_AUX=0x2000
#F_TYPE=0x06
F_TYPE=0xFF


ARG= -v
AS_INCLUDES =~/SynologyDrive/20.Pro/41.TechProjects/02.Apple_II/devenvtool/Merlin32_v1.2_b1/Library

all:  | $(BUILD_DIR)
	-killall "Virtual ]["
	$(AS) -v $(AS_INCLUDES) $(CASM_SOURCES)
	-mv $(TARGET) $(BUILD_DIR)/$(TARGET)
	-mv $(TARGET)_Symbols.txt $(BUILD_DIR)/$(TARGET)_Symbols.txt
	-make addfile
	
	-open -a "Virtual ][.app"

addfile:
	-cp $(PO_FILE) $(BUILD_DIR)/$(PO_FILE_DEST)
	$(CADIUS_PATH)/$(CADIUS) ADDFILE $(BUILD_DIR)/$(PO_FILE_DEST) $(PO_VOL_NAME) $(BUILD_DIR)/$(TARGET)
	$(CP2_PATH)/$(CP2) sa $(BUILD_DIR)/$(PO_FILE_DEST) type=$(F_TYPE),aux=$(F_AUX) $(TARGET)
	
	

replacefile:
	$(CADIUS_PATH)/$(CADIUS) REPLACEFILE $(BUILD_DIR)/$(PO_FILE_DEST) $(PO_VOL_NAME) $(BUILD_DIR)/$(TARGET)
	$(CP2_PATH)/$(CP2) sa $(BUILD_DIR)/$(PO_FILE_DEST) type=$(F_TYPE),aux=$(F_AUX) $(TARGET)
	
clean:
	-rm -fR $(BUILD_DIR)

$(BUILD_DIR):
	mkdir $@

	