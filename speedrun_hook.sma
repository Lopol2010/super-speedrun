#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>

#define KZ_LEVEL ADMIN_KICK 
#define PLUGIN	"Speedrun: Hook"
#define VERSION "0.1"
#define AUTHOR	"Lopol2010"

new bool:canusehook[33]
new bool:ishooked[33]
new hookorigin[33][3]
/* new Float:antihookcheat[33] */
new hook_sound
new hook_speed
new prefix[33] = "[^4Speedrun]"
new Sbeam = 0

public plugin_init()
{
	
    register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("+hook","hook_on",KZ_LEVEL)
	register_clcmd("-hook","hook_off",KZ_LEVEL)
	register_concmd("hook","give_hook", KZ_LEVEL, "<name|#userid|steamid|@ALL> <on/off>")

	hook_sound = register_cvar("hook_sound","0")
	hook_speed = register_cvar("hook_speed", "800.0")
}

public plugin_natives()
{
	register_native("is_hook_active","is_hook_active",1)
	register_native("is_hook_allowed","is_hook_allowed",1)
	/* register_native("give_hook","give_hook",1) */
	register_native("user_hook_enable","user_hook_enable",1)
}
public is_hook_active(id)
{
	return ishooked[id]
}
public is_hook_allowed(id)
{
	return canusehook[id]
}
public user_hook_enable(id, bool:isEnabled)
{
	canusehook[id] = isEnabled
	if(!isEnabled) remove_hook(id)
}
public plugin_precache()
{
	precache_sound("weapons/xbow_hit2.wav")
	Sbeam = precache_model("sprites/laserbeam.spr")
}

public give_hook(id)
{
	if (!(  get_user_flags( id ) & KZ_LEVEL ))
		return PLUGIN_HANDLED

	new szarg1[32], szarg2[8], bool:mode
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,32)
	if(equal(szarg2,"on"))
		mode = true
		
	if(equal(szarg1,"@ALL"))
	{
		new Alive[32], alivePlayers
		get_players(Alive, alivePlayers, "ach")
		for(new i;i<alivePlayers;i++)
		{
			canusehook[i] = mode
			if(mode)
				client_print_color(i, print_team_default,  "%s^x01, %L.", prefix, i, "KZ_HOOK")
				
		}
	}
	else
	{
		new pid = find_player("bl",szarg1);
		if(pid > 0)
		{
			canusehook[pid] = mode
			if(mode)
			{
				client_print_color(pid, print_team_default, "%s^x01 %L.", prefix, pid, "KZ_HOOK")
				
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public hook_on(id)
{
	if( !canusehook[id] /*&& !( get_user_flags( id ) & KZ_LEVEL )*/ || !is_user_alive(id) )
	{
		return PLUGIN_HANDLED
	}

	get_user_origin(id,hookorigin[id],3)
	ishooked[id] = true
	/* antihookcheat[id] = get_gametime() */
	
	if (get_pcvar_num(hook_sound) == 1)
	emit_sound(id,CHAN_STATIC,"weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)

	set_task(0.1,"hook_task",id,"",0,"ab")
	hook_task(id)
	
	return PLUGIN_HANDLED
}

public hook_off(id)
{
	remove_hook(id)
	
	return PLUGIN_HANDLED
}

public hook_task(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		remove_hook(id)
	
	remove_beam(id)
	draw_hook(id)
	
	new origin[3], Float:velocity[3]
	get_user_origin(id,origin)
	new distance = get_distance(hookorigin[id],origin)
	velocity[0] = (hookorigin[id][0] - origin[0]) * (2.0 * get_pcvar_num(hook_speed) / distance)
	velocity[1] = (hookorigin[id][1] - origin[1]) * (2.0 * get_pcvar_num(hook_speed) / distance)
	velocity[2] = (hookorigin[id][2] - origin[2]) * (2.0 * get_pcvar_num(hook_speed) / distance)
		
	set_pev(id,pev_velocity,velocity)
}

public draw_hook(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(hookorigin[id][0])		// origin
	write_coord(hookorigin[id][1])		// origin
	write_coord(hookorigin[id][2])		// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(random_num(1,100))		// life
	write_byte(random_num(1,20))		// width
	write_byte(random_num(1,0))		// noise					
	write_byte(random_num(1,255))		// r
	write_byte(random_num(1,255))		// g
	write_byte(random_num(1,255))		// b
	write_byte(random_num(1,500))		// brightness
	write_byte(random_num(1,200))		// speed
	message_end()
}

public remove_hook(id)
{
	if(task_exists(id))
		remove_task(id)
	remove_beam(id)
	ishooked[id] = false
}

public remove_beam(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(id)
	message_end()
}

