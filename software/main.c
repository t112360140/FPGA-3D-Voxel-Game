#include <stdint.h>
#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"

#include "ff16/source/ff.h"

#include "library.h"
#include "keyboard.h"

// #define DEBUG

#ifdef DEBUG
    #define PRINT_LOG(...) printf(__VA_ARGS__)
#else
    #define PRINT_LOG(...) 
#endif

#define MUL(A, B) ALT_CI_MULTIPLIER((A), (B))
#define MULQ(A, B) ALT_CI_MULTIPLIER_Q((A), (B))
#define LSHIFT(val, amt)  ALT_CI_SHIFTER((val), (amt))
#define RSHIFT(val, amt)  ALT_CI_SHIFTER((val), ((amt) | 0x20))
#define LSSHIFT(val, amt)  ALT_CI_SSHIFTER((val), (amt))
#define RSSHIFT(val, amt)  ALT_CI_SSHIFTER((val), ((amt) | 0x20))

static inline uint32_t millis(){
    return IORD_ALTERA_AVALON_PIO_DATA(MILLIS_BASE);
}

static inline void delay(uint32_t deley_time){
    uint32_t start_time = millis();
    while((millis()-start_time)<deley_time);
    return;
}

volatile uint8_t *sram_8_ptr = (volatile uint8_t *) (SRAM_CONTROLLER_0_BASE | 0x80000000);
volatile uint16_t *sram_16_ptr = (volatile uint16_t *) (SRAM_CONTROLLER_0_BASE | 0x80000000);

volatile int32_t *bridge_ptr = (volatile int32_t *) (DATA_BRIDGE_BASE | 0x80000000);

volatile uint8_t *vga_text_ptr = (volatile uint8_t *) (VGA_TEXT_BASE | 0x80000000);

#define INVDELTA_TABLE_SIZE 4096
volatile int32_t *inv_delta_ptr = (volatile int32_t *) (INV_DELTA_BASE | 0x80000000);

volatile uint8_t *block_info_ptr = (volatile uint8_t *) (BLOCK_INFO_BASE | 0x80000000);

volatile uint8_t *bgm_ram_ptr = (volatile uint8_t *) (BGM_BASE | 0x80000000);

FATFS fs;

static void tick_isr(void* context);
void init_tick_interrupt(void);
static void state_key_isr(void* context);
void init_state_key_interrupt(void);
static void mount_sd_isr(void* context);
void init_mount_sd_interrupt(void);


#define FRAC_BITS 16
#define SCALE (1 << FRAC_BITS)

#define TO_FIXED_CONST(f) ((int32_t)((f) * SCALE))
static inline int32_t toFixedFloat(float float_val) {
    return (int32_t) (float_val * SCALE);
}
static inline int32_t toFixed(int32_t val) {
    return LSHIFT(val, FRAC_BITS);
}
static inline float getFloat(int32_t fixed_val) {
    return (float) fixed_val / SCALE;
}
#define TO_INT_CONST(f) ((int32_t)((f)>>FRAC_BITS))
static inline int32_t toInt(int32_t fixed_val) {
    return RSSHIFT(fixed_val, FRAC_BITS);
}
static inline int32_t getFloatPart(int32_t fixed_val) {
    return fixed_val & (SCALE - 1);
}
#define MULTQ16_CONST(a, b) ((int32_t)(((int64_t)(a) * (int64_t)(b)) >> FRAC_BITS))
static inline int32_t multQ16(int32_t a, int32_t b) {
    return MULQ(a, b);
}
static inline int32_t one_div(int32_t x) {
    uint16_t i = RSHIFT(abs_t(x), (FRAC_BITS-10));
    if (i >= INVDELTA_TABLE_SIZE)
        i = INVDELTA_TABLE_SIZE - 1;
    return inv_delta_ptr[i];
}

#define VGA_H 120.0
#define VGA_W 160.0
#define FOV_FACTOR TO_FIXED_CONST(1.0)

#define MAP_SIZE  (2*1024*1024)

#define WORLD_X 128
#define WORLD_Y 128
#define WORLD_Z 128

#define TPS 20
#define VELOCITY                (TO_FIXED_CONST(3.0f) / TPS)
#define RUN_VELOCITY            (TO_FIXED_CONST(5.0f) / TPS)
#define ROTATION_RATE           (200 / TPS)
#define GRAVITY                 (TO_FIXED_CONST(30.0f) / (TPS * TPS))
#define TERMINAL_VELOCITY       (TO_FIXED_CONST(60.0f) / TPS)
#define TERMINAL_VELOCITY_WATER (TO_FIXED_CONST(2.0f) / TPS)

// --- 跳躍初速設定 (V = sqrt(2 * g * h)) ---
// 陸地跳躍高度 1.5 格 (sqrt(90) 約等於 9.4868)
#define JUMP_VELOCITY           (TO_FIXED_CONST(9.4868f) / TPS)
// 水中跳躍高度 0.5 格 (sqrt(30) 約等於 5.4772)
#define JUMP_VELOCITY_WATER     (TO_FIXED_CONST(5.4772f) / TPS)

#define KEY_C_W       (1 << 0)
#define KEY_C_S       (1 << 1)
#define KEY_C_A       (1 << 2)
#define KEY_C_D       (1 << 3)
#define KEY_C_UP      (1 << 4)
#define KEY_C_DOWN    (1 << 5)
#define KEY_C_LEFT    (1 << 6)
#define KEY_C_RIGHT   (1 << 7)
#define KEY_C_JUMP    (1 << 8)
#define KEY_C_RUN     (1 << 9)

#define MIN_VAL(a, b) ((a) < (b) ? (a) : (b))
#define MAX_VAL(a, b) ((a) > (b) ? (a) : (b))


void clearVGAText(){
    uint16_t i=0;
    for(i=0;i<128;i++)
        vga_text_ptr[i] = ' ';
}

void printVGA(uint8_t x, uint8_t y, const char* str) {
    uint16_t offset = y * 10 + x;
    uint16_t i=0;
    for (i = 0; str[i] != '\0'; i++) {
        vga_text_ptr[offset + i] = str[i];
    }
}

void printVGAChar(uint8_t x, uint8_t y, uint8_t char_) {
    uint16_t offset = y * 10 + x;
    vga_text_ptr[offset] = char_;
}


struct __attribute__((packed)) {
    int32_t x, y, z, h, w, vy;
    uint16_t yaw, pitch;

    uint8_t faceBlock;
    uint16_t faceBlock_x, faceBlock_y, faceBlock_z;
    uint8_t isUnderwater, viewUnderwater, onGround;
    uint8_t selectBlockType;
} player = {
    .x = TO_FIXED_CONST((float)(WORLD_X>>1)) + TO_FIXED_CONST(0.5f),
    .y = TO_FIXED_CONST(64.0f),
    .z = TO_FIXED_CONST((float)(WORLD_Z>>1)) + TO_FIXED_CONST(0.5f),
    .h = TO_FIXED_CONST(1.8f),
    .w = TO_FIXED_CONST(0.3f),
    .vy = 0, .yaw = 512, .pitch = 512,
    .faceBlock = 0, .faceBlock_x = 0, .faceBlock_y = 0, .faceBlock_z = 0,
    .isUnderwater = 0, .viewUnderwater = 0, .onGround = 0,
    .selectBlockType = 1
};

// 光線投射結果結構
typedef struct {
    uint8_t hit;
    uint8_t side;
    int16_t mapX, mapY, mapZ;
    int8_t stepX, stepY, stepZ;
    int32_t dist;
} RayResult;

