    DSK boot2.bin
    TYP BIN
    mx  %11

DEBUG   =   0
    org       $4000
    lst       on
    xc
    xc

BSLOT           EQU     $2B                      ; Boot slot

RWTS            EQU     $BD00
PRGJMP          EQU     $4200                    ; After the sector copy to memory, jmp to program entry point




    ;----------------------------------------------
    ; Zero Page & CST definition
    ;----------------------------------------------

SETNORM         EQU     $FE84
SETINV          EQU     $FE80

NBSECTORS       EQU      16

    ;----------------------------------------------
    ; Init
    ;----------------------------------------------
init
            jsr     SETNORM
            ldx     #$00
            ldy     #$01    
            jsr     dispPositionCursor

init_value
            lda     BSLOT
            sta     ioSlot
 
            lda     #$01
            sta     ioTrack                 ; Track to read is 2
            jsr     seekDrive

            ldx     #NBSECTORS                    ; lecture 16 secteurs
            stx     CURRSECTOR
            lda     #>PRGJMP               ; set the data buffer to $4200 (high byte is only changed)
            sta     where

            ldx     #$08
            ldy     #$09    
            jsr     dispPositionCursor
            ldx     #<_loading
            ldy     #>_loading
            jsr     printMsg


:loop                                   ; corriger les bugs dessous..
            lda     #NBSECTORS
            sec
            sbc     CURRSECTOR

            ldy     #$09
            ldx     _loading_size  
            jsr     dispPositionCursor

            jsr     dispByte
            sta     ioSector
            lda     where
            sta     ioBuffer+1
            jsr     readDataBlock 
            inc     where
            dec     CURRSECTOR
            bne     :loop
            jmp     PRGJMP

where       db      0

readDataBlock
            
            lda     #$01                    ; 1 -> Read Command
            sta     ioCmd
            jsr     CALL_RWTS
            rts

seekDrive
            lda     #$00     
            sta     ioCmd
            jsr     CALL_RWTS
            rts     
CALL_RWTS
            ; RWTS is located at $3D00
            ldy     #<iocb
            lda     #>iocb
            JSR     RWTS
            ;beneath dos page 6-5 $48 doit être mis a 0 appel chaque apple de RWTS
            pha
            lda     #$00
            sta     $48
            pla
            
            rts

readKey
            lda     $C000               ; Wait until a key is pressed
            bpl     readKey
            bit     $C010
            rts 


iocb        dfb     $01                            ;
ioSlot      dfb     $60                            ; Slot number ex:60
iodrive     dfb     $01                            ; Drive number $01 
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
CURRSECTOR  dfb     16
_loading    asc     "LOADING: "
_loading_end            dfb     0
_loading_size dfb  8 + _loading_end - _loading 


dct 
            dfb     $00,$01,$EF,$D8
TABLE
            dfb     00,13,11                  ; 00->00,01->13,02->11
            dfb     09,07,05                  ; 03->09,04->07;05->05
            dfb     03,01,14                  ; 06->03,07->01,08->14
            dfb     12,10,08                  ; 09->12,10->10,11->08
            dfb     06,04,02,15               ; 12->6,13->04,14->02,15->15


            ;put     vibr_lib.s
            put     disp.s
            put     printbyte.s
        



