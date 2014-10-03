/*
	**
	* =============================================================================
	* TF2 Jailbreak Plugin Set (TF2Jail)
	*
	* Created and developed by Keith Warren (Jack of Designs).
	* =============================================================================
	*
	* This program is free software: you can redistribute it and/or modify
	* it under the terms of the GNU General Public License as published by
	* the Free Software Foundation, either version 3 of the License, or
	* (at your option) any later version.
	*
	* This program is distributed in the hope that it will be useful,
	* but WITHOUT ANY WARRANTY; without even the implied warranty of
	* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	* GNU General Public License for more details.
	*
	* You should have received a copy of the GNU General Public License
	* along with this program. If not, see <http://www.gnu.org/licenses/>.
	*
	**
*/

#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <adminmenu>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#include <autoexecconfig>

//TF2Jail Include
#include <tf2jail>

#undef REQUIRE_EXTENSIONS
#tryinclude <sdkhooks>
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN

/***************************/
//Remove slashes for support.

//Sourcebans 1.4.X
//#tryinclude <sourcebans>

//Sourcebans 2.X.X
//#tryinclude <sb_bans>

/***************************/

#tryinclude <tf2attributes>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <clientprefs>
#tryinclude <voiceannounce_ex>
#tryinclude <roundtimer>
//#tryinclude <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME	"[TF2] Jailbreak"
#define PLUGIN_AUTHOR	"Keith Warren(Jack of Designs)"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT	"http://www.jackofdesigns.com/"
#define WARDEN_MODEL	"models/jailbreak/warden/warden_v2"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

#if defined _updater_included
#define UPDATE_URL         "https://raw.github.com/JackofDesigns/TF2-Jailbreak/Beta/updater.txt"
#endif

//ConVar Handles, Globals, etc..
new Handle:JB_ConVars[68] = {INVALID_HANDLE, ...};
new bool:cv_Enabled = true, bool:cv_Advertise = true, bool:cv_Cvars = true, cv_Logging = 2, bool:cv_Balance = true, Float:cv_BalanceRatio = 0.5,
bool:cv_RedMelee = true, bool:cv_Warden = false, bool:cv_WardenAuto = false, bool:cv_WardenModel = true, bool:cv_WardenForceSoldier = true,
bool:cv_WardenFF = true, bool:cv_WardenCC = true, bool:cv_WardenRequest = true, cv_WardenLimit = 0, bool:cv_DoorControl = true, Float:cv_DoorOpenTimer = 60.0,
cv_RedMute = 2, Float:cv_RedMuteTime = 15.0, cv_BlueMute = 2, bool:cv_DeadMute = true, bool:cv_MicCheck = true, bool:cv_MicCheckType = true, bool:cv_Rebels = true,
Float:cv_RebelsTime = 30.0, cv_Criticals = 1, cv_Criticalstype = 2, Float:cv_WVotesNeeded = 0.60, cv_WVotesMinPlayers = 0, cv_WVotesPostAction = 0, cv_WVotesPassedLimit = 3,
bool:cv_Freekillers = true, Float:cv_FreekillersTime = 6.0, cv_FreekillersKills = 6, Float:cv_FreekillersWave = 60.0, cv_FreekillersAction = 2, String:BanMsg[255],
String:BanMsgDC[255], cv_FreekillersBantime = 60, cv_FreekillersBantimeDC = 120, bool:cv_LRSEnabled = true, bool:cv_LRSAutomatic = true, bool:cv_LRSLockWarden = true,
cv_FreedayLimit = 3, bool:cv_1stDayFreeday = true, bool:cv_DemoCharge = true, bool:cv_DoubleJump = true, bool:cv_Airblast = true, String:Particle_Freekiller[100],
String:Particle_Rebellion[100], String:Particle_Freeday[100], cv_WardenVoice = 1, bool:cv_WardenWearables = true, bool:cv_FreedayTeleports = true, cv_WardenStabProtection = 0,
bool:cv_KillPointServerCommand = true, bool:cv_RemoveFreedayOnLR = true, bool:cv_RemoveFreedayOnLastGuard = true, bool:cv_PrefStatus = false, cv_WardenTimer = 20, bool:cv_AdminFlags = false,
bool:cv_PrefBlue = false, bool:cv_PrefWarden = false, bool:cv_ConsoleSpew = false, cv_BuildingsManage, bool:cv_PrefForce = true, bool:cv_FFButton = true;

//Plugins/Extension bools

#if defined _voiceannounce_ex_included_
new bool:e_voiceannounce_ex = false;
#endif

new bool:e_steamtools = false, bool:e_clientprefs = false, bool:attributes = false;

//Global Bools
new bool:g_IsMapCompatible = false, bool:g_CellsOpened = false, bool:g_1stRoundFreeday = false, bool:g_VoidFreekills = false,
bool:g_bIsLRInUse = false, bool:g_bIsWardenLocked = false, bool:g_bOneGuardLeft = false, bool:g_bActiveRound = false,
bool:g_bFreedayTeleportSet = false, bool:g_bLRConfigActive = true, bool:g_bLockWardenLR = false, bool:g_bDisableCriticals = false, bool:g_bLateLoad = false, bool:g_bAdminLockWarden = false;

//Player Array Bools
new bool:g_ScoutsBlockedDoubleJump[MAXPLAYERS+1], bool:g_PyrosDisableAirblast[MAXPLAYERS+1], bool:g_IsMuted[MAXPLAYERS+1],
bool:g_IsRebel[MAXPLAYERS + 1], bool:g_IsQueuedFreeday[MAXPLAYERS + 1], bool:g_IsFreeday[MAXPLAYERS + 1], bool:g_IsFreekiller[MAXPLAYERS + 1],
bool:g_HasTalked[MAXPLAYERS+1], bool:g_LockedFromWarden[MAXPLAYERS+1], bool:g_bRolePreference_Blue[MAXPLAYERS+1], bool:g_bRolePreference_Warden[MAXPLAYERS+1],
bool:g_HasModel[MAXPLAYERS+1], bool:g_Voted[MAXPLAYERS+1] = {false, ...};

//Global Integers
new Warden = -1, CustomClient = -1, LR_Pending = -1,
LR_Current = -1, g_Voters = 0, g_Votes = 0,
g_VotesNeeded = 0, g_VotesPassed = 0, WardenLimit = 0,
FreedayLimit = 0;

//Player Array Integers
new g_FirstKill[MAXPLAYERS + 1], g_Killcount[MAXPLAYERS + 1], g_HasBeenWarden[MAXPLAYERS + 1];

//Global Floats
new Float:free_pos[3];

//Global Strings
new String:GCellNames[32], String:GCellOpener[32], String:GFFButton[32], String:DoorList[][] = {"func_door", "func_door_rotating", "func_movelinear"},
String:LRConfig_File[PLATFORM_MAX_PATH], String:CustomLR[32];

//Global Handles
new Handle:sFW_WardenCreated, Handle:sFW_WardenRemoved, Handle:sFW_OnLastRequestExecute;
new Handle:g_hArray_Pending, Handle:g_hRolePref_Blue, Handle:g_hRolePref_Warden;

//Text Node Handles
new Handle:TextNodes[3] = {INVALID_HANDLE, ...};

//Engine ConVar Handles
new Handle:JB_EngineConVars[3] = {INVALID_HANDLE, ...};

//Timer Handles
new Handle:hTimer_Advertisement, Handle:hTimer_FreekillingData, Handle:hTimer_OpenCells,
Handle:hTimer_FriendlyFireEnable, Handle:hTimer_WardenLock;

//Player Array Handles
new Handle:hTimer_ParticleTimers[MAXPLAYERS+1], Handle:hTimer_RebelTimers[MAXPLAYERS+1];

//Enumeration Structures
enum eWardenMenu
{
	Open = 0,
	FriendlyFire,
	Collision
};
new eWardenMenu:EnumWardenMenu;

enum eComms
{
	None = 0,
	Basecomms,
	Sourcecomms
};
new eComms:EnumCommsList;

enum eDoorsMode
{
	OPEN = 0,
	CLOSE,
	LOCK,
	UNLOCK
};

