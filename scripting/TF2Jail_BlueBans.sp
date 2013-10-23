/*
	https://forums.alliedmods.net/showthread.php?p=1544101
	
	Cheers to Databomb for his plugin code, I basically just took it and fixed it up for TF2.
	All the same rules and licensing apply.
*/

#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#include <autoexecconfig>
#include <TF2Jail>
#include <tf2items>
#include <banning>

//Optional Extensions
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

//Optional Plugins
#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <adminmenu>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME     "[TF2] Jailbreak - Bans"												//Plugin name
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"											//Plugin author
#define PLUGIN_VERSION  "4.9.7"																	//Plugin version
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."									//Plugin description
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"											//Plugin contact URL

#define CLAN_TAG_COLOR	"{community}[TF2Jail-Bans]"
#define CLAN_TAG		"[TF2Jail-Bans]"

new Handle:JBB_Cvar_Enabled = INVALID_HANDLE;
new Handle:JBB_Cvar_SoundName = INVALID_HANDLE;
new Handle:JBB_Cvar_JoinBanMessage = INVALID_HANDLE;
new Handle:JBB_Cvar_Database_Driver = INVALID_HANDLE;
new Handle:JBB_Cvar_Debugger = INVALID_HANDLE;
new Handle:JBB_Cvar_MySQL = INVALID_HANDLE;
new Handle:JBB_Cvar_Table_Prefix = INVALID_HANDLE;

new Handle:Guard_Cookie = INVALID_HANDLE;
new Handle:Handles[MAXPLAYERS+1];
new Handle:TopMenu = INVALID_HANDLE;
new String:SoundPath[PLATFORM_MAX_PATH];
new Handle:DNames = INVALID_HANDLE;
new Handle:DSteamIDs = INVALID_HANDLE;
new Handle:CP_DataBase = INVALID_HANDLE;
new Handle:BanDatabase = INVALID_HANDLE;
new iCookieIndex;
new bool:bAuthIdNativeExists = false;
new Handle:TimedBanLocalList = INVALID_HANDLE;
new LocalTimeRemaining[MAXPLAYERS+1];
new Handle:TimedBanSteamList = INVALID_HANDLE;
new GuardBanTargetUserId[MAXPLAYERS+1];
new GuardBanTimeLength[MAXPLAYERS+1];
new String:sLogTableName[32];
new String:sTimesTableName[32];
new bool:debugging;
new bool:mysql_cvar = true;

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
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail_BlueBans.phrases");

	CreateConVar("tf2jail_bluebans_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	JBB_Cvar_Enabled = CreateConVar("sm_jail_blueban_enable","1","Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN);
	JBB_Cvar_SoundName = CreateConVar("sm_jail_blueban_denysound", "", "Sound to play on join denied: (def: none)",FCVAR_PLUGIN);
	JBB_Cvar_JoinBanMessage = CreateConVar("sm_jail_blueban_joinbanmsg", "Please visit our website to appeal.", "Text to give the client on join banned: (def: Please visit our website to appeal.)", FCVAR_PLUGIN);
	JBB_Cvar_Table_Prefix = CreateConVar("sm_jail_blueban_tableprefix", "", "Prefix for database to use: (def: none)", FCVAR_PLUGIN);
	JBB_Cvar_Database_Driver = CreateConVar("sm_jail_blueban_sqldriver", "default", "Name of the sql driver to use: (def: default)", FCVAR_PLUGIN);
	JBB_Cvar_Debugger = CreateConVar("sm_jail_blueban_debug", "1", "Debugging logs status: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JBB_Cvar_MySQL = CreateConVar("sm_jail_blueban_sqlprogram", "1", "(1 = MySQL, 0 = SQLite)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_win", RoundEnd);

	AutoExecConfig(true, "TF2Jail_BlueBans");

	RegAdminCmd("sm_banguard", Command_LiveBan, ADMFLAG_SLAY, "sm_banguard <player> <optional: time> - Bans a player from guards(blue) team.");
	RegAdminCmd("sm_banstatus", Command_IsBanned, ADMFLAG_GENERIC, "sm_banstatus <player> - Gives you information if player is banned or not from guards(blue) team.");
	RegAdminCmd("sm_unbanguard", Command_LiveUnban, ADMFLAG_SLAY, "sm_unbanguard <player> - Unbans a player from guards(blue) team.");
	RegAdminCmd("sm_ragebanguard", Command_RageBan, ADMFLAG_SLAY, "sm_ragebanguard <player> - Lists recently disconnected players and allows you to ban them from guards(blue) team.");
	RegAdminCmd("sm_banguard_offline", Command_Offline_Ban, ADMFLAG_KICK, "sm_banguard_offline <steamid> - Allows admins to ban players while not on the server from guards(blue) team.");
	RegAdminCmd("sm_unbanguard_offline", Command_Offline_Unban, ADMFLAG_KICK, "sm_unbanguard_offline <steamid> - Allows admins to unban players while not on the server from guards(blue) team.");

	Guard_Cookie = RegClientCookie("TF2Jail_GuardBanned", "Are you banned from blue team? This cookies gives the information.", CookieAccess_Protected);

	DNames = CreateArray(MAX_TARGET_LENGTH);
	DSteamIDs = CreateArray(22);
	TimedBanLocalList = CreateArray(2);
	iCookieIndex = 0;

	for (new idx = 1; idx <= MaxClients; idx++)
	{
		LocalTimeRemaining[idx] = 0;
		GuardBanTargetUserId[idx] = 0;
	}

	TimedBanSteamList = CreateArray(23);
		
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	CreateTimer(60.0, CheckTimedGuardBans, _, TIMER_REPEAT);
}

