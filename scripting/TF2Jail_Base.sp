/*

Gamemode Description: Jailbreak is a gamemode consists of two teams facing off against each other in role playing style of Guards and Prisoners. Blue team consists of the Guards team which usually have weapons while
the red team consists of prisoners who have melee only. The object of the guards is to kill all of the prisoners and the object of the prisoners is to kill all the guards but there's a catch between the two. Guards
may only shoot prisoners if they rebel against orders given and prisoners can kill guards at anytime.

Plugin Description: This plugin is based on old ideas ever since the original Jailbreak was released for Counter-Strike while adding new ideas and more compatibility for a different game such as Team Fortress 2. This
plugin is designed to be very open ended in terms of compatibility and features. You may turn on/off features as you please and the plugin should be compatible even if none of the plugins or extensions are installed.

The following extensions are required:
 - SDK Tools
 - SDK Hooks

Everything else just won't run unless the plugin or extension required for it is running.

This plugin is licensed under the Sourcemod licensing so you may do with the code as you please but you MUST give the source code with any compiled binaries(SMX) files.

Check out my website and community below:
http://www.jackofdesigns.com/
http://community.jackofdesigns.com/

Feel free to donate to me if you like my work or you find this plugin useful.

Special thanks to The Outpost Community for giving me a server to test this on. (It's currently high ranks in terms of game server tracking websites)

*/

#pragma semicolon 1	//We like to be clean-cut.

//////////////////
//Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#tryinclude <clientprefs>
#tryinclude <tf2items>
#tryinclude <steamtools>
#undef REQUIRE_PLUGIN
#tryinclude <adminmenu>
#tryinclude <updater>
#tryinclude <tf2attributes>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <betherobot>
#tryinclude <voiceannounce_ex>
#tryinclude <filesmanagementinterface>
//////////////////

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Defines

#define PLUGIN_NAME     "[TF2] Jailbreak"														//Plugin name
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"											//Plugin author
#define PLUGIN_VERSION  "4.8.0"																	//Plugin version
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."									//Plugin description
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"											//Plugin contact URL

//#define UPDATE_URL    "http://jackofdesigns.com/plugins/jailbreak/jailbreak.txt"				//Update file to track new updates posted.

#define CLAN_TAG_COLOR	"{community}[TF2Jail]"													//Tag used for in-game messages to players.
#define CLAN_TAG		"[TF2Jail]"																//Tag used for logging purposes.

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Handles, Bools, Strings, etc.

new Handle:JB_Cvar_Version = INVALID_HANDLE;
new Handle:JB_Cvar_Enabled = INVALID_HANDLE;
new Handle:JB_Cvar_Advertise = INVALID_HANDLE;
new Handle:JB_Cvar_Cvars = INVALID_HANDLE;
new Handle:JB_Cvar_Balance = INVALID_HANDLE;
new Handle:JB_Cvar_BalanceRatio = INVALID_HANDLE;
new Handle:JB_Cvar_RedMelee = INVALID_HANDLE;
new Handle:JB_Cvar_Warden = INVALID_HANDLE;
new Handle:JB_Cvar_WardenModel = INVALID_HANDLE;
new Handle:JB_Cvar_WardenColor = INVALID_HANDLE;
new Handle:JB_Cvar_Doorcontrol = INVALID_HANDLE;
new Handle:JB_Cvar_DoorOpenTime = INVALID_HANDLE;
new Handle:JB_Cvar_RedMute = INVALID_HANDLE;
new Handle:JB_Cvar_RedMuteTime = INVALID_HANDLE;
new Handle:JB_Cvar_MicCheck = INVALID_HANDLE;
new Handle:JB_Cvar_Rebels = INVALID_HANDLE;
new Handle:JB_Cvar_RebelsTime = INVALID_HANDLE;
new Handle:JB_Cvar_Crits = INVALID_HANDLE;
new Handle:JB_Cvar_VoteNeeded = INVALID_HANDLE;
new Handle:JB_Cvar_VoteMinPlayers = INVALID_HANDLE;
new Handle:JB_Cvar_VotePostAction = INVALID_HANDLE;

new Handle:g_fward_onBecome = INVALID_HANDLE;
new Handle:g_fward_onRemove = INVALID_HANDLE;

new Handle:g_adverttimer = INVALID_HANDLE;
new Handle:Cvar_FF = INVALID_HANDLE;
new Handle:Cvar_COL = INVALID_HANDLE;

new bool:j_Enabled;
new bool:j_Advertise;
new bool:j_Cvars;
new bool:j_Balance;
new Float:j_BalanceRatio;
new bool:j_RedMelee;
new bool:j_Warden;
new bool:j_WardenModel;
new gWardenColor[3];
new bool:j_DoorControl;
new Float:j_DoorOpenTimer;
new j_RedMute;
new Float:j_RedMuteTime;
new bool:j_MicCheck;
new bool:j_Rebels;
new Float:j_RebelsTime;
new j_Criticals;
new Float:j_WVotesNeeded;
new j_WVotesMinPlayers;
new j_WVotesPostAction;

//Extension Bools
new bool:e_sdkhooks;
new bool:e_tf2items;
new bool:e_clientprefs;
//new bool:e_updater;
new bool:e_tf2attributes;
new bool:e_sourcecomms;
new bool:e_basecomm;
new bool:e_betherobot;
new bool:e_voiceannounce_ex;
new bool:e_filemanager;

new bool:steamtools = false;

//Globals
new bool:g_IsMapCompatible = false;
new bool:g_CellDoorTimerActive = false;
new bool:g_1stRoundFreeday = false;
new bool:g_bIsLRInUse = false;
new bool:g_bIsWardenLocked = false;
new bool:g_bIsSpeedDemonRound = false;
new bool:g_RobotRoundClients[MAXPLAYERS+1];
new bool:g_IsMuted[MAXPLAYERS+1];
new bool:g_IsRebel[MAXPLAYERS + 1];
new bool:g_IsFreeday[MAXPLAYERS + 1];
new bool:g_IsFreedayActive[MAXPLAYERS + 1];
new bool:g_IsFreekiller[MAXPLAYERS + 1];
new bool:g_HasTalked[MAXPLAYERS+1];

new g_FirstKill[MAXPLAYERS + 1];
new g_Killcount[MAXPLAYERS + 1];

new g_Voters = 0;
new g_Votes = 0;
new g_VotesNeeded = 0;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

new String:DoorList[][] = {"func_door", "func_movelinear", "func_door_rotating"};

new Warden = -1;

enum LastRequests
{
	LR_Disabled = 0,
	LR_FreedayForAll,
	LR_PersonalFreeday,
	LR_GuardsMeleeOnly,
	LR_HHHKillRound,
	LR_LowGravity,
	LR_SpeedDemon,
	LR_HungerGames,
	LR_RoboticTakeOver
};
new LastRequests:enumLastRequests;

