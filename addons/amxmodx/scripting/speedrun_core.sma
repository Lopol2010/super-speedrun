/*
    adding new category:
        ALWAYS ADD NEW CATEGORY AS THE LAST ELEMENT OF ENUM!!! OTHERWISE DATABASE WILL BE BROKEN!
        ALWAYS ADD NEW CATEGORY AS THE LAST ELEMENT OF ENUM!!! OTHERWISE DATABASE WILL BE BROKEN!
        ALWAYS ADD NEW CATEGORY AS THE LAST ELEMENT OF ENUM!!! OTHERWISE DATABASE WILL BE BROKEN!
        1. core & stats: enum _:Categories
        2. in core: new g_iCategorySign[Categories] 
        3. in stats & main_menu: new const g_szCategory[][]"
        4. in core: edit native rotate_user_category
        5. in core: edit Command_CategoryMenu
        6. in core: edit Command_CategoryMenu KEYS variable
        7. in core: edit CategoryMenu_Handler
        8. in core: edit CategoryMenu_Handler in if statement change number that's compared with keys variable
        9. in toplist: add entry for list of categories (currently in stats.ts file)

*/
#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <box_system>
#include <fun>
#include <hidemenu>
#include <checkpoints>
#include <speedrun>
#include <fpschecker>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Speedrun: Core"
#define VERSION "1.0"
#define AUTHOR "Mistrick & Lopol2010"

#pragma semicolon 1

#define MAX_PLAYERS 32

#define FPS_LIMIT 1050
#define FPS_OFFSET 5
#define FAILS_TILL_PRINT 3
#define CRAZYSPEED_BOOST 250.0
#define FASTRUN_AIRACCELERATE -55.0
#define PUSH_DIST 300.0

enum (+=100)
{
    TASK_SHOWSPEED = 100,
    TASK_CHECKFRAMES,
    TASK_QUERY_INITIAL_FPS,
};
enum _:Categories
{
    Cat_100fps,
    Cat_200fps,
    Cat_250fps,
    Cat_333fps,
    Cat_500fps,
    Cat_FastRun,
    Cat_Default,
    Cat_CrazySpeed,
    Cat_2k,
    Cat_LowGravity,
};
enum _:PlayerData
{
    m_bBhop,
    m_bSpeed,
    m_bKeys,
    m_bInSaveBox,
    m_bSavePoint,
    m_iInitialFps,
    m_iCategory,
    m_iPrevCategory,
};

new g_iCategorySign[Categories] = {100, 200, 250, 333, 500, 0, 1, 2, 3, 4};
// new const g_szCategory[][] = 
// {
// 	"[100 FPS]", "[200 FPS]", "[250 FPS]", "[333 FPS]", "[500 FPS]", "[Fastrun]", "[Crazy Speed]", "[2K]", "[Low Gravity]"
// };

