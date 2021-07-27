//Original author Fai (BB.O.) - https://forums.alliedmods.net/showthread.php?p=1681614 (requires a player to have nightvision goggles in their inventory)

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <nolag_nightvision>

#pragma semicolon 1

new const	plugin[]    	=    "NoLag Nightvision",
        version[]    	=    "1.0",
        author[]    	=    "Foxa";

#define MAX_PLAYERS 		32



new fwLightStyle;

new g_sDefaultLight[8];

new g_iNV[MAX_PLAYERS+1]=NVG_OFF;

new p_cvSkyColor[3];

public plugin_init(){
    register_plugin(plugin, version, author);
    
    unregister_forward(FM_LightStyle, fwLightStyle);
    
    register_clcmd("nightvision", "cmd_NightVision");
    
    p_cvSkyColor[0]=get_cvar_pointer("sv_skycolor_r");
    p_cvSkyColor[1]=get_cvar_pointer("sv_skycolor_g");
    p_cvSkyColor[2]=get_cvar_pointer("sv_skycolor_b");
    
    set_pcvar_num(p_cvSkyColor[0], 0);
    set_pcvar_num(p_cvSkyColor[1], 0);
    set_pcvar_num(p_cvSkyColor[2], 0);
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
}

public _get_user_nvg_mode(pid, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);

    return g_iNV[id];
}

public cmd_NightVision(id){
    if(!is_user_connected(id))
        return PLUGIN_HANDLED;
    
    if(g_iNV[id]==NVG_OFF){
        g_iNV[id]=NVG_NORMAL;
        NV(id, "z");
        rg_send_audio(id, "items/nvg_on.wav");
    }
    else if(g_iNV[id]==NVG_NORMAL){
        g_iNV[id]=NVG_FULLBRIGHT;
        NV(id, "#");
        rg_send_audio(id, "items/nvg_on.wav");
    }
    else{
        g_iNV[id]=NVG_OFF;
        NV(id, g_sDefaultLight);
        rg_send_audio(id, "items/nvg_off.wav");
    }
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
