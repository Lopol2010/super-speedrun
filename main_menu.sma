
#include <amxmodx>
#include <checkpoints>
#include <hidemenu>
#include <reapi>
#include <cstrike>
#include <speedrun_stats>

#define PLUGIN "Super Speedrun Server's Main Menu"
#define VERSION "0.1"
#define AUTHOR "Lopol2010"

native rotate_user_category(id);
native get_user_category(id);

new const g_szCategory[][] = 
{
    "100 FPS", "200 FPS", "250 FPS", "333 FPS", "500 FPS", "Fastrun", "Bhop", "Crazy Speed", "2K"
};

public plugin_init(){
    register_plugin(PLUGIN,VERSION,AUTHOR);
    register_clcmd("say /menu","Command_Menu");
    // register_menucmd(register_menuid("MainMenu"), 1023, "Menu_Handler");
    // register_menucmd(register_menuid("MainMenu_Spec"), 0, "Menu_Handler_Spec");
}

public Command_Menu(id)
{
    new szMenu[64], iLen, iMax = charsmax(szMenu), Keys;

    new menu = menu_create("\wSuper Speedrun \rv1.0", "Menu_Handler")

    if(get_user_team(id) == TEAM_CT)
    {

        if(get_checkpoints_count(id) < 1) 
            formatex(szMenu, charsmax(szMenu), "\w Checkpoint");
        else
            formatex(szMenu, charsmax(szMenu), "\w Checkpoint \y#%d", get_checkpoints_count(id));
        menu_additem(menu, szMenu, "0");

        formatex(szMenu, charsmax(szMenu), "\w Gocheck");
        menu_additem(menu, szMenu, "1");

        formatex(szMenu, charsmax(szMenu), "\w Category [\y%s\w]", g_szCategory[get_user_category(id)]);
        menu_additem(menu, szMenu, "2");

        
        formatex(szMenu, charsmax(szMenu), "\w Statistics");
        menu_additem(menu, szMenu, "3");

        formatex(szMenu, charsmax(szMenu), "\w FPS Settings");
        menu_additem(menu, szMenu, "4");

        formatex(szMenu, charsmax(szMenu), "\w Go Spectator");
        menu_additem(menu, szMenu, "5");
    }
    else
    {
        formatex(szMenu, charsmax(szMenu), "\w Join game");
        menu_additem(menu, szMenu, "10");

        formatex(szMenu, charsmax(szMenu), "\w Statistics");
        menu_additem(menu, szMenu, "3");

        formatex(szMenu, charsmax(szMenu), "\w FPS Settings");
        menu_additem(menu, szMenu, "4");
    }
    
    // menu_setprop(menu, MPROP_EXITNAME, fmt("%l", "EXIT"));
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
        case 10: {
            rg_round_respawn(id);
            rg_set_user_team(id, TEAM_CT);
        }
    }
    if(key != 9)
        Command_Menu(id);
    return PLUGIN_HANDLED;
}

