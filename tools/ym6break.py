#!/usr/bin/env python3

# usage: ./ym6break.py unpacked-interleaved.ym label_prefix_
#
# ym file must be unpacked, interleaved (default for Ay_Emul)
#
# requires ./tools/salvador.exe

import struct
import sys
import os
from subprocess import Popen, PIPE
from utils import *

TOOLS = './tools/'
SALVADOR = TOOLS + 'salvador.exe'

def drop_comment(f):
    comment = ''
    while True:
        b = f.read(1)
        if b[0] == 0:
            break
        comment = comment + chr(b[0])
        print(chr(b[0]), end='')
    print()
    return comment

def readym(filename):
    with open(filename, "rb") as f:
        hdr = f.read(12) # YM6!LeOnArD!               # 12
        nframes = struct.unpack(">I", f.read(4))[0]      # 16

        print("YM6 file has ", nframes, " frames")

        attrib = struct.unpack(">I", f.read(4))       # 20
        digidrums = struct.unpack(">h", f.read(2))    # 22
        masterclock = struct.unpack(">I", f.read(4))  # 26
        framehz = struct.unpack(">h", f.read(2))      # 28
        loopfrm = struct.unpack(">I", f.read(4))      # 32
        f.read(2) # additional data                   # 34
        print("Masterclock: ", masterclock, "Hz")
        print("Frame: ", framehz, "Hz")

        # skip digidrums but we don't do that here..

        comment1 = drop_comment(f)
        comment2 = drop_comment(f)
        comment3 = drop_comment(f)

        regs=[]
        for i in range(16):
            complete = list(f.read(nframes))
            chu = chunker(complete, 2)
            #decimated = [x if x < y else y for x, y in chu]
            #decimated = complete[::2]
            #decimated = [x if x != 255 else y for x, y in chu]
            decimated = complete
            #print(f'complete[{i}]=', complete)
            #print(f'decimated[{i}]=', decimated)
            decbytes = bytes(decimated)
            regs.append(decbytes)  ## brutal decimator

        return [regs, comment1, comment2, comment3]

try:
    ymfile = sys.argv[1]
except:
    sys.stderr.write(f'usage: {sys.argv[0]} unpacked-interleaved.ym label_prefix\n')
    exit(1)
    
(origname, ext) = os.path.splitext(ymfile)
basename = os.path.basename(origname)
incname = basename + ".inc"

try:
    label = sys.argv[2]
except:
    label = origname.replace('-', '_')

workdir = 'tmp/'

try:
    os.mkdir(workdir)
except:
    pass

try:
    [columns, comment1, comment2, comment3] = readym(ymfile)
except:
    sys.stderr.write(f'error reading f{ymfile}\n')
    exit(1)

with open(incname, "w") as inc:
    inc.write(f'; {comment1}\n; {comment2}\n; {comment3}\n')
    for i, c in enumerate(columns[0:14]):
        cname = workdir + basename + ("%02d" % i) + ".bin"
        zname = workdir + basename + ("%02d" % i) + ".z"
        with open(cname, "wb") as f:
            f.write(c)
        
        with Popen([SALVADOR, "-v", "-classic", "-w 256", cname, zname], stdout=PIPE) as proc:
            print(proc.stdout.read())

        with open(zname, "rb") as f:
            dbname = label + ("%02d" % i)
            data = f.read()
            inc.write(f'{dbname}: db ' +  ",".join("$%02x" % x for x in data) + "\n")
