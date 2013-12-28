# 1 "src/entry.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "src/entry.S"






.globl _start
_start:
 b reset

_TEXT_BASE:
 .word TEXT_BASE

_TEXT_PHY_BASE:
 .word CFG_PHY_UBOOT_BASE

.globl _bss_start
_bss_start:
 .word __bss_start

.globl _bss_end
_bss_end:
 .word _end

reset:

 mrs r0, cpsr
 bic r0, r0, #0x1f
 orr r0, r0, #0xd3
 msr cpsr, r0

cpu_init_crit:

 mov r0, #0
 mcr p15, 0, r0, c7, c7, 0
 mcr p15, 0, r0, c8, c7, 0


 mrc p15, 0, r0, c1, c0, 0
 bic r0, r0, #0x00002300
 bic r0, r0, #0x00000087
 orr r0, r0, #0x00000002
 orr r0, r0, #0x00001000
 mcr p15, 0, r0, c1, c0, 0


 ldr r0, =0x70000000
 orr r0, r0, #0x13
 mcr p15, 0, r0, c15, c2, 4

 bl lowlevel_init


 ldr r0, =0xff000fff
 bic r1, pc, r0
 ldr r2, _TEXT_BASE
 bic r2, r2, r0
 cmp r1, r2
 beq after_copy


 mov r0, #0x1000
 bl copy_from_nand

after_copy:
enable_mmu:

 ldr r5, =0x0000ffff
 mcr p15, 0, r5, c3, c0, 0


 ldr r0, _mmu_table_base
 ldr r1, =CFG_PHY_UBOOT_BASE
 ldr r2, =0xfff00000
 bic r0, r0, r2
 orr r1, r0, r1
 mcr p15, 0, r1, c2, c0, 0

mmu_on:
 mrc p15, 0, r0, c1, c0, 0
 orr r0, r0, #1
 mcr p15, 0, r0, c1, c0, 0
 nop
 nop
 nop
 nop

skip_hw_init:
stack_setup:
 ldr sp, =(CFG_UBOOT_BASE + CFG_UBOOT_SIZE - 0xc)

clear_bss:
 ldr r0, _bss_start
 ldr r1, _bss_end
 mov r2, #0x00000000

clbss_l:
 str r2, [r0]
 add r0, r0, #4
 cmp r0, r1
 ble clbss_l

 ldr pc, _start_armboot

_start_armboot:
 .word start_armboot

_mmu_table_base:
 .word mmu_table

 .globl copy_from_nand
copy_from_nand:
 mov r10, lr
 mov r9, r0
 ldr sp, _TEXT_PHY_BASE
 sub sp, sp, #12
 mov fp, #0
 mov r9, #0x1000
 bl copy_uboot_to_ram

3: tst r0, #0x0
 bne copy_failed

 ldr r0, =0x0c000000
 ldr r1, _TEXT_PHY_BASE
1: ldr r3, [r0], #4
 ldr r4, [r1], #4
 teq r3, r4
 bne compare_failed
 subs r9, r9, #4
 bne 1b

4: mov lr, r10
 mov pc, lr

copy_failed:
 nop
 b copy_failed

compare_failed:
 nop
 b compare_failed
