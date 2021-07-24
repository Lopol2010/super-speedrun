#include <amxmodx>
#include <fakemeta>
#include <nvault>
#include <speedrun>
#include <sxgeo>

#define MAX_LANGS_NUM 9
#define MAX_LANG_KEY_LENGTH 3
#define MAX_LANG_NAME_LENGTH 32

enum _:LANG {
    LANG_KEY[MAX_LANG_KEY_LENGTH],
    LANG_NAME[MAX_LANG_NAME_LENGTH]
}

new g_Langs[MAX_LANGS_NUM][LANG], g_LangsNum;

new g_DefaultLang;
new g_PlayersSettings;
new g_PlayersLang[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin("Auto Language with Menu", "2.0", "F@nt0M remake by Lopol2010");
    register_dictionary("langmenu.txt");

    register_menucmd(register_menuid("LANGMENU"), 1023, "HandleMenu");
    register_srvcmd("langmenu_add", "CmdAddLang");
    register_srvcmd("langmenu_cmd", "CmdAddCmd");
    register_clcmd("amx_langmenu", "CmdLangMenu");

    new path[128];
    get_localinfo("amxx_configsdir", path, charsmax(path));
    server_cmd("exec %s/langmenu.cfg", path);
    server_exec();

    g_PlayersSettings = nvault_open("players_lang");
}

public plugin_cfg() {
    if (g_LangsNum <= 0) {
        set_fail_state("Fail to load config");
        return;
    }
    set_cvar_num("amx_client_languages", 1);
    new langKey[MAX_LANG_KEY_LENGTH];
    get_cvar_string("amx_language", langKey, charsmax(langKey));
    g_DefaultLang = findLangId(langKey);
    if (g_DefaultLang == -1) {
        g_DefaultLang = 0;
    }
}

public plugin_natives()
{
    register_native("show_langmenu", "_show_langmenu", 1);
}

public _show_langmenu(id)
{
    CmdLangMenu(id);
}

public plugin_end() {
    if (g_PlayersSettings != INVALID_HANDLE) {
        nvault_close(g_PlayersSettings);
    }
}

public client_putinserver(id)
{
    new arg[1]; arg[0] = id;
    set_task(3.0, "print_info_task", _, arg, sizeof arg);
}

public print_info_task(arg[])
{
    new id = arg[0];
    if(is_user_connected(id))
        client_print_color(id, print_team_default, "%s Your language is set to ^4%s^1. You can change it via ^4/lang^1 menu.", PREFIX, g_Langs[g_PlayersLang[id]][LANG_NAME]);
}

public client_authorized(id) {

    new authid[24], langKey[MAX_LANG_KEY_LENGTH + 1], lang;
    get_user_authid(id, authid, charsmax(authid));


    // first try to get player's language from vault
    if (nvault_lookup(g_PlayersSettings, authid, langKey, charsmax(langKey), lang)) {
        lang = findLangId(langKey);
        if (lang != -1) {
            setUserLang(id, lang, false);
        } else {
            setUserLang(id, g_DefaultLang, true);
        }
    } else {

        // if no language found in vault then try to get player's language by their country code 
        new szIP[16]; get_user_ip(id, szIP, charsmax(szIP), /*strip port*/ 0);
        new code[3]; 
        if(sxgeo_code(szIP, code, charsmax(code)))
        {
            lang = findLangId(code);
            if (lang != -1) {
                setUserLang(id, lang, true);
                return;
            } 
        }

        // if sxgeo fails or found language not supported then try to get language from user info's lang key
        get_user_info(id, "lang", langKey, charsmax(langKey))
        lang = findLangId(langKey);
        if (lang != -1) {
            setUserLang(id, lang, true);
        } else {
            setUserLang(id, g_DefaultLang, true);
        }
    }

}

public CmdAddCmd() {
    new cmd[32];
    if (read_args(cmd, charsmax(cmd)) > 0) {
        remove_quotes(cmd);
        trim(cmd);
        if (strlen(cmd) > 0) {
            register_clcmd(cmd, "CmdLangMenu");
        }
    }

    return PLUGIN_HANDLED;
}

public CmdAddLang() {
    if (read_argc() < 2 || g_LangsNum >= MAX_LANGS_NUM) {
        return PLUGIN_HANDLED;
    }

    read_argv(1, g_Langs[g_LangsNum][LANG_KEY], MAX_LANG_KEY_LENGTH);
    read_argv(2, g_Langs[g_LangsNum][LANG_NAME], MAX_LANG_NAME_LENGTH);
    g_LangsNum++;

    return PLUGIN_HANDLED;
}

public CmdLangMenu(id) {

    new keys = MENU_KEY_0;

    new menu[512];
    new len = formatex(menu, charsmax(menu), "\r%L^n^n", id, "LANG_MENU_TITLE");

    for (new i = 0; i < g_LangsNum; i++) {
        if (g_PlayersLang[id] == i) {
            len += formatex(menu[len], charsmax(menu) - len, "\r[\y%i\r]\d %s \y(%L)^n", i + 1, g_Langs[i][LANG_NAME], id, "LANG_MENU_CURRENT");
        } else {
            keys |= (1 << i);
            len += formatex(menu[len], charsmax(menu) - len, "\r[\y%i\r]\w %s^n", i + 1, g_Langs[i][LANG_NAME]);
        }
    }

    formatex(menu[len], charsmax(menu) - len, "^n\r[\y0\r] \w%L", id, "LANG_MENU_CANCEL");
    show_menu(id, keys, menu, -1, "LANGMENU");

    return PLUGIN_HANDLED;
}

public HandleMenu(id, key) {
    if (key == 9) {
        return;
    }

    if (0 <= key < g_LangsNum) {
        setUserLang(id, key, true);
        client_print_color(id, print_team_default, "%L", id, "LANG_MENU_SAVED", PREFIX);
    }
}

findLangId(const lang[]) {
    for (new i = 0; i < g_LangsNum; i++) {
        if (equal(g_Langs[i][LANG_KEY], lang)) {
            return i;
        }
    }

    return -1;
}

setUserLang(const id, const lang, const bool:save = false) {
    g_PlayersLang[id] = lang;
    new infobuffer = engfunc(EngFunc_GetInfoKeyBuffer, id);
    engfunc(EngFunc_SetClientKeyValue, id, infobuffer, "lang", g_Langs[lang][LANG_KEY]);
    if (save && g_PlayersSettings != INVALID_HANDLE) {
        new authid[24], langKey[MAX_LANG_KEY_LENGTH];
        get_user_authid(id, authid, charsmax(authid));
        copy(langKey, charsmax(langKey), g_Langs[lang][LANG_KEY]);
        nvault_pset(g_PlayersSettings, authid, g_Langs[lang][LANG_KEY]);
    }
}