#if defined _fpschecker_included
	#endinput
#endif
#define _fpschecker_included


native Float:get_user_fps(id);
native record_user_fps(id, bool:enabled);
native Float:get_recorded_user_fps(id);
