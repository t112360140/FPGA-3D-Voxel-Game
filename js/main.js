// const vga=new VGA('VGA', 480, 640, 1);
// const vga=new VGA('VGA', 240, 320, 2);
const vga=new VGA('VGA', 120, 160, 4);
// const vga=new VGA('VGA', 60, 80, 8);
// const vga=new VGA('VGA', 30, 40, 16);
// const vga=new VGA('VGA', 15, 20, 32);
vga.draw();

const WORLD_X=128, WORLD_Y=128, WORLD_Z=128;
const block_bit=8;
let map=new Uint16Array(WORLD_X*WORLD_Y*WORLD_Z*(block_bit/16));

var MAX_LENGTH=24;      // 顯示距離
var FOV_FACTOR=1.0;    // 視野廣度，1.0 大約是 90 度 FOV

const TPS=40;
const WATER_TPS=5;
const FPS=15;
const VELOCITY=3;   //m/s
const RUN_VELOCITY=5;   //m/s
const ROTATION_RATE=200;    //(1024*(度/360))/s
const GRAVITY=30;  //m/s*s
const TERMINAL_VELOCITY=60;  //m/s
const TERMINAL_VELOCITY_IN_WATER=2;  //m/s

const CAN_BREAK_LENGTH=6;

const player={
    x: toFixed(WORLD_X>>1)+toFixed(0.5),
    y: toFixed(64),
    z: toFixed(WORLD_Z>>1)+toFixed(0.5),

    h: toFixed(1.8),
    w: toFixed(0.3),

    vy: 0,
    
    // 視角也可以用定點數！
    // 假設一圈 360 度被我們量化成 1024 個單位 (10-bit 角度)
    yaw: 512,   // 0 ~ 1023
    pitch: 512,

    faceBlock: null,
    isUnderwater: false,
    viewUnderwater: false,
    onGround: false,
    selectBlockType: 1,
}


const WORLD_X_bit=Math.log2(WORLD_X);
const WORLD_Y_bit=Math.log2(WORLD_Y);
const WORLD_Z_bit=Math.log2(WORLD_Z);


const C_STONE  = (4 << 5) | (4 << 2) | 2; // 灰色
const C_STONE_D= (3 << 5) | (3 << 2) | 1; // 暗灰色 (石頭紋路)
const C_DIRT   = (3 << 5) | (2 << 2) | 0; // 棕色
const C_DIRT_D = (2 << 5) | (1 << 2) | 0; // 暗棕色 (泥土顆粒)
const C_GRASS  = (1 << 5) | (5 << 2) | 1; // 綠色
const C_GRASS_D= (1 << 5) | (4 << 2) | 0; // 暗綠色 (草地細節)
const C_LEAF  = (1 << 5) | (4 << 2) | 0; // 綠色
const C_LEAF_D= (0 << 5) | (3 << 2) | 0; // 暗綠色
const C_WOOD  = (3 << 5) | (1 << 2) | 0; // 棕色
const C_WOOD_W = (4 << 5) | (4 << 2) | 1; // 白棕色
const C_WOOD_D = (1 << 5) | (1 << 2) | 0; // 暗棕色
const C_WATER  = (3 << 5) | (3 << 2) | 3; // 藍色
const C_WATER_D = (1 << 5) | (1 << 2) | 2; // 暗藍色
const C_WHITE  = (5 << 5) | (5 << 2) | 3; // 白色
const C_BLACK  = (0 << 5) | (0 << 2) | 0; // 黑色
// 4x4 貼圖庫 (Texture ROM)
const TEX = [
    // 石頭 (隨機點綴暗色斑塊)  //offset: 0
        C_STONE, C_STONE_D, C_STONE, C_STONE,
        C_STONE, C_STONE, C_STONE, C_STONE_D,
        C_STONE, C_STONE_D, C_STONE, C_STONE,
        C_STONE, C_STONE, C_STONE_D, C_STONE,
    // 純泥土 (用於草地底部或純泥土塊)  //offset: 1
        C_DIRT, C_DIRT_D, C_DIRT, C_DIRT,
        C_DIRT, C_DIRT, C_DIRT_D, C_DIRT,
        C_DIRT_D, C_DIRT, C_DIRT, C_DIRT_D,
        C_DIRT, C_DIRT_D, C_DIRT, C_DIRT,
    // 草地頂面 (純草)  //offset: 2
        C_GRASS, C_GRASS_D, C_GRASS, C_GRASS,
        C_GRASS_D, C_GRASS, C_GRASS, C_GRASS_D,
        C_GRASS, C_GRASS, C_GRASS_D, C_GRASS,
        C_GRASS, C_GRASS_D, C_GRASS, C_GRASS,
    // 草地側面 (上半綠草，下半泥土)  //offset: 3
        C_GRASS, C_GRASS_D, C_GRASS, C_GRASS, // Y=3 (方塊最上緣)
        C_GRASS_D, C_GRASS, C_GRASS, C_DIRT,  // Y=2 (交界處)
        C_DIRT, C_DIRT_D, C_DIRT, C_DIRT,     // Y=1
        C_DIRT_D, C_DIRT, C_DIRT_D, C_DIRT,    // Y=0 (方塊最下緣)
    // 木頭頂面  //offset: 4
        C_WOOD, C_WOOD, C_WOOD, C_WOOD,
        C_WOOD, C_WOOD_W, C_WOOD_W, C_WOOD,
        C_WOOD, C_WOOD_W, C_WOOD_W, C_WOOD,
        C_WOOD, C_WOOD, C_WOOD, C_WOOD,
    // 木頭側面  //offset: 5
        C_WOOD_D, C_WOOD, C_WOOD, C_WOOD,
        C_WOOD_D, C_WOOD, C_WOOD_D, C_WOOD,
        C_WOOD, C_WOOD, C_WOOD_D, C_WOOD,
        C_WOOD, C_WOOD, C_WOOD_D, C_WOOD,
    // 樹葉  //offset: 6
        C_LEAF, C_LEAF, C_LEAF, C_LEAF_D,
        C_LEAF_D, C_LEAF, C_LEAF_D, C_LEAF,
        C_LEAF, C_LEAF, C_LEAF, C_LEAF_D,
        C_LEAF, C_LEAF_D, C_LEAF, C_LEAF,
    // 水  //offset: 7
        C_WATER_D, C_WATER, C_WATER, C_WATER_D,
        C_WATER_D, C_WATER, C_WATER_D, C_WHITE,
        C_WHITE, C_WATER, C_WATER_D, C_WATER,
        C_WATER, C_WATER, C_WATER_D, C_WATER_D,
    // 純黑  //offset: 8
        C_BLACK, C_BLACK, C_BLACK, C_BLACK,
        C_BLACK, C_BLACK, C_BLACK, C_BLACK,
        C_BLACK, C_BLACK, C_BLACK, C_BLACK,
        C_BLACK, C_BLACK, C_BLACK, C_BLACK,
];
/*
0: 空氣
1: 石頭
2: 草地
3: 泥土
4: 木頭
5: 葉子

15: 基岩
*/
const CAN_PLACE_LIST=[1, 2, 3, 4, 5, 6];
const BLOCK_INFO = {    //[頂部材質、側邊材質、底部材質、{可穿透、可破壞}]
    0: [7, 7, 7, 1, 0, 0, 0, 0],     // 空氣
    1: [0, 0, 0, 0, 1, 0, 0, 0],     // 石頭
    2: [2, 3, 1, 0, 1, 0, 0, 0],     // 草地
    3: [1, 1, 1, 0, 1, 0, 0, 0],     // 泥土
    4: [4, 5, 4, 0, 1, 0, 0, 0],     // 木頭
    5: [6, 6, 6, 0, 1, 0, 0, 0],     // 葉子
    6: [7, 7, 7, 1, 0, 0, 0, 0],     // 水
    7: [7, 7, 7, 1, 0, 0, 0, 0],     // 水
    8: [7, 7, 7, 1, 0, 0, 0, 0],     // 水
    9: [7, 7, 7, 1, 0, 0, 0, 0],     // 水
    10: [8, 8, 8, 0, 1, 0, 0, 0],    // 
    11: [8, 8, 8, 0, 1, 0, 0, 0],    // 
    12: [8, 8, 8, 0, 1, 0, 0, 0],    // 
    13: [8, 8, 8, 0, 1, 0, 0, 0],    // 
    14: [8, 8, 8, 0, 1, 0, 0, 0],    // 
    15: [8, 8, 8, 0, 0, 0, 0, 0],    // 
};

