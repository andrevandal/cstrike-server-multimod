#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <reapi>

#define PLUGIN "PodBot Admin"
#define VERSION "1.2.0"
#define AUTHOR "cstrike-server-multimod"

new g_pCvarInterval;
new g_pCvarChance;
new g_pCvarAutoBalance;
new Float:g_fLastBotChat;
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_concmd("pb_add", "command_add", ADMIN_RCON, "[skill 0-100] [T|CT|ANY] - add one PodBot");
    register_concmd("pb_fillserver", "command_fill", ADMIN_RCON, "[skill 0-100] [T|CT|ANY] - fill available slots with PodBots");
    register_concmd("pb_removebots", "command_remove", ADMIN_RCON, "- remove all PodBots");
    register_concmd("pb_kick", "command_kick", ADMIN_RCON, "<bot name or #userid> - remove one PodBot");
    register_concmd("pb_balance", "command_balance", ADMIN_RCON, "- balance teams with PodBots");
    register_concmd("pb_skill", "command_skill", ADMIN_RCON, "[min 0-100] [max 0-100] - set default bot skill range");

    // Bot chat throttling:
    // pb_chat_interval: minimum seconds between ANY bot messages server-wide (<= 0 to disable throttling, -1 to mute bots)
    // pb_chat_chance: percentage chance (1-100) that an allowed message actually prints
    g_pCvarInterval = register_cvar("pb_chat_interval", "20.0");
    g_pCvarChance = register_cvar("pb_chat_chance", "30");
    g_pCvarAutoBalance = register_cvar("pb_autobalance", "1");
    set_task(5.0, "BalanceTeams", .flags = "b");

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

    new skill, team;
    new args = getBotCreationArgs(id, skill, team);
    if (args < 0)
        return PLUGIN_HANDLED;

    if (args == 0)
    {
        server_cmd("pb add");
        client_print(id, print_console, "[PodBot] Adding one bot using the configured skill range.");
    }
    else
    {
        server_cmd("pb add %d 1 %d 5", skill, team);
        client_print(id, print_console, "[PodBot] Adding skill %d bot.", skill);
    }
    return PLUGIN_HANDLED;
}

public command_fill(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    new skill, team;
    new args = getBotCreationArgs(id, skill, team);
    if (args < 0)
        return PLUGIN_HANDLED;

    if (args == 0)
    {
        server_cmd("pb fillserver");
        client_print(id, print_console, "[PodBot] Filling slots using the configured skill range.");
    }
    else
    {
        server_cmd("pb fillserver %d 1 %d 5", skill, team);
        client_print(id, print_console, "[PodBot] Filling slots with skill %d bots.", skill);
    }
    return PLUGIN_HANDLED;
}

public command_skill(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    if (read_argc() == 1)
    {
        client_print(id, print_console, "[PodBot] Current skill range: %d-%d.", get_cvar_num("pb_minbotskill"), get_cvar_num("pb_maxbotskill"));
        return PLUGIN_HANDLED;
    }

    new minArg[4], maxArg[4];
    read_argv(1, minArg, charsmax(minArg));
    read_argv(2, maxArg, charsmax(maxArg));

    if (!is_str_num(minArg) || !is_str_num(maxArg))
    {
        client_print(id, print_console, "[PodBot] Usage: pb_skill <min 0-100> <max 0-100>.");
        return PLUGIN_HANDLED;
    }

    new minSkill = str_to_num(minArg);
    new maxSkill = str_to_num(maxArg);
    if (minSkill < 0 || maxSkill > 100 || minSkill > maxSkill)
    {
        client_print(id, print_console, "[PodBot] Skill range must be 0-100 and min must not exceed max.");
        return PLUGIN_HANDLED;
    }

    set_cvar_num("pb_minbotskill", minSkill);
    set_cvar_num("pb_maxbotskill", maxSkill);
    client_print(id, print_console, "[PodBot] Default skill range set to %d-%d.", minSkill, maxSkill);
    return PLUGIN_HANDLED;
}

getBotCreationArgs(id, &skill, &team)
{
    new argc = read_argc();
    if (argc == 1)
        return 0;

    if (argc > 3)
    {
        client_print(id, print_console, "[PodBot] Usage: pb_add [skill 0-100] [T|CT|ANY].");
        return -1;
    }

    new skillArg[4];
    read_argv(1, skillArg, charsmax(skillArg));
    if (!is_str_num(skillArg))
    {
        client_print(id, print_console, "[PodBot] Skill must be a number from 0 to 100.");
        return -1;
    }

    skill = str_to_num(skillArg);
    if (skill < 0 || skill > 100)
    {
        client_print(id, print_console, "[PodBot] Skill must be a number from 0 to 100.");
        return -1;
    }

    team = 5;
    if (argc == 3)
    {
        new teamArg[4];
        read_argv(2, teamArg, charsmax(teamArg));

        if (equali(teamArg, "T"))
            team = 1;
        else if (equali(teamArg, "CT"))
            team = 2;
        else if (!equali(teamArg, "ANY"))
        {
            client_print(id, print_console, "[PodBot] Team must be T, CT, or ANY.");
            return -1;
        }
    }

    return 1;
}

public command_remove(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    server_cmd("pb removebots");
    client_print(id, print_console, "[PodBot] Removing all bots.");
    return PLUGIN_HANDLED;
}

public command_kick(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new targetArg[32];
    read_argv(1, targetArg, charsmax(targetArg));

    new target = cmd_target(id, targetArg);
    if (!target)
        return PLUGIN_HANDLED;

    if (!is_user_bot(target))
    {
        client_print(id, print_console, "[PodBot] Target is not a bot.");
        return PLUGIN_HANDLED;
    }

    server_cmd("pb remove #%d", get_user_userid(target));
    client_print(id, print_console, "[PodBot] Removing %n.", target);
    return PLUGIN_HANDLED;
}

public command_balance(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    balanceTeams(true);
    client_print(id, print_console, "[PodBot] Team balance checked.");
    return PLUGIN_HANDLED;
}

public BalanceTeams()
{
    balanceTeams(false);
}

balanceTeams(const bool:force)
{
    if ((!force && !get_pcvar_num(g_pCvarAutoBalance)) || get_cvar_num("mp_freeforall"))
        return;

    new tPlayers, ctPlayers;
    new tBot, ctBot;

    for (new id = 1; id <= MaxClients; id++)
    {
        if (!is_user_connected(id))
            continue;

        switch (cs_get_user_team(id))
        {
            case CS_TEAM_T:
            {
                tPlayers++;
                if (is_user_bot(id))
                    tBot = id;
            }
            case CS_TEAM_CT:
            {
                ctPlayers++;
                if (is_user_bot(id))
                    ctBot = id;
            }
        }
    }

    if (abs(tPlayers - ctPlayers) < 2)
        return;

    new targetTeam;
    new botToRemove;
    if (tPlayers > ctPlayers)
    {
        targetTeam = 2;
        botToRemove = tBot;
    }
    else
    {
        targetTeam = 1;
        botToRemove = ctBot;
    }

    if (botToRemove)
    {
        server_cmd("pb remove #%d", get_user_userid(botToRemove));
        return;
    }

    new minSkill = get_cvar_num("pb_minbotskill");
    new maxSkill = get_cvar_num("pb_maxbotskill");
    server_cmd("pb add %d 1 %d 5", (minSkill + maxSkill) / 2, targetTeam);
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
