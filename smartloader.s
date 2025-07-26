    DSK PRG.SYSTEM
    TYP BIN
    mx  %11

DEBUG   =   0

            org       $2000
            xc
            xc

; DSK PRG.SYSTEM
;cadius  DELETEFILE blank.po BASIC.SYSTEM

;DSK PRG.BIN
;cadius  ADDFILE blank.po blank BASIC.SYSTEM
;cp2 sa blank.po type=0xFF,aux=0x2000 BASIC.SYSTEM

; Image item length is 24
; Image first Char is type 1=> Directory 0=> Normal Image
; Byte 1: Command Byte 2: Value
;    0x01 Process Directory item, Value: ID of the Item 
;    0x02 Process Image item :
;     0x03 Value 0x0 Refresh same Page, Value 0xFE Previous Page, Value 0x01 Next Page,

; Result 
;    Byte 0  : status code
;    Byte 1  : Item count in the page
;    Byte 2  : Current Page
;    Byte 3  : Max Page
;    Byte 4  : Current Directory 23 Byte
;    Bytes 27 : 0x0

BELL            EQU     $FF3A     
PREAD           EQU     $FB1E
CLRSCR          EQU     $FC58
COUT            EQU     $FDED               ; Apple II character out func.
COUTD           EQU     $FDE2
COUT1           EQU     $FDF0
CTR             EQU     $08
PTR             EQU     $06

CURPOS          EQU     $FB5B
BASCLC          EQU     $FBC1               ; subroutine to position cursor

BASL            EQU     $28
BASH            EQU     $29
CV              EQU     $25                 ; Cursor position
CH              EQU     $24                 

WAIT            EQU     $FCA8

CMD_BLK         EQU     $2600               ; Command Block
RES_BLK         EQU     $2800               ; Result  Block

MLI             EQU     $BF00               ; ProDOS system call
CROUT           EQU     $FD8E               ; Print Carriage return 
PRBYTE          EQU     $FDDA               ; Print Hex Byte
IORTS           EQU     $FF58
myZP            EQU     $02


cstMaxImgLen    EQU    #$10                 ; Constant Max Image Filename len
cstLineOffset   EQU    #$03
cstMaxItemPPage EQU    #$10                 ; 16 item per page 

zpImgIndx       EQU    $85                  ; Current ImageIndex
zpPrevImgIndx   EQU    $86
zpMaxImgIndx    EQU    $87

zpPageIndx      EQU    $88 
zpMaxPageIndx   EQU    $89

zpDispMask      EQU    $32                  ; INVERTED 0x7F NORMAL 0xFF

zpPtr1          EQU    $80                  ; 80/81 2 Bytes Addr ptr for DisplayMsg on Screen 
zpPtr2          EQU    $83 

diskSlot        EQU    $70

LOC0            EQU    $00
LOC1            EQU    $01

start       

    ;----------------------------------------------
    ; Clear Screen
    ;----------------------------------------------
    
    jsr     CLRSCR
    
 
    ;---------------------------------------------
    ;   VAR INIT
    ;---------------------------------------------
    
    ldx     #$00
    
    stx     zpImgIndx
    stx     zpPrevImgIndx
    stx     zpMaxImgIndx

    stx     zpPageIndx
    stx     zpMaxPageIndx




    ldx     #$0
    stx     calc_1_high
    stx     calc_2_high
    ldx     #$31
    stx     calc_1_low
    ldx     #$03
    stx     calc_2_low
    jsr     div_16B_16B

    ;jsr     getDriveSlot
    ;lda     #$09
    ;sta     CURTRK
    ;lda     #$08
    ;sta     DESTRK
    ;jsr     armmove

    ;---------------------------------------------
    ;   MAIN SCREEN MASK INIT
    ;---------------------------------------------

