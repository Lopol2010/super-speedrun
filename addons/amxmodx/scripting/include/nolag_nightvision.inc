#if defined _nolag_nightvision_included
	#endinput
#endif
#define _nolag_nightvision_included

enum _:NVG_STATE {
    NVG_OFF = 0,
    NVG_NORMAL,
    NVG_FULLBRIGHT
}

native get_user_nvg_mode(id);
native set_user_nvg_mode(id, mode);