CROSS_COMPILE ?= arm-linux-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
AR = $(CROSS_COMPILE)ar
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

OPTS = -mcpu=arm1176jzf-s -Wall
INCLUDE = -I./ -I./include
LD_FILE = build/nude.ld

CFLAGS = $(OPTS) $(INCLUDE) -O2
ASFLAGS = $(OPTS) $(INCLUDE)
LDFLAGS= -e _start -T $(LD_FILE)
OBJCOPYFLAGS = -O binary
OBJDUMPFLAGS = -D

OUTPUT = ./output
OUTPUT_ELF = $(OUTPUT)/nude.elf
OUTPUT_BIN = $(OUTPUT)/nude.bin
OUTPUT_DUMP = $(OUTPUT)/nude.S
OUTPUT_MAP = $(OUTPUT)/nude.map

ROOT_DIR = .
SRC_DIR = $(ROOT_DIR)/src

FULL_SRCS = $(SRC_DIR)/entry.S \
			$(SRC_DIR)/lowlevel_init.S \
			$(SRC_DIR)/stump.c

FULL_AS_SRCS = $(filter %.S, $(FULL_SRCS))
FULL_AS_OBJS = $(patsubst $(ROOT_DIR)/%.S, $(OUTPUT)/%.o, $(subst \,/,$(FULL_AS_SRCS)))
FULL_C_SRCS = $(filter %.c, $(FULL_SRCS))
FULL_C_OBJS = $(patsubst $(ROOT_DIR)/%.c, $(OUTPUT)/%.o, $(subst \,/,$(FULL_C_SRCS)))

OBJ_PATH = $(subst $(ROOT_DIR), $(OUTPUT), $(sort $(dir $(subst \,/,$(FULL_SRCS)))))

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
