#include <amxmodx>
#include <reapi>
#include <speedrun>

#define PLUGIN	"Speedrun: Hook"
#define VERSION "0.1"
#define AUTHOR	"Lopol2010"

#define speed_option(%1,%2) (SPEED_OPTIONS[g_ePlayerSettings[%1][m_iSpeedOption]][%2])
#define sprite_option(%1,%2) (SPRITE_OPTIONS[g_ePlayerSettings[%1][m_iSpriteOption]][%2])

enum _:SpeedOptions { Name[32], Float:Velocity };
new SPEED_OPTIONS[][SpeedOptions] = 
{
    { "SR_HOOK_SPEED_SLOW", 600.0 },
    { "SR_HOOK_SPEED_MID",  800.0 },
    { "SR_HOOK_SPEED_FAST", 1200.0 },
    { "SR_HOOK_SPEED_MAX",  2000.0 },
};

enum _:SpriteOptions { Name[32], Path[64] };
new SPRITE_OPTIONS[][SpriteOptions] = 
{
    { "SR_HOOK_SPRITE_DEFAULT", "sprites/laserbeam.spr" },
    { "SR_HOOK_SPRITE_SUPER",   "sprites/iHOOK/super_hook.spr" },
};

enum _:HookSettings 
{
    m_iSpeedOption,
    m_iSpriteOption,
};

new g_ePlayerSettings[33][HookSettings];

new bool:g_bCanHook[33] = { true, ... };
new bool:g_bIsHooked[33];
new g_iHookOrigin[33][3];
/* new Float:antihookcheat[33] */
new bool:g_bHookSound;
new Float:g_fHookSpeed[33];
new g_iSprite[33];
new g_iSpriteIds[sizeof SPRITE_OPTIONS];
new Float:g_fLastTimeHook[33] = { -1.0, ... };
new g_fwOnHookStart;

public plugin_init()
{
    
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("+hook", "Command_Hook_On");
    register_clcmd("-hook", "Command_Hook_Off");
    g_fwOnHookStart = CreateMultiForward("OnHookStart", ET_IGNORE, FP_CELL);
    g_bHookSound = bool:register_cvar("hook_sound","0");

    new const cmd[][] = { "/hook", "/h", "!hook", "!h" };
    for(new i = 0; i < sizeof cmd; i++) {
        register_clcmd(fmt("say %s", cmd[i]), "Command_Menu");
        register_clcmd(fmt("say_team %s", cmd[i]), "Command_Menu");
    }
}

public plugin_cfg()
{
    for(new id = 1; id <= MaxClients; id++)
    {
        ResetCachedSettings(id);
    }
}

public plugin_precache()
{
    precache_sound("weapons/xbow_hit2.wav");
    
    for(new i = 0; i < sizeof SPRITE_OPTIONS; i ++)
    {
        g_iSpriteIds[i] = precache_model(SPRITE_OPTIONS[i][Path]);
    }
}

public plugin_natives()
{
    register_native("hook_menu_display", "_hook_menu_display");
    register_native("is_hook_active", "_is_hook_active", 1);
    register_native("is_hook_allowed", "_is_hook_allowed", 1);
    register_native("user_hook_enable", "_user_hook_enable", 1);
    register_native("is_time_after_hook_passed", "_is_time_after_hook_passed", 1);
}

public client_disconnected(id)
{
    ResetCachedSettings(id);
}

public ResetCachedSettings(id)
{
    g_ePlayerSettings[id][m_iSpeedOption] = 1;
    g_ePlayerSettings[id][m_iSpriteOption] = 0;

    g_fHookSpeed[id] = speed_option(id, Velocity);
    g_iSprite[id] = g_iSpriteIds[g_ePlayerSettings[id][m_iSpriteOption]];
}

public Command_Menu(id)
{
    if(!is_user_connected(id)) return PLUGIN_CONTINUE;

    new szMenu[64];

    new menu = menu_create(fmt("\w%L", id, "SR_HOOK_MENU_TITLE"), "Menu_Handler");

    formatex(szMenu, charsmax(szMenu), "%L", id, "SR_HOOK_SPEED", id, speed_option(id, Name));
    menu_additem(menu, szMenu, "0");

    formatex(szMenu, charsmax(szMenu), "%L", id, "SR_HOOK_SPRITE", id, sprite_option(id, Name));
    menu_additem(menu, szMenu, "1");
    
    formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_CLOSE");
    menu_setprop(menu, MPROP_EXITNAME, szMenu);
    menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);                // Force an EXIT item since pagination is disabled.
    menu_setprop(menu, MPROP_PERPAGE, 0);
    menu_display(id, menu);
    
    return PLUGIN_HANDLED;
}

