#include <amxmodx>
#include <amxmisc>
#include <reapi>

#define PLUGIN "PodBot Admin"
#define VERSION "1.2.0"
#define AUTHOR "cstrike-server-multimod"

new g_pCvarInterval;
new g_pCvarChance;
new Float:g_fLastBotChat;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_concmd("pb_add", "command_add", ADMIN_RCON, "- add one PodBot");
    register_concmd("pb_fillserver", "command_fill", ADMIN_RCON, "- fill available slots with PodBots");
    register_concmd("pb_removebots", "command_remove", ADMIN_RCON, "- remove all PodBots");

    // Bot chat throttling:
    // pb_chat_interval: minimum seconds between ANY bot messages server-wide (<= 0 to disable throttling, -1 to mute bots)
    // pb_chat_chance: percentage chance (1-100) that an allowed message actually prints
    g_pCvarInterval = register_cvar("pb_chat_interval", "20.0");
    g_pCvarChance = register_cvar("pb_chat_chance", "30");

    register_clcmd("say", "handle_say");
    register_clcmd("say_team", "handle_say_team");

    // Block flashlight usage for bots completely (humans can still use flashlight)
    RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink", .post = false);
}

public OnPlayerPreThink(const id)
{
    if (is_user_bot(id))
    {
        // Cancel flashlight toggle impulse from bot
        if (get_entvar(id, var_impulse) == 100)
        {
            set_entvar(id, var_impulse, 0);
        }

        // Strip flashlight effect if active on bot
        new effects = get_entvar(id, var_effects);
        if (effects & EF_DIMLIGHT)
        {
            set_entvar(id, var_effects, effects & ~EF_DIMLIGHT);
        }
    }
}

public command_add(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    server_cmd("pb add");
    client_print(id, print_console, "[PodBot] Adding one bot.");
    return PLUGIN_HANDLED;
}

public command_fill(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    server_cmd("pb fillserver");
    client_print(id, print_console, "[PodBot] Filling available slots with bots.");
    return PLUGIN_HANDLED;
}

public command_remove(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    server_cmd("pb removebots");
    client_print(id, print_console, "[PodBot] Removing all bots.");
    return PLUGIN_HANDLED;
}

public handle_say(id)
{
    return filter_bot_chat(id);
}

public handle_say_team(id)
{
    return filter_bot_chat(id);
}

filter_bot_chat(id)
{
    if (!is_user_bot(id))
        return PLUGIN_CONTINUE;

    new Float:interval = get_pcvar_float(g_pCvarInterval);

    // If negative (e.g. -1.0), bot chat is completely muted
    if (interval < 0.0)
        return PLUGIN_HANDLED;

    // If 0.0, throttling is disabled
    if (interval == 0.0)
        return PLUGIN_CONTINUE;

    new Float:now = get_gametime();
    if (now - g_fLastBotChat < interval)
    {
        // Suppress message: another bot spoke too recently (prevents reply chains)
        return PLUGIN_HANDLED;
    }

    new chance = get_pcvar_num(g_pCvarChance);
    if (chance < 100 && random_num(1, 100) > chance)
    {
        // Suppress message: failed probability check
        return PLUGIN_HANDLED;
    }

    // Message allowed: update timestamp
    g_fLastBotChat = now;
    return PLUGIN_CONTINUE;
}