RayResult lastHit;

// ==========================================
// 世界存取與屬性查詢
// ==========================================

static inline uint8_t getBlock(int16_t x, int16_t y, int16_t z) {
    if (x < 0 || x >= WORLD_X || y < 0 || z < 0 || z >= WORLD_Z) return 15;
    if(y >= WORLD_Y) return 0;
    uint32_t index = LSSHIFT((uint32_t)x, 14) | LSSHIFT((uint32_t)y, 7) | z;
    return sram_8_ptr[index];
}

static inline void setBlock(int16_t x, int16_t y, int16_t z, uint8_t block) {
    if (x < 0 || x >= WORLD_X || y < 0 || y >= WORLD_Y || z < 0 || z >= WORLD_Z) return;
    uint32_t index = LSSHIFT((uint32_t)x, 14) | LSSHIFT((uint32_t)y, 7) | z;
    sram_8_ptr[index] = block;
}

// 檢查方塊是否為實體 (利用 block_info 的 Offset 3)
static inline uint8_t isSolid(uint8_t blockType) {
    if (blockType > 15) return 1;
    return !(block_info_ptr[(blockType << 3) + 3]); // 0=實體, 1=可穿透
}

// ==========================================
// 軟體 Raycast 與 互動邏輯
// ==========================================

#define MAX_RAY_STEPS 24
#define CAN_BREAK_LENGTH TO_FIXED_CONST(6.0f)

RayResult castRay(int32_t px, int32_t py, int32_t pz, int32_t dirX, int32_t dirY, int32_t dirZ, uint8_t viewUW) {
    RayResult res = {0};
    int16_t mapX = toInt(px);
    int16_t mapY = toInt(py);
    int16_t mapZ = toInt(pz);

    int32_t deltaDistX = one_div(dirX);
    int32_t deltaDistY = one_div(dirY);
    int32_t deltaDistZ = one_div(dirZ);

    int8_t stepX, stepY, stepZ;
    int32_t sideDistX, sideDistY, sideDistZ;

    if (dirX < 0) {
        stepX = -1;
        sideDistX = multQ16(getFloatPart(px), deltaDistX);
    }else{
        stepX =  1;
        sideDistX = multQ16(SCALE - getFloatPart(px), deltaDistX);
    }

    if (dirY < 0) {
        stepY = -1;
        sideDistY = multQ16(getFloatPart(py), deltaDistY);
    }else{
        stepY =  1;
        sideDistY = multQ16(SCALE - getFloatPart(py), deltaDistY);
    }

    if (dirZ < 0) {
        stepZ = -1;
        sideDistZ = multQ16(getFloatPart(pz), deltaDistZ);
    }else{
        stepZ =  1;
        sideDistZ = multQ16(SCALE - getFloatPart(pz), deltaDistZ);
    }

    int hit = 0;
    int hitSide = 0;
    int steps = MAX_RAY_STEPS;

    while (hit == 0 && steps > 0) {
        if (sideDistX < sideDistY) {
            if (sideDistX < sideDistZ) {
                sideDistX += deltaDistX;
                mapX += stepX;
                hitSide = 0;
            }else{
                sideDistZ += deltaDistZ;
                mapZ += stepZ;
                hitSide = 2;
            }
        } else {
            if (sideDistY < sideDistZ) {
                sideDistY += deltaDistY;
                mapY += stepY;
                hitSide = 1;
            }else{
                sideDistZ += deltaDistZ;
                mapZ += stepZ;
                hitSide = 2;
            }
        }
        if (mapX < 0 || mapX >= WORLD_X || mapY < 0 || mapY >= WORLD_Y || mapZ < 0 || mapZ >= WORLD_Z) break;

        uint8_t type = getBlock(mapX, mapY, mapZ);
        // 水中視角無視可穿透方塊，或者視角內就是水的話無視
        if (block_info_ptr[LSHIFT(type, 3) + 3]) hit = 0;
        else hit = type;

        steps--;
    }

    res.hit = hit; res.side = hitSide;
    res.mapX = mapX; res.mapY = mapY; res.mapZ = mapZ;
    res.stepX = stepX; res.stepY = stepY; res.stepZ = stepZ;

    if (hitSide == 0) res.dist = multQ16(LSHIFT((int32_t)mapX, FRAC_BITS) - px + ((stepX == -1) ? SCALE : 0), (dirX > 0) ? deltaDistX : -deltaDistX);
    else if (hitSide == 1) res.dist = multQ16(LSHIFT((int32_t)mapY, FRAC_BITS) - py + ((stepY == -1) ? SCALE : 0), (dirY > 0) ? deltaDistY : -deltaDistY);
    else res.dist = multQ16(LSHIFT((int32_t)mapZ, FRAC_BITS) - pz + ((stepZ == -1) ? SCALE : 0), (dirZ > 0) ? deltaDistZ : -deltaDistZ);

    return res;
}

// 檢查某個虛擬位置是否會和實體方塊重疊
uint8_t checkHitAABB(int32_t px, int32_t py, int32_t pz, int32_t w, int32_t h) {
    int16_t minX = TO_INT_CONST(px - w);
    int16_t maxX = TO_INT_CONST(px + w);
    int16_t minY = TO_INT_CONST(py);
    int16_t maxY = TO_INT_CONST(py + h);
    int16_t minZ = TO_INT_CONST(pz - w);
    int16_t maxZ = TO_INT_CONST(pz + w);

    int16_t cx, cy, cz;
    for (cx = minX; cx <= maxX; cx++) {
        for (cy = minY; cy <= maxY; cy++) {
            for (cz = minZ; cz <= maxZ; cz++) {
                if (isSolid(getBlock(cx, cy, cz))) return 1;
            }
        }
    }
    return 0;
}

void breakBlockAction() {
    if (player.faceBlock) {
        uint8_t targetBlock = lastHit.hit;
        // 利用 ROM 檢查是否可破壞 (Offset 4)
        uint8_t destructible = block_info_ptr[(targetBlock << 3) + 4];

        if (destructible) {
            setBlock(lastHit.mapX, lastHit.mapY, lastHit.mapZ, 0);
            if (getBlock(lastHit.mapX, lastHit.mapY - 1, lastHit.mapZ) == 3) {
                setBlock(lastHit.mapX, lastHit.mapY - 1, lastHit.mapZ, 2);
            }
        }
    }
}

void placeBlockAction() {
    if (player.faceBlock) {
        int16_t tx = lastHit.mapX;
        int16_t ty = lastHit.mapY;
        int16_t tz = lastHit.mapZ;

        if (isSolid(lastHit.hit)) {
            if (lastHit.side == 0) tx -= lastHit.stepX;
            else if (lastHit.side == 1) ty -= lastHit.stepY;
            else tz -= lastHit.stepZ;
        }

        if (!isSolid(getBlock(tx, ty, tz))) {
            setBlock(tx, ty, tz, player.selectBlockType);
            if (checkHitAABB(player.x, player.y, player.z, player.w, player.h)) {
                setBlock(tx, ty, tz, 0);
            } else {
                if (getBlock(tx, ty - 1, tz) == 2) {
                    setBlock(tx, ty - 1, tz, 3);
                }
            }
        }
    }
}