const TREE_TEMPLATE = [
    // 樹幹
    [0, 1, 0, 4], [0, 2, 0, 4],  
    
    [-2, 3, -2, 5], [-2, 3, -1, 5], [-2, 3, 0, 5], [-2, 3, 1, 5], [-2, 3, 2, 5],
    [-1, 3, -2, 5], [-1, 3, -1, 5], [-1, 3, 0, 5], [-1, 3, 1, 5], [-1, 3, 2, 5],
    [ 0, 3, -2, 5], [ 0, 3, -1, 5], [ 0, 3, 0, 4], [ 0, 3, 1, 5], [ 0, 3, 2, 5],
    [ 1, 3, -2, 5], [ 1, 3, -1, 5], [ 1, 3, 0, 5], [ 1, 3, 1, 5], [ 1, 3, 2, 5],
    [ 2, 3, -2, 5], [ 2, 3, -1, 5], [ 2, 3, 0, 5], [ 2, 3, 1, 5], [ 2, 3, 2, 5],
    
    [-2, 4, -2, 5], [-2, 4, -1, 5], [-2, 4, 0, 5], [-2, 4, 1, 5], [-2, 4, 2, 5],
    [-1, 4, -2, 5], [-1, 4, -1, 5], [-1, 4, 0, 5], [-1, 4, 1, 5], [-1, 4, 2, 5],
    [ 0, 4, -2, 5], [ 0, 4, -1, 5], [ 0, 4, 0, 4], [ 0, 4, 1, 5], [ 0, 4, 2, 5],
    [ 1, 4, -2, 5], [ 1, 4, -1, 5], [ 1, 4, 0, 5], [ 1, 4, 1, 5], [ 1, 4, 2, 5],
    [ 2, 4, -2, 5], [ 2, 4, -1, 5], [ 2, 4, 0, 5], [ 2, 4, 1, 5], [ 2, 4, 2, 5],
    
    [-1, 5, 0, 5], [ 0, 5, -1, 5], [ 0, 5, 0, 4], [ 0, 5, 1, 5], [ 1, 5, 0, 5],
    [-1, 6, 0, 5], [ 0, 6, -1, 5], [ 0, 6, 0, 5], [ 0, 6, 1, 5], [ 1, 6, 0, 5],
];


