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
#include <tf2jail>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#include <clientprefs>
#include <steamtools>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <sourcebans>
#include <tf2attributes>
#include <sourcecomms>
#include <basecomm>
#include <betherobot>
#include <betheskeleton>
#include <voiceannounce_ex>
#include <tf2items>
#include <tf2items_giveweapon>
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME     "[TF2] Jailbreak"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "5.1.0"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

#define WARDEN_MODEL			"models/jailbreak/warden/warden_v2.mdl"

#define UPDATE_URL         "https://raw.github.com/JackofDesigns/TF2-Jailbreak/master/updater.txt"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

//ConVar Handles, Globals, etc..
new Handle:JB_ConVars[57] = {INVALID_HANDLE, ...};

new bool:j_Enabled = true;
new bool:j_Advertise = true;
new bool:j_Cvars = true;
new j_Logging = 2;
new bool:j_Balance = true;
new Float:j_BalanceRatio = 0.5;
new bool:j_RedMelee = true;
new bool:j_Warden = false;
new bool:j_WardenAuto = false;
new bool:j_WardenModel = true;
new bool:j_WardenForceSoldier = true;
new bool:j_WardenFF = true;
new bool:j_WardenCC = true;
new bool:j_WardenRequest = true;
new j_WardenLimit = 0;
new bool:j_DoorControl = true;
new Float:j_DoorOpenTimer = 60.0;
new j_RedMute = 2;
new Float:j_RedMuteTime = 15.0;
new j_BlueMute = 2;
new bool:j_DeadMute = true;
new bool:j_MicCheck = true;
new bool:j_MicCheckType = true;
new bool:j_Rebels = true;
new Float:j_RebelsTime = 30.0;
new j_Criticals = 1;
new j_Criticalstype = 2;
new Float:j_WVotesNeeded = 0.60;
new j_WVotesMinPlayers = 0;
new j_WVotesPostAction = 0;
new j_WVotesPassedLimit = 3;
new bool:j_Freekillers = true;
new Float:j_FreekillersTime = 6.0;
new j_FreekillersKills = 6;
new Float:j_FreekillersWave = 60.0;
new j_FreekillersAction = 2;
new j_FreekillersBantime = 60;
new j_FreekillersBantimeDC = 120;
new bool:j_LRSEnabled = true;
new bool:j_LRSAutomatic = true;
new bool:j_LRSLockWarden = true;
new j_FreedayLimit = 3;
new bool:j_1stDayFreeday = true;
new bool:j_DemoCharge = true;
new bool:j_DoubleJump = true;
new bool:j_Airblast = true;
new j_WardenVoice = 1;
new bool:j_WardenWearables = true;
new bool:j_FreedayTeleports = true;
new j_WardenStabProtection = 0;
new bool:j_KillPointServerCommand = true;

//Plugins/Extension bools
new bool:e_tf2items = false;
new bool:e_tf2attributes = false;
new bool:e_voiceannounce_ex = false;
new bool:e_sourcebans = false;
new bool:e_steamtools = false;

//Plugin Global Bools
new bool:g_IsMapCompatible = false;
new bool:g_CellDoorTimerActive = false;
new bool:g_1stRoundFreeday = false;
new bool:g_VoidFreekills = false;
new bool:g_bIsLRInUse = false;
new bool:g_bIsWardenLocked = false;
new bool:g_bIsLowGravRound = false;
new bool:g_bIsDiscoRound = false;
new bool:g_bOneGuardLeft = false;
new bool:g_bTimerStatus = true;
new bool:g_bActiveRound = false;
new bool:g_bFreedayTeleportSet = false;
new bool:g_bLRConfigActive = true;
new bool:g_bLockWardenLR = false;
new bool:g_ScoutsBlockedDoubleJump[MAXPLAYERS+1];
new bool:g_PyrosDisableAirblast[MAXPLAYERS+1];
new bool:g_IsMuted[MAXPLAYERS+1];
new bool:g_IsRebel[MAXPLAYERS + 1];
new bool:g_IsFreeday[MAXPLAYERS + 1];
new bool:g_IsFreedayActive[MAXPLAYERS + 1];
new bool:g_IsFreekiller[MAXPLAYERS + 1];
new bool:g_HasTalked[MAXPLAYERS+1];
new bool:g_LockedFromWarden[MAXPLAYERS+1];
new bool:g_HasModel[MAXPLAYERS+1];
new bool:g_bLateLoad = false;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

//Plugin Global Integers, Floats, Strings, etc..
new Warden = -1;
new Suicide = -1;
new LR_Number = -1;
new g_Voters = 0;
new g_Votes = 0;
new g_VotesNeeded = 0;
new g_VotesPassed = 0;
new g_FirstKill[MAXPLAYERS + 1];
new g_Killcount[MAXPLAYERS + 1];
new g_AmmoCount[MAXPLAYERS + 1];
new WardenLimit = 0;
new FreedayLimit = 0;
new g_HasBeenWarden[MAXPLAYERS + 1] = 0;
new Float:free_pos[3];
new String:GCellNames[32];
new String:GCellOpener[32];
new String:DoorList[][] = {"func_door", "func_door_rotating", "func_movelinear"};
new String:LRConfig_File[PLATFORM_MAX_PATH];

//Handles
new Handle:g_hArray_Pending = INVALID_HANDLE;
new Handle:Forward_WardenCreated = INVALID_HANDLE;
new Handle:Forward_WardenRemoved = INVALID_HANDLE;
new Handle:g_adverttimer = INVALID_HANDLE;
new Handle:g_checkweapontimer = INVALID_HANDLE;
new Handle:g_refreshspellstimer = INVALID_HANDLE;
new Handle:DataTimerF = INVALID_HANDLE;
new Handle:WardenName;
new Handle:JB_EngineConVars[3] = {INVALID_HANDLE, ...};

//Enumerators
enum WardenMenuAccept
{
	WM_Disabled = 0,
	WM_FFChange,
	WM_CCChange
};
new WardenMenuAccept:enum_WardenMenu;

enum CommsList
{
	None = 0,
	Basecomms,
	Sourcecomms
};
new CommsList:enumCommsList;

enum DoorMode
{
	DM_OPEN = 0,
	DM_CLOSE,
	DM_LOCK,
	DM_UNLOCK
};

enum KillWeaponsEnum
{
	KW_Disabled = 0,
	KW_Red,
	KW_Blue,
	KW_Both
};
new KillWeaponsEnum:KillWeaponsEnumHandle;

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
	PrintToServer("%s Jailbreak is now loading...", TAG);
	File_LoadTranslations("common.phrases");
	File_LoadTranslations("TF2Jail.phrases");

	AutoExecConfig_SetFile("TF2Jail");

	JB_ConVars[0] = AutoExecConfig_CreateConVar("tf2jail_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	JB_ConVars[1] = AutoExecConfig_CreateConVar("sm_tf2jail_enable", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[2] = AutoExecConfig_CreateConVar("sm_tf2jail_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[3] = AutoExecConfig_CreateConVar("sm_tf2jail_set_variables", "1", "Set default cvars: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[4] = AutoExecConfig_CreateConVar("sm_tf2jail_logging", "2", "Status and the type of logging: (0 = disabled, 1 = regular logging, 2 = logging to TF2Jail.log)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
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

	AutoExecConfig_ExecuteFile();

	for (new i = 0; i < sizeof(JB_ConVars); i++)
	{
		HookConVarChange(JB_ConVars[i], HandleCvars);
	}

	PluginEvents(true);

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
	RegConsoleCmd("sm_wcc", WardenCollision);
	RegConsoleCmd("sm_givelr", GiveLR);
	RegConsoleCmd("sm_givelastrequest", GiveLR);
	RegConsoleCmd("sm_removelr", RemoveLR);
	RegConsoleCmd("sm_removelastrequest", RemoveLR);

	RegAdminCmd("sm_rw", AdminRemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", AdminRemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_pardon", AdminPardonFreekiller, ADMFLAG_GENERIC);
	RegAdminCmd("sm_denylr", AdminDenyLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_denylastrequest", AdminDenyLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_opencells", AdminOpenCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_closecells", AdminCloseCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_lockcells", AdminLockCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unlockcells", AdminUnlockCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcewarden", AdminForceWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcelr", AdminForceLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_jailreset", AdminResetPlugin, ADMFLAG_GENERIC);
	RegAdminCmd("sm_compatible", AdminMapCompatibilityCheck, ADMFLAG_GENERIC);
	RegAdminCmd("sm_givefreeday", AdminGiveFreeday, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removefreeday", AdminRemoveFreeday, ADMFLAG_GENERIC);
	RegAdminCmd("sm_allow", AdminAcceptWardenChange, ADMFLAG_GENERIC);
	RegAdminCmd("sm_cancel", AdminCancelWardenChange, ADMFLAG_GENERIC);

	JB_EngineConVars[0] = FindConVar("mp_friendlyfire");
	JB_EngineConVars[1] = FindConVar("tf_avoidteammates_pushaway");
	JB_EngineConVars[2] = FindConVar("sv_gravity");

	WardenName = CreateHudSynchronizer();

	AddMultiTargetFilter("@warden", WardenGroup, "The Warden.", false);
	AddMultiTargetFilter("@rebels", RebelsGroup, "All Rebels.", false);
	AddMultiTargetFilter("@freedays", FreedaysGroup, "All Freedays.", false);
	AddMultiTargetFilter("@!warden", NotWardenGroup, "All but the Warden.", false);
	AddMultiTargetFilter("@!rebels", NotRebelsGroup, "All but the Rebels.", false);
	AddMultiTargetFilter("@!freedays", NotFreedaysGroup, "All but the Freedays.", false);

	Forward_WardenCreated = CreateGlobalForward("Warden_OnWardenCreated", ET_Ignore, Param_Cell);
	Forward_WardenRemoved = CreateGlobalForward("Warden_OnWardenRemoved", ET_Ignore, Param_Cell);
	
	BuildPath(Path_SM, LRConfig_File, sizeof(LRConfig_File), "configs/tf2jail/lastrequests.cfg");

	AddServerTag("Jailbreak");

	g_hArray_Pending = CreateArray();

	AutoExecConfig_CleanFile();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));

	if (!StrEqual(Game, "tf") || !StrEqual(Game, "tf_beta"))
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
	CreateNative("TF2Jail_GiveFreeday", Native_GiveFreeday);
	CreateNative("TF2Jail_IsRebel", Native_IsRebel);
	CreateNative("TF2Jail_MarkRebel", Native_MarkRebel);
	CreateNative("TF2Jail_IsFreekiller", Native_IsFreekiller);
	CreateNative("TF2Jail_MarkFreekiller", Native_MarkFreekill);
	RegPluginLibrary("tf2jail");

	g_bLateLoad = late;

	return APLRes_Success;
}

