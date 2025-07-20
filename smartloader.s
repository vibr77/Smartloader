    DSK PRG.BIN
    TYP BIN
    mx  %11

DEBUG   =   0

            org       $2000
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

CURPOS          EQU     $FB5B
BASCLC          EQU     $FBC1               ; subroutine to position cursor

BASL            EQU     $28
BASH            EQU     $29
CV              EQU     $25                 ; Cursor position
CH              EQU     $24                 ; 

WAIT            EQU     $FCA8
;CYCLE1          EQU     $2501
;CYCLE           EQU     $2500
CMD_BLK         EQU     $2600               ; Command Block
;SCRATCHPAD      EQU     $3100
RES_BLK         EQU     $2800               ; Result for CMD
RES_BLK2        EQU     $2900               ; Result for CMD

MLI             EQU     $BF00              ; ProDOS system call
CROUT           EQU     $FD8E              ; Monitor CROUT routine
PRBYTE          EQU     $FDDA              ; Monitor PRBYTE routine
IORTS           EQU     $FF58
myZP            EQU     $02


cstMaxImgLen    EQU    #$10                 ; Constant Max Image Filename len
cstLineOffset   EQU    #$03
cstMaxImgItem   EQU    #$07
zpImgIndx       EQU    $85                  ; Current ImageIndex
zpPrevImgIndx   EQU    $86
zpMaxImgIndx    EQU    $87
zpDispMask      EQU    $88
zpPtr1          EQU    $80                  ; 80/81 2 Bytes Addr ptr for DisplayMsg on Screen 
zpPtr2          EQU    $83 

start       


            ;----------------------------------------------
            ; Clear Screen
            ;----------------------------------------------
            
            jsr     CLRSCR
            
            ;----------------------------------------------
            ; Check PRODOS
            ;----------------------------------------------
            
            ldx     #$01
            ;lda     $BF00
            ;cmp     #$4c
            ;bne     loopb                                   ; TO BE CHANGED
            
            ;---------------------------------------------
            ;   VAR INIT
            ;---------------------------------------------
            
            ldx     #$00
            inx
            stx     zpImgIndx
            stx     zpPrevImgIndx

            ldx     #$07
            stx     zpMaxImgIndx
 
            ldx     #$0F
            ldy     #$00    
            jsr     dispPositionCursor

            ldx     #$FF                            ; add Inverse Mask
            stx     zpDispMask                      ; store to zeropage       
           
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
            ldy     #$15    
            jsr     dispPositionCursor
            
            ldy     #$28
            jsr     dispLine

            ldx     #$0
            ldy     #$17    
            jsr     dispPositionCursor

            ldx     #<_option
            ldy     #>_option
            jsr     printMsg


            ;jsr     loadImageNameToDataBlock
            ;jsr     writeCmdBlk
            ;jsr     readKey
refresh            
            jsr     readBlock
            lda     RES_BLK
            cmp     #$20
            bne     refresh_0                       ; Error to be diplayed

            lda     RES_BLK+1                       
            sta     zpMaxImgIndx 
            ;BRK
            ;jsr     readKey
            jsr     dispDataBlock
            
            
            ldx     #$00                            ; init imgaIndex
            stx     zpImgIndx                       ; store to zeropage
            ldx     #$7F                            ; add Inverse Mask
            stx     zpDispMask                      ; store to zeropage
            jsr     dispDataBlockImage              ; disp current selection

            jsr     mainDispatch
            
            ;jsr     checkDriveSlot
            ;jsr     writeCmdBlk
            ;brk
            jsr start

refresh_0
            jsr     dispErrorMsg
            rts


;   @Funct: setCommand
;   @Param: X Command, Y Value
;

setCommand       
            lda     #<CMD_BLK
            sta     zpPtr1
            
            lda     #>CMD_BLK
            sta     zpPtr1+1
            txa
            sta     CMD_BLK
            
            tya
            sta     CMD_BLK+1

            lda     #$00
            ldy     #$01
setCommand_0
            iny
            sta     (zpPtr1),Y
            cpy     #$FF
            bne     setCommand_0
            lda     #<CMD_BLK
            sta     zpPtr1
            
            lda     #>CMD_BLK
            inc
            sta     zpPtr1+1
            ldy     #$00
            lda     #$00
setCommand_1
            sta (zpPtr1),Y
            cpy     #$FF
            iny
            bne     setCommand_1

setCommand_2
            jsr     MLI                         ; CALL PRODOS WRITE_BLOCK
            dfb     $81
            dfb     #<paramBLK_WR
            dfb     #>paramBLK_WR
            jsr     ERROR
            rts

dispLine
            lda     #$DF
            jsr     COUT
            dey
            bne dispLine
            rts

    DO DEBUG
