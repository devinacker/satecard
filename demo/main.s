.include "global.i"
.include "driver.i"

;-------------------------------------------------------------------------------
.zeropage

TextPos: .res 2

;-------------------------------------------------------------------------------
.segment "LORAM"

Tilemap: .res 32*32*2
SectorBuffer: .res SECTOR_SIZE

;-------------------------------------------------------------------------------
.segment "RODATA"
incbin	FontTiles, "data/font.png.tiles.lz4"
incbin	FontPalette, "data/font.png.palette"

;      12345678901234567890123456789012"
TitleStr:
.byte "SateCard driver test v0.1",10,10,0

FoundCard:
.byte "Card detected successfully!",10,0 

DeviceConfig:
.byte "Device config word: ",0
DeviceModel:
.byte "CF card model: ",0
DeviceSerial:
.byte "Serial #: ",0
DeviceFirmware:
.byte "Firmware rev.: ",0
TotalCapacity:
.byte "Total sector count: ",0

NoBootSector:
.byte "No boot sector found.",10,0

Partition1:
.byte "Partition 1:",10,0
Partition2:
.byte "Partition 2:",10,0
Partition3:
.byte "Partition 3:",10,0
Partition4:
.byte "Partition 4:",10,0
UnusedPartition:
.byte "  Unused",10,0
BootPartition:
.byte "  Boot partition",10,0
PartitionStart:
.byte "  Start: ",0
PartitionSize:
.byte "Size: ", 0

;-------------------------------------------------------------------------------
.segment "CODE"

VRAM_TILEMAP       = $0000
VRAM_CHARSET       = $2000

proc Main
	; decompress and load font
	LZ4_decompress FontTiles, EXRAM, y
	VRAM_memcpy VRAM_CHARSET, EXRAM, y
	CGRAM_memcpy 0, FontPalette, sizeof_FontPalette
	
	; set background color
	CGRAM_setcolor_rgb 0, 0,0,0
		
	; set up screen (mode 0, all 8x8 tiles)
	lda #bgmode(BG_MODE_0, BG3_PRIO_NORMAL, BG_SIZE_8X8, BG_SIZE_8X8, BG_SIZE_8X8, BG_SIZE_8X8)
	sta BGMODE
	; set up layer 1 (with 1x1 playfield)
	lda #bgsc(VRAM_TILEMAP, SC_SIZE_32X32)
	sta BG1SC
	
	; set up tileset
	ldx #bgnba(VRAM_CHARSET, 0, 0, 0)
	stx BG12NBA
	
	; enable layer 1 only
	lda #tm(ON, OFF, OFF, OFF, OFF)
	sta TM
	
	; turn on screen
	lda #inidisp(ON, DISP_BRIGHTNESS_MAX)
	sta SFX_inidisp
	WAIT_vbl

	; enable joypad polling
	lda #$01
	sta SFX_nmitimen

	VBL_set VBL
	VBL_on

	print 1, 0, TitleStr
	sty z:TextPos
	
	break
	jsl CardDetect
	ldy z:TextPos
	bcc :+
	jsr PrintString
	brl @end
	
:	ldx #.loword(FoundCard)
	jsr PrintString
	sty z:TextPos

	jsl CardLEDEnable
	
	; attempt to read out the card info buffer here
	ldx #.loword(SectorBuffer)
	stx z:CardRWBuffer
	lda #^SectorBuffer
	sta z:CardRWBuffer+2
	
	jsl CardReadInfo
	ldy z:TextPos
	bcc :+
	jsr PrintString
	brl @end
	
	; so far so good...check the configuration word