// new g_iMaxSpeed = 320;
new g_bStartPosition, Float:g_fStartOrigin[3], Float:g_fStartVAngles[3];
new g_ePlayerInfo[33][PlayerData];
new g_szMapName[32];
new g_iSyncHudSpeed;
new g_fwChangedCategory;
new g_fwOnStart;
new g_iReturn;
new Float:g_fSavedOrigin[33][3], Float:g_fSavedVAngles[33][3], g_iSavedDuck[33], Float: g_fNextFpsCheck[33];
new Trie:g_tRemoveEntities, g_iForwardSpawn;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say /setstart", "Command_SetStart", ADMIN_RCON);
    register_clcmd("say /start", "Command_Start");
    register_clcmd("say /bhop", "Command_Bhop");
    register_clcmd("say /speed", "Command_Speed");
    register_clcmd("say /keys", "Command_Keys");
    register_clcmd("say /showkeys", "Command_Keys");
    register_clcmd("say /spec", "Command_Spec");
    register_clcmd("say /game", "Command_CategoryMenu");
    register_clcmd("say /2k", "Command_Category2k");
    // register_clcmd("say /fps", "Command_SpeedrunMenu");
    register_clcmd("say /save", "Command_SaveMenu");
    register_clcmd("drop", "Command_CategoryMenu");


    register_menucmd(register_menuid("CategoryMenu"), 1023, "CategoryMenu_Handler");
    register_menucmd(register_menuid("SpeedrunMenu"), 1023, "SpeedrunMenu_Handler");
    register_menucmd(register_menuid("SaveMenu"), 1023, "SaveMenu_Handler");

    register_message(get_user_msgid("ScoreInfo"), "Message_ScoreInfo");

    RegisterHookChain(RG_PM_AirMove, "HC_PM_AirMove_Pre", false);
    RegisterHookChain(RG_CBasePlayer_Jump, "HC_CBasePlayer_Jump_Pre", false);
    RegisterHookChain(RG_CBasePlayer_Spawn, "HC_CBasePlayer_Spawn_Post", true);
    RegisterHookChain(RG_CBasePlayer_Killed, "HC_CBasePlayer_Killed_Pre", false);
    RegisterHookChain(RG_CBasePlayer_Killed, "HC_CBasePlayer_Killed_Post", true);
    RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "HC_CBasePlayer_GiveDefaultItems", false);
    RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "HC_CSGR_DeadPlayerWeapons_Pre", false);

    register_forward(FM_ClientKill, "FM_ClientKill_Pre", false);

    RegisterHam( Ham_Item_Deploy, "weapon_usp", "Ham_Item_Deploy_USP_Post", 1);
    RegisterHam( Ham_Item_Deploy, "weapon_knife", "Ham_Item_Deploy_KNIFE_Post", 1);
    

    g_fwChangedCategory = CreateMultiForward("SR_ChangedCategory", ET_IGNORE, FP_CELL, FP_CELL);
    g_fwOnStart = CreateMultiForward("SR_PlayerOnStart", ET_IGNORE, FP_CELL);

    set_msg_block(get_user_msgid("AmmoPickup"), BLOCK_SET);
    set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);
    set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);
    set_msg_block(get_user_msgid("WeapPickup"), BLOCK_SET);

    g_iSyncHudSpeed = CreateHudSyncObj();

    // set_task(0.1, "Task_ShowSpeed", TASK_SHOWSPEED, .flags = "b");
    CreateHudThink();
    set_task(3.0, "Task_CheckFrames", TASK_CHECKFRAMES, .flags = "b");

    set_cvar_num("mp_autoteambalance", 0);
    set_cvar_num("mp_round_infinite", 1);
    set_cvar_num("mp_freezetime", 0);
    set_cvar_num("mp_limitteams", 0);
    set_cvar_num("mp_auto_join_team", 1);
    set_cvar_string("humans_join_team", "CT");

    register_dictionary("speedrun.txt");
}
CreateHudThink()
{
    new ent = create_entity("info_target");	
    set_entvar(ent, var_classname, "timer_think");
    set_entvar(ent, var_nextthink, get_gametime() + 1.0);	
    register_think("timer_think", "Think_Hud");
}
public SR_StartButtonPress(id)
{
    SavePoint(id);
    g_iSavedDuck[id] = get_entvar(id, var_flags) & FL_DUCKING;
}
public SR_ChangedCategory(id, cat)
{
    if(is_user_alive(id)) ExecuteHamB(Ham_CS_RoundRespawn, id);

    sr_give_default_items(id);
    
    reset_checkpoints(id);

    if(cat >= Cat_FastRun && g_ePlayerInfo[id][m_iPrevCategory] < Cat_FastRun)
    {
        // client_print_color(id, print_team_default, "%s^1 Resetting your fps to ^4%d^1!", PREFIX, g_ePlayerInfo[id][m_iInitialFps]);
        client_cmd(id, "fps_max %d", g_ePlayerInfo[id][m_iInitialFps]);
    }
}