enum eTextNodeParams
{
	Float:eCoord_X,
	Float:eCoord_Y,
	Float:eHoldTime,
	eRed,
	eBlue,
	eGreen,
	eAlpha,
	eEffect,
	Float:efxTime,
	Float:eFadeIn,
	Float:eFadeOut,
};
new eaTNPs[3][eTextNodeParams];

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plug-in only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	MarkNativeAsOptional("Steam_SetGameDescription");
	
	CreateNative("TF2Jail_WardenActive", Native_ExistWarden);
	CreateNative("TF2Jail_IsWarden", Native_IsWarden);
	CreateNative("TF2Jail_WardenSet", Native_SetWarden);
	CreateNative("TF2Jail_WardenUnset", Native_RemoveWarden);
	CreateNative("TF2Jail_IsFreeday", Native_IsFreeday);
	CreateNative("TF2Jail_GiveFreeday", Native_GiveFreeday);
	CreateNative("TF2Jail_IsRebel", Native_IsRebel);
	CreateNative("TF2Jail_MarkRebel", Native_MarkRebel);
	CreateNative("TF2Jail_IsFreekiller", Native_IsFreekiller);
	CreateNative("TF2Jail_MarkFreekiller", Native_MarkFreekill);
	CreateNative("TF2Jail_StripToMelee", Native_StripToMelee);
	CreateNative("TF2Jail_StripAllWeapons", Native_StripAllWeapons);
	CreateNative("TF2Jail_LockWarden", Native_LockWarden);
	CreateNative("TF2Jail_UnlockWarden", Native_UnlockWarden);
	CreateNative("TF2Jail_Log", Native_Logging);
	CreateNative("TF2Jail_IsLRRound", Native_IsLRRound);
	
	sFW_WardenCreated = CreateGlobalForward("TF2Jail_OnWardenCreated", ET_Ignore, Param_Cell);
	sFW_WardenRemoved = CreateGlobalForward("TF2Jail_OnWardenRemoved", ET_Ignore, Param_Cell);
	sFW_OnLastRequestExecute = CreateGlobalForward("TF2Jail_OnLastRequestExecute", ET_Event, Param_String);
	
	RegPluginLibrary("tf2jail");
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	Jail_Log("%s Jailbreak is now loading...", JTAG);
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail.phrases");
	
	AutoExecConfig_SetFile("TF2Jail");

	JB_ConVars[0] = AutoExecConfig_CreateConVar("tf2jail_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	JB_ConVars[1] = AutoExecConfig_CreateConVar("sm_tf2jail_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[2] = AutoExecConfig_CreateConVar("sm_tf2jail_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[3] = AutoExecConfig_CreateConVar("sm_tf2jail_set_variables", "1", "Set default cvars: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[4] = AutoExecConfig_CreateConVar("sm_tf2jail_logging", "2", "Status and the type of logging: (0 = disabled, 1 = regular logging, 2 = logging to TF2Jail logs.)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[5] = AutoExecConfig_CreateConVar("sm_tf2jail_auto_balance", "1", "Should the plugin autobalance teams: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[6] = AutoExecConfig_CreateConVar("sm_tf2jail_balance_ratio", "0.5", "Ratio for autobalance: (Example: 0.5 = 2:4)", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	JB_ConVars[7] = AutoExecConfig_CreateConVar("sm_tf2jail_melee", "1", "Strip Red Team of weapons: (1 = strip weapons, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[8] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_enable", "1", "Allow Wardens: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[9] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_auto", "1", "Automatically assign a random Wardens on round start: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[10] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_model", "1", "Does Wardens have a model: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[11] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_forcesoldier", "1", "Force Wardens to be Soldier class: (1 = yes, 0 = no)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[12] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_friendlyfire", "1", "Allow Wardens to manage friendly fire: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[13] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_collision", "1", "Allow Wardens to manage collision: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[14] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_request", "0", "Require admin acceptance for cvar changes: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[15] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_limit", "3", "Number of allowed Wardens per user per map: (1.0 - 12.0) (0.0 = unlimited)", FCVAR_PLUGIN, true, 0.0, true, 12.0);
	JB_ConVars[16] = AutoExecConfig_CreateConVar("sm_tf2jail_door_controls", "1", "Allow Wardens and Admins door control: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[17] = AutoExecConfig_CreateConVar("sm_tf2jail_cell_timer", "60", "Time after Arena round start to open doors: (1.0 - 60.0) (0.0 = off)", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	JB_ConVars[18] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_red", "2", "Mute Red team: (2 = mute prisoners alive and all dead, 1 = mute prisoners on round start based on redmute_time, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[19] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_red_time", "15", "Mute time for redmute: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_ConVars[20] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_blue", "2", "Mute Blue players: (2 = always except Wardens, 1 = while Wardens is active, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[21] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_dead", "1", "Mute Dead players: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[22] = AutoExecConfig_CreateConVar("sm_tf2jail_microphonecheck_enable", "1", "Check blue clients for microphone: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[23] = AutoExecConfig_CreateConVar("sm_tf2jail_microphonecheck_type", "1", "Block blue team or Wardens if no microphone: (1 = Blue, 0 = Wardens only)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[24] = AutoExecConfig_CreateConVar("sm_tf2jail_rebelling_enable", "1", "Enable the Rebel system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[25] = AutoExecConfig_CreateConVar("sm_tf2jail_rebelling_time", "30.0", "Rebel timer: (1.0 - 60.0, 0 = always)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_ConVars[26] = AutoExecConfig_CreateConVar("sm_tf2jail_criticals", "1", "Which team gets crits: (0 = off, 1 = blue, 2 = red, 3 = both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	JB_ConVars[27] = AutoExecConfig_CreateConVar("sm_tf2jail_criticals_type", "2", "Type of crits given: (1 = mini, 2 = full)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
	JB_ConVars[28] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_votesneeded", "0.60", "Percentage of players required for fire Wardens vote: (default 0.60 - 60%) (0.05 - 1.0)", 0, true, 0.05, true, 1.00);
	JB_ConVars[29] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_minplayers", "0", "Minimum amount of players required for fire Wardens vote: (0 - MaxPlayers)", 0, true, 0.0, true, float(MAXPLAYERS));
	JB_ConVars[30] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_postaction", "0", "Fire Wardens instantly on vote success or next round: (0 = instant, 1 = Next round)", _, true, 0.0, true, 1.0);
	JB_ConVars[31] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_passlimit", "3", "Limit to Wardens fired by players via votes: (1 - 10, 0 = unlimited)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	JB_ConVars[32] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_enable", "1", "Enable the Freekill system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[33] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_seconds", "6.0", "Time in seconds minimum for freekill flag on mark: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_ConVars[34] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_kills", "6", "Number of kills required to flag for freekilling: (1.0 - MaxPlayers)", FCVAR_PLUGIN, true, 1.0, true, float(MAXPLAYERS));
	JB_ConVars[35] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_wave", "60.0", "Time in seconds until client is banned for being marked: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_ConVars[36] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_action", "2", "Action towards marked freekiller: (2 = Ban client based on cvars, 1 = Slay the client, 0 = remove mark on timer)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[37] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_ban_reason", "You have been banned for freekilling.", "Message to give the client if they're marked as a freekiller and banned.", FCVAR_PLUGIN);
	JB_ConVars[38] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_ban_reason_dc", "You have been banned for freekilling and disconnecting.", "Message to give the client if they're marked as a freekiller/disconnected and banned.", FCVAR_PLUGIN);
	JB_ConVars[39] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_duration", "60", "Time banned after timer ends: (0 = permanent)", FCVAR_PLUGIN, true, 0.0);
	JB_ConVars[40] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_duration_dc", "120", "Time banned if disconnected after timer ends: (0 = permanent)", FCVAR_PLUGIN, true, 0.0);
	JB_ConVars[41] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_enable", "1", "Status of the LR System: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[42] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_automatic", "1", "Automatically grant last request to last prisoner alive: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[43] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_lock_warden", "1", "Lock Wardens during last request rounds: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[44] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_limit", "3", "Max number of freedays for the lr: (1.0 - 16.0)", FCVAR_PLUGIN, true, 1.0, true, 16.0);
	JB_ConVars[45] = AutoExecConfig_CreateConVar("sm_tf2jail_1stdayfreeday", "1", "Status of the 1st day freeday: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[46] = AutoExecConfig_CreateConVar("sm_tf2jail_democharge", "1", "Allow demomen to charge: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[47] = AutoExecConfig_CreateConVar("sm_tf2jail_doublejump", "1", "Deny scouts to double jump: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[48] = AutoExecConfig_CreateConVar("sm_tf2jail_airblast", "1", "Deny pyros to airblast: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[49] = AutoExecConfig_CreateConVar("sm_tf2jail_particle_freekiller", "ghost_firepit", "Name of the Particle for Freekillers (0 = Disabled)", FCVAR_PLUGIN);
	JB_ConVars[50] = AutoExecConfig_CreateConVar("sm_tf2jail_particle_rebellion", "medic_radiusheal_red_volume", "Name of the Particle for Rebellion (0 = Disabled)", FCVAR_PLUGIN);
	JB_ConVars[51] = AutoExecConfig_CreateConVar("sm_tf2jail_particle_freeday", "eyeboss_team_sparks_red", "Name of the Particle for Freedays (0 = Disabled)", FCVAR_PLUGIN);
	JB_ConVars[52] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_voice", "1", "Voice management for Wardens: (0 = disabled, 1 = unmute, 2 = warning)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[53] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_wearables", "1", "Strip Wardens wearables: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[54] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_teleport", "1", "Status of teleporting: (1 = enable, 0 = disable) (Disables all functionality regardless of configs)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[55] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_stabprotection", "1", "Give Wardens backstab protection: (2 = Always, 1 = Once, 0 = Disabled)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[56] = AutoExecConfig_CreateConVar("sm_tf2jail_point_servercommand", "1", "Kill 'point_servercommand' entities: (1 = Kill on Spawn, 0 = Disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[57] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_removeonlr", "1", "Remove Freedays on Last Request: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[58] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_removeonlastguard", "1", "Remove Freedays on Last Guard: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[59] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_enable", "0", "Allow clients to choose their preferred teams/roles: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[60] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_timer", "20", "Time in seconds after Warden is unset or lost to lock Warden: (0 = Disabled, NON-FLOAT VALUE)", FCVAR_PLUGIN);
	JB_ConVars[61] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_flags", "0", "Lock Warden to a command access flag: (1 = enable, 0 = disable) (Command Access: TF2Jail_WardenOverride)", FCVAR_PLUGIN);
	JB_ConVars[62] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_blue", "0", "Enable the preference for Blue if preferences are enabled: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[63] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_warden", "0", "Enable the preference for Blue if preferences are enabled: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[64] = AutoExecConfig_CreateConVar("sm_tf2jail_console_prints_status", "1", "Enable console messages and information: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[65] = AutoExecConfig_CreateConVar("sm_tf2jail_buildings_manage", "1", "Allow Engineers to build on the following teams: (0 = None, 1 = Blue, 2 = Red, 3 = Both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	JB_ConVars[66] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_force", "1", "Force admin commands to set players to roles regardless of preference: (1 = Force, 0 = Respect)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[67] = AutoExecConfig_CreateConVar("sm_tf2jail_friendlyfire_button", "1", "Status for Friendly Fire button if exists: (1 = Locked, 0 = Unlocked)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	
	for (new i = 0; i < sizeof(JB_ConVars); i++)
	{
		HookConVarChange(JB_ConVars[i], HandleCvars);
	}
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("arena_round_start", ArenaRoundStart);
	HookEvent("teamplay_round_win", RoundEnd);
	HookEvent("post_inventory_application", RegeneratePlayer);
	HookEvent("player_changeclass", ChangeClass, EventHookMode_Pre);
	
	AddCommandListener(InterceptBuild, "build");

	RegConsoleCmd("sm_fire", Command_FireWarden, "Vote for Warden to be fired.");
	RegConsoleCmd("sm_firewarden", Command_FireWarden, "Vote for Warden to be fired.");
	RegConsoleCmd("sm_w", BecomeWarden, "Become the Warden.");
	RegConsoleCmd("sm_warden", BecomeWarden, "Become the Warden.");
	RegConsoleCmd("sm_uw", ExitWarden, "Remove yourself from Warden.");
	RegConsoleCmd("sm_unwarden", ExitWarden, "Remove yourself from Warden.");
	RegConsoleCmd("sm_wmenu", WardenMenuC, "Call the Warden Menu if you're Warden.");
	RegConsoleCmd("sm_wardenmenu", WardenMenuC, "Call the Warden Menu if you're Warden.");
	RegConsoleCmd("sm_open", OnOpenCommand, "Open the cell doors.");
	RegConsoleCmd("sm_close", OnCloseCommand, "Close the cell doors.");
	RegConsoleCmd("sm_wff", WardenFriendlyFire, "Request or enable Friendly Fire as Warden.");
	RegConsoleCmd("sm_wcc", WardenCollision, "Request or enable Collision changes as Warden.");
	RegConsoleCmd("sm_givelr", GiveLR, "Give a last request to a Prisoner as Warden.");
	RegConsoleCmd("sm_givelastrequest", GiveLR, "Give a last request to a Prisoner as Warden.");
	RegConsoleCmd("sm_removelr", RemoveLR, "Remove a last request from a Prisoner as Warden.");
	RegConsoleCmd("sm_removelastrequest", RemoveLR, "Remove a last request from a Prisoner as Warden.");
	RegConsoleCmd("sm_currentlr", CurrentLR, "Last requests that are currently queued for next round or current.");
	RegConsoleCmd("sm_currentlastrequests", CurrentLR, "Last requests that are currently queued for next round or current.");
	RegConsoleCmd("sm_lrlist", ListLRs, "Display a list of last requests available.");
	RegConsoleCmd("sm_lrslist", ListLRs, "Display a list of last requests available.");
	RegConsoleCmd("sm_lrs", ListLRs, "Display a list of last requests available.");
	RegConsoleCmd("sm_lastrequestlist", ListLRs, "Display a list of last requests available.");
	RegConsoleCmd("sm_cw", CurrentWarden, "Display the name of the current Warden.");
	RegConsoleCmd("sm_currentwarden", CurrentWarden, "Display the name of the current Warden.");

	RegAdminCmd("sm_rw", AdminRemoveWarden, ADMFLAG_GENERIC, "Remove the currently active Warden.");
	RegAdminCmd("sm_removewarden", AdminRemoveWarden, ADMFLAG_GENERIC, "Remove the currently active Warden.");
	RegAdminCmd("sm_pardon", AdminPardonFreekiller, ADMFLAG_GENERIC, "Pardon an actively marked Free killer.");
	RegAdminCmd("sm_denylr", AdminDenyLR, ADMFLAG_GENERIC, "Deny any currently queued last requests.");
	RegAdminCmd("sm_denylastrequest", AdminDenyLR, ADMFLAG_GENERIC, "Deny any currently queued last requests.");
	RegAdminCmd("sm_opencells", AdminOpenCells, ADMFLAG_GENERIC, "Open the cell doors if closed.");
	RegAdminCmd("sm_closecells", AdminCloseCells, ADMFLAG_GENERIC, "Close the cell doors if open.");
	RegAdminCmd("sm_lockcells", AdminLockCells, ADMFLAG_GENERIC, "Lock the cell doors if unlocked.");
	RegAdminCmd("sm_unlockcells", AdminUnlockCells, ADMFLAG_GENERIC, "Unlock the cell doors if locked.");
	RegAdminCmd("sm_forcewarden", AdminForceWarden, ADMFLAG_GENERIC, "Force a client to become Warden.");
	RegAdminCmd("sm_forcelr", AdminForceLR, ADMFLAG_GENERIC, "Force a last request to become queued for the administrator.");
	RegAdminCmd("sm_jailreset", AdminResetPlugin, ADMFLAG_GENERIC, "Reset all plug-in global variables. (DEBUGGING)");
	RegAdminCmd("sm_compatible", AdminMapCompatibilityCheck, ADMFLAG_GENERIC, "Check if the current map is compatible with the plug-in.");
	RegAdminCmd("sm_givefreeday", AdminGiveFreeday, ADMFLAG_GENERIC, "Give a client on the server a Free day.");
	RegAdminCmd("sm_removefreeday", AdminRemoveFreeday, ADMFLAG_GENERIC, "Remove a client's Free day status if they have one.");
	RegAdminCmd("sm_allow", AdminAcceptWardenChange, ADMFLAG_GENERIC, "Accept or allow Warden changes made on the server.");
	RegAdminCmd("sm_cancel", AdminCancelWardenChange, ADMFLAG_GENERIC, "Cancel any currently active Warden changes on the server.");
	RegAdminCmd("sm_lw", LockWarden, ADMFLAG_GENERIC, "Lock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_lockwarden", LockWarden, ADMFLAG_GENERIC, "Lock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_ulw", UnlockWarden, ADMFLAG_GENERIC, "Unlock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_unlockwarden", UnlockWarden, ADMFLAG_GENERIC, "Unlock Warden from being taken by clients publicly.");
	
	JB_EngineConVars[0] = FindConVar("mp_friendlyfire");
	JB_EngineConVars[1] = FindConVar("tf_avoidteammates_pushaway");
	JB_EngineConVars[2] = FindConVar("sv_gravity");
		
	for (new i = 0; i < sizeof(TextNodes); i++)
	{
		TextNodes[i] = CreateHudSynchronizer();
	}
	
	AddMultiTargetFilter("@warden", WardenGroup, "The Warden.", false);
	AddMultiTargetFilter("@rebels", RebelsGroup, "All Rebels.", false);
	AddMultiTargetFilter("@freedays", FreedaysGroup, "All Freedays.", false);
	AddMultiTargetFilter("@!warden", NotWardenGroup, "All but the Warden.", false);
	AddMultiTargetFilter("@!rebels", NotRebelsGroup, "All but the Rebels.", false);
	AddMultiTargetFilter("@!freedays", NotFreedaysGroup, "All but the Freedays.", false);
	
	BuildPath(Path_SM, LRConfig_File, sizeof(LRConfig_File), "configs/tf2jail/lastrequests.cfg");
	
	g_hArray_Pending = CreateArray();
	
	SetCookieMenuItem(TF2Jail_Preferences, 0, "TF2Jail Preferences");
	
	AutoExecConfig_CleanFile();
}

public OnAllPluginsLoaded()
{
	e_steamtools = LibraryExists("SteamTools");
	attributes = LibraryExists("tf2attributes");
	e_clientprefs = LibraryExists("clientprefs");
	
	if (LibraryExists("sourcecomms"))
	{
		EnumCommsList = Sourcecomms;
	}
	else if (LibraryExists("basecomm"))
	{
		EnumCommsList = Basecomms;
	}
	else
	{
		EnumCommsList = None;
	}
	
	#if defined _voiceannounce_ex_included_
	e_voiceannounce_ex = LibraryExists("voiceannounce_ex");
	#endif
	
	#if defined _updater_included
	if (LibraryExists("updater")) Updater_AddPlugin(UPDATE_URL);
	#endif
}

public OnLibraryAdded(const String:name[])
{
	e_steamtools = StrEqual(name, "SteamTools", false);
	attributes = StrEqual(name, "tf2attributes");
	e_clientprefs = StrEqual(name, "clientprefs");

	if (StrEqual(name, "sourcecomms"))
	{
		EnumCommsList = Sourcecomms;
	}
	else if (StrEqual(name, "basecomm"))
	{
		EnumCommsList = Basecomms;
	}
	
	#if defined _voiceannounce_ex_included_
	e_voiceannounce_ex = StrEqual(name, "voiceannounce_ex");
	#endif
}

public OnLibraryRemoved(const String:name[])
{
	e_steamtools = StrEqual(name, "SteamTools", false);
	attributes = StrEqual(name, "tf2attributes");
	e_clientprefs = StrEqual(name, "clientprefs");
		
	if (StrEqual(name, "sourcecomms") || StrEqual(name, "basecomm"))
	{
		EnumCommsList = None;
	}
	
	#if defined _voiceannounce_ex_included_
	e_voiceannounce_ex = StrEqual(name, "voiceannounce_ex");
	#endif
}

public OnPluginEnd()
{
	OnMapEnd();
}

public OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(JB_ConVars[1]);
	cv_Advertise = GetConVarBool(JB_ConVars[2]);
	cv_Cvars = GetConVarBool(JB_ConVars[3]);
	cv_Logging = GetConVarInt(JB_ConVars[4]);
	cv_Balance = GetConVarBool(JB_ConVars[5]);
	cv_BalanceRatio = GetConVarFloat(JB_ConVars[6]);
	cv_RedMelee = GetConVarBool(JB_ConVars[7]);
	cv_Warden = GetConVarBool(JB_ConVars[8]);
	cv_WardenAuto = GetConVarBool(JB_ConVars[9]);
	cv_WardenModel = GetConVarBool(JB_ConVars[10]);
	cv_WardenForceSoldier = GetConVarBool(JB_ConVars[11]);
	cv_WardenFF = GetConVarBool(JB_ConVars[12]);
	cv_WardenCC = GetConVarBool(JB_ConVars[13]);
	cv_WardenRequest = GetConVarBool(JB_ConVars[14]);
	cv_WardenLimit = GetConVarInt(JB_ConVars[15]);
	cv_DoorControl = GetConVarBool(JB_ConVars[16]);
	cv_DoorOpenTimer = GetConVarFloat(JB_ConVars[17]);
	cv_RedMute = GetConVarInt(JB_ConVars[18]);
	cv_RedMuteTime = GetConVarFloat(JB_ConVars[19]);
	cv_BlueMute = GetConVarInt(JB_ConVars[20]);
	cv_DeadMute = GetConVarBool(JB_ConVars[21]);
	cv_MicCheck = GetConVarBool(JB_ConVars[22]);
	cv_MicCheckType = GetConVarBool(JB_ConVars[23]);
	cv_Rebels = GetConVarBool(JB_ConVars[24]);
	cv_RebelsTime = GetConVarFloat(JB_ConVars[25]);
	cv_Criticals = GetConVarInt(JB_ConVars[26]);
	cv_Criticalstype = GetConVarInt(JB_ConVars[27]);
	cv_WVotesNeeded = GetConVarFloat(JB_ConVars[28]);
	cv_WVotesMinPlayers = GetConVarInt(JB_ConVars[29]);
	cv_WVotesPostAction = GetConVarInt(JB_ConVars[30]);
	cv_WVotesPassedLimit = GetConVarInt(JB_ConVars[31]);
	cv_Freekillers = GetConVarBool(JB_ConVars[32]);
	cv_FreekillersTime = GetConVarFloat(JB_ConVars[33]);
	cv_FreekillersKills = GetConVarInt(JB_ConVars[34]);
	cv_FreekillersWave = GetConVarFloat(JB_ConVars[35]);
	cv_FreekillersAction = GetConVarInt(JB_ConVars[36]);
	GetConVarString(JB_ConVars[37], BanMsg, sizeof(BanMsg));
	GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
	cv_FreekillersBantime = GetConVarInt(JB_ConVars[39]);
	cv_FreekillersBantimeDC = GetConVarInt(JB_ConVars[40]);
	cv_LRSEnabled = GetConVarBool(JB_ConVars[41]);
	cv_LRSAutomatic = GetConVarBool(JB_ConVars[42]);
	cv_LRSLockWarden = GetConVarBool(JB_ConVars[43]);
	cv_FreedayLimit = GetConVarInt(JB_ConVars[44]);
	cv_1stDayFreeday = GetConVarBool(JB_ConVars[45]);
	cv_DemoCharge = GetConVarBool(JB_ConVars[46]);
	cv_DoubleJump = GetConVarBool(JB_ConVars[47]);
	cv_Airblast = GetConVarBool(JB_ConVars[48]);
	GetConVarString(JB_ConVars[49], Particle_Freekiller, sizeof(Particle_Freekiller));
	GetConVarString(JB_ConVars[50], Particle_Rebellion, sizeof(Particle_Rebellion));
	GetConVarString(JB_ConVars[51], Particle_Freeday, sizeof(Particle_Freeday));
	cv_WardenVoice = GetConVarInt(JB_ConVars[52]);
	cv_WardenWearables = GetConVarBool(JB_ConVars[53]);
	cv_FreedayTeleports = GetConVarBool(JB_ConVars[54]);
	cv_WardenStabProtection = GetConVarInt(JB_ConVars[55]);
	cv_KillPointServerCommand = GetConVarBool(JB_ConVars[56]);
	cv_RemoveFreedayOnLR = GetConVarBool(JB_ConVars[57]);
	cv_RemoveFreedayOnLastGuard = GetConVarBool(JB_ConVars[58]);
	cv_PrefStatus = GetConVarBool(JB_ConVars[59]);
	cv_WardenTimer = GetConVarInt(JB_ConVars[60]);
	cv_AdminFlags = GetConVarBool(JB_ConVars[61]);
	cv_PrefBlue = GetConVarBool(JB_ConVars[62]);
	cv_PrefWarden = GetConVarBool(JB_ConVars[63]);
	cv_ConsoleSpew = GetConVarBool(JB_ConVars[64]);
	cv_BuildingsManage = GetConVarInt(JB_ConVars[65]);
	cv_PrefForce = GetConVarBool(JB_ConVars[66]);
	cv_FFButton = GetConVarBool(JB_ConVars[67]);
	
	if (!cv_Enabled) return;

	if (cv_Cvars)
	{
		ConvarsSet(true);
	}

	if (e_steamtools)
	{
		decl String:gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}

	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
			{
				OnClientConnected(i);
			}
			
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
			
			if (!AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
		g_1stRoundFreeday = false;
		g_bLateLoad = false;
	}
	
	ResetVotes();
	ParseConfigs();
	
	if (e_clientprefs && cv_PrefStatus)
	{			
		if (cv_PrefBlue)
		{
			g_hRolePref_Blue = RegClientCookie("TF2Jail_RolePreference_Blue", "Sets the preferred role of the client. (Blue)", CookieAccess_Private);
		}
		
		if (cv_PrefWarden)
		{
			g_hRolePref_Warden = RegClientCookie("TF2Jail_RolePreference_Warden", "Sets the preferred role of the client. (Warden)", CookieAccess_Private);
		}
	}
	
	Jail_Log("%s Jailbreak has successfully loaded.", JTAG);
}

public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true)) return;

	new iNewValue = StringToInt(newValue);

	if (cvar == JB_ConVars[0])
	{
		SetConVarString(JB_ConVars[0], PLUGIN_VERSION);
	}
	else if (cvar == JB_ConVars[1])
	{
		cv_Enabled = bool:iNewValue;
		switch (iNewValue)
		{
		case 0:
			{
				CPrintToChatAll("%s %t", JTAG_COLORED, "plugin disabled");
				if (e_steamtools)
				{
					Steam_SetGameDescription("Team Fortress");
				}
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (cv_WardenModel && IsWarden(i))
						{
							RemoveModel(i);
						}
						if (g_IsRebel[i])
						{
							g_IsRebel[i] = false;
						}
					}
				}
			}
		case 1:
			{
				CPrintToChatAll("%s %t", JTAG_COLORED, "plugin enabled");
				if (e_steamtools)
				{
					decl String:gameDesc[64];
					Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
					Steam_SetGameDescription(gameDesc);
				}
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (cv_WardenModel && IsWarden(i))
						{
							decl String:s[PLATFORM_MAX_PATH];
							Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
							SetModel(i, s);
						}
					}
				}
			}
		}
	}
	else if (cvar == JB_ConVars[2])
	{
		cv_Advertise = bool:iNewValue;
		ClearTimer(hTimer_Advertisement);
		if (cv_Advertise)
		{
			StartAdvertisement();
		}
	}
	else if (cvar == JB_ConVars[3])
	{
		cv_Cvars = bool:iNewValue;
		ConvarsSet(cv_Cvars ? true : false);
	}
	else if (cvar == JB_ConVars[4])
	{
		cv_Logging = iNewValue;
	}
	else if (cvar == JB_ConVars[5])
	{
		cv_Balance = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[6])
	{
		cv_BalanceRatio = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[7])
	{
		cv_RedMelee = bool:iNewValue;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				new team = GetClientTeam(i);
				switch (iNewValue)
				{
					case 0:
						{
							if (team == _:TFTeam_Red)
							{
								TF2_RegeneratePlayer(i);
							}
						}
					case 1: RequestFrame(ManageWeapons, GetClientUserId(i));
				}
			}
		}
	}
	else if (cvar == JB_ConVars[8])
	{
		cv_Warden = bool:iNewValue;
		if (cv_Warden)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsWarden(i))
				{
					WardenUnset(i);
				}
			}
		}
	}
	else if (cvar == JB_ConVars[9])
	{
		cv_WardenAuto = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[10])
	{
		cv_WardenModel = bool:iNewValue;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsWarden(i))
			{
				if (cv_WardenModel)
				{
					decl String:s[PLATFORM_MAX_PATH];
					Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
					SetModel(i, s);
				}
				else
				{
					RemoveModel(i);
				}
			}
		}
	}
	else if (cvar == JB_ConVars[11])
	{
		cv_WardenForceSoldier = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[12])
	{
		cv_WardenFF = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[13])
	{
		cv_WardenCC = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[14])
	{
		cv_WardenRequest = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[15])
	{
		cv_WardenLimit = iNewValue;
	}
	else if (cvar == JB_ConVars[16])
	{
		cv_DoorControl = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[17])
	{
		cv_DoorOpenTimer = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[18])
	{
		cv_RedMute = iNewValue;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == _:TFTeam_Red)
				{
					switch (iNewValue)
					{
					case 0:	UnmutePlayer(i);
					case 1:	if (g_CellsOpened) MutePlayer(i);
					case 2:	if (g_bActiveRound) MutePlayer(i);
					}
				}
			}
		}
	}
	else if (cvar == JB_ConVars[19])
	{
		cv_RedMuteTime = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[20])
	{
		cv_BlueMute = iNewValue;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == _:TFTeam_Blue)
				{
					switch (iNewValue)
					{
					case 0:	UnmutePlayer(i);
					case 1:	MutePlayer(i);
					case 2:	if (!IsWarden(i)) MutePlayer(i);
					}
				}
			}
		}
	}
	else if (cvar == JB_ConVars[21])
	{
		cv_DeadMute = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[22])
	{
		cv_MicCheck = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[23])
	{
		cv_MicCheckType = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[24])
	{
		cv_Rebels = bool:iNewValue;
		if (iNewValue == 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && g_IsRebel[i])
				{
					g_IsRebel[i] = false;
				}
			}
		}
	}
	else if (cvar == JB_ConVars[25])
	{
		cv_RebelsTime = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[26])
	{
		cv_Criticals = iNewValue;
	}
	else if (cvar == JB_ConVars[27])
	{
		cv_Criticalstype = iNewValue;
	}
	else if (cvar == JB_ConVars[28])
	{
		cv_WVotesNeeded = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[29]) 
	{
		cv_WVotesMinPlayers = iNewValue;
	}
	else if (cvar == JB_ConVars[30]) 
	{
		cv_WVotesPostAction = iNewValue;
	}
	else if (cvar == JB_ConVars[31]) 
	{
		cv_WVotesPassedLimit = iNewValue;
	}
	else if (cvar == JB_ConVars[32])
	{
		cv_Freekillers = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[33])
	{
		cv_FreekillersTime = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[34])
	{
		cv_FreekillersKills = iNewValue;
	}
	else if (cvar == JB_ConVars[35])
	{
		cv_FreekillersWave = StringToFloat(newValue);
	}
	else if (cvar == JB_ConVars[36])
	{
		cv_FreekillersAction = iNewValue;
	}
	else if (cvar == JB_ConVars[37])
	{
		GetConVarString(JB_ConVars[37], BanMsg, sizeof(BanMsg));
	}
	else if (cvar == JB_ConVars[38])
	{
		GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
	}
	else if (cvar == JB_ConVars[39])
	{
		cv_FreekillersBantime = iNewValue;
	}
	else if (cvar == JB_ConVars[40])
	{
		cv_FreekillersBantimeDC = iNewValue;
	}
	else if (cvar == JB_ConVars[41])
	{
		cv_LRSEnabled = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[42])
	{
		cv_LRSAutomatic = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[43])
	{
		cv_LRSLockWarden = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[44])
	{
		cv_FreedayLimit = iNewValue;
	}
	else if (cvar == JB_ConVars[45])
	{
		cv_1stDayFreeday = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[46])
	{
		cv_DemoCharge = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[47])
	{
		cv_DoubleJump = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[48])
	{
		cv_Airblast = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[49])
	{
		GetConVarString(JB_ConVars[49], Particle_Freekiller, sizeof(Particle_Freekiller));
	}
	else if (cvar == JB_ConVars[50])
	{
		GetConVarString(JB_ConVars[50], Particle_Rebellion, sizeof(Particle_Rebellion));
	}
	else if (cvar == JB_ConVars[51])
	{
		GetConVarString(JB_ConVars[51], Particle_Freeday, sizeof(Particle_Freeday));
	}
	else if (cvar == JB_ConVars[52])
	{
		cv_WardenVoice = iNewValue;
	}
	else if (cvar == JB_ConVars[53])
	{
		cv_WardenWearables = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[54])
	{
		cv_FreedayTeleports = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[55])
	{
		cv_WardenStabProtection = iNewValue;
	}
	else if (cvar == JB_ConVars[56])
	{
		cv_KillPointServerCommand = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[57])
	{
		cv_RemoveFreedayOnLR = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[58])
	{
		cv_RemoveFreedayOnLastGuard = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[59])
	{
		cv_PrefStatus = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[60])
	{
		cv_WardenTimer = iNewValue;
	}
	else if (cvar == JB_ConVars[61])
	{
		cv_AdminFlags = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[62])
	{
		cv_PrefBlue = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[63])
	{
		cv_PrefWarden = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[64])
	{
		cv_ConsoleSpew = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[65])
	{
		cv_BuildingsManage = iNewValue;
	}
	else if (cvar == JB_ConVars[66])
	{
		cv_PrefForce = bool:iNewValue;
	}
	else if (cvar == JB_ConVars[67])
	{
		cv_FFButton = bool:iNewValue;
	}
}

