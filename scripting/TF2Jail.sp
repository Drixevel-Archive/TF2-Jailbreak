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

//Defines
#define PLUGIN_NAME	"[TF2] Jailbreak"
#define PLUGIN_VERSION	"5.6.6"
#define PLUGIN_AUTHOR	"Keith Warren(Shaders Allen)"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT	"http://www.shadersallen.com/"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

//Sourcemod Includes
#include <sourcemod>
#include <sdkhooks>
#include <adminmenu>
#include <tf2_stocks>

//External Includes
#include <morecolors>
#include <smlib>

//Our Includes
#include <tf2jail>

//Required Includes
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>

#undef REQUIRE_PLUGIN
#tryinclude <tf2-weapon-restrictions>
#tryinclude <tf2attributes>
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <clientprefs>
//#tryinclude <voiceannounce_ex>

//New Syntax
#pragma semicolon 1
#pragma newdecls required

//Handle Arrays
ConVar hConVars[81];
Handle hTextNodes[4];
ConVar hEngineConVars[3];

//Plugin Forward Handles
Handle sFW_WardenCreated;
Handle sFW_WardenRemoved;
Handle sFW_OnLastRequestExecute;
Handle sFW_OnFreedayGiven;
Handle sFW_OnFreedayRemoved;
Handle sFW_OnFreekillerGiven;
Handle sFW_OnFreekillerRemoved;
Handle sFW_OnRebelGiven;
Handle sFW_OnRebelRemoved;

//Other Handles
Handle hRolePref_Blue;
Handle hRolePref_Warden;
ArrayList hLastRequestUses;
StringMap hWardenSkinClasses;
StringMap hWardenSkins;

