extern void serial_puts(const char *s);
int start_armboot(void)
{
	asm volatile ( 
    "ldr r0, =0x7f008820\n"
    "ldr r1, =0x111111\n"
    "str r1, [r0]\n"
    "ldr r0, =0x7f008824\n"
    "ldr r2, =0x0\n"
    "str r2, [r0]\n"
	);
	serial_puts("HELLO CHOI\n");
	while (1);
	return 0;
}
