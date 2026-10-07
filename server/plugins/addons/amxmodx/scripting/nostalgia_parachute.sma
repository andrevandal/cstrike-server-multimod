#include <amxmodx>
#include <fakemeta>
#include <reapi>

#define PARACHUTE_MODEL "models/parachute.mdl"

new Float:g_fallSpeed;
new g_parachute[MAX_PLAYERS + 1];
new bool:g_hasModel;

public plugin_precache()
{
	g_hasModel = bool:file_exists(PARACHUTE_MODEL);
	if (g_hasModel)
		precache_model(PARACHUTE_MODEL);
}

public plugin_init()
{
	register_plugin("Nostalgia Parachute", "1.0.0", "cstrike-server-multimod");

	bind_pcvar_float(create_cvar("parachute_fallspeed", "100", .has_min = true, .min_val = 0.0), g_fallSpeed);

	RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink");
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled", .post = true);
}

public client_disconnected(id)
{
	removeParachute(id);
}

public OnPlayerKilled(const victim)
{
	removeParachute(victim);
}

public OnPlayerPreThink(const id)
{
	if (!is_user_alive(id))
		return;

	new bool:falling = !(get_entvar(id, var_flags) & FL_ONGROUND) && get_entvar(id, var_waterlevel) == 0;

	if (!falling || !(get_entvar(id, var_button) & IN_USE))
	{
		removeParachute(id);
		return;
	}

	new Float:velocity[3];
	get_entvar(id, var_velocity, velocity);

	if (velocity[2] >= 0.0)
		return;

	velocity[2] = floatmax(velocity[2], -g_fallSpeed);
	set_entvar(id, var_velocity, velocity);
	showParachute(id);
}

showParachute(const id)
{
	if (!g_hasModel || !is_nullent(g_parachute[id]))
		return;

	new ent = rg_create_entity("info_target");
	if (is_nullent(ent))
		return;

	engfunc(EngFunc_SetModel, ent, PARACHUTE_MODEL);
	set_entvar(ent, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(ent, var_aiment, id);
	g_parachute[id] = ent;
}

removeParachute(const id)
{
	if (!is_nullent(g_parachute[id]))
		set_entvar(g_parachute[id], var_flags, FL_KILLME);

	g_parachute[id] = 0;
}