start_0

    ldx     #$0F
    ldy     #$00    
    jsr     dispPositionCursor

    ldx     #$FF                                        ; Normal charset
    stx     zpDispMask                                  ; store to zeropage       
    
    ldx     #<_title
    ldy     #>_title
    jsr     printMsg

    ldx     #$22
    ldy     #$17    
    jsr     dispPositionCursor

    ldx     #<_version
    ldy     #>_version
    jsr     printMsg

    ldx     #$00
    ldy     #$01    
    jsr     dispPositionCursor

    ldy     #$28
    jsr     dispLine

    ldx     #$00
    ldy     #$14    
    jsr     dispPositionCursor
    
    ldy     #$28
    jsr     dispLine

    ldx     #$00
    ldy     #$16    
    jsr     dispPositionCursor

    lda     #"D"                            ; display DIR:/
    jsr     COUT1
     lda     #"I"
    jsr     COUT1
     lda     #"R"
    jsr     COUT1
    lda     #":"
    jsr     COUT1
    lda     #"/"
    jsr     COUT1

    ldx     #$0
    ldy     #$17    
    jsr     dispPositionCursor

    ldx     #<_option
    ldy     #>_option
    jsr     printMsg

    ;---------------------------------------------
    ;   MAIN SCREEN DATA REQUEST
    ;---------------------------------------------

    ldx #$00                                ; the first write command is not working...
    ldy #$00                                ; so issue a fake request
    jsr setCommand                          ; this should be fine 


refresh            
    jsr     readBlock

    ;----------------------------------------------
    ; MOVE THE HEAD
    ;----------------------------------------------
    jsr     getDriveSlot
    
    lda     #$16                            ; Move the head so in case of Reading error the SmartDisk will recompute the reading content of the sdcard
    sta     CURTRK
    lda     #$17
    sta     DESTRK
    jsr     armmove

    lda     RES_BLK
    cmp     #$20
    bne     refresh_0                       ; Error to be diplayed

    lda     RES_BLK+1                  
    sta     zpMaxImgIndx 

    lda     RES_BLK+2
    sta     zpPageIndx

    lda     RES_BLK+3
    sta     zpMaxPageIndx

    jsr     dispDataBlock

    ldx     #$04                            ; Display Current Dir
    ldy     #$16    
    jsr     dispPositionCursor

    ldx     #$04                            ; Data start at index 4 of RES_BLK
    ldy     #>RES_BLK
    jsr     printMsg
    
    ldx     #$00                            ; init imgaIndex
    stx     zpImgIndx                       ; store to zeropage
    
    ldx     #$7F                            ; add Inverse Mask
    stx     zpDispMask                      ; store to zeropage
    
    jsr     dispDataBlockImage              ; disp current selection
    jsr     mainDispatch
    
    jsr start

refresh_0
    jsr     dispErrorMsg
    rts


getDriveSlot
    ldx     #$00
    stx     diskSlot                ;Init DiskSlot to 0
    lda     #$c8                    ;load hi slot +1
	stx     LOC0                    ;SETPG3 must return X=0
	sta     LOC1                    ;set ptr H
getDriveSlot_1       
	ldy     #$07                    ;Y is byte ptr
	dec     LOC1
	lda     LOC1
	cmp     #$c0                    ;at last slot yet?
	beq     getDriveSlot_3          ;yes and it cant be a disk
	sta     diskSlot                ;Store the current DriveSlot
getDriveSlot_2      
	lda     (LOC0),y                ;fetch a slot byte
	cmp     DISKID-1,y              ;is it a disk ??
	bne     getDriveSlot_1          ;no so next slot down
	dey
	dey                             ;yes so check next byte
	bpl     getDriveSlot_2          ;until 4 checked
getDriveSlot_3
	rts

;   @Funct: setCommand
;   @Param: X Command, Y Value


setCommand       
    lda     #<CMD_BLK                           ; Storing CMD_BLK address to zpPtr1
    sta     zpPtr1
    
    lda     #>CMD_BLK
    sta     zpPtr1+1

    txa                                         ; Command: X -> Byte0 of CMD_BLK 
    sta     CMD_BLK
    
    tya
    sta     CMD_BLK+1                           ; Value: Y -> Byte1 of CMD_BLK 

    lda     #$00                                ; A -> 00 to wipe remaining block data
    ldy     #$01                                ; start at offset 1, it will be incremented so Byte 2

