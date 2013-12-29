#include <s3c6410.h>

/*
 * Standard NAND flash commands
 */
#define NAND_CMD_READ0		0
#define NAND_CMD_READ1		1
#define NAND_CMD_RNDOUT		5
#define NAND_CMD_PAGEPROG	0x10
#define NAND_CMD_READOOB	0x50
#define NAND_CMD_ERASE1		0x60
#define NAND_CMD_STATUS		0x70
#define NAND_CMD_STATUS_MULTI	0x71
#define NAND_CMD_SEQIN		0x80
#define NAND_CMD_RNDIN		0x85
#define NAND_CMD_READID		0x90
#define NAND_CMD_ERASE2		0xd0
#define NAND_CMD_RESET		0xff

/* Extended commands for large page devices */
#define NAND_CMD_READSTART	0x30
#define NAND_CMD_RNDOUTSTART	0xE0
#define NAND_CMD_CACHEDPROG	0x15

#define NAND_DISABLE_CE()	(NFCONT_REG |= (1 << 1))
#define NAND_ENABLE_CE()	(NFCONT_REG &= ~(1 << 1))
#define NF_TRANSRnB()		do { while(!(NFSTAT_REG & (1 << 0))); } while(0)

static int nandll_read_page (unsigned char *buf, unsigned long addr, int large_block)
{
	int i;
	int page_size = 512;

	if (large_block==1)
		page_size = 2048;
	if (large_block==2)
		page_size = 4096;

    NAND_ENABLE_CE();

    NFCMD_REG = NAND_CMD_READ0;

    /* Write Address */
    NFADDR_REG = 0;

	if (large_block)
		NFADDR_REG = 0;

	NFADDR_REG = (addr) & 0xff;
	NFADDR_REG = (addr >> 8) & 0xff;
	NFADDR_REG = (addr >> 16) & 0xff;

	if (large_block)
		NFCMD_REG = NAND_CMD_READSTART;

    NF_TRANSRnB();

	/* for compatibility(2460). u32 cannot be used. by scsuh */
	for(i=0; i < page_size; i++) {
		*buf++ = NFDATA8_REG;
    }

    NAND_DISABLE_CE();
    return 0;
}

static int nandll_read_blocks (unsigned long dst_addr, unsigned long size, int large_block)
{
	unsigned char *buf = (unsigned char *)dst_addr;
    int i;
	unsigned int page_shift = 9;

	if (large_block==1)
		page_shift = 11;

        /* Read pages */
	if(large_block==2)
		page_shift = 12;
 
	if(large_block == 2)
	{
		/* Read pages */
		for (i = 0; i < 4; i++, buf+=(1<<(page_shift-1))) {
		        nandll_read_page(buf, i, large_block);
		}


		/* Read pages */
		for (i = 4; i < (0x3c000>>page_shift); i++, buf+=(1<<page_shift)) {
		        nandll_read_page(buf, i, large_block);
		}
	}
	else
	{
		for (i = 0; i < (0x3c000>>page_shift); i++, buf+=(1<<page_shift)) {
		        nandll_read_page(buf, i, large_block);
		}
	}

        return 0;
}

int copy_uboot_to_ram (void)
{
	int large_block = 0;
	int i;
	volatile unsigned char id;
	
	NAND_ENABLE_CE();
    NFCMD_REG = NAND_CMD_READID;
    NFADDR_REG =  0x00;

	/* wait for a while */
    for (i=0; i<200; i++);
	id = NFDATA8_REG;
	id = NFDATA8_REG;

	if (id > 0x80)
		large_block = 1;
	if(id == 0xd5)
		large_block = 2;


	/* read NAND Block.
	 * 128KB ->240KB because of U-Boot size increase. by scsuh
	 * So, read 0x3c000 bytes not 0x20000(128KB).
	 */
	return nandll_read_blocks(CFG_PHY_UBOOT_BASE, 0x3c000, large_block);
}
