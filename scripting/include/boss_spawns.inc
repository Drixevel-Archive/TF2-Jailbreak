#if defined _boss_spawns_included
  #endinput
#endif
#define _boss_spawns_included

/**
 * Spawns a Hatman on the map. (Horsemann)
 *
 * @param client		Client spawning the boss. (0 = Console)
 * @param X				Float value for X parameter of spawn location.
 * @param Y				Float value for Y parameter of spawn location.
 * @param Z				Float value for Z parameter of spawn location.
 * @param scale			Float value for the scale of the boss.
 * @param glow			True if boss should glow, false if not.
 * @param spew			True if to log, reply & show activity, false otherwise.
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnHatman(client, Float:X = 0.0, Float:Y = 0.0, Float:Z = 0.0, Float:scale = 1.0, bool:glow = false, bool:spew = true);

/**
 * Spawns an Eyeboss on the map. (Monoculus)
 *
 * @param client		Client spawning the boss. (0 = Console)
 * @param X				Float value for X parameter of spawn location.
 * @param Y				Float value for Y parameter of spawn location.
 * @param Z				Float value for Z parameter of spawn location.
 * @param scale			Float value for the scale of the boss.
 * @param glow			True if boss should glow, false if not.
 * @param spew			True if to log, reply & show activity, false otherwise.
 * @param type			Type of Eyeboss: (0 = Normal, 1 = Red, 2 = Blue)
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnEyeboss(client, Float:X = 0.0, Float:Y = 0.0, Float:Z = 0.0, Float:scale = 1.0, bool:glow = false, bool:spew = true, type = 0);

/**
 * Spawns Merasmus on the map.
 *
 * @param client		Client spawning the boss. (0 = Console)
 * @param X				Float value for X parameter of spawn location.
 * @param Y				Float value for Y parameter of spawn location.
 * @param Z				Float value for Z parameter of spawn location.
 * @param scale			Float value for the scale of the boss.
 * @param glow			True if boss should glow, false if not.
 * @param spew			True if to log, reply & show activity, false otherwise.
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnMerasmus(client, Float:X = 0.0, Float:Y = 0.0, Float:Z = 0.0, Float:scale = 1.0, bool:glow = false, bool:spew = true);

/**
 * Spawns a Skeleton on the map.
 *
 * @param client		Client spawning the boss. (0 = Console)
 * @param X				Float value for X parameter of spawn location.
 * @param Y				Float value for Y parameter of spawn location.
 * @param Z				Float value for Z parameter of spawn location.
 * @param scale			Float value for the scale of the boss.
 * @param glow			True if boss should glow, false if not.
 * @param spew			True if to log, reply & show activity, false otherwise.
 * @param type			Type of Skeleton: (0 = Green, 1 = Red, 2 = Blue)
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnSkeleton(client, Float:X = 0.0, Float:Y = 0.0, Float:Z = 0.0, Float:scale = 1.0, bool:glow = false, bool:spew = true, type = 0);

/**
 * Spawns the Skeleton King on the map.
 *
 * @param client		Client spawning the boss. (0 = Console)
 * @param X				Float value for X parameter of spawn location.
 * @param Y				Float value for Y parameter of spawn location.
 * @param Z				Float value for Z parameter of spawn location.
 * @param glow			True if boss should glow, false if not.
 * @param spew			True if to log, reply & show activity, false otherwise.
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnSkeletonKing(client, Float:X = 0.0, Float:Y = 0.0, Float:Z = 0.0, bool:glow = false, bool:spew = true);

/**
 * Spawns the Ghost on the map.
 *
 * @param client		Client spawning the boss. (0 = Console)
 * @param X				Float value for X parameter of spawn location.
 * @param Y				Float value for Y parameter of spawn location.
 * @param Z				Float value for Z parameter of spawn location.
 * @param glow			True if boss should glow, false if not.
 * @param spew			True if to log, reply & show activity, false otherwise.
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnGhost(client, Float:X = 0.0, Float:Y = 0.0, Float:Z = 0.0, bool:glow = false, bool:spew = true);

public SharedPlugin:__pl_boss_spawns = 
{
	name = "BossSpawns",
	file = "BossSpawns.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_boss_spawns_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_SpawnHatman");
	MarkNativeAsOptional("TF2_SpawnEyeboss");
	MarkNativeAsOptional("TF2_SpawnMerasmus");
	MarkNativeAsOptional("TF2_SpawnSkeleton");
	MarkNativeAsOptional("TF2_SpawnSkeletonKing");
	MarkNativeAsOptional("TF2_SpawnGhost");
}
#endif
