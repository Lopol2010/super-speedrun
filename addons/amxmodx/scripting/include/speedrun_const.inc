#if defined _speedrun_const_included
    #endinput
#endif
#define _speedrun_const_included

stock const PREFIX[] = "^4[^1Super Speedrun^4]^1";
stock const MENU_VERSION[] = "\rv1.2-beta";

stock const g_szCategory[][] = 
{
    "100 FPS", "200 FPS", "250 FPS", "333 FPS", "500 FPS", "Fastrun", "Bhop", "Crazy Speed", "2K", "Low Gravity"
};

// IMPORTANT NOTE: Always add new category at the end! 
// Otherwise active database will be broken! Category id should be unique.
enum _:Categories
{
    Cat_100fps =  0,
    Cat_200fps =  1,
    Cat_250fps =  2,
    Cat_333fps =  3,
    Cat_500fps =  4,
    Cat_FastRun = 5,
    Cat_Default = 6,
    Cat_CrazySpeed =    7,
    Cat_2k =            8,
    Cat_LowGravity =    9,
};

stock const g_iCategoryRotateOrder[] = { Cat_Default, Cat_100fps, Cat_CrazySpeed, Cat_2k, Cat_LowGravity };
stock const g_iCategorySign[Categories] = {100, 200, 250, 333, 500, 0, 1, 2, 3, 4};
stock const g_iCategoryMaxFps[Categories] = {100, 200, 250, 333, 500, 0, 0, 0, 200, 0};