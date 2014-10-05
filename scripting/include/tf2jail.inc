#if defined _tf2jail_included
  #endinput
#endif
#define _tf2jail_included

#define JTAG_COLORED	"{community}[TF2Jail]"
#define JTAG	"[TF2Jail]"
#define PLUGIN_VERSION	"5.4.5"

//Door Controls
enum eDoorsMode
{
	OPEN = 0,
	CLOSE,
	LOCK,
	UNLOCK
};

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

/**
 * Returns if the current round is a Last Request day.
 *
 * @param Status		Cell to execute. (OPEN, CLOSE, LOCK, UNLOCK) (If doors are locked, they must be unlocked to open)
 * @return		True on success, false on incompatible map.
 **/
native TF2Jail_ManageCells(eDoorsMode:Status);

//Forwards
/**
 * Called when the Warden has been assigned/created via the plugin or natives.
 *
 * @param client		Client who received Warden.
 * @noreturn
 **/
forward TF2Jail_OnWardenCreated(client);

#pragma deprecated Use TF2Jail_OnWardenCreated(client) instead.
forward Warden_OnWardenCreated(client);

/**
 * Called when the Warden has been removed/retired via the plugin or natives.
 *
 * @param client		Client who lost Warden.
 * @noreturn
 **/
forward TF2Jail_OnWardenRemoved(client);

#pragma deprecated Use TF2Jail_OnWardenRemoved(client) instead.
forward Warden_OnWardenRemoved(client);

/**
 * Called when a last request is about to be executed.
 *
 * @param Handler		String or text called by the Handler in the Last Request configuration file. (Use this to differentiate your custom LRs)
 * @noreturn
 **/
 forward TF2Jail_OnLastRequestExecute(const String:Handler[]);

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
	MarkNativeAsOptional("TF2Jail_ManageCells");
}
#endif