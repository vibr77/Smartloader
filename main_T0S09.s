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
WAIT            EQU     $FCA8

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
EMUL_TYPE       EQU     $2300
RES_BLK_P2      EQU     $2200               ; Result  Block

cstMaxImgLen    EQU    #$10                 ; Constant Max Image Filename len
cstLineOffset   EQU    #$04
cstMaxItemPPage EQU    #$10                 ; 16 item per page 

zpImgIndx       EQU    $85                  ; Current ImageIndex
zpPrevImgIndx   EQU    $86
zpMaxImgIndx    EQU    $87

zpPageIndx      EQU    $88 
zpMaxPageIndx   EQU    $89
zpScratch       EQU    $90


zpDispMask      EQU    $32                  ; INVERTED 0x7F NORMAL 0xFF

zpPtr1          EQU    $80                  ; 80/81 2 Bytes Addr ptr for DisplayMsg on Screen 
zpPtr2          EQU    $83


SPACEBAR         EQU    $20
KEYPOLL        EQU    $C000



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
            ;jsr     readKey
            ldx     #$0
            ldy     #$17    
            jsr     dispPositionCursor

            ldx     #<_option
            ldy     #>_option
            jsr     printMsg
            ;jmp     refresh

warmup
            jsr     dispClearCenterBlock
            jsr     readDataBlock
            jsr     dispRWTSReturnCode
            lda     RES_BLK                           ; First Bytes of RES_BLK indicate the return status code
          
            lda     RES_BLK+4
            sta     EMUL_TYPE

            jsr     seekDrive

            ;ldx     #$15
            ;jsr     setCommand
            ;jsr     readKey
            ;jmp     preboot
            ldx     #$08
            ldy     #$08    
            jsr     dispPositionCursor
            ldx     #<_pressanykey
            ldy     #>_pressanykey
            jsr     printMsg
            ldx     #$08
            ldy     #$09
            jsr     dispPositionCursor

            ldx     #$05
            ldy     #$FF
            sty     PTR
            sty     PTR+1
warmup_wait_1s
            dec     PTR 
            lda     PTR
            cmp     #$00
            bne     warmup_wait_1s
            dec     PTR+1
            lda     PTR+1
            cmp     #$00
            bne     warmup_wait_1s

            ldy     #$FF
            sty     PTR
            sty     PTR+1
            txa
            adc     #$AF
            jsr     COUT1
            dex
            
            lda     $C000
            and     #$80
            beq     warmup_wait_next
            jmp     refresh

warmup_wait_next 
            txa
            bne     warmup_wait_1s
            ldx     #$15
            jsr     setCommand
            
            jmp     prewait_1s


refresh

            jsr     dispClearCenterBlock
            jsr     readDataBlock
            jsr     dispRWTSReturnCode
            ;jsr     readKey
            lda     RES_BLK                           ; First Bytes of RES_BLK indicate the return status code
                                            ; transform to Apple charset
            
            cmp     #$20                              ; If not 20 then raise an error
            bne     refresh_err                       ; Error to be diplayed

            lda     RES_BLK+1                         ; init zeroPage values
            sta     zpMaxImgIndx 
            beq     refresh_err                      ; if zpMaxImgIndx eq 0 then we have a problem
            lda     RES_BLK+2
            sta     zpPageIndx

            lda     RES_BLK+3
            sta     zpMaxPageIndx

            lda     RES_BLK+4
            sta     EMUL_TYPE

            lda     #$0
            sta     zpImgIndx

            ldy     #$0
            ldx     #$22
            jsr     dispPositionCursor

            lda     #" "                            ; " "
            jsr     COUT
            lda     #" "                            ; " "
            jsr     COUT

            lda     #"/"                            ; "/"
            jsr     COUT
    
            lda     #" "                            ; " "
            jsr     COUT
            lda     #" "                            ; " "
            jsr     COUT
            lda     #" "                            ; " "
            jsr     COUT
           

            ldy     #$0
            ldx     #$1B
            jsr     dispPositionCursor

            lda     #"P"
            jsr     COUT

            lda     zpPageIndx
            jsr     j_printInt8_NoPad


            lda     #"/"
            jsr     COUT

            lda     zpMaxPageIndx
            jsr     j_printInt8_NoPad


            

