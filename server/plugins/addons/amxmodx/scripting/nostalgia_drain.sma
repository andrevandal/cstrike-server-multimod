#include <amxmodx>
#include <amxmisc>

// Graceful restart. The entrypoint wrapper touches DRAIN_FLAG on SIGTERM
// (Coolify/compose redeploy). This plugin then:
//   1. announces the restart in chat, center text and sound,
//   2. starts a Galileo map vote (the vote's winner becomes the next map),
//   3. quits as soon as the next map loads, so the restarted container
//      comes up with the new image.
// If nobody is online, or DRAIN_SECONDS pass without a map change, it quits
// right away. The container's stop_grace_period must exceed DRAIN_SECONDS.

#define PLUGIN "Nostalgia Drain"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

// AMXX file natives resolve paths relative to the mod dir (cstrike/), so the
// flag lives there. The entrypoint wrapper writes "$CSTRIKE/nostalgia-drain".
#define DRAIN_FLAG "nostalgia-drain"
#define DRAIN_SECONDS 300
#define VOTE_DELAY 10.0

new bool:g_draining;
new g_remaining;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    set_task(2.0, "checkDrainFlag", 0, _, _, "b");
}

public plugin_cfg()
{
    // Fresh map after a drain: the process is going down.
    if (file_exists(DRAIN_FLAG))
    {
        server_cmd("quit");
    }
}

public checkDrainFlag()
{
    if (g_draining || !file_exists(DRAIN_FLAG))
    {
        return;
    }

    g_draining = true;

    // get_playersnum() counts bots too; the server is "empty" with only bots left.
    if (get_playersnum_ex(GetPlayers_ExcludeBots) == 0)
    {
        server_cmd("quit");
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
    // No argument: Galileo changes map when the vote ends. "-now" is rejected
    // by this Galileo build (its argument parser never matches it).
    server_cmd("gal_startvote");
}

public drainTick()
{
    g_remaining--;

    if (g_remaining <= 0)
    {
        server_cmd("quit");
        return;
    }

    if (g_remaining <= 10)
    {
        client_cmd(0, "spk ^"buttons/blip1.wav^"");
        client_print(0, print_center, "Reiniciando em %d", g_remaining);
    }
    else if (g_remaining % 30 == 0)
    {
        client_print_color(0, print_team_default, "^4[Servidor]^1 Reinicio em ^3%d^1 segundos.", g_remaining);
    }
}
