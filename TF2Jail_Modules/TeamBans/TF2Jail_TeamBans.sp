/*
	https://forums.alliedmods.net/showthread.php?p=1544101
	
	Cheers to Databomb for his plugin code, I basically just took it and fixed it up for TF2.
	All the same rules and licensing apply.
*/

#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#include <autoexecconfig>
#include <jackofdesigns>

//TF2Jail Includes
#include <tf2jail>

#undef REQUIRE_EXTENSIONS
#tryinclude <clientprefs>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <adminmenu>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME     "[TF2] Jailbreak - Team Bans"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "1.0.5"
#define PLUGIN_DESCRIPTION	"Manage bans for one or multiple teams."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

new Handle:ConVars[8] = {INVALID_HANDLE, ...};
new bool:cv_Enabled = true, String:cv_DenySound[PLATFORM_MAX_PATH], String:cv_JoinBanMsg[100], 
String:cv_DatabasePrefix[64], String:cv_DatabaseConfigEntry[64], bool:cv_Debugging = true,
bool:cv_SQLProgram = true;

new Handle:cBan_Blue = INVALID_HANDLE;
new Handle:cBan_Red = INVALID_HANDLE;
new Handle:Handles[MAXPLAYERS+1];
new Handle:TopMenu = INVALID_HANDLE;
new Handle:DNames = INVALID_HANDLE;
new Handle:DSteamIDs = INVALID_HANDLE;
new Handle:CP_DataBase = INVALID_HANDLE;
new Handle:BanDatabase = INVALID_HANDLE;
new iCookieIndex = 0;
new bool:bAuthIdNativeExists = false;
new Handle:TimedBanLocalList = INVALID_HANDLE;
new LocalTimeRemaining[MAXPLAYERS+1];
new Handle:TimedBanSteamList = INVALID_HANDLE;
new GuardBanTargetUserId[MAXPLAYERS+1];
new GuardBanTimeLength[MAXPLAYERS+1];
new String:sLogTableName[32];
new String:sTimesTableName[32];

new bool:RoundActive = false;

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
	File_LoadTranslations("TF2Jail_TeamBans.phrases");
	
	AutoExecConfig_SetFile("TF2Jail_TeamBans");

	ConVars[0] = AutoExecConfig_CreateConVar("tf2jail_teambans_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ConVars[1] = AutoExecConfig_CreateConVar("sm_jail_teambans_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN);
	ConVars[2] = AutoExecConfig_CreateConVar("sm_jail_teambans_denysound", "", "Sound file to play when denied. (Relative to the sound folder)",FCVAR_PLUGIN);
	ConVars[3] = AutoExecConfig_CreateConVar("sm_jail_teambans_joinbanmsg", "Please visit our website to appeal.", "Message to the client on join if banned.", FCVAR_PLUGIN);
	ConVars[4] = AutoExecConfig_CreateConVar("sm_jail_teambans_tableprefix", "", "Prefix for database tables. (Can be blank)", FCVAR_PLUGIN);
	ConVars[5] = AutoExecConfig_CreateConVar("sm_jail_teambans_sqldriver", "default", "Config entry to use for database: (default = 'default')", FCVAR_PLUGIN);
	ConVars[6] = AutoExecConfig_CreateConVar("sm_jail_teambans_debug", "1", "Spew debugging information: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[7] = AutoExecConfig_CreateConVar("sm_jail_teambans_sqlprogram", "1", "SQL Program to use: (1 = MySQL, 0 = SQLite)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	
	for (new i = 0; i < sizeof(ConVars); i++)
	{
		HookConVarChange(ConVars[i], HandleCvars);
	}
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_win", RoundEnd);

	RegAdminCmd("sm_teamban", Command_LiveBan, ADMFLAG_SLAY, "sm_teamban <player> <optional: time> - Bans a player from guards(blue) team.");
	RegAdminCmd("sm_teamban_status", Command_IsBanned, ADMFLAG_GENERIC, "sm_teamban_status <player> - Gives you information if player is banned or not from guards(blue) team.");
	RegAdminCmd("sm_teamunban", Command_LiveUnban, ADMFLAG_SLAY, "sm_teamunban <player> - Unbans a player from guards(blue) team.");
	RegAdminCmd("sm_teamban_rage", Command_RageBan, ADMFLAG_SLAY, "sm_teamban_rage - Lists recently disconnected players and allows you to ban them from guards(blue) team.");
	RegAdminCmd("sm_teamban_offline", Command_Offline_Ban, ADMFLAG_KICK, "sm_teamban_offline <steamid> - Allows admins to ban players while not on the server from guards(blue) team.");
	RegAdminCmd("sm_teamunban_offline", Command_Offline_Unban, ADMFLAG_KICK, "sm_teamunban_offline <steamid> - Allows admins to unban players while not on the server from guards(blue) team.");

	cBan_Blue = RegClientCookie("TF2Jail_TB_Blue", "Is player banned from blue?", CookieAccess_Protected);
	cBan_Red = RegClientCookie("TF2Jail_TB_Red", "Is player banned from red?", CookieAccess_Protected);
	
	if (cBan_Red) {}

	DNames = CreateArray(MAX_TARGET_LENGTH);
	DSteamIDs = CreateArray(22);
	TimedBanLocalList = CreateArray(2);
	TimedBanSteamList = CreateArray(23);

	for (new i = 1; i <= MaxClients; i++)
	{
		LocalTimeRemaining[i] = 0;
		GuardBanTargetUserId[i] = 0;
	}
		
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	CreateTimer(60.0, CheckTimedGuardBans, INVALID_HANDLE, TIMER_REPEAT);
	
	AutoExecConfig_CleanFile();
}

