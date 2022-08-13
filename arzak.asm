                ; je m'appelle arzak
                .project arzak.rom
                .tape v06c-rom
		.org 100h

MESSAGES_XY     equ $0010

		di
; ---
start:
		xra	a
		out	10h
		lxi	sp,100h
		mvi	a,0C3h
		sta	0
		lxi	h,Restart
		shld	1

		mvi	a,0C9h
		sta	38h

                ; all blakc
                lxi h, colors0+15
                call colorset

                call    precalc_rails

Restart:
                lxi sp, $100
                lxi h, colors0+15
                call colorset
		call	Cls
                xra a
                sta framecnt

                ; нарисовать перспективные линии уходящие вдаль
                call scan_fanout		

                ; нарисовать горизонтальные подвижные линии
prefill:
		mvi c, 40 
prefill_L1:
		push b
		call persplines
		pop b
		dcr c
		jnz prefill_L1

                ; развернуть текстуры с маской для скроллера
                call prepare_textures

                ; нарисовать большую надпись внизу HARZAKC
                mvi c, $40
                mvi a, $c0      ; 
                sta varblit_plane
                lxi d, harzakc0
                call varblit

                mvi c, $3f
                mvi a, $e0      ; 
                sta varblit_plane
                lxi d, harzakc1
                call varblit


                ; верхние линии
                call drawsky

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;    MAIN LOOP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                ;ei
                di

                ; загружаем и прокачиваем начало песенки
                lxi h, song_1
                call gigachad_init
                call gigachad_enable
                call gigachad_precharge

                ;lxi h, colors_main+15
                ;call colorset

                call colors_blackout
                mvi a, OPCODE_STC
                sta fade_in_flag

                call msgseq_init

                ; все тяжкие: основной цикл и даже музыка без синхронизации
foreva:
                call rnd16

                call persplines

                lxi h, framecnt
                mov a, m
                inr m
                rar
                lda arzaky
                jc az_L2
                
                lxi h, arzakdy
                mov a, m
                inx h           ; h = &arzaky
                mov b, m
                add b           ; a = arzaky + arzakdy
                mov m, a        ; arzaky = a
                dcx h           ; h = &arzakdy
                cpi 8           ; y = 8
                jnz az_L1       ; no, ok
                mvi m, -1       ; dy = -1
az_L1           cpi -8          ; y = -8?
                jnz az_L2
                mvi m, 1
az_L2
                adi $d0
                mov c, a        ; y position
                mvi a, $c0      ; 
                sta varblit_plane
                lxi d, varplane0

                lda framecnt                
                rar
                push psw

                jnc az_L3x
                ei              ; sync before white
                hlt
az_L3x

                jc az_L3        ; odd frame -> white
                mvi a, $e0
                sta varblit_plane
                lxi d, varplane1  ; even frame -> red/yellow
az_L3
                ;mvi a, 15
                ;out 2

                call varblit
                ;mvi a, 0
                ;out 2


                ; выравниваем медленный-быстрый кадры
                ; два гигачада ~6500 + в быстрый кадр
                ; в медленном только вывод АЫ
                pop psw
                jc az_L4      ; slow white frame, one gigachad
                ; fast red frame
                call gigachad_frame
                call ay_send_user
                call gigachad_frame
                jmp az_L5
az_L4
                call ay_send_user
az_L5
                call scrollerframe6 ; 67416, ~49752 with premasked
                                    ; 61272 with every other y update 
                                    ; 58200 without extra inx b
                                    ; 40592 with premasked / every other
                                    ; 50/(0.5*(70+89)/59.9) ~ 37.5 fps

                ; искорки на надписи 
                call sparky

                call msgseq_frame

fade_in_flag    stc
                jnc foreva

                call clrs_fadetomain
                lxi h, colors_buf+15
                call colorset

                lda framecnt
                cpi 8
                jm foreva
                mvi a, OPCODE_ORA_A
                sta fade_in_flag
		jmp foreva

arzakdy         db 1
arzaky          db $0
framecnt        db 0
texlinecnt      db 0

                ; fast fill horizontal segment
                ; a = y
                ; b = x1, c = x2

skylines:       db $75, $00, $58,  $75, $60, $70,   $75, $90, $ff
                db $79, $00, $52,   $79, $98, $ff
                db $80, $00, $47,  $80, $4c, $54,   $80, $98, $9c,  $80, $a0, $ff
                db $88, $00, $40,   $88, $9b, $a3,  $88, $aa, $ff
                db $96, $00, $40,   $96, $a8, $ff
                ;;db $b7, $00, $60, $b7, $90, $ff
                db $b7, $00, $4a,  $b7, $50, $60,   $b7, $8c, $94, $b7, $9a, $ff
                db $e0, $00, $08, $e0, $3a, $42,  $e0, $46, $ca,   $e0, $d0, $e0
                db 0