function getBlock(x, y, z){
    if(x<0 || y<0 || z<0 || x>=WORLD_X || z>=WORLD_Z) return 15;
    if(y>=WORLD_Y) return 0;

    const offsetBit=Math.log2(16/block_bit);
    // {z, y, x}<<sqrt(16/block_bit), x&sqrt(16/block_bit)

    const index=(((z)<<(WORLD_X_bit+WORLD_Y_bit))|((y)<<(WORLD_X_bit))|(x))>>offsetBit;
    if(!(x&offsetBit)) return (map[index])&((1<<block_bit)-1);
    else return ((map[index])>>block_bit)&((1<<block_bit)-1);
}
function setBlock(x, y, z, block=15){
    if(x<0 || y<0 || z<0 || x>=WORLD_X || y>=WORLD_Y || z>=WORLD_Z) return;

    const offsetBit=Math.log2(16/block_bit);
    // {z, y, x}<<offsetBit, x&offsetBit

    const index=(((z)<<(WORLD_X_bit+WORLD_Y_bit))|((y)<<(WORLD_X_bit))|(x))>>offsetBit;
    if(!(x&offsetBit)){
        map[index]=(map[index]&(((1<<block_bit)-1)<<block_bit))|(block&((1<<block_bit)-1));
    }else{
        map[index]=(map[index]&((1<<block_bit)-1))|((block&((1<<block_bit)-1))<<block_bit);
    }
}

function placeTree(x = 0, y = 0, z = 0) {
    for (let i = 0; i < TREE_TEMPLATE.length; i++) {
        let dx = TREE_TEMPLATE[i][0];
        let dy = TREE_TEMPLATE[i][1];
        let dz = TREE_TEMPLATE[i][2];
        let type = TREE_TEMPLATE[i][3];
        
        setBlock(x + dx, y + dy, z + dz, type);
    }
}


function genMapPerlin(seed) {
    const seed1=seed%100000;
    const seed2=seed1+20134;
    const seed3=seed1+43102;
    for (let x = 0; x < WORLD_X; x++) {
        for (let z = 0; z < WORLD_Z; z++) {
            const grass=60+15*perlin(x, z, seed1);
            const stone=53+10*perlin(x, z, seed2);
            for (let y = 0; y < grass; y++) {
                if(y<stone) setBlock(x, y+1, z, 1);
                else if(y>=grass-1){
                    setBlock(x, y, z, 2);                    

                    if (y > 48) {
                        // 1. 計算目前的 8x8 網格座標 (直接右移 3 位元)
                        const cx = x >> 3;
                        const cz = z >> 3;
                        
                        // 2. 取得這個網格專屬的 Hash 值
                        const hashVal = (cx * 821) ^ (cz * 983) ^ seed1;
                        
                        // 3. 從 Hash 中抽出這棵樹的「天選偏移座標」
                        // 為了保證相鄰網格的樹也不會貼在一起，我們將偏移量限制在 2~5 之間 (置中)
                        // (hashVal & 3) 會產生 0~3 的數字，加上 2 後變成 2~5
                        const offsetX = (hashVal & 3) + 2;
                        const offsetZ = ((hashVal >> 2) & 3) + 2;
                        
                        // 4. 判斷目前的 x, z 迴圈，是不是剛好走到這個「天選座標」
                        // (x & 7) 是取 0~7 的餘數，等同於 x % 8
                        const isChosenX = (x & 7) === offsetX;
                        const isChosenZ = (z & 7) === offsetZ;
                        
                        if (isChosenX && isChosenZ) {
                            // 5. 抽出機率值 (0~255)，決定這個網格到底要不要長樹
                            const spawnChance = (hashVal >> 4) & 0xFF;
                            
                            // 假設 > 100 代表這個 8x8 網格有大約 60% 的機率會長樹
                            if (spawnChance > 100) {
                                placeTree(x, y, z);
                            }
                        }
                    }
                }
                else setBlock(x, y, z, 3);
            }
            setBlock(x, 0, z, 15);
            if(grass<=64) setBlock(x, 48, z, 6);
        }
    }

    const player_x=toInt(player.x);
    const player_z=toInt(player.z);
    for(let y=WORLD_Y-3;y>0;y--){
        if(getBlock(player_x, y, player_z)!=0){
            player.y=toFixed(y+5);
            break;
        }
    }
}


function genMap(seed) {
    rand32_init(seed);
    const offsetX = (rand32() & 0xFFFF);
    const offsetZ = (rand32() & 0xFFFF);

    for (let x = 0; x < WORLD_X; x++) {
        for (let z = 0; z < WORLD_Z; z++) {
            const nx = x + offsetX;
            const nz = z + offsetZ;

            let noise1 = (multQ16(sin(nx<<3), cos(nz<<3))<<3);
            noise1 += (sin((nx<<5) + (nz<<4))<<1);
            noise1 += (multQ16(sin(nx<<6), cos(nz<<5))<<0);
            noise1 = toInt(noise1);

            let noise2 = (multQ16(sin(nx<<5), cos(nz<<5))<<1);
            noise2 = toInt(noise2);

            const stone = 50 - noise1;
            const grass = stone + 4 + noise2;

            setBlock(x, 0, z, 15);
            for (let y = 1; y < WORLD_Y; y++) {
                if (y < stone) setBlock(x, y, z, 1);
                else if (y < grass) setBlock(x, y, z, 3);
                else if (y === grass) setBlock(x, y, z, 2);
                else setBlock(x, y, z, 0); // 空氣
            }
            if (grass < 49) setBlock(x, 49, z, 6);
        }
    }

    for (let x = 0; x < WORLD_X / 8; x++) {
        for (let z = 0; z < WORLD_Z / 8; z++) {
            const hashVal = (x * 821) ^ (z * 983) ^ seed;
            const tx = (x << 3) + ((hashVal & 3) + 2);
            const tz = (z << 3) + (((hashVal >> 1) & 3) + 2);

            const spawnChance = (hashVal >> 4) & 0xFF;
            if (spawnChance > 150) {
                let y;
                for (y = WORLD_Y - 2; y >= 0; y--) {
                    let block = getBlock(tx, y, tz);
                    if (block !== 0) {
                        if (block !== 2) y = 0;
                        break;
                    }
                }
                if (y > 0) placeTree(tx, y, tz);
            }
        }
    }

    player.x = toFixed(WORLD_X >> 1) + toFixed(0.5);
    player.z = toFixed(WORLD_Z >> 1) + toFixed(0.5);
    const player_x = toInt(player.x);
    const player_z = toInt(player.z);
    
    for (let y = WORLD_Y - 3; y > 0; y--) {
        if (getBlock(player_x, y, player_z) !== 0) {
            player.y = toFixed(y + 5);
            break;
        }
    }
}