#if defined _updater_included
public Action:Updater_OnPluginChecking() Jail_Log("%s Checking if TF2Jail requires an update...", JTAG);
public Action:Updater_OnPluginDownloading() Jail_Log("%s New version has been found, downloading new files...", JTAG);
public Updater_OnPluginUpdated() Jail_Log("%s Download complete, updating files...", JTAG);
public Updater_OnPluginUpdating() Jail_Log("%s Updates complete! You may now reload the plugin or wait for map change/server restart.", JTAG);
#endif

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public OnMapStart()
{
	if (cv_Enabled)
	{
		if (cv_Advertise)
		{
			StartAdvertisement();
		}
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
			{
				g_HasBeenWarden[i] = 0;
			}
		}
		
		if (cv_WardenModel)
		{
			decl String:s[PLATFORM_MAX_PATH];
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
			if (PrecacheModel(s, true))
			{
				decl i;
				
				new String:model_extensions[][] = { ".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy" };
				for (i = 0; i < sizeof(model_extensions); i++)
				{
					Format(s, PLATFORM_MAX_PATH, "%s%s", WARDEN_MODEL, model_extensions[i]);
					if (FileExists(s, true)) AddFileToDownloadsTable(s);
				}
				
				new String:material_extensions[][] = { ".vtf", ".vmt" };
				for (i = 0; i < sizeof(material_extensions); i++)
				{
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/NineteenEleven%s", material_extensions[i]);
					AddFileToDownloadsTable(s);
					
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/warden_body%s", material_extensions[i]);
					AddFileToDownloadsTable(s);
					
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/warden_hat%s", material_extensions[i]);
					AddFileToDownloadsTable(s);
					
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/warden_head%s", material_extensions[i]);
					AddFileToDownloadsTable(s);
				}
			}
			else
			{
				Jail_Log("Error precaching model, please check configurations and file integrity.");
				cv_WardenModel = false;
			}
		}
		
		PrecacheSound("ui/system_message_alert.wav", true);
		
		g_1stRoundFreeday = true;
		g_VotesNeeded = 0;
		WardenLimit = 0;
		
		ResetVotes();
	}
}

public OnMapEnd()
{
	if (cv_Enabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				g_HasTalked[i] = false;
				g_IsMuted[i] = false;
				g_IsQueuedFreeday[i] = false;
				g_LockedFromWarden[i] = false;
				g_HasBeenWarden[i] = 0;
				
				if (IsWarden(i))
				{
					RemoveModel(i);
				}
				
				hTimer_ParticleTimers[i] = INVALID_HANDLE;
				hTimer_RebelTimers[i] = INVALID_HANDLE;
				
				for (new x = 0; x < sizeof(TextNodes); x++)
				{
					if (TextNodes[x] == INVALID_HANDLE) continue;
					ClearSyncHud(i, TextNodes[x]);
				}
			}
		}

		g_bActiveRound = false;
		g_bAdminLockWarden = false;
		WardenLimit = 0;
		LR_Current = -1;
		ResetVotes();
		
		ConvarsSet(false);
		
		hTimer_Advertisement = INVALID_HANDLE;
		hTimer_FreekillingData = INVALID_HANDLE;
		hTimer_OpenCells = INVALID_HANDLE;
		hTimer_FriendlyFireEnable = INVALID_HANDLE;
		hTimer_WardenLock = INVALID_HANDLE;
	}
}

public OnClientConnected(client)
{
	g_Voted[client] = false;
	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(cv_WVotesNeeded));
}

public OnClientCookiesCached(client)
{
	if (IsValidClient(client))
	{
		decl String:value[8];
		
		if (cv_PrefStatus)
		{
			GetClientCookie(client, g_hRolePref_Blue, value, sizeof(value));
			g_bRolePreference_Blue[client] = (value[0] != '\0' && StringToInt(value));
			if(StrEqual(value, ""))
			{
				SetClientCookie(client, g_hRolePref_Blue, "1");
			}
			
			GetClientCookie(client, g_hRolePref_Warden, value, sizeof(value));
			g_bRolePreference_Warden[client] = (value[0] != '\0' && StringToInt(value));
			if(StrEqual(value, ""))
			{
				SetClientCookie(client, g_hRolePref_Warden, "1");
			}
		}
	}
}

