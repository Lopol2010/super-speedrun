#include <amxmodx>

public plugin_init()
{
	register_plugin("1", "1", "1")
	register_clcmd("nm", "nm")
}

public nm(id)
{
	new map[33]
	get_cvar_string("amx_nextmap", map, 32)
	server_cmd("changelevel %s", map)
	
}
