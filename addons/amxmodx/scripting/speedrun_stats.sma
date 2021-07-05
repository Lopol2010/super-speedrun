/* 
    идея для паблика: фан сервер с багами которые сделанны специально, использывание hitbox_tracker, баг граната взрывается несколько раз
    TODO: 
        * сделать найтвижену пояснение в чат о двух режимах
        * 
        * опять не работает ci-ninja (или работает? когда залогинился вроде работает...)
        * multilang for remaining client_prints
        * add chat message on Low Gravity category selected
        fix low gravity (when you enter category, no gravity applied)
        nominate not work
        проверить список плагинов amxmodx в утилите hlds_loader похоже много полезного
        ночное видиние так же видят спектры
        ограничение скорости убрать? наверно только для спидран карт, щас нашел карту не проходимую на 2к скорости
        slowmo, noWASD
        * расставить зона на спидран картах
                остановился размечать зоны на карте после speedrun_enborian (где то на 10 дальше ушел)
        * allow map change when 2 players afk and third player says rtv
        * ?? delete finish stuff from database
        * add kzbr_hii_fastrun, bhop_bloody, bkz_abstract, akzk_desertcliff, chk_neutral2, clintmo_bhopwarehouse (& maybe other maps https://all-cs.ru/cs16/maps/jumping/bhop)
                тут на kz-rush, cosy-climbing, 17buddies можно вроде нарыть много картhttps://www.google.ru/search?hl=ru&q=hb_dilo
                https://gamebanana.com/mods/cats/5524
        * сделать хук спид для разных игроков свой(и обдумать как это лучше сделать )
        * add plugin to freeze entites, for example dooors
        * add plugin to remove entities (entity remover, or use ripent)
        * add categories, or maybe a 'modifiers' such as "low gravity", "double jumps"
        * ?? allow use /save menu for maps with buttons
        * world record bot (do a research on that, https://dev-cs.ru/resources/142/)
        * (fixed?) fix message on finish showing wrong time
        * set language automaticaly with sxGeo and:
            or ask Kushfield how to implement that. 
            Or see myself how it works on his server
                                    https://dev-cs.ru/resources/469/
                                    https://dev-cs.ru/resources/570/field?field=source
                                    (remove AutoLang - seems not work)
        * check my notebook
        * allow to interupt run with hook (menu open up 1. stop timer & use hoo 2. continue run)

        // 3. (? optional ?) Auto change invalid FPS (no fps categories in the beginning, so this point is not valid for now)
    DONE:
        * add 100fps category
        * префикс в чате для игроков как на найте (пример [RU])
        * настроить sxGeo_informer как на найт джампе
        * chat prefix unifiend for most plugins
        * добавить к спидометру показ кнопок
        * донастроить reklama (квары в configs/plugins/reklama), почему то он еще bad load  не загружается.
        * (fixed? if so... its was fucking hard) git pull fix https://stackoverflow.com/questions/55237191/git-pull-not-executing-through-a-webhook-in-bash-script
            problem: script on production server not pulling from repo after pushing from developer PC. (based on github's commit webhooks )
        * уменьшить шанс попадания ср карты в голосования за смену карты
        * убрать beep на финиш и на финиш-топ1
        * проверить почему super-speedrun-master.sh не запускает нормально ./compile.sh (вроде бы незапускает)
        * баг когда скрываешь оружие не стартануть таймер (с кнопки точно, карта bhop_bunnyjump)
        * сделать stand-up прыжки возможными (щас походу нет эффекта от них)
            (не сделал, даже толком не поискал норм спидран где это реализовано, на найте например нету) 
        * 2k mode  в core ограничить 2000, сейчас тупо умножается на 2000, протестить на sr_enemy
        * (not important for now) 5.3.1 how to check for player leaving start zone? possible solutions: 
                    4. use simple algorythm that will detect whether a point (player origin) is inside of a box.
                    3. use th //is or even copy code from rehlds source (as stated in comments in the provided link) https://forums.alliedmods.net/showthread.php?t=307944
        сгенерить .res файлы
        * (само исправилось? вроде после освобождения места на диске стало 3сек.) стала слишком долгая интермиссия
                взять тестовый сервак помощнее, проверить как он справиться со сменой карты https://www.ipserver.su/ru/page/tos
                через htop видно загрузка проца на 100% возможно он не вывозит?
                (без файла maps.ini стало 3-4 сек)
                отключить все плагины и проверить (6 sec стало, 5 сек без pluigns.ini но с map-manager, наоборот тоже 5сек)
                если это не помогло, отключать модули
                возможные причины: 1. отключить все плагины и проверить 2. нехватает места на диске (сейчас 93% занято было, команда df для проверки на ubuntu)
        * если сделать сначало финиш а потом старт, то таймер запускается только после рестарта. Причем запускается с багом, в самой старт зоне и после выхода из неё.
                решение: сначало ставить старт (или переписать box_system чтобы нельзя было ставить несколько зон финиш\старт что тоже не очень круто если будет нужно несколько зон)
        *(нужные вады не нашлись) проверить скачанный пак спидран карт
            "C:\Users\der19\Downloads\FILES FROM RUS_SR.zip"
        * (removed map) L 31/05/2021 - 15:01:57: (map "speedrun_action") CalcSurfaceExtents: Bad surface extents
        * (removed map) L 31/05/2021 - 14:51:56: (map "speedrun_omg") TEX_InitFromWad: couldn't open srhelvis.wad
        * L 26/05/2021 - 12:57:33: (map "speedrun_woah") Mod_LoadModel: models/player/gign/gign.mdl has been modified since starting the engine.  Consider running system diagnostics to check for faulty hardware.
            Info (map "speedrun_4ever") (file "addons/amxmodx/logs/error_20210531.log")
            L 05/31/2021 - 14:25:23: [AMXX] Run time error 4 (plugin "speedrun_core.amxx") - debug not enabled!
            L 05/31/2021 - 14:25:23: [AMXX] To enable debug mode, add "debug" after the plugin name in plugins.ini (without quotes).
        * (removed)speedrun_4lunch разобратся (крашит клиент с ошбикой allocblock full)
        * (removed) speedrun_aztec_hd2020, speedrun_badbl3 (miss creditsbadbl.wad)
        * (not checked this) speedrun_aqua demonpesik вылетил
        * (removed)speedrun_around сломано освещение
        * (removed map) speedrun_CrazySpeed! (miss aaacredits.wad)
        * пункт меню 6 оставить 6ым когда в спектрах
        * fix timer shows for everyone (core line 649)
        * speclist & fpscchecker мерцают
        * поставить низкий приоритет картам speedrun для map manager
        * box_system баг при создании финишной зоны после стартовой
        * box_system сделать удаление зон, или проверить удаляются ли они в оригинальном плагине (сейчас не удаляются)
        * add server to monitorings
        * исправить смену карты (сделать задержку 15 сек, а затем сразу менять. сейчас сразу интермиссия но 5 сек.)
                поллучить ответ https://dev-cs.ru/threads/2457/page-44
                ОТВЕТ: переписал сам scheduler, юзать mapm_intermission_delay и mp_chattime
        * добавить nightvision
        * player can't join at speedrun_rqnjar (see if its not enough spawns, maybe should enable kz_auto_add_spawns...)
        * fix weapon hidding (not work properly)
        * add map ds_ice (also big speedrun pack)
        * comment out multilang.amxx
        * fix bug with language not set correctly! (probably need replace LANG_PLAYER to ids)
        * fix invis menu after reconnect still hides things
        *fix can't start in the start of map (hook block)
        * change time for map vote and time after map vote to 15 and 15
        // 5. start/stop zones are visible
        // 4. checkpoints.sma beautify chat messages on checkpoin/gocheck
        * add antispam (done by chatmanager_addon)
        * copy main menu from nightjump
        * fixed bug with checkpoints
        * change "set a map record"
        * change timer appearence
        * ??? really need this ??? add voteban/kick for players
        * set default lang [ru] (in amxx.cfg)
        * then maybe add possibility to change size of finish zone, so that you can move corners like <box_system> do, but zone itself always sticks to the ground under it.
                So you move corners as if its 2D plane. 
        * and then launch new plugins!
        * migrate toplist
        * Bugs & suggestions system. 
                    Get module that can work with telegram and create command for players 
                    like 'say @text' so that 'text' will be sended to admin's telegram. 
        * use box system's forwards to make start zone visible!
        2. spectators menu
        1. fix hook in speedrun maps
        5. first rewrite finish drawing, now its temp-entity, need use <beams> stocks. Those can change color faster and seem to be much more reliable!
                    addtofullpack static version: https://github.com/ddenzer/addtofullpack_manager
        1. When map starts decide if timer should be managed by buttons on the map or by speedrun zones
        2. Auto bind for menus (game, category)
*/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <reapi>
#include <geoip>
#include <sqlx>
#include <box_system>
#include <checkpoints>
#include <speedrun>
#include <hidemenu>
#include <beams>
#pragma loadlib sqlite

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Speedrun: Stats"
#define VERSION "1.0"
#define AUTHOR "Mistrick & Lopol2010"