setCommand_0                                    ; Wipe the content of CMD_BLK 2x256 Bytes
    iny
    sta     (zpPtr1),Y
    cpy     #$FF
    bne     setCommand_0
    
    ldy     #<CMD_BLK
    sty     zpPtr1

    ldy     #>CMD_BLK
    iny
    sty     zpPtr1+1
    
    ldy     #$00
    lda     #$00

setCommand_1                                    ; write 00 to clean up the 2nd 256 Bytes
    sta (zpPtr1),Y
    cpy     #$FF
    iny
    bne     setCommand_1

setCommand_2      
    jsr     MLI                                 ; CALL PRODOS WRITE_BLOCK 
    dfb     $81
    dfb     #<paramBLK_WR
    dfb     #>paramBLK_WR
    jsr     dispCommandProdosReturnCode
    rts

dispLine
    lda     #$DF
    jsr     COUT
    dey
    bne dispLine
    rts

dispDataBlock
    lda     #$00
    sta     zpImgIndx
    ldx     #$FF
    stx     zpDispMask

dispDataBlock_1
    jsr dispClearLineImage
    jsr dispDataBlockImage

dispDataBlock_2
    inc zpImgIndx 
    lda zpImgIndx
    
    sbc zpMaxImgIndx
    bcc dispDataBlock_1

    ;jsr dispClearLineImage
    ;jsr dispDataBlockImage
    rts

;Display the name of the image on screen
;zpImgIndx contain the index
;zpDispMask  contains the display mode #FF normal, #3F inverted
getImageAddr      
    ldx     #$18                        ; #18 -> 24 !!!
    stx     calc_1_low
    sta     calc_2_low
    
    jsr     mult_8B_8B

    ldx     calc_result_high
    stx     calc_2_high

    ldx     calc_result_low
    stx     calc_2_low

    ;ldx     #<RES_BLK
    ldx     #$20                                ; we start at 0x2820 and not 0x2800 to keep 32 bytes of data
    stx     calc_1_low

    ldx     #>RES_BLK
    stx     calc_1_high

    jsr     add_16B_16B

    ldx     calc_result_low
    stx     zpPtr2

    ldx     calc_result_high
    stx     zpPtr2+1
    rts

dispErrorMsg
    ldx     #$0F
    ldy     #$00    
    jsr     dispPositionCursor

    ldx     #$FF                            ; add Inverse Mask
    stx     zpDispMask                      ; store to zeropage       
    
    ldx     #<error_10
    ldy     #>error_10

    jsr     printMsg
    jsr     readKey
    rts
            

dispClearLineImage
    lda     zpImgIndx
    adc     cstLineOffset                   ; position Cursor with line Offset
    tay 
    ldx     #$0
    jsr     dispPositionCursor
    lda     #$A0                            ; space
    ldy     #$00

dispClearLineImage_0
    jsr     COUT
    iny     
    cpy     #$13
    bne     dispClearLineImage_0
    rts

dispImageAttr
    ldy     #$00
    lda     (zpPtr2),Y
    cmp     #$01
    bne     dispImageAttr_0
    ;lda     #$BC                            ; "<"
    ;jsr     COUT1                            ; print
    lda     #$C4                            ; "D"
    jsr     COUT1                            ; print
    ;lda     #$BE                            ; ">"
    ;jsr     COUT1                            ; print
    lda     #$A0                            ; "SPC"
    jsr     COUT1                            ; print
    rts

dispImageAttr_0
    ;lda     #$A0                            ; "SPC"
    ;jsr     COUT1                            ; print
    ;lda     #$A0                            ; "SPC"
    ;jsr     COUT1                            ; print
    lda     #$AD                            ; "SPC"
    jsr     COUT1                            ; print
    lda     #$A0                            ; "SPC"
    jsr     COUT1                            ; print

    rts

