#if defined _TF2Jail_included
  #endinput
#endif
#define _TF2Jail_included

// NOTE: Requires you check if the player is in-game, alive, etc.

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

//Valid client check
stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching") || IsFakeClient(client) || !IsValidEntity(client))return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}return true;
}