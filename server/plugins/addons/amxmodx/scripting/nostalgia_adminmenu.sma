#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <reapi>
#define PLUGIN "Nostalgia Admin Menu"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("adminmenu", "cmd_MainMenu", ADMIN_MENU, "- abre o Admin Menu Nostalgia");
    register_clcmd("say /admin", "cmd_MainMenu");
    register_clcmd("say /menu", "cmd_MainMenu");
    register_clcmd("say_team /admin", "cmd_MainMenu");
    register_clcmd("say_team /menu", "cmd_MainMenu");
    register_clcmd("say /dm", "cmd_ToggleDM");
    register_clcmd("say /deathmatch", "cmd_ToggleDM");
    register_clcmd("say_team /dm", "cmd_ToggleDM");
    register_clcmd("amx_dm", "cmd_ToggleDM", ADMIN_CVAR, "- ativa ou desativa modo Deathmatch");
    register_concmd("amx_money16k", "cmd_Money16k", ADMIN_RCON, "- set every connected player to $16,000");
    RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", .post = true);
}

public cmd_Money16k(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    new count;
    for (new player = 1; player <= MaxClients; player++)
    {
        if (!is_user_connected(player))
            continue;

        cs_set_user_money(player, 16000);
        count++;
    }

    client_print(0, print_chat, "[DM] $16,000 definido para %d jogadores.", count);
    return PLUGIN_HANDLED;
}

public cmd_MainMenu(id)
{
    if (!access(id, ADMIN_MENU))
    {
        client_print(id, print_chat, "[Admin] Voce nao tem permissao para abrir o menu.");
        return PLUGIN_HANDLED;
    }

    ShowMainMenu(id);
    return PLUGIN_HANDLED;
}

ShowMainMenu(id)
{
    new menu = menu_create("\y[ ADMIN NOSTALGIA ] \wMenu Principal", "HandleMainMenu");

    menu_additem(menu, "Gerenciar Bots (PodBot)", "1", ADMIN_RCON);
    menu_additem(menu, "Controle de Partida", "2", ADMIN_CFG);
    menu_additem(menu, "Modos & Diversao", "3", ADMIN_CVAR);
    menu_additem(menu, "Mapas & Votacao", "4", ADMIN_MAP);
    menu_additem(menu, "Gerenciar Jogadores (Kick/Ban/Team)", "5", ADMIN_KICK);

    menu_setprop(menu, MPROP_EXITNAME, "Sair");
    menu_display(id, menu, 0);
}

public HandleMainMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    switch (str_to_num(info))
    {
        case 1: ShowBotsMenu(id);
        case 2: ShowMatchMenu(id);
        case 3: ShowFunMenu(id);
        case 4: ShowMapsMenu(id);
        case 5: ShowPlayersMenu(id);
    }

    return PLUGIN_HANDLED;
}

// ==========================================
// 1. MENU DE BOTS
// ==========================================
ShowBotsMenu(id)
{
    new menu = menu_create("\y[ ADMIN ] \wGerenciar Bots", "HandleBotsMenu");

    menu_additem(menu, "Adicionar 1 Bot (Aleatorio)", "1");
    menu_additem(menu, "Adicionar 1 Bot CT", "2");
    menu_additem(menu, "Adicionar 1 Bot TR", "3");
    menu_additem(menu, "Encher Servidor (Fill)", "4");
    menu_additem(menu, "Remover Todos os Bots", "5");

    new min_skill = get_cvar_num("pb_minbotskill");
    new skill_txt[48];
    if (min_skill < 70)
        copy(skill_txt, charsmax(skill_txt), "Dificuldade: \y[ Facil 65 ]");
    else if (min_skill < 90)
        copy(skill_txt, charsmax(skill_txt), "Dificuldade: \y[ Medio 85 ]");
    else
        copy(skill_txt, charsmax(skill_txt), "Dificuldade: \y[ Hardcore 98 ]");
    menu_additem(menu, skill_txt, "6");

    new Float:chat_int = get_cvar_float("pb_chat_interval");
    new chat_txt[48];
    if (chat_int < 0.0)
        copy(chat_txt, charsmax(chat_txt), "Chat dos Bots: \r[ Silenciado ]");
    else if (chat_int <= 15.0)
        copy(chat_txt, charsmax(chat_txt), "Chat dos Bots: \y[ Normal (15s) ]");
    else if (chat_int <= 30.0)
        copy(chat_txt, charsmax(chat_txt), "Chat dos Bots: \y[ Moderado (30s) ]");
    else
        copy(chat_txt, charsmax(chat_txt), "Chat dos Bots: \y[ Raro (60s) ]");

    menu_additem(menu, chat_txt, "7");
    menu_setprop(menu, MPROP_EXITNAME, "Voltar ao Menu Principal");
    menu_display(id, menu, 0);
}

public HandleBotsMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        ShowMainMenu(id);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    switch (str_to_num(info))
    {
        case 1:
        {
            server_cmd("pb add");
            client_print(id, print_chat, "[PodBot] 1 bot adicionado.");
            ShowBotsMenu(id);
        }
        case 2:
        {
            server_cmd("pb add 2");
            client_print(id, print_chat, "[PodBot] 1 bot CT adicionado.");
            ShowBotsMenu(id);
        }
        case 3:
        {
            server_cmd("pb add 1");
            client_print(id, print_chat, "[PodBot] 1 bot TR adicionado.");
            ShowBotsMenu(id);
        }
        case 4:
        {
            server_cmd("pb fillserver");
            client_print(id, print_chat, "[PodBot] Servidor sendo preenchido com bots.");
            ShowBotsMenu(id);
        }
        case 5:
        {
            server_cmd("pb removebots");
            client_print(id, print_chat, "[PodBot] Todos os bots removidos.");
            ShowBotsMenu(id);
        }
        case 6:
        {
            new min_skill = get_cvar_num("pb_minbotskill");
            if (min_skill < 70)
            {
                set_cvar_num("pb_minbotskill", 80);
                set_cvar_num("pb_maxbotskill", 90);
                client_print(id, print_chat, "[PodBot] Dificuldade alterada para: MEDIO (80-90).");
            }
            else if (min_skill < 90)
            {
                set_cvar_num("pb_minbotskill", 95);
                set_cvar_num("pb_maxbotskill", 100);
                client_print(id, print_chat, "[PodBot] Dificuldade alterada para: HARDCORE (95-100).");
            }
            else
            {
                set_cvar_num("pb_minbotskill", 60);
                set_cvar_num("pb_maxbotskill", 70);
                client_print(id, print_chat, "[PodBot] Dificuldade alterada para: FACIL (60-70).");
            }
            ShowBotsMenu(id);
        }
        case 7:
        {
            new Float:chat_int = get_cvar_float("pb_chat_interval");
            if (chat_int < 0.0)
            {
                set_cvar_float("pb_chat_interval", 15.0);
                set_cvar_num("pb_chat_chance", 40);
                client_print(id, print_chat, "[PodBot] Chat dos bots: NORMAL (15s).");
            }
            else if (chat_int <= 15.0)
            {
                set_cvar_float("pb_chat_interval", 30.0);
                set_cvar_num("pb_chat_chance", 25);
                client_print(id, print_chat, "[PodBot] Chat dos bots: MODERADO (30s).");
            }
            else if (chat_int <= 30.0)
            {
                set_cvar_float("pb_chat_interval", 60.0);
                set_cvar_num("pb_chat_chance", 20);
                client_print(id, print_chat, "[PodBot] Chat dos bots: RARO (60s).");
            }
            else
            {
                set_cvar_float("pb_chat_interval", -1.0);
                client_print(id, print_chat, "[PodBot] Chat dos bots: SILENCIADO.");
            }
            ShowBotsMenu(id);
        }
    }

    return PLUGIN_HANDLED;
}

// ==========================================
// 2. CONTROLE DE PARTIDA
// ==========================================
ShowMatchMenu(id)
{
    new menu = menu_create("\y[ ADMIN ] \wControle de Partida", "HandleMatchMenu");

    menu_additem(menu, "Reiniciar Round (1 segundo)", "1");
    menu_additem(menu, "Reiniciar Round (3 segundos)", "2");

    new ff = get_cvar_num("mp_friendlyfire");
    new ff_txt[48];
    formatex(ff_txt, charsmax(ff_txt), "Fogo Amigo: %s", ff ? "\y[LIGADO]" : "\r[DESLIGADO]");
    menu_additem(menu, ff_txt, "3");

    new alltalk = get_cvar_num("sv_alltalk");
    new alltalk_txt[48];
    formatex(alltalk_txt, charsmax(alltalk_txt), "Alltalk (Voz Livre): %s", alltalk ? "\y[LIGADO]" : "\r[DESLIGADO]");
    menu_additem(menu, alltalk_txt, "4");

    new freeze = get_cvar_num("mp_freezetime");
    new freeze_txt[48];
    formatex(freeze_txt, charsmax(freeze_txt), "Tempo de Congelamento: \y[ %ds ]", freeze);
    menu_additem(menu, freeze_txt, "5");

    menu_additem(menu, "Pausar / Despausar Partida", "6");

    menu_setprop(menu, MPROP_EXITNAME, "Voltar ao Menu Principal");
    menu_display(id, menu, 0);
}

public HandleMatchMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        ShowMainMenu(id);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    switch (str_to_num(info))
    {
        case 1:
        {
            server_cmd("sv_restart 1");
            client_print(id, print_chat, "[Match] Round reiniciado em 1 segundo.");
            ShowMatchMenu(id);
        }
        case 2:
        {
            server_cmd("sv_restart 3");
            client_print(id, print_chat, "[Match] Round reiniciado em 3 segundos.");
            ShowMatchMenu(id);
        }
        case 3:
        {
            new ff = !get_cvar_num("mp_friendlyfire");
            set_cvar_num("mp_friendlyfire", ff);
            client_print(id, print_chat, "[Match] Fogo amigo agora: %s.", ff ? "LIGADO" : "DESLIGADO");
            ShowMatchMenu(id);
        }
        case 4:
        {
            new at = !get_cvar_num("sv_alltalk");
            set_cvar_num("sv_alltalk", at);
            client_print(id, print_chat, "[Match] Alltalk agora: %s.", at ? "LIGADO" : "DESLIGADO");
            ShowMatchMenu(id);
        }
        case 5:
        {
            new freeze = get_cvar_num("mp_freezetime");
            if (freeze == 0) freeze = 3;
            else if (freeze == 3) freeze = 5;
            else freeze = 0;
            set_cvar_num("mp_freezetime", freeze);
            client_print(id, print_chat, "[Match] Freezetime alterado para %d segundos.", freeze);
            ShowMatchMenu(id);
        }
        case 6:
        {
            server_cmd("amx_pause");
            client_print(id, print_chat, "[Match] Estado de pausa alternado.");
            ShowMatchMenu(id);
        }
    }

    return PLUGIN_HANDLED;
}

// ==========================================
// 3. MODOS & DIVERSAO
// ==========================================
ShowFunMenu(id)
{
    new menu = menu_create("\y[ ADMIN ] \wModos & Diversao", "HandleFunMenu");

    new grav = get_cvar_num("sv_gravity");
    new grav_txt[48];
    formatex(grav_txt, charsmax(grav_txt), "Gravidade: \y[ %d ]", grav);
    menu_additem(menu, grav_txt, "1");

    new dm_respawn = get_cvar_num("mp_forcerespawn");
    new dm_ffa = get_cvar_num("mp_freeforall");
    new dm_txt[64];
    if (dm_respawn <= 0)
        copy(dm_txt, charsmax(dm_txt), "Modo Deathmatch (DM): \r[ DESLIGADO ]");
    else if (dm_ffa)
        copy(dm_txt, charsmax(dm_txt), "Modo Deathmatch (DM): \y[ FFA (Todos vs Todos) ]");
    else
        copy(dm_txt, charsmax(dm_txt), "Modo Deathmatch (DM): \y[ TDM (Times CT vs TR) ]");

    menu_additem(menu, dm_txt, "2");
    menu_setprop(menu, MPROP_EXITNAME, "Voltar ao Menu Principal");
    menu_display(id, menu, 0);
}

public HandleFunMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        ShowMainMenu(id);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    switch (str_to_num(info))
    {
        case 1:
        {
            new grav = get_cvar_num("sv_gravity");
            if (grav >= 800) grav = 400;
            else if (grav >= 400) grav = 200;
            else grav = 800;
            set_cvar_num("sv_gravity", grav);
            client_print(id, print_chat, "[Fun] Gravidade ajustada para: %d.", grav);
            ShowFunMenu(id);
        }
        case 2:
        {
            ToggleDMMode();
            ShowFunMenu(id);
        }
    }

    return PLUGIN_HANDLED;
}

// ==========================================
// 4. MAPAS & VOTACAO
// ==========================================
ShowMapsMenu(id)
{
    new menu = menu_create("\y[ ADMIN ] \wMapas & Votacao", "HandleMapsMenu");

    menu_additem(menu, "Abrir Menu de Troca de Mapa", "1", ADMIN_MAP);
    menu_additem(menu, "Forcar Votacao de Mapa Agora (RTV)", "2", ADMIN_VOTE);
    menu_additem(menu, "Cancelar Votacao Atual", "3", ADMIN_VOTE);

    menu_setprop(menu, MPROP_EXITNAME, "Voltar ao Menu Principal");
    menu_display(id, menu, 0);
}

public HandleMapsMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        ShowMainMenu(id);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    switch (str_to_num(info))
    {
        case 1:
        {
            client_cmd(id, "amx_mapmenu");
        }
        case 2:
        {
            server_cmd("gal_startvote");
            client_print(id, print_chat, "[Galileo] Votacao de mapa forcada.");
            ShowMapsMenu(id);
        }
        case 3:
        {
            server_cmd("gal_cancelvote");
            client_print(id, print_chat, "[Galileo] Votacao cancelada.");
            ShowMapsMenu(id);
        }
    }

    return PLUGIN_HANDLED;
}

// ==========================================
// 5. JOGADORES (Atalhos diretos para menus nativos)
// ==========================================
ShowPlayersMenu(id)
{
    new menu = menu_create("\y[ ADMIN ] \wGerenciar Jogadores", "HandlePlayersMenu");

    menu_additem(menu, "Menu de Expulsao (Kick)", "1", ADMIN_KICK);
    menu_additem(menu, "Menu de Banimento (Ban)", "2", ADMIN_BAN);
    menu_additem(menu, "Menu de Slap / Slay", "3", ADMIN_SLAY);
    menu_additem(menu, "Menu de Troca de Time (Team)", "4", ADMIN_LEVEL_A);
    menu_additem(menu, "Punicoes (Drogar, Cegar, Raio, Levitar...)", "5", ADMIN_SLAY);

    menu_setprop(menu, MPROP_EXITNAME, "Voltar ao Menu Principal");
    menu_display(id, menu, 0);
}

public HandlePlayersMenu(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        ShowMainMenu(id);
        return PLUGIN_HANDLED;
    }

    new info[4], name[64], access_flags, callback;
    menu_item_getinfo(menu, item, access_flags, info, charsmax(info), name, charsmax(name), callback);
    menu_destroy(menu);

    switch (str_to_num(info))
    {
        case 1: client_cmd(id, "amx_kickmenu");
        case 2: client_cmd(id, "amx_banmenu");
        case 3: client_cmd(id, "amx_slapmenu");
        case 4: client_cmd(id, "amx_teammenu");
        case 5: client_cmd(id, "amx_punishmenu");
    }

    return PLUGIN_HANDLED;
}
public cmd_ToggleDM(id)
{
    if (!access(id, ADMIN_CVAR))
    {
        client_print(id, print_chat, "[Admin] Voce nao tem permissao para alterar o modo de jogo.");
        return PLUGIN_HANDLED;
    }

    ToggleDMMode();
    return PLUGIN_HANDLED;
}

ToggleDMMode()
{
    new dm_respawn = get_cvar_num("mp_forcerespawn");
    new dm_ffa = get_cvar_num("mp_freeforall");

    if (dm_respawn <= 0)
    {
        // Turn ON TDM
        server_cmd("mp_forcerespawn 1.5; mp_respawn_immunitytime 2; mp_round_infinite 1; mp_free_armor 2; mp_buy_anywhere 1; mp_buytime 9999; mp_refill_bpammo_weapons 2; mp_auto_reload_weapons 1; mp_startmoney 16000; mp_maxmoney 16000; mp_item_staytime 20; mp_freeforall 0; mp_freezetime 0; sv_restart 1");
        new players[MAX_PLAYERS], num;
        get_players(players, num, "ch");
        for (new i = 0; i < num; i++)
        {
            cs_set_user_money(players[i], 16000);
        }
        client_print(0, print_chat, "[DM] Modo Deathmatch ATIVADO (TDM)! Respawn rapido e rounds infinitos.");
    }
    else if (!dm_ffa)
    {
        // Switch to FFA
        server_cmd("mp_freeforall 1; sv_restart 1");
        client_print(0, print_chat, "[DM] Modo Deathmatch FFA ATIVADO! Todos contra todos.");
    }
    else
    {
        // Turn OFF -> Classic
        server_cmd("mp_forcerespawn 0; mp_respawn_immunitytime 0; mp_round_infinite 0; mp_free_armor 0; mp_buy_anywhere 0; mp_buytime 0.25; mp_refill_bpammo_weapons 0; mp_auto_reload_weapons 0; mp_startmoney 800; mp_maxmoney 16000; mp_item_staytime 300; mp_freeforall 0; mp_freezetime 2; sv_restart 1");
        client_print(0, print_chat, "[DM] Modo Deathmatch DESLIGADO. Modo classico restaurado.");
    }
}

public OnPlayerSpawn(const id)
{
    if (!is_user_alive(id))
        return;

    if (get_cvar_num("mp_forcerespawn") > 0)
    {
        cs_set_user_money(id, 16000);
    }
}
