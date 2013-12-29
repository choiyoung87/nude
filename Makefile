CROSS_COMPILE	?= arm-linux-
BOARD_NAME		?= s3c6410

CC		= $(CROSS_COMPILE)gcc
AS		= $(CROSS_COMPILE)as
AR		= $(CROSS_COMPILE)ar
LD		= $(CROSS_COMPILE)ld
OBJCOPY	= $(CROSS_COMPILE)objcopy
OBJDUMP	= $(CROSS_COMPILE)objdump

OPTS	= -mcpu=arm1176jzf-s -Wall
INCLUDE	= -I./include
LD_FILE	= build/$(BOARD_NAME).ld

CFLAGS	= $(OPTS) $(INCLUDE) -O2
ASFLAGS	= $(OPTS) $(INCLUDE)
LDFLAGS	= -e _start -T $(LD_FILE)
OBJCOPYFLAGS	= -O binary
OBJDUMPFLAGS	= -D

OUTPUT		= ./output
OUTPUT_ELF	= $(OUTPUT)/nude.elf
OUTPUT_BIN	= $(OUTPUT)/nude.bin
OUTPUT_DUMP	= $(OUTPUT)/nude.S
OUTPUT_MAP	= $(OUTPUT)/nude.map

ROOT_DIR	= ./
SRC_DIR		= $(ROOT_DIR)/src
BOOT_DIR	= $(SRC_DIR)/boot
BOARD_DIR	= $(SRC_DIR)/board
DRIVER_DIR	= $(SRC_DIR)/driver
COMMON_DIR	= $(SRC_DIR)/common

BOOT_SRCS	= $(BOOT_DIR)/entry.S
BOARD_SRCS	= $(BOARD_DIR)/smdk6410.S
DRIVER_SRCS	= $(DRIVER_DIR)/nand.c \
				$(DRIVER_DIR)/serial.c 
COMMON_SRCS = $(COMMON_DIR)/main.c

FULL_SRCS	= $(BOOT_SRCS) $(BOARD_SRCS) $(DRIVER_SRCS) $(COMMON_SRCS)

FULL_AS_SRCS	= $(filter %.S, $(FULL_SRCS))
FULL_AS_OBJS	= $(patsubst $(ROOT_DIR)/%.S, $(OUTPUT)/%.o, $(subst \,/,$(FULL_AS_SRCS)))
FULL_C_SRCS		= $(filter %.c, $(FULL_SRCS))
FULL_C_OBJS		= $(patsubst $(ROOT_DIR)/%.c, $(OUTPUT)/%.o, $(subst \,/,$(FULL_C_SRCS)))

OBJ_PATH		= $(subst $(ROOT_DIR), $(OUTPUT), $(sort $(dir $(subst \,/,$(FULL_SRCS)))))

all:$(OBJ_PATH) $(FULL_AS_OBJS) $(FULL_C_OBJS) $(OUTPUT_ELF) $(OUTPUT_BIN) $(OUTPUT_DUMP)

$(OBJ_PATH):
	@mkdir -p $@

$(FULL_C_OBJS): $(OUTPUT)/%.o :$(ROOT_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(FULL_AS_OBJS): $(OUTPUT)/%.o :$(ROOT_DIR)/%.S
	$(CC) $(ASFLAGS) -c $< -o $@

$(OUTPUT_ELF): $(FULL_AS_OBJS) $(FULL_C_OBJS)
	$(LD) $(LDFLAGS) $(FULL_C_OBJS) $(FULL_AS_OBJS) -Map=$(OUTPUT_MAP) --output $@

$(OUTPUT_BIN): $(OUTPUT_ELF)
	$(OBJCOPY) $(OBJCOPYFLAGS) $< $@

$(OUTPUT_DUMP): $(OUTPUT_ELF)
	$(OBJDUMP) $(OBJDUMPFLAGS) $(OUTPUT_ELF) > $(OUTPUT_DUMP)

clean:
	@find . -name "*.o" -o -name "*.bin" -o -name "*.elf" | xargs rm -rf
	@rm -rf $(OUTPUT)
