/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'cpu' in SOPC Builder design 'NIOS'
 * SOPC Builder design path: ../NIOS.sopcinfo
 *
 * Generated: Thu Jun 18 00:03:42 CST 2026
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * BGM configuration
 *
 */

#define ALT_MODULE_CLASS_BGM altera_avalon_onchip_memory2
#define BGM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define BGM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define BGM_BASE 0x220000
#define BGM_CONTENTS_INFO ""
#define BGM_DUAL_PORT 1
#define BGM_GUI_RAM_BLOCK_TYPE "AUTO"
#define BGM_INIT_CONTENTS_FILE "BGM"
#define BGM_INIT_MEM_CONTENT 1
#define BGM_INSTANCE_ID "NONE"
#define BGM_IRQ -1
#define BGM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define BGM_NAME "/dev/BGM"
#define BGM_NON_DEFAULT_INIT_FILE_ENABLED 1
#define BGM_RAM_BLOCK_TYPE "AUTO"
#define BGM_READ_DURING_WRITE_MODE "DONT_CARE"
#define BGM_SINGLE_CLOCK_OP 1
#define BGM_SIZE_MULTIPLE 1
#define BGM_SIZE_VALUE 16384
#define BGM_SPAN 16384
#define BGM_TYPE "altera_avalon_onchip_memory2"
#define BGM_WRITABLE 1


/*
 * BGM_CTRL configuration
 *
 */

#define ALT_MODULE_CLASS_BGM_CTRL altera_avalon_pio
#define BGM_CTRL_BASE 0x229920
#define BGM_CTRL_BIT_CLEARING_EDGE_REGISTER 0
#define BGM_CTRL_BIT_MODIFYING_OUTPUT_REGISTER 0
#define BGM_CTRL_CAPTURE 0
#define BGM_CTRL_DATA_WIDTH 8
#define BGM_CTRL_DO_TEST_BENCH_WIRING 0
#define BGM_CTRL_DRIVEN_SIM_VALUE 0
#define BGM_CTRL_EDGE_TYPE "NONE"
#define BGM_CTRL_FREQ 100000000
#define BGM_CTRL_HAS_IN 0
#define BGM_CTRL_HAS_OUT 1
#define BGM_CTRL_HAS_TRI 0
#define BGM_CTRL_IRQ -1
#define BGM_CTRL_IRQ_INTERRUPT_CONTROLLER_ID -1
#define BGM_CTRL_IRQ_TYPE "NONE"
#define BGM_CTRL_NAME "/dev/BGM_CTRL"
#define BGM_CTRL_RESET_VALUE 0
#define BGM_CTRL_SPAN 16
#define BGM_CTRL_TYPE "altera_avalon_pio"


/*
 * BGM_STATE configuration
 *
 */

#define ALT_MODULE_CLASS_BGM_STATE altera_avalon_pio
#define BGM_STATE_BASE 0x229930
#define BGM_STATE_BIT_CLEARING_EDGE_REGISTER 0
#define BGM_STATE_BIT_MODIFYING_OUTPUT_REGISTER 0
#define BGM_STATE_CAPTURE 0
#define BGM_STATE_DATA_WIDTH 8
#define BGM_STATE_DO_TEST_BENCH_WIRING 0
#define BGM_STATE_DRIVEN_SIM_VALUE 0
#define BGM_STATE_EDGE_TYPE "NONE"
#define BGM_STATE_FREQ 100000000
#define BGM_STATE_HAS_IN 1
#define BGM_STATE_HAS_OUT 0
#define BGM_STATE_HAS_TRI 0
#define BGM_STATE_IRQ -1
#define BGM_STATE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define BGM_STATE_IRQ_TYPE "NONE"
#define BGM_STATE_NAME "/dev/BGM_STATE"
#define BGM_STATE_RESET_VALUE 0
#define BGM_STATE_SPAN 16
#define BGM_STATE_TYPE "altera_avalon_pio"


/*
 * BLOCK_INFO configuration
 *
 */