public OnAllPluginsLoaded()
{
	bAuthIdNativeExists = IsSetAuthIdNativePresent();
}

public OnClientAuthorized(client, const String:sSteamID[])
{
	new iNeedle = FindStringInArray(DSteamIDs, sSteamID);
	if (iNeedle != -1)
	{
		RemoveFromArray(DNames, iNeedle);
		RemoveFromArray(DSteamIDs, iNeedle);
		if (debugging) LogMessage("removed %N from Rage Bannable player list for re-connecting to the server", client);
	}
	
	if (mysql_cvar)
	{
		decl String:query[255];
		Format(query, sizeof(query), "SELECT ban_time FROM %s WHERE steamid = '%s'", sTimesTableName, sSteamID);
		SQL_TQuery(BanDatabase, DB_Callback_OnClientAuthed, query, _:client);
	}
	else
	{
		new iSteamArrayIndex = FindStringInArray(TimedBanSteamList, sSteamID);
		if (iSteamArrayIndex != -1)
		{
			LocalTimeRemaining[client] = GetArrayCell(TimedBanSteamList, iSteamArrayIndex, 22);
			if (debugging) LogMessage("%N joined with %i time remaining on ban", client, LocalTimeRemaining[client]);
		}
	}
}

public DB_Callback_OnClientAuthed(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error in OnClientAuthorized query: %s", error);
	}
	else
	{
		new iRowCount = SQL_GetRowCount(hndl);
		if (debugging) LogMessage("SQL Auth: %d row count", iRowCount);
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			new iBanTimeRemaining = SQL_FetchInt(hndl, 0);
			if (debugging) LogMessage("SQL Auth: %N joined with %i time remaining on ban", client, iBanTimeRemaining);
			PushArrayCell(TimedBanLocalList, client);
			LocalTimeRemaining[client] = iBanTimeRemaining;
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
	if (ArraySize == 0)
	{
		PrintToChat(Client, "%s %t", CLAN_TAG, "No Targets");
	}
	else
	{
		new Handle:menu = CreateMenu(MenuHandler_RageBan);
		
		SetMenuTitle(menu, "%T", "Rage Ban Menu Title", Client);
		SetMenuExitBackButton(menu, true);

		for (new ArrayIndex = 0; ArrayIndex < ArraySize; ArrayIndex++)
		{
			decl String:sName[MAX_TARGET_LENGTH];
			GetArrayString(DNames, ArrayIndex, sName, sizeof(sName));
			decl String:sSteamID[22];
			GetArrayString(DSteamIDs, ArrayIndex, sSteamID, sizeof(sSteamID));
			AddMenuItem(menu, sSteamID, sName);
		}
		
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_RageBan(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			{
				CloseHandle(menu);
			}
		case MenuAction_Cancel:
			{
				if ((param2 == MenuCancel_ExitBack) && (TopMenu != INVALID_HANDLE))
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_Select:
			{
				decl String:sInfoString[22];
				GetMenuItem(menu, param2, sInfoString, sizeof(sInfoString));
				
				if (bAuthIdNativeExists)
				{
					SetAuthIdCookie(sInfoString, Guard_Cookie, "1");
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
				if (debugging) PrintToChat(param1, "%s %t", CLAN_TAG, "Ready to Guard Ban", sInfoString);
			}
	}
}

public CP_Callback_CheckBan(Handle:owner, Handle:hndl, const String:error[], any:stringPack)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Guard Ban query had a failure: %s", error);
		CloseHandle(stringPack);
	}
	else
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
			if (debugging)
			{
				SQL_FetchRow(hndl);
				new iCTBanStatus = SQL_FetchInt(hndl, 0);
				LogMessage("CTBan status on player is currently %i. Will do UPDATE on %s", iCTBanStatus, authID);
			}

			decl String:query[255];
			Format(query, sizeof(query), "UPDATE sm_cookie_cache SET value = '1', timestamp = %i WHERE player = '%s' AND cookie_id = '%i'", iTimeStamp, authID, iCookieIndex);
			if (debugging) LogMessage("Query to run: %s", query);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
		}
		else
		{
			if (debugging) LogMessage("couldn't find steamID in database, need to INSERT");
			decl String:query[255];
			Format(query, sizeof(query), "INSERT INTO sm_cookie_cache (player, cookie_id, value, timestamp) VALUES ('%s', %i, '1', %i)", authID, iCookieIndex, iTimeStamp);
			if (debugging) LogMessage("Query to run: %s", query);
			SQL_TQuery(CP_DataBase, CP_Callback_IssueBan, query);
		}
		
		decl String:sTargetName[MAX_TARGET_LENGTH];
		GetArrayString(DNames, iArrayBanIndex, sTargetName, sizeof(sTargetName));
		decl String:adminSteamID[22];
		GetClientAuthString(iAdminIndex, adminSteamID, sizeof(adminSteamID));

		if (mysql_cvar)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%s', '%s', 'Console', 0, 0, 'Rage ban')", sLogTableName, iTimeStamp, authID, sTargetName, adminSteamID, iAdminIndex);
			if (debugging) LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, iAdminIndex);
		}
		
		LogMessage("%N (%s) has issued a rage ban on %s (%s) indefinitely.", iAdminIndex, adminSteamID, sTargetName, authID);

		ShowActivity2(iAdminIndex, CLAN_TAG, "%t", "Rage Ban", sTargetName);

		RemoveFromArray(DNames, iArrayBanIndex);
		RemoveFromArray(DSteamIDs, iArrayBanIndex);
		if (debugging) LogMessage("Removed %i index from rage ban menu.", iArrayBanIndex);
	}
}

