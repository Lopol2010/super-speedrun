#include <amxmodx>
#include <amxmisc>

public plugin_init()
{
	register_plugin("Nextmap Command", "1.0", "Lopol2010")
	register_clcmd("nm", "nm", ADMIN_CFG)
}

public nm(id, level)
{
	if(!access(id, level)) return PLUGIN_CONTINUE

	new map[33]
	get_cvar_string("amx_nextmap", map, 32)
	server_cmd("amx_map %s", map)
	
	return PLUGIN_CONTINUE
}