dispDataBlockImage
    
    lda     zpImgIndx
    jsr     getImageAddr
    
    lda     zpImgIndx
    
    adc     cstLineOffset                   ; position Cursor with line Offset
    tay 
    ldx     #$0
    jsr     dispPositionCursor

    ;lda     zpImgIndx
    ;jsr     printInt8

    ;lda     #$A0                            ; "SPC"
    ;jsr     COUT1                            ; print

    jsr     dispImageAttr

    ldy     #$01                              ; we start at 1 instead of 0 cause first char indicate type of file
    lda     (zpPtr2),Y
            

dispDataBlockImage_1
    jsr     str2UpperCase                            ; shift to uppercase
    jsr     COUT1
    iny
    lda     (zpPtr2),Y                      ; indirect zeropage addressing pointing to current char
    bne     dispDataBlockImage_1
    lda     #$A0                            ; SPACE

dispDataBlockImage_2
    iny
    jsr     COUT1
    pha
    tya
    sbc     #$18
    pla
    ;cpy     #$18
    bcc     dispDataBlockImage_2
    rts

; Main process flow
; Reading from the keyboard

pNextPage
    
    ; we need to do a bit of computation
    ; currentpage * 16 + 16 > Maxitem ?
    ; if yes index zpPageIndex
    ; if not go to zpPageIndex = 0 
    
    ldx zpPageIndx
    cpx zpMaxPageIndx
    beq pNextPage_1
    
    lda     zpPageIndx
    sbc     zpMaxImgIndx
    bcc     pNextPage_0        ;   the result is negative
    
    inc     zpPageIndx
    ldx     #$11
    ldy     zpPageIndx
    jsr     setCommand
    jsr     start
    
    rts
pNextPage_0                     ; we are reaching the max number of page, looping to 0
    ldx     #$11
    ldy     #$00
    sty     zpPageIndx
    
    jsr     setCommand
    jsr     start
pNextPage_1
    jmp mainDispatch
    
pPreviousPage

    ldx zpPageIndx
    beq pPreviousPage_0
    dec zpPageIndx
    rts

pPreviousPage_0                 
                                           
    ldx zpPageIndx
    cpx zpMaxPageIndx
    bne pPreviousPage_1

    ldx #$11
    ldy zpMaxPageIndx
    jsr setCommand
    jsr start

pPreviousPage_1
    jmp mainDispatch

pKeyUp
    
    ldx     #$FF                            ; Change the current Image back to normal text
    stx     zpDispMask
    jsr     dispDataBlockImage

    ldx     zpImgIndx
    cpx     #00                             ; if current Index is 0 then roll to the end
    bne     pKeyUp_0
    
    ldx     zpMaxImgIndx                    ; zpImgIndx =7 rolling to 0
    dex
    stx     zpImgIndx
    jmp     mainDispatch_2

pKeyUp_0
    jsr     decImageIndex                   ; decrement current Index
    jmp     mainDispatch_2

pKeydown
    lda     zpImgIndx
    
    ldx     #$FF
    stx     zpDispMask
    jsr     dispDataBlockImage
    ldx     zpImgIndx
    inx
    cpx     zpMaxImgIndx                    ; TODO put this automatic from the stack
    bne     pKeydown_0

    ldx     #$0                             ; zpImgIndx =7 rolling to 0
    stx     zpImgIndx
    jmp     mainDispatch_2

pKeydown_0
    jsr     incImageIndex
    jmp     mainDispatch_2

pSelectItem

    jsr     CLRSCR

    ldx     #$05
    ldy     #$09    
    jsr     dispPositionCursor
    
    ldx     #$FF
    stx     zpDispMask

    lda     zpImgIndx
    jsr     getImageAddr                        ; get the selected item address in the read data block 

    ldx     zpPtr2                              ; zpPtr2 contains the address of the image address
    inx                                         ; the first char is the type of the item will not display it     
    ldy     zpPtr2+1

    jsr     printMsg

    ldy     #$00
    lda     (zpPtr2),y                            ; A contains the type selected item

    cmp     #$01                                ; it is a directory    
    beq     pSelectItem_setCommandDirectory

    cmp     #$00                                ; it is a file
    beq     pSelectItem_setCommandFile