skylines_white:
               ;db $73, $00, $58,   $73, $a0, $ff
               db $73, $00, $ff
               db $75, $00, $4e,   $75, $a0, $ff
               db 0

skylines_red:
               ;db $73, $00, $58,   $73, $a0, $ff
               ;db $74, $00, $ff
               db $75, $00, $4e,   $75, $a0, $ff
               db $77, $00, $38,   $77, $a8, $ff
               db $7c, $00, $48,   $7c, $a0, $a8,  $7c, $b0, $ff
               db $84, $00, $26,   $84, $30, $40,  $84, $a8, $bf,  $84, $d0, $ff
               db $8f, $00, $30,   $8f, $b0, $b6,  $8f, $c8, $ff
               db 0
               
trolltbl:
              db $50, $64,  $94, $98,    0, 0, 0, 0  ; -8
              db $50, $64,  $93, $98,    0, 0, 0, 0  ; -7
              db $50, $64,  $92, $98,    0, 0, 0, 0  ; -6
              db $50, $64,  $91, $98,    0, 0, 0, 0  ; -5
              db $50, $65,  $90, $98,    0, 0, 0, 0  ; -4
              db $50, $65,  $90, $98,    0, 0, 0, 0  ; -3  
              db $50, $66,  $8f, $98,    0, 0, 0, 0  ; -2
              db $50, $66,  $8f, $98,    0, 0, 0, 0  ; -1
              
              db $50, $67,  $8e, $98,    0, 0, 0, 0  
              db $50, $67,  $8e, $98,    0, 0, 0, 0  
              db $50, $68,  $8d, $98,    0, 0, 0, 0  
              db $50, $69,  $8d, $98,    0, 0, 0, 0  
              db $50, $6a,  $8c, $98,    $75, $76, 0, 0  
              db $50, $6a,  $8c, $98,    $74, $77, 0, 0  
              db $50, $6b,  $8b, $98,    $74, $77, 0, 0  
              db $50, $6b,  $8b, $98,    $73, $78,  0, 0  
              db $50, $6b,  $8b, $98,    $73, $78, 0, 0  

              ; хитрость -- рисуем белые линии на горизонте
              ; вокруг хобота птероида итд, смотрится как будто
              ; весь огромный спрайт выводится с маской
              ; это надо делать синхронно с птероидом, иначе мы опаздываем 
              ; за лучом (слишком низко в кадре) и получается мерцание
              ; см troll_hook
trollsky:       
              mvi a, $c0
              sta hline_xy+1

              lda arzaky; -8..8
              adi 8
              add a
              add a
              add a
              adi trolltbl & $ff
              mov l, a
              mvi a, trolltbl >> 8
              aci 0
              mov h, a
ts_L1:              
              mov a, m
              ora a
              rz
              inx h
              mov b, a
              mov c, m \ inx h
              mvi a, $73
              push h
              call hline_xy
              pop h
              jmp ts_L1
              

drawsky:
                mvi a, $c0 ; white
                sta hline_xy+1
                lxi h, skylines_white
                call drawsky_L1

                mvi a, $e0 ; red
                sta hline_xy+1
                lxi h, skylines_red
                call drawsky_L1


                mvi a, $a0
                sta hline_xy+1
                lxi h, skylines
                call drawsky_L1
                ret
                
drawsky_L1:
                mov a, m \ inx h
                ora a
                rz
                mov b, m \ inx h
                mov c, m \ inx h
                push h
                call hline_xy
                pop h
                jmp drawsky_L1
                
spark_xy        dw 0

sparky          
                lda framecnt
                ani $3
                rnz
                call sparkle_restore

                lda rnd16+1
                ani $1f
                adi $20
                sta spark_xy

                lda rnd16+2
                ani $f
                adi 8
                sta spark_xy+1

                call sparkle_save

                ret

sparkle_back    ds 14