enum RedMute
{
	RM_Disabled = 0,
	RM_MutedArena,
	RM_Muted
};
new RedMute:enumRedMute;

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Plugin Events and Functionality

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
	LogMessage("%s Jailbreak is now loading...", CLAN_TAG_COLOR);

	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail_Base.phrases");

	JB_Cvar_Version = CreateConVar("tf2jail_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	JB_Cvar_Enabled = CreateConVar("sm_jail_enabled", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_Enabled = true;
	
	JB_Cvar_Advertise = CreateConVar("sm_jail_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_Advertise = true;
	
	JB_Cvar_Cvars = CreateConVar("sm_jail_variables", "1", "Set default cvars: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_Cvars = true;
	
	JB_Cvar_Balance = CreateConVar("sm_jail_autobalance", "1", "Should the plugin autobalance teams: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_Balance = true;
	
	JB_Cvar_BalanceRatio = CreateConVar("sm_jail_balance_ratio", "0.5", "Ratio for autobalance: (Example: 0.5 = 2:4)", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	j_BalanceRatio = 0.5;
	
	JB_Cvar_RedMelee = CreateConVar("sm_jail_redmeleeonly", "1", "Strip Red Team of weapons: (1 = strip weapons, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_RedMelee = true;
	
	JB_Cvar_Warden = CreateConVar("sm_jail_warden", "1", "Allow Wardens: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_Warden = false;
	
	JB_Cvar_WardenModel = CreateConVar("sm_jail_wardenmodel", "1", "Does Warden have a model: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_WardenModel = true;
	
	JB_Cvar_WardenColor = CreateConVar("sm_jail_wardencolor", "125 150 250", "Color of warden if wardenmodel is off: (0 = off)", FCVAR_PLUGIN);
	gWardenColor[0] = 125;
	gWardenColor[1] = 150;
	gWardenColor[2] = 250;
	
	JB_Cvar_Doorcontrol = CreateConVar("sm_jail_doorcontrols", "1", "Allow Wardens and Admins door control: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_DoorControl = true;
	
	JB_Cvar_DoorOpenTime = CreateConVar("sm_jail_cell_opener", "60", "Time after Arena round start to open doors: (1.0 - 60.0) (0.0 = off)", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	j_DoorOpenTimer = 60.0;
	
	JB_Cvar_RedMute = CreateConVar("sm_jail_redmute", "2", "Mute Red team: (2 = mute prisoners alive and all dead, 1 = mute prisoners on round start based on redmute_time, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	enumRedMute = RM_Muted;

	JB_Cvar_RedMuteTime = CreateConVar("sm_jail_redmute_time", "15", "Mute time for redmute: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	j_RedMuteTime = 15.0;
	
	JB_Cvar_MicCheck = CreateConVar("sm_jail_micchecks", "1", "Check blue clients for microphone: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_MicCheck = true;
	
	JB_Cvar_Rebels = CreateConVar("sm_jail_rebels", "1", "Enable the rebel system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	j_Rebels = true;
	
	JB_Cvar_RebelsTime = CreateConVar("sm_jail_rebel_time", "30.0", "Rebel timer: (1.0 - 60.0, 0 = always)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	j_RebelsTime = 30.0;

	JB_Cvar_Crits = CreateConVar("sm_jail_crits", "1", "Which team gets crits: (0 = off, 1 = blue, 2 = red, 3 = both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	j_Criticals = 1;
	
	JB_Cvar_VoteNeeded = CreateConVar("sm_jail_voteoffwarden_votesneeded", "0.60", "Percentage of players required for fire warden vote: (default 0.60 - 60%) (0.05 - 1.0)", 0, true, 0.05, true, 1.00);
	j_WVotesNeeded = 0.60;

	JB_Cvar_VoteMinPlayers = CreateConVar("sm_jail_voteoffwarden_minplayers", "0", "Minimum amount of players required for fire warden vote: (0 - MaxPlayers)", 0, true, 0.0, true, float(MAXPLAYERS));
	j_WVotesMinPlayers = 0;

	JB_Cvar_VotePostAction = CreateConVar("sm_jail_voteoffwarden_post", "0", "Fire warden instantly on vote success or next round: (0 = instant, 1 = Next round)", _, true, 0.0, true, 1.0);
	j_WVotesPostAction = 0;
	
	HookConVarChange(JB_Cvar_Enabled, HandleCvars);
	HookConVarChange(JB_Cvar_Advertise, HandleCvars);
	HookConVarChange(JB_Cvar_Cvars, HandleCvars);
	HookConVarChange(JB_Cvar_Balance, HandleCvars);
	HookConVarChange(JB_Cvar_BalanceRatio, HandleCvars);
	HookConVarChange(JB_Cvar_RedMelee, HandleCvars);
	HookConVarChange(JB_Cvar_Warden, HandleCvars);
	HookConVarChange(JB_Cvar_WardenModel, HandleCvars);
	HookConVarChange(JB_Cvar_WardenColor, HandleCvars);
	HookConVarChange(JB_Cvar_Doorcontrol, HandleCvars);
	HookConVarChange(JB_Cvar_DoorOpenTime, HandleCvars);
	HookConVarChange(JB_Cvar_RedMute, HandleCvars);
	HookConVarChange(JB_Cvar_RedMuteTime, HandleCvars);
	HookConVarChange(JB_Cvar_MicCheck, HandleCvars);
	HookConVarChange(JB_Cvar_Rebels, HandleCvars);
	HookConVarChange(JB_Cvar_RebelsTime, HandleCvars);
	HookConVarChange(JB_Cvar_Crits, HandleCvars);
	HookConVarChange(JB_Cvar_VoteNeeded, HandleCvars);
	HookConVarChange(JB_Cvar_VoteMinPlayers, HandleCvars);
	HookConVarChange(JB_Cvar_VotePostAction, HandleCvars);
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_win", RoundWin);
	HookEvent("arena_round_start", ArenaRoundStart);
	HookEvent("teamplay_round_win", RoundEnd);
	
	AddCommandListener(InterceptBuild, "build");
	
	AutoExecConfig(true, "TF2Jail_Base");

	RegConsoleCmd("sm_jailbreak", JailbreakMenu);
	RegConsoleCmd("sm_fire", Command_FireWarden);
	RegConsoleCmd("sm_firewarden", Command_FireWarden);
	RegConsoleCmd("sm_w", BecomeWarden);
	RegConsoleCmd("sm_warden", BecomeWarden);
	RegConsoleCmd("sm_uw", ExitWarden);
	RegConsoleCmd("sm_unwarden", ExitWarden);
	RegConsoleCmd("sm_wmenu", WardenMenuC);
	RegConsoleCmd("sm_wardenmenu", WardenMenuC);
	RegConsoleCmd("sm_open", OnOpenCommand);
	RegConsoleCmd("sm_close", OnCloseCommand);
	RegConsoleCmd("sm_wff", WardenFriendlyFire);
	RegConsoleCmd("sm_wardenff", WardenFriendlyFire);
	RegConsoleCmd("sm_wardenfriendlyfire", WardenFriendlyFire);
	RegConsoleCmd("sm_wcc", WardenCollision);
	RegConsoleCmd("sm_wcollision", WardenCollision);
	RegConsoleCmd("sm_givelr", GiveLR);
	RegConsoleCmd("sm_givelastrequest", GiveLR);
	RegConsoleCmd("sm_removelr", RemoveLR);
	RegConsoleCmd("sm_removelastrequest", RemoveLR);
	
	RegAdminCmd("sm_rw", AdminRemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", AdminRemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_denylr", AdminDenyLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_denylastrequest", AdminDenyLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_opencells", AdminOpenCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_closecells", AdminCloseCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_lockcells", AdminLockCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unlockcells", AdminUnlockCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcewarden", AdminForceWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcelr", AdminForceLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_jaildebugger", AdminDebugger, ADMFLAG_GENERIC);
	RegAdminCmd("sm_jailreset", AdminResetPlugin, ADMFLAG_GENERIC);
	RegAdminCmd("sm_compatible", MapCompatibilityCheck, ADMFLAG_GENERIC);
	
	Cvar_FF = FindConVar("mp_friendlyfire");
	Cvar_COL = FindConVar("tf_avoidteammates_pushaway");
	
	AddMultiTargetFilter("@warden", WardenGroup, "the warden", false);
	AddMultiTargetFilter("@rebels", RebelsGroup, "all rebellers", false);
	AddMultiTargetFilter("@freedays", FreedaysGroup, "all freedays", false);
	AddMultiTargetFilter("@!warden", NotWardenGroup, "all but the warden", false);
	AddMultiTargetFilter("@!rebels", NotRebelsGroup, "all but rebellers", false);
	AddMultiTargetFilter("@!freedays", NotFreedaysGroup, "all but freedays", false);

	/*if (e_updater)
	{
		Updater_AddPlugin(UPDATE_URL);
	}*/
	
	steamtools = LibraryExists("SteamTools");
	
	g_fward_onBecome = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	g_fward_onRemove = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);

	AddServerTag2("Jailbreak");
}

public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true))
	{
		return;
	}
	
	new iNewValue = StringToInt(newValue);
	
	if (cvar == JB_Cvar_Enabled)
	{
		if (iNewValue == 1)
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin enabled");
			HookEvent("player_spawn", PlayerSpawn);
			HookEvent("player_hurt", PlayerHurt);
			HookEvent("player_death", PlayerDeath);
			HookEvent("teamplay_round_start", RoundStart);
			HookEvent("teamplay_round_win", RoundWin);
			HookEvent("arena_round_start", ArenaRoundStart);
			HookEvent("teamplay_round_win", RoundEnd);
			AddCommandListener(InterceptBuild, "build");
			j_Enabled = true;
			if (steamtools)
			{
				decl String:gameDesc[64];
				Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
				Steam_SetGameDescription(gameDesc);
			}
		}
		else if (iNewValue == 0)
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin disabled");
			UnhookEvent("player_spawn", PlayerSpawn);
			UnhookEvent("player_hurt", PlayerHurt);
			UnhookEvent("player_death", PlayerDeath);
			UnhookEvent("teamplay_round_start", RoundStart);
			UnhookEvent("teamplay_round_win", RoundWin);
			UnhookEvent("arena_round_start", ArenaRoundStart);
			UnhookEvent("teamplay_round_win", RoundEnd);
			RemoveCommandListener(InterceptBuild, "build");
			j_Enabled = false;
			if (steamtools)
			{
				Steam_SetGameDescription("Team Fortress");
			}
		}
	}
	else if (cvar == JB_Cvar_Advertise)
	{
		if (iNewValue == 1)
		{
			j_Advertise = true;
		}
		else if (iNewValue == 0)
		{
			j_Advertise = false;
		}
	}
	else if (cvar == JB_Cvar_Cvars)
	{
		if (iNewValue == 1)
		{
			j_Cvars = true;
		}
		else if (iNewValue == 0)
		{
			j_Cvars = false;
		}
	}
	else if (cvar == JB_Cvar_Balance)
	{
		if (iNewValue == 1)
		{
			j_Balance = true;
		}
		else if (iNewValue == 0)
		{
			j_Balance = false;
		}
	}
	else if (cvar == JB_Cvar_BalanceRatio)
	{
		j_BalanceRatio = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_RedMelee)
	{
		if (iNewValue == 1)
		{
			j_RedMelee = true;
		}
		else if (iNewValue == 0)
		{
			j_RedMelee = false;
		}
	}
	else if (cvar == JB_Cvar_Warden)
	{
		if (iNewValue == 1)
		{
			j_Warden = true;
		}
		else if (iNewValue == 0)
		{
			j_Warden = false;
		}
	}
	else if (cvar == JB_Cvar_WardenModel)
	{
		if (iNewValue == 1)
		{
			j_WardenModel = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i == Warden)
				{
					SetModel(i, "models/jailbreak/warden/warden_v2.mdl");
				}
			}
		}
		else if (iNewValue == 0)
		{
			j_WardenModel = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i == Warden)
				{
					RemoveModel(i);
				}
			}
		}
	}
	else if (cvar == JB_Cvar_WardenColor)
	{
		gWardenColor = SplitColorString(newValue);
	}
	else if (cvar == JB_Cvar_Doorcontrol)
	{
		if (iNewValue == 1)
		{
			j_DoorControl = false;
		}
		else if (iNewValue == 0)
		{
			j_DoorControl = true;
		}
	}
	else if (cvar == JB_Cvar_DoorOpenTime)
	{
		j_DoorOpenTimer = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_RedMute)
	{
		switch(iNewValue)
		{
			case 0:
			{
				enumRedMute = RM_Disabled;
			}
			case 1:
			{
				enumRedMute = RM_MutedArena;
			}
			case 2:
			{
				enumRedMute = RM_Muted;
			}
		}
	}
	else if (cvar == JB_Cvar_RedMuteTime)
	{
		j_RedMuteTime = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_MicCheck)
	{
		if (iNewValue == 1)
		{
			j_MicCheck = true;
		}
		else if (iNewValue == 0)
		{
			j_MicCheck = false;
		}
	}	
	else if (cvar == JB_Cvar_Rebels)
	{
		if (iNewValue == 1)
		{
			j_Rebels = true;
		}
		else if (iNewValue == 0)
		{
			j_Rebels = false;
		}
	}	
	else if (cvar == JB_Cvar_RebelsTime)
	{
		j_RebelsTime = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_Crits)
	{
		j_Criticals = iNewValue;
	}
	else if (cvar == JB_Cvar_VoteNeeded)
	{
		j_WVotesNeeded = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_VoteMinPlayers)
	{
		j_WVotesMinPlayers = iNewValue;
	}
	else if (cvar == JB_Cvar_VotePostAction)
	{
		j_WVotesPostAction = iNewValue;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));

	if (!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("Steam_SetGameDescription");
	
	CreateNative("TF2Jail_WardenActive", Native_ExistWarden);
	CreateNative("TF2Jail_IsWarden", Native_IsWarden);
	CreateNative("TF2Jail_WardenSet", Native_SetWarden);
	CreateNative("TF2Jail_WardenUnset", Native_RemoveWarden);
	CreateNative("TF2Jail_IsFreeday", Native_IsFreeday);
	CreateNative("TF2Jail_IsRebel", Native_IsRebel);
	CreateNative("TF2Jail_IsFreekiller", Native_IsFreekiller);


	RegPluginLibrary("TF2Jail");

	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	e_sdkhooks = LibraryExists("sdkhooks");
	e_tf2items = LibraryExists("tf2items");
	e_clientprefs = LibraryExists("clientprefs");
	//e_updater = LibraryExists("updater");
	e_tf2attributes = LibraryExists("tf2attributes");
	e_sourcecomms = LibraryExists("sourcecomms");
	e_basecomm = LibraryExists("basecomm");
	e_betherobot = LibraryExists("betherobot");
	e_voiceannounce_ex = LibraryExists("voiceannounce_ex");
	e_filemanager = LibraryExists("filesmanagementinterface");
}

public OnPluginEnd()
{
	ConvarsOff();
	RemoveServerTag2("Jailbreak");
	LogMessage("%s Jailbreak has been unloaded successfully.", CLAN_TAG);
}

public OnLibraryAdded(const String:name[])
{
	e_sdkhooks = !e_sdkhooks ? StrEqual(name, "sdkhooks", false) : e_sdkhooks;
	e_tf2items = !e_tf2items ? StrEqual(name, "tf2items", false) : e_tf2items;
	e_clientprefs = !e_clientprefs ? StrEqual(name, "clientprefs", false) : e_clientprefs;
	//e_updater = !e_updater ? StrEqual(name, "updater", false) : e_updater;
	e_tf2attributes = !e_tf2attributes ? StrEqual(name, "tf2attributes", false) : e_tf2attributes;
	e_sourcecomms = !e_sourcecomms ? StrEqual(name, "sourcecomms", false) : e_sourcecomms;
	e_basecomm = !e_basecomm ? StrEqual(name, "basecomm", false) : e_basecomm;
	e_betherobot = !e_betherobot ? StrEqual(name, "betherobot", false) : e_betherobot;
	e_voiceannounce_ex = !e_voiceannounce_ex ? StrEqual(name, "voiceannounce_ex", false) : e_voiceannounce_ex;
	e_filemanager = !e_filemanager ? StrEqual(name, "filesmanagementinterface", false) : e_filemanager;
	
	/*if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}*/
	
	if (strcmp(name, "SteamTools", false) == 0)
	{
		steamtools = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	e_sdkhooks = e_sdkhooks ? StrEqual(name, "sdkhooks", false) : e_sdkhooks;
	e_tf2items = e_tf2items ? StrEqual(name, "tf2items", false) : e_tf2items;
	e_clientprefs = e_clientprefs ? StrEqual(name, "clientprefs", false) : e_clientprefs;
	//e_updater = e_updater ? StrEqual(name, "updater", false) : e_updater;
	e_tf2attributes = e_tf2attributes ? StrEqual(name, "tf2attributes", false) : e_tf2attributes;
	e_sourcecomms = e_sourcecomms ? StrEqual(name, "sourcecomms", false) : e_sourcecomms;
	e_basecomm = e_basecomm ? StrEqual(name, "basecomm", false) : e_basecomm;
	e_betherobot = e_betherobot ? StrEqual(name, "betherobot", false) : e_betherobot;
	e_voiceannounce_ex = e_voiceannounce_ex ? StrEqual(name, "voiceannounce_ex", false) : e_voiceannounce_ex;
	e_filemanager = e_filemanager ? StrEqual(name, "filesmanagementinterface", false) : e_filemanager;
	
	if (strcmp(name, "SteamTools", false) == 0)
	{
		steamtools = false;
	}
}

public OnConfigsExecuted()
{
	j_Enabled = GetConVarBool(JB_Cvar_Enabled);
	j_Advertise = GetConVarBool(JB_Cvar_Advertise);
	j_Cvars = GetConVarBool(JB_Cvar_Cvars);
	j_Balance = GetConVarBool(JB_Cvar_Balance);
	j_BalanceRatio = GetConVarFloat(JB_Cvar_BalanceRatio);
	j_RedMelee = GetConVarBool(JB_Cvar_RedMelee);
	j_Warden = GetConVarBool(JB_Cvar_Warden);
	j_WardenModel = GetConVarBool(JB_Cvar_WardenModel);
	j_DoorControl = GetConVarBool(JB_Cvar_Doorcontrol);
	j_DoorOpenTimer = GetConVarFloat(JB_Cvar_DoorOpenTime);
	j_RedMute = GetConVarInt(JB_Cvar_RedMute);
	j_RedMuteTime = GetConVarFloat(JB_Cvar_RedMuteTime);
	j_MicCheck = GetConVarBool(JB_Cvar_MicCheck);
	j_Rebels = GetConVarBool(JB_Cvar_Rebels);
	j_RebelsTime = GetConVarFloat(JB_Cvar_RebelsTime);
	j_Criticals = GetConVarInt(JB_Cvar_Crits);
	j_WVotesNeeded = GetConVarFloat(JB_Cvar_VoteNeeded);
	j_WVotesMinPlayers = GetConVarInt(JB_Cvar_VoteMinPlayers);
	j_WVotesPostAction = GetConVarInt(JB_Cvar_VotePostAction);
	
	new String:strVersion[16];
	GetConVarString(JB_Cvar_Version, strVersion, 16);
	if (StrEqual(strVersion, PLUGIN_VERSION) == false)
	{
		LogError("Your plugin seems to be outdated, please refresh your config in order to receive new command variables list.");
	}
	SetConVarString(JB_Cvar_Version, PLUGIN_VERSION);

	switch(j_RedMute)
	{
		case 0:
		{
			enumRedMute = RM_Disabled;
		}
		case 1:
		{
			enumRedMute = RM_MutedArena;
		}
		case 2:
		{
			enumRedMute = RM_Muted;
		}
	}

	if (j_Enabled)
	{		
		if (j_Cvars)
		{
			SetConVarInt(FindConVar("mp_stalemate_enable"),0);
			SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
			SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
			SetConVarInt(FindConVar("mp_autoteambalance"), 0);
			SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
			SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
			SetConVarInt(FindConVar("tf_scout_air_dash_count"), 0);
		}
		if (j_WardenModel)
		{
			if (PrecacheModel("models/jailbreak/warden/warden_v2.mdl", true))
			{
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.mdl");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.dx80.vtx");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.dx90.vtx");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.phy");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.sw.vtx");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.vvd");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/NineteenEleven.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/NineteenEleven.vmt");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_body.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_body.vmt");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_hat.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_hat.vmt");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_head.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_head.vmt");
			}
			else
			{
				LogError("Warden model has failed to load correctly, please verify the files.");
				j_WardenModel = false;
			}
		}
	}
	if (steamtools)
	{
		decl String:gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	ResetVotes();
}

public OnMapStart()
{
	g_1stRoundFreeday = true;

	if (j_Enabled && j_Advertise)
	{
		g_adverttimer = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT);
	}
	
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
	CheckTheMap();
}

CheckTheMap()
{
	new open_cells = Entity_FindByName("open_cells", "func_button");
	new cell_door = Entity_FindByName("cell_door", "func_door");
	if (Entity_IsValid(open_cells) && Entity_IsValid(cell_door))
	{
		g_IsMapCompatible = true;
		LogMessage("%s The current map has passed all compatibility checks, plugin may proceed.", CLAN_TAG);
	}
	else
	{
		g_IsMapCompatible = false;
		LogError("The current map is incompatible with this plugin. Please verify the map or change it.");
		LogError("Feel free to type !compatible in chat to check the map manually.");
	}
}

public Action:TimerAdvertisement (Handle:timer, any:client)
{
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin advertisement");
}

public OnMapEnd()
{
	CloseHandle(g_adverttimer);
	g_adverttimer = INVALID_HANDLE;	
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			g_HasTalked[i] = false;
			g_IsMuted[i] = false;
			g_IsFreeday[i] = false;
		}
	}
	if (j_Cvars)
	{
		ConvarsOff();
	}

	ResetVotes();
	g_IsMapCompatible = false;
	
	if (steamtools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
}