refresh_0                                             ; Display all image on screen
            jsr     dispCurrentPath
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

j_printInt8_NoPad
            jmp printInt8_NoPad

 

;-----------------------------------------------------------------------------
; Routine: dispErrorMessage                                       
; Description: display an error message on the screen and wait for keypress
; Input: zpPtr2 pointing to the right error message
; output: nothing  
;-----------------------------------------------------------------------------

dispCurrentPath
        ldx     #$05                                ; First Char is 5
        ldy     #$16       
        jsr     dispPositionCursor
        
        ldx     #$FF
        stx     zpDispMask

        ldx     #$06                                ; PATH Address is 0x2106 (RES_BLK)                   
        ldy     #$21

        stx     zpPtr1
        sty     zpPtr1+1
        ldy     #0
        lda     (zpPtr1),Y
        beq     dispCurrentPath_1
dispCurrentPath_0
        clc
        adc     #$80
        jsr     str2UpperCase
        jsr     COUT1                           ; Char disp routine
        iny                                     ; increase char position
        lda     (zpPtr1),Y                      ; indirect zeropage addressing pointing to current char
        bne     dispCurrentPath_0               ; no need of cmp 00 is current char is not 00 then loo
dispCurrentPath_1
        rts   
        

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

printMsgCentered

    stx zpPtr1
    sty zpPtr1+1
    txa 
    pha
    tya
    pha
    ldy     #0
    lda     (zpPtr1),Y
    beq     printMsgCentered_1
printMsgCentered_0
    iny
    ;iny                                     ; increase char position
    lda     (zpPtr1),Y                      ; indirect zeropage addressing pointing to current char
    bne     printMsgCentered_0
    tya
    sbc     #40
    EOR     #$FF
    lsr     a
    tay
    iny
    lda     #" "
printMsgCentered_A
    jsr     COUT1
    dey
    bne     printMsgCentered_A 
    pla
    tay
    pla
    tax
    ;jsr     printMsg
printMsgCentered_1  
    rts

    
       

dispRWTSReturnCode    
    pha
    ldx     #$FF
    stx     zpDispMask
    
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
        cmp     #$10
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
    cpx     #$26                            ; 22-> 34 
    bne     dispClearLineImage_0            ; Not equal we clear out the line
    pla                                     ; restore A from stack
    rts                                     ; return to caller

dispImageAttr
    ldy     #$00
    lda     (zpPtr2),Y
    cmp     #$44                            ; "D" in ASCII
    beq     dispImageAttr_D
    
    cmp     #$46                            ; "F" in ASCII
    beq     dispImageAttr_F

    cmp     #$4D                            ; "M" in ASCII
    beq     dispImageAttr_M

    cmp     #$54                            ; "T" in ASCII
    beq     dispImageAttr_T
    
    cmp     #$45                            ; "E" in ASCII for Empty
    beq     dispImageAttr_E

    cmp     #$56                            ; "V" in ASCII for value
    beq     dispImageAttr_V

    cmp     #$58                            ; "V" in ASCII for value
    beq     dispImageAttr_X


    jmp     dispImageAttr_end

dispImageAttr_D
    lda     #$C4                            ; "D"
    jmp     dispImageAttr_end

dispImageAttr_F

    lda     #$AD                            ; "-"
    jmp     dispImageAttr_end

dispImageAttr_M

    lda     #$A0                            ; " "
    jmp     dispImageAttr_end

dispImageAttr_E

    lda     #$A0                            ; " "
    jmp     dispImageAttr_end


dispImageAttr_V

    lda     #$A0                            ; " "
    jmp     dispImageAttr_end

dispImageAttr_X

    lda     #$A0                            ; " "
    jmp     dispImageAttr_end