public OnClientPutInServer(client)
{
	g_IsMuted[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!cv_Enabled) return Plugin_Continue;
	if (IsValidClient(client) && IsValidClient(attacker) && attacker > 0 && attacker <= MaxClients)
	{
		if (g_IsFreeday[client] && !IsWarden(attacker))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		
		if (g_bDisableCriticals) return Plugin_Continue;
		
		switch (GetClientTeam(attacker))
		{
		case TFTeam_Red:
			{
				switch (cv_Criticals)
				{
				case 2, 3:
					{
						switch (cv_Criticalstype)
						{
						case 1: damagetype |= DMG_SLOWBURN;
						case 2: damagetype |= DMG_CRIT;
						}
						return Plugin_Changed;
					}
				}
			}
		case TFTeam_Blue:
			{
				switch (cv_Criticals)
				{
				case 1, 3:
					{
						switch (cv_Criticalstype)
						{
						case 1: damagetype |= DMG_SLOWBURN;
						case 2: damagetype |= DMG_CRIT;
						}
						return Plugin_Changed;
					}
				}
			}
		}
		if (cv_WardenStabProtection == 2)
		{
			if (IsWarden(client))
			{
				decl String:szClassName[64];
				GetEntityClassname(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), szClassName, sizeof(szClassName));
				if (StrEqual(szClassName, "tf_weapon_knife") && (damagetype & DMG_CRIT == DMG_CRIT))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	if (cv_Enabled)
	{
		CreateTimer(5.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)
{
	if (!cv_Enabled) return;

	if (IsValidClient(client))
	{
		if (g_Voted[client])
		{
			g_Votes--;
		}
		
		g_Voters--;
		g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(cv_WVotesNeeded));
		
		if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded)
		{
			if (cv_WVotesPostAction == 1)
			{
				return;
			}
			FireWardenCall();
		}

		if (IsWarden(client))
		{
			CPrintToChatAll("%s %t", JTAG_COLORED, "warden disconnected");
			PrintCenterTextAll("%t", "warden disconnected center");
			Warden = -1;
		}
		
		g_HasTalked[client] = false;
		g_IsMuted[client] = false;
		g_ScoutsBlockedDoubleJump[client] = false;
		g_PyrosDisableAirblast[client] = false;
		g_IsRebel[client] = false;
		g_IsQueuedFreeday[client] = false;
		g_Killcount[client] = 0;
		g_FirstKill[client] = 0;
		
		ClearTimer(hTimer_ParticleTimers[client]);
		
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		g_IsRebel[client] = false;
		
		switch (GetClientTeam(client))
		{
		case TFTeam_Red:
			{
				switch (class)
				{
				case TFClass_Scout:
					{
						if (cv_DoubleJump)
						{
							AddAttribute(client, "no double jump", 1.0);
							g_ScoutsBlockedDoubleJump[client] = true;
						}
					}
				case TFClass_Pyro:
					{
						if (cv_Airblast)
						{
							AddAttribute(client, "airblast disabled", 1.0);
							g_PyrosDisableAirblast[client] = true;
						}
					}
				case TFClass_DemoMan:
					{
						if (cv_DemoCharge)
						{
							new ent = -1;
							while ((ent = FindEntityByClassnameSafe(ent, "tf_wearable_demoshield")) != -1)
							{
								AcceptEntityInput(ent, "kill");
							}
						}
					}
				}
				
				if (cv_RedMute != 0)
				{
					MutePlayer(client);
				}
				
				if (g_IsQueuedFreeday[client])
				{
					GiveFreeday(client);
				}
			}
		case TFTeam_Blue:
			{
				#if defined _voiceannounce_ex_included_
				if (e_voiceannounce_ex && cv_MicCheck)
				{
					if (cv_MicCheckType)
					{
						if (!g_HasTalked[client] && !IsVIP(client))
						{
							ChangeClientTeam(client, _:TFTeam_Red);
							TF2_RespawnPlayer(client);
							CPrintToChat(client, "%s %t", JTAG_COLORED, "microphone unverified");
						}
					}
				}
				#endif
				
				if (cv_BlueMute == 2)
				{
					MutePlayer(client);
				}
			}
		}
	}
}

public PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(client) && IsValidClient(client_attacker))
	{
		if (client_attacker != client)
		{
			if (g_IsFreeday[client_attacker])
			{
				RemoveFreeday(client_attacker);
			}

			if (cv_Rebels)
			{
				if (GetClientTeam(client_attacker) == _:TFTeam_Red && GetClientTeam(client) == _:TFTeam_Blue && !g_IsRebel[client_attacker])
				{
					MarkRebel(client_attacker);
				}
			}
		}
	}
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_IsFreeday[client])
	{
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsValidClient(client))
	{
		if (IsValidClient(client_killer))
		{
			if (client_killer != client)
			{
				if (cv_Freekillers)
				{
					if (GetClientTeam(client_killer) == _:TFTeam_Blue)
					{
						if ((g_FirstKill[client_killer] + cv_FreekillersTime) >= GetTime())
						{
							if (++g_Killcount[client_killer] == cv_FreekillersKills)
							{
								if (!g_VoidFreekills)
								{
									MarkFreekiller(client_killer);
								}
								else
								{
									CPrintToChatAll("%s %t", JTAG_COLORED, "freekiller flagged while void", client_killer);
								}
							}
						}
						else
						{
							g_Killcount[client_killer] = 1;
							g_FirstKill[client_killer] = GetTime();
						}
					}
				}
			}
		}
				
		if (cv_LRSAutomatic && g_bLRConfigActive)
		{
			if (Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE) == 1)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						LastRequestStart(i, 0);
						Jail_Log("%N has received last request for being the last prisoner alive.", i);
					}
				}
			}
		}
		
		new blue_count = Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE);
		
		if (cv_RemoveFreedayOnLastGuard)
		{
			if (blue_count == 1)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (g_IsFreeday[i])
					{
						RemoveFreeday(i);
					}
				}
			}
		}
		
		if (!g_bOneGuardLeft)
		{
			if (blue_count == 1)
			{
				g_VoidFreekills = true;
				g_bOneGuardLeft = true;
				PrintCenterTextAll("%t", "last guard");
			}
		}

		if (cv_DeadMute)
		{
			MutePlayer(client);
		}

		if (g_IsFreeday[client])
		{
			RemoveFreeday(client);
			Jail_Log("%N was an active freeday on round.", client);
		}
		
		if (g_PyrosDisableAirblast[client])
		{
			RemoveAttribute(client, "airblast disabled");
			g_PyrosDisableAirblast[client] = false;
		}
		
		if (g_ScoutsBlockedDoubleJump[client])
		{
			RemoveAttribute(client, "no double jump");
			g_ScoutsBlockedDoubleJump[client] = false;
		}
		
		ClearTimer(hTimer_ParticleTimers[client]);
			
		if (IsWarden(client))
		{
			WardenUnset(client);
			PrintCenterTextAll("%t", "warden killed", client);
		}
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	if (cv_1stDayFreeday && g_1stRoundFreeday)
	{
		DoorHandler(OPEN);
		PrintCenterTextAll("1st round freeday");
		
		decl String:s1stDay[255];
		Format(s1stDay, sizeof(s1stDay), "%t", "1st day freeday node");
		SetTextNode(TextNodes[0], s1stDay, eaTNPs[0][eCoord_X], eaTNPs[0][eCoord_Y], eaTNPs[0][eHoldTime], eaTNPs[0][eRed], eaTNPs[0][eGreen], eaTNPs[0][eBlue], eaTNPs[0][eAlpha], eaTNPs[0][eEffect], eaTNPs[0][efxTime], eaTNPs[0][eFadeIn], eaTNPs[0][eFadeOut]);
		g_1stRoundFreeday = false;
		Jail_Log("1st day freeday has been activated.");
	}
	
	if (g_IsMapCompatible)
	{
		if (!StrEqual(GCellOpener, ""))
		{
			new CellHandler = Entity_FindByName(GCellOpener, "func_button");
			if (Entity_IsValid(CellHandler))
			{
				if (cv_DoorControl)
				{
					Entity_Lock(CellHandler);
					Jail_Log("Door Controls: Disabled - Cell Opener is locked.");
				}
				else
				{
					Entity_UnLock(CellHandler);
					Jail_Log("Door Controls: Enabled - Cell Opener is unlocked.");
				}
			}
			else
			{
				Jail_Log("[ERROR] Entity name not found for Cell Door Opener! Please verify integrity of the config and the map.");
			}
		}
		
		if (!StrEqual(GFFButton, ""))
		{
			new FFButton = Entity_FindByName(GFFButton, "func_button");
			if (Entity_IsValid(FFButton))
			{
				if (cv_FFButton)
				{
					Entity_Lock(FFButton);
					Jail_Log("FF Button: Disabled.");
				}
				else
				{
					Entity_UnLock(FFButton);
					Jail_Log("FF Button: Enabled.");
				}
			}
		}
	}
	
	Warden = -1;
	g_bIsLRInUse = false;
	g_bActiveRound = true;
}

public ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;
	
	g_bIsWardenLocked = false;
	
	if (cv_Balance)
	{
		new Float:Ratio;
		for (new i = 1; i <= MaxClients; i++)
		{
			Ratio = float(GetTeamClientCount(_:TFTeam_Blue)) / float(GetTeamClientCount(_:TFTeam_Red));
			
			if (Ratio <= cv_BalanceRatio || GetTeamClientCount(_:TFTeam_Red) <= 2)
			{
				break;
			}
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				if (cv_PrefStatus && g_bRolePreference_Blue[i])
				{
					continue;
				}

				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);
				
				CPrintToChat(i, "%s %t", JTAG_COLORED, "moved for balance");
				Jail_Log("%N has been moved to prisoners team for balance.", i);
			}
		}
	}
	
	if (g_IsMapCompatible && cv_DoorOpenTimer != 0.0)
	{
		new autoopen = RoundFloat(cv_DoorOpenTimer);
		hTimer_OpenCells = CreateTimer(cv_DoorOpenTimer, Open_Doors, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		CPrintToChatAll("%s %t", JTAG_COLORED, "cell doors open start", autoopen);
		Jail_Log("Cell doors are being auto opened via automatic timer.");
		g_CellsOpened = true;
	}

	switch(cv_RedMute)
	{
	case 0:
		{
			CPrintToChatAll("%s %t", JTAG_COLORED, "red mute system disabled");
			Jail_Log("Mute system has been disabled this round, nobody has been muted.");
		}
	case 1:
		{
			new time = RoundFloat(cv_RedMuteTime);
			CPrintToChatAll("%s %t", JTAG_COLORED, "red team muted temporarily", time);
			CreateTimer(cv_RedMuteTime, UnmuteReds, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
			Jail_Log("Red team has been temporarily muted and will wait %s seconds to be unmuted.", time);
		}
	case 2:
		{
			CPrintToChatAll("%s %t", JTAG_COLORED, "red team muted");
			Jail_Log("Red team has been muted permanently this round.");
		}
	}
		
	if (LR_Current != -1)
	{
		new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(hConfig, LRConfig_File);
		
		new String:buffer[255], String:number[255];
		if (KvGotoFirstSubKey(hConfig))
		{
			do
			{
				IntToString(LR_Current, number, sizeof(number));
				KvGetSectionName(hConfig, buffer, sizeof(buffer));
				
				if (StrEqual(buffer, number))
				{
					if (StrEqual(CustomLR, ""))
					{
						new String:LR_Name[255], String:LR_Message[255];
						KvGetString(hConfig, "Name", LR_Name, sizeof(LR_Name));
						Format(LR_Message, sizeof(LR_Message), "%t", "last request node", LR_Name);
						SetTextNode(TextNodes[1], LR_Message, eaTNPs[1][eCoord_X], eaTNPs[1][eCoord_Y], eaTNPs[1][eHoldTime], eaTNPs[1][eRed], eaTNPs[1][eGreen], eaTNPs[1][eBlue], eaTNPs[1][eAlpha], eaTNPs[1][eEffect], eaTNPs[1][efxTime], eaTNPs[1][eFadeIn], eaTNPs[1][eFadeOut]);
					}
					
					new bool:IsFreedayRound = false, String:ServerCommands[255];
					
					decl String:Handler[PLATFORM_MAX_PATH];
					KvGetString(hConfig, "Handler", Handler, sizeof(Handler));
					
					Call_StartForward(sFW_OnLastRequestExecute);
					Call_PushString(Handler);
					Call_Finish();
					
					if (KvGetString(hConfig, "Execute_Cmd", ServerCommands, sizeof(ServerCommands)))
					{
						if (!StrEqual(ServerCommands, ""))
						{
							new Handle:pack;
							CreateDataTimer(0.5, ExecuteServerCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
							WritePackString(pack, ServerCommands);
						}
					}
					
					if (KvJumpToKey(hConfig, "Parameters"))
					{
						if (KvGetNum(hConfig, "IsFreedayType", 0) != 0)
						{
							IsFreedayRound = true;
						}

						if (KvGetNum(hConfig, "OpenCells", 0) == 1)
						{
							DoorHandler(OPEN);
						}
						
						if (KvGetNum(hConfig, "VoidFreekills", 0) == 1)
						{
							g_VoidFreekills = true;
						}
						
						if (KvGetNum(hConfig, "TimerStatus", 1) == 0)
						{
							RoundTimer_Stop();
						}
						
						if (KvGetNum(hConfig, "LockWarden", 0) == 1)
						{
							g_bLockWardenLR = true;
						}
						
						if (KvGetNum(hConfig, "EnableCriticals", 0) == 0)
						{
							g_bDisableCriticals = true;
						}
						
						if (KvJumpToKey(hConfig, "KillWeapons"))
						{
							for (new i = 1; i < MaxClients; i++)
							{
								if (IsValidClient(i) && IsPlayerAlive(i))
								{
									switch (GetClientTeam(i))
									{
									case TFTeam_Red:
										{
											if (KvGetNum(hConfig, "Red", 0) == 1)
											{
												StripToMelee(i);
											}
										}
									case TFTeam_Blue:
										{
											if (KvGetNum(hConfig, "Blue", 0) == 1)
											{
												StripToMelee(i);
											}
										}
									}
									
									if (KvGetNum(hConfig, "Warden", 0) == 1 && IsWarden(i))
									{
										StripToMelee(i);
									}
								}
							}
							KvGoBack(hConfig);
						}
						
						if (KvJumpToKey(hConfig, "FriendlyFire"))
						{
							if (KvGetNum(hConfig, "Status", 0) == 1)
							{
								new Float:TimeFloat = KvGetFloat(hConfig, "Timer", 1.0);
								if (TimeFloat >= 0.1)
								{
									hTimer_FriendlyFireEnable = CreateTimer(TimeFloat, EnableFFTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
								}
								else
								{
									Jail_Log("[ERROR] Timer is set to a value below 0.1! Timer could not be created.");
								}
							}
							KvGoBack(hConfig);
						}
						KvGoBack(hConfig);
					}
					
					decl String:ActiveAnnounce[255];
					if (KvGetString(hConfig, "Activated", ActiveAnnounce, sizeof(ActiveAnnounce)))
					{
						if (IsFreedayRound)
						{
							decl String:ClientName[32];
							for (new i = 1; i <= MaxClients; i++)
							{
								if (g_IsFreeday[i])
								{
									GetClientName(i, ClientName, sizeof(ClientName));
									ReplaceString(ActiveAnnounce, sizeof(ActiveAnnounce), "%M", ClientName, true);
									Format(ActiveAnnounce, sizeof(ActiveAnnounce), "%s %s", JTAG_COLORED, ActiveAnnounce);
									CPrintToChatAll(ActiveAnnounce);
								}
							}
							FreedayForAll(false);
						}
						else
						{
							Format(ActiveAnnounce, sizeof(ActiveAnnounce), "%s %s", JTAG_COLORED, ActiveAnnounce);
							CPrintToChatAll(ActiveAnnounce);
						}
					}
				}
			} while (KvGotoNextKey(hConfig));
		}
		CloseHandle(hConfig);
	}
	
	if (!StrEqual(CustomLR, ""))
	{
		SetTextNode(TextNodes[1], CustomLR, eaTNPs[1][eCoord_X], eaTNPs[1][eCoord_Y], eaTNPs[1][eHoldTime], eaTNPs[1][eRed], eaTNPs[1][eGreen], eaTNPs[1][eBlue], eaTNPs[1][eAlpha], eaTNPs[1][eEffect], eaTNPs[1][efxTime], eaTNPs[1][eFadeIn], eaTNPs[1][eFadeOut]);
		CustomLR[0] = '\0';
	}
	
	FindRandomWarden();
}

public RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if (!cv_Enabled) return;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			UnmutePlayer(i);
			
			if (g_IsFreeday[i])
			{
				RemoveFreeday(i);
			}
			
			if (g_ScoutsBlockedDoubleJump[i])
			{
				RemoveAttribute(i, "no double jump");
				g_ScoutsBlockedDoubleJump[i] = false;
			}
			
			if (g_PyrosDisableAirblast[i])
			{
				RemoveAttribute(i, "airblast disabled");
				g_PyrosDisableAirblast[i] = false;
			}
			
			if (g_HasModel[i])
			{
				RemoveModel(i);
			}
			
			hTimer_RebelTimers[i] = INVALID_HANDLE;
			
			for (new x = 0; x < sizeof(TextNodes); x++)
			{
				if (TextNodes[x] == INVALID_HANDLE) continue;
				ClearSyncHud(i, TextNodes[x]);
			}
		}
	}
	
	ResetConVar(JB_EngineConVars[0], false, false);
	ResetConVar(JB_EngineConVars[1], false, false);
	
	g_bIsWardenLocked = true;
	g_bOneGuardLeft = false;
	g_bActiveRound = false;
	g_VoidFreekills = false;
	FreedayLimit = 0;
	g_bLockWardenLR = false;
	g_bDisableCriticals = false;
	
	ClearTimer(hTimer_OpenCells);
	ClearTimer(hTimer_WardenLock);
	ClearTimer(hTimer_FriendlyFireEnable);
	
	if (LR_Current != -1)
	{
		new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(hConfig, LRConfig_File);
		
		new String:buffer[255], String:number[255];
		if (KvGotoFirstSubKey(hConfig))
		{
			do
			{
				IntToString(LR_Current, number, sizeof(number));
				KvGetSectionName(hConfig, buffer, sizeof(buffer));
				
				if (StrEqual(buffer, number))
				{
					new String:ServerCommands[255];
					if (KvGetString(hConfig, "Ending_Cmd", ServerCommands, sizeof(ServerCommands)))
					{
						if (!StrEqual(ServerCommands, ""))
						{							
							new Handle:pack;
							CreateDataTimer(0.5, ExecuteServerCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
							WritePackString(pack, ServerCommands);
						}
					}
				}
			} while (KvGotoNextKey(hConfig));
		}
		CloseHandle(hConfig);
	}
	
	LR_Current = -1;
	if (LR_Pending != -1)
	{
		LR_Current = LR_Pending;
		LR_Pending = -1;
	}
}

public RegeneratePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	RequestFrame(ManageWeapons, GetEventInt(event, "userid"));
}

