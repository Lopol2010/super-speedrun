#include <amxmodx>
#include <sxgeo>
// #include <geoip>
#include <speedrun>
#include <chatmanager>

#if (AMXX_VERSION_NUM < 183) || defined NO_NATIVE_COLORCHAT
    #include <colorchat>
#else
    #define DontChange print_team_default
    #define client_disconnect client_disconnected
#endif

#pragma semicolon 1

stock const STEAM_PREFIX[] = "^1[^4Steam^1]";
new const CONNECT_SOUND[] = "buttons/blip1.wav";

new g_pcvar_amx_language;
new g_bSteamPlayer[33];

public plugin_init()
{
    register_plugin("[SxGeo] Connect Info", "1.0", "s1lent");
    register_dictionary("sxgeo_connect_info.txt");

    g_pcvar_amx_language = get_cvar_pointer("amx_language");
}

public client_putinserver(id)
{
    new szLanguage[3];
    get_user_info(id, "lang", szLanguage, charsmax(szLanguage));
    if(strlen(szLanguage) != 3)
    {
        get_pcvar_string(g_pcvar_amx_language, szLanguage, charsmax(szLanguage));
    }

    new szName[32], szIP[16], szSteamSuffix[32];
    get_user_name(id, szName, charsmax(szName));
    get_user_ip(id, szIP, charsmax(szIP), /*strip port*/ 0);
    g_bSteamPlayer[id] = is_user_steam(id);
    if(g_bSteamPlayer[id]) szSteamSuffix = STEAM_PREFIX;

    new szCountry[64], szRegion[64], szCity[64];

    new bool:bCountryFound = sxgeo_country(szIP, szCountry, charsmax(szCountry), /*use lang server*/ szLanguage);
    new bool:bRegionFound  = sxgeo_region (szIP, szRegion,  charsmax(szRegion),  /*use lang server*/ szLanguage);
    new bool:bCityFound    = sxgeo_city   (szIP, szCity,    charsmax(szCity),    /*use lang server*/ szLanguage);

    if (bCountryFound && bCityFound && bRegionFound)
    {
        client_print_color(0, DontChange, "%s %L %L^3 %s ^4(%s, %s) %s", PREFIX, LANG_PLAYER, "CINFO_JOINED", szName, LANG_PLAYER, "CINFO_FROM", szCity, szRegion, szCountry, szSteamSuffix);
    }
    else if (bCountryFound && bRegionFound)
    {
        client_print_color(0, DontChange, "%s %L %L^3 %s ^4(%s) %s", PREFIX, LANG_PLAYER, "CINFO_JOINED", szName, LANG_PLAYER, "CINFO_FROM", szRegion, szCountry, szSteamSuffix);
    }
    else if (bCountryFound)
    {
        client_print_color(0, DontChange, "%s %L %L^4 %s %s", PREFIX, LANG_PLAYER, "CINFO_JOINED", szName, LANG_PLAYER, "CINFO_FROM", szCountry, szSteamSuffix);
    }
    else
    {
        // we don't know where you are :(
        client_print_color(0, DontChange, "%s %L %L %L %s", PREFIX, LANG_PLAYER, "CINFO_JOINED", szName, LANG_PLAYER, "CINFO_FROM", LANG_PLAYER, "CINFO_COUNTRY_UNKNOWN", szSteamSuffix);
    }

    if (bCountryFound || bCityFound || bRegionFound)
    {
        new code[3]; sxgeo_code(szIP, code, charsmax(code));
        // new code[3]; geoip_code2_ex(szIP, code);
        // server_print(code);
        new prefix[11]; formatex(prefix, charsmax(prefix), "^4[^1%s^4]^1 ", code);
        // client_print_color(id, print_team_blue, prefix);
        cm_set_prefix(id, prefix);
    }
    else
    {
        cm_set_prefix(id, "^4[^1??^4]^1 ");
    }

    client_cmd(0, "spk %s", CONNECT_SOUND);
}

stock is_user_steam(id)
{
    static dp_pointer;
    if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider"))) {
        server_cmd("dp_clientinfo %d", id); server_exec();
        return (get_pcvar_num(dp_pointer) == 2) ? true : false;
    }
    return false;
}