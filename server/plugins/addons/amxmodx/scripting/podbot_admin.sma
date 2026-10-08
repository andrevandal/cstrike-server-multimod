#include <amxmodx>
#include <amxmisc>

#define PLUGIN "PodBot Admin"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_concmd("pb_add", "command_add", ADMIN_RCON, "- add one PodBot")
    register_concmd("pb_fillserver", "command_fill", ADMIN_RCON, "- fill available slots with PodBots")
    register_concmd("pb_removebots", "command_remove", ADMIN_RCON, "- remove all PodBots")
}

public command_add(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED

    server_cmd("pb add")
    client_print(id, print_console, "[PodBot] Adding one bot.")
    return PLUGIN_HANDLED
}

public command_fill(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED

    server_cmd("pb fillserver")
    client_print(id, print_console, "[PodBot] Filling available slots with bots.")
    return PLUGIN_HANDLED
}

public command_remove(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED

    server_cmd("pb removebots")
    client_print(id, print_console, "[PodBot] Removing all bots.")
    return PLUGIN_HANDLED
}
