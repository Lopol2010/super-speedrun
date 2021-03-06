#include <amxmodx> 
#include <fun>
#include <amxmisc> 
#include <reapi>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <speclist>
#include <speedrun>
#include <hamsandwich>

#define PLUGIN "HUD Customizer 0.4" 
#define VERSION "0.4" 
#define AUTHOR "Igoreso" 


// Hides Crosshair, Ammo, Weapons List ( CAL in code ). Players won't be able to switch weapons using list so it's not recommended
#define HUD_HIDE_CAL (1<<0)

// Hides Flashlight, but adds Crosshair ( Flash in code )
#define HUD_HIDE_FLASH (1<<1)

// Hides all. Equal to "hud_draw 0", it removes everything (amx's menus TOO), so it's hardly not recommended.
//#define HUD_HIDE_ALL (1<<2)

// Hides Radar, Health & Armor, but adds Crosshair ( RHA in code )	
#define HUD_HIDE_RHA (1<<3)

// Hides Timer	
#define HUD_HIDE_TIMER (1<<4)

// Hides Money
#define HUD_HIDE_MONEY (1<<5)

// Hides Crosshair ( Cross in code )
#define HUD_HIDE_CROSS (1<<6)

// Draws additional Crosshair, NOT tested.
//#define HUD_DRAW_CROSS (1<<7)


#define MAX_ENTITYS 900+15*32

new g_msgHideWeapon
new bool:g_bHideCAL
new bool:g_bHideFlash
//new bool:g_bHideAll
new bool:g_bHideRHA
new bool:g_bHideTimer
new bool:g_bHideMoney
new bool:g_bHideCross
//new bool:g_bDrawCross
new bool:gWaterFound
new bool:gWaterEntity[MAX_ENTITYS]

new g_cvarHideCAL
new g_cvarHideFlash
//new g_cvarHideAll
new g_cvarHideRHA
new g_cvarHideTimer
new g_cvarHideMoney
new g_cvarHideCross
//new g_cvarDrawCross
new g_weaponHidden[33]
new gViewInvisible[33]
new gWaterInvisible[33]
new g_viewmodel[33][64]

public plugin_init() 
{ 
    register_plugin(PLUGIN, VERSION, AUTHOR) 
 
    register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1) 

    register_clcmd("say /hide", "HideMenu");
    register_clcmd("say /invis", "HideMenu");
    register_clcmd("say_team /hide", "HideMenu");
    register_clcmd("say_team /invis", "HideMenu");

    g_msgHideWeapon = get_user_msgid("HideWeapon")
    register_event("ResetHUD", "onResetHUD", "b")
    register_event("CurWeapon", "Event_CurWeapon", "be","1=1")
    register_message(g_msgHideWeapon, "msgHideWeapon")
    
    g_cvarHideCAL = register_cvar("amx_hud_hide_cross_ammo_weaponlist", "0")
    g_cvarHideFlash = register_cvar("amx_hud_hide_flashlight", "1")
//	g_cvarHideAll = register_cvar("amx_hud_hide_all", "0")	// NOT RECOMMENDED
    g_cvarHideRHA = register_cvar("amx_hud_hide_radar_health_armor", "1")
    g_cvarHideTimer = register_cvar("amx_hud_hide_timer", "1")
    g_cvarHideMoney = register_cvar("amx_hud_hide_money", "1")
    g_cvarHideCross = register_cvar("amx_hud_hide_crosshair", "0")
//	g_cvarDrawCross = register_cvar("amx_hud_draw_newcross", "0")

    HudApplyCVars()
    register_dictionary("speedrun.txt");
} 

public plugin_cfg()
{
    new ent = -1;
    while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_water") ) != 0 )
    {
        if( !gWaterFound )
        {
            gWaterFound = true;
        }

        gWaterEntity[ent] = true;
    }
    
    ent = -1;
    while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_illusionary") ) != 0 )
    {
        if( pev( ent, pev_skin ) ==  CONTENTS_WATER )
        {
            if( !gWaterFound )
            {
                gWaterFound = true;
            }
    
            gWaterEntity[ent] = true;
        }
    }
    
    ent = -1;
    while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_conveyor") ) != 0 )
    {
        if( pev( ent, pev_spawnflags ) == 3 )
        {
            if( !gWaterFound )
            {
                gWaterFound = true;
            }
    
            gWaterEntity[ent] = true;
        }
    }

}