#pragma semicolon 1

#define HOOK_ANTICHEAT_TIME 3.0
#define FINISH_SPRITENAME "sprites/white.spr"

enum _:PlayerData
{
    m_bConnected,
    m_bAuthorized,
    m_bTimerStarted,
    m_bFinished,
    m_iPlayerIndex,
    Float:m_fStartRun,
    m_bWasUseHook       // true if player used hook and until next respawn (by command or death)
};
enum _:Categories
{
    Cat_100fps,
    Cat_200fps,
    Cat_250fps,
    Cat_333fps,
    Cat_500fps,
    Cat_FastRun,
    Cat_Default,
    Cat_CrazySpeed,
    Cat_2k,
    Cat_LowGravity,
};
enum _:Cvars
{
    SQL_HOST,
    SQL_USER,
    SQL_PASSWORD,
    SQL_DATABASE
};
enum _:ResultsColumns
{
    Results_id,
    Results_mid,
    Results_category,
    Results_checkpoints,
    Results_gochecks,
    Results_besttime,
    Results_recorddate,
};

new const g_szCategory[][] = 
{
    "100 FPS", "200 FPS", "250 FPS", "333 FPS", "500 FPS", "Fastrun", "Bhop", "Crazy Speed", "2K", "Low Gravity"
};

new g_pCvars[Cvars];
new Handle:g_hTuple, g_szQuery[512];
new g_szMapName[32];
new g_iMapIndex;
new g_ePlayerInfo[33][PlayerData];
new g_iBestTime[33][Categories];
new g_iFinishEnt;
new g_szMotd[1536];
new g_iBestTimeofMap[Categories];
stock g_fwFinished;
stock g_iReturn;