public plugin_precache()
{	
    new const szRemoveEntities[][] = 
    {
        "func_bomb_target", "func_escapezone", "func_hostage_rescue", "func_vip_safetyzone", "info_vip_start",
        "hostage_entity", "info_bomb_target", "func_buyzone","info_hostage_rescue", "monster_scientist",
        "player_weaponstrip", "game_player_equip"
    };
    g_tRemoveEntities = TrieCreate();
    for(new i = 0; i < sizeof(szRemoveEntities); i++)
    {
        TrieSetCell(g_tRemoveEntities, szRemoveEntities[i], i);
    }
    g_iForwardSpawn = register_forward(FM_Spawn, "FakeMeta_Spawn_Pre", false);
    engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
}
public FakeMeta_Spawn_Pre(ent)
{
    if(!pev_valid(ent)) return FMRES_IGNORED;

    new szClassName[32]; get_entvar(ent, var_classname, szClassName, charsmax(szClassName));
    if(TrieKeyExists(g_tRemoveEntities, szClassName))
    {
        engfunc(EngFunc_RemoveEntity, ent);
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}
public plugin_cfg()
{
    TrieDestroy(g_tRemoveEntities);
    unregister_forward(FM_Spawn, g_iForwardSpawn, 0);

    LoadStartPosition();
    SetGameName();
    BlockChangingTeam();
    BlockSpawnTriggerPush();

    // g_iMaxSpeed = max(get_cvar_num("sv_maxvelocity"), get_cvar_num("sv_maxspeed"));
}
LoadStartPosition()
{
    new szDir[128]; get_localinfo("amxx_datadir", szDir, charsmax(szDir));
    format(szDir, charsmax(szDir), "%s/speedrun/", szDir);

    if(!dir_exists(szDir))	mkdir(szDir);

    get_mapname(g_szMapName, charsmax(g_szMapName));
    new szFile[128]; formatex(szFile, charsmax(szFile), "%s%s.bin", szDir, g_szMapName);

    if(!file_exists(szFile)) return;

    new file = fopen(szFile, "rb");
    fread_blocks(file, _:g_fStartOrigin, sizeof(g_fStartOrigin), BLOCK_INT);
    fread_blocks(file, _:g_fStartVAngles, sizeof(g_fStartVAngles), BLOCK_INT);
    fclose(file);

    g_bStartPosition = true;
}
SetGameName()
{
    new szGameName[32]; formatex(szGameName, charsmax(szGameName), "Speedrun");
    set_member_game(m_GameDesc, szGameName);
}
BlockChangingTeam()
{
    new szCmds[][] = {"jointeam", "joinclass"};
    for(new i; i < sizeof(szCmds); i++)
    {
        register_clcmd(szCmds[i], "Command_BlockJointeam");
    }
    register_clcmd("chooseteam", "Command_Chooseteam");
}

new Float:g_fSpawns[32][3], g_iSpawnsNum;

BlockSpawnTriggerPush()
{
    new ent = -1;
    while((ent = rg_find_ent_by_class(ent, "info_player_start")))
    {
        get_entvar(ent, var_origin, g_fSpawns[g_iSpawnsNum++]);
        if(g_iSpawnsNum >= sizeof(g_fSpawns)) break;
    }
    SetTriggerPushSolid(SOLID_NOT);
}
SetTriggerPushSolid(solid)
{
    new ent = -1;
    while((ent = rg_find_ent_by_class(ent, "trigger_push")))
    {
        if(is_on_spawn(ent, PUSH_DIST))
        {
            set_entvar(ent, var_solid, solid);
        }
    }
}
is_on_spawn(ent, Float:fMaxDistance)
{
    new Float:fMins[3], Float:fOrigin[3];
    get_entvar(ent, var_absmin, fMins);
    get_entvar(ent, var_absmax, fOrigin);

    //xs_vec_sub(fOrigin, fMins, fOriginm);
    //xs_vec_mul_scalar(fOrigin, 0.5, );
    fOrigin[0] = (fOrigin[0]+fMins[0])/2;
    fOrigin[1] = (fOrigin[1]+fMins[1])/2;
    fOrigin[2] = (fOrigin[2]+fMins[2])/2;

    for(new i = 0; i < g_iSpawnsNum; i++)
    {
        if(get_distance_f(fOrigin, g_fSpawns[i]) < fMaxDistance)
            return 1;
    }
    return 0;
}

public plugin_natives()
{
    register_native("get_user_category", "_get_user_category");
    register_native("set_user_category", "_set_user_category");
    register_native("rotate_user_category", "_rotate_user_category");
    register_native("sr_command_spec", "_sr_command_spec");
    register_native("sr_command_start", "_sr_command_start");
    register_native("sr_give_default_items", "_sr_give_default_items");
    register_native("sr_regive_weapon", "_sr_regive_weapon");
}

public _sr_command_start(pid, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);

    if(!is_user_connected(id)) return;

    if(g_ePlayerInfo[id][m_bSavePoint])
    {
        SetPosition(id, g_fSavedOrigin[id], g_fSavedVAngles[id]);
	    set_entvar( id, var_flags, get_entvar(id, var_flags) | g_iSavedDuck[id]);
    }
    else if(g_bStartPosition)
    {
        SetPosition(id, g_fStartOrigin, g_fStartVAngles);
    }
    else
    {
        ExecuteHamB(Ham_CS_RoundRespawn, id);
    }

    if(get_user_weapon(id) == CSW_KNIFE && get_user_category(id) == Cat_LowGravity)
        set_user_gravity(id, 0.5);

    reset_checkpoints(id);

    ExecuteForward(g_fwOnStart, g_iReturn, id);
}
public _sr_command_spec()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);

    if(get_member(id, m_iTeam) != TEAM_SPECTATOR)
    {
        rg_join_team(id, TEAM_SPECTATOR);
    }
    else
    {
        rg_set_user_team(id, TEAM_CT);
        ExecuteHamB(Ham_CS_RoundRespawn, id);
        HC_CBasePlayer_GiveDefaultItems(id);
    }

    main_menu_display(id);
}