sparkle_save
                lhld spark_xy
                mvi a, $c0
                add h
                mov h, a        ; hl -> $c000

                mvi a, $20
                add h
                mov d, a        ; de -> $e000

                mvi a, 3
                add l
                mov l, a
                mov e, a

                lxi b, sparkle_back

                mov a, m \ stax b \ inx b   ; save
                ori 8 \ mov m, a            ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $f7 \ stax d            ; clear
                dcr l \ dcr e

                mov a, m \ stax b \ inx b   ; save
                ori 8 \ mov m, a            ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $f7 \ stax d            ; clear
                dcr l \ dcr e

                mov a, m \ stax b \ inx b   ; save
                ori 8 \ mov m, a            ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $f7 \ stax d            ; clear
                dcr l \ dcr e

                mov a, m \ stax b \ inx b   ; save
                ori $7f \ mov m, a          ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $80 \ stax d            ; clear
                dcr l \ dcr e

                mov a, m \ stax b \ inx b   ; save
                ori 8 \ mov m, a            ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $f7 \ stax d            ; clear
                dcr l \ dcr e

                mov a, m \ stax b \ inx b   ; save
                ori 8 \ mov m, a            ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $f7 \ stax d            ; clear
                dcr l \ dcr e

                mov a, m \ stax b \ inx b   ; save
                ori 8 \ mov m, a            ; draw 
                ldax d \ stax b \ inx b     ; save
                ani $f7 \ stax d            ; clear
                dcr l \ dcr e

                ret

sparkle_restore 
                lhld spark_xy
                mvi a, $c0
                add h
                mov h, a

                mvi a, $20
                add h
                mov d, a

                mvi a, 3
                add l
                mov l, a
                mov e, a

                lxi b, sparkle_back
        
                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ldax b \ mov m, a \ inx b \ dcx h 
                ldax b \ stax d   \ inx b \ dcx d

                ret



                ; ; ; ; ; ; ; ; ; ; 
                ; draw 6 textured sines
                ; ; ; ; ; ; ; ; ; ;  

#ifdef ONETEXTURE

              ;lxi b, scroll_rail
              ;lxi d, texture
draw_tex0:     
              lxi h, 0
              dad sp
              shld draw_tex0_sp+1
              
              ; texture on stack
              xchg
              sphl

              lxi h, (TEX_PLANE << 8) | $ff
dtex0_L1:
              ; v3  h = screen, d = tex
              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $c0 \ ana e \ mov e, a
              mvi a, $3f \ ana m \ ora e \ mov m, a
              
              ;ldax b \ mov l, a \ inx b \ -- this is invisible by eyej
              ;inx b 

              mvi a, $30 \ ana d \ mov d, a 
              mvi a, $cf \ ana m \ ora d \ mov m, a

              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $f3 \ ana m \ mov m, a
              mvi a, $0c \ ana e
              ora m \ mov m, a

              ;ldax b \ mov l, a \ inx b
              ;inx b
              mvi a, $fc \ ana m \ mov m, a
              mvi a, $03 \ ana d
              ora m \ mov m, a

              inr h

              ; v3  h = screen, d = tex
              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $3f \ ana m \ mov m, a
              mvi a, $c0 \ ana e
              ora m \ mov m, a

              ;ldax b \ mov l, a \ inx b \
              ;inx b
              mvi a, $cf \ ana m \ mov m, a \ 
              mvi a, $30 \ ana d
              ora m \ mov m, a

              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $f3 \ ana m \ mov m, a
              mvi a, $0c \ ana e
              ora m \ mov m, a

              ;ldax b \ mov l, a \ inx b
              ;inx b
              mvi a, $fc \ ana m \ mov m, a
              mvi a, $03 \ ana d
              ora m \ mov m, a

              ; next column
              inr h             ; de += 256

              mvi a, TEX_PLANE + 32 ; $e0 ; $c0+$20
              cmp h
              jnz dtex0_L1
draw_tex0_sp: lxi sp, 0
              ret




scrollerframe6
                lxi b, scroll_rail

                ; pick texture and offset
                lxi d, texture1
                llda framecnt
                ani $7f
                add e
                mov e, a
sf6_L1:
                push b
                push d

                call draw_tex0

                pop d
                inr d
                pop b
                inr b
                mvi a, (scroll_rail>>8) + 6
                cmp b
                jnz sf6_L1

                ret
#else
scrollerframe6
                lxi b, scroll_rail

                ; pick texture and offset
                lxi d, texture_premasked
                lda framecnt
                mov h, a
                ani $7f
                add e
                mov e, a

                ; adjust for premasked texture: (framecnt & 3) * 6
                mov a, h
                ani 3 
                ; a *= 6
                add a 
                mov h, a
                add a
                add h
                ; d += (framecnt & 3) * 6
                add d
                mov d, a

sf6_L1:
                push b
                push d

                call draw_tex_premasked

                pop d
                inr d
                pop b
                inr b
                mvi a, (scroll_rail>>8) + 6
                cmp b
                jnz sf6_L1

                ret

              
              ; 80000/97000 vs 9
draw_tex_premasked:     
              lxi h, 0
              dad sp
              shld draw_tex_premasked_sp+1
              
              ; texture on stack
              xchg
              sphl

              lxi h, (TEX_PLANE << 8) | $ff
