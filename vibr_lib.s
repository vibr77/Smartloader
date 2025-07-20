

calc_1_low      EQU $90
calc_1_high     EQU $91

calc_2_low      EQU $92
calc_2_high     EQU $93

calc_result_low      EQU $94         ;
calc_result_high     EQU $95         ;


hex2dec    
    LDX    #0    ; en A le nombre en hexadécimal
    LDY    #0
    CMP    #200    ; j'ajoute la gestion de 200
    BCC    hexCENTAINE
    INX        ; 240 - 100 = 140
    SBC    #100    ; c'est voulu pour passer une fois après
hexCENTAINE    
    CMP    #100
    BCC    hexDIZAINE
    INX
    SBC    #100
    BNE    hexCENTAINE
hexDIZAINE    
    CMP    #10
    BCC    hexEND
    INY
    SBC    #10
    BNE    hexDIZAINE
hexEND
    RTS



add16test
            lda #$02                    ; adding 02FF & 00EE => should give 
            sta calc_1_high
            
            lda #$ff
            sta calc_1_low

            lda #$00
            sta calc_2_high
            
            lda #$ee
            sta calc_2_low

            jsr add_16B_16B
            jsr readKey
            rts

mul8test
            lda #$02                    ; adding 02FF & 00EE => should give 
            sta calc_1_low

            lda #$ff
            sta calc_2_low

            jsr mult_8B_8B
            
            jsr readKey

            rts





add_8B_8B
        clc                     ;
        lda calc_1_low
        adc calc_2_low
        
        sta calc_result_low
        lda calc_result_high
        adc #$00
        sta calc_result_high
        rts

add_16B_16B
        clc
        lda calc_1_low
        adc calc_2_low
        
        sta calc_result_low
        
        lda calc_1_high
        adc calc_2_high
        
        sta calc_result_high
        rts




; ***************************************************************************************
; On Entry:
;   factor1: multiplier
;   factor2: multiplicand
; On Exit:
;   factor1: low byte of product
;   A:       high byte of product
mult_8B_8B
    lda #0
    ldx #8
    lsr calc_1_low

mult_8B_8B_loop
    bcc mult_8B_8B_noadd
    clc
    adc calc_2_low
mult_8B_8B_noadd
    ror
    ror calc_1_low

    dex
    bne mult_8B_8B_loop
    sta calc_result_high
    lda calc_1_low
    sta calc_result_low
;    sta factor2
    rts