#define ALT_MODULE_CLASS_BLOCK_INFO altera_avalon_onchip_memory2
#define BLOCK_INFO_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define BLOCK_INFO_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define BLOCK_INFO_BASE 0x229880
#define BLOCK_INFO_CONTENTS_INFO ""
#define BLOCK_INFO_DUAL_PORT 1
#define BLOCK_INFO_GUI_RAM_BLOCK_TYPE "AUTO"
#define BLOCK_INFO_INIT_CONTENTS_FILE "BLOCK_INFO"
#define BLOCK_INFO_INIT_MEM_CONTENT 1
#define BLOCK_INFO_INSTANCE_ID "NONE"
#define BLOCK_INFO_IRQ -1
#define BLOCK_INFO_IRQ_INTERRUPT_CONTROLLER_ID -1
#define BLOCK_INFO_NAME "/dev/BLOCK_INFO"
#define BLOCK_INFO_NON_DEFAULT_INIT_FILE_ENABLED 1
#define BLOCK_INFO_RAM_BLOCK_TYPE "AUTO"
#define BLOCK_INFO_READ_DURING_WRITE_MODE "DONT_CARE"
#define BLOCK_INFO_SINGLE_CLOCK_OP 1
#define BLOCK_INFO_SIZE_MULTIPLE 1
#define BLOCK_INFO_SIZE_VALUE 128
#define BLOCK_INFO_SPAN 128
#define BLOCK_INFO_TYPE "altera_avalon_onchip_memory2"
#define BLOCK_INFO_WRITABLE 0


/*
 * COS_TABLE configuration
 *
 */

#define ALT_MODULE_CLASS_COS_TABLE altera_avalon_onchip_memory2
#define COS_TABLE_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define COS_TABLE_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define COS_TABLE_BASE 0x229000
#define COS_TABLE_CONTENTS_INFO ""
#define COS_TABLE_DUAL_PORT 1
#define COS_TABLE_GUI_RAM_BLOCK_TYPE "AUTO"
#define COS_TABLE_INIT_CONTENTS_FILE "COS_TABLE"
#define COS_TABLE_INIT_MEM_CONTENT 1
#define COS_TABLE_INSTANCE_ID "NONE"
#define COS_TABLE_IRQ -1
#define COS_TABLE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define COS_TABLE_NAME "/dev/COS_TABLE"
#define COS_TABLE_NON_DEFAULT_INIT_FILE_ENABLED 1
#define COS_TABLE_RAM_BLOCK_TYPE "AUTO"
#define COS_TABLE_READ_DURING_WRITE_MODE "DONT_CARE"
#define COS_TABLE_SINGLE_CLOCK_OP 1
#define COS_TABLE_SIZE_MULTIPLE 1
#define COS_TABLE_SIZE_VALUE 1024
#define COS_TABLE_SPAN 1024
#define COS_TABLE_TYPE "altera_avalon_onchip_memory2"
#define COS_TABLE_WRITABLE 0


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_qsys"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x00228820
#define ALT_CPU_CPU_FREQ 100000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "tiny"
#define ALT_CPU_DATA_ADDR_WIDTH 0x16
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_EXCEPTION_ADDR 0x00210020
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 100000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 0
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x16
#define ALT_CPU_NAME "cpu"
#define ALT_CPU_RESET_ADDR 0x00210000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x00228820
#define NIOS2_CPU_FREQ 100000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "tiny"
#define NIOS2_DATA_ADDR_WIDTH 0x16
#define NIOS2_DCACHE_LINE_SIZE 0
#define NIOS2_DCACHE_LINE_SIZE_LOG2 0
#define NIOS2_DCACHE_SIZE 0
#define NIOS2_EXCEPTION_ADDR 0x00210020
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 0
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 0
#define NIOS2_ICACHE_LINE_SIZE_LOG2 0
#define NIOS2_ICACHE_SIZE 0
#define NIOS2_INST_ADDR_WIDTH 0x16
#define NIOS2_RESET_ADDR 0x00210000


/*
 * Custom instruction macros
 *
 */

#define ALT_CI_MULTIPLIER(A,B) __builtin_custom_inii(ALT_CI_MULTIPLIER_N,(A),(B))
#define ALT_CI_MULTIPLIER_N 0x0
#define ALT_CI_MULTIPLIER_Q(A,B) __builtin_custom_inii(ALT_CI_MULTIPLIER_Q_N,(A),(B))
#define ALT_CI_MULTIPLIER_Q_N 0x1
#define ALT_CI_SHIFTER(A,B) __builtin_custom_inii(ALT_CI_SHIFTER_N,(A),(B))
#define ALT_CI_SHIFTER_N 0x2
#define ALT_CI_SSHIFTER(A,B) __builtin_custom_inii(ALT_CI_SSHIFTER_N,(A),(B))
#define ALT_CI_SSHIFTER_N 0x3


/*
 * Data_Bridge configuration
 *
 */