dtexpre_L1:
              ; v3  h = screen, d = tex
              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $3f \ ana m \ ora e \ mov m, a

              ;ldax b \ mov l, a \ inx b \
              ;inx b
              mvi a, $cf \ ana m \ ora d \ mov m, a

              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $f3 \ ana m \ ora e \ mov m, a

              ;ldax b \ mov l, a \ inx b \
              ;inx b
              mvi a, $fc \ ana m \ ora d \ mov m, a

              inr h

              ; v3  h = screen, d = tex
              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $3f \ ana m \ ora e \ mov m, a

              ;ldax b \ mov l, a \ inx b \
              ;inx b
              mvi a, $cf \ ana m \ ora d \ mov m, a

              pop d
              ldax b \ mov l, a \ inx b
              mvi a, $f3 \ ana m \ ora e \ mov m, a

              ;ldax b \ mov l, a \ inx b \
              ;inx b
              mvi a, $fc \ ana m \ ora d \ mov m, a

              inr h


              mvi a, TEX_PLANE + 32 ; $e0 ; $c0+$20
              cmp h
              jnz dtexpre_L1
draw_tex_premasked_sp: 
              lxi sp, 0
              ret
              

#endif
persplines
                mvi c, n_lines

                lxi h, line_z
drawlines_L1:         
                ; odd/even based on value of c
                ; find out colour for this line
                mov a, c
                rar
                sbb a
                sta fill_color+1

                push b
                push h
                
                mov a, m
                call persp_y
                mov d, a        ; d = old Y

                inr m           ; z = z + 1
                mov a, m
                call persp_y
                mov e, a        ; e = a =  new value
draw_next_y:
                cmp d           ; compare new to old in d
                jm end_draw
fill_color:     mvi b, 0
                
                ;; inline hline
                lxi h, $8000
                add l
                mov l, a
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b \ inr h
                mov m, b \ inr h \ mov m, b ;\ inr h
                
                ;; inline hline
                dcr a
                jp draw_next_y
                
end_draw:
                pop h
                inx h
                pop b
                dcr c
                jnz drawlines_L1
                ret
                

scan_fanout:
                ; чтобы точно была плоскость A0 после рестарта
                mvi a, $a0
                sta hline_xy+1
                
		; dumb and full of cum way of drawing fanning stripes

                mvi a, 114
                sta line_y0

                lxi d, $1000    ; 10.[0/256] = increment
scan_line:
                mvi b, 128
                
                mvi a, 0
                sta scan_odd+1
                lxi h, 0        ; x = 0.0 fixed point 0, 1/255 fractional part
scan_line_L1:                
                dad d           ; x = x + dx
                push h
                push d
                
                mov a, h        ; a = max(floor(x), 127)
                ora a
                jp $+5
                mvi a, $7f
                adi 128         ; a = screen x1
                mov c, a

scan_odd:       mvi a, 0
                cma
                sta scan_odd+1
                ora a ; mind the flags
                
                lda line_y0
                push b
                push psw
                cnz hline_xy
                pop psw
                pop b
                jnz scan_nomiroir
                
                push b
                ; miroir
                mov d, b
                mov a, c
                sbi 128 \ cma \  adi 128 ; adi 127 should be fine?
                mov b, a
                mov a, d
                sbi 128 \ cma \  adi 128 ; adi 127 should be fine?
                mov c, a
                
                lda line_y0
                call hline_xy
                pop b
scan_nomiroir:                
                mov b, c
                
                pop d
                pop h
                
                mvi a, 0
                ora h
                jp scan_line_L1

                ; next y
                lda line_y0
                dcr a
                ;jm scan_done
                rm
                sta line_y0

                ; increase dx
                lxi h, $80
                dad d
                xchg
                jmp scan_line
;scan_done                
;                ret                
                
; 
; horizontal lines
;
n_lines         equ 6
line_z          db 0, 42, 84, 126, 168, 210

                ; a = z
                ; returns a = y'
                ; CLOBBERS: a
persp_y         push h
                lxi h, persp_tab
                add l
                mov l, a
                mvi a, 0
                adc h
                mov h, a
                mov a, m
                pop h
                ret
                
; inlined in persplines
;                ; fill full horizontal line
;                ; b = bitmap
;                ; a = y
;                ; CLOBBERS: hl 
;hline           
;                lxi h, $8000
;                add l
;                mov l, a
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b \ inr h
;                mov m, b \ inr h \ mov m, b ;\ inr h
;                ret

                ; fast fill horizontal segment
                ; a = y
                ; b = x1, c = x2
hline_xy           
                mvi h, $a0
                mov l, a
                ; c - b = count
                mov a, c
                sub b
                inr a
                mov c, a
