.include "libSFX.i"

.define setpos(ypos, xpos) ldy #($40*(ypos))+(2*(xpos))
.macro print ypos, xpos, str
	setpos(ypos, xpos)
	ldx #.loword(str)
	jsr PrintString
.endmac

.global Tilemap
.global PrintString, PrintByte
