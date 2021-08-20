//Original author Fai (BB.O.) - https://forums.alliedmods.net/showthread.php?p=1681614 (requires a player to have nightvision goggles in their inventory)
//Edit author is Foxa

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <nolag_nightvision>

#pragma semicolon 1

new const	plugin[]    	=    "NoLag Nightvision",
            version[]    	=    "2.0",
            author[]    	=    "Lopol2010";



new fwLightStyle;
new g_sDefaultLight[8];
new g_iNV[33]=NVG_OFF;
new p_cvSkyColor[3];

public plugin_init(){
    register_plugin(plugin, version, author);
     
	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "HC_CSGameRules_PlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_Observer_SetMode, "HC_CBasePlayer_Observer_SetMode", true);
 
    unregister_forward(FM_LightStyle, fwLightStyle);
    
    register_clcmd("nightvision", "cmd_NightVision");
    
    p_cvSkyColor[0]=get_cvar_pointer("sv_skycolor_r");
    p_cvSkyColor[1]=get_cvar_pointer("sv_skycolor_g");
    p_cvSkyColor[2]=get_cvar_pointer("sv_skycolor_b");
    
    set_pcvar_num(p_cvSkyColor[0], 0);
    set_pcvar_num(p_cvSkyColor[1], 0);
    set_pcvar_num(p_cvSkyColor[2], 0);

    // set_task(0.1, "spectators_nvg", .flags = "b");
}

public HC_CSGameRules_PlayerSpawn(id)
{
    set_user_nvg_mode(id, NVG_OFF);
}

public HC_CBasePlayer_Observer_SetMode(id)
{
    switch(get_entvar(id, var_iuser1))
    {
        case OBS_IN_EYE, OBS_CHASE_FREE, OBS_CHASE_LOCKED:
        {
            new target = get_entvar(id, var_iuser2);
            if(is_user_alive(target) && id != target && g_iNV[id] != g_iNV[target])
            {
                set_user_nvg_mode(id, g_iNV[target]);
            }
        }
        default:
        {
            set_user_nvg_mode(id, NVG_OFF);
        }
    }
}

public spectators_nvg()
{
    new iSpecMode;
    for(new id = 1, target; id <= MaxClients; id ++)
    {
        iSpecMode = get_entvar(id, var_iuser1);
        target = (iSpecMode == OBS_CHASE_LOCKED  || iSpecMode == OBS_CHASE_FREE || iSpecMode == OBS_IN_EYE) ? get_entvar(id, var_iuser2) : id;
        if(target == id || g_iNV[id] == g_iNV[target]) continue;

        set_user_nvg_mode(id, g_iNV[target]);
    }
}

public plugin_precache(){
    fwLightStyle=register_forward(FM_LightStyle, "fw_LightStyle");
}

public client_disconnected(id){
    g_iNV[id]=NVG_OFF;
}

public plugin_natives()
{
    register_native("get_user_nvg_mode", "_get_user_nvg_mode");
    register_native("set_user_nvg_mode", "_set_user_nvg_mode");
}

public _get_user_nvg_mode(pid, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return g_iNV[id];
}

public _set_user_nvg_mode(pid, argc)
{
    enum { arg_id = 1, arg_mode }
    new id = get_param(arg_id);
    new mode = get_param(arg_mode);
    switch(mode)
    {
        case NVG_OFF: NV(id, g_sDefaultLight);
        case NVG_NORMAL: NV(id, "z");
        case NVG_FULLBRIGHT: NV(id, "#");
    }
    g_iNV[id] = mode;
}

public cmd_NightVision(id){
    if(!is_user_alive(id))
        return PLUGIN_HANDLED;
    
    if(g_iNV[id]==NVG_OFF){
        set_user_nvg_mode(id, NVG_NORMAL);
        rg_send_audio(id, "items/nvg_on.wav");
    }
    else if(g_iNV[id]==NVG_NORMAL){
        set_user_nvg_mode(id, NVG_FULLBRIGHT);
        rg_send_audio(id, "items/nvg_on.wav");
    }
    else{
        set_user_nvg_mode(id, NVG_OFF);
        rg_send_audio(id, "items/nvg_off.wav");
    }

    spectators_nvg();
    
    return PLUGIN_HANDLED;
}

public fw_LightStyle(style, const value[]){
    if(!style)
        copy(g_sDefaultLight, charsmax(g_sDefaultLight), value);
}

NV(id, const type[]){
    message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
    write_byte(0);
    write_string(type);
    message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
