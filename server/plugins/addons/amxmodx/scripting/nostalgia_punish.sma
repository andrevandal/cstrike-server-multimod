#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <reapi>

// Admin punishments (drug, blind, bad aim, levitate, lightning). Effects are
// modelled on "punishments" v0.1 by Radiance
// (forums.alliedmods.net/showthread.php?t=70363), rewritten:
//   - every message is closed with message_end() and sent only to connected humans
//     (upstream's rem_blind() left a message open and crashed the server);
//   - bad aim blocks bullet damage via ReAPI instead of set_user_hitzones;
//   - each effect has a duration (0 = until removed) and re-applies after respawn;
//   - the target is told by center text, chat and sound.

#define PLUGIN "Nostalgia Punish"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

#define PUNISH_ACCESS ADMIN_SLAY
#define DEFAULT_SECONDS 5
#define TICK_SECONDS 0.1
#define TASK_TICK 7300
#define TASK_REAPPLY 7400

enum
{
    FX_DRUG,
    FX_BLIND,
    FX_BADAIM,
    FX_DROP,
    FX_LIGHT,
    FX_COUNT
};

// Effects 0..FX_LASTING-1 last for a duration; FX_LIGHT is instant.
#define FX_LASTING 4

new const FxKey[FX_COUNT][8] = { "drug", "blind", "badaim", "drop", "light" };
new const FxLabel[FX_COUNT][40] = {
    "Drogado (visao esticada)",
    "Cego (tela preta)",
    "Mira ruim (tiros sem dano)",
    "Levitando",
    "Raio"
};
new const FxSound[FX_COUNT][32] = {
    "AQS/laughs2.wav",
    "AQS/shutdown.wav",
    "AQS/yourefunny.wav",
    "AQS/laughs3.wav",
    "ambience/thunder_clap.wav"
};
new const SoundRemoved[] = "buttons/bell1.wav";

#define DUR_COUNT 6
new const DurSeconds[DUR_COUNT] = { 5, 10, 15, 30, 60, 0 };

new bool:g_bOn[MAX_PLAYERS + 1][FX_LASTING];
new Float:g_fEnd[MAX_PLAYERS + 1][FX_LASTING];

new g_iMenuFx[MAX_PLAYERS + 1];
new g_iMenuDur[MAX_PLAYERS + 1];

new g_iSmoke;
new g_iLight;
new g_msgFov;
new g_msgFade;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("amx_punishmenu", "cmd_Menu", PUNISH_ACCESS, "- menu de punicoes");
    register_concmd("amx_punish", "cmd_Punish", PUNISH_ACCESS, "<drug|blind|badaim|drop|light> <nome|#userid|todos> [segundos, 0=ate remover]");
    register_concmd("amx_unpunish", "cmd_Unpunish", PUNISH_ACCESS, "<nome|#userid|todos> [efeito] - remove punicoes");

    RegisterHookChain(RG_CBasePlayer_Spawn, "OnSpawn", true);
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage", false);

    g_msgFov = get_user_msgid("SetFOV");
    g_msgFade = get_user_msgid("ScreenFade");

    set_task(TICK_SECONDS, "Tick", TASK_TICK, _, _, "b");
}

public plugin_precache()
{
    g_iLight = precache_model("sprites/lgtning.spr");
    g_iSmoke = precache_model("sprites/steam1.spr");

    for (new fx = 0; fx < FX_COUNT; fx++)
        precache_sound(FxSound[fx]);

    precache_sound(SoundRemoved);
}

public client_connect(id)
{
    clearPlayer(id);
    g_iMenuDur[id] = 0;
}

public client_disconnected(id)
{
    clearPlayer(id);
}

clearPlayer(id)
{
    for (new fx = 0; fx < FX_LASTING; fx++)
    {
        g_bOn[id][fx] = false;
        g_fEnd[id][fx] = 0.0;
    }
}

// ==========================================
// Effects
// ==========================================
public OnSpawn(const id)
{
    if (!is_user_alive(id) || is_user_bot(id))
        return;

    if (g_bOn[id][FX_DRUG] || g_bOn[id][FX_BLIND])
        set_task(0.3, "Reapply", TASK_REAPPLY + id);
}

public Reapply(taskid)
{
    new id = taskid - TASK_REAPPLY;
    if (!is_user_connected(id))
        return;

    if (g_bOn[id][FX_DRUG])
        sendFov(id, 140);
    if (g_bOn[id][FX_BLIND])
        sendFade(id, true);
}