public OnAllPluginsLoaded()
{
	bAuthIdNativeExists = GetFeatureStatus(FeatureType_Native, "SetAuthIdCookie") == FeatureStatus_Available;
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Handles[i] != INVALID_HANDLE)
		{
			CloseHandle(Handles[i]);
			Handles[i] = INVALID_HANDLE;
		}
	}
}

public OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(ConVars[1]);
	GetConVarString(ConVars[2], cv_DenySound, sizeof(cv_DenySound));
	GetConVarString(ConVars[3], cv_JoinBanMsg, sizeof(cv_JoinBanMsg));
	GetConVarString(ConVars[4], cv_DatabasePrefix, sizeof(cv_DatabasePrefix));
	GetConVarString(ConVars[5], cv_DatabaseConfigEntry, sizeof(cv_DatabaseConfigEntry));
	cv_Debugging = GetConVarBool(ConVars[6]);
	cv_SQLProgram = GetConVarBool(ConVars[7]);

	if (cv_SQLProgram)
	{
		if (SQL_CheckConfig(cv_DatabaseConfigEntry))
		{
			SQL_TConnect(DB_Callback_Connect, cv_DatabaseConfigEntry);
		}
		else
		{
			TF2Jail_Log("SQL Entry '%s' could not be found, falling back to 'default'.", cv_DatabaseConfigEntry);
			SQL_TConnect(DB_Callback_Connect, "default");
		}
	}
	else
	{
		if (SQL_CheckConfig("clientprefs"))
		{
			SQL_TConnect(CP_Callback_Connect, "clientprefs");
		}
		else
		{
			TF2Jail_Log("SQL Entry 'clientprefs' could not be found, falling back to 'default'.");
			SQL_TConnect(DB_Callback_Connect, "default");
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
		cv_Enabled = bool:iNewValue;
	}
	else if (cvar == ConVars[2])
	{
		GetConVarString(ConVars[2], cv_DenySound, sizeof(cv_DenySound));
	}
	else if (cvar == ConVars[3])
	{
		GetConVarString(ConVars[3], cv_JoinBanMsg, sizeof(cv_JoinBanMsg));
	}
	else if (cvar == ConVars[4])
	{
		GetConVarString(ConVars[4], cv_DatabasePrefix, sizeof(cv_DatabasePrefix));
	}
	else if (cvar == ConVars[5])
	{
		GetConVarString(ConVars[5], cv_DatabaseConfigEntry, sizeof(cv_DatabaseConfigEntry));
	}
	else if (cvar == ConVars[6])
	{
		cv_Debugging = bool:iNewValue;
	}
	else if (cvar == ConVars[7])
	{
		cv_SQLProgram = bool:iNewValue;
	}
}

public OnMapStart()
{
   decl String:buffer[PLATFORM_MAX_PATH];
   if (strcmp(cv_DenySound, ""))
   {
		PrecacheSound(cv_DenySound, true);
		Format(buffer, sizeof(buffer), "sound/%s", cv_DenySound);
		AddFileToDownloadsTable(buffer);
   }
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundActive = true;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundActive = false;
}

