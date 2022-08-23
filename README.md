# ARZAK - a demo for Vector-06c

2nd place in Combined Intro at Undefined Summer 2022.

Links: [pouet](https://www.pouet.net/prod.php?which=92050) [demozoo](https://demozoo.org/productions/312404/) [events.retroscene](https://events.retroscene.org/undefined2022/Undefined_Intro/2764)

![harzakc screenshot](https://github.com/svofski/v06c-arzak/raw/master/screenshot.png "arzach avec son ptéroïde blanc")

Music credit: [scalesman^mc - melody in the air](https://zxart.ee/spa/autores/s/scalesmann/07-melody-in-the-air/qid:500227/) (looped and adjusted for 25Hz, apologies to the author).

## Music player: Gigachad16

This is the first time Gigachad16 is used in the wild. Gigachad16 is a player for compressed YM6 files. YM6 is a music format in form of AY-3-8912/YM-2419 register dumps. It is documented here: http://leonard.oxg.free.fr/ Before YM6 file can be used with Gigachad16, it has to be preprocessed using a script in tools/ym6break.py. 

In order to unpack 14 independently packed streams, Gigachad16 implements a simple RTOS kernel with cooperative multitasking. 14 DeZX0 tasks unpack 14 data streams, 16 bytes at a time, frame by frame. The entire player takes only 5-20 raster lines on Vector-06c, which probably makes it the fastest AY player for 8080. Data compression rates for interleaved YM6 streams are very good, but RAM requirements for the buffers and task stacks are relatively high. Buffers occupy (256 bytes window + 22 bytes task context) * 14 = 3892 extra bytes.

ZX0 unpacker is based on [ZX0 8080 decoder by Ivan Gorodetsky and Einar Saukas](https://github.com/ivagorRetrocomp/DeZX).

### ym6break.py

Requirements: lhafile for packed ym6 files and [salvador](https://github.com/emmanuel-marty/salvador) for windowed zx0 compression.

It opens an ym6 file, breaks it into independent register streams, compresses each stream and creates include files usable with Gigachad16.

YM6 files can be created from any AY-specific format using [Ay_Emul](https://bulba.untergrund.net/emulator_e.htm) by Sergey Bulba.

