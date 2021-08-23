;@ ASM header for the K005849/K005885 emulator
;@

/** \brief  Game screen height in pixels */
#define GAME_HEIGHT (224)
/** \brief  Game screen width in pixels */
#define GAME_WIDTH  (256)

	.equ BGSRCTILECOUNTBITS,	13
	.equ BGDSTTILECOUNTBITS,	10
	.equ BGGROUPTILECOUNTBITS,	4
	.equ BGBLOCKCOUNT,			(1<<(BGSRCTILECOUNTBITS - BGGROUPTILECOUNTBITS))
	.equ BGTILESIZEBITS,		5

	.equ SPRSRCTILECOUNTBITS,	13
	.equ SPRDSTTILECOUNTBITS,	10
	.equ SPRGROUPTILECOUNTBITS,	4
	.equ SPRBLOCKCOUNT,			(1<<(SPRSRCTILECOUNTBITS - SPRGROUPTILECOUNTBITS))
	.equ SPRTILESIZEBITS,		5

	koptr		.req r12
						;@ K005849.s
	.struct 0
scanline:		.long 0			;@ These 3 must be first in state.
nextLineChange:	.long 0
lineState:		.long 0

periodicIrqFunc:.long 0			;@
frameIrqFunc:	.long 0
frame2IrqFunc:	.long 0

k005849State:					;@
zRAM1:			.space 0x20
zRAM2:			.space 0x20

k005849Regs:					;@ 0-4
scrollYReg:		.byte 0			;@ 0 (Scroll Y. ofs?).
scrollXReg:		.byte 0			;@ 1 (Scroll X. ofs?).
scrollAxis:		.byte 0			;@ 2 (bit 0 Scroll X bit8?, bit 1 = use ram scroll, bit 2 = ram scroll y?), JB 0x02, 0x06. GB 0x02. MrG 0x02. IH 0x0A. FI 0x00. DD 0x02, 0x01, 0x00.
sprBank:		.byte 0			;@ 3 (005885 0x3=tilebank, 0x8=sprram), JB 0x02, 0xC2, (0xC2, 0xCA)... . GB (0x82, 0x8A)... MrG (0xA2, 0xAA)... IH (0xE2, 0xEA)... (0xE3, 0xEB)... FI 0x04. DD 0x00
irqControl:		.byte 0			;@ 4, JB 0x00 (0x00,0x01, 0x02, 0x03), IH 0x15, (0x1C, 0x1D)... DD 0x02

isIronHorse:	.byte 0
spritePaletteOffset:	.byte 0
frameOdd:		.byte 0
gfxReload:
bgMemReload:	.byte 0
sprMemReload:	.byte 0
sprPalReload:	.byte 0
koPadding1:		.space 1

bgMemAlloc:		.long 0
sprMemAlloc:	.long 0
sprPalAlloc:	.long 0

bgrRomBase:		.long 0
bgrGfxDest:		.long 0
bgrRomSize:		.long 0
bgrMask:		.long 0
spriteRomBase:	.long 0
spriteRomSize:	.long 0
spriteMask:		.long 0

dirtyTiles:		.space 4
gfxRAM:			.long 0
sprBlockLUT:	.long 0
bgBlockLUT:		.long 0

k005849Size:

;@----------------------------------------------------------------------------

