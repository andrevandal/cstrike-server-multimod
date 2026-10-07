#include <amxmodx>
#include <reapi>

new g_killBonus, g_headshotBonus, g_maxHealth;

public plugin_init()
{
	register_plugin("Nostalgia Vampire", "1.0.0", "cstrike-server-multimod");

	bind_pcvar_num(create_cvar("vampire_kill_hp", "15", .has_min = true, .min_val = 0.0), g_killBonus);
	bind_pcvar_num(create_cvar("vampire_headshot_hp", "30", .has_min = true, .min_val = 0.0), g_headshotBonus);
	bind_pcvar_num(create_cvar("vampire_max_hp", "100", .has_min = true, .min_val = 1.0), g_maxHealth);

	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled", .post = true);
}

public OnPlayerKilled(const victim, const killer)
{
	if (killer == victim || !is_user_alive(killer))
		return;

	if (get_member(killer, m_iTeam) == get_member(victim, m_iTeam))
		return;

	new bonus = get_member(victim, m_bHeadshotKilled) ? g_headshotBonus : g_killBonus;
	new Float:health = Float:get_entvar(killer, var_health) + float(bonus);

	set_entvar(killer, var_health, floatmin(health, float(g_maxHealth)));
}