public OnClientAuthorized(client, const String:auth[])
{
	if (!StrEqual(auth, "BOT"))
	{
		new cID = FindStringInArray(DSteamIDs, auth);
		if (cID != -1)
		{
			RemoveFromArray(DNames, cID);
			RemoveFromArray(DSteamIDs, cID);
			TF2Jail_BB_Debug("removed %N from Rage Bannable player list for re-connecting to the server", client);
		}
		
		if (cv_SQLProgram)
		{
			decl String:query[255];
			Format(query, sizeof(query), "SELECT ban_time FROM %s WHERE steamid = '%s'", sTimesTableName, auth);
			SQL_TQuery(BanDatabase, Client_Authorized, query, GetClientUserId(client));
		}
		else
		{
			new iSteamArrayIndex = FindStringInArray(TimedBanSteamList, auth);
			if (iSteamArrayIndex != -1)
			{
				LocalTimeRemaining[client] = GetArrayCell(TimedBanSteamList, iSteamArrayIndex, 22);
				TF2Jail_BB_Debug("%N joined with %i time remaining on ban", client, LocalTimeRemaining[client]);
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (cv_Enabled)
	{
		Handles[client] = INVALID_HANDLE;
		CreateTimer(0.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (cv_Enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (IsValidClient(client) && IsPlayerAlive(client))
		{			
			decl String:sCookie[5];
			GetClientCookie(client, cBan_Blue, sCookie, sizeof(sCookie));
			
			if (GetClientTeam(client) == _:TFTeam_Blue && bool:StringToInt(sCookie))
			{
				PrintCenterText(client, "%t", "Enforcing Guard Ban");
				CPrintToChat(client, cv_JoinBanMsg);
				
				if (RoundActive)
				{
					ChangeClientTeam(client, _:TFTeam_Spectator);
				}
				else
				{
					ChangeClientTeam(client, _:TFTeam_Red);
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	decl String:sDisconnectSteamID[22];
	GetClientAuthString(client, sDisconnectSteamID, sizeof(sDisconnectSteamID));
	
	if (Handles[client] != INVALID_HANDLE)
	{
		CloseHandle(Handles[client]);
		Handles[client] = INVALID_HANDLE;
	}
	
	decl String:sName[MAX_TARGET_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	
	if (FindStringInArray(DSteamIDs, sDisconnectSteamID) == -1)
	{
		PushArrayString(DNames, sName);
		PushArrayString(DSteamIDs, sDisconnectSteamID);
		
		if (GetArraySize(DNames) >= 7)
		{
			RemoveFromArray(DNames, 0);
			RemoveFromArray(DSteamIDs, 0);
		}
	}
	
	new iBannedArrayIndex = FindValueInArray(TimedBanLocalList, client);
	if (iBannedArrayIndex != -1)
	{
		RemoveFromArray(TimedBanLocalList, iBannedArrayIndex);
		
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, client);
		WritePackString(hPack, sDisconnectSteamID);
		
		if (cv_SQLProgram)
		{
			decl String:query[255];
			Format(query, sizeof(query), "SELECT ban_time FROM %s WHERE steamid = '%s'", sTimesTableName, sDisconnectSteamID);
			SQL_TQuery(BanDatabase, DB_Callback_ClientDisconnect, query, hPack);
		}
		else
		{
			new iSteamArrayIndex = FindStringInArray(TimedBanSteamList, sDisconnectSteamID);
			if (iSteamArrayIndex != -1)
			{
				if (LocalTimeRemaining[client] <= 0)
				{
					RemoveFromArray(TimedBanSteamList, iSteamArrayIndex);
				}
				else
				{
					SetArrayCell(TimedBanSteamList, iSteamArrayIndex, LocalTimeRemaining[client], 22);
				}
			}
		}
	}
}

public AdminMenu_RageBan(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
			{
				Format(buffer, maxlength, "Rage Ban");
			}
		case TopMenuAction_SelectOption:
			{
				DisplayRageBanMenu(param, GetArraySize(DNames));
			}
	}
}

DisplayRageBanMenu(Client, ArraySize)
{
	if (ArraySize != 0)
	{
		new Handle:menu = CreateMenu(MenuHandler_RageBan);
		
		SetMenuTitle(menu, "%T", "Rage Ban Menu Title", Client);
		SetMenuExitBackButton(menu, true);

		for (new i = 0; i < ArraySize; i++)
		{
			decl String:sName[MAX_TARGET_LENGTH];
			GetArrayString(DNames, i, sName, sizeof(sName));
			decl String:sSteamID[22];
			GetArrayString(DSteamIDs, i, sSteamID, sizeof(sSteamID));
			AddMenuItem(menu, sSteamID, sName);
		}
		
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	}
	else
	{
		CPrintToChat(Client, "%s %t", JTAG, "No Targets");
	}
}

public MenuHandler_RageBan(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				decl String:sInfoString[22];
				GetMenuItem(menu, param2, sInfoString, sizeof(sInfoString));
				
				if (bAuthIdNativeExists)
				{
					SetAuthIdCookie(sInfoString, cBan_Blue, "1");
				}
				else
				{
					if (CP_DataBase != INVALID_HANDLE)
					{
						decl String:query[255];
						Format(query, sizeof(query), "SELECT value FROM sm_cookie_cache WHERE player = '%s' and cookie_id = '%i'", sInfoString, iCookieIndex);
						new Handle:TheDataPack = CreateDataPack();
						WritePackString(TheDataPack, sInfoString);
						WritePackCell(TheDataPack, param1);
						WritePackCell(TheDataPack, param2);
						SQL_TQuery(CP_DataBase, CP_Callback_CheckBan, query, TheDataPack); 
					}
				}
				CPrintToChat(param1, "%s %t", JTAG, "Ready to Guard Ban", sInfoString);
			}
		case MenuAction_Cancel:
			{
				if ((param2 == MenuCancel_ExitBack) && (TopMenu != INVALID_HANDLE))
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action:Command_Offline_Ban(client, args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban_offline <steamid>", JTAG);
		return Plugin_Handled;
	}
	
	decl String:sAuthId[32];
	GetCmdArgString(sAuthId, sizeof(sAuthId));
	if (bAuthIdNativeExists)
	{
		SetAuthIdCookie(sAuthId, cBan_Blue, "1");
		CReplyToCommand(client, "%s %t", JTAG, "Banned AuthId", sAuthId);
	}
	else
	{
		CReplyToCommand(client, "%s %t", JTAG, "Feature Not Available");
	}
	return Plugin_Handled;
}

public Action:Command_Offline_Unban(client, args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamunban_offline <steamid>", JTAG);
		return Plugin_Handled;
	}
	
	decl String:sAuthId[32];
	GetCmdArgString(sAuthId, sizeof(sAuthId));
	
	if (bAuthIdNativeExists)
	{
		SetAuthIdCookie(sAuthId, cBan_Blue, "0");
		CReplyToCommand(client, "%s %t", JTAG, "Unbanned AuthId", sAuthId);
	}
	else
	{
		CReplyToCommand(client, "%s %t", JTAG, "Feature Not Available");
	}
	return Plugin_Handled;
}

public Action:Command_RageBan(client, args)
{
	new iArraySize = GetArraySize(DNames);
	
	if (iArraySize == 0)
	{
		CReplyToCommand(client, "%s %t", JTAG, "No Targets");
		return Plugin_Handled;
	}
	
	if (IsClientInGame(client))
	{
		DisplayRageBanMenu(client, iArraySize);
	}
	else
	{
		CReplyToCommand(client, "%s %t", JTAG, "Feature Not Available On Console");
	}
	return Plugin_Handled;
}

public OnAdminMenuReady(Handle:topmenu)
{
	new TopMenuObject:frequent_commands = FindTopMenuCategory(topmenu, "ts_commands");
	
	if (frequent_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(topmenu, "sm_banguard", TopMenuObject_Item, AdminMenu_CTBan, frequent_commands, "sm_banguard", ADMFLAG_SLAY);
	}
	
	new TopMenuObject:player_commands = FindTopMenuCategory(topmenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(topmenu, "sm_rageban", TopMenuObject_Item, AdminMenu_RageBan, player_commands, "sm_rageban", ADMFLAG_SLAY);
		
		if (frequent_commands == INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(topmenu, "sm_banguard", TopMenuObject_Item, AdminMenu_CTBan, player_commands, "sm_banguard", ADMFLAG_SLAY);		
		}
	}
}

public AdminMenu_CTBan(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
			{
				Format(buffer, maxlength, "Guard Ban");
			}
		case TopMenuAction_SelectOption:
			{
				DisplayCTBanPlayerMenu(param);
			}
	}
}

DisplayCTBanPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_CTBanPlayerList);
	
	SetMenuTitle(menu, "%T", "Guard Ban Menu Title", client);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayCTBanTimeMenu(client, targetUserId)
{
	new Handle:menu = CreateMenu(MenuHandler_CTBanTimeList);

	SetMenuTitle(menu, "%T", "Guard Ban Length Menu", client, GetClientOfUserId(targetUserId));
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "0", "Permanent");
	AddMenuItem(menu, "5", "5 Minutes");
	AddMenuItem(menu, "10", "10 Minutes");
	AddMenuItem(menu, "30", "30 Minutes");
	AddMenuItem(menu, "60", "1 Hour");
	AddMenuItem(menu, "120", "2 Hours");
	AddMenuItem(menu, "240", "4 Hours");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayCTBanReasonMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_CTBanReasonList);

	SetMenuTitle(menu, "%T", "Guard Ban Reason Menu", client, GetClientOfUserId(GuardBanTargetUserId[client]));
	SetMenuExitBackButton(menu, true);

	decl String:sMenuReason[128];
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 1", client);
	AddMenuItem(menu, "1", sMenuReason);
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 2", client);
	AddMenuItem(menu, "2", sMenuReason);
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 3", client);
	AddMenuItem(menu, "3", sMenuReason);
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 4", client);
	AddMenuItem(menu, "4", sMenuReason);
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 5", client);
	AddMenuItem(menu, "5", sMenuReason);
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 6", client);
	AddMenuItem(menu, "6", sMenuReason);
	Format(sMenuReason, sizeof(sMenuReason), "%T", "Guard Ban Reason 7", client);
	AddMenuItem(menu, "7", sMenuReason);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_CTBanReasonList(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				decl String:sBanChoice[10];
				GetMenuItem(menu, param2, sBanChoice, sizeof(sBanChoice));
				new iBanReason = StringToInt(sBanChoice);
				new iTimeToBan = GuardBanTimeLength[param1];
				new iTargetIndex = GetClientOfUserId(GuardBanTargetUserId[param1]);
				
				decl String:sBanned[3];
				GetClientCookie(iTargetIndex, cBan_Blue, sBanned, sizeof(sBanned));
				new banFlag = StringToInt(sBanned);
				if (!banFlag)
				{
					PerformBan(iTargetIndex, param1, iTimeToBan, iBanReason);
				}
				else
				{
					CPrintToChat(param1, "%s %t", JTAG, "Already Guard Banned", iTargetIndex);
				}
			}
		case MenuAction_Cancel:
			{
				if (param2 == MenuCancel_ExitBack && TopMenu != INVALID_HANDLE)
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public MenuHandler_CTBanPlayerList(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				decl String:info[32];
				new userid, target;
				
				GetMenuItem(menu, param2, info, sizeof(info));
				userid = StringToInt(info);

				if ((target = GetClientOfUserId(userid)) == 0)
				{
					CPrintToChat(param1, "%s %t", JTAG, "Player no longer available");
				}
				else if (!CanUserTarget(param1, target))
				{
					CPrintToChat(param1, "%s %t", JTAG, "Unable to target");
				}
				else
				{
					GuardBanTargetUserId[param1] = userid;
					DisplayCTBanTimeMenu(param1, userid);
				}
			}
		case MenuAction_Cancel:
			{
				if (param2 == MenuCancel_ExitBack && TopMenu != INVALID_HANDLE)
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public MenuHandler_CTBanTimeList(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				decl String:info[32];
				GetMenuItem(menu, param2, info, sizeof(info));
				new iTimeToBan = StringToInt(info);
				GuardBanTimeLength[param1] = iTimeToBan;
				DisplayCTBanReasonMenu(param1);
			}
		case MenuAction_Cancel:
			{
				if (param2 == MenuCancel_ExitBack && TopMenu != INVALID_HANDLE)
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action:CheckBanCookies(Handle:timer, any: client)
{
	if (AreClientCookiesCached(client))
	{
		ProcessBanCookies(client);
	}
	else if (IsValidClient(client))
	{
		CreateTimer(5.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

ProcessBanCookies(client)
{
	if (IsValidClient(client))
	{
		decl String:cookie[32];
		GetClientCookie(client, cBan_Blue, cookie, sizeof(cookie));
		
		if (StrEqual(cookie, "1")) 
		{
			if (GetClientTeam(client) == _:TFTeam_Blue)
			{
				if (IsPlayerAlive(client))
				{
					new wepIdx;
					for (new i; i < 4; i++)
					{
						if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
						{
							RemovePlayerItem(client, wepIdx);
							AcceptEntityInput(wepIdx, "Kill");
						}
					}
				
					ForcePlayerSuicide(client);
				}
				ChangeClientTeam(client, _:TFTeam_Red);
				CPrintToChat(client, "%s %t", JTAG, "Enforcing Guard Ban");
			}		
		}
	}
}

public Action:Command_LiveUnban(client, args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamunban <player>", JTAG);
		return Plugin_Handled;
	}
		
	decl String:target[64];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:clientName[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml);
	if (target_count != 1)
	{
		ReplyToTargetError(client, target_count);
	}
	else
	{
		if (AreClientCookiesCached(target_list[0]))
		{
			Remove_CTBan(client, target_list[0]);
		}
		else
		{
			CReplyToCommand(client, "%s %t", JTAG, "Cookie Status Unavailable");
		}
	}	
	return Plugin_Handled;
}

Remove_CTBan(adminIndex, targetIndex, bExpired=false)
{
	decl String:isBanned[3];
	GetClientCookie(targetIndex, cBan_Blue, isBanned, sizeof(isBanned));
	
	if (bool:StringToInt(isBanned))
	{
		decl String:targetSteam[22];
		GetClientAuthString(targetIndex, targetSteam, sizeof(targetSteam));
		
		if (cv_SQLProgram)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "UPDATE %s SET timeleft=-1 WHERE offender_steamid = '%s' and timeleft >= 0", sLogTableName, targetSteam);

			TF2Jail_BB_Debug("log query: %s", logQuery);

			SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, logQuery, targetIndex);
		}
		
		TF2Jail_Log("%N has removed the Guard ban on %N (%s).", adminIndex, targetIndex, targetSteam);
		
		if (!bExpired)
		{
			CShowActivity2(adminIndex, JTAG, "%t", "Guard Ban Removed", targetIndex);
		}
		else
		{
			CShowActivity2(adminIndex, JTAG, "%t", "Guard Ban Auto Removed", targetIndex);
		}
		
		decl String:query[255];
		Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", sTimesTableName, targetSteam);
		SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, query, targetIndex);	
	}
	
	SetClientCookie(targetIndex, cBan_Blue, "0");
}

public Action:Command_LiveBan(client, args)
{
	if (args > 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban <player> <time> <reason>", JTAG);
		return Plugin_Handled;
	}
	
	new numArgs = GetCmdArgs();
	decl String:target[64];
	GetCmdArg(1, target, sizeof(target));
	decl String:sBanTime[16];
	GetCmdArg(2, sBanTime, sizeof(sBanTime));
	new iBanTime = StringToInt(sBanTime);
	new String:sReasonStr[200];
	decl String:sArgPart[200];
	
	for (new arg = 3; arg <= numArgs; arg++)
	{
		GetCmdArg(arg, sArgPart, sizeof(sArgPart));
		Format(sReasonStr, sizeof(sReasonStr), "%s %s", sReasonStr, sArgPart);
	}
	
	decl String:clientName[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml);
	if ((target_count != 1))
	{
		ReplyToTargetError(client, target_count);
	}
	else
	{
		if (target_list[0] && IsValidClient(target_list[0]))
		{
			if (AreClientCookiesCached(target_list[0]))
			{
				decl String:isBanned[3];
				GetClientCookie(target_list[0], cBan_Blue, isBanned, sizeof(isBanned));
				new banFlag = StringToInt(isBanned);	
				if (banFlag)
				{
					CReplyToCommand(client, "%s %t", JTAG, "Already Guard Banned", target_list[0]);
				}
				else
				{
					PerformBan(target_list[0], client, iBanTime, _, sReasonStr);
				}
			}
			else
			{
				CReplyToCommand(client, "%s %t", JTAG, "Cookie Status Unavailable");
			}
		}				
	}
	return Plugin_Handled;
}

PerformBan(client, admin, banTime=0, reason=0, String:manualReason[]="")
{
	SetClientCookie(client, cBan_Blue, "1");
	
	decl String:targetSteam[22];
	GetClientAuthString(client, targetSteam, sizeof(targetSteam));

	if (GetClientTeam(client) == _:TFTeam_Blue)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
		ChangeClientTeam(client, _:TFTeam_Red);
	}
	
	decl String:sReason[128];
	if (strlen(manualReason) > 0)
	{
		Format(sReason, sizeof(sReason), "%s", manualReason);
	}
	else
	{		
		switch (reason)
		{
			case 1:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 1", admin);
			}
			case 2:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 2", admin);
			}
			case 3:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 3", admin);
			}
			case 4:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 4", admin);
			}
			case 5:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 5", admin);
			}
			case 6:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 6", admin);
			}
			case 7:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 7", admin);
			}
			default:
			{
				Format(sReason, sizeof(sReason), "No reason given.");
			}
		}
	}
	
	new timestamp = GetTime();
	
	if (admin && IsValidClient(admin))
	{
		decl String:adminSteam[32];
		GetClientAuthString(admin, adminSteam, sizeof(adminSteam));
		
		if (cv_SQLProgram)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%N', '%s', '%N', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, client, adminSteam, admin, banTime, banTime, sReason);
			TF2Jail_BB_Debug("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		TF2Jail_Log("%N (%s) has issued a Guard ban on %N (%s) for %d minutes for %s.", admin, adminSteam, client, targetSteam, banTime, sReason);
	}
	else
	{
		if (cv_SQLProgram)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, reason) VALUES (%d, '%s', '%N', 'STEAM_0:1:1', 'Console', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, client, banTime, banTime, sReason);
			TF2Jail_BB_Debug("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		TF2Jail_Log("Console has issued a Guard ban on %N (%s) for %d.", client, targetSteam, banTime);
	}

	if (banTime > 0)
	{
		CShowActivity2(admin, JTAG, "%t", "Temporary Guard Ban", client, banTime);
		PushArrayCell(TimedBanLocalList, client);
		LocalTimeRemaining[client] = banTime;
		
		if (cv_SQLProgram)
		{
			decl String:query[255];
			Format(query, sizeof(query), "INSERT INTO %s (steamid, ban_time) VALUES ('%s', %d)", sTimesTableName, targetSteam, banTime);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, query, client);
			TF2Jail_BB_Debug("ctban query: %s", query);
		}
		
		SetArrayCell(TimedBanSteamList, PushArrayString(TimedBanSteamList, targetSteam), banTime, 22);
	}
	else
	{
		CShowActivity2(admin, JTAG, "%t", "Permanent Guard Ban", client);	
	}
}

