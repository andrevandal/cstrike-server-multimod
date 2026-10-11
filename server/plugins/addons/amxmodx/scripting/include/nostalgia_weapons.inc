#if defined _nostalgia_weapons_included
  #endinput
#endif
#define _nostalgia_weapons_included

#include <reapi>

// Primary and secondary guns that take clip + reserve ammo. Grenades, knife and C4 are excluded.
stock bool:nw_is_ammo_weapon(const WeaponIdType:weapon)
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
