#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <nostalgia_weapons>

#define PLUGIN "Nostalgia Ammo Pickup"
#define VERSION "1.1.0"
#define AUTHOR "cstrike-server-multimod"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch");
}

public OnWeaponBoxTouch(const weaponbox, const id)
{
    if (id < 1 || id > MaxClients || !is_user_alive(id) || get_cvar_num("mp_forcerespawn") <= 0)
        return HAM_IGNORED;

    new WeaponIdType:weapon = rg_get_weaponbox_id(weaponbox);
    if (!nw_is_ammo_weapon(weapon))
        return HAM_IGNORED;

    if (!user_has_weapon(id, _:weapon))
        return HAM_IGNORED;

    new maxAmmo = rg_get_weapon_info(weapon, WI_MAX_ROUNDS);
    if (maxAmmo <= 0)
        return HAM_IGNORED;

    // A dropped copy of a weapon the player already carries becomes a full reserve-ammo pickup.
    rg_set_user_bpammo(id, weapon, maxAmmo);
    set_entvar(weaponbox, var_nextthink, get_gametime() + 0.01);
    return HAM_SUPERCEDE;
}
