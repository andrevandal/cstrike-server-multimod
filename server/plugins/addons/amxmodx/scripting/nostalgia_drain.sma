#include <amxmodx>
#include <amxmisc>

// Graceful restart. The entrypoint wrapper touches DRAIN_FLAG on SIGTERM
// (Coolify/compose redeploy). This plugin then:
//   1. announces the restart in chat and sound,
//   2. runs a Galileo map vote that only picks the next map (-nochange: Galileo
//      never freezes players, shows the scoreboard or changes level),
//   3. saves the winner to NEXT_MAP_FILE (kept in /state by the entrypoint, which
//      starts the next boot on that map), counts down 10 s and quits.
// Players stay in the game until the final countdown ends: the server never dies
// while a client is loading a map. If nobody is online, or DRAIN_SECONDS pass
// without a vote result, it quits right away. The container's stop_grace_period
// must exceed DRAIN_SECONDS.

#define PLUGIN "Nostalgia Drain"
#define VERSION "2.0.0"
#define AUTHOR "cstrike-server-multimod"

// AMXX file natives resolve paths relative to the mod dir (cstrike/), so the
// flag lives there. The entrypoint wrapper writes "$CSTRIKE/nostalgia-drain".
#define DRAIN_FLAG "nostalgia-drain"
// The entrypoint links this path into /state and reads it on the next boot.
#define NEXT_MAP_FILE "nostalgia-next-map"
#define DRAIN_SECONDS 300
#define VOTE_DELAY 10.0
#define RESTART_SECONDS 10

new bool:g_draining;
new bool:g_voteStarted;
new g_remaining;
new g_countdown;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    set_task(2.0, "checkDrainFlag", 0, _, _, "b");
}

public checkDrainFlag()
{
    if (g_draining || !file_exists(DRAIN_FLAG))
    {
        return;
    }

    g_draining = true;

    if (isServerEmpty())
    {
        quitServer();
        return;
    }

    client_cmd(0, "spk ^"buttons/bell1.wav^"");
    client_print_color(0, print_team_default, "^4[Servidor]^1 Reiniciando para atualizar. Votem o proximo mapa; o servidor volta logo depois.");

    g_remaining = DRAIN_SECONDS;
    set_task(VOTE_DELAY, "startDrainVote");
    set_task(1.0, "drainTick", 0, _, _, "b");
}

public startDrainVote()
{
    // The server is going down, so "Stay Here" cannot be an answer. Galileo re-reads
    // this cvar when a vote starts.
    set_cvar_num("gal_extendmap_allow_stay", 0);

    // Galileo writes the winner to amx_nextmap when the vote ends. Blank it first so
    // the map left over from before the vote is never mistaken for the result.
    set_cvar_string("amx_nextmap", "");
    g_voteStarted = true;

    // -nochange: set the next map and nothing else. "-now" is rejected by this
    // Galileo build (its argument parser never matches it).
    server_cmd("gal_startvote -nochange");
}

public drainTick()
{
    if (isServerEmpty() || --g_remaining <= 0)
    {
        quitServer();
        return;
    }

    if (g_countdown > 0)
    {
        if (--g_countdown == 0)
        {
            quitServer();
            return;
        }

        client_cmd(0, "spk ^"buttons/blip1.wav^"");
        client_print(0, print_center, "Reiniciando em %d", g_countdown);
    }
    else if (g_voteStarted)
    {
        checkVoteResult();
    }
}

checkVoteResult()
{
    new map[32];
    get_cvar_string("amx_nextmap", map, charsmax(map));

    if (!map[0] || !is_map_valid(map))
    {
        return;
    }

    saveNextMap(map);

    g_countdown = RESTART_SECONDS;
    client_cmd(0, "spk ^"buttons/bell1.wav^"");
    client_print_color(0, print_team_default, "^4[Servidor]^1 Proximo mapa: ^3%s^1. Reiniciando em ^3%d^1 segundos.", map, RESTART_SECONDS);
}

saveNextMap(const map[])
{
    new file = fopen(NEXT_MAP_FILE, "wt");

    if (!file)
    {
        log_amx("Could not write %s; the server will restart on its default map", NEXT_MAP_FILE);
        return;
    }

    fputs(file, map);
    fclose(file);
}

// get_playersnum() counts bots too; the server is "empty" with only bots left.
bool:isServerEmpty()
{
    return get_playersnum_ex(GetPlayers_ExcludeBots) == 0;
}

quitServer()
{
    server_cmd("quit");
}
