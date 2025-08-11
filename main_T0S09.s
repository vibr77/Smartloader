    DSK smartloader_s09.bin
    TYP BIN
    mx  %11

DEBUG   =   0

    org       $4000
    xc
    xc

BELL            EQU     $FF3A     
PREAD           EQU     $FB1E
CLRSCR          EQU     $FC58
COUT            EQU     $FDED               ; Apple II character out func.
COUTD           EQU     $FDE2
COUT1           EQU     $FDF0
CTR             EQU     $08
PTR             EQU     $06
PRBYTE          EQU     $FDDA

CURPOS          EQU     $FB5B
BASCLC          EQU     $FBC1               ; subroutine to position cursor

BASL            EQU     $28
BASH            EQU     $29
CV              EQU     $25                 ; Cursor position
CH              EQU     $24 
RWTS            EQU     $BD00

printMsg        EQU     $08D5
dispPositionCursor EQU  $08B8
str2UpperCase   EQU     $08CA                ; shift to uppercase



    ;----------------------------------------------
    ; Zero Page & CST definition
    ;----------------------------------------------

CMD_BLK         EQU     $2000               ; Command Block
RES_BLK         EQU     $2100               ; Result  Block
RES_BLK_P2      EQU     $2200               ; Result  Block

cstMaxImgLen    EQU    #$10                 ; Constant Max Image Filename len
cstLineOffset   EQU    #$04
cstMaxItemPPage EQU    #$10                 ; 16 item per page 

zpImgIndx       EQU    $85                  ; Current ImageIndex
zpPrevImgIndx   EQU    $86
zpMaxImgIndx    EQU    $87

zpPageIndx      EQU    $88 
zpMaxPageIndx   EQU    $89

zpDispMask      EQU    $32                  ; INVERTED 0x7F NORMAL 0xFF

zpPtr1          EQU    $80                  ; 80/81 2 Bytes Addr ptr for DisplayMsg on Screen 
zpPtr2          EQU    $83


    ;----------------------------------------------
    ; Init
    ;----------------------------------------------
init



init_value
            ldx     #$00
            
            stx     zpImgIndx
            stx     zpPrevImgIndx
            stx     zpMaxImgIndx

            stx     zpPageIndx
            stx     zpMaxPageIndx

init_disp

            ldx     #$00
            ldy     #$16    
            jsr     dispPositionCursor

            ldx     #<_path
            ldy     #>_path
            jsr     printMsg

            ldx     #$0
            ldy     #$17    
            jsr     dispPositionCursor

            ldx     #<_option
            ldy     #>_option
            jsr     printMsg


refresh
            ;jmp     testR
            jsr     readDataBlock
            jsr     dispRWTSReturnCode

            lda     RES_BLK                           ; First Bytes of RES_BLK indicate the return status code
            cmp     #$20                              ; If not 20 then raise an error
            bne     refresh_err                       ; Error to be diplayed

            lda     RES_BLK+1                         ; init zeroPage values
            sta     zpMaxImgIndx 

            lda     RES_BLK+2
            sta     zpPageIndx

            lda     RES_BLK+3
            sta     zpMaxPageIndx

refresh_0                                             ; Display all image on screen
            jsr     dispDataBlockImage                ; Display 1 line
            inc     zpImgIndx
            lda     zpImgIndx
            cmp     zpMaxImgIndx
            bne     refresh_0                         ; if not the end of the page loop
            lda     #$0                 
            sta     zpImgIndx

refresh_1
            jsr     seekDrive
            jmp     mainDispatch
            


refresh_err
            lda     #<_error_10
            sta     zpPtr2
            lda     #>_error_10
            sta     zpPtr2+1
            jsr     dispErrorMessage                   ;
            jmp     refresh



;-----------------------------------------------------------------------------
; Routine: dispErrorMessage                                       
; Description: display an error message on the screen and wait for keypress
; Input: zpPtr2 pointing to the right error message
; output: nothing  
;-----------------------------------------------------------------------------

dispErrorMessage                   
        jsr     dispClearCenterBlock                ; Start clearing the central block

        ldx     #$08
        ldy     #$08    
        jsr     dispPositionCursor

        ldx     #<_error
        ldy     #>_error
        jsr     printMsg

        ldx     #$08
        ldy     #$0A  
        jsr     dispPositionCursor
       
        ldx     zpPtr2
        ldy     zpPtr2+1  
        jsr     printMsg
       
        ldx     #$08
        ldy     #$0D    
        jsr     dispPositionCursor
        
        ldx     #<_pressanykey
        ldy     #>_pressanykey
        jsr     printMsg

        jsr readKey                                 ; wait for keypress
        rts                                         ; return to caller


dispRWTSReturnCode    
    pha
    ldy     #$0                            ; Display the Key value on the top right of the screen
    ldx     #$0
    jsr     dispPositionCursor
    
    lda     #$C5                            ; "E"
    jsr     COUT
    lda     ioRet
    jsr     PRBYTE    ;Print error code
    
    pla

    rts