hline_xy_L1:                
                ; column = x / 8, pixel = x % 8
                mov a, b
                rar \ rar \ rar
                ani $1f
                add h
                mov h, a
                
                ; find first pixel mask
                mvi a, 7
                ana b  ; x % 8
                adi PixelMask & 255
                mov e, a
                mvi a, PixelMask >> 8
                aci 0
                mov d, a
                ldax d
                
                mov d, a
                ; set pixel
hline_xy_L2x:
                mov a, d
hline_xy_L2:                
                ora m
                mov m, a
                
                dcr c
                rz
                
                mov a, d        ; mask
                rrc
                mov d, a
                jnc hline_xy_L2 ; no rollover, same column
hline_xy_L3:                
                inr h           ; next column
                
                mov a, c
                sui 8
                jm hline_xy_L2x ; less than 8 pixels remain, process by one
                
                ; do in chunks
                mov c, a
hline_xy_bitmap equ $+1
                mvi m, $ff
                jnz hline_xy_L3
                ret

#ifdef RINGARDE_RAILS
                ; рассчитать верхнюю рельсу скроллера x 8
precalc_rails_simple:  
                
                lxi h, 0    ; начальная фаза
                lxi b, $70 ;$80  ; 0.5   приращение аргумента
                mvi a, 0    ; 256 values to calculate
                lxi d, scroll_rail
prails_L1:
                push psw
                push h
                push d
                mov e, h    ; arg
                call cose
                ; do stuff with de 
                mov a, e
                rar \ rar \ rar \ ani $1f  ; a = de / 8
                cma
                pop d

                push d
                
                xchg
                lxi d, 256
                mov m, a \ sui 3  \ dad d
                mov m, a \ sui 3  \ dad d
                mov m, a \ sui 3  \ dad d
                mov m, a \ sui 3  \ dad d
                mov m, a \ sui 3  \ dad d
                mov m, a \ sui 3  \ dad d
                mov m, a \ sui 3  \ dad d
                mov m, a ;\ dcr a \ dad d


                pop d
                inx d
                pop h
                dad b
                pop psw
                dcr a
                jnz prails_L1
                
                ret
#else

;DXSTEP          equ 38 -- cool
                ; приращение аргумента
DXBASE          equ $c0 ; /2  - сократили inx b в выводе текстуры
DXSTEP          equ 7;10
YOFFS           equ 0 ; -16
INITPHASE       equ $6000 ; $7800
TEX_PLANE       equ $c0
precalc_rails:
                lxi h, DXBASE; $c0/2 ; $10;$20
                lxi b, DXSTEP
                push h
                push b
                shld crail_dx

                mvi a, YOFFS
                sta crail_constofs
                lxi h, scroll_rail
                shld crail_railptr

                call calc_rail

                pop b
                pop h
                dad b
                push h
                push b
                shld crail_dx

                mvi a, YOFFS + 3*1
                sta crail_constofs
                lxi h, scroll_rail + 256*1
                shld crail_railptr
                call calc_rail

                pop b
                pop h
                dad b
                push h
                push b
                shld crail_dx


                mvi a, YOFFS + 3*2
                sta crail_constofs
                lxi h, scroll_rail + 256*2
                shld crail_railptr
                call calc_rail

                pop b
                pop h
                dad b
                push h
                push b
                shld crail_dx


                mvi a, YOFFS + 3*3
                sta crail_constofs
                lxi h, scroll_rail + 256*3
                shld crail_railptr
                call calc_rail

                pop b
                pop h
                dad b
                push h
                push b
                shld crail_dx

                mvi a, YOFFS + 3*4
                sta crail_constofs
                lxi h, scroll_rail + 256*4
                shld crail_railptr
                call calc_rail

                pop b
                pop h
                dad b
                push h
                push b
                shld crail_dx

                mvi a, YOFFS + 3*5
                sta crail_constofs
                lxi h, scroll_rail + 256*5
                shld crail_railptr
                call calc_rail

                pop b
                pop h

                ret



calc_rail:
                lxi h, INITPHASE    ; начальная фаза
crail_dx        equ $+1
                lxi b, DXBASE
                mvi a, 0    ; 256 values to calculate
crail_railptr   equ $+1
                lxi d, scroll_rail
crail2_L1:
                push psw
                push h
                push d
                mov e, h    ; arg
                call cose
                ; do stuff with de 
                mov a, e
                ;rar \ rar \ rar \ ani $1f  ; a = de / 8
                ;rar \ rar \ ani $3f
                ;ora a \ rar
                cma
                pop d
crail_constofs  equ $+1
                sui 3
                stax d
                inx d
                pop h
                dad b   ; x += dx
                pop psw
                dcr a
                jnz crail2_L1
                ret

#endif
                

; shift0:
; c0, 30, 0c, 03, ...
; shift1:
; 03, c0, 30, 0c
; shift2:
; 0c, 03, c0, 30
; shift3:
; 30, 0c, 03, c0 