new bool:g_bStartButton;
new Trie:g_tStarts;
new Trie:g_tStops;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    g_pCvars[SQL_HOST] = register_cvar("speedrun_host", "127.0.0.1");
    g_pCvars[SQL_USER] = register_cvar("speedrun_user", "root");
    g_pCvars[SQL_PASSWORD] = register_cvar("speedrun_password", "root");
    g_pCvars[SQL_DATABASE] = register_cvar("speedrun_database", "speedrun_stats.db");
    
    register_clcmd("cleartop", "Command_ClearTop", ADMIN_CFG);
    // register_clcmd("setfinish", "Command_SetFinish", ADMIN_CFG);
    register_clcmd("say /rank", "Command_Rank");
    register_clcmd("say /top15", "Command_Top15");
    register_clcmd("say /update", "Command_Update");
    
    RegisterHookChain(RG_CBasePlayer_Jump, "HC_CheckStartTimer", false);
    RegisterHookChain(RG_CBasePlayer_Duck, "HC_CheckStartTimer", false);
    RegisterHookChain(RG_CBasePlayer_Spawn, "HC_CBasePlayer_Spawn_Post", true);

    RegisterHam( Ham_Use, "func_button", "fwdUse", 0);
    
    g_fwFinished = CreateMultiForward("SR_PlayerFinishedMap", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
    
    // Timer managed by buttons on the map
    g_tStarts = TrieCreate( );
    g_tStops  = TrieCreate( );

    new const szStarts[ ][ ] =
    {
        "counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
        "multi_start", "timer_startbutton", "start_timer_emi", "gogogo"
    };

    new const szStops[ ][ ]  =
    {
        "counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
        "multi_stop", "stop_counter", "m_counter_end_emi"
    };

    for( new i = 0; i < sizeof szStarts; i++ )
        TrieSetCell( g_tStarts, szStarts[ i ], 1 );
    
    for( new i = 0; i < sizeof szStops; i++ )
        TrieSetCell( g_tStops, szStops[ i ], 1 );

}
public plugin_natives()
{
    register_native("sr_show_toplist", "_sr_show_toplist", 1);
    register_native("sr_get_timer_display_text", "_sr_get_timer_display_text");
}
public _sr_get_timer_display_text(plugin, argc)
{
    enum { arg_id = 1, arg_text = 2, arg_len = 3 }
    new id = get_param(arg_id);
    new len = get_param(arg_len);
    if(g_ePlayerInfo[id][m_bTimerStarted] && !g_ePlayerInfo[id][m_bFinished] && is_user_alive(id))
    {		
        new iTime = get_running_time(id);
        new szTime[32];
        formatex(szTime, charsmax(szTime), "Time: %d:%02d.%03d", iTime / 60000, (iTime / 1000) % 60, iTime % 1000);

        set_string(arg_text, szTime, len);
    }
}
public _sr_show_toplist(id)
{
    Command_Top15(id);
}
public fwdUse(ent, id)
{
    if( !ent || id > 32 )
    {
        return HAM_IGNORED;
    }
    
    if( !is_user_alive(id) )
    {
        return HAM_IGNORED;
    }

    
    new name[32];
    get_user_name(id, name, 31);
    
    new szTarget[ 32 ];
    pev(ent, pev_target, szTarget, 31);
    
    if( TrieKeyExists( g_tStarts, szTarget ) )
    {
        g_bStartButton = true;

        static bool:antispam[33];
        if(is_hook_active(id) || !is_time_after_hook_passed(id, HOOK_ANTICHEAT_TIME))
        {
            if(!antispam[id])
            {
                client_print_color(id, print_team_default, "%s^1 Wait %f seconds after using hook!", PREFIX, HOOK_ANTICHEAT_TIME);
                antispam[id] = true;
            }
            return HAM_IGNORED;
        }
        antispam[id] = false;

        StartTimer(id);

        strip_user_weapons(id);

        rg_give_item(id, "weapon_knife");
        rg_give_item(id, "weapon_usp");
        rg_set_user_bpammo(id, WEAPON_USP, 24);
    }
    
    if( TrieKeyExists( g_tStops, szTarget ) )
    {
        if( g_ePlayerInfo[id][m_bTimerStarted] && !g_ePlayerInfo[id][m_bFinished] )
        {

            if(get_user_noclip(id))
            {
                return HAM_IGNORED;
            }
                
            Forward_PlayerFinished(id);
            user_hook_enable(id, true);
        }
        else
        {
            // kz_hud_message(id, "%L", id, "KZ_TIMER_NOT_STARTED")
            // client_print_color(id, print_team_default, "%s^1 Timer not started", PREFIX);
        }

    }
    return HAM_IGNORED;
}
public plugin_cfg()
{
    set_task(0.5, "DB_Init");
}
public plugin_precache()
{
    // g_iSprite = precache_model("sprites/white.spr");
}
public Command_ClearTop(id, level, cid)
{
    if(!cmd_access(id, level, cid, 0)) return PLUGIN_HANDLED;
    
    formatex(g_szQuery, charsmax(g_szQuery), "DELETE FROM `results` WHERE mid=%d", g_iMapIndex);

    SQL_ThreadQuery(g_hTuple, "Query_ClearTop", g_szQuery);
    
    return PLUGIN_CONTINUE;
}
public Command_Rank(id)
{
    if(!g_ePlayerInfo[id][m_bAuthorized] || is_flooding(id)) return PLUGIN_HANDLED;
    
    new category = get_user_category(id);
    
    if(g_iBestTime[id][category] == 0 && g_iBestTime[id][category] == 0)
    {
        client_print_color(id, print_team_default, "^4[^1%s^4]^1 You never reach finish.", g_szCategory[category]);
        return PLUGIN_CONTINUE;
    }
    
    ShowRank(id, category);
    
    return PLUGIN_CONTINUE;
}
public Command_Top15(id)
{
    if(!g_ePlayerInfo[id][m_bAuthorized] || is_flooding(id)) return PLUGIN_HANDLED;
    
    ShowTop15(id, get_user_category(id));
    
    return PLUGIN_CONTINUE;
}
public Command_Update(id)
{
    if(!g_ePlayerInfo[id][m_bAuthorized] || is_flooding(id)) return PLUGIN_HANDLED;
    
    new szName[32]; get_user_name(id, szName, charsmax(szName)); SQL_PrepareString(szName, szName, charsmax(szName));
    formatex(g_szQuery, charsmax(g_szQuery), "UPDATE `runners` SET nickname = '%s' WHERE id=%d", szName, g_ePlayerInfo[id][m_iPlayerIndex]);
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    return PLUGIN_CONTINUE;
}
public DB_Init()
{
    state mysql;
    
    new szDB[32]; get_pcvar_string(g_pCvars[SQL_DATABASE], szDB, charsmax(szDB));
    
    if(contain(szDB, ".") > 0)
    {
        state sqlite;
    }
        
    SQL_Init();
}
SQL_Init()<sqlite>
{
    SQL_SetAffinity("sqlite");
    
    new szDir[128]; get_localinfo("amxx_datadir", szDir, charsmax(szDir));
    new szDB[32]; get_pcvar_string(g_pCvars[SQL_DATABASE], szDB, charsmax(szDB));
    new szFile[128]; format(szFile, charsmax(szFile), "%s/%s", szDir, szDB);
    
    if(!file_exists(szFile))
    {
        new file = fopen(szFile, "w");
        if(!file)
        {
            new szMsg[128]; formatex(szMsg, charsmax(szMsg), "%s file not found and cant be created.", szFile);
            set_fail_state(szMsg);
        }
        fclose(file);
    }
    
    g_hTuple = SQL_MakeDbTuple("", "", "", szFile, 0);
    
    formatex(g_szQuery, charsmax(g_szQuery),
            "CREATE TABLE IF NOT EXISTS `runners`( \
            id 		INTEGER		PRIMARY KEY,\
            steamid		TEXT 	NOT NULL, \
            nickname	TEXT 	NOT NULL, \
            ip		TEXT 	NOT NULL, \
            nationality	TEXT 	NULL)");
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    formatex(g_szQuery, charsmax(g_szQuery),
            "CREATE TABLE IF NOT EXISTS `maps`( \
            mid 		INTEGER		PRIMARY KEY,\
            mapname		TEXT 		NOT NULL	UNIQUE, \
            finishX		INTEGER 	NOT NULL	DEFAULT 0, \
            finishY		INTEGER 	NOT NULL 	DEFAULT 0, \
            finishZ		INTEGER 	NOT NULL 	DEFAULT 0)");
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    formatex(g_szQuery, charsmax(g_szQuery),
            "CREATE TABLE IF NOT EXISTS `results`( \
            id			INTEGER 	NOT NULL, \
            mid 		INTEGER 	NOT NULL, \
            category	INTEGER 	NOT NULL, \
            checkpoints INTEGER 	NOT NULL, \
            gochecks	INTEGER 	NOT NULL, \
            besttime	INTEGER 	NOT NULL, \
            recorddate	DATETIME	NULL, \
            FOREIGN KEY(id) REFERENCES `runners`(id) ON DELETE CASCADE, \
            FOREIGN KEY(mid) REFERENCES `maps`(mid) ON DELETE CASCADE, \
            PRIMARY KEY(id, mid, category))");
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    set_task(1.0, "DelayedLoadMapInfo");
}
SQL_Init()<mysql>
{
    new szHost[32], szUser[32], szPass[32], szDB[32];
    get_pcvar_string(g_pCvars[SQL_HOST], szHost, charsmax(szHost));
    get_pcvar_string(g_pCvars[SQL_USER], szUser, charsmax(szUser));
    get_pcvar_string(g_pCvars[SQL_PASSWORD], szPass, charsmax(szPass));
    get_pcvar_string(g_pCvars[SQL_DATABASE], szDB, charsmax(szDB));
    
    g_hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB);
    
    if(g_hTuple == Empty_Handle)
    {
        set_fail_state("Cant create connection tuple");
    }
    
    formatex(g_szQuery, charsmax(g_szQuery),
            "CREATE TABLE IF NOT EXISTS `runners`(\
            id			INT(11)	UNSIGNED	AUTO_INCREMENT,\
            steamid		VARCHAR(32)	NOT NULL,\
            nickname	VARCHAR(32)	NOT NULL,\
            ip			VARCHAR(32)	NOT NULL,\
            nationality	VARCHAR(3)	NULL,\
            PRIMARY KEY(id))");
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    formatex(g_szQuery, charsmax(g_szQuery),
            "CREATE TABLE IF NOT EXISTS `maps`(\
            mid 		INT(11)	UNSIGNED 	AUTO_INCREMENT,\
            mapname		VARCHAR(64)	NOT NULL	UNIQUE,\
            finishX		INT(11) 	NOT NULL	DEFAULT 0,\
            finishY		INT(11) 	NOT NULL 	DEFAULT 0,\
            finishZ		INT(11) 	NOT NULL 	DEFAULT 0,\
            PRIMARY KEY(mid))");
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    formatex(g_szQuery, charsmax(g_szQuery),
            "CREATE TABLE IF NOT EXISTS `results`(\
            id			INT(11)		UNSIGNED,\
            mid			INT(11)		UNSIGNED,\
            category	INT(11)		NOT NULL,\
            checkpoints INT(11)		NOT NULL,\
            gochecks    INT(11)		NOT NULL,\
            besttime	INT(11)		NOT NULL,\
            recorddate	DATETIME	NULL,\
            FOREIGN KEY(id) REFERENCES `runners`(id) ON DELETE CASCADE,\
            FOREIGN KEY(mid) REFERENCES `maps`(mid) ON DELETE CASCADE,\
            PRIMARY KEY(id, mid, category))");
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
    set_task(1.0, "DelayedLoadMapInfo");
}
public DelayedLoadMapInfo()
{
    get_mapname(g_szMapName, charsmax(g_szMapName));
    formatex(g_szQuery, charsmax(g_szQuery), "SELECT mid, finishX, finishY, finishZ FROM `maps` WHERE mapname='%s'", g_szMapName);
    SQL_ThreadQuery(g_hTuple, "Query_LoadMapHandle", g_szQuery);
}
public Query_LoadMapHandle(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL error[LoadMapHandle]: %s", error); return;
    }
    
    if(SQL_MoreResults(query))
    {
        g_iMapIndex = SQL_ReadResult(query, 0);
    }
    else
    {		
        formatex(g_szQuery, charsmax(g_szQuery), "INSERT INTO `maps`(mapname) VALUES ('%s')", g_szMapName);
        SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
        
        formatex(g_szQuery, charsmax(g_szQuery), "SELECT mid, finishX, finishY, finishZ FROM `maps` WHERE mapname='%s'", g_szMapName);
        SQL_ThreadQuery(g_hTuple, "Query_LoadMapHandle", g_szQuery);
    }

    if(g_iMapIndex)
    {
        for(new i = 1; i <= 32; i++)
        {
            if(g_ePlayerInfo[i][m_bConnected]) ClientAuthorization(i);
        }
        for(new i; i < Categories; i++)
        {
            ShowTop15(0, i);
        }
    }
}
public Query_ClearTop(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL error[ClearTop]: %s", error); return;
    }

    for(new o = 0; o < sizeof(g_iBestTime); o++)
    {
        arrayset(g_iBestTime[o], 0, sizeof(g_iBestTime[]));
    }
    arrayset(g_iBestTimeofMap, 0, sizeof(g_iBestTimeofMap));

    client_print(0, print_chat, "Top15 just cleared.");
}
public Query_IngnoredHandle(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL error[IngnoredHandle]: %s", error); return;
    }
}
public client_connect(id)
{
    g_ePlayerInfo[id][m_bAuthorized] = false;
    g_ePlayerInfo[id][m_bTimerStarted] = false;
    g_ePlayerInfo[id][m_bFinished] = false;
    g_ePlayerInfo[id][m_iPlayerIndex] = 0;
}
public client_putinserver(id)
{
    if(!is_user_bot(id) && !is_user_hltv(id))
    {
        g_ePlayerInfo[id][m_bConnected] = true;
        ClientAuthorization(id);
    }
}
ClientAuthorization(id)
{
    if(!g_iMapIndex) return;
    
    new szAuth[32]; get_user_authid(id, szAuth, charsmax(szAuth));
    
    new data[1]; data[0] = id;
    formatex(g_szQuery, charsmax(g_szQuery), "SELECT id, ip, nationality FROM `runners` WHERE steamid='%s'", szAuth);
    SQL_ThreadQuery(g_hTuple, "Query_LoadRunnerInfoHandler", g_szQuery, data, sizeof(data));
}
public Query_LoadRunnerInfoHandler(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
    }
    
    new id = data[0];
    if(!is_user_connected(id)) return;
    
    new szCode[5];
    
    if(SQL_MoreResults(query))
    {
        client_authorized_db(id, SQL_ReadResult(query, 0));
        
        SQL_ReadResult(query, 2, szCode, 1);
        
        if(szCode[0] == 0)
        {
            new szIP[32]; get_user_ip(id, szIP, charsmax(szIP), 1);
            
            get_nationality(id, szIP, szCode);
            formatex(g_szQuery, charsmax(g_szQuery), "UPDATE `runners` SET nationality='%s' WHERE id=%d", szCode, g_ePlayerInfo[id][m_iPlayerIndex]);
            SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
        }
    }
    else
    {
        new szAuth[32]; get_user_authid(id, szAuth, charsmax(szAuth));
        new szIP[32]; get_user_ip(id, szIP, charsmax(szIP), 1);
        new szName[64]; get_user_name(id, szName, charsmax(szName));
        SQL_PrepareString(szName, szName, 63);
        
        get_nationality(id, szIP, szCode);
        
        formatex(g_szQuery, charsmax(g_szQuery), "INSERT INTO `runners` (steamid, nickname, ip, nationality) VALUES ('%s', '%s', '%s', '%s')", szAuth, szName, szIP, szCode);
        SQL_ThreadQuery(g_hTuple, "Query_InsertRunnerHandle", g_szQuery, data, size);
    }
}
public Query_InsertRunnerHandle(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL error[InsertRunner]: %s",error); return;
    }
    
    new id = data[0];
    if(!is_user_connected(id)) return;
    
    client_authorized_db(id , SQL_GetInsertId(query));
}
client_authorized_db(id, pid)
{
    g_ePlayerInfo[id][m_iPlayerIndex] = pid;
    g_ePlayerInfo[id][m_bAuthorized] = true;
    
    arrayset(g_iBestTime[id], 0, sizeof(g_iBestTime[]));

    LoadRunnerData(id);
}
LoadRunnerData(id)
{
    if(!g_ePlayerInfo[id][m_bAuthorized]) return;
    
    new data[1]; data[0] = id;
    
    formatex(g_szQuery, charsmax(g_szQuery), "SELECT * FROM `results` WHERE id=%d AND mid=%d", g_ePlayerInfo[id][m_iPlayerIndex], g_iMapIndex);
    SQL_ThreadQuery(g_hTuple, "Query_LoadDataHandle", g_szQuery, data, sizeof(data));
}
public Query_LoadDataHandle(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL Insert error: %s",error); return;
    }
    
    new id = data[0];
    if(!is_user_connected(id)) return;
    
    while(SQL_MoreResults(query))
    {
        new category = SQL_ReadResult(query, Results_category);
        g_iBestTime[id][category] = SQL_ReadResult(query, Results_besttime);
        
        SQL_NextRow(query);
    }
}
public client_disconnected(id)
{
    g_ePlayerInfo[id][m_bAuthorized] = false;
    g_ePlayerInfo[id][m_bConnected] = false;
}