dispImageAttr_T

    ;lda     #$A0                            ; " "
    ldx     zpPtr2
    ldy     zpPtr2+1
    jsr     printMsgCentered
    rts
    ;jmp     dispImageAttr_end

dispImageAttr_end
    jsr     COUT1                           ; print
    lda     #$A0                            ; "SPC"
    jsr     COUT1                           ; print
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

    ldy     #$01                            ; we start at 1 instead of 0 cause first char indicate type of file
    lda     (zpPtr2),Y
   
dispDataBlockImage_1
    clc                                     ; Clear the carry before adding
    adc     #$80                            ; Add 128 to the char to transform it to Apple CharSet
    jsr     str2UpperCase                   ; shift to uppercase
    jsr     COUT1
    iny
    lda     (zpPtr2),Y                      ; indirect zeropage addressing pointing to current char
    cmp     #$7C
    beq     dispDataBlockImage_1_V
    
    cmp     #$00                        
    bne     dispDataBlockImage_1
    lda     #$A0                            ; SPACE
    jmp     dispDataBlockImage_2

dispDataBlockImage_1_V                      ; dispValue the label has a separator "|"" the value is after it 
    iny
    tya                                     ; Save the value of Y into the stack,
    pha                                     ; Y will be needed 3x times 
    pha                                     ; push to the stack
    pha
    lda     #" "                            ; Pad with " " space til $18
    jsr     dispDataBlockImage_2            ; it return here where normally it goes to the upper caller
    pla                                     ; retrieve A from the stack ->Y
    tay                                     ; Move A to Y

dispDataBlockImage_1_V_1                    ; Counting the size of the value to pad to right
    iny                                     ; The character after the separator |
    lda     (zpPtr2),Y                      ; Relative adressing using zeropage
    bne     dispDataBlockImage_1_V_1        ; Looking for the 0x0 char to mark the end of the string
    sty     zpScratch                       ; Saving the value of Y index of the last char, 
    pla                                     ; Retrieve the value of Y (start of the value string)

    sbc     zpScratch                       ; substract scratchValue to A
    eor     #$FF                            ; Get the positive value
    sbc     #30                             ; Pad right at 30 char with a new substract
    eor     #$FF                            ; get the positive value
    tax                     
    ldy     CV                              ; Get the current line index
    jsr     dispPositionCursor              ; Set the display cursor (x,y)
    pla                                     ; Get back A (Y start index position) 
    tay
    lda     (zpPtr2),Y

dispDataBlockImage_1_V_2                    ; Display the value on screen
    adc     #$80                            ; +128 to transform ASCII to Apple II charset
    jsr     COUT1                           ; Print to screen
    iny                                     ; Next char
    lda     (zpPtr2),Y                      ;
    bne     dispDataBlockImage_1_V_2        ; if char is 0x0 return to the caller
    rts


dispDataBlockImage_2                       ; Pads the label with space to position #29
    iny
    jsr     COUT1
    pha
    tya
    sbc     #29
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

pIsSelectableItem
   
    ;lda     zpImgIndx
    jsr     getImageAddr
    clc
    ldy     #$0
    lda     (zpPtr2),Y
    cmp     #$54                            ; ASCII T
    beq     pIsSelectableItem_1
    cmp     #$45                            ; ASCII E 
    beq     pIsSelectableItem_1
    cmp     #$58                            ; ASCII X 
    beq     pIsSelectableItem_1
    clc
    rts

pIsSelectableItem_1
    sec
    rts

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
    txa
    jsr     pIsSelectableItem
    bcs     pKeyUp
    
    jmp     mainDispatch_2

pKeyUp_0
    jsr     decImageIndex                   ; decrement current Index
    
    lda     zpImgIndx
    jsr     pIsSelectableItem
    bcs     pKeyUp

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
    txa         
    jsr     pIsSelectableItem
    bcs     pKeydown
    jmp     mainDispatch_2