public OnEntityCreated(entity, const String:classname[])
{
	if (cv_Enabled && IsValidEntity(entity))
	{
		if (StrContains(classname, "tf_ammo_pack", false) != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
		
		if (cv_KillPointServerCommand)
		{
			//Crashing on Linux
			/*if (StrContains(classname, "point_servercommand", false) != -1)
			{
				if (cv_KillPointServerCommand)
				{
					AcceptEntityInput(entity, "Kill");
				}
			}*/
		}
	}
}

public Action:InterceptBuild(client, const String:command[], args)
{
	if (!cv_Enabled) return Plugin_Continue;
	
	if (IsValidClient(client)) return Plugin_Continue;
	
	switch (cv_BuildingsManage)
	{
		case 1:
			{
				if (GetClientTeam(client) != _:TFTeam_Blue)
				{
					return Plugin_Handled;
				}
			}
		case 2:
			{
				if (GetClientTeam(client) != _:TFTeam_Red)
				{
					return Plugin_Handled;
				}
			}
		case 3: return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientSayCommand_Post(client, const String:command[], const String:sArgs[])
{
	if (client == CustomClient)
	{
		strcopy(CustomLR, sizeof(CustomLR), sArgs);
		CPrintToChat(client, "%s %t", JTAG_COLORED, "last request custom set", CustomLR);
		Jail_Log("Custom LR set to %s by client %N.", CustomLR, client);
		CustomClient = -1;
	}
}

#if defined _voiceannounce_ex_included_
public bool:OnClientSpeakingEx(client)
{
	if (cv_Enabled && e_voiceannounce_ex && cv_MicCheck && !g_HasTalked[client])
	{
		g_HasTalked[client] = true;
		CPrintToChat(client, "%s %t", JTAG_COLORED, "microphone verified");
	}
}
#endif

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:Command_FireWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
		
	if (cv_WVotesPassedLimit != 0)
	{
		if (WardenLimit < cv_WVotesPassedLimit)
		{
			AttemptFireWarden(client);
		}
		else
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "warden fire limit reached");
		}
	}
	else
	{
		AttemptFireWarden(client);
	}
	
	return Plugin_Handled;
}

AttemptFireWarden(client)
{
	if (GetClientCount(true) < cv_WVotesMinPlayers)
	{
		CReplyToCommand(client, "%s %t", JTAG, "fire warden minimum players not met");
		return;			
	}

	if (g_Voted[client])
	{
		CReplyToCommand(client, "%s %t", JTAG, "fire warden already voted", g_Votes, g_VotesNeeded);
		return;
	}

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	g_Votes++;
	g_Voted[client] = true;

	CPrintToChatAll("%s %t", JTAG_COLORED, "fire warden requested", name, g_Votes, g_VotesNeeded);

	if (g_Votes >= g_VotesNeeded)
	{
		FireWardenCall();
	}
}

FireWardenCall()
{
	if (Warden != -1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsWarden(i))
			{
				WardenUnset(i);
				g_LockedFromWarden[i] = true;
			}
		}
		ResetVotes();
		g_VotesPassed++;
		WardenLimit++;
	}
}

ResetVotes()
{
	g_Votes = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		g_Voted[i] = false;
	}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:AdminMapCompatibilityCheck(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!StrEqual(GCellNames, ""))
	{
		new cell_door = Entity_FindByName(GCellNames, "func_door");
		CReplyToCommand(client, "%s %t", JTAG, Entity_IsValid(cell_door) ? "Map Compatibility Cell Doors Detected" : "Map Compatibility Cell Doors Undetected");
	}
		
	if (!StrEqual(GCellOpener, ""))
	{
		new open_cells = Entity_FindByName(GCellOpener, "func_button");		
		CReplyToCommand(client, "%s %t", JTAG, Entity_IsValid(open_cells) ? "Map Compatibility Cell Opener Detected" : "Map Compatibility Cell Opener Undetected");
	}
	
	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Scan Map Compatibility");
	Jail_Log("Admin %N has checked the map for compatibility.", client);
	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_ScoutsBlockedDoubleJump[i] = false;
		g_PyrosDisableAirblast[i] = false;
		g_IsMuted[i] = false;
		g_IsRebel[i] = false;
		g_IsQueuedFreeday[i] = false;
		g_IsFreeday[i] = false;
		g_IsFreekiller[i] = false;
		g_HasTalked[i] = false;
		g_LockedFromWarden[i] = false;
		g_HasModel[i] = false;

		g_FirstKill[i] = 0;
		g_Killcount[i] = 0;
		g_HasBeenWarden[i] = 0;
	}
	
	g_CellsOpened = false;
	g_1stRoundFreeday = false;
	g_VoidFreekills = false;
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	g_bOneGuardLeft = false;
	g_bLateLoad = false;
	g_bLockWardenLR = false;
	g_bDisableCriticals = false;

	Warden = -1;
	WardenLimit = 0;
	FreedayLimit = 0;

	EnumWardenMenu = Open;
	
	ParseConfigs();

	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Reset Plugin");
	Jail_Log("Admin %N has reset the plugin of all it's bools, integers and floats.", client);

	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(OPEN);
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Open Cells");
		Jail_Log("Admin %N has opened the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminCloseCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(CLOSE);
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Close Cells");
		Jail_Log("Admin %N has closed the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminLockCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(LOCK);
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Lock Cells");
		Jail_Log("Admin %N has locked the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "incompatible map");
	}
	
	return Plugin_Handled;
}

public Action:AdminUnlockCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (g_IsMapCompatible)
	{
		DoorHandler(UNLOCK);
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Unlock Cells");
		Jail_Log("Admin %N has unlocked the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminForceWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (Warden != -1)
	{
		CReplyToCommand(client, "%s %t", JTAG, "warden current", Warden);
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		FindWardenRandom(client);
	}
	else
	{
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));

		new target = FindTarget(client, arg1);
		if (target != -1 || target <= 2 || target != client)
		{
			if (!IsPlayerAlive(target))
			{
				CReplyToCommand(client, "%s %t", JTAG, "Target must be alive");
				return Plugin_Handled;
			}
			
			if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) < 2)
			{
				WardenSet(target);
				CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden", target);
				Jail_Log("Admin %N has forced a %N Warden.", client, target);
				return Plugin_Handled;
			}
			
			if (cv_PrefStatus)
			{
				if (cv_PrefForce)
				{
					WardenSet(target);
					CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden", target);
					Jail_Log("Admin %N has forced a %N Warden.", client, target);
					return Plugin_Handled;
				}
				
				if (g_bRolePreference_Warden[target])
				{
					WardenSet(target);
					CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden", target);
					Jail_Log("Admin %N has forced a %N Warden.", client, target);
				}
				else
				{
					CReplyToCommand(client, "%s %t", JTAG, "Admin Force Warden Not Preferred", target);
					Jail_Log("Client %N has their preference set to prisoner only, finding another client...", target);
				}
				return Plugin_Handled;
			}
			
			WardenSet(target);
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden", target);
			Jail_Log("Admin %N has forced a %N Warden.", client, target);
		}
	}
	return Plugin_Handled;
}

FindWardenRandom(client)
{
	new Random = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
	if (IsValidClient(Random))
	{
		if (cv_PrefStatus)
		{
			if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) != 1)
			{
				if (g_bRolePreference_Warden[Random])
				{
					WardenSet(Random);
					CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden Random", Random);
					Jail_Log("Admin %N has given %N Warden by Force.", client, Random);
				}
				else
				{
					CPrintToChat(client, "%s %t", JTAG_COLORED, "Admin Force Random Warden Not Preferred", Random);
					Jail_Log("Client %N has their preference set to prisoner only, finding another client...", Random);
					FindWardenRandom(client);
				}
			}
			else
			{
				WardenSet(Random);
				CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden Random", Random);
				Jail_Log("Admin %N has given %N Warden by Force.", client, Random);
			}
		}
		else
		{
			WardenSet(Random);
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Warden Random", Random);
			Jail_Log("Admin %N has given %N Warden by Force.", client, Random);
		}
	}
}

public Action:AdminForceLR(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", JTAG, "last request config invalid");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Last Request Self");
		LastRequestStart(client, client);
		Jail_Log("Admin %N has given his/herself last request using admin.", client);
	}
	else
	{
		decl String:arg[64];
		GetCmdArgString(arg, sizeof(arg));

		new target = FindTarget(client, arg, true, false);
		
		if (target != -1 || target != client)
		{
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Force Last Request", target);
			LastRequestStart(target, client, false);
			Jail_Log("Admin %N has gave %N a Last Request by admin.", client, target);
		}
	}
	
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", JTAG, "last request config invalid");
		return Plugin_Handled;
	}
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (g_IsQueuedFreeday[i])
			{
				CPrintToChat(client, "%s %t", JTAG_COLORED, "admin removed freeday");
				g_IsQueuedFreeday[i] = false;
			}
			
			if (g_IsFreeday[i])
			{
				CPrintToChat(client, "%s %t", JTAG_COLORED, "admin removed freeday active");
				g_IsFreeday[i] = false;
			}
			
			if (TextNodes[1] != INVALID_HANDLE)
			{
				ClearSyncHud(i, TextNodes[1]);
			}
		}
	}
	
	g_bIsLRInUse = false;
	
	LR_Pending = -1;
	LR_Current = -1;
	
	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Deny Last Request");
	Jail_Log("Admin %N has denied all currently queued last requests and reset the last request system.", client);
	
	return Plugin_Handled;
}

public Action:AdminPardonFreekiller(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	if (cv_Freekillers)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_IsFreekiller[i])
			{
				TF2_RegeneratePlayer(i);
				ServerCommand("sm_beacon #%d", GetClientUserId(i));
				g_IsFreekiller[i] = false;
				ClearTimer(hTimer_FreekillingData);
				ClearTimer(hTimer_ParticleTimers[i]);
			}
		}
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Pardon Freekillers");
		Jail_Log("Admin %N has pardoned all currently marked Freekillers.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "freekillers system disabled");
	}
	return Plugin_Handled;
}

public Action:AdminGiveFreeday(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", JTAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	GiveFreedaysMenu(client);
	return Plugin_Handled;
}

GiveFreedaysMenu(client)
{
	if(IsVoteInProgress()) return;
		
	new Handle:hMenu = CreateMenu(MenuHandle_FreedayAdmins);
	SetMenuTitle(hMenu,"Choose a Player");
	AddTargetsToMenu2(hMenu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	DisplayMenu(hMenu, client, 20);
	
	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Give Freeday Menu");
	Jail_Log("Admin %N is giving someone a freeday...", client);
}

public MenuHandle_FreedayAdmins(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(hMenu, param2, info, sizeof(info));

			new target = GetClientOfUserId(StringToInt(info));
			if (IsValidClient(target))
			{
				GiveFreeday(target);
				Jail_Log("%N has given %N a Freeday.", target, param1);
			}
			else
			{
				CPrintToChat(param1, "%s %t", JTAG_COLORED, "Player no longer available");
			}
			GiveFreedaysMenu(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public Action:AdminRemoveFreeday(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", JTAG, "last request config invalid");
		return Plugin_Handled;
	}
		
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	RemoveFreedaysMenu(client);
	return Plugin_Handled;
}

RemoveFreedaysMenu(client)
{
	if (IsVoteInProgress()) return;
	
	decl String:user_id[12], String:name[MAX_NAME_LENGTH], String:display[MAX_NAME_LENGTH+12];
	
	new Handle:hMenu = CreateMenu(MenuHandle_RemoveFreedays);
	SetMenuTitle(hMenu,"Choose an active Freeday");	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && g_IsFreeday[i])
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
			GetClientName(i, name, sizeof(name));
			Format(display, sizeof(display), "%s (%s)", name, user_id);
			AddMenuItem(hMenu, user_id, display);
		}
	}
	DisplayMenu(hMenu, client, 20);
	
	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Remove Freeday Menu");
	Jail_Log("Admin %N is removing someone's freeday status...", client);
}

public MenuHandle_RemoveFreedays(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[32];
			GetMenuItem(hMenu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));
			
			if (!IsValidClient(target))
			{
				CReplyToCommand(param1, "%s %t", JTAG, "Player no longer available");
				return;
			}
			
			if (g_IsFreeday[target])
			{
				RemoveFreeday(target);
				Jail_Log("%N has removed %N's Freeday.", param1, target);
			}
			else
			{
				CReplyToCommand(param1, "%s %t", JTAG, "lr freeday removed invalid", target);
			}
			
			RemoveFreedaysMenu(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public Action:AdminAcceptWardenChange(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (Warden == -1)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "no warden current", Warden);
		return Plugin_Handled;
	}

	switch (EnumWardenMenu)
	{
	case Open:
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "no current requests");
		}
	case FriendlyFire:
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Accept Request FF", Warden);
			CPrintToChatAll("%s %t", JTAG_COLORED, "friendlyfire enabled");
			Jail_Log("Admin %N has accepted %N's request to enable Friendly Fire.", client, Warden);
		}
	case Collision:
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Accept Request CC", Warden);
			CPrintToChatAll("%s %t", JTAG_COLORED, "collision enabled");
			Jail_Log("Admin %N has accepted %N's request to enable Collision.", client, Warden);
		}
	}
	return Plugin_Handled;
}

public Action:AdminCancelWardenChange(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (Warden == -1)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "no warden current", Warden);
		return Plugin_Handled;
	}
	
	switch (EnumWardenMenu)
	{
	case Open:
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "no active warden commands");
		}
	case FriendlyFire:
		{
			ResetConVar(JB_EngineConVars[0], false, false);
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Cancel Active FF");
			CPrintToChatAll("%s %t", JTAG_COLORED, "friendlyfire disabled");
			Jail_Log("Admin %N has cancelled %N's request for Friendly Fire.", client, Warden);
		}
	case Collision:
		{
			ResetConVar(JB_EngineConVars[1], false, false);
			CShowActivity2(client, JTAG_COLORED, "%t", "Admin Cancel Active CC");
			CPrintToChatAll("%s %t", JTAG_COLORED, "collision disabled");
			Jail_Log("Admin %N has cancelled %N's request for Collision.", client, Warden);
		}
	}
	
	EnumWardenMenu = Open;
	
	return Plugin_Handled;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:BecomeWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!cv_Warden)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden disabled");
		return Plugin_Handled;
	}
	
	if (g_1stRoundFreeday || g_bIsWardenLocked)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden locked");
		return Plugin_Handled;
	}
	
	if (cv_LRSLockWarden && g_bLockWardenLR)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden locked lr round");
		return Plugin_Handled;
	}
	
	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden current", Warden);
		return Plugin_Handled;
	}
	
	if (g_bAdminLockWarden)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden locked admin");
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (cv_WardenLimit != 0)
		{
			if (g_HasBeenWarden[client] >= cv_WardenLimit && GetClientTeam(client) == _:TFTeam_Blue)
			{	
				CPrintToChat(client, "%s %t", JTAG_COLORED, "warden limit reached", client, cv_WardenLimit);
				return Plugin_Handled;
			}
		}
		
		#if defined _voiceannounce_ex_included_
		if (cv_MicCheck && !cv_MicCheckType && !g_HasTalked[client])
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "microphone check warden block");
			return Plugin_Handled;
		}
		#endif
		
		if (g_LockedFromWarden[client])
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "voted off of warden");
			return Plugin_Handled;
		}
		
		if (GetClientTeam(client) != _:TFTeam_Blue)
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "guards only");
			return Plugin_Handled;
		}
		
		if (cv_PrefStatus && g_bRolePreference_Warden[client])
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "preference set against guards or warden");
			return Plugin_Handled;
		}

		if (cv_AdminFlags && !CheckCommandAccess(client, "TF2Jail_WardenOverride", ADMFLAG_RESERVATION))
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "warden incorrect flags");
			return Plugin_Handled;
		}
		
		WardenSet(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "dead warden");
	}
	return Plugin_Handled;
}

public Action:CurrentWarden(client, args)
{
	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden current", Warden);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "no warden current", Warden);
	}
	return Plugin_Handled;
}

public Action:WardenMenuC(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
		
	if (IsWarden(client))
	{
		WardenMenu(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
	}

	return Plugin_Handled;
}

WardenMenu(client)
{
	if (IsVoteInProgress()) return;
	
	new Handle:hMenu = CreateMenu(MenuHandle_WardenMenu);
	SetMenuTitle(hMenu, "Available Warden Commands:");
	AddMenuItem(hMenu, "1", "Open Cells");
	AddMenuItem(hMenu, "2", "Close Cells");
	AddMenuItem(hMenu, "3", "Toggle Friendlyfire");
	AddMenuItem(hMenu, "4", "Toggle Collision");
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}

public MenuHandle_WardenMenu(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			switch (param2)
			{
			case 0: FakeClientCommandEx(param1, "say /open");
			case 1: FakeClientCommandEx(param1, "say /close");
			case 2: FakeClientCommandEx(param1, "say /wff");
			case 3: FakeClientCommandEx(param1, "say /wcc");
			}
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public Action:WardenFriendlyFire(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_WardenFF)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden friendly fire manage disabled");
		return Plugin_Handled;
	}
	
	if (!IsWarden(client))
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
		return Plugin_Handled;
	}

	if (!cv_WardenRequest)
	{
		if (!GetConVarBool(JB_EngineConVars[0]))
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CPrintToChatAll("%s %t", JTAG_COLORED, "friendlyfire enabled");
			Jail_Log("%N has enabled friendly fire as warden.", Warden);
		}
		else
		{
			SetConVarBool(JB_EngineConVars[0], false);
			CPrintToChatAll("%s %t", JTAG_COLORED, "friendlyfire disabled");
			Jail_Log("%N has disabled friendly fire as warden.", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", JTAG_COLORED, "friendlyfire request");
		EnumWardenMenu = FriendlyFire;
	}
	
	return Plugin_Handled;
}