#define MAX_SIM_DIST 8
void waterSim() {
    int16_t px = TO_INT_CONST(player.x);
    int16_t py = TO_INT_CONST(player.y);
    int16_t pz = TO_INT_CONST(player.z);

    int16_t minY = MAX_VAL(py - MAX_SIM_DIST, 0);
    int16_t maxY = MIN_VAL(WORLD_Y - 1, py + MAX_SIM_DIST);
    int16_t minZ = MAX_VAL(pz - MAX_SIM_DIST, 0);
    int16_t maxZ = MIN_VAL(WORLD_Z - 1, pz + MAX_SIM_DIST);
    int16_t minX = MAX_VAL(px - MAX_SIM_DIST, 0);
    int16_t maxX = MIN_VAL(WORLD_X - 1, px + MAX_SIM_DIST);

    int16_t cx, cy, cz;
    for (cy = minY; cy <= maxY; cy++) {
        for (cz = minZ; cz <= maxZ; cz++) {
            for (cx = minX; cx <= maxX; cx++) {
                uint8_t type = getBlock(cx, cy, cz);
                if (type == 0 || (type >= 7 && type <= 9)) {
                    uint8_t ideal_type = 0;
                    uint8_t above = getBlock(cx, cy + 1, cz);

                    if (above >= 6 && above <= 9) {
                        ideal_type = 7;
                    } else {
                        uint8_t min_w = 10;
                        uint8_t n1 = isSolid(getBlock(cx + 1, cy - 1, cz)) ? getBlock(cx + 1, cy, cz) : 10;
                        uint8_t n2 = isSolid(getBlock(cx - 1, cy - 1, cz)) ? getBlock(cx - 1, cy, cz) : 10;
                        uint8_t n3 = isSolid(getBlock(cx, cy - 1, cz + 1)) ? getBlock(cx, cy, cz + 1) : 10;
                        uint8_t n4 = isSolid(getBlock(cx, cy - 1, cz - 1)) ? getBlock(cx, cy, cz - 1) : 10;

                        if (n1 >= 6 && n1 <= 9) min_w = MIN_VAL(min_w, n1);
                        if (n2 >= 6 && n2 <= 9) min_w = MIN_VAL(min_w, n2);
                        if (n3 >= 6 && n3 <= 9) min_w = MIN_VAL(min_w, n3);
                        if (n4 >= 6 && n4 <= 9) min_w = MIN_VAL(min_w, n4);

                        if (min_w <= 8) ideal_type = min_w + 1;
                    }

                    if (ideal_type != type) {
                        if (ideal_type != 0 || type != 0) setBlock(cx, cy, cz, ideal_type);
                    }
                }
            }
        }
    }
}


// ==========================================
// 狀態更新與橋接硬體
// ==========================================

void calcPlayStatus() {
    int32_t cosYaw = cos_t(player.yaw + 512);
    int32_t sinYaw = sin_t(player.yaw + 512);
    int32_t cosPitch = cos_t(player.pitch + 512);
    int32_t sinPitch = sin_t(player.pitch + 512);

    int32_t fwdX = multQ16(cosYaw, cosPitch);
    int32_t fwdY = sinPitch;
    int32_t fwdZ = multQ16(sinYaw, cosPitch);

    // --- 執行軟體 Raycast 獲取面向方塊 ---
    lastHit = castRay(player.x, player.y + player.h, player.z, fwdX, fwdY, fwdZ, player.viewUnderwater);
    if (lastHit.hit != 0 && lastHit.dist < CAN_BREAK_LENGTH) {
        player.faceBlock = 1;
        player.faceBlock_x = lastHit.mapX;
        player.faceBlock_y = lastHit.mapY;
        player.faceBlock_z = lastHit.mapZ;
    } else {
        player.faceBlock = 0;
    }

    int32_t rightX = sinYaw;
    int32_t rightY = 0;
    int32_t rightZ = -cosYaw;

    int32_t upX = multQ16(fwdY, rightZ) - multQ16(fwdZ, rightY);
    int32_t upY = multQ16(fwdZ, rightX) - multQ16(fwdX, rightZ);
    int32_t upZ = multQ16(fwdX, rightY) - multQ16(fwdY, rightX);

    int32_t aspect_fov = MULTQ16_CONST(TO_FIXED_CONST(VGA_W / VGA_H), FOV_FACTOR);
    int32_t step_scalar = MULTQ16_CONST(MULTQ16_CONST(TO_FIXED_CONST(2.0), FOV_FACTOR), TO_FIXED_CONST(1.0 / VGA_H));

    int32_t dirX0 = fwdX - multQ16(aspect_fov, rightX) + multQ16(FOV_FACTOR, upX);
    int32_t dirY0 = fwdY - multQ16(aspect_fov, rightY) + multQ16(FOV_FACTOR, upY);
    int32_t dirZ0 = fwdZ - multQ16(aspect_fov, rightZ) + multQ16(FOV_FACTOR, upZ);

    int32_t dirXdx = multQ16(rightX, step_scalar);
    int32_t dirYdx = multQ16(rightY, step_scalar);
    int32_t dirZdx = multQ16(rightZ, step_scalar);

    int32_t dirXdy = multQ16(upX, -step_scalar);
    int32_t dirYdy = multQ16(upY, -step_scalar);
    int32_t dirZdy = multQ16(upZ, -step_scalar);

    bridge_ptr[0] = player.x;
    bridge_ptr[1] = player.y;
    bridge_ptr[2] = player.y + player.h;
    bridge_ptr[3] = player.z;

    bridge_ptr[4] = dirX0; bridge_ptr[5] = dirY0; bridge_ptr[6] = dirZ0;
    bridge_ptr[7] = dirXdx; bridge_ptr[8] = dirYdx; bridge_ptr[9] = dirZdx;
    bridge_ptr[10] = dirXdy; bridge_ptr[11] = dirYdy; bridge_ptr[12] = dirZdy;

    bridge_ptr[13] = ((((int32_t) VGA_H) >> 1) + RSSHIFT(MUL(((int32_t)player.pitch-512), (int32_t)VGA_H), 8));
    bridge_ptr[14] = player.viewUnderwater;

    bridge_ptr[15] = player.faceBlock;
    bridge_ptr[16] = player.faceBlock_x;
    bridge_ptr[17] = player.faceBlock_y;
    bridge_ptr[18] = player.faceBlock_z;
}

// ==========================================
// 地圖生成
// ==========================================

static const int8_t TREE_TEMPLATE[][4] = {
        { 0, 1, 0, 4 }, { 0, 2, 0, 4 },
        {-2, 3,-2, 5 }, {-2, 3,-1, 5 }, {-2, 3, 0, 5 }, {-2, 3, 1, 5 }, {-2, 3, 2, 5 },
        {-1, 3,-2, 5 }, {-1, 3,-1, 5 }, {-1, 3, 0, 5 }, {-1, 3, 1, 5 }, {-1, 3, 2, 5 },
        { 0, 3,-2, 5 }, { 0, 3,-1, 5 }, { 0, 3, 0, 4 }, { 0, 3, 1, 5 }, { 0, 3, 2, 5 },
        { 1, 3,-2, 5 }, { 1, 3,-1, 5 }, { 1, 3, 0, 5 }, { 1, 3, 1, 5 }, { 1, 3, 2, 5 },
        { 2, 3,-2, 5 }, { 2, 3,-1, 5 }, { 2, 3, 0, 5 }, { 2, 3, 1, 5 }, { 2, 3, 2, 5 },
        {-2, 4,-2, 5 }, {-2, 4,-1, 5 }, {-2, 4, 0, 5 }, {-2, 4, 1, 5 }, {-2, 4, 2, 5 },
        {-1, 4,-2, 5 }, {-1, 4,-1, 5 }, {-1, 4, 0, 5 }, {-1, 4, 1, 5 }, {-1, 4, 2, 5 },
        { 0, 4,-2, 5 }, { 0, 4,-1, 5 }, { 0, 4, 0, 4 }, { 0, 4, 1, 5 }, { 0, 4, 2, 5 },
        { 1, 4,-2, 5 }, { 1, 4,-1, 5 }, { 1, 4, 0, 5 }, { 1, 4, 1, 5 }, { 1, 4, 2, 5 },
        { 2, 4,-2, 5 }, { 2, 4,-1, 5 }, { 2, 4, 0, 5 }, { 2, 4, 1, 5 }, { 2, 4, 2, 5 },
        {-1, 5, 0, 5 }, { 0, 5,-1, 5 }, { 0, 5, 0, 4 }, { 0, 5, 1, 5 }, { 1, 5, 0, 5 },
        {-1, 6, 0, 5 }, { 0, 6,-1, 5 }, { 0, 6, 0, 5 }, { 0, 6, 1, 5 }, { 1, 6, 0, 5 }
};

