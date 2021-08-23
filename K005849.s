// Konami 005849/005885 Video Chip emulation

#ifdef __arm__

#ifdef GBA
#include "../Shared/gba_asm.h"
#elif NDS
#include "../Shared/nds_asm.h"
#endif
#include "../Equates.h"
#include "K005849.i"

	.global k005849Reset
	.global k005849SaveState
	.global k005849LoadState
	.global k005849GetStateSize
	.global convertTiles5849
	.global convertTiles5885
	.global addBackgroundTiles
	.global doScanline
	.global copyScrollValues
	.global convertTileMap5849
	.global convertTileMap5885
	.global convertTileMapJackal
	.global convertTileMapDD
	.global convertTileMapDDFG
	.global convertSprites5849
	.global convertSprites5885
	.global k005849Ram_R
	.global k005849Ram_W
	.global k005885Ram_R
	.global k005885Ram_W
	.global k005849_R
	.global k005849_W
	.global k005885_R
	.global k005885_W


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
k005849Reset:		;@ r0=NMI(periodicIrqFunc), r1=IRQ(frameIrqFunc), r2=FIRQ(frame2IrqFunc), r3=ram+LUTs
;@----------------------------------------------------------------------------
	stmfd sp!,{r0-r3,lr}

	mov r0,koptr
	ldr r1,=k005849Size/4
	bl memclr_						;@ Clear VDP state

	ldr r2,=lineStateTable
	ldr r1,[r2],#4
	mov r0,#-1
	stmia koptr,{r0-r2}				;@ Reset scanline, nextChange & lineState

