//Original author Fai (BB.O.) - https://forums.alliedmods.net/showthread.php?p=1681614 (requires a player to have nightvision goggles in their inventory)

#include <amxmodx>
#include <fakemeta>

#pragma semicolon 1

new const	plugin[]    	=    "NoLag Nightvision",
        version[]    	=    "1.0",
        author[]    	=    "Foxa";

#define MAX_PLAYERS 		32

#define OFF 			0
#define NORMAL 			1
#define FULLBRIGHT		2

new fwLightStyle;

new g_sDefaultLight[8];

new g_iNV[MAX_PLAYERS+1]=OFF;

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
    g_iNV[id]=OFF;
}

public cmd_NightVision(id){
    if(!is_user_connected(id))
        return PLUGIN_HANDLED;
    
    if(g_iNV[id]==OFF){
        g_iNV[id]=NORMAL;
        NV(id, "z");
        client_cmd(id, "spk items/nvg_on");
    }
    else if(g_iNV[id]==NORMAL){
        g_iNV[id]=FULLBRIGHT;
        NV(id, "#");
        client_cmd(id, "spk items/nvg_on");
        // client_cmd(id, "spk items/nvg_off");
    }
    else{
        g_iNV[id]=OFF;
        NV(id, g_sDefaultLight);
        client_cmd(id, "spk items/nvg_off");
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
