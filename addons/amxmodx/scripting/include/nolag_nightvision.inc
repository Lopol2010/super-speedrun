#if defined _speedrun_included
	#endinput
#endif
#define _speedrun_included

enum _:NVG_STATE {
    NVG_OFF,
    NVG_NORMAL,
    NVG_FULLBRIGHT
}

native get_user_nvg_mode(id);