public Action:Command_IsBanned(client, args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban_status <player>", JTAG);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_NAME_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:sName[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, sName, sizeof(sName), tn_is_ml);
	
	if (target_count != 1) 
	{
		ReplyToTargetError(client, target_count);
	}
	else
	{
		if (target_list[0] && IsValidClient(target_list[0]))
		{
			if (AreClientCookiesCached(target_list[0]))
			{
				decl String:isBanned[3];
				GetClientCookie(target_list[0], cBan_Blue, isBanned, sizeof(isBanned));
				new banFlag = StringToInt(isBanned);	
				if (banFlag)
				{
					if (LocalTimeRemaining[target_list[0]] <= 0)
					{
						CReplyToCommand(client, "%s %t", JTAG, "Permanent Guard Ban", target_list[0]);
					}
					else
					{
						CReplyToCommand(client, "%s %t", JTAG, "Temporary Guard Ban", target_list[0], LocalTimeRemaining[target_list[0]]);
					}
				}
				else
				{
					CReplyToCommand(client, "%s %t", JTAG, "Not Guard Banned", target_list[0]);
				}
			}
			else
			{
				CReplyToCommand(client, "%s %t", JTAG, "Cookie Status Unavailable");	
			}
		}
		else
		{
			CReplyToCommand(client, "%s %t", JTAG, "Unable to target");
		}				
	}
	return Plugin_Handled;
}