void placeTree(uint16_t x, uint16_t y, uint16_t z) {
    uint16_t i;
    for (i = 0; i < sizeof(TREE_TEMPLATE) / sizeof(TREE_TEMPLATE[0]); i++) {
        setBlock(
                (int16_t)x + TREE_TEMPLATE[i][0],
                (int16_t)y + TREE_TEMPLATE[i][1],
                (int16_t)z + TREE_TEMPLATE[i][2],
                TREE_TEMPLATE[i][3]
             );
    }
}

int16_t noise_1(int16_t nx, int16_t nz) {
    int32_t noise = LSSHIFT(multQ16(sin_t(LSHIFT(nx, 3)), cos_t(LSHIFT(nz, 3))), 3);
    noise += LSSHIFT(sin_t(LSHIFT(nx, 5) + LSHIFT(nz, 4)), 1);
    noise += multQ16(sin_t(LSHIFT(nx, 6)), cos_t(LSHIFT(nz, 5)));
    return RSSHIFT(noise, FRAC_BITS);
}
int16_t noise_2(int16_t nx, int16_t nz) {
    return RSSHIFT(LSSHIFT(multQ16(cos_t(LSHIFT(nx, 5)), cos_t(LSHIFT(nz, 5))), 1), FRAC_BITS);
}

void genMap(uint32_t seed) {
    IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);

    uint16_t x, y, z;

    rand32_init(seed);
    uint16_t offsetX = (rand32() & 0xFFFF);
    uint16_t offsetZ = (rand32() & 0xFFFF);
    for (x = 0; x < WORLD_X; x++) {
        for (z = 0; z < WORLD_Z; z++) {
            uint32_t base_word_index = LSHIFT((uint32_t)x, 14) | z;
            int16_t nx = x + offsetX;
            int16_t nz = z + offsetZ;
            int16_t stone = 50 - noise_1(nx, nz);
            int16_t grass = stone + 4 + noise_2(nx, nz);

            sram_8_ptr[base_word_index] = 15;
            uint8_t packed_block = 0x00;
            for (y = 1; y < WORLD_Y; y++) {
                if (y < stone) packed_block = 1;
                else if (y < grass) packed_block = 3;
                else if (y == grass) packed_block = 2;
                else packed_block = 0;
                sram_8_ptr[base_word_index | LSHIFT((uint32_t)y, 7)] = packed_block;
            }
            if (grass < 49) sram_8_ptr[base_word_index | (49 << 7)] = 6;
        }
        IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, LSHIFT(1, RSHIFT(x+1, 4))-1);
        printVGA(RSHIFT(x+1, 4)+1, 4, "=");
    }

    for (x = 0; x < WORLD_X/8; x++) {
        for (z = 0; z < WORLD_Z/8; z++) {
            uint16_t hashVal = MUL(x, 821) ^ MUL(z, 983) ^ seed;
            int16_t tx = LSHIFT(x, 3) + ((hashVal & 3) + 2);
            int16_t tz = LSHIFT(z, 3) + (((hashVal >> 1) & 3) + 2);

            uint8_t spawnChance = (RSHIFT(hashVal, 4)) & 0xFF;
            if (spawnChance > 150) {
                for(y=WORLD_Y-2;y>=0;y--){
                    uint8_t block = sram_8_ptr[(LSHIFT((uint32_t)tx, 14) | tz) | LSHIFT((uint32_t)y, 7)];
                    if(block != 0){
                        if(block != 2) y = 0;
                        break;
                    }
                }
                if(y>0) placeTree(tx, y, tz);
            }
        }
    }

    player.x = TO_FIXED_CONST(WORLD_X/2) + TO_FIXED_CONST(0.5);
    player.z = TO_FIXED_CONST(WORLD_Z/2) + TO_FIXED_CONST(0.5);
    for (y = WORLD_Y - 3; y > 0; y--) {
        if (sram_8_ptr[(((uint32_t)TO_INT_CONST(player.x)<<14) | LSHIFT((uint32_t)y, 7) | TO_INT_CONST(player.z))] != 0) {
            player.y = LSHIFT(y+5, FRAC_BITS);
            break;
        }
    }
}

void genMapFlat(){
    IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);

    uint16_t x, y, z;
    for (x = 0; x < WORLD_X; x++) {
        for (z = 0; z < WORLD_Z; z++) {
            uint32_t base_word_index = LSHIFT((uint32_t)x, 14) | z;

            sram_8_ptr[base_word_index] = 15;
            uint8_t packed_block = 0x00;
            for (y = 1; y < WORLD_Y; y++) {
                if (y < 5 ) packed_block = 3;
                else if (y == 5) packed_block = 2;
                else packed_block = 0;
                sram_8_ptr[base_word_index | LSHIFT((uint32_t)y, 7)] = packed_block;
            }
        }
        IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, LSHIFT(1, RSHIFT(x+1, 4))-1);
        printVGA(RSHIFT(x+1, 4)+1, 4, "=");
    }
    player.x = TO_FIXED_CONST(WORLD_X/2) + TO_FIXED_CONST(0.5);
    player.y = TO_FIXED_CONST(7);
    player.z = TO_FIXED_CONST(WORLD_Z/2) + TO_FIXED_CONST(0.5);
}

// ==========================================
// 移動與物理邏輯
// ==========================================

void movePlayer(int32_t dx, int32_t dy, int32_t dz) {
    if (!checkHitAABB(player.x + dx, player.y, player.z, player.w, player.h)) {
        player.x += dx;
    } else {
        if (dx > 0) player.x = toFixed(toInt(player.x) + 1) - player.w - 1;
        else        player.x = toFixed(toInt(player.x)) + player.w + 1;
    }

    if (!checkHitAABB(player.x, player.y + dy, player.z, player.w, player.h)) {
        player.y += dy;
        player.onGround = 0;
    } else {
        if (dy > 0){
            player.y = toFixed(toInt(player.y + player.h) + 1) - player.h - 1;
            player.onGround = 0;
        }else {
            player.y = toFixed(toInt(player.y)) + 1;
            player.onGround = 1;
        }
        player.vy = 0;
    }

    if (!checkHitAABB(player.x, player.y, player.z + dz, player.w, player.h)) {
        player.z += dz;
    } else {
        if (dz > 0) player.z = toFixed(toInt(player.z) + 1) - player.w - 1;
        else        player.z = toFixed(toInt(player.z)) + player.w + 1;
    }
}