public OnClientConnected(client)
{
	if (IsFakeClient(client))
	return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
	
	return;
}

public OnClientPutInServer(client)
{
	g_IsMuted[client] = false;
	g_RobotRoundClients[client] = false;
	g_IsRebel[client] = false;
	g_IsFreeday[client] = false;
}

public OnClientPostAdminCheck(client)
{
	if (j_Enabled)
	{
		CreateTimer(4.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Welcome(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "welcome message");
	}
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	return;
	
	if (g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
	
	if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded ) 
	{
		if (j_WVotesPostAction == 1)
		{
			return;
		}
		FireWardenCall();
	}

	if (client == Warden)
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden disconnected");
		PrintCenterTextAll("%t", "warden disconnected center");
		Warden = -1;
	}
	g_HasTalked[client] = false;
	g_IsMuted[client] = false;
	g_RobotRoundClients[client] = false;
	g_IsRebel[client] = false;
	g_IsFreeday[client] = false;
	g_Killcount[client] = 0;
	g_FirstKill[client] = 0;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	new notarget = GetEntityFlags(client)|FL_NOTARGET;

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		switch(enumLastRequests)
		{
			case LR_GuardsMeleeOnly, LR_HungerGames:
			{
				TF2_RemoveWeaponSlot(client, 0);
				TF2_RemoveWeaponSlot(client, 1);
				TF2_RemoveWeaponSlot(client, 3);
				TF2_RemoveWeaponSlot(client, 4);
				TF2_RemoveWeaponSlot(client, 5);
				TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
			}
		}
		if (team == _:TFTeam_Red)
		{
			SetEntityFlags(client, notarget);

			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
			{
				AcceptEntityInput(ent, "kill");
			}
			if (TF2_GetPlayerClass(client) == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_RemoveCondition(client, TFCond_Cloaked);
			}
			if (j_RedMelee)
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				new index = -1;
				switch(class)
				{
					case TFClass_DemoMan:
					{
						SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Engineer:
					{
						SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Heavy:
					{
						//SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Medic:
					{
						SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Pyro:
					{
						//SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Scout:
					{
						SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Sniper:
					{
						//SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Soldier:
					{
						SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
					case TFClass_Spy:
					{
						SetClip(client, 0, 0, client);
						SetClip(client, 1, 0, client);
						SetAmmo(client, 0, 0, client);
						SetAmmo(client, 1, 0, client);
					}
				}
				new primaryW = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if (primaryW > MaxClients && IsValidEdict(primaryW))
				{
					index = GetEntProp(primaryW, Prop_Send, "m_iItemDefinitionIndex");
					switch (index)
					{
						case 56, 1005: SetClip(client, 0, 0, client);
					}
				}
				TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
				TF2_RemoveWeaponSlot(client, 3);
				TF2_RemoveWeaponSlot(client, 4);
				TF2_RemoveWeaponSlot(client, 5);
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "stripped weapons and ammo");
			}
			if (j_RedMute != 0 && !g_IsMuted[client])
			{
				MutePlayer(client);
				g_IsMuted[client] = true;
			}
			if (g_IsFreeday[client])
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				SetEntityRenderColor(client, 0, 255, 0, 255);
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "lr freeday message");
				new flags = GetEntityFlags(client)|FL_NOTARGET;
				SetEntityFlags(client, flags);
				g_IsFreeday[client] = false;
				g_IsFreedayActive[client] = true;
			}
		}
		else if (team == _:TFTeam_Blue)
		{
			if (e_voiceannounce_ex && !g_HasTalked[client] && j_MicCheck && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION))
			{
				ChangeClientTeam(client, _:TFTeam_Red);
				TF2_RespawnPlayer(client);
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone unverified");
			}
		}
	}
	return Plugin_Continue;
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!j_Enabled || !IsValidClient(client) || !IsValidClient(client_attacker))
	{
		return Plugin_Continue;
	}

	if (client_attacker != client)
	{
		if (g_IsFreedayActive[client_attacker])
		{
			SetEntProp(client_attacker, Prop_Data, "m_takedamage", 2);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday lost", client_attacker);
			PrintCenterTextAll("%t", "lr freeday lost center", client_attacker);
			new flags = GetEntityFlags(client_attacker)&~FL_NOTARGET;
			SetEntityFlags(client_attacker, flags);
			SetEntityRenderColor(client_attacker, 255, 255, 255, 255);
			g_IsFreedayActive[client_attacker] = false;
		}
		if (j_Rebels && GetClientTeam(client_attacker) == _:TFTeam_Red && GetClientTeam(client) == _:TFTeam_Blue && !g_IsRebel[client_attacker])
		{
			g_IsRebel[client_attacker] = true;
			SetEntityRenderColor(client_attacker, 0, 255, 0, 255);
			decl String:clientName[MAX_NAME_LENGTH];
			GetClientName(client_attacker, clientName, sizeof(clientName));
			CRemoveTags(clientName, sizeof(clientName));
			//CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "prisoner has rebelled", clientName);
			if (j_RebelsTime >= 1.0)
			{
				new time = RoundFloat(j_RebelsTime);
				CPrintToChat(client_attacker, "%s %t", CLAN_TAG_COLOR, "rebel timer start", time);
				CreateTimer(j_RebelsTime, RemoveRebel, client_attacker, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action:RemoveRebel(Handle:timer, any:client)
{
	if (client > 0 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "rebel timer end");
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new time = GetTime();
	
	if (!j_Enabled || !IsValidClient(client) || !IsValidClient(client_killer))
	{
		return Plugin_Continue;
	}

	if (client_killer != client)
	{
		if ((g_FirstKill[client_killer]+6) >= time)
		{
			if (++g_Killcount[client_killer] == 6)
			{
				g_IsFreekiller[client_killer] = true;
				SetEntityRenderColor(client_killer, 255, 0, 0, 255);
				TF2_RemoveAllWeapons(client_killer);
				ServerCommand("sm_beacon #%d", GetClientUserId(client_killer));
				EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
			}
		}
		else
		{
			g_Killcount[client_killer] = 1;
			g_FirstKill[client_killer] = time;
		}
	}
	
	if (client == Warden)
	{
		WardenUnset(Warden);
		PrintCenterTextAll("%t", "warden killed", Warden);
	}

	switch(enumRedMute)
	{
		case RM_MutedArena, RM_Muted:
		{
			MutePlayer(client);
		}
	}

	new lastprisoner = Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE);
	if (lastprisoner == 1 && !j_Warden)
	{
		if (IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
		{
			LastRequestStart(client);
		}
	}
	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Warden = -1;
	g_bIsLRInUse = false;
	ServerCommand("sm_countdown_enabled 2");
	if (j_Enabled && g_1stRoundFreeday)
	{
		OpenCells();
		PrintCenterTextAll("1st round freeday");
		g_1stRoundFreeday = false;
	}
	if (g_IsMapCompatible)
	{
		new open_cells = Entity_FindByName("open_cells", "func_button");
		if (Entity_IsValid(open_cells))
		{
			if (j_DoorControl)
			{
				Entity_Lock(open_cells);
			}
			else
			{
				Entity_UnLock(open_cells);
			}
		}
	}
	else
	{
		LogError("Map is incompatible, disabling check for door controls command variable.");
	}
}

public Action:RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{

}

public Action:ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	g_bIsWardenLocked = false;

	new Float:Ratio;
	if (j_Balance)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			Ratio = Float:GetTeamClientCount(_:TFTeam_Blue)/Float:GetTeamClientCount(_:TFTeam_Red);
			if (Ratio <= j_BalanceRatio)
			{
				break;
			}
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);
				CPrintToChat(i, "%s %t", CLAN_TAG_COLOR, "moved for balance");
			}
		}
	}
	
	if (g_IsMapCompatible && j_DoorOpenTimer != 0.0)
	{
		new autoopen = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "cell doors open start", autoopen);
		CreateTimer(j_DoorOpenTimer, Open_Doors, _);
		g_CellDoorTimerActive = true;
	}

	switch(enumRedMute)
	{
		case RM_Disabled:
		{
			CPrintToChatAll("%s Muting is currently disabled. Everyone may talk.", CLAN_TAG_COLOR);
		}
		case RM_MutedArena:
		{
			new time = RoundFloat(j_RedMuteTime);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team muted temporarily", time);
			CreateTimer(j_RedMuteTime, UnmuteReds, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		case RM_Muted:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team muted");
		}
	}
	
	switch(enumLastRequests)
	{
		case LR_FreedayForAll:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr free for all executed");
			enumLastRequests = LR_Disabled;
		}
		case LR_PersonalFreeday:
		{
			//CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday executed", client);
			enumLastRequests = LR_Disabled;
		}
		case LR_GuardsMeleeOnly:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr guards melee only executed");
			enumLastRequests = LR_Disabled;
		}
		case LR_HHHKillRound:
		{
			ServerCommand("sm_behhh @all");
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hhh kill round executed");
			CreateTimer(10.0, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			enumLastRequests = LR_Disabled;
		}
		case LR_LowGravity:
		{
			ServerCommand("sv_gravity 300");
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr low gravity round executed");
			enumLastRequests = LR_Disabled;
		}
		case LR_SpeedDemon:
		{
			g_bIsSpeedDemonRound = true;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr speed demon round executed");
			enumLastRequests = LR_Disabled;
		}
		case LR_HungerGames:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hunger games executed");
			CreateTimer(10.0, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			enumLastRequests = LR_Disabled;
		}
		case LR_RoboticTakeOver:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					g_RobotRoundClients[i] = true;
					BeTheRobot_SetRobot(i, true);
				}
			}
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr robotic takeover executed");
			enumLastRequests = LR_Disabled;
		}
	}
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	if (GetConVarBool(Cvar_FF))
	{
		SetConVarBool(Cvar_FF, false);
	}

	if (GetConVarBool(Cvar_COL))
	{
		SetConVarBool(Cvar_COL, false);
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			UnmutePlayer(i);
			if (g_RobotRoundClients[i])
			{
				BeTheRobot_SetRobot(i, false);
				g_RobotRoundClients[i] = false;
			}
		}
		if (i == Warden)
		{
			WardenUnset(i);
		}
		if (g_IsFreedayActive[i])
		{
			g_IsFreedayActive[i] = false;
		}
	}
	ServerCommand("sv_gravity 800");
	if (g_bIsSpeedDemonRound)
	{
		ResetPlayerSpeed();
		g_bIsSpeedDemonRound = false;
	}
	return Plugin_Continue;
}

