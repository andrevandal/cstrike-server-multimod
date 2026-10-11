#include <amxmodx>
#include <nostalgia_weapons>

#define PLUGIN "Nostalgia Weapons Tests"
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
    check_ammo_weapon("ammo AK47", WEAPON_AK47, true);
    check_ammo_weapon("ammo M4A1", WEAPON_M4A1, true);
    check_ammo_weapon("ammo knife", WEAPON_KNIFE, false);
    check_ammo_weapon("ammo hegrenade", WEAPON_HEGRENADE, false);

    server_print("TEST SUMMARY pass=%d fail=%d", g_iPass, g_iFail);
    server_cmd("quit");
}

check_ammo_weapon(const name[], const WeaponIdType:weapon, bool:want)
{
    if (nw_is_ammo_weapon(weapon) == want)
    {
        g_iPass++;
        server_print("TEST PASS %s", name);
    }
    else
    {
        g_iFail++;
        server_print("TEST FAIL %s: got %d want %d", name, nw_is_ammo_weapon(weapon), want);
    }
}