public OnAllPluginsLoaded()
{	
	e_steamtools = LibraryExists("SteamTools");
	e_tf2items = LibraryExists("tf2items");
	e_voiceannounce_ex = LibraryExists("voiceannounce_ex");
	e_tf2attributes = LibraryExists("tf2attributes");
	e_sourcebans = LibraryExists("sourcebans");
	if (LibraryExists("sourcecomms")) enumCommsList = Sourcecomms;
	if (LibraryExists("basecomm")) enumCommsList = Basecomms;
	
#if defined _updater_included
	if (LibraryExists("updater")) Updater_AddPlugin(UPDATE_URL);
#endif
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false)) e_steamtools = true;
	if (StrEqual(name, "sourcebans")) e_sourcebans = true;
	if (StrEqual(name, "sourcecomms")) enumCommsList = Sourcecomms;
	if (StrEqual(name, "basecomm")) enumCommsList = Basecomms;
	if (StrEqual(name, "voiceannounce_ex")) e_voiceannounce_ex = true;
	if (StrEqual(name, "tf2attributes")) e_tf2attributes = true;
	if (StrEqual(name, "tf2items")) e_tf2items = true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false)) e_steamtools = false;
	if (StrEqual(name, "sourcecomms") || StrEqual(name, "basecomm")) enumCommsList = None;
	if (StrEqual(name, "tf2items"))	e_tf2items = false;
	if (StrEqual(name, "tf2attributes")) e_tf2attributes = false;
	if (StrEqual(name, "sourcebans")) e_sourcebans = false;
	if (StrEqual(name, "voiceannounce_ex"))	e_voiceannounce_ex = false;
}

public OnPluginEnd()
{
	OnMapEnd();
}

public OnConfigsExecuted()
{
	j_Enabled = GetConVarBool(JB_ConVars[1]);
	j_Advertise = GetConVarBool(JB_ConVars[2]);
	j_Cvars = GetConVarBool(JB_ConVars[3]);
	j_Logging = GetConVarInt(JB_ConVars[4]);
	j_Balance = GetConVarBool(JB_ConVars[5]);
	j_BalanceRatio = GetConVarFloat(JB_ConVars[6]);
	j_RedMelee = GetConVarBool(JB_ConVars[7]);
	j_Warden = GetConVarBool(JB_ConVars[8]);
	j_WardenAuto = GetConVarBool(JB_ConVars[9]);
	j_WardenModel = GetConVarBool(JB_ConVars[10]);
	j_WardenForceSoldier = GetConVarBool(JB_ConVars[11]);
	j_WardenFF = GetConVarBool(JB_ConVars[12]);
	j_WardenCC = GetConVarBool(JB_ConVars[13]);
	j_WardenRequest = GetConVarBool(JB_ConVars[14]);
	j_WardenLimit = GetConVarInt(JB_ConVars[15]);
	j_DoorControl = GetConVarBool(JB_ConVars[16]);
	j_DoorOpenTimer = GetConVarFloat(JB_ConVars[17]);
	j_RedMute = GetConVarInt(JB_ConVars[18]);
	j_RedMuteTime = GetConVarFloat(JB_ConVars[19]);
	j_BlueMute = GetConVarInt(JB_ConVars[20]);
	j_DeadMute = GetConVarBool(JB_ConVars[21]);
	j_MicCheck = GetConVarBool(JB_ConVars[22]);
	j_MicCheckType = GetConVarBool(JB_ConVars[23]);
	j_Rebels = GetConVarBool(JB_ConVars[24]);
	j_RebelsTime = GetConVarFloat(JB_ConVars[25]);
	j_Criticals = GetConVarInt(JB_ConVars[26]);
	j_Criticalstype = GetConVarInt(JB_ConVars[27]);
	j_WVotesNeeded = GetConVarFloat(JB_ConVars[28]);
	j_WVotesMinPlayers = GetConVarInt(JB_ConVars[29]);
	j_WVotesPostAction = GetConVarInt(JB_ConVars[30]);
	j_WVotesPassedLimit = GetConVarInt(JB_ConVars[31]);
	j_Freekillers = GetConVarBool(JB_ConVars[32]);
	j_FreekillersTime = GetConVarFloat(JB_ConVars[33]);
	j_FreekillersKills = GetConVarInt(JB_ConVars[34]);
	j_FreekillersWave = GetConVarFloat(JB_ConVars[35]);
	j_FreekillersAction = GetConVarInt(JB_ConVars[36]);
	j_FreekillersBantime = GetConVarInt(JB_ConVars[37]);
	j_FreekillersBantimeDC = GetConVarInt(JB_ConVars[38]);
	j_LRSEnabled = GetConVarBool(JB_ConVars[41]);
	j_LRSAutomatic = GetConVarBool(JB_ConVars[42]);
	j_LRSLockWarden = GetConVarBool(JB_ConVars[43]);
	j_FreedayLimit = GetConVarInt(JB_ConVars[44]);
	j_1stDayFreeday = GetConVarBool(JB_ConVars[45]);
	j_DemoCharge = GetConVarBool(JB_ConVars[46]);
	j_DoubleJump = GetConVarBool(JB_ConVars[47]);
	j_Airblast = GetConVarBool(JB_ConVars[48]);
	j_WardenVoice = GetConVarInt(JB_ConVars[52]);
	j_WardenWearables = GetConVarBool(JB_ConVars[53]);
	j_FreedayTeleports = GetConVarBool(JB_ConVars[54]);
	j_WardenStabProtection = GetConVarInt(JB_ConVars[55]);
	j_KillPointServerCommand = GetConVarBool(JB_ConVars[55]);

	if (j_Enabled)
	{
		if (j_Cvars)
		{
			ConvarsSet(true);
		}

		if (e_steamtools)
		{
			decl String:gameDesc[64];
			Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
			Steam_SetGameDescription(gameDesc);
		}

		ResetVotes();

		if (g_bLateLoad)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					OnClientPutInServer(i);
				}
			}
		}

		g_checkweapontimer = CreateTimer(1.0, CheckWeapons, _, TIMER_REPEAT);
		
		ParseConfigs();

		PrintToServer("%s Jailbreak has successfully loaded.", TAG);
	}
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
		switch (iNewValue)
		{
			case 0:
				{
					j_Enabled = false;
					CPrintToChatAll("%s %t", TAG_COLORED, "plugin disabled");
					PluginEvents(false);
					if (e_steamtools)
					{
						Steam_SetGameDescription("Team Fortress");
					}
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsWarden(i) && j_WardenModel)
						{
							RemoveModel(i);
						}
						if (g_IsRebel[i])
						{
							g_IsRebel[i] = false;
						}
					}
				}
			case 1:
				{
					j_Enabled = true;
					CPrintToChatAll("%s %t", TAG_COLORED, "plugin enabled");
					PluginEvents(true);
					if (e_steamtools)
					{
						decl String:gameDesc[64];
						Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
						Steam_SetGameDescription(gameDesc);
					}
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsWarden(i) && j_WardenModel)
						{
							SetModel(i, WARDEN_MODEL);
						}
					}
				}
		}
	}

	else if (cvar == JB_ConVars[2])
	{
		switch (iNewValue)
		{
			case 0:
				{
					j_Advertise = false;
					ClearTimer(g_adverttimer);
				}
			case 1:
				{
					j_Advertise = true;
					if (g_adverttimer == INVALID_HANDLE)
					{
						g_adverttimer = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT);
					}
				}
		}
	}

	else if (cvar == JB_ConVars[3])
	{
		switch (iNewValue)
		{
			case 0:
				{
					j_Cvars = false;
					ConvarsSet(false);
				}
			case 1:
				{
					j_Cvars = true;
					ConvarsSet(true);
				}
		}
	}

	else if (cvar == JB_ConVars[4])
	{
		j_Logging = iNewValue;
	}

	else if (cvar == JB_ConVars[5])
	{
		switch (iNewValue)
		{
			case 0:	j_Balance = false;
			case 1:	j_Balance = true;
		}
	}

	else if (cvar == JB_ConVars[6])
	{
		j_BalanceRatio = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[7])
	{
		switch (iNewValue)
		{
			case 0:
				{
					j_RedMelee = false;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red && IsPlayerAlive(i))
						{
							TF2_RegeneratePlayer(i);
						}
					}
				}
			case 1:
				{
					j_RedMelee = true;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i) && IsPlayerAlive(i))
						{
							CreateTimer(0.1, ManageWeapons, i);
						}
					}
				}
		}
	}

	else if (cvar == JB_ConVars[8])
	{
		switch (iNewValue)
		{
			case 0:
				{
					j_Warden = false;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsWarden(i))
						{
							WardenUnset(i);
						}
					}
				}
			case 1:	j_Warden = true;
		}
	}

	else if (cvar == JB_ConVars[9])
	{
		switch (iNewValue)
		{
			case 0:	j_WardenAuto = false;
			case 1:	j_WardenAuto = true;
		}
	}

	else if (cvar == JB_ConVars[10])
	{
		switch (iNewValue)
		{
			case 0:
				{
					j_WardenModel = false;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsWarden(i))
						{
							RemoveModel(i);
						}
					}
				}
			case 1:
				{
					j_WardenModel = true;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsWarden(i))
						{
							SetModel(i, WARDEN_MODEL);
						}
					}
				}
		}
	}

	else if (cvar == JB_ConVars[11])
	{
		switch (iNewValue)
		{
			case 0:	j_WardenForceSoldier = false;
			case 1:	j_WardenForceSoldier = true;
		}
	}

	else if (cvar == JB_ConVars[12])
	{
		switch (iNewValue)
		{
			case 0:	j_WardenFF = false;
			case 1:	j_WardenFF = true;
		}
	}

	else if (cvar == JB_ConVars[13])
	{
		switch (iNewValue)
		{
			case 0:	j_WardenCC = false;
			case 1:	j_WardenCC = true;
		}
	}

	else if (cvar == JB_ConVars[14])
	{
		switch (iNewValue)
		{
			case 0:	j_WardenRequest = false;
			case 1:	j_WardenRequest = true;
		}
	}

	else if (cvar == JB_ConVars[15])
	{
		j_WardenLimit = iNewValue;
	}

	else if (cvar == JB_ConVars[16])
	{
		switch (iNewValue)
		{
			case 0:	j_DoorControl = false;
			case 1:	j_DoorControl = true;
		}
	}

	else if (cvar == JB_ConVars[17])
	{
		j_DoorOpenTimer = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[18])
	{
		j_RedMute = iNewValue;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == _:TFTeam_Red)
				{
					switch (iNewValue)
					{
						case 0:	UnmutePlayer(i);
						case 1:	if (g_CellDoorTimerActive) MutePlayer(i);
						case 2:	if (g_bActiveRound) MutePlayer(i);
					}
				}
			}
		}
	}

	else if (cvar == JB_ConVars[19])
	{
		j_RedMuteTime = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[20])
	{
		j_BlueMute = iNewValue;

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
						case 2:	if (i != Warden) MutePlayer(i);
					}
				}
			}
		}
	}

	else if (cvar == JB_ConVars[21])
	{
		switch (iNewValue)
		{
			case 0:	j_DeadMute = false;
			case 1:	j_DeadMute = true;
		}
	}

	else if (cvar == JB_ConVars[22])
	{
		switch (iNewValue)
		{
			case 0:	j_MicCheck = false;
			case 1:	j_MicCheck = true;
		}
	}

	else if (cvar == JB_ConVars[23])
	{
		switch (iNewValue)
		{
			case 0:	j_MicCheckType = false;
			case 1:	j_MicCheckType = true;
		}
	}

	else if (cvar == JB_ConVars[24])
	{
		switch (iNewValue)
		{
			case 0:
				{
					j_Rebels = false;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (g_IsRebel[i])
						{
							g_IsRebel[i] = false;
						}
					}
				}
			case 1:	j_Rebels = true;
		}
	}

	else if (cvar == JB_ConVars[25])
	{
		j_RebelsTime = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[26])
	{
		j_Criticals = iNewValue;
	}

	else if (cvar == JB_ConVars[27])
	{
		j_Criticalstype = iNewValue;
	}

	else if (cvar == JB_ConVars[28])
	{
		j_WVotesNeeded = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[29]) 
	{
		j_WVotesMinPlayers = iNewValue;
	}

	else if (cvar == JB_ConVars[30]) 
	{
		j_WVotesPostAction = iNewValue;
	}

	else if (cvar == JB_ConVars[31]) 
	{
		j_WVotesPassedLimit = iNewValue;
	}

	else if (cvar == JB_ConVars[32])
	{
		switch (iNewValue)
		{
			case 0:	j_Freekillers = false;
			case 1:	j_Freekillers = true;
		}
	}

	else if (cvar == JB_ConVars[33])
	{
		j_FreekillersTime = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[34])
	{
		j_FreekillersKills = iNewValue;
	}

	else if (cvar == JB_ConVars[35])
	{
		j_FreekillersWave = StringToFloat(newValue);
	}

	else if (cvar == JB_ConVars[36])
	{
		j_FreekillersAction = iNewValue;
	}
	
	//37, 38

	else if (cvar == JB_ConVars[39])
	{
		j_FreekillersBantime = iNewValue;
	}

	else if (cvar == JB_ConVars[40])
	{
		j_FreekillersBantimeDC = iNewValue;
	}

	else if (cvar == JB_ConVars[41])
	{
		switch (iNewValue)
		{
			case 0:	j_LRSEnabled = false;
			case 1:	j_LRSEnabled = true;
		}
	}

	else if (cvar == JB_ConVars[42])
	{
		switch (iNewValue)
		{
			case 0:	j_LRSAutomatic = false;
			case 1:	j_LRSAutomatic = true;
		}
	}

	else if (cvar == JB_ConVars[43])
	{
		switch (iNewValue)
		{
			case 0:	j_LRSLockWarden = false;
			case 1:	j_LRSLockWarden = true;
		}
	}

	else if (cvar == JB_ConVars[44])
	{
		j_FreedayLimit = iNewValue;
	}

	else if (cvar == JB_ConVars[45])
	{
		switch (iNewValue)
		{
			case 0:	j_1stDayFreeday = false;
			case 1:	j_1stDayFreeday = true;
		}
	}

	else if (cvar == JB_ConVars[46])
	{
		switch (iNewValue)
		{
			case 0:	j_DemoCharge = false;
			case 1:	j_DemoCharge = true;
		}
	}

	else if (cvar == JB_ConVars[47])
	{
		switch (iNewValue)
		{
			case 0:	j_DoubleJump = false;
			case 1:	j_DoubleJump = true;
		}
	}

	else if (cvar == JB_ConVars[48])
	{
		switch (iNewValue)
		{
			case 0:	j_Airblast = false;
			case 1:	j_Airblast = true;
		}
	}

	//49, 50, 51
	
	else if (cvar == JB_ConVars[52])
	{
		j_WardenVoice = iNewValue;
	}
	
	else if (cvar == JB_ConVars[53])
	{
		switch (iNewValue)
		{
			case 0:	j_WardenWearables = false;
			case 1:	j_WardenWearables = true;
		}
	}
	
	else if (cvar == JB_ConVars[54])
	{
		switch (iNewValue)
		{
			case 0:	j_FreedayTeleports = false;
			case 1:	j_FreedayTeleports = true;
		}
	}
	
	else if (cvar == JB_ConVars[55])
	{
		j_WardenStabProtection = iNewValue;
	}
	
	else if (cvar == JB_ConVars[56])
	{
		switch (iNewValue)
		{
			case 0:	j_KillPointServerCommand = false;
			case 1:	j_KillPointServerCommand = true;
		}
	}
}