loadImageNameToDataBlock
            lda     #$00
            sta     zpImgIndx

loadImageNameToDataBlock_1
            
            ldx     #$10                        ; #10 -> 16 !!!
            stx     calc_1_low
            sta     calc_2_low
            
            jsr     mult_8B_8B

            ldx     calc_result_high
            stx     calc_2_high

            ldx     calc_result_low
            stx     calc_2_low

            ldx     #<RES_BLK
            stx     calc_1_low

            ldx     #>RES_BLK
            stx     calc_1_high

            jsr     add_16B_16B

            ldx     calc_result_low
            stx     zpPtr2

            ldx     calc_result_high
            stx     zpPtr2+1                    ; at this stage we should have the rigth destination address in zpPtr2

            lda     zpImgIndx
            asl     a
            tax

            lda     imageTable,x                 ; Get low byte address
            ldy     imageTable+1,x               ; Get high byte address

            sta     zpPtr1                       ; must be at the begininng
            sty     zpPtr1+1

            ldy     #0
            lda     (zpPtr1),y
            

loadImageNameToDataBlock_2                      ; copy char to dest addr char starting at $3200 + 16*ImageIndex
            sta     (zpPtr2),y 
            iny 
            lda     (zpPtr1),y 
            bne     loadImageNameToDataBlock_2

loadImageNameToDataBlock_3                      ; complement to 16
            sta     (zpPtr2),y
            iny     
            cpy     cstMaxImgLen
            bne     loadImageNameToDataBlock_3         
    
loadImageNameToDataBlock_4                      ; Move to the next imageIndex
            lda     zpImgIndx
            inc     a
            sta     zpImgIndx
            cmp     #$08
            bne     loadImageNameToDataBlock_1

loadImageNameToDataBlock_5
            rts
    FIN

dispDataBlock
            lda     #$00
            sta     zpImgIndx
            ldx     #$FF
            stx     zpDispMask

dispDataBlock_1
            jsr dispDataBlockImage

dispDataBlock_2
            ;lda zpImgIndx
            inc zpImgIndx 
            lda zpImgIndx
            cmp zpMaxImgIndx
            bne dispDataBlock_1
            rts

;Display the name of the image on screen
;zpImgIndx contain the index
;zpDispMask  contains the display mode #FF normal, #3F inverted
getImageAddr
           
            ldx     #$10                        ; #10 -> 16 !!!
            stx     calc_1_low
            sta     calc_2_low
            
            jsr     mult_8B_8B

            ldx     calc_result_high
            stx     calc_2_high

            ldx     calc_result_low
            stx     calc_2_low

            ;ldx     #<RES_BLK
            ldx     #$10                    ; we start at 0x2810 and not 0x2800 to keep 16 bytes of data 
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
            

dispDataBlockImage
            
            lda     zpImgIndx
            jsr     getImageAddr
            
            lda     zpImgIndx
            
            adc     cstLineOffset                   ; position Cursor with line Offset
            tay 
            ldx     #$0
            jsr     dispPositionCursor

            ;lda     #$00
            ;ldx     zpImgIndx
            ;jsr     PrintUint16
            lda     zpImgIndx
            jsr     PRBYTE

            lda     #$BE                            ; ">"
            jsr     COUT                            ; print

            lda     #$A0                            ; " "
            jsr     COUT                            ; print

            ldy     #$00
            lda     (zpPtr2),Y
            

dispDataBlockImage_1
            and     zpDispMask
            jsr     $FDED
            iny
            lda     (zpPtr2),Y                      ; indirect zeropage addressing pointing to current char
            bne     dispDataBlockImage_1
            rts

; Main process flow
; Reading from the keyboard
JMP_REBOOT
            jmp     reboot
JMP_REFRESH
            jmp     refresh
mainDispatch
            jsr     readKey
            
            pha                                     ; Putting A containing the key value on the stack 
            
            ldy     #$00                            ; Display the Key value on the top right of the screen
            ldx     #$06
            jsr     dispPositionCursor
            jsr     PRBYTE

            lda     zpImgIndx
            sta     zpPrevImgIndx
            
            pla
            cmp     #$D2                            ; KEY [R]
            beq     JMP_REFRESH

            cmp     #$C2                            ; KEY [R]
            beq     JMP_REBOOT

            cmp     #$8D                            ; KEY [ENTER] / [RETURN] 
            beq     mainDispatch_4            
            
            cmp     #$8B                            ; KEY [UP]
            bne     mainDispatch_0
            
            ldx     #$FF                            ; Change the current Image back to normal text
            stx     zpDispMask
            jsr     dispDataBlockImage

            ldx     zpImgIndx
            cpx     #00                             ; if current Index is 0 then roll to the end
            bne     mainDispatch_A
            
            ldx     zpMaxImgIndx                    ; zpImgIndx =7 rolling to 0
            stx     zpImgIndx
            jmp     mainDispatch_2