#define ALT_MODULE_CLASS_Data_Bridge Data_Bridge
#define DATA_BRIDGE_BASE 0x229400
#define DATA_BRIDGE_IRQ -1
#define DATA_BRIDGE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define DATA_BRIDGE_NAME "/dev/Data_Bridge"
#define DATA_BRIDGE_SPAN 1024
#define DATA_BRIDGE_TYPE "Data_Bridge"


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PIO
#define __ALTERA_AVALON_SPI
#define __ALTERA_AVALON_SYSID_QSYS
#define __ALTERA_NIOS2_QSYS
#define __DATA_BRIDGE
#define __MULTIPLIER
#define __MULTIPLIER_Q
#define __SHIFTER
#define __SRAM_CONTROLLER
#define __SSHIFTER


/*
 * INV_DELTA configuration
 *
 */

#define ALT_MODULE_CLASS_INV_DELTA altera_avalon_onchip_memory2
#define INV_DELTA_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define INV_DELTA_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define INV_DELTA_BASE 0x224000
#define INV_DELTA_CONTENTS_INFO ""
#define INV_DELTA_DUAL_PORT 1
#define INV_DELTA_GUI_RAM_BLOCK_TYPE "AUTO"
#define INV_DELTA_INIT_CONTENTS_FILE "INV_DELTA"
#define INV_DELTA_INIT_MEM_CONTENT 1
#define INV_DELTA_INSTANCE_ID "NONE"
#define INV_DELTA_IRQ -1
#define INV_DELTA_IRQ_INTERRUPT_CONTROLLER_ID -1
#define INV_DELTA_NAME "/dev/INV_DELTA"
#define INV_DELTA_NON_DEFAULT_INIT_FILE_ENABLED 1
#define INV_DELTA_RAM_BLOCK_TYPE "AUTO"
#define INV_DELTA_READ_DURING_WRITE_MODE "DONT_CARE"
#define INV_DELTA_SINGLE_CLOCK_OP 1
#define INV_DELTA_SIZE_MULTIPLE 1
#define INV_DELTA_SIZE_VALUE 16384
#define INV_DELTA_SPAN 16384
#define INV_DELTA_TYPE "altera_avalon_onchip_memory2"
#define INV_DELTA_WRITABLE 0


/*
 * KEY_1 configuration
 *
 */

#define ALT_MODULE_CLASS_KEY_1 altera_avalon_pio
#define KEY_1_BASE 0x2299a0
#define KEY_1_BIT_CLEARING_EDGE_REGISTER 0
#define KEY_1_BIT_MODIFYING_OUTPUT_REGISTER 0
#define KEY_1_CAPTURE 0
#define KEY_1_DATA_WIDTH 32
#define KEY_1_DO_TEST_BENCH_WIRING 0
#define KEY_1_DRIVEN_SIM_VALUE 0
#define KEY_1_EDGE_TYPE "NONE"
#define KEY_1_FREQ 100000000
#define KEY_1_HAS_IN 1
#define KEY_1_HAS_OUT 0
#define KEY_1_HAS_TRI 0
#define KEY_1_IRQ -1
#define KEY_1_IRQ_INTERRUPT_CONTROLLER_ID -1
#define KEY_1_IRQ_TYPE "NONE"
#define KEY_1_NAME "/dev/KEY_1"
#define KEY_1_RESET_VALUE 0
#define KEY_1_SPAN 16
#define KEY_1_TYPE "altera_avalon_pio"


/*
 * KEY_2 configuration
 *
 */

#define ALT_MODULE_CLASS_KEY_2 altera_avalon_pio
#define KEY_2_BASE 0x229990
#define KEY_2_BIT_CLEARING_EDGE_REGISTER 0
#define KEY_2_BIT_MODIFYING_OUTPUT_REGISTER 0
#define KEY_2_CAPTURE 0
#define KEY_2_DATA_WIDTH 32
#define KEY_2_DO_TEST_BENCH_WIRING 0
#define KEY_2_DRIVEN_SIM_VALUE 0
#define KEY_2_EDGE_TYPE "NONE"
#define KEY_2_FREQ 100000000
#define KEY_2_HAS_IN 1
#define KEY_2_HAS_OUT 0
#define KEY_2_HAS_TRI 0
#define KEY_2_IRQ -1
#define KEY_2_IRQ_INTERRUPT_CONTROLLER_ID -1
#define KEY_2_IRQ_TYPE "NONE"
#define KEY_2_NAME "/dev/KEY_2"
#define KEY_2_RESET_VALUE 0
#define KEY_2_SPAN 16
#define KEY_2_TYPE "altera_avalon_pio"


/*
 * MODE configuration
 *
 */