public _sr_regive_weapon()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    if(!is_user_connected(id)) return;

    new wpn[32];
    get_weaponname(get_user_weapon(id), wpn, charsmax(wpn));
    rg_give_item(id, wpn, GT_REPLACE);

}

public _sr_give_default_items()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    if(!is_user_connected(id)) return;

    static tmp[32]; new iNum = 0, iWeaponBits = get_user_weapons(id, tmp, iNum); 
    if(~iWeaponBits & (1<<CSW_KNIFE))
        rg_give_item(id, "weapon_knife");
    if(~iWeaponBits & (1<<CSW_USP))
        rg_give_item(id, "weapon_usp");
    rg_set_user_bpammo(id, WEAPON_USP, 24);
}

public _get_user_category()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return g_ePlayerInfo[id][m_iCategory];
}
public _rotate_user_category()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);

    g_ePlayerInfo[id][m_iPrevCategory] = g_ePlayerInfo[id][m_iCategory];
    switch(get_user_category(id))
    {
        case Cat_Default: g_ePlayerInfo[id][m_iCategory] = Cat_100fps;
        case Cat_100fps: g_ePlayerInfo[id][m_iCategory] = Cat_CrazySpeed;
        case Cat_CrazySpeed: g_ePlayerInfo[id][m_iCategory] = Cat_2k;
        case Cat_2k: g_ePlayerInfo[id][m_iCategory] = Cat_LowGravity;
        case Cat_LowGravity: g_ePlayerInfo[id][m_iCategory] = Cat_Default;
        default: g_ePlayerInfo[id][m_iCategory] = Cat_Default;
    }

    ExecuteForward(g_fwChangedCategory, g_iReturn, id, g_ePlayerInfo[id][m_iCategory]);
}
public _set_user_category()
{
    enum { arg_id = 1, arg_category }
    new id = get_param(arg_id);
    new category = get_param(arg_category);

    g_ePlayerInfo[id][m_iCategory] = category;
    if(is_user_alive(id)) ExecuteHamB(Ham_CS_RoundRespawn, id);
}
public client_putinserver(id)
{
    g_ePlayerInfo[id][m_bBhop] = true;
    g_ePlayerInfo[id][m_bSpeed] = true;
    g_ePlayerInfo[id][m_bKeys] = true;
    g_ePlayerInfo[id][m_bInSaveBox] = false;
    g_ePlayerInfo[id][m_bSavePoint] = false;
    g_ePlayerInfo[id][m_iCategory] = Cat_Default;
    g_ePlayerInfo[id][m_iInitialFps] = 100;

    new data[1]; data[0] = id;
    set_task(1.0, "task_delayed_query_initial_fps", TASK_QUERY_INITIAL_FPS, data, sizeof data);
}

public task_delayed_query_initial_fps(arg[])
{
    new id = arg[0];
    if(!is_user_bot(id) && is_user_connected(id)) query_client_cvar(id, "fps_max", "cvar_fps_max_query_callback");
}

public client_disconnected(id)
{
    g_ePlayerInfo[id][m_bSpeed] = false;
    g_ePlayerInfo[id][m_bKeys] = false;

    client_cmd(id, "fps_max %d", g_ePlayerInfo[id][m_iInitialFps]);
}
public Command_SetStart(id, flag)
{
    if((~get_user_flags(id) & flag) || !is_user_alive(id)) return PLUGIN_HANDLED;

    get_entvar(id, var_origin, g_fStartOrigin);
    get_entvar(id, var_v_angle, g_fStartVAngles);

    g_bStartPosition = true;

    SaveStartPosition(g_szMapName, g_fStartOrigin, g_fStartVAngles);

    client_print_color(id, print_team_blue, "%s^3 Start position has been set.", PREFIX);

    return PLUGIN_HANDLED;
}
SaveStartPosition(map[], Float:origin[3], Float:vangles[3])
{
    new szDir[128]; get_localinfo("amxx_datadir", szDir, charsmax(szDir));
    new szFile[128]; formatex(szFile, charsmax(szFile), "%s/speedrun/%s.bin", szDir, map);

    new file = fopen(szFile, "wb");
    fwrite_blocks(file, _:origin, sizeof(origin), BLOCK_INT);
    fwrite_blocks(file, _:vangles, sizeof(vangles), BLOCK_INT);
    fclose(file);
}

