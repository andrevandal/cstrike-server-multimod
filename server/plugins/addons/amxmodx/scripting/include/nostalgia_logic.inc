#if defined _nostalgia_logic_included
  #endinput
#endif
#define _nostalgia_logic_included

#include <amxmodx>

// Target team sizes (humans + bots) for PodBot balancing. Team 1 = T, 2 = CT.
// bigTeam receives the extra player when the total is odd.
stock nl_team_sizes(minPlayers, humansT, humansCT, bigTeam, &sizeT, &sizeCT)
{
    new total = max(minPlayers - 1, 0) + humansT + humansCT;
    sizeT = total / 2;
    sizeCT = total / 2;
    if (bigTeam == 1)
    {
        sizeT += total % 2;
    }
    else
    {
        sizeCT += total % 2;
    }

    sizeT = max(sizeT, humansT);
    sizeCT = max(sizeCT, humansCT);
    if (sizeT - sizeCT >= 2)
    {
        sizeCT = sizeT - 1;
    }
    else if (sizeCT - sizeT >= 2)
    {
        sizeT = sizeCT - 1;
    }
}

stock bool:nl_is_classic_map(const map[])
{
    return equali(map, "cs_", 3) || equali(map, "de_", 3);
}