public Action:WardenCollision(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!cv_WardenCC)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden collision manage disabled");
		return Plugin_Handled;
	}
	
	if (!IsWarden(client))
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
		return Plugin_Handled;
	}
	
	if (!cv_WardenRequest)
	{
		if (!GetConVarBool(JB_EngineConVars[1]))
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CPrintToChatAll("%s %t", JTAG_COLORED, "collision enabled");
			Jail_Log("%N has enabled collision as warden.", Warden);
		}
		else
		{
			SetConVarBool(JB_EngineConVars[1], false);
			CPrintToChatAll("%s %t", JTAG_COLORED, "collision disabled");
			Jail_Log("%N has disabled collision as warden.", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", JTAG_COLORED, "collision request");
		EnumWardenMenu = Collision;
	}

	return Plugin_Handled;
}

public Action:ExitWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		CPrintToChatAll("%s %t", JTAG_COLORED, "warden retired", client);
		PrintCenterTextAll("%t", "warden retired center");
		WardenUnset(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
	}

	return Plugin_Handled;
}

public Action:LockWarden(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsWarden(i))
		{
			WardenUnset(i);
		}
	}
	g_bAdminLockWarden = true;
	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Lock Warden");
	Jail_Log("Admin %N has locked Warden via administration.", client);
	return Plugin_Handled;
}

public Action:UnlockWarden(client, args)
{
	g_bAdminLockWarden = false;
	CShowActivity2(client, JTAG_COLORED, "%t", "Admin Unlock Warden");
	Jail_Log("Admin %N has unlocked Warden via administration.", client);
	return Plugin_Handled;
}

public Action:AdminRemoveWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (Warden != -1)
	{
		PrintCenterTextAll("%t", "warden fired center");
		CShowActivity2(client, JTAG_COLORED, "%t", "Admin Remove Warden", Warden);
		Jail_Log("Admin %N has removed %N's Warden status with admin.", client, Warden);
		WardenUnset(Warden);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "no warden current");
	}

	return Plugin_Handled;
}

public Action:OnOpenCommand(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
		
	if (cv_DoorControl)
	{
		if (!g_IsMapCompatible)
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "incompatible map");
			return Plugin_Handled;
		}
			
		if (IsWarden(client))
		{
			DoorHandler(OPEN);
			Jail_Log("%N has opened the cell doors using door controls as warden.", client);
		}
		else
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "door controls disabled");
	}
	return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
		
	if (cv_DoorControl)
	{
		if (!g_IsMapCompatible)
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "incompatible map");
		}
		if (IsWarden(client))
		{
			DoorHandler(CLOSE);
			Jail_Log("%N has closed the cell doors using door controls as warden.", client);
		}
		else
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "door controls disabled");
	}
	return Plugin_Handled;
}

public Action:GiveLR(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!cv_LRSEnabled)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "lr system disabled");
		return Plugin_Handled;
	}
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", JTAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		if (!g_bIsLRInUse)
		{
			if (!IsVoteInProgress())
			{
				new Handle:hMenu = CreateMenu(MenuHandle_GiveLR);
				SetMenuTitle(hMenu,"Choose a Player:");
				AddTargetsToMenu2(hMenu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
				DisplayMenu(hMenu, client, 20);
				
				Jail_Log("%N is giving someone a last request...", client);
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", JTAG_COLORED, "last request in use");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
	}

	return Plugin_Handled;
}

public MenuHandle_GiveLR(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[32];
			GetMenuItem(hMenu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));
			
			if (IsValidClient(target) && Warden != -1)
			{
				decl String:Name[MAX_NAME_LENGTH];
				GetClientName(target, Name, sizeof(Name));
				
				if (GetClientTeam(target) != _:TFTeam_Red)
				{
					CPrintToChat(param1, "%s %t", JTAG_COLORED, "prisoners only");
					return;
				}
				
				LastRequestStart(target, param1);
				CPrintToChatAll("%s %t", JTAG_COLORED, "last request given", Warden, target);
				Jail_Log("%N has given %N a Last Request as warden.", param1, target);
			}
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public Action:CurrentLR(client, args)
{
	if (LR_Current != -1)
	{
		new String:number[255];
		new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
		if (FileToKeyValues(hConfig, LRConfig_File))
		{
			IntToString(LR_Current, number, sizeof(number));
			if (KvGotoFirstSubKey(hConfig))
			{
				decl String:ID[64], String:Name[255];
				do
				{
					KvGetSectionName(hConfig, ID, sizeof(ID));    
					KvGetString(hConfig, "Name", Name, sizeof(Name));
					if (StrEqual(ID, number))
					{
						CPrintToChat(client, "%s %t", JTAG_COLORED, "current last requests", Name);
					}
				} while (KvGotoNextKey(hConfig));
			}
		}
		CloseHandle(hConfig);
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "no current last requests");
	}
	return Plugin_Handled;
}

public Action:ListLRs(client, args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	CurrentLRList(client);
	return Plugin_Handled;
}

CurrentLRList(client)
{
	if (IsVoteInProgress()) return;

	new Handle:hMenu = CreateMenu(MenuHandle_ListLRs);
	SetMenuTitle(hMenu, "Last Requests List");
	ParseLastRequests(client, hMenu);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}

public MenuHandle_ListLRs(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			new String:choice[255];
			GetMenuItem(hMenu, param2, choice, sizeof(choice));
			
			new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
			FileToKeyValues(hConfig, LRConfig_File);
			
			if (KvGotoFirstSubKey(hConfig))
			{
				new String:buffer[255];
				do
				{
					KvGetSectionName(hConfig, buffer, sizeof(buffer));
					if (StrEqual(buffer, choice))
					{
						decl String:Description[256];
						KvGetString(hConfig, "Description", Description, sizeof(Description));
						
						if (!StrEqual(Description, ""))
						{
							CPrintToChat(param1, "%s %s", JTAG_COLORED, Description);
						}
						else
						{
							CPrintToChat(param1, "%s %t", JTAG_COLORED, "no description available");
						}
					}
				} while (KvGotoNextKey(hConfig));
			}
			CurrentLRList(param1);
			CloseHandle(hConfig);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public Action:RemoveLR(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", JTAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!IsWarden(client))
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "not warden");
		return Plugin_Handled;
	}
	
	g_bIsLRInUse = false;
	g_IsQueuedFreeday[client] = false;
	g_IsFreeday[client] = false;
	CPrintToChat(Warden, "%s %t", JTAG_COLORED, "warden removed lr");
	Jail_Log("Warden %N has cleared all last requests currently queued.", client);

	return Plugin_Handled;
}

WardenSet(client)
{
	Warden = client;
	g_HasBeenWarden[client]++;
	
	switch (cv_WardenVoice)
	{
	case 1: SetClientListeningFlags(client, VOICE_NORMAL);
	case 2: CPrintToChatAll("%s %t", JTAG_COLORED, "warden voice muted", Warden);
	}
	
	if (cv_WardenForceSoldier)
	{
		new Health = GetClientHealth(client);
		TF2_SetPlayerClass(client, TFClass_Soldier);
		TF2_RegeneratePlayer(client);
		new Health2 = GetClientHealth(client);
		if (Health < Health2)
		{
			SetEntityHealth(client, Health);
		}
	}

	if (cv_WardenModel)
	{
		decl String:s[PLATFORM_MAX_PATH];
		Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
		SetModel(client, s);
	}
	
	if (cv_WardenStabProtection == 1)
	{
		AddAttribute(client, "backstab shield", 1.0);
	}
	
	decl String:sWarden[255];
	Format(sWarden, sizeof(sWarden), "%t", "warden current node", Warden);
	SetTextNode(TextNodes[2], sWarden, eaTNPs[2][eCoord_X], eaTNPs[2][eCoord_Y], eaTNPs[2][eHoldTime], eaTNPs[2][eRed], eaTNPs[2][eGreen], eaTNPs[2][eBlue], eaTNPs[2][eAlpha], eaTNPs[2][eEffect], eaTNPs[2][efxTime], eaTNPs[2][eFadeIn], eaTNPs[2][eFadeOut]);
	ClearTimer(hTimer_WardenLock);
	
	ResetVotes();
	WardenMenu(client);
	Forward_OnWardenCreation(client);
	
	CPrintToChatAll("%s %t", JTAG_COLORED, "warden new", client);
	CPrintToChat(client, "%s %t", JTAG_COLORED, "warden message");
}

WardenUnset(client)
{
	if (Warden != -1)
	{
		Warden = -1;
		if (cv_WardenModel)
		{
			RemoveModel(client);
		}
	}
	
	if (g_bActiveRound)
	{
		if (cv_BlueMute == 1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
				{
					UnmutePlayer(i);
				}
			}
		}
		
		if (cv_WardenTimer != 0 && cv_WardenTimer != 0.0)
		{
			new Float:timer = float(cv_WardenTimer);
			hTimer_WardenLock = CreateTimer(timer, DisableWarden, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	RemoveAttribute(client, "backstab shield");
	Forward_OnWardenRemoved(client);
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !g_HasModel[client])
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
		if (cv_WardenWearables)
		{
			RemoveValveHat(client, true);
		}
		g_HasModel[client] = true;
	}
}

public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_HasModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		RemoveValveHat(client);
		g_HasModel[client] = false;
	}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
LastRequestStart(client, sender = 0, bool:Timer = true)
{
	if (IsVoteInProgress()) return;

	new Handle:hMenu = CreateMenu(MenuHandle_LR);
	SetMenuTitle(hMenu, "Last Request Menu");
	ParseLastRequests(client, hMenu);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
	
	if (IsWarden(sender))
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "warden granted lr", sender);
	}
	else if (!sender)
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "console granted lr");
	}
	else
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "admin granted lr", sender);
	}
	
	g_bIsLRInUse = true;
	
	if (!Timer) RoundTimer_Stop();
}

public MenuHandle_LR(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			new String:choice[255];
			GetMenuItem(hMenu, param2, choice, sizeof(choice));
			
			new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
			FileToKeyValues(hConfig, LRConfig_File);

			if (!KvGotoFirstSubKey(hConfig))
			{
				Jail_Log("Last requests menu seems to be empty, please verify it's integrity.");
				CPrintToChatAll("%s %t", JTAG_COLORED, "last request config invalid");
				return;
			}
			
			if (cv_RemoveFreedayOnLR)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (g_IsFreeday[i])
					{
						RemoveFreeday(i);
					}
				}
				CPrintToChatAll("%s %t", JTAG_COLORED, "last request freedays removed");
			}
			
			new String:buffer[255];
			do
			{
				KvGetSectionName(hConfig, buffer, sizeof(buffer));
				if (StrEqual(buffer, choice))
				{
					decl String:QueueAnnounce[255], String:ClientName[MAX_NAME_LENGTH], String:Active[255];
					
					new String:Handler[128];
					KvGetString(hConfig, "Handler", Handler, sizeof(Handler));
					
					if (StrEqual(Handler, "LR_Custom"))
					{
						if (KvGetString(hConfig, "Queue_Announce", QueueAnnounce, sizeof(QueueAnnounce)))
						{
							GetClientName(param1, ClientName, sizeof(ClientName));
							ReplaceString(QueueAnnounce, sizeof(QueueAnnounce), "%M", ClientName, true);
							Format(QueueAnnounce, sizeof(QueueAnnounce), "%s %s", JTAG_COLORED, QueueAnnounce);
							CPrintToChatAll(QueueAnnounce);
						}
						
						CPrintToChat(param1, "%s %t", JTAG_COLORED, "custom last request message");
						CustomClient = param1;
						
						return;
					}
					
					new bool:ActiveRound = false;
					if (KvJumpToKey(hConfig, "Parameters"))
					{
						if (KvGetNum(hConfig, "ActiveRound", 0) == 1)
						{
							ActiveRound = true;
						}
						KvGoBack(hConfig);
					}
					
					if (ActiveRound)
					{
						if (g_bActiveRound)
						{
							CPrintToChat(param1, "%s %t", JTAG_COLORED, "lr cannot pick active round");
							return;
						}
						
						Call_StartForward(sFW_OnLastRequestExecute);
						Call_PushString(Handler);
						Call_Finish();
						
						if (KvGetString(hConfig, "Activated", Active, sizeof(Active)))
						{
							GetClientName(param1, ClientName, sizeof(ClientName));
							ReplaceString(Active, sizeof(Active), "%M", ClientName, true);
							Format(Active, sizeof(Active), "%s %s", JTAG_COLORED, Active);
							CPrintToChatAll(Active);
						}
						
						new String:ServerCommands[255];
						if (KvGetString(hConfig, "Execute_Cmd", ServerCommands, sizeof(ServerCommands)))
						{
							if (!StrEqual(ServerCommands, ""))
							{							
								new Handle:dp;
								CreateDataTimer(0.5, ExecuteServerCommand, dp, TIMER_FLAG_NO_MAPCHANGE);
								WritePackString(dp, ServerCommands);
							}
						}
						
						if (KvJumpToKey(hConfig, "Parameters"))
						{
							switch (KvGetNum(hConfig, "IsFreedayType", 0))
							{
							case 1:
								{
									GiveFreeday(param1);
								}
							case 2:
								{
									FreedayforClientsMenu(param1, true, true);
								}
							case 3:
								{
									FreedayForAll(false);
								}
							}
							
							if (KvGetNum(hConfig, "IsSuicide", 0) == 1)
							{
								ForcePlayerSuicide(param1);
							}
							
							if (KvGetNum(hConfig, "OpenCells", 0) == 1)
							{
								DoorHandler(OPEN);
							}
							
							if (KvGetNum(hConfig, "VoidFreekills", 0) == 1)
							{
								g_VoidFreekills = true;
							}
							
							if (KvGetNum(hConfig, "TimerStatus", 1) == 0)
							{
								RoundTimer_Stop();
							}
							
							if (KvGetNum(hConfig, "LockWarden", 0) == 1)
							{
								g_bLockWardenLR = true;
							}
							
							if (KvGetNum(hConfig, "EnableCriticals", 0) == 0)
							{
								g_bDisableCriticals = true;
							}
							
							if (KvJumpToKey(hConfig, "KillWeapons"))
							{
								for (new i = 1; i < MaxClients; i++)
								{
									if (IsValidClient(i) && IsPlayerAlive(i))
									{
										switch (GetClientTeam(i))
										{
										case TFTeam_Red:
											{
												if (KvGetNum(hConfig, "Red", 0) == 1)
												{
													StripToMelee(i);
												}
											}
										case TFTeam_Blue:
											{
												if (KvGetNum(hConfig, "Blue", 0) == 1)
												{
													StripToMelee(i);
												}
											}
										}
										
										if (KvGetNum(hConfig, "Warden", 0) == 1 && IsWarden(i))
										{
											StripToMelee(i);
										}
									}
								}
								KvGoBack(hConfig);
							}
							
							if (KvJumpToKey(hConfig, "FriendlyFire"))
							{
								if (KvGetNum(hConfig, "Status", 0) == 1)
								{
									new Float:TimeFloat = KvGetFloat(hConfig, "Timer", 1.0);
									if (TimeFloat >= 0.1)
									{
										hTimer_FriendlyFireEnable = CreateTimer(TimeFloat, EnableFFTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
									}
									else
									{
										Jail_Log("[ERROR] Timer is set to a value below 0.1! Timer could not be created.");
									}
								}
								KvGoBack(hConfig);
							}
							KvGoBack(hConfig);
						}
						LR_Current = StringToInt(choice);
					}
					else
					{
						new bool:FreedayCheck = true;
						if (KvJumpToKey(hConfig, "Parameters"))
						{
							switch (KvGetNum(hConfig, "IsFreedayType", 0))
							{
							case 1:
								{
									g_IsQueuedFreeday[param1] = true;
									FreedayCheck = false;
								}
							case 2:
								{
									FreedayforClientsMenu(param1, false, true);
									FreedayCheck = false;
								}
							case 3:
								{
									FreedayForAll(true);
								}
							}
							KvGoBack(hConfig);
						}
						
						if (KvGetString(hConfig, "Queue_Announce", QueueAnnounce, sizeof(QueueAnnounce)))
						{
							GetClientName(param1, ClientName, sizeof(ClientName));
							ReplaceString(QueueAnnounce, sizeof(QueueAnnounce), "%M", ClientName, true);
							Format(QueueAnnounce, sizeof(QueueAnnounce), "%s %s", JTAG_COLORED, QueueAnnounce);
							CPrintToChatAll(QueueAnnounce);
						}
						
						if (FreedayCheck)
						{
							LR_Pending = StringToInt(choice);
						}
					}
					break;
				}
			} while (KvGotoNextKey(hConfig));

			CloseHandle(hConfig);
		}
	case MenuAction_Cancel:
		{
			if (g_bActiveRound)
			{
				CPrintToChatAll("%s %t", JTAG_COLORED, "last request closed");
			}
			g_bIsLRInUse = false;
		}
	case MenuAction_End:
		{
			CloseHandle(hMenu);
			g_bIsLRInUse = false;
		}
	}
}

