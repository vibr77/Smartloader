

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

def buffer2file(filename,buffer,offset):

     file = open(filename, "w+b")
     file.seek(offset)
     file.write(buffer)
     file.close
     return


buffer=bytearray(35*16*256)
for i in range (0,35):
     for j in range (0,16):
          for k in range (0,256):
               buffer[i*16*256+j*256+k]=0

print()
print("-------------------------------------------------------------------------------")
print("SCRIPT: Init Blank dsk file")
print("-------------------------------------------------------------------------------")
print("destination file:"+sys.argv[1])
print("-------------------------------------------------------------------------------")
print()
print()
buffer2file(sys.argv[1],buffer,0)