public OnTakeDamage(const victim, const inflictor, const attacker, Float:damage, bitsDamage)
{
    if (attacker < 1 || attacker > MaxClients || attacker == victim)
        return HC_CONTINUE;

    // Bullets only: the inflictor is the shooter. Grenades and the knife still hurt.
    if (g_bOn[attacker][FX_BADAIM] && inflictor == attacker && get_user_weapon(attacker) != CSW_KNIFE)
    {
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }

    return HC_CONTINUE;
}

public Tick()
{
    new Float:now = get_gametime();

    for (new id = 1; id <= MaxClients; id++)
    {
        if (!is_user_connected(id))
            continue;

        for (new fx = 0; fx < FX_LASTING; fx++)
        {
            if (!g_bOn[id][fx])
                continue;

            if (g_fEnd[id][fx] > 0.0 && now >= g_fEnd[id][fx])
            {
                stopEffect(id, fx);
                notifyRemoved(id, fx);
                continue;
            }

            if (fx == FX_DROP && is_user_alive(id))
            {
                new Float:velocity[3];
                get_entvar(id, var_velocity, velocity);
                velocity[2] = 350.0;
                set_entvar(id, var_velocity, velocity);
            }
        }
    }
}

startEffect(id, fx, seconds)
{
    if (fx == FX_LIGHT)
    {
        lightning(id);
        return;
    }

    g_bOn[id][fx] = true;
    g_fEnd[id][fx] = seconds > 0 ? get_gametime() + float(seconds) : 0.0;

    if (fx == FX_DRUG)
        sendFov(id, 140);
    else if (fx == FX_BLIND)
        sendFade(id, true);
}

stopEffect(id, fx)
{
    g_bOn[id][fx] = false;
    g_fEnd[id][fx] = 0.0;

    if (fx == FX_DRUG)
        sendFov(id, 90);
    else if (fx == FX_BLIND)
        sendFade(id, false);
}

sendFov(id, fov)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    message_begin(MSG_ONE, g_msgFov, _, id);
    write_byte(fov);
    message_end();
}

sendFade(id, bool:blind)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    message_begin(MSG_ONE, g_msgFade, _, id);
    if (blind)
    {
        write_short(1 << 0);
        write_short(1 << 0);
        write_short(1 << 2); // FFADE_STAYOUT
        write_byte(0);
        write_byte(0);
        write_byte(0);
        write_byte(255);
    }
    else
    {
        write_short(1 << 12);
        write_short(0);
        write_short(0); // FFADE_IN
        write_byte(0);
        write_byte(0);
        write_byte(0);
        write_byte(0);
    }
    message_end();
}

lightning(id)
{
    new origin[3];
    get_user_origin(id, origin);
    origin[2] -= 26;

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_coord(origin[0] + 150);
    write_coord(origin[1] + 150);
    write_coord(origin[2] + 400);
    write_short(g_iLight);
    write_byte(1);
    write_byte(5);
    write_byte(2);
    write_byte(20);
    write_byte(30);
    write_byte(200);
    write_byte(200);
    write_byte(200);
    write_byte(200);
    write_byte(200);
    message_end();

    message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
    write_byte(TE_SPARKS);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_SMOKE);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_short(g_iSmoke);
    write_byte(10);
    write_byte(10);
    message_end();

    emit_sound(id, CHAN_AUTO, FxSound[FX_LIGHT], 1.0, ATTN_NORM, 0, PITCH_NORM);
    user_kill(id, 1);
}

// ==========================================
// Notices to the target
// ==========================================
notifyPunished(id, fx, seconds)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    client_print(id, print_center, "PUNICAO: %s", FxLabel[fx]);

    if (seconds > 0 && fx != FX_LIGHT)
        client_print_color(id, print_team_default, "^4[Admin]^1 Voce foi punido: ^3%s^1 por ^4%d^1 segundos.", FxLabel[fx], seconds);
    else if (fx == FX_LIGHT)
        client_print_color(id, print_team_default, "^4[Admin]^1 Voce foi punido: ^3%s^1.", FxLabel[fx]);
    else
        client_print_color(id, print_team_default, "^4[Admin]^1 Voce foi punido: ^3%s^1 ate um admin remover.", FxLabel[fx]);

    client_cmd(id, "spk ^"%s^"", FxSound[fx]);
}

