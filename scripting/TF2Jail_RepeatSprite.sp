#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>

//TF2Jail Includes
#include <tf2jail>

#define PLUGIN_NAME     "[TF2] TF2Jail - Repeat Sprite"
#define PLUGIN_AUTHOR   "Keith Warren(Shaders Allen)"
#define PLUGIN_DESCRIPTION	"Spawns a sprite above players heads who say 'Repeat' in chat."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_CONTACT  "http://www.shadersallen.com/"

#define JTAG "[RS]"
#define JTAG_COLORED "{red}[RS]{default}"

new g_EntList[MAXPLAYERS + 1];
new Handle:g_hCooldown[MAXPLAYERS + 1];
new g_hMaxPerRound[MAXPLAYERS + 1];
new gVelocityOffset;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public OnPluginStart()
{
	File_LoadTranslations("common.phrases");
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_changeclass", ChangeClass, EventHookMode_Pre);
	HookEvent("teamplay_round_win", RoundEnd);
	
	RegConsoleCmd("sm_r", ExecuteRepeat);
	
	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_hCooldown[i] = INVALID_HANDLE;
		}
	}
}

public RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ClearTimer(g_hCooldown[i]);
		}
	}
}

public OnClientPutInServer(client)
{
	g_hMaxPerRound[client] = 0;
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	/*if (StrContains(sArgs, "!r", false) || StrContains(sArgs, "/r", false) || StrContains(sArgs, "repeat", false))
	{
		return Plugin_Handled;
	}*/
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	ClearTimer(g_hCooldown[client]);
	KillSprite(client);
}

public Action:ExecuteRepeat(client, args)
{
	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%s You must be alive to call repeats.", JTAG);
		return Plugin_Handled;
	}
	
	if (g_hMaxPerRound[client] <= 0)
	{
		CPrintToChat(client, "You cannot repeat any more, you have used all of your repeats this life.");
		return Plugin_Handled;
	}
		
	if (g_hCooldown[client] != INVALID_HANDLE)
	{
		CPrintToChat(client, "You cannot repeat at this time.");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) != _:TFTeam_Red)
	{
		CPrintToChat(client, "You are not a prisoner, you cannot call repeats.");
		return Plugin_Handled;
	}

	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		if (g_EntList[client] <= 0)
		{
			CreateSprite(client, "materials/custom/jailbreak/repeat.vtf", 25.0);
			EmitSoundToAll("jailbreak/Repeat.wav", client);
			
			CPrintToChatAll("%s %N: REPEAT!", JTAG_COLORED, client);
			
			g_hCooldown[client] = CreateTimer(25.0, CanRepeat, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			g_hMaxPerRound[client]--;
			CPrintToChat(client, "%s You have %i repeats left this life.", JTAG_COLORED, g_hMaxPerRound[client]);
		}
	}
	return Plugin_Handled;
}

public OnMapStart()
{
	PrecacheGeneric("materials/custom/jailbreak/repeat.vmt", true);
	AddFileToDownloadsTable("materials/custom/jailbreak/repeat.vmt");
	PrecacheGeneric("materials/custom/jailbreak/repeat.vtf", true);
	AddFileToDownloadsTable("materials/custom/jailbreak/repeat.vtf");
	AddFileToDownloadsTable("sound/jailbreak/Repeat.wav");
	PrecacheSound("jailbreak/Repeat.wav", true);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client))
	{
		g_hMaxPerRound[client] = 3;
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillSprite(client);
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillSprite(client);
}

public Action:RemoveSprite(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		KillSprite(client);
	}
}

public Action:CanRepeat(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	
	if (IsClientInGame(client))
	{
		g_hCooldown[client] = INVALID_HANDLE;
		CPrintToChat(client, "You can now repeat again.");
	}
}

CreateSprite(client, String:sprite[], Float:offset)
{
	new String:szTemp2[64]; 
	Format(szTemp2, sizeof(szTemp2), "client%i", client);
	DispatchKeyValue(client, "targetname", szTemp2);

	new Float:vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "repeat_spr");
		DispatchKeyValue(ent, "parentname", szTemp2);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

		g_EntList[client] = ent;
		
		CreateTimer(3.5, RemoveSprite, GetClientUserId(client));
	}
}

KillSprite(client)
{
	if (g_EntList[client] > 0 && IsValidEntity(g_EntList[client]))
	{
		AcceptEntityInput(g_EntList[client], "kill");
		g_EntList[client] = 0;
	}
}

public OnGameFrame()
{
	new ent, Float:vOrigin[3], Float:vVelocity[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		if ((ent = g_EntList[i]) > 0)
		{
			if (!IsValidEntity(ent))
			{
				g_EntList[i] = 0;
			}
			else if ((ent = EntRefToEntIndex(ent)) > 0)
			{
				GetClientEyePosition(i, vOrigin);
				vOrigin[2] += 25.0;
				GetEntDataVector(i, gVelocityOffset, vVelocity);
				TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
			}
		}
	}
}

void ClearTimer(Handle& timer)
{
	if (timer != null)
	{
		KillTimer(timer);
		timer = null;
	}
}