public Action:Updater_OnPluginChecking() Jail_Log("%s Checking if TF2Jail requires an update...", TAG);
public Action:Updater_OnPluginDownloading() Jail_Log("%s New version has been found, downloading new files...", TAG);
public Updater_OnPluginUpdated() Jail_Log("%s Download complete, updating files...", TAG);
public Updater_OnPluginUpdating() Jail_Log("%s Updates complete! You may now reload the plugin or wait for map change/server restart.", TAG);

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public OnMapStart()
{
	if (j_Enabled)
	{
		if (j_Advertise)
		{
			g_adverttimer = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT);
		}

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
			{
				OnClientConnected(i);
				g_AmmoCount[i] = 0;
			}
			g_HasBeenWarden[i] = 0;
		}
		
		if (j_WardenModel)
		{
			PrecacheModel(WARDEN_MODEL, true);
			AddFileToDownloadsTable(WARDEN_MODEL);
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
		
		PrecacheSound("ui/system_message_alert.wav", true);
		
		g_1stRoundFreeday = true;
		g_bActiveRound = false;
		g_Voters = 0;
		g_Votes = 0;
		g_VotesNeeded = 0;
		WardenLimit = 0;

		ParseConfigs();
	}
}

public OnMapEnd()
{
	if (j_Enabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				g_HasTalked[i] = false;
				g_IsMuted[i] = false;
				g_IsFreeday[i] = false;
				g_LockedFromWarden[i] = false;
				
				if (IsWarden(i))
				{
					RemoveModel(i);
				}
			}
		}

		g_IsMapCompatible = false;
		g_bActiveRound = false;
		
		ResetVotes();
		
		ConvarsSet(false);
		RemoveServerTag("Jailbreak");
		ClearTimer(g_checkweapontimer);
		ClearTimer(g_adverttimer);
		PrintToServer("%s Jailbreak has been unloaded successfully.", TAG);
	}
}

public OnClientConnected(client)
{
	g_Voted[client] = false;
	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
}

public OnClientPutInServer(client)
{
	g_IsMuted[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, PlayerTakeDamage);
}