//	mov r0,#-1
	str r0,[koptr,#gfxReload]
	ldr r0,=0x0FF					;@ Double Dribble requires 0x1FF
	str r0,[koptr,#spriteMask]

	ldmfd sp!,{r0-r3,lr}
	cmp r0,#0
	adreq r0,dummyIrqFunc
	cmp r1,#0
	adreq r1,dummyIrqFunc
	cmp r2,#0
	adreq r2,dummyIrqFunc

	str r0,[koptr,#periodicIrqFunc]
	str r1,[koptr,#frameIrqFunc]
	str r2,[koptr,#frame2IrqFunc]

	str r3,[koptr,#gfxRAM]
	add r3,r3,#0x2000
	str r3,[koptr,#sprBlockLUT]
	add r3,r3,#SPRBLOCKCOUNT*4
	str r3,[koptr,#bgBlockLUT]

dummyIrqFunc:
	bx lr

;@----------------------------------------------------------------------------
k005849SaveState:		;@ In r0=destination, r1=koptr. Out r0=state size.
	.type   k005849SaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r4,r0				;@ Store destination
	mov r5,r1				;@ Store koptr (r1)

	ldr r1,[r5,#gfxRAM]
	mov r2,#0x2000
	bl memcpy

	add r0,r4,#0x2000
	add r1,r5,#k005849State
	mov r2,#0x48
	bl memcpy

	ldmfd sp!,{r4,r5,lr}
	ldr r0,=0x2048
	bx lr
;@----------------------------------------------------------------------------
k005849LoadState:		;@ In r0=koptr, r1=source. Out r0=state size.
	.type   k005849LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r5,r0				;@ Store koptr (r0)
	mov r4,r1				;@ Store source

	ldr r0,[r5,#gfxRAM]
	mov r2,#0x2000
	bl memcpy

	add r0,r5,#k005849State
	add r1,r4,#0x2000
	mov r2,#0x48
	bl memcpy

	mov r0,#-1
	str r0,[r5,#gfxReload]

	mov koptr,r5
	bl endFrame
	ldmfd sp!,{r4,r5,lr}
;@----------------------------------------------------------------------------
k005849GetStateSize:	;@ Out r0=state size.
	.type   k005849GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=0x2048
	bx lr

;@----------------------------------------------------------------------------
convertTiles5849:			;@ r0 = destination, r1 = source, r2 = length.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldr lr,=0x0F0F0F0F
bgChr5849:
	ldr r3,[r1],#4				;@ Read graphics
	and r4,lr,r3,lsr#4
	and r3,lr,r3
	orr r3,r4,r3,lsl#4
	str r3,[r0],#4

	subs r2,r2,#4
	bne bgChr5849

	ldmfd sp!,{r4,lr}
	bx lr
;@----------------------------------------------------------------------------
convertTiles5885:			;@ r0 = dest, r1 = src1, r2 = src2, r3 = length.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	ldr lr,=0x0F0F0F0F
bgChr5885:
	ldrb r4,[r1],#1
	ldrb r5,[r2],#1
	orr r4,r4,r5,lsl#8
	ldrb r5,[r1],#1
	orr r4,r4,r5,lsl#16
	ldrb r5,[r2],#1
	orr r4,r4,r5,lsl#24

	and r5,lr,r4,lsr#4
	and r4,lr,r4
	orr r4,r5,r4,lsl#4
	str r4,[r0],#4

	subs r3,r3,#4
	bne bgChr5885

	ldmfd sp!,{r4-r5,lr}
	bx lr
;@----------------------------------------------------------------------------
addBackgroundTiles:			;@ r0 = dest.
;@----------------------------------------------------------------------------
	ldr r1,=0x10101010
	mov r3,#0
bgChrLoop2:
	mov r2,#16
bgChrLoop1:
	str r3,[r0],#4
	subs r2,r2,#1
	bne bgChrLoop1
	adds r3,r3,r1
	bcc bgChrLoop2
	bx lr

;@----------------------------------------------------------------------------
#ifdef GBA
	.section .ewram,"ax"
#endif
;@----------------------------------------------------------------------------
k005849Ram_R:				;@ Ram read (0x0000-0x1FFF)
;@----------------------------------------------------------------------------
k005885Ram_R:				;@ Ram read (0x2000-0x3FFF)
;@----------------------------------------------------------------------------
	bic r1,r1,#0xFE000
	ldr r2,[koptr,#gfxRAM]
	ldrb r0,[r2,r1]
	bx lr
;@----------------------------------------------------------------------------
k005849_R:					;@ I/O read (0x2000-0x2044)
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	bic r2,r1,#0xFE000
	cmp r2,#0x45
	bmi Scrl_R
	b empty_IO_R
;@----------------------------------------------------------------------------
k005885_R:					;@ I/O read (0x0000-0x005F)
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	bic r2,r1,#0xFE000
	cmp r2,#0x05
	bmi registersR
	cmp r2,#0x60
	bpl empty_IO_R
	subs r2,r2,#0x20
	bmi empty_IO_R
//	b Scrl_R
;@----------------------------------------------------------------------------
Scrl_R:
;@----------------------------------------------------------------------------
	add r1,koptr,#zRAM1
	ldrb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
registersR:
;@----------------------------------------------------------------------------
	and r2,r2,#0x07
	add r1,koptr,#k005849Regs
	ldrb r0,[r1,r2]
	bx lr



;@----------------------------------------------------------------------------
k005849Ram_W:				;@ Ram write (0x0000-0x1FFF)
;@----------------------------------------------------------------------------
k005885Ram_W:				;@ Ram write (0x2000-0x3FFF)
;@----------------------------------------------------------------------------
	bic r1,r1,#0xFE000
	ldr r2,[koptr,#gfxRAM]
	strb r0,[r2,r1]
	mvn r1,r1,asr#11
	add r2,koptr,#gfxRAM
	strb r1,[r2,r1]
	bx lr
;@----------------------------------------------------------------------------
k005849_W:					;@ I/O write (0x2000-0x2044)
;@----------------------------------------------------------------------------
	bic r2,r1,#0xFE000
	cmp r2,#0x40
	bmi scrollRAMW
	beq scrollYW
	cmp r2,#0x41
	beq scrollXW
	cmp r2,#0x42
	beq scrollAxisW
	cmp r2,#0x43
	beq spriteBankW
	cmp r2,#0x44
	beq irqW
	b empty_IO_W
;@----------------------------------------------------------------------------
k005885_W:					;@ I/O write (0x0000-0x005F)
;@----------------------------------------------------------------------------
	bic r2,r1,#0xFE000
	cmp r2,#0x00
	beq scrollYW
	cmp r2,#0x01
	beq scrollXW
	cmp r2,#0x02
	beq scrollAxisW
	cmp r2,#0x03
	beq spriteBankW
	cmp r2,#0x04
	beq irqW

	cmp r2,#0x60
	bpl empty_IO_W
	subs r2,r2,#0x20
	bmi empty_IO_W
//	b scrollRAMW
;@----------------------------------------------------------------------------
scrollRAMW:
;@----------------------------------------------------------------------------
	add r1,koptr,#zRAM1
	strb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
scrollYW:			;@ Register 0
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	strb r0,[koptr,#scrollYReg]
	bx lr
;@----------------------------------------------------------------------------
scrollXW:			;@ Register 1
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	strb r0,[koptr,#scrollXReg]
	bx lr
;@----------------------------------------------------------------------------
scrollAxisW:		;@ Register 2
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	strb r0,[koptr,#scrollAxis]
	bx lr
;@----------------------------------------------------------------------------
spriteBankW:		;@ Register 3
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	strb r0,[koptr,#sprBank]
	bx lr

;@----------------------------------------------------------------------------
irqW:				;@ Register 4
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{r4,lr}
	strb r0,[koptr,#irqControl]
	mov r4,r0
	ands r0,r4,#4
	moveq lr,pc
	ldreq pc,[koptr,#frame2IrqFunc]
	ands r0,r4,#2
	moveq lr,pc
	ldreq pc,[koptr,#frameIrqFunc]
	ands r0,r4,#1
	moveq lr,pc
	ldreq pc,[koptr,#periodicIrqFunc]
	ldmfd sp!,{r4,lr}

//	tst r0,#0x08				;@ Screen flip bit
//	tst r0,#0x10				;@ Scanline timer 64 instead of 32

	bx lr

;@----------------------------------------------------------------------------
checkTileReload:
;@----------------------------------------------------------------------------
	ldr r9,[koptr,#bgBlockLUT]
	ldrb r0,[koptr,#bgMemReload]
	cmp r0,#0
	bxeq lr
	mov r0,#1<<(BGDSTTILECOUNTBITS-BGGROUPTILECOUNTBITS)
	str r0,[koptr,#bgMemAlloc]
	mov r1,#1<<(32-BGGROUPTILECOUNTBITS)		;@ r1=value
	strb r1,[koptr,#bgMemReload]	;@ Clear bg mem reload.
	mov r0,r9					;@ r0=destination
	mov r2,#BGBLOCKCOUNT		;@ 512 tile entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
convertTileMap5849:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	mov r6,r0					;@ Destination
	bl checkTileReload
	ldr r10,=adressTrans5849	;@ Translate bank + yx to adress
	ldrb r0,[koptr,#sprBank]
	tst r0,#0x40
	orrne r0,r0,#0x01
	and r0,r0,#0x03
	add r10,r10,r0
	ldr r8,=(((1<<(BGGROUPTILECOUNTBITS + BGTILESIZEBITS)) - 1) << 16) + (BGGROUPTILECOUNTBITS + BGTILESIZEBITS)

	ldrh r0,[koptr,#dirtyTiles+2]	;@ Check dirty map, this should be +0.
	cmp r0,#0
	beq noChange
	mov r0,#0
	strh r0,[koptr,#dirtyTiles+2]
	ldr r4,[koptr,#gfxRAM]
	ldrb r0,[koptr,#irqControl]
	tst r0,#0x08				;@ Screen flip bit
	bne flippedTileMap5849

	ldr r3,=0x20000008			;@ Row modulo + tile vs color map offset
	mov r11,#0x01000000			;@ Increase read
	bl bgrMapRender
	sub r4,r4,#0x800-0x20
	bl bgrMapRender
noChange:
	ldmfd sp!,{r3-r11,pc}

flippedTileMap5849:
	ldr r3,=0xE0000008			;@ Row modulo + tile vs color map offset
	ldr r11,=0xFF000C00			;@ Decrease read, XY-flip
	sub r4,r4,#1
	add r4,r4,#0x800-0x20
	bl bgrMapRender
	add r4,r4,#0x800+0x20
	bl bgrMapRender
	ldmfd sp!,{r3-r11,pc}

;@----------------------------------------------------------------------------
convertTileMap5885:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	ldrb r1,[koptr,#isIronHorse]
	cmp r1,#0
	ldreq r10,=adressTrans5885		;@ Translate bank + yx to adress
	ldrne r10,=adressTransIronHorse	;@ Translate bank + yx to adress
	ldr r8,=(((1<<(BGGROUPTILECOUNTBITS + BGTILESIZEBITS)) - 1) << 16) + (BGGROUPTILECOUNTBITS + BGTILESIZEBITS)
	mov r11,#0
	b startTileMap
;@----------------------------------------------------------------------------
convertTileMapDD:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	ldr r10,=adressTransDD		;@ Translate bank + yx to adress
	ldr r8,=(((1<<(BGGROUPTILECOUNTBITS + BGTILESIZEBITS)) - 1) << 16) + (BGGROUPTILECOUNTBITS + BGTILESIZEBITS)
	mov r11,#0
	b startTileMap
;@----------------------------------------------------------------------------
convertTileMapDDFG:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	ldr r10,=adressTransDDFG	;@ Translate bank + yx to adress
	ldr r8,=(((1<<(BGGROUPTILECOUNTBITS + BGTILESIZEBITS)) - 1) << 16) + (BGGROUPTILECOUNTBITS + BGTILESIZEBITS)
	mov r11,#0x3000				;@ Palette ofs
	b startTileMap
;@----------------------------------------------------------------------------
convertTileMapJackal:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	ldr r10,=adressTransJackal	;@ Translate bank + yx to adress
	ldr r8,=(((1<<(BGGROUPTILECOUNTBITS + BGTILESIZEBITS + 1)) - 1) << 16) + (BGGROUPTILECOUNTBITS + BGTILESIZEBITS + 1)
	mov r11,#0
;@----------------------------------------------------------------------------
startTileMap:
	mov r6,r0					;@ Destination
	bl checkTileReload
	ldrb r0,[koptr,#sprBank]
	and r0,r0,#0x03
	add r10,r10,r0
	ldr r3,=0x00000004			;@ Row modulo + tile vs color map offset

	ldr r4,[koptr,#gfxRAM]
	ldrb r0,[koptr,#irqControl]
	tst r0,#0x08				;@ Screen flip bit
	bne flippedTileMap5885

	orr r11,r11,#0x01000000		;@ Increase read
	bl bgrMapRender
	ldrb r0,[koptr,#sprBank]
//	tst r0,#0x80				;@ Screen width 240/256? Tilemap width 256/512?
//	tst r0,#0x04				;@ Is left/right overlay on?
	eor r0,r0,#0x80
	tst r0,#0x84

	add r4,r4,#0x400
	blne bgrMapRender
	ldmfd sp!,{r3-r11,pc}

flippedTileMap5885:
	orr r11,r11,#0xFF000000		;@ Decrease read
	orr r11,r11,#0x00000C00
	add r4,r4,#0x400
	sub r4,r4,#1
	bl bgrMapRender

	ldrb r0,[koptr,#sprBank]
//	tst r0,#0x80				;@ Screen width 240/256? Tilemap width 256/512?
//	tst r0,#0x04				;@ Is left/right overlay on?
	eor r0,r0,#0x80
	tst r0,#0x84

	add r4,r4,#0xC00
	blne bgrMapRender

	ldmfd sp!,{r3-r11,pc}

;@----------------------------------------------------------------------------
;@ yxbb,
;@----------------------------------------------------------------------------
adressTrans5849:
	.byte 0x00, 0x04, 0x08, 0x08
	.byte 0x00, 0x04, 0x08, 0x08
	.byte 0x00, 0x04, 0x08, 0x08
	.byte 0x00, 0x04, 0x08, 0x08
	.byte 0x01, 0x05, 0x09, 0x09
	.byte 0x01, 0x05, 0x09, 0x09
	.byte 0x01, 0x05, 0x09, 0x09
	.byte 0x01, 0x05, 0x09, 0x09
	.byte 0x02, 0x06, 0x08, 0x0A
	.byte 0x02, 0x06, 0x08, 0x0A
	.byte 0x02, 0x06, 0x08, 0x0A
	.byte 0x02, 0x06, 0x08, 0x0A
	.byte 0x03, 0x07, 0x09, 0x0B
	.byte 0x03, 0x07, 0x09, 0x0B
	.byte 0x03, 0x07, 0x09, 0x0B
	.byte 0x03, 0x07, 0x09, 0x0B
adressTrans5885:
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
adressTransIronHorse:
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x03, 0x07, 0x0B, 0x0F
adressTransJackal:
	.byte 0x00, 0x04, 0x08, 0x0C
	.byte 0x04, 0x04, 0x0C, 0x0C
	.byte 0x08, 0x0C, 0x08, 0x0C
	.byte 0x0C, 0x0C, 0x0C, 0x0C
	.byte 0x01, 0x05, 0x09, 0x0D
	.byte 0x05, 0x05, 0x0D, 0x0D
	.byte 0x09, 0x0D, 0x09, 0x0D
	.byte 0x0D, 0x0D, 0x0D, 0x0D
	.byte 0x02, 0x06, 0x0A, 0x0E
	.byte 0x06, 0x06, 0x0E, 0x0E
	.byte 0x0A, 0x0E, 0x0A, 0x0E
	.byte 0x0E, 0x0E, 0x0E, 0x0E
	.byte 0x03, 0x07, 0x0B, 0x0F
	.byte 0x07, 0x07, 0x0F, 0x0F
	.byte 0x0B, 0x0F, 0x0B, 0x0F
	.byte 0x0F, 0x0F, 0x0F, 0x0F
adressTransDD:
	.byte 0x00, 0x08, 0x10, 0x18
	.byte 0x00, 0x08, 0x10, 0x18
	.byte 0x04, 0x0C, 0x14, 0x1C
	.byte 0x04, 0x0C, 0x14, 0x1C
	.byte 0x01, 0x09, 0x11, 0x19
	.byte 0x01, 0x09, 0x11, 0x19
	.byte 0x05, 0x0D, 0x15, 0x1D
	.byte 0x05, 0x0D, 0x15, 0x1D
	.byte 0x02, 0x0A, 0x12, 0x1A
	.byte 0x02, 0x0A, 0x12, 0x1A
	.byte 0x06, 0x0E, 0x16, 0x1E
	.byte 0x06, 0x0E, 0x16, 0x1E
	.byte 0x03, 0x0B, 0x13, 0x1B
	.byte 0x03, 0x0B, 0x13, 0x1B
	.byte 0x07, 0x0F, 0x17, 0x1F
	.byte 0x07, 0x0F, 0x17, 0x1F
adressTransDDFG:
	.byte 0x00, 0x00, 0x08, 0x08
	.byte 0x00, 0x00, 0x08, 0x08
	.byte 0x04, 0x04, 0x0C, 0x0C
	.byte 0x04, 0x04, 0x0C, 0x0C
	.byte 0x01, 0x01, 0x09, 0x09
	.byte 0x01, 0x01, 0x09, 0x09
	.byte 0x05, 0x05, 0x0D, 0x0D
	.byte 0x05, 0x05, 0x0D, 0x0D
	.byte 0x02, 0x02, 0x0A, 0x0A
	.byte 0x02, 0x02, 0x0A, 0x0A
	.byte 0x06, 0x06, 0x0E, 0x0E
	.byte 0x06, 0x06, 0x0E, 0x0E
	.byte 0x03, 0x03, 0x0B, 0x0B
	.byte 0x03, 0x03, 0x0B, 0x0B
	.byte 0x07, 0x07, 0x0F, 0x0F
	.byte 0x07, 0x07, 0x0F, 0x0F

;@----------------------------------------------------------------------------
checkFrameIRQ:
;@----------------------------------------------------------------------------
	ldrb r1,[koptr,#irqControl]
	ands r0,r1,#2				;@ IRQ enabled? Every frame.
	stmfd sp!,{r1,lr}
	movne lr,pc
	ldrne pc,[koptr,#frameIrqFunc]
	ldmfd sp!,{r1,lr}

	ldrb r0,[koptr,#frameOdd]
	ands r0,r1,r0,lsl#2			;@ FIRQ enabled? Every other frame.
	ldrne pc,[koptr,#frame2IrqFunc]
	bx lr
;@----------------------------------------------------------------------------
frameEndHook:
	ldrb r1,[koptr,#frameOdd]
	eor r1,r1,#1
	strb r1,[koptr,#frameOdd]

	ldr r2,=lineStateTable
	ldr r1,[r2],#4
	mov r0,#0
	stmia koptr,{r0-r2}			;@ Reset scanline, nextChange & lineState

//	mov r0,#0					;@ Must return 0 to end frame.
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
newFrame:					;@ Called before line 0
;@----------------------------------------------------------------------------
//	mov r0,#0
//	str r0,[koptr,#scanline]	;@ Reset scanline count
//	strb r0,lineState			;@ Reset line state
	bx lr

;@----------------------------------------------------------------------------
lineStateTable:
	.long 0, newFrame			;@ zeroLine
	.long 239, endFrame			;@ Last visible scanline
	.long 240, checkFrameIRQ	;@ frameIRQ
	.long 256, frameEndHook		;@ totalScanlines
;@----------------------------------------------------------------------------
#ifdef GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
	.align 2
#endif
;@----------------------------------------------------------------------------
redoScanline:
;@----------------------------------------------------------------------------
	ldr r2,[koptr,#lineState]
	ldmia r2!,{r0,r1}
	stmib koptr,{r1,r2}			;@ Write nextLineChange & lineState
	stmfd sp!,{lr}
	mov lr,pc
	bx r0
	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
doScanline:
;@----------------------------------------------------------------------------
	ldmia koptr,{r0,r1}			;@ Read scanLine & nextLineChange
	cmp r0,r1
	bpl redoScanline
	add r0,r0,#1
	str r0,[koptr,#scanline]
;@----------------------------------------------------------------------------
checkScanlineIRQ:
;@----------------------------------------------------------------------------
	ands r0,r0,#0x1f			;@ NMI every 32th scanline
	bxne lr

	stmfd sp!,{lr}
	ldrb r0,[koptr,#irqControl]
	ands r0,r0,#1				;@ NMI enabled? 8 times a frame?
	movne lr,pc
	ldrne pc,[koptr,#periodicIrqFunc]

	mov r0,#1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
bgrMapRender:
	stmfd sp!,{lr}

	add r7,r6,#0x1000			;@ Background map offset
bgTrLoop1:
	ldrb r0,[r4,r3,lsl#8]		;@ Read from K005885 Tilemap RAM,  tttttttt
	ldrb r5,[r4],r11,asr#24		;@ Read from K005885 Colormap RAM, ttyxcccc -> ccccyxtt

	mov r1,r5,lsr#4				;@ YX flip
	ldrb r2,[r10,r1,lsl#2]		;@ Translate bank+YX bits to address
	orr r0,r0,r2,lsl#8

	and r5,r5,#0x0F
	orr r5,r5,r11,ror#12		;@ Color bits
	eor r5,r5,r1,lsl#30			;@ YX flip

	bl getTilesFromCache
	orr r0,r0,r5,ror#20

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	strh r5,[r7],#2				;@ Write to NDS Tilemap RAM 2 (extra bgr color)
	tst r6,#0x03E
	bne bgTrLoop1
	add r4,r4,r3,asr#24
	tst r6,#0x7C0
	bne bgTrLoop1

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
tileCacheFull:
	strb r2,[koptr,#bgMemReload]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
getTilesFromCache:			;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	mov r1,r0,lsr#BGGROUPTILECOUNTBITS		;@ Mask tile number
	and r0,r0,#(1<<BGGROUPTILECOUNTBITS)-1
	ldr r2,[r9,r1,lsl#2]		;@ Check cache, uncached = 0x10000000
	orrs r0,r0,r2,lsl#BGGROUPTILECOUNTBITS
	bxcc lr						;@ Allready cached
allocTiles:
	ldr r2,[koptr,#bgMemAlloc]
	subs r2,r2,#1
	bmi tileCacheFull
	str r2,[koptr,#bgMemAlloc]

	str r2,[r9,r1,lsl#2]
	orr r0,r0,r2,lsl#BGGROUPTILECOUNTBITS
;@----------------------------------------------------------------------------
renderTiles:
	stmfd sp!,{r0,r3-r7,r9,lr}
#ifdef ARM9
	ldrd r4,r5,[koptr,#bgrRomBase]
#else
	ldr r4,[koptr,#bgrRomBase]
	ldr r5,[koptr,#bgrGfxDest]
#endif
	add r1,r4,r1,lsl r8
	add r0,r5,r2,lsl r8

renderTilesLoop:
	ldmia r1!,{r2-r7,r9,lr}
	stmia r0!,{r2-r7,r9,lr}
	tst r0,r8,lsr#16
	bne renderTilesLoop

	ldmfd sp!,{r0,r3-r7,r9,pc}
;@----------------------------------------------------------------------------
copyScrollValues:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7}
	mov r3,#0x20
	ldrb r5,[koptr,#scrollYReg]
	ldrb r6,[koptr,#scrollXReg]
	ldrb r4,[koptr,#scrollAxis]
	and r4,r4,#0x07
	orr r6,r6,r4,lsl#8
	orr r6,r6,r5,lsl#16

	ldrb r7,[koptr,#irqControl]
	tst r7,#0x08				;@ Screen flip bit
	movne r7,#-1
	moveq r7,#1
	rsbne r6,r6,#0x1800
	add r1,koptr,#zRAM1
	addne r1,r1,#0x1F

	tst r4,#0x02				;@ Use ZRAM?
	beq setScrlLoop
	ands r2,r4,#0x04			;@ Use it for vertical scroll?
	movne r2,#0x10
cpyScrlLoop:
	ldrb r5,[r1,#0x20]
	ldrb r4,[r1],r7
	and r5,r5,#1
	orr r4,r4,r5,lsl#8
	tst r7,#0x08				;@ Screen flip bit
	addeq r4,r6,r4,lsl r2
	subne r4,r6,r4,lsl r2

	mov r5,r4
	stmia r0!,{r4,r5}
	stmia r0!,{r4,r5}
	stmia r0!,{r4,r5}
	stmia r0!,{r4,r5}
	subs r3,r3,#1
	bne cpyScrlLoop
	ldmfd sp!,{r4-r7}
	bx lr

setScrlLoop:
	mov r5,r6
	stmia r0!,{r5,r6}
	stmia r0!,{r5,r6}
	stmia r0!,{r5,r6}
	stmia r0!,{r5,r6}
	subs r3,r3,#1
	bne setScrlLoop
	ldmfd sp!,{r4-r7}
	bx lr

;@----------------------------------------------------------------------------
reloadSprites:
;@----------------------------------------------------------------------------
	mov r1,#0x40000000				;@ r1=value
	strb r1,[koptr,#sprMemReload]	;@ Clear spr mem reload.
	mov r0,r9						;@ r0=destination
	mov r2,#SPRBLOCKCOUNT			;@ 512 tile entries
	b memset_						;@ Prepare lut
;@----------------------------------------------------------------------------
	.equ PRIORITY,	0x800		;@ 0x800=AGB OBJ priority 2
;@----------------------------------------------------------------------------
convertSprites5849:			;@ in r0 = destination.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	mov r11,r0					;@ Destination
	mov r8,#48					;@ Number of sprites

	ldr r9,[koptr,#sprBlockLUT]
	ldrb r0,[koptr,#sprMemReload]
	cmp r0,#0
	blne reloadSprites

	and r4,r4,#0x08
	ldr r10,[koptr,#gfxRAM]
	add r10,r10,#0x1100			;@ This should be 0x1000 + 0x100/0
	sub r10,r10,r4,lsl#5		;@ See intro on Jail Break.

	ldr r7,=g_scaling
	ldrb r7,[r7]
	cmp r7,#UNSCALED			;@ Do autoscroll
	ldreq r7,=0x01000000		;@ No scaling
//	ldrne r7,=0x00DB6DB6		;@ 192/224, 6/7, scaling. 0xC0000000/0xE0 = 0x00DB6DB6.
//	ldrne r7,=0x00B6DB6D		;@ 160/224, 5/7, scaling. 0xA0000000/0xE0 = 0x00B6DB6D.
	ldrne r7,=(SCREEN_HEIGHT<<19)/7		;@ 192/224, 6/7, scaling. 0xC0000000/0xE0 = 0x00DB6DB6.
	mov r0,#0
	ldreq r0,=yStart			;@ First scanline?
	ldrbeq r0,[r0]
	add r6,r0,#0x08

	mov r5,#0x40000000			;@ 16x16 size
	orrne r5,r5,#0x0100			;@ Scaling

	ldrb r4,[koptr,#irqControl]
	tst r4,#0x08				;@ Flip enabled?
	orrne r5,#0x30000000		;@ Flips
	rsbne r7,r7,#0
	rsbne r6,r0,#0xE8

	add r10,r10,r8,lsl#2		;@ Begin with the last sprite
dm5:
	ldr r4,[r10,#-4]!			;@ GreenBeret OBJ, r4=Tile,Attrib,Xpos,Ypos.
	movs r0,r4,lsr#24			;@ Mask Y, check yPos 0
	beq skipSprite
	movs r1,r4,lsr#16			;@ Attrib bit7, xpos bit 8
	and r1,r1,#0xFF				;@ XPos
	orrcs r1,r1,#0x0100			;@ xpos bit 8
	tst r7,#0x80000000			;@ Is scaling negative (flip)?
	subeq r1,r1,#(GAME_WIDTH-SCREEN_WIDTH)/2
	rsbne r1,r1,#(GAME_WIDTH-16)-(GAME_WIDTH-SCREEN_WIDTH)/2			;@ Flip Xpos
	mov r1,r1,lsl#23

	sub r0,r0,r6
	mul r0,r7,r0				;@ Y scaling
	sub r0,r0,#0x07800000		;@ -8, + 0.5
	add r0,r5,r0,lsr#24			;@ YPos + size + scaling
	orr r0,r0,r1,lsr#7			;@ XPos

	and r1,r4,#0x3000			;@ X/Yflip
	eor r0,r0,r1,lsl#16
	str r0,[r11],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.

	and r0,r4,#0xFF
	and r1,r4,#0x4000
	orr r0,r0,r1,lsr#6
	mov r0,r0,lsl#2
	bl getSpriteFromCache5885	;@ Jump to spr copy, takes tile# in r0, gives new tile# in r0

	and r1,r4,#0x0F00			;@ Color
	orr r0,r0,r1,lsl#4
	orr r0,r0,#PRIORITY			;@ Priority
	strh r0,[r11],#4			;@ Store OBJ Atr 2. Pattern, prio & palette.
dm3:
	subs r8,r8,#1
	bne dm5
	ldmfd sp!,{r4-r11,pc}
skipSprite:
	mov r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
	str r0,[r11],#8
	b dm3

dm7:
	mov r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
	str r0,[r11],#8
	subs r8,r8,#1
	bne dm7
	ldmfd sp!,{r4-r11,pc}

;@----------------------------------------------------------------------------
convertSprites5885:			;@ in r0 = destination.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	mov r11,r0					;@ Destination

	ldr r9,[koptr,#sprBlockLUT]
	ldrb r0,[koptr,#sprMemReload]
	cmp r0,#0
	blne reloadSprites

	ldrb r0,[koptr,#sprBank]
	and r0,r0,#0x08
	ldr r10,[koptr,#gfxRAM]
	add r10,r10,#0x1000
	add r10,r10,r0,lsl#8		;@ Iron Horse wants it this way. Maybe not ddribble?

	ldr r7,=g_scaling
	ldrb r7,[r7]
	cmp r7,#UNSCALED			;@ Do autoscroll
	ldreq r7,=0x01000000		;@ No scaling
//	ldrne r7,=0x00DB6DB6		;@ 192/224, 6/7, scaling. 0xC0000000/0xE0 = 0x00DB6DB6.
//	ldrne r7,=0x00B6DB6D		;@ 160/224, 5/7, scaling. 0xA0000000/0xE0 = 0x00B6DB6D.
	ldrne r7,=(SCREEN_HEIGHT<<19)/7		;@ 192/224, 6/7, scaling. 0xC0000000/0xE0 = 0x00DB6DB6.
	mov r0,#0
	ldreq r0,=yStart			;@ First scanline?
	ldrbeq r0,[r0]
	add r6,r0,#0x10

	mov r5,#0x00000000			;@ 8x8 size
	orrne r5,r5,#0x0100			;@ Scaling

	ldrb r4,[koptr,#irqControl]
	tst r4,#0x08				;@ Flip enabled?
	orrne r5,#0x30000000		;@ Flips
	rsbne r7,r7,#0
	rsbne r6,r0,#0xF0
	mov r6,r6,lsl#16

	mov r8,#64					;@ Number of sprites.
	add r10,r10,r8,lsl#2		;@ Begin with the last sprite
	add r10,r10,r8				;@ r8 * 5
dm4:
	ldrb r3,[r10,#-3]			;@ K005885 OBJ, Y pos
	cmp r3,#0x00				;@ Check yPos 0
	beq dm8
	ldrb r1,[r10,#-2]			;@ X pos
	ldrb r2,[r10,#-1]			;@ Size, flip, high X bit.
	mov r1,r1,lsl#23
	orr r1,r1,r2,lsl#31			;@ Xpos bit8

	tst r7,#0x80000000			;@ Is scaling negative (flip)?
	rsbne r1,r1,#0x78000000		;@ Flip Xpos

	orr r1,r5,r1,lsr#7
	and r0,r2,#0x60				;@ X/Yflip
	eor r1,r1,r0,lsl#23

	mvn r0,#0					;@ Tile number mask
	mov r4,#4					;@ Sprite height / 2
	ands r2,r2,#0x1C			;@ 16x16 size
	orreq r1,r1,#0x40000000
	mvneq r0,#0x03
	moveq r4,#8
	tst r2,#0x10				;@ 32x32 size
	orrne r1,r1,#0x80000000
	mvnne r0,#0x0F
	movne r4,#0x10
	cmp r2,#0x08				;@ 8x16
	orreq r1,r1,#0x00008000
	mvneq r0,#0x02
	moveq r4,#8
	cmp r2,#0x04				;@ 16x8
	orreq r1,r1,#0x00004000
	mvneq r0,#0x01
	cmp r4,#4
	biceq r1,r1,#0x00000100		;@ No scale for 8high sprites

	sub r3,r3,r6,asr#16			;@ Y offset
	add r3,r3,r4
	mul r3,r7,r3				;@ Y scaling
	add r3,r3,#0x00800000		;@ Add 0.5 for rounding.
	sub r3,r3,r4,lsl#24
	orr r3,r1,r3,lsr#24			;@ Size + scaling + yoffset

	str r3,[r11],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.

	ldrb r4,[r10,#-4]			;@ Tile number + color
	ldrb r1,[r10,#-5]!			;@ Tile number
	orr r1,r1,r4,lsl#28
	orr r1,r1,r1,lsr#20
	and r0,r0,r1,ror#30

	bl getSpriteFromCache5885	;@ Takes tile# in r0, gives new tile# in r0

	ldrb r1,[koptr,#spritePaletteOffset]
	add r4,r4,r1,lsl#4
	and r1,r4,#0xF0				;@ Color
	orr r0,r0,r1,lsl#8
	orr r0,r0,#PRIORITY			;@ Priority
	strh r0,[r11],#4			;@ Store OBJ Atr 2. Pattern, prio & palette.
dm6:
	subs r8,r8,#1
	bne dm4
	ldmfd sp!,{r4-r11,pc}
dm8:
	sub r10,r10,#5
	mov r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
	str r0,[r11],#8
	b dm6

;@----------------------------------------------------------------------------
spriteCacheFull:
	strb r2,[koptr,#sprMemReload]
	mov r2,#1<<(SPRDSTTILECOUNTBITS-SPRGROUPTILECOUNTBITS)
	str r2,[koptr,#sprMemAlloc]
	ldmfd sp!,{r4-r11,pc}
;@----------------------------------------------------------------------------
getSpriteFromCache5885:		;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	mov r2,r0,ror#SPRGROUPTILECOUNTBITS
	adr r1,lowBitTable
	ldrb r0,[r1,r2,lsr#32-SPRGROUPTILECOUNTBITS]
	ldr r1,[koptr,#spriteMask]
	and r1,r2,r1
	ldr r2,[r9,r1,lsl#2]
	orrs r0,r0,r2,lsl#2			;@ Check cache, uncached = 0x40000000
	bxcc lr						;@ Allready cached
alloc32x32:
	ldr r2,[koptr,#sprMemAlloc]
	subs r2,r2,#1
	bmi spriteCacheFull
	str r2,[koptr,#sprMemAlloc]

	and r3,r2,#0x07
	and r2,r2,#0x38
	orr r2,r3,r2,lsl#2
	str r2,[r9,r1,lsl#2]
	orr r0,r0,r2,lsl#2
;@----------------------------------------------------------------------------
do32:
	stmfd sp!,{r0,r4-r8,lr}
	ldr r0,[koptr,#spriteRomBase]
	add r1,r0,r1,lsl#SPRGROUPTILECOUNTBITS + SPRTILESIZEBITS

	ldr r0,=SPRITE_GFX			;@ r0=GBA/NDS SPR tileset
	add r0,r0,r2,lsl#7			;@ x128 bytes

spr32Loop:
	ldmia r1!,{r2-r8,lr}			;@ 1 16x8 tile
	stmia r0!,{r2-r8,lr}
	ldmia r1!,{r2-r8,lr}
	stmia r0!,{r2-r8,lr}
	tst r1,#0x40
	addne r0,r0,#(256 - 16) * 8 / 2	;@ Next row
	bne spr32Loop
	tst r1,#0x80
	subne r0,r0,#256 * 8 / 2		;@ Back up
	bne spr32Loop
	tst r1,#0x100
	addne r0,r0,#(256 - 32) * 8 / 2	;@ Next row
	bne spr32Loop

	ldmfd sp!,{r0,r4-r8,pc}

;@----------------------------------------------------------------------------
lowBitTable:
	.byte 0x00,0x01,0x20,0x21,0x02,0x03,0x22,0x23
	.byte 0x40,0x41,0x60,0x61,0x42,0x43,0x62,0x63
;@----------------------------------------------------------------------------

#endif // #ifdef __arm__