notifyRemoved(id, fx)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    client_print(id, print_center, "Punicao removida");
    client_print_color(id, print_team_default, "^4[Admin]^1 Punicao removida: ^3%s^1.", FxLabel[fx]);
    client_cmd(id, "spk ^"%s^"", SoundRemoved);
}

// ==========================================
// Targeting
// ==========================================
bool:isImmune(admin, target)
{
    return target != admin && (get_user_flags(target) & ADMIN_IMMUNITY) != 0;
}

bool:isEligible(admin, target, fx)
{
    if (!is_user_connected(target) || isImmune(admin, target))
        return false;

    // Instant or physical effects need a living body; screen effects need a human.
    if (fx == FX_LIGHT || fx == FX_DROP)
        return bool:is_user_alive(target);
    if (fx == FX_DRUG || fx == FX_BLIND)
        return !is_user_bot(target);

    return true;
}

// Applies fx to one target; returns 1 if it was applied.
applyTo(admin, target, fx, seconds)
{
    if (!isEligible(admin, target, fx))
        return 0;

    startEffect(target, fx, seconds);
    notifyPunished(target, fx, seconds);
    return 1;
}

announce(admin, fx, seconds, target)
{
    new durTxt[32];
    if (fx == FX_LIGHT)
        durTxt[0] = 0;
    else if (seconds > 0)
        formatex(durTxt, charsmax(durTxt), " (%ds)", seconds);
    else
        copy(durTxt, charsmax(durTxt), " (ate remover)");

    if (target)
        client_print_color(0, print_team_default, "^4[Admin]^1 ^3%n^1 aplicou ^3%s^1%s em ^3%n^1.", admin, FxLabel[fx], durTxt, target);
    else
        client_print_color(0, print_team_default, "^4[Admin]^1 ^3%n^1 aplicou ^3%s^1%s em ^3todos^1.", admin, FxLabel[fx], durTxt);
}

// target 0 = everyone eligible. Returns how many players were punished.
punish(admin, target, fx, seconds)
{
    new count;

    if (target)
    {
        count = applyTo(admin, target, fx, seconds);
    }
    else
    {
        for (new id = 1; id <= MaxClients; id++)
            count += applyTo(admin, id, fx, seconds);
    }

    if (count)
        announce(admin, fx, seconds, target);

    return count;
}

// fx -1 = every lasting effect. Returns how many effects were removed.
unpunish(target, fx)
{
    new count;

    for (new id = 1; id <= MaxClients; id++)
    {
        if (target && id != target)
            continue;
        if (!is_user_connected(id))
            continue;

        for (new e = 0; e < FX_LASTING; e++)
        {
            if ((fx >= 0 && e != fx) || !g_bOn[id][e])
                continue;

            stopEffect(id, e);
            notifyRemoved(id, e);
            count++;
        }
    }

    return count;
}

parseEffect(const name[])
{
    for (new fx = 0; fx < FX_COUNT; fx++)
    {
        if (equali(name, FxKey[fx]))
            return fx;
    }

    return -1;
}