public Engine_TouchFinish(ent, id)
{
    if(g_ePlayerInfo[id][m_bTimerStarted] && !g_ePlayerInfo[id][m_bFinished])
    {
        Forward_PlayerFinished(id);
    }
}

Create_Box(ent, Float:color[3] = {255.0,255.0,255.0})
{
    new Float:maxs[3]; get_entvar(ent, var_absmax, maxs);
    new Float:mins[3]; get_entvar(ent, var_absmin, mins);
    
    new Float:fOrigin[3]; get_entvar(ent, var_origin, fOrigin);
    
    new Float:z;

    // z = zIsMin ? mins[2] : fOrigin[2];
    z = mins[2];
    DrawLine(ent, maxs[0], maxs[1], z, mins[0], maxs[1], z, color);
    DrawLine(ent, maxs[0], maxs[1], z, maxs[0], mins[1], z, color);
    DrawLine(ent, maxs[0], mins[1], z, mins[0], mins[1], z, color);
    DrawLine(ent, mins[0], mins[1], z, mins[0], maxs[1], z, color);

}
ReDrawLine(beamEnt, Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) 
{
    new Float:start[3], Float:stop[3];
    start[0] = x1;
    start[1] = y1;
    start[2] = z1;
    
    stop[0] = x2;
    stop[1] = y2;
    stop[2] = z2;

    Beam_SetStartPos(beamEnt, start);
    Beam_SetEndPos(beamEnt, stop);
}
DrawLine(ent, Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, Float:color[3] = {255.0,255.0,255.0}) 
{
    new Float:start[3], Float:stop[3];
    start[0] = x1;
    start[1] = y1;
    start[2] = z1;
    
    stop[0] = x2;
    stop[1] = y2;
    stop[2] = z2;
    
    new beamEnt = Beam_Create(FINISH_SPRITENAME, 10.0);

    new class[20];
    pev(ent, FAKEMETA_PEV_TYPE, class, charsmax(class));
    format(class, charsmax(class), "beam_%s", class);
    set_pev(beamEnt, pev_classname, class);

    Beam_PointsInit(beamEnt, start, stop);
    Beam_SetBrightness(beamEnt, 200.0);
    Beam_SetColor(beamEnt, color);
    set_pev(beamEnt, pev_owner, ent);
    return beamEnt;
}