pSelectItem_setCommandDirectory
    ldx     #$10
    ldy     zpImgIndx
    jsr     setCommand
    jsr     start

pSelectItem_setCommandFile
    ldx     #$02
    ldy     zpImgIndx
    jsr     setCommand

    jsr     readBlock
    lda     RES_BLK
    cmp     #$22
    bne     pSelectItem_setCommandFile_err
    jmp     #$C600                                    ; TODO put this variable according to the slot
    rts

pSelectItem_setCommandFile_err       
    jsr dispErrorMsg
    jsr readKey
    jmp start

mainDispatch_selectItem
    jmp     pSelectItem

mainDispatch_reboot
    jmp     reboot

mainDispatch_refresh
    jmp     refresh

mainDispatch_nextPage
    jmp     pNextPage

mainDispatch_previousPage
    jmp     pPreviousPage

mainDispatch_keyDown
    jmp     pKeydown

mainDispatch_keyUp
    jmp     pKeyUp

mainDispatch
    jsr     readKey
    jsr     mainDispatch_disp
    
    cmp     #$D2                            ; KEY [R]
    beq     mainDispatch_refresh

    cmp     #$C2                            ; KEY [R]
    beq     mainDispatch_reboot

    cmp     #$95
    beq     mainDispatch_nextPage           ; KEY right arrow

    cmp     #$88
    beq     mainDispatch_previousPage       ; KEY left arrow

    cmp     #$8D                            ; KEY [ENTER] / [RETURN] 
    beq     mainDispatch_selectItem            
    
    cmp     #$8B                            ; KEY [UP]
    beq     mainDispatch_keyUp
    
    cmp     #$8A
    beq     mainDispatch_keyDown
    
    jmp     mainDispatch

mainDispatch_disp                                           ; Putting A containing the key value on the stack 
    pha
    ldy     #$00                            ; Display the Key value on the top right of the screen
    ldx     #$06
    jsr     dispPositionCursor
    
    ldx     #$FF                            ; add Inverse Mask    
    stx     zpDispMask   

    jsr     PRBYTE
    
    ldx     #$7F                            ; add Inverse Mask
    stx     zpDispMask   

    lda     zpImgIndx
    sta     zpPrevImgIndx
    pla
    rts
            
    ;lda     zpImgIndx
    ;sbc     #$09
    ;bpl     mainDispatch_3                 

mainDispatch_2
    ldy     #$0
    ldx     #$22
    jsr     dispPositionCursor

    lda     zpImgIndx
    jsr     printInt8

    lda     #"/"                            ; "/"
    jsr     COUT
    
    lda     zpMaxImgIndx
    tax
    dex
    txa  
    jsr     printInt8
    
    ldy     #$0
    ldx     #$1B
    jsr     dispPositionCursor

    lda     #"P"
    jsr     COUT

    lda     zpPageIndx
    jsr     printInt8_NoPad

    lda     #"/"
    jsr     COUT

    lda     zpMaxPageIndx
    jsr     printInt8_NoPad
    
    ldx     #$3F
    stx     zpDispMask
    jsr     dispDataBlockImage
    jmp     mainDispatch

;--------------------------------------------------------
; Value is in A
; printInt8_NoPad does not print dizaine number if 0
; printInt8_SpcPad print " " if dizaine equal 0
; printInt8 print double digit number
;---------------------------------------------------------
printInt8_NoPad
    jsr     hex2dec
    pha
    tya
    beq     printInt8_1  
    ora     #"0"
    jsr     COUT1
    jmp     printInt8_1
    
printInt8_SpcPad                           ; value in A
    jsr     hex2dec
    pha
    tya
    beq     printInt8_SPC  
    ora     #"0"
    jsr     COUT1
    jmp     printInt8_1

