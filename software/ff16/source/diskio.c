/*-----------------------------------------------------------------------*/
/* Low level disk I/O module SKELETON for FatFs     (C)ChaN, 2025        */
/*-----------------------------------------------------------------------*/
/* If a working storage control module is available, it should be        */
/* attached to the FatFs via a glue function rather than modifying it.   */
/* This is an example of glue functions to attach various exsisting      */
/* storage control modules to the FatFs module with a defined API.       */
/*-----------------------------------------------------------------------*/

#include "ff.h"			/* Basic definitions of FatFs */
#include "diskio.h"		/* Declarations FatFs MAI */

#include "system.h"
#include "altera_avalon_spi_regs.h"

/* Example: Mapping of physical drive number for each drive */
#define DEV_FLASH	0	/* Map FTL to physical drive 0 */
#define DEV_MMC		1	/* Map MMC/SD card to physical drive 1 */
#define DEV_USB		2	/* Map USB MSD to physical drive 2 */

// #define SD_SPI_BASE 0x00

#define CS_LOW()    IOWR_ALTERA_AVALON_SPI_SLAVE_SEL(SD_SPI_BASE, 1)
#define CS_HIGH()   IOWR_ALTERA_AVALON_SPI_SLAVE_SEL(SD_SPI_BASE, 0)

// 發送並接收 1 個 Byte
static BYTE xchg_spi (BYTE dat) {
    // 1. 等待 TX 準備好：確保 SPI 的發送區有空位 (避免資料覆蓋 Overrun)
    while ((IORD_ALTERA_AVALON_SPI_STATUS(SD_SPI_BASE) & ALTERA_AVALON_SPI_STATUS_TRDY_MSK) == 0);

    // 2. 寫入 TX，啟動硬體時脈傳輸
    IOWR_ALTERA_AVALON_SPI_TXDATA(SD_SPI_BASE, dat);
    
    // 3. 等待 RX 準備好：確保 8 個 Clock 確實跑完，且收到 SD 卡的回傳
    while ((IORD_ALTERA_AVALON_SPI_STATUS(SD_SPI_BASE) & ALTERA_AVALON_SPI_STATUS_RRDY_MSK) == 0);
    
    // 4. 讀取 RX 暫存器 (這會自動清除 RRDY 旗標，迎接下一個 Byte)
    return (BYTE)IORD_ALTERA_AVALON_SPI_RXDATA(SD_SPI_BASE);
}

/* ===================================================================== */
/* SD 卡 SPI 協定底層函式                                                 */
/* ===================================================================== */
#define CMD0   (0)      /* GO_IDLE_STATE */
#define CMD1   (1)      /* SEND_OP_COND */
#define CMD8   (8)      /* SEND_IF_COND */
#define CMD12  (12)     /* STOP_TRANSMISSION */
#define ACMD41 (0x80+41)/* APP_SEND_OP_COND */
#define CMD17  (17)     /* READ_SINGLE_BLOCK */
#define CMD24  (24)     /* WRITE_BLOCK */
#define CMD55  (55)     /* APP_CMD */
#define CMD58  (58)     /* READ_OCR */

static volatile DSTATUS Stat = STA_NOINIT; /* 磁碟狀態 */
static BYTE CardType; /* SD 卡類型 b0:MMC, b1:SDv1, b2:SDv2, b3:Block addressing */

// 等待 SD 卡準備好
static int wait_ready (void) {
    BYTE d;
    UINT tmr = 5000000; 
    do {
        d = xchg_spi(0xFF);
    } while (d != 0xFF && --tmr);
    return (d == 0xFF) ? 1 : 0;
}

// 發送 SD 卡指令
static BYTE send_cmd (BYTE cmd, DWORD arg) {
    BYTE n, res;
    if (cmd & 0x80) { // ACMD
        cmd &= 0x7F;
        res = send_cmd(CMD55, 0);
        if (res > 1) return res;
    }
    // 選擇 SD 卡並等待準備好
    CS_HIGH(); xchg_spi(0xFF);
    CS_LOW(); xchg_spi(0xFF);
    if (!wait_ready()) return 0xFF;

    // 傳送 6 bytes 的指令封包
    xchg_spi(cmd | 0x40);          // Start + Command index
    xchg_spi((BYTE)(arg >> 24));   // Argument[31..24]
    xchg_spi((BYTE)(arg >> 16));   // Argument[23..16]
    xchg_spi((BYTE)(arg >> 8));    // Argument[15..8]
    xchg_spi((BYTE)arg);           // Argument[7..0]
    
    n = 0x01;                      // Dummy CRC + Stop
    if (cmd == CMD0) n = 0x95;     // Valid CRC for CMD0
    if (cmd == CMD8) n = 0x87;     // Valid CRC for CMD8
    xchg_spi(n);

    // 等待有效回應 (0x00 ~ 0x7F)
    if (cmd == CMD12) xchg_spi(0xFF); // Skip stuff byte for CMD12
    n = 10; 
    do {
        res = xchg_spi(0xFF);
    } while ((res & 0x80) && --n);

    return res;
}


/*-----------------------------------------------------------------------*/
/* Get Drive Status                                                      */
/*-----------------------------------------------------------------------*/

DSTATUS disk_status (
	BYTE pdrv		/* Physical drive nmuber to identify the drive */
)
{
    if (pdrv) return STA_NOINIT;
    return Stat;
}