public CP_Callback_IssueBan(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error writing to database: %s", error);
	}
	else
	{
		if (debugging) LogMessage("succesfully wrote to the database");
	}
}

public Action:Command_Offline_Ban(client, args)
{
	decl String:sAuthId[32];
	GetCmdArgString(sAuthId, sizeof(sAuthId));
	if (bAuthIdNativeExists)
	{
		SetAuthIdCookie(sAuthId, Guard_Cookie, "1");
		ReplyToCommand(client, "%s %t", CLAN_TAG, "Banned AuthId", sAuthId);
	}
	else
	{
		ReplyToCommand(client, "%s %t", CLAN_TAG, "Feature Not Available");
	}
	return Plugin_Handled;
}

public Action:Command_Offline_Unban(client, args)
{
	decl String:sAuthId[32];
	GetCmdArgString(sAuthId, sizeof(sAuthId));
	if (bAuthIdNativeExists)
	{
		SetAuthIdCookie(sAuthId, Guard_Cookie, "0");
		ReplyToCommand(client, "%s %t", CLAN_TAG, "Unbanned AuthId", sAuthId);
	}
	else
	{
		ReplyToCommand(client, "%s %t", CLAN_TAG, "Feature Not Available");
	}
	return Plugin_Handled;
}

public Action:Command_RageBan(client, args)
{
	new iArraySize = GetArraySize(DNames);
	if (iArraySize == 0)
	{
		ReplyToCommand(client, "%s %t", CLAN_TAG, "No Targets");
		return Plugin_Handled;
	}
	
	if (!args)
	{
		if (client)
		{
			DisplayRageBanMenu(client, iArraySize);
		}
		else
		{
			ReplyToCommand(client, "%s %t", CLAN_TAG, "Feature Not Available On Console");
		}
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "%s Usage: sm_rageban", CLAN_TAG);
	}
	
	return Plugin_Handled;
}

