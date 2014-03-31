#if defined _tf2jail_included
  #endinput
#endif
#define _tf2jail_included

#define TAG_COLORED	"{community}[TF2Jail]"
#define TAG	"[TF2Jail]"

#tryinclude <tf2attributes>

// NOTE: Requires you check if the player is in-game, alive, etc.

//Natives
/**
 * Warden Check if exists.
 *
 * @return		True on success, false on failure.
 **/
native TF2Jail_WardenActive();

/**
 * Returns if client is Warden.
 *
 * @param client		Client is Warden.
 * @return		True on success, false on failure.
 **/
native TF2Jail_IsWarden(client);

/**
 * Sets a client to Warden.
 *
 * @param client		Client to become Warden.
 * @noreturn
 **/
native TF2Jail_WardenSet(client);

/**
 * Remove the Warden if there is one.
 *
 * @param client		Client to remove Warden.
 * @noreturn
 **/
native TF2Jail_WardenUnset(client);

/**
 * Returns if the client is a Freeday.
 *
 * @param client		Client is Freeday.
 * @return		True on success, false on failure.
 **/
native TF2Jail_IsFreeday(client);

/**
 * Sets a client to Freeday.
 *
 * @param client		Client to give Freeday.
 * @noreturn
 **/
native TF2Jail_GiveFreeday(client);

/**
 * Returns if the client is a Rebel.
 *
 * @param client		Client is Rebel.
 * @return		True on success, false on failure.
 **/
native TF2Jail_IsRebel(client);

/**
 * Marks a client as a Rebel.
 *
 * @param client		Client to mark Rebel.
 * @noreturn
 **/
native TF2Jail_MarkRebel(client);

/**
 * Returns if the cilent is a Freekiller.
 *
 * @param client		Client is Freekiller.
 * @return		True on success, false on failure.
 **/
native TF2Jail_IsFreekiller(client);

/**
 * Marks the client as a Freekiller.
 *
 * @param client		Client to mark Freekiller.
 * @noreturn
 **/
native TF2Jail_MarkFreekiller(client);

/**
 * Strip clients to melee while using TF2Jail Rules. (Keep Weapons, ammo = 0)
 *
 * @param client		Client to Strip to melee.
 * @noreturn
 **/
native TF2Jail_StripToMelee(client);

/**
 * Strip client to melee entirely using TF2Jail rules.
 *
 * @param client		Client to Strip entirely.
 * @noreturn
 **/
native TF2Jail_StripAllWeapons(client);

/**
 * Lock warden from being allowed.
 *
 * @noreturn
 **/
native TF2Jail_LockWarden();

/**
 * Unlock warden from being allowed.
 *
 * @noreturn
 **/
native TF2Jail_UnlockWarden();

/**
 * Log using TF2Jail's logging system/rules.
 *
 * @param log			String or text to log.
 * @param ...			Formatting parameters.
 * @noreturn
 **/
native TF2Jail_Log(const String:log[], any:...);

/**
 * Returns if the current round is a Last Request day.
 *
 * @return		True on success, false on failure.
 **/
native TF2Jail_IsLRRound();

//Forwards
/**
 * Called when the Warden has been assigned/created via the plugin or natives.
 *
 * @noreturn
 **/
forward Warden_OnWardenCreated(client);

/**
 * Called when the Warden has been removed/retired via the plugin or natives.
 *
 * @noreturn
 **/
forward Warden_OnWardenRemoved(client);

public SharedPlugin:__pl_tf2jail = 
{
	name = "tf2jail",
	file = "TF2Jail.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_tf2jail_SetNTVOptional()
{
	MarkNativeAsOptional("TF2Jail_WardenActive");
	MarkNativeAsOptional("TF2Jail_IsWarden");
	MarkNativeAsOptional("TF2Jail_WardenSet");
	MarkNativeAsOptional("TF2Jail_WardenUnset");
	MarkNativeAsOptional("TF2Jail_IsFreeday");
	MarkNativeAsOptional("TF2Jail_GiveFreeday");
	MarkNativeAsOptional("TF2Jail_IsRebel");
	MarkNativeAsOptional("TF2Jail_MarkRebel");
	MarkNativeAsOptional("TF2Jail_IsFreekiller");
	MarkNativeAsOptional("TF2Jail_MarkFreekiller");
	MarkNativeAsOptional("TF2Jail_StripToMelee");
	MarkNativeAsOptional("TF2Jail_StripAllWeapons");
	MarkNativeAsOptional("TF2Jail_LockWarden");
	MarkNativeAsOptional("TF2Jail_UnlockWarden");
	MarkNativeAsOptional("TF2Jail_IsLRRound");
}
#endif