//---渲染---
function castRay(player_x, player_y, player_z, dirX, dirY, dirZ, throughBlock=false, max_length=MAX_LENGTH) {
    if(!max_length) max_length=MAX_LENGTH;
    
    // ==========================================
    // Phase 1: Setup 準備階段 (每條射線執行一次)
    // ==========================================
    
    // 1. 取得起點所在的方塊座標 (直接右移 16 位元，超級快！)
    let mapX = toInt(player_x);
    let mapY = toInt(player_y);
    let mapZ = toInt(player_z);

    // 2. 計算 deltaDist：在某個軸上走過「一個完整方塊」的距離
    // 在 JS 裡我們用浮點數算完後，放大 256 倍轉成定點整數
    // (在 FPGA 裡，這個 1/dir 會用硬體除法器或唯讀記憶體 ROM 來查表)
    // let deltaDistX = Math.floor(abs(1 / (dirX || 0.00001)) * SCALE);
    // let deltaDistY = Math.floor(abs(1 / (dirY || 0.00001)) * SCALE);
    // let deltaDistZ = Math.floor(abs(1 / (dirZ || 0.00001)) * SCALE);

    // 查表直接得到 Q16.16 格式的定點數 deltaDist
    let deltaDistX = one_div(Q16_to_Q10(dirX));
    let deltaDistY = one_div(Q16_to_Q10(dirY));
    let deltaDistZ = one_div(Q16_to_Q10(dirZ));


    let stepX, stepY, stepZ;
    let sideDistX, sideDistY, sideDistZ;

    // 3. 計算步進方向 (step) 與初始邊界距離 (sideDist)
    // 這裡的位元運算與遮罩 (& 0xFF) 是為了取出定點數的「小數部分」
    /*
    if (dirX < 0) {
        stepX = -1;
        sideDistX = (getFloatPart(player_x) * deltaDistX) >> FRAC_BITS;
    } else {
        stepX = 1;
        sideDistX = ((SCALE - getFloatPart(player_x)) * deltaDistX) >> FRAC_BITS;
    }

    if (dirY < 0) {
        stepY = -1;
        sideDistY = (getFloatPart(player_y) * deltaDistY) >> FRAC_BITS;
    } else {
        stepY = 1;
        sideDistY = ((SCALE - getFloatPart(player_y)) * deltaDistY) >> FRAC_BITS;
    }

    if (dirZ < 0) {
        stepZ = -1;
        sideDistZ = (getFloatPart(player_z) * deltaDistZ) >> FRAC_BITS;
    } else {
        stepZ = 1;
        sideDistZ = ((SCALE - getFloatPart(player_z)) * deltaDistZ) >> FRAC_BITS;
    }
    */
    // --- 修正：使用 Math.floor 除以 256，避免 JS 的 32-bit 位移溢位 ---
    if (dirX < 0) {
        stepX = -1;
        sideDistX = multQ16(getFloatPart(player_x), deltaDistX);
    } else {
        stepX = 1;
        sideDistX = multQ16((SCALE - getFloatPart(player_x)), deltaDistX);
    }

    if (dirY < 0) {
        stepY = -1;
        sideDistY = multQ16(getFloatPart(player_y), deltaDistY);
    } else {
        stepY = 1;
        sideDistY = multQ16((SCALE - getFloatPart(player_y)), deltaDistY);
    }

    if (dirZ < 0) {
        stepZ = -1;
        sideDistZ = multQ16(getFloatPart(player_z), deltaDistZ);
    } else {
        stepZ = 1;
        sideDistZ = multQ16((SCALE - getFloatPart(player_z)), deltaDistZ);
    }

    // ==========================================
    // Phase 2: Inner Loop 核心迴圈 (尋找方塊的狀態機)
    // ==========================================
    
    let hit = 0;      // 撞到的方塊類型 (0 代表空氣)
    let hitSide = 0;  // 撞到哪一面 (0=X面, 1=Y面, 2=Z面) 用來做基礎光影
    let MAX_STEPS = max_length; // 視距：最多往前找 24 個方塊，避免無窮迴圈
    
    // 這就是未來在 FPGA 裡面的 always @(posedge clk) 區塊！
    while (hit === 0 && MAX_STEPS > 0) {
        // --- 修正後的 DDA 核心判斷邏輯 ---
        if (sideDistX < sideDistY) {
            if (sideDistX < sideDistZ) {
                sideDistX += deltaDistX; 
                mapX += stepX; 
                hitSide = 0;
            } else {
                sideDistZ += deltaDistZ; 
                mapZ += stepZ; 
                hitSide = 2;
            }
        } else {
            if (sideDistY < sideDistZ) {
                sideDistY += deltaDistY; 
                mapY += stepY; 
                hitSide = 1;
            } else {
                sideDistZ += deltaDistZ; 
                mapZ += stepZ; 
                hitSide = 2;
            }
        }
        // 檢查是否飛出 16x16x16 的世界邊界
        if (mapX < 0 || mapX >= WORLD_X || mapY < 0 || mapY >= WORLD_Y || mapZ < 0 || mapZ >= WORLD_Z) {
            break; 
        }
        // 呼叫你的地圖函數，檢查這個網格有沒有方塊
        const type=getBlock(mapX, mapY, mapZ);
        hit = (throughBlock&&BLOCK_INFO[type][3])?0:type;
        MAX_STEPS--;
    }

    let perpWallDist;
    if (hitSide === 0) perpWallDist = multQ16((toFixed(mapX) - player_x + toFixed((1 - stepX) / 2)), deltaDistX*(dirX>0?1:-1));
    else if (hitSide === 1) perpWallDist = multQ16((toFixed(mapY) - player_y + toFixed((1 - stepY) / 2)), deltaDistY*(dirY>0?1:-1));
    else perpWallDist = multQ16((toFixed(mapZ) - player_z + toFixed((1 - stepZ) / 2)), deltaDistZ*(dirZ>0?1:-1));

    return {
        blockType: hit,
        side: hitSide,
        stepX,
        stepY,         
        stepZ,
        dist: perpWallDist,   // 新增：回傳精準距離
        mapX,
        mapY,
        mapZ,
    };
}

