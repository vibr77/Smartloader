# Smartloader for SmartDisk II

This repository is hosting the Smartloader for the Apple II floppy disk Emulator SmartDisk II.
The smartloader enables to list and select directly on the Apple II the content of the SDCard

The initial version (up to 0.36) was using prodos 2.4, to increase the compatibility and also the User experience performance a different approach has be selected.

From version 0.37, The smartloader uses:
- a custom bootloader to load RWTS from sector 1 to 8 (on normal DOS image RWTS starts at sector 2 )
- Fast RWTS, non standard DOS3.3c (sector 01 to 08)
- Smartloader (sector 09 to 0E)

Memory location:

- $800 Bootloader with disp routine used by the smartloader (unsed space by bootloader are used to store routine)
- $4000 Smartloader entry point
- $2000-$20FF 256 Bytes block to send command to SmartDisk
- $2100-$22FF 512 Bytes block to receive information from SmartDisk

- Track 2 is to receive information
- Track 3 is to send command to SmartDisk II

To build the smartloader :
- Merlin32 from Brutal Deluxe is needed (or ca65 but syntax needs to be adapted)
- Python3 to have final image with sector block at the right place

The current version is on dev beta only and does not work with SmartDisk II as current release of smartdisk II uses old prodos version (v0.36) memory location



