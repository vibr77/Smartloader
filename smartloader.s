    DSK PRG.SYSTEM
    TYP BIN
    mx  %11


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
CYCLE1          EQU     $2501
CYCLE           EQU     $2500
CMD_BLK         EQU     $3000               ; Command Block
SCRATCHPAD      EQU     $3100
RES_BLK         EQU     $3200               ; Result for CMD
RES_BLK2        EQU     $3300               ; Result for CMD

MLI             EQU     $BF00              ; ProDOS system call
CROUT           EQU     $FD8E              ; Monitor CROUT routine
PRBYTE          EQU     $FDDA              ; Monitor PRBYTE routine
IORTS           EQU     $FF58
myZP            EQU     $02


cstMaxImgLen    EQU    #$10                 ; Constant Max Image Filename len
cstLineOffset   EQU    #$02
zpImgIndx       EQU    $85                  ; Current ImageIndex
zpPrevImgIndx   EQU    $86
zpDispMask      EQU    $87
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
 
            jsr     loadImageNameToDataBlock
            jsr     readKey
            jsr     dispDataBlock
            
            ldx     #$00                            ; init imgaIndex
            stx     zpImgIndx                       ; store to zeropage
            ldx     #$3F                            ; add Inverse Mask
            stx     zpDispMask                      ; store to zeropage
            jsr     dispDataBlockImage              ; disp current selection

            jsr     testkeybloop
            
            jsr     checkDriveSlot
            jsr     writeCmdBlk
            brk

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

            ldx     #$00
            stx     calc_1_low

            ldx     #$32
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

dispDataBlock
            lda     #$00
            sta     zpImgIndx
            ldx     #$FF
            stx     zpDispMask

dispDataBlock_1
            jsr dispDataBlockImage

dispDataBlock_2
            lda zpImgIndx
            inc 
            sta zpImgIndx
            cmp #$08
            bne dispDataBlock_1

            rts


;Display the name of the image on screen
;zpImgIndx contain the index
;zpDispMask  contains the display mode #FF normal, #3F inverted

dispDataBlockImage
            lda     zpImgIndx
            ldx     #$10                        ; #10 -> 16 !!!
            stx     calc_1_low
            sta     calc_2_low
            
            jsr     mult_8B_8B

            ldx     calc_result_high
            stx     calc_2_high

            ldx     calc_result_low
            stx     calc_2_low

            ldx     #$00
            stx     calc_1_low

            ldx     #$32
            stx     calc_1_high

            jsr     add_16B_16B

            ldx     calc_result_low
            stx     zpPtr2

            lda     zpImgIndx
            
            adc     cstLineOffset                   ; position Cursor with line Offset
            tay 
            ldx     #$0
            jsr     dispPositionCursor

            lda     #$00
            ldx     zpImgIndx
            jsr     PrintUint16

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


testkeybloop
            jsr readKey
            pha
            ldy #$01
            ldx #$26
            jsr dispPositionCursor
            jsr PRBYTE

            
            lda zpImgIndx



            sta zpPrevImgIndx
            pla
            cmp #$8B
            bne testkeybloop_0
            
            ldx #$FF
            stx zpDispMask
            
            jsr dispDataBlockImage
            jsr decImageIndex
            
            ;jmp testkeybloop_1
testkeybloop_0            
            cmp #$8A
            bne testkeybloop_1
            
            lda zpImgIndx
            cmp #$07
            beq testkeybloop
            ldx #$FF
            stx zpDispMask
            jsr dispDataBlockImage

            jsr incImageIndex

testkeybloop_1            
            lda zpImgIndx
            ;jsr PRBYTE
            sbc #$09
            bpl testkeybloop_2
            ;JSR *+3                    
            jsr padd1char

testkeybloop_2

            ldy     #$0
            ldx     #$26
            jsr dispPositionCursor

            lda     #$00
            ldx     zpImgIndx
            jsr     PrintUint16
            
            ;ldy zpPrevImgIndx
            ;ldx #$2
            ;jsr dispPositionCursor
            ;ldx cstMaxImgLen
            ;inx
            ;inx
            ;inx
            ;lda #$A0

