#include <amxmodx>
#include <reapi>

#define AUTHOR "Lopol2010"
#define PLUGIN "Changelog"
#define VERSION "1.0"

// #define INFO_DELAY 1.0 //delay before print info when player joined server

public plugin_init()
{
	register_plugin ( PLUGIN, VERSION, AUTHOR )
    register_clcmd("news", "Command_Info");
    register_clcmd("say /news", "Command_Info");
    register_clcmd("say /info", "Command_Info");
}

public Command_Info(id, level, cid)
{
	static szURL[256];
	szURL = "http://193.19.118.100:61441/info";

    new iLen = 0, iMax = charsmax(g_szMotd);

    iLen += formatex(g_szMotd[iLen], iMax-iLen, "<meta http-equiv = ^"refresh^" content = ^"0; url = %s^" />", szURL);
    iLen += formatex(g_szMotd[iLen], iMax-iLen, "<style>body { background-color: #0c0e0e; } body:after { content: ^"Loading...^"; font-size: 54px; color: grey; }</style>");

    show_motd(id, g_szMotd, "Info");
}

// public client_putinserver(id)
// {
//     new arg[1]; arg[0] = id;
//     set_task(INFO_DELAY, "print_info_task", _, arg, sizeof arg);
// }