public Action:CheckTimedGuardBans(Handle:timer)
{
	new iTimeArraySize = GetArraySize(TimedBanLocalList);
	
	for (new idx = 0; idx < iTimeArraySize; idx++)
	{
		new iBannedClientIndex = GetArrayCell(TimedBanLocalList, idx);
		if (IsClientInGame(iBannedClientIndex))
		{
			if (IsPlayerAlive(iBannedClientIndex))
			{
				LocalTimeRemaining[iBannedClientIndex]--;
				if (debugging) LogMessage("found alive time banned client with %i remaining", LocalTimeRemaining[iBannedClientIndex]);
				if (LocalTimeRemaining[iBannedClientIndex] <= 0)
				{
					RemoveFromArray(TimedBanLocalList, idx);
					iTimeArraySize--;
					Remove_CTBan(0, iBannedClientIndex, true);
					if (debugging) LogMessage("removed Guard ban on %N", iBannedClientIndex);
				}
			}
		}
	}
}

public OnConfigsExecuted()
{
	debugging = GetConVarBool(JBB_Cvar_Debugger);
	mysql_cvar = GetConVarBool(JBB_Cvar_MySQL);

	SQL_TConnect(CP_Callback_Connect, "clientprefs");
	
	decl String:sDatabaseDriver[64];
	GetConVarString(JBB_Cvar_Database_Driver, sDatabaseDriver, sizeof(sDatabaseDriver));
	SQL_TConnect(DB_Callback_Connect, sDatabaseDriver);
}

public DB_Callback_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Default database database connection failure: %s", error);
		SetFailState("Error while connecting to default database. Exiting.");
	}
	else
	{
		BanDatabase = hndl;
		
		decl String:sPrefix[64];
		GetConVarString(JBB_Cvar_Table_Prefix, sPrefix, sizeof(sPrefix));
		if (strlen(sPrefix) > 0)
		{
			Format(sTimesTableName, sizeof(sTimesTableName), "%s_tf2jail_bluebans", sPrefix);
		}
		else
		{
			Format(sTimesTableName, sizeof(sTimesTableName), "tf2jail_bluebans");
		}
		
		decl String:sQuery[255];
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(22), ban_time INT(16), PRIMARY KEY (steamid))", sTimesTableName);
		
		SQL_TQuery(BanDatabase, DB_Callback_Create, sQuery); 
		
		if (strlen(sPrefix) > 0)
		{
			Format(sLogTableName, sizeof(sLogTableName), "%s_tf2jail_blueban_logs", sPrefix);
		}
		else
		{
			Format(sLogTableName, sizeof(sLogTableName), "tf2jail_blueban_logs");
		}
		
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (timestamp INT, offender_steamid VARCHAR(22), offender_name VARCHAR(32), admin_steamid VARCHAR(22), admin_name VARCHAR(32), bantime INT(16), timeleft INT(16), reason VARCHAR(200), PRIMARY KEY (timestamp))", sLogTableName);
		SQL_TQuery(BanDatabase, DB_Callback_Create, sQuery);
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
	if (hndl == INVALID_HANDLE)
	{
		LogError("Clientprefs database connection failure: %s", error);
		SetFailState("Error while connecting to clientprefs database. Exiting.");
	}
	else
	{
		CP_DataBase = hndl;
		
		SQL_TQuery(CP_DataBase, CP_Callback_FindCookie, "SELECT id FROM sm_cookies WHERE name = 'TF2Jail_GuardBanned'");
	}
}