public plugin_natives()
{
    register_native("is_weapon_hidden", "_is_weapon_hidden")
    register_native("show_hide_menu", "_show_hide_menu")
    
}
public HideMenu(id)
{
    new g_menu = menu_create(fmt("%L", id, "SR_SET_MENU_TITLE"), "HideMenu_Handler");

    menu_additem( g_menu, fmt("%L - %L", id, "SR_SET_MENU_PLAYERS", id, !gViewInvisible[id] ? "SR_SET_MENU_VISIBLE" : "SR_SET_MENU_HIDDEN"), "0" )
    menu_additem( g_menu, fmt("%L - %L", id, "SR_SET_MENU_WEAPON", id, !g_weaponHidden[id] ? "SR_SET_MENU_VISIBLE" : "SR_SET_MENU_HIDDEN"), "1" )
    menu_additem( g_menu, fmt("%L - %L", id, "SR_SET_MENU_WATER", id, !gWaterInvisible[id] ? "SR_SET_MENU_VISIBLE" : "SR_SET_MENU_HIDDEN"), "2" )
    menu_additem( g_menu, fmt("%L - %L", id, "SR_SET_MENU_SPEC", id, is_speclist_enabled(id) ? "SR_SET_MENU_VISIBLE" : "SR_SET_MENU_HIDDEN"), "3" )
    menu_addblank( g_menu, 0 )
    menu_additem( g_menu, fmt("%L - %L", id, "SR_SET_MENU_BEEP", id, sr_is_beep_enabled(id) ? "SR_SET_MENU_VISIBLE" : "SR_SET_MENU_HIDDEN"), "4" )
    menu_additem( g_menu, fmt("%L", id, "SR_SET_MENU_HOOKMENU"), "6" )
    // menu_addblank2( g_menu )
    menu_addblank( g_menu, 0 )
    
    menu_additem( g_menu, fmt("%L", id, "SR_SET_MENU_UPDATE"), "5" )
    menu_addblank2( g_menu )
    menu_addblank2( g_menu )

    menu_setprop( g_menu, MPROP_PERPAGE, 0 )
	menu_setprop( g_menu, MPROP_EXIT, MEXIT_FORCE )
	menu_setprop( g_menu, MPROP_EXITNAME, fmt("%L", id, "SR_MENU_CLOSE") )
    menu_display( id, g_menu )
    return PLUGIN_HANDLED
}

public client_disconnected(id)
{
    g_weaponHidden[id] = false
    gViewInvisible[id] = false
    gWaterInvisible[id] = false
    g_viewmodel[id] = ""
}

public HideMenu_Handler(id, menu, item)
{
    if( item == MENU_EXIT )
    {
        main_menu_display(id)
        return PLUGIN_HANDLED
    }
    new cmd[3];
    menu_item_getinfo(menu, item, _, cmd, 2);
    new key = str_to_num(cmd);
    switch(key)
    {
        case 0: 
        {
            cmdInvisible(id)
        }
        case 1: 
        {
            hide_weapon(id)
        }
        case 2: 
        {
            cmdWaterInvisible(id)
        }
        case 3:
        {
            speclist_toggle(id)
        }
        case 4:
        {
            sr_toggle_beep(id)
        }
        case 5:
        {
            sr_update_nickname(id)
        }
        case 6:
        {
            hook_menu_display(id)
            return PLUGIN_HANDLED
        }
    }
    HideMenu(id)
    return PLUGIN_HANDLED
}
public cmdInvisible(id)
{

    gViewInvisible[id] = !gViewInvisible[id]
    // if(gViewInvisible[id])
    // 	kz_chat(id, "%L", id, "KZ_INVISIBLE_PLAYERS_ON")
    // else
    // 	kz_chat(id, "%L", id, "KZ_INVISIBLE_PLAYERS_OFF")

    return PLUGIN_HANDLED
}