#ifdef BYTE_TEXTURE
prepare_textures:
              lxi d, texture_premasked

              mvi l, $c0
preptex_L0:
              mvi h, 6
              lxi b, texture1
preptex_L1: 
              ldax b \ ana l \ stax d \ inx d \ inr c 
              mov a, l \ rrc \ rrc \ mov l, a
              jnz preptex_L1

              inr b
              dcr h
              jnz preptex_L1
              
              rlc \ rlc
              mov l, a
              cpi $c0
              jnz preptex_L0
              ret




              .org 0x100 + . & 0xff00  ; ALIGN 256
texture1       
              ;.include texture.inc

#else

ptctr         db 0

prepare_textures:
              lxi d, texture_premasked
              mvi l, $c0
              mvi h, $80      ; pointer to second texture copy
prept_L0:
              lxi b, texture8
              mvi a, 6
prept_L1A:
              sta ptctr
prept_L1: 
              ldax b
              push b

              ;;;; unwrap 1 byte
              mvi c, 8
prept_L2:
              ral \ mov b, a
              mvi a, 0    ;; carry -> 0xff, no carry = 0
              sbi 0

              ana l 
              stax d          ; preshifted[d] = anal

              push d
              mov e, h
              stax d          ; preshifted[d + 128] = anal
              pop d

              inr h
              inx d         
              mov a, l \ rrc \ rrc \ mov l, a ; next mask

              dcr c           ; bit count
              mov a, b
              jnz prept_L2
              ;;;; - unwrap 1 byte 

              ; unwrapped 8 bits -> 8 bytes, next source byte
              pop b     ; b = source ptr
              inx b     ; src++

              ; go to next line?
              mvi a, $80
              cmp e
              jnz prept_L1

              ; end of line, align de to 256
              inr d
              mvi e, 0
              mvi h, $80

              ; end of line, count it
              lda ptctr
              dcr a
              jnz prept_L1A
              
              ; next texture shift
              mov a, l
              rlc \ rlc
              mov l, a
              cpi $c0
              jnz prept_L0
              ret

              ;.org 0x100 + . & 0xff00  ; ALIGN 256
texture8       
              .include texture8.inc
#endif

;              .org 0x100 + . & 0xff00  ; ALIGN 256
;scroll_rail:  .ds 256*8


                
                ; m = arg
cosm:           mov e, m
cose:           ; clobbers hl, d = 0, e = result
                mvi d, 0
                lxi h, costab
                dad d           ; hl = ptr cos(arg)
                mov e, m        ; de = cos(arg)
                ret

costab          .db 255,255,255,255,254,254,254,253,253,252,251,250,249,249,247,246,245,244,243,241,240,238,237,235,233,232,230,228,226,224,222,220,217,215,213,210,208,206,203,201,198,195,193,190,187,184,182,179,176,173,170,167,164,161,158,155,152,149,146,142,139,136,133,130,127,124,120,117,114,111,108,105,102,99,96,93,90,87,84,81,78,75,72,69,66,64,61,58,56,53,51,48,46,43,41,39,37,34,32,30,28,26,24,23,21,19,17,16,14,13,12,10,9,8,7,6,5,4,3,3,2,2,1,1,0,0,0,0,0,0,0,0,1,1,2,2,3,3,4,5,6,7,8,9,10,12,13,14,16,17,19,21,23,24,26,28,30,32,34,37,39,41,43,46,48,51,53,56,58,61,64,66,69,72,75,78,81,84,87,90,93,96,99,102,105,108,111,114,117,120,124,127,130,133,136,139,142,146,149,152,155,158,161,164,167,170,173,176,179,182,184,187,190,193,195,198,201,203,206,208,210,213,215,217,220,222,224,226,228,230,232,233,235,237,238,240,241,243,244,245,246,247,249,249,250,251,252,253,253,254,254,254,255,255,255,255

; установить пиксель в плоскости $80
; вход:
; H - X
; L - Y
setpixel:
		mov d,h
		mvi a,11111000b
		ana h
		rrc
		rrc
		stc
		rar
                adi $40
		mov h,a
		mvi a,111b
		ana d
		mov e,a
		mvi d,PixelMask>>8
		ldax d
		ora m
		mov m,a
		ret

		; аргументы line()
line_x0		.db 100
line_y0		.db 55
line_x1		.db 0
line_y1		.db 50 

                .org 0x100 + . & 0xff00
PixelMask:
		.db 10000000b
		.db 01000000b
		.db 00100000b
		.db 00010000b
		.db 00001000b
		.db 00000100b
		.db 00000010b
		.db 00000001b

                ;;;
                
		