public CP_Callback_FindCookie(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Cookie query failure: %s", error);
	}
	else
	{
		new iRowCount = SQL_GetRowCount(hndl);
		if (iRowCount)
		{
			SQL_FetchRow(hndl);
			new CookieIDIndex = SQL_FetchInt(hndl, 0);
			if (debugging) LogMessage("found cookie index as %i", CookieIDIndex);
			iCookieIndex = CookieIDIndex;
		}
		else
		{
			LogError("Could not find the cookie index. Rageban functionality disabled.");
		}
	}
}

public OnMapStart()
{
   decl String:buffer[PLATFORM_MAX_PATH];
   GetConVarString(JBB_Cvar_SoundName, SoundPath, sizeof(SoundPath));
   if (strcmp(SoundPath, ""))
   {
		PrecacheSound(SoundPath, true);
		Format(buffer, sizeof(buffer), "sound/%s", SoundPath);
		AddFileToDownloadsTable(buffer);
   }
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == TopMenu)
	{
		return;
	}
	
	TopMenu = topmenu;
	
	new TopMenuObject:frequent_commands = FindTopMenuCategory(TopMenu, "ts_commands");
	
	if (frequent_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(TopMenu, 
			"sm_banguard",
			TopMenuObject_Item,
			AdminMenu_CTBan,
			frequent_commands,
			"sm_banguard",
			ADMFLAG_SLAY);
	}
	
	new TopMenuObject:player_commands = FindTopMenuCategory(TopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(TopMenu, 
			"sm_rageban",
			TopMenuObject_Item,
			AdminMenu_RageBan,
			player_commands,
			"sm_rageban",
			ADMFLAG_SLAY);
		
		if (frequent_commands == INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(TopMenu, 
				"sm_banguard",
				TopMenuObject_Item,
				AdminMenu_CTBan,
				player_commands,
				"sm_banguard",
				ADMFLAG_SLAY);		
		}
	}
}

public AdminMenu_CTBan(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
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
		case MenuAction_End:
			{
				CloseHandle(menu);
			}
		case MenuAction_Cancel:
			{
				if (param2 == MenuCancel_ExitBack && TopMenu != INVALID_HANDLE)
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_Select:
			{
				decl String:sBanChoice[10];
				GetMenuItem(menu, param2, sBanChoice, sizeof(sBanChoice));
				new iBanReason = StringToInt(sBanChoice);
				new iTimeToBan = GuardBanTimeLength[param1];
				new iTargetIndex = GetClientOfUserId(GuardBanTargetUserId[param1]);
				
				decl String:sBanned[3];
				GetClientCookie(iTargetIndex, Guard_Cookie, sBanned, sizeof(sBanned));
				new banFlag = StringToInt(sBanned);
				if (!banFlag)
				{
					PerformCTBan(iTargetIndex, param1, iTimeToBan, iBanReason);
				}
				else
				{
					PrintToChat(param1, "%s %t", CLAN_TAG, "Already Guard Banned", iTargetIndex);
				}
			}
	}
}

