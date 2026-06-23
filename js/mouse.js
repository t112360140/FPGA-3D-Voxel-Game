let mouseLock=false;
vga.canvas.addEventListener('mousedown', async(e)=>{
    if(!mouseLock){
        await vga.canvas.requestPointerLock();
        return;
    }
    if(e.buttons==1){
        if(player.faceBlock)
            breakBlock(player.faceBlock.mapX, player.faceBlock.mapY, player.faceBlock.mapZ);
    }else if(e.buttons==2){
        if(player.faceBlock)
            placeBlock(player.faceBlock.mapX, player.faceBlock.mapY, player.faceBlock.mapZ, player.selectBlockType, player);
    }
});

vga.canvas.addEventListener('mousemove', (e)=>{
    if(!mouseLock) return;
    const rotation=ROTATION_RATE/100;

    player.pitch-=rotation*e.movementY;
    if(player.pitch<=(512-256)) player.pitch=(512-256);
    if(player.pitch>=(512+256)) player.pitch=(512+256);
    player.yaw=(player.yaw-rotation*e.movementX+1024)%1024;
});

let selectIndex=0;
vga.canvas.addEventListener('wheel', async(e)=>{
    if(e.wheelDeltaY<0&&selectIndex<CAN_PLACE_LIST.length-1) selectIndex++;
    else if(selectIndex>0) selectIndex--;

    player.selectBlockType=CAN_PLACE_LIST[selectIndex];
});

document.addEventListener("pointerlockchange", ()=>{
    mouseLock=(document.pointerLockElement==vga.canvas);
});