public Action:PlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!j_Enabled) return Plugin_Continue;

	if (!IsValidClient(client) || !IsValidClient(attacker)) return Plugin_Continue;

	new team_attacker = GetClientTeam(attacker);

	if (attacker > 0 && client != attacker)
	{
		switch (team_attacker)
		{
		case TFTeam_Red:
			{
				if (j_Criticals == 2 || j_Criticals == 3)
				{
					if (j_Criticalstype == 2) damagetype |= DMG_ACID;
					if (j_Criticalstype == 1) damagetype |= DMG_CRIT;
					return Plugin_Changed;
				}
			}
		case TFTeam_Blue:
			{
				if (j_Criticals == 1 || j_Criticals == 3)
				{
					if (j_Criticalstype == 2) damagetype |= DMG_ACID;
					if (j_Criticalstype == 1) damagetype |= DMG_CRIT;
					return Plugin_Changed;
				}
			}
		}
		if (IsWarden(client) && j_WardenStabProtection == 2)
		{
			decl String:szClassName[64];
			GetEntityClassname(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), szClassName, sizeof(szClassName));
			if (StrEqual(szClassName, "tf_weapon_knife") && (damagetype & DMG_CRIT == DMG_CRIT))
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	if (j_Enabled)
	{
		CreateTimer(4.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)
{
	if (!j_Enabled || !IsValidClient(client)) return;

	if (g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
	
	if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded)
	{
		if (j_WVotesPostAction == 1) return;
		FireWardenCall();
	}

	if (IsWarden(client))
	{
		CPrintToChatAll("%s %t", TAG_COLORED, "warden disconnected");
		PrintCenterTextAll("%t", "warden disconnected center");
		Warden = -1;
	}
	
	g_HasTalked[client] = false;
	g_IsMuted[client] = false;
	g_ScoutsBlockedDoubleJump[client] = false;
	g_PyrosDisableAirblast[client] = false;
	g_IsRebel[client] = false;
	g_IsFreeday[client] = false;
	g_Killcount[client] = 0;
	g_FirstKill[client] = 0;
	g_AmmoCount[client] = 0;
	
	return;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	new TFClassType:class = TF2_GetPlayerClass(client);

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		CreateTimer(0.1, ManageWeapons, client);
		switch (team)
		{
		case TFTeam_Red:
			{
				switch (class)
				{
				case TFClass_Spy:
					{
						if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
						{
							TF2_RemoveCondition(client, TFCond_Cloaked);
						}
					}
				case TFClass_Scout:
					{
						if (j_DoubleJump)
						{
							AddAttribute(client, "no double jump", 1.0);
							g_ScoutsBlockedDoubleJump[client] = true;
						}
					}
				case TFClass_Pyro:
					{
						if (j_Airblast)
						{
							AddAttribute(client, "airblast disabled", 1.0);
							g_PyrosDisableAirblast[client] = true;
						}
					}
				case TFClass_DemoMan:
					{
						if (j_DemoCharge)
						{
							new ent = -1;
							while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1) AcceptEntityInput(ent, "kill");
						}
					}
				}
				if (j_RedMute != 0)
				{
					MutePlayer(client);
				}
				if (g_IsFreeday[client])
				{
					GiveFreeday(client);
				}
			}
		case TFTeam_Blue:
			{
				if (e_voiceannounce_ex && j_MicCheck)
				{
					if (j_MicCheckType)
					{
						if (!g_HasTalked[client] && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION))
						{
							ChangeClientTeam(client, _:TFTeam_Red);
							TF2_RespawnPlayer(client);
							CPrintToChat(client, "%s %t", TAG_COLORED, "microphone unverified");
						}
					}
				}
				if (j_BlueMute == 2)
				{
					MutePlayer(client);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsValidClient(client) || !IsValidClient(client_attacker))
	{
		if (client_attacker != client)
		{
			if (g_IsFreedayActive[client_attacker])
			{
				RemoveFreeday(client_attacker);
			}

			if (j_Rebels)
			{
				if (GetClientTeam(client_attacker) == _:TFTeam_Red && GetClientTeam(client) == _:TFTeam_Blue && !g_IsRebel[client_attacker])
				{
					MarkRebel(client_attacker);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_IsFreedayActive[client])
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsValidClient(client))
	{
		if (IsValidClient(client_killer))
		{
			if (j_Freekillers)
			{
				if (client_killer != client && GetClientTeam(client_killer) == _:TFTeam_Blue)
				{
					if ((g_FirstKill[client_killer] + j_FreekillersTime) >= GetTime())
					{
						if (++g_Killcount[client_killer] == j_FreekillersKills)
						{
							if (!g_VoidFreekills)
							{
								MarkFreekiller(client_killer);
							}
							else
							{
								CPrintToChatAll("%s %t", TAG_COLORED, "freekiller flagged while void", client_killer);
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
			
			if (j_LRSAutomatic)
			{
				if (Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE) == 1)
				{
					if (IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
					{
						if (g_bLRConfigActive) LastRequestStart(client);
						Jail_Log("%N has received last request for being the last prisoner alive.", client);
					}
				}
			}
			
			if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) == 1 && !g_bOneGuardLeft)
			{
				g_VoidFreekills = true;
				g_bOneGuardLeft = true;
				PrintCenterTextAll("%t", "last guard");
			}

			if (j_DeadMute)
			{
				MutePlayer(client);
			}

			if (g_IsFreedayActive[client])
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
		}
		
		if (IsWarden(client))
		{
			WardenUnset(client);
			PrintCenterTextAll("%t", "warden killed", client);
		}
	}
	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	if (j_1stDayFreeday && g_1stRoundFreeday)
	{
		DoorHandler(DM_OPEN);
		PrintCenterTextAll("1st round freeday");
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
				if (j_DoorControl)
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
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (g_HasModel[i])
			{
				RemoveModel(i);
			}
		}
	}
	
	Warden = -1;
	g_bIsLRInUse = false;
	g_bActiveRound = true;
	
	return Plugin_Continue;
}

public Action:ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;
	
	g_bIsWardenLocked = false;

	if (j_Balance)
	{
		new Float:Ratio;
		for (new i = 1; i <= MaxClients; i++)
		{
			Ratio = Float:GetTeamClientCount(_:TFTeam_Blue)/Float:GetTeamClientCount(_:TFTeam_Red);
			if (Ratio <= j_BalanceRatio || GetTeamClientCount(_:TFTeam_Red) == 1)
			{
				break;
			}
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);
				CPrintToChat(i, "%s %t", TAG_COLORED, "moved for balance");
				if (g_HasModel[i]) RemoveModel(i);
				Jail_Log("%N has been moved to prisoners team for balance.", i);
			}
		}
	}
	
	if (g_IsMapCompatible && j_DoorOpenTimer != 0.0)
	{
		new autoopen = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", TAG_COLORED, "cell doors open start", autoopen);
		CreateTimer(j_DoorOpenTimer, Open_Doors, _);
		g_CellDoorTimerActive = true;
		Jail_Log("Cell doors have been auto opened via automatic timer if they exist.");
	}

	switch(j_RedMute)
	{
	case 0:
		{
			CPrintToChatAll("%s %t", TAG_COLORED, "red mute system disabled");
			Jail_Log("Mute system has been disabled this round, nobody has been muted.");
		}
	case 1:
		{
			new time = RoundFloat(j_RedMuteTime);
			CPrintToChatAll("%s %t", TAG_COLORED, "red team muted temporarily", time);
			CreateTimer(j_RedMuteTime, UnmuteReds, _, TIMER_FLAG_NO_MAPCHANGE);
			Jail_Log("Red team has been temporarily muted and will wait %s seconds to be unmuted.", time);
		}
	case 2:
		{
			CPrintToChatAll("%s %t", TAG_COLORED, "red team muted");
			Jail_Log("Red team has been muted permanently this round.");
		}
	}
	
	if (LR_Number != -1)
	{
		new Handle:LastRequestConfig = CreateKeyValues("TF2Jail_LastRequests");
		FileToKeyValues(LastRequestConfig, LRConfig_File);
	
		decl String:buffer[255], String:number[255];
	
		if (KvGotoFirstSubKey(LastRequestConfig))
		{
			IntToString(LR_Number, number, sizeof(number));
			KvGetSectionName(LastRequestConfig, buffer, sizeof(buffer));
			
			if (StrEqual(buffer, number))
			{
				new bool:NotActiveRound = true, bool:IsFreedayRound = false;
				if (KvJumpToKey(LastRequestConfig, "Parameters"))
				{
					if (KvGetNum(LastRequestConfig, "ActiveRound", 0) == 1)
					{
						NotActiveRound = false;
						Jail_Log("%s Active Round is 1.", TAG);
					}
				}
				KvGoBack(LastRequestConfig);
				
				if (!NotActiveRound)
				{
					Jail_Log("%s Active round = false executed", TAG);
					decl String:ServerCommands[255];
					if (KvGetString(LastRequestConfig, "ServerCommand", ServerCommands, sizeof(ServerCommands)))
					{
						ServerCommand("%s", ServerCommands);
						Jail_Log("%s Executed %s into console.", TAG, ServerCommands);
					}
					
					if (KvJumpToKey(LastRequestConfig, "Parameters"))
					{
						if (KvGetNum(LastRequestConfig, "IsSuicide", 0) == 1)
						{
							if (!NotActiveRound)
							{
								for (new i = 1; i <= MaxClients; i++)
								{
									if (i == Suicide)
									{
										ForcePlayerSuicide(i);
										Jail_Log("%s Suicide forced on %s.", TAG, i);
									}
								}
								Suicide = -1;
							}
						}
						
						if (KvGetNum(LastRequestConfig, "IsFreedayType", 0) != 0)
						{
							IsFreedayRound = true;
						}

						if (KvGetNum(LastRequestConfig, "OpenCells", 0) == 1)
						{
							DoorHandler(DM_OPEN);
						}
						
						if (KvGetNum(LastRequestConfig, "VoidFreekills", 0) == 1)
						{
							g_VoidFreekills = true;
						}
						
						if (KvGetNum(LastRequestConfig, "TimerStatus", 1) == 0)
						{
							if (g_bTimerStatus)
							{
								ServerCommand("sm_countdown_enabled 0");
								g_bTimerStatus = false;
							}
						}
						
						if (KvGetNum(LastRequestConfig, "LockWarden", 0) == 1)
						{
							g_bLockWardenLR = true;
						}
						else
						{
							g_bLockWardenLR = false;
						}
						
						if (KvJumpToKey(LastRequestConfig, "FriendlyFire"))
						{
							if (KvGetNum(LastRequestConfig, "Status", 0) == 1)
							{
								new Float:TimeFloat = KvGetFloat(LastRequestConfig, "Timer", 1.0);
								if (TimeFloat >= 0.1)
								{
									CreateTimer(TimeFloat, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
								}
								else
								{
									Jail_Log("[ERROR] Timer is set to a value below 0.1! Timer could not be created.");
								}
							}
							KvGoBack(LastRequestConfig);
						}
						KvGoBack(LastRequestConfig);
					}
					else
					{
						Jail_Log("[TF2Jail]Error Parsing Parameter", TAG);
					}
					
					decl String:ActiveAnnounce[255];
					if (KvGetString(LastRequestConfig, "Activated", ActiveAnnounce, sizeof(ActiveAnnounce)))
					{
						if (IsFreedayRound)
						{
							decl String:ClientName[32];
							for (new i = 1; i <= MaxClients; i++)
							{
								if (g_IsFreedayActive[i])
								{
									GetClientName(i, ClientName, sizeof(ClientName));
									ReplaceString(ActiveAnnounce, sizeof(ActiveAnnounce), "%M", ClientName, true);
									Format(ActiveAnnounce, sizeof(ActiveAnnounce), "%s %s", TAG_COLORED, ActiveAnnounce);
									CPrintToChatAll(ActiveAnnounce);
								}
							}
						}
						else
						{
							Format(ActiveAnnounce, sizeof(ActiveAnnounce), "%s %s", TAG_COLORED, ActiveAnnounce);
							CPrintToChatAll(ActiveAnnounce);
						}
					}
				}
				else
				{
					Jail_Log("%s Active Round is 0.", TAG);
				}
			}
		}
		else
		{
			Jail_Log("[ERROR] Could not parse config file, please check for existence and integrity of the file.");
			CloseHandle(LastRequestConfig);
		}
		
		LR_Number = -1;
		Jail_Log("%s LR set to -1", TAG);
	}
	else
	{
		Jail_Log("%s LR - -1", TAG);
	}
	
	if (j_WardenAuto)
	{
		new client = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE|CLIENTFILTER_NOBOTS);
		if (IsValidClient(client) && Warden == -1)
		{
			WardenSet(client);
			Jail_Log("%N has been set to warden automatically at the start of this arena round.", client);
		}
	}
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	g_bIsWardenLocked = true;
	g_bOneGuardLeft = false;
	g_bActiveRound = false;
	FreedayLimit = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			UnmutePlayer(i);
			if (g_IsFreedayActive[i])
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
		}
	}
	
	if (GetConVarBool(JB_EngineConVars[0]))
	{
		SetConVarBool(JB_EngineConVars[0], false);
	}

	if (GetConVarBool(JB_EngineConVars[1]))
	{
		SetConVarBool(JB_EngineConVars[1], false);
	}

	if (g_VoidFreekills)
	{
		g_VoidFreekills = false;
	}
	
	if (g_bIsLowGravRound)
	{
		ResetConVar(JB_EngineConVars[2], true, true);
		g_bIsLowGravRound = false;
	}
	
	if (g_bIsDiscoRound)
	{
		ServerCommand("sm_disco");
		g_bIsDiscoRound = false;
	}
	
	if (!g_bTimerStatus)
	{
		ServerCommand("sm_countdown_enabled 2");
	}
	
	ClearTimer(g_refreshspellstimer);
	
	CloseAllMenus();

	return Plugin_Continue;
}

public Action:RegeneratePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (j_Enabled)
	{
		CreateTimer(0.1, ManageWeapons, client);
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
		
		if (StrContains(classname, "point_servercommand", false) != -1)
		{
			if (j_KillPointServerCommand)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
}

public Action:InterceptBuild(client, const String:command[], args)
{
	if (j_Enabled && IsValidClient(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public bool:OnClientSpeakingEx(client)
{
	if (j_Enabled && e_voiceannounce_ex && j_MicCheck && !g_HasTalked[client])
	{
		g_HasTalked[client] = true;
		CPrintToChat(client, "%s %t", TAG_COLORED, "microphone verified");
	}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:Command_FireWarden(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}

	if (j_WVotesPassedLimit != 0)
	{
		if (WardenLimit < j_WVotesPassedLimit) AttemptFireWarden(client);
		else
		{
			PrintToChat(client, "You are not allowed to vote again, the warden fire limit has been reached.");
			return Plugin_Handled;
		}
	}
	else AttemptFireWarden(client);

	return Plugin_Handled;
}

AttemptFireWarden(client)
{
	if (GetClientCount(true) < j_WVotesMinPlayers)
	{
		CReplyToCommand(client, "%s %t", TAG, "fire warden minimum players not met");
		return;			
	}

	if (g_Voted[client])
	{
		CReplyToCommand(client, "%s %t", TAG, "fire warden already voted", g_Votes, g_VotesNeeded);
		return;
	}

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	g_Votes++;
	g_Voted[client] = true;

	CPrintToChatAll("%s %t", TAG_COLORED, "fire warden requested", name, g_Votes, g_VotesNeeded);

	if (g_Votes >= g_VotesNeeded) FireWardenCall();
}

FireWardenCall()
{
	if (Warden != -1)
	{
		for (new i=1; i<=MAXPLAYERS; i++)
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
	for (new i=1; i<=MAXPLAYERS; i++) g_Voted[i] = false;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:AdminMapCompatibilityCheck(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	new open_cells = Entity_FindByName("open_cells", "func_button");
	new cell_door = Entity_FindByName("cell_door", "func_door");
	
	if (Entity_IsValid(open_cells))
	{
		CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Opener Detected");
	}
	else
	{
		CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Opener Undetected");
	}
	
	if (Entity_IsValid(cell_door))
	{
		CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Doors Detected");
	}
	else
	{
		CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Doors Detected");
	}
	CShowActivity2(client, TAG, "%t", "Admin Scan Map Compatibility", client);
	Jail_Log("Admin %N has checked the map for compatibility.", client);

	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_ScoutsBlockedDoubleJump[i] = false;
		g_PyrosDisableAirblast[i] = false;
		g_IsMuted[i] = false;
		g_IsRebel[i] = false;
		g_IsFreeday[i] = false;
		g_IsFreedayActive[i] = false;
		g_IsFreekiller[i] = false;
		g_HasTalked[i] = false;
		g_LockedFromWarden[i] = false;
		g_HasModel[i] = false;

		g_FirstKill[i] = 0;
		g_Killcount[i] = 0;
		g_AmmoCount[i] = 0;
		g_HasBeenWarden[i] = 0;
		
		if (IsClientConnected(i))
		{
			OnClientConnected(i);
		}
	}

	g_IsMapCompatible = false;
	g_CellDoorTimerActive = false;
	g_1stRoundFreeday = false;
	g_VoidFreekills = false;
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	g_bIsLowGravRound = false;
	g_bIsDiscoRound = false;
	g_bOneGuardLeft = false;
	g_bTimerStatus = true;
	g_bLateLoad = false;

	Warden = -1;
	WardenLimit = 0;
	FreedayLimit = 0;

	enum_WardenMenu = WM_Disabled;
	
	ParseConfigs();

	CPrintToChatAll("%s %t", TAG_COLORED, "admin reset plugin");
	CShowActivity2(client, TAG, "%t", "Admin Reset Plugin", client);
	Jail_Log("Admin %N has reset the plugin of all it's bools, integers and floats.", client);

	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(DM_OPEN);
		CShowActivity2(client, TAG, "%t", "Admin Open Cells", client);
		Jail_Log("Admin %N has opened the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminCloseCells(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(DM_CLOSE);
		CShowActivity2(client, TAG, "%t", "Admin Close Cells", client);
		Jail_Log("Admin %N has closed the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminLockCells(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(DM_LOCK);
		CShowActivity2(client, TAG, "%t", "Admin Lock Cells", client);
		Jail_Log("Admin %N has locked the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG, "incompatible map");
	}
	
	return Plugin_Handled;
}

public Action:AdminUnlockCells(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	if (g_IsMapCompatible)
	{
		DoorHandler(DM_UNLOCK);
		CShowActivity2(client, TAG, "%t", "Admin Unlock Cells", client);
		Jail_Log("Admin %N has unlocked the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminForceWarden(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "current warden", Warden);
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		new Random = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
		if (IsValidClient(Random))
		{
			WardenSet(Random);
			CShowActivity2(client, TAG, "%t", "Admin Force warden Random", client, Random);
			CPrintToChatAll("%s %t", TAG_COLORED, "forced warden", client, Random);
			Jail_Log("Admin %N has given %N Warden by Force.", client, Random);
		}
	}
	else
	{
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));

		new target = FindTarget(client, arg1);
		if (target == -1 || target >= 2 || target == client)
		{
			return Plugin_Handled; 
		}
		CShowActivity2(client, TAG, "%t", "Admin Force warden", client, target);
		WardenSet(target);
		Jail_Log("Admin %N has forced a random Warden. The person who received Warden was %N", client, target);
	}
	
	return Plugin_Handled;
}

public Action:AdminForceLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		CShowActivity2(client, TAG, "%t", "Admin Force Last Request Self", client);
		LastRequestStart(client);
		Jail_Log("Admin %N has given his/herself last request using admin.", client);
	}
	else
	{
		decl String:arg[64];
		GetCmdArgString(arg, sizeof(arg));

		new target = FindTarget(client, arg, true, false);
		if (target == -1 || target == client)
		{
			return Plugin_Handled; 
		}
		CShowActivity2(client, TAG, "%t", "Admin Force Last Request", client, target);
		LastRequestStart(target, false);
		Jail_Log("Admin %N has gave %N a Last Request by admin.", client, target);
	}
	
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_IsFreeday[i])
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "admin removed freeday");
			g_IsFreeday[i] = false;
		}
		if (g_IsFreedayActive[i])
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "admin removed freeday");
			g_IsFreedayActive[i] = false;
		}
	}
	
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	
	CShowActivity2(client, TAG, "%t", "Admin Deny Last Request", client);
	CPrintToChatAll("%s %t", TAG_COLORED, "admin deny lr");
	Jail_Log("Admin %N has denied all currently queued last requests and reset the last request system.", client);

	return Plugin_Handled;
}

