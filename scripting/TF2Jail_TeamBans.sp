/*
	https://forums.alliedmods.net/showthread.php?p=1544101
	
	Cheers to Databomb for his plugin code, I basically just took it and fixed it up for TF2.
	All the same rules and licensing apply.
	
	Finally fucking fixed up after about a year and a half of no recurring updates.
*/

#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <adminmenu>

#undef REQUIRE_EXTENSIONS
#tryinclude <clientprefs>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#define REQUIRE_PLUGIN

//New Syntax
#pragma newdecls required

#define PLUGIN_NAME     "[TF2] Jailbreak - Team Bans"
#define PLUGIN_AUTHOR   "Keith Warren(Shaders Allen)"
#define PLUGIN_VERSION  "1.0.6"
#define PLUGIN_DESCRIPTION	"Manage bans for one or multiple teams."
#define PLUGIN_CONTACT  "http://www.shadersallen.com/"

#define JTAG "[Teambans]"

Handle ConVars[8];
bool cv_Enabled; char cv_DenySound[PLATFORM_MAX_PATH]; char cv_JoinBanMsg[100];
char cv_DatabasePrefix[64]; char cv_DatabaseConfigEntry[64]; bool cv_Debugging;
bool cv_SQLProgram;

Handle cBan_Blue;
Handle cBan_Red;
Handle Handles[MAXPLAYERS + 1];
Handle hArray_RageTables_Name;
Handle hArray_RageTables_IDs;
Handle CP_DataBase;
Handle BanDatabase;
int iCookieIndex;
bool bAuthIdNativeExists;
Handle TimedBanLocalList;
int LocalTimeRemaining[MAXPLAYERS + 1];
Handle TimedBanSteamList;
int GuardBanTargetUserId[MAXPLAYERS + 1];
int GuardBanTimeLength[MAXPLAYERS + 1];
char sLogTableName[32];
char sTimesTableName[32];

bool RoundActive;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail_TeamBans.phrases");

	ConVars[0] = CreateConVar("tf2jail_teambans_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ConVars[1] = CreateConVar("sm_jail_teambans_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_NOTIFY);
	ConVars[2] = CreateConVar("sm_jail_teambans_denysound", "", "Sound file to play when denied. (Relative to the sound folder)",FCVAR_NOTIFY);
	ConVars[3] = CreateConVar("sm_jail_teambans_joinbanmsg", "Please visit our website to appeal.", "Message to the client on join if banned.", FCVAR_NOTIFY);
	ConVars[4] = CreateConVar("sm_jail_teambans_tableprefix", "", "Prefix for database tables. (Can be blank)", FCVAR_NOTIFY);
	ConVars[5] = CreateConVar("sm_jail_teambans_sqldriver", "default", "Config entry to use for database: (default = 'default')", FCVAR_NOTIFY);
	ConVars[6] = CreateConVar("sm_jail_teambans_debug", "1", "Spew debugging information: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ConVars[7] = CreateConVar("sm_jail_teambans_sqlprogram", "1", "SQL Program to use: (1 = MySQL, 0 = SQLite)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	for (int i = 0; i < sizeof(ConVars); i++)
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
	RegAdminCmd("sm_teamban_guardban", Command_CTBanMenu, ADMFLAG_KICK);

	cBan_Blue = RegClientCookie("TF2Jail_TB_Blue", "Is player banned from blue?", CookieAccess_Protected);
	cBan_Red = RegClientCookie("TF2Jail_TB_Red", "Is player banned from red?", CookieAccess_Protected);
	
	if (cBan_Red)
	{

	}
	
	hArray_RageTables_Name = CreateArray(MAX_TARGET_LENGTH);
	hArray_RageTables_IDs = CreateArray(22);
	TimedBanLocalList = CreateArray(2);
	TimedBanSteamList = CreateArray(23);

	for (int i = 1; i <= MaxClients; i++)
	{
		LocalTimeRemaining[i] = 0;
		GuardBanTargetUserId[i] = 0;
	}
	
	CreateTimer(60.0, CheckTimedGuardBans, _, TIMER_REPEAT);
	
	AutoExecConfig();
}

public void OnAllPluginsLoaded()
{
	bAuthIdNativeExists = GetFeatureStatus(FeatureType_Native, "SetAuthIdCookie") == FeatureStatus_Available;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Handles[i] != null)
		{
			CloseHandle(Handles[i]);
			Handles[i] = null;
		}
	}
}

public void OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(ConVars[1]);
	GetConVarString(ConVars[2], cv_DenySound, sizeof(cv_DenySound));
	GetConVarString(ConVars[3], cv_JoinBanMsg, sizeof(cv_JoinBanMsg));
	GetConVarString(ConVars[4], cv_DatabasePrefix, sizeof(cv_DatabasePrefix));
	GetConVarString(ConVars[5], cv_DatabaseConfigEntry, sizeof(cv_DatabaseConfigEntry));
	cv_Debugging = GetConVarBool(ConVars[6]);
	cv_SQLProgram = GetConVarBool(ConVars[7]);
	
	if (BanDatabase == null && strlen(cv_DatabaseConfigEntry) > 0)
	{
		SQL_TConnect(DB_Callback_Connect, cv_DatabaseConfigEntry);
	}
}

public int HandleCvars(Handle hCvar, char[] sOldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if (hCvar == ConVars[0])
	{
		SetConVarString(ConVars[0], PLUGIN_VERSION);
	}
	else if (hCvar == ConVars[1])
	{
		cv_Enabled = view_as<bool>(iNewValue);
	}
	else if (hCvar == ConVars[2])
	{
		strcopy(cv_DenySound, sizeof(cv_DenySound), newValue);
	}
	else if (hCvar == ConVars[3])
	{
		strcopy(cv_JoinBanMsg, sizeof(cv_JoinBanMsg), newValue);
	}
	else if (hCvar == ConVars[4])
	{
		strcopy(cv_DatabasePrefix, sizeof(cv_DatabasePrefix), newValue);
	}
	else if (hCvar == ConVars[5])
	{
		strcopy(cv_DatabaseConfigEntry, sizeof(cv_DatabaseConfigEntry), newValue);
	}
	else if (hCvar == ConVars[6])
	{
		cv_Debugging = view_as<bool>(iNewValue);
	}
	else if (hCvar == ConVars[7])
	{
		cv_SQLProgram = view_as<bool>(iNewValue);
	}
}

public void OnMapStart()
{
   char buffer[PLATFORM_MAX_PATH];
   if (strlen(cv_DenySound) != 0)
   {
		PrecacheSound(cv_DenySound, true);
		Format(buffer, sizeof(buffer), "sound/%s", cv_DenySound);
		AddFileToDownloadsTable(buffer);
   }
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	RoundActive = true;
}