public Command_Spec(id)
{
    sr_command_spec(id);
    return PLUGIN_HANDLED;
}

public Command_Start(id)
{
    sr_command_start(id);
    return PLUGIN_HANDLED;
}
SetPosition(id, Float:origin[3], Float:vangles[3])
{
    set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
    set_entvar(id, var_v_angle, vangles);
    set_entvar(id, var_angles, vangles);
    set_entvar(id, var_fixangle, 1);
    set_entvar(id, var_health, 100.0);
    engfunc(EngFunc_SetOrigin, id, origin);
}
public Ham_Item_Deploy_USP_Post(weapon)
{
    new id = get_member(weapon, m_pPlayer);
    if(get_user_category(id) == Cat_LowGravity)
    {
        set_user_gravity(id, 1.0);
    }
}
public Ham_Item_Deploy_KNIFE_Post(weapon)
{
    new id = get_member(weapon, m_pPlayer);
    if(get_user_category(id) == Cat_LowGravity)
    {
        set_user_gravity(id, 0.5);
    }
}
public Command_Bhop(id)
{
    g_ePlayerInfo[id][m_bBhop] = !g_ePlayerInfo[id][m_bBhop];
    client_print_color(id, print_team_default, "%s^1 Bhop is^3 %s^1.", PREFIX, g_ePlayerInfo[id][m_bBhop] ? "enabled" : "disabled");
}
public Command_Speed(id)
{
    g_ePlayerInfo[id][m_bSpeed] = !g_ePlayerInfo[id][m_bSpeed];
    client_print_color(id, print_team_default, "^4%s^1 Speedometer is^3 %s^1.", PREFIX, g_ePlayerInfo[id][m_bSpeed] ? "enabled" : "disabled");
}
public Command_Keys(id)
{
    g_ePlayerInfo[id][m_bKeys] = !g_ePlayerInfo[id][m_bKeys];
    client_print_color(id, print_team_default, "^4%s^1 Show keys is^3 %s^1.", PREFIX, g_ePlayerInfo[id][m_bKeys] ? "enabled" : "disabled");
}
public Command_BlockJointeam(id)
{
    return PLUGIN_HANDLED;
}
public Command_Chooseteam(id)
{
    main_menu_display(id);
    return PLUGIN_HANDLED;
}
public Command_Category2k(id)
{
    g_ePlayerInfo[id][m_iPrevCategory] = g_ePlayerInfo[id][m_iCategory];
    g_ePlayerInfo[id][m_iCategory] = Cat_2k;

    ExecuteForward(g_fwChangedCategory, g_iReturn, id, g_ePlayerInfo[id][m_iCategory]);
    
}
public is_finish_zone_exists()
{

    return 0 != rg_find_ent_by_class(-1, "SR_FINISH");
}
public Command_CategoryMenu(id)
{
    new szMenu[128], len = 0;
    len = formatex(szMenu[len], charsmax(szMenu) - len, "\yCategory Menu^n^n");


    // if(is_finish_zone_exists())
    // {
    // 	len += formatex(szMenu[len], charsmax(szMenu) - len, "\r4.CrazySpeed 2K^n", g_ePlayerInfo[id][m_iCategory] == Cat_2k ? "\r" : "\w");
    // 	len += formatex(szMenu[len], charsmax(szMenu) - len, "^n^n^n^n^n^n\r0. \wExit");

    // 	show_menu(id, (1 << 0)|(1 << 1), szMenu, -1, "CategoryMenu");
    // } else {
    len += formatex(szMenu[len], charsmax(szMenu) - len, "%s1. Default^n", g_ePlayerInfo[id][m_iCategory] == Cat_Default? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "%s2. 100 fps^n", g_ePlayerInfo[id][m_iCategory] == Cat_100fps? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "%s3. CrazySpeed^n", g_ePlayerInfo[id][m_iCategory] == Cat_CrazySpeed ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "%s4. CrazySpeed 2K^n", g_ePlayerInfo[id][m_iCategory] == Cat_2k ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "%s5. Low Gravity^n", g_ePlayerInfo[id][m_iCategory] == Cat_LowGravity ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "^n^n^n^n^n^n\r0. \wExit");

    show_menu(id, (1 << 0)|(1 << 1)|(1 << 2)|(1 << 3)|(1 << 4)|(1 << 9), szMenu, -1, "CategoryMenu");
    // }
    return PLUGIN_HANDLED;
}
public CategoryMenu_Handler(id, key)
{
    g_ePlayerInfo[id][m_iPrevCategory] = g_ePlayerInfo[id][m_iCategory];

    switch(key)
    {
        case 0: g_ePlayerInfo[id][m_iCategory] = Cat_Default;
        case 1: g_ePlayerInfo[id][m_iCategory] = Cat_100fps;
        case 2: g_ePlayerInfo[id][m_iCategory] = Cat_CrazySpeed;
        case 3: g_ePlayerInfo[id][m_iCategory] = Cat_2k;
        case 4: g_ePlayerInfo[id][m_iCategory] = Cat_LowGravity;
    }

    if(key <= 4)
    {
        ExecuteForward(g_fwChangedCategory, g_iReturn, id, g_ePlayerInfo[id][m_iCategory]);
    }
}
public Command_SpeedrunMenu(id)
{
    new szMenu[128], len = 0;

    len = formatex(szMenu[len], charsmax(szMenu) - len, "\ySpeedrun Menu^n^n");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "\r1.100 FPS^n", g_ePlayerInfo[id][m_iCategory] == Cat_100fps ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "\r2.200 FPS^n", g_ePlayerInfo[id][m_iCategory] == Cat_200fps ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "\r3.250 FPS^n", g_ePlayerInfo[id][m_iCategory] == Cat_250fps ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "\r4.333 FPS^n", g_ePlayerInfo[id][m_iCategory] == Cat_333fps ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "\r5.500 FPS^n", g_ePlayerInfo[id][m_iCategory] == Cat_500fps ? "\r" : "\w");
    len += formatex(szMenu[len], charsmax(szMenu) - len, "^n^n^n^n\r0. \wExit");

    show_menu(id, (1 << 0)|(1 << 1)|(1 << 2)|(1 << 3)|(1 << 4)|(1 << 9), szMenu, -1, "SpeedrunMenu");
    return PLUGIN_HANDLED;
}
public SpeedrunMenu_Handler(id, key)
{
    g_ePlayerInfo[id][m_iPrevCategory] = g_ePlayerInfo[id][m_iCategory];

    switch(key)
    {
        case 0: g_ePlayerInfo[id][m_iCategory] = Cat_100fps;
        case 1: g_ePlayerInfo[id][m_iCategory] = Cat_200fps;
        case 2: g_ePlayerInfo[id][m_iCategory] = Cat_250fps;
        case 3: g_ePlayerInfo[id][m_iCategory] = Cat_333fps;
        case 4: g_ePlayerInfo[id][m_iCategory] = Cat_500fps;
    }
    if(key != 9)
    {
        ExecuteForward(g_fwChangedCategory, g_iReturn, id, g_ePlayerInfo[id][m_iCategory]);
    }
}
public Command_SaveMenu(id)
{
    new szMenu[256], iLen, iMax = charsmax(szMenu), Keys;

    iLen = formatex(szMenu, iMax, "\yStartpoint Menu^n^n");
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r1.\w Save Startpoint%s^n", g_ePlayerInfo[id][m_bSavePoint] ? "\r[active]" : "\y[inactive]");
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r2.\w Delete Startpoint^n");
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r3.\w Start^n");
    iLen += formatex(szMenu[iLen], iMax - iLen, "^n^n^n^n^n^n\r0.\w Exit");

    Keys |= (1 << 0)|(1 << 1)|(1 << 2)|(1 << 9);

    show_menu(id, Keys, szMenu, -1, "SaveMenu");
    return PLUGIN_HANDLED;
}