#define ALT_MODULE_CLASS_MODE altera_avalon_pio
#define MODE_BASE 0x229960
#define MODE_BIT_CLEARING_EDGE_REGISTER 0
#define MODE_BIT_MODIFYING_OUTPUT_REGISTER 0
#define MODE_CAPTURE 0
#define MODE_DATA_WIDTH 8
#define MODE_DO_TEST_BENCH_WIRING 0
#define MODE_DRIVEN_SIM_VALUE 0
#define MODE_EDGE_TYPE "NONE"
#define MODE_FREQ 100000000
#define MODE_HAS_IN 0
#define MODE_HAS_OUT 1
#define MODE_HAS_TRI 0
#define MODE_IRQ -1
#define MODE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define MODE_IRQ_TYPE "NONE"
#define MODE_NAME "/dev/MODE"
#define MODE_RESET_VALUE 0
#define MODE_SPAN 16
#define MODE_TYPE "altera_avalon_pio"


/*
 * SD_MOUNT configuration
 *
 */

#define ALT_MODULE_CLASS_SD_MOUNT altera_avalon_pio
#define SD_MOUNT_BASE 0x229950
#define SD_MOUNT_BIT_CLEARING_EDGE_REGISTER 0
#define SD_MOUNT_BIT_MODIFYING_OUTPUT_REGISTER 0
#define SD_MOUNT_CAPTURE 1
#define SD_MOUNT_DATA_WIDTH 1
#define SD_MOUNT_DO_TEST_BENCH_WIRING 0
#define SD_MOUNT_DRIVEN_SIM_VALUE 0
#define SD_MOUNT_EDGE_TYPE "RISING"
#define SD_MOUNT_FREQ 100000000
#define SD_MOUNT_HAS_IN 1
#define SD_MOUNT_HAS_OUT 0
#define SD_MOUNT_HAS_TRI 0
#define SD_MOUNT_IRQ 3
#define SD_MOUNT_IRQ_INTERRUPT_CONTROLLER_ID 0
#define SD_MOUNT_IRQ_TYPE "EDGE"
#define SD_MOUNT_NAME "/dev/SD_MOUNT"
#define SD_MOUNT_RESET_VALUE 0
#define SD_MOUNT_SPAN 16
#define SD_MOUNT_TYPE "altera_avalon_pio"


/*
 * SD_spi configuration
 *
 */

#define ALT_MODULE_CLASS_SD_spi altera_avalon_spi
#define SD_SPI_BASE 0x229900
#define SD_SPI_CLOCKMULT 1
#define SD_SPI_CLOCKPHASE 0
#define SD_SPI_CLOCKPOLARITY 0
#define SD_SPI_CLOCKUNITS "Hz"
#define SD_SPI_DATABITS 8
#define SD_SPI_DATAWIDTH 16
#define SD_SPI_DELAYMULT "1.0E-9"
#define SD_SPI_DELAYUNITS "ns"
#define SD_SPI_EXTRADELAY 0
#define SD_SPI_INSERT_SYNC 0
#define SD_SPI_IRQ -1
#define SD_SPI_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SD_SPI_ISMASTER 1
#define SD_SPI_LSBFIRST 0
#define SD_SPI_NAME "/dev/SD_spi"
#define SD_SPI_NUMSLAVES 1
#define SD_SPI_PREFIX "spi_"
#define SD_SPI_SPAN 32
#define SD_SPI_SYNC_REG_DEPTH 2
#define SD_SPI_TARGETCLOCK 20000000u
#define SD_SPI_TARGETSSDELAY "0.0"
#define SD_SPI_TYPE "altera_avalon_spi"


/*
 * SEED configuration
 *
 */

#define ALT_MODULE_CLASS_SEED altera_avalon_pio
#define SEED_BASE 0x229940
#define SEED_BIT_CLEARING_EDGE_REGISTER 0
#define SEED_BIT_MODIFYING_OUTPUT_REGISTER 0
#define SEED_CAPTURE 0
#define SEED_DATA_WIDTH 32
#define SEED_DO_TEST_BENCH_WIRING 0
#define SEED_DRIVEN_SIM_VALUE 0
#define SEED_EDGE_TYPE "NONE"
#define SEED_FREQ 100000000
#define SEED_HAS_IN 1
#define SEED_HAS_OUT 0
#define SEED_HAS_TRI 0
#define SEED_IRQ -1
#define SEED_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SEED_IRQ_TYPE "NONE"
#define SEED_NAME "/dev/SEED"
#define SEED_RESET_VALUE 0
#define SEED_SPAN 16
#define SEED_TYPE "altera_avalon_pio"


/*
 * SRAM_Controller_0 configuration
 *
 */

