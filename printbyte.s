dispByte
	PHA
	LSR A
	LSR A
	LSR A
	LSR A
	JSR _printHex
	PLA
	AND #$0F
	JSR _printHex
	RTS

_printHex
	CMP #10
	BCC _digit
	ADC #6        ; ajustement A-F
_digit
	adc #'0'
	jsr COUT1
	RTS