// "todos"/"all"/"@all" -> 0 (everyone); otherwise a player index, or -1 if not found.
resolveTarget(admin, const arg[])
{
    if (equali(arg, "todos") || equali(arg, "all") || equali(arg, "@all"))
        return 0;

    new target = cmd_target(admin, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
    return target ? target : -1;
}

// ==========================================
// Console commands
// ==========================================
public cmd_Punish(id, level, cid)
{
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED;

    new fxName[16], targetArg[32], secondsArg[8];
    read_argv(1, fxName, charsmax(fxName));
    read_argv(2, targetArg, charsmax(targetArg));

    new fx = parseEffect(fxName);
    if (fx < 0)
    {
        console_print(id, "[Punish] Efeito invalido. Use: drug, blind, badaim, drop, light.");
        return PLUGIN_HANDLED;
    }

    new seconds = DEFAULT_SECONDS;
    if (read_argc() >= 4)
    {
        read_argv(3, secondsArg, charsmax(secondsArg));
        seconds = clamp(str_to_num(secondsArg), 0, 3600);
    }

    new target = resolveTarget(id, targetArg);
    if (target < 0)
        return PLUGIN_HANDLED;

    if (!punish(id, target, fx, seconds))
        console_print(id, "[Punish] Nenhum alvo elegivel (imune, morto, ou bot em efeito de tela).");

    return PLUGIN_HANDLED;
}

public cmd_Unpunish(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new targetArg[32], fxName[16];
    read_argv(1, targetArg, charsmax(targetArg));

    new fx = -1;
    if (read_argc() >= 3)
    {
        read_argv(2, fxName, charsmax(fxName));
        fx = parseEffect(fxName);
        if (fx < 0 || fx >= FX_LASTING)
        {
            console_print(id, "[Punish] Efeito invalido. Use: drug, blind, badaim, drop.");
            return PLUGIN_HANDLED;
        }
    }

    new target = resolveTarget(id, targetArg);
    if (target < 0)
        return PLUGIN_HANDLED;

    console_print(id, "[Punish] %d punicao(oes) removida(s).", unpunish(target, fx));
    return PLUGIN_HANDLED;
}

// ==========================================
// Menu: effect -> target. Duration is cycled in the first menu (default 5 s).
// ==========================================
public cmd_Menu(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    ShowEffectMenu(id);
    return PLUGIN_HANDLED;
}

ShowEffectMenu(id)
{
    new menu = menu_create("\y[ ADMIN ] \wPunicoes", "HandleEffectMenu");

    for (new fx = 0; fx < FX_COUNT; fx++)
    {
        new info[4];
        num_to_str(fx, info, charsmax(info));
        menu_additem(menu, FxLabel[fx], info);
    }

    new seconds = DurSeconds[g_iMenuDur[id]];
    new durText[48];
    if (seconds > 0)
        formatex(durText, charsmax(durText), "Duracao: \y%d s \d(clique para mudar)", seconds);
    else
        copy(durText, charsmax(durText), "Duracao: \yate remover \d(clique para mudar)");
    menu_additem(menu, durText, "d");

    menu_additem(menu, "Remover punicoes...", "r");

    menu_setprop(menu, MPROP_EXITNAME, "Sair");
    menu_display(id, menu, 0);
}

public HandleEffectMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    if (info[0] == 'd')
    {
        g_iMenuDur[id] = (g_iMenuDur[id] + 1) % DUR_COUNT;
        ShowEffectMenu(id);
    }
    else if (info[0] == 'r')
    {
        g_iMenuFx[id] = -1;
        ShowTargetMenu(id);
    }
    else
    {
        g_iMenuFx[id] = str_to_num(info);
        ShowTargetMenu(id);
    }

    return PLUGIN_HANDLED;
}

ShowTargetMenu(id)
{
    new fx = g_iMenuFx[id];
    new title[96];
    if (fx >= 0)
        formatex(title, charsmax(title), "\y[ ADMIN ] \w%s \d- escolha o alvo", FxLabel[fx]);
    else
        copy(title, charsmax(title), "\y[ ADMIN ] \wRemover punicao de:");

    new menu = menu_create(title, "HandleTargetMenu");
    menu_additem(menu, "\yTODOS", "0");

    for (new target = 1; target <= MaxClients; target++)
    {
        if (!is_user_connected(target))
            continue;

        new name[32], label[64], info[8];
        get_user_name(target, name, charsmax(name));
        num_to_str(get_user_userid(target), info, charsmax(info));

        if (fx >= 0 && isImmune(id, target))
            formatex(label, charsmax(label), "%s \r(imune)", name);
        else if (is_user_bot(target))
            formatex(label, charsmax(label), "%s \d(bot)", name);
        else
            copy(label, charsmax(label), name);

        menu_additem(menu, label, info);
    }

    menu_setprop(menu, MPROP_EXITNAME, "Voltar");
    menu_display(id, menu, 0);
}

public HandleTargetMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        ShowEffectMenu(id);
        return PLUGIN_HANDLED;
    }

    new info[8], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    new userid = str_to_num(info);
    new target = 0;

    if (userid != 0)
    {
        target = find_player("k", userid);
        if (!target)
        {
            client_print(id, print_chat, "[Punish] O jogador saiu do servidor.");
            ShowTargetMenu(id);
            return PLUGIN_HANDLED;
        }
    }

    new fx = g_iMenuFx[id];

    if (fx < 0)
    {
        client_print(id, print_chat, "[Punish] %d punicao(oes) removida(s).", unpunish(target, -1));
    }
    else if (!punish(id, target, fx, DurSeconds[g_iMenuDur[id]]))
    {
        client_print(id, print_chat, "[Punish] Alvo nao elegivel (imune, morto, ou bot em efeito de tela).");
    }

    ShowTargetMenu(id);
    return PLUGIN_HANDLED;
}
