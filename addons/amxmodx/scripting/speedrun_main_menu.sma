
#include <amxmodx>
#include <checkpoints>
#include <hidemenu>
#include <reapi>
#include <cstrike>
#include <hamsandwich>
#include <speedrun>

#define PLUGIN "Super Speedrun: Main Menu"
#define VERSION "1.1"
#define AUTHOR "Lopol2010"

#define ADMIN_TELEGRAM "@flowershy"

public plugin_init(){
    register_plugin(PLUGIN,VERSION,AUTHOR);
    register_clcmd("say /menu","Command_Menu");
    register_clcmd("say /m","Command_Menu");
    register_clcmd("say_team /menu","Command_Menu");
    register_clcmd("say_team /m","Command_Menu");
    RegisterHookChain(RG_CBasePlayer_Spawn, "HC_CBasePlayer_Spawn_Post", true);
}
public plugin_natives()
{
    register_native("main_menu_display", "_main_menu_display");
}
public _main_menu_display()
{
    enum { arg_id = 1 }
    new id = get_param(arg_id);
    Command_Menu(id);
}
public HC_CBasePlayer_Spawn_Post(id)
{
    if(is_user_alive(id))
    {
        Command_Menu(id);
    }
}
public Command_Menu(id)
{
    if(!is_user_connected(id)) return PLUGIN_CONTINUE;

    new szMenu[64];

    new menu = menu_create("\wSuper Speedrun \rv1.0-beta", "Menu_Handler")

    if(get_user_team(id) == 2)
    {

        if(get_checkpoints_count(id) < 1) 
            formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_CHECKPOINT");
        else
            formatex(szMenu, charsmax(szMenu), "%L \y#%d", id, "SR_MENU_CHECKPOINT", get_checkpoints_count(id));
        menu_additem(menu, szMenu, "0");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_GOCHECK");
        menu_additem(menu, szMenu, "1");

        menu_addblank2(menu);

        formatex(szMenu, charsmax(szMenu), "%L [\y%s\w]", id, "SR_MENU_CATEGORY", g_szCategory[get_user_category(id)]);
        menu_additem(menu, szMenu, "2");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_RESTART");
        menu_additem(menu, szMenu, "7");
        
        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_SPEC");
        menu_additem(menu, szMenu, "5");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_STATISTICS");
        menu_additem(menu, szMenu, "3");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_FPS");
        menu_additem(menu, szMenu, "4");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_CONTACT");
        menu_additem(menu, szMenu, "6");
    }
    else
    {
        menu_addblank2(menu);
        menu_addblank2(menu);
        menu_addblank2(menu);

        formatex(szMenu, charsmax(szMenu), "%L [\y%s\w]", id, "SR_MENU_CATEGORY", g_szCategory[get_user_category(id)]);
        menu_additem(menu, szMenu, "2");

        menu_addblank2(menu);
        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_JOINCT");
        menu_additem(menu, szMenu, "10");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_STATISTICS");
        menu_additem(menu, szMenu, "3");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_FPS");
        menu_additem(menu, szMenu, "4");

        formatex(szMenu, charsmax(szMenu), "%L", id, "SR_MENU_CONTACT");
        menu_additem(menu, szMenu, "6");
    }
    
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
    menu_item_getinfo(menu, item, _, cmd,2);
    new key = str_to_num(cmd);
    switch(key)
    {
        case 0: checkpoint(id);
        case 1: gocheck(id);
        case 2: {
            rotate_user_category(id)
        }
        case 3: sr_show_toplist(id);
        case 4: {
          show_hide_menu(id);  
          return PLUGIN_HANDLED;
        } 
        case 5: {
            sr_command_spec(id);
        }
        case 6: {
            client_print_color(id, print_team_default, "%s %L", PREFIX, id, "SR_MENU_FEEDBACK");
            client_print_color(id, print_team_default, "%s %L ^4%s", PREFIX, id, "SR_MENU_TELEGRAM", ADMIN_TELEGRAM);
            // client_print_color(id, print_team_default, "%s Send any problems and suggestions in telegram ^4%s", PREFIX, ADMIN_TELEGRAM);
        }
        case 7: {
            sr_command_start(id);
        }
        case 10: {
            sr_command_spec(id);
        }
    }
    if(key != 9)
        Command_Menu(id);
    return PLUGIN_HANDLED;
}