function renderFrame(vga, player, max_length=MAX_LENGTH) {
    // let radianYaw = angleToRadian((player.yaw+512)%1024);
    // let radianPitch = angleToRadian((player.pitch+512)%1024);

    // let cosYaw = Math.cos(radianYaw);
    // let sinYaw = Math.sin(radianYaw);
    // let cosPitch = Math.cos(radianPitch);
    // let sinPitch = Math.sin(radianPitch);
    let cosYaw = cos((player.yaw+512)%1024);
    let sinYaw = sin((player.yaw+512)%1024);
    let cosPitch = cos((player.pitch+512)%1024);
    let sinPitch = sin((player.pitch+512)%1024);

    let fwdX = multQ16(cosYaw, cosPitch);
    let fwdY = sinPitch;
    let fwdZ = multQ16(sinYaw, cosPitch);

    let rightX = sinYaw;
    let rightY = 0;
    let rightZ = -cosYaw;

    let upX = multQ16(fwdY, rightZ) - multQ16(fwdZ, rightY);
    let upY = multQ16(fwdZ, rightX) - multQ16(fwdX, rightZ);
    let upZ = multQ16(fwdX, rightY) - multQ16(fwdY, rightX);

    let px = player.x;
    let py = player.y + player.h;
    let pz = player.z;

    for (let y = 0; y < vga.height; y++) {
        for (let x = 0; x < vga.width; x++) {
            
            // X = ((x/width)*2-1)*width/height
            // Y = 1.0-(y/height)*2
            let ndcY = toFixed(1.0) - multQ16(multQ16(toFixed(y), toFixed(1/vga.height)), toFixed(2.0));
            let ndcX = multQ16(multQ16(multQ16(toFixed(x), toFixed(1/vga.width)), toFixed(2.0)) + toFixed(-1.0), multQ16(toFixed(vga.width), toFixed(1/vga.height)));

            // X = fX+nX*FOV*rightX+nY*FOV*upX
            // Y = fY+nX*FOV*rightY+nY*FOV*upY
            // Z = fZ+nX*FOV*rightZ+nY*FOV*upZ
            let dirX = fwdX + multQ16(multQ16(ndcX, toFixed(FOV_FACTOR)), rightX) + multQ16(multQ16(ndcY, toFixed(FOV_FACTOR)), upX);
            let dirY = fwdY + multQ16(multQ16(ndcX, toFixed(FOV_FACTOR)), rightY) + multQ16(multQ16(ndcY, toFixed(FOV_FACTOR)), upY);
            let dirZ = fwdZ + multQ16(multQ16(ndcX, toFixed(FOV_FACTOR)), rightZ) + multQ16(multQ16(ndcY, toFixed(FOV_FACTOR)), upZ);

            // X = fX+(((x/width)*2-1)*width/height)*FOV*rightX+(1.0-(y/height)*2)*FOV*upX
            // Y = fY+(((x/width)*2-1)*width/height)*FOV*rightY+(1.0-(y/height)*2)*FOV*upY
            // Z = fZ+(((x/width)*2-1)*width/height)*FOV*rightZ+(1.0-(y/height)*2)*FOV*upZ

/*
X = fX+(((x/width)*2-1)*width/height)*FOV*rightX+(1.0-(y/height)*2)*FOV*upX
Y = fY+(((x/width)*2-1)*width/height)*FOV*rightY+(1.0-(y/height)*2)*FOV*upY
Z = fZ+(((x/width)*2-1)*width/height)*FOV*rightZ+(1.0-(y/height)*2)*FOV*upZ

X = 
	FX
	+
	x*(2*FOV*rightX/height)-(width*FOV*rightX/height)
	+
	(FOV*upX)-y*(2*FOV*upX/height)

TO_FIXED_CONST



nX:
((x/width)*2-1)*width/height
(x/width)*2*(width/height)-(width/height)
x*2/height-width/height

nY:
1.0-y*2/height



(x*2/height-width/height)*FOV*rightX
x*2*FOV*rightX/height-width*FOV*rightX/height
*/


            let hitResult = castRay(px, py, pz, dirX, dirY, dirZ , player.viewUnderwater, max_length);

            let pixelColor = 0;
            if (hitResult.blockType !== 0) {
                // --- 1. 計算精確的撞擊點座標 ---
                // (玩家精確浮點座標) + (距離 * 射線方向)
                let exactX = px + multQ16(hitResult.dist, dirX);
                let exactY = py + multQ16(hitResult.dist, dirY);
                let exactZ = pz + multQ16(hitResult.dist, dirZ);

                // --- 2. 擷取 U, V 座標 (0.0 ~ 1.0 的小數部分) ---
                let u, v;
                if (hitResult.side === 0) { // 撞到 X 面，貼圖平鋪在 Y-Z 軸上
                    u = getFloatPart(exactZ);
                    v = getFloatPart(exactY);
                } else if (hitResult.side === 1) { // 撞到 Y 面 (頂底)，貼圖平鋪在 X-Z 軸上
                    u = getFloatPart(exactX);
                    v = getFloatPart(exactZ);
                } else { // 撞到 Z 面，貼圖平鋪在 X-Y 軸上
                    u = getFloatPart(exactX);
                    v = getFloatPart(exactY);
                }

                // 將 0.0~1.0 轉換為 0~3 的整數 (4x4 貼圖的 index)
                // (在硬體中，這就是直接抓小數點的 [7:6] 兩個 bit！)
                let texU = toInt(u<<2);
                let texV = toInt(v<<2);
                
                // Y軸在螢幕上是反的，所以我們把 V 反轉一下，讓草地乖乖長在上面
                texV = 3 - texV;

                // --- 3. 根據方塊種類與打中的面，挑選對應的貼圖陣列 ---
                let texOffset;
                let type = hitResult.blockType;
                
                if (hitResult.side === 1) {
                    if (hitResult.stepY < 0) texOffset = BLOCK_INFO[type][0]*16; // 從上往下看
                    else texOffset = BLOCK_INFO[type][2]*16; // 從下往上看
                } else {
                    texOffset = BLOCK_INFO[type][1]*16;  // 側面
                }

                // --- 4. 從陣列中讀取顏色 (查 ROM 表) ---
                // 4x4 陣列的 1D index 公式： V * 4 + U
                let baseColor = TEX[texOffset+texV * 4 + texU];

                if(player.faceBlock&&((texU==0||texU==3)&&(texV==0||texV==3))&&
                    player.faceBlock.mapX==hitResult.mapX&&
                    player.faceBlock.mapY==hitResult.mapY&&
                    player.faceBlock.mapZ==hitResult.mapZ
                ){
                    pixelColor=0xFF;
                }else{
                    // --- 5. 加上原有的假光影魔法 ---
                    if (hitResult.side === 0) {
                        let r = ((baseColor >> 5) & 0x07) >> 1;
                        let g = ((baseColor >> 2) & 0x07) >> 1;
                        let b = (baseColor & 0x03) >> 1;
                        pixelColor = (r << 5) | (g << 2) | b;   //wire [7:0] newColor = {1'b0, baseColor[7:6], 1'b0, baseColor[4:3], 1'b0, baseColor[1]}
                    } else if (hitResult.side === 2) {
                        let r = ((baseColor >> 5) & 0x07) >> 2;
                        let g = ((baseColor >> 2) & 0x07) >> 2;
                        let b = (baseColor & 0x03) >> 1;
                        pixelColor = (r << 5) | (g << 2) | b;
                    } else {
                        pixelColor = baseColor;
                    }
                }
            } else {
                // 畫漸層天空
                pixelColor = (0 << 5) | (1 << 2) | (y > ((vga.height>>1)+(((player.pitch-512)*(vga.height))>>8)) ? 3 : 2); 
            }

            if(player.viewUnderwater){
                let r = ((pixelColor >> 5) & 0x07) >> 1;
                let g = ((pixelColor >> 2) & 0x07) >> 1;
                let b = (pixelColor & 0x03) + 1;
                pixelColor = (r << 5) | (g << 2) | (b&0x03);
            }

            vga.setPixelColor(y * vga.width + x, pixelColor);
        }
    }
    
    // 在畫面正中央畫一個小黑點當作準星
    let centerX = vga.width >> 1;
    let centerY = vga.height >> 1;
    vga.setPixelColor(centerY * vga.width + centerX, 0xFF); // 中心點設為白色

    vga.draw();
}