void updatePlayerLogic(uint32_t keys) {
    if ((keys & KEY_C_UP) && player.pitch <= (512 + (256 - ROTATION_RATE))) player.pitch += ROTATION_RATE;
    if ((keys & KEY_C_DOWN) && player.pitch >= (512 - (256 - ROTATION_RATE))) player.pitch -= ROTATION_RATE;
    if (keys & KEY_C_LEFT) player.yaw = (player.yaw + ROTATION_RATE) & 0x3FF;
    if (keys & KEY_C_RIGHT) player.yaw = (player.yaw - ROTATION_RATE + 1024) & 0x3FF;

    int32_t speed = (keys & KEY_C_RUN) ? RUN_VELOCITY : VELOCITY;
    int32_t local_dx = 0, local_dz = 0;

    if (keys & KEY_C_W) local_dx += speed;
    if (keys & KEY_C_S) local_dx -= speed;
    if (keys & KEY_C_A) local_dz += speed;
    if (keys & KEY_C_D) local_dz -= speed;

    int32_t cosDir = cos_t(player.yaw - 512);
    int32_t sinDir = sin_t(player.yaw - 512);

    int32_t world_dx = multQ16(local_dx, cosDir) - multQ16(local_dz, sinDir);
    int32_t world_dz = multQ16(local_dx, sinDir) + multQ16(local_dz, cosDir);

    uint8_t c_block = getBlock(TO_INT_CONST(player.x), TO_INT_CONST(player.y), TO_INT_CONST(player.z));
    uint8_t h_block = getBlock(TO_INT_CONST(player.x), TO_INT_CONST(player.y + player.h), TO_INT_CONST(player.z));
    player.isUnderwater = (c_block >= 6 && c_block <= 9);
    player.viewUnderwater = (h_block >= 6 && h_block <= 9);

    if ((keys & KEY_C_JUMP)) {
        if (player.isUnderwater) player.vy = JUMP_VELOCITY_WATER;
        else if (player.onGround) player.vy = JUMP_VELOCITY;
    }

    if (player.isUnderwater) {
        player.vy -= GRAVITY;
        if (player.vy < -TERMINAL_VELOCITY_WATER) player.vy = -TERMINAL_VELOCITY_WATER;
    } else {
        player.vy -= GRAVITY;
        if (player.vy < -TERMINAL_VELOCITY) player.vy = -TERMINAL_VELOCITY;
    }

    movePlayer(world_dx, player.vy, world_dz);
}

// 實體按鍵處理邏輯
static uint8_t last_action_keys = 0x07;
void handleActionKeys() {
    uint8_t curr_keys = IORD_ALTERA_AVALON_PIO_DATA(ACTION_KEYS_BASE) & 0x03;
    uint8_t fall_edges = last_action_keys & ~curr_keys; // 尋找按下的負緣

    if (fall_edges & 0x01) breakBlockAction();     // 破壞
    if (fall_edges & 0x02) placeBlockAction();     // 放置
    last_action_keys = curr_keys;

    player.selectBlockType = IORD_ALTERA_AVALON_PIO_DATA(BLOCK_SELECT_BASE);
}


// ==========================================
// MAP SAVE
// ==========================================

#define SAVE_SLOT_NUM (0x07)
#define SD_BUF_SIZE 512

volatile uint8_t SD_inited=0;

uint8_t SaveMapExist(uint8_t slot){
    if(!SD_inited) return 0;

    FILINFO fno;

    char filename[] = "WORLD_0.BIN";
    filename[6]=48+(slot & SAVE_SLOT_NUM);

    FRESULT res = f_stat(filename, &fno);

    if(res == FR_OK) return 1;
    return 0;
}
void RemoveMapSave(uint8_t slot){
    char filename[] = "WORLD_0.BIN";
    filename[6]=48+(slot & SAVE_SLOT_NUM);
    f_unlink(filename);
}
uint8_t SaveMapToSD(uint8_t slot) {
    if(!SD_inited) return 0;

    FIL file;
    UINT bw;
    FRESULT res;
    uint8_t success = 1;

    char filename[] = "WORLD_0.BIN";
    filename[6] = 48 + (slot & SAVE_SLOT_NUM);

    PRINT_LOG("Saving Map to %s...\n", filename);

    res = f_open(&file, filename, FA_WRITE | FA_CREATE_ALWAYS);
    
    if (res == FR_OK) {
        // 先寫入玩家狀態 (不壓縮)
        res = f_write(&file, (void*)&player, sizeof(player), &bw);
        if (res != FR_OK || bw != sizeof(player)) {
            success = 0;
            f_close(&file);
            return success;
        }

        // --- RLE 壓縮與緩衝區初始化 ---
        uint8_t buffer[SD_BUF_SIZE];
        uint32_t buf_idx = 0;
        uint32_t compressed_size = 0;
        
        uint8_t current_block = sram_8_ptr[0];
        uint8_t run_count = 1;
        
        uint32_t chunk_threshold = MAP_SIZE >> 3; // 用來更新進度條的門檻 (每 1/8 更新一次)
        uint8_t progress_step = 0;

        IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);

        // 定義一個局部巨集來處理 Buffer 寫入，讓程式碼乾淨
        #define PUSH_BYTE(b) do { \
            buffer[buf_idx++] = (b); \
            if (buf_idx == SD_BUF_SIZE) { \
                f_write(&file, buffer, SD_BUF_SIZE, &bw); \
                if (bw != SD_BUF_SIZE) success = 0; \
                compressed_size += bw; \
                buf_idx = 0; \
            } \
        } while(0)

        uint32_t i;
        // 開始掃描 2MB 的 SRAM
        for (i = 1; i < MAP_SIZE; i++) {
            uint8_t next_block = sram_8_ptr[i];

            if (next_block == current_block && run_count < 127) {
                run_count++;
            } else {
                // 結算上一批方塊
                if (run_count >= 3) {
                    PUSH_BYTE(0x80 | run_count); // 寫入 Flag (MSB = 1) 與次數
                    PUSH_BYTE(current_block);    // 寫入方塊 ID
                } else {
                	uint8_t c;
                    for (c = 0; c < run_count; c++) {
                        PUSH_BYTE(current_block); // 原樣寫入 (MSB 必為 0)
                    }
                }
                // 更新狀態
                current_block = next_block;
                run_count = 1;
            }

            // 更新進度條
            if (i == (progress_step + 1) * chunk_threshold) {
                progress_step++;
                IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, (1 << progress_step) - 1);
                printVGA(progress_step, 4, "=");
            }
        }

        // 寫入收尾的最後一批方塊
        if (run_count >= 3) {
            PUSH_BYTE(0x80 | run_count);
            PUSH_BYTE(current_block);
        } else {
            uint8_t c;
            for (c = 0; c < run_count; c++) {
                PUSH_BYTE(current_block);
            }
        }

        // 將 Buffer 內剩餘的尾巴資料寫入 SD 卡
        if (buf_idx > 0 && success) {
            f_write(&file, buffer, buf_idx, &bw);
            compressed_size += bw;
            if (bw != buf_idx) success = 0;
        }

        if (success) {
            PRINT_LOG("Save Complete! Compressed from %u to %u bytes.\n", MAP_SIZE, compressed_size);
            
            IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0xFF);
            printVGA(8, 4, "=");
        } else {
            PRINT_LOG("Write Error! SD Card might be full or pulled out.\n");
        }
        
        f_close(&file);
    } else {
        PRINT_LOG("Failed to create file! Error Code: %d\n", res);
        success = 0;
    }
    return success;
}