public SavePoint(id)
{
    get_entvar(id, var_origin, g_fSavedOrigin[id]);
    get_entvar(id, var_v_angle, g_fSavedVAngles[id]);

    g_ePlayerInfo[id][m_bSavePoint] = true;
}

public SaveMenu_Handler(id, key)
{
    if(!is_user_alive(id)) return PLUGIN_HANDLED;

    switch(key)
    {
        case 0:
            {
                new Float:fVelocity[3]; get_entvar(id, var_velocity, fVelocity);
                if(g_ePlayerInfo[id][m_bInSaveBox] && floatabs(fVelocity[0]) < 0.00001 && floatabs(fVelocity[1]) < 0.00001 && floatabs(fVelocity[2]) < 0.00001)
                {
                    SavePoint(id);
                    client_print_color(id, print_team_default, "%s^1 Start point created.", PREFIX);
                }
                else
                {
                    client_print_color(id, print_team_red, "%s^3 You must be in spawnbox or stop moving.", PREFIX);
                }
            }
        case 1:
            {
                g_ePlayerInfo[id][m_bSavePoint] = false;
                client_print_color(id, print_team_default, "%s^1 Start point removed.", PREFIX);
            }
        case 2:	Command_Start(id);
    }	

    if(key < 3) Command_SaveMenu(id);

    return PLUGIN_HANDLED;
}
public box_start_touch(box, id, const szClass[])
{
    if(!is_user_connected(id)) return;

    if(equal(szClass, "start"))
    {
        g_ePlayerInfo[id][m_bInSaveBox] = true;
    }
}
public box_stop_touch(box, id, const szClass[])
{
    if(!is_user_connected(id)) return;
    if(equal(szClass, "start"))
    {
        g_ePlayerInfo[id][m_bInSaveBox] = false;
    }
}
//*******************************************************************//
public Message_ScoreInfo(Msgid, Dest, id)
{
    new player = get_msg_arg_int(1);
    set_msg_arg_int(2, ARG_SHORT, 0);//frags
    set_msg_arg_int(3, ARG_SHORT, g_iCategorySign[g_ePlayerInfo[player][m_iCategory]]);//deaths
}
//*******************************************************************//
public HC_CBasePlayer_Spawn_Post(id)
{
    if(!is_user_alive(id)) return HC_CONTINUE;

    if(get_user_weapon(id) == CSW_KNIFE && get_user_category(id) == Cat_LowGravity)
        set_user_gravity(id, 0.5);

    if(g_bStartPosition)
        Command_Start(id);

    return HC_CONTINUE;
}
public HC_CBasePlayer_Killed_Pre()
{
    SetHookChainArg(3, ATYPE_INTEGER, 1);
}
public HC_CBasePlayer_Killed_Post(id)
{
    if(TEAM_UNASSIGNED < get_member(id, m_iTeam) < TEAM_SPECTATOR)
    {
        ExecuteHamB(Ham_CS_RoundRespawn, id);
        Command_Start(id);
    }
}
public HC_CBasePlayer_GiveDefaultItems(id)
{
    sr_give_default_items(id);
    return HC_SUPERCEDE;
}
public HC_CBasePlayer_Jump_Pre(id)
{
    if(!g_ePlayerInfo[id][m_bBhop]) return HC_CONTINUE;

    new flags = get_entvar(id, var_flags);

    if((flags & FL_WATERJUMP) || !(flags & FL_ONGROUND)  || get_entvar(id, var_waterlevel) >= 2) return HC_CONTINUE;

    new Float:fVelocity[3], Float:fAngles[3];

    get_entvar(id, var_velocity, fVelocity);

    if(g_ePlayerInfo[id][m_iCategory] == Cat_2k) 
    {
        get_entvar(id, var_angles, fAngles);

        fVelocity[0] = floatcos(fAngles[1], degrees) * 2000.0;
        fVelocity[1] = floatsin(fAngles[1], degrees) * 2000.0;

    }
    if(g_ePlayerInfo[id][m_iCategory] == Cat_CrazySpeed)
    {		
        get_entvar(id, var_angles, fAngles);

        fVelocity[0] += floatcos(fAngles[1], degrees) * CRAZYSPEED_BOOST;
        fVelocity[1] += floatsin(fAngles[1], degrees) * CRAZYSPEED_BOOST;
    }

    fVelocity[2] = 268.32815729997476356910084024775;

    set_entvar(id, var_velocity, fVelocity);
    set_entvar(id, var_gaitsequence, 6);

    return HC_CONTINUE;
}
public HC_PM_AirMove_Pre(id)
{
    if(g_ePlayerInfo[id][m_iCategory] != Cat_FastRun) return HC_CONTINUE;

    static bFastRun[33];
    new buttons = get_entvar(id, var_button);

    if((buttons & IN_BACK) && (buttons & IN_JUMP) && !bFastRun[id])
    {
        bFastRun[id] = true;
    }
    if((get_member(id, m_afButtonReleased) & IN_BACK) && bFastRun[id])
    {
        bFastRun[id] = false;
    }
    if(bFastRun[id])
    {
        set_movevar(mv_airaccelerate, FASTRUN_AIRACCELERATE);
    }

    return HC_CONTINUE;
}
public HC_CSGR_DeadPlayerWeapons_Pre(id)
{
    SetHookChainReturn(ATYPE_INTEGER, GR_PLR_DROP_GUN_NO);
    return HC_SUPERCEDE;
}
// *******************************************************************//
public FM_ClientKill_Pre(id)
{
    Command_Start(id);
    return FMRES_SUPERCEDE;
}
// *******************************************************************//
public Think_Hud(ent)
{
    new Float:rate = 0.091;
    set_entvar(ent, var_nextthink, get_gametime() + rate);
  
    new Float:fSpeed, Float:fVelocity[3], iSpecMode, len, button;
    static szTime[32], szKeys[32];

    for(new id = 1, target; id <= MAX_PLAYERS; id++)
    {
        if(!g_ePlayerInfo[id][m_bSpeed]) continue;
    
        iSpecMode = get_entvar(id, var_iuser1);
        target = (iSpecMode == 1  || iSpecMode == 2 || iSpecMode == 4) ? get_entvar(id, var_iuser2) : id;
        get_entvar(target, var_velocity, fVelocity);

        fSpeed = vector_length(fVelocity);

        if(!is_user_alive(id) && g_ePlayerInfo[id][m_bKeys])
        {
            button = get_entvar(target, var_button);
            
            len = formatex(szKeys, charsmax(szKeys), "%s^n",          (button & IN_FORWARD) ? 	    "W" : ".");
            len += formatex(szKeys[len], charsmax(szKeys)-len, "%s",  (button & IN_MOVELEFT) ? 	    "A" : ". ");
            len += formatex(szKeys[len], charsmax(szKeys)-len, "%s",  (button & IN_BACK) ? 		    " S " : " . ");
            len += formatex(szKeys[len], charsmax(szKeys)-len, "%s^n",    (button & IN_MOVERIGHT) ?   "D" : " .");
            len += formatex(szKeys[len], charsmax(szKeys)-len, "%s^n",    (button & IN_JUMP) ? 		"JUMP" : ".");
            len += formatex(szKeys[len], charsmax(szKeys)-len, "%s^n^n",  (button & IN_DUCK) ? 		"DUCK" : "      ");
        }
        else
        {
            formatex(szKeys, charsmax(szKeys), "^n^n^n^n^n");
        }

        sr_get_timer_display_text(target, szTime, charsmax(szTime));

        set_hudmessage(0, 55, 255, -1.0, 0.73, 0, _, rate, _, _, 1);
        ShowSyncHudMsg(id, g_iSyncHudSpeed, "%s%s^n%3.2f", szKeys, szTime, fSpeed);
        szTime[0] = '^0';
    }
}
public Task_CheckFrames()
{

    for(new id = 1; id <= MAX_PLAYERS; id++)
    {
        if(!is_user_alive(id))
        {
            continue;
        }

        static fails_till_print[33];
        if (g_fNextFpsCheck[id] > get_gametime()) continue;

        new cat = g_ePlayerInfo[id][m_iCategory];
        if(g_ePlayerInfo[id][m_iCategory] < Cat_FastRun && get_user_fps(id) > g_iCategorySign[cat] + FPS_OFFSET
                || g_ePlayerInfo[id][m_iCategory] >= Cat_FastRun && get_user_fps(id) > FPS_LIMIT + FPS_OFFSET)
        {
            if(fails_till_print[id] >= FAILS_TILL_PRINT)
            {
                fails_till_print[id] = 0;
                client_print_color(id, print_team_red, "%s^1 Incorrect ^3%d ^1fps. Auto attempt to set ^4%d^1!", PREFIX, floatround(get_user_fps(id)), g_ePlayerInfo[id][m_iCategory] < Cat_FastRun ? g_iCategorySign[cat] : FPS_LIMIT);
            }
            fails_till_print[id]++;

            ExecuteHamB(Ham_CS_RoundRespawn, id);
            client_cmd(id, "fps_max %d", g_iCategorySign[cat]);
        }
        g_fNextFpsCheck[id] = get_gametime() + 1.0;
    }
}

public cvar_fps_max_query_callback(id, const cvar[], const value[])
{
    // Если квар не существует value будет 'Bad CVAR request'
    // log_amx("User: '%s', cvar: '%s', value: '%s'", user_name, cvar, value);

    if(equali(value, "bad")) 
    {
        new name[33]; get_user_name(id, name, charsmax(name));
        log_amx("Cannot read fps_max for %s, set to 100.", name);
        g_ePlayerInfo[id][m_iInitialFps] = 100;
        return;
    }

    g_ePlayerInfo[id][m_iInitialFps] = clamp(str_to_num(value), 100, 9999);
}