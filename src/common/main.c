extern void serial_puts(const char *s);
int start_armboot(void)
{
	serial_puts("\nHELLO SINZU\n");
	while (1);
	return 0;
}
