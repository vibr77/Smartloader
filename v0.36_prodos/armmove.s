armmove
	lda	#$00
	sta	FLAG					; initialize flag
	lda	CURTRK					; get current track
	sec
	sbc DESTRK					; substract destination track
	beq done					; if equal do nothing exit
	bcs ok						; positive result yes go on
	eor	#$FF				; make result positive
	adc #$01					;
ok
	sta DELTA					; save result
	rol FLAG					; set in/out flag
	lsr CURTRK					; ON ODD or EVEN Track
	rol FLAG					; put result in FLAG
	asl FLAG					; Adjust for table offset
	ldy FLAG					; get offset table
loop
	lda table,y 				; get phase to turn on
	jsr phase					; 
	lda table+1,y 				; get next phase to turn on
	jsr phase				
	tya							;
	eor #$02					; adjust offset
	tay							;
	dec DELTA					; decrement number of track
	lda DELTA					;
	bne loop					; if not done do another update
	lda DESTRK
	sta CURTRK
done
	rts
phase
	ora diskSlot					; add slot to phase
	tax							;
	LDA DRVSM1,x 				; turn on phase
	jsr wait 					; wait arm to settle
	lda DRVSM0,x 				; turn off phase
	rts
wait
	lda #$56					; delay 20 ms
	jsr DELAY					; DELAY EQU $FCA8
	rts
table
	dfb $02,$04,$06,$00
	dfb $06,$04,$02,$00

DRVSM0	EQU	$C080
DRVSM1	EQU	$C081


CURTRK 	dfb $00
DESTRK	dfb $00
DELTA	dfb $00
FLAG	dfb	$00
DELAY	EQU	$FCA8

