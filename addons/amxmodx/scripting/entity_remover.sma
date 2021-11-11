#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
//#include <chat>

enum entity_data
{
	entity_index,
	entity_solid
};

#define TASK_ID_CHECK	10000

new Array:g_class, Array:g_model, Array:g_undo[33];
new g_ent_class[33][32], g_ent[33], g_ent_model[33][32];
new g_total_undo[33], g_save_file[200];
new g_msgid_SayText, g_max_players, g_total;
new bool:g_connected[33];

public plugin_precache()
{
	g_class = ArrayCreate(32, 1);
	g_model = ArrayCreate(32, 1);
	get_datadir(g_save_file, 199);
	add(g_save_file, 199, "/removed_entities", 0);
	
	if( !dir_exists(g_save_file) )
	{
		mkdir(g_save_file);
	}
	
	new map[64];
	get_mapname(map, 63);
	strtolower(map);
	format(g_save_file, 199, "%s/%s.txt", g_save_file, map);
	LoadEntities();
	register_forward(FM_Spawn, "FwdSpawn", 0);
	
	return PLUGIN_CONTINUE;
}

public plugin_init()
{
	register_plugin("Entity Remover", "1.0", "Lovsky");
	
	
	register_dictionary("common.txt");
	register_dictionary("entity_remover.txt");
	
	register_clcmd("er_remove", "CmdRemove", ADMIN_CVAR, "-- removes the entity you are currently looking at");
	register_clcmd("er_undo", "CmdUndo", ADMIN_CVAR, "-- brings back last entity you deleted");
	register_concmd("er_reset", "CmdReset", ADMIN_CVAR, "-- resets all deleted entities");
	
	register_clcmd("ermenu", "er_menu"); // команда вызова меню
	register_menu(	"er_menu", (1<<0|1<<1|1<<2|1<<9), "Handle_ermenu"); //регестрация менюшки
	
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_logevent("EventNewRound", 2, "1=Round_Start");
	register_logevent("EventNewRound", 2, "1=Round_End");
	
	g_msgid_SayText = get_user_msgid("SayText");
	g_max_players = global_get(glb_maxClients);
	
	for( new plr = 1; plr <= g_max_players; plr++ )
	{
		g_undo[plr] = ArrayCreate(2, 1);
	}
	
	return PLUGIN_CONTINUE;
}

public er_menu(plr)
{
	new szMenu[1024], iLen;
	iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\yМеню удаления объектов^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y1\r]\w Удалить объект^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y2\r]\w Вернуть объект^n\dОбъекты возвращаются по очереди^nот последнего который был удалён^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y3\r]\w Сбросить все удалённые объекты^n\d(Удаления будут сброшены)^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y0\r]\w Выход^n^n");
	show_menu(plr, (1<<0|1<<1|1<<2|1<<9), szMenu, -1, "er_menu");	
}

public Handle_ermenu(plr, iKey)
{
	switch(iKey)
	{
		
		case 0: 
		{
		client_cmd(plr, "er_remove");
//		er_menu(plr);
		}
		case 1: 
		{
		client_cmd(plr, "er_undo");
		er_menu(plr);
		}
		case 2:
		{		
		client_cmd(plr, "er_reset");
		er_menu(plr);
		}
	}
}

public FwdSpawn(ent)
{
	if( pev_valid(ent) )
	{
		set_task(0.1, "TaskDelayedCheck", ent + TASK_ID_CHECK, "", 0, "", 0);
		
		return FMRES_HANDLED;
	}
	
	return FMRES_IGNORED;
}