public MenuHandler_CTBanPlayerList(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			{
				CloseHandle(menu);
			}
		case MenuAction_Cancel:
			{
				if (param2 == MenuCancel_ExitBack && TopMenu != INVALID_HANDLE)
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_Select:
			{
				decl String:info[32];
				new userid, target;
				
				GetMenuItem(menu, param2, info, sizeof(info));
				userid = StringToInt(info);

				if ((target = GetClientOfUserId(userid)) == 0)
				{
					PrintToChat(param1, "%s %t", CLAN_TAG, "Player no longer available");
				}
				else if (!CanUserTarget(param1, target))
				{
					PrintToChat(param1, "%s %t", CLAN_TAG, "Unable to target");
				}
				else
				{
					GuardBanTargetUserId[param1] = userid;
					DisplayCTBanTimeMenu(param1, userid);
				}
			}
	}
}

public MenuHandler_CTBanTimeList(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			{
				CloseHandle(menu);
			}
		case MenuAction_Cancel:
			{
				if (param2 == MenuCancel_ExitBack && TopMenu != INVALID_HANDLE)
				{
					DisplayTopMenu(TopMenu, param1, TopMenuPosition_LastCategory);
				}
			}
		case MenuAction_Select:
			{
				decl String:info[32];
				GetMenuItem(menu, param2, info, sizeof(info));
				new iTimeToBan = StringToInt(info);
				GuardBanTimeLength[param1] = iTimeToBan;
				DisplayCTBanReasonMenu(param1);
			}
	}
}

public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (Handles[client] != INVALID_HANDLE)
		{
			CloseHandle(Handles[client]);
			Handles[client] = INVALID_HANDLE;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(JBB_Cvar_Enabled))
	{
		Handles[client] = INVALID_HANDLE;
		CreateTimer(0.0, CheckBanCookies, client, TIMER_FLAG_NO_MAPCHANGE);
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
		
		new Handle:ClientDisconnectPack = CreateDataPack();
		WritePackCell(ClientDisconnectPack, client);
		WritePackString(ClientDisconnectPack, sDisconnectSteamID);
		
		if (mysql_cvar)
		{
			decl String:query[255];
			Format(query, sizeof(query), "SELECT ban_time FROM %s WHERE steamid = '%s'", sTimesTableName, sDisconnectSteamID);
			SQL_TQuery(BanDatabase, DB_Callback_ClientDisconnect, query, ClientDisconnectPack);
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

public DB_Callback_ClientDisconnect(Handle:owner, Handle:hndl, const String:error[], any:thePack)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error with query on client disconnect: %s", error);
		CloseHandle(thePack);
	}
	else
	{
		ResetPack(thePack);
		new client = ReadPackCell(thePack);
		decl String:sAuthID[22];
		ReadPackString(thePack, sAuthID, sizeof(sAuthID));
		
		new iRowCount = SQL_GetRowCount(hndl);
		if (iRowCount)
		{
			if (debugging)
			{
				SQL_FetchRow(hndl);
				new iBanTimeRemaining = SQL_FetchInt(hndl, 0);

				if (IsClientInGame(client))
				{
					LogMessage("SQL: %N disconnected with %i time remaining on ban", client, iBanTimeRemaining);
				}
				else
				{
					LogMessage("SQL: %i client index disconnected with %i time remaining on ban", client, iBanTimeRemaining);
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
}

public DB_Callback_DisconnectAction(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error with updating/deleting record after client disconnect: %s", error);
	}
}

public Action:CheckBanCookies(Handle:timer, any: client)
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

ProcessBanCookies(client)
{
	if (client && IsClientInGame(client))
	{
		decl String:cookie[32];
		GetClientCookie(client, Guard_Cookie, cookie, sizeof(cookie));
		
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
				PrintToChat(client, "%s %t", CLAN_TAG, "Enforcing Guard Ban");
			}		
		}
	}
}

public Action:Command_LiveUnban(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%s Usage: sm_unctban <player>", CLAN_TAG);
	}
	else
	{
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
				ReplyToCommand(client, "%s %t", CLAN_TAG, "Cookie Status Unavailable");
			}
		}	
	}
	
	return Plugin_Handled;
}