//SQL Handles

public Client_Authorized(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	if (hndl != INVALID_HANDLE)
	{
		new iRowCount = SQL_GetRowCount(hndl);
		TF2Jail_BB_Debug("SQL Auth: %d row count", iRowCount);
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			new iBanTimeRemaining = SQL_FetchInt(hndl, 0);
			TF2Jail_BB_Debug("SQL Auth: %N joined with %i time remaining on ban", client, iBanTimeRemaining);
			PushArrayCell(TimedBanLocalList, client);
			LocalTimeRemaining[client] = iBanTimeRemaining;
		}
	}
	else
	{
		LogError("Error in OnClientAuthorized query: %s", error);
	}
}

public DB_Callback_CTBan(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		if (cv_Debugging && IsValidClient(client))
		{
			TF2Jail_Log("SQL CTBan: Updated database with Guard Ban for %N", client);
		}
	}
	else
	{
		LogError("Error writing CTBan to Timed Ban database: %s", error);
	}
}

public DB_Callback_RemoveCTBan(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		if (cv_Debugging && IsValidClient(client))
		{
			TF2Jail_Log("CTBan on %N was removed in SQL", client);
		}
		else if (cv_Debugging	 && !IsClientInGame(client))
		{
			TF2Jail_Log("CTBan on --- was removed in SQL");
		}
	}
	else
	{
		LogError("Error handling steamID after Guard ban removal: %s", error);
	}
}

