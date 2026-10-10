#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#define PLUGIN "Nostalgia Armoury Respawn"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"
#define TASK_RESPAWN 7300   // task id = TASK_RESPAWN + entity index

new Float:g_respawnTime;
new g_respawned;   // restores since map start, for armoury_status

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    bind_pcvar_float(create_cvar("armoury_respawn_time", "10", .has_min = true, .min_val = 0.0, .description = "Seconds until an emptied map weapon spawn (armoury_entity) refills in Deathmatch; 0 disables"), g_respawnTime);
    RegisterHam(Ham_Touch, "armoury_entity", "OnArmouryTouchPost", 1);
    register_srvcmd("armoury_status", "CmdStatus");
}

public OnArmouryTouchPost(const ent, const id)
{
    if (g_respawnTime <= 0.0 || get_cvar_float("mp_forcerespawn") <= 0.0)
        return HAM_IGNORED;

    if (get_member(ent, m_Armoury_iCount) > 0 || task_exists(TASK_RESPAWN + ent))
        return HAM_IGNORED;

    set_task(g_respawnTime, "RestoreArmoury", TASK_RESPAWN + ent);
    return HAM_IGNORED;
}

public RestoreArmoury(taskId)
{
    new ent = taskId - TASK_RESPAWN;
    if (!is_entity(ent) || get_cvar_float("mp_forcerespawn") <= 0.0 || get_cvar_num("mp_weapons_allow_map_placed") == 0)
        return;

    set_member(ent, m_Armoury_iCount, get_member(ent, m_Armoury_iInitialCount));
    set_entvar(ent, var_effects, get_entvar(ent, var_effects) & ~EF_NODRAW);
    set_entvar(ent, var_solid, SOLID_TRIGGER);

    new Float:origin[3];
    get_entvar(ent, var_origin, origin);
    engfunc(EngFunc_SetOrigin, ent, origin);

    g_respawned++;
}

public CmdStatus()
{
    new visible, empty;
    new ent;
    while((ent = rg_find_ent_by_class(ent, "armoury_entity")))
    {
        if (get_member(ent, m_Armoury_iCount) > 0)
            visible++;
        else
            empty++;
    }

    server_print("armoury_status visible=%d empty=%d respawned=%d respawn_time=%.1f", visible, empty, g_respawned, g_respawnTime);
    return PLUGIN_HANDLED;
}