testkeybloop_3
            ;jsr COUT
            ;dex
            ;cpx #$0
            ;bne testkeybloop_3


            ;ldy     zpImgIndx
            ;ldx     #$02   
            ;jsr     dispPositionCursor

            ;lda     zpImgIndx           ; multiply by 2 for index of a DW 
            ;asl     a
            ;tax

            ;lda     imageTable,x      ;Get low byte address
            ;ldy     imageTable+1,x        ;Get high byte address
            ;tax    
            ;ldx     #<image_01
            ;Ldy     #>image_01
            
            ;jsr     dispImageFile

            ldx #$3F
            stx zpDispMask
            jsr dispDataBlockImage
            jmp     testkeybloop
            rts

padd1char
            lda     #$A0              ; padding right by print space char
            jsr     COUT              ; display content of A
            rts                     ; return to PC on stack



incImageIndex
            ldx zpImgIndx
            cpx #$254
            beq incImageIndex_0
            inx
            stx zpImgIndx
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
            TYA     
            STX     CH
            JSR     CURPOS
            pla                                     ; pull regA from the stack
            RTS

dispImageFile

            stx     zpPtr1                       ; must be at the begininng
            Sty     zpPtr1+1

            lda     #$00
            ldx     zpImgIndx                       ; load X with current Image Index
            jsr     PrintUint16                     ; print 16 unsigned integer A LOW, X HIGH

            lda     #$BE                            ; ">"
            jsr     COUT                           ; print

            ldy     #0
            lda     (zpPtr1),Y
            ldx     #$3F
            stx     zpDispMask

dispImageFile_1
            AND     zpDispMask
            JSR     $FDED
            INY
            LDA     (zpPtr1),Y            ; indirect zeropage addressing pointing to current char
            bne     dispImageFile_1
dispImageFile_2
            cpy     cstMaxImgLen
            beq     dispImageFile_E
            LDA     #$BE
            JSR     $FDED
            INY
            jmp     dispImageFile_2
dispImageFile_E
            rts

printMsgInit
            STX     zpPtr1
            STY     zpPtr1+1
            LDY     #0
            LDA     (zpPtr1),Y

            ;jsr    readKey
printMsg
            AND     #$3F
            JSR     $FDED                   ; Char disp routine
            INY                             ; increase char position
            LDA     (zpPtr1),Y            ; indirect zeropage addressing pointing to current char
            bne     printMsg                ; no need of cmp 00 is current char is not 00 then loop
printMsgDone
            jsr readKey
            rts     

writeCmdBlk
            
            LDX     #$66
            LDA     #<RES_BLK
            STA     zpPtr1
            LDA     #>RES_BLK
            STA     zpPtr1+1
            LDY     0
writeCmdBlk01
            LDA     #$10
            STA     (zpPtr1),Y
            INY
            cpy     255
            bne     writeCmdBlk01
            JSR     MLI
            DFB     $81
            DFB     #<paramLst
            DFB     #>paramLst
            jsr     ERROR
            jsr     readBlock
            RTS

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
            JSR  PRBYTE    ;Print error code
            JSR  BELL      ;Ring the bell
            JSR  CROUT     ;Print a carriage return
            RTS
readBlock
            
            LDY     #$0

readBlock01
            LDA     #$20
            STA     (zpPtr1),Y
            INY
            cpy     255
            bne     readBlock01
            jsr     readKey
            JSR     MLI
            DFB     $80
            DFB     #<paramLst
            DFB     #>paramLst
            jsr     ERROR
            jmp     reboot
            RTS
readKey
            LDA     $C000               ; Wait until a key is pressed
            BPL     readKey
            BIT     $C010
            rts    

reboot
            jmp     #$C600
            rts
Wait
            ;LDX     #$255
Wait_1              
            LDA     #$255
            JSR     WAIT
            DEX
            ;CPX     #$0
            ;JMP     Wait_1
            ;RTS

title       
            ASC     "SMARTLOADER"
            dfb     $00
line
            ASC     "__________________________________________________________
            dfb     $00
msg         
            ASC     "This is the sound of sea"
            dfb     $8D,$00                       ; 8D for cariage return
msg2
            ASC     "Holly Shit"
            dfb     $8D,$00                       ; 8D for cariage return
noprodos
            ASC     "No proDos"
            dfb     $8D,$00
prodos
            ASC     "ProDos found"
            dfb     $8D,$00
paramLst
            DFB      $03                    ; paramcnt =3
            DFB      $60                    ; slot number
            DFB      $00
            DFB      $32
            DFB      $B0
            DFB      $00

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


; Merlin32 include
            PUT     print_uint16_with_sp.s
            PUT     vibr_lib.s


	