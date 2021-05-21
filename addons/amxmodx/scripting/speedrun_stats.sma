/* 
    TODO: 
        * fix message on finish showing wrong time
        * set language automaticaly https://dev-cs.ru/resources/469/
                                    https://dev-cs.ru/resources/570/field?field=source
                                    (remove AutoLang - seems not work)
        * check my notebook
        * allow to interupt run with hook (menu open up 1. stop timer & use hoo 2. continue run)

        // 5.3.1 how to check for player leaving start zone? possible solutions: 
        //             4. use simple algorythm that will detect whether a point (player origin) is inside of a box.
        //             1. see Box.sma (set_task) 
        //             2. using client_prethink and touch hooks 
        //             3. use this or even copy code from rehlds source (as stated in comments in the provided link) https://forums.alliedmods.net/showthread.php?t=307944
        // 3. (? optional ?) Auto change invalid FPS (no fps categories in the beginning, so this point is not valid for now)
    DONE:
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
#define FINISH_CLASSNAME "SR_FINISH"
#define FINISH_SPRITENAME "sprites/white.spr"

enum _:PlayerData
{
    m_bConnected,
    m_bAuthorized,
    m_bTimerStarted,
    m_bFinished,
    m_iPlayerIndex,
    // m_iSkillLevel,
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
    Cat_2k
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
enum _:RunnersColumns
{
    Runners_id,
    Runners_steamid,
    Runners_nickname,
    Runners_ip,
    Runners_nationality,
};
enum _:MapsColumns
{
    Maps_mid,
    Maps_mapname,
    Maps_finishX,
    Maps_finishY,
    Maps_finishZ,
};
enum _:SkillLevels
{
    PRO, 
    NOOB
}

new const PREFIX[] = "^1[^4Speedrun^1]";

new const g_szCategory[][] = 
{
    "100 FPS", "200 FPS", "250 FPS", "333 FPS", "500 FPS", "Fastrun", "Bhop", "Crazy Speed", "2K"
};

new g_pCvars[Cvars];
new Handle:g_hTuple, g_szQuery[512];
new g_szMapName[32];
new g_iMapIndex;
new g_ePlayerInfo[33][PlayerData];
new g_iBestTime[33][Categories];
new g_iFinishEnt;
// new g_iFinishBeams[12];
// new g_iSprite;
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
    g_pCvars[SQL_DATABASE] = register_cvar("speedrun_database", "speedrun");
    
    register_clcmd("cleartop", "Command_ClearTop", ADMIN_CFG);
    register_clcmd("setfinish", "Command_SetFinish", ADMIN_CFG);
    register_clcmd("say /rank", "Command_Rank");
    register_clcmd("say /top15", "Command_Top15");
    register_clcmd("say /update", "Command_Update");
    
    RegisterHookChain(RG_CBasePlayer_Jump, "HC_CheckStartTimer", false);
    RegisterHookChain(RG_CBasePlayer_Duck, "HC_CheckStartTimer", false);
    RegisterHookChain(RG_CBasePlayer_Spawn, "HC_CBasePlayer_Spawn_Post", true);

    // register_forward(FM_AddToFullPack, "FM_AddToFullPack_Post", 1);
    RegisterHam( Ham_Use, "func_button", "fwdUse", 0);

    register_touch(FINISH_CLASSNAME, "player", "Engine_TouchFinish");
    
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
public FM_AddToFullPack_Post(const STATE/* = 0*/, e, ent, host, hostflags, player, set)
{
   if (is_user_alive(host) && g_ePlayerInfo[host][m_bFinished] && pev_valid(ent))
   {
      static classname[8];
      pev(ent, pev_classname, classname, 7);
      if (equal(classname, "beamfin"))
      {
        set_es(STATE, ES_RenderColor, Float:{0,200,0});
        return FMRES_HANDLED;
      }
   }
   return FMRES_IGNORED;
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

        static bool:antispam;
        if(is_hook_active(id) || !is_time_after_hook_passed(id, HOOK_ANTICHEAT_TIME))
        {
            if(!antispam)
            {
                client_print_color(id, print_team_default, "%s^1 Wait %f seconds after using hook!", PREFIX, HOOK_ANTICHEAT_TIME);
                antispam = true;
            }
            return HAM_IGNORED;
        }
        antispam = false;

        StartTimer(id);

        strip_user_weapons(id);

        if(!is_weapon_hidden(id))
        {
            give_item(id,"weapon_knife");
            give_item(id,"weapon_usp");
            rg_set_user_bpammo(id, WEAPON_USP, 24);
        }
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
public Command_SetFinish(id, level, cid)
{
    if(!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
    if(g_iFinishEnt)
    {
        client_print_color(id, print_team_red, "%s^1 Finish zone is ^3removed^1.", PREFIX);
        DeleteFinishOrigin();	
        remove_entity(g_iFinishEnt);
        // DeleteFinishBeams();
        g_iFinishEnt = 0;
        g_bStartButton = true;
        g_ePlayerInfo[id][m_bFinished] = true;
        return PLUGIN_HANDLED;
    }
    
    g_bStartButton = false;
    g_ePlayerInfo[id][m_bFinished] = true;
    
    new Float:fOrigin[3]; get_entvar(id, var_origin, fOrigin);
    fOrigin[2] = fOrigin[2] - 20.0;
    CreateFinish(fOrigin);
    SaveFinishOrigin();
    
    return PLUGIN_HANDLED;
}
// DeleteFinishBeams()
// {

//     for(new i = 0; i < sizeof g_iFinishBeams; i++)
//     {
//         new iBeamEntity = g_iFinishBeams[i];
//         if(!is_valid_ent(iBeamEntity)) return;

//         remove_entity(iBeamEntity);
//         g_iFinishBeams[i] = 0;
//     }
        
// }
DeleteFinishOrigin()
{
    formatex(g_szQuery, charsmax(g_szQuery), "UPDATE `maps` SET finishX = '0', finishY = '0', finishZ = '0' WHERE mid=%d", g_iMapIndex);
    SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
}
SaveFinishOrigin()
{
    if(is_valid_ent(g_iFinishEnt))
    {
        new Float:fOrigin[3]; get_entvar(g_iFinishEnt, var_origin, fOrigin);
        new iOrigin[3]; FVecIVec(fOrigin, iOrigin);
        
        formatex(g_szQuery, charsmax(g_szQuery), "UPDATE `maps` SET finishX = '%d', finishY = '%d', finishZ = '%d' WHERE mid=%d", 
            iOrigin[0], iOrigin[1], iOrigin[2], g_iMapIndex);
        
        SQL_ThreadQuery(g_hTuple, "Query_IngnoredHandle", g_szQuery);
    }
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
        
        CreateFinishI(SQL_ReadResult(query, 1),  SQL_ReadResult(query, 2),  SQL_ReadResult(query, 3));

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
        // Create_Box(id, ent);
        // SetFinishColor(200, 0, 0);
        Forward_PlayerFinished(id);
    }
}
// public SetFinishColor(r, g, b)
// {
//     new Float:fColor[3];
//     fColor[0] = float(r);
//     fColor[1] = float(g);
//     fColor[2] = float(b);
//     for(new i = 0; i < sizeof g_iFinishBeams; i++)
//     {
//         new iBeamEntity = g_iFinishBeams[i];
//         if(!is_valid_ent(iBeamEntity)) return;
        
//         // server_print("Finish beam is valid!");

//         Beam_SetColor(iBeamEntity, fColor);
//     }
// }
CreateFinishI(x, y, z)
{
    if(!x && !y && !z) return;
    
    new Float:fOrigin[3];
    fOrigin[0] = float(x);
    fOrigin[1] = float(y);
    fOrigin[2] = float(z);
    
    CreateFinish(fOrigin);
}
CreateFinish(const Float:fOrigin[3])
{	
    if(is_valid_ent(g_iFinishEnt)) remove_entity(g_iFinishEnt);
    
    g_iFinishEnt = 0;
    
    new ent = create_entity("trigger_multiple");
    set_entvar(ent, var_classname, FINISH_CLASSNAME);
    
    set_entvar(ent, var_origin, fOrigin);
    dllfunc(DLLFunc_Spawn, ent);
    
    entity_set_size(ent, Float:{-100.0, -100.0, -50.0}, Float:{100.0, 100.0, 50.0});
    
    set_entvar(ent, var_solid, SOLID_TRIGGER);
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    
    g_iFinishEnt = ent;
    
    Create_Box(g_iFinishEnt, Float:{255.0,0.0,0.0});
    // SetFinishColor(200, 0, 0);
    // set_entvar(ent, var_nextthink, get_gametime());
}
Create_Box(ent, Float:color[3] = {255.0,255.0,255.0}, zIsMin = false)
{
    new Float:maxs[3]; get_entvar(ent, var_absmax, maxs);
    new Float:mins[3]; get_entvar(ent, var_absmin, mins);
    
    new Float:fOrigin[3]; get_entvar(ent, var_origin, fOrigin);
    
    new Float:z;

    z = zIsMin ? mins[2] : fOrigin[2];
    DrawLine(maxs[0], maxs[1], z, mins[0], maxs[1], z, color);
    DrawLine(maxs[0], maxs[1], z, maxs[0], mins[1], z, color);
    DrawLine(maxs[0], mins[1], z, mins[0], mins[1], z, color);
    DrawLine(mins[0], mins[1], z, mins[0], maxs[1], z, color);

}
DrawLine(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, Float:color[3] = {255.0,255.0,255.0}) 
{
    new Float:start[3], Float:stop[3];
    start[0] = x1;
    start[1] = y1;
    start[2] = z1;
    
    stop[0] = x2;
    stop[1] = y2;
    stop[2] = z2;
    
    new beamEnt = Beam_Create(FINISH_SPRITENAME, 10.0);
    set_pev(beamEnt, pev_classname, "beamfin");
    Beam_PointsInit(beamEnt, start, stop);
    Beam_SetBrightness(beamEnt, 200.0);
    Beam_SetColor(beamEnt, color);
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
public box_created(ent, const szClass[])
{
    static Float:color_start[3] = {0.0, 255.0, 0.0}, Float:color_finish[3] = {255.0, 0.0, 0.0};
    if(equal("start", szClass))
    {
        Create_Box(ent, color_start, true);
        g_bStartButton = false;
        // g_ePlayerInfo[id][m_bFinished] = true;
    }
    if(equal("finish", szClass))
    {
        Create_Box(ent, color_finish, true);
        g_bStartButton = false;
        // g_ePlayerInfo[id][m_bFinished] = true;
        g_iFinishEnt = ent;
    }
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
        client_cmd( 0, "spk woop" );
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
