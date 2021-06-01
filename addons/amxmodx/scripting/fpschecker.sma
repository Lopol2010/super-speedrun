#pragma semicolon 1
#include <amxmodx>
#include <fakemeta>

#define UPDATE 0.5	// Частота обновлений худа
/*** Настройка цвета в RGB ***/
#define RED 64		// Количество красного
#define GREEN 64	// Количество зеленого
#define BLUE 64		// Количество синего
/*** Конец настройки цвета ***/

#define FPS_CHECK_CMD       "/fps"


public plugin_init()
{
    register_plugin("Fps Checker", "0.3", "Dev-CS.ru & Lopol2010");
    register_forward(FM_CmdStart, "CmdStart");

    register_clcmd("say", "check");

    set_task(UPDATE, "ShowFpsHud", .flags="b");

}

enum fps_s {
    warnings,
    num_cmds,
    msec_sum,
    Float: next_check,
    Float: fps
} new fps_info[33][fps_s];


public client_connect(id) {
    arrayset(fps_info[id], 0, sizeof(fps_info[]));
}

public CmdStart(id, uc_handle)
{ 
    if (fps_info[id][next_check] <= get_gametime())
    {         
        fps_info[id][fps] = (fps_info[id][num_cmds] * 1000.0) / fps_info[id][msec_sum];

        fps_info[id][num_cmds] = 0;
        fps_info[id][msec_sum] = 0;
        fps_info[id][next_check] = get_gametime() + 1.0;
    }
    fps_info[id][num_cmds]++;
    fps_info[id][msec_sum] += get_uc(uc_handle, UC_Msec);
}

public ShowFpsHud() {

    for(new id = 1; id <= MAX_PLAYERS; id++)
    {
        if(!is_user_alive(id)){
            new spec;
            spec = pev(id, pev_iuser2);
            if(spec)
            {
                set_hudmessage(RED, GREEN, BLUE, 0.15, 0.15, 0, _, UPDATE, UPDATE, UPDATE, .channel = 3);
                show_hudmessage(id, "FPS: %f", fps_info[spec][fps]);
            }
        }
    }
}
public plugin_natives()
{
    register_native("get_user_fps", "_get_user_fps");
}

public _get_user_fps(plugin, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return floatround(fps_info[id][fps]);
}

public check(id)
{
    new const cmdlen = strlen(FPS_CHECK_CMD);
    new arg[40], cmd[10], nick[32];
    read_args(arg,charsmax(arg));
    remove_quotes(arg);
    trim(arg);

    parse(arg, cmd, cmdlen, nick, charsmax(nick));

    if(!equali(arg, FPS_CHECK_CMD, cmdlen))
    {
        return PLUGIN_CONTINUE;
    }

    if(strlen(arg) - cmdlen == 0)
    {
        client_print_color(id, print_team_default, "[^4FPS Checker^1] Usage: /fps nickname");
        return PLUGIN_HANDLED_MAIN;
    }

    new targetId;
    targetId = find_player_ex(FindPlayer_CaseInsensitive | FindPlayer_MatchNameSubstring, nick); 

    if(targetId != 0)
    {
        new targetName[32];
        get_user_name(targetId, targetName, charsmax(targetName));
        client_print_color(id, print_team_default, "[^4FPS Checker^1] Player ^4%s ^1has ^4%f ^1fps", targetName, fps_info[targetId][fps]);
    }
    else 
    {
        client_print_color(id, print_team_default, "[^4FPS Checker^1] Player ^4%s ^1not found", nick);
    }
    return PLUGIN_HANDLED_MAIN;
}

stock kick_user(id, szReason[])
{
    new iUserId = get_user_userid(id);
    server_cmd("kick #%d ^" % s ^"", iUserId, szReason);
}