pKeydown_0
    jsr     incImageIndex
    lda     zpImgIndx
    jsr     pIsSelectableItem
    bcs     pKeydown
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

    ;ldx     #$08
    ;ldy     #$0A    
    ;jsr     dispPositionCursor
    lda     #" "
    jsr     COUT1

    jsr     getImgPageIndx
    jsr     printInt8

    lda     #" "
    jsr     COUT1

    lda     zpImgIndx     
    jsr     getImageAddr                        ; get the selected item address in the read data block 
    ;jsr     readKey
    ;ldx     zpPtr2                              ; zpPtr2 contains the address of the image address
    ;inx                                         ; the first char is the type of the item will not display it     
    ;ldy     zpPtr2+1

    ;jsr     printAscii
    ;jsr     readKey
    ldy     #$00
    lda     (zpPtr2),y                          ; A contains the type selected item
    
    pha
    jsr     pSelectItem_setCommand
    pla
    cmp     #$44                                ; 0x44 = "D" ASCII it is a directory    
    bne     pSelectItem_1
    
    jmp     refresh                             ; it is equal this is a directory

pSelectItem_1
    cmp     #$46                                ; 0x46 = "F" ASCII it is a file
    bne     pSelectItem_2

                                                ; TODO add a condition to trigger C600 or C500 for Smartport
    ;lda     EMUL_TYPE
    ;adc     #$B0                                ; transform to Apple charset        
    ;jsr     COUT1
    ;jsr     COUT1
    ;jsr     COUT1
prewait_1s
    ldy     #$FF
    sty     PTR
    sty     PTR+1
wait_1s
    dec     PTR 
    lda     PTR
    cmp     #$00
    bne     wait_1s
    dec     PTR+1
    lda     PTR+1
    cmp     #$00
    bne     wait_1s

    ;lda     EMUL_TYPE
    ;adc     #$B0                                ; transform to Apple charset        
    ;jsr     COUT1
    ;jsr     COUT1
    ;jsr     COUT1
    
preboot    
    lda     EMUL_TYPE
    cmp     #$00                                ; D0 = Disk Image .2mg .dsk etc...                                       
    beq     pSelectDiskII
    
    cmp     #$01
    beq     pSelectSmartport

pSelectItem_2
    jmp     refresh                             ; we should never hit this point... but if no D or F 

pSelectDiskII
    ;lda     EMUL_TYPE
    ;adc     #$B0
    ;jsr     COUT1
    ;jsr     COUT1
    ;jsr     COUT1

    ;jsr     readKey
    jmp     #$C600                              ; it is a file mount and then jump
    
pSelectSmartport

    ;lda    $FBBF
    ;jsr    printInt8
    ;lda    $FBBF
    ;jsr    printInt8
    ;jsr    readKey
    lda    $FBBF
    cmp     #$00                            ; Check if we are on Apple IIGS
    bne     not_iigs

is_iigs

    jmp     #$FAA6

not_iigs

    
    jmp     #$C500

pSelectItem_setCommand    
    jsr     getImgPageIndx
    tay     
    ldx     #$10
    jsr     setCommand
    rts

pKeyMain
    ldx     #$09
    ldx     #$09
    jsr     setCommand
    jmp     refresh


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

mainDispatch_main
    jmp     pKeyMain

mainDispatch
    jsr     readKey
    jsr     mainDispatch_disp
    
    cmp     #$D2                            ; KEY [R]
    beq     mainDispatch_refresh

    cmp     #$CD                            ; KEY [M]
    beq     mainDispatch_main

    cmp     #$C2                            ; KEY [B]
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

mainDispatch_disp                           ; Putting A containing the key value on the stack 
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
    ;jsr     COUT
    
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
    
printInt8_SpcPad                ; value in A
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
            ;jsr     readKey
            rts

seekDrive
            lda     #$01
            sta     ioTrack
            lda     #$02       
                                 ; 0 -> Seek Command
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
            asc     "PATH:/"
            dfb     $00

_title       
            asc     "BOOTLOADER"
            dfb     $00

_option 
            ASC     "[R]EFRESH [B]OOT [M]AIN"
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



