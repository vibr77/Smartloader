BELL            EQU     $FF3A     
PREAD           EQU     $FB1E
CLRSCR          EQU     $FC58

COUT            EQU     $FDED               ; Apple II character out func.
COUTD           EQU     $FDE2
COUT1           EQU     $FDF0

CURPOS          EQU     $FB5B
BASCLC          EQU     $FBC1               ; subroutine to position cursor

BASL            EQU     $28
BASH            EQU     $29
CV              EQU     $25                 ; Cursor position
CH              EQU     $24    

zpDispMask      EQU    $32                  ; INVERTED 0x7F NORMAL 0xFF

zpPtr1          EQU    $80                  ; 80/81 2 Bytes Addr ptr for DisplayMsg on Screen 
zpPtr2          EQU    $83 

dispPositionCursor
    pha                                     ; push regA to stack
    tya     
    stx     CH
    jsr     CURPOS
    pla                                     ; pull regA from the stack
    rts

dispLine
    lda     #$DF
    jsr     COUT
    dey
    bne dispLine
    rts

str2UpperCase
    pha
    sbc     #$E0
    bcs     str2UpperCase_1
    pla
    rts
str2UpperCase_1
    pla
    and     #$DF
    rts

printMsg
    stx     zpPtr1
    sty     zpPtr1+1
    ldy     #0
    lda     (zpPtr1),Y
    beq     printMsg_1
printMsg_0
    jsr     str2UpperCase
    jsr     COUT1                           ; Char disp routine
    iny                                     ; increase char position
    lda     (zpPtr1),Y                      ; indirect zeropage addressing pointing to current char
    bne     printMsg_0                      ; no need of cmp 00 is current char is not 00 then loo
printMsg_1
    rts   