Cls:
                lxi h, 0
                dad sp
                shld cls_sp+1
                lxi sp, 0
                lxi d, 0
                ; 256/32 * 32 -> 256 times for one bitplane
                lxi b, $400
cls_L1:           
                push d \ push d \ push d \ push d
                push d \ push d \ push d \ push d
                push d \ push d \ push d \ push d
                push d \ push d \ push d \ push d
                dcr c
                jnz cls_L1
                dcr b
                jnz cls_L1
cls_sp:         lxi sp, 0
                ret



                ; di
                ; mvi c, $d0
                ; mvi a, $c0
                ; sta varblit_plane
                ; lxi d, varplane0
                ; call varblit

varblit:
                ;di
                lxi h, 0
                dad sp
                shld varblit_sp
                xchg
                sphl
        
                ;mvi d, 80
                mov l, c
vb_L0:                
                pop b   ; c = first column, b = number of 2-column chunks (0-16)
                mov a, b    ; end = 255, 255
                ana c
                jm vb_exit
                
varblit_plane   equ $+1
                mvi a, $c0 ; plane msb
                add c
                mov h, a        ; hl = screen addr

                mov a, b ; b = precalculated offset into vbline_16
                sta vb_M1+1
vb_M1:          jmp vbline_16
vb_L1:

                .org 0x100 + . & 0xff00
vbline_16:      pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b \ inr h
                pop b \ mov m, c \ inr h \ mov m, b; \ inr h
                
vb_L2:          ; next line
                dcr l

                mvi a, -$73
                add l             ; перед строкой 73 очистить края вокруг будто маска
                jz troll_clearhook
                inr a
                jz troll_hook     ; после строки 73 нарисовать белый горизонт вокруг птероида

vb_L3:
                jmp vb_L0

vb_exit:                
varblit_sp      equ $+1
                lxi sp, 0
                ret

vb_hl:          dw 0
troll_hook:
                shld vb_hl
                lxi h, 0
                dad sp
                shld trollhook_sp
                lhld varblit_sp
                sphl

                call trollsky
                lhld vb_hl

trollhook_sp    equ $+1
                lxi sp, 0
                jmp vb_L3

troll_clearhook:
                mvi a, $e0
                cmp h
                jm vb_L3
                shld vb_hl
                lxi h, $ca73
                xra a
                mov m, a \ inr h \ mov m, a \ inr h \ mov m, a

                inr h \ inr h \ inr h \ inr h
                mov m, a \ inr h \ mov m, a \ inr h \ mov m, a
                


                lhld vb_hl
                jmp vb_L3


		; выход:
		; HL - число от 1 до 65535
rnd16:
		lxi h,65535
		dad h
		shld rnd16+1
		rnc
		mvi a,00000001b ;перевернул 80h - 10000000b
		xra l
		mov l,a
		mvi a,01101000b	;перевернул 16h - 00010110b
		xra h
		mov h,a
		shld rnd16+1
		ret

colors_blackout:
                lxi h, colors_buf
                mvi c, 16
                xra a
cab_L1:
                mov m, a
                inx h
                dcr c
                jnz cab_L1
                ret

clrs_fadetomain:
                lxi h, colors_buf
                lxi d, colors_main

                mvi c, 16
clrs_ftm_L1:
                push b

                mvi c, 0    ; c = color accumulator
                ldax d
                ani 007q    ; rouge
                mov b, a    ; b = rouge goal

                mov a, m
                ani 007q

                cmp b
                jp $+5      ; z+ -> no need to change
                adi 001q     
                
                ora c
                mov c, a

                ; vert
                ldax d
                ani 070q
                mov b, a
                mov a, m
                ani 070q
                cmp b
                jp $+5
                adi 010q
                ora c
                mov c, a

                ; azul
                ldax d
                ani 300q
                mov b, a
                mov a, m
                ani 300q
                cmp b
                jnc $+5
                adi 100q
                ora c
               
                mov m, a  ; save 
                
                inx h
                inx d
                pop b
                dcr c
                jnz clrs_ftm_L1
                ret

                

colorset:
                ei
                hlt
		mvi	a, 88h
		out	0
		mvi	c, 15
colorset1:	mov	a, c
		out	2
		mov	a, m
		out	0Ch
		dcx	h
		out	0Ch
		out	0Ch
		dcr	c
		out	0Ch
		out	0Ch
		out	0Ch
		jp	colorset1
		mvi	a,255
		out	3
                ret
                ; 8 A C E
                ; 0 0 x x = 0
                ; 1 0 x x = 1
                ; 0 1 x x = 1
                ; 1 1 x x = 0
                