Remove_CTBan(adminIndex, targetIndex, bExpired=false)
{
	decl String:isBanned[3];
	GetClientCookie(targetIndex, Guard_Cookie, isBanned, sizeof(isBanned));
	new banFlag = StringToInt(isBanned);
	
	if (banFlag)
	{
		decl String:targetSteam[22];
		GetClientAuthString(targetIndex, targetSteam, sizeof(targetSteam));
		
		if (mysql_cvar)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "UPDATE %s SET timeleft=-1 WHERE offender_steamid = '%s' and timeleft >= 0", sLogTableName, targetSteam);

			if (debugging) LogMessage("log query: %s", logQuery);

			SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, logQuery, targetIndex);
		}
		
		LogMessage("%N has removed the Guard ban on %N (%s).", adminIndex, targetIndex, targetSteam);
		
		if (!bExpired)
		{
			ShowActivity2(adminIndex, CLAN_TAG, "%t", "Guard Ban Removed", targetIndex);
		}
		else
		{
			ShowActivity2(adminIndex, CLAN_TAG, "%t", "Guard Ban Auto Removed", targetIndex);
		}
		
		decl String:query[255];
		Format(query, sizeof(query), "DELETE FROM %s WHERE steamid = '%s'", sTimesTableName, targetSteam);
		SQL_TQuery(BanDatabase, DB_Callback_RemoveCTBan, query, targetIndex);	
	}
	
	SetClientCookie(targetIndex, Guard_Cookie, "0");
}

public DB_Callback_RemoveCTBan(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error handling steamID after Guard ban removal: %s", error);
	}
	else
	{
		if (debugging && IsClientInGame(client))
		{
			LogMessage("CTBan on %N was removed in SQL", client);
		}
		else if (debugging	 && !IsClientInGame(client))
		{
			LogMessage("CTBan on --- was removed in SQL");
		}
	}
}

public Action:Command_LiveBan(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%s Usage: sm_banguard <player> <time> <reason>", CLAN_TAG);
	}
	else
	{
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
			if (target_list[0] && IsClientInGame(target_list[0]))
			{
				if (AreClientCookiesCached(target_list[0]))
				{
					decl String:isBanned[3];
					GetClientCookie(target_list[0], Guard_Cookie, isBanned, sizeof(isBanned));
					new banFlag = StringToInt(isBanned);	
					if (banFlag)
					{
						ReplyToCommand(client, "%s %t", CLAN_TAG, "Already Guard Banned", target_list[0]);
					}
					else
					{
						PerformCTBan(target_list[0], client, iBanTime, _, sReasonStr);
					}
				}
				else
				{
					ReplyToCommand(client, "%s %t", CLAN_TAG, "Cookie Status Unavailable");
				}
			}				
		}
	}
	return Plugin_Handled;
}

