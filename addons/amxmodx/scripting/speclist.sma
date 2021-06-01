#include <amxmodx>
#include <fakemeta>

#if !defined MAX_PLAYERS
	#define MAX_PLAYERS 32
#endif

#define IMMUNITY_FLAG ADMIN_BAN	// Флаг с которым игрока не будет выводить в speclist, закомментируйте если хотите чтобы выводило всех.
#define UPDATE 0.5				// Частота обновлений списка

/*** Настройка цвета в RGB ***/
#define RED 34		// Количество красного
#define GREEN 34	// Количество зеленого
#define BLUE 34		// Количество синего
/*** Конец настройки цвета ***/

#pragma semicolon 1
new szDhud[MAX_PLAYERS][512];
new gCvarPluginEnabled;
new gCvarImmunity;
new bool:gOnOff[33] = { true, ... };

public plugin_init() {
	register_plugin("SpecList", "1.0", "Lopol2010");	// Remake Spectators List by FatalisDK
	register_dictionary("speclist.txt");

	gCvarPluginEnabled = create_cvar("amx_speclist", "1", FCVAR_NONE, "Enable or disable spectators list on the server.");
	gCvarImmunity = create_cvar("amx_speclist_immunity", "0", FCVAR_NONE, "Allow immune players to be hidden from speclist.");
	register_clcmd("say /speclist", "cmdSpecList", 0, "Toggle speclist when you alive. Still enabled when you spec someone.");

	set_task(UPDATE, "ShowSpecList", .flags="b");
}

public plugin_natives()
{
    register_native("speclist_toggle", "speclist_toggle");
    register_native("is_speclist_enabled", "is_speclist_enabled");
}
public is_speclist_enabled(plugin, argc)
{
    enum {
        arg_id = 1
    }
    new id = get_param(arg_id);
    return gOnOff[id];
}
public speclist_toggle(plugin, argc)
{
    enum {
        arg_id = 1
    }
    new id = get_param(arg_id);
    cmdSpecList(id);
}
public cmdSpecList(id)
{
	gOnOff[id] = !gOnOff[id];
	if( !gOnOff[id] )
		client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "DISABLED");
	else
		client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "ENABLED");
	return PLUGIN_CONTINUE;
}
public ShowSpecList() {

	if(!get_pcvar_num(gCvarPluginEnabled)) return;

	new szName[16], iLen[MAX_PLAYERS];
	new iDead[MAX_PLAYERS], dCount;
	get_players(iDead, dCount, "bch");


	for(new i, id, spec; i < dCount; i++) {
		id = iDead[i];
		spec = pev(id, pev_iuser2);

		if(spec == id || !is_user_alive(spec)) continue;
		if( get_pcvar_num(gCvarImmunity) && get_user_flags(id) & IMMUNITY_FLAG ) continue;

		get_user_name(id, szName, charsmax(szName));
		iLen[spec] += formatex(szDhud[spec][iLen[spec]], charsmax(szDhud[]) - iLen[spec], "%s^n", szName);

		szDhud[id] = szDhud[spec];
	}

	new iAlive[MAX_PLAYERS], aCount;
	get_players(iAlive, aCount, "ch"); //ach
	for(new i, id; i < aCount; i++) {
		id = iAlive[i];

		if(!gOnOff[id] && is_user_alive(id)) continue;
		if(!szDhud[id][0]) continue;

		set_hudmessage(RED, GREEN, BLUE, 0.75, 0.15, 0, _, UPDATE, UPDATE, UPDATE, .channel = 2);
		show_hudmessage(id, "%L:^n%s", LANG_PLAYER, "SPECT", szDhud[id]);

		arrayset(szDhud[id], 0, sizeof(szDhud[]));
	}
}