printInt8                       ; value in A
    jsr     hex2dec
    pha
    tya  
    ora     #"0"
    jsr     COUT1
    jmp     printInt8_1

printInt8_SPC
    lda  #" "
    jsr  COUT1

printInt8_1
    pla
    ora     #"0"
    jsr     COUT1

    rts

incImageIndex
    ldx     zpImgIndx
    cpx     #$255
    beq     incImageIndex_0
    inx
    stx     zpImgIndx

incImageIndex_0
    rts
            
decImageIndex
    ldx     zpImgIndx
    cpx     #$0
    beq     decImageIndex_0
    dex                                 
    stx     zpImgIndx

decImageIndex_0
    rts
            
dispPositionCursor
    pha                                     ; push regA to stack
    tya     
    stx     CH
    jsr     CURPOS
    pla                                     ; pull regA from the stack
    rts

printMsg
    stx     zpPtr1
    sty     zpPtr1+1
    ldy     #0
    lda     (zpPtr1),Y
    beq     printMsg_1
    jsr     str2UpperCase

printMsg_0
    ;and     zpDispMask
    jsr     COUT1                           ; Char disp routine
    iny                                     ; increase char position
    lda     (zpPtr1),Y                      ; indirect zeropage addressing pointing to current char
    jsr     str2UpperCase
    bne     printMsg_0                      ; no need of cmp 00 is current char is not 00 then loo
printMsg_1
    rts     

checkDriveSlot
    lda    $CFFF                            ; reset all other I/O Select spaces
    jsr    IORTS                            ; call my own c800 space
    tsx
    lda    $100,x
    sta    myZP+1
    ASL    A 
    ASL    A 
    ASL    A 
    ASL    A 
    TAX
    STX    myZP

    jsr    readKey
    rts

dispCommandProdosReturnCode    
    pha
    ldy     #$00                            ; Display the Key value on the top right of the screen
    ldx     #$0
    jsr     dispPositionCursor
    
    lda     #$C5                            ; "E"
    jsr     COUT

    pla
    jsr     PRBYTE    ;Print error code
    ;jsr     BELL      ;Ring the bell
    rts

readBlock
    LDA     #<RES_BLK
    STA     zpPtr1
    LDA     #>RES_BLK
    STA     zpPtr1+1
    LDA     #$00
    LDY     #$0

readBlock_01          
    STA     (zpPtr1),Y
    INY
    cpy     #$FF
    bne     readBlock_01

readBlock_02
    JSR     MLI
    DFB     $80
    DFB     #<paramBLK_RD
    DFB     #>paramBLK_RD

    jsr     dispCommandProdosReturnCode
    rts

readKey
    LDA     $C000               ; Wait until a key is pressed
    BPL     readKey
    BIT     $C010
    rts    

reboot
    jmp     #$C600
    rts

_title       
    ASC     "SMARTLOADER"
    dfb     $00
_version
    ASC     "v0.34"
    dfb     $00
    
_option 
            ASC     "[R]EFRESH [B]OOT [S]ETTINGS"
            dfb     $00

error_10
            ASC     "ERR 10 UNABLE TO GET DATA"
            dfb     $00

DISKID      dfb   $20,$ff,$00,$ff,$03,$ff,$3c

paramBLK_RD
    DFB      $03                    ; paramcnt =3
    DFB      $60                    ; slot number
    DFB      #<RES_BLK
    DFB      #>RES_BLK
    DFB      $B0
    DFB      $00

paramBLK_WR
    DFB      $03                    ; paramcnt =3
    DFB      $60                    ; slot number
    DFB      #<CMD_BLK
    DFB      #>CMD_BLK
    DFB      $A8                    ; 1st Block on track 23 0x17 Physical sector 0 & 2, Warning has to be on a different track than RD block
    DFB      $00

; Merlin32 include
    PUT     print_uint16_with_sp.s
    PUT     vibr_lib.s
    PUT     armmove.s


	