public SR_PlayerOnStart(id)
{
    HC_CBasePlayer_Spawn_Post(id);
}
public OnHookStart(id)
{
    g_ePlayerInfo[id][m_bWasUseHook] = true;
}
public HC_CBasePlayer_Spawn_Post(id)
{
    g_ePlayerInfo[id][m_bTimerStarted] = false;
    g_ePlayerInfo[id][m_bFinished] = false;
    g_ePlayerInfo[id][m_bWasUseHook] = false;
    user_hook_enable(id, true);
    // hide_timer(id);
}
public HC_CheckStartTimer(id)
{
    if(g_bStartButton) return;
    
    if(g_ePlayerInfo[id][m_bAuthorized] && !g_ePlayerInfo[id][m_bTimerStarted] && !g_ePlayerInfo[id][m_bWasUseHook])
    {
        StartTimer(id);
    }
}
public box_created(box, const szClass[])
{

    static Float:color_start[3] = {0.0, 255.0, 0.0}, Float:color_finish[3] = {255.0, 0.0, 0.0};
    if(equal("start", szClass))
    {
        Create_Box(box, color_start);
        g_bStartButton = false;
        // g_ePlayerInfo[id][m_bFinished] = true;
    }
    if(equal("finish", szClass))
    {
        Create_Box(box, color_finish);
        g_bStartButton = false;
        // g_ePlayerInfo[id][m_bFinished] = true;
        g_iFinishEnt = box;
    }
}
public box_deleted(box, const szClass[])
{
    new a = -1;
    new class[32];
    format(class, charsmax(class), "beam_%s", szClass);
    
    while((a = find_ent_by_owner(a, class, box)))
    {
        remove_entity(a);
    }
    g_iFinishEnt = 0;
}
public box_resized(box, const szClass[])
{
    new beams[4], a = -1, count = 0;

    new class[32];
    format(class, charsmax(class), "beam_%s", szClass);
    
    while((a = find_ent_by_owner(a, class, box)))
    {
        beams[count++] = a;
    }

    new Float:maxs[3]; get_entvar(box, var_absmax, maxs);
    new Float:mins[3]; get_entvar(box, var_absmin, mins);
    
    // maxs[2] = mins[2];
    new Float:z = mins[2];

    ReDrawLine(beams[0], maxs[0], maxs[1], z, mins[0], maxs[1], z);
    ReDrawLine(beams[1], maxs[0], maxs[1], z, maxs[0], mins[1], z);
    ReDrawLine(beams[2], maxs[0], mins[1], z, mins[0], mins[1], z);
    ReDrawLine(beams[3], mins[0], mins[1], z, mins[0], maxs[1], z);

}
public box_start_touch(box, ent, const szClass[])
{
    if(equal(szClass, "finish"))
    {
        Engine_TouchFinish(box, ent);
    }
}
public box_stop_touch(box, id, const szClass[])
{
    if(equal(szClass, "start"))
    {
        HC_CheckStartTimer(id);
    }
}
StartTimer(id)
{
    if(!g_iFinishEnt && !g_bStartButton) return;
    
    user_hook_enable(id, false);
    reset_checkpoints(id);
    
    g_ePlayerInfo[id][m_bTimerStarted] = true;
    g_ePlayerInfo[id][m_bFinished] = false;
    g_ePlayerInfo[id][m_fStartRun] = _:get_gametime();
}