public DB_Callback_DisconnectAction(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error with updating/deleting record after client disconnect: %s", error);
	}
}

public DB_Callback_ClientDisconnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		ResetPack(data);
		new client = ReadPackCell(data);
		decl String:sAuthID[22];
		ReadPackString(data, sAuthID, sizeof(sAuthID));
		CloseHandle(data);
		
		if (SQL_GetRowCount(hndl))
		{
			if (cv_Debugging)
			{
				SQL_FetchRow(hndl);
				new iRemain = SQL_FetchInt(hndl, 0);

				if (IsValidClient(client))
				{
					TF2Jail_Log("SQL: %N disconnected with %i time remaining on ban", client, iRemain);
				}
				else
				{
					TF2Jail_Log("SQL: %i client index disconnected with %i time remaining on ban", client, iRemain);
				}
			}

			if (LocalTimeRemaining[client] <= 0)
			{
				decl String:query[255];
				Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", sTimesTableName, sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
				Format(query, sizeof(query), "UPDATE %s SET timeleft=-1 WHERE offender_steamid = '%s' AND timeleft >= 0", sLogTableName, sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
			}
			else
			{
				decl String:query[255];
				Format(query, sizeof(query), "UPDATE %s SET ban_time = %d WHERE steamid = '%s'", sTimesTableName, LocalTimeRemaining[client], sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
				Format(query, sizeof(query), "UPDATE %s SET timeleft = %d WHERE offender_steamid = '%s' AND timeleft >= 0", sLogTableName, LocalTimeRemaining[client], sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
			}
		}
	}
	else
	{
		LogError("Error with query on client disconnect: %s", error);
		CloseHandle(data);
	}
}

public DB_Callback_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		BanDatabase = hndl;
		decl String:sQuery[255];
		
		if (StrEqual(cv_DatabasePrefix, ""))
		{
			Format(sTimesTableName, sizeof(sTimesTableName), "tf2jail_bluebans");
		}
		else
		{
			Format(sTimesTableName, sizeof(sTimesTableName), "%s_tf2jail_bluebans", cv_DatabasePrefix);
		}
		
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(22), ban_time INT(16), PRIMARY KEY (steamid))", sTimesTableName);
		SQL_TQuery(BanDatabase, DB_Callback_Create, sQuery); 
		
		if (StrEqual(cv_DatabasePrefix, ""))
		{
			Format(sLogTableName, sizeof(sLogTableName), "tf2jail_blueban_logs");
		}
		else
		{
			Format(sLogTableName, sizeof(sLogTableName), "%s_tf2jail_blueban_logs", cv_DatabasePrefix);
		}
		
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (timestamp INT, offender_steamid VARCHAR(22), offender_name VARCHAR(32), admin_steamid VARCHAR(22), admin_name VARCHAR(32), bantime INT(16), timeleft INT(16), reason VARCHAR(200), PRIMARY KEY (timestamp))", sLogTableName);
		SQL_TQuery(BanDatabase, DB_Callback_Create, sQuery);
	}
	else
	{
		LogError("Default database database connection failure: %s", error);
		SetFailState("Error while connecting to default database. Exiting.");
	}
}