public OnGameFrame() 
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i)) continue;
		if (g_bIsSpeedDemonRound)
		{
			SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 400.0);
		}
		
		switch(j_Criticals)
		{
			case 0:
			{
				//Do Nothing
			}
			case 1:
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
				{
					TF2_AddCondition(i, TFCond_Kritzkrieged, 0.1);
				}
			}
			case 2:
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
				{
					TF2_AddCondition(i, TFCond_Kritzkrieged, 0.1);
				}
			}
			case 3:
			{
				if (IsValidClient(i) && IsPlayerAlive(i))
				{
					TF2_AddCondition(i, TFCond_Kritzkrieged, 0.1);
				}
			}
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (j_Enabled && IsValidEntity(entity))
	{
		if (StrContains(classname, "tf_ammo_pack", false) != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public bool:OnClientSpeakingEx(client)
{
	if (e_voiceannounce_ex && j_MicCheck && !g_HasTalked[client])
	{
		g_HasTalked[client] = true;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone verified");
	}
}

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Public Commands

public Action:JailbreakMenu(client, args)
{
	if (j_Enabled)
	{
		if (!client)
		{
			ReplyToCommand(client, "%t","Command is in-game only");
			return Plugin_Handled;
		}
		JB_ShowMenu(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

JB_ShowMenu(client)
{
	new Handle:menu = CreateMenu(JB_MenuHandler);
	SetMenuExitBackButton(menu, false);

	SetMenuTitle(menu, "Jailbreak %s", PLUGIN_VERSION);

	AddMenuItem(menu, "rules",    "Rules & Gameplay");
	AddMenuItem(menu, "commands", "Commands");

	DisplayMenu(menu, client, 30);
}

public JB_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new Handle:cpanel = CreatePanel();
		if (param2 == 0)
		{
			SetPanelTitle(cpanel, "Rules:");
			DrawPanelText(cpanel, " ");

			DrawPanelText(cpanel, "This menu is currently being built.");
		}
		else if (param2 == 1)
		{
			SetPanelTitle(cpanel, "Commands:");
			DrawPanelText(cpanel, " ");
		}
		for (new j = 0; j < 7; ++j)
		DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
		DrawPanelText(cpanel, " ");
		DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);

		SendPanelToClient(cpanel, param1, Help_MenuHandler, 45);
		CloseHandle(cpanel);
	}
}

public Help_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (menu == INVALID_HANDLE && action == MenuAction_Select)
	{
		JB_ShowMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		JB_ShowMenu(param1);
	}
}

public Action:Command_FireWarden(client, args)
{
	if (j_Enabled)
	{
		if (!client) return Plugin_Handled;
		AttemptFireWarden(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

AttemptFireWarden(client)
{
	if (GetClientCount(true) < j_WVotesMinPlayers)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "fire warden minimum players not met");
		return;			
	}
	if (g_Voted[client])
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "fire warden already voted", g_Votes, g_VotesNeeded);
		return;
	}
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	g_Votes++;
	g_Voted[client] = true;
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "fire warden requested", name, g_Votes, g_VotesNeeded);
	if (g_Votes >= g_VotesNeeded)
	{
		FireWardenCall();
	}	
}

