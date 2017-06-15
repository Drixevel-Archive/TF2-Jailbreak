/**
 * vim: set ts=4 :
 * =============================================================================
 * TF2 Weapon Restrictions
 * Restrict TF2 Weapons to specific types or indexes from a config file
 *
 * Name (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: 1.0.0
 */
#if defined _tf2weaponrestrictions_included_
  #endinput
#endif
#define _tf2weaponrestrictions_included_

// Plugin 1.0 series

/**
 * Load a specific weapon restriction config.
 * 
 * @param restrictionName 	Restriction file to load.  Alternately, "" or "none" will unload all restrictions
 * @noreturn
 * @error					Config doesn't exist or couldn't be found.
 */
native WeaponRestrictions_SetConfig(const String:restrictionName[]);

/**
 * Returns the current weapon restriction config loaded.
 * 
 * @param restrictionName 	String to format. (Will format to empty string or "none" if no config is loaded.
 * @noreturn
 */
native WeaponRestrictions_CurrentConfig(const String:restrictionName[]);

/**
 * Called whenever the main config is loaded or changed.
 * 
 */
forward WeaponRestrictions_OnChanged(const String:restrictionName[]);

/**
 * Callled whenever a player has their weapons set to the config rules.
 * param client		client index
 * 
 */
forward WeaponRestrictions_OnExecuted(client);

public SharedPlugin:__pl_tf2weaponrestrictions = 
{
	name = "tf2weaponrestrictions",
	file = "tf2-weapon-restrictions.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_tf2weaponrestrictions_SetNTVOptional()
{
	MarkNativeAsOptional("WeaponRestrictions_SetConfig");
	MarkNativeAsOptional("WeaponRestrictions_CurrentConfig");
}
#endif