#define ALT_MODULE_CLASS_SRAM_Controller_0 SRAM_Controller
#define SRAM_CONTROLLER_0_BASE 0x0
#define SRAM_CONTROLLER_0_IRQ -1
#define SRAM_CONTROLLER_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SRAM_CONTROLLER_0_NAME "/dev/SRAM_Controller_0"
#define SRAM_CONTROLLER_0_SPAN 2097152
#define SRAM_CONTROLLER_0_TYPE "SRAM_Controller"


/*
 * STATE_KEY configuration
 *
 */

#define ALT_MODULE_CLASS_STATE_KEY altera_avalon_pio
#define STATE_KEY_BASE 0x229970
#define STATE_KEY_BIT_CLEARING_EDGE_REGISTER 0
#define STATE_KEY_BIT_MODIFYING_OUTPUT_REGISTER 0
#define STATE_KEY_CAPTURE 1
#define STATE_KEY_DATA_WIDTH 8
#define STATE_KEY_DO_TEST_BENCH_WIRING 0
#define STATE_KEY_DRIVEN_SIM_VALUE 0
#define STATE_KEY_EDGE_TYPE "RISING"
#define STATE_KEY_FREQ 100000000
#define STATE_KEY_HAS_IN 1
#define STATE_KEY_HAS_OUT 0
#define STATE_KEY_HAS_TRI 0
#define STATE_KEY_IRQ 2
#define STATE_KEY_IRQ_INTERRUPT_CONTROLLER_ID 0
#define STATE_KEY_IRQ_TYPE "EDGE"
#define STATE_KEY_NAME "/dev/STATE_KEY"
#define STATE_KEY_RESET_VALUE 0
#define STATE_KEY_SPAN 16
#define STATE_KEY_TYPE "altera_avalon_pio"


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone IV E"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/jtag_uart"
#define ALT_STDERR_BASE 0x229a38
#define ALT_STDERR_DEV jtag_uart
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/jtag_uart"
#define ALT_STDIN_BASE 0x229a38
#define ALT_STDIN_DEV jtag_uart
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/jtag_uart"
#define ALT_STDOUT_BASE 0x229a38
#define ALT_STDOUT_DEV jtag_uart
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "NIOS"


/*
 * VGA_CLEAR configuration
 *
 */

#define ALT_MODULE_CLASS_VGA_CLEAR altera_avalon_pio
#define VGA_CLEAR_BASE 0x229980
#define VGA_CLEAR_BIT_CLEARING_EDGE_REGISTER 0
#define VGA_CLEAR_BIT_MODIFYING_OUTPUT_REGISTER 0
#define VGA_CLEAR_CAPTURE 0
#define VGA_CLEAR_DATA_WIDTH 9
#define VGA_CLEAR_DO_TEST_BENCH_WIRING 0
#define VGA_CLEAR_DRIVEN_SIM_VALUE 0
#define VGA_CLEAR_EDGE_TYPE "NONE"
#define VGA_CLEAR_FREQ 100000000
#define VGA_CLEAR_HAS_IN 0
#define VGA_CLEAR_HAS_OUT 1
#define VGA_CLEAR_HAS_TRI 0
#define VGA_CLEAR_IRQ -1
#define VGA_CLEAR_IRQ_INTERRUPT_CONTROLLER_ID -1
#define VGA_CLEAR_IRQ_TYPE "NONE"
#define VGA_CLEAR_NAME "/dev/VGA_CLEAR"
#define VGA_CLEAR_RESET_VALUE 0
#define VGA_CLEAR_SPAN 16
#define VGA_CLEAR_TYPE "altera_avalon_pio"


/*
 * VGA_TEXT configuration
 *
 */

#define ALT_MODULE_CLASS_VGA_TEXT altera_avalon_onchip_memory2
#define VGA_TEXT_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define VGA_TEXT_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define VGA_TEXT_BASE 0x229800
#define VGA_TEXT_CONTENTS_INFO ""
#define VGA_TEXT_DUAL_PORT 1
#define VGA_TEXT_GUI_RAM_BLOCK_TYPE "AUTO"
#define VGA_TEXT_INIT_CONTENTS_FILE "NIOS_VGA_TEXT"
#define VGA_TEXT_INIT_MEM_CONTENT 1
#define VGA_TEXT_INSTANCE_ID "NONE"
#define VGA_TEXT_IRQ -1
#define VGA_TEXT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define VGA_TEXT_NAME "/dev/VGA_TEXT"
#define VGA_TEXT_NON_DEFAULT_INIT_FILE_ENABLED 0
#define VGA_TEXT_RAM_BLOCK_TYPE "AUTO"
#define VGA_TEXT_READ_DURING_WRITE_MODE "DONT_CARE"
#define VGA_TEXT_SINGLE_CLOCK_OP 1
#define VGA_TEXT_SIZE_MULTIPLE 1
#define VGA_TEXT_SIZE_VALUE 128
#define VGA_TEXT_SPAN 128
#define VGA_TEXT_TYPE "altera_avalon_onchip_memory2"
#define VGA_TEXT_WRITABLE 1


