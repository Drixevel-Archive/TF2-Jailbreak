#pragma semicolon 1

#include <sourcemod>
#include <tf2jail>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "[TF2Jail] Freeday Godmode",
	author = "Keith Warren (Shaders Allen)",
	description = "Gives Freedays Godmode on start & removes on exit.",
	version = "1.0.0",
	url = "http://www.shadersallen.com/"
};

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (TF2Jail_IsFreeday(client))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	if (TF2Jail_IsFreeday(attacker))
	{
		TF2Jail_RemoveFreeday(attacker);
	}
	
	return Plugin_Continue;
}