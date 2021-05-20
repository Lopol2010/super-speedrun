
#include <amxmodx>
#include <checkpoints>
#include <hidemenu>
#include <reapi>
#include <cstrike>
#include <speedrun_stats>

#define PLUGIN "Super Speedrun Server's Main Menu"
#define VERSION "0.1"
#define AUTHOR "Lopol2010"

#define ADMIN_TELEGRAM "@flowershy"

native rotate_user_category(id);
native get_user_category(id);

new const PREFIX[] = "^1[^4Speedrun^1]";
new const g_szCategory[][] = 
{
    "100 FPS", "200 FPS", "250 FPS", "333 FPS", "500 FPS", "Fastrun", "Bhop", "Crazy Speed", "2K"
};

public plugin_init(){
    register_plugin(PLUGIN,VERSION,AUTHOR);
    register_clcmd("say /menu","Command_Menu");
    register_clcmd("say /m","Command_Menu");
    register_clcmd("say_team /menu","Command_Menu");
    register_clcmd("say_team /m","Command_Menu");
    RegisterHookChain(RG_CBasePlayer_Spawn, "HC_CBasePlayer_Spawn_Post", true);
    register_dictionary("speedrun.txt")
}
public HC_CBasePlayer_Spawn_Post(id)
{
    if(is_user_alive(id))
        Command_Menu(id);
}
public Command_Menu(id)
{
    new szMenu[64], iLen, iMax = charsmax(szMenu), Keys;

    new menu = menu_create("\wSuper Speedrun \rv1.0-beta", "Menu_Handler")

    if(get_user_team(id) == TEAM_CT)
    {

        if(get_checkpoints_count(id) < 1) 
            formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_CHECKPOINT");
        else
            formatex(szMenu, charsmax(szMenu), "%L \y#%d", LANG_PLAYER, "SR_MENU_CHECKPOINT", get_checkpoints_count(id));
        menu_additem(menu, szMenu, "0");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_GOCHECK");
        menu_additem(menu, szMenu, "1");

        formatex(szMenu, charsmax(szMenu), "%L [\y%s\w]", LANG_PLAYER, "SR_MENU_CATEGORY", g_szCategory[get_user_category(id)]);
        menu_additem(menu, szMenu, "2");

        
        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_STATISTICS");
        menu_additem(menu, szMenu, "3");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_FPS");
        menu_additem(menu, szMenu, "4");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_SPEC");
        menu_additem(menu, szMenu, "5");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_CONTACT");
        menu_additem(menu, szMenu, "6");
    }
    else
    {
        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_JOINCT");
        menu_additem(menu, szMenu, "10");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_STATISTICS");
        menu_additem(menu, szMenu, "3");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_FPS");
        menu_additem(menu, szMenu, "4");

        formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_CONTACT");
        menu_additem(menu, szMenu, "6");
    }
    
    formatex(szMenu, charsmax(szMenu), "%L", LANG_PLAYER, "SR_MENU_CLOSE");
    menu_setprop(menu, MPROP_EXITNAME, szMenu);
    // menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);                // Force an EXIT item since pagination is disabled.
    // menu_setprop(menu, MPROP_PERPAGE, 0);
    menu_display(id, menu);
    
    return PLUGIN_HANDLED;
}
public Menu_Handler(id, menu, item)
{
    if(item < 0) return PLUGIN_CONTINUE;

	new cmd[3];
	menu_item_getinfo(menu, item, _, cmd,2);
	new key = str_to_num(cmd);
    switch(key)
    {
        case 0: checkpoint(id);
        case 1: gocheck(id);
        case 2: {
            // client_cmd(id, "say /game");
            rotate_user_category(id)
            // Command_Menu(id);
            // return PLUGIN_HANDLED;
        }
        case 3: sr_show_toplist(id);
        case 4: {
          show_hide_menu(id);  
          return PLUGIN_HANDLED;
        } 
        case 5: {
            // cs_set_user_team()
            rg_set_user_team(id, TEAM_SPECTATOR);
            user_kill(id);
        }
        case 6: {
            client_print_color(id, print_team_default, "%s %L", PREFIX, LANG_PLAYER, "SR_MENU_FEEDBACK");
            client_print_color(id, print_team_default, "%s %L ^4%s", PREFIX, LANG_PLAYER, "SR_MENU_TELEGRAM", ADMIN_TELEGRAM);
            // client_print_color(id, print_team_default, "%s Send any problems and suggestions in telegram ^4%s", PREFIX, ADMIN_TELEGRAM);
        }
        case 10: {
            rg_round_respawn(id);
            rg_set_user_team(id, TEAM_CT);
        }
    }
    if(key != 9)
        Command_Menu(id);
    return PLUGIN_HANDLED;
}

