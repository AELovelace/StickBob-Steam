/// @description Movement & Actions based off of Input
if(global.isPaused){
	exit;
}
getSPControls()
paddle_movement()
playerShoot()
playerSpriteIndexer()
speedBar = xSpeed * 12.5
if(speedBar < 0){
	speedBar *=-1	
}
vpSizeWidth = window_get_width()
vpSizeLength = window_get_height();
if (sprite_index != sprPlayerDie){
	global.stopShooting = false;	
}