mainDispatch_A 
            jsr     decImageIndex                   ; decrement current Index
            jmp     mainDispatch_2                  ; go the display part

mainDispatch_0            
            cmp     #$8A                            ; Key Down
            bne     mainDispatch
            
            lda     zpImgIndx
            
            ldx     #$FF
            stx     zpDispMask
            jsr     dispDataBlockImage
            ldx     zpImgIndx
            cpx     zpMaxImgIndx                    ; TODO put this automatic from the stack
            bne     mainDispatch_1

            ldx     #$0                             ; zpImgIndx =7 rolling to 0
            stx     zpImgIndx
            jmp     mainDispatch_2

mainDispatch_1
            jsr     incImageIndex                   ; increment current index

mainDispatch_2            
            lda     zpImgIndx
            sbc     #$09
            bpl     mainDispatch_3                 
            jsr     padd1char

mainDispatch_3
            ldy     #$0
            ldx     #$22
            jsr     dispPositionCursor

            ;lda     #$00
            ;ldx     zpImgIndx
            ;jsr     PrintUint16
            lda     zpImgIndx
            jsr     PRBYTE

            lda     #$AF                            ; "/"
            jsr     COUT
            
            lda     zpMaxImgIndx
            jsr     PRBYTE
            ;lda     #$00
            ;ldx     zpMaxImgIndx
            ;jsr     PrintUint16
            
            ldx     #$3F
            stx     zpDispMask
            jsr     dispDataBlockImage
            jmp     mainDispatch

mainDispatch_4 
            jsr     CLRSCR

            ldx     #$10
            ldy     #$09    
            jsr     dispPositionCursor
            
            ldx     #$FF
            stx     zpDispMask

            lda     zpImgIndx
            jsr     getImageAddr

            ldx     zpPtr2
            ldy     zpPtr2+1

            jsr     printMsg
            ldx     #$01
            ldy     zpImgIndx
            jsr     setCommand
            
            jsr     readKey

            rts

padd1char
            lda     #$A0              ; padding right by print space char
            jsr     COUT              ; display content of A
            rts                       ; return to PC on stack

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

printMsg_0
            and     zpDispMask
            jsr     COUT                   ; Char disp routine
            iny                             ; increase char position
            lda     (zpPtr1),Y            ; indirect zeropage addressing pointing to current char
            bne     printMsg_0                ; no need of cmp 00 is current char is not 00 then loo
            rts     

writeCmdBlk
            
            ;LDX     #$66
            LDA     #<RES_BLK
            STA     zpPtr1
            LDA     #>RES_BLK
            STA     zpPtr1+1
            LDY     0

writeCmdBlk_0
   
            JSR     MLI
            DFB     $81
            DFB     #<paramBLK_WR
            DFB     #>paramBLK_WR
            jsr     ERROR
            jsr     readBlock
            rts

checkDriveSlot
            lda    $CFFF        ;reset all other I/O Select spaces
            jsr    IORTS        ;call my own c800 space
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

ERROR    
            pha
            ldy     #$00                            ; Display the Key value on the top right of the screen
            ldx     #$0
            jsr     dispPositionCursor
            
            lda     #$C5                            ; "/"
            jsr     COUT

            pla
            jsr     PRBYTE    ;Print error code
            jsr     BELL      ;Ring the bell
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

            jsr     ERROR
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
            ASC     "v0.26"
            dfb     $00
_option 
            ASC     "[R]EFRESH [B]OOT [S]ETTINGS"
            dfb     $00

error_10
            ASC     "ERR 10 UNABLE TO GET DATA"
            dfb     $00

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
            DFB      $B0
            DFB      $00

    DO DEBUG
image_00
            ASC ".."
            dfb $00
image_01      
            ASC     "ARKANOID.WOZ"
            dfb     $00
image_02
            ASC     "ZAXXON.WOZ"
            dfb     $00
image_03      
            ASC     "PAINTSHOP.DSK"
            dfb     $00
image_04      
            ASC     "CHOPLIFTER.DSK"
            dfb     $00

image_05      
            ASC     "LODE RUNNER.DSK"
            dfb     $00

image_06      
            ASC     "COMMANDO.DSK"
            dfb     $00
image_07      
            ASC     "PRODO.DSK"
            dfb     $00

imageTable
            dw  image_00,image_01,image_01,image_02,image_03,image_04,image_05,image_06,image_07
    ELSE
    FIN
; Merlin32 include
            PUT     print_uint16_with_sp.s
            PUT     vibr_lib.s


	