/*
 * action_keys configuration
 *
 */

#define ACTION_KEYS_BASE 0x2299c0
#define ACTION_KEYS_BIT_CLEARING_EDGE_REGISTER 0
#define ACTION_KEYS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define ACTION_KEYS_CAPTURE 0
#define ACTION_KEYS_DATA_WIDTH 2
#define ACTION_KEYS_DO_TEST_BENCH_WIRING 0
#define ACTION_KEYS_DRIVEN_SIM_VALUE 0
#define ACTION_KEYS_EDGE_TYPE "NONE"
#define ACTION_KEYS_FREQ 100000000
#define ACTION_KEYS_HAS_IN 1
#define ACTION_KEYS_HAS_OUT 0
#define ACTION_KEYS_HAS_TRI 0
#define ACTION_KEYS_IRQ -1
#define ACTION_KEYS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define ACTION_KEYS_IRQ_TYPE "NONE"
#define ACTION_KEYS_NAME "/dev/action_keys"
#define ACTION_KEYS_RESET_VALUE 0
#define ACTION_KEYS_SPAN 16
#define ACTION_KEYS_TYPE "altera_avalon_pio"
#define ALT_MODULE_CLASS_action_keys altera_avalon_pio


/*
 * block_select configuration
 *
 */

#define ALT_MODULE_CLASS_block_select altera_avalon_pio
#define BLOCK_SELECT_BASE 0x2299d0
#define BLOCK_SELECT_BIT_CLEARING_EDGE_REGISTER 0
#define BLOCK_SELECT_BIT_MODIFYING_OUTPUT_REGISTER 0
#define BLOCK_SELECT_CAPTURE 0
#define BLOCK_SELECT_DATA_WIDTH 8
#define BLOCK_SELECT_DO_TEST_BENCH_WIRING 0
#define BLOCK_SELECT_DRIVEN_SIM_VALUE 0
#define BLOCK_SELECT_EDGE_TYPE "NONE"
#define BLOCK_SELECT_FREQ 100000000
#define BLOCK_SELECT_HAS_IN 1
#define BLOCK_SELECT_HAS_OUT 0
#define BLOCK_SELECT_HAS_TRI 0
#define BLOCK_SELECT_IRQ -1
#define BLOCK_SELECT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define BLOCK_SELECT_IRQ_TYPE "NONE"
#define BLOCK_SELECT_NAME "/dev/block_select"
#define BLOCK_SELECT_RESET_VALUE 0
#define BLOCK_SELECT_SPAN 16
#define BLOCK_SELECT_TYPE "altera_avalon_pio"


/*
 * game_tick configuration
 *
 */

#define ALT_MODULE_CLASS_game_tick altera_avalon_pio
#define GAME_TICK_BASE 0x229a10
#define GAME_TICK_BIT_CLEARING_EDGE_REGISTER 0
#define GAME_TICK_BIT_MODIFYING_OUTPUT_REGISTER 0
#define GAME_TICK_CAPTURE 1
#define GAME_TICK_DATA_WIDTH 1
#define GAME_TICK_DO_TEST_BENCH_WIRING 0
#define GAME_TICK_DRIVEN_SIM_VALUE 0
#define GAME_TICK_EDGE_TYPE "RISING"
#define GAME_TICK_FREQ 100000000
#define GAME_TICK_HAS_IN 1
#define GAME_TICK_HAS_OUT 0
#define GAME_TICK_HAS_TRI 0
#define GAME_TICK_IRQ 1
#define GAME_TICK_IRQ_INTERRUPT_CONTROLLER_ID 0
#define GAME_TICK_IRQ_TYPE "EDGE"
#define GAME_TICK_NAME "/dev/game_tick"
#define GAME_TICK_RESET_VALUE 0
#define GAME_TICK_SPAN 16
#define GAME_TICK_TYPE "altera_avalon_pio"


/*
 * hal configuration
 *
 */

#define ALT_MAX_FD 32
#define ALT_SYS_CLK none
#define ALT_TIMESTAMP_CLK none


/*
 * jtag_uart configuration
 *
 */