FreedayforClientsMenu(client, bool:active = false, bool:rep = false)
{
	if (IsVoteInProgress()) return;
	
	new Handle:hMenu;
	switch (active)
	{
		case false: hMenu = CreateMenu(MenuHandle_FreedayForClients);
		case true: hMenu = CreateMenu(MenuHandle_FreedayForClientsActive);
	}

	SetMenuTitle(hMenu, "Choose a Player");
	SetMenuExitBackButton(hMenu, false);
	AddTargetsToMenu2(hMenu, 0, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	if (rep) CPrintToChatAll("%s %t", JTAG_COLORED, "lr freeday picking clients", client);
}

public MenuHandle_FreedayForClientsActive(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(hMenu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));
			
			if (IsValidClient(param1))
			{
				if (!IsValidClient(target))
				{
					CPrintToChat(param1, "%s %t", JTAG_COLORED, "Player no longer available");
					FreedayforClientsMenu(param1, true);
				}
				
				if (g_IsFreeday[target])
				{
					CPrintToChat(param1, "%s %t", JTAG_COLORED, "freeday currently queued", target);
					FreedayforClientsMenu(param1, true);
				}
				else
				{
					if (FreedayLimit < cv_FreedayLimit)
					{
						GiveFreeday(param1);
						FreedayLimit++;
						CPrintToChatAll("%s %t", JTAG_COLORED, "lr freeday picked clients", param1, target);
						FreedayforClientsMenu(param1, true);
					}
					else
					{
						CPrintToChatAll("%s %t", JTAG_COLORED, "lr freeday picked clients maxed", param1);
					}
				}
			}
		}
	case MenuAction_Cancel:
		{
			LastRequestStart(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public MenuHandle_FreedayForClients(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(hMenu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));
			
			if (IsValidClient(param1))
			{
				if (!IsValidClient(target))
				{
					CPrintToChat(param1, "%s %t", JTAG_COLORED, "Player no longer available");
					FreedayforClientsMenu(param1);
				}
				
				if (g_IsQueuedFreeday[target])
				{
					CPrintToChat(param1, "%s %t", JTAG_COLORED, "freeday currently queued", target);
					FreedayforClientsMenu(param1);
				}
				else
				{
					if (FreedayLimit < cv_FreedayLimit)
					{
						g_IsQueuedFreeday[target] = true;
						FreedayLimit++;
						CPrintToChatAll("%s %t", JTAG_COLORED, "lr freeday picked clients", param1, target);
						FreedayforClientsMenu(param1);
					}
					else
					{
						CPrintToChatAll("%s %t", JTAG_COLORED, "lr freeday picked clients maxed", param1);
					}
				}
			}
		}
	case MenuAction_Cancel:
		{
			LastRequestStart(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

/* Stock Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
GiveFreeday(client)
{
	CPrintToChat(client, "%s %t", JTAG_COLORED, "lr freeday message");
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
	if (cv_FreedayTeleports && g_bFreedayTeleportSet) TeleportEntity(client, free_pos, NULL_VECTOR, NULL_VECTOR);
	
	ClearTimer(hTimer_ParticleTimers[client]);
	hTimer_ParticleTimers[client] = CreateTimer(2.0, Timer_FreedayParticle, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_IsQueuedFreeday[client] = false;
	g_IsFreeday[client] = true;
	Jail_Log("%N has been given a Freeday.", client);
}

FreedayForAll(bool:active = false)
{
	if (active)
	{
		DoorHandler(OPEN);
	}
	else
	{
		
	}
}

public Action:Timer_FreedayParticle(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateParticle(Particle_Freeday, 3.0, client, ATTACH_NORMAL);
	}
	else
	{
		ClearTimer(hTimer_ParticleTimers[client]);
	}
}

RemoveFreeday(client)
{
	CPrintToChatAll("%s %t", JTAG_COLORED, "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	g_IsFreeday[client] = false;
	ClearTimer(hTimer_ParticleTimers[client]);
	Jail_Log("%N is no longer a Freeday.", client);
}

MarkRebel(client)
{
	g_IsRebel[client] = true;
	
	ClearTimer(hTimer_ParticleTimers[client]);
	hTimer_ParticleTimers[client] = CreateTimer(2.0, Timer_RebelParticle, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CPrintToChatAll("%s %t", JTAG_COLORED, "prisoner has rebelled", client);
	if (cv_RebelsTime >= 1.0)
	{
		new time = RoundFloat(cv_RebelsTime);
		CPrintToChat(client, "%s %t", JTAG_COLORED, "rebel timer start", time);
		hTimer_RebelTimers[client] = CreateTimer(cv_RebelsTime, RemoveRebel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	Jail_Log("%N has been marked as a Rebeller.", client);
}

public Action:Timer_RebelParticle(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateParticle(Particle_Rebellion, 3.0, client, ATTACH_NORMAL);
	}
	else
	{
		ClearTimer(hTimer_ParticleTimers[client]);
	}
}

MarkFreekiller(client)
{
	g_IsFreekiller[client] = true;
	
	ClearTimer(hTimer_ParticleTimers[client]);
	hTimer_ParticleTimers[client] = CreateTimer(2.0, Timer_FreekillerParticle, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	TF2_RemoveAllWeapons(client);
	ServerCommand("sm_beacon #%d", GetClientUserId(client));
	EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
	
	if (cv_FreekillersWave >= 1.0)
	{
		new time = RoundFloat(cv_FreekillersWave);
		CPrintToChatAll("%s %t", JTAG_COLORED, "freekiller timer start", client, time);

		decl String:sAuth[24];
		if(!GetClientAuthString(client, sAuth, sizeof(sAuth[])))
		{
			CReplyToCommand(client, "%s Client failed to auth, delayed ban not possible.", JTAG);
			return;
		}
		else
		{
			new Handle:pack;
			hTimer_FreekillingData = CreateDataTimer(cv_FreekillersWave, BanClientTimerFreekiller, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(pack, client);
			WritePackCell(pack, GetClientUserId(client));
			WritePackString(pack, sAuth);
		}
	}
	Jail_Log("%N has been marked as a Freekiller.", client);
}

public Action:Timer_FreekillerParticle(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateParticle(Particle_Freekiller, 3.0, client, ATTACH_NORMAL);
	}
	else
	{
		ClearTimer(hTimer_ParticleTimers[client]);
	}
}

bool:AlreadyMuted(client)
{
	switch (EnumCommsList)
	{
	case Basecomms:
		{
			if (!BaseComm_IsClientMuted(client)) return false;
			return true;
		}
	case Sourcecomms:
		{
			if (SourceComms_GetClientMuteType(client) == bNot) return false;
			return true;
		}
	}
	return false;
}

ConvarsSet(bool:Status = false)
{
	if (Status)
	{
		SetConVarInt(FindConVar("mp_stalemate_enable"),0);
		SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		SetConVarInt(FindConVar("mp_autoteambalance"), 0);
		SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
		SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
		SetConVarInt(FindConVar("phys_pushscale"), 1000);
	}
	else
	{
		SetConVarInt(FindConVar("mp_stalemate_enable"),1);
		SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);
		SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
		SetConVarInt(FindConVar("mp_scrambleteams_auto"), 1);
	}
}

bool:IsWarden(client)
{
	if (client == Warden) return true;
	return false;
}

MutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && !g_IsMuted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		g_IsMuted[client] = true;
		CPrintToChat(client, "%s %t", JTAG_COLORED, "muted player");
	}
}

UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && g_IsMuted[client])
	{
		UnmuteClient(client);
		g_IsMuted[client] = false;
		CPrintToChat(client, "%s %t", JTAG_COLORED, "unmuted player");
	}
}

ParseLastRequests(client, Handle:hMenu)
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
	
	if (FileToKeyValues(hConfig, LRConfig_File))
	{
		if (KvGotoFirstSubKey(hConfig))
		{
			decl String:LR_ID[64];
			decl String:LR_NAME[255];
			do
			{
				KvGetSectionName(hConfig, LR_ID, sizeof(LR_ID));    
				KvGetString(hConfig, "Name", LR_NAME, sizeof(LR_NAME));
				
				if (KvJumpToKey(hConfig, "Parameters"))
				{
					new bool:VIPCheck = false;
					if (KvGetNum(hConfig, "IsVIPOnly", 0) == 1)
					{
						VIPCheck = true;
						Format(LR_NAME, sizeof(LR_NAME), "%s [VIP Only]", LR_NAME);
					}
					
					switch (KvGetNum(hConfig, "Disabled", 0))
					{
					case 0:
					{
						if (VIPCheck)
						{
							if (IsVIP(client))
							{
								AddMenuItem(hMenu, LR_ID, LR_NAME);
							}
							else
							{
								AddMenuItem(hMenu, LR_ID, LR_NAME, ITEMDRAW_DISABLED);
							}
						}
						else
						{
							AddMenuItem(hMenu, LR_ID, LR_NAME);
						}
					}
					case 1:	AddMenuItem(hMenu, LR_ID, LR_NAME, ITEMDRAW_DISABLED);
					}
					KvGoBack(hConfig);
				}
			} while (KvGotoNextKey(hConfig));
			g_bLRConfigActive = true;
		}
	}
	else
	{
		g_bLRConfigActive = false;
	}
	CloseHandle(hConfig);
}

ParseConfigs()
{
	ParseMapConfig();
	ParseNodeConfig();
}

ParseMapConfig()
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_MapConfig");
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/tf2jail/mapconfig.cfg");
	
	decl String:g_Mapname[128];
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));

	Jail_Log("Loading last request configuration entry - %s...", g_Mapname);

	if (FileToKeyValues(hConfig, sBuffer))
	{
		if (KvJumpToKey(hConfig, g_Mapname))
		{
			decl String:CellNames[32], String:CellsButton[32], String:FFButton[32];
			
			KvGetString(hConfig, "CellNames", CellNames, sizeof(CellNames), "");
			if (!StrEqual(CellNames, ""))
			{
				new iCelldoors = Entity_FindByName(CellNames, "func_door");
				if (Entity_IsValid(iCelldoors))
				{
					GCellNames = CellNames;
					g_IsMapCompatible = true;
				}
				else
				{
					g_IsMapCompatible = false;
				}
			}
			else
			{
				g_IsMapCompatible = false;
			}
			
			KvGetString(hConfig, "CellsButton", CellsButton, sizeof(CellsButton), "");
			if (!StrEqual(CellsButton, ""))
			{
				new iCellOpener = Entity_FindByName(CellsButton, "func_button");
				if (Entity_IsValid(iCellOpener))
				{
					GCellOpener = CellsButton;
				}
			}
			
			KvGetString(hConfig, "FFButton", FFButton, sizeof(FFButton), "");
			if (!StrEqual(FFButton, ""))
			{
				new iFFButton = Entity_FindByName(FFButton, "func_button");
				if (Entity_IsValid(iFFButton))
				{
					GCellOpener = FFButton;
				}
			}
			
			if (KvJumpToKey(hConfig, "Freeday"))
			{
				if (KvJumpToKey(hConfig, "Teleport"))
				{
					g_bFreedayTeleportSet = (KvGetNum(hConfig, "Status", 1) == 1);
					
					if (g_bFreedayTeleportSet)
					{
						free_pos[0] = KvGetFloat(hConfig, "Coordinate_X", 0.0);
						free_pos[1] = KvGetFloat(hConfig, "Coordinate_Y", 0.0);
						free_pos[2] = KvGetFloat(hConfig, "Coordinate_Z", 0.0);
						
						Jail_Log("Freeday Teleportation coordinates set for the map '%s' - X: %d, Y: %d, Z: %d", g_Mapname, free_pos[0], free_pos[1], free_pos[2]);
					}
					
					KvGoBack(hConfig);
				}
				else
				{
					g_bFreedayTeleportSet = false;
					Jail_Log("Could not find subset key for 'Freeday' - 'Teleport', disabling functionality for Freeday Teleportation.");
				}
				KvGoBack(hConfig);
			}
			else
			{
				g_bFreedayTeleportSet = false;
				Jail_Log("Could not find subset 'Freeday', disabling functionality for Freedays via Map.");
			}
		}
		else
		{
			g_IsMapCompatible = false;
			g_bFreedayTeleportSet = false;
			Jail_Log("Map '%s' is missing from configuration file, please verify integrity of your installation.", g_Mapname);
		}
	}
	else
	{
		g_IsMapCompatible = false;
		g_bFreedayTeleportSet = false;
		Jail_Log("Configuration file is invalid or not found, please verify integrity of your installation.");
	}
	
	Jail_Log("Map configuration for '%s' has been parsed and loaded.", g_Mapname);
	CloseHandle(hConfig);
}

ParseNodeConfig()
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_Nodes");
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/tf2jail/textnodes.cfg");

	if (FileToKeyValues(hConfig, sBuffer))
	{
		if (KvGotoFirstSubKey(hConfig, false))
		{
			new count = 0;
			do
			{
				eaTNPs[count][eCoord_X] = KvGetFloat(hConfig, "Coord_X", -1.0);
				eaTNPs[count][eCoord_Y] = KvGetFloat(hConfig, "Coord_Y", -1.0);
				eaTNPs[count][eHoldTime] = KvGetFloat(hConfig, "HoldTime", 5.0);
				eaTNPs[count][eRed] = KvGetNum(hConfig, "Red", 255);
				eaTNPs[count][eGreen] = KvGetNum(hConfig, "Green", 255);
				eaTNPs[count][eBlue] = KvGetNum(hConfig, "Blue", 255);
				eaTNPs[count][eAlpha] = KvGetNum(hConfig, "Alpha", 255);
				eaTNPs[count][eEffect] = KvGetNum(hConfig, "Effect", 0);
				eaTNPs[count][efxTime] = KvGetFloat(hConfig, "fxTime", 6.0);
				eaTNPs[count][eFadeIn] = KvGetFloat(hConfig, "FadeIn", 0.1);
				eaTNPs[count][eFadeOut] = KvGetFloat(hConfig, "FadeOut", 0.2);
				
				Jail_Debug("Setting eaTNPS[%i] to %f, %f, %f, %i, %i, %i, %i, %i, %f, %f, %f", count, eaTNPs[count][eCoord_X], eaTNPs[count][eCoord_Y], eaTNPs[count][eHoldTime], eaTNPs[count][eRed], eaTNPs[count][eGreen], eaTNPs[count][eBlue], eaTNPs[count][eAlpha], eaTNPs[count][eEffect], eaTNPs[count][efxTime], eaTNPs[count][eFadeIn], eaTNPs[count][eFadeOut]);
				count++;
			} while (KvGotoNextKey(hConfig, false));
		}
	}
	else
	{
		Jail_Log("Couldn't parse text node configuration file, please verify it's integrity.");
	}
	
	CloseHandle(hConfig);
}

EmptyWeaponSlots(client)
{
	switch(TF2_GetPlayerClass(client))
	{
	case TFClass_DemoMan, TFClass_Engineer, TFClass_Medic, TFClass_Scout, TFClass_Soldier, TFClass_Spy:
		{
			SetClip(client, 0, 0);
		}
	}
	
	SetClip(client, 1, 0);
	SetAmmo(client, 0, 0);
	SetAmmo(client, 1, 0);
	
	decl String:szClassName[64];
	GetEntityClassname(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), szClassName, sizeof(szClassName));
	if (StrEqual(szClassName, "tf_weapon_compound_bow"))
	{
		SetClip(client, 0, 0);
	}

	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 5);
	CPrintToChat(client, "%s %t", JTAG_COLORED, "stripped weapons and ammo");
}

Jail_Log(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	switch (cv_Logging)
	{
	case 1: LogMessage("%s", buffer);
	case 2:
		{
			decl String:Date[20];
			FormatTime(Date, sizeof(Date), "%Y-%m-%d", GetTime());
			
			decl String:path[PLATFORM_MAX_PATH], String:path_final[PLATFORM_MAX_PATH];
			Format(path, sizeof(path), "logs/TF2Jail_%s.log", Date);
			BuildPath(Path_SM, path_final, sizeof(path_final), path);
			LogToFileEx(path_final, "%s", buffer);
		}
	}
	
	if (cv_ConsoleSpew)
	{
		PrintToConsoleAll("%s %s", JTAG, buffer);
	}
}

stock Jail_Debug(const String:format[], any:...)	//Used for debugging purposes! Might/might not exist in the plugin.
{
	decl String:Date[20], String:buffer[256];
	FormatTime(Date, sizeof(Date), "%Y-%m-%d", GetTime());
	VFormat(buffer, sizeof(buffer), format, 2);
			
	decl String:path[PLATFORM_MAX_PATH], String:path_final[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "logs/TF2Jail_Debug_%s.log", Date);
	BuildPath(Path_SM, path_final, sizeof(path_final), path);
	LogToFileEx(path_final, "%s", buffer);
}

DoorHandler(eDoorsMode:status)
{
	if (!StrEqual(GCellNames, ""))
	{
		for (new i = 0; i < sizeof(DoorList); i++)
		{
			new String:buffer[60], ent = -1;
			while((ent = FindEntityByClassnameSafe(ent, DoorList[i])) != -1)
			{
				GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if (StrEqual(buffer, GCellNames, false))
				{
					switch (status)
					{
					case OPEN: AcceptEntityInput(ent, "Open");
					case CLOSE: AcceptEntityInput(ent, "Close");
					case LOCK: AcceptEntityInput(ent, "Lock");
					case UNLOCK: AcceptEntityInput(ent, "Unlock");
					}
				}
			}
		}
		switch (status)
		{
		case OPEN:
			{
				if (g_CellsOpened)
				{
					CPrintToChatAll("%s %t", JTAG_COLORED, "doors manual open");
					g_CellsOpened = false;
				}
				else
				{
					CPrintToChatAll("%s %t", JTAG_COLORED, "doors opened");
				}
			}
		case CLOSE: CPrintToChatAll("%s %t", JTAG_COLORED, "doors closed");
		case LOCK: CPrintToChatAll("%s %t", JTAG_COLORED, "doors locked");
		case UNLOCK: CPrintToChatAll("%s %t", JTAG_COLORED, "doors unlocked");
		}
	}
}

UnmuteClient(client)
{
	static Handle:cvDeadTalk = INVALID_HANDLE;

	if (cvDeadTalk == INVALID_HANDLE)
	{
		cvDeadTalk = FindConVar("sm_deadtalk");
	}

	if (cvDeadTalk == INVALID_HANDLE)
	{
		SetClientListeningFlags(client, VOICE_NORMAL);
	}
	else
	{
		if (GetConVarInt(cvDeadTalk) == 1 && !IsPlayerAlive(client))
		{
			SetClientListeningFlags(client, VOICE_LISTENALL);
		}
		else if (GetConVarInt(cvDeadTalk) == 2 && !IsPlayerAlive(client))
		{
			SetClientListeningFlags(client, VOICE_TEAM);
		}
		else
		{
			SetClientListeningFlags(client, VOICE_NORMAL);
		}
	}
}

FindRandomWarden()
{
	if (cv_WardenAuto)
	{
		new client = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE|CLIENTFILTER_NOBOTS);
		if (IsValidClient(client))
		{
			if (cv_PrefStatus)
			{
				if (g_bRolePreference_Warden[client])
				{
					WardenSet(client);
					Jail_Log("%N has been set to warden automatically at the start of this arena round.", client);
				}
				else
				{
					Jail_Log("%N has preferred settings set to Prisoner only.", client);
					FindRandomWarden();
				}
			}
			else
			{
				WardenSet(client);
				Jail_Log("%N has been set to warden automatically at the start of this arena round.", client);
			}
		}
	}
}

public TF2Jail_Preferences(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
	case CookieMenuAction_SelectOption:
		{
			PreferenceMenu(client);
		}
	}
}

PreferenceMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandle_Preferences);
	SetMenuTitle(hMenu, "TF2Jail Preferences");
	decl String:sValue[64];
	Format(sValue, sizeof(sValue), "%s", g_bRolePreference_Blue[client] ? "Blue Preference [ON]" : "Blue Preference [OFF]");
	AddMenuItem(hMenu, "Pref_Blue", sValue, cv_PrefBlue ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(sValue, sizeof(sValue), "%s", g_bRolePreference_Warden[client] ? "Warden Preference [ON]" : "Warden Preference [OFF]");
	AddMenuItem(hMenu, "Pref_Warden", sValue, cv_PrefWarden ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	DisplayMenu(hMenu, client, 0);
}

public MenuHandle_Preferences(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[64];
			GetMenuItem(hMenu, param2, info, sizeof(info));
						
			if (StrEqual(info, "Pref_Blue"))
			{
				if (cv_PrefBlue)
				{
					if (!g_bRolePreference_Blue[param1])
					{
						SetClientCookie(param1, g_hRolePref_Blue, "1");
						g_bRolePreference_Blue[param1] = true;
						CPrintToChat(param1, "%s %t", JTAG_COLORED, "preference blue on");
					}
					else
					{
						SetClientCookie(param1, g_hRolePref_Blue, "0");
						g_bRolePreference_Blue[param1] = false;
						CPrintToChat(param1, "%s %t", JTAG_COLORED, "preference blue off");
					}
				}
			}
			else if (StrEqual(info, "Pref_Warden"))
			{
				if (cv_PrefWarden)
				{
					if (!g_bRolePreference_Warden[param1])
					{
						SetClientCookie(param1, g_hRolePref_Warden, "1");
						g_bRolePreference_Warden[param1] = true;
						CPrintToChat(param1, "%s %t", JTAG_COLORED, "preference warden on");
					}
					else
					{
						SetClientCookie(param1, g_hRolePref_Warden, "0");
						g_bRolePreference_Warden[param1] = false;
						CPrintToChat(param1, "%s %t", JTAG_COLORED, "preference warden off");
					}
				}
			}
			PreferenceMenu(param1);
		}
		case MenuAction_End: CloseHandle(hMenu);
	}
}

StartAdvertisement()
{
	hTimer_Advertisement = CreateTimer(120.0, TimerAdvertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

IsVIP(client)
{
	return CheckCommandAccess(client, "TF2Jail_VIP", ADMFLAG_RESERVATION);
}

SetTextNode(Handle:node, const String:sText[], Float:X = -1.0, Float:Y = -1.0, Float:HoldTime = 5.0, Red = 255, Green = 255, Blue = 255, Alpha = 255, Effect = 0, Float:fXTime = 6.0, Float:FadeIn = 0.1, Float:FadeOut = 0.2)
{
	SetHudTextParams(X, Y, HoldTime, Red, Green, Blue, Alpha, Effect, fXTime, FadeIn, FadeOut);
	Jail_Debug("SetTextNode - %s, %f, %f, %f, %i, %i, %i, %i, %i, %f, %f, %f", sText, X, Y, HoldTime, Red, Green, Blue, Alpha, Effect, fXTime, FadeIn, FadeOut);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			ShowSyncHudText(i, node, sText);
		}
	}
}

bool:IsValidClient(iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return false;
	return true;
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

AddAttribute(client, String:attribute[], Float:value)
{
	if (attributes && IsValidClient(client))
	{
		TF2Attrib_SetByName(client, attribute, value);
	}
}

RemoveAttribute(client, String:attribute[])
{
	if (attributes && IsValidClient(client))
	{
		TF2Attrib_RemoveByName(client, attribute);
	}
}

FindEntityByClassnameSafe(iStart, String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

RemoveValveHat(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
	edict = MaxClients+1;
	while ((edict = FindEntityByClassnameSafe(edict, "tf_powerup_bottle")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFPowerupBottle") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}

StripToMelee(client)
{
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
}

Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		if (attach != NO_ATTACH)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
			if (attach == ATTACH_HEAD)
			{
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		if (time != 0.0)
		{
			CreateTimer(time, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		LogError("Could not create info_particle_system");
	}
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, any:Edict)
{	
	if (IsValidEdict(Edict))
	{
		RemoveEdict(Edict);
	}
}

SetClip(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}

SetAmmo(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}

PrintToConsoleAll(const String:format[], any:...)
{
	new String:sValue[256];
	VFormat(sValue, 256, format, 2);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			PrintToConsole(i, sValue);
		}
	}
}

TF2_SwitchtoSlot(client, slot)
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

/* Timers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:UnmuteReds(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			UnmutePlayer(i);
		}
	}
	CPrintToChatAll("%s %t", JTAG_COLORED, "red team unmuted");
	Jail_Log("All players have been unmuted.");
}

public Action:Open_Doors(Handle:hTimer)
{
	hTimer_OpenCells = INVALID_HANDLE;
	if (g_CellsOpened)
	{
		DoorHandler(OPEN);
		new time = RoundFloat(cv_DoorOpenTimer);
		CPrintToChatAll("%s %t", JTAG_COLORED, "cell doors open end", time);
		g_CellsOpened = false;
		Jail_Log("Doors have been automatically opened by a timer.");
	}
}

public Action:TimerAdvertisement (Handle:hTimer)
{
	CPrintToChatAll("%s %t", JTAG_COLORED, "plugin advertisement");
	return Plugin_Continue;
}

public Action:Timer_Welcome(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (cv_Enabled && IsValidClient(client))
	{
		CPrintToChat(client, "%s %t", JTAG_COLORED, "welcome message");
	}
}

public Action:BanClientTimerFreekiller(Handle:hTimer, Handle:hPack)
{
	hTimer_FreekillingData = INVALID_HANDLE;
	
	new iPosition;
	if ((iPosition = FindValueInArray(g_hArray_Pending, hTimer) != -1))
	{
		RemoveFromArray(g_hArray_Pending, iPosition);
	}

	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new userid = ReadPackCell(hPack);
	new String:sAuth[24];
	ReadPackString(hPack, sAuth, sizeof(sAuth));
	
	if (IsValidClient(client))
	{
		switch (cv_FreekillersAction)
		{
		case 0:
			{
				g_IsFreekiller[client] = false;
				TF2_RegeneratePlayer(client);
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
			}
		case 1:
			{
				ForcePlayerSuicide(client);
				g_IsFreekiller[client] = false;
			}
		case 2:
			{
				if (IsValidClient(userid))
				{
					#if defined _sourcebans_included
					
					SBBanPlayer(0, userid, 60, "Client has been marked for Freekilling.");
					Jail_Log("Client %N has been banned via Sourcebans for being marked as a Freekiller.", userid);
					
					#elseif defined _sb_bans_included
					
					SB_SubmitBan(client, userid, "Client has been marked for Freekilling.");
					Jail_Log("Client %N has been banned via Sourcebans for being marked as a Freekiller.", userid);
					
					#else
					
					BanClient(userid, cv_FreekillersBantime, BANFLAG_AUTHID, "Client has been marked for Freekilling.", BanMsg, "freekillban", userid);
					Jail_Log("Client %N has been banned for being marked as a Freekiller.", userid);
					
					#endif
				}
				else
				{
					if (cv_FreekillersAction == 2)
					{
						GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
						BanIdentity(sAuth, cv_FreekillersBantimeDC, BANFLAG_AUTHID, BanMsgDC);
						Jail_Log("%N has been banned via identity.", BANFLAG_AUTHID);
					}
				}
			}
		}
	}
	else
	{
		if (cv_FreekillersAction == 2)
		{
			GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
			BanIdentity(sAuth, cv_FreekillersBantimeDC, BANFLAG_AUTHID, BanMsgDC);
			Jail_Log("%N has been banned via identity.", BANFLAG_AUTHID);
		}
	}
}

public Action:EnableFFTimer(Handle:hTimer)
{
	hTimer_FriendlyFireEnable = INVALID_HANDLE;
	SetConVarBool(JB_EngineConVars[0], true);
}

public Action:RemoveRebel(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	hTimer_RebelTimers[client] = INVALID_HANDLE;
	
	if (IsValidClient(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		CPrintToChat(client, "%s %t", JTAG_COLORED, "rebel timer end");
		ClearTimer(hTimer_ParticleTimers[client]);
		Jail_Log("%N is no longer a Rebeller.", client);
	}
}

public Action:DisableWarden(Handle:hTimer)
{
	hTimer_WardenLock = INVALID_HANDLE;
	if (g_bActiveRound)
	{
		CPrintToChatAll("%s %t", JTAG_COLORED, "warden locked timer");
		g_bIsWardenLocked = true;
	}
}
public Action:ExecuteServerCommand(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new String:buffer[128];
	ReadPackString(pack, buffer, sizeof(buffer));
	ServerCommand(buffer);
}

/* Next Frame Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public ManageWeapons(any:data)
{
	new client = GetClientOfUserId(data);
	if (GetClientTeam(client) == _:TFTeam_Red)
	{
		if (cv_Enabled && cv_RedMelee)
		{
			EmptyWeaponSlots(client);
		}
	}
}

/* Group Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public bool:WardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && IsWarden(i))
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
		if (IsValidClient(i) && Warden != -1 && !IsWarden(i))
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
		if (IsValidClient(i) && g_IsQueuedFreeday[i] || IsValidClient(i) && g_IsFreeday[i])
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
		if (IsValidClient(i) && !g_IsQueuedFreeday[i] || IsValidClient(i) && !g_IsFreeday[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

/* Native Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Native_ExistWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Warden)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");
	}
	
	if (Warden != -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Native_IsWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Warden)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (IsWarden(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Native_SetWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Warden)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (Warden != -1)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Warden is currently in use, cannot execute native function.");
	}
	else
	{
		if (cv_PrefStatus && g_bRolePreference_Warden[client])
		{
			ThrowNativeError(SP_ERROR_INDEX, "Client index %i has their preference set to prisoner only.", client);
		}

		WardenSet(client);
	}
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Warden)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (IsWarden(client))
	{
		WardenUnset(client);
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not Warden.", client);
	}
}

public Native_IsFreeday(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Last Request System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (g_IsQueuedFreeday[client] || g_IsFreeday[client])
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Native_GiveFreeday(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_LRSEnabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Last Request System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (g_IsFreeday[client])
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Freeday.", client);
	}
	else
	{
		if (g_IsQueuedFreeday[client])
		{
			g_IsQueuedFreeday[client] = false;
		}
		GiveFreeday(client);
	}
}

public Native_IsRebel(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Rebels)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Rebel System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (g_IsRebel[client])
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Native_MarkRebel(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Rebels)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Rebel System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (!g_IsRebel[client])
	{
		MarkRebel(client);
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Rebel.", client);
	}
}

public Native_IsFreekiller(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Freekillers)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Anti-Freekill System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (g_IsFreekiller[client])
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Native_MarkFreekill(Handle:plugin, numParams)
{
	if (!cv_Enabled || !cv_Freekillers)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Anti-Freekill System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (!g_IsFreekiller[client])
	{
		MarkFreekiller(client);
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already marked as a Freekiller.", client);
	}
}

public Native_StripToMelee(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (IsPlayerAlive(client))
	{
		RequestFrame(ManageWeapons, GetClientUserId(client));
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip ammo.", client);
	}
}

public Native_StripAllWeapons(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (IsPlayerAlive(client))
	{
		StripToMelee(client);
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip weapons.", client);
	}
}

public Native_LockWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin is disabled");
	}
	
	g_bAdminLockWarden = true;
	CPrintToChatAll("%s %t", JTAG_COLORED, "warden locked natives");
	Jail_Log("Natives has locked Warden.");
}

public Native_UnlockWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin is disabled");
	}
	
	g_bAdminLockWarden = false;
	CPrintToChatAll("%s %t", JTAG_COLORED, "warden unlocked natives");
	Jail_Log("Natives has unlocked Warden.");
}

public Native_Logging(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin is disabled");
	}
	
	decl String:buffer[1024], written;
	FormatNativeString(0, 1, 2, sizeof(buffer),  written, buffer);
	Jail_Log("%s", buffer);
}

public Native_IsLRRound(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin is disabled");
	}
	
	if (LR_Current != -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Forward_OnWardenCreation(client)
{
	Call_StartForward(sFW_WardenCreated);
	Call_PushCell(client);
	Call_Finish();
}

public Forward_OnWardenRemoved(client)
{
	Call_StartForward(sFW_WardenRemoved);
	Call_PushCell(client);
	Call_Finish();
}
/* Plugin End ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
