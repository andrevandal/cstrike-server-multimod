#include <amxmodx>
#include <nostalgia_logic>

#define PLUGIN "Nostalgia Logic Tests"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

new g_iPass;
new g_iFail;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    run_tests();
}

run_tests()
{
    // (minPlayers, humansT, humansCT, bigTeam) -> (sizeT, sizeCT)
    check_team_sizes("team 10/0/0/big1", 10, 0, 0, 1, 5, 4);
    check_team_sizes("team 10/0/0/big2", 10, 0, 0, 2, 4, 5);
    check_team_sizes("team 10/1/0/big1", 10, 1, 0, 1, 5, 5);
    check_team_sizes("team 10/1/0/big2", 10, 1, 0, 2, 5, 5);
    check_team_sizes("team 10/0/1/big1", 10, 0, 1, 1, 5, 5);
    check_team_sizes("team 10/3/0/big1", 10, 3, 0, 1, 6, 6);
    check_team_sizes("team 10/7/0/big1", 10, 7, 0, 1, 8, 8);
    check_team_sizes("team 1/0/0/big1", 1, 0, 0, 1, 0, 0);
    check_team_sizes("team 0/2/0/big1", 0, 2, 0, 1, 2, 1);
    check_team_sizes("team 10/2/2/big2", 10, 2, 2, 2, 6, 7);

    check_classic_map("classic cs_italy", "cs_italy", true);
    check_classic_map("classic de_dust2", "de_dust2", true);
    check_classic_map("classic DE_DUST", "DE_DUST", true);
    check_classic_map("classic as_oilrig", "as_oilrig", false);
    check_classic_map("classic aim_headshot", "aim_headshot", false);
    check_classic_map("classic de", "de", false);
    check_classic_map("classic fy_cs_pool", "fy_cs_pool", false);

    server_print("TEST SUMMARY pass=%d fail=%d", g_iPass, g_iFail);
    server_cmd("quit");
}

check_team_sizes(const name[], minPlayers, humansT, humansCT, bigTeam, wantT, wantCT)
{
    new sizeT, sizeCT;
    nl_team_sizes(minPlayers, humansT, humansCT, bigTeam, sizeT, sizeCT);

    if (sizeT == wantT && sizeCT == wantCT)
    {
        g_iPass++;
        server_print("TEST PASS %s", name);
    }
    else
    {
        g_iFail++;
        server_print("TEST FAIL %s: got %d,%d want %d,%d", name, sizeT, sizeCT, wantT, wantCT);
    }
}

check_classic_map(const name[], const map[], bool:want)
{
    new bool:got = nl_is_classic_map(map);

    if (got == want)
    {
        g_iPass++;
        server_print("TEST PASS %s", name);
    }
    else
    {
        g_iFail++;
        server_print("TEST FAIL %s: got %d want %d", name, _:got, _:want);
    }
}
