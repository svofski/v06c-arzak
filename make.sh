set -e

PASM=prettyasm/main.js
BIN2WAV=../bin2wav/bin2wav.js
ZX0=./tools/zx0.exe
PNG2DB=./tools/png2db-arzak.py

ZX0_ORG=4000


MAIN=arzak
ROM=$MAIN-raw.rom
ROMZ=$MAIN.rom
WAV=$MAIN.wav
ROM_ZX0=$MAIN.zx0
DZX0_BIN=dzx0-fwd.$ZX0_ORG
RELOC=reloc-zx0
RELOC_BIN=$RELOC.0100

rm -f $ROM_ZX0 $ROM

if ! test -e scalesman_air25.inc ; then
  ./tools/ym6break.py music/scalesman_air25.ym songA_
fi

#if ! test -e firestarter_3elehaq.inc ; then
#    ./ym6break.py music/firestarter_3elehaq.ym songB_
#fi

if ! test -e arzak.inc ; then
    $PNG2DB arzak.png -lineskip 1 -leftofs 0 -nplanes 2 -lut 0,0,2,3,1 -labels varplane0,varplane1 > arzak.inc
fi

if ! test -e harzakc.inc ; then
    $PNG2DB harzakc.png -lineskip 1 -leftofs 8 -nplanes 2 -lut 0,2,3,1 -labels harzakc0,harzakc1 > harzakc.inc
fi

#if ! test -e texture.inc ; then
#    tools/png2db-arzak.py -mode tex2 texture.png >texture.inc
#fi

if ! test -e texture8.inc ; then
    tools/png2db-arzak.py -mode bits8 -lineskip 1 texture.png >texture8.inc
fi

$PASM $MAIN.asm -o $ROM
ROM_SZ=`cat $ROM | wc -c`
echo "$ROM: $ROM_SZ octets"

$ZX0 -c $ROM $ROM_ZX0
ROM_ZX0_SZ=`cat $ROM_ZX0 | wc -c`
echo "$ROM_ZX0: $ROM_ZX0_SZ octets"

$PASM -Ddzx0_org=0x$ZX0_ORG dzx0-fwd.asm -o $DZX0_BIN
DZX0_SZ=`cat $DZX0_BIN | wc -c`
echo "$DZX0_BIN: $DZX0_SZ octets"

$PASM -Ddst=0x$ZX0_ORG -Ddzx_sz=$DZX0_SZ -Ddata_sz=$ROM_ZX0_SZ $RELOC.asm -o $RELOC_BIN
RELOC_SZ=`cat $RELOC_BIN | wc -c`
echo "$RELOC_BIN: $RELOC_SZ octets"

cat $RELOC_BIN $DZX0_BIN $ROM_ZX0 > $ROMZ

#$BIN2WAV -m v06c-turbo $ROMZ $WAV
$BIN2WAV -c 5 -m v06c-rom $ROMZ $WAV
