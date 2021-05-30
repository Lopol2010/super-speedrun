#if defined _box_sysem_included
  #endinput
#endif
#define _box_sysem_included

/**
 * Called when ent enter into box
 */
forward box_start_touch(box, ent, const szClass[]);

/**
 * Called when ent leave
 */
forward box_stop_touch(box, ent, const szClass[]);

/**
 * Called each frame when ent touches box
 */
forward box_touch(box, ent, const szClass[]);



/**
 * Called after box initialization
 */
forward box_created(ent, const szClass[]);

/**
 * Called before box uninitialization
 */
forward box_deleted(ent, const szClass[]);


#define FAKEMETA_PEV_TYPE 	pev_netname
#define FAKEMETA_PEV_ID 	pev_message

#define ENGINE_ENT_TYPE 	EV_SZ_netname,
#define ENGINE_ENT_ID 		EV_SZ_message,

/**
 * Fetch box UNIQUE id
 */
stock BOX_GetId(ent, szClass[], len){
	#if defined _fakemeta_included
		return pev(ent, FAKEMETA_PEV_ID, szClass, len);
	#else
		#if defined _engine_included
			entity_get_string(ent, ENGINE_ENT_ID, szClass, len);
		#else
			#assert "You need fakemeta or engine module included before this box_system"
		#endif
	#endif
}