FireWardenCall()
{
	if (Warden != -1)
	{
		for (new i=1; i<=MAXPLAYERS; i++)
		{
			WardenUnset(i);
		}
		ResetVotes();
	}
}

ResetVotes()
{
	g_Votes = 0;
	
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Admin Commands

public Action:MapCompatibilityCheck(client, args)
{
	if (j_Enabled)
	{
		new open_cells = Entity_FindByName("open_cells", "func_button");
		new cell_door = Entity_FindByName("cell_door", "func_door");
		if (Entity_IsValid(open_cells))
		{
			CPrintToChat(client, "%s Cell Opener = Detected", CLAN_TAG);
		}
		else
		{
			CPrintToChat(client, "%s Cell Opener = Undetected", CLAN_TAG);
		}
		if (Entity_IsValid(cell_door))
		{
			CPrintToChat(client, "%s Cell Doors = Detected", CLAN_TAG);
		}
		else
		{
			CPrintToChat(client, "%s Cell Doors = Undetected", CLAN_TAG);
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (j_Enabled)
	{
		g_CellDoorTimerActive = false;
		g_1stRoundFreeday = false;
		g_bIsLRInUse = false;
		g_bIsWardenLocked = false;
		g_bIsSpeedDemonRound = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			g_RobotRoundClients[i] = false;
			g_IsMuted[i] = false;
			g_IsRebel[i] = false;
			g_IsFreeday[i] = false;
			g_IsFreedayActive[i] = false;
			g_HasTalked[i] = false;
		}
		Warden = -1;
		enumLastRequests = LR_Disabled;
		enumRedMute = RM_Disabled;

		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin reset plugin");
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminDebugger(client, args)	//REALLY shit coded debugger
{
	if (j_Enabled)
	{
		if (g_1stRoundFreeday == true)
		{
			PrintToChat(client, "g_1stRoundFreeday == true");
		}
		else if (g_1stRoundFreeday == false)
		{
			PrintToChat(client, "g_1stRoundFreeday == false");
		}
		if (g_bIsLRInUse == true)
		{
			PrintToChat(client, "g_bIsLRInUse == true");
		}
		else if (g_bIsLRInUse == false)
		{
			PrintToChat(client, "g_bIsLRInUse == false");
		}
		if (g_bIsWardenLocked == true)
		{
			PrintToChat(client, "g_bIsWardenLocked == true");
		}
		else if (g_bIsWardenLocked == false)
		{
			PrintToChat(client, "g_bIsWardenLocked == false");
		}
		switch(enumLastRequests)
		{
			case LR_Disabled:
			{
				PrintToChat(client, "Queued = None");
			}
			case LR_FreedayForAll:
			{
				PrintToChat(client, "Queued = Freeday for All");
			}
			case LR_PersonalFreeday:
			{
				PrintToChat(client, "Queued = Personal Freeday");
			}
			case LR_HHHKillRound:
			{
				PrintToChat(client, "Queued = HHH Kill Round");
			}
			case LR_LowGravity:
			{
				PrintToChat(client, "Queued = Low Gravity");
			}
			case LR_SpeedDemon:
			{
				PrintToChat(client, "Queued = Speed Demon");
			}
			case LR_HungerGames:
			{
				PrintToChat(client, "Queued = Hunger Games");
			}
			case LR_RoboticTakeOver:
			{
				PrintToChat(client, "Queued = Robotic Takeover");
			}
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (j_Enabled)
	{
		if (g_IsMapCompatible)
		{
			OpenCells();
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminCloseCells(client, args)
{
	if (j_Enabled)
	{
		if (g_IsMapCompatible)
		{
			CloseCells();
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminLockCells(client, args)
{
	if (j_Enabled)
	{
		if (g_IsMapCompatible)
		{
			LockCells();
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminUnlockCells(client, args)
{
	if (j_Enabled)
	{
		if (g_IsMapCompatible)
		{
			UnlockCells();
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminForceWarden(client, args)
{
	if (j_Enabled)
	{
		if (Warden == -1)
		{
			new randomplayer = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
			if (randomplayer)
			{
				WardenSet(randomplayer);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "forced warden", client, randomplayer);
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "current warden", Warden);
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminForceLR(client, args)
{
	if (j_Enabled)
	{
		LastRequestStart(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (j_Enabled)
	{
		g_bIsLRInUse = false;
		g_bIsWardenLocked = false;
		enumLastRequests = LR_Disabled;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_RobotRoundClients[i])
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed robot");
				g_RobotRoundClients[i] = false;
			}
			if (g_IsFreeday[i] || g_IsFreedayActive[i])
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed freeday");
				g_IsFreeday[i] = false;
				g_IsFreedayActive[i] = false;
			}
		}
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin deny lr");
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Warden Commands/Handling

public Action:BecomeWarden(client, args)
{
	if (j_Enabled)
	{
		if (j_Warden)
		{
			if (!g_1stRoundFreeday || !g_bIsWardenLocked)
			{
				if (Warden == -1)
				{
					if (GetClientTeam(client) == _:TFTeam_Blue)
					{
						if (IsValidClient(client) && IsPlayerAlive(client))
						{
							CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "new warden", client);
							CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden message");
							WardenSet(client);
						}
						else
						{
							CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "dead warden");
						}
					}
					else
					{
						CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "guards only");
					}
				}
				else
				{
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "current warden", Warden);
				}
			}
			else
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden locked");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "Warden disabled");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:WardenMenuC(client, args)
{
	if (j_Enabled)
	{
		if (client == Warden)
		{
			WardenMenu(client);
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

WardenMenu(client)
{
	new Handle:menu = CreateMenu(WardenMenuHandler);
	SetMenuTitle(menu, "Available Warden Commands:");
	AddMenuItem(menu, "1", "Open Cells");
	AddMenuItem(menu, "2", "Close Cells");
	AddMenuItem(menu, "3", "Toggle Friendlyfire");
	AddMenuItem(menu, "4", "Toggle Collision");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public WardenMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		switch (param2)
		{
			case 0:
			{
				FakeClientCommandEx(client, "say /open");
			}
			case 1:
			{
				FakeClientCommandEx(client, "say /close");
			}
			case 2:
			{
				FakeClientCommandEx(client, "say /wff");
			}
			case 3:
			{
				FakeClientCommandEx(client, "say /wcc");
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{

	}
	else if (action == MenuAction_End)    
	{
		CloseHandle(menu);
	}
}

public Action:WardenFriendlyFire(client, args)
{
	if (j_Enabled)
	{
		if (client == Warden)
		{
			if (GetConVarBool(Cvar_FF) == false)
			{
				SetConVarBool(Cvar_FF, true);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire enabled");
				LogMessage("%s %N has enabled friendly fire as Warden.", CLAN_TAG_COLOR, Warden);
			}
			else
			{
				SetConVarBool(Cvar_FF, false);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire disabled");
				LogMessage("%s %N has disabled friendly fire as Warden.", CLAN_TAG_COLOR, Warden);
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:WardenCollision(client, args)
{
	if (j_Enabled)
	{
		if (client == Warden)
		{
			if (GetConVarBool(Cvar_COL) == false)
			{
				SetConVarBool(Cvar_COL, true);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision enabled");
				LogMessage("%s %N has enabled collision as Warden.", CLAN_TAG_COLOR, Warden);
			}
			else
			{
				SetConVarBool(Cvar_COL, false);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision disabled");
				LogMessage("%s %N has disabled collision fire as Warden.", CLAN_TAG_COLOR, Warden);
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:ExitWarden(client, args)
{
	if (j_Enabled)
	{
		if (client == Warden)
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden retired", client);
			PrintCenterTextAll("%t", "warden retired center");
			WardenUnset(client);
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:AdminRemoveWarden(client, args)
{
	if (j_Enabled)
	{
		if (Warden != -1)
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden fired", client, Warden);
			PrintCenterTextAll("%t", "warden fired center");
			WardenUnset(Warden);
		}
		else
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "no warden current");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:OnOpenCommand(client, args)
{
	if (j_Enabled)
	{
		if (g_IsMapCompatible)
		{
			if (j_DoorControl)
			{
				if (client == Warden)
				{
					OpenCells();
				}
				else
				{    
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
				}
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "door controls disabled");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
	if (j_Enabled)
	{
		if (g_IsMapCompatible)
		{
			if (j_DoorControl)
			{
				if (client == Warden)
				{
					CloseCells();
				}
				else
				{    
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
				}
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "door controls disabled");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:GiveLR(client, args)
{
	if (j_Enabled)
	{
		if (client == Warden)
		{
			if (g_bIsLRInUse == false)
			{
				if (args != 1)
				{
					ReplyToCommand(client, "%s Usage: sm_givelr <player|#userid>", CLAN_TAG_COLOR);
					return Plugin_Handled;
				}
				new String:arg1[32];
				GetCmdArg(1, arg1, sizeof(arg1));
				
				new target = FindTarget(client, arg1, false, false);
				if (target == -1)
				{
					return Plugin_Handled;
				}
				if (IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) == _:TFTeam_Red)
				{
					LastRequestStart(target);
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request given", Warden, target);
				}
				else
				{
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "last request invalid client");
				}
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "last request invalid client");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

public Action:RemoveLR(client, args)
{
	if (j_Enabled)
	{
		if (client == Warden)
		{
			g_bIsLRInUse = false;
			g_bIsWardenLocked = false;
			enumLastRequests = LR_Disabled;
			g_IsFreeday[client] = false;
			g_IsFreedayActive[client] = false;
			CPrintToChat(Warden, "%s %t", CLAN_TAG_COLOR, "warden removed lr");
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
	}
	return Plugin_Handled;
}

WardenSet(client)
{
	Warden = client;
	SetClientListeningFlags(client, VOICE_NORMAL);
	if (j_WardenModel)
	{
		SetModel(client, "models/jailbreak/warden/warden_v2.mdl");
	}
	else
	{
		SetEntityRenderColor(client, gWardenColor[0], gWardenColor[1], gWardenColor[2], 255);
	}
	WardenMenu(client);
	Forward_OnWardenCreation(client);
}

WardenUnset(client)
{
	if (Warden != -1)
	{
		Warden = -1;
		if (j_WardenModel)
		{
			RemoveModel(client);
		}
		else
		{
			SetEntityRenderColor(client, 0, 0, 0, 0);
		}
	}
	Forward_OnWardenRemoved(client);
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && client == Warden)
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetWearableAlpha(client, 255);
	}
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetWearableAlpha(client, 0);
	}
}

stock SetWearableAlpha(client, alpha, bool:override = false)
{
	if (!override) return 0;
	new count;
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[35];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue;
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue;
		SetEntityRenderMode(z, RENDER_TRANSCOLOR);
		SetEntityRenderColor(z, 255, 255, 255, alpha);
		count++;
	}
	return count;
}

OpenCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Open");
			}
		}
	}
	if (g_CellDoorTimerActive)
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors manual open");
		g_CellDoorTimerActive = false;
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors opened");
}

CloseCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Close");
			}
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors closed");
}

LockCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Lock");
			}
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors locked");
}

UnlockCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Unlock");
			}
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors unlocked");
}

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Command Intercepts

public Action:InterceptBuild(client, const String:command[], args)
{
	if (!j_Enabled) return Plugin_Continue;

	if (IsValidClient(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Last Requestion Functionality

LastRequestStart(client)
{
	new Handle:LRMenu = CreateMenu(MenuHandlerLR, MENU_ACTIONS_ALL);
	SetMenuTitle(LRMenu, "Last Request Menu");

	AddMenuItem(LRMenu, "class_id", "Freeday for yourself");
	AddMenuItem(LRMenu, "class_id", "Freeday for you and others");
	AddMenuItem(LRMenu, "class_id", "Freeday for all");
	AddMenuItem(LRMenu, "class_id", "Commit Suicide");
	AddMenuItem(LRMenu, "class_id", "Guards Melee Only Round");
	AddMenuItem(LRMenu, "class_id", "HHH Kill Round");
	AddMenuItem(LRMenu, "class_id", "Low Gravity Round");
	AddMenuItem(LRMenu, "class_id", "Speed Demon Round");
	AddMenuItem(LRMenu, "class_id", "Hunger Games");
	if (e_betherobot)
	{
		AddMenuItem(LRMenu, "class_id", "Robotic Takeover");
	}
	else
	{
		AddMenuItem(LRMenu, "class_id", "Robotic Takeover");
	}
	AddMenuItem(LRMenu, "class_id", "Custom Request");
	
	SetMenuExitButton(LRMenu, true);
	DisplayMenu(LRMenu, client, 30 );
}

public MenuHandlerLR(Handle:LRMenu, MenuAction:action, client, item)
{
	if ( action == MenuAction_Display )
	{
		g_bIsLRInUse = true;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden granted lr");
	}
	else if ( action == MenuAction_Select )
	{    
		switch (item)
		{
			case 0:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday queued", client);
				enumLastRequests = LR_PersonalFreeday;
				g_IsFreeday[client] = true;
			}
			case 1:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday picking clients", client);
				FreedayforClientsMenu(client);
			}
			case 2:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr free for all queued", client);
				enumLastRequests = LR_FreedayForAll;
			}
			case 3:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr suicide", client);
				ForcePlayerSuicide(client);
			}
			case 4:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr guards melee only queued", client);
				enumLastRequests = LR_GuardsMeleeOnly;
			}
			case 5:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hhh kill round queued", client);
				enumLastRequests = LR_HHHKillRound;
			}
			case 6:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr low gravity round queued", client);
				enumLastRequests = LR_LowGravity;
			}
			case 7:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr speed demon round queued", client);
				enumLastRequests = LR_SpeedDemon;
			}
			case 8:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hunger games queued", client);
				enumLastRequests = LR_HungerGames;
			}
			case 9:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr robotic takeover queued", client);
				enumLastRequests = LR_RoboticTakeOver;
			}
			case 10:
			{
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr custom message", client);
			}
		}
		g_bIsWardenLocked = true;
	}
	else if (action == MenuAction_Cancel)
	{
		g_bIsLRInUse = false;
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request closed");
	}
	else if (action == MenuAction_End)    
	{
		CloseHandle(LRMenu);
	}
}

FreedayforClientsMenu(client)
{
	new Handle:menu = CreateMenu(FreedayForClientsMenu_H, MENU_ACTIONS_ALL);

	SetMenuTitle(menu, "Choose a Player");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public FreedayForClientsMenu_H(Handle:menu, MenuAction:action, param1, param2)
{
	new counter = 0;

	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));

			if ((target) == 0)
			{
				PrintToChat(param1, "[JODC] %T", "Player no longer available", LANG_SERVER);
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "[JODC] %T", "Unable to target", LANG_SERVER);
			}
			else
			{
				g_IsFreeday[target] = true;
				counter++;
				if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
				{
					FreedayforClientsMenu(param1);
				}
			}
		}
	}
	if (counter == 3)
	{
		CloseHandle(menu);
		PrintToChat(param1, "You have reached the maximum number of allowed clients for Freeday.");
	}
}

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//Stocks and required Functions

stock ResetPlayerSpeed()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i)) continue;
		new TFClassType:class = TF2_GetPlayerClass(i);
		switch(class)
		{
			case TFClass_DemoMan: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 280.0);
			case TFClass_Engineer: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
			case TFClass_Heavy: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 230.0);
			case TFClass_Medic: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 320.0);
			case TFClass_Pyro: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
			case TFClass_Scout: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 400.0);
			case TFClass_Sniper: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
			case TFClass_Soldier: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 240.0);
			case TFClass_Spy: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
		}
	}
}

public Action:EnableFFTimer(Handle:timer)
{
	SetConVarBool(Cvar_FF, true);
}

public Action:UnmuteReds(Handle:timer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && TFTeam:GetClientTeam(i) == TFTeam_Red && g_IsMuted[i] == true)
		{
			UnmutePlayer(i);
			g_IsMuted[i] = false;
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team unmuted");
	return Plugin_Continue;
}

public Action:Open_Doors(Handle:timer, any:client)
{
	if (g_CellDoorTimerActive)
	{
		OpenCells();
		new time = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "cell doors open end", time);
		g_CellDoorTimerActive = false;
	}
}

stock ConvarsOff()
{
	SetConVarInt(FindConVar("mp_stalemate_enable"),1);
	SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
	SetConVarInt(FindConVar("mp_autoteambalance"), 1);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 1);
	SetConVarInt(FindConVar("tf_scout_air_dash_count"), 1);
}

public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//Null
}

stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsValidClient(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

stock MutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION))
	{
		Client_Mute(client);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "muted player");
	}
}

stock UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION))
	{
		Client_UnMute(client);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "unmuted player");
	}
}