#define ALT_MODULE_CLASS_jtag_uart altera_avalon_jtag_uart
#define JTAG_UART_BASE 0x229a38
#define JTAG_UART_IRQ 0
#define JTAG_UART_IRQ_INTERRUPT_CONTROLLER_ID 0
#define JTAG_UART_NAME "/dev/jtag_uart"
#define JTAG_UART_READ_DEPTH 64
#define JTAG_UART_READ_THRESHOLD 8
#define JTAG_UART_SPAN 8
#define JTAG_UART_TYPE "altera_avalon_jtag_uart"
#define JTAG_UART_WRITE_DEPTH 64
#define JTAG_UART_WRITE_THRESHOLD 8


/*
 * millis configuration
 *
 */

#define ALT_MODULE_CLASS_millis altera_avalon_pio
#define MILLIS_BASE 0x2299e0
#define MILLIS_BIT_CLEARING_EDGE_REGISTER 0
#define MILLIS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define MILLIS_CAPTURE 0
#define MILLIS_DATA_WIDTH 32
#define MILLIS_DO_TEST_BENCH_WIRING 0
#define MILLIS_DRIVEN_SIM_VALUE 0
#define MILLIS_EDGE_TYPE "NONE"
#define MILLIS_FREQ 100000000
#define MILLIS_HAS_IN 1
#define MILLIS_HAS_OUT 0
#define MILLIS_HAS_TRI 0
#define MILLIS_IRQ -1
#define MILLIS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define MILLIS_IRQ_TYPE "NONE"
#define MILLIS_NAME "/dev/millis"
#define MILLIS_RESET_VALUE 0
#define MILLIS_SPAN 16
#define MILLIS_TYPE "altera_avalon_pio"


/*
 * move_ctrl configuration
 *
 */

#define ALT_MODULE_CLASS_move_ctrl altera_avalon_pio
#define MOVE_CTRL_BASE 0x2299b0
#define MOVE_CTRL_BIT_CLEARING_EDGE_REGISTER 0
#define MOVE_CTRL_BIT_MODIFYING_OUTPUT_REGISTER 0
#define MOVE_CTRL_CAPTURE 0
#define MOVE_CTRL_DATA_WIDTH 10
#define MOVE_CTRL_DO_TEST_BENCH_WIRING 0
#define MOVE_CTRL_DRIVEN_SIM_VALUE 0
#define MOVE_CTRL_EDGE_TYPE "NONE"
#define MOVE_CTRL_FREQ 100000000
#define MOVE_CTRL_HAS_IN 1
#define MOVE_CTRL_HAS_OUT 0
#define MOVE_CTRL_HAS_TRI 0
#define MOVE_CTRL_IRQ -1
#define MOVE_CTRL_IRQ_INTERRUPT_CONTROLLER_ID -1
#define MOVE_CTRL_IRQ_TYPE "NONE"
#define MOVE_CTRL_NAME "/dev/move_ctrl"
#define MOVE_CTRL_RESET_VALUE 0
#define MOVE_CTRL_SPAN 16
#define MOVE_CTRL_TYPE "altera_avalon_pio"


/*
 * onchip_memory2 configuration
 *
 */

#define ALT_MODULE_CLASS_onchip_memory2 altera_avalon_onchip_memory2
#define ONCHIP_MEMORY2_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define ONCHIP_MEMORY2_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define ONCHIP_MEMORY2_BASE 0x210000
#define ONCHIP_MEMORY2_CONTENTS_INFO ""
#define ONCHIP_MEMORY2_DUAL_PORT 0
#define ONCHIP_MEMORY2_GUI_RAM_BLOCK_TYPE "AUTO"
#define ONCHIP_MEMORY2_INIT_CONTENTS_FILE "NIOS_onchip_memory2"
#define ONCHIP_MEMORY2_INIT_MEM_CONTENT 1
#define ONCHIP_MEMORY2_INSTANCE_ID "NONE"
#define ONCHIP_MEMORY2_IRQ -1
#define ONCHIP_MEMORY2_IRQ_INTERRUPT_CONTROLLER_ID -1
#define ONCHIP_MEMORY2_NAME "/dev/onchip_memory2"
#define ONCHIP_MEMORY2_NON_DEFAULT_INIT_FILE_ENABLED 1
#define ONCHIP_MEMORY2_RAM_BLOCK_TYPE "AUTO"
#define ONCHIP_MEMORY2_READ_DURING_WRITE_MODE "DONT_CARE"
#define ONCHIP_MEMORY2_SINGLE_CLOCK_OP 0
#define ONCHIP_MEMORY2_SIZE_MULTIPLE 1
#define ONCHIP_MEMORY2_SIZE_VALUE 65536
#define ONCHIP_MEMORY2_SPAN 65536
#define ONCHIP_MEMORY2_TYPE "altera_avalon_onchip_memory2"
#define ONCHIP_MEMORY2_WRITABLE 1


