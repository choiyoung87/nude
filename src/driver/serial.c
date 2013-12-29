#define ELFIN_UART_BASE		0x7F005000

typedef volatile unsigned char		S3C64XX_REG8;
typedef volatile unsigned short		S3C64XX_REG16;
typedef volatile unsigned long		S3C64XX_REG32;

typedef struct {
	S3C64XX_REG32	ULCON;
	S3C64XX_REG32	UCON;
	S3C64XX_REG32	UFCON;
	S3C64XX_REG32	UMCON;
	S3C64XX_REG32	UTRSTAT;
	S3C64XX_REG32	UERSTAT;
	S3C64XX_REG32	UFSTAT;
	S3C64XX_REG32	UMSTAT;
	S3C64XX_REG8	UTXH;
	S3C64XX_REG8	res1[3];
	S3C64XX_REG8	URXH;
	S3C64XX_REG8	res2[3];
	S3C64XX_REG32	UBRDIV;
} S3C64XX_UART;

static inline S3C64XX_UART * S3C64XX_GetBase_UART(unsigned int nr)
{
	return (S3C64XX_UART *)(ELFIN_UART_BASE + (nr * 0x400));
}

void serial_putc(const char c)
{
	S3C64XX_UART *const uart = S3C64XX_GetBase_UART(0);

	/* wait for room in the tx FIFO */
	while (!(uart->UTRSTAT & 0x2));

	uart->UTXH = c;

	/* If \n, also do \r */
	if (c == '\n')
		serial_putc('\r');
}

void serial_puts(const char *s)
{
	while (*s) {
		serial_putc(*s++);
	}
}
