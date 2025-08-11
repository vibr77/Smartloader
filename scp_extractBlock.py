#
#__   _____ ___ ___        Author: Vincent BESSON
# \ \ / /_ _| _ ) _ \      Release: 0.1
#  \ V / | || _ \   /      Date: 2025
#   \_/ |___|___/_|_\      Description: Apple Disk II Emulator data script
#                2025      Licence: Creative Commons
#______________________


# Extract 256 Bytes block from file and write to a dest file
# argv 1: (str) source file
# argv 2: (str) destination file
# argv 3: (int) Number of block of 256 Bytes to extract
# argv 4: (int) Offset of 256 Bytes block to start the extraction

import pandas as pd
import numpy as np
from bitstring import Bits, BitArray, BitStream, pack, options
import sys

def buffer2file(filename,buffer,offset):
    try:
        file = open(filename, "w+b")
    except OSError:
        print('cannot open', filename)
        sys.exit(-1)
    else:
        file.seek(offset)
        file.write(buffer)
        file.close
    return

def file2buffer(filename,buffer,blocknum,offset):
    
    file = open(filename, "rb")						# Open file for reading in Binary
    file.seek(offset)			
    indx=0 											# Read file by block of 512 Bytes    
    data = file.read(256)							# read the first block

    while data:										# tant qu'il y a des blocks
        buffer[indx*256:(indx+1)*256]=data
        data = file.read(256)
        dlen=len(data)
        blen=len(buffer)
        print("     Block:"+repr(indx)+", buffer size:"+repr(blen)+", block size:"+repr(dlen))
        
        
        if indx>blocknum:
            break

        indx=indx+1

    file.close()
    return buffer

src=bytearray()
blocknum=int(sys.argv[3])
offset=int(sys.argv[4])*256
dst=sys.argv[2]

print()
print("-------------------------------------------------------------------------------")
print("SCRIPT: Init Blank dsk file")
print("-------------------------------------------------------------------------------")

src=file2buffer(sys.argv[1],src,blocknum,offset)
buffer2file(dst,src,0)
