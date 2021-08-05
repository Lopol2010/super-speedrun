#if defined _speedrun_included
	#endinput
#endif
#define _speedrun_included

stock const PREFIX[] = "^4[^1Super Speedrun^4]^1";

native get_user_category(id);
native set_user_category(id);
native rotate_user_category(id);
native sr_command_spec(id);
native sr_command_start(id);
native sr_give_default_items(id);
native sr_regive_weapon(id);

forward SR_PlayerOnStart(id);
forward SR_ChangedCategory(id, cat);
forward SR_StartButtonPress(id);

native main_menu_display(id);

native sr_show_toplist(id);
native sr_get_timer_display_text(id, text[] = "", len = 0);

native is_hook_active(id);
native is_hook_allowed(id);
/* native give_hook(id); */
native user_hook_enable(id, isEnabled);
native bool:is_time_after_hook_passed(id, Float:time);
forward OnHookStart(id);

native show_langmenu(id);