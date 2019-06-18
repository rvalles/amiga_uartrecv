#!/usr/bin/env python3
import struct
import sys
import time
import serial
def sendblock(ser, buf):
    size=len(buf)
    while True:
        while ser.read(1)==b'A':
            print("size prompt received.")
            ser.write(struct.pack('>H', size))
            print("size sent:", size)
        print("size ack received")
        if not size:
            return 0
        ser.write(buf)
        cksum=sum(buf)%65536
        print("data sent. cksum:", cksum)
        ack=ser.read(1)
        print("checksum prompt received:", ack)
        #if ack=='O': #overflow -> retry
            #ser.write(b'S')
            #continue
        rcksum=struct.unpack('>H', ser.read(2))[0]
        print("checksum received:",rcksum)
        if rcksum==cksum:
            ser.write(b'W') #W to write
            break
        ser.write(b'S')
    return size
f = open(sys.argv[1], 'rb')
#345600, 354689, 394099, 506699, 591149
ser = serial.Serial('/dev/ttyUSB0', 506699)
while not ser.in_waiting:
    ser.write(b'!')
    time.sleep(.1)
blocksize = ord(ser.read(1))*256
print("maxblocksize received: ", blocksize)
blocksize = 512
while sendblock(ser, f.read(blocksize)):
    continue
ser.close()
f.close()