;-----------------------------------------------------------------------------
; Routine: dispClearCenterBlock                                       
; Description: Clear out the center of the screen (list of image)
; Input: nothing
; output: nothing  
;-----------------------------------------------------------------------------
dispClearCenterBlock                                        
        ldx     #$FF
        stx     zpDispMask
        lda     #$0
dispClearCenterBlock_0
        jsr     dispClearLineImage
        tax
        inx
        txa
        cmp     #$0f
        bne     dispClearCenterBlock_0
        rts

dispDataBlock
        lda     #$00
        sta     zpImgIndx
        ldx     #$FF
        stx     zpDispMask

dispDataBlock_1
        lda zpImgIndx
        jsr dispClearLineImage
        jsr dispDataBlockImage

dispDataBlock_2
        inc zpImgIndx 
        lda zpImgIndx
        
        sbc zpMaxImgIndx
        bcc dispDataBlock_1
        rts

;-----------------------------------------------------------------------------
; Routine: dispClearLineImage
; Description: Clear out one line of text with an line offset of cstLineOffset
; Input: A with the line number
; output: nothing  
;-----------------------------------------------------------------------------

dispClearLineImage
    pha                                     ; push A on stack
    clc                                     ; clear the carry before doing adds    
    adc     cstLineOffset                   ; Add line offset constant
    tay                                     ; prepare X & Y for dispPositionCursor
    ldx     #$0
    jsr     dispPositionCursor
    lda     #$A0                            ; space
    ldx     #$00                            ; Position 0 

dispClearLineImage_0
    jsr     COUT                            ; Print space (contained in A)
    inx                                     ; increment X
    cpx     #$22                            ; 22-> 34 
    bne     dispClearLineImage_0            ; Not equal we clear out the line
    pla                                     ; restore A from stack
    rts                                     ; return to caller

dispImageAttr
    ldy     #$00
    lda     (zpPtr2),Y
    cmp     #$01
    bne     dispImageAttr_0

    lda     #$C4                            ; "D"
    jsr     COUT1                            ; print
 
    lda     #$A0                            ; "SPC"
    jsr     COUT1                            ; print
    rts

dispImageAttr_0

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
    jsr     dispImageAttr

    ldy     #$01                              ; we start at 1 instead of 0 cause first char indicate type of file
    lda     (zpPtr2),Y
            

dispDataBlockImage_1
    jsr     str2UpperCase                   ; shift to uppercase
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

    bcc     dispDataBlockImage_2
    rts


getImgPageIndx
    lda     zpPageIndx                                  ; Take the current page index
    sta     calc_1_low      

    lda     #$10                                        ; 0x10 -> 16
    sta     calc_2_low

    jsr     mult_8B_8B                                  ; Multiply current page index by 16
    ldx     calc_result_low
    stx     calc_1_low

    ldx     zpImgIndx                                   ; 
    stx     calc_2_low

    ldx     #$00
    stx     calc_2_high
    stx     calc_1_high

    jsr     add_16B_16B                                 ; Add the current image index to the result of multiply
    lda     calc_result_low
    
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
        jsr    writeDataBlock
        
        ;jsr     dispCommandProdosReturnCode
        rts

pNextPage
    ldx zpPageIndx                              
    cpx zpMaxPageIndx
    beq pNextPage_0                                     ; check if current page is the last page
      
    inc     zpPageIndx
    ldx     #$11                                        ; Command 0x11 is to change currentPath page Index
    ldy     zpPageIndx
    jsr     setCommand
    
    jmp     refresh
    
pNextPage_0
    ldx     zpPageIndx 
    beq     pNextPage_1                                 ; current Page Index == MaxPage Index, check if current Index ==0 then do nothing
    
    ldx     #$11                                        ; otherwise let loop to index 0 and send the command
    ldy     #$00                                        ; Command 0x11 is to change currentPath page Index
    sty     zpPageIndx
    jsr     setCommand
    
    jmp     refresh                                       ; send the Command and loop back to start

pNextPage_1
    jmp mainDispatch
    
pPreviousPage
    ldx zpPageIndx
    beq pPreviousPage_0                                 ; Current page Index is 0 so let loop MaxPageIndex 
    dec zpPageIndx                                      ; current page index is not 0 => decrease
    
    ldx #$11                                            ; Command 0x11 is to change currentPath page Index
    ldy zpPageIndx
    jsr setCommand                                      ; send the Command and loop back to start
    jmp refresh
    
pPreviousPage_0                                                      
    ldx zpPageIndx
    cpx zpMaxPageIndx
    beq pPreviousPage_1                                 ; Compage current page Index with MaxPageIndx
                                                        ; if both equal then do nothing otherwize move to last page Index (maxPageIndx)
    ldx #$11                                            ; Command 0x11 is to change currentPath page Index
    ldy zpMaxPageIndx
    jsr setCommand                                      ; send the Command and loop back to start
    jmp refresh