uint8_t LoadMapFromSD(uint8_t slot) {
    if(!SD_inited) return 0;

    FIL file;
    UINT br;
    FRESULT res;
    uint8_t success = 1;

    char filename[] = "WORLD_0.BIN";
    filename[6] = 48 + (slot & SAVE_SLOT_NUM);

    PRINT_LOG("Loading Map from %s...\n", filename);

    res = f_open(&file, filename, FA_READ);
    
    if (res == FR_OK) {
        // 先讀取玩家狀態 (不壓縮)
        res = f_read(&file, (void*)&player, sizeof(player), &br);
        if(res != FR_OK || br != sizeof(player)){
            success = 0;
            f_close(&file);
            return success;
        }

        // --- RLE 解壓縮與緩衝區初始化 ---
        uint8_t buffer[SD_BUF_SIZE];
        uint32_t buf_idx = SD_BUF_SIZE; // 故意設為滿，強迫第一次迴圈進行讀取
        br = SD_BUF_SIZE;
        
        uint32_t sram_ptr_idx = 0;
        uint32_t chunk_threshold = MAP_SIZE >> 3;
        uint8_t progress_step = 0;

        IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);

        // 巨集：從 Buffer 拿取 1 個 Byte，若 Buffer 空了自動向 SD 卡要資料
        #define FETCH_BYTE(out_var) do { \
            if (buf_idx >= br) { \
                f_read(&file, buffer, SD_BUF_SIZE, &br); \
                buf_idx = 0; \
                if (br == 0) { success = 0; break; } /* EOF 提早發生 */ \
            } \
            out_var = buffer[buf_idx++]; \
        } while(0)

        // 開始還原 2MB 的地圖資料到 SRAM
        while (sram_ptr_idx < MAP_SIZE && success) {
            uint8_t val;
            FETCH_BYTE(val);
            if (!success) break;

            if (val & 0x80) {
                // 最高位為 1：這是壓縮標籤 [Flag + Count]
                uint8_t count = val & 0x7F;
                uint8_t block_id;
                FETCH_BYTE(block_id); // 讀取下一個 Byte 作為方塊 ID
                if (!success) break;
                
                uint8_t c;
                // 連續寫入 SRAM
                for (c = 0; c < count; c++) {
                    if (sram_ptr_idx < MAP_SIZE) {
                        sram_8_ptr[sram_ptr_idx++] = block_id;
                    }
                }
            } else {
                // 最高位為 0：這是單一方塊
                sram_8_ptr[sram_ptr_idx++] = val;
            }

            // 更新進度條 (依據已還原的 SRAM 大小)
            if (sram_ptr_idx >= (progress_step + 1) * chunk_threshold) {
                progress_step++;
                IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, (1 << progress_step) - 1);
                printVGA(progress_step, 4, "=");
            }
        }

        if (success) {
            PRINT_LOG("Load Complete! Map ready.\n");            
        } else {
            PRINT_LOG("Read Error or File corrupted!\n");
        }
        
        calcPlayStatus();
        f_close(&file);
        
    } else if (res == FR_NO_FILE) {
        PRINT_LOG("No save file found. Please generate a new map.\n");
        success = 0;
    } else {
        PRINT_LOG("Failed to open file! Error Code: %d\n", res);
        success = 0;
    }
    return success;
}


struct {
    uint8_t up, down, left, right, enter;
    uint8_t up_pressed, down_pressed, left_pressed, right_pressed, enter_pressed;
} g_input;

void update_inputs() {
    uint8_t curr_up = getKeyboard(KEY_2_BASE, KEY_UP_ARROW);
    uint8_t curr_down = getKeyboard(KEY_2_BASE, KEY_DOWN_ARROW);
    uint8_t curr_left = getKeyboard(KEY_2_BASE, KEY_LEFT_ARROW);
    uint8_t curr_right = getKeyboard(KEY_2_BASE, KEY_RIGHT_ARROW);
    uint8_t curr_enter = getKeyboard(KEY_2_BASE, KEY_ENTER);
    
    g_input.up_pressed = (!g_input.up && curr_up);
    g_input.down_pressed = (!g_input.down && curr_down);
    g_input.left_pressed = (!g_input.left && curr_left);
    g_input.right_pressed = (!g_input.right && curr_right);
    g_input.enter_pressed = (!g_input.enter && curr_enter);
    
    g_input.up = curr_up;
    g_input.down = curr_down;
    g_input.left = curr_left;
    g_input.right = curr_right;
    g_input.enter = curr_enter;
}

static inline void set_mode(uint8_t mode) {
    IOWR_ALTERA_AVALON_PIO_DATA(MODE_BASE, mode);
}

#define BGM_SIZE 16384

uint8_t bgm_ctrl=0;
uint32_t bgm_ctrl_time=0;
static inline void bgm_play(uint8_t song) {
    IOWR_ALTERA_AVALON_PIO_DATA(BGM_CTRL_BASE, 0x80 | (song&0x3F));
    bgm_ctrl_time=millis();
    bgm_ctrl=1;
}
static inline void bgm_set(uint8_t song) {
    IOWR_ALTERA_AVALON_PIO_DATA(BGM_CTRL_BASE, 0x00 | (song&0x3F));
    bgm_ctrl_time=millis();
    bgm_ctrl=1;
}
static inline void bgm_stop() {
    IOWR_ALTERA_AVALON_PIO_DATA(BGM_CTRL_BASE, 0x40);
    bgm_ctrl_time=millis();
    bgm_ctrl=1;
}
static inline void bgm_update(){
    if(!bgm_ctrl) return;
    if(millis()-bgm_ctrl_time>10){
        IOWR_ALTERA_AVALON_PIO_DATA(BGM_CTRL_BASE, 0x00);
        bgm_ctrl=0;
    }
}
static inline uint8_t bgm_playing(){
    return IORD_ALTERA_AVALON_PIO_DATA(BGM_STATE_BASE) & 0x01;
}

static inline uint8_t bgm_init_from_sd(){
    if (!SD_inited) return 0;

    FIL file;
    UINT br;
    FRESULT res;
    
    res = f_open(&file, "BGM.BIN", FA_READ);
    if (res == FR_OK) {
        PRINT_LOG("Found BGM.BIN, loading custom BGM...\n");
        
        res = f_read(&file, (void*)bgm_ram_ptr, BGM_SIZE, &br); 
        
        f_close(&file);
        
        if (res == FR_OK) {
            PRINT_LOG("Custom BGM Loaded successfully! (%d bytes)\n", br);
            return 1;
        }
    }
    PRINT_LOG("Using default internal BGM.\n");
    return 0;
}

// ==========================================
// MAIN 與 ISR
// ==========================================

enum STATE {
    IDLE,
    MENU,
    MENU_LOOP,
    MAP_GEN,
    MAP_GEN_LOOP,
    LOAD,
    LOAD_LOOP,
    SAVE,
    SAVE_LOOP,
    GAME,
    STOP,
    STOP_LOOP
};

volatile uint8_t state = IDLE;

volatile uint8_t game_tick = 0;
volatile uint8_t stop_game = 0;

volatile uint8_t mount_sd = 1;

uint32_t bgm_cooldown_start = 0;
uint32_t bgm_cooldown_duration = 0;
uint8_t  bgm_in_cooldown = 0;
uint8_t  current_game_song = 0;

