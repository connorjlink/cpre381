main:
	ori s0, x0, 0x123 # $00 : 12306413 
	j skip            # $04 : 0080006f
	li s0, 0xffffffff # $08 : fff00413
skip:
	ori s1, x0, 0x123 # $0C : 12306493
	beq s0, s1, skip2 # $10 : 00940463
	li s0, 0xffffffff # $14 : fff00413
skip2:
	jal fun           # $18 : 014000ef
	ori s3, x0, 0x123 # $1C : 12306993
	beq s0, x0, exit  # $20 : 00040a63
	ori s4, x0, 0x123 # $24 : 12306a13
	j exit            # $28 : 00c0006f
fun:
	ori s2, x0, 0x123 # $2C : 12306913
	jr ra             # $30 : 00008067
exit:
	ebreak            # $34 : 00100073