public Action:AdminPardonFreekiller(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!j_Freekillers)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "freekillers system disabled");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_IsFreekiller[i])
		{
			TF2_RegeneratePlayer(i);
			ServerCommand("sm_beacon #%d", GetClientUserId(i));
			g_IsFreekiller[i] = false;
			ClearTimer(DataTimerF);
		}
	}
	CShowActivity2(client, TAG, "%t", "Admin Pardon Freekillers", client);
	CPrintToChatAll("%s %t", TAG_COLORED, "admin pardoned freekillers");
	Jail_Log("Admin %N has pardoned all currently marked Freekillers.", client);
	
	return Plugin_Handled;
}

public Action:AdminGiveFreeday(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}

	GiveFreedaysMenu(client);
	return Plugin_Handled;
}

GiveFreedaysMenu(client)
{
	if(!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(MenuHandle_FreedayAdmins, MENU_ACTIONS_ALL);
		SetMenuTitle(menu,"Choose a Player");
		AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
		DisplayMenu(menu, client, 20);
		CShowActivity2(client, TAG, "%t", "Admin Give Freeday Menu", client);
		Jail_Log("Admin %N is giving someone a freeday...", client);
	}
}

public MenuHandle_FreedayAdmins(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, item, info, sizeof(info));

			new target = GetClientOfUserId(StringToInt(info));
			if (target == 0)
			{
				PrintToChat(client, "Client is not valid.");
			}
			else
			{
				GiveFreeday(target);
				Jail_Log("%N has given %N a Freeday.", target, client);
			}
			GiveFreedaysMenu(client);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:AdminRemoveFreeday(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}

	RemoveFreedaysMenu(client);
	return Plugin_Handled;
}

RemoveFreedaysMenu(client)
{
	if(!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(MenuHandle_RemoveFreedays, MENU_ACTIONS_ALL);
		SetMenuTitle(menu,"Choose a Player");
		AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
		DisplayMenu(menu, client, 20);
		CShowActivity2(client, TAG, "%t", "Admin Remove Freeday Menu", client);
		Jail_Log("Admin %N is removing someone's freeday status...", client);
	}
}

public MenuHandle_RemoveFreedays(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, item, info, sizeof(info));

			new target = GetClientOfUserId(StringToInt(info));
			if (target == 0)
			{
				PrintToChat(client, "Client is not valid.");
			}
			else
			{
				RemoveFreeday(target);
				Jail_Log("%N has removed %N's Freeday.", target, client);
			}
			RemoveFreedaysMenu(client);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:AdminAcceptWardenChange(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	switch (enum_WardenMenu)
	{
	case WM_Disabled:
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "no current requests");
		}
	case WM_FFChange:
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire enabled");
			CShowActivity2(client, TAG, "%t", "Admin Accept Request FF", client, Warden);
			Jail_Log("Admin %N has accepted %N's request to enable Friendly Fire.", client, Warden);
		}
	case WM_CCChange:
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CPrintToChatAll("%s %t", TAG_COLORED, "collision enabled");
			CShowActivity2(client, TAG, "%t", "Admin Accept Request CC", client, Warden);
			Jail_Log("Admin %N has accepted %N's request to enable Collision.", client, Warden);
		}
	}
	return Plugin_Handled;
}

public Action:AdminCancelWardenChange(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	switch (enum_WardenMenu)
	{
	case WM_Disabled:
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "no active warden commands");
		}
	case WM_FFChange:
		{
			SetConVarBool(JB_EngineConVars[0], false);
			CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire disabled");
			CShowActivity2(client, TAG, "%t", "Admin Cancel Active FF", client);
			Jail_Log("Admin %N has cancelled %N's request for Friendly Fire.", client, Warden);
		}
	case WM_CCChange:
		{
			SetConVarBool(JB_EngineConVars[1], false);
			CPrintToChatAll("%s %t", TAG_COLORED, "collision disabled");
			CShowActivity2(client, TAG, "%t", "Admin Cancel Active CC", client);
			Jail_Log("Admin %N has cancelled %N's request for Collision.", client, Warden);
		}
	}
	enum_WardenMenu = WM_Disabled;
	return Plugin_Handled;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:BecomeWarden(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}

	if (!j_Warden)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "warden disabled");
		return Plugin_Handled;
	}
	
	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "current warden", Warden);
		return Plugin_Handled;
	}
	
	if (j_WardenLimit != 0)
	{
		if (g_HasBeenWarden[client] >= j_WardenLimit && GetClientTeam(client) == _:TFTeam_Blue)
		{	
			CPrintToChat(client, "%s %t", TAG_COLORED, "warden limit reached", client, j_WardenLimit);
			return Plugin_Handled;
		}
	}
	
	if (j_MicCheck && !j_MicCheckType && !g_HasTalked[client])
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "microphone check warden block");
		return Plugin_Handled;
	}
	
	if (g_1stRoundFreeday || g_bIsWardenLocked)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "warden locked");
		return Plugin_Handled;
	}
	
	if (j_LRSLockWarden && g_bLockWardenLR)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "warden locked lr round");
		return Plugin_Handled;
	}
	
	if (g_LockedFromWarden[client])
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "voted off of warden");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) == _:TFTeam_Blue)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			CPrintToChatAll("%s %t", TAG_COLORED, "new warden", client);
			CPrintToChat(client, "%s %t", TAG_COLORED, "warden message");
			WardenSet(client);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "dead warden");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "guards only");
	}
	
	return Plugin_Handled;
}

public Action:WardenMenuC(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		WardenMenu(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
	}

	return Plugin_Handled;
}