PerformCTBan(client, adminclient, banTime=0, reason=0, String:manualReason[]="")
{
	SetClientCookie(client, Guard_Cookie, "1");
	
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
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 1", adminclient);
			}
			case 2:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 2", adminclient);
			}
			case 3:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 3", adminclient);
			}
			case 4:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 4", adminclient);
			}
			case 5:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 5", adminclient);
			}
			case 6:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 6", adminclient);
			}
			case 7:
			{
				Format(sReason, sizeof(sReason), "%T", "Guard Ban Reason 7", adminclient);
			}
			default:
			{
				Format(sReason, sizeof(sReason), "No reason given.");
			}
		}
	}
	
	new timestamp = GetTime();
	
	if (adminclient && IsClientInGame(adminclient))
	{
		decl String:adminSteam[32];
		GetClientAuthString(adminclient, adminSteam, sizeof(adminSteam));
		
		if (mysql_cvar)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%N', '%s', '%N', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, client, adminSteam, adminclient, banTime, banTime, sReason);
			if (debugging)	LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		LogMessage("%N (%s) has issued a Guard ban on %N (%s) for %d minutes for %s.", adminclient, adminSteam, client, targetSteam, banTime, sReason);
	}
	else
	{
		if (mysql_cvar)
		{
			decl String:logQuery[350];
			Format(logQuery, sizeof(logQuery), "INSERT INTO %s (timestamp, offender_steamid, offender_name, admin_steamid, admin_name, bantime, reason) VALUES (%d, '%s', '%N', 'STEAM_0:1:1', 'Console', %d, %d, '%s')", sLogTableName, timestamp, targetSteam, client, banTime, banTime, sReason);
			if (debugging)	LogMessage("log query: %s", logQuery);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, logQuery, client);
		}
		LogMessage("Console has issued a Guard ban on %N (%s) for %d.", client, targetSteam, banTime);
	}

	if (banTime > 0)
	{
		ShowActivity2(adminclient, CLAN_TAG, "%t", "Temporary Guard Ban", client, banTime);
		PushArrayCell(TimedBanLocalList, client);
		LocalTimeRemaining[client] = banTime;
		
		if (mysql_cvar)
		{
			decl String:query[255];
			Format(query, sizeof(query), "INSERT INTO %s (steamid, ban_time) VALUES ('%s', %d)", sTimesTableName, targetSteam, banTime);
			if (debugging)	LogMessage("ctban query: %s", query);
			SQL_TQuery(BanDatabase, DB_Callback_CTBan, query, client);
		}
		
		new iSteamArrayIndex = PushArrayString(TimedBanSteamList, targetSteam);
		SetArrayCell(TimedBanSteamList, iSteamArrayIndex, banTime, 22);
	}
	else
	{
		ShowActivity2(adminclient, CLAN_TAG, "%t", "Permanent Guard Ban", client);	
	}
}

public DB_Callback_CTBan(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error writing CTBan to Timed Ban database: %s", error);
	}
	else
	{
		if (debugging && IsClientInGame(client))
		{
			LogMessage("SQL CTBan: Updated database with Guard Ban for %N", client);
		}
	}
}

public Action:Command_IsBanned(client, args)
{
	if ((args < 1) || !args)
	{
		ReplyToCommand(client, "%s Usage: sm_isbanned <player>", CLAN_TAG);
	}
	else
	{
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
			if (target_list[0] && IsClientInGame(target_list[0]))
			{
				if (AreClientCookiesCached(target_list[0]))
				{
					decl String:isBanned[3];
					GetClientCookie(target_list[0], Guard_Cookie, isBanned, sizeof(isBanned));
					new banFlag = StringToInt(isBanned);	
					if (banFlag)
					{
						if (LocalTimeRemaining[target_list[0]] <= 0)
						{
							ReplyToCommand(client, "%s %t", CLAN_TAG, "Permanent Guard Ban", target_list[0]);
						}
						else
						{
							ReplyToCommand(client, "%s %t", CLAN_TAG, "Temporary Guard Ban", target_list[0], LocalTimeRemaining[target_list[0]]);
						}
					}
					else
					{
						ReplyToCommand(client, "%s %t", CLAN_TAG, "Not Guard Banned", target_list[0]);
					}
				}
				else
				{
					ReplyToCommand(client, "%s %t", CLAN_TAG, "Cookie Status Unavailable");	
				}
			}
			else
			{
				ReplyToCommand(client, "%s %t", CLAN_TAG, "Unable to target");
			}				
		}
	}
	
	return Plugin_Handled;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetConVarBool(JBB_Cvar_Enabled))
	{
		decl String:sCookie[5];
		GetClientCookie(client, Guard_Cookie, sCookie, sizeof(sCookie));
		new iBanStatus = StringToInt(sCookie);
		
		decl String:BanMsg[100];
		GetConVarString(JBB_Cvar_JoinBanMessage, BanMsg, sizeof(BanMsg));
		
		if (team == _:TFTeam_Blue && iBanStatus)
		{
			PrintCenterText(client, "%t", "Enforcing Guard Ban");
			PrintToChat(client, BanMsg);
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

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!RoundActive)	RoundActive = true;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundActive)	RoundActive = false;
}

bool:IsSetAuthIdNativePresent()
{
	if (GetFeatureStatus(FeatureType_Native, "SetAuthIdCookie") == FeatureStatus_Available)
	{
		return true;
	}
	return false;
}