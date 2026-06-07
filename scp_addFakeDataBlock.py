#
#__   _____ ___ ___        Author: Vincent BESSON
# \ \ / /_ _| _ ) _ \      Release: 0.1
#  \ V / | || _ \   /      Date: 2024
#   \_/ |___|___/_|_\      Description: Apple Disk II Emulator data script
#                2024      Licence: Creative Commons
#______________________


# pour tester le DSK généré, il faut des blocks bidons avec une liste des images disque
# ce programme fait le job

# python3 scp_addFakeDataBlock.py  file.dsk offset_oú_placer_les_blocks_bidons

import pandas as pd
import numpy as np
from bitstring import Bits, BitArray, BitStream, pack, options
import sys

debug=False

def buf2fil(destFile,buf,blockNumber):
     file = open(destFile, "r+b")
     file.seek(512*blockNumber)
     file.write(buf)
     file.close
     return

itemCount=7
bufz=bytearray([ 0x20,                  # Return code
                 itemCount,             # Number of Item
                 0x00,                  # current Page
                 0x00,                  # MaxPage
                 0x00,
                 0x00                           
                ])


#tab=[   "TMAIN MENU","D.","D..","FLEMMINGS.WOZ","FCOMMANDO.DSK","FBOUNCING KAMUNGAS","FSPACE INVADERS",""]
tab=["TMAIN MENU","E","MFAVORITE","MFILE MANAGER","E ","VEMULATION|DISKII","MABOUT","",""]

offset=32

bufz[6:]=("MAIN MENU".ljust(23)).encode(encoding="utf-8")
bufz.append(0)
bufz.append(0)
bufz.append(0)
for i in range (0,itemCount+1):
    pos=i*24+offset
    print(i)
    l=len(tab[i])
    bufz[pos:]=(tab[i]).encode(encoding="utf-8")
    for k in range(l,25):
        bufz.append(0)

desired_length = 512
padding_byte = b'\x00'
while len(bufz) < desired_length:
    bufz += padding_byte



blockOffset=int(sys.argv[2])
buf2fil(sys.argv[1],bufz,blockOffset)

if debug:
    s=Bits(bufz)  
    s.pp('bin8,hex',width=110)
