#include <amxmodx>

#define PLUGIN "Nostalgia Mode Rules"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_cfg()
{
    set_task(1.0, "applyModeRules");
}

public applyModeRules()
{
    new map[32];
    get_mapname(map, charsmax(map));

    if (equali(map, "cs_", 3) || equali(map, "de_", 3))
    {
        setClassicRules();
    }
}

setClassicRules()
{
    set_cvar_float("mp_forcerespawn", 0.0);
    set_cvar_num("mp_respawn_immunitytime", 0);
    set_cvar_num("mp_round_infinite", 0);
    set_cvar_num("mp_free_armor", 0);
    set_cvar_num("mp_buy_anywhere", 0);
    set_cvar_float("mp_buytime", 0.25);
    set_cvar_num("mp_startmoney", 800);
    set_cvar_num("mp_refill_bpammo_weapons", 0);
    set_cvar_num("mp_auto_reload_weapons", 0);
    set_cvar_num("mp_item_staytime", 300);
    set_cvar_num("mp_freeforall", 0);
    set_cvar_num("mp_freezetime", 2);
    set_cvar_num("mp_autobunnyhopping", 1);
}
