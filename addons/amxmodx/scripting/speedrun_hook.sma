#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <speedrun>

#define KZ_LEVEL ADMIN_KICK 
#define PLUGIN	"Speedrun: Hook"
#define VERSION "0.1"
#define AUTHOR	"Lopol2010"

enum _:HookSettings 
{
    SPEED
};

new const HOOK_SPEED_NAMES[][] = 
{
    "SR_HOOK_SPEED_SLOW",
    "SR_HOOK_SPEED_MID",
    "SR_HOOK_SPEED_FAST",
    "SR_HOOK_SPEED_MAX",
};

new const Float:HOOK_SPEED_VALUES[] = 
{
    600.0, 800.0, 1200.0, 2000.0
};

new const g_iTotalSpeedTypes = sizeof HOOK_SPEED_NAMES;
new g_ePlayerSettings[33][HookSettings];

new bool:g_bCanHook[33];
new bool:g_bIsHooked[33];
new g_iHookOrigin[33][3];
/* new Float:antihookcheat[33] */
new bool:g_bHookSound;
new Float:g_fHookSpeed[33] = { 800.0, ... };
new g_iBeamSprite = 0;
new Float:g_fLastTimeHook[33] = { -1.0, ... };
new g_fwOnHookStart;

public plugin_init()
{
    
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("+hook","hook_on",KZ_LEVEL)
    register_clcmd("-hook","hook_off",KZ_LEVEL)
    register_concmd("hook","give_hook", KZ_LEVEL, "<name|#userid|steamid|@ALL> <on/off>")
    g_fwOnHookStart = CreateMultiForward("OnHookStart", ET_IGNORE, FP_CELL)
    g_bHookSound = bool:register_cvar("hook_sound","0")

    register_clcmd("say /hook","Hook_Menu");
    register_clcmd("say /h","Hook_Menu");
}

public plugin_cfg()
{
    for(new id = 1; id <= MaxClients; id++)
    {
        g_ePlayerSettings[id][SPEED] = 1;
    }
}

public plugin_natives()
{
    register_native("is_hook_active","_is_hook_active",1)
    register_native("is_hook_allowed","_is_hook_allowed",1)
    /* register_native("give_hook","give_hook",1) */
    register_native("user_hook_enable","_user_hook_enable",1)
    register_native("is_time_after_hook_passed","_is_time_after_hook_passed",1)
}

public Hook_Menu(id)
{
    if(!is_user_connected(id)) return PLUGIN_CONTINUE;

    new szMenu[64];

    new menu = menu_create(fmt("\wHook Menu"), "Menu_Handler")

    formatex(szMenu, charsmax(szMenu), "%L", id, HOOK_SPEED_NAMES[g_ePlayerSettings[id][SPEED]]);
    menu_additem(menu, szMenu, "0");
    
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
            g_ePlayerSettings[id][SPEED] += 1;
            if(g_iTotalSpeedTypes-1 < g_ePlayerSettings[id][SPEED]) {
                g_ePlayerSettings[id][SPEED] = 0;
            }
            g_fHookSpeed[id] = HOOK_SPEED_VALUES[g_ePlayerSettings[id][SPEED]]; 
        }
    }
    if(key != 9)
        Hook_Menu(id);
    return PLUGIN_HANDLED;
}
public bool:_is_time_after_hook_passed(id, Float:time)
{
    // server_print("%f %f %f", g_fLastTimeHook[id], get_gametime(), (get_gametime() - g_fLastTimeHook[id]))
    return g_fLastTimeHook[id] < 0.0 ? true : ((get_gametime() - g_fLastTimeHook[id]) >= time)
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
public plugin_precache()
{
    precache_sound("weapons/xbow_hit2.wav")
    g_iBeamSprite = precache_model("sprites/laserbeam.spr")
}

public give_hook(id)
{
    if (!(  get_user_flags( id ) & KZ_LEVEL ))
        return PLUGIN_HANDLED

    new szarg1[32], szarg2[8], bool:mode
    read_argv(1,szarg1,32)
    read_argv(2,szarg2,32)
    if(equal(szarg2,"on"))
        mode = true
        
    if(equal(szarg1,"@ALL"))
    {
        new Alive[32], alivePlayers
        get_players(Alive, alivePlayers, "ach")
        for(new i;i<alivePlayers;i++)
        {
            g_bCanHook[i] = mode
            if(mode)
                client_print_color(i, print_team_default,  "%s %L.", PREFIX, i, "KZ_HOOK")
                
        }
    }
    else
    {
        new pid = find_player("bl",szarg1);
        if(pid > 0)
        {
            g_bCanHook[pid] = mode
            if(mode)
            {
                client_print_color(pid, print_team_default, "%s %L.", PREFIX, pid, "KZ_HOOK")
                
            }
        }
    }
    
    return PLUGIN_HANDLED
}

public hook_on(id)
{
    if( !g_bCanHook[id] /*&& !( get_user_flags( id ) & KZ_LEVEL )*/ || !is_user_alive(id) )
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

public hook_off(id)
{
    remove_hook(id)
    
    return PLUGIN_HANDLED
}

public hook_task(id)
{
    if(!is_user_connected(id) || !is_user_alive(id))
        remove_hook(id)
    
    g_fLastTimeHook[id] = get_gametime()
    remove_beam(id)
    draw_hook(id)
    
    new origin[3], Float:velocity[3]
    get_user_origin(id,origin)
    new distance = get_distance(g_iHookOrigin[id],origin)
    
    velocity[0] = (g_iHookOrigin[id][0] - origin[0]) * (g_fHookSpeed[id] / distance)
    velocity[1] = (g_iHookOrigin[id][1] - origin[1]) * (g_fHookSpeed[id] / distance)
    velocity[2] = (g_iHookOrigin[id][2] - origin[2]) * (g_fHookSpeed[id] / distance)
        
    set_pev(id,pev_velocity,velocity)
}

public draw_hook(id)
{
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(1)				// TE_BEAMENTPOINT
    write_short(id)				// entid
    write_coord(g_iHookOrigin[id][0])		// origin
    write_coord(g_iHookOrigin[id][1])		// origin
    write_coord(g_iHookOrigin[id][2])		// origin
    write_short(g_iBeamSprite)			// sprite index
    write_byte(0)				// start frame
    write_byte(0)				// framerate
    write_byte(random_num(1,100))		// life
    write_byte(random_num(1,20))		// width
    write_byte(random_num(1,0))		// noise					
    write_byte(random_num(1,255))		// r
    write_byte(random_num(1,255))		// g
    write_byte(random_num(1,255))		// b
    write_byte(random_num(1,500))		// brightness
    write_byte(random_num(1,200))		// speed
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