function playrUpdate(player){
    let radianYaw = angleToRadian((player.yaw+512)%1024);
    let radianPitch = angleToRadian((player.pitch+512)%1024);

    // let cosYaw = Math.cos(radianYaw);
    // let sinYaw = Math.sin(radianYaw);
    // let cosPitch = Math.cos(radianPitch);
    // let sinPitch = Math.sin(radianPitch);
    let cosYaw = cos((player.yaw+512)%1024);
    let sinYaw = sin((player.yaw+512)%1024);
    let cosPitch = cos((player.pitch+512)%1024);
    let sinPitch = sin((player.pitch+512)%1024);

    let fwdX = multQ16(cosYaw, cosPitch);
    let fwdY = sinPitch;
    let fwdZ = multQ16(sinYaw, cosPitch);

    let px = player.x;
    let py = player.y + player.h;
    let pz = player.z;

    let hitResult = castRay(px, py, pz, fwdX, fwdY, fwdZ, true);

    if(hitResult.blockType !== 0 && hitResult.dist<toFixed(CAN_BREAK_LENGTH)){
        player.faceBlock=hitResult;
    }else{
        player.faceBlock=null;
    }

    const blockType=getBlock(toInt(px), toInt(player.y), toInt(pz));
    const headBlockType=getBlock(toInt(px), toInt(py), toInt(pz));
    player.isUnderwater=(6<=blockType&&blockType<=9);
    player.viewUnderwater=(6<=headBlockType&&headBlockType<=9);

    player.onGround=checkHitAABB(player.x, player.y-2, player.z, player.w, player.h);
    
    if(!player.isUnderwater){
        if(player.vy>toFixed(-TERMINAL_VELOCITY/TPS)) player.vy-=toFixed(GRAVITY/(TPS*TPS));
        else player.vy=toFixed(-TERMINAL_VELOCITY/TPS);
    }else{
        if(player.vy>toFixed(-TERMINAL_VELOCITY_IN_WATER/TPS)) player.vy-=toFixed(GRAVITY/(TPS*TPS));
        else player.vy=toFixed(-TERMINAL_VELOCITY_IN_WATER/TPS);
    }
}

