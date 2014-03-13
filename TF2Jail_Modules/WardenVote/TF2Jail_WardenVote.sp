#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#include <autoexecconfig>
#include <jackofdesigns>

//TF2Jail Includes
#include <tf2jail>

#define PLUGIN_NAME     "[TF2] TF2Jail - Warden Vote"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "1.0.0"
#define PLUGIN_DESCRIPTION	"Allow clients to vote for the Next Warden based on settings."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

new Handle:ConVars[5] = {INVALID_HANDLE, ...};
new bool:cv_enable = true, bool:cv_roundstart = true, cv_picktype = 1, cv_minimumplayers;

new bool:g_bLateLoad = false;

new g_TotalPages[MAXPLAYERS + 1];
new g_TotalVotes[MAXPLAYERS + 1];

new client_count;
new pages;

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
	AutoExecConfig_SetFile("TF2Jail");
	
	ConVars[0] = AutoExecConfig_CreateConVar("tf2jail_wardenvote_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	ConVars[1] = AutoExecConfig_CreateConVar("sm_tf2jail_wardenvote_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[2] = AutoExecConfig_CreateConVar("sm_tf2jail_wardenvote_roundstart", "1", "Execute vote on arena round start: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[3] = AutoExecConfig_CreateConVar("sm_tf2jail_wardenvote_picktype", "1", "How to pick clients for vote: (1 = Random, 2 = Ascending Indexes)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
	ConVars[4] = AutoExecConfig_CreateConVar("sm_tf2jail_wardenvote_picktype", "7", "Minimum amount of clients to start votes: (0 = Disabled, Maximum amount is 32)", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	
	AutoExecConfig_ExecuteFile();

	for (new i = 0; i < sizeof(ConVars); i++)
	{
		HookConVarChange(ConVars[i], HandleCvars);
	}
	
	HookEvent("arena_round_start", ArenaRoundStart);
	
	RegAdminCmd("sm_startwardenvote", StartWardenVote, ADMFLAG_GENERIC);
	
	AutoExecConfig_CleanFile();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("Steam_SetGameDescription");

	g_bLateLoad = late;
	return APLRes_Success;
}

public OnConfigsExecuted()
{
	cv_enable = GetConVarBool(ConVars[1]);
	cv_roundstart = GetConVarBool(ConVars[2]);
	cv_picktype = GetConVarInt(ConVars[3]);
	cv_minimumplayers = GetConVarInt(ConVars[4]);
	
	if (cv_enable)
	{
		if (g_bLateLoad)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					OnClientPutInServer(i);
				}
			}
			g_bLateLoad = false;
		}
	}
}

public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true)) return;

	new iNewValue = StringToInt(newValue);

	if (cvar == ConVars[0])
	{
		SetConVarString(ConVars[0], PLUGIN_VERSION);
	}
	
	else if (cvar == ConVars[1])
	{
		cv_enable = bool:StringToInt(newValue);
	}

	else if (cvar == ConVars[2])
	{
		cv_roundstart = bool:StringToInt(newValue);
	}
	
	else if (cvar == ConVars[3])
	{
		cv_picktype = iNewValue;
	}
	
	else if (cvar == ConVars[4])
	{
		cv_minimumplayers = iNewValue;
	}
}

public OnClientPutInServer(client)
{
	g_TotalPages[client] = 1;
	g_TotalVotes[client] = 0;
}

public ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_enable || !cv_roundstart) return;
	StartVote();
	return;
}

public Action:StartWardenVote(client, args)
{
	if (!cv_enable) return Plugin_Handled;
	StartVote();
	return Plugin_Handled;
}

StartVote()
{
	client_count = Client_GetCount(true, false);
	
	if (client_count < cv_minimumplayers)
	{
		TF2Jail_Log("Vote for Warden not executed due to lack of clients on the server. (Minimum amount: %i)", cv_minimumplayers);
		return;
	}
	
	pages = client_count / 7;
	
	CPrintToChatAll("%s Vote has been started for Warden.", TAG_COLORED);
	CreateTimer(20.0, WardenVoteEnd, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (TF2Jail_IsWarden(i))
			{
				TF2Jail_WardenUnset(i);
			}
			g_TotalVotes[i] = 0;
			DisplayVoteMenu(i);
		}
	}
	TF2Jail_LockWarden();
}

public Action:WardenVoteEnd(Handle:hTimer)
{
	new winner = Array_FindHighestValue(g_TotalVotes, sizeof(g_TotalVotes), 1);
	if (IsValidClient(winner))
	{
		if (GetClientTeam(winner) != _:TFTeam_Blue)
		{
			ChangeClientTeam(winner, _:TFTeam_Blue);
			TF2_RespawnPlayer(winner);
		}
		TF2Jail_WardenSet(winner);
		TF2Jail_UnlockWarden();
		CPrintToChatAll("%s Votes have ended, %N has won by the majority of votes!", TAG_COLORED, winner);
		TF2Jail_Log("%N has been set as Warden by a majority vote.", winner);
	}
}

DisplayVoteMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler1, MENU_ACTIONS_ALL);
	decl String:ssx[32];
	Format(ssx, sizeof(ssx), "Vote for Warden (Page %i/%i)", g_TotalPages[client], pages);
	SetMenuTitle(menu, ssx);
	UTIL_AddTargetsToMenu2(menu);
	DisplayMenu(menu, client, 20);
}

public MenuHandler1(Handle:menu, MenuAction:action, client, itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				if (g_TotalPages[client] <= pages)
				{
					new String:info[32];
					GetMenuItem(menu, itemNum, info, sizeof(info));
					new iInfo = StringToInt(info);
					new target = GetClientOfUserId(iInfo);
					if (IsValidClient(target))
					{
						g_TotalPages[client]++;
						g_TotalVotes[target]++;
						
						DisplayVoteMenu(client);
					}
				}
				else
				{
					g_TotalPages[client] = 1;
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

stock UTIL_AddTargetsToMenu2(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+12];
	
	new num_clients;
	
	for (new i = 1; i <= 7; i++)
	{
		new Picked;
		switch (cv_picktype)
		{
			case 1: Picked = Client_GetRandom(CLIENTFILTER_INGAMEAUTH);
			case 2: Picked = Client_GetNext(CLIENTFILTER_INGAMEAUTH);
		}
		if (IsValidClient(Picked))
		{
			IntToString(GetClientUserId(Picked), user_id, sizeof(user_id));
			GetClientName(Picked, name, sizeof(name));
			Format(display, sizeof(display), "%s (%s)", name, user_id);
			AddMenuItem(menu, user_id, display);
			num_clients++;
		}
	}
	return num_clients;
}  