floor0          equ 000q
floor1          equ 233q ; 213q
pic1            equ 156q  ; желтушный
pic2            equ 114q  ; малиновый
pic3            equ 377q  ; блѣ

colors0:        .ds 16

colors_buf:     .ds 16
                
colors_main:
                .db floor0, pic2, pic3, pic1
                .db floor1, pic2, pic3, pic1
                .db floor1, pic2, pic3, pic1
                .db floor0, pic2, pic3, pic1

persp_tab       db 0, 5, 8, 12, 15, 18, 21, 24, 26, 29, 31, 33, 36, 38, 40, 42, 43, 45, 47, 48, 50, 51, 53, 54, 55, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 72, 73, 74, 75, 75, 76, 77, 77, 78, 78, 79, 80, 80, 81, 81, 82, 82, 83, 83, 84, 84, 85, 85, 86, 86, 87, 87, 87, 88, 88, 89, 89, 89, 90, 90, 90, 91, 91, 91, 92, 92, 92, 93, 93, 93, 94, 94, 94, 94, 95, 95, 95, 95, 96, 96, 96, 96, 97, 97, 97, 97, 98, 98, 98, 98, 99, 99, 99, 99, 99, 100, 100, 100, 100, 100, 101, 101, 101, 101, 101, 101, 102, 102, 102, 102, 102, 102, 103, 103, 103, 103, 103, 103, 104, 104, 104, 104, 104, 104, 104, 105, 105, 105, 105, 105, 105, 105, 105, 106, 106, 106, 106, 106, 106, 106, 106, 106, 107, 107, 107, 107, 107, 107, 107, 107, 107, 108, 108, 108, 108, 108, 108, 108, 108, 108, 108, 109, 109, 109, 109, 109, 109, 109, 109, 109, 109, 109, 110, 110, 110, 110, 110, 110, 110, 110, 110, 110, 110, 110, 110, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 113, 114, 114, 114, 114, 114, 114

; une planète, un système
.include arzak.inc

; HARZAKC
.include harzakc.inc


msgseq_ctr     .db 0

msgseq_init
                lxi h, MESSAGES_XY
                call gotoxy
                lxi h, msg0
                mov a, m
                sta msgseq_ctr
                inx h
                shld _puts_sptr
                ret

msgseq_frame    
                lda framecnt
                mov b, a
                ani $3
                rnz
                lda msgseq_ctr
                ora a
                jz msgseq_L1
                ; continue skipping until delay runs out
                dcr a
                sta msgseq_ctr
                ret

msgseq_L1:      
                lhld _puts_sptr
                mov a, m
                ora a
                jz msgseq_L2
                cpi ' '
                jz msgseq_L2
                mvi a, 4
                ana b
                mvi c, 7;'_'
                lhld _puts_de
                xchg
                jz _putchar_c
msgseq_L2:
                call _putchar
                rnz
                lhld _puts_sptr
                inx h
                mov a, m ; next delay, 0 = restart
                ora a
                jz msgseq_init
                sta msgseq_ctr
                inx h
                shld _puts_sptr
                lxi h, MESSAGES_XY
                call gotoxy
                ret

               
              

                  
                ;          12345678901234567890123456789012

msg0            ;.db 1, $d4, 0
                ;.db 1, 'M', 20, 'BIUS  MOEBIUS', 0
                ;.db 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
                ;.db    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 0
                .db 80,   '      ARZAK EST UN MONDE ...    ', 0
                .db 10,   '    UNE PLAN',$8a,'TE, UN SYSt', $8a, 'ME     ', 0
                .db 20,   " MAIS C'EST AUSSI ET SURTOUT... ", 0
                .db 10,   '            UN HOMME            ', 0
                .db 1,    '                              ', 13, '   ', 0
                .db 1,    'SCALESMAN^MC MELODY IN THE AIR', 0
                .db 15,   '                                ', 0
                .db 5,    '        ARZACH BY M',20,'BIUS       ', 0
                .db 15,   '                                ', 0
                .db 80,  ' A VECTOR-06C DEMO BY SVO',1,' 2022  ', 0
                .db 50,   '                                ', 0
                .db 0

.include font8x8.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GIGACHAD ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; songe
song_1:         dw songA_00, songA_01, songA_02, songA_03, songA_04, songA_05, songA_06
                dw songA_07, songA_08, songA_09, songA_10, songA_11, songA_12, songA_13            
.include scalesman_air25.inc

.include gigachad16.inc

texture_premasked     equ gigachad_end
texture_premasked_end equ texture_premasked + 256 * 6 * 4 ; 6 lines, 4 shifts

;              .org 0x100 + . & 0xff00  ; ALIGN 256
scroll_rail           equ texture_premasked_end;.ds 256*8
scroll_rail_end       equ scroll_rail + 256 * 8


