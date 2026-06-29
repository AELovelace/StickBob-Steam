
// Horizontal Speed
xSpeed = 0;
// Vertical Speed
ySpeed = 0;
// Gravity
grv = 0.3;
// Walk Speed
walksp = 0;
// Initial Direction (-1 for left, 1 for right)
climbHeight = 8;
mouseAngle = 0;
fireCooldown = 10;
currentCooldown = fireCooldown;
playerHealth = 1;
maxHealth = 1;
isDying = false;
global.stopShooting = false;
dir = -1; 
// AI State (optional, but useful for more complex AI)
state = "patrol";

vfx_init_trail();
