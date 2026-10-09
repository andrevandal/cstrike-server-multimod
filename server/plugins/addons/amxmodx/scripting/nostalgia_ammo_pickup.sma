#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#define PLUGIN "Nostalgia Ammo Pickup"
#define VERSION "1.0.0"
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
    if (!isAmmoPickupWeapon(weapon))
        return HAM_IGNORED;

    new maxAmmo = rg_get_weapon_info(weapon, WI_MAX_ROUNDS);
    if (maxAmmo <= 0)
        return HAM_IGNORED;

    // A dropped firearm becomes a full reserve-ammo pickup, even when its clip is empty.
    rg_set_user_bpammo(id, weapon, maxAmmo);
    set_entvar(weaponbox, var_nextthink, get_gametime() + 0.01);
    return HAM_SUPERCEDE;
}

bool:isAmmoPickupWeapon(const WeaponIdType:weapon)
{
    switch (weapon)
    {
        case WEAPON_P228, WEAPON_SCOUT, WEAPON_XM1014, WEAPON_MAC10, WEAPON_AUG,
             WEAPON_ELITE, WEAPON_FIVESEVEN, WEAPON_UMP45, WEAPON_SG550, WEAPON_GALIL,
             WEAPON_FAMAS, WEAPON_USP, WEAPON_GLOCK18, WEAPON_AWP, WEAPON_MP5N, WEAPON_M249,
             WEAPON_M3, WEAPON_M4A1, WEAPON_TMP, WEAPON_G3SG1, WEAPON_DEAGLE, WEAPON_SG552,
             WEAPON_AK47, WEAPON_P90:
        {
            return true;
        }
    }

    return false;
}