:	ldx #.loword(DeviceConfig)
	jsr PrintString
	lda SectorBuffer+1
	jsr PrintByte
	lda SectorBuffer+0
	jsr PrintByte
	jsr Newline
	
	ldx #.loword(DeviceModel)
	jsr PrintString
	ldx #.loword(SectorBuffer)+54
	lda #40
	jsr PrintSwappedString
	jsr Newline
	
	ldx #.loword(DeviceSerial)
	jsr PrintString
	ldx #0
	ldx #.loword(SectorBuffer)+20
	lda #20
	jsr PrintSwappedString
	jsr Newline
	
	ldx #.loword(DeviceFirmware)
	jsr PrintString
	ldx #0
	ldx #.loword(SectorBuffer)+46
	lda #8
	jsr PrintSwappedString
	jsr Newline
	
	ldx #.loword(TotalCapacity)
	jsr PrintString
	lda SectorBuffer+15
	jsr PrintByte
	lda SectorBuffer+14
	jsr PrintByte
	lda SectorBuffer+17
	jsr PrintByte
	lda SectorBuffer+16
	jsr PrintByte
	jsr Newline
	
	jsr Newline
	sty z:TextPos
	; try to read boot sector (LBA #0)
	; TODO: make this a macro
	lda #1
	ldx #0
	txy
	jsl CardReadSectors
	ldy z:TextPos
	bcc :+
	jsr PrintString
	bra @end
	
:	; boot sector read OK... see if it's valid
	ldx SectorBuffer+SECTOR_SIZE-2
	cpx #$aa55
	beq :+
	ldx #.loword(NoBootSector)
	jsr PrintString
	bra @end
	
:	; start reading partition info
	ldx #.loword(Partition1)
	jsr PrintString
	ldx #0
	jsr ReadPartitionInfo
	
	ldx #.loword(Partition2)
	jsr PrintString
	ldx #16
	jsr ReadPartitionInfo
	
	ldx #.loword(Partition3)
	jsr PrintString
	ldx #32
	jsr ReadPartitionInfo
	
	ldx #.loword(Partition4)
	jsr PrintString
	ldx #48
	jsr ReadPartitionInfo
	
@end:
	bra @end
endproc

;-------------------------------------------------------------------------------
proc PrintSwappedString
	size = ZPAD
	sta z:size
	stz z:size+1
:	lda a:1,x
	sta Tilemap,y
	iny
	iny
	dec z:size
	beq :+
	lda a:0,x
	sta Tilemap,y
	iny
	iny
	inx
	inx
	dec z:size
	bne :-
:	rts
endproc

;-------------------------------------------------------------------------------
proc ReadPartitionInfo
	; check partition type
	lda SectorBuffer+450,x
	bne :+
	ldx #.loword(UnusedPartition)
	jsr PrintString
	rts
	
:	; check boot flag
	lda SectorBuffer+446,x
	bpl :+
	phx
	ldx #.loword(BootPartition)
	jsr PrintString
	plx
	
:	; get size info
	phx
	ldx #.loword(PartitionStart)
	jsr PrintString
	plx
	lda SectorBuffer+457,x
	jsr PrintByte
	lda SectorBuffer+456,x
	jsr PrintByte
	lda SectorBuffer+455,x
	jsr PrintByte
	lda SectorBuffer+454,x
	jsr PrintByte

	iny
	iny
	phx
	ldx #.loword(PartitionSize)
	jsr PrintString
	plx
	lda SectorBuffer+461,x
	jsr PrintByte
	lda SectorBuffer+460,x
	jsr PrintByte
	lda SectorBuffer+459,x
	jsr PrintByte
	lda SectorBuffer+458,x
	jsr PrintByte
;	jsr Newline

	rts
endproc

;-------------------------------------------------------------------------------
proc VBL
	VRAM_memcpy VRAM_TILEMAP, Tilemap, 32*32*2
	rtl
endproc

;-------------------------------------------------------------------------------
proc Newline
	; TODO: Handle overflow here
	RW a16
	tya
	clc
	adc #$40
	and #$ffc0
	tay
	RW a8
	rts
endproc

;-------------------------------------------------------------------------------
proc PrintString
	lda a:0,x
	beq end

	cmp #$0a
	bne :+
	jsr Newline
	inx
	bra PrintString
	
:	sta Tilemap,y
	inx
	iny
	iny
	bra PrintString
end:
	rts
endproc

;-------------------------------------------------------------------------------
ByteTbl: .byte "0123456789ABCDEF"

proc PrintByte
	phx
	xba
	lda #0
	xba
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda ByteTbl,x
	sta Tilemap,y
	iny
	lda #0
	sta Tilemap,y
	iny
	
	pla
	and #$0f
	tax
	lda ByteTbl,x
	sta Tilemap,y
	iny
	lda #0
	sta Tilemap,y
	iny
	
	plx
	rts
endproc
