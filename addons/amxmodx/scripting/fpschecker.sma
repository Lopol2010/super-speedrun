#pragma semicolon 1
#include <amxmodx>
#include <fakemeta>

#define UPDATE 0.5	// Частота обновлений худа
/*** Настройка цвета в RGB ***/
#define RED 50		// Количество красного
#define GREEN 50	// Количество зеленого
#define BLUE 50		// Количество синего
/*** Конец настройки цвета ***/

#define FPS_CHECK_CMD       "/fps"


public plugin_init()
{
    register_plugin("Fps Checker", "0.3", "Dev-CS.ru & Lopol2010");
    register_forward(FM_CmdStart, "CmdStart");

    register_clcmd("say", "check");

    set_task(UPDATE, "ShowFpsHud", .flags="b");

}

enum _:fps_s {
    warnings,
    num_cmds,
    msec_sum,
    Float: next_check,
    Float: fps,

    bool:record,
    Float: max_avg_fps,
    Float: min_avg_fps,
} 

// this is for interval checks
new fps_info[33][fps_s];
// this is for recording total fps on period of time
new fps_record[33][fps_s];


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

    if(fps_record[id][record])
    {
        fps_record[id][num_cmds]++;
        fps_record[id][msec_sum] += get_uc(uc_handle, UC_Msec);
        fps_record[id][fps] = (fps_record[id][num_cmds] * 1000.0) / fps_record[id][msec_sum];
        if(fps_record[id][fps] > fps_record[id][max_avg_fps])
        {
            fps_record[id][max_avg_fps] = fps_record[id][fps];
        }
        else if(fps_record[id][fps] < fps_record[id][min_avg_fps])
        {
            fps_record[id][min_avg_fps] = fps_record[id][fps];
        }
    }
}

public ShowFpsHud() {

    for(new id = 1; id <= MAX_PLAYERS; id++)
    {
        if(!is_user_alive(id) && is_user_connected(id)){
            new spec;
            spec = pev(id, pev_iuser2);
            if(spec)
            {
                set_hudmessage(RED, GREEN, BLUE, 0.80, 0.13, 0, _, UPDATE, UPDATE, UPDATE, .channel = 3);
                show_hudmessage(id, "FPS: %d", floatround(fps_info[spec][fps]));
            }
        }
    }
}
public plugin_natives()
{
    register_native("get_user_fps", "_get_user_fps");
    register_native("record_user_fps", "_record_user_fps");
    register_native("get_user_avg_fps", "_get_user_avg_fps");
    register_native("get_user_max_avg_fps", "_get_user_max_avg_fps");
    register_native("get_user_min_avg_fps", "_get_user_min_avg_fps");
}

public Float:_get_user_min_avg_fps(plugin, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return fps_record[id][min_avg_fps];
}
public Float:_get_user_max_avg_fps(plugin, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return fps_record[id][max_avg_fps];
}
public Float:_get_user_avg_fps(plugin, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return fps_record[id][fps];
}
public _record_user_fps(plugin, argc)
{
    enum { arg_id = 1, arg_enabled = 2 }
    new id = get_param(arg_id);
    new bool:enabled = bool:get_param(arg_enabled);
    fps_record[id][record] = enabled;
    if(fps_record[id][record])
    {
        fps_record[id][num_cmds] = 0;
        fps_record[id][msec_sum] = 0;
        fps_record[id][max_avg_fps] = 0.0;
        fps_record[id][min_avg_fps] = 1_000_000_000.0;
    }
}

public Float:_get_user_fps(plugin, argc)
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    return fps_info[id][fps];
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
