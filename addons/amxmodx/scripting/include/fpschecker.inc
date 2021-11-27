#if defined _fpschecker_included
	#endinput
#endif
#define _fpschecker_included


native Float:get_user_fps(id);
native record_user_fps(id, bool:enabled);
native Float:get_user_avg_fps(id);
native Float:get_user_max_avg_fps(id);
native Float:get_user_min_avg_fps(id);