Forward_PlayerFinished(id)
{
    g_ePlayerInfo[id][m_bFinished] = true;
    
    new record = false;
    new iTime = get_running_time(id);
    new category = get_user_category(id);
    new szTime[32]; get_formated_time_smart(iTime, szTime, charsmax(szTime));
    new szTimeDelta[32]; get_formated_time_smart(g_iBestTimeofMap[category] - iTime, szTimeDelta, charsmax(szTimeDelta));
    
    new szName[32]; get_user_name(id, szName, charsmax(szName));

    // console_print(id, "^4[^1%s^4]^1 Time: %s!", g_szCategory[category], szTime);
    // client_print_color(0, print_team_blue, "^4[^1%s^4] ^3%s^1 %L ^3%s", 
        // g_szCategory[category], szName, LANG_PLAYER, "SR_TIME_FINISH", szTime);
    
    if(g_iBestTime[id][category] == 0)
    {
        // client_print_color(id, print_team_default, "%s^1 First finish.", g_szCategory[category]);
        SaveRunnerData(id, category, iTime);
    }
    else if(g_iBestTime[id][category] > iTime)
    {
        // get_formated_time(g_iBestTime[id][category] - iTime, szTime, charsmax(szTime));
        // console_print(id, "%s Own record: -%s!", g_szCategory[category], szTime);
        // client_print_color(id, print_team_default, "%s Own record: -%s!", g_szCategory[category], szTime);
        SaveRunnerData(id, category, iTime);
    }
    else if(g_iBestTime[id][category] < iTime)
    {
        // get_formated_time(iTime - g_iBestTime[id][category], szTime, charsmax(szTime));
        // console_print(id, "%s Own record: +%s!", g_szCategory[category], szTime);
    }
    else
    {
        // client_print_color(id, print_team_default, "%s%s^1 Own record equal!", PREFIX, g_szCategory[category]);
    }
    
    if(g_iBestTimeofMap[category] == 0 || g_iBestTimeofMap[category] > iTime)
    {
        // get_formated_time_smart(iTime, szTime, charsmax(szTime));
        if(g_iBestTimeofMap[category] > 0)
        {
            client_print_color(0, print_team_blue, "^4[^1%s^4] %L", 
                g_szCategory[category], LANG_PLAYER, "SR_TIME_FINISH", szName, szTime);
            client_print_color(0, print_team_default, "^4[^1%s^4] %L", 
                g_szCategory[category], LANG_PLAYER, "SR_TIME_WR_BY", szName, szTimeDelta);
        } 
        else 
        {
            client_print_color(0, print_team_blue, "^4[^1%s^4] %L", 
                g_szCategory[category], LANG_PLAYER, "SR_TIME_WR_FIRST", szName, szTime);
        }
        
        g_iBestTimeofMap[category] = iTime;
        record = true;
    }
    if(g_iBestTimeofMap[category] != 0 && g_iBestTimeofMap[category] < iTime)
    {
        // new szTimeDelta[32];
        // get_formated_time_smart(g_iBestTimeofMap[category] - iTime, szTimeDelta, charsmax(szTimeDelta));
        // get_formated_time(iTime - g_iBestTimeofMap[category], szTime, charsmax(szTime));
        // console_print(id, "%s Map record: +%s!", g_szCategory[category], szTime);
        client_print_color(0, print_team_blue, "^4[^1%s^4] %L", 
            g_szCategory[category], LANG_PLAYER, "SR_TIME_FINISH", szName, szTime);
    }
    if(record)
    {
        // client_cmd( 0, "spk woop" );
        client_cmd(0, "spk buttons/bell1");
    }
    else
    {
        if(g_bStartButton)
        {
            client_cmd(0, "spk buttons/bell1");
        }
        else
        {
            client_cmd(0, "spk buttons/bell1");
            // client_cmd(0, "spk buttons/spark1");
        }
    }
    
    // ExecuteForward(g_fwFinished, g_iReturn, id, iTime, record);
    
    // hide_timer(id);
}
public SaveRunnerData(id, category, iTime)
{
    if(!g_ePlayerInfo[id][m_bAuthorized]) return;
    
    new query_type = g_iBestTime[id][category] ? 1 : 0;

    g_iBestTime[id][category] = iTime;
    
    new szRecordTime[32]; get_time("%Y-%m-%d %H:%M:%S", szRecordTime, charsmax(szRecordTime));
    
    if(query_type)
    {
        formatex(g_szQuery, charsmax(g_szQuery), "UPDATE `results` SET checkpoints=%d, gochecks=%d, besttime=%d, recorddate='%s' WHERE id=%d AND mid=%d AND category=%d",
            get_checkpoints_count(id), get_gochecks_count(id), iTime, szRecordTime, g_ePlayerInfo[id][m_iPlayerIndex], g_iMapIndex, category);
    }
    else
    {
        formatex(g_szQuery, charsmax(g_szQuery), "INSERT INTO `results` VALUES (%d, %d, %d, %d, %d, %d, '%s')",
            g_ePlayerInfo[id][m_iPlayerIndex], g_iMapIndex, category, get_checkpoints_count(id), get_gochecks_count(id), iTime, szRecordTime);
    }
    
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    
}