WardenMenu(client)
{
	if(IsVoteInProgress()) return;

	new Handle:menu = CreateMenu(MenuHandle_WardenMenu, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Available Warden Commands:");
	AddMenuItem(menu, "1", "Open Cells");
	AddMenuItem(menu, "2", "Close Cells");
	AddMenuItem(menu, "3", "Toggle Friendlyfire");
	AddMenuItem(menu, "4", "Toggle Collision");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public MenuHandle_WardenMenu(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			switch (item)
			{
			case 0: FakeClientCommandEx(client, "say /open");
			case 1: FakeClientCommandEx(client, "say /close");
			case 2: FakeClientCommandEx(client, "say /wff");
			case 3: FakeClientCommandEx(client, "say /wcc");
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:WardenFriendlyFire(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}

	if (!j_WardenFF)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "warden friendly fire manage disabled");
		return Plugin_Handled;
	}
	
	if (client != Warden)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
		return Plugin_Handled;
	}

	if (!j_WardenRequest)
	{
		if (!GetConVarBool(JB_EngineConVars[0]))
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire enabled");
			Jail_Log("%N has enabled friendly fire as warden.", Warden);
		}
		else
		{
			SetConVarBool(JB_EngineConVars[0], false);
			CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire disabled");
			Jail_Log("%N has disabled friendly fire as warden.", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire request");
		enum_WardenMenu = WM_FFChange;
	}
	
	return Plugin_Handled;
}

public Action:WardenCollision(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!j_WardenCC)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "warden collision manage disabled");
		return Plugin_Handled;
	}
	
	if (client != Warden)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
		return Plugin_Handled;
	}
	
	if (!j_WardenRequest)
	{
		if (!GetConVarBool(JB_EngineConVars[1]))
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CPrintToChatAll("%s %t", TAG_COLORED, "collision enabled");
			Jail_Log("%N has enabled collision as warden.", Warden);
		}
		else
		{
			SetConVarBool(JB_EngineConVars[1], false);
			CPrintToChatAll("%s %t", TAG_COLORED, "collision disabled");
			Jail_Log("%N has disabled collision as warden.", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", TAG_COLORED, "collision request");
		enum_WardenMenu = WM_CCChange;
	}

	return Plugin_Handled;
}

public Action:ExitWarden(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		CPrintToChatAll("%s %t", TAG_COLORED, "warden retired", client);
		PrintCenterTextAll("%t", "warden retired center");
		WardenUnset(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
	}

	return Plugin_Handled;
}

public Action:AdminRemoveWarden(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (Warden != -1)
	{
		CPrintToChatAll("%s %t", TAG_COLORED, "warden fired", client, Warden);
		PrintCenterTextAll("%t", "warden fired center");
		CShowActivity2(client, TAG, "%t", "Admin Remove warden", client, Warden);
		Jail_Log("Admin %N has removed %N's Warden status with admin.", client, Warden);
		WardenUnset(Warden);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "no warden current");
	}

	return Plugin_Handled;
}

public Action:OnOpenCommand(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		if (j_DoorControl)
		{
			if (IsWarden(client))
			{
				DoorHandler(DM_OPEN);
				Jail_Log("%N has opened the cell doors using door controls as warden.", client);
			}
			else
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "door controls disabled");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}

	if (g_IsMapCompatible)
	{
		if (j_DoorControl)
		{
			if (IsWarden(client))
			{
				DoorHandler(DM_CLOSE);
				Jail_Log("%N has closed the cell doors using door controls as warden.", client);
			}
			else
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "door controls disabled");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:GiveLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!j_LRSEnabled)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "lr system disabled");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		if (!g_bIsLRInUse)
		{
			if(IsVoteInProgress()) return Plugin_Handled;

			new Handle:menu = CreateMenu(MenuHandle_GiveLR, MENU_ACTIONS_ALL);
			SetMenuTitle(menu,"Choose a Player:");
			AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
			DisplayMenu(menu, client, 20);
			Jail_Log("%N is giving someone a last request...", client);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "last request in use");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
	}

	return Plugin_Handled;
}

public MenuHandle_GiveLR(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[32];
			decl String:Name[32];    
			GetMenuItem(menu, item, info, sizeof(info));     
			new iInfo = StringToInt(info);
			new iUserid = GetClientOfUserId(iInfo);
			GetClientName(iUserid, Name, sizeof(Name));    
			if (GetClientTeam(iUserid) != _:TFTeam_Red)
			{
				PrintToChat(client,"You cannot give LR to a guard or spectator!");
			}
			else
			{
				LastRequestStart(iUserid);
				CPrintToChatAll("%s %t", TAG_COLORED, "last request given", Warden, iUserid);
				Jail_Log("%N has given %N a Last Request as warden.", client, iUserid);
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:RemoveLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	if (!client)
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (client != Warden)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
		return Plugin_Handled;
	}
	
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = false;
	CPrintToChat(Warden, "%s %t", TAG_COLORED, "warden removed lr");
	Jail_Log("Warden %N has cleared all last requests currently queued.", client);

	return Plugin_Handled;
}

WardenSet(client)
{
	Warden = client;
	g_HasBeenWarden[client]++;
	
	switch (j_WardenVoice)
	{
		case 1: SetClientListeningFlags(client, VOICE_NORMAL);
		case 2: CPrintToChatAll("%s %t", TAG_COLORED, "warden voice muted", Warden);
	}
	
	if (j_WardenForceSoldier)
	{
		TF2_SetPlayerClass(client, TFClass_Soldier);
	}

	if (j_WardenModel) SetModel(client, WARDEN_MODEL);
	
	if (j_WardenStabProtection == 1) AddAttribute(client, "backstab shield", 1.0);
	
	SetHudTextParams(-1.0, -1.0, 2.0, 255, 255, 255, 255, 1, _, 1.0, 1.0);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (j_BlueMute == 1)
			{
				if (GetClientTeam(i) == _:TFTeam_Blue && i != Warden)
				{
					MutePlayer(i);
				}
			}
			ShowSyncHudText(i, WardenName, "%t", "Current warden Screen Message", Warden);
		}
	}
	ResetVotes();
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

		}
	}
	
	if (j_BlueMute == 1)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue && i != Warden)
			{
				UnmutePlayer(i);
			}
		}
	}
	
	RemoveAttribute(client, "backstab shield");
	
	Forward_OnWardenRemoved(client);
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && IsWarden(client) && !g_HasModel[client])
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		if (j_WardenWearables)
		{
			new iEntity = -1;
			while((iEntity = FindEntityByClassnameSafe(iEntity, "tf_wear*")) != -1)
			{
				if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(iEntity, "kill");
				}
			}
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
		g_HasModel[client] = false;
	}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
LastRequestStart(client, bool:Timer = true)
{
	if(IsVoteInProgress()) return;

	new Handle:LRMenu_Handle = CreateMenu(MenuHandle_LR, MENU_ACTIONS_ALL);
	SetMenuTitle(LRMenu_Handle, "Last Request Menu");

	new Handle:LastRequestConfig = CreateKeyValues("TF2Jail_LastRequests");

	if (!FileToKeyValues(LastRequestConfig, LRConfig_File))
	{
		Jail_Log("Last Request config not found, functionality disabled. Please make sure to check your configs folder.");
		g_bLRConfigActive = false;
	}
	else
	{
		if (KvGotoFirstSubKey(LastRequestConfig))
		{
			decl String:LR_ID[64];
			decl String:LR_NAME[255];
			do
			{
				KvGetSectionName(LastRequestConfig, LR_ID, sizeof(LR_ID));    
				KvGetString(LastRequestConfig, "Name", LR_NAME, sizeof(LR_NAME));
				
				if (KvJumpToKey(LastRequestConfig, "Parameters"))
				{
					if (kvbool(KvGetNum(LastRequestConfig, "Disabled", 0)))
					{
						AddMenuItem(LRMenu_Handle, LR_ID, LR_NAME);
					}
					else
					{
						AddMenuItem(LRMenu_Handle, LR_ID, LR_NAME, ITEMDRAW_DISABLED);
					}
					KvGoBack(LastRequestConfig);
				}
			}
			while (KvGotoNextKey(LastRequestConfig));
			
			g_bLRConfigActive = true;
		}
		else
		{
			Jail_Log("Last Request config could not be parsed! Please check the validity of your config.");
			g_bLRConfigActive = false;
		}
	}
	CloseHandle(LastRequestConfig);

	SetMenuExitButton(LRMenu_Handle, true);
	DisplayMenu(LRMenu_Handle, client, 30 );
	
	CPrintToChat(client, "%s %t", TAG_COLORED, "warden granted lr");
	g_bIsLRInUse = true;
	
	if (!Timer && g_bTimerStatus)
	{
		ServerCommand("sm_countdown_enabled 0");
	}
}

public MenuHandle_LR(Handle:menu, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			new Handle:LastRequestConfig = CreateKeyValues("TF2Jail_LastRequests");
			FileToKeyValues(LastRequestConfig, LRConfig_File);

			if (KvGotoFirstSubKey(LastRequestConfig))
			{
				decl String:buffer[255];
				decl String:choice[255];
				GetMenuItem(menu, item, choice, sizeof(choice));     

				do
				{
					KvGetSectionName(LastRequestConfig, buffer, sizeof(buffer));
					if (StrEqual(buffer, choice))
					{
						decl String:QueueAnnounce[255], String:ClientName[32];
						if (KvGetString(LastRequestConfig, "Queue_Announce", QueueAnnounce, sizeof(QueueAnnounce)))
						{
							GetClientName(client, ClientName, sizeof(ClientName));
							ReplaceString(QueueAnnounce, sizeof(QueueAnnounce), "%M", ClientName, true);
							Format(QueueAnnounce, sizeof(QueueAnnounce), "%s %s", TAG_COLORED, QueueAnnounce);
							CPrintToChatAll(QueueAnnounce);
						}
						
						if (KvJumpToKey(LastRequestConfig, "Parameters"))
						{
							new bool:ActiveRound = true;
							if (KvGetNum(LastRequestConfig, "ActiveRound", 0) == 0)
							{
								ActiveRound = false;
							}

							new FreedayValue = KvGetNum(LastRequestConfig, "IsFreedayType", 0);
							switch (FreedayValue)
							{
								case 1:
								{
									if (ActiveRound)
									{
										g_IsFreeday[client] = true;
									}
									else
									{
										GiveFreeday(client);
									}
								}
								case 2:
								{
									FreedayforClientsMenu(client);
								}
							}
							
							if (KvGetNum(LastRequestConfig, "IsSuicide", 0) == 1)
							{
								if (ActiveRound)
								{
									ForcePlayerSuicide(client);
								}
								else
								{
									Suicide = client;
								}
							}
							
							if (KvJumpToKey(LastRequestConfig, "KillWeapons"))
							{
								new both = 0;
								if (KvGetNum(LastRequestConfig, "Red", 0) == 1)
								{
									KillWeaponsEnumHandle = KW_Red;
									both++;
								}
							
								if (KvGetNum(LastRequestConfig, "Blue", 0) == 1)
								{
									KillWeaponsEnumHandle = KW_Blue;
									both++;
								}
								
								if (both == 2)
								{
									KillWeaponsEnumHandle = KW_Both;
								}
								KvGoBack(LastRequestConfig);
							}
							else
							{
								KillWeaponsEnumHandle = KW_Disabled;
								KvGoBack(LastRequestConfig);
							}
							KvGoBack(LastRequestConfig);
						}
					}
				}while (KvGotoNextKey(LastRequestConfig));
				
				LR_Number = StringToInt(choice);
				CloseHandle(LastRequestConfig);
			}
			else
			{
				CloseHandle(LastRequestConfig);
				CloseHandle(menu);
			}
			
			g_bIsWardenLocked = true;
		}
	case MenuAction_Cancel:
		{
			g_bIsLRInUse = false;
			CPrintToChatAll("%s %t", TAG_COLORED, "last request closed");
		}
	case MenuAction_End: CloseHandle(menu), g_bIsLRInUse = false;
	}
}

