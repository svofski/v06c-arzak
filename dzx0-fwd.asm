                .project dzx0-fwd.4000
                .org $4000
; -----------------------------------------------------------------------------
; ZX0 8080 decoder by Ivan Gorodetsky - OLD FILE FORMAT v1 
; Based on ZX0 z80 decoder by Einar Saukas
; v1 (2021-02-15) - 103 bytes forward / 100 bytes backward
; v2 (2021-02-17) - 101 bytes forward / 100 bytes backward
; v3 (2021-02-22) - 99 bytes forward / 98 bytes backward
; v4 (2021-02-23) - 98 bytes forward / 97 bytes backward
; v5 (2021-08-16) - 94 bytes forward and backward (slightly faster)
; v6 (2021-08-17) - 92 bytes forward / 94 bytes backward (forward version slightly faster)
; v7 (2022-04-30) - 92 bytes forward / 94 bytes backward (source address now in DE, slightly faster)
; -----------------------------------------------------------------------------
; Parameters (forward):
;   DE: source address (compressed data)
;   BC: destination address (decompressing)
;
; Parameters (backward):
;   DE: last source address (compressed data)
;   BC: last destination address (decompressing)
; -----------------------------------------------------------------------------
; compress forward with <-c> option (<-classic> for salvador)
;
; compress backward with <-b -c> options (<-b -classic> for salvador)
;
; Compile with The Telemark Assembler (TASM) 3.2
; -----------------------------------------------------------------------------

;#define BACKWARD


dzx0:
                ; $18, 8 lines
                ; $2f
                ; $47..
                lda $c021
                cpi $81
                jz bootscreen_da
                lxi h, jokecall 
                ; no boot screen, no jokes
                xra a
                mov m, a
                inx h
                mov m, a
                inx h
                mov m, a
bootscreen_da:
                lxi h, $c018
                shld mockblock

                lxi h, $

		lxi h,0FFFFh
		push h
		inx h
		mvi a,080h
dzx0_literals:
		call dzx0_elias
		call dzx0_ldir
		jc dzx0_new_offset
		call dzx0_elias
dzx0_copy:
		xchg
		xthl
		push h
		dad b
		xchg
		call dzx0_ldir
		xchg
		pop h
		xthl
		xchg
		jnc dzx0_literals
dzx0_new_offset:
		call dzx0_elias
		mov h,a
		pop psw
		xra a
		sub l
		rz
		push h
		rar\ mov h,a
		ldax d
		rar\ mov l,a
		inx d
		xthl
		mov a,h
		lxi h,1
		cnc dzx0_elias_backtrack
		inx h
		jmp dzx0_copy
dzx0_elias:
		inr l
dzx0_elias_loop:	
		add a
		jnz dzx0_elias_skip
		ldax d
		inx d
		ral
dzx0_elias_skip:
		rc
dzx0_elias_backtrack:
		dad h
		add a
		jnc dzx0_elias_loop
		jmp dzx0_elias

dzx0_ldir:
		push psw
dzx0_ldir1:
		ldax d
		stax b
		inx d
		inx b
		dcx h
		mov a,h
		ora l
		jnz dzx0_ldir1
jokecall:
                call joke
		pop psw
		add a
		ret
mockblock       dw 0
joke:           
                ;ora d
                ;xra c
                ;rpo
                push h
                push d
                push b
                lhld mockblock
                mvi a, $7e
                mov m, a

                inr l ;; $18,$19..$1f
                      ;; $30,$31..$37
                mov a, l
                ani 7
                jnz nana
nextblock:
                mov a, l
                sui 8
                mov l, a

                inr h
                mov a, h
                cpi $e0
                jnz nana

                mvi h, $c0
                mov a, l
                adi $18
                cpi $d8
                jnz $+5
                mvi a, $18 ; rollover from the start
                mov l, a
nana:
                shld mockblock
                pop b
                pop d
                pop h
                ret
		.end
