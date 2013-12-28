#include <s3c6410.h>
_TEXT_BASE:
	.word	TEXT_BASE

	.globl	lowlevel_init
lowlevel_init:
	mov	r12, lr

	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r1, =0x55555555
	str	r1, [r0, #GPKCON0_OFFSET]

	ldr	r1, =0x55555555
	str	r1, [r0, #GPKCON1_OFFSET]

	ldr	r1, =0x22222666
	str	r1, [r0, #GPLCON0_OFFSET]

	ldr	r1, =0x04000000
	str	r1, [r0, #GPFCON_OFFSET]
	ldr	r1, =0x2000
	str	r1, [r0, #GPFDAT_OFFSET]

	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r1, =0x00111111
	str	r1, [r0, #GPMCON_OFFSET]

	ldr	r1, =0x00000555
	str	r1, [r0, #GPMPUD_OFFSET]

	ldr	r1, =0x002a
	str	r1, [r0, #GPMDAT_OFFSET]

	ldr	r1, =0
	str	r1, [r0, #MEM1DRVCON_OFFSET]

	/* disable watchdog */
	ldr	r0, =0x7e000000
	orr	r0, r0, #0x4000
	mov	r1, #0
	str	r1, [r0]

	/* external interrupt pending clear */
	ldr	r0, =(ELFIN_GPIO_BASE+EINTPEND_OFFSET)
	ldr	r1, [r0]
	str	r1, [r0]

	ldr	r0, =ELFIN_VIC0_BASE_ADDR
	ldr	r1, =ELFIN_VIC1_BASE_ADDR

	/* disable all interrupts */
	mvn	r3, #0x0
	str	r3, [r0, #oINTMSK]
	str	r3, [r1, #oINTMSK]

	/* set all interrupts as irq */
	mov	r3, #0x0
	str	r3, [r0, #oINTMOD]
	str	r3, [r1, #oINTMOD]

	/* clear current interrupt */
	mov	r3, #0x0
	str	r3, [r0, #oVECTADDR]
	str	r3, [r1, #oVECTADDR]

	bl	system_clock_init

	bl	uart_asm_init

	/* transmit data for uart0 */
	ldr	r0, =ELFIN_UART_BASE
	ldr	r1, =0x4b4b4b4b
	str	r1, [r0, #UTXH_OFFSET]

	bl	nand_asm_init

	bl	mem_ctrl_asm_init

	/* reset by sleep mode wakeup */
	ldr     r0, =(ELFIN_CLOCK_POWER_BASE+RST_STAT_OFFSET)
	ldr     r1, [r0]
	bic     r1, r1, #0xfffffff7
	cmp     r1, #0x8
	beq     wakeup_reset

1:
	ldr	r0, =ELFIN_UART_BASE
	ldr	r1, =0x4b4b4b4b
	str	r1, [r0, #UTXH_OFFSET]

	mov	lr, r12
	mov	pc, lr

wakeup_reset:
	/* clear wakeup status register */
	ldr	r0, =(ELFIN_CLOCK_POWER_BASE+WAKEUP_STAT_OFFSET)
	ldr	r1, [r0]
	str	r1, [r0]

	/* led test */
	ldr     r0, =ELFIN_GPIO_BASE
	ldr     r1, =0x3000
	str     r1, [r0, #GPNDAT_OFFSET]

	/* load return address and jump to kernel */
	ldr	r0, =(ELFIN_CLOCK_POWER_BASE+INF_REG0_OFFSET)
	ldr	r1, [r0]
	mov	pc, r1
	nop
	nop

system_clock_init:
	ldr	r0, =ELFIN_CLOCK_POWER_BASE	@0x7e00f000

	ldr	r1, [r0, #OTHERS_OFFSET]
	mov	r2, #0x40
	orr	r1, r1, r2
	str	r1, [r0, #OTHERS_OFFSET]

	nop
	nop
	nop
	nop
	nop

	ldr	r2, =0x80
	orr	r1, r1, r2
	str	r1, [r0, #OTHERS_OFFSET]

check_syncack:
	ldr	r1, [r0, #OTHERS_OFFSET]
	ldr	r2, =0xf00
	and	r1, r1, r2
	cmp	r1, #0xf00
	bne	check_syncack

	mov	r1, #0xff00
	orr	r1, r1, #0xff
	str	r1, [r0, #APLL_LOCK_OFFSET]
	str	r1, [r0, #MPLL_LOCK_OFFSET]
	str	r1, [r0, #EPLL_LOCK_OFFSET]

	ldr   	r1, [r0, #CLK_DIV2_OFFSET]
	bic	r1, r1, #0x70000
	orr	r1, r1, #0x30000
	str	r1, [r0, #CLK_DIV2_OFFSET]

	ldr   	r1, [r0, #CLK_DIV0_OFFSET]
	bic	r1, r1, #0x30000
	bic	r1, r1, #0xff00
	bic	r1, r1, #0xff
	ldr	r2, =CLK_DIV_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLK_DIV0_OFFSET]

	ldr	r1, =APLL_VAL
	str	r1, [r0, #APLL_CON_OFFSET]
	ldr	r1, =MPLL_VAL
	str	r1, [r0, #MPLL_CON_OFFSET]

	ldr	r1, =0x80200203

	str	r1, [r0, #EPLL_CON0_OFFSET]
	ldr	r1, =0x0
	str	r1, [r0, #EPLL_CON1_OFFSET]

	ldr	r1, [r0, #CLK_SRC_OFFSET]

	ldr	r2, =0x2007

	orr	r1, r1, r2

	str	r1, [r0, #CLK_SRC_OFFSET]

	mov	r1, #0x10000
1:	subs	r1, r1, #1	
	bne	1b

	ldr	r1, [r0, #OTHERS_OFFSET]
	orr	r1, r1, #0x20
	str	r1, [r0, #OTHERS_OFFSET]

	mov	pc, lr

uart_asm_init:
	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r1, =0x220022
	str   	r1, [r0, #GPACON_OFFSET]

	ldr	r1, =0x2222
	str   	r1, [r0, #GPBCON_OFFSET]

	ldr	r0, =ELFIN_UART_CONSOLE_BASE
	mov	r1, #0x0
	str	r1, [r0, #UFCON_OFFSET]
	str	r1, [r0, #UMCON_OFFSET]

	mov	r1, #0x3
	str	r1, [r0, #ULCON_OFFSET]

	ldr	r1, =0xe45

	str	r1, [r0, #UCON_OFFSET]

	ldr	r1, =0x22

	str	r1, [r0, #UBRDIV_OFFSET]

	ldr	r1, =0x1FFF

	str	r1, [r0, #UDIVSLOT_OFFSET]

	ldr	r1, =0x4f4f4f4f
	str	r1, [r0, #UTXH_OFFSET]

	mov	pc, lr

nand_asm_init:
	ldr	r0, =ELFIN_NAND_BASE
	ldr	r1, [r0, #NFCONF_OFFSET]
	orr	r1, r1, #0x70
	orr	r1, r1, #0x7700
	str     r1, [r0, #NFCONF_OFFSET]

	ldr	r1, [r0, #NFCONT_OFFSET]
	orr	r1, r1, #0x03
	str     r1, [r0, #NFCONT_OFFSET]

	mov	pc, lr

mem_ctrl_asm_init:
	ldr	r0, =ELFIN_MEM_SYS_CFG			@Memory sussystem address 0x7e00f120
	mov	r1, #0xd				@ Xm0CSn2 = NFCON CS0, Xm0CSn3 = NFCON CS1
	str	r1, [r0]

	ldr	r0, =ELFIN_DMC1_BASE			@DMC1 base address 0x7e001000

	ldr	r1, =0x04
	str	r1, [r0, #INDEX_DMC_MEMC_CMD]

	ldr	r1, =DMC_DDR_REFRESH_PRD
	str	r1, [r0, #INDEX_DMC_REFRESH_PRD]

	ldr	r1, =DMC_DDR_CAS_LATENCY
	str	r1, [r0, #INDEX_DMC_CAS_LATENCY]

	ldr	r1, =DMC_DDR_t_DQSS
	str	r1, [r0, #INDEX_DMC_T_DQSS]

	ldr	r1, =DMC_DDR_t_MRD
	str	r1, [r0, #INDEX_DMC_T_MRD]

	ldr	r1, =DMC_DDR_t_RAS
	str	r1, [r0, #INDEX_DMC_T_RAS]

	ldr	r1, =DMC_DDR_t_RC
	str	r1, [r0, #INDEX_DMC_T_RC]

	ldr	r1, =DMC_DDR_t_RCD
	ldr	r2, =DMC_DDR_schedule_RCD
	orr	r1, r1, r2
	str	r1, [r0, #INDEX_DMC_T_RCD]

	ldr	r1, =DMC_DDR_t_RFC
	ldr	r2, =DMC_DDR_schedule_RFC
	orr	r1, r1, r2
	str	r1, [r0, #INDEX_DMC_T_RFC]

	ldr	r1, =DMC_DDR_t_RP
	ldr	r2, =DMC_DDR_schedule_RP
	orr	r1, r1, r2
	str	r1, [r0, #INDEX_DMC_T_RP]

	ldr	r1, =DMC_DDR_t_RRD
	str	r1, [r0, #INDEX_DMC_T_RRD]

	ldr	r1, =DMC_DDR_t_WR
	str	r1, [r0, #INDEX_DMC_T_WR]

	ldr	r1, =DMC_DDR_t_WTR
	str	r1, [r0, #INDEX_DMC_T_WTR]

	ldr	r1, =DMC_DDR_t_XP
	str	r1, [r0, #INDEX_DMC_T_XP]

	ldr	r1, =DMC_DDR_t_XSR
	str	r1, [r0, #INDEX_DMC_T_XSR]

	ldr	r1, =DMC_DDR_t_ESR
	str	r1, [r0, #INDEX_DMC_T_ESR]

	ldr	r1, =DMC1_MEM_CFG
	str	r1, [r0, #INDEX_DMC_MEMORY_CFG]

	ldr	r1, =DMC1_MEM_CFG2
	str	r1, [r0, #INDEX_DMC_MEMORY_CFG2]

	ldr	r1, =DMC1_CHIP0_CFG
	str	r1, [r0, #INDEX_DMC_CHIP_0_CFG]

	ldr	r1, =DMC_DDR_32_CFG
	str	r1, [r0, #INDEX_DMC_USER_CONFIG]

	@DMC0 DDR Chip 0 configuration direct command reg
	ldr	r1, =DMC_NOP0
	str	r1, [r0, #INDEX_DMC_DIRECT_CMD]

	@Precharge All
	ldr	r1, =DMC_PA0
	str	r1, [r0, #INDEX_DMC_DIRECT_CMD]

	@Auto Refresh	2 time
	ldr	r1, =DMC_AR0
	str	r1, [r0, #INDEX_DMC_DIRECT_CMD]
	str	r1, [r0, #INDEX_DMC_DIRECT_CMD]

	@MRS
	ldr	r1, =DMC_mDDR_EMR0
	str	r1, [r0, #INDEX_DMC_DIRECT_CMD]

	@Mode Reg
	ldr	r1, =DMC_mDDR_MR0
	str	r1, [r0, #INDEX_DMC_DIRECT_CMD]

	@Enable DMC1
	mov	r1, #0x0
	str	r1, [r0, #INDEX_DMC_MEMC_CMD]

check_dmc1_ready:
	ldr	r1, [r0, #INDEX_DMC_MEMC_STATUS]
	mov	r2, #0x3
	and	r1, r1, r2
	cmp	r1, #0x1
	bne	check_dmc1_ready
	nop
	mov	pc, lr

.macro FL_SECTION_ENTRY base,ap,d,c,b
	.word (\base << 20) | (\ap << 10) | \
	      (\d << 5) | (1<<4) | (\c << 3) | (\b << 2) | (1<<1)
.endm
.section .mmudata, "a"
	.align 14
	// the following alignment creates the mmu table at address 0x4000.
	.globl mmu_table
mmu_table:
	.set __base,0
	// 1:1 mapping for debugging
	.rept 0xA00
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	// access is not allowed.
	.rept 0xC00 - 0xA00
	.word 0x00000000
	.endr

	// 128MB for SDRAM 0xC0000000 -> 0x50000000
	.set __base, 0x500
	.rept 0xD00 - 0xC00
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	// access is not allowed.
	.rept 0x1000 - 0xD00
	.word 0x00000000
	.endr

