#if defined _tf2jail_included
  #endinput
#endif
#define _tf2jail_included

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
native bool TF2Jail_WardenActive();

/**
 * Returns if client is Warden.
 *
 * @param client		Client is Warden.
 * @return		True on success, false on failure.
 **/
native bool TF2Jail_IsWarden(int client);

/**
 * Sets a client to Warden.
 *
 * @param client		Client to become Warden.
 * @noreturn
 **/
native void TF2Jail_WardenSet(int client);

/**
 * Remove the Warden if there is one.
 *
 * @param client		Client to remove Warden.
 * @noreturn
 **/
native void TF2Jail_WardenUnset(int client);

/**
 * Returns if the client is a Freeday.
 *
 * @param client		Client is Freeday.
 * @return		True on success, false on failure.
 **/
native bool TF2Jail_IsFreeday(int client);

/**
 * Sets a client to Freeday.
 *
 * @param client		Client to give Freeday.
 * @noreturn
 **/
native void TF2Jail_GiveFreeday(int client);

/**
 * Removes a client's Freeday.
 *
 * @param client		Client to remove Freeday from.
 * @noreturn
 **/
native void TF2Jail_RemoveFreeday(int client);

/**
 * Returns if the client is a Rebel.
 *
 * @param client		Client is Rebel.
 * @return		True on success, false on failure.
 **/
native bool TF2Jail_IsRebel(int client);

/**
 * Marks a client as a Rebel.
 *
 * @param client		Client to mark Rebel.
 * @noreturn
 **/
native void TF2Jail_MarkRebel(int client);

/**
 * Returns if the cilent is a Freekiller.
 *
 * @param client		Client is Freekiller.
 * @return		True on success, false on failure.
 **/
native bool TF2Jail_IsFreekiller(int client);

/**
 * Marks the client as a Freekiller.
 *
 * @param client		Client to mark Freekiller.
 * @noreturn
 **/
native void TF2Jail_MarkFreekiller(int client);

/**
 * Strip clients to melee while using TF2Jail Rules. (Keep Weapons, ammo = 0)
 *
 * @param client		Client to Strip to melee.
 * @noreturn
 **/
native void TF2Jail_StripToMelee(int client);

/**
 * Strip client to melee entirely using TF2Jail rules.
 *
 * @param client		Client to Strip entirely.
 * @noreturn
 **/
native void TF2Jail_StripAllWeapons(int client);

/**
 * Lock warden from being allowed.
 *
 * @noreturn
 **/
native void TF2Jail_LockWarden();

/**
 * Unlock warden from being allowed.
 *
 * @noreturn
 **/
native void TF2Jail_UnlockWarden();

/**
 * Log using TF2Jail's logging system/rules.
 *
 * @param log			String or text to log.
 * @param ...			Formatting parameters.
 * @noreturn
 **/
native void TF2Jail_Log(const char[] log, any ...);

/**
 * Returns if the current round is a Last Request day.
 *
 * @return		True on success, false on failure.
 **/
native bool TF2Jail_IsLRRound();

/**
 * Returns if the current round is a Last Request day.
 *
 * @param Status		Cell to execute. (OPEN, CLOSE, LOCK, UNLOCK) (If doors are locked, they must be unlocked to open)
 * @return		True on success, false on incompatible map.
 **/
native bool TF2Jail_ManageCells(eDoorsMode Status);

//Forwards
/**
 * Called when the Warden has been assigned/created via the plugin or natives.
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnWardenCreated(int client);

#pragma deprecated Use TF2Jail_OnWardenCreated(client) instead.
forward Warden_OnWardenCreated(client);

/**
 * Called when the Warden has been removed/retired via the plugin or natives.
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnWardenRemoved(int client);

#pragma deprecated Use TF2Jail_OnWardenRemoved(client) instead.
forward Warden_OnWardenRemoved(client);

/**
 * Called when a last request is about to be executed.
 *
 * @param Handler		String or text called by the Handler in the Last Request configuration file. (Use this to differentiate your custom LRs)
 * @noreturn
 **/
 forward void TF2Jail_OnLastRequestExecute(const char[] Handler);
 
 /**
 * Called when a client is given Freeday. (post)
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnFreedayGiven(int client);

 /**
 * Called when a client has been removed from Freeday. (post)
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnFreedayRemoved(int client);

 /**
 * Called when a client has marked as a Freekiller. (post)
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnFreekillerGiven(int client);

 /**
 * Called when a client has been cleared from Freekiller. (post)
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnFreekillerRemoved(int client);

 /**
 * Called when a client has marked as a Rebel. (post)
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnRebelGiven(int client);

 /**
 * Called when a client has been cleared from Rebel. (post)
 *
 * @param client		Client Index
 * @noreturn
 **/
forward void TF2Jail_OnRebelRemoved(int client);

#if !defined REQUIRE_PLUGIN
public __pl_tf2jail_SetNTVOptional()
{
	MarkNativeAsOptional("TF2Jail_WardenActive");
	MarkNativeAsOptional("TF2Jail_IsWarden");
	MarkNativeAsOptional("TF2Jail_WardenSet");
	MarkNativeAsOptional("TF2Jail_WardenUnset");
	MarkNativeAsOptional("TF2Jail_IsFreeday");
	MarkNativeAsOptional("TF2Jail_GiveFreeday");
	MarkNativeAsOptional("TF2Jail_RemoveFreeday");
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

public SharedPlugin __pl_tf2jail = 
{
	name = "tf2jail",
	file = "TF2Jail.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};