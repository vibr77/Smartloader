;
;__    ________  ___       Author: Vincent BESSON
; \ \ / /_ _| _ ) _ \      Release: 0.1
;  \ V / | || _ \   /      Date: 2025
;   \_/ |___|___/_|_\      Description: Apple Disk II Smartloader source
;                2025      Licence: Creative Commons
;______________________

; Bootloader of the Smartloader:
; Source Files:
;   main_T0S0.s
;   main_T0S0_disp.s
; the first byte (value $01) is used by the boot rom
; the bootloader starts at $801
; The first step is to build the display
; Then to load the RWTS Dos sector (8-1) to $BF00 going downwards
; Then loads to $4000 the smartloader sector from (0F to 09)
; Becareful this bootloader can not exceed 256 bytes

; When changing the size of smartloader in 4000, need to be changed
; Readnext 
;   cpx     #$0E 
; LOAD_SML_SECT                                          
;                lda     #$45
;                sta     LOADADDR+1
;                ldx     #$0D
;                stx     CURRSECTOR
;                jmp     PREP_CALL
;

; Changelog:
;
; 2025.08.25 v0.37:
; [-] Remove of Prodos image type
; [+] New Bootloader track 0 sector 0
; [+] Fast Dos RWTS to load READ / WRITE
; [+] Code refactoring


                DSK      smartloader_s0.bin
		lst	on
                TYP      BIN
                MX       %11

                ORG      $800
                xc
                xc

VERSION         EQU      "v.fat"

START           EQU      *
BEEP            EQU      $FBDD
KYBD            EQU      $C000
STROBE          EQU      $C010
POINTA          EQU      $26
BSLOT           EQU      $2B                      ; Boot slot
BSECTR          EQU      $3D                      ; LAST BSECTR READ
BTEMP           EQU      $3E                      ; ADDRESS BTEMP
BRENTRY         EQU      $5C                      ; OFFSET TO READER (DISK II ROM)
START_SECTOR    EQU      $08                      ; First sector to read moving downward
END_SECTOR      EQU      $00                      ; Last sector to read
PRGJMP          EQU      $4000                    ; After the sector copy to memory, jmp to program entry point
RWTS_LOC_HI     EQU      $BF                      ; High adress of RWTS target location ($BF00)
TRACK           EQU      $41                      ; Track number (used by Cx000)

                dfb     01                        ; <!> Needed by thre boot rom

                ;jsr     BEEP
                jsr     keypress
                lda     CURRSECTOR                ; Sector to be loaded 
                cmp     #$08                      ; 08 means we are at the begining and we starts by init the display
                bne     C1
                jsr     INIT_DISP                 ; Display the screen mask and then load the sectors
C1
                lda     POINTA+1                  ; WHERE DID BSECTR GET LOADED?
                cmp     #09                       ; (AT 0800, The address was incremented after reading the sector) 
                bne     READNEXT                  ; =>NO. WE'RE LOADING SOMETHING

                ; calcul de l'adresse de la routine de lecture d'un secteur de la prom de boot
                lda     BSLOT                     ; GET BOOT BSLOT
                lsr     A                         ; CONVERT TO CX00
                lsr     A
                lsr     A
                lsr     A
                ora     #$C0
                sta     BTEMP+1
                lda     #BRENTRY                   ; PROM ROUTINE OFFSET
                sta     BTEMP
READNEXT                                          ;
                ldx     READ_SECTORS
                cpx     #$0A                      ; c-> 8 + 2 secteurs
                beq     START_PRG                 ; then jump smartloader
SUITE
                INC     READ_SECTORS
                ldx     CURRSECTOR
                cpx     #END_SECTOR               ; finish DOS RWTS si = 0? 
                beq     LOAD_SML_SECT             ; if yes then load smartloader sectors
                
                dec     CURRSECTOR                ; ONE LESS BELL TO ANSWER..

PREP_CALL                                         ; Preparation call for ROM Call to load sectors 
                ;phx
                ;txa
                ;jsr     dispHexByte
                ;plx
                lda     TABLE,X                   ; GET PHYSICAL BSECTR NUMBER
                sta     BSECTR                    ; AND SET FOR BOOT PROM READ
                
                lda     LOADADDR+1                ; GET LOAD ADDRESS
                sta     POINTA+1                  ; FOR BSECTR READ
                dec     LOADADDR+1                ; MOVE LOAD ADDRESS DOWN A PAGE
                ldx     BSLOT                     ; RESTORE BSLOT NUMBER                     
                jmp     (BTEMP)                   ; Call ROM to load more sectors
LOAD_SML_SECT
                lda     #$41                      ; boot2 4000 - 41ff
                sta     LOADADDR+1
                ldx     #$0A                      ; boot2 commence  9 - a
                stx     CURRSECTOR
                dec     CURRSECTOR
                ;brk
                jmp     PREP_CALL

START_PRG       ;jsr     BEEP
                brk
                jmp     PRGJMP                    ; OFF TO LOOADER!

INIT_DISP
                jsr     CLRSCR

                ;LDA     #$11                      ; Switch off 80 Col mode  TO BE TESTED
                ;JSR     $FDED
                ;ldx     $C00C                      ; 80 Col soft switch (off)
                
                ldx     #$0E
                ldy     #$00    
                jsr     dispPositionCursor

                ldx     #$FF                      ; Normal charset
                stx     zpDispMask                ; store to zeropage       
                
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

                ldy     #$14    
                jsr     dispPositionCursor
                
                ldy     #$28
                jsr     dispLine

                ldx     #$00
                ldy     #$00    
                jsr     dispPositionCursor

                rts

;dispHexByte
;	PHA
;        pha
;	LSR A
;	LSR A
;	LSR A
;	LSR A
;	JSR _printByteHex
;	PLA
;	AND #$0F
;	JSR _printByteHex
 ;       pla
;	RTS

;_printByteHex
;	CMP #10
;	BCC _digit
;	ADC #6        ; ajustement A-F
;_digit
;	adc #'0'
;	jsr COUT1
;	RTS

_title       
                asc     "S"
                dfb     $00
_version
                asc     VERSION
                dfb     $00 
keypress
                lda     KYBD
                cmp     #$80
                bcc     keypress
                sta     STROBE
                rts
;*  TABLE OF PHYSICAL BSECTR NUMBERS
;*  WHICH CORRESPOND TO THE LOGICAL
;*  BSECTRS 0-F ON TRACK ZERO...

TABLE
                dfb     00,13,11                  ; 00->00,01->13,02->11
                dfb     09,07,05                  ; 03->09,04->07;05->05
                dfb     03,01,14                  ; 06->03,07->01,08->14
                dfb     12,10,08                  ; 09->12,10->10,11->08
                dfb     06,04,02,15               ; 12->6,13->04,14->02,15->15
CURRSECTOR      dfb     START_SECTOR              ; 10 sectors to be loaded
READ_SECTORS    dfb     0                         ; Total sector Read
LOADADDR        dfb     $00,RWTS_LOC_HI

                put     main_T0S0_disp.s          ; Load additionnal disp routine
END             EQU     *
                ds      $800+256-END,$0           ; padding to make it 256 (1 sector)

; Everything below this line should start at $900