public DB_Callback_Create(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error establishing table creation: %s", error);
		SetFailState("Unable to ascertain creation of table in default database. Exiting.");
	}
}

public CP_Callback_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		CP_DataBase = hndl;
		SQL_TQuery(CP_DataBase, CP_Callback_FindCookie, "SELECT id FROM sm_cookies WHERE name = 'TF2Jail_GuardBanned'");
	}
	else
	{
		LogError("Clientprefs database connection failure: %s", error);
		SetFailState("Error while connecting to clientprefs database. Exiting.");
	}
}

public CP_Callback_FindCookie(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		new iRowCount = SQL_GetRowCount(hndl);
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			new CookieIDIndex = SQL_FetchInt(hndl, 0);
			TF2Jail_BB_Debug("found cookie index as %i", CookieIDIndex);
			iCookieIndex = CookieIDIndex;
		}
		else
		{
			LogError("Could not find the cookie index. Rageban functionality disabled.");
		}
	}
	else
	{
		LogError("Cookie query failure: %s", error);
	}
}

public CP_Callback_CheckBan(Handle:owner, Handle:hndl, const String:error[], any:stringPack)
{
	if (hndl != INVALID_HANDLE)
	{
		ResetPack(stringPack);
		decl String:authID[22];
		ReadPackString(stringPack, authID, sizeof(authID));
		new iAdminIndex = ReadPackCell(stringPack);
		new iArrayBanIndex = ReadPackCell(stringPack);
		CloseHandle(stringPack);
		
		new iTimeStamp = GetTime();
		
		new iRowCount = SQL_GetRowCount(hndl);
		if (iRowCount)
		{
			if (cv_Debugging)
			{
				SQL_FetchRow(hndl);
				new iCTBanStatus = SQL_FetchInt(hndl, 0);
				TF2Jail_Log("CTBan status on player is currently %i. Will do UPDATE on %s", iCTBanStatus, authID);
			}

			decl String:query[255];
			Format(query, sizeof(query), "UPDATE sm_cookie_cache SET value = '1', timestamp = %i WHERE player = '%s' AND cookie_id = '%i'", iTimeStamp, authID, iCookieIndex);
			TF2Jail_BB_Debug("Query to run: %s", query);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
		}
		else
		{
			if (cv_Debugging) TF2Jail_Log("couldn't find steamID in database, need to INSERT");
			decl String:query[255];
			Format(query, sizeof(query), "INSERT INTO sm_cookie_cache (player, cookie_id, value, timestamp) VALUES ('%s', %i, '1', %i)", authID, iCookieIndex, iTimeStamp);
			TF2Jail_BB_Debug("Query to run: %s", query);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
		}
		
		decl String:sTargetName[MAX_TARGET_LENGTH];
		GetArrayString(DNames, iArrayBanIndex, sTargetName, sizeof(sTargetName));
		decl String:adminSteamID[22];
		GetClientAuthString(iAdminIndex, adminSteamID, sizeof(adminSteamID));

		if (cv_SQLProgram)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%s', '%s', 'Console', 0, 0, 'Rage ban')", sLogTableName, iTimeStamp, authID, sTargetName, adminSteamID, iAdminIndex);
			TF2Jail_BB_Debug("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, iAdminIndex);
		}
		
		TF2Jail_Log("%N (%s) has issued a rage ban on %s (%s) indefinitely.", iAdminIndex, adminSteamID, sTargetName, authID);

		CShowActivity2(iAdminIndex, JTAG, "%t", "Rage Ban", sTargetName);

		RemoveFromArray(DNames, iArrayBanIndex);
		RemoveFromArray(DSteamIDs, iArrayBanIndex);
		TF2Jail_BB_Debug("Removed %i index from rage ban menu.", iArrayBanIndex);
	}
	else
	{
		LogError("Guard Ban query had a failure: %s", error);
		CloseHandle(stringPack);
	}
}