public cmdWaterInvisible(id)
{
    if( !gWaterFound )
    {
        // kz_chat(id, "%L", id, "KZ_INVISIBLE_NOWATER")
        // return PLUGIN_HANDLED
    }
    
    gWaterInvisible[id] = !gWaterInvisible[id]
    // if(gWaterInvisible[id])
    // 	kz_chat(id, "%L", id, "KZ_INVISIBLE_WATER_ON")
    // else
    // 	kz_chat(id, "%L", id, "KZ_INVISIBLE_WATER_OFF")
        
    return PLUGIN_HANDLED
}
public FM_client_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet) 
{ 
    if( player )
    {
        if(gViewInvisible[host])
        {
            set_es(es, ES_RenderMode, kRenderTransTexture)
            set_es(es, ES_RenderAmt, 0)
            set_es(es, ES_Origin, { 999999999.0, 999999999.0, 999999999.0 } )
        }
    }
    else if( gWaterInvisible[host] && gWaterEntity[ent] )
    {
        set_es(es, ES_Effects, get_es( es, ES_Effects ) | EF_NODRAW )
    }
    
    return FMRES_IGNORED
} 

public hide_weapon(id)
{
    g_weaponHidden[id] = !g_weaponHidden[id]
    set_pev(id, pev_viewmodel2, g_weaponHidden[id] ? "" : g_viewmodel[id] )
    onResetHUD(id)
}

public _show_hide_menu()
{
    enum {
        arg_id = 1
    }
    HideMenu(get_param(arg_id))
}

public _is_weapon_hidden()
{
    enum {
        arg_id = 1
    }
    return g_weaponHidden[get_param(arg_id)]
}

public Event_CurWeapon(id) 
{     
    new ptr;
    pev(id, pev_viewmodel2, ptr, g_viewmodel[id], charsmax(g_viewmodel[]))

    if(g_weaponHidden[id])
        set_pev(id, pev_viewmodel2, "")
}

public onResetHUD(id)
{
    HudApplyCVars()
    new iHideFlags = GetHudHideFlags()

    if(g_weaponHidden[id])
        iHideFlags |= HUD_HIDE_CAL
    else
        iHideFlags &= ~HUD_HIDE_CAL

    if(iHideFlags)
    {
        message_begin(MSG_ONE, g_msgHideWeapon, _, id)
        write_byte(iHideFlags)
        message_end()
    }	
}

public msgHideWeapon(msg_id, msg_dest, msg_entity)
{
    new iHideFlags = GetHudHideFlags()

    if(g_weaponHidden[msg_entity])
        iHideFlags |= HUD_HIDE_CAL
    else
        iHideFlags &= ~HUD_HIDE_CAL

    if(iHideFlags)
        set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags)
}

GetHudHideFlags()
{
    new iFlags

    if( g_bHideCAL )
        iFlags |= HUD_HIDE_CAL
    if( g_bHideFlash )
        iFlags |= HUD_HIDE_FLASH
//	if( g_bHideAll )
//		iFlags |= HUD_HIDE_ALL
    if( g_bHideRHA )
        iFlags |= HUD_HIDE_RHA
    if( g_bHideTimer )
        iFlags |= HUD_HIDE_TIMER
    if( g_bHideMoney )
        iFlags |= HUD_HIDE_MONEY 
    if( g_bHideCross )
        iFlags |= HUD_HIDE_CROSS
//	if( g_bDrawCross )
//		iFlags |= HUD_DRAW_CROSS


    return iFlags
}

HudApplyCVars()
{
    g_bHideCAL = bool:get_pcvar_num(g_cvarHideCAL)
    g_bHideFlash = bool:get_pcvar_num(g_cvarHideFlash)
//	g_bHideAll = bool:get_pcvar_num(g_cvarHideAll)
    g_bHideRHA = bool:get_pcvar_num(g_cvarHideRHA)
    g_bHideTimer = bool:get_pcvar_num(g_cvarHideTimer)
    g_bHideMoney = bool:get_pcvar_num(g_cvarHideMoney)
    g_bHideCross = bool:get_pcvar_num(g_cvarHideCross)
//	g_bDrawCross = bool:get_pcvar_num(g_cvarDrawCross)
}