stock AddServerTag2(const String:tag[])
{
	new Handle:hTags = INVALID_HANDLE;
	hTags = FindConVar("sv_tags");
	if (hTags != INVALID_HANDLE)
	{
		decl String:tags[256];
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrContains(tags, tag, true) > 0) return;
		if (strlen(tags) == 0)
		{
			Format(tags, sizeof(tags), tag);
		}
		else
		{
			Format(tags, sizeof(tags), "%s,%s", tags, tag);
		}
		SetConVarString(hTags, tags, true);
	}
}

stock RemoveServerTag2(const String:tag[])
{
	new Handle:hTags = INVALID_HANDLE;
	hTags = FindConVar("sv_tags");
	if (hTags != INVALID_HANDLE)
	{
		decl String:tags[50];
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrEqual(tags, tag, true))
		{
			Format(tags, sizeof(tags), "");
			SetConVarString(hTags, tags, true);
			return;
		}
		new pos = StrContains(tags, tag, true);
		new len = strlen(tags);
		if (len > 0 && pos > -1)
		{
			new bool:found;
			new String:taglist[50][50];
			ExplodeString(tags, ",", taglist, sizeof(taglist[]), sizeof(taglist));
			for (new i; i < sizeof(taglist[]); i++)
			{
				if (StrEqual(taglist[i], tag, true))
				{
					Format(taglist[i], sizeof(taglist), "");
					found = true;
					break;
				}
			}    
			if (!found) return;
			ImplodeStrings(taglist, sizeof(taglist[]), ",", tags, sizeof(tags));
			if (pos == 0)
			{
				tags[0] = 0x20;
			}    
			else if (pos == len-1)
			{
				Format(tags[strlen(tags)-1], sizeof(tags), "");
			}    
			else
			{
				ReplaceString(tags, sizeof(tags), ",,", ",");
			}    
			SetConVarString(hTags, tags, true);
		}
	}    
}  

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching") || IsFakeClient(client))
	{
		return false;
	}
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

