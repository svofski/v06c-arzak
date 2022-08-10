    ; установить позицию для вывода следующего символа
    ; H = столбец, L = строка ($F8 = верхняя)
gotoxy
    shld _puts_de
    ret

    ; Вывести 0-терминированую строку в HL на экран
puts
    shld _puts_sptr
_puts_1:
    call _putchar
    jnz _puts_1
    ret

_puts_sptr:dw 0
_puts_de: dw 0

    ; Нарисовать один символ
_putchar:
    lhld _puts_sptr
    mov a, m
    ora a
    rz
    mov c, a
    inx h
    shld _puts_sptr
    xchg
    lhld _puts_de
    inr h
    shld _puts_de
    dcr h
    xchg
_putchar_c:
    lxi h,0
    dad sp
    shld _pch_sp+1

    ; Найти адрес спрайта символа
    ; bc = (c-32)*8
    mov a,c
    ;sui 32
    ;mov c, a
    rlc
    rlc
    rlc
    ani 7
    mov b,a
    mov a,c
    rlc
    rlc
    rlc
    ani $f8
    mov c,a
    lxi h, _font_table
    dad b
    sphl        ; sp -> char

    lxi h, $c000
    dad d        ; hl -> destination

    ; Выдавить биты на экран
    pop b\ mov m, c\ dcr l\ mov m, b\ dcr l
    pop b\ mov m, c\ dcr l\ mov m, b\ dcr l
    pop b\ mov m, c\ dcr l\ mov m, b\ dcr l
    pop b\ mov m, c\ dcr l\ mov m, b\ dcr l

_pch_sp:
    lxi sp, 0
    ret

_font_table:
    .include readable.inc