pPreviousPage_1
    jmp mainDispatch                                    ; loop back to mainDispatch

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
    ldx     #$FF
    stx     zpDispMask

    jsr     dispClearCenterBlock

    ldx     #$08
    ldy     #$08    
    jsr     dispPositionCursor

    ldx     #<_loading
    ldy     #>_loading
    jsr     printMsg

    ldx     #$08
    ldy     #$0A    
    jsr     dispPositionCursor
    
    jsr     getImgPageIndx
    jsr     printInt8

    lda     #" "
    jsr     COUT1

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
    
    jsr     getImgPageIndx
    tay     
    ldx     #$10
    jsr     setCommand
    
    jmp     refresh

pSelectItem_setCommandFile

    jsr     getImgPageIndx
    tay
    ldx     #$02
    jsr     setCommand
    
    ;Lets go Straight 
    ;jsr     wait
    jmp     #$C600                                    ; TODO put this variable according to the slot
    
pSelectItem_setCommandFile_err       
    ;jsr dispErrorMsg
    jsr readKey
    jmp refresh

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
    pha
    ora     #"0"
    jsr     COUT1
    pla
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

    ;----------------------------------------------
    ; Data Read / Write Routines
    ;----------------------------------------------

reboot
    jmp     #$C600
    rts

testR    
            ldx     #$0F
            ldy     #$0B    
            jsr     dispPositionCursor
            
            ldx     #<_title
            ldy     #>_title

            jsr     printMsg
            jsr     readDataBlock
            jsr     writeDataBlock
            jsr     seekDrive
            lda     #"$"
            jsr     COUT    

            jsr     readKey

            rts

readDataBlock
            
            lda     #$01                    ; 1 -> Read Command
            sta     ioCmd
            
            lda     #$02
            sta     ioTrack                 ; Track to read is 2
            
            lda     #$00
            sta     ioSector                ; First block of 256 Bytes is at sector 0

            lda     #>RES_BLK               ; set the data buffer to $2100 (high byte is only changed)
            sta     ioBuffer+1
            
            jsr     CALL_RWTS
            
            lda     #>RES_BLK_P2            ; 2nd Read data buffer is $2200, put a check on if it is need to do a 2nd read
            sta     #ioBuffer+1
            
            lda     #$01                    ; 2nd block of 256 Bytes is at sector 1
            sta     ioSector
            
            jsr     CALL_RWTS

            rts

writeDataBlock
            lda     #>CMD_BLK
            sta     ioBuffer+1
            lda     #$03
            sta     ioTrack
            lda     #$00
            sta     ioSector                ; Only block of 256 Bytes is at sector 0
            lda     #$02                            ; 2 -> Write Command
            sta     ioCmd
            jsr     CALL_RWTS

seekDrive
            lda     #$01
            sta     ioTrack
            lda     #$02                            ; 0 -> Seek Command
            sta     ioCmd
            jsr     CALL_RWTS
            rts     
CALL_RWTS
            ; RWTS is located at $3D00
            lda     #$00
            sta     $48
            ldy     #<iocb
            lda     #>iocb
            JSR     RWTS
            
            rts

readKey
            lda     $C000               ; Wait until a key is pressed
            bpl     readKey
            bit     $C010
            rts 

_loading    
            asc     "LOADING:"
            dfb     $00

_error  
            asc     "ERROR:"
            dfb     $00

_error_10
            asc     "10 UNABLE TO GET DISK LIST"
            dfb     $00


_pressanykey
            asc     "PRESS ANY <KEY> TO CONTINUE"
            dfb     $00

_path
            asc     "DIR:/"
            dfb     $00

_title       
            asc     "BOOTLOADER"
            dfb     $00

_option 
            ASC     "[R]EFRESH [B]OOT [S]ETTINGS"
            dfb     $00

iocb        dfb     $01                            ;
ioslot      dfb     $60                            ; Slot number ex:60
            dfb     $01                            ; Drive number $01 
ioVolume    dfb     $FE                            ; Volume track expected ($00 everything)
ioTrack     dfb     $02                            ; Track number 0x00 -> 0x22
ioSector    dfb     $00                            ; Sector number 0x00 -> 0x0F
ioDct       dfb     <dct,>dct                        ; DCT LOW HIGH
ioBuffer    dfb     $00,$00                        ; Buffer to read/write Low / High
            dfb     $00                            ; not used
ioByte      dfb     $01                            ; Byte Count $00 for 256
ioCmd       dfb     $01                            ; $OO -> SEEK, $01 -> READ, $02 -> WRITE, $04 -> FORMAT
ioRet       dfb     $00                            ; Return code
ioLast      dfb     $FE,$60,$01

dct 
            dfb     $00,$01,$EF,$D8

            put     vibr_lib.s

END        DFB      $00