FreedayforClientsMenu(client)
{
	if(IsVoteInProgress()) return;

	new Handle:menu2 = CreateMenu(MenuHandle_FreedayForClients, MENU_ACTIONS_ALL);

	SetMenuTitle(menu2, "Choose a Player");
	SetMenuExitBackButton(menu2, false);
	
	AddTargetsToMenu2(menu2, 0, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	
	DisplayMenu(menu2, client, MENU_TIME_FOREVER);
}

public MenuHandle_FreedayForClients(Handle:menu2, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu2, item, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));
			
			if (IsValidClient(client) && !IsClientInKickQueue(client))
			{
				if (target == 0)
				{
					CPrintToChat(client, "%s %t", TAG_COLORED, "Player no longer available");
					FreedayforClientsMenu(client);
				}
				else if (g_IsFreeday[target])
				{
					CPrintToChat(client, "%s %t", TAG_COLORED, "freeday currently queued", target);
					FreedayforClientsMenu(client);
				}
				else
				{
					if (FreedayLimit < j_FreedayLimit)
					{
						g_IsFreeday[target] = true;
						FreedayLimit++;
						CPrintToChatAll("%s %t", TAG_COLORED, "lr freeday picked clients", client, target);
						FreedayforClientsMenu(client);
					}
					else
					{
						CPrintToChatAll("%s %t", TAG_COLORED, "lr freeday picked clients maxed", client);
					}
				}
			}
		}
	case MenuAction_Cancel:
		{
			LastRequestStart(client);
		}
	case MenuAction_End: CloseHandle(menu2);
	}
}