//----移動----
// 檢查某個虛擬位置 (x, y, z) 是否會和實體方塊重疊
function checkHitAABB(x, y, z, w, h) {
    // 算出玩家身體「最小」與「最大」涵蓋的方塊座標 (直接 >> 8)
    let minX = toInt(x - w);
    let maxX = toInt(x + w);
    let minY = toInt(y);         // y 是腳底
    let maxY = toInt(y + h);     // y + h 是頭頂
    let minZ = toInt(z - w);
    let maxZ = toInt(z + w);

    // 迴圈檢查這個包圍盒內的每一個方塊
    // 因為玩家寬度很小 (w=0.3)，這個迴圈通常只會跑 1~4 次而已！
    for (let ix = minX; ix <= maxX; ix++) {
        for (let iy = minY; iy <= maxY; iy++) {
            for (let iz = minZ; iz <= maxZ; iz++) {
                if (!(BLOCK_INFO[getBlock(ix, iy, iz)][3])) {
                    return true; // 只要碰到任何一個非空氣方塊，就是撞到了
                }
            }
        }
    }
    return false; // 安全！
}
function movePlayer(dx, dy, dz) {
    // 1. 先嘗試走 X 軸
    if (!checkHitAABB(player.x + dx, player.y, player.z, player.w, player.h)) {
        player.x += dx; // 沒撞到，正式更新 X 座標
    }else{
        if(dx>0) player.x = toFixed(toInt(player.x)+1)-player.w-1;
        else player.x = toFixed(toInt(player.x))+player.w+1;
    }

    // 2. 再嘗試走 Y 軸 (跳躍或掉落)
    if (!checkHitAABB(player.x, player.y + dy, player.z, player.w, player.h)) {
        player.y += dy; // 沒撞到，正式更新 X 座標
    }else{
        if(dy>0) player.y = toFixed(toInt(player.y+player.h)+1)-player.h-1;
        else player.y = toFixed(toInt(player.y))+1;
        player.vy=0;
    }

    // 3. 最後嘗試走 Z 軸
    if (!checkHitAABB(player.x, player.y, player.z + dz, player.w, player.h)) {
        player.z += dz; // 沒撞到，正式更新 X 座標
    }else{
        if(dz>0) player.z = toFixed(toInt(player.z)+1)-player.w-1;
        else player.z = toFixed(toInt(player.z))+player.w+1;
    }
}

function playerJump(){
    if(player.isUnderwater) player.vy=toFixed(Math.sqrt(0.5*2*GRAVITY)/TPS);
    else if(player.onGround)
        player.vy=toFixed(Math.sqrt(1.5*2*GRAVITY)/TPS);
}


function placeBlock(x, y, z, type, player){
    let blockType=getBlock(x, y, z);
    if(!BLOCK_INFO[blockType][3]){
        if (player.faceBlock.side === 0) x -= player.faceBlock.stepX;
        if (player.faceBlock.side === 1) y -= player.faceBlock.stepY;
        if (player.faceBlock.side === 2) z -= player.faceBlock.stepZ;
    }
    blockType=getBlock(x, y, z);
    if(BLOCK_INFO[blockType][3]){
        setBlock(x, y, z, type);
        if (checkHitAABB(player.x, player.y, player.z, player.w, player.h)) {
            setBlock(x, y, z, blockType);
        }else{
            switch(getBlock(x, y-1, z)){
                case 2:
                    setBlock(x, y-1, z, 3);
                    break;
            }
        }
    }
}
function breakBlock(x, y, z){
    if(BLOCK_INFO[getBlock(x, y, z)][4]) setBlock(x, y, z, 0);

    switch(getBlock(x, y-1, z)){
        case 3:
            setBlock(x, y-1, z, 2);
            break;
    }
}


