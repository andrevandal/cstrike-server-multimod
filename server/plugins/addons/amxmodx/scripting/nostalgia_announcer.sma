#include <amxmodx>
#include <cstrike>

#define PLUGIN "Nostalgia Announcer"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

const Float:MULTIKILL_WINDOW = 4.0;

new const SoundFiles[10][32] = {
    "nostalgia/DoubleKill.wav",
    "nostalgia/TripleKill.wav",
    "nostalgia/MegaKill.wav",
    "nostalgia/Rampage.wav",
    "nostalgia/KillingSpree.wav",
    "nostalgia/Dominating.wav",
    "nostalgia/Ownage.wav",
    "nostalgia/Mayhem.wav",
    "nostalgia/Carnage.wav",
    "nostalgia/Godlike.wav"
};

new const StreakLabels[10][16] = {
    "DOUBLE KILL",
    "TRIPLE KILL",
    "MEGA KILL",
    "RAMPAGE",
    "KILLING SPREE",
    "DOMINATING",
    "OWNAGE",
    "MAYHEM",
    "CARNAGE",
    "GODLIKE"
};

new Float:g_lastKillTime[MAX_PLAYERS + 1];
new g_multiKills[MAX_PLAYERS + 1];

public plugin_precache()
{
    for (new i = 0; i < sizeof SoundFiles; i++)
    {
        precache_sound(SoundFiles[i]);
    }
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_event("DeathMsg", "OnPlayerDeath", "a");
}

public client_disconnected(id)
{
    g_lastKillTime[id] = 0.0;
    g_multiKills[id] = 0;
}

public OnPlayerDeath()
{
    new killer = read_data(1);
    new victim = read_data(2);

    if (victim >= 1 && victim <= MaxClients)
    {
        g_lastKillTime[victim] = 0.0;
        g_multiKills[victim] = 0;
    }

    if (killer < 1 || killer > MaxClients || killer == victim || !is_user_connected(killer))
        return;

    if (!get_cvar_num("mp_freeforall") && cs_get_user_team(killer) == cs_get_user_team(victim))
        return;

    new Float:now = get_gametime();
    if (now - g_lastKillTime[killer] <= MULTIKILL_WINDOW)
    {
        g_multiKills[killer]++;
    }
    else
    {
        g_multiKills[killer] = 1;
    }
    g_lastKillTime[killer] = now;

    if (g_multiKills[killer] < 2)
        return;

    new soundIndex = g_multiKills[killer] - 2;
    if (soundIndex >= sizeof SoundFiles)
    {
        soundIndex = sizeof SoundFiles - 1;
    }
    new playerName[32];
    get_user_name(killer, playerName, charsmax(playerName));

    client_cmd(0, "spk ^"%s^"", SoundFiles[soundIndex]);
    client_print_color(0, print_team_default, "^4[DM]^1 %s: ^3%s!", playerName, StreakLabels[soundIndex]);
}