public Action RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	RoundActive = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client))
	{
		return;
	}
		
	int iLookup = FindStringInArray(hArray_RageTables_IDs, auth);
	
	if (iLookup != -1)
	{
		RemoveFromArray(hArray_RageTables_Name, iLookup);
		RemoveFromArray(hArray_RageTables_IDs, iLookup);
		LogMessage("Removed %N from rage tables for reconnecting.", client);
	}
	
	if (cv_SQLProgram && BanDatabase != null)
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT ban_time FROM %s WHERE steamid = '%s';", sTimesTableName, auth);
		SQL_TQuery(BanDatabase, Client_Authorized, sQuery, GetClientUserId(client));
	}
	else
	{
		int iSteamArrayIndex = FindStringInArray(TimedBanSteamList, auth);
		
		if (iSteamArrayIndex != -1)
		{
			LocalTimeRemaining[client] = GetArrayCell(TimedBanSteamList, iSteamArrayIndex, 22);
			LogMessage("%N joined with %i time remaining on ban", client, LocalTimeRemaining[client]);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (cv_Enabled)
	{
		Handles[client] = null;
		CreateTimer(0.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (cv_Enabled)
	{
		return Plugin_Continue;
	}
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{			
		char sCookie[5];
		GetClientCookie(client, cBan_Blue, sCookie, sizeof(sCookie));
		
		if (TF2_GetClientTeam(client) == TFTeam_Blue && view_as<bool>(StringToInt(sCookie)))
		{
			PrintCenterText(client, "%t", "Enforcing Guard Ban");
			CPrintToChat(client, cv_JoinBanMsg);
			
			switch (RoundActive)
			{
				case true: TF2_ChangeClientTeam(client, TFTeam_Spectator);
				case false: TF2_ChangeClientTeam(client, TFTeam_Red);
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	char sDisconnectSteamID[22];
	GetClientAuthId(client, AuthId_Steam2, sDisconnectSteamID, sizeof(sDisconnectSteamID));
	
	if (Handles[client] != null)
	{
		CloseHandle(Handles[client]);
		Handles[client] = null;
	}
	
	char sName[MAX_TARGET_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	
	if (FindStringInArray(hArray_RageTables_IDs, sDisconnectSteamID) == -1)
	{
		PushArrayString(hArray_RageTables_Name, sName);
		PushArrayString(hArray_RageTables_IDs, sDisconnectSteamID);
		
		if (GetArraySize(hArray_RageTables_Name) >= 7)
		{
			RemoveFromArray(hArray_RageTables_Name, 0);
			RemoveFromArray(hArray_RageTables_IDs, 0);
		}
	}
	
	int iBannedArrayIndex = FindValueInArray(TimedBanLocalList, client);
	
	if (iBannedArrayIndex != -1)
	{
		RemoveFromArray(TimedBanLocalList, iBannedArrayIndex);
		
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, client);
		WritePackString(hPack, sDisconnectSteamID);
		
		if (cv_SQLProgram)
		{
			char sQuery[256];
			Format(sQuery, sizeof(sQuery), "SELECT ban_time FROM %s WHERE steamid = '%s';", sTimesTableName, sDisconnectSteamID);
			SQL_TQuery(BanDatabase, DB_Callback_ClientDisconnect, sQuery, hPack);
		}
		else
		{
			int iSteamArrayIndex = FindStringInArray(TimedBanSteamList, sDisconnectSteamID);
			
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

void DisplayRageBanMenu(int client)
{
	int RageTablesSize = GetArraySize(hArray_RageTables_Name);
	
	if (RageTablesSize == 0)
	{
		CPrintToChat(client, "%s %t", JTAG, "No Targets");
		return;
	}
	
	Handle hMenu = CreateMenu(MenuHandler_RageBan);
	
	SetMenuTitle(hMenu, "%T", "Rage Ban Menu Title", client);
	SetMenuExitBackButton(hMenu, true);
	
	for (int i = 0; i < RageTablesSize; i++)
	{
		char sName[MAX_TARGET_LENGTH];
		GetArrayString(hArray_RageTables_Name, i, sName, sizeof(sName));
		
		char sSteamID[32];
		GetArrayString(hArray_RageTables_IDs, i, sSteamID, sizeof(sSteamID));
		
		AddMenuItem(hMenu, sSteamID, sName);
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_RageBan(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sInfoString[22];
				GetMenuItem(menu, param2, sInfoString, sizeof(sInfoString));
				
				if (bAuthIdNativeExists)
				{
					SetAuthIdCookie(sInfoString, cBan_Blue, "1");
				}
				else
				{
					if (CP_DataBase != null)
					{
						char sQuery[256];
						Format(sQuery, sizeof(sQuery), "SELECT value FROM sm_cookie_cache WHERE player = '%s' and cookie_id = '%i';", sInfoString, iCookieIndex);
						
						Handle TheDataPack = CreateDataPack();
						WritePackString(TheDataPack, sInfoString);
						WritePackCell(TheDataPack, param1);
						WritePackCell(TheDataPack, param2);
						
						SQL_TQuery(CP_DataBase, CP_Callback_CheckBan, sQuery, TheDataPack); 
					}
				}
				
				CPrintToChat(param1, "%s %t", JTAG, "Ready to Guard Ban", sInfoString);
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action Command_Offline_Ban(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban_offline <steamid>", JTAG);
		return Plugin_Handled;
	}
	
	char sAuthId[32];
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

public Action Command_Offline_Unban(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamunban_offline <steamid>", JTAG);
		return Plugin_Handled;
	}
	
	char sAuthId[32];
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

public Action Command_RageBan(int client, int args)
{
	int iArraySize = GetArraySize(hArray_RageTables_Name);
	
	if (iArraySize == 0)
	{
		CReplyToCommand(client, "%s %t", JTAG, "No Targets");
		return Plugin_Handled;
	}
	
	if (IsClientInGame(client))
	{
		DisplayRageBanMenu(client);
	}
	else
	{
		CReplyToCommand(client, "%s %t", JTAG, "Feature Not Available On Console");
	}
	
	return Plugin_Handled;
}

public Action Command_CTBanMenu(int client, int args)
{
	DisplayCTBanPlayerMenu(client);
	return Plugin_Handled;
}

void DisplayCTBanPlayerMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_CTBanPlayerList);
	
	SetMenuTitle(menu, "%T", "Guard Ban Menu Title", client);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void DisplayCTBanTimeMenu(int client, int targetUserId)
{
	Handle menu = CreateMenu(MenuHandler_CTBanTimeList);

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

void DisplayCTBanReasonMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_CTBanReasonList);

	SetMenuTitle(menu, "%T", "Guard Ban Reason Menu", client, GetClientOfUserId(GuardBanTargetUserId[client]));
	SetMenuExitBackButton(menu, true);

	char sMenuReason[128];
	
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

public int MenuHandler_CTBanReasonList(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sBanChoice[12];
				GetMenuItem(menu, param2, sBanChoice, sizeof(sBanChoice));
				
				int iBanReason = StringToInt(sBanChoice);
				int iTimeToBan = GuardBanTimeLength[param1];
				int iTargetIndex = GetClientOfUserId(GuardBanTargetUserId[param1]);
				
				char sBanned[32];
				GetClientCookie(iTargetIndex, cBan_Blue, sBanned, sizeof(sBanned));
				
				int banFlag = StringToInt(sBanned);
				
				if (!banFlag)
				{
					PerformBan(iTargetIndex, param1, iTimeToBan, iBanReason);
				}
				else
				{
					CPrintToChat(param1, "%s %t", JTAG, "Already Guard Banned", iTargetIndex);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public int MenuHandler_CTBanPlayerList(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char info[32];
				GetMenuItem(menu, param2, info, sizeof(info));
				int userid = StringToInt(info);
				int target;

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
		case MenuAction_End: CloseHandle(menu);
	}
}

public int MenuHandler_CTBanTimeList(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char info[32];
				GetMenuItem(menu, param2, info, sizeof(info));
				int iTimeToBan = StringToInt(info);
				
				GuardBanTimeLength[param1] = iTimeToBan;
				DisplayCTBanReasonMenu(param1);
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action CheckBanCookies(Handle timer, any client)
{
	if (AreClientCookiesCached(client))
	{
		ProcessBanCookies(client);
	}
	else if (IsClientInGame(client))
	{
		CreateTimer(5.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ProcessBanCookies(int client)
{
	if (IsClientInGame(client))
	{
		char cookie[32];
		GetClientCookie(client, cBan_Blue, cookie, sizeof(cookie));
		
		if (StrEqual(cookie, "1") && TF2_GetClientTeam(client) == TFTeam_Blue) 
		{
			if (IsPlayerAlive(client))
			{
				int wepIdx;
				for (int i; i < 4; i++)
				{
					if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
					{
						RemovePlayerItem(client, wepIdx);
						AcceptEntityInput(wepIdx, "Kill");
					}
				}
			
				ForcePlayerSuicide(client);
			}
			
			TF2_ChangeClientTeam(client, TFTeam_Red);
			CPrintToChat(client, "%s %t", JTAG, "Enforcing Guard Ban");	
		}
	}
}

public Action Command_LiveUnban(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamunban <player>", JTAG);
		return Plugin_Handled;
	}
		
	char target[64];
	GetCmdArg(1, target, sizeof(target));
	
	char clientName[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml);
	
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

void Remove_CTBan(int adminIndex, int targetIndex, bool bExpired = false)
{
	char isBanned[12];
	GetClientCookie(targetIndex, cBan_Blue, isBanned, sizeof(isBanned));
	
	if (view_as<bool>(StringToInt(isBanned)))
	{
		char targetSteam[32];
		GetClientAuthId(targetIndex, AuthId_Steam2, targetSteam, sizeof(targetSteam));
		
		if (cv_SQLProgram)
		{
			char sQuery[512];
			Format(sQuery, sizeof(sQuery), "UPDATE %s SET timeleft = -1 WHERE offender_steamid = '%s' and timeleft >= 0;", sLogTableName, targetSteam);
			SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, sQuery, targetIndex);
			
			LogMessage("log query: %s", sQuery);
		}
		
		LogMessage("%N has removed the Guard ban on %N (%s).", adminIndex, targetIndex, targetSteam);
		
		switch (bExpired)
		{
			case true: CShowActivity2(adminIndex, JTAG, "%t", "Guard Ban Auto Removed", targetIndex);
			case false: CShowActivity2(adminIndex, JTAG, "%t", "Guard Ban Removed", targetIndex);
		}
		
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "DELETE FROM %s WHERE steamid = '%s';", sTimesTableName, targetSteam);
		SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, sQuery, targetIndex);	
	}
	
	SetClientCookie(targetIndex, cBan_Blue, "0");
}

public Action Command_LiveBan(int client, int args)
{
	if (args > 3)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban <player> <time> <reason>", JTAG);
		return Plugin_Handled;
	}
	
	char target[64];
	GetCmdArg(1, target, sizeof(target));
	
	char sBanTime[32];
	GetCmdArg(2, sBanTime, sizeof(sBanTime));
	
	int iBanTime = StringToInt(sBanTime);
	char sReasonStr[256];
	char sArgPart[256];
	
	for (int arg = 3; arg <= args; arg++)
	{
		GetCmdArg(arg, sArgPart, sizeof(sArgPart));
		Format(sReasonStr, sizeof(sReasonStr), "%s %s", sReasonStr, sArgPart);
	}
	
	char clientName[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml);
	
	if ((target_count != 1))
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	if (target_list[0] && IsClientInGame(target_list[0]))
	{
		if (AreClientCookiesCached(target_list[0]))
		{
			char isBanned[3];
			GetClientCookie(target_list[0], cBan_Blue, isBanned, sizeof(isBanned));
			
			int banFlag = StringToInt(isBanned);	
			
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
	
	return Plugin_Handled;
}

void PerformBan(int client, int admin, int banTime = 0, int reason = 0, char[] manualReason = "")
{
	SetClientCookie(client, cBan_Blue, "1");
	
	char targetSteam[24];
	GetClientAuthId(client, AuthId_Steam2, targetSteam, sizeof(targetSteam));

	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
		
		TF2_ChangeClientTeam(client, TFTeam_Red);
	}
	
	char sReason[128];
	if (strlen(manualReason) > 0)
	{
		Format(sReason, sizeof(sReason), "%s", manualReason);
	}
	else
	{		
		switch (reason)
		{
			case 1: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 1", admin);
			case 2: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 2", admin);
			case 3: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 3", admin);
			case 4: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 4", admin);
			case 5: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 5", admin);
			case 6: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 6", admin);
			case 7: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 7", admin);
			default: Format(sReason, sizeof(sReason), "No reason given.");
		}
	}
	
	int timestamp = GetTime();
	
	char sName_Client[MAX_NAME_LENGTH];
	GetClientName(client, sName_Client, sizeof(sName_Client));
	
	int size = 2 * strlen(sName_Client) + 1;
	char[] sEscapedName = new char[size];
	SQL_EscapeString(BanDatabase, sName_Client, sEscapedName, size + 1);
	
	if (admin && IsClientInGame(admin))
	{
		char sName_Admin[MAX_NAME_LENGTH];
		GetClientName(admin, sName_Admin, sizeof(sName_Admin));
		
		size = 2 * strlen(sName_Admin) + 1;
		char[] sEscapedName2 = new char[size];
		SQL_EscapeString(BanDatabase, sName_Admin, sEscapedName2, size + 1);
		
		char adminSteam[32];
		GetClientAuthId(admin, AuthId_Steam2, adminSteam, sizeof(adminSteam));
		
		if (cv_SQLProgram)
		{
			char logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%s', '%s', '%s', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, sEscapedName, adminSteam, sEscapedName2, banTime, banTime, sReason);
			LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		
		LogMessage("%N (%s) has issued a Guard ban on %N (%s) for %d minutes for %s.", admin, adminSteam, client, targetSteam, banTime, sReason);
	}
	else
	{
		if (cv_SQLProgram)
		{
			char logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, reason) VALUES (%d, '%s', '%s', 'STEAM_0:1:1', 'Console', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, sEscapedName, banTime, banTime, sReason);
			LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		
		LogMessage("Console has issued a Guard ban on %N (%s) for %d.", client, targetSteam, banTime);
	}

	if (banTime > 0)
	{
		CShowActivity2(admin, JTAG, "%t", "Temporary Guard Ban", client, banTime);
		PushArrayCell(TimedBanLocalList, client);
		LocalTimeRemaining[client] = banTime;
		
		if (cv_SQLProgram)
		{
			char query[255];
			Format(query, sizeof(query), "INSERT INTO %s (steamid, ban_time) VALUES ('%s', %d)", sTimesTableName, targetSteam, banTime);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, query, client);
			LogMessage("ctban query: %s", query);
		}
		
		SetArrayCell(TimedBanSteamList, PushArrayString(TimedBanSteamList, targetSteam), banTime, 22);
	}
	else
	{
		CShowActivity2(admin, JTAG, "%t", "Permanent Guard Ban", client);	
	}
}

public Action Command_IsBanned(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban_status <player>", JTAG);
		return Plugin_Handled;
	}
	
	char target[MAX_NAME_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	char sName[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, sName, sizeof(sName), tn_is_ml);
	
	if (target_count != 1) 
	{
		ReplyToTargetError(client, target_count);
	}
	else
	{
		if (target_list[0] && IsClientInGame(target_list[0]))
		{
			if (AreClientCookiesCached(target_list[0]))
			{
				char isBanned[3];
				GetClientCookie(target_list[0], cBan_Blue, isBanned, sizeof(isBanned));
				
				int banFlag = StringToInt(isBanned);	
				
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

public void Client_Authorized(Handle owner, Handle hndl, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	
	if (hndl != null)
	{
		int iRowCount = SQL_GetRowCount(hndl);
		LogMessage("SQL Auth: %d row count", iRowCount);
		
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			
			int iBanTimeRemaining = SQL_FetchInt(hndl, 0);
			LogMessage("SQL Auth: %N joined with %i time remaining on ban", client, iBanTimeRemaining);
			
			PushArrayCell(TimedBanLocalList, client);
			LocalTimeRemaining[client] = iBanTimeRemaining;
		}
	}
	else
	{
		LogError("Error in OnClientAuthorized query: %s", error);
	}
}

public int DB_Callback_CTBan(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl != null)
	{
		if (cv_Debugging && IsClientInGame(client))
		{
			LogMessage("SQL CTBan: Updated database with Guard Ban for %N", client);
		}
	}
	else
	{
		LogError("Error writing CTBan to Timed Ban database: %s", error);
	}
}

public int DB_Callback_RemoveCTBan(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl != null)
	{
		if (cv_Debugging && IsClientInGame(client))
		{
			LogMessage("CTBan on %N was removed in SQL", client);
		}
		else if (cv_Debugging	 && !IsClientInGame(client))
		{
			LogMessage("CTBan on --- was removed in SQL");
		}
	}
	else
	{
		LogError("Error handling steamID after Guard ban removal: %s", error);
	}
}

public int DB_Callback_DisconnectAction(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("Error with updating/deleting record after client disconnect: %s", error);
	}
}

public int DB_Callback_ClientDisconnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
	{
		ResetPack(data);
		
		int client = ReadPackCell(data);
		
		char sAuthID[22];
		ReadPackString(data, sAuthID, sizeof(sAuthID));
		
		CloseHandle(data);
		
		if (SQL_GetRowCount(hndl))
		{
			if (cv_Debugging)
			{
				SQL_FetchRow(hndl);
				int iRemain = SQL_FetchInt(hndl, 0);

				if (IsClientInGame(client))
				{
					LogMessage("SQL: %N disconnected with %i time remaining on ban", client, iRemain);
				}
				else
				{
					LogMessage("SQL: %i client index disconnected with %i time remaining on ban", client, iRemain);
				}
			}

			if (LocalTimeRemaining[client] <= 0)
			{
				char query[255];
				
				Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", sTimesTableName, sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
				
				Format(query, sizeof(query), "UPDATE %s SET timeleft=-1 WHERE offender_steamid = '%s' AND timeleft >= 0", sLogTableName, sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
			}
			else
			{
				char query[255];
				
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

public int DB_Callback_Connect(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("Default database database connection failure: %s", error);
		return;
	}
	
	if (BanDatabase != null)
	{
		CloseHandle(hndl);
		return;
	}
	
	BanDatabase = hndl;
	char sQuery[256];
	
	if (strlen(cv_DatabasePrefix) != 0)
	{
		Format(sTimesTableName, sizeof(sTimesTableName), "tf2jail_bluebans");
	}
	else
	{
		Format(sTimesTableName, sizeof(sTimesTableName), "%s_tf2jail_bluebans", cv_DatabasePrefix);
	}
	
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(22), ban_time INT(16), PRIMARY KEY (steamid))", sTimesTableName);
	SQL_TQuery(BanDatabase, DB_Callback_Create, sQuery); 
	
	if (strlen(cv_DatabasePrefix) != 0)
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

public int DB_Callback_Create(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("Error establishing table creation: %s", error);
		SetFailState("Unable to ascertain creation of table in default database. Exiting.");
	}
}

public int CP_Callback_Connect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
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

public int CP_Callback_FindCookie(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
	{
		int iRowCount = SQL_GetRowCount(hndl);
		
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			
			int CookieIDIndex = SQL_FetchInt(hndl, 0);
			
			LogMessage("found cookie index as %i", CookieIDIndex);
			
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

public int CP_Callback_CheckBan(Handle owner, Handle hndl, const char[] error, any stringPack)
{
	if (hndl != null)
	{
		ResetPack(stringPack);
		
		char authID[22];
		ReadPackString(stringPack, authID, sizeof(authID));
		
		int iAdminIndex = ReadPackCell(stringPack);
		
		int iArrayBanIndex = ReadPackCell(stringPack);
		
		CloseHandle(stringPack);
		
		int iTimeStamp = GetTime();
		
		int iRowCount = SQL_GetRowCount(hndl);
		
		if (iRowCount)
		{
			if (cv_Debugging)
			{
				SQL_FetchRow(hndl);
				int iCTBanStatus = SQL_FetchInt(hndl, 0);
				LogMessage("CTBan status on player is currently %i. Will do UPDATE on %s", iCTBanStatus, authID);
			}

			char query[255];
			Format(query, sizeof(query), "UPDATE sm_cookie_cache SET value = '1', timestamp = %i WHERE player = '%s' AND cookie_id = '%i'", iTimeStamp, authID, iCookieIndex);
			LogMessage("Query to run: %s", query);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
		}
		else
		{
			if (cv_Debugging)
			{
				LogMessage("couldn't find steamID in database, need to INSERT");
			}
			
			char query[255];
			Format(query, sizeof(query), "INSERT INTO sm_cookie_cache (player, cookie_id, value, timestamp) VALUES ('%s', %i, '1', %i)", authID, iCookieIndex, iTimeStamp);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
			
			LogMessage("Query to run: %s", query);
		}
		
		char sTargetName[MAX_TARGET_LENGTH];
		GetArrayString(hArray_RageTables_Name, iArrayBanIndex, sTargetName, sizeof(sTargetName));
		
		int size = 2 * strlen(sTargetName) + 1;
		char[] sTargetNameE = new char[size];
		SQL_EscapeString(BanDatabase, sTargetName, sTargetNameE, size + 1);
		
		char adminSteamID[22];
		GetClientAuthId(iAdminIndex, AuthId_Steam2, adminSteamID, sizeof(adminSteamID));

		if (cv_SQLProgram)
		{
			char logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%s', '%s', 'Console', 0, 0, 'Rage ban')", sLogTableName, iTimeStamp, authID, sTargetNameE, adminSteamID, iAdminIndex);
			LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, iAdminIndex);
		}
		
		LogMessage("%N (%s) has issued a rage ban on %s (%s) indefinitely.", iAdminIndex, adminSteamID, sTargetName, authID);

		CShowActivity2(iAdminIndex, JTAG, "%t", "Rage Ban", sTargetName);

		RemoveFromArray(hArray_RageTables_Name, iArrayBanIndex);
		RemoveFromArray(hArray_RageTables_IDs, iArrayBanIndex);
		LogMessage("Removed %i index from rage ban menu.", iArrayBanIndex);
	}
	else
	{
		LogError("Guard Ban query had a failure: %s", error);
		CloseHandle(stringPack);
	}
}

public int CP_Callback_IssueBan(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
	{
		LogMessage("succesfully wrote to the database");
	}
	else
	{
		LogError("Error writing to database: %s", error);
	}
}

public Action CheckTimedGuardBans(Handle timer)
{
	int iTime = GetArraySize(TimedBanLocalList);
	
	for (int i = 0; i < iTime; i++)
	{
		int client = GetArrayCell(TimedBanLocalList, i);
		
		if (IsClientInGame(client))
		{
			LocalTimeRemaining[client]--;
			
			LogMessage("found alive time banned client with %i remaining", LocalTimeRemaining[client]);
			
			if (LocalTimeRemaining[client] <= 0)
			{
				RemoveFromArray(TimedBanLocalList, i);
				iTime--;
				Remove_CTBan(0, client, true);
				LogMessage("removed Guard ban on %N", client);
			}
		}
	}
}
Handle BanDatabase;
int iCookieIndex;
bool bAuthIdNativeExists;
Handle TimedBanLocalList;
int LocalTimeRemaining[MAXPLAYERS + 1];
Handle TimedBanSteamList;
int GuardBanTargetUserId[MAXPLAYERS + 1];
int GuardBanTimeLength[MAXPLAYERS + 1];
char sLogTableName[32];
char sTimesTableName[32];

bool RoundActive;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail_TeamBans.phrases");

	ConVars[0] = CreateConVar("tf2jail_teambans_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ConVars[1] = CreateConVar("sm_jail_teambans_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_NOTIFY);
	ConVars[2] = CreateConVar("sm_jail_teambans_denysound", "", "Sound file to play when denied. (Relative to the sound folder)",FCVAR_NOTIFY);
	ConVars[3] = CreateConVar("sm_jail_teambans_joinbanmsg", "Please visit our website to appeal.", "Message to the client on join if banned.", FCVAR_NOTIFY);
	ConVars[4] = CreateConVar("sm_jail_teambans_tableprefix", "", "Prefix for database tables. (Can be blank)", FCVAR_NOTIFY);
	ConVars[5] = CreateConVar("sm_jail_teambans_sqldriver", "default", "Config entry to use for database: (default = 'default')", FCVAR_NOTIFY);
	ConVars[6] = CreateConVar("sm_jail_teambans_debug", "1", "Spew debugging information: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ConVars[7] = CreateConVar("sm_jail_teambans_sqlprogram", "1", "SQL Program to use: (1 = MySQL, 0 = SQLite)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	for (int i = 0; i < sizeof(ConVars); i++)
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
	RegAdminCmd("sm_teamban_guardban", Command_CTBanMenu, ADMFLAG_KICK);

	cBan_Blue = RegClientCookie("TF2Jail_TB_Blue", "Is player banned from blue?", CookieAccess_Protected);
	cBan_Red = RegClientCookie("TF2Jail_TB_Red", "Is player banned from red?", CookieAccess_Protected);
	
	if (cBan_Red)
	{

	}
	
	hArray_RageTables_Name = CreateArray(MAX_TARGET_LENGTH);
	hArray_RageTables_IDs = CreateArray(22);
	TimedBanLocalList = CreateArray(2);
	TimedBanSteamList = CreateArray(23);

	for (int i = 1; i <= MaxClients; i++)
	{
		LocalTimeRemaining[i] = 0;
		GuardBanTargetUserId[i] = 0;
	}
	
	CreateTimer(60.0, CheckTimedGuardBans, _, TIMER_REPEAT);
	
	AutoExecConfig();
}

public void OnAllPluginsLoaded()
{
	bAuthIdNativeExists = GetFeatureStatus(FeatureType_Native, "SetAuthIdCookie") == FeatureStatus_Available;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Handles[i] != null)
		{
			CloseHandle(Handles[i]);
			Handles[i] = null;
		}
	}
}

public void OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(ConVars[1]);
	GetConVarString(ConVars[2], cv_DenySound, sizeof(cv_DenySound));
	GetConVarString(ConVars[3], cv_JoinBanMsg, sizeof(cv_JoinBanMsg));
	GetConVarString(ConVars[4], cv_DatabasePrefix, sizeof(cv_DatabasePrefix));
	GetConVarString(ConVars[5], cv_DatabaseConfigEntry, sizeof(cv_DatabaseConfigEntry));
	cv_Debugging = GetConVarBool(ConVars[6]);
	cv_SQLProgram = GetConVarBool(ConVars[7]);
	
	if (BanDatabase == null && strlen(cv_DatabaseConfigEntry) > 0)
	{
		SQL_TConnect(DB_Callback_Connect, cv_DatabaseConfigEntry);
	}
}

public int HandleCvars(Handle hCvar, char[] sOldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if (hCvar == ConVars[0])
	{
		SetConVarString(ConVars[0], PLUGIN_VERSION);
	}
	else if (hCvar == ConVars[1])
	{
		cv_Enabled = view_as<bool>(iNewValue);
	}
	else if (hCvar == ConVars[2])
	{
		strcopy(cv_DenySound, sizeof(cv_DenySound), newValue);
	}
	else if (hCvar == ConVars[3])
	{
		strcopy(cv_JoinBanMsg, sizeof(cv_JoinBanMsg), newValue);
	}
	else if (hCvar == ConVars[4])
	{
		strcopy(cv_DatabasePrefix, sizeof(cv_DatabasePrefix), newValue);
	}
	else if (hCvar == ConVars[5])
	{
		strcopy(cv_DatabaseConfigEntry, sizeof(cv_DatabaseConfigEntry), newValue);
	}
	else if (hCvar == ConVars[6])
	{
		cv_Debugging = view_as<bool>(iNewValue);
	}
	else if (hCvar == ConVars[7])
	{
		cv_SQLProgram = view_as<bool>(iNewValue);
	}
}

public void OnMapStart()
{
   char buffer[PLATFORM_MAX_PATH];
   if (strlen(cv_DenySound) != 0)
   {
		PrecacheSound(cv_DenySound, true);
		Format(buffer, sizeof(buffer), "sound/%s", cv_DenySound);
		AddFileToDownloadsTable(buffer);
   }
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	RoundActive = true;
}

public Action RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	RoundActive = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client))
	{
		return;
	}
		
	int iLookup = FindStringInArray(hArray_RageTables_IDs, auth);
	
	if (iLookup != -1)
	{
		RemoveFromArray(hArray_RageTables_Name, iLookup);
		RemoveFromArray(hArray_RageTables_IDs, iLookup);
		LogMessage("Removed %N from rage tables for reconnecting.", client);
	}
	
	if (cv_SQLProgram && BanDatabase != null)
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT ban_time FROM %s WHERE steamid = '%s';", sTimesTableName, auth);
		SQL_TQuery(BanDatabase, Client_Authorized, sQuery, GetClientUserId(client));
	}
	else
	{
		int iSteamArrayIndex = FindStringInArray(TimedBanSteamList, auth);
		
		if (iSteamArrayIndex != -1)
		{
			LocalTimeRemaining[client] = GetArrayCell(TimedBanSteamList, iSteamArrayIndex, 22);
			LogMessage("%N joined with %i time remaining on ban", client, LocalTimeRemaining[client]);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (cv_Enabled)
	{
		Handles[client] = null;
		CreateTimer(0.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (cv_Enabled)
	{
		return Plugin_Continue;
	}
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{			
		char sCookie[5];
		GetClientCookie(client, cBan_Blue, sCookie, sizeof(sCookie));
		
		if (TF2_GetClientTeam(client) == TFTeam_Blue && view_as<bool>(StringToInt(sCookie)))
		{
			PrintCenterText(client, "%t", "Enforcing Guard Ban");
			CPrintToChat(client, cv_JoinBanMsg);
			
			switch (RoundActive)
			{
				case true: TF2_ChangeClientTeam(client, TFTeam_Spectator);
				case false: TF2_ChangeClientTeam(client, TFTeam_Red);
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	char sDisconnectSteamID[22];
	GetClientAuthId(client, AuthId_Steam2, sDisconnectSteamID, sizeof(sDisconnectSteamID));
	
	if (Handles[client] != null)
	{
		CloseHandle(Handles[client]);
		Handles[client] = null;
	}
	
	char sName[MAX_TARGET_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	
	if (FindStringInArray(hArray_RageTables_IDs, sDisconnectSteamID) == -1)
	{
		PushArrayString(hArray_RageTables_Name, sName);
		PushArrayString(hArray_RageTables_IDs, sDisconnectSteamID);
		
		if (GetArraySize(hArray_RageTables_Name) >= 7)
		{
			RemoveFromArray(hArray_RageTables_Name, 0);
			RemoveFromArray(hArray_RageTables_IDs, 0);
		}
	}
	
	int iBannedArrayIndex = FindValueInArray(TimedBanLocalList, client);
	
	if (iBannedArrayIndex != -1)
	{
		RemoveFromArray(TimedBanLocalList, iBannedArrayIndex);
		
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, client);
		WritePackString(hPack, sDisconnectSteamID);
		
		if (cv_SQLProgram)
		{
			char sQuery[256];
			Format(sQuery, sizeof(sQuery), "SELECT ban_time FROM %s WHERE steamid = '%s';", sTimesTableName, sDisconnectSteamID);
			SQL_TQuery(BanDatabase, DB_Callback_ClientDisconnect, sQuery, hPack);
		}
		else
		{
			int iSteamArrayIndex = FindStringInArray(TimedBanSteamList, sDisconnectSteamID);
			
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

void DisplayRageBanMenu(int client)
{
	int RageTablesSize = GetArraySize(hArray_RageTables_Name);
	
	if (RageTablesSize == 0)
	{
		CPrintToChat(client, "%s %t", JTAG, "No Targets");
		return;
	}
	
	Handle hMenu = CreateMenu(MenuHandler_RageBan);
	
	SetMenuTitle(hMenu, "%T", "Rage Ban Menu Title", client);
	SetMenuExitBackButton(hMenu, true);
	
	for (int i = 0; i < RageTablesSize; i++)
	{
		char sName[MAX_TARGET_LENGTH];
		GetArrayString(hArray_RageTables_Name, i, sName, sizeof(sName));
		
		char sSteamID[32];
		GetArrayString(hArray_RageTables_IDs, i, sSteamID, sizeof(sSteamID));
		
		AddMenuItem(hMenu, sSteamID, sName);
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_RageBan(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sInfoString[22];
				GetMenuItem(menu, param2, sInfoString, sizeof(sInfoString));
				
				if (bAuthIdNativeExists)
				{
					SetAuthIdCookie(sInfoString, cBan_Blue, "1");
				}
				else
				{
					if (CP_DataBase != null)
					{
						char sQuery[256];
						Format(sQuery, sizeof(sQuery), "SELECT value FROM sm_cookie_cache WHERE player = '%s' and cookie_id = '%i';", sInfoString, iCookieIndex);
						
						Handle TheDataPack = CreateDataPack();
						WritePackString(TheDataPack, sInfoString);
						WritePackCell(TheDataPack, param1);
						WritePackCell(TheDataPack, param2);
						
						SQL_TQuery(CP_DataBase, CP_Callback_CheckBan, sQuery, TheDataPack); 
					}
				}
				
				CPrintToChat(param1, "%s %t", JTAG, "Ready to Guard Ban", sInfoString);
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action Command_Offline_Ban(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban_offline <steamid>", JTAG);
		return Plugin_Handled;
	}
	
	char sAuthId[32];
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

public Action Command_Offline_Unban(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamunban_offline <steamid>", JTAG);
		return Plugin_Handled;
	}
	
	char sAuthId[32];
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

public Action Command_RageBan(int client, int args)
{
	int iArraySize = GetArraySize(hArray_RageTables_Name);
	
	if (iArraySize == 0)
	{
		CReplyToCommand(client, "%s %t", JTAG, "No Targets");
		return Plugin_Handled;
	}
	
	if (IsClientInGame(client))
	{
		DisplayRageBanMenu(client);
	}
	else
	{
		CReplyToCommand(client, "%s %t", JTAG, "Feature Not Available On Console");
	}
	
	return Plugin_Handled;
}

public Action Command_CTBanMenu(int client, int args)
{
	DisplayCTBanPlayerMenu(client);
	return Plugin_Handled;
}

void DisplayCTBanPlayerMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_CTBanPlayerList);
	
	SetMenuTitle(menu, "%T", "Guard Ban Menu Title", client);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void DisplayCTBanTimeMenu(int client, int targetUserId)
{
	Handle menu = CreateMenu(MenuHandler_CTBanTimeList);

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

void DisplayCTBanReasonMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_CTBanReasonList);

	SetMenuTitle(menu, "%T", "Guard Ban Reason Menu", client, GetClientOfUserId(GuardBanTargetUserId[client]));
	SetMenuExitBackButton(menu, true);

	char sMenuReason[128];
	
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

public int MenuHandler_CTBanReasonList(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sBanChoice[12];
				GetMenuItem(menu, param2, sBanChoice, sizeof(sBanChoice));
				
				int iBanReason = StringToInt(sBanChoice);
				int iTimeToBan = GuardBanTimeLength[param1];
				int iTargetIndex = GetClientOfUserId(GuardBanTargetUserId[param1]);
				
				char sBanned[32];
				GetClientCookie(iTargetIndex, cBan_Blue, sBanned, sizeof(sBanned));
				
				int banFlag = StringToInt(sBanned);
				
				if (!banFlag)
				{
					PerformBan(iTargetIndex, param1, iTimeToBan, iBanReason);
				}
				else
				{
					CPrintToChat(param1, "%s %t", JTAG, "Already Guard Banned", iTargetIndex);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public int MenuHandler_CTBanPlayerList(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char info[32];
				GetMenuItem(menu, param2, info, sizeof(info));
				int userid = StringToInt(info);
				int target;

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
		case MenuAction_End: CloseHandle(menu);
	}
}

public int MenuHandler_CTBanTimeList(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char info[32];
				GetMenuItem(menu, param2, info, sizeof(info));
				int iTimeToBan = StringToInt(info);
				
				GuardBanTimeLength[param1] = iTimeToBan;
				DisplayCTBanReasonMenu(param1);
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action CheckBanCookies(Handle timer, any client)
{
	if (AreClientCookiesCached(client))
	{
		ProcessBanCookies(client);
	}
	else if (IsClientInGame(client))
	{
		CreateTimer(5.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ProcessBanCookies(int client)
{
	if (IsClientInGame(client))
	{
		char cookie[32];
		GetClientCookie(client, cBan_Blue, cookie, sizeof(cookie));
		
		if (StrEqual(cookie, "1") && TF2_GetClientTeam(client) == TFTeam_Blue) 
		{
			if (IsPlayerAlive(client))
			{
				int wepIdx;
				for (int i; i < 4; i++)
				{
					if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
					{
						RemovePlayerItem(client, wepIdx);
						AcceptEntityInput(wepIdx, "Kill");
					}
				}
			
				ForcePlayerSuicide(client);
			}
			
			TF2_ChangeClientTeam(client, TFTeam_Red);
			CPrintToChat(client, "%s %t", JTAG, "Enforcing Guard Ban");	
		}
	}
}

public Action Command_LiveUnban(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamunban <player>", JTAG);
		return Plugin_Handled;
	}
		
	char target[64];
	GetCmdArg(1, target, sizeof(target));
	
	char clientName[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml);
	
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

void Remove_CTBan(int adminIndex, int targetIndex, bool bExpired = false)
{
	char isBanned[12];
	GetClientCookie(targetIndex, cBan_Blue, isBanned, sizeof(isBanned));
	
	if (view_as<bool>(StringToInt(isBanned)))
	{
		char targetSteam[32];
		GetClientAuthId(targetIndex, AuthId_Steam2, targetSteam, sizeof(targetSteam));
		
		if (cv_SQLProgram)
		{
			char sQuery[512];
			Format(sQuery, sizeof(sQuery), "UPDATE %s SET timeleft = -1 WHERE offender_steamid = '%s' and timeleft >= 0;", sLogTableName, targetSteam);
			SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, sQuery, targetIndex);
			
			LogMessage("log query: %s", sQuery);
		}
		
		LogMessage("%N has removed the Guard ban on %N (%s).", adminIndex, targetIndex, targetSteam);
		
		switch (bExpired)
		{
			case true: CShowActivity2(adminIndex, JTAG, "%t", "Guard Ban Auto Removed", targetIndex);
			case false: CShowActivity2(adminIndex, JTAG, "%t", "Guard Ban Removed", targetIndex);
		}
		
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "DELETE FROM %s WHERE steamid = '%s';", sTimesTableName, targetSteam);
		SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, sQuery, targetIndex);	
	}
	
	SetClientCookie(targetIndex, cBan_Blue, "0");
}

public Action Command_LiveBan(int client, int args)
{
	if (args > 3)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban <player> <time> <reason>", JTAG);
		return Plugin_Handled;
	}
	
	char target[64];
	GetCmdArg(1, target, sizeof(target));
	
	char sBanTime[32];
	GetCmdArg(2, sBanTime, sizeof(sBanTime));
	
	int iBanTime = StringToInt(sBanTime);
	char sReasonStr[256];
	char sArgPart[256];
	
	for (int arg = 3; arg <= args; arg++)
	{
		GetCmdArg(arg, sArgPart, sizeof(sArgPart));
		Format(sReasonStr, sizeof(sReasonStr), "%s %s", sReasonStr, sArgPart);
	}
	
	char clientName[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml);
	
	if ((target_count != 1))
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	if (target_list[0] && IsClientInGame(target_list[0]))
	{
		if (AreClientCookiesCached(target_list[0]))
		{
			char isBanned[3];
			GetClientCookie(target_list[0], cBan_Blue, isBanned, sizeof(isBanned));
			
			int banFlag = StringToInt(isBanned);	
			
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
	
	return Plugin_Handled;
}

void PerformBan(int client, int admin, int banTime = 0, int reason = 0, char[] manualReason = "")
{
	SetClientCookie(client, cBan_Blue, "1");
	
	char targetSteam[24];
	GetClientAuthId(client, AuthId_Steam2, targetSteam, sizeof(targetSteam));

	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
		
		TF2_ChangeClientTeam(client, TFTeam_Red);
	}
	
	char sReason[128];
	if (strlen(manualReason) > 0)
	{
		Format(sReason, sizeof(sReason), "%s", manualReason);
	}
	else
	{		
		switch (reason)
		{
			case 1: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 1", admin);
			case 2: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 2", admin);
			case 3: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 3", admin);
			case 4: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 4", admin);
			case 5: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 5", admin);
			case 6: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 6", admin);
			case 7: Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 7", admin);
			default: Format(sReason, sizeof(sReason), "No reason given.");
		}
	}
	
	int timestamp = GetTime();
	
	if (admin && IsClientInGame(admin))
	{
		char adminSteam[32];
		GetClientAuthId(admin, AuthId_Steam2, adminSteam, sizeof(adminSteam));
		
		if (cv_SQLProgram)
		{
			char logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%N', '%s', '%N', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, client, adminSteam, admin, banTime, banTime, sReason);
			LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		
		LogMessage("%N (%s) has issued a Guard ban on %N (%s) for %d minutes for %s.", admin, adminSteam, client, targetSteam, banTime, sReason);
	}
	else
	{
		if (cv_SQLProgram)
		{
			char logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, reason) VALUES (%d, '%s', '%N', 'STEAM_0:1:1', 'Console', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, client, banTime, banTime, sReason);
			LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		
		LogMessage("Console has issued a Guard ban on %N (%s) for %d.", client, targetSteam, banTime);
	}

	if (banTime > 0)
	{
		CShowActivity2(admin, JTAG, "%t", "Temporary Guard Ban", client, banTime);
		PushArrayCell(TimedBanLocalList, client);
		LocalTimeRemaining[client] = banTime;
		
		if (cv_SQLProgram)
		{
			char query[255];
			Format(query, sizeof(query), "INSERT INTO %s (steamid, ban_time) VALUES ('%s', %d)", sTimesTableName, targetSteam, banTime);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, query, client);
			LogMessage("ctban query: %s", query);
		}
		
		SetArrayCell(TimedBanSteamList, PushArrayString(TimedBanSteamList, targetSteam), banTime, 22);
	}
	else
	{
		CShowActivity2(admin, JTAG, "%t", "Permanent Guard Ban", client);	
	}
}

public Action Command_IsBanned(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%s Usage: sm_teamban_status <player>", JTAG);
		return Plugin_Handled;
	}
	
	char target[MAX_NAME_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	char sName[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, sName, sizeof(sName), tn_is_ml);
	
	if (target_count != 1) 
	{
		ReplyToTargetError(client, target_count);
	}
	else
	{
		if (target_list[0] && IsClientInGame(target_list[0]))
		{
			if (AreClientCookiesCached(target_list[0]))
			{
				char isBanned[3];
				GetClientCookie(target_list[0], cBan_Blue, isBanned, sizeof(isBanned));
				
				int banFlag = StringToInt(isBanned);	
				
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

public void Client_Authorized(Handle owner, Handle hndl, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	
	if (hndl != null)
	{
		int iRowCount = SQL_GetRowCount(hndl);
		LogMessage("SQL Auth: %d row count", iRowCount);
		
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			
			int iBanTimeRemaining = SQL_FetchInt(hndl, 0);
			LogMessage("SQL Auth: %N joined with %i time remaining on ban", client, iBanTimeRemaining);
			
			PushArrayCell(TimedBanLocalList, client);
			LocalTimeRemaining[client] = iBanTimeRemaining;
		}
	}
	else
	{
		LogError("Error in OnClientAuthorized query: %s", error);
	}
}

public int DB_Callback_CTBan(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl != null)
	{
		if (cv_Debugging && IsClientInGame(client))
		{
			LogMessage("SQL CTBan: Updated database with Guard Ban for %N", client);
		}
	}
	else
	{
		LogError("Error writing CTBan to Timed Ban database: %s", error);
	}
}

public int DB_Callback_RemoveCTBan(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl != null)
	{
		if (cv_Debugging && IsClientInGame(client))
		{
			LogMessage("CTBan on %N was removed in SQL", client);
		}
		else if (cv_Debugging	 && !IsClientInGame(client))
		{
			LogMessage("CTBan on --- was removed in SQL");
		}
	}
	else
	{
		LogError("Error handling steamID after Guard ban removal: %s", error);
	}
}

public int DB_Callback_DisconnectAction(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("Error with updating/deleting record after client disconnect: %s", error);
	}
}

public int DB_Callback_ClientDisconnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
	{
		ResetPack(data);
		
		int client = ReadPackCell(data);
		
		char sAuthID[22];
		ReadPackString(data, sAuthID, sizeof(sAuthID));
		
		CloseHandle(data);
		
		if (SQL_GetRowCount(hndl))
		{
			if (cv_Debugging)
			{
				SQL_FetchRow(hndl);
				int iRemain = SQL_FetchInt(hndl, 0);

				if (IsClientInGame(client))
				{
					LogMessage("SQL: %N disconnected with %i time remaining on ban", client, iRemain);
				}
				else
				{
					LogMessage("SQL: %i client index disconnected with %i time remaining on ban", client, iRemain);
				}
			}

			if (LocalTimeRemaining[client] <= 0)
			{
				char query[255];
				
				Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", sTimesTableName, sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
				
				Format(query, sizeof(query), "UPDATE %s SET timeleft=-1 WHERE offender_steamid = '%s' AND timeleft >= 0", sLogTableName, sAuthID);
				SQL_TQuery(BanDatabase, DB_Callback_DisconnectAction, query);
			}
			else
			{
				char query[255];
				
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

public int DB_Callback_Connect(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("Default database database connection failure: %s", error);
		return;
	}
	
	if (BanDatabase != null)
	{
		CloseHandle(hndl);
		return;
	}
	
	BanDatabase = hndl;
	char sQuery[256];
	
	if (strlen(cv_DatabasePrefix) != 0)
	{
		Format(sTimesTableName, sizeof(sTimesTableName), "tf2jail_bluebans");
	}
	else
	{
		Format(sTimesTableName, sizeof(sTimesTableName), "%s_tf2jail_bluebans", cv_DatabasePrefix);
	}
	
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(22), ban_time INT(16), PRIMARY KEY (steamid))", sTimesTableName);
	SQL_TQuery(BanDatabase, DB_Callback_Create, sQuery); 
	
	if (strlen(cv_DatabasePrefix) != 0)
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

public int DB_Callback_Create(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("Error establishing table creation: %s", error);
		SetFailState("Unable to ascertain creation of table in default database. Exiting.");
	}
}

public int CP_Callback_Connect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
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

public int CP_Callback_FindCookie(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
	{
		int iRowCount = SQL_GetRowCount(hndl);
		
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			
			int CookieIDIndex = SQL_FetchInt(hndl, 0);
			
			LogMessage("found cookie index as %i", CookieIDIndex);
			
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

public int CP_Callback_CheckBan(Handle owner, Handle hndl, const char[] error, any stringPack)
{
	if (hndl != null)
	{
		ResetPack(stringPack);
		
		char authID[22];
		ReadPackString(stringPack, authID, sizeof(authID));
		
		int iAdminIndex = ReadPackCell(stringPack);
		
		int iArrayBanIndex = ReadPackCell(stringPack);
		
		CloseHandle(stringPack);
		
		int iTimeStamp = GetTime();
		
		int iRowCount = SQL_GetRowCount(hndl);
		
		if (iRowCount)
		{
			if (cv_Debugging)
			{
				SQL_FetchRow(hndl);
				int iCTBanStatus = SQL_FetchInt(hndl, 0);
				LogMessage("CTBan status on player is currently %i. Will do UPDATE on %s", iCTBanStatus, authID);
			}

			char query[255];
			Format(query, sizeof(query), "UPDATE sm_cookie_cache SET value = '1', timestamp = %i WHERE player = '%s' AND cookie_id = '%i'", iTimeStamp, authID, iCookieIndex);
			LogMessage("Query to run: %s", query);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
		}
		else
		{
			if (cv_Debugging)
			{
				LogMessage("couldn't find steamID in database, need to INSERT");
			}
			
			char query[255];
			Format(query, sizeof(query), "INSERT INTO sm_cookie_cache (player, cookie_id, value, timestamp) VALUES ('%s', %i, '1', %i)", authID, iCookieIndex, iTimeStamp);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
			
			LogMessage("Query to run: %s", query);
		}
		
		char sTargetName[MAX_TARGET_LENGTH];
		GetArrayString(hArray_RageTables_Name, iArrayBanIndex, sTargetName, sizeof(sTargetName));
		
		char adminSteamID[22];
		GetClientAuthId(iAdminIndex, AuthId_Steam2, adminSteamID, sizeof(adminSteamID));

		if (cv_SQLProgram)
		{
			char logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%s', '%s', 'Console', 0, 0, 'Rage ban')", sLogTableName, iTimeStamp, authID, sTargetName, adminSteamID, iAdminIndex);
			LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, iAdminIndex);
		}
		
		LogMessage("%N (%s) has issued a rage ban on %s (%s) indefinitely.", iAdminIndex, adminSteamID, sTargetName, authID);

		CShowActivity2(iAdminIndex, JTAG, "%t", "Rage Ban", sTargetName);

		RemoveFromArray(hArray_RageTables_Name, iArrayBanIndex);
		RemoveFromArray(hArray_RageTables_IDs, iArrayBanIndex);
		LogMessage("Removed %i index from rage ban menu.", iArrayBanIndex);
	}
	else
	{
		LogError("Guard Ban query had a failure: %s", error);
		CloseHandle(stringPack);
	}
}

public int CP_Callback_IssueBan(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl != null)
	{
		LogMessage("succesfully wrote to the database");
	}
	else
	{
		LogError("Error writing to database: %s", error);
	}
}

public Action CheckTimedGuardBans(Handle timer)
{
	int iTime = GetArraySize(TimedBanLocalList);
	
	for (int i = 0; i < iTime; i++)
	{
		int client = GetArrayCell(TimedBanLocalList, i);
		
		if (IsClientInGame(client))
		{
			LocalTimeRemaining[client]--;
			
			LogMessage("found alive time banned client with %i remaining", LocalTimeRemaining[client]);
			
			if (LocalTimeRemaining[client] <= 0)
			{
				RemoveFromArray(TimedBanLocalList, i);
				iTime--;
				Remove_CTBan(0, client, true);
				LogMessage("removed Guard ban on %N", client);
			}
		}
	}
}
