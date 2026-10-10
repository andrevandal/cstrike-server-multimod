#include <amxmodx>
#include <reapi>
#include <nostalgia_logic>

#define PLUGIN "Nostalgia Mode Rules"
#define VERSION "1.1.0"
#define AUTHOR "cstrike-server-multimod"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHookChain(RG_CBasePlayer_DropIdlePlayer, "OnDropIdlePlayer");
}

// ReGameDLL kicks players idle for max(mp_roundtime, 60 s) * 2 ("Player idle").
// Full admins (ADMIN_BAN, which moderators lack) are exempt.
public OnDropIdlePlayer(const id, const reason[])
{
    if (get_user_flags(id) & ADMIN_BAN)
    {
        return HC_SUPERCEDE;
    }

    return HC_CONTINUE;
}

public plugin_cfg()
{
    set_task(1.0, "applyModeRules");
}

public applyModeRules()
{
    new map[32];
    get_mapname(map, charsmax(map));

    if (nl_is_classic_map(map))
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