public TaskDelayedCheck(ent)
{
	ent -= TASK_ID_CHECK;
	
	if( !pev_valid(ent) )
	{
		return PLUGIN_CONTINUE;
	}
	
	new class[32], sModel[32];
	pev(ent, pev_classname, class, 32);
	pev(ent, pev_model, sModel, 32);
	
	new saved_class[32], saved_model[32];
	for( new i; i < g_total; i++ )
	{
		ArrayGetString(g_class, i, saved_class, 32);
		ArrayGetString(g_model, i, saved_model, 32);
		
		if( equal(class, saved_class, 0) && equal(sModel, saved_model, 0) )
		{
			RemoveEntity(ent);
			break;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_connect(plr)
{
	g_ent[plr] = 0;
	g_ent_class[plr][0] = '^0';
	g_ent_model[plr][0] = '^0';
	
	ArrayClear(g_undo[plr]);
	g_total_undo[plr] = 0;
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(plr)
{
	g_connected[plr] = true;
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(plr)
{
	g_connected[plr] = false;
	
	return PLUGIN_CONTINUE;
}

public CmdRemove(plr, level, cid)
{
	if(!cmd_access(plr, level, cid, 1)) return PLUGIN_HANDLED;
	
	g_ent[plr] = GetAimAtEnt(plr);
	
	if(pev_valid(g_ent[plr]))
	{
		pev(g_ent[plr], pev_classname, g_ent_class[plr], 63);
			
		if(equali(g_ent_class[plr], "player", 0))
		{
			Print(plr, "%L", plr, "CANNOT_DELETE_PLAYER");
			er_menu(plr);
			return PLUGIN_HANDLED;
		}
		
		pev(g_ent[plr], pev_model, g_ent_model[plr], 63);
		
		new title[96];
		formatex(title, 95, "%L", plr, "MENU_REMOVE_ENTITY");
		format(title, 95, "%s:\w %s", title, g_ent_class[plr]);
		new menu = menu_create(title, "MenuDelete", 0);
		new yes[64], yes_info[32], no[16];
		formatex(yes, 63, "%L", plr, "YES");
		formatex(yes_info, 31, "%L", plr, "MENU_YES_INFO");
		format(yes, 63, "%s \y(%s)", yes, yes_info);
		formatex(no, 15, "%L", plr, "NO");		
		menu_additem(menu, yes, "1", 0, -1);
		menu_additem(menu, no, "2", 0, -1);		
		menu_setprop(menu, MPROP_PERPAGE, 0);
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);		
		menu_display(plr, menu, 0);
	}
	else
	{
		Print(plr, "%L", plr, "AIM_AT_ENTITY");
		er_menu(plr);
	}
	
	return PLUGIN_HANDLED;
}

public MenuDelete(plr, menu, item)
{
	new _access, info[2], callback;
	menu_item_getinfo(menu, item, _access, info, 1, "", 0, callback);
	
	if( info[0] == '1' )
	{
		new solid = pev(g_ent[plr], pev_solid);		
		RemoveEntity(g_ent[plr]);		
		ArrayPushString(g_class, g_ent_class[plr]);
		ArrayPushString(g_model, g_ent_model[plr]);
		g_total++;		
		SaveEntities();
		new info[entity_data];
		info[entity_index] = g_ent[plr];
		info[entity_solid] = solid;		
		ArrayPushArray(g_undo[plr], info);
		g_total_undo[plr]++;		
//		Print(plr, "%L", plr, "ENTITY_REMOVED");
		client_print_color(plr, print_team_default, "%L", plr, "ENTITY_REMOVED");
		er_menu(plr);
	}
	
	g_ent[plr] = 0;
	g_ent_class[plr][0] = '^0';
	g_ent_model[plr][0] = '^0';	
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public CmdUndo(plr, level, cid)
{
	if(!cmd_access(plr, level, cid, 1)) return PLUGIN_HANDLED;
	if(!g_total_undo[plr])
	{
		console_print(plr, "%L", plr, "NO_UNDO_ENTITIES");
//		Print(plr, "Нет удалённых объектов");
		client_print_color(plr, print_team_default, "%L", plr, "NO_UNDO_ENTITIES");
		return PLUGIN_HANDLED;
	}
	
	new info[entity_data];
	ArrayGetArray(g_undo[plr], -- g_total_undo[plr], info);
	new ent = info[entity_index];
	ArrayDeleteItem(g_undo[plr], g_total_undo[plr]);
	
	if(!pev_valid(ent))
	{
		console_print(plr, "%L", plr, "UNDO_INVALID_ENTITY");
		return PLUGIN_HANDLED;
	}
	
	set_pev(ent, pev_rendermode, kRenderNormal);
	set_pev(ent, pev_renderamt, 16);
	set_pev(ent, pev_solid, info[entity_solid]);
	new class[32];
	pev(ent, pev_classname, class, 31);
	console_print(plr, "%L", plr, "UNDO_SUCCESS", class);
	client_print_color(plr, print_team_default, "^4[Entity Remover] ^1Вы отменили удаление ^3' %s '", class);
	
	new model[32];
	pev(ent, pev_model, model, 31);
	
	new saved_class[32], saved_model[32];
	for( new i = 0; i < g_total; i++ )
	{
		ArrayGetString(g_class, i, saved_class, 31);
		
		if( !equal(class, saved_class, 0) )
		{
			continue;
		}
		
		ArrayGetString(g_model, i, saved_model, 31);
		
		if( equal(model, saved_model, 0) )
		{
			ArrayDeleteItem(g_class, i);
			ArrayDeleteItem(g_model, i);
			g_total--;
			
			SaveEntities();
			
			break;
		}
	}
	
	return PLUGIN_HANDLED;
}

public CmdReset(plr, level, cid)
{
	if( !cmd_access(plr, level, cid, 1) )
	{
		return PLUGIN_HANDLED;
	}
	
	ArrayClear(g_class);
	ArrayClear(g_model);
	g_total = 0;
	
	delete_file(g_save_file);
	
	for( new i = 1; i <= g_max_players; i++ )
	{
		if( g_connected[i] )
		{
			ArrayClear(g_undo[i]);
			g_total_undo[i] = 0;
		}
	}
	
//	console_print(plr, "%L", plr, "RESET_1");
//	console_print(plr, "%L", plr, "RESET_2");
	client_print_color(plr, print_team_default, "^4* ^1Удаления сброшены. Перезагрузите карту и изменения вступят в силу.");
	
	return PLUGIN_HANDLED;
}

public EventNewRound()
{
	if( !g_total )
	{
		return PLUGIN_CONTINUE;
	}
	
	new ent, class[32], saved_model[32], ent_model[32];
	for( new i = 0; i < g_total; i++ )
	{
		ArrayGetString(g_class, i, class, 31);
		ArrayGetString(g_model, i, saved_model, 31);
		
		ent = g_max_players;
		while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", class)) )
		{
			pev(ent, pev_model, ent_model, 31);
			
			if( equal(saved_model, ent_model, 0) )
			{
				RemoveEntity(ent);
				break;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

LoadEntities()
{
	if( file_exists(g_save_file) )
	{
		new f = fopen(g_save_file, "rt");
		
		new data[70], class[32], model[32];
		
		while( !feof(f) )
		{
			fgets(f, data, 69);
			
			parse(data, class, 32, model, 32);
			
			ArrayPushString(g_class, class);
			ArrayPushString(g_model, model);
			g_total++;
		}
		
		fclose(f);
		
		return 1;
	}
	
	return 0;
}

SaveEntities()
{
	delete_file(g_save_file);
	
	new f = fopen(g_save_file, "wt");
	
	new data[70], class[32], model[32];
	
	for( new i = 0; i < g_total; i++ )
	{
		ArrayGetString(g_class, i, class, 31);
		ArrayGetString(g_model, i, model, 31);
		
		formatex(data, 69, "^"%s^" ^"%s^"^n", class, model);
		
		fputs(f, data);
	}
	
	fclose(f);
	
	return 1;
}

RemoveEntity(ent)
{
	set_pev(ent, pev_rendermode, kRenderTransAlpha);
	set_pev(ent, pev_renderamt, 0);
	
	set_pev(ent, pev_solid, SOLID_NOT);
	
	return 1;
}

GetAimAtEnt(plr)
{
	static Float:start[3], Float:view_ofs[3], Float:dest[3], i;
	
	pev(plr, pev_origin, start);
	pev(plr, pev_view_ofs, view_ofs);
	
	for( i = 0; i < 3; i++ )
	{
		start[i] += view_ofs[i];
	}
	
	pev(plr, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	
	for( i = 0; i < 3; i++ )
	{
		dest[i] *= 9999.0;
		dest[i] += start[i];
	}

	engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, plr, 0);
	
	return get_tr2(0, TR_pHit);
}

Print(plr, const fmt[], any:...)
{ 
	new i = plr ? plr : GetPlayer();
	if( !i )
	{
		return 0;
	}
	
	new message[192];
	message[0] = 0x04;
	vformat(message[1], 191, fmt, 3);
	
	message_begin(plr ? MSG_ONE : MSG_ALL, g_msgid_SayText, {0, 0, 0}, plr);
	write_byte(i);
	write_string(message);
	message_end();
	
	return 1;
}

GetPlayer()
{
	for( new plr = 1; plr <= g_max_players; plr++ )
	{
		if( g_connected[plr] )
		{
			return plr;
		}
	}
	
	return 0;
}
