// Horizontal Speed
xSpeed = 0;
// Vertical Speed
ySpeed = 0;
// Gravity
grv = 0.3;
// Walk Speed
walksp = 2;
// Initial Direction (-1 for left, 1 for right)
climbHeight = 8;
mouseAngle = 0;
fireCooldown = 30;
currentCooldown = fireCooldown;
playerHealth = 1;
maxHealth = 1;
isDying = false;
global.stopShooting = false;
checkTimer = 60
checkTimerCurrent = 0;
canCheck = true
dir = -1; 
// AI State (optional, but useful for more complex AI)
state = "patrol";