public Menu_Handler(id, menu, item)
{
    if(item < 0) return PLUGIN_CONTINUE;

    new cmd[3];
    menu_item_getinfo(menu, item, _, cmd, 2);
    new key = str_to_num(cmd);
    switch(key)
    {
        case 0: {
            g_ePlayerSettings[id][m_iSpeedOption] += 1;
            if(sizeof SPEED_OPTIONS-1 < g_ePlayerSettings[id][m_iSpeedOption]) {
                g_ePlayerSettings[id][m_iSpeedOption] = 0;
            }
            g_fHookSpeed[id] = speed_option(id, Velocity); 
        }
        case 1: {
            g_ePlayerSettings[id][m_iSpriteOption] += 1;
            if(sizeof SPRITE_OPTIONS-1 < g_ePlayerSettings[id][m_iSpriteOption]) {
                g_ePlayerSettings[id][m_iSpriteOption] = 0;
            }
            g_iSprite[id] = g_iSpriteIds[g_ePlayerSettings[id][m_iSpriteOption]]; 
        }
    }
    if(key != 9)
        Command_Menu(id);
    return PLUGIN_HANDLED;
}
public bool:_is_time_after_hook_passed(id, Float:time)
{
    // server_print("%f %f %f", g_fLastTimeHook[id], get_gametime(), (get_gametime() - g_fLastTimeHook[id]))
    return g_fLastTimeHook[id] < 0.0 ? true : ((get_gametime() - g_fLastTimeHook[id]) >= time)
}
public _hook_menu_display()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    Command_Menu(id);
}
public _is_hook_active(id)
{
    return g_bIsHooked[id]
}
public _is_hook_allowed(id)
{
    return g_bCanHook[id]
}
public _user_hook_enable(id, bool:isEnabled)
{
    g_bCanHook[id] = isEnabled
    if(!isEnabled) remove_hook(id)
}

public Command_Hook_On(id)
{
    if( !g_bCanHook[id] || !is_user_alive(id) )
    {
        return PLUGIN_HANDLED
    }

    get_user_origin(id, g_iHookOrigin[id], 3)
    g_bIsHooked[id] = true
    /* antihookcheat[id] = get_gametime() */
    
    if (get_pcvar_num(g_bHookSound) == 1)
    emit_sound(id,CHAN_STATIC,"weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)

    set_task(0.1,"hook_task",id,"",0,"ab")
    hook_task(id)
    g_fLastTimeHook[id] = get_gametime()
    ExecuteForward(g_fwOnHookStart, _, id)
    
    return PLUGIN_HANDLED
}

public Command_Hook_Off(id)
{
    remove_hook(id)
    
    return PLUGIN_HANDLED
}

public hook_task(id)
{
    if(!is_user_connected(id) || !is_user_alive(id))
        remove_hook(id);
    
    g_fLastTimeHook[id] = get_gametime();
    remove_beam(id);
    draw_hook(id);
    
    new origin[3], Float:velocity[3];
    get_user_origin(id, origin);
    new distance = get_distance(g_iHookOrigin[id],origin);
    
    velocity[0] = (g_iHookOrigin[id][0] - origin[0]) * (g_fHookSpeed[id] / distance);
    velocity[1] = (g_iHookOrigin[id][1] - origin[1]) * (g_fHookSpeed[id] / distance);
    velocity[2] = (g_iHookOrigin[id][2] - origin[2]) * (g_fHookSpeed[id] / distance);
    
    set_entvar(id, var_velocity, velocity);
}

public draw_hook(id)
{
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(1)				// TE_BEAMENTPOINT
    write_short(id)				// entid
    write_coord(g_iHookOrigin[id][0])		// origin
    write_coord(g_iHookOrigin[id][1])		// origin
    write_coord(g_iHookOrigin[id][2])		// origin
    write_short(g_iSprite[id])			// sprite index
    write_byte(0)				// start frame
    write_byte(0)				// framerate
    write_byte(random_num(100,100))		// life
    write_byte(random_num(15,15))		// width
    write_byte(random_num(0,0))		// noise					
    write_byte(random_num(255,255))		// r
    write_byte(random_num(255,255))		// g
    write_byte(random_num(255,255))		// b
    write_byte(random_num(500,500))		// brightness
    write_byte(random_num(0,0))		// speed
    message_end()
}

public remove_hook(id)
{
    if(task_exists(id))
        remove_task(id)
    remove_beam(id)
    g_bIsHooked[id] = false
    
}

public remove_beam(id)
{
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(99) // TE_KILLBEAM
    write_short(id)
    message_end()
}

