#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "0.02"

#define IsOnLadder(%1) (pev(%1, pev_movetype) == MOVETYPE_FLY)  

new const FL_ONGROUND2 = ( FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER |  FL_CONVEYOR | FL_FLOAT )
new checknumbers[33]
new gochecknumbers[33]
new Float:Checkpoints[33][2][3]
new pCvar_checkpoints
new bool:g_bCpAlternate[33]

public plugin_init()
{
	pCvar_checkpoints = register_cvar("checkpoints","1")

	register_plugin("Checkpoints API", VERSION, "Lopol2010")
	register_clcmd("cp","CheckPoint",0)
	register_clcmd("gc", "GoCheck",0)
	register_clcmd("say /cp","CheckPoint")
	register_clcmd("say /gc", "GoCheck")

	register_dictionary("prokreedz.txt")

}

public plugin_natives()
{
	register_native("checkpoint", "CheckPoint", 1);
	register_native("gocheck", "GoCheck", 1);
	register_native("get_checkpoints_count", "get_checkpoints_count", 1);
	register_native("get_gochecks_count", "get_gochecks_count", 1);
	register_native("reset_checkpoints", "reset_checkpoints", 1);
}

public get_checkpoints_count(id)
{
	return checknumbers[id];
}

public get_gochecks_count(id)
{
	return gochecknumbers[id];
}

public reset_checkpoints(id)
{
	arrayset(checknumbers, 0, sizeof(checknumbers));
	arrayset(gochecknumbers, 0, sizeof(gochecknumbers));
}

public CheckPoint(id)
{
	
	if( !is_user_alive( id ) )
	{
		client_print(id, print_chat, "%L", id, "CP_NOT_ALIVE")
		return PLUGIN_HANDLED
	}
	
	if(get_pcvar_num(pCvar_checkpoints) == 0)
	{
		client_print(id,  print_chat,"%L",  id, "CP_CHECKPOINT_OFF")
		return PLUGIN_HANDLED
	}

	if( !( pev( id, pev_flags ) & FL_ONGROUND2 ) && !IsOnLadder(id))
	{
		client_print(id,  print_chat,"%L", id, "CP_CHECKPOINT_AIR")
		return PLUGIN_HANDLED
	}
		
	// if( IsPaused[id] )
	// {
	// 	client_print(id, "%L", id, "CP_CHECKPOINT_PAUSE")
	// 	return PLUGIN_HANDLED
	// }
		
	pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id] ? 1 : 0])
	g_bCpAlternate[id] = !g_bCpAlternate[id]
	checknumbers[id]++


	client_print(id, print_chat, "%L", id, "CP_CHECKPOINT", checknumbers[id])

	return PLUGIN_HANDLED
}

public GoCheck(id) 
{
	if( !is_user_alive( id ) )
	{
		client_print(id, print_chat, "%L",  id, "CP_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if( checknumbers[id] == 0  ) 
	{
		client_print(id,  print_chat,"%L",  id, "CP_NOT_ENOUGH_CHECKPOINTS")
		return PLUGIN_HANDLED
	}

	// if( IsPaused[id] )
	// {
	// 	client_print(id,  print_chat,"%L", "CP_TELEPORT_PAUSE")	
	// 	return PLUGIN_HANDLED
	// }
	
	set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} );
	set_pev( id, pev_view_ofs, Float:{  0.0,   0.0,  12.0 } );
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING );
	set_pev( id, pev_fuser2, 0.0 );
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 } );
	set_pev(id, pev_origin, Checkpoints[ id ][ !g_bCpAlternate[id] ] )
	gochecknumbers[id]++

	return PLUGIN_HANDLED
}