//Particle Entity Indexes
int iParticle_Wardens[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
int iParticle_Freedays[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
int iParticle_Rebels[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
int iParticle_Freekillers[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

//Timer Handles
Handle hTimer_Advertisement;
Handle hTimer_FreekillingData;
Handle hTimer_OpenCells;
Handle hTimer_FriendlyFireEnable;
Handle hTimer_WardenLock;
Handle hTimer_RoundTimer;
Handle hTimer_RebelTimers[MAXPLAYERS + 1];

//Menu Handles
Menu hWardenMenu;
Menu hListLRsMenu;
Menu hWardenModelsMenu;

//ConVar Global Variables
bool cv_Enabled;
bool cv_Advertise;
bool cv_Cvars;
int cv_Logging;
bool cv_Balance;
float cv_BalanceRatio;
bool cv_RedMelee;
bool cv_Warden;
bool cv_WardenAuto;
bool cv_WardenModels;
bool cv_WardenForceClass;
bool cv_WardenFF;
bool cv_WardenCC;
bool cv_WardenRequest;
int cv_WardenLimit;
bool cv_DoorControl;
float cv_DoorOpenTimer;
int cv_RedMute;
float cv_RedMuteTime;
int cv_BlueMute;
bool cv_DeadMute;
bool cv_MicCheck;
bool cv_MicCheckType;
bool cv_Rebels;
float cv_RebelsTime;
int cv_Criticals;
int cv_Criticalstype;
bool cv_WVotesStatus;
float cv_WVotesNeeded;
int cv_WVotesMinPlayers;
int cv_WVotesPostAction;
int cv_WVotesPassedLimit;
bool cv_Freekillers;
float cv_FreekillersTime;
int cv_FreekillersKills;
float cv_FreekillersWave;
int cv_FreekillersAction;
char cv_sBanMSG[256];
char cv_sBanMSGDC[256];
int cv_FreekillersBantime;
int cv_FreekillersBantimeDC;
bool cv_LRSEnabled;
bool cv_LRSAutomatic;
bool cv_LRSLockWarden;
int cv_FreedayLimit;
bool cv_1stDayFreeday;
bool cv_DemoCharge;
bool cv_DoubleJump;
bool cv_Airblast;
bool cv_RendererParticles;
bool cv_RendererColors;
char cv_sDefaultColor[24];
int cv_WardenVoice;
bool cv_WardenWearables;
bool cv_FreedayTeleports;
int cv_WardenStabProtection;
bool cv_KillPointServerCommand;
bool cv_RemoveFreedayOnLR;
bool cv_RemoveFreedayOnLastGuard;
bool cv_PrefStatus;
int cv_WardenTimer;
bool cv_AdminFlags;
bool cv_PrefBlue;
bool cv_PrefWarden;
bool cv_ConsoleSpew;
bool cv_PrefForce;
bool cv_FFButton;
char cv_sWeaponConfig[256];
int cv_KillFeeds;
bool cv_WardenDeathCrits;
bool cv_RoundTimerStatus;
int cv_RoundTime;
int cv_RoundTime_Freeday;
bool cv_RoundTime_Center;
char cv_sRoundTimer_Execute[64];
char cv_sDefaultWardenModel[64];
bool cv_WardenModelMenu;
int cv_RandomWardenTimer;
bool cv_bDebugs;
bool cv_bGodmodeFreedays;

//External Extensions/Plugin Booleans
bool eSourcebans;
bool eSourceComms;
bool eSteamWorks;
bool eTF2Attributes;
//bool eVoiceannounce_ex;
bool eTF2WeaponRestrictions;

//Plugin Global Booleans
bool bIsMapCompatible;
bool bCellsOpened;
bool b1stRoundFreeday;
bool bVoidFreeKills;
bool bIsLRInUse;
bool bIsWardenLocked;
bool bOneGuardLeft;
bool bActiveRound;
bool bFreedayTeleportSet;
bool bLRConfigActive = true;
bool bLockWardenLR;
bool bDisableCriticles;
bool bLateLoad;
bool bAdminLockWarden;
bool bAdminLockedLR;
bool bDifferentWepRestrict;
bool bWardenBackstabbed;

//Global Boolean Player Arrays
bool bBlockedDoubleJump[MAXPLAYERS + 1];
bool bDisabledAirblast[MAXPLAYERS + 1];
bool bIsMuted[MAXPLAYERS + 1];
bool bIsRebel[MAXPLAYERS + 1];
bool bIsQueuedFreeday[MAXPLAYERS + 1];
bool bIsFreeday[MAXPLAYERS + 1];
bool bIsFreekiller[MAXPLAYERS + 1];
bool bHasTalked[MAXPLAYERS + 1];
bool bLockedFromWarden[MAXPLAYERS + 1];
bool bRolePreference_Blue[MAXPLAYERS + 1];
bool bRolePreference_Warden[MAXPLAYERS + 1];
bool bVoted[MAXPLAYERS + 1];

//Global Integer Player Arrays
int iFirstKill[MAXPLAYERS + 1];
int iKillcount[MAXPLAYERS + 1];
int iHasBeenWarden[MAXPLAYERS + 1];

//Global Integers/Variables
int iWarden = -1;
int iCustom = -1;
int iLRPending = -1;
int iLRCurrent = -1;
int iVoters = 0;
int iVotes = 0;
int iVotesNeeded = 0;
int iWardenLimit = 0;
int iFreedayLimit = 0;
int iRoundTime;
float fFreedayPosition[3];

//Global String/Char Variables
char sCellNames[32];
char sCellOpener[32];
char sFFButton[32];
char sDoorsList[][] =  { "func_door", "func_door_rotating", "func_movelinear" };
char sLRConfig[PLATFORM_MAX_PATH];
char sCustomLR[32];
char sOldModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

//Role Renderers Globals
int a_iDefaultColors[4] = {255, 255, 255, 255};
int a_iWardenColors[4] = {255, 255, 255, 255};
char sWardenParticle[64];
int a_iFreedaysColors[4] = {255, 255, 255, 255};
char sFreedaysParticle[64];
int a_iRebellersColors[4] = {255, 255, 255, 255};
char sRebellersParticle[64];
int a_iFreekillersColors[4] = {255, 255, 255, 255};
char sFreekillersParticle[64];

//Enum Structs
enum eWardenMenu
{
	Open = 0,
	FriendlyFire,
	Collision
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

//Enum Globals
eWardenMenu EnumWardenMenu;
int EnumTNPS[4][eTextNodeParams];

/* Plugin Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//TF2 only... duh.
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plug-in only works for Team Fortress 2.");
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

public void OnPluginStart()
{
	//Verbose that the plugin is loading...
	Jail_Log(false, "%s Jailbreak is now loading...", "plugin tag");

	//Load translation files, double check that they exist first and if not, SetFailState and log it to TF2Jail logs.
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail.phrases");

	//ConVars
	hConVars[0] = CreateConVar("tf2jail_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	hConVars[1] = CreateConVar("sm_tf2jail_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[2] = CreateConVar("sm_tf2jail_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[3] = CreateConVar("sm_tf2jail_set_variables", "1", "Set default cvars: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[4] = CreateConVar("sm_tf2jail_logging", "2", "Status and the type of logging: (0 = disabled, 1 = regular logging, 2 = logging to TF2Jail logs.)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[5] = CreateConVar("sm_tf2jail_auto_balance", "1", "Should the plugin autobalance teams: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[6] = CreateConVar("sm_tf2jail_balance_ratio", "0.5", "Ratio for autobalance: (Example: 0.5 = 2:4)", FCVAR_NOTIFY, true, 0.1, true, 1.0);
	hConVars[7] = CreateConVar("sm_tf2jail_melee", "1", "Strip Red Team of weapons: (1 = strip weapons, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[8] = CreateConVar("sm_tf2jail_warden_enable", "1", "Allow Wardens: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[9] = CreateConVar("sm_tf2jail_warden_auto", "1", "Automatically assign a random Wardens on round start: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[10] = CreateConVar("sm_tf2jail_warden_models", "1", "Enable custom models for Warden: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[11] = CreateConVar("sm_tf2jail_warden_forceclass", "1", "Force Wardens to be the class assigned to the models: (1 = yes, 0 = no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[12] = CreateConVar("sm_tf2jail_warden_friendlyfire", "1", "Allow Wardens to manage friendly fire: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[13] = CreateConVar("sm_tf2jail_warden_collision", "1", "Allow Wardens to manage collision: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[14] = CreateConVar("sm_tf2jail_warden_request", "0", "Require admin acceptance for cvar changes: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[15] = CreateConVar("sm_tf2jail_warden_limit", "3", "Number of allowed Wardens per user per map: (0.0 = unlimited)", FCVAR_NOTIFY, true, 0.0);
	hConVars[16] = CreateConVar("sm_tf2jail_door_controls", "1", "Allow Wardens and Admins door control: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[17] = CreateConVar("sm_tf2jail_cell_timer", "60", "Time after Arena round start to open doors: (1.0 - 60.0) (0.0 = off)", FCVAR_NOTIFY, true, 0.0, true, 60.0);
	hConVars[18] = CreateConVar("sm_tf2jail_mute_red", "2", "Mute Red team: (2 = mute prisoners all the time, 1 = mute prisoners on round start based on redmute_time, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[19] = CreateConVar("sm_tf2jail_mute_red_time", "15", "Mute time for redmute: (1.0 - 60.0)", FCVAR_NOTIFY, true, 1.0, true, 60.0);
	hConVars[20] = CreateConVar("sm_tf2jail_mute_blue", "2", "Mute Blue players: (2 = always except Wardens, 1 = while Wardens is active, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[21] = CreateConVar("sm_tf2jail_mute_dead", "1", "Mute Dead players: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[22] = CreateConVar("sm_tf2jail_microphonecheck_enable", "0", "Check blue clients for microphone: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[23] = CreateConVar("sm_tf2jail_microphonecheck_type", "0", "Block blue team or Wardens if no microphone: (1 = Blue, 0 = Wardens only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[24] = CreateConVar("sm_tf2jail_rebelling_enable", "1", "Enable the Rebel system: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[25] = CreateConVar("sm_tf2jail_rebelling_time", "30.0", "Rebel timer: (1.0 - 60.0, 0 = always)", FCVAR_NOTIFY, true, 1.0, true, 60.0);
	hConVars[26] = CreateConVar("sm_tf2jail_criticals", "1", "Which team gets crits: (0 = off, 1 = blue, 2 = red, 3 = both)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	hConVars[27] = CreateConVar("sm_tf2jail_criticals_type", "2", "Type of crits given: (1 = mini, 2 = full)", FCVAR_NOTIFY, true, 1.0, true, 2.0);
	hConVars[28] = CreateConVar("sm_tf2jail_warden_veto_status", "1", "Status to allow votes to fire wardens: (1 = on, 0 = off)", _, true, 0.0, true, 1.0);
	hConVars[29] = CreateConVar("sm_tf2jail_warden_veto_votesneeded", "0.60", "Percentage of players required for fire Wardens vote: (default 0.60 - 60%) (0.05 - 1.00)", 0, true, 0.05, true, 1.00);
	hConVars[30] = CreateConVar("sm_tf2jail_warden_veto_minplayers", "0", "Minimum amount of players required for fire Wardens vote: (0 - MaxPlayers)", 0, true, 0.0, true, float(MAXPLAYERS));
	hConVars[31] = CreateConVar("sm_tf2jail_warden_veto_postaction", "0", "Fire Wardens instantly on vote success or next round: (0 = instant, 1 = Next round)", _, true, 0.0, true, 1.0);
	hConVars[32] = CreateConVar("sm_tf2jail_warden_veto_passlimit", "3", "Limit to Wardens fired by players via votes: (1 - 10, 0 = unlimited)", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	hConVars[33] = CreateConVar("sm_tf2jail_freekilling_enable", "1", "Enable the Freekill system: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[34] = CreateConVar("sm_tf2jail_freekilling_seconds", "6.0", "Time in seconds minimum for freekill flag on mark: (1.0 - 60.0)", FCVAR_NOTIFY, true, 1.0, true, 60.0);
	hConVars[35] = CreateConVar("sm_tf2jail_freekilling_kills", "6", "Number of kills required to flag for freekilling: (1.0 - MaxPlayers)", FCVAR_NOTIFY, true, 1.0, true, float(MAXPLAYERS));
	hConVars[36] = CreateConVar("sm_tf2jail_freekilling_wave", "60.0", "Time in seconds until client is banned for being marked: (1.0 Minimum)", FCVAR_NOTIFY, true, 1.0);
	hConVars[37] = CreateConVar("sm_tf2jail_freekilling_action", "2", "Action towards marked freekiller: (2 = Ban client based on cvars, 1 = Slay the client, 0 = remove mark on timer)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[38] = CreateConVar("sm_tf2jail_freekilling_ban_reason", "You have been banned for freekilling.", "Message to give the client if they're marked as a freekiller and banned.", FCVAR_NOTIFY);
	hConVars[39] = CreateConVar("sm_tf2jail_freekilling_ban_reason_dc", "You have been banned for freekilling and disconnecting.", "Message to give the client if they're marked as a freekiller/disconnected and banned.", FCVAR_NOTIFY);
	hConVars[40] = CreateConVar("sm_tf2jail_freekilling_duration", "60", "Time banned after timer ends: (0 = permanent)", FCVAR_NOTIFY, true, 0.0);
	hConVars[41] = CreateConVar("sm_tf2jail_freekilling_duration_dc", "120", "Time banned if disconnected after timer ends: (0 = permanent)", FCVAR_NOTIFY, true, 0.0);
	hConVars[42] = CreateConVar("sm_tf2jail_lastrequest_enable", "1", "Status of the LR System: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[43] = CreateConVar("sm_tf2jail_lastrequest_automatic", "1", "Automatically grant last request to last prisoner alive: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[44] = CreateConVar("sm_tf2jail_lastrequest_lock_warden", "1", "Lock Wardens during last request rounds: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[45] = CreateConVar("sm_tf2jail_freeday_limit", "3", "Max number of freedays for the lr: (1.0 - 16.0)", FCVAR_NOTIFY, true, 1.0, true, 16.0);
	hConVars[46] = CreateConVar("sm_tf2jail_1stdayfreeday", "1", "Status of the 1st day freeday: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[47] = CreateConVar("sm_tf2jail_democharge", "1", "Stop the Demoman class from charging with shields: (1 = yes, 0 = no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[48] = CreateConVar("sm_tf2jail_doublejump", "1", "Stop the Scout class from double jumping: (1 = yes, 0 = no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[49] = CreateConVar("sm_tf2jail_airblast", "1", "Stop the Pyro class from air blasting: (1 = yes, 0 = no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[50] = CreateConVar("sm_tf2jail_renderer_particles", "1", "Status for particles to render from config: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[51] = CreateConVar("sm_tf2jail_renderer_colors", "1", "Status for colors to render from config: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[52] = CreateConVar("sm_tf2jail_renderer_default_color", "255, 255, 255, 255", "Default color to set clients to if one isn't present: (Default: 255, 255, 255, 255)", FCVAR_NOTIFY);
	hConVars[53] = CreateConVar("sm_tf2jail_warden_voice", "1", "Voice management for Wardens: (0 = disabled, 1 = unmute, 2 = warning)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[54] = CreateConVar("sm_tf2jail_warden_wearables", "1", "Strip Wardens wearables: (1 = enable, 0 = disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[55] = CreateConVar("sm_tf2jail_freeday_teleport", "1", "Status of teleporting: (1 = enable, 0 = disable) (Disables all functionality regardless of configs)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[56] = CreateConVar("sm_tf2jail_warden_stabprotection", "0", "Give Wardens backstab protection: (2 = Always, 1 = Once, 0 = Disabled)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[57] = CreateConVar("sm_tf2jail_point_servercommand", "1", "Kill 'point_servercommand' entities: (1 = Kill on Spawn, 0 = Disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[58] = CreateConVar("sm_tf2jail_freeday_removeonlr", "1", "Remove Freedays on Last Request: (1 = enable, 0 = disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[59] = CreateConVar("sm_tf2jail_freeday_removeonlastguard", "1", "Remove Freedays on Last Guard: (1 = enable, 0 = disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[60] = CreateConVar("sm_tf2jail_preference_enable", "0", "Allow clients to choose their preferred teams/roles: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[61] = CreateConVar("sm_tf2jail_warden_timer", "20", "Time in seconds after Warden is unset or lost to lock Warden: (0 = Disabled, NON-FLOAT VALUE)", FCVAR_NOTIFY);
	hConVars[62] = CreateConVar("sm_tf2jail_warden_flags", "0", "Lock Warden to a command access flag: (1 = enable, 0 = disable) (Command Access: TF2Jail_WardenOverride)", FCVAR_NOTIFY);
	hConVars[63] = CreateConVar("sm_tf2jail_preference_blue", "0", "Enable the preference for Blue if preferences are enabled: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[64] = CreateConVar("sm_tf2jail_preference_warden", "0", "Enable the preference for Blue if preferences are enabled: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[65] = CreateConVar("sm_tf2jail_console_prints_status", "1", "Enable console messages and information: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[66] = CreateConVar("sm_tf2jail_preference_force", "1", "Force admin commands to set players to roles regardless of preference: (1 = Force, 0 = Respect)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[67] = CreateConVar("sm_tf2jail_friendlyfire_button", "1", "Status for Friendly Fire button if exists: (1 = Locked, 0 = Unlocked)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[68] = CreateConVar("sm_tf2jail_weaponconfig", "Jailbreak", "Name of the config for Weapon Blocker: (Default: Jailbreak) (If you compiled plugin without plugin, disregard)", FCVAR_NOTIFY);
	hConVars[69] = CreateConVar("sm_tf2jail_disable_killfeeds", "0", "Disable kill feeds status: (0 = None, 1 = Red, 2 = Blue, 3 = All)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	hConVars[70] = CreateConVar("sm_tf2jail_warden_death_crits", "1", "Disable critical hits on Warden death: (0 = Disabled, 1 = Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[71] = CreateConVar("sm_tf2jail_roundtimer_status", "1", "Status of the round timer: (0 = Disabled, 1 = Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[72] = CreateConVar("sm_tf2jail_roundtimer_time", "600", "Amount of time normally on the timer: (0.0 = disabled)", FCVAR_NOTIFY, true, 0.0);
	hConVars[73] = CreateConVar("sm_tf2jail_roundtimer_time_freeday", "300", "Amount of time on 1st day freeday: (0.0 = disabled)", FCVAR_NOTIFY, true, 0.0);
	hConVars[74] = CreateConVar("sm_tf2jail_roundtimer_center", "0", "Show center text for round timer: (0 = Disabled, 1 = Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[75] = CreateConVar("sm_tf2jail_roundtimer_execute", "sm_slay @red", "Commands to execute to server on timer end: (Maximum Characters: 64)", FCVAR_NOTIFY);
	hConVars[76] = CreateConVar("sm_tf2jail_warden_defaultmodel", "Warden V2", "Default model by name to set Wardens to: (Maximum Characters: 64)", FCVAR_NOTIFY);
	hConVars[77] = CreateConVar("sm_tf2jail_warden_models_menu", "1", "Status for the Warden models menu: (1 = Enabled, 0 = Disabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[78] = CreateConVar("sm_tf2jail_random_warden_timer", "5", "Seconds after the round starts to choose a warden: (0 = instant, default: 5)", FCVAR_NOTIFY, true, 0.0);
	hConVars[79] = CreateConVar("sm_tf2jail_debug_logs", "1", "Status for debugging logs.\n (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[80] = CreateConVar("sm_tf2jail_freeday_godmode", "1", "Status for freedays to receive godmode.\n (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	//Execute the file after we create & set the ConVars.
	AutoExecConfig();

	//Hook all ConVars up and check for changes.
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		hConVars[i].AddChangeHook(HandleCvars);
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
	for (int i = 0; i < sizeof(hTextNodes); i++)
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
	hLastRequestUses = new ArrayList();
	hWardenSkinClasses = new StringMap();
	hWardenSkins = new StringMap();
}

public void OnAllPluginsLoaded()
{
	//Mark a bool for every library that exists so we can use them when available.
	eSourcebans = LibraryExists("sourcebans");
	eSourceComms = LibraryExists("sourcecomms");
	eSteamWorks = LibraryExists("SteamWorks");
	eTF2Attributes = LibraryExists("tf2attributes");
	//eVoiceannounce_ex = LibraryExists("voiceannounce_ex");
	eTF2WeaponRestrictions = LibraryExists("tf2weaponrestrictions");
}

public void OnLibraryAdded(const char[] sName)
{
	//Check if the libraries have been added and if so, start using them.
	eSourcebans = StrEqual(sName, "sourcebans");
	eSourceComms = StrEqual(sName, "sourcecomms");
	eSteamWorks = StrEqual(sName, "SteamWorks");
	eTF2Attributes = StrEqual(sName, "tf2attributes");
	//eVoiceannounce_ex = StrEqual(sName, "voiceannounce_ex");
	eTF2WeaponRestrictions = StrEqual(sName, "tf2weaponrestrictions");
}

public void OnLibraryRemoved(const char[] sName)
{
	//Check if the libraries have been removed and if so, stop using them.
	eSourcebans = StrEqual(sName, "sourcebans");
	eSourceComms = StrEqual(sName, "sourcecomms");
	eSteamWorks = StrEqual(sName, "SteamWorks");
	eTF2Attributes = StrEqual(sName, "tf2attributes");
	//eVoiceannounce_ex = StrEqual(sName, "voiceannounce_ex");
	eTF2WeaponRestrictions = StrEqual(sName, "tf2weaponrestrictions");
}

public void OnPluginPauseChange(bool pause)
{
	//Once the plugin is paused, set the description back to normal.
	if (eSteamWorks)
	{
		switch (pause)
		{
			case true:SteamWorks_SetGameDescription("Team Fortress");
			case false:
			{
				char sDescription[64];
				Format(sDescription, sizeof(sDescription), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
				SteamWorks_SetGameDescription(sDescription);
			}
		}
	}
}

public void OnPluginEnd()
{
	//Execute all OnMapEnd functionality whenever the plugin ends.
	OnMapEnd();
}

public void OnConfigsExecuted()
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
	cv_WardenStabProtection = GetConVarInt(hConVars[56]);
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
	cv_RandomWardenTimer = GetConVarInt(hConVars[78]);
	cv_bDebugs = GetConVarBool(hConVars[79]);
	cv_bGodmodeFreedays = GetConVarBool(hConVars[80]);

	if (cv_Enabled)
	{
		//Set the ConVars up on the server based on settings.
		if (cv_Cvars)
		{
			ConvarsSet(true);
		}

		//Take account for late loading. Probably don't need to set the bool to false but better safe than sorry.
		if (bLateLoad)
		{
			//Load all client data with their respective statuses in-game.
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					OnClientConnected(i);
				}

				if (Client_IsIngame(i))
				{
					OnClientPutInServer(i);
				}

				if (!AreClientCookiesCached(i))
				{
					OnClientCookiesCached(i);
				}
			}

			//Variables to set if the plugin loads during a map.
			b1stRoundFreeday = false;
			bLateLoad = false;
		}

		//Build what we need to build.
		ResetVotes(); //Reset votes for all clients.
		ParseConfigs(); //Parse all configuration files under 'addons/sourcemod/configs/tf2jail/...'.
		BuildMenus(); //Build all menus that don't need to be rendered on usage only.

		//By default, we should store the default color into the 2D Integer Array just to save it.
		char sStringArray[4][8];
		ExplodeString(cv_sDefaultColor, ", ", sStringArray, 4, 8);

		//Fill the integer arrays for default colors.
		for (int i = 0; i < 4; i++)
		{
			a_iDefaultColors[i] = StringToInt(sStringArray[i]);
		}

		//Plugin is loaded! :) YAY!
		Jail_Log(false, "Jailbreak has successfully loaded.");
	}
}

public int SteamWorks_SteamServersConnected()
{
	char sDescription[64];
	Format(sDescription, sizeof(sDescription), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
	SteamWorks_SetGameDescription(sDescription);
}

public int HandleCvars(Handle hCvar, char[] sOldValue, char[] sNewValue)
{
	if (StrEqual(sOldValue, sNewValue, true))
	{
		return;
	}

	int iNewValue = StringToInt(sNewValue);
	bool bNewValue = view_as<bool>(iNewValue);

	if (hCvar == hConVars[0])
	{
		SetConVarString(hConVars[0], PLUGIN_VERSION);
	}
	else if (hCvar == hConVars[1])
	{
		cv_Enabled = bNewValue;

		switch (iNewValue)
		{
			case 1:
			{
				CPrintToChatAll("%t %t", "plugin tag", "plugin enabled");

				if (eSteamWorks)
				{
					char sDescription[64];
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

				for (int i = 1; i <= MaxClients; i++)
				{
					if (!Client_IsIngame(i) || !bIsRebel[i])continue;
					bIsRebel[i] = false;
				}


			}
		}
	}
	else if (hCvar == hConVars[2])
	{
		cv_Advertise = bNewValue;

		KillTimerSafe(hTimer_Advertisement);

		if (cv_Advertise)
		{
			StartAdvertisement();
		}
	}
	else if (hCvar == hConVars[3])
	{
		cv_Cvars = bNewValue;

		ConvarsSet(cv_Cvars);
	}
	else if (hCvar == hConVars[4])
	{
		cv_Logging = iNewValue;
	}
	else if (hCvar == hConVars[5])
	{
		cv_Balance = bNewValue;
	}
	else if (hCvar == hConVars[6])
	{
		cv_BalanceRatio = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[7])
	{
		cv_RedMelee = bNewValue;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Red)
			{
				switch (cv_RedMelee)
				{
					case true:RequestFrame(ManageWeapons, GetClientUserId(i));
					case false:TF2_RegeneratePlayer(i);
				}
			}
		}
	}
	else if (hCvar == hConVars[8])
	{
		cv_Warden = bNewValue;

		if (!cv_Warden && WardenExists())
		{
			WardenUnset(iWarden);
		}
	}
	else if (hCvar == hConVars[9])
	{
		cv_WardenAuto = bNewValue;
	}
	else if (hCvar == hConVars[10])
	{
		cv_WardenModels = bNewValue;

		if (WardenExists())
		{
			switch (cv_WardenModels)
			{
				case true:SetWardenModel(iWarden, cv_sDefaultWardenModel);
				case false:RemoveModel(iWarden);
			}
		}
	}
	else if (hCvar == hConVars[11])
	{
		cv_WardenForceClass = bNewValue;
	}
	else if (hCvar == hConVars[12])
	{
		cv_WardenFF = bNewValue;
	}
	else if (hCvar == hConVars[13])
	{
		cv_WardenCC = bNewValue;
	}
	else if (hCvar == hConVars[14])
	{
		cv_WardenRequest = bNewValue;
	}
	else if (hCvar == hConVars[15])
	{
		cv_WardenLimit = iNewValue;
	}
	else if (hCvar == hConVars[16])
	{
		cv_DoorControl = bNewValue;
	}
	else if (hCvar == hConVars[17])
	{
		cv_DoorOpenTimer = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[18])
	{
		cv_RedMute = iNewValue;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && TF2_GetClientTeam(i) == TFTeam_Red)
			{
				switch (iNewValue)
				{
					case 0: UnmutePlayer(i);
					case 1: if (bCellsOpened) MutePlayer(i);
					case 2: if (bActiveRound) MutePlayer(i);
				}
			}
		}
	}
	else if (hCvar == hConVars[19])
	{
		cv_RedMuteTime = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[20])
	{
		cv_BlueMute = iNewValue;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				switch (iNewValue)
				{
					case 0: UnmutePlayer(i);
					case 1: if (WardenExists()) MutePlayer(i);
					case 2: if (!IsWarden(i)) MutePlayer(i);
				}
			}
		}
	}
	else if (hCvar == hConVars[21])
	{
		cv_DeadMute = bNewValue;
	}
	else if (hCvar == hConVars[22])
	{
		cv_MicCheck = bNewValue;

		if (cv_MicCheck)
		{
			SetConVarBool(hCvar, false);
			LogMessage("This feature is currently disabled.");
		}
	}
	else if (hCvar == hConVars[23])
	{
		cv_MicCheckType = bNewValue;

		if (cv_MicCheckType)
		{
			SetConVarBool(hCvar, false);
			LogMessage("This feature is currently disabled.");
		}
	}
	else if (hCvar == hConVars[24])
	{
		cv_Rebels = bNewValue;

		if (!cv_Rebels)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && bIsRebel[i])
				{
					bIsRebel[i] = false;
				}
			}
		}
	}
	else if (hCvar == hConVars[25])
	{
		cv_RebelsTime = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[26])
	{
		cv_Criticals = iNewValue;
	}
	else if (hCvar == hConVars[27])
	{
		cv_Criticalstype = iNewValue;
	}
	else if (hCvar == hConVars[28])
	{
		cv_WVotesStatus = bNewValue;
	}
	else if (hCvar == hConVars[29])
	{
		cv_WVotesNeeded = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[30])
	{
		cv_WVotesMinPlayers = iNewValue;
	}
	else if (hCvar == hConVars[31])
	{
		cv_WVotesPostAction = iNewValue;
	}
	else if (hCvar == hConVars[32])
	{
		cv_WVotesPassedLimit = iNewValue;
	}
	else if (hCvar == hConVars[33])
	{
		cv_Freekillers = bNewValue;
	}
	else if (hCvar == hConVars[34])
	{
		cv_FreekillersTime = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[35])
	{
		cv_FreekillersKills = iNewValue;
	}
	else if (hCvar == hConVars[36])
	{
		cv_FreekillersWave = StringToFloat(sNewValue);
	}
	else if (hCvar == hConVars[37])
	{
		cv_FreekillersAction = iNewValue;
	}
	else if (hCvar == hConVars[38])
	{
		strcopy(cv_sBanMSG, sizeof(cv_sBanMSG), sNewValue);
	}
	else if (hCvar == hConVars[39])
	{
		strcopy(cv_sBanMSGDC, sizeof(cv_sBanMSGDC), sNewValue);
	}
	else if (hCvar == hConVars[40])
	{
		cv_FreekillersBantime = iNewValue;
	}
	else if (hCvar == hConVars[41])
	{
		cv_FreekillersBantimeDC = iNewValue;
	}
	else if (hCvar == hConVars[42])
	{
		cv_LRSEnabled = bNewValue;
	}
	else if (hCvar == hConVars[43])
	{
		cv_LRSAutomatic = bNewValue;
	}
	else if (hCvar == hConVars[44])
	{
		cv_LRSLockWarden = bNewValue;
	}
	else if (hCvar == hConVars[45])
	{
		cv_FreedayLimit = iNewValue;
	}
	else if (hCvar == hConVars[46])
	{
		cv_1stDayFreeday = bNewValue;
	}
	else if (hCvar == hConVars[47])
	{
		cv_DemoCharge = bNewValue;
	}
	else if (hCvar == hConVars[48])
	{
		cv_DoubleJump = bNewValue;
	}
	else if (hCvar == hConVars[49])
	{
		cv_Airblast = bNewValue;
	}
	else if (hCvar == hConVars[50])
	{
		cv_RendererParticles = bNewValue;
	}
	else if (hCvar == hConVars[51])
	{
		cv_RendererColors = bNewValue;
	}
	else if (hCvar == hConVars[52])
	{
		strcopy(cv_sDefaultColor, sizeof(cv_sDefaultColor), sNewValue);
	}
	else if (hCvar == hConVars[53])
	{
		cv_WardenVoice = iNewValue;
	}
	else if (hCvar == hConVars[54])
	{
		cv_WardenWearables = bNewValue;
	}
	else if (hCvar == hConVars[55])
	{
		cv_FreedayTeleports = bNewValue;
	}
	else if (hCvar == hConVars[56])
	{
		cv_WardenStabProtection = iNewValue;
	}
	else if (hCvar == hConVars[57])
	{
		cv_KillPointServerCommand = bNewValue;
	}
	else if (hCvar == hConVars[58])
	{
		cv_RemoveFreedayOnLR = bNewValue;
	}
	else if (hCvar == hConVars[59])
	{
		cv_RemoveFreedayOnLastGuard = bNewValue;
	}
	else if (hCvar == hConVars[60])
	{
		cv_PrefStatus = bNewValue;
	}
	else if (hCvar == hConVars[61])
	{
		cv_WardenTimer = iNewValue;
	}
	else if (hCvar == hConVars[62])
	{
		cv_AdminFlags = bNewValue;
	}
	else if (hCvar == hConVars[63])
	{
		cv_PrefBlue = bNewValue;
	}
	else if (hCvar == hConVars[64])
	{
		cv_PrefWarden = bNewValue;
	}
	else if (hCvar == hConVars[65])
	{
		cv_ConsoleSpew = bNewValue;
	}
	else if (hCvar == hConVars[66])
	{
		cv_PrefForce = bNewValue;
	}
	else if (hCvar == hConVars[67])
	{
		cv_FFButton = bNewValue;
	}
	else if (hCvar == hConVars[68])
	{
		strcopy(cv_sWeaponConfig, sizeof(cv_sWeaponConfig), sNewValue);
	}
	else if (hCvar == hConVars[69])
	{
		cv_KillFeeds = iNewValue;
	}
	else if (hCvar == hConVars[70])
	{
		cv_WardenDeathCrits = bNewValue;
	}
	else if (hCvar == hConVars[71])
	{
		cv_RoundTimerStatus = bNewValue;
	}
	else if (hCvar == hConVars[72])
	{
		cv_RoundTime = iNewValue;
	}
	else if (hCvar == hConVars[73])
	{
		cv_RoundTime_Freeday = iNewValue;
	}
	else if (hCvar == hConVars[74])
	{
		cv_RoundTime_Center = bNewValue;
	}
	else if (hCvar == hConVars[75])
	{
		strcopy(cv_sRoundTimer_Execute, sizeof(cv_sRoundTimer_Execute), sNewValue);
	}
	else if (hCvar == hConVars[76])
	{
		strcopy(cv_sDefaultWardenModel, sizeof(cv_sDefaultWardenModel), sNewValue);
	}
	else if (hCvar == hConVars[77])
	{
		cv_WardenModelMenu = bNewValue;
	}
	else if (hCvar == hConVars[78])
	{
		cv_RandomWardenTimer = bNewValue;
	}
	else if (hCvar == hConVars[79])
	{
		cv_bDebugs = bNewValue;
	}
	else if (hCvar == hConVars[80])
	{
		cv_bGodmodeFreedays = bNewValue;
	}
}

public void TF2WeaponRestrictions_RestrictionChanged(const char[] sRestriction)
{
	if (!StrEqual(sRestriction, "Jailbreak") && iLRCurrent == -1)
	{
		bDifferentWepRestrict = true;
	}
}

/* Server Commands ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public void OnMapStart()
{
	if (cv_Enabled)
	{
		KillTimerSafe(hTimer_RoundTimer);

		if (cv_Advertise)
		{
			StartAdvertisement();
		}

		for (int i = 1; i <= MaxClients; i++)
		{
			iHasBeenWarden[i] = 0;
		}

		if (cv_WardenModels)
		{
			ParseWardenModelsConfig();
		}

		if (cv_Freekillers)
		{
			PrecacheSound("ui/system_message_alert.wav", true);
		}

		b1stRoundFreeday = true;

		iVotesNeeded = 0;
		ResetVotes();

		for (int i = 0; i < hLastRequestUses.Length; i++)
		{
			hLastRequestUses.Set(i, 0);
		}
	}
}

public void OnMapEnd()
{
	if (cv_Enabled)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i))
			{
				if (IsWarden(i))
				{
					RemoveModel(i);
				}

				if (bIsMuted[i])
				{
					UnmuteClient(i);
				}
			}

			bHasTalked[i] = false;
			bIsMuted[i] = false;
			bIsQueuedFreeday[i] = false;
			bLockedFromWarden[i] = false;
			iHasBeenWarden[i] = 0;
			hTimer_RebelTimers[i] = null;
		}

		bActiveRound = false;
		bAdminLockWarden = false;
		iWardenLimit = 0;
		iLRCurrent = -1;
		ResetVotes();

		ConvarsSet(false);

		hTimer_Advertisement = null;
		hTimer_FreekillingData = null;
		hTimer_OpenCells = null;
		hTimer_FriendlyFireEnable = null;
		hTimer_WardenLock = null;
	}
}

public void OnClientConnected(int client)
{
	if (cv_Enabled)
	{
		bVoted[client] = false;
		iVoters++;
		iVotesNeeded = RoundToFloor(float(iVoters) * cv_WVotesNeeded);
		bIsMuted[client] = false;
	}
}

public void OnClientCookiesCached(int client)
{
	if (cv_Enabled && cv_PrefStatus && Client_IsIngame(client))
	{
		char sValue[8];

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

public void OnClientPutInServer(int client)
{
	if (cv_Enabled)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

		CreateTimer(5.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

		MutePlayer(client);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!cv_Enabled)
	{
		return Plugin_Continue;
	}

	if (!Client_IsIngame(victim) || !Client_IsIngame(attacker))
	{
		return Plugin_Continue;
	}

	bool bReturn;

	if (cv_bGodmodeFreedays && bIsFreeday[victim] && !IsWarden(attacker))
	{
		damage = 0.0;
		bReturn = true;
	}

	if (!bDisableCriticles && (cv_WardenDeathCrits && !bIsWardenLocked))
	{
		switch (TF2_GetClientTeam(attacker))
		{
			case TFTeam_Red:
			{
				switch (cv_Criticals)
				{
					case 2, 3:
					{
						switch (cv_Criticalstype)
						{
							case 1:damagetype = damagetype | DMG_SLOWBURN;
							case 2:damagetype = damagetype | DMG_CRIT;
						}

						bReturn = true;
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
							case 1:damagetype = damagetype | DMG_SLOWBURN;
							case 2:damagetype = damagetype | DMG_CRIT;
						}

						bReturn = true;
					}
				}
			}
		}
	}

	if (cv_WardenStabProtection != 0 && IsWarden(victim) && (cv_WardenStabProtection == 1 && !bWardenBackstabbed))
	{
		char sClassName[64];
		GetEntityClassname(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), sClassName, sizeof(sClassName));

		if (StrEqual(sClassName, "tf_weapon_knife") && (damagetype & DMG_CRIT == DMG_CRIT))
		{
			damage = 0.0;
			bWardenBackstabbed = true;

			bReturn = true;
		}
	}

	return bReturn ? Plugin_Changed : Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (!cv_Enabled || !Client_IsIngame(client))
	{
		return;
	}

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
	bIsQueuedFreeday[client] = false;
	iKillcount[client] = 0;
	iFirstKill[client] = 0;

	ClearFreekiller(client);
	ClearRebel(client);
}

public void OnPlayerSpawn(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!Client_IsIngame(client))return;

	TFClassType class = TF2_GetPlayerClass(client);
	bIsRebel[client] = false;

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
		{
			switch (class)
			{
				case TFClass_Scout:
				{
					if (cv_DoubleJump)
					{
						AddAttribute2(client, 49, 1.0);
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
			}

			if (cv_RedMute == 2)
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
			/*if (eVoiceannounce_ex && cv_MicCheck)
			{
				if (cv_MicCheckType)
				{
					if (!bHasTalked[client] && !IsVIP(client))
					{
						TF2_ChangeClientTeam(client, TFTeam_Red);
						CPrintToChat(client, "%t %t", "plugin tag", "microphone unverified");
					}
				}
			}*/

			if (cv_BlueMute == 2)
			{
				MutePlayer(client);
			}
		}
	}
}

public void OnPlayerHurt(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (!Client_IsIngame(client) || !Client_IsIngame(attacker) || attacker == client)return;

	if (bIsFreeday[attacker])
	{
		RemoveFreeday(attacker);
	}

	if (cv_Rebels)
	{
		if (TF2_GetClientTeam(attacker) == TFTeam_Red && TF2_GetClientTeam(client) == TFTeam_Blue && !bIsRebel[attacker])
		{
			MarkRebel(attacker);
		}
	}
}

public Action OnChangeClass(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (bIsFreeday[client])
	{
		int flags = GetEntityFlags(client) | FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public Action OnPlayerDeathPre(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int client_killer = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (Client_IsIngame(client) && Client_IsIngame(client_killer))
	{
		switch (cv_KillFeeds)
		{
			case 1:
			{
				if (TF2_GetClientTeam(client_killer) == TFTeam_Red)
				{
					SetEventBroadcast(hEvent, true);
				}
			}
			case 2:
			{
				if (TF2_GetClientTeam(client_killer) == TFTeam_Blue)
				{
					SetEventBroadcast(hEvent, true);
				}
			}
			case 3:SetEventBroadcast(hEvent, true);
		}
	}
}

public void OnPlayerDeath(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int client_killer = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (Client_IsIngame(client))
	{
		if (bIsFreeday[client])
		{
			RemoveFreeday(client);
			Jail_Log(false, "%N was an active freeday on round.", client);
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
			RemoveAttribute2(client, 49);
			bBlockedDoubleJump[client] = false;
		}

		if (IsWarden(client))
		{
			WardenUnset(client);
			PrintCenterTextAll("%t", "warden killed", client);
		}

		if (cv_Freekillers && Client_IsIngame(client_killer) && client != client_killer)
		{
			if (TF2_GetClientTeam(client_killer) == TFTeam_Blue)
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

		if (bIsRebel[client])
		{
			ClearRebel(client);
		}
	}

	if (cv_LRSAutomatic && bLRConfigActive)
	{
		if (TF2_GetTeamClientCount(TFTeam_Red) == 1)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Red)
				{
					LastRequestStart(i, i);
					Jail_Log(false, "%N has received last request for being the last prisoner alive.", i);
				}
			}
		}
	}

	if (TF2_GetTeamClientCount(TFTeam_Blue) == 1)
	{
		if (cv_RemoveFreedayOnLastGuard)
		{
			for (int i = 1; i <= MaxClients; i++)
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

public void OnRoundStart(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	if (cv_1stDayFreeday && b1stRoundFreeday)
	{
		DoorHandler(OPEN);
		PrintCenterTextAll("1st round freeday");

		char s1stDay[256];
		Format(s1stDay, sizeof(s1stDay), "%t", "1st day freeday node");
		SetTextNode(hTextNodes[0], s1stDay, EnumTNPS[0][fCoord_X], EnumTNPS[0][fCoord_Y], EnumTNPS[0][fHoldTime], EnumTNPS[0][iRed], EnumTNPS[0][iGreen], EnumTNPS[0][iBlue], EnumTNPS[0][iAlpha], EnumTNPS[0][iEffect], EnumTNPS[0][fFXTime], EnumTNPS[0][fFadeIn], EnumTNPS[0][fFadeOut]);
		Jail_Log(false, "1st day freeday has been activated.");
	}

	if (bIsMapCompatible)
	{
		if (strlen(sCellOpener) != 0)
		{
			int CellHandler = Entity_FindByName(sCellOpener, "func_button");
			if (IsValidEntity(CellHandler))
			{
				if (cv_DoorControl)
				{
					SetEntProp(CellHandler, Prop_Data, "m_bLocked", 1, 1);
					Jail_Log(false, "Door Controls: Disabled - Cell Opener is locked.");
				}
				else
				{
					SetEntProp(CellHandler, Prop_Data, "m_bLocked", 0, 1);
					Jail_Log(false, "Door Controls: Enabled - Cell Opener is unlocked.");
				}
			}
			else
			{
				Jail_Log(false, "[ERROR] Entity name not found for Cell Door Opener! Please verify integrity of the config and the map.");
			}
		}

		if (strlen(sFFButton) != 0)
		{
			int FFButton = Entity_FindByName(sFFButton, "func_button");
			if (IsValidEntity(FFButton))
			{
				if (cv_FFButton)
				{
					SetEntProp(FFButton, Prop_Data, "m_bLocked", 1, 1);
					Jail_Log(false, "FF Button: Disabled.");
				}
				else
				{
					SetEntProp(FFButton, Prop_Data, "m_bLocked", 0, 1);
					Jail_Log(false, "FF Button: Enabled.");
				}
			}
		}
	}

	if (eTF2WeaponRestrictions && bDifferentWepRestrict)
	{
		WeaponRestrictions_SetConfig(cv_sWeaponConfig);
		bDifferentWepRestrict = false;
	}

	iWarden = -1;
	bIsLRInUse = false;
	bActiveRound = true;
}

public void OnArenaRoundStart(Handle event, const char[] name, bool bDontBroadcast)
{
	if (!cv_Enabled)return;

	KillTimerSafe(hTimer_RoundTimer);

	if (cv_RoundTimerStatus)
	{
		iRoundTime = b1stRoundFreeday ? cv_RoundTime_Freeday : cv_RoundTime;

		if (iRoundTime != 0)
		{
			hTimer_RoundTimer = CreateTimer(1.0, Timer_Round, _, TIMER_REPEAT);
		}
	}

	bIsWardenLocked = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreeday[i] && !IsPlayerAlive(i))
		{
			TF2_ChangeClientTeam(i, TFTeam_Red);
			TF2_RespawnPlayer(i);
		}
	}

	if (cv_Balance && GetClientCount(true) > 2)
	{
		float Ratio;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!Client_IsIngame(i))continue;

			Ratio = float(TF2_GetTeamClientCount(TFTeam_Blue)) / float(TF2_GetTeamClientCount(TFTeam_Red));

			if (Ratio <= cv_BalanceRatio)
			{
				break;
			}

			if (Client_IsIngame(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				if (cv_PrefStatus && bRolePreference_Blue[i] || CheckCommandAccess(i, "TF2Jail_Autobalance_Immunity", ADMFLAG_RESERVATION))
				{
					continue;
				}

				TF2_ChangeClientTeam(i, TFTeam_Red);
				TF2_RespawnPlayer(i);

				CPrintToChat(i, "%t %t", "plugin tag", "moved for balance");
				Jail_Log(false, "%N has been moved to prisoners team for balance.", i);

				RequestFrame(ManageWeapons, GetClientUserId(i));
			}
		}
	}

	if (bIsMapCompatible && cv_DoorOpenTimer != 0.0)
	{
		int autoopen = RoundFloat(cv_DoorOpenTimer);
		hTimer_OpenCells = CreateTimer(cv_DoorOpenTimer, Open_Doors, _, TIMER_FLAG_NO_MAPCHANGE);
		CPrintToChatAll("%t %t", "plugin tag", "cell doors open start", autoopen);
		Jail_Log(false, "Cell doors are being auto opened via automatic timer.");
		bCellsOpened = true;
	}

	switch (cv_RedMute)
	{
		case 2:
		{
			CPrintToChatAll("%t %t", "plugin tag", "red team muted");

			Jail_Log(false, "Red team has been muted permanently this round.");
		}
		case 1:
		{
			int time = RoundFloat(cv_RedMuteTime);
			CPrintToChatAll("%t %t", "plugin tag", "red team muted temporarily", time);

			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && TF2_GetClientTeam(i) == TFTeam_Red)
				{
					MutePlayer(i);
				}
			}

			CreateTimer(cv_RedMuteTime, UnmuteReds, _, TIMER_FLAG_NO_MAPCHANGE);

			Jail_Log(false, "Red team has been temporarily muted and will wait %s seconds to be unmuted.", time);
		}
		case 0:
		{
			CPrintToChatAll("%t %t", "plugin tag", "red mute system disabled");

			Jail_Log(false, "Mute system has been disabled this round, nobody has been muted.");
		}
	}

	if (iLRCurrent != -1)
	{
		hLastRequestUses.Set(iLRCurrent, hLastRequestUses.Get(iLRCurrent) + 1);

		Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(hConfig, sLRConfig);

		char sLastRequestID[256];
		IntToString(iLRCurrent, sLastRequestID, sizeof(sLastRequestID));

		if (KvJumpToKey(hConfig, sLastRequestID))
		{
			if (strlen(sCustomLR) == 0)
			{
				char sLRName[256];
				KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));

				char sLRMessage[256];
				Format(sLRMessage, sizeof(sLRMessage), "%t", "last request node", sLRName);

				SetTextNode(hTextNodes[1], sLRMessage, EnumTNPS[1][fCoord_X], EnumTNPS[1][fCoord_Y], EnumTNPS[1][fHoldTime], EnumTNPS[1][iRed], EnumTNPS[1][iGreen], EnumTNPS[1][iBlue], EnumTNPS[1][iAlpha], EnumTNPS[1][iEffect], EnumTNPS[1][fFXTime], EnumTNPS[1][fFadeIn], EnumTNPS[1][fFadeOut]);
			}

			bool IsFreedayRound = false;

			char sHandler[PLATFORM_MAX_PATH];
			KvGetString(hConfig, "Handler", sHandler, sizeof(sHandler));

			Call_StartForward(sFW_OnLastRequestExecute);
			Call_PushString(sHandler);
			Call_Finish();

			char sExecute[256];
			if (KvGetString(hConfig, "Execute_Cmd", sExecute, sizeof(sExecute)))
			{
				if (strlen(sExecute) != 0)
				{
					Handle pack;
					CreateDataTimer(0.5, ExecuteServerCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackString(pack, sExecute);
				}
			}

			if (eTF2WeaponRestrictions)
			{
				char sRestrictions[256];

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

				if (KvGetNum(hConfig, "TimerStatus", 1) == 1)
				{
					KillTimerSafe(hTimer_RoundTimer);
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
					for (int i = 1; i < MaxClients; i++)
					{
						if (Client_IsIngame(i) && IsPlayerAlive(i))
						{
							switch (TF2_GetClientTeam(i))
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
						float TimeFloat = KvGetFloat(hConfig, "Timer", 1.0);
						if (TimeFloat >= 0.1)
						{
							hTimer_FriendlyFireEnable = CreateTimer(TimeFloat, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
						}
						else
						{
							Jail_Log(false, "[ERROR] Timer is set to a value below 0.1! Timer could not be created.");
						}
					}

					KvGoBack(hConfig);
				}

				KvGoBack(hConfig);
			}

			char sActive[256];
			if (KvGetString(hConfig, "Activated", sActive, sizeof(sActive)))
			{
				if (IsFreedayRound)
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && bIsFreeday[i])
						{
							char sName[MAX_NAME_LENGTH];
							GetClientName(i, sName, sizeof(sName));

							ReplaceString(sActive, sizeof(sActive), "{NAME}", sName);
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
			Jail_Log(false, "Error starting Last Request number %i, couldn't be found in configuration file.", iLRCurrent);
		}
		CloseHandle(hConfig);
	}

	if (strlen(sCustomLR) != 0)
	{
		SetTextNode(hTextNodes[1], sCustomLR, EnumTNPS[1][fCoord_X], EnumTNPS[1][fCoord_Y], EnumTNPS[1][fHoldTime], EnumTNPS[1][iRed], EnumTNPS[1][iGreen], EnumTNPS[1][iBlue], EnumTNPS[1][iAlpha], EnumTNPS[1][iEffect], EnumTNPS[1][fFXTime], EnumTNPS[1][fFadeIn], EnumTNPS[1][fFadeOut]);
		sCustomLR[0] = '\0';
	}

	if (cv_WardenAuto && cv_RandomWardenTimer > 0)
	{
		CPrintToChatAll("%t %t", "plugin tag", "finding random warden", cv_RandomWardenTimer);
		CreateTimer(float(cv_RandomWardenTimer), FindRandomWardenTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnRoundEnd(Handle hEvent, char[] sName, bool bBroadcast)
{
	if (!cv_Enabled)return;

	KillTimerSafe(hTimer_RoundTimer);

	if (b1stRoundFreeday)
	{
		b1stRoundFreeday = false;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			UnmutePlayer(i);

			if (bIsFreeday[i])
			{
				RemoveFreeday(i);
			}

			if (bDisabledAirblast[i])
			{
				RemoveAttribute(i, "airblast disabled");
				bDisabledAirblast[i] = false;
			}

			if (bBlockedDoubleJump[i])
			{
				RemoveAttribute2(i, 49);
				bBlockedDoubleJump[i] = false;
			}

			if (strlen(sOldModel[i]) > 0)
			{
				RemoveModel(i);
			}

			KillTimerSafe(hTimer_RebelTimers[i]);

			for (int x = 0; x < sizeof(hTextNodes); x++)
			{
				if (hTextNodes[x] != null)
				{
					ClearSyncHud(i, hTextNodes[x]);
				}
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
	bWardenBackstabbed = false;

	KillTimerSafe(hTimer_OpenCells);
	KillTimerSafe(hTimer_WardenLock);
	KillTimerSafe(hTimer_FriendlyFireEnable);

	if (iLRCurrent != -1)
	{
		Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(hConfig, sLRConfig);

		char sLastRequestID[256];
		IntToString(iLRCurrent, sLastRequestID, sizeof(sLastRequestID));

		if (KvJumpToKey(hConfig, sLastRequestID))
		{
			char sExecute[256];
			if (KvGetString(hConfig, "Ending_Cmd", sExecute, sizeof(sExecute)))
			{
				if (strlen(sExecute) != 0)
				{
					Handle pack;
					CreateDataTimer(0.5, ExecuteServerCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackString(pack, sExecute);
				}
			}
		}
		else
		{
			Jail_Log(false, "Error ending Last Request number %i, couldn't be found in configuration file.", iLRCurrent);
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

public void OnRegeneration(Handle hEvent, char[] sName, bool bBroadcast)
{
	RequestFrame(ManageWeapons, GetEventInt(hEvent, "userid"));
}

public void OnEntityCreated(int entity, const char[] sClassName)
{
	if (!cv_Enabled)return;

	if (StrContains(sClassName, "tf_ammo_pack", false) != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}

	if (cv_KillPointServerCommand && StrContains(sClassName, "point_servercommand", false) != -1)
	{
		RequestFrame(KillEntity, EntIndexToEntRef(entity));
	}
}

public void OnClientSayCommand_Post(int client, const char[] sCommand, const char[] sArgs)
{
	if (client == iCustom)
	{
		strcopy(sCustomLR, sizeof(sCustomLR), sArgs);
		CPrintToChat(client, "%t %t", "plugin tag", "last request custom set", sCustomLR);
		Jail_Log(false, "Custom LR set to %s by client %N.", sCustomLR, client);
		iCustom = -1;
	}
}

/*public bool OnClientSpeakingEx(int client)
{
	if (cv_Enabled && eVoiceannounce_ex && cv_MicCheck && !bHasTalked[client])
	{
		bHasTalked[client] = true;
		CPrintToChat(client, "%t %t", "plugin tag", "microphone verified");
	}
}*/

public int WeaponRestrictions_OnExecuted(int client)
{
	if (Client_IsIngame(client) && IsPlayerAlive(client))
	{
		StripToMelee(client);
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (cv_DemoCharge && TF2_GetClientTeam(client) == TFTeam_Red && condition == TFCond_Charging)
	{
		TF2_RemoveCondition(client, condition);
	}
}

/* Player Commands ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action Command_FireWarden(int client, int args)
{
	if (!cv_Enabled || client == 0)
	{
		return Plugin_Handled;
	}

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

	if (cv_WVotesPassedLimit != 0 && iWardenLimit > cv_WVotesPassedLimit)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "warden fire limit reached");
		return Plugin_Handled;
	}

	AttemptFireWarden(client);

	return Plugin_Handled;
}

public Action Command_BecomeWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

	if (TF2_GetClientTeam(client) != TFTeam_Blue)
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

public Action Command_ExitWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

public Action Command_WardenMenu(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

public Action Command_OpenCells(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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
	Jail_Log(false, "%N has opened the cell doors using door controls as Warden.", client);

	return Plugin_Handled;
}

public Action Command_CloseCells(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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
	Jail_Log(false, "%N has closed the cell doors using door controls as Warden.", client);

	return Plugin_Handled;
}

public Action Command_EnableFriendlyFire(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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
			Jail_Log(false, "%N has disabled friendly fire as Warden.", iWarden);
		}
		case false:
		{
			SetConVarBool(hEngineConVars[0], true);
			CPrintToChatAll("%t %t", "plugin tag", "friendlyfire enabled", iWarden);
			Jail_Log(false, "%N has enabled friendly fire as Warden.", iWarden);
		}
	}

	return Plugin_Handled;
}

public Action Command_EnableCollisions(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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
			Jail_Log(false, "%N has disabled collision as Warden.", iWarden);
		}
		case false:
		{
			SetConVarBool(hEngineConVars[1], true);
			CPrintToChatAll("%t %t", "plugin tag", "collision enabled", iWarden);
			Jail_Log(false, "%N has enabled collision as Warden.", iWarden);
		}
	}

	return Plugin_Handled;
}

public Action Command_GiveLastRequest(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

	if (IsVoteInProgress())return Plugin_Handled;

	Handle hMenu = CreateMenu(MenuHandle_ForceLR);
	SetMenuTitle(hMenu, "%s", "choose a player");

	char sUserID[12]; char sDisplay[MAX_NAME_LENGTH + 12];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Red)
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sDisplay, sizeof(sDisplay), "%L", i);
			AddMenuItem(hMenu, sUserID, sDisplay);
		}
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	Jail_Log(false, "%N is giving someone a last request...", client);

	return Plugin_Handled;
}

public Action Command_RemoveLastRequest(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			bIsQueuedFreeday[i] = false;
		}
	}

	bIsLRInUse = false;
	iLRPending = -1;
	CReplyToCommand(client, "%t %t", "plugin tag", "warden removed lr");
	Jail_Log(false, "%N has cleared all last requests currently queued.", client);

	return Plugin_Handled;
}

public Action Command_CurrentLastRequest(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

	Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");

	if (FileToKeyValues(hConfig, sLRConfig))
	{
		char sLastRequestID[256];
		IntToString(iLRCurrent, sLastRequestID, sizeof(sLastRequestID));

		if (KvJumpToKey(hConfig, sLastRequestID))
		{
			char sLRID[64]; char sLRName[256];
			KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
			KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));
			CReplyToCommand(client, "%t %t", "plugin tag", "current last requests", sLRName, sLRID);
		}
	}
	CloseHandle(hConfig);

	return Plugin_Handled;
}

public Action Command_ListLastRequests(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

public Action Command_CurrentWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!cv_Warden)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden disabled");
		return Plugin_Handled;
	}

	CReplyToCommand(client, "%t %t", "plugin tag", WardenExists() ? "warden current" : "no warden current", iWarden);

	return Plugin_Handled;
}

char sWardenModel[MAXPLAYERS + 1][64];

public Action Command_WardenModel(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!cv_WardenModelMenu)return Plugin_Handled;

	if (IsVoteInProgress())return Plugin_Handled;

	switch (DisplayMenu(hWardenModelsMenu, client, MENU_TIME_FOREVER))
	{
		case true:CPrintToChat(client, "%t %t", "plugin tag", "warden model information", sWardenModel[client]);
		case false:CPrintToChat(client, "%t %t", "plugin tag", "warden model missing menu");
	}

	return Plugin_Handled;
}

/* Admin Commands ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action AdminRemoveWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!WardenExists())
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "no warden current");
		return Plugin_Handled;
	}

	PrintCenterTextAll("%t", "warden fired center");

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Remove Warden", client, iWarden);

	Jail_Log(false, "%N has removed %N's Warden status with admin.", client, iWarden);
	WardenUnset(iWarden);

	return Plugin_Handled;
}

public Action AdminPardonFreekiller(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!cv_Freekillers)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "freekillers system disabled");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		int target = FindTarget(client, sArg, true);

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
		Jail_Log(false, "%N has cleared %N as a Freekiller.", target, client);
	}

	PardonFreekillersMenu(client);
	return Plugin_Handled;
}

public Action AdminPardonAllFreekillers(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!cv_Freekillers)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "freekillers system disabled");
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreekiller[i])
		{
			ClearFreekiller(i);
			Jail_Log(false, "%N has cleared %N as a Freekiller.", i, client);
		}
	}

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Pardon Freekillers");

	return Plugin_Handled;
}

public Action AdminDenyLR(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!Client_IsIngame(i))continue;

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

		if (hTextNodes[1] != null)
		{
			ClearSyncHud(i, hTextNodes[1]);
		}
	}

	bIsLRInUse = false;

	iLRPending = -1;
	iLRCurrent = -1;

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Deny Last Request");

	Jail_Log(false, "%N has denied all currently queued last requests and reset the last request system.", client);

	return Plugin_Handled;
}

public Action AdminOpenCells(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(OPEN);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Open Cells");

	Jail_Log(false, "%N has opened the cells using admin.", client);

	return Plugin_Handled;
}

public Action AdminCloseCells(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(CLOSE);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Close Cells");

	Jail_Log(false, "%N has closed the cells using admin.", client);

	return Plugin_Handled;
}

public Action AdminLockCells(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(LOCK);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Lock Cells");

	Jail_Log(false, "%N has locked the cells using admin.", client);

	return Plugin_Handled;
}

public Action AdminUnlockCells(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bIsMapCompatible)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "incompatible map");
		return Plugin_Handled;
	}

	DoorHandler(UNLOCK);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Unlock Cells");

	Jail_Log(false, "%N has unlocked the cells using admin.", client);

	return Plugin_Handled;
}

public Action AdminForceWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (WardenExists())
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden exists", iWarden);
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char sTag[64];
		Format(sTag, sizeof(sTag), "%t", "plugin tag");

		char sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		int target = FindTarget(client, sArg, true);

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

		if (TF2_GetTeamClientCount(TFTeam_Blue) < 2)
		{
			WardenSet(target);
			CShowActivity2(client, sTag, "%t", "Admin Force Warden", target);
			Jail_Log(false, "%N has forced a %N Warden.", client, target);
			return Plugin_Handled;
		}

		if (cv_PrefStatus)
		{
			if (cv_PrefForce)
			{
				WardenSet(target);
				CShowActivity2(client, sTag, "%t", "Admin Force Warden", target);
				Jail_Log(false, "%N has forced a %N Warden.", client, target);
				return Plugin_Handled;
			}

			if (bRolePreference_Warden[target])
			{
				WardenSet(target);
				CShowActivity2(client, sTag, "%t", "Admin Force Warden", target);
				Jail_Log(false, "%N has forced a %N Warden.", client, target);
			}
			else
			{
				CReplyToCommand(client, "%t %t", "plugin tag", "Admin Force Warden Not Preferred", target);
				Jail_Log(false, "%N has their preference set to prisoner only, finding another client...", target);
			}
			return Plugin_Handled;
		}

		WardenSet(target);
		CShowActivity2(client, sTag, "%t", "Admin Force Warden", target);
		Jail_Log(false, "%N has forced a %N Warden.", client, target);

		return Plugin_Handled;
	}

	FindWardenRandom(client);
	return Plugin_Handled;
}

public Action AdminForceLR(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");

	if (args > 0)
	{
		char sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		int target = FindTarget(client, sArg, true);

		if (!Client_IsIngame(target))
		{
			CReplyToCommand(client, "%t %t", "plugin tag", "Player no longer available");
			return Plugin_Handled;
		}

		CShowActivity2(client, sTag, "%t", "Admin Force Last Request", target);
		LastRequestStart(target, client, false, true);
		Jail_Log(false, "%N has gave %N a Last Request by admin.", client, target);

		return Plugin_Handled;
	}

	CShowActivity2(client, sTag, "%t", "Admin Force Last Request Self");
	LastRequestStart(client, client, true, true);
	Jail_Log(false, "%N has given his/herself last request using admin.", client);

	return Plugin_Handled;
}

public Action AdminResetPlugin(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	for (int i = 1; i <= MaxClients; i++)
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

		iFirstKill[i] = 0;
		iKillcount[i] = 0;
		iHasBeenWarden[i] = 0;

		sOldModel[i][0] = '\0';
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
	bWardenBackstabbed = false;

	iWarden = -1;
	iWardenLimit = 0;
	iFreedayLimit = 0;

	EnumWardenMenu = Open;

	ParseConfigs();
	ParseLastRequestConfig();
	BuildMenus();

	CReplyToCommand(client, "%t %t", "plugin tag", "Admin Reset Plugin");
	Jail_Log(false, "%N has reset the plugin of all its bools, integers and floats.", client);

	return Plugin_Handled;
}

public Action AdminMapCompatibilityCheck(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (strlen(sCellNames) != 0)
	{
		int cell_door = Entity_FindByName(sCellNames, "func_door");
		CReplyToCommand(client, "%t %t", "plugin tag", IsValidEntity(cell_door) ? "Map Compatibility Cell Doors Detected" : "Map Compatibility Cell Doors Undetected");
	}

	if (strlen(sCellOpener) != 0)
	{
		int open_cells = Entity_FindByName(sCellOpener, "func_button");
		CReplyToCommand(client, "%t %t", "plugin tag", IsValidEntity(open_cells) ? "Map Compatibility Cell Opener Detected" : "Map Compatibility Cell Opener Undetected");
	}

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Scan Map Compatibility");

	Jail_Log(false, "%N has checked the map for compatibility.", client);

	return Plugin_Handled;
}

public Action AdminGiveFreeday(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		int target = FindTarget(client, sArg, true);

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

		char sTag[64];
		Format(sTag, sizeof(sTag), "%t", "plugin tag");
		CShowActivity2(client, sTag, "%t", "Admin Give Freeday", target);

		GiveFreeday(target);
		Jail_Log(false, "%N has given %N a Freeday.", target, client);

		return Plugin_Handled;
	}

	GiveFreedaysMenu(client);
	return Plugin_Handled;
}

public Action AdminRemoveFreeday(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bLRConfigActive)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "last request config invalid");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char sArg[64];
		GetCmdArgString(sArg, sizeof(sArg));

		int target = FindTarget(client, sArg, true);

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

		char sTag[64];
		Format(sTag, sizeof(sTag), "%t", "plugin tag");
		CShowActivity2(client, sTag, "%t", "Admin Remove Freeday", target);

		RemoveFreeday(target);
		Jail_Log(false, "%N has given %N a Freeday.", target, client);

		return Plugin_Handled;
	}

	RemoveFreedaysMenu(client);
	return Plugin_Handled;
}

public Action AdminAcceptWardenChange(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");

	switch (EnumWardenMenu)
	{
		case Open:CReplyToCommand(client, "%t %t", "plugin tag", "no warden requests queued");
		case FriendlyFire:
		{
			SetConVarBool(hEngineConVars[0], true);
			CShowActivity2(client, sTag, "%t", "Admin Accept Request FF", iWarden);
			CPrintToChatAll("%t %t", "plugin tag", "friendlyfire enabled");
			Jail_Log(false, "%N has accepted %N's request to enable Friendly Fire.", client, iWarden);
		}
		case Collision:
		{
			SetConVarBool(hEngineConVars[1], true);
			CShowActivity2(client, sTag, "%t", "Admin Accept Request CC", iWarden);
			CPrintToChatAll("%t %t", "plugin tag", "collision enabled");
			Jail_Log(false, "%N has accepted %N's request to enable Collision.", client, iWarden);
		}
	}
	return Plugin_Handled;
}

public Action AdminCancelWardenChange(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");

	switch (EnumWardenMenu)
	{
		case Open:CReplyToCommand(client, "%t %t", "plugin tag", "no warden requests active");
		case FriendlyFire:
		{
			SetConVarBool(hEngineConVars[0], false);
			CShowActivity2(client, sTag, "%t", "Admin Cancel Active FF");
			CPrintToChatAll("%t %t", "plugin tag", "friendlyfire disabled");
			Jail_Log(false, "%N has cancelled %N's request for Friendly Fire.", client, iWarden);
		}
		case Collision:
		{
			SetConVarBool(hEngineConVars[1], false);
			CShowActivity2(client, sTag, "%t", "Admin Cancel Active CC");
			CPrintToChatAll("%t %t", "plugin tag", "collision disabled");
			Jail_Log(false, "%N has cancelled %N's request for Collision.", client, iWarden);
		}
	}

	EnumWardenMenu = Open;

	return Plugin_Handled;
}

public Action AdminLockWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (bAdminLockWarden)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden already locked");
		return Plugin_Handled;
	}

	if (WardenExists())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && IsWarden(i))
			{
				WardenUnset(i);
			}
		}
	}

	bAdminLockWarden = true;

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Lock Warden");

	Jail_Log(false, "%N has locked Warden via administration.", client);

	return Plugin_Handled;
}

public Action AdminUnlockWarden(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

	if (!bAdminLockWarden)
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "warden not locked");
		return Plugin_Handled;
	}

	bAdminLockWarden = false;

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Unlock Warden");

	Jail_Log(false, "%N has unlocked Warden via administration.", client);

	return Plugin_Handled;
}

public Action AdminMarkFreekiller(int client, int args)
{
	if (!cv_Enabled)return Plugin_Handled;

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

	char sArg[64];
	GetCmdArgString(sArg, sizeof(sArg));

	int target = FindTarget(client, sArg, true);

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

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Mark Freekiller", target);

	MarkFreekiller(target);
	Jail_Log(false, "%L has marked %L as a Free Killer.", client, target);

	return Plugin_Handled;
}

/* Menu Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

void PardonFreekillersMenu(int client)
{
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return;
	}

	if (IsVoteInProgress())return;

	Handle hMenu = CreateMenu(MenuHandle_PardonFreekillers);
	SetMenuTitle(hMenu, "%s", "choose a player");

	char sUserID[12]; char sName[MAX_NAME_LENGTH + 12];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreekiller[i])
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sName, sizeof(sName), "%L", i);
			AddMenuItem(hMenu, sUserID, sName);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Pardon Freekiller Menu");

	Jail_Log(false, "%N has pardoned someone currently marked Freekillers...", client);
}

public int MenuHandle_PardonFreekillers(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(StringToInt(sInfo));
			if (!Client_IsIngame(target))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
				PardonFreekillersMenu(param1);
				return;
			}

			ClearFreekiller(target);
			Jail_Log(false, "%N has cleared %N as a Freekiller.", target, param1);

			PardonFreekillersMenu(param1);
		}
		case MenuAction_End:CloseHandle(hMenu);
	}
}

void GiveFreedaysMenu(int client)
{
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return;
	}

	if (IsVoteInProgress())return;

	Handle hMenu = CreateMenu(MenuHandle_FreedayAdmins);
	SetMenuTitle(hMenu, "%s", "choose a player");

	char sUserID[12]; char sDisplay[MAX_NAME_LENGTH + 12];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !bIsFreeday[i])
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sDisplay, sizeof(sDisplay), "%L", i);
			AddMenuItem(hMenu, sUserID, sDisplay);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Give Freeday Menu");

	Jail_Log(false, "%N is giving someone a freeday...", client);
}

public int MenuHandle_FreedayAdmins(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(StringToInt(sInfo));
			if (!Client_IsIngame(target))
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "Player no longer available");
				GiveFreedaysMenu(param1);
				return;
			}

			GiveFreeday(target);
			Jail_Log(false, "%N has given %N a Freeday.", target, param1);

			GiveFreedaysMenu(param1);
		}
		case MenuAction_End:CloseHandle(hMenu);
	}
}

void RemoveFreedaysMenu(int client)
{
	if (!Client_IsIngame(client))
	{
		CReplyToCommand(client, "%t %t", "plugin tag", "Command is in-game only");
		return;
	}

	if (IsVoteInProgress())return;

	Handle hMenu = CreateMenu(MenuHandle_RemoveFreedays);
	SetMenuTitle(hMenu, "%s", "choose a player");

	char sUserID[12]; char sName[MAX_NAME_LENGTH + 12];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreeday[i])
		{
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sName, sizeof(sName), "%L", i);
			AddMenuItem(hMenu, sUserID, sName);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");
	CShowActivity2(client, sTag, "%t", "Admin Remove Freeday Menu");

	Jail_Log(false, "%N is removing someone's freeday status...", client);
}

public int MenuHandle_RemoveFreedays(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(StringToInt(sInfo));

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
			Jail_Log(false, "%N has removed %N's Freeday.", param1, target);

			RemoveFreedaysMenu(param1);
		}
		case MenuAction_End:CloseHandle(hMenu);
	}
}

void WardenMenu(int client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	DisplayMenu(hWardenMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandle_WardenMenu(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
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

public int MenuHandle_ForceLR(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(StringToInt(sInfo));

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

			if (TF2_GetClientTeam(target) != TFTeam_Red)
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "prisoners only");
				return;
			}

			LastRequestStart(target, param1);
			CPrintToChatAll("%t %t", "plugin tag", "last request given", iWarden, target);
			Jail_Log(false, "%N has given %N a Last Request as Warden.", param1, target);
		}
		case MenuAction_End:CloseHandle(hMenu);
	}
}

public int MenuHandle_WardenModels(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			strcopy(sWardenModel[param1], sizeof(sWardenModel[]), sInfo);
			CPrintToChat(param1, "%t %t", "plugin tag", "warden model set", sWardenModel[param1]);
		}
	}
}

void ListLastRequests(int client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	DisplayMenu(hListLRsMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandle_ListLRs(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");
			FileToKeyValues(hConfig, sLRConfig);

			if (KvGotoFirstSubKey(hConfig))
			{
				char sSectionIDs[256];
				do {
					KvGetSectionName(hConfig, sSectionIDs, sizeof(sSectionIDs));
					if (StrEqual(sSectionIDs, sInfo))
					{
						char sDescription[256];
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

void FreedayforClientsMenu(int client, bool active = false, bool rep = false)
{
	if (IsVoteInProgress())
	{
		return;
	}

	Handle hMenu = CreateMenu(active ? MenuHandle_FreedayForClientsActive : MenuHandle_FreedayForClients);
	SetMenuTitle(hMenu, "%s", "choose a player");
	SetMenuExitBackButton(hMenu, false);

	char sUserID[12]; char sName[MAX_NAME_LENGTH + 12];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			if (active)if (!IsPlayerAlive(i))continue;

			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			Format(sName, sizeof(sName), "%L", i);
			AddMenuItem(hMenu, sUserID, sName);
		}
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	if (rep)CPrintToChatAll("%t %t", "plugin tag", "lr freeday picking clients", client);
}

public int MenuHandle_FreedayForClients(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(StringToInt(sInfo));

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
		case MenuAction_End:CloseHandle(hMenu);
	}
}

public int MenuHandle_FreedayForClientsActive(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(StringToInt(sInfo));

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
		case MenuAction_End:CloseHandle(hMenu);
	}
}

void PreferenceMenu(int client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	Handle hMenu = CreateMenu(MenuHandle_Preferences);
	SetMenuTitle(hMenu, "%s", "preferences title");

	char sValue[64];

	Format(sValue, sizeof(sValue), "%s", bRolePreference_Blue[client] ? "Blue Preference [ON]" : "Blue Preference [OFF]");
	AddMenuItem(hMenu, "Pref_Blue", sValue, cv_PrefBlue ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(sValue, sizeof(sValue), "%s", bRolePreference_Warden[client] ? "Warden Preference [ON]" : "Warden Preference [OFF]");
	AddMenuItem(hMenu, "Pref_Warden", sValue, cv_PrefWarden ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandle_Preferences(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
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
		case MenuAction_End:CloseHandle(hMenu);
	}
}

void LastRequestStart(int client, int sender = 0, bool Timer = true, bool lock = false)
{
	if (IsVoteInProgress())
	{
		return;
	}

	Handle hStartLRMenu = CreateMenu(MenuHandle_GiveLR);
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
		KillTimerSafe(hTimer_RoundTimer);
	}

	if (lock)
	{
		CPrintToChatAll("%t %t", "plugin tag", "force lr admin lock", sender, client);
		bAdminLockedLR = true;
	}
}

public int MenuHandle_GiveLR(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));

			Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");

			if (!FileToKeyValues(hConfig, sLRConfig))
			{
				Jail_Log(false, "Last requests menu seems to be empty, please verify its integrity.");
				CPrintToChatAll("%t %t", "plugin tag", "last request config invalid");
				CloseHandle(hConfig);
				return;
			}

			if (cv_RemoveFreedayOnLR)
			{
				for (int i = 1; i <= MaxClients; i++)
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
				Jail_Log(false, "Last request ID '%s' not found in the configuration file, please verify integrity of configuration file.", sInfo);
				CloseHandle(hConfig);
				return;
			}

			char sAnnounce[256]; char sClientName[MAX_NAME_LENGTH]; char sActive[256];

			GetClientName(param1, sClientName, sizeof(sClientName));

			char Handler[128];
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

			bool ActiveRound = false;
			if (KvJumpToKey(hConfig, "Parameters"))
			{
				ActiveRound = view_as<bool>(KvGetNum(hConfig, "ActiveRound", 0));
				KvGoBack(hConfig);
			}

			if (ActiveRound)
			{
				if (!bActiveRound)
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "lr cannot pick active round");
					return;
				}

				hLastRequestUses.Set(StringToInt(sInfo), hLastRequestUses.Get(StringToInt(sInfo)) + 1);

				Call_StartForward(sFW_OnLastRequestExecute);
				Call_PushString(Handler);
				Call_Finish();

				if (KvGetString(hConfig, "Activated", sActive, sizeof(sActive)))
				{
					ReplaceString(sActive, sizeof(sActive), "{NAME}", sClientName, true);
					CPrintToChatAll("%t %s", "plugin tag", sActive);
				}

				char sExecute[256];
				if (KvGetString(hConfig, "Execute_Cmd", sExecute, sizeof(sExecute)))
				{
					char sIndex[64];
					IntToString(GetClientUserId(param1), sIndex, sizeof(sIndex));
					ReplaceString(sExecute, sizeof(sExecute), "{client}", sIndex);

					if (strlen(sExecute) != 0)
					{
						Handle dp;
						CreateDataTimer(0.5, ExecuteServerCommand, dp, TIMER_FLAG_NO_MAPCHANGE);
						WritePackString(dp, sExecute);
					}
				}

				if (eTF2WeaponRestrictions)
				{
					char sWeaponsConfig[256];
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
						case 3: //Freeday For All
						{
							//N/A
						}
						case 2: //Freeday For Clients
						{
							FreedayforClientsMenu(param1, true, true);
						}
						case 1: //Freeday for Yourself
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

					if (KvGetNum(hConfig, "TimerStatus", 1) == 1)
					{
						KillTimerSafe(hTimer_RoundTimer);
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
						for (int i = 1; i < MaxClients; i++)
						{
							if (Client_IsIngame(i) && IsPlayerAlive(i))
							{
								switch (TF2_GetClientTeam(i))
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
							float TimeFloat = KvGetFloat(hConfig, "Timer", 1.0);
							if (TimeFloat >= 0.1)
							{
								hTimer_FriendlyFireEnable = CreateTimer(TimeFloat, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
							}
							else
							{
								Jail_Log(false, "[ERROR] Timer is set to a value below 0.1! Timer could not be created.");
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
						case 3: //Freeday For All
						{
							//N/A
						}
						case 2: //Freeday For Clients
						{
							FreedayforClientsMenu(param1, false, true);
						}
						case 1: //Freeday For Yourself
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
bool GiveFreeday(int client)
{
	if (client == 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}

	CPrintToChat(client, "%t %t", "plugin tag", "lr freeday message");

	int flags = GetEntityFlags(client) | FL_NOTARGET;
	SetEntityFlags(client, flags);

	if (cv_FreedayTeleports && bFreedayTeleportSet)
	{
		TeleportEntity(client, fFreedayPosition, NULL_VECTOR, NULL_VECTOR);
	}

	if (cv_RendererParticles && strlen(sFreedaysParticle) != 0)
	{
		if (iParticle_Freedays[client] != INVALID_ENT_REFERENCE)
		{
			int old = EntRefToEntIndex(iParticle_Freedays[client]);

			if (IsValidEntity(old))
			{
				AcceptEntityInput(old, "Kill");
			}
		}

		iParticle_Freedays[client] = CreateParticle2(sFreedaysParticle, 0.0, client, ATTACH_NORMAL);
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iFreedaysColors[0], a_iFreedaysColors[1], a_iFreedaysColors[2], a_iFreedaysColors[3]);
	}

	bIsQueuedFreeday[client] = false;
	bIsFreeday[client] = true;
	Jail_Log(false, "%N has been given a Freeday.", client);

	Call_StartForward(sFW_OnFreedayGiven);
	Call_PushCell(client);
	Call_Finish();

	return true;
}

bool RemoveFreeday(int client)
{
	if (client == 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}

	CPrintToChatAll("%t %t", "plugin tag", "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	int flags = GetEntityFlags(client) & ~FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	bIsFreeday[client] = false;

	if (iParticle_Freedays[client] != INVALID_ENT_REFERENCE)
	{
		int old = EntRefToEntIndex(iParticle_Freedays[client]);

		if (IsValidEntity(old))
		{
			AcceptEntityInput(old, "Kill");
		}

		iParticle_Freedays[client] = -1;
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);
	}

	Jail_Log(false, "%N is no longer a Freeday.", client);

	Call_StartForward(sFW_OnFreedayRemoved);
	Call_PushCell(client);
	Call_Finish();

	return true;
}

bool MarkRebel(int client)
{
	if (bIsRebel[client])
	{
		return false;
	}

	bIsRebel[client] = true;

	if (cv_RendererParticles && strlen(sRebellersParticle) != 0)
	{
		if (iParticle_Rebels[client] != INVALID_ENT_REFERENCE)
		{
			int old = EntRefToEntIndex(iParticle_Rebels[client]);

			if (IsValidEntity(old))
			{
				AcceptEntityInput(old, "Kill");
			}
		}

		iParticle_Rebels[client] = CreateParticle2(sRebellersParticle, 0.0, client, ATTACH_NORMAL);
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iRebellersColors[0], a_iRebellersColors[1], a_iRebellersColors[2], a_iRebellersColors[3]);
	}

	if (cv_RebelsTime > 0.0)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "rebel timer start", RoundFloat(cv_RebelsTime));

		KillTimerSafe(hTimer_RebelTimers[client]);
		hTimer_RebelTimers[client] = CreateTimer(cv_RebelsTime, Timer_RemoveRebel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	CPrintToChatAll("%t %t", "plugin tag", "prisoner has rebelled", client);
	Jail_Log(false, "%N has been marked as a Rebeller.", client);

	Call_StartForward(sFW_OnRebelGiven);
	Call_PushCell(client);
	Call_Finish();

	return true;
}

void ClearRebel(int client)
{
	if (!bIsRebel[client])
	{
		return;
	}

	bIsRebel[client] = false;

	if (iParticle_Rebels[client] != INVALID_ENT_REFERENCE)
	{
		int old = EntRefToEntIndex(iParticle_Rebels[client]);

		if (IsValidEntity(old))
		{
			AcceptEntityInput(old, "Kill");
		}

		iParticle_Rebels[client] = INVALID_ENT_REFERENCE;
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);
	}

	KillTimerSafe(hTimer_RebelTimers[client]);

	Call_StartForward(sFW_OnRebelRemoved);
	Call_PushCell(client);
	Call_Finish();
}

bool MarkFreekiller(int client, bool avoid = false)
{
	if (avoid && bVoidFreeKills)
	{
		CPrintToChatAll("%t %t", "plugin tag", "freekiller flagged while void", client);
		return false;
	}

	if (bIsFreekiller[client])
	{
		return false;
	}

	bIsFreekiller[client] = true;

	if (cv_RendererParticles && strlen(sFreekillersParticle) != 0)
	{
		if (iParticle_Freekillers[client] != INVALID_ENT_REFERENCE)
		{
			int old = EntRefToEntIndex(iParticle_Freekillers[client]);

			if (IsValidEntity(old))
			{
				AcceptEntityInput(old, "Kill");
			}
		}

		iParticle_Freekillers[client] = CreateParticle2(sFreekillersParticle, 0.0, client, ATTACH_NORMAL);
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iFreekillersColors[0], a_iFreekillersColors[1], a_iFreekillersColors[2], a_iFreekillersColors[3]);
	}

	TF2_RemoveAllWeapons(client);
	EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
	CPrintToChatAll("%t %t", "plugin tag", "freekiller timer start", client, RoundFloat(cv_FreekillersWave));

	char sAuth[24];
	GetClientAuthId(client, AuthId_Engine, sAuth, sizeof(sAuth[]));

	char sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName[]));

	Handle pack;
	hTimer_FreekillingData = CreateDataTimer(cv_FreekillersWave, BanClientTimerFreekiller, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, GetClientUserId(client));
	WritePackString(pack, sAuth);
	WritePackString(pack, sName);

	Jail_Log(false, "%N has been marked as a Freekiller.", client);

	Call_StartForward(sFW_OnFreekillerGiven);
	Call_PushCell(client);
	Call_Finish();

	return true;
}

void ClearFreekiller(int client)
{
	if (!bIsFreekiller[client])
	{
		return;
	}

	bIsFreekiller[client] = false;

	TF2_RegeneratePlayer(client);

	KillTimerSafe(hTimer_FreekillingData);

	if (iParticle_Freekillers[client] != INVALID_ENT_REFERENCE)
	{
		int old = EntRefToEntIndex(iParticle_Freekillers[client]);

		if (IsValidEntity(old))
		{
			AcceptEntityInput(old, "Kill");
		}

		iParticle_Freekillers[client] = -1;
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);
	}

	Jail_Log(false, "%N has been cleared as a Freekiller.", client);

	Call_StartForward(sFW_OnFreekillerRemoved);
	Call_PushCell(client);
	Call_Finish();
}

bool AlreadyMuted(int client)
{
	switch (eSourceComms)
	{
		case true:
		{
			return view_as<bool>(SourceComms_GetClientMuteType(client) != bNot);
		}
		case false:
		{
			return view_as<bool>(BaseComm_IsClientMuted(client));
		}
	}

	return false;
}

void ConvarsSet(bool Status = false)
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

bool IsWarden(int client)
{
	return view_as<bool>(client == iWarden);
}

bool WardenExists()
{
	return view_as<bool>(iWarden != -1);
}

void MutePlayer(int client)
{
	if (!AlreadyMuted(client) && !IsVIP(client) && !bIsMuted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		bIsMuted[client] = true;
		CPrintToChat(client, "%t %t", "plugin tag", "muted player");

		Jail_Log(true, "Client '%N' is muted by the plugin.", client);
	}
}

void UnmutePlayer(int client)
{
	if (bIsMuted[client])
	{
		UnmuteClient(client);
		bIsMuted[client] = false;
		CPrintToChat(client, "%t %t", "plugin tag", "unmuted player");

		Jail_Log(true, "Client '%N' is unmuted by the plugin.", client);
	}
}

void ParseLastRequests(int client, Handle hMenu)
{
	Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");

	if (FileToKeyValues(hConfig, sLRConfig) && KvGotoFirstSubKey(hConfig))
	{
		char sLRID[64]; char sLRName[256];
		do {
			bool IsDisabled = false;
			KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
			KvGetString(hConfig, "Name", sLRName, sizeof(sLRName));

			if (KvJumpToKey(hConfig, "Parameters"))
			{
				int disabled = KvGetNum(hConfig, "Disabled", 0);
				int CurrentUses = hLastRequestUses.Get(StringToInt(sLRID));
				int Permitted = KvGetNum(hConfig, "UsesPerMap", 3);

				switch (disabled)
				{
					case 1:Format(sLRName, sizeof(sLRName), "[Disabled] %s", sLRName);
					case 0:Format(sLRName, sizeof(sLRName), "[%i/%i] %s", CurrentUses, Permitted, sLRName);
				}

				bool VIPCheck = false; bool GrantAccess = false;
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

void ParseConfigs()
{
	ParseMapConfig();
	ParseNodeConfig();
	ParseLastRequestConfig(true);
	ParseRoleRenderersConfig();
	ParseWardenModelsConfig(true);
}

void ParseMapConfig()
{
	Handle hConfig = CreateKeyValues("TF2Jail_MapConfig");

	char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/mapconfig.cfg");

	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	Jail_Log(false, "Loading last request configuration entry for map '%s'...", sMapName);

	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvJumpToKey(hConfig, sMapName))
		{
			char CellNames[32]; char CellsButton[32]; char FFButton[32];

			KvGetString(hConfig, "CellNames", CellNames, sizeof(CellNames), "");
			if (strlen(CellNames) != 0)
			{
				int iCelldoors = Entity_FindByName(CellNames, "func_door");
				if (IsValidEntity(iCelldoors))
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
				int iCellOpener = Entity_FindByName(CellsButton, "func_button");
				if (IsValidEntity(iCellOpener))
				{
					sCellOpener = CellsButton;
				}
			}

			KvGetString(hConfig, "FFButton", FFButton, sizeof(FFButton), "");
			if (strlen(FFButton) != 0)
			{
				int iFFButton = Entity_FindByName(FFButton, "func_button");
				if (IsValidEntity(iFFButton))
				{
					sCellOpener = FFButton;
				}
			}

			if (KvJumpToKey(hConfig, "Freeday"))
			{
				if (KvJumpToKey(hConfig, "Teleport"))
				{
					bFreedayTeleportSet = view_as<bool>(KvGetNum(hConfig, "Status", 1));

					if (bFreedayTeleportSet)
					{
						char sCoordinates[128];
						KvGetString(hConfig, "Coordinates", sCoordinates, sizeof(sCoordinates));

						if (StrContains(sCoordinates, ",") != -1)
						{
							char sExplodedCoords[3][32];
							ExplodeString(sCoordinates, ", ", sExplodedCoords, 3, 20);

							fFreedayPosition[0] = StringToFloat(sExplodedCoords[0]);
							fFreedayPosition[1] = StringToFloat(sExplodedCoords[1]);
							fFreedayPosition[2] = StringToFloat(sExplodedCoords[2]);
						}
						else
						{
							KvGetVector(hConfig, "Coordinates", fFreedayPosition);
						}

						Jail_Log(false, "Freeday teleport coordinates set for the map '%s' - X: %d, Y: %d, Z: %d", sMapName, fFreedayPosition[0], fFreedayPosition[1], fFreedayPosition[2]);
					}

					KvGoBack(hConfig);
				}
				else
				{
					bFreedayTeleportSet = false;
					Jail_Log(false, "Could not find subset key for 'Freeday' - 'Teleport', disabling functionality for Freeday Teleportation.");
				}
				KvGoBack(hConfig);
			}
			else
			{
				bFreedayTeleportSet = false;
				Jail_Log(false, "Could not find subset 'Freeday', disabling functionality for Freedays via Map.");
			}
		}
		else
		{
			bIsMapCompatible = false;
			bFreedayTeleportSet = false;
			Jail_Log(false, "Map '%s' is missing from configuration file, please verify integrity of your installation.", sMapName);
		}
	}
	else
	{
		bIsMapCompatible = false;
		bFreedayTeleportSet = false;
		Jail_Log(false, "Configuration file is invalid or not found, please verify integrity of your installation.");
	}

	Jail_Log(false, "Map configuration for '%s' has been parsed and loaded.", sMapName);
	CloseHandle(hConfig);
}

void ParseNodeConfig()
{
	Handle hConfig = CreateKeyValues("TF2Jail_Nodes");

	char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/textnodes.cfg");

	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvGotoFirstSubKey(hConfig, false))
		{
			int count = 0;
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
		Jail_Log(false, "Couldn't parse text node configuration file, please verify its integrity.");
	}

	CloseHandle(hConfig);
}

void ParseLastRequestConfig(bool DefaultValue = false)
{
	Handle hConfig = CreateKeyValues("TF2Jail_LastRequests");

	int iSize = 0;
	if (FileToKeyValues(hConfig, sLRConfig))
	{
		if (KvGotoFirstSubKey(hConfig, false))
		{
			do {
				iSize++;

			} while (KvGotoNextKey(hConfig, false));
		}
	}

	hLastRequestUses.Resize(iSize);

	if (DefaultValue)
	{
		for (int i = 0; i < hLastRequestUses.Length; i++)
		{
			hLastRequestUses.Set(i, 0);
		}
	}

	CloseHandle(hConfig);
}

void ParseRoleRenderersConfig()
{
	Handle hConfig = CreateKeyValues("TF2Jail_RoleRenders");

	char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/rolerenderers.cfg");

	if (!FileToKeyValues(hConfig, sConfig))
	{
		Jail_Log(false, "Couldn't parse role renderers configuration file, please verify its integrity.");
		CloseHandle(hConfig);
		return;
	}

	SetRoleRender(hConfig, "Warden", a_iWardenColors, sWardenParticle, sizeof(sWardenParticle));
	SetRoleRender(hConfig, "Freedays", a_iFreedaysColors, sFreedaysParticle, sizeof(sFreedaysParticle));
	SetRoleRender(hConfig, "Rebellers", a_iRebellersColors, sRebellersParticle, sizeof(sRebellersParticle));
	SetRoleRender(hConfig, "Freekillers", a_iFreekillersColors, sFreekillersParticle, sizeof(sFreekillersParticle));

	CloseHandle(hConfig);
}

void SetRoleRender(Handle hConfig, const char[] sRole, int iColor[4], char[] sParticle, int size)
{
	if (KvJumpToKey(hConfig, sRole))
	{
		iColor[0] = 256, iColor[1] = 256, iColor[2] = 256, iColor[3] = 256;
		KvGetColor(hConfig, "Color", iColor[0], iColor[1], iColor[2], iColor[3]);

		KvGetString(hConfig, "Particle", sParticle, size);
		KvGoBack(hConfig);
	}
}

void ParseWardenModelsConfig(bool MenuOnly = false)
{
	if (!MenuOnly)
	{
		hWardenSkinClasses.Clear();
		hWardenSkins.Clear();
	}

	if (MenuOnly && hWardenModelsMenu == null)
	{
		return;
	}
	else if (hWardenModelsMenu != null)
	{
		RemoveAllMenuItems(hWardenModelsMenu);
	}

	Handle hConfig = CreateKeyValues("TF2Jail_WardenModels");

	char sWardenModelsConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sWardenModelsConfig, sizeof(sWardenModelsConfig), "configs/tf2jail/wardenmodels.cfg");
	FileToKeyValues(hConfig, sWardenModelsConfig);

	if (KvGotoFirstSubKey(hConfig, false))
	{
		do {
			char sName[64];
			KvGetSectionName(hConfig, sName, sizeof(sName));

			char sModel[64];
			KvGetString(hConfig, "model", sModel, sizeof(sModel));

			char sClass[64];
			KvGetString(hConfig, "class", sClass, sizeof(sClass), "none");

			if (strlen(sModel) == 0)
			{
				Jail_Log(false, "ERROR: Model for '%s' not set, please add it. Skipping this model.", sName);
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

					PrecacheModel(sModel);
					AddFileToDownloadsTable(sModel);
					hWardenSkins.SetString(sName, sModel, false);
					AddMenuItem(hWardenModelsMenu, sName, sName);
				}
				case false:
				{
					Jail_Log(false, "ERROR: Main model file is missing for Warden Model '%s'. Skipping this model.", sName);
					continue;
				}
			}

			hWardenSkinClasses.SetString(sName, sClass, false);

			if (KvJumpToKey(hConfig, "files"))
			{
				if (KvGotoFirstSubKey(hConfig, false))
				{
					do {
						char sDownload[PLATFORM_MAX_PATH];
						KvGetString(hConfig, NULL_STRING, sDownload, sizeof(sDownload));

						switch (FileExists(sDownload, true))
						{
							case true:
							{
								PrecacheModel(sDownload);
								AddFileToDownloadsTable(sDownload);
							}
							case false:Jail_Log(false, "WARNING: File '%s' is missing for Warden Model '%s'.", sDownload, sName);
						}
					} while (KvGotoNextKey(hConfig, false));
					KvGoBack(hConfig);
				}
				else
				{
					Jail_Log(false, "ERROR: Files subsection is empty for Warden model '%s'. Skipping this model.", sName);
					continue;
				}
			}
			else
			{
				Jail_Log(false, "ERROR: No files set to download for Warden model '%s'. Skipping this model.", sName);
				continue;
			}

		} while (KvGotoNextKey(hConfig, false));
	}

	CloseHandle(hConfig);
}

void BuildMenus()
{
	//Wardens Menu
	if (hWardenMenu != null)
	{
		CloseHandle(hWardenMenu);
		hWardenMenu = null;
	}

	hWardenMenu = CreateMenu(MenuHandle_WardenMenu);
	SetMenuTitle(hWardenMenu, "%s", "warden commands");
	SetMenuExitButton(hWardenMenu, true);

	Handle hConfig = CreateKeyValues("WardenMenu");

	char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/tf2jail/wardenmenu.cfg");

	FileToKeyValues(hConfig, sConfig);
	KvGotoFirstSubKey(hConfig, false);
	do {
		char sLRID[64]; char sLRName[256];
		KvGetSectionName(hConfig, sLRID, sizeof(sLRID));
		KvGetString(hConfig, NULL_STRING, sLRName, sizeof(sLRName));
		AddMenuItem(hWardenMenu, sLRID, sLRName);
	} while (KvGotoNextKey(hConfig, false));
	CloseHandle(hConfig);

	//List of Last Requests Menu
	if (hListLRsMenu != null)
	{
		CloseHandle(hListLRsMenu);
		hListLRsMenu = null;
	}

	hListLRsMenu = CreateMenu(MenuHandle_ListLRs);
	SetMenuTitle(hListLRsMenu, "%s", "list last requests");
	SetMenuExitButton(hListLRsMenu, true);

	hConfig = CreateKeyValues("TF2Jail_LastRequests");
	if (FileToKeyValues(hConfig, sLRConfig) && KvGotoFirstSubKey(hConfig))
	{
		char sLRID[64]; char sLRName[256];
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
					int Permitted = KvGetNum(hConfig, "UsesPerMap", 3);
					int CurrentUses = hLastRequestUses.Get(StringToInt(sLRID));
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
	if (hWardenModelsMenu != null)
	{
		CloseHandle(hWardenModelsMenu);
		hWardenModelsMenu = null;
	}

	hWardenModelsMenu = CreateMenu(MenuHandle_WardenModels);
	SetMenuTitle(hWardenModelsMenu, "%s", "warden models title");

	//If 1st parameter boolean is true, load the menu with items available but nothing else. A map change is required to precache and load files for models properly.
	ParseWardenModelsConfig(true);
}

void EmptyWeaponSlots(int client)
{
	int offset = Client_GetWeaponsOffset(client) - 4;

	for (int i = 0; i < 2; i++)
	{
		offset += 4;

		int weapon = GetEntDataEnt2(client, offset);

		if (!IsValidEntity(weapon) || i == TFWeaponSlot_Melee)
		{
			continue;
		}

		int clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
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

void Jail_Log(bool bDebug, const char[] sFormat, any...)
{
	if (bDebug && !cv_bDebugs)
	{
		return;
	}

	//Format what we need based on the extra data passed through the parameters.
	char sLog[2048];
	VFormat(sLog, sizeof(sLog), sFormat, 3);

	//Remove all the color tags since we're using this for logging.
	CRemoveTags(sLog, sizeof(sLog));

	switch (cv_Logging)
	{
		case 1: LogMessage(sLog);
		case 2:
		{
			char sDate[32];
			FormatTime(sDate, sizeof(sDate), "%Y-%m-%d", GetTime());

			char sPath[PLATFORM_MAX_PATH]; char sPathFinal[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "logs/TF2Jail_%s.log", sDate);
			BuildPath(Path_SM, sPathFinal, sizeof(sPathFinal), sPath);
			LogToFileEx(sPathFinal, "%s%s", bDebug ? "[DEBUG]" : "", sLog);
		}
	}

	if (cv_ConsoleSpew)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!Client_IsIngame(i) || IsFakeClient(i))continue;

			SetGlobalTransTarget(i);
			PrintToConsole(i, sLog);
		}
	}
}

void DoorHandler(eDoorsMode status)
{
	if (strlen(sCellNames) != 0)
	{
		for (int i = 0; i < sizeof(sDoorsList); i++)
		{
			char sEntityName[128]; int ent = -1;
			while ((ent = FindEntityByClassnameSafe(ent, sDoorsList[i])) != -1)
			{
				GetEntPropString(ent, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
				if (StrEqual(sEntityName, sCellNames, false))
				{
					switch (status)
					{
						case OPEN:AcceptEntityInput(ent, "Open");
						case CLOSE:AcceptEntityInput(ent, "Close");
						case LOCK:AcceptEntityInput(ent, "Lock");
						case UNLOCK:AcceptEntityInput(ent, "Unlock");
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
			case CLOSE:CPrintToChatAll("%t %t", "plugin tag", "doors closed");
			case LOCK:CPrintToChatAll("%t %t", "plugin tag", "doors locked");
			case UNLOCK:CPrintToChatAll("%t %t", "plugin tag", "doors unlocked");
		}
	}
}

void UnmuteClient(int client)
{
	static Handle cvDeadTalk = null;

	if (cvDeadTalk == null)
	{
		cvDeadTalk = FindConVar("sm_deadtalk");
	}

	if (cvDeadTalk == null)
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

void FindRandomWarden()
{
	if (cv_WardenAuto)
	{
		int client = Client_GetRandom(CLIENTFILTER_TEAMTWO | CLIENTFILTER_ALIVE | CLIENTFILTER_NOBOTS);

		if (Client_IsIngame(client))
		{
			if (cv_PrefStatus)
			{
				if (bRolePreference_Warden[client])
				{
					WardenSet(client);
					Jail_Log(false, "%N has been set to Warden automatically at the start of this arena round.", client);
				}
				else
				{
					Jail_Log(false, "%N has preferred settings set to Prisoner only.", client);
					FindRandomWarden();
				}
			}
			else
			{
				WardenSet(client);
				Jail_Log(false, "%N has been set to Warden automatically at the start of this arena round.", client);
			}
		}
	}
}

public int TF2Jail_Preferences(int client, CookieMenuAction action, any info, char[] sDisplay, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_SelectOption:
		{
			PreferenceMenu(client);
		}
	}
}

void StartAdvertisement()
{
	hTimer_Advertisement = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

bool IsVIP(int client)
{
	return CheckCommandAccess(client, "TF2Jail_VIP", ADMFLAG_RESERVATION);
}

void SetTextNode(Handle node, const char[] sText, float X = -1.0, float Y = -1.0, float HoldTime = 5.0, int Red = 255, int Green = 255, int Blue = 255, int Alpha = 255, int Effect = 0, float fXTime = 6.0, float FadeIn = 0.1, float FadeOut = 0.2)
{
	SetHudTextParams(X, Y, HoldTime, Red, Green, Blue, Alpha, Effect, fXTime, FadeIn, FadeOut);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			ShowSyncHudText(i, node, sText);
		}
	}
}

void AddAttribute(int client, char[] sAttribute, float value)
{
	if (eTF2Attributes && Client_IsIngame(client))
	{
		TF2Attrib_SetByName(client, sAttribute, value);
	}
}

void AddAttribute2(int client, int iAttribute, float value)
{
	if (eTF2Attributes && Client_IsIngame(client))
	{
		TF2Attrib_SetByDefIndex(client, iAttribute, value);
	}
}

void RemoveAttribute(int client, char[] sAttribute)
{
	if (eTF2Attributes && Client_IsIngame(client))
	{
		TF2Attrib_RemoveByName(client, sAttribute);
	}
}

void RemoveAttribute2(int client, int iAttribute)
{
	if (eTF2Attributes && Client_IsIngame(client))
	{
		TF2Attrib_RemoveByDefIndex(client, iAttribute);
	}
}

int FindEntityByClassnameSafe(int iStart, char[] sClassName)
{
	while (iStart > -1 && !IsValidEntity(iStart))
	{
		iStart--;
	}

	return FindEntityByClassname(iStart, sClassName);
}

void RemoveValveHat(int client, bool unhide = false)
{
	char sNetClass[32];

	int edict = MaxClients + 1;
	while ((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
	{
		if (GetEntityNetClass(edict, sNetClass, sizeof(sNetClass)) && strcmp(sNetClass, "CTFWearable") == 0)
		{
			int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
	edict = MaxClients + 1;
	while ((edict = FindEntityByClassnameSafe(edict, "tf_powerup_bottle")) != -1)
	{
		if (GetEntityNetClass(edict, sNetClass, sizeof(sNetClass)) && strcmp(sNetClass, "CTFPowerupBottle") == 0)
		{
			int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}

bool StripToMelee(int client)
{
	if (client == 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}

	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);

	return true;
}

int CreateParticle2(const char[] sType, float refresh = 2.0, int client, int attach = NO_ATTACH, float xOffs = 0.0, float yOffs = 0.0, float zOffs = 0.0)
{
	int particle = CreateEntityByName("info_particle_system");

	if (IsValidEntity(particle))
	{
		float pos[3];
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

		if (refresh > 0.0)
		{
			Handle hPack;
			CreateDataTimer(1.0, CheckClient, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			WritePackFloat(hPack, 0.0);
			WritePackCell(hPack, GetClientUserId(client));
			WritePackCell(hPack, EntIndexToEntRef(particle));
			WritePackString(hPack, sType);
			WritePackFloat(hPack, refresh);
			WritePackCell(hPack, attach);
			WritePackFloat(hPack, xOffs);
			WritePackFloat(hPack, yOffs);
			WritePackFloat(hPack, zOffs);
		}
	}

	return EntIndexToEntRef(particle);
}

public Action CheckClient(Handle timer, Handle hPack)
{
	ResetPack(hPack);

	float time = ReadPackFloat(hPack);

	int client = GetClientOfUserId(ReadPackCell(hPack));
	int entity = EntRefToEntIndex(ReadPackCell(hPack));

	char sType[64];
	ReadPackString(hPack, sType, sizeof(sType));

	float refresh = ReadPackFloat(hPack);
	int attach = ReadPackCell(hPack);
	float xOffs = ReadPackFloat(hPack);
	float yOffs = ReadPackFloat(hPack);
	float zOffs = ReadPackFloat(hPack);

	if (!cv_RendererParticles || !Client_IsIngame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	time++;

	if (time <= refresh)
	{
		ResetPack(hPack);
		WritePackFloat(hPack, time);
		return Plugin_Continue;
	}

	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}

	int new_particle = CreateParticle2(sType, time, client, attach, xOffs, yOffs, zOffs);

	if (StrEqual(sType, sWardenParticle))
	{
		iParticle_Wardens[client] = new_particle;
	}
	else if (StrEqual(sType, sFreedaysParticle))
	{
		iParticle_Freedays[client] = new_particle;
	}
	else if (StrEqual(sType, sRebellersParticle))
	{
		iParticle_Rebels[client] = new_particle;
	}
	else if (StrEqual(sType, sFreekillersParticle))
	{
		iParticle_Freekillers[client] = new_particle;
	}

	return Plugin_Continue;
}

void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && Client_IsIngame(client) && IsPlayerAlive(client))
	{
		char sClassName[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, sClassName, sizeof(sClassName)))
		{
			FakeClientCommandEx(client, "use %s", sClassName);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

bool WardenSet(int client)
{
	if (WardenExists() || !bActiveRound)
	{
		return false;
	}

	iWarden = client;
	iHasBeenWarden[client]++;

	switch (cv_WardenVoice)
	{
		case 2:CPrintToChatAll("%t %t", "plugin tag", "warden voice muted", iWarden);
		case 1:SetClientListeningFlags(client, VOICE_NORMAL);
	}

	if (cv_BlueMute == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && TF2_GetClientTeam(i) == TFTeam_Blue && !IsWarden(i))
			{
				MutePlayer(i);
			}
		}
	}

	if (AlreadyMuted(client))
	{
		UnmutePlayer(client);
	}

	if (cv_WardenForceClass)
	{
		char sClass[PLATFORM_MAX_PATH];
		if (hWardenSkinClasses.GetString(cv_sDefaultWardenModel, sClass, sizeof(sClass)))
		{
			TFClassType iClass = TF2_GetClass(sClass);

			int Health = GetClientHealth(client);

			TF2_SetPlayerClass(client, iClass);
			TF2_RegeneratePlayer(client);

			if (Health < GetClientHealth(client))
			{
				SetEntityHealth(client, Health);
			}

			TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
		}
	}

	if (cv_WardenModels)
	{
		SetWardenModel(client, cv_sDefaultWardenModel);
	}

	if (cv_RendererParticles && strlen(sWardenParticle) > 0)
	{
		if (iParticle_Wardens[client] != INVALID_ENT_REFERENCE)
		{
			int old = EntRefToEntIndex(iParticle_Wardens[client]);

			if (IsValidEntity(old))
			{
				AcceptEntityInput(old, "Kill");
			}
		}

		iParticle_Wardens[client] = CreateParticle2(sWardenParticle, 0.0, client, ATTACH_NORMAL);
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iWardenColors[0], a_iWardenColors[1], a_iWardenColors[2], a_iWardenColors[3]);
	}

	char sWarden[256];
	Format(sWarden, sizeof(sWarden), "%t", "warden current node", iWarden);
	SetTextNode(hTextNodes[2], sWarden, EnumTNPS[2][fCoord_X], EnumTNPS[2][fCoord_Y], EnumTNPS[2][fHoldTime], EnumTNPS[2][iRed], EnumTNPS[2][iGreen], EnumTNPS[2][iBlue], EnumTNPS[2][iAlpha], EnumTNPS[2][iEffect], EnumTNPS[2][fFXTime], EnumTNPS[2][fFadeIn], EnumTNPS[2][fFadeOut]);

	KillTimerSafe(hTimer_WardenLock);

	ResetVotes();
	WardenMenu(client);

	Call_StartForward(sFW_WardenCreated);
	Call_PushCell(client);
	Call_Finish();

	CPrintToChatAll("%t %t", "plugin tag", "warden new", client);
	CPrintToChat(client, "%t %t", "plugin tag", "warden message");

	return true;
}

void SetWardenModel(int client, const char[] sModel)
{
	if (!IsWarden(client))
	{
		return;
	}

	char sModelPlatform[PLATFORM_MAX_PATH];
	hWardenSkins.GetString(sModel, sModelPlatform, sizeof(sModelPlatform));

	char sClass[64];
	hWardenSkinClasses.GetString(sModel, sClass, sizeof(sClass));
	SetModel(client, sModelPlatform, sClass);

	CPrintToChat(client, "%t %t", "plugin tag", "warden model message", sModel);
}

bool WardenUnset(int client)
{
	if (!IsWarden(client) || !IsPlayerAlive(client))
	{
		return false;
	}

	iWarden = -1;

	if (cv_WardenModels)
	{
		RemoveModel(client);
	}

	if (cv_BlueMute == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				UnmutePlayer(i);
			}
		}
	}

	if (bActiveRound)
	{
		if (cv_WardenTimer != 0)
		{
			hTimer_WardenLock = CreateTimer(float(cv_WardenTimer), DisableWarden, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	if (iParticle_Wardens[client] != INVALID_ENT_REFERENCE)
	{
		int old = EntRefToEntIndex(iParticle_Wardens[client]);

		if (IsValidEntity(old))
		{
			AcceptEntityInput(old, "Kill");
		}

		iParticle_Wardens[client] = -1;
	}

	if (cv_RendererColors)
	{
		SetEntityRenderColor(client, a_iDefaultColors[0], a_iDefaultColors[1], a_iDefaultColors[2], a_iDefaultColors[3]);
	}

	if (hTextNodes[2] != null)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			ClearSyncHud(i, hTextNodes[2]);
		}
	}

	EnumWardenMenu = Open;

	Call_StartForward(sFW_WardenRemoved);
	Call_PushCell(client);
	Call_Finish();

	return true;
}

void SetModel(int client, const char[] sModel, const char[] class)
{
	if (Client_IsIngame(client) && IsPlayerAlive(client))
	{
		if (cv_WardenForceClass)
		{
			TFClassType playerclass = TF2_GetClass(class);

			if (playerclass != TFClass_Unknown)
			{
				TF2_SetPlayerClass(client, playerclass, false, false);
				TF2_RegeneratePlayer(client);
			}
		}

		GetClientModel(client, sOldModel[client], PLATFORM_MAX_PATH);

		SetVariantString(sModel);
		AcceptEntityInput(client, "SetCustomModel");

		if (cv_WardenWearables)
		{
			RemoveValveHat(client, true);
		}
	}
}

void RemoveModel(int client)
{
	if (Client_IsIngame(client))
	{
		SetVariantString(sOldModel[client]);
		AcceptEntityInput(client, "SetCustomModel");
	}
}

void AttemptFireWarden(int client)
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

void FireWardenCall()
{
	if (WardenExists())
	{
		for (int i = 1; i <= MaxClients; i++)
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

void ResetVotes()
{
	iVotes = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		bVoted[i] = false;
	}
}

void FindWardenRandom(int client)
{
	char sTag[64];
	Format(sTag, sizeof(sTag), "%t", "plugin tag");

	int Random = Client_GetRandom(CLIENTFILTER_TEAMTWO | CLIENTFILTER_ALIVE);
	if (Client_IsIngame(Random))
	{
		if (cv_PrefStatus)
		{
			if (TF2_GetTeamClientCount(TFTeam_Blue) == 1)
			{
				WardenSet(Random);
				CShowActivity2(client, sTag, "%t", "Admin Force Warden Random", Random);
				Jail_Log(false, "%N has given %N Warden by Force.", client, Random);
			}

			if (bRolePreference_Warden[Random])
			{
				WardenSet(Random);
				CShowActivity2(client, sTag, "%t", "Admin Force Warden Random", Random);
				Jail_Log(false, "%N has given %N Warden by Force.", client, Random);
			}
			else
			{
				CPrintToChat(client, "%t %t", "plugin tag", "Admin Force Random Warden Not Preferred", Random);
				Jail_Log(false, "%N has their preference set to prisoner only, finding another client...", Random);
				FindWardenRandom(client);
			}
			return;
		}

		WardenSet(Random);
		CShowActivity2(client, sTag, "%t", "Admin Force Warden Random", Random);
		Jail_Log(false, "%N has given %N Warden by Force.", client, Random);
	}
}

int TF2_GetTeamClientCount(TFTeam team)
{
	int value = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == team)
		{
			value++;
		}
	}

	return value;
}

/* Timers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action Timer_Round(Handle hTimer)
{
	if (!cv_Enabled)
	{
		KillTimerSafe(hTimer_RoundTimer);
		return Plugin_Stop;
	}

	iRoundTime--;

	char sRoundTimer[64];
	Format(sRoundTimer, sizeof(sRoundTimer), "%02d:%02d", iRoundTime / 60, iRoundTime % 60);

	SetTextNode(hTextNodes[3], sRoundTimer, EnumTNPS[3][fCoord_X], EnumTNPS[3][fCoord_Y], EnumTNPS[3][fHoldTime], EnumTNPS[3][iRed], EnumTNPS[3][iGreen], EnumTNPS[3][iBlue], EnumTNPS[3][iAlpha], EnumTNPS[3][iEffect], EnumTNPS[3][fFXTime], EnumTNPS[3][fFadeIn], EnumTNPS[3][fFadeOut]);

	if (cv_RoundTime_Center)
	{
		PrintCenterTextAll(sRoundTimer);
	}

	if (iRoundTime <= 0)
	{
		ServerCommand("%s", cv_sRoundTimer_Execute);
		KillTimerSafe(hTimer_RoundTimer);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action UnmuteReds(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && TF2_GetClientTeam(i) == TFTeam_Red)
		{
			UnmutePlayer(i);
		}
	}

	CPrintToChatAll("%t %t", "plugin tag", "red team unmuted");
	Jail_Log(false, "All players have been unmuted.");
}

public Action Open_Doors(Handle hTimer)
{
	hTimer_OpenCells = null;

	if (bCellsOpened)
	{
		DoorHandler(OPEN);
		int time = RoundFloat(cv_DoorOpenTimer);
		CPrintToChatAll("%t %t", "plugin tag", "cell doors open end", time);
		bCellsOpened = false;
		Jail_Log(false, "Doors have been automatically opened by a timer.");
	}
}

public Action TimerAdvertisement(Handle hTimer)
{
	CPrintToChatAll("%t %t", "plugin tag", "plugin advertisement");
	return Plugin_Continue;
}

public Action Timer_Welcome(Handle hTimer, any data)
{
	int client = GetClientOfUserId(data);

	if (cv_Enabled && Client_IsIngame(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "welcome message");
	}
}

public Action BanClientTimerFreekiller(Handle hTimer, Handle data)
{
	hTimer_FreekillingData = null;

	ResetPack(data);

	int userid = ReadPackCell(data);
	int client = GetClientOfUserId(userid);

	char sAuth[24];
	ReadPackString(data, sAuth, sizeof(sAuth));

	char sName[MAX_NAME_LENGTH];
	ReadPackString(data, sName, sizeof(sName));

	if (!Client_IsIngame(client) && cv_FreekillersAction == 2)
	{
		BanIdentity(sAuth, cv_FreekillersBantimeDC, BANFLAG_AUTHID, cv_sBanMSGDC, "freekill_identityban", userid);
		CPrintToChatAll("%t %t", "plugin tag", "freekiller disconnected", sName, sAuth);
		Jail_Log(false, "%s [%s ]has been banned via identity.", sName, sAuth);
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
					Jail_Log(false, "%N has been banned via Sourcebans1 for being marked as a Freekiller.", client);
				}
				case false:
				{
					BanClient(client, cv_FreekillersBantime, BANFLAG_AUTO, "Client has been marked for Freekilling.", cv_sBanMSG, "freekill_liveban", userid);
					Jail_Log(false, "%N has been banned for being marked as a Freekiller.", client);
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

public Action EnableFFTimer(Handle hTimer)
{
	hTimer_FriendlyFireEnable = null;
	SetConVarBool(hEngineConVars[0], true);
}

public Action Timer_RemoveRebel(Handle hTimer, any data)
{
	int client = GetClientOfUserId(data);

	if (client > 0)
	{
		ClearRebel(client);
		hTimer_RebelTimers[client] = null;
		return Plugin_Stop;
	}

	return Plugin_Stop;
}

public Action DisableWarden(Handle hTimer)
{
	hTimer_WardenLock = null;

	if (bActiveRound)
	{
		CPrintToChatAll("%t %t", "plugin tag", "warden locked timer");
		bIsWardenLocked = true;
	}
}

public Action ExecuteServerCommand(Handle timer, Handle data)
{
	ResetPack(data);

	char sExecute[128];
	ReadPackString(data, sExecute, sizeof(sExecute));
	ServerCommand(sExecute);
}

public Action FindRandomWardenTimer(Handle hTimer)
{
	FindRandomWarden();
}

/* Next Frame Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public void ManageWeapons(any data)
{
	int client = GetClientOfUserId(data);
	if (cv_Enabled && cv_RedMelee && Client_IsIngame(client) && TF2_GetClientTeam(client) == TFTeam_Red)
	{
		EmptyWeaponSlots(client);
	}
}

public void KillEntity(any data)
{
	int entity = EntRefToEntIndex(data);
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

/* Group Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public bool WardenGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsWarden(i))
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool NotWardenGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !IsWarden(i))
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool RebelsGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool NotRebelsGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !bIsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool FreedaysGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreeday[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool NotFreedaysGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !bIsFreeday[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool FreekillersGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && bIsFreekiller[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool NotFreekillersGroup(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !bIsFreekiller[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

/* Native Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public int Native_ExistWarden(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Warden)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");
	}

	return WardenExists();
}

public int Native_IsWarden(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Warden)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	return IsWarden(client);
}

public int Native_SetWarden(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Warden)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (WardenExists())
	{
		return ThrowNativeError(SP_ERROR_INDEX, "warden is currently in use, cannot execute native function.");
	}

	if (cv_PrefStatus && bRolePreference_Warden[client])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i has their preference set to prisoner only.", client);
	}

	return WardenSet(client);
}

public int Native_RemoveWarden(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Warden)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!IsWarden(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not warden.", client);
	}

	return WardenUnset(client);
}

public int Native_IsFreeday(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_LRSEnabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	return view_as<bool>(bIsQueuedFreeday[client] || bIsFreeday[client]);
}

public int Native_GiveFreeday(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_LRSEnabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsFreeday[client])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Freeday.", client);
	}

	if (bIsQueuedFreeday[client])
	{
		bIsQueuedFreeday[client] = false;
		Jail_Log(false, "%N was queued as a Freeday, removed from queue to turn into a Freeday.");
	}

	return GiveFreeday(client);
}

public int Native_RemoveFreeday(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_LRSEnabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!bIsFreeday[client])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is not a Freeday.", client);
	}

	return RemoveFreeday(client);
}

public int Native_IsRebel(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Rebels)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Rebels' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	return bIsRebel[client];
}

public int Native_MarkRebel(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Rebels)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Rebels' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsRebel[client])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Rebel.", client);
	}

	return MarkRebel(client);
}

public int Native_IsFreekiller(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Freekillers)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Freekillers' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	return bIsFreekiller[client];
}

public int Native_MarkFreekill(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Freekillers)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Freekillers' for 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (bIsFreekiller[client])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already marked as a Freekiller.", client);
	}

	return MarkFreekiller(client);
}

public int Native_StripToMelee(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!IsPlayerAlive(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip ammo.", client);
	}

	RequestFrame(ManageWeapons, GetClientUserId(client));
	return 0;
}

public int Native_StripAllWeapons(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !Client_IsIngame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}

	if (!IsPlayerAlive(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip weapons.", client);
	}

	return StripToMelee(client);
}

public int Native_LockWarden(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Warden)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");
	}

	bAdminLockWarden = true;
	CPrintToChatAll("%t %t", "plugin tag", "warden locked natives");

	Jail_Log(false, "Natives has locked Warden.");
	return 0;
}

public int Native_UnlockWarden(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_Warden)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Warden' for 'TF2Jail' is currently disabled.");
	}

	bAdminLockWarden = false;
	CPrintToChatAll("%t %t", "plugin tag", "warden unlocked natives");

	Jail_Log(false, "Natives has unlocked Warden.");
	return 0;
}

public int Native_Logging(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);

	Jail_Log(false, sFormat);
	return 0;
}

public int Native_IsLRRound(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_LRSEnabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Last Requests' for 'TF2Jail' is currently disabled.");
	}

	return view_as<bool>(iLRCurrent != -1);
}

public int Native_ManageCells(Handle plugin, int numParams)
{
	if (!cv_Enabled)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin 'TF2Jail' is currently disabled.");
	}

	if (!cv_DoorControl)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Plugin feature 'Door Controls' for 'TF2Jail' is currently disabled.");
	}

	if (!bIsMapCompatible)
	{
		return false;
	}

	DoorHandler(GetNativeCell(1));

	return true;
}
/* Plugin End ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

stock void KillTimerSafe(Handle &timer)
{
	if (timer != null)
	{
		KillTimer(timer);
		timer = null;
	}
}