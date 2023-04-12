// Konami 005849/005885 Video Chip emulation

#ifndef K005849_HEADER
#define K005849_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#define CHIP_K005849 (0)
#define CHIP_K005885 (1)

/** \brief  Game screen height in pixels */
#define GAME_HEIGHT (224)
/** \brief  Game screen width in pixels */
#define GAME_WIDTH  (256)

typedef struct {
	u32 scanline;
	u32 nextLineChange;
	u32 lineState;

	void *periodicIrqFunc;
	void *frameIrqFunc;
	void *frame2IrqFunc;

//k005849State:
	u8 zRAM1[0x20];
	u8 zRAM2[0x20];

//k005849Regs:					// 0-4
	u8 scrollYReg;				// 0 (Scroll Y. ofs?)
	u8 scrollXReg;				// 1 (Scroll X. ofs?)
	u8 scrollAxis;				// 2 (bit 0 Scroll X bit8?, bit 1 = use ram scroll, bit 2 = ram scroll y?), JB 0x02, 0x06. GB 0x02. MrG 0x02. IH 0x0A. FI 0x00
	u8 sprBank;					// 3 (005885 0x02=prio enable?, 8=sprram), JB 0x02, 0xC2, (0x00, 0x08)... . GB (0x82, 0x8A)... MrG (0xA2, 0xAA)... IH (0xE2, 0xEA)... (0xE3, 0xEB)... FI 0x04
	u8 irqControl;				// 4, JB 0x00, IH 0x15, (0x1C, 0x1D)...

	u8 isIronHorse;
	u8 spritePaletteOffset;
	u8 frameOdd;
	u8 bgMemReload;
	u8 sprMemReload;
	u8 sprPalReload;
	u8 koPadding1[1];

	u32 bgMemAlloc;
	u32 sprMemAlloc;
	u32 sprPalAlloc;

	u32 bgrRomBase;
	u32 bgrRomSize;
	u32 bgrMask;
	u32 bgrGfxDest;
	u32 spriteRomBase;
	u32 spriteRomSize;
	u32 spriteMask;

	u8 dirtyTiles[4];
	void *gfxRAM;
	u32 *sprBlockLUT;
	u32 *bgBlockLUT;
} K005849;

void k005849Reset(void *periodicIrqFunc(), void *frameIrqFunc(), void *frame2IrqFunc(), void *ram);

/**
 * Saves the state of the chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The K005849/K005885 chip to save.
 * @return The size of the state.
 */
int k005849SaveState(void *destination, const K005849 *chip);

/**
 * Loads the state of the chip from the source.
 * @param  *chip: The K005849/K005885 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int k005849LoadState(K005849 *chip, const void *source);

/**
 * Gets the state size of a K005849/K005885.
 * @return The size of the state.
 */
int k005849GetStateSize(void);

void convertTiles5849(void *destination, const void *source, int length);
void convertTiles5885(void *destination, const void *source1, const void *source2, int length);
void convertSprites5849(void *destination);
void convertSprites5885(void *destination);
void doScanline(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // K005849_HEADER