ShowRank(id, category)
{
    formatex(g_szQuery, charsmax(g_szQuery), "SELECT COUNT(*) FROM `results` WHERE mid=%d AND category=%d AND besttime > 0 AND besttime < %d", 
            g_iMapIndex, category, g_iBestTime[id][category]);
        
    new data[3]; data[0] = id; data[1] = category;
    SQL_ThreadQuery(g_hTuple, "Query_LoadRankHandle", g_szQuery, data, sizeof(data));
}
public Query_LoadRankHandle(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL error[LoadRankHandle]: %s", error); return;
    }
    
    new id = data[0];
    new category = data[1];
    
    if(!is_user_connected(id) || !SQL_MoreResults(query)) return;
    
    new rank = SQL_ReadResult(query, Results_id) + 1;
    client_print_color(id, print_team_default, "^4[^1%s^4]^1 Your rank is %d!", g_szCategory[category], rank);
}

ShowTop15(id, category)
{
    formatex(g_szQuery, charsmax(g_szQuery), "SELECT nickname, besttime, checkpoints, gochecks FROM `results` JOIN `runners` ON `runners`.id=`results`.id WHERE mid=%d AND category=%d AND besttime ORDER BY besttime ASC LIMIT 15", 
            g_iMapIndex, category);
        
    new data[2]; data[0] = id; data[1] = category;
    SQL_ThreadQuery(g_hTuple, "Query_LoadTop15Handle", g_szQuery, data, sizeof(data));
}
public Query_LoadTop15Handle(failstate, Handle:query, error[], errnum, data[], size)
{
    if(failstate != TQUERY_SUCCESS)
    {
        log_amx("SQL error[LoadTop15]: %s",error); return;
    }

    new id = data[0];
    if(!is_user_connected(id) && id != 0) return;
    
    new category = data[1];
    
    new iLen = 0, iMax = charsmax(g_szMotd);
    iLen = formatex(g_szMotd[iLen], iMax-iLen, "<meta charset=utf-8>");
    iLen += formatex(g_szMotd[iLen], iMax-iLen, "<style>{font:normal 10px} body {margin:0px;} table, th, td{border: 1px solid lightgray;border-collapse:collapse;text-align:center;}");
    iLen += formatex(g_szMotd[iLen], iMax-iLen, "</style><html><table width=100%%><thead><tr><th width=10%%>%s</th> <th width=50%%>%s</th><th width=10%%>%s</th><th width=10%%>%s</th><th width=10%%>%s</th></tr></thead><tbody>", "№", "", "CP", "Gochecks", "");
    
    
    new i = 1;
    new iTime, szName[32], szTime[32],
        checkpoints, gochecks;
    while(SQL_MoreResults(query))
    {
        SQL_ReadResult(query, 0, szName, 31);
        iTime       = SQL_ReadResult(query, 1);
        checkpoints = SQL_ReadResult(query, 2);
        gochecks    = SQL_ReadResult(query, 3);
        get_formated_time(iTime, szTime, 31);
        
        iLen += formatex(g_szMotd[iLen], iMax-iLen, "<tr><td>%d</td><td>%s</td>", i, szName);
        iLen += formatex(g_szMotd[iLen], iMax-iLen, "<td>%d</td>", checkpoints);
        iLen += formatex(g_szMotd[iLen], iMax-iLen, "<td>%d</td>", gochecks);
        if(i == 1)
        {
            g_iBestTimeofMap[category] = iTime;
            iLen += formatex(g_szMotd[iLen], iMax-iLen, "<td>%s</td>",  szTime);
            // iLen += formatex(g_szMotd[iLen], iMax-iLen, "<td>%s</td><td></td>",  szTime);
            if(id == 0) return;
        }
        else
        {
            iLen += formatex(g_szMotd[iLen], iMax-iLen, "<td>%s</td>", szTime);
            
            // get_formated_time(iTime-g_iBestTimeofMap[category] , szTime, 31);
            // iLen += formatex(g_szMotd[iLen], iMax-iLen, "<td>+%s</td>", szTime);
        }
        iLen += formatex(g_szMotd[iLen], iMax-iLen, "</tr>");
        
        i++;
        SQL_NextRow(query);
    }
    iLen += formatex(g_szMotd[iLen], iMax-iLen, "</pre>");
    show_motd(id, g_szMotd, "Top15");
}


