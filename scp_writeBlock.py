

#
#__   _____ ___ ___        Author: Vincent BESSON
# \ \ / /_ _| _ ) _ \      Release: 0.1
#  \ V / | || _ \   /      Date: 2024
#   \_/ |___|___/_|_\      Description: Apple Disk II Emulator data script
#                2024      Licence: Creative Commons
#______________________

import pandas as pd
import numpy as np
from bitstring import Bits, BitArray, BitStream, pack, options
import sys

# Description: Write 256 Byte block from source file to destination with sector offset
# Arguments: 
#   1 -> bin file
#   2 -> dsk file 
#   3 -> track 0 offset sector to start,

sectorDosZPhy= bytearray([0x0,0x07,0x0E,0x06,0x0D,0x05,0x0C,0x04,0x0B,0x03,0x0A,0x02,0x09,0x01,0x08,0x0F])

def buffer2file(filename,buffer,offset,len):

     file = open(filename, "r+b")
     file.seek(offset)
     file.write(buffer)
     file.close
     return

def file2buffer(filename,buffer):
    
    file = open(filename, "rb")						# Open file for reading in Binary
    			
    indx=0 											# Read file by block of 512 Bytes    
    data = file.read(256)							# read the first block
    print("Loading:")
    
    while data:										# tant qu'il y a des blocks
        buffer[indx*256:(indx+1)*256]=data
        data = file.read(256)
        dlen=len(data)
        blen=len(buffer)
        print("     block:"+repr(indx)+", buffer size:"+repr(blen)+", block size:"+repr(dlen))
        indx=indx+1
        if indx>16:
            break

    file.close()
    return buffer

bootloader=bytearray()
print()
print("-------------------------------------------------------------------------------")
print("SCRIPT: Write 256 Bytes block to destination image")
print("-------------------------------------------------------------------------------")
print("Write block:")
print('     Source firmware:'+repr(sys.argv[1]))
print('     Destination image:'+repr(sys.argv[2]))
bootloader=file2buffer(sys.argv[1],bootloader)
blen=len(bootloader)
print("bootloader size:"+repr(blen))

sectorNum=blen//256
if blen % 256:
	sectorNum+=1

startSector=int(sys.argv[3])

print("     Number of sector to write:"+repr(sectorNum))
print("     Sector start offset:"+repr(startSector))

for i in range(0,sectorNum):
    fOffset=i*256
#    pSector=sectorDosZPhy[startSector+i]
#    pOffset=pSector*256
    pSector=startSector+i
    pOffset=(startSector+i)*256
    print("     Logical sector:"+repr(i)+", physical sector:"+repr(pSector)+", write offset:"+repr(hex(pOffset)))
 
    wlen=0
    if blen>fOffset+256:
    	wlen=256
    else:
    	wlen=blen-fOffset
         
    #print("     Write len:"+repr(wlen))
    buffer2file(sys.argv[2],bootloader[fOffset:fOffset+wlen],pOffset,wlen)


print("-------------------------------------------------------------------------------")
print()
print()
