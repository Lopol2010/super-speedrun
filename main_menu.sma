
#include <amxmodx>
#include <checkpoints>
#include <hidemenu>

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
    register_menucmd(register_menuid("MainMenu"), 1023, "Menu_Handler");
}

public Command_Menu(id)
{
    new szMenu[256], iLen, iMax = charsmax(szMenu), Keys;

    iLen = formatex(szMenu, iMax, "\yMenu^n^n");
    
    if(get_checkpoints_count(id) < 1) 
        iLen += formatex(szMenu[iLen], iMax - iLen, "\r1.\w Checkpoint^n");
    else
        iLen += formatex(szMenu[iLen], iMax - iLen, "\r1.\w Checkpoint \y#%d^n", get_checkpoints_count(id));
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r2.\w Gocheck^n");
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r3.\w Category [\y%s\w]^n", g_szCategory[get_user_category(id)]);
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r4.\w Top 15^n");
    iLen += formatex(szMenu[iLen], iMax - iLen, "\r5.\w Boost FPS^n");
    iLen += formatex(szMenu[iLen], iMax - iLen, "^n^n^n^n^n^n\r0.\w Exit");

    Keys |= (1 << 0)|(1 << 1)|(1 << 2)|(1 << 3)|(1 << 4)|(1 << 9);
    
    show_menu(id, Keys, szMenu, -1, "MainMenu");
    return PLUGIN_HANDLED;
}
public Menu_Handler(id, key)
{
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
        case 3: client_cmd(id, "say /top15");
        case 4: {
          show_hide_menu(id);  
          return PLUGIN_HANDLED;
        } 
    }
    if(key != 9)
        Command_Menu(id);
    return PLUGIN_HANDLED;
}