/* Stock Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}

GiveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CPrintToChat(client, "%s %t", TAG_COLORED, "lr freeday message");
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	if(j_FreedayTeleports && g_bFreedayTeleportSet) TeleportEntity(client, free_pos, NULL_VECTOR, NULL_VECTOR);
	
	decl String:Particle[100];
	GetConVarString(JB_ConVars[51], Particle, sizeof(Particle));
	CreateParticle(Particle, 3.0, client, ATTACH_NORMAL);
	
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = true;
	Jail_Log("%N has been given a Freeday.", client);
}

RemoveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	CPrintToChatAll("%s %t", TAG_COLORED, "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	g_IsFreedayActive[client] = false;
	Jail_Log("%N is no longer a Freeday.", client);
}

MarkRebel(client)
{
	g_IsRebel[client] = true;
	
	decl String:Particle[100];
	GetConVarString(JB_ConVars[50], Particle, sizeof(Particle));
	CreateParticle(Particle, 3.0, client, ATTACH_NORMAL);
	
	CPrintToChatAll("%s %t", TAG_COLORED, "prisoner has rebelled", client);
	if (j_RebelsTime >= 1.0)
	{
		new time = RoundFloat(j_RebelsTime);
		CPrintToChat(client, "%s %t", TAG_COLORED, "rebel timer start", time);
		CreateTimer(j_RebelsTime, RemoveRebel, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	Jail_Log("%N has been marked as a Rebeller.", client);
}

MarkFreekiller(client)
{
	g_IsFreekiller[client] = true;
	
	decl String:Particle[100];
	GetConVarString(JB_ConVars[49], Particle, sizeof(Particle));
	CreateParticle(Particle, 3.0, client, ATTACH_NORMAL);
	
	TF2_RemoveAllWeapons(client);
	ServerCommand("sm_beacon #%d", GetClientUserId(client));
	EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
	
	if (j_FreekillersWave >= 1.0)
	{
		new time = RoundFloat(j_FreekillersWave);
		CPrintToChatAll("%s %t", TAG_COLORED, "freekiller timer start", client, time);

		decl String:sAuth[24];
		if(!GetClientAuthString(client, sAuth, sizeof(sAuth[])))
		{
			CReplyToCommand(client, "%s Client failed to auth, delayed ban not possible.", TAG);
			return;
		}
		else
		{
			new Handle:hPack;
			DataTimerF = CreateDataTimer(j_FreekillersWave, BanClientTimerFreekiller, hPack);
			WritePackCell(hPack, client);
			WritePackCell(hPack, GetClientUserId(client));
			WritePackString(hPack, sAuth);
			if (DataTimerF != INVALID_HANDLE)
			{
				PushArrayCell(hPack, DataTimerF);
			}
		}
	}
	Jail_Log("%N has been marked as a Freekiller.", client);
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

ClearTimer(&Handle:hTimer)
{
	if (hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

AddAttribute(client, String:attribute[], Float:value)
{
	if (e_tf2attributes)
	{
		if (IsValidClient(client))
		{
			TF2Attrib_SetByName(client, attribute, value);
		}
	}
	else
	{
		Jail_Log("TF2 Attributes is not currently installed, skipping attribute set.");
	}
}

RemoveAttribute(client, String:attribute[])
{
	if (e_tf2attributes)
	{
		if (IsValidClient(client))
		{
			TF2Attrib_RemoveByName(client, attribute);
		}
	}
	else
	{
		Jail_Log("TF2 Attributes is not currently installed, skipping attribute set.");
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

bool:AlreadyMuted(client)
{
	switch (enumCommsList)
	{
	case Basecomms:
		{
			if (!BaseComm_IsClientMuted(client))
			{
				return false;
			}
			else return true;
		}
	case Sourcecomms:
		{
			if (SourceComms_GetClientMuteType(client) == bNot)
			{
				return false;
			}
			else return true;
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

Jail_Log(const String:format[], any:...)
{
	switch (j_Logging)
	{
	case 1:
		{
			decl String:buffer[256];
			VFormat(buffer, sizeof(buffer), format, 2);
			LogMessage("%s", buffer);
			PrintToServer("%s", buffer);
		}
	case 2:
		{
			decl String:buffer[256], String:path[PLATFORM_MAX_PATH];
			VFormat(buffer, sizeof(buffer), format, 2);
			BuildPath(Path_SM, path, sizeof(path), "logs/TF2Jail.log");
			LogToFileEx(path, "%s", buffer);
			PrintToServer("%s", buffer);
		}
	}
}

bool:IsWarden(client)
{
	if (client == Warden)
	{
		return true;
	}
	else
	{
		return false;
	}
}

PluginEvents(bool:Enable = true)
{
	if (Enable)
	{
		HookEvent("player_spawn", PlayerSpawn);
		HookEvent("player_hurt", PlayerHurt);
		HookEvent("player_death", PlayerDeath);
		HookEvent("teamplay_round_start", RoundStart);
		HookEvent("arena_round_start", ArenaRoundStart);
		HookEvent("teamplay_round_win", RoundEnd);
		HookEvent("post_inventory_application", RegeneratePlayer);
		HookEvent("player_changeclass", ChangeClass, EventHookMode_Pre);
		AddCommandListener(InterceptBuild, "build");
	}
	else
	{
		UnhookEvent("player_spawn", PlayerSpawn);
		UnhookEvent("player_hurt", PlayerHurt);
		UnhookEvent("player_death", PlayerDeath);
		UnhookEvent("teamplay_round_start", RoundStart);
		UnhookEvent("arena_round_start", ArenaRoundStart);
		UnhookEvent("teamplay_round_win", RoundEnd);
		UnhookEvent("post_inventory_application", RegeneratePlayer);
		UnhookEvent("player_changeclass", ChangeClass, EventHookMode_Pre);
		RemoveCommandListener(InterceptBuild, "build");
	}
}

MutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && !g_IsMuted[client])
	{
		Client_Mute(client);
		g_IsMuted[client] = true;
		CPrintToChat(client, "%s %t", TAG_COLORED, "muted player");
	}
}

UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && g_IsMuted[client])
	{
		Client_UnMute(client);
		g_IsMuted[client] = false;
		CPrintToChat(client, "%s %t", TAG_COLORED, "unmuted player");
	}
}

ParseConfigs()
{
	new Handle:MapConfig = CreateKeyValues("TF2Jail_MapConfig");
	
	decl String:MapConfig_File[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, MapConfig_File, sizeof(MapConfig_File), "configs/tf2jail/mapconfig.cfg");
	
	decl String:g_Mapname[128];
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));

	PrintToServer("Loading %s...", g_Mapname);

	if (!FileToKeyValues(MapConfig, MapConfig_File))
	{
		Jail_Log("Map config not found, functionality disabled. Please make sure to check your configs folder.");
		g_bFreedayTeleportSet = false;
	}
	else
	{
		if (KvJumpToKey(MapConfig, g_Mapname))
		{
			decl String:CellNames[32], String:CellsButton[32];
			
			KvGetString(MapConfig, "CellNames", CellNames, sizeof(CellNames), "");
			if (!StrEqual(CellNames, ""))
			{
				new CellNames_H = Entity_FindByName(CellNames, "func_door");
				if (Entity_IsValid(CellNames_H))
				{
					GCellNames = CellNames;
					g_IsMapCompatible = true;
				}
				else
				{
					Jail_Log("Cell doors not detected as the name %s on the map %s.", CellNames, g_Mapname);
				}
			}
			else
			{
				Jail_Log("Cell door names not set in the map config for %s. Disabling door controls.", g_Mapname);
			}
			
			KvGetString(MapConfig, "CellsButton", CellsButton, sizeof(CellsButton), "");
			if (!StrEqual(CellsButton, ""))
			{
				new CellsButton_H = Entity_FindByName(CellsButton, "func_button");
				if (Entity_IsValid(CellsButton_H))
				{
					GCellOpener = CellsButton;
				}
				else
				{
					Jail_Log("Cell opener button not detected as the name %s on the map %s.", CellNames, g_Mapname);
				}
			}
			else
			{
				Jail_Log("Cell door names not set in the map config for %s. Disabling door controls.", g_Mapname);
			}
			
			if (KvJumpToKey(MapConfig, "Freeday"))
			{
				if (KvJumpToKey(MapConfig, "Teleport"))
				{
					g_bFreedayTeleportSet = (KvGetNum(MapConfig, "Status", 1) == 1);
					free_pos[0] = KvGetFloat(MapConfig, "Coordinate_X", 0.0);
					free_pos[1] = KvGetFloat(MapConfig, "Coordinate_Y", 0.0);
					free_pos[2] = KvGetFloat(MapConfig, "Coordinate_Z", 0.0);
					
					PrintToServer("Freeday Teleport Coordinates: %f, %f, %f", free_pos[0], free_pos[1], free_pos[2]);
				}
				else
				{
					Jail_Log("Invalid config! Could not access subkey: Freeday/Teleport");
					g_bFreedayTeleportSet = false;
				}
			}
			else
			{
				Jail_Log("Invalid config! Could not access subkey: Freeday");
				g_bFreedayTeleportSet = false;
			}
			
			PrintToServer("Successfully parsed %s", g_Mapname);
		}
		else
		{
			Jail_Log("Map name '%s' not found in the config. Please add a new key entry for the map.", g_Mapname);
			g_bFreedayTeleportSet = false;
		}
	}
	CloseHandle(MapConfig);
}

EmptyWeaponSlots(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
	case TFClass_DemoMan, TFClass_Engineer, TFClass_Medic, TFClass_Scout, TFClass_Soldier, TFClass_Spy:
		{
			SetClip(client, 0, 0);
			SetClip(client, 1, 0);
			SetAmmo(client, 0, 0);
			SetAmmo(client, 1, 0);
		}
	case TFClass_Heavy, TFClass_Pyro, TFClass_Sniper:
		{
			SetClip(client, 1, 0);
			SetAmmo(client, 0, 0);
			SetAmmo(client, 1, 0);
		}
	}
	
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (primary > MaxClients && IsValidEdict(primary))
	{
		new index = -1;
		index = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
		case 56, 1005: SetClip(client, 0, 0);
		}
	}

	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 5);
	CPrintToChat(client, "%s %t", TAG_COLORED, "stripped weapons and ammo");
}

GiveRandomSpell(client)
{
	new rint = GetRandomInt(0,11);
	new ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
	{
		if(ent)
		{
			if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetHudTextParams(-1.0, 0.65, 6.0, 0, 255, 0, 255);
				SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", rint);
				SetEntProp(ent, Prop_Send, "m_iSpellCharges", 2);
				switch (rint)
				{
				case 0: ShowHudText(client, -1, "Picked up the spell: Fire Ball");
				case 1: ShowHudText(client, -1, "Picked up the spell: Bat Missiles");
				case 2: ShowHudText(client, -1, "Picked up the spell: Uber Charge");
				case 3: ShowHudText(client, -1, "Picked up the spell: Giant Bomb");
				case 4: ShowHudText(client, -1, "Picked up the spell: Super Jump");
				case 5: ShowHudText(client, -1, "Picked up the spell: Invisible");
				case 6: ShowHudText(client, -1, "Picked up the spell: Teleportation");
				case 7: ShowHudText(client, -1, "Picked up the spell: Electro Bolt");
				case 8: ShowHudText(client, -1, "Picked up the spell: Tiny Demon");
				case 9: ShowHudText(client, -1, "Picked up the spell: TEAM MONOCULUS");
				case 10: ShowHudText(client, -1, "Picked up the spell: Meteor Shower");
				case 11: ShowHudText(client, -1, "Picked up the spell: Skeleton Army");
				}
			}
		}
	}
}

CloseAllMenus()
{
	for (new idx = 1; idx < MaxClients; idx++)
	{
		if (IsClientInGame(idx))
		{
			if (GetClientTeam(idx) == _:TFTeam_Red)
			{
				if (GetClientMenu(idx))
				{
					CancelClientMenu(idx);
				}
			}
		}
	}
}

DoorHandler(DoorMode:status)
{
	if (!StrEqual(GCellNames, ""))
	{
		for (new i = 0; i < sizeof(DoorList); i++)
		{
			new String:buffer[60], ent = -1;
			while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
			{
				GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if (StrEqual(buffer, GCellNames, false))
				{
					switch (status)
					{
						case DM_OPEN: AcceptEntityInput(ent, "Open");
						case DM_CLOSE: AcceptEntityInput(ent, "Close");
						case DM_LOCK: AcceptEntityInput(ent, "Lock");
						case DM_UNLOCK: AcceptEntityInput(ent, "Unlock");
					}
				}
			}
		}
		switch (status)
		{
			case DM_OPEN:
				{
					CPrintToChatAll("%s %t", TAG_COLORED, "doors opened");
					if (g_CellDoorTimerActive)
					{
						CPrintToChatAll("%s %t", TAG_COLORED, "doors manual open");
						g_CellDoorTimerActive = false;
					}
				}
			case DM_CLOSE: CPrintToChatAll("%s %t", TAG_COLORED, "doors closed");
			case DM_LOCK: CPrintToChatAll("%s %t", TAG_COLORED, "doors locked");
			case DM_UNLOCK: CPrintToChatAll("%s %t", TAG_COLORED, "doors unlocked");
		}
	}
}

bool:kvbool(value)
{
	if (value == 0)
	{
		return false;
	}
	else
	{
		return true;
	}
}

Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle)) {
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
			CreateTimer(time, DeleteParticle, particle);
		}
	}
	else
	{
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}

/* Timers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:UnmuteReds(Handle:hTimer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			UnmutePlayer(i);
		}
	}
	CPrintToChatAll("%s %t", TAG_COLORED, "red team unmuted");
	Jail_Log("All players have been unmuted.");
}

public Action:Open_Doors(Handle:hTimer, any:client)
{
	if (g_CellDoorTimerActive)
	{
		DoorHandler(DM_OPEN);
		new time = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", TAG_COLORED, "cell doors open end", time);
		g_CellDoorTimerActive = false;
		Jail_Log("Doors have been automatically opened by a timer.");
	}
}

public Action:StartMagicianWars(Handle:hTimer, any:client)
{
	SetConVarBool(JB_EngineConVars[0], true);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if (e_tf2items) TF2Items_GiveWeapon(i, 1069);
			GiveRandomSpell(i);
		}
	}
	g_refreshspellstimer = CreateTimer(15.0, RefreshSpells, _, TIMER_REPEAT);
}

public Action:RefreshSpells (Handle:hTimer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			GiveRandomSpell(i);
		}
	}
}

public Action:TimerAdvertisement (Handle:hTimer, any:client)
{
	CPrintToChatAll("%s %t", TAG_COLORED, "plugin advertisement");
}

public Action:CheckWeapons (Handle:hTimer, any:client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
		new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if (IsValidEntity(weapon))
		{
			new Ammo = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			
			if (Ammo != g_AmmoCount[client] && g_IsFreedayActive[client])
			{
				RemoveFreeday(client);
				g_AmmoCount[client] = Ammo;
			}
			else
			{
				g_AmmoCount[client] = Ammo;
			}
		}
	}
}

public Action:Timer_Welcome(Handle:hTimer, any:client)
{
	if (IsValidClient(client))
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "welcome message");
	}
}

public Action:ManageWeapons(Handle:hTimer, any:client)
{
	new team = GetClientTeam(client);
	switch (team)
	{
		case TFTeam_Red:
			{
				if (j_RedMelee)
				{
					EmptyWeaponSlots(client);
				}
				
				if (KillWeaponsEnumHandle == KW_Red || KillWeaponsEnumHandle == KW_Both)
				{
					TF2_RemoveWeaponSlot(client, 0);
					TF2_RemoveWeaponSlot(client, 1);
					TF2_RemoveWeaponSlot(client, 3);
					TF2_RemoveWeaponSlot(client, 4);
					TF2_RemoveWeaponSlot(client, 5);
					TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
				}
			}
		case TFTeam_Blue:
			{
				if (KillWeaponsEnumHandle == KW_Blue || KillWeaponsEnumHandle == KW_Both)
				{
					TF2_RemoveWeaponSlot(client, 0);
					TF2_RemoveWeaponSlot(client, 1);
					TF2_RemoveWeaponSlot(client, 3);
					TF2_RemoveWeaponSlot(client, 4);
					TF2_RemoveWeaponSlot(client, 5);
					TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
				}
			}
	}
	KillWeaponsEnumHandle = KW_Disabled;
}

public Action:BanClientTimerFreekiller(Handle:hTimer, Handle:hPack)
{
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

	switch (j_FreekillersAction)
	{
	case 0:
		{
			if (IsValidClient(client))
			{
				g_IsFreekiller[client] = false;
				TF2_RegeneratePlayer(client);
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
			}
		}
	case 1:
		{
			if (IsValidClient(client))
			{
				ForcePlayerSuicide(client);
				g_IsFreekiller[client] = false;
			}
		}
	case 2:
		{
			if (GetClientOfUserId(userid))
			{
				decl String:BanMsg[100];
				GetConVarString(JB_ConVars[37], BanMsg, sizeof(BanMsg));
				if (e_sourcebans)
				{
					SBBanPlayer(0, client, 60, "Client has been marked for Freekilling.");
					Jail_Log("Client %N has been banned via Sourcebans for being marked as a Freekiller.", userid);
				}
				else
				{
					BanClient(client, j_FreekillersBantime, BANFLAG_AUTHID, "Client has been marked for Freekilling.", BanMsg, "freekillban", client);
					Jail_Log("Client %N has been banned for being marked as a Freekiller.", userid);
				}
			}
			else
			{
				decl String:BanMsgDC[100];
				GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
				BanIdentity(sAuth, j_FreekillersBantimeDC, BANFLAG_AUTHID, BanMsgDC);
				Jail_Log("%N has been banned via identity.", BANFLAG_AUTHID);
			}
		}
	}
	CloseHandle(hPack);
}

public Action:EnableFFTimer(Handle:hTimer)
{
	SetConVarBool(JB_EngineConVars[0], true);
}

public Action:DeleteParticle(Handle:timer, any:Edict)
{	
	if(IsValidEdict(Edict))
	{
		RemoveEdict(Edict);
	}
}

/* Group Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public bool:WardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && IsWarden(i)) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NotWardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && i != Warden) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:RebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && g_IsRebel[i]) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NotRebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && !g_IsRebel[i]) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:FreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && g_IsFreeday[i] || IsValidClient(i) && g_IsFreedayActive[i])PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NotFreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && !g_IsFreeday[i] || IsValidClient(i) && !g_IsFreedayActive[i]) PushArrayCell(hClients, i);
	}
	return true;
}

public Action:RemoveRebel(Handle:hTimer, any:client)
{
	if (IsValidClient(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		CPrintToChat(client, "%s %t", TAG_COLORED, "rebel timer end");
		Jail_Log("%N is no longer a Rebeller.", client);
	}
}

/* Native Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Native_ExistWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden)
	ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");

	if (Warden != -1) return true;
	return false;
}

public Native_IsWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (IsWarden(client)) return true;
	return false;
}

public Native_SetWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (Warden == -1) WardenSet(client);
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (IsWarden(client)) WardenUnset(client);
}

public Native_IsFreeday(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Last Request System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsFreeday[client] || g_IsFreedayActive[client]) return true;
	return false;
}

public Native_GiveFreeday(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Last Request System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (!g_IsFreeday[client] || !g_IsFreedayActive[client]) GiveFreeday(client);
}

public Native_IsRebel(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Rebels) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Rebel System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsRebel[client]) return true;
	return false;
}

public Native_MarkRebel(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Rebels) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Rebel System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (!g_IsRebel[client]) MarkRebel(client);
}

public Native_IsFreekiller(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Freekillers) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Anti-Freekill System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsFreekiller[client]) return true;
	return false;
}

public Native_MarkFreekill(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Freekillers) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Anti-Freekill System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (!g_IsFreekiller[client]) MarkFreekiller(client);
}

public Forward_OnWardenCreation(client)
{
	Call_StartForward(Forward_WardenCreated);
	Call_PushCell(client);
	Call_Finish();
}

public Forward_OnWardenRemoved(client)
{
	Call_StartForward(Forward_WardenRemoved);
	Call_PushCell(client);
	Call_Finish();
}
/* Plugin End ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/