function waterSim(player){
    const player_x = toInt(player.x);
    const player_y = toInt(player.y);
    const player_z = toInt(player.z);
    
    // 💡 小技巧：將 Y 軸改為由下往上掃描 (y++)
    // 這樣當瀑布往下流時，才會有「一格一格」掉落的動畫感，而不是一瞬間流到底！
    const minY = Math.max(player_y - MAX_LENGTH, 0);
    const maxY = Math.min(WORLD_Y - 1, player_y + MAX_LENGTH);
    const minZ = Math.max(player_z - MAX_LENGTH, 0);
    const maxZ = Math.min(WORLD_Z - 1, player_z + MAX_LENGTH);
    const minX = Math.max(player_x - MAX_LENGTH, 0);
    const maxX = Math.min(WORLD_X - 1, player_x + MAX_LENGTH);

    for(let y = minY; y <= maxY; y++){
        for(let z = minZ; z <= maxZ; z++){
            for(let x = minX; x <= maxX; x++){
                
                const type = getBlock(x, y, z);
                
                // 核心邏輯：只針對「空氣(0)」或「流動水(7,8,9)」進行重新評估
                // 源頭水(6) 不會自然衰退，實體方塊也不受影響
                if (type === 0 || (type >= 7 && type <= 9)) {
                    
                    let ideal_type = 0; // 預設理想狀態是空氣(0)
                    const above = getBlock(x, y + 1, z);
                    
                    // 條件 1：如果上方有任何水 (6~9)，這格必定是滿強度流動水 (7)
                    if (above >= 6 && above <= 9) {
                        ideal_type = 7;
                    } else {
                        // 條件 2：否則，尋找四周最強的水源 (數字最小的)
                        let min_w = 10; 
                        const n1 = !BLOCK_INFO[getBlock(x + 1, y-1, z)][3]?getBlock(x + 1, y, z):10;
                        const n2 = !BLOCK_INFO[getBlock(x - 1, y-1, z)][3]?getBlock(x - 1, y, z):10;
                        const n3 = !BLOCK_INFO[getBlock(x, y-1, z + 1)][3]?getBlock(x, y, z + 1):10;
                        const n4 = !BLOCK_INFO[getBlock(x, y-1, z - 1)][3]?getBlock(x, y, z - 1):10;
                        
                        if (n1 >= 6 && n1 <= 9) min_w = min(min_w, n1);
                        if (n2 >= 6 && n2 <= 9) min_w = min(min_w, n2);
                        if (n3 >= 6 && n3 <= 9) min_w = min(min_w, n3);
                        if (n4 >= 6 && n4 <= 9) min_w = min(min_w, n4);
                        
                        // 水只能延伸 3 格 (7 -> 8 -> 9)，如果四周最強的是 8，這格就是 9
                        if (min_w <= 8) {
                            ideal_type = min_w + 1;
                        }
                    }
                    
                    // 如果這格「應該變成的狀態」跟「現在的狀態」不同，就更新它
                    if (ideal_type !== type) {
                        // 防止把空氣(0)又設成空氣(0)，浪費效能
                        if (ideal_type !== 0 || type !== 0) {
                            setBlock(x, y, z, ideal_type);
                        }
                    }
                }
            }
        }
    }
}

//----MAIN----

let seed=parseInt(location.hash.slice(1), 16);
if(!isFinite(seed)) seed=null;

// genMapPerlin(new Date().getTime());
genMap((seed===null)?new Date().getTime():seed);


let keyPress={};
window.addEventListener('keyup', (e)=>{keyPress[e.code]=false;});
window.addEventListener('keydown', (e)=>{keyPress[e.code]=true;});

setInterval(()=>{
    const velocity=(keyPress.ShiftLeft?RUN_VELOCITY:VELOCITY)/TPS;
    const rotation=ROTATION_RATE/TPS;

    if(keyPress.ArrowUp&&player.pitch<=(512+(256-rotation))) player.pitch+=rotation;
    if(keyPress.ArrowDown&&player.pitch>=(512-(256-rotation))) player.pitch-=rotation;
    if(keyPress.ArrowLeft) player.yaw=(player.yaw+rotation)%1024;
    if(keyPress.ArrowRight) player.yaw=(player.yaw-rotation+1024)%1024;

    const dx=toFixed((keyPress.KeyW?velocity:0)-(keyPress.KeyS?velocity:0));
    const dy=toFixed((keyPress.KeyA?velocity:0)-(keyPress.KeyD?velocity:0));

    // const cosDir=Math.cos(2*Math.PI*(player.yaw-512)/1024);
    // const sinDir=Math.sin(2*Math.PI*(player.yaw-512)/1024);
    const cosDir=cos(player.yaw-512);
    const sinDir=sin(player.yaw-512);

    movePlayer(multQ16(dx, cosDir)-multQ16(dy, sinDir), player.vy, multQ16(dx, sinDir)+multQ16(dy, cosDir));

    if(keyPress.Space) playerJump()

    playrUpdate(player);

    if(keyPress.KeyQ&&player.faceBlock){
        breakBlock(player.faceBlock.mapX, player.faceBlock.mapY, player.faceBlock.mapZ);
        keyPress.KeyQ=false;
    }
    if(keyPress.KeyE && player.faceBlock) {
        placeBlock(player.faceBlock.mapX, player.faceBlock.mapY, player.faceBlock.mapZ, player.selectBlockType, player);
        keyPress.KeyE = false;
    }

}, 1000/TPS);
setInterval(()=>{
    waterSim(player);
}, 1000/WATER_TPS);
setInterval(()=>{
    renderFrame(vga, player);
}, 1000/FPS);