int main() {
    set_mode(0);

    init_tick_interrupt();
    init_state_key_interrupt();
    init_mount_sd_interrupt();

    uint8_t water_tick_counter = 0;

    uint8_t select=0, temp=0;

    uint8_t use_slot=8;

    while (1) {
        if(mount_sd){
            mount_sd=0;

            PRINT_LOG("Mounting SD Card...\n");
            FRESULT res = f_mount(&fs, "", 1); 
            if (res == FR_OK) {
                SD_inited = 1;
                PRINT_LOG("SD Card Ready! FAT32 File System Mounted.\n");
                
                bgm_init_from_sd();
            } else {
                PRINT_LOG("SD Card Mount Failed! Error Code: %d\n", res);
            }
        }


        switch(state){
            case MENU:
            case MENU_LOOP:
            case LOAD:
            case LOAD_LOOP:
            case MAP_GEN:
            case MAP_GEN_LOOP:
                if(!bgm_playing()) {
                    current_game_song = 0;
                    bgm_play(0); 
                }
                break;

            case GAME:
                if (!bgm_playing()) {
                    if (!bgm_in_cooldown) {
                        bgm_in_cooldown = 1;
                        bgm_cooldown_start = millis();
                        
                        bgm_cooldown_duration = 3000 + (rand32() & 0x3FFF);
                        
                        bgm_set(0);
                    } else {
                        if ((millis() - bgm_cooldown_start) > bgm_cooldown_duration) {
                            bgm_in_cooldown = 0;
                            
                            uint32_t r = rand32() & 0x01;
                            current_game_song = current_game_song + 1 + r;

                            if (current_game_song > 3) {
                                current_game_song -= 3;
                            }
                            
                            bgm_play(current_game_song);
                            PRINT_LOG("Playing Game BGM: %d\n", current_game_song);
                        }
                    }
                } else {
                    if(current_game_song == 0) bgm_stop();
                    bgm_in_cooldown = 0;
                }
                break;

            case STOP:
            case STOP_LOOP:
            case SAVE:
            case SAVE_LOOP:
            default:
                if (bgm_playing()) {
                    current_game_song = 0;
                    bgm_stop();
                }
                break;
        }
        bgm_update();


        switch(state){
            case IDLE:{
                calcPlayStatus();

                clearVGAText();
                state = MENU;
                break;
            }
            case MENU:{
                set_mode(1);
                IOWR_ALTERA_AVALON_PIO_DATA(VGA_CLEAR_BASE, 0x0102);
                printVGA(0, 1, "MINECRAFT!");
                printVGA(0, 3, "   PLAY");
                printVGA(0, 4, "   LOAD");
                select=0;
                stop_game=0;

                state = MENU_LOOP;
                break;
            }
            case MENU_LOOP:{
                update_inputs();
                printVGA(1, 3, (select==0)?">":" "); printVGA(1, 4, (select==1)?">":" ");
                if(g_input.up_pressed){
                    select=select>0?select-1:1;
                }else if(g_input.down_pressed){
                    select=select<1?select+1:0;
                }else if(g_input.enter_pressed){
                    switch(select){
                        case 0:
                            state = MAP_GEN;
                            break;
                        case 1:
                            state = LOAD;
                            break;
                        default:
                            state = MENU;
                    }
                }
                break;
            }
            case LOAD:{
                set_mode(3);
                clearVGAText();
                printVGA(1, 1, "LOAD MAP");
                printVGA(0, 4, "   LOAD");
                printVGA(0, 5, "   REMOVE");
                printVGA(0, 6, "   EXIT");

                IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);
                
                for(temp=0;temp<8;temp++)
                    if(SaveMapExist(temp)) break;
                if(temp!=8){
                    printVGA(0, 2, " WORLD_0");
                    temp=temp & SAVE_SLOT_NUM;
                    printVGAChar(7, 2, temp+'0');
                }else{
                    printVGA(0, 2, "  EMPTY!");
                }

                if(!SD_inited) mount_sd=1;

                select=0;
                stop_game = 0;
                state = LOAD_LOOP;
                break;
            }
            case LOAD_LOOP:{
                if(stop_game){
                    clearVGAText();
                    select=0;
                    state = MENU;
                    break;
                }
                update_inputs();
                printVGA(1, 4, (select==0)?">":" "); printVGA(1, 5, (select==1)?">":" "); printVGA(1, 6, (select==2)?">":" ");
                if(g_input.up_pressed){
                    select=select>0?select-1:2;
                }else if(g_input.down_pressed){
                    select=select<2?select+1:0;
                }if(g_input.right_pressed){
                    uint8_t i;
                    for(i=0;i<8;i++)
                        if(SaveMapExist((temp+i+1) & SAVE_SLOT_NUM)) break;
                    if(i!=8){
                        temp = (temp+i+1) & SAVE_SLOT_NUM;
                        printVGAChar(7, 2, temp+'0');
                    }else printVGA(0, 2, "  EMPTY!");
                }else if(g_input.left_pressed){
                    uint8_t i;
                    for(i=0;i<8;i++)
                        if(SaveMapExist((temp-(i+1)+8) & SAVE_SLOT_NUM)) break;
                    if(i!=8){
                        temp = (temp-(i+1)+8) & SAVE_SLOT_NUM;
                        printVGAChar(7, 2, temp+'0');
                    }else printVGA(0, 2, "  EMPTY!");
                }else if(g_input.enter_pressed){
                    switch(select){
                        case 0:
                            clearVGAText();
                            if(!SaveMapExist(temp)){
                                state = LOAD;
                                break;
                            }
                            printVGA(0, 1, "   LOAD");
                            printVGA(0, 4, "[        ]");

                            uint8_t success=LoadMapFromSD(temp);
                            delay(500);
                            
                            if(success) printVGA(0, 4, " SUCCESS! ");
                            else printVGA(0, 4, "  FAILED! ");

                            delay(1000);
                            clearVGAText();
                            printVGA(0, 3, "START GAME");
                            delay(1000);

                            if(success){
                                use_slot=temp;
                                stop_game=0;
                                clearVGAText();
                                IOWR_ALTERA_AVALON_PIO_DATA(VGA_CLEAR_BASE, 0x0000);
                                state = GAME; set_mode(5);
                            }else{
                                state = LOAD;
                            }
                            break;
                        case 1:
                            RemoveMapSave(temp);
                            for(temp=0;temp<8;temp++)
                                if(SaveMapExist(temp)) break;
                            if(temp!=8){
                                printVGA(0, 2, " WORLD_0 ");
                                temp=temp & 0x0F;
                                printVGAChar(7, 2, temp+'0');
                            }else{
                                printVGA(0, 2, "  EMPTY!");
                            }
                            break;
                        case 2:
                            clearVGAText();
                            state = MENU;
                            break;
                    }
                    stop_game = 0;
                    select=0;
                }
                break;
            }
            case MAP_GEN:{
                set_mode(4);
                clearVGAText();
                printVGA(0, 2, "SEED: RAND");
                printVGA(0, 3, "    Flat");
                printVGA(0, 5, "   START");

                IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);

                select=1; temp=0;
                stop_game = 0;
                state = MAP_GEN_LOOP;
                break;
            }
            case MAP_GEN_LOOP:{
                if(stop_game){
                    clearVGAText();
                    select=0;
                    state = MENU;
                    break;
                }
                update_inputs();
                printVGA(1, 3, (select==0)?">":" "); printVGA(1, 5, (select==1)?">":" ");
                uint32_t seed = IORD_ALTERA_AVALON_PIO_DATA(SEED_BASE);
                if(seed==0) printVGA(5, 2, " RAND");
                else sprintf((char*)(vga_text_ptr+2*10+5), "%05X", (unsigned int)seed);
                if(g_input.up_pressed){
                    select=select>0?select-1:1;
                }else if(g_input.down_pressed){
                    select=select<1?select+1:0;
                }else if(g_input.enter_pressed){
                    switch(select){
                        case 0:
                            temp=!temp;
                            printVGA(2, 3, temp?"*":" ");
                            break;
                        case 1:
                            clearVGAText();
                            printVGA(0, 1, "   MAP    ");
                            printVGA(0, 2, " Generate ");
                            printVGA(0, 4, "[        ]");

                            PRINT_LOG("Map Gen Start.\n");
                            uint32_t seed =  IORD_ALTERA_AVALON_PIO_DATA(SEED_BASE);
                            if(temp) genMapFlat();
                            else genMap((seed==0)?millis():seed);
                            calcPlayStatus();
                            PRINT_LOG("Map Gen Finish.\n");
                            
                            printVGA(0, 4, "  Finish! ");
                            delay(1000);
                            clearVGAText();
                            printVGA(0, 3, "START GAME");
                            delay(1000);
                            clearVGAText();

                            IOWR_ALTERA_AVALON_PIO_DATA(VGA_CLEAR_BASE, 0x0000);

                            use_slot=8;

                            stop_game = 0;
                            state = GAME; set_mode(5);
                            break;
                    }
                }
                break;
            }
            case GAME:{
                if(stop_game) {
                    stop_game = 0;
                    state = STOP;
                    break;
                }

                if (game_tick) {
                    game_tick = 0;

                    uint32_t keys = IORD_ALTERA_AVALON_PIO_DATA(MOVE_CTRL_BASE);
                    updatePlayerLogic(keys);
                    handleActionKeys();

                    water_tick_counter++;
                    if (water_tick_counter >= 8) { // 20 TPS / 8 = 5 TPS (水流速度)
                        water_tick_counter = 0;
                        waterSim();
                    }

                    calcPlayStatus();
                }
                break;
            }
            case STOP:{
                set_mode(6);
                IOWR_ALTERA_AVALON_PIO_DATA(VGA_CLEAR_BASE, 0x0102);
                clearVGAText();

                printVGA(0, 2, "  BACK");
                printVGA(0, 3, "  SAVE");
                printVGA(0, 4, "  EXIT");

                select=0;
                stop_game=0;
                state = STOP_LOOP;
                break;
            }
            case STOP_LOOP:{
                if(stop_game) {
                    stop_game = 0;
                    clearVGAText();
                    IOWR_ALTERA_AVALON_PIO_DATA(VGA_CLEAR_BASE, 0x0000);
                    state = GAME; set_mode(5);
                    break;
                }
                update_inputs();
                printVGA(1, 2, (select==0)?">":" "); printVGA(1, 3, (select==1)?">":" "); printVGA(1, 4, (select==2)?">":" ");
                if(g_input.up_pressed){
                    select=select>0?select-1:2;
                }else if(g_input.down_pressed){
                    select=select<2?select+1:0;
                }else if(g_input.enter_pressed){
                    clearVGAText();
                    switch(select){
                        case 0:
                            IOWR_ALTERA_AVALON_PIO_DATA(VGA_CLEAR_BASE, 0x0000);
                            state = GAME; set_mode(5);
                            break;
                        case 1:
                            state = SAVE;
                            break;
                        case 2:
                            state = MENU;
                            break;
                    }
                    stop_game = 0;
                }
                break;
            }
            case SAVE:{
                set_mode(2);
                printVGA(0, 1, "   SAVE");
                printVGA(0, 3, " WORLD_0 ");
                printVGA(0, 5, "   SAVE");
                printVGA(0, 6, "   EXIT");

                IOWR_ALTERA_AVALON_PIO_DATA(PROGRESS_BASE, 0x00);
                
                if(!SD_inited) mount_sd=1;
                
                if(use_slot!=8){
                    temp=use_slot;
                }else{
                    for(temp=0;temp<8;temp++)
                        if(!SaveMapExist(temp)) break;
                    temp=temp & 0x0F;
                }
                if(!SaveMapExist(temp)) printVGA(2, 4, "[NEW] ");
                else if(temp==use_slot) printVGA(2, 4, "[USED]");
                else printVGA(2, 4, "      ");
                printVGAChar(7, 3, temp+'0');

                select=0;
                state = SAVE_LOOP;
                break;
            }
            case SAVE_LOOP:{
                if(stop_game) {
                    stop_game = 0;
                    clearVGAText();
                    state = STOP;
                    break;
                }

                update_inputs();
                printVGA(1, 5, (select==0)?">":" "); printVGA(1, 6, (select==1)?">":" ");
                if(g_input.up_pressed){
                    select=select>0?select-1:1;
                }else if(g_input.down_pressed){
                    select=select<1?select+1:0;
                }if(g_input.right_pressed){
                    temp=(temp+1) & SAVE_SLOT_NUM;
                    if(!SaveMapExist(temp)) printVGA(2, 4, "[NEW] ");
                    else if(temp==use_slot) printVGA(2, 4, "[USED]");
                    else printVGA(2, 4, "      ");
                    printVGAChar(7, 3, temp+'0');
                }else if(g_input.left_pressed){
                    temp=(temp+7) & SAVE_SLOT_NUM;
                    if(!SaveMapExist(temp)) printVGA(2, 4, "[NEW] ");
                    else if(temp==use_slot) printVGA(2, 4, "[USED]");
                    else printVGA(2, 4, "      ");
                    printVGAChar(7, 3, temp+'0');
                }else if(g_input.enter_pressed){
                    clearVGAText();
                    switch(select){
                        case 0:
                            clearVGAText();
                            printVGA(0, 1, "   SAVE");
                            printVGA(0, 4, "[        ]");

                            uint8_t success=SaveMapToSD(temp);
                            delay(500);
                            
                            if(success) printVGA(0, 4, " SUCCESS! ");
                            else printVGA(0, 4, "  FAILED! ");

                            delay(1000);

                            state = STOP;
                            break;
                        case 1:
                            state = STOP;
                            break;
                    }
                    stop_game = 0;
                    select=0;
                }
                break;
            }

            default:
                state = IDLE;
                break;
        }
    }
    return 0;
}


