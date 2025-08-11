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
                TYP      BIN
                MX       %11

                ORG      $800
                xc
                xc

VERSION         EQU      "v0.37"

START           EQU      *
POINTA          EQU      $26
BSLOT           EQU      $2B                      ; Boot slot
BSECTR          EQU      $3D                      ; LAST BSECTR READ
BTEMP           EQU      $3E                      ; ADDRESS BTEMP
BRETRY          EQU      $5C                      ; OFFSET TO READER
START_SECTOR    EQU      $08                      ; First sector to read moving downward
END_SECTOR      EQU      $00                      ; Last sector to read
PRGJMP          EQU      $4000                    ; After the sector copy to memory, jmp to program entry point
RWTS_LOC_HI     EQU      $BF                      ; High adress of RWTS target location ($BF00)

                dfb     01                        ; <!> Needed by thre boot rom
                lda     CURRSECTOR                ; Sector to be loaded 
                cmp     #$08                      ; 08 means we are at the begining and we starts by init the display
                bne     C1
                jsr     INIT_DISP                 ; Display the screen mask and then load the sectors
C1
                lda     POINTA+1                  ; WHERE DID BSECTR GET LOADED?
                cmp     #09                       ; (AT 0800)?
                bne     READNEXT                  ; =>NO. WE'RE LOADING SOMETHING
;
                lda     BSLOT                     ; GET BOOT BSLOT
                lsr     A                         ; CONVERT TO CX00
                lsr     A
                lsr     A
                lsr     A
                ora     #$C0
                sta     BTEMP+1
                lda     #BRETRY                   ; PROM ROUTINE OFFSET
                sta     BTEMP

READNEXT                                          ;
               
                ldx     READ_SECTOR
                cpx     #$0F                      ; check if sector from 0E -> 09 is done
                beq     START_PRG                 ; then jump smartloader
                INC     READ_SECTOR
                ldx     CURRSECTOR
                cpx     #END_SECTOR               ; finish DOS RWTS ? 
                beq     LOAD_SML_SECT             ; if yes then load smartloader sectors
                
                dec     CURRSECTOR                ; ONE LESS BELL TO ANSWER..

PREP_CALL                                         ; Preparation call for ROM Call to load sectors 
                lda     TABLE,X                   ; GET PHYSICAL BSECTR NUMBER
                sta     BSECTR                    ; AND SET FOR BOOT PROM READ
                
                lda     LOADADDR+1                ; GET LOAD ADDRESS
                sta     POINTA+1                  ; FOR BSECTR READ
                dec     LOADADDR+1                ; MOVE LOAD ADDRESS DOWN A PAGE
                ldx     BSLOT                     ; RESTORE BSLOT NUMBER
                lda     CURRSECTOR
                
                jmp     (BTEMP)                   ; Call ROM to load more sectors
LOAD_SML_SECT                                          
                lda     #$46
                sta     LOADADDR+1
                ldx     #$0E
                stx     CURRSECTOR
                jmp     PREP_CALL

START_PRG
                jmp     PRGJMP                    ; OFF TO LOOADER!

INIT_DISP
                jsr     CLRSCR
                
                ldx     #$0F
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

                rts
_title       
                asc     "SMARTLOADER"
                dfb     $00
_version
                asc     VERSION
                dfb     $00 

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
READ_SECTOR     dfb     0                         ; Total sector Read
LOADADDR        dfb     $00,RWTS_LOC_HI

                put     main_T0S0_disp.s          ; Load additionnal disp routine
END             EQU     *
                ds      $800+256-END,$0           ; padding to make it 256 (1 sector)

; Everything below this line should start at $900