/*
 * progress configuration
 *
 */

#define ALT_MODULE_CLASS_progress altera_avalon_pio
#define PROGRESS_BASE 0x229a20
#define PROGRESS_BIT_CLEARING_EDGE_REGISTER 0
#define PROGRESS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PROGRESS_CAPTURE 0
#define PROGRESS_DATA_WIDTH 8
#define PROGRESS_DO_TEST_BENCH_WIRING 0
#define PROGRESS_DRIVEN_SIM_VALUE 0
#define PROGRESS_EDGE_TYPE "NONE"
#define PROGRESS_FREQ 100000000
#define PROGRESS_HAS_IN 0
#define PROGRESS_HAS_OUT 1
#define PROGRESS_HAS_TRI 0
#define PROGRESS_IRQ -1
#define PROGRESS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PROGRESS_IRQ_TYPE "NONE"
#define PROGRESS_NAME "/dev/progress"
#define PROGRESS_RESET_VALUE 0
#define PROGRESS_SPAN 16
#define PROGRESS_TYPE "altera_avalon_pio"


/*
 * sysid_qsys configuration
 *
 */

#define ALT_MODULE_CLASS_sysid_qsys altera_avalon_sysid_qsys
#define SYSID_QSYS_BASE 0x229a30
#define SYSID_QSYS_ID 4660
#define SYSID_QSYS_IRQ -1
#define SYSID_QSYS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SYSID_QSYS_NAME "/dev/sysid_qsys"
#define SYSID_QSYS_SPAN 8
#define SYSID_QSYS_TIMESTAMP 1781712172
#define SYSID_QSYS_TYPE "altera_avalon_sysid_qsys"


/*
 * vram_addr configuration
 *
 */

#define ALT_MODULE_CLASS_vram_addr altera_avalon_pio
#define VRAM_ADDR_BASE 0x229a00
#define VRAM_ADDR_BIT_CLEARING_EDGE_REGISTER 0
#define VRAM_ADDR_BIT_MODIFYING_OUTPUT_REGISTER 0
#define VRAM_ADDR_CAPTURE 0
#define VRAM_ADDR_DATA_WIDTH 16
#define VRAM_ADDR_DO_TEST_BENCH_WIRING 0
#define VRAM_ADDR_DRIVEN_SIM_VALUE 0
#define VRAM_ADDR_EDGE_TYPE "NONE"
#define VRAM_ADDR_FREQ 100000000
#define VRAM_ADDR_HAS_IN 0
#define VRAM_ADDR_HAS_OUT 1
#define VRAM_ADDR_HAS_TRI 0
#define VRAM_ADDR_IRQ -1
#define VRAM_ADDR_IRQ_INTERRUPT_CONTROLLER_ID -1
#define VRAM_ADDR_IRQ_TYPE "NONE"
#define VRAM_ADDR_NAME "/dev/vram_addr"
#define VRAM_ADDR_RESET_VALUE 0
#define VRAM_ADDR_SPAN 16
#define VRAM_ADDR_TYPE "altera_avalon_pio"


/*
 * vram_data configuration
 *
 */

#define ALT_MODULE_CLASS_vram_data altera_avalon_pio
#define VRAM_DATA_BASE 0x2299f0
#define VRAM_DATA_BIT_CLEARING_EDGE_REGISTER 0
#define VRAM_DATA_BIT_MODIFYING_OUTPUT_REGISTER 0
#define VRAM_DATA_CAPTURE 0
#define VRAM_DATA_DATA_WIDTH 8
#define VRAM_DATA_DO_TEST_BENCH_WIRING 0
#define VRAM_DATA_DRIVEN_SIM_VALUE 0
#define VRAM_DATA_EDGE_TYPE "NONE"
#define VRAM_DATA_FREQ 100000000
#define VRAM_DATA_HAS_IN 1
#define VRAM_DATA_HAS_OUT 0
#define VRAM_DATA_HAS_TRI 0
#define VRAM_DATA_IRQ -1
#define VRAM_DATA_IRQ_INTERRUPT_CONTROLLER_ID -1
#define VRAM_DATA_IRQ_TYPE "NONE"
#define VRAM_DATA_NAME "/dev/vram_data"
#define VRAM_DATA_RESET_VALUE 0
#define VRAM_DATA_SPAN 16
#define VRAM_DATA_TYPE "altera_avalon_pio"

#endif /* __SYSTEM_H_ */
