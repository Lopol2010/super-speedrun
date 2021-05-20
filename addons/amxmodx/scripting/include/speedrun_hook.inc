#if defined _speedrun_hook_included
	#endinput
#endif
#define _speedrun_hook_included

native is_hook_active(id);
native is_hook_allowed(id);
/* native give_hook(id); */
native user_hook_enable(id, isEnabled);
native bool:is_time_after_hook_passed(id, Float:time);
forward OnHookStart(id);