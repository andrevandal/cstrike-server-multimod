#include <amxmodx>
#include <reapi>
#include <nostalgia_weapons>

#define PLUGIN "Nostalgia Buy Ammo"
#define VERSION "1.0.0"
#define AUTHOR "cstrike-server-multimod"

// Set in the pre-hook: did the buyer already hold this weapon before the purchase?
new bool:g_bHadWeapon[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHookChain(RG_BuyWeaponByWeaponID, "OnBuyWeaponPre", false);
    RegisterHookChain(RG_BuyWeaponByWeaponID, "OnBuyWeaponPost", true);
}

public OnBuyWeaponPre(const id, const WeaponIdType:weapon)
{
    g_bHadWeapon[id] = bool:user_has_weapon(id, _:weapon);
    return HC_CONTINUE;
}

// Purchased guns arrive with a full clip and reserve. Re-buying an owned gun is an ammo refill
// handled by BuyGunAmmo, so only a newly acquired weapon is filled here.
public OnBuyWeaponPost(const id, const WeaponIdType:weapon)
{
    if (!nw_is_ammo_weapon(weapon) || g_bHadWeapon[id] || !user_has_weapon(id, _:weapon))
        return HC_CONTINUE;

    new clip = rg_get_weapon_info(weapon, WI_GUN_CLIP_SIZE);
    new reserve = rg_get_weapon_info(weapon, WI_MAX_ROUNDS);

    if (clip > 0)
        rg_set_user_ammo(id, weapon, clip);

    if (reserve > 0)
        rg_set_user_bpammo(id, weapon, reserve);

    return HC_CONTINUE;
}