stock SetClip(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}

stock SetAmmo(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}

stock ClearTimer(&Handle:timer)
{ 
	if (timer != INVALID_HANDLE) 
	{ 
		KillTimer(timer); 
	} 
	timer = INVALID_HANDLE; 
}

stock bool:AlreadyMuted(client)
{
	if (e_sourcecomms)
	{
		if (SourceComms_GetClientMuteType(client) == bNot)
		{
			return false;
		}
		else
		{
			return true;
		}
	}
	else if (e_basecomm)
	{
		if (!BaseComm_IsClientMuted(client))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
	return false;
}


public bool:WardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && i == Warden)
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotWardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && i != Warden)
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:RebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && g_IsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotRebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && !g_IsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:FreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && g_IsFreeday[i] || IsValidClient(i) && g_IsFreedayActive[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotFreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && !g_IsFreeday[i] || IsValidClient(i) && !g_IsFreedayActive[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}


public Native_ExistWarden(Handle:plugin, numParams)
{
	if (Warden != -1)
		return true;
	
	return false;
}

public Native_IsWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (client == Warden)
		return true;
	
	return false;
}

public Native_SetWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (Warden == -1)
	{
		WardenSet(client);
	}
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (client == Warden)
	{
		WardenUnset(client);
	}
}

public Native_IsFreeday(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsFreeday[client] || g_IsFreedayActive[client])
		return true;
	
	return false;
}

public Native_IsRebel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsRebel[client])
		return true;
	
	return false;
}

public Native_IsFreekiller(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsFreekiller[client])
		return true;
	
	return false;
}

public Forward_OnWardenCreation(client)
{
	Call_StartForward(g_fward_onBecome);
	Call_PushCell(client);
	Call_Finish();
}

public Forward_OnWardenRemoved(client)
{
	Call_StartForward(g_fward_onRemove);
	Call_PushCell(client);
	Call_Finish();
}

SplitColorString(const String:colors[])
{
	decl _iColors[3], String:_sBuffer[3][4];
	ExplodeString(colors, " ", _sBuffer, 3, 4);
	for (new i = 0; i <= 2; i++)
		_iColors[i] = StringToInt(_sBuffer[i]);
	
	return _iColors;
}

/*	//End of the file.
###################################
TF2 Jailbreak plugin by Keith Warren(Jack of Designs). Source Code made for The Outpost Community.
###################################
*/	//End of the file.