public CP_Callback_IssueBan(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		TF2Jail_BB_Debug("succesfully wrote to the database");
	}
	else
	{
		LogError("Error writing to database: %s", error);
	}
}

// Timers

public Action:CheckTimedGuardBans(Handle:timer)
{
	new iTime = GetArraySize(TimedBanLocalList);
	
	for (new i = 0; i < iTime; i++)
	{
		new iBannedClientIndex = GetArrayCell(TimedBanLocalList, i);
		if (IsValidClient(iBannedClientIndex))
		{
			if (IsPlayerAlive(iBannedClientIndex))
			{
				LocalTimeRemaining[iBannedClientIndex]--;
				
				TF2Jail_BB_Debug("found alive time banned client with %i remaining", LocalTimeRemaining[iBannedClientIndex]);
				
				if (LocalTimeRemaining[iBannedClientIndex] <= 0)
				{
					RemoveFromArray(TimedBanLocalList, i);
					iTime--;
					Remove_CTBan(0, iBannedClientIndex, true);
					TF2Jail_BB_Debug("removed Guard ban on %N", iBannedClientIndex);
				}
			}
		}
	}
}

//Stocks

TF2Jail_BB_Debug(const String:format[], any:...)
{
	if (cv_Debugging)
	{
		decl String:buffer[256];
		VFormat(buffer, sizeof(buffer), format, 2);
		TF2Jail_Log("%s", buffer);
	}
}