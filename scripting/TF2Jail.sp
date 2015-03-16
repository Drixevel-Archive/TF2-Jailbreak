/*
	**
	* =============================================================================
	* TF2 Jailbreak Plugin Set (TF2Jail)
	*
	* Created and developed by Keith Warren (Drixevel).
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

//Required Extensions
#tryinclude <sdkhooks>

//Non-Required Extensions
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>

//Non-Required Plugins
#undef REQUIRE_PLUGIN
#tryinclude <tf2-weapon-restrictions>
#tryinclude <tf2attributes>
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <clientprefs>
#tryinclude <voiceannounce_ex>

#define PLUGIN_NAME	"[TF2] Jailbreak"
#define PLUGIN_VERSION	"5.5.0"
#define PLUGIN_AUTHOR	"Keith Warren(Drixevel)"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT	"http://www.drixevel.com/"

//Version of Sourcemod the plugin checks for.
#define SOURCEMOD_REQUIRED	"1.6"

new Handle:hConVars[78] = {INVALID_HANDLE, ...};
new Handle:hTextNodes[4] = {INVALID_HANDLE, ...};
new Handle:hEngineConVars[3] = {INVALID_HANDLE, ...};

new Handle:sFW_WardenCreated, Handle:sFW_WardenRemoved, Handle:sFW_OnLastRequestExecute, Handle:sFW_OnFreedayGiven, Handle:sFW_OnFreedayRemoved, Handle:sFW_OnFreekillerGiven, Handle:sFW_OnFreekillerRemoved, Handle:sFW_OnRebelGiven, Handle:sFW_OnRebelRemoved;
new Handle:hRolePref_Blue, Handle:hRolePref_Warden, Handle:hLastRequestUses, Handle:hWardenSkinClasses, Handle:hWardenSkins;

new Handle:hParticle_Wardens[MAXPLAYERS + 1], Handle:hParticle_Freedays[MAXPLAYERS + 1], Handle:hParticle_Rebels[MAXPLAYERS + 1], Handle:hParticle_Freekillers[MAXPLAYERS + 1];

new Handle:hTimer_Advertisement, Handle:hTimer_FreekillingData, Handle:hTimer_OpenCells,
Handle:hTimer_FriendlyFireEnable, Handle:hTimer_WardenLock, Handle:hTimer_RoundTimer, Handle:hTimer_RebelTimers[MAXPLAYERS + 1];

new Handle:hWardenMenu, Handle:hListLRsMenu;

new bool:cv_Enabled , bool:cv_Advertise , bool:cv_Cvars , cv_Logging, bool:cv_Balance, Float:cv_BalanceRatio,
bool:cv_RedMelee, bool:cv_Warden, bool:cv_WardenAuto, bool:cv_WardenModels, bool:cv_WardenForceClass,
bool:cv_WardenFF, bool:cv_WardenCC, bool:cv_WardenRequest, cv_WardenLimit, bool:cv_DoorControl, Float:cv_DoorOpenTimer,
cv_RedMute, Float:cv_RedMuteTime, cv_BlueMute, bool:cv_DeadMute, bool:cv_MicCheck, bool:cv_MicCheckType, bool:cv_Rebels,
Float:cv_RebelsTime, cv_Criticals, cv_Criticalstype, bool:cv_WVotesStatus, Float:cv_WVotesNeeded, cv_WVotesMinPlayers, cv_WVotesPostAction,
cv_WVotesPassedLimit, bool:cv_Freekillers, Float:cv_FreekillersTime, cv_FreekillersKills, Float:cv_FreekillersWave, cv_FreekillersAction, String:cv_sBanMSG[255],
String:cv_sBanMSGDC[255], cv_FreekillersBantime, cv_FreekillersBantimeDC, bool:cv_LRSEnabled, bool:cv_LRSAutomatic, bool:cv_LRSLockWarden,
cv_FreedayLimit, bool:cv_1stDayFreeday, bool:cv_DemoCharge, bool:cv_DoubleJump, bool:cv_Airblast, bool:cv_RendererParticles,
bool:cv_RendererColors, String:cv_sDefaultColor[24], cv_WardenVoice, bool:cv_WardenWearables, bool:cv_FreedayTeleports, cv_WardenStabProtection,
bool:cv_KillPointServerCommand, bool:cv_RemoveFreedayOnLR, bool:cv_RemoveFreedayOnLastGuard, bool:cv_PrefStatus, cv_WardenTimer, bool:cv_AdminFlags,
bool:cv_PrefBlue, bool:cv_PrefWarden, bool:cv_ConsoleSpew, bool:cv_PrefForce, bool:cv_FFButton, String:cv_sWeaponConfig[255], cv_KillFeeds, bool:cv_WardenDeathCrits,
bool:cv_RoundTimerStatus, cv_RoundTime, cv_RoundTime_Freeday, bool:cv_RoundTime_Center, String:cv_sRoundTimer_Execute[64], String:cv_sDefaultWardenModel[64],
bool:cv_WardenModelMenu;

//External Extensions/Plugin Booleans
new bool:eSourcebans, bool:eSourceComms, bool:eSteamWorks, bool:eTF2Attributes, bool:eVoiceannounce_ex, bool:eTF2WeaponRestrictions;

new bool:bIsMapCompatible = false, bool:bCellsOpened = false, bool:b1stRoundFreeday = false, bool:bVoidFreeKills = false,
bool:bIsLRInUse = false, bool:bIsWardenLocked = false, bool:bOneGuardLeft = false, bool:bActiveRound = false,
bool:bFreedayTeleportSet = false, bool:bLRConfigActive = true, bool:bLockWardenLR = false, bool:bDisableCriticles = false,
bool:bLateLoad = false, bool:bAdminLockWarden = false, bool:bAdminLockedLR = false, bool:bDifferentWepRestrict = false;

new bool:bBlockedDoubleJump[MAXPLAYERS + 1], bool:bDisabledAirblast[MAXPLAYERS + 1], bool:bIsMuted[MAXPLAYERS + 1],
bool:bIsRebel[MAXPLAYERS + 1], bool:bIsQueuedFreeday[MAXPLAYERS + 1], bool:bIsFreeday[MAXPLAYERS + 1], bool:bIsFreekiller[MAXPLAYERS + 1],
bool:bHasTalked[MAXPLAYERS + 1], bool:bLockedFromWarden[MAXPLAYERS + 1], bool:bRolePreference_Blue[MAXPLAYERS + 1], bool:bRolePreference_Warden[MAXPLAYERS + 1],
bool:bHasModel[MAXPLAYERS + 1], bool:bVoted[MAXPLAYERS + 1] = {false, ...};

new iWarden = -1, iCustom = -1, iLRPending = -1,
iLRCurrent = -1, iVoters = 0, iVotes = 0,
iVotesNeeded = 0, iWardenLimit = 0, iFreedayLimit = 0,
Float:iFreedayPosition[3], iRoundTime;

new iFirstKill[MAXPLAYERS + 1], iKillcount[MAXPLAYERS + 1], iHasBeenWarden[MAXPLAYERS + 1];

new String:sCellNames[32], String:sCellOpener[32], String:sFFButton[32], String:sDoorsList[][] = {"func_door", "func_door_rotating", "func_movelinear"},
String:sLRConfig[PLATFORM_MAX_PATH], String:sCustomLR[32];

//Role Renderers Globals
new a_iDefaultColors[4];

new a_iWardenColors[4];
new String:sWardenParticle[64];

new a_iFreedaysColors[4];
new String:sFreedaysParticle[64];

new a_iRebellersColors[4];
new String:sRebellersParticle[64];

new a_iFreekillersColors[4];
new String:sFreekillersParticle[64];

//Warden Model Menu
new Handle:hWardenModelsMenu;

enum eWardenMenu
{
	Open = 0,
	FriendlyFire,
	Collision
};

enum eAttachedParticles
{
	NO_ATTACH = 0,
	ATTACH_NORMAL,
	ATTACH_HEAD
};

enum eTextNodeParams
{
	Float:fCoord_X,
	Float:fCoord_Y,
	Float:fHoldTime,
	iRed,
	iBlue,
	iGreen,
	iAlpha,
	iEffect,
	Float:fFXTime,
	Float:fFadeIn,
	Float:fFadeOut,
};

new eWardenMenu:EnumWardenMenu;
new EnumTNPS[4][eTextNodeParams];

/* Plugin Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:sError[], err_max)
{
	//TF2 only... wonder why.
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(sError, err_max, "This plug-in only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	//Sourcemod Compatibility Check
	new String:sVersion[32];
	GetConVarString(FindConVar("sourcemod_version"), sVersion, sizeof(sVersion));
	
	if (StrContains(sVersion, SOURCEMOD_REQUIRED) == -1)
	{
		Format(sError, err_max, "This plugin requires Sourcemod %s+ [Current Version: %s]", SOURCEMOD_REQUIRED, sVersion);
		return APLRes_Failure;
	}
	
	//Mark these as optional just in case either SourceBans itself or Sourcecomms along with SourceBans are running.
	MarkNativeAsOptional("SBBanPlayer");
	MarkNativeAsOptional("SourceComms_GetClientMuteType");
	
	//Mark these as optional anyways just in case the plugins aren't running.
	MarkNativeAsOptional("BanClient");
	MarkNativeAsOptional("BaseComm_IsClientMuted");
	
	//Marking this as optional JUST IN CASE.
	MarkNativeAsOptional("SteamWorks_SetGameDescription");
	
	//Natives
	CreateNative("TF2Jail_WardenActive", Native_ExistWarden);
	CreateNative("TF2Jail_IsWarden", Native_IsWarden);
	CreateNative("TF2Jail_WardenSet", Native_SetWarden);
	CreateNative("TF2Jail_WardenUnset", Native_RemoveWarden);
	CreateNative("TF2Jail_IsFreeday", Native_IsFreeday);
	CreateNative("TF2Jail_GiveFreeday", Native_GiveFreeday);
	CreateNative("TF2Jail_RemoveFreeday", Native_RemoveFreeday);
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
	CreateNative("TF2Jail_ManageCells", Native_ManageCells);
	
	//Forwards
	sFW_WardenCreated = CreateGlobalForward("TF2Jail_OnWardenCreated", ET_Event, Param_Cell);
	sFW_WardenRemoved = CreateGlobalForward("TF2Jail_OnWardenRemoved", ET_Event, Param_Cell);
	sFW_OnLastRequestExecute = CreateGlobalForward("TF2Jail_OnLastRequestExecute", ET_Event, Param_String);
	sFW_OnFreedayGiven = CreateGlobalForward("TF2Jail_OnFreedayGiven", ET_Event, Param_Cell);
	sFW_OnFreedayRemoved = CreateGlobalForward("TF2Jail_OnFreedayRemoved", ET_Event, Param_Cell);
	sFW_OnFreekillerGiven = CreateGlobalForward("TF2Jail_OnFreekillerGiven", ET_Event, Param_Cell);
	sFW_OnFreekillerRemoved = CreateGlobalForward("TF2Jail_OnFreekillerRemoved", ET_Event, Param_Cell);
	sFW_OnRebelGiven = CreateGlobalForward("TF2Jail_OnRebelGiven", ET_Event, Param_Cell);
	sFW_OnRebelRemoved = CreateGlobalForward("TF2Jail_OnRebelRemoved", ET_Event, Param_Cell);
	
	//Register the library
	RegPluginLibrary("tf2jail");
	
	//Check if the plugin is late-load and set it correctly.
	bLateLoad = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	Jail_Log("%s Jailbreak is now loading...", "plugin tag");
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail.phrases");
	
	//Set the config file before handling it.
	AutoExecConfig_SetFile("TF2Jail");
	
	//ConVars
	hConVars[0] = AutoExecConfig_CreateConVar("tf2jail_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hConVars[1] = AutoExecConfig_CreateConVar("sm_tf2jail_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[2] = AutoExecConfig_CreateConVar("sm_tf2jail_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[3] = AutoExecConfig_CreateConVar("sm_tf2jail_set_variables", "1", "Set default cvars: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[4] = AutoExecConfig_CreateConVar("sm_tf2jail_logging", "2", "Status and the type of logging: (0 = disabled, 1 = regular logging, 2 = logging to TF2Jail logs.)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hConVars[5] = AutoExecConfig_CreateConVar("sm_tf2jail_auto_balance", "1", "Should the plugin autobalance teams: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[6] = AutoExecConfig_CreateConVar("sm_tf2jail_balance_ratio", "0.5", "Ratio for autobalance: (Example: 0.5 = 2:4)", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	hConVars[7] = AutoExecConfig_CreateConVar("sm_tf2jail_melee", "1", "Strip Red Team of weapons: (1 = strip weapons, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[8] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_enable", "1", "Allow Wardens: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[9] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_auto", "1", "Automatically assign a random Wardens on round start: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[10] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_models", "1", "Enable custom models for Warden: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[11] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_forceclass", "1", "Force Wardens to be the class assigned to the models: (1 = yes, 0 = no)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[12] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_friendlyfire", "1", "Allow Wardens to manage friendly fire: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[13] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_collision", "1", "Allow Wardens to manage collision: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[14] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_request", "0", "Require admin acceptance for cvar changes: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[15] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_limit", "3", "Number of allowed Wardens per user per map: (0.0 = unlimited)", FCVAR_PLUGIN, true, 0.0);
	hConVars[16] = AutoExecConfig_CreateConVar("sm_tf2jail_door_controls", "1", "Allow Wardens and Admins door control: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[17] = AutoExecConfig_CreateConVar("sm_tf2jail_cell_timer", "60", "Time after Arena round start to open doors: (1.0 - 60.0) (0.0 = off)", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	hConVars[18] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_red", "2", "Mute Red team: (2 = mute prisoners alive and all dead, 1 = mute prisoners on round start based on redmute_time, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hConVars[19] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_red_time", "15", "Mute time for redmute: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	hConVars[20] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_blue", "2", "Mute Blue players: (2 = always except Wardens, 1 = while Wardens is active, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hConVars[21] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_dead", "1", "Mute Dead players: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[22] = AutoExecConfig_CreateConVar("sm_tf2jail_microphonecheck_enable", "1", "Check blue clients for microphone: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[23] = AutoExecConfig_CreateConVar("sm_tf2jail_microphonecheck_type", "1", "Block blue team or Wardens if no microphone: (1 = Blue, 0 = Wardens only)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[24] = AutoExecConfig_CreateConVar("sm_tf2jail_rebelling_enable", "1", "Enable the Rebel system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[25] = AutoExecConfig_CreateConVar("sm_tf2jail_rebelling_time", "30.0", "Rebel timer: (1.0 - 60.0, 0 = always)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	hConVars[26] = AutoExecConfig_CreateConVar("sm_tf2jail_criticals", "1", "Which team gets crits: (0 = off, 1 = blue, 2 = red, 3 = both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	hConVars[27] = AutoExecConfig_CreateConVar("sm_tf2jail_criticals_type", "2", "Type of crits given: (1 = mini, 2 = full)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
	hConVars[28] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_status", "1", "Status to allow votes to fire wardens: (1 = on, 0 = off)", _, true, 0.0, true, 1.0);
	hConVars[29] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_votesneeded", "0.60", "Percentage of players required for fire Wardens vote: (default 0.60 - 60%) (0.05 - 1.00)", 0, true, 0.05, true, 1.00);
	hConVars[30] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_minplayers", "0", "Minimum amount of players required for fire Wardens vote: (0 - MaxPlayers)", 0, true, 0.0, true, float(MAXPLAYERS));
	hConVars[31] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_postaction", "0", "Fire Wardens instantly on vote success or next round: (0 = instant, 1 = Next round)", _, true, 0.0, true, 1.0);
	hConVars[32] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_passlimit", "3", "Limit to Wardens fired by players via votes: (1 - 10, 0 = unlimited)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	hConVars[33] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_enable", "1", "Enable the Freekill system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[34] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_seconds", "6.0", "Time in seconds minimum for freekill flag on mark: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	hConVars[35] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_kills", "6", "Number of kills required to flag for freekilling: (1.0 - MaxPlayers)", FCVAR_PLUGIN, true, 1.0, true, float(MAXPLAYERS));
	hConVars[36] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_wave", "60.0", "Time in seconds until client is banned for being marked: (1.0 Minimum)", FCVAR_PLUGIN, true, 1.0);
	hConVars[37] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_action", "2", "Action towards marked freekiller: (2 = Ban client based on cvars, 1 = Slay the client, 0 = remove mark on timer)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hConVars[38] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_ban_reason", "You have been banned for freekilling.", "Message to give the client if they're marked as a freekiller and banned.", FCVAR_PLUGIN);
	hConVars[39] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_ban_reason_dc", "You have been banned for freekilling and disconnecting.", "Message to give the client if they're marked as a freekiller/disconnected and banned.", FCVAR_PLUGIN);
	hConVars[40] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_duration", "60", "Time banned after timer ends: (0 = permanent)", FCVAR_PLUGIN, true, 0.0);
	hConVars[41] = AutoExecConfig_CreateConVar("sm_tf2jail_freekilling_duration_dc", "120", "Time banned if disconnected after timer ends: (0 = permanent)", FCVAR_PLUGIN, true, 0.0);
	hConVars[42] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_enable", "1", "Status of the LR System: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[43] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_automatic", "1", "Automatically grant last request to last prisoner alive: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[44] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_lock_warden", "1", "Lock Wardens during last request rounds: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[45] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_limit", "3", "Max number of freedays for the lr: (1.0 - 16.0)", FCVAR_PLUGIN, true, 1.0, true, 16.0);
	hConVars[46] = AutoExecConfig_CreateConVar("sm_tf2jail_1stdayfreeday", "1", "Status of the 1st day freeday: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[47] = AutoExecConfig_CreateConVar("sm_tf2jail_democharge", "1", "Allow demomen to charge: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[48] = AutoExecConfig_CreateConVar("sm_tf2jail_doublejump", "1", "Deny scouts to double jump: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[49] = AutoExecConfig_CreateConVar("sm_tf2jail_airblast", "1", "Deny pyros to airblast: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[50] = AutoExecConfig_CreateConVar("sm_tf2jail_renderer_particles", "1", "Status for particles to render from config: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[51] = AutoExecConfig_CreateConVar("sm_tf2jail_renderer_colors", "1", "Status for colors to render from config: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[52] = AutoExecConfig_CreateConVar("sm_tf2jail_renderer_default_color", "255, 255, 255, 255", "Default color to set clients to if one isn't present: (Default: 255, 255, 255, 255)", FCVAR_PLUGIN);
	hConVars[53] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_voice", "1", "Voice management for Wardens: (0 = disabled, 1 = unmute, 2 = warning)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hConVars[54] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_wearables", "1", "Strip Wardens wearables: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[55] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_teleport", "1", "Status of teleporting: (1 = enable, 0 = disable) (Disables all functionality regardless of configs)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[56] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_stabprotection", "0", "Give Wardens backstab protection: (2 = Always, 1 = Once, 0 = Disabled)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hConVars[57] = AutoExecConfig_CreateConVar("sm_tf2jail_point_servercommand", "1", "Kill 'point_servercommand' entities: (1 = Kill on Spawn, 0 = Disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[58] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_removeonlr", "1", "Remove Freedays on Last Request: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[59] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_removeonlastguard", "1", "Remove Freedays on Last Guard: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[60] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_enable", "0", "Allow clients to choose their preferred teams/roles: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[61] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_timer", "20", "Time in seconds after Warden is unset or lost to lock Warden: (0 = Disabled, NON-FLOAT VALUE)", FCVAR_PLUGIN);
	hConVars[62] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_flags", "0", "Lock Warden to a command access flag: (1 = enable, 0 = disable) (Command Access: TF2Jail_WardenOverride)", FCVAR_PLUGIN);
	hConVars[63] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_blue", "0", "Enable the preference for Blue if preferences are enabled: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[64] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_warden", "0", "Enable the preference for Blue if preferences are enabled: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[65] = AutoExecConfig_CreateConVar("sm_tf2jail_console_prints_status", "1", "Enable console messages and information: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[66] = AutoExecConfig_CreateConVar("sm_tf2jail_preference_force", "1", "Force admin commands to set players to roles regardless of preference: (1 = Force, 0 = Respect)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[67] = AutoExecConfig_CreateConVar("sm_tf2jail_friendlyfire_button", "1", "Status for Friendly Fire button if exists: (1 = Locked, 0 = Unlocked)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[68] = AutoExecConfig_CreateConVar("sm_tf2jail_weaponconfig", "Jailbreak", "Name of the config for Weapon Blocker: (Default: Jailbreak) (If you compiled plugin without plugin, disregard)", FCVAR_PLUGIN);
	hConVars[69] = AutoExecConfig_CreateConVar("sm_tf2jail_disable_killfeeds", "0", "Disable kill feeds status: (0 = None, 1 = Red, 2 = Blue, 3 = All)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	hConVars[70] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_death_crits", "1", "Disable critical hits on Warden death: (0 = Disabled, 1 = Enabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[71] = AutoExecConfig_CreateConVar("sm_tf2jail_roundtimer_status", "1", "Status of the round timer: (0 = Disabled, 1 = Enabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[72] = AutoExecConfig_CreateConVar("sm_tf2jail_roundtimer_time", "600", "Amount of time normally on the timer: (0.0 = disabled)", FCVAR_PLUGIN, true, 0.0);
	hConVars[73] = AutoExecConfig_CreateConVar("sm_tf2jail_roundtimer_time_freeday", "300", "Amount of time on 1st day freeday: (0.0 = disabled)", FCVAR_PLUGIN, true, 0.0);
	hConVars[74] = AutoExecConfig_CreateConVar("sm_tf2jail_roundtimer_center", "0", "Show center text for round timer: (0 = Disabled, 1 = Enabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[75] = AutoExecConfig_CreateConVar("sm_tf2jail_roundtimer_execute", "sm_slay @red", "Commands to execute to server on timer end: (Minimum 64 characters)", FCVAR_PLUGIN);
	hConVars[76] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_defaultmodel", "Warden V2", "Default model by name to set Wardens to: (Minimum 64 characters)", FCVAR_PLUGIN);
	hConVars[77] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_models_menu", "1", "Status for the Warden models menu: (1 = Enabled, 0 = Disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Execute the file after we create & set the ConVars.
	AutoExecConfig_ExecuteFile();
	
	//Hook all ConVars up and check for changes.
	for (new i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], HandleCvars);
	}
	
	//Hooked Events
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_death", OnPlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("arena_round_start", OnArenaRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("post_inventory_application", OnRegeneration);
	HookEvent("player_changeclass", OnChangeClass, EventHookMode_Pre);
	
	//Player Commands (Anyone can use)
	RegConsoleCmd("sm_fire", Command_FireWarden, "Vote for Warden to be fired.");
	RegConsoleCmd("sm_firewarden", Command_FireWarden, "Vote for Warden to be fired.");
	RegConsoleCmd("sm_w", Command_BecomeWarden, "Become the Warden.");
	RegConsoleCmd("sm_warden", Command_BecomeWarden, "Become the Warden.");
	RegConsoleCmd("sm_uw", Command_ExitWarden, "Remove yourself from Warden.");
	RegConsoleCmd("sm_unwarden", Command_ExitWarden, "Remove yourself from Warden.");
	RegConsoleCmd("sm_wmenu", Command_WardenMenu, "Call the Warden Menu if you're Warden.");
	RegConsoleCmd("sm_wardenmenu", Command_WardenMenu, "Call the Warden Menu if you're Warden.");
	RegConsoleCmd("sm_open", Command_OpenCells, "Open the cell doors.");
	RegConsoleCmd("sm_close", Command_CloseCells, "Close the cell doors.");
	RegConsoleCmd("sm_wff", Command_EnableFriendlyFire, "Request or enable Friendly Fire as Warden.");
	RegConsoleCmd("sm_wcc", Command_EnableCollisions, "Request or enable Collision changes as Warden.");
	RegConsoleCmd("sm_givelr", Command_GiveLastRequest, "Give a last request to a Prisoner as Warden.");
	RegConsoleCmd("sm_givelastrequest", Command_GiveLastRequest, "Give a last request to a Prisoner as Warden.");
	RegConsoleCmd("sm_removelr", Command_RemoveLastRequest, "Remove a last request from a Prisoner as Warden.");
	RegConsoleCmd("sm_removelastrequest", Command_RemoveLastRequest, "Remove a last request from a Prisoner as Warden.");
	RegConsoleCmd("sm_currentlr", Command_CurrentLastRequest, "Last requests that are currently queued for next round or current.");
	RegConsoleCmd("sm_currentlastrequests", Command_CurrentLastRequest, "Last requests that are currently queued for next round or current.");
	RegConsoleCmd("sm_lrlist", Command_ListLastRequests, "Display a list of last requests available.");
	RegConsoleCmd("sm_lrslist", Command_ListLastRequests, "Display a list of last requests available.");
	RegConsoleCmd("sm_lrs", Command_ListLastRequests, "Display a list of last requests available.");
	RegConsoleCmd("sm_lastrequestlist", Command_ListLastRequests, "Display a list of last requests available.");
	RegConsoleCmd("sm_cw", Command_CurrentWarden, "Display the name of the current Warden.");
	RegConsoleCmd("sm_currentwarden", Command_CurrentWarden, "Display the name of the current Warden.");
	RegConsoleCmd("sm_wm", Command_WardenModel, "Set your model while being Warden.");
	RegConsoleCmd("sm_wmodel", Command_WardenModel, "Set your model while being Warden.");
	RegConsoleCmd("sm_wardenmodel", Command_WardenModel, "Set your model while being Warden.");
	
	//Admin commands (Admin only)
	RegAdminCmd("sm_rw", AdminRemoveWarden, ADMFLAG_GENERIC, "Remove the currently active Warden.");
	RegAdminCmd("sm_removewarden", AdminRemoveWarden, ADMFLAG_GENERIC, "Remove the currently active Warden.");
	RegAdminCmd("sm_pardon", AdminPardonFreekiller, ADMFLAG_GENERIC, "Pardon an actively marked Free killer.");
	RegAdminCmd("sm_unmark", AdminPardonFreekiller, ADMFLAG_GENERIC, "Pardon an actively marked Free killer.");
	RegAdminCmd("sm_pardonall", AdminPardonAllFreekillers, ADMFLAG_GENERIC, "Pardon all actively marked Free killer.");
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
	RegAdminCmd("sm_lw", AdminLockWarden, ADMFLAG_GENERIC, "Lock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_lockwarden", AdminLockWarden, ADMFLAG_GENERIC, "Lock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_ulw", AdminUnlockWarden, ADMFLAG_GENERIC, "Unlock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_unlockwarden", AdminUnlockWarden, ADMFLAG_GENERIC, "Unlock Warden from being taken by clients publicly.");
	RegAdminCmd("sm_mark", AdminMarkFreekiller, ADMFLAG_GENERIC, "Marks a client as a Free Killer.");
	RegAdminCmd("sm_markfreekiller", AdminMarkFreekiller, ADMFLAG_GENERIC, "Marks a client as a Free Killer.");
	
	//Engine ConVars we would like to hook into for various reasons.
	hEngineConVars[0] = FindConVar("mp_friendlyfire");
	hEngineConVars[1] = FindConVar("tf_avoidteammates_pushaway");
	hEngineConVars[2] = FindConVar("sv_gravity");
	
	//Lets create the HUD elements here to use later for the text nodes.
	for (new i = 0; i < sizeof(hTextNodes); i++)
	{
		hTextNodes[i] = CreateHudSynchronizer();
	}
	
	//MultiTarget filters
	AddMultiTargetFilter("@warden", WardenGroup, "The Warden.", false);
	AddMultiTargetFilter("@rebels", RebelsGroup, "All Rebels.", false);
	AddMultiTargetFilter("@freedays", FreedaysGroup, "All Freedays.", false);
	AddMultiTargetFilter("@freekillers", FreekillersGroup, "All Freekillers.", false);
	AddMultiTargetFilter("@!warden", NotWardenGroup, "All but the Warden.", false);
	AddMultiTargetFilter("@!rebels", NotRebelsGroup, "All but the Rebels.", false);
	AddMultiTargetFilter("@!freekillers", NotFreekillersGroup, "All but the Freekillers.", false);
	
	//Client cookies to handle preferences.
	hRolePref_Blue = RegClientCookie("TF2Jail_RolePreference_Blue", "Sets the preferred role of the client. (Blue)", CookieAccess_Private);
	hRolePref_Warden = RegClientCookie("TF2Jail_RolePreference_Warden", "Sets the preferred role of the client. (Warden)", CookieAccess_Private);
	SetCookieMenuItem(TF2Jail_Preferences, 0, "TF2Jail Preferences");
	
	//Building the path to last requests here since It's needed more than once with this plugin.
	BuildPath(Path_SM, sLRConfig, sizeof(sLRConfig), "configs/tf2jail/lastrequests.cfg");
	
	//Arrays/Tries (Holds data)
	hLastRequestUses = CreateArray();
	hWardenSkinClasses = CreateTrie();
	hWardenSkins = CreateTrie();
	
	//Clean our configuration file of anything missing. (Should be done at the end of OnPluginStart I read somewhere)
	AutoExecConfig_CleanFile();
}

public OnAllPluginsLoaded()
{
	eSourcebans = LibraryExists("SourceBans");
	eSourceComms = LibraryExists("sourcecomms");
	eSteamWorks = LibraryExists("SteamWorks");
	eTF2Attributes = LibraryExists("tf2attributes");
	eVoiceannounce_ex = LibraryExists("voiceannounce_ex");
	eTF2WeaponRestrictions = LibraryExists("tf2weaponrestrictions");
}

public OnLibraryAdded(const String:sName[])
{
	eSourcebans = StrEqual(sName, "SourceBans", false);
	eSourceComms = StrEqual(sName, "sourcecomms");
	eSteamWorks = StrEqual(sName, "SteamWorks", false);
	eTF2Attributes = StrEqual(sName, "tf2attributes", false);
	eVoiceannounce_ex = StrEqual(sName, "voiceannounce_ex", false);
	eTF2WeaponRestrictions = StrEqual(sName, "tf2weaponrestrictions", false);
}

public OnLibraryRemoved(const String:sName[])
{
	eSourcebans = StrEqual(sName, "SourceBans", false);
	eSourceComms = StrEqual(sName, "sourcecomms");
	eSteamWorks = StrEqual(sName, "SteamWorks", false);
	eTF2Attributes = StrEqual(sName, "tf2attributes", false);
	eVoiceannounce_ex = StrEqual(sName, "voiceannounce_ex", false);
	eTF2WeaponRestrictions = StrEqual(sName, "tf2weaponrestrictions", false);
}

public OnPluginPauseChange(bool:pause)
{
	if (eSteamWorks)
	{
		switch (pause)
		{
			case true:
				{
					SteamWorks_SetGameDescription("Team Fortress");
				}
			case false:
				{
					new String:sDescription[64];
					Format(sDescription, sizeof(sDescription), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
					SteamWorks_SetGameDescription(sDescription);
				}
		}
	}
}

public OnPluginEnd()
{
	OnMapEnd();
}

public OnConfigsExecuted()
{
	//Preload all ConVars to make the plugin work less later. We obviously hook the same ConVars for changes during the round.
	cv_Enabled = GetConVarBool(hConVars[1]);
	cv_Advertise = GetConVarBool(hConVars[2]);
	cv_Cvars = GetConVarBool(hConVars[3]);
	cv_Logging = GetConVarInt(hConVars[4]);
	cv_Balance = GetConVarBool(hConVars[5]);
	cv_BalanceRatio = GetConVarFloat(hConVars[6]);
	cv_RedMelee = GetConVarBool(hConVars[7]);
	cv_Warden = GetConVarBool(hConVars[8]);
	cv_WardenAuto = GetConVarBool(hConVars[9]);
	cv_WardenModels = GetConVarBool(hConVars[10]);
	cv_WardenForceClass = GetConVarBool(hConVars[11]);
	cv_WardenFF = GetConVarBool(hConVars[12]);
	cv_WardenCC = GetConVarBool(hConVars[13]);
	cv_WardenRequest = GetConVarBool(hConVars[14]);
	cv_WardenLimit = GetConVarInt(hConVars[15]);
	cv_DoorControl = GetConVarBool(hConVars[16]);
	cv_DoorOpenTimer = GetConVarFloat(hConVars[17]);
	cv_RedMute = GetConVarInt(hConVars[18]);
	cv_RedMuteTime = GetConVarFloat(hConVars[19]);
	cv_BlueMute = GetConVarInt(hConVars[20]);
	cv_DeadMute = GetConVarBool(hConVars[21]);
	cv_MicCheck = GetConVarBool(hConVars[22]);
	cv_MicCheckType = GetConVarBool(hConVars[23]);
	cv_Rebels = GetConVarBool(hConVars[24]);
	cv_RebelsTime = GetConVarFloat(hConVars[25]);
	cv_Criticals = GetConVarInt(hConVars[26]);
	cv_Criticalstype = GetConVarInt(hConVars[27]);
	cv_WVotesStatus = GetConVarBool(hConVars[28]);
	cv_WVotesNeeded = GetConVarFloat(hConVars[29]);
	cv_WVotesMinPlayers = GetConVarInt(hConVars[30]);
	cv_WVotesPostAction = GetConVarInt(hConVars[31]);
	cv_WVotesPassedLimit = GetConVarInt(hConVars[32]);
	cv_Freekillers = GetConVarBool(hConVars[33]);
	cv_FreekillersTime = GetConVarFloat(hConVars[34]);
	cv_FreekillersKills = GetConVarInt(hConVars[35]);
	cv_FreekillersWave = GetConVarFloat(hConVars[36]);
	cv_FreekillersAction = GetConVarInt(hConVars[37]);
	GetConVarString(hConVars[38], cv_sBanMSG, sizeof(cv_sBanMSG));
	GetConVarString(hConVars[39], cv_sBanMSGDC, sizeof(cv_sBanMSGDC));
	cv_FreekillersBantime = GetConVarInt(hConVars[40]);
	cv_FreekillersBantimeDC = GetConVarInt(hConVars[41]);
	cv_LRSEnabled = GetConVarBool(hConVars[42]);
	cv_LRSAutomatic = GetConVarBool(hConVars[43]);
	cv_LRSLockWarden = GetConVarBool(hConVars[44]);
	cv_FreedayLimit = GetConVarInt(hConVars[45]);
	cv_1stDayFreeday = GetConVarBool(hConVars[46]);
	cv_DemoCharge = GetConVarBool(hConVars[47]);
	cv_DoubleJump = GetConVarBool(hConVars[48]);
	cv_Airblast = GetConVarBool(hConVars[49]);
	cv_RendererParticles = GetConVarBool(hConVars[50]);
	cv_RendererColors = GetConVarBool(hConVars[51]);
	GetConVarString(hConVars[52], cv_sDefaultColor, sizeof(cv_sDefaultColor));
	cv_WardenVoice = GetConVarInt(hConVars[53]);
	cv_WardenWearables = GetConVarBool(hConVars[54]);
	cv_FreedayTeleports = GetConVarBool(hConVars[55]);
	cv_WardenStabProtection = GetConVarBool(hConVars[56]);
	cv_KillPointServerCommand = GetConVarBool(hConVars[57]);
	cv_RemoveFreedayOnLR = GetConVarBool(hConVars[58]);
	cv_RemoveFreedayOnLastGuard = GetConVarBool(hConVars[59]);
	cv_PrefStatus = GetConVarBool(hConVars[60]);
	cv_WardenTimer = GetConVarInt(hConVars[61]);
	cv_AdminFlags = GetConVarBool(hConVars[62]);
	cv_PrefBlue = GetConVarBool(hConVars[63]);
	cv_PrefWarden = GetConVarBool(hConVars[64]);
	cv_ConsoleSpew = GetConVarBool(hConVars[65]);
	cv_PrefForce = GetConVarBool(hConVars[66]);
	cv_FFButton = GetConVarBool(hConVars[67]);
	GetConVarString(hConVars[68], cv_sWeaponConfig, sizeof(cv_sWeaponConfig));
	cv_KillFeeds = GetConVarInt(hConVars[69]);
	cv_WardenDeathCrits = GetConVarBool(hConVars[70]);
	cv_RoundTimerStatus = GetConVarBool(hConVars[71]);
	cv_RoundTime = GetConVarInt(hConVars[72]);
	cv_RoundTime_Freeday = GetConVarInt(hConVars[73]);
	cv_RoundTime_Center = GetConVarBool(hConVars[74]);
	GetConVarString(hConVars[75], cv_sRoundTimer_Execute, sizeof(cv_sRoundTimer_Execute));
	GetConVarString(hConVars[76], cv_sDefaultWardenModel, sizeof(cv_sDefaultWardenModel));
	cv_WardenModelMenu = GetConVarBool(hConVars[77]);

	if (!cv_Enabled) return;
	
	//Set the ConVars up on the server based on settings.
	if (cv_Cvars)
	{
		ConvarsSet(true);
	}
	
	//Take account for late loading. Probably don't need to set the bool to false but better safe than sorry.
	if (bLateLoad)
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
		
		b1stRoundFreeday = false;
		bLateLoad = false;
	}
	
	//Build what we need to build.
	ResetVotes();
	ParseConfigs();
	BuildMenus();
	
	//By default, we should store the default color into the 2D Integer Array just to save it.
	new String:sStringArray[4][8];
	ExplodeString(cv_sDefaultColor, ", ", sStringArray, 4, 8);
	
	for (new i = 0; i < 4; i++)
	{
		a_iDefaultColors[i] = StringToInt(sStringArray[i]);
	}
	
	//Plugin is loaded! :)
	Jail_Log("%s Jailbreak has successfully loaded.", "plugin tag");
}

public SteamWorks_SteamServersConnected()
{
	if (eSteamWorks)
	{
		new String:sDescription[64];
		Format(sDescription, sizeof(sDescription), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
		SteamWorks_SetGameDescription(sDescription);
	}
}

public HandleCvars(Handle:cvar, const String:sOldValue[], const String:sNewValue[])
{
	if (StrEqual(sOldValue, sNewValue, true)) return;

	new iNewValue = StringToInt(sNewValue);

	if (cvar == hConVars[0])
	{
		SetConVarString(hConVars[0], PLUGIN_VERSION);
	}
	else if (cvar == hConVars[1])
	{
		cv_Enabled = bool:iNewValue;
		switch (iNewValue)
		{
		case 1:
			{
				CPrintToChatAll("%t %t", "plugin tag", "plugin enabled");

				if (eSteamWorks)
				{
					new String:sDescription[64];
					Format(sDescription, sizeof(sDescription), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
					SteamWorks_SetGameDescription(sDescription);
				}
				
				if (cv_WardenModels && WardenExists())
				{
					SetWardenModel(iWarden, cv_sDefaultWardenModel);
				}
			}
		case 0:
			{
				CPrintToChatAll("%t %t", "plugin tag", "plugin disabled");

				if (eSteamWorks)
				{
					SteamWorks_SetGameDescription("Team Fortress");
				}
				
				if (cv_WardenModels && WardenExists())
				{
					RemoveModel(iWarden);
				}

				for (new i = 1; i <= MaxClients; i++)
				{
					if (!Client_IsIngame(i) || !bIsRebel[i]) continue;
					bIsRebel[i] = false;
				}
			}
		}
	}
	else if (cvar == hConVars[2])
	{
		cv_Advertise = bool:iNewValue;
		ClearTimer(hTimer_Advertisement);
		if (cv_Advertise)
		{
			StartAdvertisement();
		}
	}
	else if (cvar == hConVars[3])
	{
		cv_Cvars = bool:iNewValue;
		ConvarsSet(cv_Cvars ? true : false);
	}
	else if (cvar == hConVars[4])
	{
		cv_Logging = iNewValue;
	}
	else if (cvar == hConVars[5])
	{
		cv_Balance = bool:iNewValue;
	}
	else if (cvar == hConVars[6])
	{
		cv_BalanceRatio = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[7])
	{
		cv_RedMelee = bool:iNewValue;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!Client_IsIngame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != _:TFTeam_Red) continue;
				
			switch (cv_RedMelee)
			{
			case true: RequestFrame(ManageWeapons, GetClientUserId(i));
			case false: TF2_RegeneratePlayer(i);
			}
		}
	}
	else if (cvar == hConVars[8])
	{
		cv_Warden = bool:iNewValue;
		if (!cv_Warden && WardenExists())
		{
			WardenUnset(iWarden);
		}
	}
	else if (cvar == hConVars[9])
	{
		cv_WardenAuto = bool:iNewValue;
	}
	else if (cvar == hConVars[10])
	{
		cv_WardenModels = bool:iNewValue;
		switch (cv_WardenModels)
		{
			case true:
				{
					if (WardenExists())
					{
						SetWardenModel(iWarden, cv_sDefaultWardenModel);
					}
				}
			case false:
				{
					if (WardenExists())
					{
						RemoveModel(iWarden);
					}
				}
		}
	}
	else if (cvar == hConVars[11])
	{
		cv_WardenForceClass = bool:iNewValue;
	}
	else if (cvar == hConVars[12])
	{
		cv_WardenFF = bool:iNewValue;
	}
	else if (cvar == hConVars[13])
	{
		cv_WardenCC = bool:iNewValue;
	}
	else if (cvar == hConVars[14])
	{
		cv_WardenRequest = bool:iNewValue;
	}
	else if (cvar == hConVars[15])
	{
		cv_WardenLimit = iNewValue;
	}
	else if (cvar == hConVars[16])
	{
		cv_DoorControl = bool:iNewValue;
	}
	else if (cvar == hConVars[17])
	{
		cv_DoorOpenTimer = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[18])
	{
		cv_RedMute = iNewValue;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == _:TFTeam_Red && !IsVIP(i))
				{
					switch (iNewValue)
					{
					case 2:	if (bActiveRound) MutePlayer(i);
					case 1:	if (bCellsOpened) MutePlayer(i);
					case 0:	UnmutePlayer(i);
					}
				}
			}
		}
	}
	else if (cvar == hConVars[19])
	{
		cv_RedMuteTime = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[20])
	{
		cv_BlueMute = iNewValue;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == _:TFTeam_Blue && !IsVIP(i))
				{
					switch (iNewValue)
					{
					case 2:	if (!IsWarden(i)) MutePlayer(i);
					case 1:	MutePlayer(i);
					case 0:	UnmutePlayer(i);
					}
				}
			}
		}
	}
	else if (cvar == hConVars[21])
	{
		cv_DeadMute = bool:iNewValue;
	}
	else if (cvar == hConVars[22])
	{
		cv_MicCheck = bool:iNewValue;
	}
	else if (cvar == hConVars[23])
	{
		cv_MicCheckType = bool:iNewValue;
	}
	else if (cvar == hConVars[24])
	{
		cv_Rebels = bool:iNewValue;
		if (iNewValue == 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && bIsRebel[i])
				{
					bIsRebel[i] = false;
				}
			}
		}
	}
	else if (cvar == hConVars[25])
	{
		cv_RebelsTime = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[26])
	{
		cv_Criticals = iNewValue;
	}
	else if (cvar == hConVars[27])
	{
		cv_Criticalstype = iNewValue;
	}
	else if (cvar == hConVars[28])
	{
		cv_WVotesStatus = bool:iNewValue;
	}
	else if (cvar == hConVars[29])
	{
		cv_WVotesNeeded = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[30])
	{
		cv_WVotesMinPlayers = iNewValue;
	}
	else if (cvar == hConVars[31])
	{
		cv_WVotesPostAction = iNewValue;
	}
	else if (cvar == hConVars[32])
	{
		cv_WVotesPassedLimit = iNewValue;
	}
	else if (cvar == hConVars[33])
	{
		cv_Freekillers = bool:iNewValue;
	}
	else if (cvar == hConVars[34])
	{
		cv_FreekillersTime = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[35])
	{
		cv_FreekillersKills = iNewValue;
	}
	else if (cvar == hConVars[36])
	{
		cv_FreekillersWave = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[37])
	{
		cv_FreekillersAction = iNewValue;
	}
	else if (cvar == hConVars[38])
	{
		GetConVarString(hConVars[38], cv_sBanMSG, sizeof(cv_sBanMSG));
	}
	else if (cvar == hConVars[39])
	{
		GetConVarString(hConVars[39], cv_sBanMSGDC, sizeof(cv_sBanMSGDC));
	}
	else if (cvar == hConVars[40])
	{
		cv_FreekillersBantime = iNewValue;
	}
	else if (cvar == hConVars[41])
	{
		cv_FreekillersBantimeDC = iNewValue;
	}
	else if (cvar == hConVars[42])
	{
		cv_LRSEnabled = bool:iNewValue;
	}
	else if (cvar == hConVars[43])
	{
		cv_LRSAutomatic = bool:iNewValue;
	}
	else if (cvar == hConVars[44])
	{
		cv_LRSLockWarden = bool:iNewValue;
	}
	else if (cvar == hConVars[45])
	{
		cv_FreedayLimit = iNewValue;
	}
	else if (cvar == hConVars[46])
	{
		cv_1stDayFreeday = bool:iNewValue;
	}
	else if (cvar == hConVars[47])
	{
		cv_DemoCharge = bool:iNewValue;
	}
	else if (cvar == hConVars[48])
	{
		cv_DoubleJump = bool:iNewValue;
	}
	else if (cvar == hConVars[49])
	{
		cv_Airblast = bool:iNewValue;
	}
	else if (cvar == hConVars[50])
	{
		cv_RendererParticles = bool:iNewValue;
	}
	else if (cvar == hConVars[51])
	{
		cv_RendererColors = bool:iNewValue;
	}
	else if (cvar == hConVars[52])
	{
		GetConVarString(hConVars[52], cv_sDefaultColor, sizeof(cv_sDefaultColor));
	}
	else if (cvar == hConVars[53])
	{
		cv_WardenVoice = iNewValue;
	}
	else if (cvar == hConVars[54])
	{
		cv_WardenWearables = bool:iNewValue;
	}
	else if (cvar == hConVars[55])
	{
		cv_FreedayTeleports = bool:iNewValue;
	}
	else if (cvar == hConVars[56])
	{
		cv_WardenStabProtection = bool:iNewValue;
	}
	else if (cvar == hConVars[57])
	{
		cv_KillPointServerCommand = bool:iNewValue;
	}
	else if (cvar == hConVars[58])
	{
		cv_RemoveFreedayOnLR = bool:iNewValue;
	}
	else if (cvar == hConVars[59])
	{
		cv_RemoveFreedayOnLastGuard = bool:iNewValue;
	}
	else if (cvar == hConVars[60])
	{
		cv_PrefStatus = bool:iNewValue;
	}
	else if (cvar == hConVars[61])
	{
		cv_WardenTimer = iNewValue;
	}
	else if (cvar == hConVars[62])
	{
		cv_AdminFlags = bool:iNewValue;
	}
	else if (cvar == hConVars[63])
	{
		cv_PrefBlue = bool:iNewValue;
	}
	else if (cvar == hConVars[64])
	{
		cv_PrefWarden = bool:iNewValue;
	}
	else if (cvar == hConVars[65])
	{
		cv_ConsoleSpew = bool:iNewValue;
	}
	else if (cvar == hConVars[66])
	{
		cv_PrefForce = bool:iNewValue;
	}
	else if (cvar == hConVars[67])
	{
		cv_FFButton = bool:iNewValue;
	}
	else if (cvar == hConVars[68])
	{
		GetConVarString(hConVars[68], cv_sWeaponConfig, sizeof(cv_sWeaponConfig));
	}
	else if (cvar == hConVars[69])
	{
		cv_KillFeeds = iNewValue;
	}
	else if (cvar == hConVars[70])
	{
		cv_WardenDeathCrits = bool:iNewValue;
	}
	else if (cvar == hConVars[71])
	{
		cv_RoundTimerStatus = bool:iNewValue;
	}
	else if (cvar == hConVars[72])
	{
		cv_RoundTime = iNewValue;
	}
	else if (cvar == hConVars[73])
	{
		cv_RoundTime_Freeday = iNewValue;
	}
	else if (cvar == hConVars[74])
	{
		cv_RoundTime_Center = bool:iNewValue;
	}
	else if (cvar == hConVars[75])
	{
		GetConVarString(hConVars[75], cv_sRoundTimer_Execute, sizeof(cv_sRoundTimer_Execute));
	}
	else if (cvar == hConVars[76])
	{
		GetConVarString(hConVars[76], cv_sDefaultWardenModel, sizeof(cv_sDefaultWardenModel));
	}
	else if (cvar == hConVars[77])
	{
		cv_WardenModelMenu = bool:iNewValue;
	}
}

public TF2WeaponRestrictions_RestrictionChanged(const String:sRestriction[])
{
	if (!StrEqual(sRestriction, "Jailbreak") && iLRCurrent == -1)
	{
		bDifferentWepRestrict = true;
	}
}

/* Server Commands ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public OnMapStart()
{
	if (!cv_Enabled) return;

	ClearTimer(hTimer_RoundTimer);

	if (cv_Advertise) StartAdvertisement();

	for (new i = 1; i <= MaxClients; i++)
	{
		iHasBeenWarden[i] = 0;
	}
	
	if (cv_WardenModels)
	{
		ParseWardenModelsConfig();
	}

	if (cv_Freekillers) PrecacheSound("ui/system_message_alert.wav", true);

	b1stRoundFreeday = true;

	iVotesNeeded = 0;
	ResetVotes();

	for (new i = 0; i < GetArraySize(hLastRequestUses); i++)
	{
		SetArrayCell(hLastRequestUses, i, 0);
	}
}

public OnMapEnd()
{
	if (!cv_Enabled) return;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			if (IsWarden(i))
			{
				RemoveModel(i);
			}

			for (new x = 0; x < sizeof(hTextNodes); x++)
			{
				if (hTextNodes[x] == INVALID_HANDLE) continue;
				ClearSyncHud(i, hTextNodes[x]);
			}
		}

		bHasTalked[i] = false;
		bIsMuted[i] = false;
		bIsQueuedFreeday[i] = false;
		bLockedFromWarden[i] = false;
		iHasBeenWarden[i] = 0;
		hTimer_RebelTimers[i] = INVALID_HANDLE;
	}

	bActiveRound = false;
	bAdminLockWarden = false;
	iWardenLimit = 0;
	iLRCurrent = -1;
	ResetVotes();

	ConvarsSet(false);

	hTimer_Advertisement = INVALID_HANDLE;
	hTimer_FreekillingData = INVALID_HANDLE;
	hTimer_OpenCells = INVALID_HANDLE;
	hTimer_FriendlyFireEnable = INVALID_HANDLE;
	hTimer_WardenLock = INVALID_HANDLE;
}

public OnClientConnected(client)
{
	if (!cv_Enabled) return;

	bVoted[client] = false;
	iVoters++;
	iVotesNeeded = RoundToFloor(float(iVoters) * cv_WVotesNeeded);
	bIsMuted[client] = false;
}

public OnClientCookiesCached(client)
{
	if (!cv_Enabled) return;

	if (Client_IsIngame(client))
	{
		new String:sValue[8];

		if (cv_PrefStatus)
		{
			GetClientCookie(client, hRolePref_Blue, sValue, sizeof(sValue));
			bRolePreference_Blue[client] = (sValue[0] != '\0' && StringToInt(sValue));
			if (strlen(sValue) != 0)
			{
				SetClientCookie(client, hRolePref_Blue, "1");
			}

			GetClientCookie(client, hRolePref_Warden, sValue, sizeof(sValue));
			bRolePreference_Warden[client] = (sValue[0] != '\0' && StringToInt(sValue));
			if (strlen(sValue) != 0)
			{
				SetClientCookie(client, hRolePref_Warden, "1");
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if (!cv_Enabled) return;

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	CreateTimer(5.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	MutePlayer(client);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!cv_Enabled) return Plugin_Continue;

	if (!Client_IsIngame(client) || !Client_IsIngame(attacker)) return Plugin_Continue;

	if (bIsFreeday[client] && !IsWarden(attacker))
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	if (!bDisableCriticles && (cv_WardenDeathCrits && !bIsWardenLocked))
	{
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
	}

	if (cv_WardenStabProtection && IsWarden(client))
	{
		new String:sClassName[64];
		GetEntityClassname(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), sClassName, sizeof(sClassName));
		if (StrEqual(sClassName, "tf_weapon_knife") && (damagetype & DMG_CRIT == DMG_CRIT))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (!cv_Enabled || !Client_IsIngame(client)) return;

	if (bVoted[client])
	{
		iVotes--;
	}

	iVoters--;
	iVotesNeeded = RoundToFloor(float(iVoters) * cv_WVotesNeeded);

	if (iVotes >= iVotesNeeded)
	{
		if (cv_WVotesPostAction == 1)
		{
			return;
		}
		FireWardenCall();
	}

	if (IsWarden(client))
	{
		CPrintToChatAll("%t %t", "plugin tag", "warden disconnected");
		PrintCenterTextAll("%t", "warden disconnected center");
		iWarden = -1;
	}

	bHasTalked[client] = false;
	bIsMuted[client] = false;
	bBlockedDoubleJump[client] = false;
	bDisabledAirblast[client] = false;
	bIsRebel[client] = false;
	bIsQueuedFreeday[client] = false;
	iKillcount[client] = 0;
	iFirstKill[client] = 0;
}

public OnPlayerSpawn(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!Client_IsIngame(client)) return;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	bIsRebel[client] = false;

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
						bBlockedDoubleJump[client] = true;
					}
				}
			case TFClass_Pyro:
				{
					if (cv_Airblast)
					{
						AddAttribute(client, "airblast disabled", 1.0);
						bDisabledAirblast[client] = true;
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

			if (bIsQueuedFreeday[client])
			{
				GiveFreeday(client);
			}
		}
	case TFTeam_Blue:
		{
			if (eVoiceannounce_ex && cv_MicCheck)
			{
				if (cv_MicCheckType)
				{
					if (!bHasTalked[client] && !IsVIP(client))
					{
						ChangeClientTeam(client, _:TFTeam_Red);
						CPrintToChat(client, "%t %t", "plugin tag", "microphone unverified");
					}
				}
			}

			if (cv_BlueMute == 2 && !IsWarden(client))
			{
				MutePlayer(client);
			}
		}
	}
}

public OnPlayerHurt(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!Client_IsIngame(client) || !Client_IsIngame(attacker) || attacker == client) return;

	if (bIsFreeday[attacker])
	{
		RemoveFreeday(attacker);
	}

	if (cv_Rebels)
	{
		if (GetClientTeam(attacker) == _:TFTeam_Red && GetClientTeam(client) == _:TFTeam_Blue && !bIsRebel[attacker])
		{
			MarkRebel(attacker);
		}
	}
}

public Action:OnChangeClass(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (bIsFreeday[client])
	{
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public Action:OnPlayerDeathPre(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (Client_IsIngame(client) && Client_IsIngame(client_killer))
	{
		switch (cv_KillFeeds)
		{
			case 1:
				{
					if (GetClientTeam(client_killer) == _:TFTeam_Red)
					{
						SetEventBroadcast(event, true);
					}
				}
			case 2:
				{
					if (GetClientTeam(client_killer) == _:TFTeam_Blue)
					{
						SetEventBroadcast(event, true);
					}
				}
			case 3: SetEventBroadcast(event, true);
		}
	}
}

public OnPlayerDeath(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (Client_IsIngame(client))
	{
		if (bIsFreeday[client])
		{
			RemoveFreeday(client);
			Jail_Log("%N was an active freeday on round.", client);
		}

		if (cv_DeadMute)
		{
			MutePlayer(client);
		}

		if (bDisabledAirblast[client])
		{
			RemoveAttribute(client, "airblast disabled");
			bDisabledAirblast[client] = false;
		}

		if (bBlockedDoubleJump[client])
		{
			RemoveAttribute(client, "no double jump");
			bBlockedDoubleJump[client] = false;
		}

		if (IsWarden(client))
		{
			WardenUnset(client);
			PrintCenterTextAll("%t", "warden killed", client);
		}

		if (cv_Freekillers && Client_IsIngame(client_killer) && client != client_killer)
		{
			if (GetClientTeam(client_killer) == _:TFTeam_Blue)
			{
				if ((iFirstKill[client_killer] + cv_FreekillersTime) >= GetTime())
				{
					if (++iKillcount[client_killer] == cv_FreekillersKills)
					{
						MarkFreekiller(client_killer, true);
					}
				}
				else
				{
					iKillcount[client_killer] = 1;
					iFirstKill[client_killer] = GetTime();
				}
			}
		}
	}

	if (cv_LRSAutomatic && bLRConfigActive)
	{
		if (Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE) == 1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
				{
					LastRequestStart(i, i);
					Jail_Log("%N has received last request for being the last prisoner alive.", i);
				}
			}
		}
	}

	if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) == 1)
	{
		if (cv_RemoveFreedayOnLastGuard)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && bIsFreeday[i])
				{
					RemoveFreeday(i);
				}
			}
		}

		if (!bOneGuardLeft)
		{
			bVoidFreeKills = true;
			bOneGuardLeft = true;
			PrintCenterTextAll("%t", "last guard");
		}
	}
}

public OnRoundStart(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	if (cv_1stDayFreeday && b1stRoundFreeday)
	{
		DoorHandler(OPEN);
		PrintCenterTextAll("1st round freeday");

		new String:s1stDay[255];
		Format(s1stDay, sizeof(s1stDay), "%t", "1st day freeday node");
		SetTextNode(hTextNodes[0], s1stDay, EnumTNPS[0][fCoord_X], EnumTNPS[0][fCoord_Y], EnumTNPS[0][fHoldTime], EnumTNPS[0][iRed], EnumTNPS[0][iGreen], EnumTNPS[0][iBlue], EnumTNPS[0][iAlpha], EnumTNPS[0][iEffect], EnumTNPS[0][fFXTime], EnumTNPS[0][fFadeIn], EnumTNPS[0][fFadeOut]);
		Jail_Log("1st day freeday has been activated.");
	}

	if (bIsMapCompatible)
	{
		if (strlen(sCellOpener) != 0)
		{
			new CellHandler = Entity_FindByName(sCellOpener, "func_button");
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

		if (strlen(sFFButton) != 0)
		{
			new FFButton = Entity_FindByName(sFFButton, "func_button");
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

	if (eTF2WeaponRestrictions && bDifferentWepRestrict)
	{
		WeaponRestrictions_SetConfig(cv_sWeaponConfig);
		bDifferentWepRestrict = false;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!Client_IsIngame(i)) continue;

		switch (GetClientTeam(i))
		{
			case TFTeam_Red: MutePlayer(i);
			case TFTeam_Blue: UnmutePlayer(i);
		}
	}

	iWarden = -1;
	bIsLRInUse = false;
	bActiveRound = true;
}

public OnArenaRoundStart(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_Enabled) return;

	ClearTimer(hTimer_RoundTimer);

	if (cv_RoundTimerStatus)
	{
		iRoundTime = b1stRoundFreeday ? cv_RoundTime_Freeday : cv_RoundTime;
		
		if (iRoundTime != 0)
		{
			hTimer_RoundTimer = CreateTimer(1.0, Timer_Round, INVALID_HANDLE, TIMER_REPEAT);
		}
	}

	bIsWardenLocked = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreeday[i] && !IsPlayerAlive(i))
		{
			ChangeClientTeam(i, _:TFTeam_Red);
			TF2_RespawnPlayer(i);
		}
	}

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
			if (Client_IsIngame(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				if (cv_PrefStatus && bRolePreference_Blue[i])
				{
					continue;
				}

				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);

				CPrintToChat(i, "%t %t", "plugin tag", "moved for balance");
				Jail_Log("%N has been moved to prisoners team for balance.", i);
			}
		}
	}

	if (bIsMapCompatible && cv_DoorOpenTimer != 0.0)
	{
		new autoopen = RoundFloat(cv_DoorOpenTimer);
		hTimer_OpenCells = CreateTimer(cv_DoorOpenTimer, Open_Doors, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		CPrintToChatAll("%t %t", "plugin tag", "cell doors open start", autoopen);
		Jail_Log("Cell doors are being auto opened via automatic timer.");
		bCellsOpened = true;
	}

	switch (cv_RedMute)
	{
	case 2:
		{
			CPrintToChatAll("%t %t", "plugin tag", "red team muted");
			Jail_Log("Red team has been muted permanently this round.");
		}
	case 1:
		{
			new time = RoundFloat(cv_RedMuteTime);
			CPrintToChatAll("%t %t", "plugin tag", "red team muted temporarily", time);
			CreateTimer(cv_RedMuteTime, UnmuteReds, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
			Jail_Log("Red team has been temporarily muted and will wait %s seconds to be unmuted.", time);
		}
	case 0:
		{
			CPrintToChatAll("%t %t", "plugin tag", "red mute system disabled");
			Jail_Log("Mute system has been disabled this round, nobody has been muted.");
		}
	}

	if (iLRCurrent != -1)
	{
		SetArrayCell(hLastRequestUses, iLRCurrent, GetArrayCell(hLastRequestUses, iLRCurrent) + 1);

		new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(hConfig, sLRConfig);

		new String:sLastRequestID[255];
		IntToString(iLRCurrent, sLastRequestID, sizeof(sLastRequestID));

		if (KvJumpToKey(hConfig, sLastRequestID))
		{
			if (strlen(sCustomLR) == 0)
			{
				new String:sLRName[255], String:sLRMessage[255];
				KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));
				Format(sLRMessage, sizeof(sLRMessage), "%t", "last request node", sLRName);
				SetTextNode(hTextNodes[1], sLRMessage, EnumTNPS[1][fCoord_X], EnumTNPS[1][fCoord_Y], EnumTNPS[1][fHoldTime], EnumTNPS[1][iRed], EnumTNPS[1][iGreen], EnumTNPS[1][iBlue], EnumTNPS[1][iAlpha], EnumTNPS[1][iEffect], EnumTNPS[1][fFXTime], EnumTNPS[1][fFadeIn], EnumTNPS[1][fFadeOut]);
			}

			new bool:IsFreedayRound = false;

			new String:sHandler[PLATFORM_MAX_PATH];
			KvGetString(hConfig, "Handler", sHandler, sizeof(sHandler));

			Call_StartForward(sFW_OnLastRequestExecute);
			Call_PushString(sHandler);
			Call_Finish();

			new String:sExecute[255];
			if (KvGetString(hConfig, "Execute_Cmd", sExecute, sizeof(sExecute)))
			{
				if (strlen(sExecute) != 0)
				{
					new Handle:pack;
					CreateDataTimer(0.5, ExecuteServerCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackString(pack, sExecute);
				}
			}

			if (eTF2WeaponRestrictions)
			{
				new String:sRestrictions[255];

				if (KvGetString(hConfig, "WeaponsConfig", sRestrictions, sizeof(sRestrictions)))
				{
					if (!StrEqual(sRestrictions, "default"))
					{
						WeaponRestrictions_SetConfig(sRestrictions);
					}
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
					bVoidFreeKills = true;
				}

				if (KvGetNum(hConfig, "TimerStatus", 1) == 0)
				{
					ClearTimer(hTimer_RoundTimer);
				}

				if (KvGetNum(hConfig, "AdminLockWarden", 0) == 1)
				{
					bLockWardenLR = true;
				}

				if (KvGetNum(hConfig, "EnableCriticals", 0) == 0)
				{
					bDisableCriticles = true;
				}

				if (KvJumpToKey(hConfig, "KillWeapons"))
				{
					for (new i = 1; i < MaxClients; i++)
					{
						if (Client_IsIngame(i) && IsPlayerAlive(i))
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
									if (KvGetNum(hConfig, "Blue", 0) == 1 || (KvGetNum(hConfig, "Warden", 0) == 1 && IsWarden(i)))
									{
										StripToMelee(i);
									}
								}
							}

							if (KvGetNum(hConfig, "Melee", 0 == 1))
							{
								TF2_RemoveAllWeapons(i);
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

			new String:sActive[255];
			if (KvGetString(hConfig, "Activated", sActive, sizeof(sActive)))
			{
				if (IsFreedayRound)
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (bIsFreeday[i])
						{
							new String:index_name[MAX_NAME_LENGTH];
							GetClientName(i, index_name, sizeof(index_name));
							ReplaceString(sActive, sizeof(sActive), "{NAME}", index_name);
							CPrintToChatAll("%t %s", "plugin tag", sActive);
						}
					}
				}
				else
				{
					CPrintToChatAll("%t %s", "plugin tag", sActive);
				}
			}
		}
		else
		{
			Jail_Log("Error starting Last Request number %i, couldn't be found in configuration file.", iLRCurrent);
		}
		CloseHandle(hConfig);
	}

	if (strlen(sCustomLR) != 0)
	{
		SetTextNode(hTextNodes[1], sCustomLR, EnumTNPS[1][fCoord_X], EnumTNPS[1][fCoord_Y], EnumTNPS[1][fHoldTime], EnumTNPS[1][iRed], EnumTNPS[1][iGreen], EnumTNPS[1][iBlue], EnumTNPS[1][iAlpha], EnumTNPS[1][iEffect], EnumTNPS[1][fFXTime], EnumTNPS[1][fFadeIn], EnumTNPS[1][fFadeOut]);
		sCustomLR[0] = '\0';
	}

	FindRandomWarden();
}

public OnRoundEnd(Handle:hEvent, const String:sName[], bool:bBroadcast)
{
	if (!cv_Enabled) return;

	ClearTimer(hTimer_RoundTimer);

	if (b1stRoundFreeday)
	{
		b1stRoundFreeday = false;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			UnmutePlayer(i);

			if (bIsFreeday[i])
			{
				RemoveFreeday(i);
			}

			if (bBlockedDoubleJump[i])
			{
				RemoveAttribute(i, "no double jump");
				bBlockedDoubleJump[i] = false;
			}

			if (bDisabledAirblast[i])
			{
				RemoveAttribute(i, "airblast disabled");
				bDisabledAirblast[i] = false;
			}

			if (bHasModel[i])
			{
				RemoveModel(i);
			}

			hTimer_RebelTimers[i] = INVALID_HANDLE;

			for (new x = 0; x < sizeof(hTextNodes); x++)
			{
				if (hTextNodes[x] == INVALID_HANDLE) continue;
				ClearSyncHud(i, hTextNodes[x]);
			}

			if (GetClientMenu(i) != MenuSource_None)
			{
				CancelClientMenu(i, true);
			}
		}
	}

	SetConVarBool(hEngineConVars[0], false);
	SetConVarBool(hEngineConVars[1], false);

	bIsWardenLocked = true;
	bOneGuardLeft = false;
	bActiveRound = false;
	bVoidFreeKills = false;
	iFreedayLimit = 0;
	bLockWardenLR = false;
	bDisableCriticles = false;
	bAdminLockedLR = false;

	ClearTimer(hTimer_OpenCells);
	ClearTimer(hTimer_WardenLock);
	ClearTimer(hTimer_FriendlyFireEnable);

	if (iLRCurrent != -1)
	{
		new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(hConfig, sLRConfig);

		new String:sLastRequestID[255];
		IntToString(iLRCurrent, sLastRequestID, sizeof(sLastRequestID));

		if (KvJumpToKey(hConfig, sLastRequestID))
		{
			new String:sExecute[255];
			if (KvGetString(hConfig, "Ending_Cmd", sExecute, sizeof(sExecute)))
			{
				if (strlen(sExecute) != 0)
				{
					new Handle:pack;
					CreateDataTimer(0.5, ExecuteServerCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackString(pack, sExecute);
				}
			}
		}
		else
		{
			Jail_Log("Error ending Last Request number %i, couldn't be found in configuration file.", iLRCurrent);
		}
		CloseHandle(hConfig);
	}

	iLRCurrent = -1;
	if (iLRPending != -1)
	{
		iLRCurrent = iLRPending;
		iLRPending = -1;
	}
}

public OnRegeneration(Handle:event, const String:sName[], bool:dontBroadcast)
{
	RequestFrame(ManageWeapons, GetEventInt(event, "userid"));
}

public OnEntityCreated(entity, const String:sClassName[])
{
	if (!cv_Enabled) return;
		
	if (StrContains(sClassName, "tf_ammo_pack", false) != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	if (cv_KillPointServerCommand && StrContains(sClassName, "point_servercommand", false) != -1)
	{
		RequestFrame(KillEntity, EntIndexToEntRef(entity));
	}
}

public OnClientSayCommand_Post(client, const String:sCommand[], const String:sArgs[])
{
	if (client == iCustom)
	{
		strcopy(sCustomLR, sizeof(sCustomLR), sArgs);
		CPrintToChat(client, "%t %t", "plugin tag", "last request custom set", sCustomLR);
		Jail_Log("Custom LR set to %s by client %N.", sCustomLR, client);
		iCustom = -1;
	}
}

public bool:OnClientSpeakingEx(client)
{
	if (cv_Enabled && eVoiceannounce_ex && cv_MicCheck && !bHasTalked[client])
	{
		bHasTalked[client] = true;
		CPrintToChat(client, "%t %t", "plugin tag", "microphone verified");
	}
}

public WeaponRestrictions_OnExecuted(client)
{
	if (Client_IsIngame(client) && IsPlayerAlive(client))
	{
		StripToMelee(client);
	}
}

/* Player Commands ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:Command_FireWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_WVotesStatus)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "fire warden disabled");
		return Plugin_Handled;
	}

	if (!WardenExists())
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "no warden current");
		return Plugin_Handled;
	}

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (cv_WVotesPassedLimit != 0)
	{
		if (iWardenLimit > cv_WVotesPassedLimit)
		{
			CPrintToChat(client, "%t %t", "plugin tag", "warden fire limit reached");
			return Plugin_Handled;
		}

		AttemptFireWarden(client);
	}
	else
	{
		AttemptFireWarden(client);
	}

	return Plugin_Handled;
}

public Action:Command_BecomeWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_Warden)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden disabled");
		return Plugin_Handled;
	}

	if (!Client_IsIngame(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (bAdminLockWarden)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden locked admin");
		return Plugin_Handled;
	}

	if (b1stRoundFreeday || bIsWardenLocked)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden locked");
		return Plugin_Handled;
	}

	if (cv_LRSLockWarden && bLockWardenLR)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden locked lr round");
		return Plugin_Handled;
	}

	if (WardenExists())
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden current", iWarden);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "Target must be alive");
		return Plugin_Handled;
	}

	if (GetClientTeam(client) != _:TFTeam_Blue)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "guards only");
		return Plugin_Handled;
	}

	if (cv_WardenLimit != 0)
	{
		if (iHasBeenWarden[client] > cv_WardenLimit)
		{
			CPrintToChat(client, "%t %t", "plugin tag", "warden limit reached", client, cv_WardenLimit);
			return Plugin_Handled;
		}
	}

	if (cv_MicCheck && !cv_MicCheckType && !bHasTalked[client])
	{
		CPrintToChat(client, "%t %t", "plugin tag", "microphone check warden block");
		return Plugin_Handled;
	}

	if (bLockedFromWarden[client])
	{
		CPrintToChat(client, "%t %t", "plugin tag", "voted off of warden");
		return Plugin_Handled;
	}

	if (cv_PrefStatus && !bRolePreference_Warden[client])
	{
		CPrintToChat(client, "%t %t", "plugin tag", "preference set against guards or warden");
		return Plugin_Handled;
	}

	if (cv_AdminFlags && !CheckCommandAccess(client, "TF2Jail_WardenOverride", ADMFLAG_RESERVATION))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden incorrect flags");
		return Plugin_Handled;
	}

	WardenSet(client);

	return Plugin_Handled;
}

public Action:Command_ExitWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	CPrintToChatAll("%t %t", "plugin tag", "warden retired", client);
	PrintCenterTextAll("%t", "warden retired center");
	WardenUnset(client);

	return Plugin_Handled;
}

public Action:Command_WardenMenu(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	WardenMenu(client);

	return Plugin_Handled;
}

public Action:Command_OpenCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_DoorControl)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "door controls disabled");
		return Plugin_Handled;
	}

	if (!bIsMapCompatible)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	DoorHandler(OPEN);
	Jail_Log("%N has opened the cell doors using door controls as Warden.", client);

	return Plugin_Handled;
}

public Action:Command_CloseCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_DoorControl)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "door controls disabled");
		return Plugin_Handled;
	}

	if (!bIsMapCompatible)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	DoorHandler(CLOSE);
	Jail_Log("%N has closed the cell doors using door controls as Warden.", client);

	return Plugin_Handled;
}

public Action:Command_EnableFriendlyFire(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_WardenFF)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden friendly fire manage disabled");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	if (cv_WardenRequest)
	{
		CPrintToChatAll("%t %t", "plugin tag", "friendlyfire request");
		EnumWardenMenu = FriendlyFire;
		return Plugin_Handled;
	}

	switch (GetConVarBool(hEngineConVars[0]))
	{
		case true:
			{
				SetConVarBool(hEngineConVars[0], false);
				CPrintToChatAll("%t %t", "plugin tag", "friendlyfire disabled", iWarden);
				Jail_Log("%N has disabled friendly fire as Warden.", iWarden);
			}
		case false:
			{
				SetConVarBool(hEngineConVars[0], true);
				CPrintToChatAll("%t %t", "plugin tag", "friendlyfire enabled", iWarden);
				Jail_Log("%N has enabled friendly fire as Warden.", iWarden);
			}
	}

	return Plugin_Handled;
}

public Action:Command_EnableCollisions(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_WardenCC)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden collision manage disabled");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	if (cv_WardenRequest)
	{
		CPrintToChatAll("%t %t", "plugin tag", "collision request");
		EnumWardenMenu = Collision;
		return Plugin_Handled;
	}

	switch (GetConVarBool(hEngineConVars[1]))
	{
		case true:
			{
				SetConVarBool(hEngineConVars[1], false);
				CPrintToChatAll("%t %t", "plugin tag", "collision disabled", iWarden);
				Jail_Log("%N has disabled collision as Warden.", iWarden);
			}
		case false:
			{
				SetConVarBool(hEngineConVars[1], true);
				CPrintToChatAll("%t %t", "plugin tag", "collision enabled", iWarden);
				Jail_Log("%N has enabled collision as Warden.", iWarden);
			}
	}

	return Plugin_Handled;
}

public Action:Command_GiveLastRequest(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_LRSEnabled)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "lr system disabled");
		return Plugin_Handled;
	}

	if (!bLRConfigActive)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (bAdminLockedLR)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "force lr locked");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	if (bIsLRInUse)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "last request in use");
		return Plugin_Handled;
	}

	if (IsVoteInProgress()) return Plugin_Handled;

	new Handle:hMenu = CreateMenu(MenuHandle_ForceLR);
	SetMenuTitle(hMenu,"%s", "choose a player");

	new String:sUserID[12], String:sDisplay[MAX_NAME_LENGTH+12];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sDisplay, sizeof(sDisplay), "%L", i);
			AddMenuItem(hMenu, sUserID, sDisplay);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	Jail_Log("%N is giving someone a last request...", client);

	return Plugin_Handled;
}

public Action:Command_RemoveLastRequest(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_LRSEnabled)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "lr system disabled");
		return Plugin_Handled;
	}

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (!IsWarden(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Handled;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			bIsQueuedFreeday[i] = false;
		}
	}

	bIsLRInUse = false;
	iLRPending = -1;
	CReplyToCommand(client, "%t %t", "plugin tag", "warden removed lr");
	Jail_Log("%N has cleared all last requests currently queued.", client);

	return Plugin_Handled;
}

public Action:Command_CurrentLastRequest(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_LRSEnabled)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "lr system disabled");
		return Plugin_Handled;
	}

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (iLRCurrent == -1)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "no current last requests");
		return Plugin_Handled;
	}

	new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");

	if (FileToKeyValues(hConfig, sLRConfig))
	{
		new String:sLastRequestID[255];
		IntToString(iLRCurrent, sLastRequestID, sizeof(sLastRequestID));

		if (KvJumpToKey(hConfig, sLastRequestID))
		{
			new String:sLRID[64], String:sLRName[255];
			KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
			KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));
			CReplyToCommand(client, "%t %t", "plugin tag", "current last requests", sLRName, sLRID);
		}
	}
	CloseHandle(hConfig);

	return Plugin_Handled;
}

public Action:Command_ListLastRequests(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_LRSEnabled)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "lr system disabled");
		return Plugin_Handled;
	}

	if (!bLRConfigActive)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	ListLastRequests(client);
	return Plugin_Handled;
}

public Action:Command_CurrentWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!cv_Warden)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden disabled");
		return Plugin_Handled;
	}

	CReplyToCommand(client, "%t %t", "plugin tag", WardenExists() ? "warden current" : "no warden current", iWarden);

	return Plugin_Handled;
}

new String:sWardenModel[MAXPLAYERS + 1][64];

public Action:Command_WardenModel(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!cv_WardenModelMenu) return Plugin_Handled;
	
	if (IsVoteInProgress()) return Plugin_Handled;
	
	switch (DisplayMenu(hWardenModelsMenu, client, MENU_TIME_FOREVER))
	{
		case true: CPrintToChat(client, "%t %t", "plugin tag", "warden model information", sWardenModel[client]);
		case false: CPrintToChat(client, "%t %t", "plugin tag", "warden model missing menu");
	}

	return Plugin_Handled;
}

/* Admin Commands ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:AdminRemoveWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!WardenExists())
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "no warden current");
		return Plugin_Handled;
	}

	PrintCenterTextAll("%t", "warden fired center");
	CShowActivity2(client, "plugin tag", "%t", "Admin Remove Warden", client, iWarden);
	Jail_Log("%N has removed %N's Warden status with admin.", client, iWarden);
	WardenUnset(iWarden);

	return Plugin_Handled;
}

public Action:AdminPardonFreekiller(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_Freekillers)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "freekillers system disabled");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		new String:sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		new target = FindTarget(client, sArg, true);

		if (!Client_IsIngame(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
			return Plugin_Handled;
		}

		if (!bIsFreekiller[target])
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "not freekiller", target);
			return Plugin_Handled;
		}

		ClearFreekiller(target);
		Jail_Log("%N has cleared %N as a Freekiller.", target, client);
	}

	PardonFreekillersMenu(client);
	return Plugin_Handled;
}

public Action:AdminPardonAllFreekillers(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_Freekillers)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "freekillers system disabled");
		return Plugin_Handled;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreekiller[i])
		{
			ClearFreekiller(i);
			Jail_Log("%N has cleared %N as a Freekiller.", i, client);
		}
	}

	CShowActivity2(client, "plugin tag", "%t", "Admin Pardon Freekillers");
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!Client_IsIngame(i)) continue;

		if (bIsQueuedFreeday[i])
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "admin removed freeday");
			bIsQueuedFreeday[i] = false;
		}

		if (bIsFreeday[i])
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "admin removed freeday active");
			bIsFreeday[i] = false;
		}

		if (hTextNodes[1] != INVALID_HANDLE)
		{
			ClearSyncHud(i, hTextNodes[1]);
		}
	}

	bIsLRInUse = false;

	iLRPending = -1;
	iLRCurrent = -1;

	CShowActivity2(client, "plugin tag", "%t", "Admin Deny Last Request");
	Jail_Log("%N has denied all currently queued last requests and reset the last request system.", client);

	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(OPEN);
	CShowActivity2(client, "plugin tag", "%t", "Admin Open Cells");
	Jail_Log("%N has opened the cells using admin.", client);

	return Plugin_Handled;
}

public Action:AdminCloseCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(CLOSE);
	CShowActivity2(client, "plugin tag", "%t", "Admin Close Cells");
	Jail_Log("%N has closed the cells using admin.", client);

	return Plugin_Handled;
}

public Action:AdminLockCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(LOCK);
	CShowActivity2(client, "plugin tag", "%t", "Admin Lock Cells");
	Jail_Log("%N has locked the cells using admin.", client);

	return Plugin_Handled;
}

public Action:AdminUnlockCells(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(UNLOCK);
	CShowActivity2(client, "plugin tag", "%t", "Admin Unlock Cells");
	Jail_Log("%N has unlocked the cells using admin.", client);

	return Plugin_Handled;
}

public Action:AdminForceWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (WardenExists())
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden exists", iWarden);
		return Plugin_Handled;
	}

	if (args > 0)
	{
		new String:sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		new target = FindTarget(client, sArg, true);

		if (!Client_IsIngame(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
			return Plugin_Handled;
		}

		if (!IsPlayerAlive(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Target must be alive");
			return Plugin_Handled;
		}

		if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) < 2)
		{
			WardenSet(target);
			CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden", target);
			Jail_Log("%N has forced a %N Warden.", client, target);
			return Plugin_Handled;
		}

		if (cv_PrefStatus)
		{
			if (cv_PrefForce)
			{
				WardenSet(target);
				CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden", target);
				Jail_Log("%N has forced a %N Warden.", client, target);
				return Plugin_Handled;
			}

			if (bRolePreference_Warden[target])
			{
				WardenSet(target);
				CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden", target);
				Jail_Log("%N has forced a %N Warden.", client, target);
			}
			else
			{
				CReplyToCommand(client, "%t %t", "plugin tag", "Admin Force Warden Not Preferred", target);
				Jail_Log("%N has their preference set to prisoner only, finding another client...", target);
			}
			return Plugin_Handled;
		}

		WardenSet(target);
		CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden", target);
		Jail_Log("%N has forced a %N Warden.", client, target);

		return Plugin_Handled;
	}

	FindWardenRandom(client);
	return Plugin_Handled;
}

public Action:AdminForceLR(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		new String:sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		new target = FindTarget(client, sArg, true);

		if (!Client_IsIngame(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
			return Plugin_Handled;
		}

		CShowActivity2(client, "plugin tag", "%t", "Admin Force Last Request", target);
		LastRequestStart(target, client, false, true);
		Jail_Log("%N has gave %N a Last Request by admin.", client, target);

		return Plugin_Handled;
	}

	CShowActivity2(client, "plugin tag", "%t", "Admin Force Last Request Self");
	LastRequestStart(client, client, true, true);
	Jail_Log("%N has given his/herself last request using admin.", client);

	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	for (new i = 1; i <= MaxClients; i++)
	{
		bBlockedDoubleJump[i] = false;
		bDisabledAirblast[i] = false;
		bIsMuted[i] = false;
		bIsRebel[i] = false;
		bIsQueuedFreeday[i] = false;
		bIsFreeday[i] = false;
		bIsFreekiller[i] = false;
		bHasTalked[i] = false;
		bLockedFromWarden[i] = false;
		bHasModel[i] = false;

		iFirstKill[i] = 0;
		iKillcount[i] = 0;
		iHasBeenWarden[i] = 0;
	}

	bCellsOpened = false;
	b1stRoundFreeday = false;
	bVoidFreeKills = false;
	bIsLRInUse = false;
	bIsWardenLocked = false;
	bOneGuardLeft = false;
	bLateLoad = false;
	bLockWardenLR = false;
	bDisableCriticles = false;
	bAdminLockedLR = false;

	iWarden = -1;
	iWardenLimit = 0;
	iFreedayLimit = 0;

	EnumWardenMenu = Open;

	ParseConfigs();
	ParseLastRequestConfig();
	BuildMenus();

	CReplyToCommand(client, "%t %t", "plugin tag", "Admin Reset Plugin");
	Jail_Log("%N has reset the plugin of all its bools, integers and floats.", client);

	return Plugin_Handled;
}

public Action:AdminMapCompatibilityCheck(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (strlen(sCellNames) != 0)
	{
		new cell_door = Entity_FindByName(sCellNames, "func_door");
		CReplyToCommand(client, "%t %t", "plugin tag", Entity_IsValid(cell_door) ? "Map Compatibility Cell Doors Detected" : "Map Compatibility Cell Doors Undetected");
	}

	if (strlen(sCellOpener) != 0)
	{
		new open_cells = Entity_FindByName(sCellOpener, "func_button");
		CReplyToCommand(client, "%t %t", "plugin tag", Entity_IsValid(open_cells) ? "Map Compatibility Cell Opener Detected" : "Map Compatibility Cell Opener Undetected");
	}

	CShowActivity2(client, "plugin tag", "%t", "Admin Scan Map Compatibility");
	Jail_Log("%N has checked the map for compatibility.", client);

	return Plugin_Handled;
}

public Action:AdminGiveFreeday(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		new String:sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		new target = FindTarget(client, sArg, true);

		if (!Client_IsIngame(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
			return Plugin_Handled;
		}

		if (bIsFreeday[target])
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "currently a freeday");
			return Plugin_Handled;
		}

		CShowActivity2(client, "plugin tag", "%t", "Admin Give Freeday", target);
		GiveFreeday(target);
		Jail_Log("%N has given %N a Freeday.", target, client);

		return Plugin_Handled;
	}

	GiveFreedaysMenu(client);
	return Plugin_Handled;
}

public Action:AdminRemoveFreeday(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		new String:sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		new target = FindTarget(client, sArg, true);

		if (!Client_IsIngame(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
			return Plugin_Handled;
		}

		if (!bIsFreeday[target])
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "not freeday");
			return Plugin_Handled;
		}

		CShowActivity2(client, "plugin tag", "%t", "Admin Remove Freeday", target);
		RemoveFreeday(target);
		Jail_Log("%N has given %N a Freeday.", target, client);

		return Plugin_Handled;
	}

	RemoveFreedaysMenu(client);
	return Plugin_Handled;
}

public Action:AdminAcceptWardenChange(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	switch (EnumWardenMenu)
	{
	case Open: CReplyToCommand(client, "%t %t", "plugin tag", "no warden requests queued");
	case FriendlyFire:
		{
			SetConVarBool(hEngineConVars[0], true);
			CShowActivity2(client, "plugin tag", "%t", "Admin Accept Request FF", iWarden);
			CPrintToChatAll("%t %t", "plugin tag", "friendlyfire enabled");
			Jail_Log("%N has accepted %N's request to enable Friendly Fire.", client, iWarden);
		}
	case Collision:
		{
			SetConVarBool(hEngineConVars[1], true);
			CShowActivity2(client, "plugin tag", "%t", "Admin Accept Request CC", iWarden);
			CPrintToChatAll("%t %t", "plugin tag", "collision enabled");
			Jail_Log("%N has accepted %N's request to enable Collision.", client, iWarden);
		}
	}
	return Plugin_Handled;
}

public Action:AdminCancelWardenChange(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	switch (EnumWardenMenu)
	{
	case Open: CReplyToCommand(client, "%t %t", "plugin tag", "no warden requests active");
	case FriendlyFire:
		{
			SetConVarBool(hEngineConVars[0], false);
			CShowActivity2(client, "plugin tag", "%t", "Admin Cancel Active FF");
			CPrintToChatAll("%t %t", "plugin tag", "friendlyfire disabled");
			Jail_Log("%N has cancelled %N's request for Friendly Fire.", client, iWarden);
		}
	case Collision:
		{
			SetConVarBool(hEngineConVars[1], false);
			CShowActivity2(client, "plugin tag", "%t", "Admin Cancel Active CC");
			CPrintToChatAll("%t %t", "plugin tag", "collision disabled");
			Jail_Log("%N has cancelled %N's request for Collision.", client, iWarden);
		}
	}

	EnumWardenMenu = Open;

	return Plugin_Handled;
}

public Action:AdminLockWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (bAdminLockWarden)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden already locked");
		return Plugin_Handled;
	}

	if (WardenExists())
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && IsWarden(i))
			{
				WardenUnset(i);
			}
		}
	}

	bAdminLockWarden = true;
	CShowActivity2(client, "plugin tag", "%t", "Admin Lock Warden");
	Jail_Log("%N has locked Warden via administration.", client);

	return Plugin_Handled;
}

public Action:AdminUnlockWarden(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!bAdminLockWarden)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden not locked");
		return Plugin_Handled;
	}

	bAdminLockWarden = false;
	CShowActivity2(client, "plugin tag", "%t", "Admin Unlock Warden");
	Jail_Log("%N has unlocked Warden via administration.", client);

	return Plugin_Handled;
}

public Action:AdminMarkFreekiller(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;

	if (!cv_Freekillers)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "freekillers system disabled");
		return Plugin_Handled;
	}

	if (args <= 0)
	{
		CReplyToCommand(client, "%s Usage: sm_markfreekiller <ip|#userid|name>", "plugin tag");
		return Plugin_Handled;
	}

	new String:sArg[64];
	GetCmdArgString(sArg, sizeof(sArg));

	new target = FindTarget(client, sArg, true);

	if (!Client_IsIngame(target))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
		return Plugin_Handled;
	}

	if (bIsFreekiller[target])
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "current freekiller");
		return Plugin_Handled;
	}

	CShowActivity2(client, "plugin tag", "%t", "Admin Mark Freekiller", target);
	MarkFreekiller(target);
	Jail_Log("%L has marked %L as a Free Killer.", client, target);

	return Plugin_Handled;
}

/* Menu Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

PardonFreekillersMenu(client)
{
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return;
	}

	if(IsVoteInProgress()) return;

	new Handle:hMenu = CreateMenu(MenuHandle_PardonFreekillers);
	SetMenuTitle(hMenu, "%s", "choose a player");

	new String:sUserID[12], String:sName[MAX_NAME_LENGTH+12];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreekiller[i])
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sName, sizeof(sName), "%L", i);
			AddMenuItem(hMenu, sUserID, sName);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	CShowActivity2(client, "plugin tag", "%t", "Admin Pardon Freekiller Menu");
	Jail_Log("%N has pardoned someone currently marked Freekillers...", client);
}

public MenuHandle_PardonFreekillers(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new target = GetClientOfUserId(StringToInt(sInfo));
			if (!Client_IsIngame(target))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
				PardonFreekillersMenu(param1);
				return;
			}
				
			ClearFreekiller(target);
			Jail_Log("%N has cleared %N as a Freekiller.", target, param1);

			PardonFreekillersMenu(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

GiveFreedaysMenu(client)
{
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return;
	}

	if(IsVoteInProgress()) return;

	new Handle:hMenu = CreateMenu(MenuHandle_FreedayAdmins);
	SetMenuTitle(hMenu, "%s", "choose a player");

	new String:sUserID[12], String:sDisplay[MAX_NAME_LENGTH+12];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !bIsFreeday[i])
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sDisplay, sizeof(sDisplay), "%L", i);
			AddMenuItem(hMenu, sUserID, sDisplay);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	CShowActivity2(client, "plugin tag", "%t", "Admin Give Freeday Menu");
	Jail_Log("%N is giving someone a freeday...", client);
}

public MenuHandle_FreedayAdmins(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new target = GetClientOfUserId(StringToInt(sInfo));
			if (!Client_IsIngame(target))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
				GiveFreedaysMenu(param1);
				return;
			}
				
			GiveFreeday(target);
			Jail_Log("%N has given %N a Freeday.", target, param1);

			GiveFreedaysMenu(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

RemoveFreedaysMenu(client)
{
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return;
	}

	if (IsVoteInProgress()) return;

	new Handle:hMenu = CreateMenu(MenuHandle_RemoveFreedays);
	SetMenuTitle(hMenu, "%s", "choose a player");

	new String:sUserID[12], String:sName[MAX_NAME_LENGTH+12];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreeday[i])
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sName, sizeof(sName), "%L", i);
			AddMenuItem(hMenu, sUserID, sName);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	CShowActivity2(client, "plugin tag", "%t", "Admin Remove Freeday Menu");
	Jail_Log("%N is removing someone's freeday status...", client);
}

public MenuHandle_RemoveFreedays(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new target = GetClientOfUserId(StringToInt(sInfo));

			if (!Client_IsIngame(target))
			{
				CReplyToCommand(param1, "%t %t", "plugin tag", "Player no longer available");
				return;
			}

			if (!bIsFreeday[target])
			{
				CReplyToCommand(param1, "%t %t", "plugin tag", "lr freeday removed invalid", target);
				RemoveFreedaysMenu(param1);
				return;
			}
				
			RemoveFreeday(target);
			Jail_Log("%N has removed %N's Freeday.", param1, target);

			RemoveFreedaysMenu(param1);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

WardenMenu(client)
{
	if (IsVoteInProgress()) return;
	DisplayMenu(hWardenMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_WardenMenu(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			if (!IsWarden(param1))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "not warden");
				return;
			}

			FakeClientCommandEx(param1, sInfo);
			WardenMenu(param1);
		}
	}
}

public MenuHandle_ForceLR(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new target = GetClientOfUserId(StringToInt(sInfo));

			if (!Client_IsIngame(target))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
				return;
			}

			if (!IsWarden(param1))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "not warden");
				return;
			}

			if (GetClientTeam(target) != _:TFTeam_Red)
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "prisoners only");
				return;
			}

			LastRequestStart(target, param1);
			CPrintToChatAll("%t %t", "plugin tag", "last request given", iWarden, target);
			Jail_Log("%N has given %N a Last Request as Warden.", param1, target);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public MenuHandle_WardenModels(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			strcopy(sWardenModel[param1], sizeof(sWardenModel[]), sInfo);
			CPrintToChat(param1, "%t %t", "plugin tag", "warden model set", sWardenModel[param1]);
		}
	}
}

ListLastRequests(client)
{
	if (IsVoteInProgress()) return;
	DisplayMenu(hListLRsMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_ListLRs(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[255];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");
			FileToKeyValues(hConfig, sLRConfig);

			if (KvGotoFirstSubKey(hConfig))
			{
				new String:sSectionIDs[255];
				do {
					KvGetSectionName(hConfig, sSectionIDs, sizeof(sSectionIDs));
					if (StrEqual(sSectionIDs, sInfo))
					{
						new String:sDescription[256];
						KvGetString(hConfig, "Description", sDescription, sizeof(sDescription));

						if (strlen(sDescription) != 0)
						{
							CPrintToChat(param1, "%t %s", "plugin tag", sDescription);
						}
						else
						{
							CPrintToChat(param1, "%t %t", "plugin tag", "no description available");
						}
					}
				} while (KvGotoNextKey(hConfig));
			}
			CloseHandle(hConfig);

			ListLastRequests(param1);
		}
	}
}

FreedayforClientsMenu(client, bool:active = false, bool:rep = false)
{
	if (IsVoteInProgress()) return;

	new Handle:hMenu;

	switch (active)
	{
		case true: hMenu = CreateMenu(MenuHandle_FreedayForClientsActive);
		case false: hMenu = CreateMenu(MenuHandle_FreedayForClients);
	}

	SetMenuTitle(hMenu, "%s", "choose a player");
	SetMenuExitBackButton(hMenu, false);

	new String:sUserID[12], String:sName[MAX_NAME_LENGTH+12];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			if (active) if (!IsPlayerAlive(i)) continue;

			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sName, sizeof(sName), "%L", i);
			AddMenuItem(hMenu, sUserID, sName);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	if (rep) CPrintToChatAll("%t %t", "plugin tag", "lr freeday picking clients", client);
}

public MenuHandle_FreedayForClients(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new target = GetClientOfUserId(StringToInt(sInfo));

			if (Client_IsIngame(param1))
			{
				if (!Client_IsIngame(target))
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
					FreedayforClientsMenu(param1);
				}

				if (bIsQueuedFreeday[target])
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "freeday currently queued", target);
				}
				else
				{
					if (iFreedayLimit < cv_FreedayLimit)
					{
						bIsQueuedFreeday[target] = true;
						iFreedayLimit++;
						CPrintToChatAll("%t %t", "plugin tag", "lr freeday picked clients", param1, target);
					}
					else
					{
						CPrintToChatAll("%t %t", "plugin tag", "lr freeday picked clients maxed", param1);
					}
				}

				FreedayforClientsMenu(param1);
			}
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				LastRequestStart(param1);
			}
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public MenuHandle_FreedayForClientsActive(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new target = GetClientOfUserId(StringToInt(sInfo));

			if (Client_IsIngame(param1))
			{
				if (!Client_IsIngame(target))
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
					FreedayforClientsMenu(param1, true);
				}

				if (bIsFreeday[target])
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "freeday currently queued", target);
				}
				else
				{
					if (iFreedayLimit < cv_FreedayLimit)
					{
						GiveFreeday(param1);
						iFreedayLimit++;
						CPrintToChatAll("%t %t", "plugin tag", "lr freeday picked clients", param1, target);
					}
					else
					{
						CPrintToChatAll("%t %t", "plugin tag", "lr freeday picked clients maxed", param1);
					}
				}

				FreedayforClientsMenu(param1, true);
			}
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				LastRequestStart(param1);
			}
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

PreferenceMenu(client)
{
	if (IsVoteInProgress()) return;
	
	new Handle:hMenu = CreateMenu(MenuHandle_Preferences);
	SetMenuTitle(hMenu, "%s", "preferences title");

	new String:sValue[64];

	Format(sValue, sizeof(sValue), "%s", bRolePreference_Blue[client] ? "Blue Preference [ON]" : "Blue Preference [OFF]");
	AddMenuItem(hMenu, "Pref_Blue", sValue, cv_PrefBlue ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(sValue, sizeof(sValue), "%s", bRolePreference_Warden[client] ? "Warden Preference [ON]" : "Warden Preference [OFF]");
	AddMenuItem(hMenu, "Pref_Warden", sValue, cv_PrefWarden ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_Preferences(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			if (StrEqual(sInfo, "Pref_Blue"))
			{
				if (cv_PrefBlue)
				{
					if (!bRolePreference_Blue[param1])
					{
						SetClientCookie(param1, hRolePref_Blue, "1");
						bRolePreference_Blue[param1] = true;
						CPrintToChat(param1, "%t %t", "plugin tag", "preference blue on");
					}
					else
					{
						SetClientCookie(param1, hRolePref_Blue, "0");
						bRolePreference_Blue[param1] = false;
						CPrintToChat(param1, "%t %t", "plugin tag", "preference blue off");
					}
				}
			}
			else if (StrEqual(sInfo, "Pref_Warden"))
			{
				if (cv_PrefWarden)
				{
					if (!bRolePreference_Warden[param1])
					{
						SetClientCookie(param1, hRolePref_Warden, "1");
						bRolePreference_Warden[param1] = true;
						CPrintToChat(param1, "%t %t", "plugin tag", "preference warden on");
					}
					else
					{
						SetClientCookie(param1, hRolePref_Warden, "0");
						bRolePreference_Warden[param1] = false;
						CPrintToChat(param1, "%t %t", "plugin tag", "preference warden off");
					}
				}
			}
			PreferenceMenu(param1);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowCookieMenu(param1);
			}
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

LastRequestStart(client, sender = 0, bool:Timer = true, bool:lock = false)
{
	if (IsVoteInProgress()) return;
	
	new Handle:hStartLRMenu = CreateMenu(MenuHandle_GiveLR);
	SetMenuTitle(hStartLRMenu, "%s", "pick last requests");
	SetMenuExitButton(hStartLRMenu, true);
	
	ParseLastRequests(client, hStartLRMenu);
	
	DisplayMenu(hStartLRMenu, client, MENU_TIME_FOREVER);

	if (IsWarden(sender))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden granted lr", sender);
	}
	else if (!sender)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "console granted lr");
	}
	else
	{
		CPrintToChat(client, "%t %t", "plugin tag", "admin granted lr", sender);
	}

	bIsLRInUse = true;

	if (!Timer)
	{
		ClearTimer(hTimer_RoundTimer);
	}

	if (lock)
	{
		CPrintToChatAll("%t %t", "plugin tag", "force lr admin lock", sender, client);
		bAdminLockedLR = true;
	}
}

public MenuHandle_GiveLR(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[255];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");

			if (!FileToKeyValues(hConfig, sLRConfig))
			{
				Jail_Log("Last requests menu seems to be empty, please verify its integrity.");
				CPrintToChatAll("%t %t", "plugin tag", "last request config invalid");
				CloseHandle(hConfig);
				return;
			}

			if (cv_RemoveFreedayOnLR)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && bIsFreeday[i])
					{
						RemoveFreeday(i);
					}
				}
				CPrintToChatAll("%t %t", "plugin tag", "last request freedays removed");
			}

			if (!KvJumpToKey(hConfig, sInfo))
			{
				Jail_Log("Last request ID '%s' not found in the configuration file, please verify integrity of configuration file.", sInfo);
				CloseHandle(hConfig);
				return;
			}

			new String:sAnnounce[255], String:sClientName[MAX_NAME_LENGTH], String:sActive[255];

			GetClientName(param1, sClientName, sizeof(sClientName));

			new String:Handler[128];
			KvGetString(hConfig, "Handler", Handler, sizeof(Handler));

			if (StrEqual(Handler, "LR_Custom"))
			{
				if (KvGetString(hConfig, "Queue_Announce", sAnnounce, sizeof(sAnnounce)))
				{
					ReplaceString(sAnnounce, sizeof(sAnnounce), "{NAME}", sClientName, true);
					CPrintToChatAll("%t %s", "plugin tag", sAnnounce);
				}

				CPrintToChat(param1, "%t %t", "plugin tag", "custom last request message");
				iCustom = param1;

				CloseHandle(hConfig);
				return;
			}

			new bool:ActiveRound = false;
			if (KvJumpToKey(hConfig, "Parameters"))
			{
				ActiveRound = bool:KvGetNum(hConfig, "ActiveRound", 0);
				KvGoBack(hConfig);
			}

			if (ActiveRound)
			{
				if (!bActiveRound)
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "lr cannot pick active round");
					return;
				}

				SetArrayCell(hLastRequestUses, StringToInt(sInfo), GetArrayCell(hLastRequestUses, StringToInt(sInfo)) + 1);

				Call_StartForward(sFW_OnLastRequestExecute);
				Call_PushString(Handler);
				Call_Finish();

				if (KvGetString(hConfig, "Activated", sActive, sizeof(sActive)))
				{
					ReplaceString(sActive, sizeof(sActive), "{NAME}", sClientName, true);
					CPrintToChatAll("%t %s", "plugin tag", sActive);
				}

				new String:sExecute[255];
				if (KvGetString(hConfig, "Execute_Cmd", sExecute, sizeof(sExecute)))
				{
					new String:sIndex[64];
					IntToString(GetClientUserId(param1), sIndex, sizeof(sIndex));
					ReplaceString(sExecute, sizeof(sExecute), "{client}", sIndex);

					if (strlen(sExecute) != 0)
					{
						new Handle:dp;
						CreateDataTimer(0.5, ExecuteServerCommand, dp, TIMER_FLAG_NO_MAPCHANGE);
						WritePackString(dp, sExecute);
					}
				}

				if (eTF2WeaponRestrictions)
				{
					new String:sWeaponsConfig[255];
					if (KvGetString(hConfig, "WeaponsConfig", sWeaponsConfig, sizeof(sWeaponsConfig)))
					{
						if (!StrEqual(sWeaponsConfig, "default"))
						{
							WeaponRestrictions_SetConfig(sWeaponsConfig);
						}
					}
				}

				if (KvJumpToKey(hConfig, "Parameters"))
				{
					switch (KvGetNum(hConfig, "IsFreedayType", 0))
					{
					case 3:	//Freeday For All
						{
							//N/A
						}
					case 2:	//Freeday For Clients
						{
							FreedayforClientsMenu(param1, true, true);
						}
					case 1:	//Freeday for Yourself
						{
							GiveFreeday(param1);
						}
					}

					if (KvGetNum(hConfig, "OpenCells", 0) == 1)
					{
						DoorHandler(OPEN);
					}

					if (KvGetNum(hConfig, "VoidFreekills", 0) == 1)
					{
						bVoidFreeKills = true;
					}

					if (KvGetNum(hConfig, "TimerStatus", 1) == 0)
					{
						ClearTimer(hTimer_RoundTimer);
					}

					if (KvGetNum(hConfig, "AdminLockWarden", 0) == 1)
					{
						bLockWardenLR = true;
					}

					if (KvGetNum(hConfig, "EnableCriticals", 0) == 0)
					{
						bDisableCriticles = true;
					}

					if (KvJumpToKey(hConfig, "KillWeapons"))
					{
						for (new i = 1; i < MaxClients; i++)
						{
							if (Client_IsIngame(i) && IsPlayerAlive(i))
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

								if (KvGetNum(hConfig, "Melee", 0) == 1)
								{
									TF2_RemoveAllWeapons(i);
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

				iLRCurrent = StringToInt(sInfo);
			}
			else
			{
				if (KvJumpToKey(hConfig, "Parameters"))
				{
					switch (KvGetNum(hConfig, "IsFreedayType", 0))
					{
					case 3:	//Freeday For All
						{
							//N/A
						}
					case 2:	//Freeday For Clients
						{
							FreedayforClientsMenu(param1, false, true);
						}
					case 1:	//Freeday For Yourself
						{
							bIsQueuedFreeday[param1] = true;
						}
					}
					KvGoBack(hConfig);
				}

				if (KvGetString(hConfig, "Queue_Announce", sAnnounce, sizeof(sAnnounce)))
				{
					GetClientName(param1, sClientName, sizeof(sClientName));
					ReplaceString(sAnnounce, sizeof(sAnnounce), "{NAME}", sClientName, true);
					CPrintToChatAll("%t %s", "plugin tag", sAnnounce);
				}

				iLRPending = StringToInt(sInfo);
			}
			CloseHandle(hConfig);
		}
	case MenuAction_Cancel:
		{
			if (bActiveRound)
			{
				CPrintToChatAll("%t %t", "plugin tag", "last request closed");
			}
			bIsLRInUse = false;
		}
	case MenuAction_End:
		{
			CloseHandle(hMenu);
			bIsLRInUse = false;
		}
	}
}


/* Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
GiveFreeday(client)
{
	CPrintToChat(client, "%t %t", "plugin tag", "lr freeday message");
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
	if (cv_FreedayTeleports && bFreedayTeleportSet) TeleportEntity(client, iFreedayPosition, NULL_VECTOR, NULL_VECTOR);
	
	if (cv_RendererParticles && strlen(sFreedaysParticle) != 0)
	{
		hParticle_Freedays[client] = CreateParticle(sFreedaysParticle, 999999.0, client, ATTACH_NORMAL);
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iFreedaysColors[0], a_iFreedaysColors[1], a_iFreedaysColors[2], a_iFreedaysColors[3]);

	bIsQueuedFreeday[client] = false;
	bIsFreeday[client] = true;
	Jail_Log("%N has been given a Freeday.", client);

	Call_StartForward(sFW_OnFreedayGiven);
	Call_PushCell(client);
	Call_Finish();
}

RemoveFreeday(client)
{
	CPrintToChatAll("%t %t", "plugin tag", "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	bIsFreeday[client] = false;

	if (hParticle_Freedays[client] != INVALID_HANDLE)
	{
		CloseHandle(hParticle_Freedays[client]);
		hParticle_Freedays[client] = INVALID_HANDLE;
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);

	Jail_Log("%N is no longer a Freeday.", client);

	Call_StartForward(sFW_OnFreedayRemoved);
	Call_PushCell(client);
	Call_Finish();
}

MarkRebel(client)
{
	bIsRebel[client] = true;
	
	if (cv_RendererParticles && strlen(sRebellersParticle) != 0)
	{
		hParticle_Rebels[client] = CreateParticle(sRebellersParticle, 999999.0, client, ATTACH_NORMAL);
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iRebellersColors[0], a_iRebellersColors[1], a_iRebellersColors[2], a_iRebellersColors[3]);

	CPrintToChatAll("%t %t", "plugin tag", "prisoner has rebelled", client);
	if (cv_RebelsTime >= 1.0)
	{
		new time = RoundFloat(cv_RebelsTime);
		CPrintToChat(client, "%t %t", "plugin tag", "rebel timer start", time);
		hTimer_RebelTimers[client] = CreateTimer(cv_RebelsTime, RemoveRebel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	Jail_Log("%N has been marked as a Rebeller.", client);

	Call_StartForward(sFW_OnRebelGiven);
	Call_PushCell(client);
	Call_Finish();
}

MarkFreekiller(client, bool:void = false)
{
	if (void && bVoidFreeKills)
	{
		CPrintToChatAll("%t %t", "plugin tag", "freekiller flagged while void", client);
		return;
	}

	bIsFreekiller[client] = true;
	
	if (cv_RendererParticles && strlen(sFreekillersParticle) != 0)
	{
		hParticle_Freekillers[client] = CreateParticle(sFreekillersParticle, 999999.0, client, ATTACH_NORMAL);
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iFreekillersColors[0], a_iFreekillersColors[1], a_iFreekillersColors[2], a_iFreekillersColors[3]);

	TF2_RemoveAllWeapons(client);
	EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
	CPrintToChatAll("%t %t", "plugin tag", "freekiller timer start", client, RoundFloat(cv_FreekillersWave));

	new String:sAuth[24];
	GetClientAuthString(client, sAuth, sizeof(sAuth[]));

	new String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName[]));

	new Handle:pack;
	hTimer_FreekillingData = CreateDataTimer(cv_FreekillersWave, BanClientTimerFreekiller, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, GetClientUserId(client));
	WritePackString(pack, sAuth);
	WritePackString(pack, sName);

	Jail_Log("%N has been marked as a Freekiller.", client);

	Call_StartForward(sFW_OnFreekillerGiven);
	Call_PushCell(client);
	Call_Finish();
}

ClearFreekiller(client)
{
	bIsFreekiller[client] = false;

	TF2_RegeneratePlayer(client);

	ClearTimer(hTimer_FreekillingData);

	if (hParticle_Freekillers[client] != INVALID_HANDLE)
	{
		CloseHandle(hParticle_Freekillers[client]);
		hParticle_Freekillers[client] = INVALID_HANDLE;
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);

	Jail_Log("%N has been cleared as a Freekiller.", client);

	Call_StartForward(sFW_OnFreekillerRemoved);
	Call_PushCell(client);
	Call_Finish();
}

bool:AlreadyMuted(client)
{
	switch (eSourceComms)
	{
		case true: if (SourceComms_GetClientMuteType(client) != bNot) return true;
		case false: if (BaseComm_IsClientMuted(client)) return true;
	}
	return false;
}

ConvarsSet(bool:Status = false)
{
	if (Status)
	{
		SetConVarInt(FindConVar("mp_stalemate_enable"), 0);
		SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		SetConVarInt(FindConVar("mp_autoteambalance"), 0);
		SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
		SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
		SetConVarInt(FindConVar("phys_pushscale"), 1000);
	}
	else
	{
		SetConVarInt(FindConVar("mp_stalemate_enable"), 1);
		SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);
		SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
		SetConVarInt(FindConVar("mp_scrambleteams_auto"), 1);
	}
}

bool:IsWarden(client)
{
	if (client == iWarden) return true;
	return false;
}

bool:WardenExists()
{
	if (iWarden != -1) return true;
	return false;
}

MutePlayer(client)
{
	if (!AlreadyMuted(client) && !IsVIP(client) && !bIsMuted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		bIsMuted[client] = true;
		CPrintToChat(client, "%t %t", "plugin tag", "muted player");
	}
}

UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !IsVIP(client) && bIsMuted[client])
	{
		UnmuteClient(client);
		bIsMuted[client] = false;
		CPrintToChat(client, "%t %t", "plugin tag", "unmuted player");
	}
}

ParseLastRequests(client, Handle:hMenu)
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");

	if (FileToKeyValues(hConfig, sLRConfig) && KvGotoFirstSubKey(hConfig))
	{
		new String:sLRID[64], String:sLRName[255];
		do {
			new bool:IsDisabled = false;
			KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
			KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));

			if (KvJumpToKey(hConfig, "Parameters"))
			{
				new disabled = KvGetNum(hConfig, "Disabled", 0);
				new CurrentUses = GetArrayCell(hLastRequestUses, StringToInt(sLRID));
				new Permitted = KvGetNum(hConfig, "UsesPerMap", 3);

				switch (disabled)
				{
				case 1: Format(sLRName, sizeof(sLRName), "[Disabled] %s", sLRName);
				case 0: Format(sLRName, sizeof(sLRName), "[%i/%i] %s", CurrentUses, Permitted, sLRName);
				}

				new bool:VIPCheck = false, bool:GrantAccess = false;
				if (KvGetNum(hConfig, "IsVIPOnly", 0) == 1)
				{
					VIPCheck = true;
					Format(sLRName, sizeof(sLRName), "%s [VIP]", sLRName);

					if (IsVIP(client))
					{
						GrantAccess = true;
					}
				}

				if (Permitted > 0 && CurrentUses >= Permitted || disabled != 0)
				{
					IsDisabled = true;
				}

				AddMenuItem(hMenu, sLRID, sLRName, !IsDisabled || (VIPCheck && GrantAccess) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				KvGoBack(hConfig);
			}
		} while (KvGotoNextKey(hConfig));
		bLRConfigActive = true;
	}
	else
	{
		bLRConfigActive = false;
	}

	CloseHandle(hConfig);
}

ParseConfigs()
{
	ParseMapConfig();
	ParseNodeConfig();
	ParseLastRequestConfig(true);
	ParseRoleRenderersConfig();
	ParseWardenModelsConfig(true);
}

ParseMapConfig()
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_MapConfig");

	new String:sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/mapconfig.cfg");

	new String:sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	Jail_Log("Loading last request configuration entry for map '%s'...", sMapName);

	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvJumpToKey(hConfig, sMapName))
		{
			new String:CellNames[32], String:CellsButton[32], String:FFButton[32];

			KvGetString(hConfig, "CellNames", CellNames, sizeof(CellNames), "");
			if (strlen(CellNames) != 0)
			{
				new iCelldoors = Entity_FindByName(CellNames, "func_door");
				if (Entity_IsValid(iCelldoors))
				{
					sCellNames = CellNames;
					bIsMapCompatible = true;
				}
				else
				{
					bIsMapCompatible = false;
				}
			}
			else
			{
				bIsMapCompatible = false;
			}

			KvGetString(hConfig, "CellsButton", CellsButton, sizeof(CellsButton), "");
			if (strlen(CellsButton) != 0)
			{
				new iCellOpener = Entity_FindByName(CellsButton, "func_button");
				if (Entity_IsValid(iCellOpener))
				{
					sCellOpener = CellsButton;
				}
			}

			KvGetString(hConfig, "FFButton", FFButton, sizeof(FFButton), "");
			if (strlen(FFButton) != 0)
			{
				new iFFButton = Entity_FindByName(FFButton, "func_button");
				if (Entity_IsValid(iFFButton))
				{
					sCellOpener = FFButton;
				}
			}

			if (KvJumpToKey(hConfig, "Freeday"))
			{
				if (KvJumpToKey(hConfig, "Teleport"))
				{
					bFreedayTeleportSet = (KvGetNum(hConfig, "Status", 1) == 1);

					if (bFreedayTeleportSet)
					{
						KvGetVector(hConfig, "Coordinates", iFreedayPosition);
						Jail_Log("Freeday teleport coordinates set for the map '%s' - X: %d, Y: %d, Z: %d", sMapName, iFreedayPosition[0], iFreedayPosition[1], iFreedayPosition[2]);
					}

					KvGoBack(hConfig);
				}
				else
				{
					bFreedayTeleportSet = false;
					Jail_Log("Could not find subset key for 'Freeday' - 'Teleport', disabling functionality for Freeday Teleportation.");
				}
				KvGoBack(hConfig);
			}
			else
			{
				bFreedayTeleportSet = false;
				Jail_Log("Could not find subset 'Freeday', disabling functionality for Freedays via Map.");
			}
		}
		else
		{
			bIsMapCompatible = false;
			bFreedayTeleportSet = false;
			Jail_Log("Map '%s' is missing from configuration file, please verify integrity of your installation.", sMapName);
		}
	}
	else
	{
		bIsMapCompatible = false;
		bFreedayTeleportSet = false;
		Jail_Log("Configuration file is invalid or not found, please verify integrity of your installation.");
	}

	Jail_Log("Map configuration for '%s' has been parsed and loaded.", sMapName);
	CloseHandle(hConfig);
}

ParseNodeConfig()
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_Nodes");

	new String:sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/textnodes.cfg");

	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvGotoFirstSubKey(hConfig, false))
		{
			new count = 0;
			do
			{
				EnumTNPS[count][fCoord_X] = KvGetFloat(hConfig, "Coord_X", -1.0);
				EnumTNPS[count][fCoord_Y] = KvGetFloat(hConfig, "Coord_Y", -1.0);
				EnumTNPS[count][fHoldTime] = KvGetFloat(hConfig, "HoldTime", 5.0);
				KvGetColor(hConfig, "Color", EnumTNPS[count][iRed], EnumTNPS[count][iGreen], EnumTNPS[count][iBlue], EnumTNPS[count][iAlpha]);
				EnumTNPS[count][iEffect] = KvGetNum(hConfig, "Effect", 0);
				EnumTNPS[count][fFXTime] = KvGetFloat(hConfig, "fxTime", 6.0);
				EnumTNPS[count][fFadeIn] = KvGetFloat(hConfig, "FadeIn", 0.1);
				EnumTNPS[count][fFadeOut] = KvGetFloat(hConfig, "FadeOut", 0.2);

				count++;
			} while (KvGotoNextKey(hConfig, false));
		}
	}
	else
	{
		Jail_Log("Couldn't parse text node configuration file, please verify its integrity.");
	}

	CloseHandle(hConfig);
}

ParseLastRequestConfig(bool:DefaultValue = false)
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_LastRequests");

	new int = 0;
	if (FileToKeyValues(hConfig, sLRConfig))
	{
		if (KvGotoFirstSubKey(hConfig, false))
		{
			do {
				int++;

			} while (KvGotoNextKey(hConfig, false));
		}
	}

	ResizeArray(hLastRequestUses, int);

	if (DefaultValue)
	{
		for (new i = 0; i < GetArraySize(hLastRequestUses); i++)
		{
			SetArrayCell(hLastRequestUses, i, 0);
		}
	}

	CloseHandle(hConfig);
}

ParseRoleRenderersConfig()
{
	new Handle:hConfig = CreateKeyValues("TF2Jail_RoleRenders");

	new String:sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/rolerenderers.cfg");

	if (!FileToKeyValues(hConfig, sConfig))
	{
		Jail_Log("Couldn't parse role renderers configuration file, please verify its integrity.");
		CloseHandle(hConfig);
		return;
	}
	
	SetRoleRender(hConfig, "Warden", a_iWardenColors, sWardenParticle);
	SetRoleRender(hConfig, "Freedays", a_iFreedaysColors, sFreedaysParticle);
	SetRoleRender(hConfig, "Rebellers", a_iRebellersColors, sRebellersParticle);
	SetRoleRender(hConfig, "Freekillers", a_iFreekillersColors, sFreekillersParticle);

	CloseHandle(hConfig);
}

SetRoleRender(Handle:hConfig, const String:sRole[], iColor[4], String:sParticle[64])
{
	if (KvJumpToKey(hConfig, sRole))
	{
		iColor[0] = 255, iColor[1] = 255, iColor[2] = 255, iColor[3] = 255;
		KvGetColor(hConfig, "Color", iColor[0], iColor[1], iColor[2], iColor[3]);
		
		KvGetString(hConfig, "Particle", sParticle, sizeof(sParticle));
		KvGoBack(hConfig);
	}
}

ParseWardenModelsConfig(bool:MenuOnly = false)
{
	if (!MenuOnly)
	{
		ClearTrie(hWardenSkinClasses);
		ClearTrie(hWardenSkins);
	}
	
	if (MenuOnly && hWardenModelsMenu == INVALID_HANDLE)
	{
		return;
	}
	else if (hWardenModelsMenu != INVALID_HANDLE)
	{
		RemoveAllMenuItems(hWardenModelsMenu);
	}
	
	new Handle:hConfig = CreateKeyValues("TF2Jail_WardenModels");
	
	new String:sWardenModelsConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sWardenModelsConfig, sizeof(sWardenModelsConfig), "configs/tf2jail/wardenmodels.cfg");
	FileToKeyValues(hConfig, sWardenModelsConfig);
	
	if (KvGotoFirstSubKey(hConfig, false))
	{
		do {
			new String:sName[64];
			KvGetSectionName(hConfig, sName, sizeof(sName));
			
			new String:sModel[64];
			KvGetString(hConfig, "model", sModel, sizeof(sModel));
			
			new String:sClass[64];
			KvGetString(hConfig, "class", sClass, sizeof(sClass), "none");
			
			if (strlen(sModel) == 0)
			{
				Jail_Log("ERROR: Model for '%s' not set, please add it. Skipping this model.", sName);
				continue;
			}
			
			if (!KvJumpToKey(hConfig, "files"))
			{
				Jail_Log("ERROR: No files set to download for Warden model '%s'. Skipping this model.", sName);
				continue;
			}
			
			if (!KvGotoFirstSubKey(hConfig, false))
			{
				Jail_Log("ERROR: Files subsection is empty for Warden model '%s'. Skipping this model.", sName);
				continue;
			}
			
			switch (FileExists(sModel, true))
			{
			case true:
				{
					if (MenuOnly)
					{
						AddMenuItem(hWardenModelsMenu, sName, sName);
						continue;
					}
					
					AddFileToDownloadsTable(sModel);
					SetTrieString(hWardenSkins, sName, sModel, false);
					AddMenuItem(hWardenModelsMenu, sName, sName);
				}
			case false:
				{
					Jail_Log("ERROR: Main model file is missing for Warden Model '%s'. Skipping this model.", sName);
					continue;
				}
			}
			
			SetTrieString(hWardenSkinClasses, sName, sClass, false);
			
			do {
				new String:sDownload[PLATFORM_MAX_PATH];
				KvGetString(hConfig, NULL_STRING, sDownload, sizeof(sDownload));
				
				switch (FileExists(sDownload, true))
				{
				case true: AddFileToDownloadsTable(sDownload);
				case false: Jail_Log("WARNING: File '%s' is missing for Warden Model '%s'.", sDownload, sName);
				}
			} while (KvGotoNextKey(hConfig, false));
			KvGoBack(hConfig);
			
		} while (KvGotoNextKey(hConfig, false));
	}
	
	CloseHandle(hConfig);
}

BuildMenus()
{
	//Wardens Menu
	if (hWardenMenu != INVALID_HANDLE)
	{
		CloseHandle(hWardenMenu);
		hWardenMenu = INVALID_HANDLE;
	}

	hWardenMenu = CreateMenu(MenuHandle_WardenMenu);
	SetMenuTitle(hWardenMenu, "%s", "warden commands");
	SetMenuExitButton(hWardenMenu, true);

	new Handle:hConfig = CreateKeyValues("WardenMenu");

	new String:sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/wardenmenu.cfg");

	FileToKeyValues(hConfig, sConfig);
	KvGotoFirstSubKey(hConfig, false);
	do {
		new String:sLRID[64], String:sLRName[255];
		KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
		KvGetString(hConfig, NULL_STRING, sLRName, sizeof(sLRName));
		AddMenuItem(hWardenMenu, sLRID, sLRName);
	} while (KvGotoNextKey(hConfig, false));
	CloseHandle(hConfig);
	
	//List of Last Requests Menu
	if (hListLRsMenu != INVALID_HANDLE)
	{
		CloseHandle(hListLRsMenu);
		hListLRsMenu = INVALID_HANDLE;
	}
	
	hListLRsMenu = CreateMenu(MenuHandle_ListLRs);
	SetMenuTitle(hListLRsMenu, "%s", "list last requests");
	SetMenuExitButton(hListLRsMenu, true);

	hConfig = CreateKeyValues("TF2Jail_LastRequests");
	if (FileToKeyValues(hConfig, sLRConfig) && KvGotoFirstSubKey(hConfig))
	{
		new String:sLRID[64], String:sLRName[255];
		do {
			KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
			KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));

			if (KvJumpToKey(hConfig, "Parameters"))
			{
				if (KvGetNum(hConfig, "Disabled", 0) == 1)
				{
					Format(sLRName, sizeof(sLRName), "[Disabled] %s", sLRName);
				}
				else
				{
					new Permitted = KvGetNum(hConfig, "UsesPerMap", 3);
					new CurrentUses = GetArrayCell(hLastRequestUses, StringToInt(sLRID));
					Format(sLRName, sizeof(sLRName), "[%i/%i] %s", CurrentUses, Permitted, sLRName);
				}

				if (KvGetNum(hConfig, "IsVIPOnly", 0) == 1)
				{
					Format(sLRName, sizeof(sLRName), "%s [VIP]", sLRName);
				}

				KvGoBack(hConfig);
			}

			AddMenuItem(hListLRsMenu, sLRID, sLRName);
		} while (KvGotoNextKey(hConfig));
	}
	CloseHandle(hConfig);
	
	//Warden Models Menu
	if (hWardenModelsMenu != INVALID_HANDLE)
	{
		CloseHandle(hWardenModelsMenu);
		hWardenModelsMenu = INVALID_HANDLE;
	}
	
	hWardenModelsMenu = CreateMenu(MenuHandle_WardenModels);
	SetMenuTitle(hWardenModelsMenu, "%s", "warden models title");
	
	//If 1st parameter boolean is true, load the menu with items available but nothing else. A map change is required to precache and load files for models properly.
	ParseWardenModelsConfig(true);
}

EmptyWeaponSlots(client)
{
	new offset = Client_GetWeaponsOffset(client) - 4;

	for (new i = 0; i < 2; i++)
	{
		offset += 4;

		new weapon = GetEntDataEnt2(client, offset);

		if (!Weapon_IsValid(weapon) || i == TFWeaponSlot_Melee)
		{
			continue;
		}

		new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
		if (clip != -1)
		{
			SetEntProp(weapon, Prop_Data, "m_iClip1", 0);
		}

		clip = GetEntProp(weapon, Prop_Data, "m_iClip2");
		if (clip != -1)
		{
			SetEntProp(weapon, Prop_Data, "m_iClip2", 0);
		}

		Client_SetWeaponPlayerAmmoEx(client, weapon, 0, 0);
	}

	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 5);
	CPrintToChat(client, "%t %t", "plugin tag", "stripped weapons and ammo");
}

Jail_Log(const String:sFormat[], any:...)
{
	//Format what we need based on the extra data passed through the parameters.
	new String:sLog[1024];
	VFormat(sLog, sizeof(sLog), sFormat, 2);
	
	//Remove all the color tags since we're using this for logging.
	CRemoveTags(sLog, sizeof(sLog));

	switch (cv_Logging)
	{
	case 1:
		{
			new String:sDate[20];
			FormatTime(sDate, sizeof(sDate), "%Y-%m-%d", GetTime());

			new String:sPath[PLATFORM_MAX_PATH], String:sPathFinal[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "logs/TF2Jail_%s.log", sDate);
			BuildPath(Path_SM, sPathFinal, sizeof(sPathFinal), sPath);
			LogToFileEx(sPathFinal, "%s", sFormat);
		}
	case 2: LogMessage(sLog);
	}

	if (cv_ConsoleSpew)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;
			
			SetGlobalTransTarget(i);
			PrintToConsole(i, sLog);
		}
	}
}

DoorHandler(eDoorsMode:status)
{
	if (strlen(sCellNames) != 0)
	{
		for (new i = 0; i < sizeof(sDoorsList); i++)
		{
			new String:sEntityName[128], ent = -1;
			while((ent = FindEntityByClassnameSafe(ent, sDoorsList[i])) != -1)
			{
				GetEntPropString(ent, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
				if (StrEqual(sEntityName, sCellNames, false))
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
				if (bCellsOpened)
				{
					CPrintToChatAll("%t %t", "plugin tag", "doors manual open");
					bCellsOpened = false;
				}
				else
				{
					CPrintToChatAll("%t %t", "plugin tag", "doors opened");
				}
			}
		case CLOSE: CPrintToChatAll("%t %t", "plugin tag", "doors closed");
		case LOCK: CPrintToChatAll("%t %t", "plugin tag", "doors locked");
		case UNLOCK: CPrintToChatAll("%t %t", "plugin tag", "doors unlocked");
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
		if (Client_IsIngame(client))
		{
			if (cv_PrefStatus)
			{
				if (bRolePreference_Warden[client])
				{
					WardenSet(client);
					Jail_Log("%N has been set to Warden automatically at the start of this arena round.", client);
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
				Jail_Log("%N has been set to Warden automatically at the start of this arena round.", client);
			}
		}
	}
}

public TF2Jail_Preferences(client, CookieMenuAction:action, any:info, String:sDisplay[], maxlen)
{
	switch (action)
	{
	case CookieMenuAction_SelectOption:
		{
			PreferenceMenu(client);
		}
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

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			ShowSyncHudText(i, node, sText);
		}
	}
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

AddAttribute(client, String:sAttribute[], Float:value)
{
	if (eTF2Attributes && Client_IsIngame(client))
	{
		TF2Attrib_SetByName(client, sAttribute, value);
	}
}

RemoveAttribute(client, String:sAttribute[])
{
	if (eTF2Attributes && Client_IsIngame(client))
	{
		TF2Attrib_RemoveByName(client, sAttribute);
	}
}

FindEntityByClassnameSafe(iStart, String:sClassName[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, sClassName);
}

RemoveValveHat(client, bool:unhide = false)
{
	new String:sNetClass[32];

	new edict = MaxClients + 1;
	while ((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
	{
		if (GetEntityNetClass(edict, sNetClass, sizeof(sNetClass)) && strcmp(sNetClass, "CTFWearable") == 0)
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
		if (GetEntityNetClass(edict, sNetClass, sizeof(sNetClass)) && strcmp(sNetClass, "CTFPowerupBottle") == 0)
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

Handle:CreateParticle(String:sType[], Float:time, client, eAttachedParticles:attach = NO_ATTACH, Float:xOffs = 0.0, Float:yOffs = 0.0, Float:zOffs = 0.0)
{
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", sType);
		if (attach != NO_ATTACH)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client, particle, 0);
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

		new Handle:sPack;
		CreateDataTimer(1.0, CheckClient, sPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(sPack, GetClientUserId(client));
		WritePackCell(sPack, EntIndexToEntRef(particle));
	}
	else
	{
		LogError("Could not create info_particle_system");
	}

	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, any:data)
{
	if (IsValidEdict(data))
	{
		RemoveEdict(data);
	}
}

public Action:CheckClient(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);

	new client = GetClientOfUserId(ReadPackCell(hPack));
	new entity = EntRefToEntIndex(ReadPackCell(hPack));

	if (!cv_RendererParticles || !Client_IsIngame(client) || !IsPlayerAlive(client))
	{
		if (!IsValidEdict(entity))
		{
			return Plugin_Stop;
		}

		RemoveEdict(entity);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock PrintToConsoleAll(const String:format[], any:...)
{
	new String:text[192];
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x))
		{
			SetGlobalTransTarget(x);
			VFormat(text, sizeof(text), format, 2);
			PrintToConsole(x, text);
		}
	}
}

TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && Client_IsIngame(client) && IsPlayerAlive(client))
	{
		new String:sClassName[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, sClassName, sizeof(sClassName)))
		{
			FakeClientCommandEx(client, "use %s", sClassName);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

WardenSet(client)
{
	iWarden = client;
	iHasBeenWarden[client]++;

	switch (cv_WardenVoice)
	{
	case 2: CPrintToChatAll("%t %t", "plugin tag", "warden voice muted", iWarden);
	case 1: SetClientListeningFlags(client, VOICE_NORMAL);
	}

	if (bActiveRound)
	{
		if (cv_BlueMute == 1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!Client_IsIngame(i) || GetClientTeam(i) != _:TFTeam_Blue) continue;
				MutePlayer(i);
			}
		}
	}

	if (cv_WardenForceClass)
	{
		new String:sClass[PLATFORM_MAX_PATH];
		GetTrieString(hWardenSkinClasses, cv_sDefaultWardenModel, sClass, sizeof(sClass));
		new TFClassType:iClass = TF2_GetClass(sClass);
		
		new Health = GetClientHealth(client);
		TF2_SetPlayerClass(client, iClass);
		TF2_RegeneratePlayer(client);
		new Health2 = GetClientHealth(client);
		if (Health < Health2)
		{
			SetEntityHealth(client, Health);
		}
	}

	if (cv_WardenModels)
	{
		SetWardenModel(client, cv_sDefaultWardenModel);
	}
	
	if (cv_RendererParticles && strlen(sWardenParticle) != 0)
	{
		hParticle_Wardens[client] = CreateParticle(sWardenParticle, 999999.0, client, ATTACH_NORMAL);
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iWardenColors[0], a_iWardenColors[1], a_iWardenColors[2], a_iWardenColors[3]);

	new String:sWarden[255];
	Format(sWarden, sizeof(sWarden), "%t", "warden current node", iWarden);
	SetTextNode(hTextNodes[2], sWarden, EnumTNPS[2][fCoord_X], EnumTNPS[2][fCoord_Y], EnumTNPS[2][fHoldTime], EnumTNPS[2][iRed], EnumTNPS[2][iGreen], EnumTNPS[2][iBlue], EnumTNPS[2][iAlpha], EnumTNPS[2][iEffect], EnumTNPS[2][fFXTime], EnumTNPS[2][fFadeIn], EnumTNPS[2][fFadeOut]);

	ClearTimer(hTimer_WardenLock);

	ResetVotes();
	WardenMenu(client);

	Call_StartForward(sFW_WardenCreated);
	Call_PushCell(client);
	Call_Finish();

	CPrintToChatAll("%t %t", "plugin tag", "warden new", client);
	CPrintToChat(client, "%t %t", "plugin tag", "warden message");
}

SetWardenModel(client, const String:sModel[])
{
	if (!IsWarden(client)) return;
	
	new String:sModelPlatform[PLATFORM_MAX_PATH];
	GetTrieString(hWardenSkins, sModel, sModelPlatform, sizeof(sModelPlatform));
	SetModel(client, sModelPlatform);
	CPrintToChat(client, "%t %t", "plugin tag", "warden model message", sModel);
}

WardenUnset(client)
{
	if (!IsWarden(client)) return;

	iWarden = -1;
	
	if (cv_WardenModels)
	{
		RemoveModel(client);
	}

	if (bActiveRound)
	{
		if (cv_BlueMute == 1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!Client_IsIngame(i) || GetClientTeam(i) != _:TFTeam_Blue) continue;
				UnmutePlayer(i);
			}
		}

		if (cv_WardenTimer != 0)
		{
			hTimer_WardenLock = CreateTimer(float(cv_WardenTimer), DisableWarden, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (hParticle_Wardens[client] != INVALID_HANDLE)
	{
		CloseHandle(hParticle_Wardens[client]);
		hParticle_Wardens[client] = INVALID_HANDLE;
	}
	
	if (cv_RendererColors) SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);
	
	EnumWardenMenu = Open;

	Call_StartForward(sFW_WardenRemoved);
	Call_PushCell(client);
	Call_Finish();
}

SetModel(client, const String:sModel[])
{
	if (Client_IsIngame(client) && IsPlayerAlive(client) && !bHasModel[client])
	{
		SetVariantString(sModel);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
		if (cv_WardenWearables)
		{
			RemoveValveHat(client, true);
		}
		bHasModel[client] = true;
	}
}

RemoveModel(client)
{
	if (Client_IsIngame(client) && bHasModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		RemoveValveHat(client);
		bHasModel[client] = false;
	}
}

AttemptFireWarden(client)
{
	if (GetClientCount(true) < cv_WVotesMinPlayers)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "fire warden minimum players not met");
		return;
	}

	if (bVoted[client])
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "fire warden already voted", iVotes, iVotesNeeded);
		return;
	}

	iVotes++;
	bVoted[client] = true;

	CPrintToChatAll("%t %t", "plugin tag", "fire warden requested", client, iVotes, iVotesNeeded);

	if (iVotes >= iVotesNeeded)
	{
		FireWardenCall();
	}
}

FireWardenCall()
{
	if (WardenExists())
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsWarden(i))
			{
				WardenUnset(i);
				bLockedFromWarden[i] = true;
			}
		}
		ResetVotes();
		iWardenLimit++;
	}
}

ResetVotes()
{
	iVotes = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		bVoted[i] = false;
	}
}

FindWardenRandom(client)
{
	new Random = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
	if (Client_IsIngame(Random))
	{
		if (cv_PrefStatus)
		{
			if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) == 1)
			{
				WardenSet(Random);
				CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden Random", Random);
				Jail_Log("%N has given %N Warden by Force.", client, Random);
			}

			if (bRolePreference_Warden[Random])
			{
				WardenSet(Random);
				CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden Random", Random);
				Jail_Log("%N has given %N Warden by Force.", client, Random);
			}
			else
			{
				CPrintToChat(client, "%t %t", "plugin tag", "Admin Force Random Warden Not Preferred", Random);
				Jail_Log("%N has their preference set to prisoner only, finding another client...", Random);
				FindWardenRandom(client);
			}
			return;
		}

		WardenSet(Random);
		CShowActivity2(client, "plugin tag", "%t", "Admin Force Warden Random", Random);
		Jail_Log("%N has given %N Warden by Force.", client, Random);
	}
}

/* Timers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:Timer_Round(Handle:hTimer)
{
	iRoundTime--;

	new String:sRoundTimer[64];
	Format(sRoundTimer, sizeof(sRoundTimer), "%02d:%02d", iRoundTime / 60, iRoundTime % 60);

	if (hTextNodes[3] && hTextNodes[3] != INVALID_HANDLE)
	{
		SetTextNode(hTextNodes[3], sRoundTimer, EnumTNPS[3][fCoord_X], EnumTNPS[3][fCoord_Y], EnumTNPS[3][fHoldTime], EnumTNPS[3][iRed], EnumTNPS[3][iGreen], EnumTNPS[3][iBlue], EnumTNPS[3][iAlpha], EnumTNPS[3][iEffect], EnumTNPS[3][fFXTime], EnumTNPS[3][fFadeIn], EnumTNPS[3][fFadeOut]);
	}

	if (cv_RoundTime_Center) PrintCenterTextAll(sRoundTimer);

	if (iRoundTime <= 0)
	{
		ServerCommand("%s", cv_sRoundTimer_Execute);
		ClearTimer(hTimer_RoundTimer);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action:UnmuteReds(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			UnmutePlayer(i);
		}
	}
	CPrintToChatAll("%t %t", "plugin tag", "red team unmuted");
	Jail_Log("All players have been unmuted.");
}

public Action:Open_Doors(Handle:hTimer)
{
	hTimer_OpenCells = INVALID_HANDLE;
	if (bCellsOpened)
	{
		DoorHandler(OPEN);
		new time = RoundFloat(cv_DoorOpenTimer);
		CPrintToChatAll("%t %t", "plugin tag", "cell doors open end", time);
		bCellsOpened = false;
		Jail_Log("Doors have been automatically opened by a timer.");
	}
}

public Action:TimerAdvertisement (Handle:hTimer)
{
	CPrintToChatAll("%t %t", "plugin tag", "plugin advertisement");
	return Plugin_Continue;
}

public Action:Timer_Welcome(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	if (cv_Enabled && Client_IsIngame(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "welcome message");
	}
}

public Action:BanClientTimerFreekiller(Handle:hTimer, Handle:data)
{
	hTimer_FreekillingData = INVALID_HANDLE;

	ResetPack(data);

	new userid = ReadPackCell(data);
	new client = GetClientOfUserId(userid);

	new String:sAuth[24];
	ReadPackString(data, sAuth, sizeof(sAuth));

	new String:sName[MAX_NAME_LENGTH];
	ReadPackString(data, sName, sizeof(sName));

	if (!Client_IsIngame(client) && cv_FreekillersAction == 2)
	{
		BanIdentity(sAuth, cv_FreekillersBantimeDC, BANFLAG_AUTHID, cv_sBanMSGDC, "freekill_identityban", userid);
		CPrintToChatAll("%t %t", "plugin tag", "freekiller disconnected", sName, sAuth);
		Jail_Log("%s [%s ]has been banned via identity.", sName, sAuth);
	}

	switch (cv_FreekillersAction)
	{
	case 2:
		{
			switch (eSourcebans)
			{
				case true:
					{
						SBBanPlayer(0, client, cv_FreekillersBantime, "Client has been marked for Freekilling.");
						Jail_Log("%N has been banned via Sourcebans1 for being marked as a Freekiller.", client);
					}
				case false:
					{
						BanClient(client, cv_FreekillersBantime, BANFLAG_AUTO, "Client has been marked for Freekilling.", cv_sBanMSG, "freekill_liveban", userid);
						Jail_Log("%N has been banned for being marked as a Freekiller.", client);
					}
			}
		}
	case 1:
		{
			if (IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
			}

			bIsFreekiller[client] = false;
		}
	case 0:
		{
			if (IsPlayerAlive(client))
			{
				TF2_RegeneratePlayer(client);
			}

			bIsFreekiller[client] = false;
		}
	}
}

public Action:EnableFFTimer(Handle:hTimer)
{
	hTimer_FriendlyFireEnable = INVALID_HANDLE;
	SetConVarBool(hEngineConVars[0], true);
}

public Action:RemoveRebel(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	hTimer_RebelTimers[client] = INVALID_HANDLE;

	if (Client_IsIngame(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		bIsRebel[client] = false;
		CPrintToChat(client, "%t %t", "plugin tag", "rebel timer end");
		if (hParticle_Rebels[client] != INVALID_HANDLE)
		{
			CloseHandle(hParticle_Rebels[client]);
			hParticle_Rebels[client] = INVALID_HANDLE;
		}
		if (cv_RendererColors) SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);
		Jail_Log("%N is no longer a Rebeller.", client);
	}

	Call_StartForward(sFW_OnRebelRemoved);
	Call_PushCell(client);
	Call_Finish();
}

public Action:DisableWarden(Handle:hTimer)
{
	hTimer_WardenLock = INVALID_HANDLE;
	if (bActiveRound)
	{
		CPrintToChatAll("%t %t", "plugin tag", "warden locked timer");
		bIsWardenLocked = true;
	}
}

public Action:ExecuteServerCommand(Handle:timer, Handle:data)
{
	ResetPack(data);

	new String:sExecute[128];
	ReadPackString(data, sExecute, sizeof(sExecute));
	ServerCommand(sExecute);
}

/* Next Frame Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public ManageWeapons(any:data)
{
	new client = GetClientOfUserId(data);
	if (cv_Enabled && cv_RedMelee && Client_IsIngame(client))
	{
		if (GetClientTeam(client) == _:TFTeam_Red)
		{
			EmptyWeaponSlots(client);
		}
	}
}

public KillEntity(any:data)
{
	new entity = EntRefToEntIndex(data);
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

/* Group Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public bool:WardenGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && IsWarden(i))
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotWardenGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && !IsWarden(i))
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:RebelsGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && bIsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotRebelsGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && !bIsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:FreedaysGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && bIsFreeday[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotFreedaysGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && !bIsFreeday[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:FreekillersGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && bIsFreekiller[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotFreekillersGroup(const String:sPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && !bIsFreekiller[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

/* Native Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Native_ExistWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");

	if (WardenExists()) return true;
	return false;
}

public Native_IsWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (IsWarden(client)) return true;
	return false;
}

public Native_SetWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (WardenExists())
	{
		ThrowNativeError(SP_ERROR_INDEX, "warden is currently in use, cannot execute native function.");
	}

	if (cv_PrefStatus && bRolePreference_Warden[client])
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i has their preference set to prisoner only.", client);
	}

	WardenSet(client);
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!IsWarden(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not warden.", client);
	}

	WardenUnset(client);
}

public Native_IsFreeday(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsQueuedFreeday[client] || bIsFreeday[client]) return true;
	return false;
}

public Native_GiveFreeday(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsFreeday[client])
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Freeday.", client);
	}

	if (bIsQueuedFreeday[client])
	{
		bIsQueuedFreeday[client] = false;
		Jail_Log("%N was queued as a Freeday, removed from queue to turn into a Freeday.");
	}

	GiveFreeday(client);
}

public Native_RemoveFreeday(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!bIsFreeday[client])
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is not a Freeday.", client);
	}

	RemoveFreeday(client);
}

public Native_IsRebel(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Rebels) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Rebels' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsRebel[client]) return true;
	return false;
}

public Native_MarkRebel(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Rebels) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Rebels' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsRebel[client])
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Rebel.", client);
	}

	MarkRebel(client);
}

public Native_IsFreekiller(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Freekillers) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Freekillers' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsFreekiller[client]) return true;
	return false;
}

public Native_MarkFreekill(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Freekillers) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Freekillers' for 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsFreekiller[client])
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already marked as a Freekiller.", client);
	}

	MarkFreekiller(client);
}

public Native_StripToMelee(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip ammo.", client);
	}

	RequestFrame(ManageWeapons, GetClientUserId(client));
}

public Native_StripAllWeapons(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);

	if (!IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip weapons.", client);
	}

	StripToMelee(client);
}

public Native_LockWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");

	bAdminLockWarden = true;
	CPrintToChatAll("%t %t", "plugin tag", "warden locked natives");

	Jail_Log("Natives has locked Warden.");
}

public Native_UnlockWarden(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");

	bAdminLockWarden = false;
	CPrintToChatAll("%t %t", "plugin tag", "warden unlocked natives");

	Jail_Log("Natives has unlocked Warden.");
}

public Native_Logging(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");

	new String:sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);

	Jail_Log(sFormat);
}

public Native_IsLRRound(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");

	if (iLRCurrent != -1) return true;
	return false;
}

public Native_ManageCells(Handle:plugin, numParams)
{
	if (!cv_Enabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	if (!cv_DoorControl) ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Door Controls' for 'TF2Jail' is currently disabled.");

	if (!bIsMapCompatible) return false;

	DoorHandler(GetNativeCell(1));

	return true;
}
/* Plugin End ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