/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (
	BYTE pdrv				/* Physical drive nmuber to identify the drive */
)
{
	BYTE n, ty, ocr[4];
    if (pdrv) return STA_NOINIT;
    if (Stat & STA_NODISK) return Stat;

    IOWR_ALTERA_AVALON_SPI_STATUS(SD_SPI_BASE, 0);
	IORD_ALTERA_AVALON_SPI_RXDATA(SD_SPI_BASE);

    CS_HIGH();
    for (n = 10; n; n--) xchg_spi(0xFF); // 發送 80 個 Dummy Clocks 喚醒 SD 卡

    ty = 0;
    if (send_cmd(CMD0, 0) == 1) { // 進入 SPI Idle 狀態
        if (send_cmd(CMD8, 0x1AA) == 1) { // SDv2
            for (n = 0; n < 4; n++) ocr[n] = xchg_spi(0xFF);
            if (ocr[2] == 0x01 && ocr[3] == 0xAA) {
                while (send_cmd(ACMD41, 1UL << 30)); // 等待初始化完成
                if (send_cmd(CMD58, 0) == 0) {       // 檢查 CCS (判斷是否為 SDHC)
                    for (n = 0; n < 4; n++) ocr[n] = xchg_spi(0xFF);
                    ty = (ocr[0] & 0x40) ? 12 : 4;   // 12: SDHC, 4: Standard SD
                }
            }
        } else { // SDv1 or MMC
            ty = (send_cmd(ACMD41, 0) <= 1) ? 2 : 1;
            while (send_cmd(ty == 2 ? ACMD41 : CMD1, 0));
        }
    }
    CardType = ty;
    CS_HIGH(); xchg_spi(0xFF);

    if (ty) Stat &= ~STA_NOINIT; // 初始化成功
    else Stat |= STA_NOINIT;     // 初始化失敗

    return Stat;
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/

DRESULT disk_read (
	BYTE pdrv,		/* Physical drive nmuber to identify the drive */
	BYTE *buff,		/* Data buffer to store read data */
	LBA_t sector,	/* Start sector in LBA */
	UINT count		/* Number of sectors to read */
)
{
	if (pdrv || !count) return RES_PARERR;
    if (Stat & STA_NOINIT) return RES_NOTRDY;
    
    // 如果是舊版標準 SD 卡，要把區塊號碼換算成實際 Byte 位址
    if (!(CardType & 8)) sector *= 512; 

    do {
        if (send_cmd(CMD17, sector) == 0) {   // 讀取單一區塊
            alt_u32 timeout = 500000;
            while (xchg_spi(0xFF) != 0xFE) {  // 等待資料起始標記 (0xFE)
                if (--timeout == 0) break;
            }
            if (timeout == 0) break;          // 超時錯誤

            int i;
            for (i = 0; i < 512; i++) {
                *buff++ = xchg_spi(0xFF);     // 連續讀取 512 Bytes 進入指標
            }
            xchg_spi(0xFF); xchg_spi(0xFF);   // 丟棄 2 Bytes 的 CRC
        } else {
            break; // 指令發送失敗
        }
        
        // 準備讀取下一個區塊
        if (!(CardType & 8)) sector += 512; else sector++;
    } while (--count);

    CS_HIGH(); xchg_spi(0xFF);
    return count ? RES_ERROR : RES_OK; // 如果 count 歸零代表全部讀完
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

#if FF_FS_READONLY == 0

DRESULT disk_write (
	BYTE pdrv,			/* Physical drive nmuber to identify the drive */
	const BYTE *buff,	/* Data to be written */
	LBA_t sector,		/* Start sector in LBA */
	UINT count			/* Number of sectors to write */
)
{
	if (pdrv || !count) return RES_PARERR;
    if (Stat & STA_NOINIT) return RES_NOTRDY;
    
    if (!(CardType & 8)) sector *= 512; 

    do {
        if (send_cmd(CMD24, sector) == 0) {   // 寫入單一區塊
            xchg_spi(0xFF); 
            xchg_spi(0xFE);                   // 發送資料起始標記 (0xFE)
            
            int i;
            for (i = 0; i < 512; i++) {
                xchg_spi(*buff++);            // 連續寫入 512 Bytes
            }
            xchg_spi(0xFF); xchg_spi(0xFF);   // 發送 2 Bytes 的 Dummy CRC
            
            if ((xchg_spi(0xFF) & 0x1F) == 0x05) { // 檢查是否成功被卡片接收
                if (!wait_ready()) break;          // 等待卡片將資料寫入快閃記憶體
            } else {
                break; // 卡片拒絕接收
            }
        } else {
            break; // 指令發送失敗
        }
        
        // 準備寫入下一個區塊
        if (!(CardType & 8)) sector += 512; else sector++;
    } while (--count);

    CS_HIGH(); xchg_spi(0xFF);
    return count ? RES_ERROR : RES_OK;
}

#endif


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/

DRESULT disk_ioctl (
	BYTE pdrv,		/* Physical drive nmuber (0..) */
	BYTE cmd,		/* Control code */
	void *buff		/* Buffer to send/receive control data */
)
{
	if (pdrv) return RES_PARERR;
    if (Stat & STA_NOINIT) return RES_NOTRDY;
    if (cmd == CTRL_SYNC) {
        CS_LOW();
        if (wait_ready()) {
            CS_HIGH();
            return RES_OK;
        }
    }
    return RES_ERROR;
}
