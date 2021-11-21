#if defined _speedrun_included
	#endinput
#endif
#define _speedrun_included

#include <speedrun_const>

native get_user_category(id);
native set_user_category(id, category);
native rotate_user_category(id);
native sr_command_spec(id);
native sr_command_start(id);
native sr_give_default_items(id);
native sr_regive_weapon(id);

forward SR_PlayerOnStart(id);
forward SR_ChangedCategory(id, cat);
forward SR_StartButtonPress(id);

native main_menu_display(id);

native sr_update_nickname(id);
native sr_show_toplist(id);
native sr_get_timer_display_text(id, text[] = "", len = 0);
native sr_toggle_beep(id);
native sr_is_beep_enabled(id);

native is_hook_active(id);
native is_hook_allowed(id);
/* native give_hook(id); */
native user_hook_enable(id, isEnabled);
native bool:is_time_after_hook_passed(id, Float:time);
forward OnHookStart(id);

native show_langmenu(id);
native get_player_lang(id, lang[], len);