static void tick_isr(void* context) {
    uint32_t status = IORD_ALTERA_AVALON_PIO_EDGE_CAP(GAME_TICK_BASE);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(GAME_TICK_BASE, status);
    if (status & 0x01) game_tick = 1;
}
void init_tick_interrupt() {
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(GAME_TICK_BASE, 0x01);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(GAME_TICK_BASE, 0);
    alt_ic_isr_register(GAME_TICK_IRQ_INTERRUPT_CONTROLLER_ID, GAME_TICK_IRQ, tick_isr, NULL, NULL);
}

static void state_key_isr(void* context) {
    uint32_t status = IORD_ALTERA_AVALON_PIO_EDGE_CAP(STATE_KEY_BASE);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(STATE_KEY_BASE, status);
    if (status & 0x01) stop_game = 1;
}
void init_state_key_interrupt() {
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(STATE_KEY_BASE, 0x01);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(STATE_KEY_BASE, 0);
    alt_ic_isr_register(STATE_KEY_IRQ_INTERRUPT_CONTROLLER_ID, STATE_KEY_IRQ, state_key_isr, NULL, NULL);
}

static void mount_sd_isr(void* context) {
    uint32_t status = IORD_ALTERA_AVALON_PIO_EDGE_CAP(SD_MOUNT_BASE);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(SD_MOUNT_BASE, status);
    if (status & 0x01) mount_sd = 1;
}
void init_mount_sd_interrupt() {
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(SD_MOUNT_BASE, 0x01);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(SD_MOUNT_BASE, 0);
    alt_ic_isr_register(SD_MOUNT_IRQ_INTERRUPT_CONTROLLER_ID, SD_MOUNT_IRQ, mount_sd_isr, NULL, NULL);
}
