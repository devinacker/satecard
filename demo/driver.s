.include "global.i"
.include "driver.i"

;-------------------------------------------------------------------------------
.zeropage
CardRWBuffer: .res 3

;-------------------------------------------------------------------------------
.segment "RODATA"
;        12345678901234567890123456789012"
NoError:
.byte "No error",10,0

CardNotReady: 
.byte "Card not ready",10,0
DiagFailed:
.byte "Drive diagnostic failed",10,0
No8BitSupport:
.byte "No 8-bit bus support",10,0

ErrBadBlock:
.byte "Bad block detected",10,0
ErrUncorrectable:
.byte "Uncorrectable error detected",10,0
ErrSectorNum:
.byte "Invalid sector number",10,0
ErrAborted:
.byte "Command aborted",10,0
ErrGeneral:
.byte "General error (check $21A1)",10,0

;-------------------------------------------------------------------------------
.segment "CODE"

;-------------------------------------------------------------------------------
; private
proc _CheckError
	ldx #.loword(NoError)
	clc

	lda ATA_STATUS
	and #$01
	bne :+
	rts
:	lda ATA_ERROR
	and #$d5
	bne :+
	rts
	
:	sec
	
	; bad block error
	bit #$80
	beq :+
	ldx #.loword(ErrBadBlock)
	rts
	
	; uncorrectable error
:	bit #$40
	beq :+
	ldx #.loword(ErrUncorrectable)
	rts
	
	; invalid sector error
:	bit #$10
	beq :+
	ldx #.loword(ErrSectorNum)
	rts
	
	; command aborted
:	bit #$04
	beq :+
	ldx #.loword(ErrAborted)
	rts
	
	; get extended error info (TODO: return messages for these also)
:	ldx #.loword(ErrGeneral)
	lda #$a0
	sta ATA_HEAD
	lda #$03
	sta ATA_COMMAND
	
	rts
endproc

proc CardReset
	lda #$06 ; reset card, disable interrupts
	sta ATA_CONTROL
	and #$02
	sta ATA_CONTROL
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardDetect
	; reset card
	jsl CardReset
	; wait for busy bit clear + ready bit set
:	bit ATA_STATUS
	bmi :-
	bvs :+
	ldx #.loword(CardNotReady)
	bra @fail
	
	; try "execute drive diagnostic" command
:	ldx #.loword(DiagFailed)
	stz ATA_HEAD
	lda #$90
	sta ATA_COMMAND
	lda ATA_ERROR
	cmp #$01 ; fail unless "no error" read
	bne @fail
	
	; enable 8-bit transfer
	ldx #.loword(No8BitSupport)
	lda #$01
	sta ATA_FEATURE
	lda #$ef
	sta ATA_COMMAND
	lda ATA_ERROR
	bit #$04 ; fail if 8-bit transfers not supported (should always be, though)
	bne @fail
	
	; card set up successfully
	ldx #.loword(NoError)
	clc
	rtl
	
@fail:
	sec
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardIRQEnable
	lda #$02
	trb ATA_CONTROL
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardIRQDisable
	lda #$02
	tsb ATA_CONTROL
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardLEDEnable
	lda SV_CONTROL
	and #$03
	ora #$08
	sta SV_CONTROL
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardLEDDisable
	lda #$0c
	trb SV_CONTROL
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardReadInfo
	stz ATA_HEAD
	lda #$ec
	sta ATA_COMMAND
:	bit ATA_STATUS
	bmi :-
	jsr _CheckError
	bcs @end
	
	; TODO: replace with DMA read later
	ldx #SECTOR_SIZE-1
	ldy #0
:	lda ATA_DATA
	sta [CardRWBuffer],y
	iny
	dex
	bpl :-
	
	ldx #.loword(NoError)
@end:
	rtl
endproc

;-------------------------------------------------------------------------------
proc CardReadSectors
	sta ATA_SECCOUNT
	stx ATA_SECTOR
	sty ATA_CYLINDERH
	lda #$e0 ; set LBA mode
	tsb ATA_HEAD
	
	lda #$20
	sta ATA_COMMAND
	ldy #0
@sec:
:	bit ATA_STATUS
	bmi :-
	jsr _CheckError
	bcs @fail
	
	; TODO: replace with DMA read later
	ldx #SECTOR_SIZE-1
:	lda ATA_DATA
	sta [CardRWBuffer],y
	iny
	bne :+
	inc z:CardRWBuffer+2
:	dex
	bpl :--
	
	lda ATA_SECCOUNT
	bne @sec
	
	ldx #.loword(NoError)
	clc
@fail:
	rtl
endproc