// hide_timer(id)
// {
//     // show_status(id, "");
// }
// display_time(id, iTime)
// {
//     show_status(id, "Time: %d:%02d.%03ds", iTime / 60000, (iTime / 1000) % 60, iTime % 1000);
// }
// show_status(id, const szMsg[], any:...)
// {
//     static szStatus[128]; vformat(szStatus, charsmax(szStatus), szMsg, 3);
//     static StatusText; if(!StatusText) StatusText = get_user_msgid("StatusText");
    
//     message_begin(MSG_ONE_UNRELIABLE, StatusText, _, id);
//     write_byte(0);
//     write_string(szStatus);
//     message_end();
// }
get_running_time(id)
{
    return floatround((get_gametime() - g_ePlayerInfo[id][m_fStartRun]) * 1000, floatround_ceil);
}
get_formated_time_smart(iTime, szTime[], size)
{
    if(iTime < 60000)
    {
        formatex(szTime, size, "%d.%03d", (iTime / 1000) % 60, iTime % 1000);
    }
    else
    {
        formatex(szTime, size, "%d:%02d.%03d", iTime / 60000, (iTime / 1000) % 60, iTime % 1000 / 10);
    }
    
}
get_formated_time(iTime, szTime[], size)
{
    formatex(szTime, size, "%d:%02d.%03d", iTime / 60000, (iTime / 1000) % 60, iTime % 1000);
}
get_nationality(id, const szIP[], szCode[5])
{
    new szTemp[3];
    if(geoip_code2_ex(szIP, szTemp))
    {
        copy(szCode, 4, szTemp);
    }
    else
    {
        get_user_info(id, "lang", szCode, 2);
        SQL_PrepareString(szCode, szCode, 4);
    }
}
bool:is_flooding(id)
{
    static Float:fAntiFlood[33];
    new bool:fl = false;
    new Float:fNow = get_gametime();
    
    if((fNow-fAntiFlood[id]) < 1.0) fl = true;
    
    fAntiFlood[id] = fNow;
    return fl;
}
stock SQL_PrepareString(const szQuery[], szOutPut[], size)
{
    copy(szOutPut, size, szQuery);
    replace_all(szOutPut, size, "'", "\'");
    replace_all(szOutPut,size, "`", "\`");
    replace_all(szOutPut,size, "\\", "\\\\");
}
