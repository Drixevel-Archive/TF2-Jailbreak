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
#include <jackofdesigns>

//TF2Jail Include
#include <tf2jail>

#undef REQUIRE_EXTENSIONS
#tryinclude <sdkhooks>
#tryinclude <clientprefs>
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <voiceannounce_ex>
#tryinclude <roundtimer>
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME	"[TF2] Jailbreak"
#define PLUGIN_AUTHOR	"Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION	"5.1.5"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT	"http://www.jackofdesigns.com/"
#define WARDEN_MODEL	"models/jailbreak/warden/warden_v2"

#if defined _updater_included
#define UPDATE_URL         "https://raw.github.com/JackofDesigns/TF2-Jailbreak/Beta/updater.txt"
#endif

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

//ConVar Handles, Globals, etc..
new Handle:JB_ConVars[60] = {INVALID_HANDLE, ...};
new bool:j_Enabled = true, bool:j_Advertise = true, bool:j_Cvars = true, j_Logging = 2, bool:j_Balance = true, Float:j_BalanceRatio = 0.5,
bool:j_RedMelee = true, bool:j_Warden = false, bool:j_WardenAuto = false, bool:j_WardenModel = true, bool:j_WardenForceSoldier = true,
bool:j_WardenFF = true, bool:j_WardenCC = true, bool:j_WardenRequest = true, j_WardenLimit = 0, bool:j_DoorControl = true, Float:j_DoorOpenTimer = 60.0,
j_RedMute = 2, Float:j_RedMuteTime = 15.0, j_BlueMute = 2, bool:j_DeadMute = true, bool:j_MicCheck = true, bool:j_MicCheckType = true, bool:j_Rebels = true,
Float:j_RebelsTime = 30.0, j_Criticals = 1, j_Criticalstype = 2, Float:j_WVotesNeeded = 0.60, j_WVotesMinPlayers = 0, j_WVotesPostAction = 0, j_WVotesPassedLimit = 3,
bool:j_Freekillers = true, Float:j_FreekillersTime = 6.0, j_FreekillersKills = 6, Float:j_FreekillersWave = 60.0, j_FreekillersAction = 2, String:BanMsg[255],
String:BanMsgDC[255], j_FreekillersBantime = 60, j_FreekillersBantimeDC = 120, bool:j_LRSEnabled = true, bool:j_LRSAutomatic = true, bool:j_LRSLockWarden = true,
j_FreedayLimit = 3, bool:j_1stDayFreeday = true, bool:j_DemoCharge = true, bool:j_DoubleJump = true, bool:j_Airblast = true, String:Particle_Freekiller[100],
String:Particle_Rebellion[100], String:Particle_Freeday[100], j_WardenVoice = 1, bool:j_WardenWearables = true, bool:j_FreedayTeleports = true, j_WardenStabProtection = 0,
bool:j_KillPointServerCommand = true, bool:j_RemoveFreedayOnLR = true, bool:j_RemoveFreedayOnLastGuard = true, j_Reftype = 1;

//Plugins/Extension bools
new bool:e_voiceannounce_ex = false, bool:e_sourcebans = false, bool:e_steamtools = false;

//Plugin Global Bools
new bool:g_IsMapCompatible = false, bool:g_CellsOpened = false, bool:g_1stRoundFreeday = false, bool:g_VoidFreekills = false,
bool:g_bIsLRInUse = false, bool:g_bIsWardenLocked = false, bool:g_bOneGuardLeft = false,
bool:g_bActiveRound = false, bool:g_bFreedayTeleportSet = false, bool:g_bLRConfigActive = true, bool:g_bLockWardenLR = false,
bool:g_ScoutsBlockedDoubleJump[MAXPLAYERS+1], bool:g_PyrosDisableAirblast[MAXPLAYERS+1],
bool:g_IsMuted[MAXPLAYERS+1], bool:g_IsRebel[MAXPLAYERS + 1], bool:g_IsFreeday[MAXPLAYERS + 1], bool:g_IsFreedayActive[MAXPLAYERS + 1],
bool:g_IsFreekiller[MAXPLAYERS + 1],bool:g_HasTalked[MAXPLAYERS+1], bool:g_LockedFromWarden[MAXPLAYERS+1], bool:g_bRolePreference[MAXPLAYERS+1],
bool:g_HasModel[MAXPLAYERS+1], bool:g_bLateLoad = false, bool:g_Voted[MAXPLAYERS+1] = {false, ...};

//Plugin Global Integers, Floats, Strings, etc..
new Warden = -1, LR_Number = -1, g_Voters = 0, g_Votes = 0, g_VotesNeeded = 0, g_VotesPassed = 0, WardenLimit = 0, FreedayLimit = 0;
new g_FirstKill[MAXPLAYERS + 1], g_Killcount[MAXPLAYERS + 1], g_HasBeenWarden[MAXPLAYERS + 1];
new Float:free_pos[3];
new String:GCellNames[32], String:GCellOpener[32], String:DoorList[][] = {"func_door", "func_door_rotating", "func_movelinear"}, String:LRConfig_File[PLATFORM_MAX_PATH];

//Handles
new Handle:g_hArray_Pending;
new Handle:Forward_WardenCreated;
new Handle:Forward_WardenRemoved;
new Handle:WardenName;
new Handle:g_hRoleCookie;
new Handle:JB_EngineConVars[3] = {INVALID_HANDLE, ...};

//Timers
new Handle:hTimer_Advertisement;
new Handle:hTimer_FreekillingData;
new Handle:hTimer_OpenCells;
new Handle:hTimer_FriendlyFireEnable;
new Handle:hTimer_WardenLock;
new Handle:hTimer_ParticleTimers[MAXPLAYERS+1];
new Handle:hTimer_RebelTimers[MAXPLAYERS+1];

//Enumerators
enum WardenMenuAccept
{
	Open = 0,
	FriendlyFire,
	Collision
};
new WardenMenuAccept:EnumWardenMenu;

enum CommsList
{
	None = 0,
	Basecomms,
	Sourcecomms
};
new CommsList:EnumCommsList;

enum DoorMode
{
	OPEN = 0,
	CLOSE,
	LOCK,
	UNLOCK
};

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
	Jail_Log("%s Jailbreak is now loading...", TAG);
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
	JB_ConVars[57] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_removeonlr", "1", "Remove Freedays on Last Request: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[58] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_removeonlastguard", "1", "Remove Freedays on Last Guard: (1 = enable, 0 = disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[59] = AutoExecConfig_CreateConVar("sm_tf2jail_pref_type", "0", "Preference Type: (0 = Disabled, 1 = Blue, 2 = Warden Only)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

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
	RegConsoleCmd("sm_currentlr", CurrentLR);
	RegConsoleCmd("sm_currentlastrequests", CurrentLR);
	RegConsoleCmd("sm_lrlist", ListLRs);
	RegConsoleCmd("sm_lastrequestlist", ListLRs);

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
	RegAdminCmd("sm_debugging", AdminDebugging, ADMFLAG_GENERIC);
	
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
	
	g_hRoleCookie = RegClientCookie("TF2Jail_RolePreference", "Sets the preferred role of the client. (Blue, Warden)", CookieAccess_Private);
	SetCookiePrefabMenu(g_hRoleCookie, CookieMenu_YesNo_Int, "Would you like to be Warden/Blue?", RolePrefHandler);
	
	for (new i = MaxClients; i > 0; --i)
	{
		if (!AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	
	BuildPath(Path_SM, LRConfig_File, sizeof(LRConfig_File), "configs/tf2jail/lastrequests.cfg");
	
	g_hArray_Pending = CreateArray();
	
	AutoExecConfig_CleanFile();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
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
	CreateNative("TF2Jail_StripToMelee", Native_StripToMelee);
	CreateNative("TF2Jail_StripAllWeapons", Native_StripAllWeapons);
	RegPluginLibrary("tf2jail");

	g_bLateLoad = late;
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	e_steamtools = LibraryExists("SteamTools");
	e_voiceannounce_ex = LibraryExists("voiceannounce_ex");
	e_sourcebans = LibraryExists("sourcebans");
	
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
	
	#if defined _updater_included
	if (LibraryExists("updater")) Updater_AddPlugin(UPDATE_URL);
	#endif
}

public OnLibraryAdded(const String:name[])
{
	e_steamtools = StrEqual(name, "SteamTools", false);
	e_sourcebans = StrEqual(name, "sourcebans");
	e_voiceannounce_ex = StrEqual(name, "voiceannounce_ex");

	if (StrEqual(name, "sourcecomms"))
	{
		EnumCommsList = Sourcecomms;
	}
	else if (StrEqual(name, "basecomm"))
	{
		EnumCommsList = Basecomms;
	}
}

public OnLibraryRemoved(const String:name[])
{
	e_steamtools = StrEqual(name, "SteamTools", false);
	e_sourcebans = StrEqual(name, "sourcebans");
	e_voiceannounce_ex = StrEqual(name, "voiceannounce_ex");
	
	if (StrEqual(name, "sourcecomms") || StrEqual(name, "basecomm"))
	{
		EnumCommsList = None;
	}
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
	GetConVarString(JB_ConVars[37], BanMsg, sizeof(BanMsg));
	GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
	j_FreekillersBantime = GetConVarInt(JB_ConVars[39]);
	j_FreekillersBantimeDC = GetConVarInt(JB_ConVars[40]);
	j_LRSEnabled = GetConVarBool(JB_ConVars[41]);
	j_LRSAutomatic = GetConVarBool(JB_ConVars[42]);
	j_LRSLockWarden = GetConVarBool(JB_ConVars[43]);
	j_FreedayLimit = GetConVarInt(JB_ConVars[44]);
	j_1stDayFreeday = GetConVarBool(JB_ConVars[45]);
	j_DemoCharge = GetConVarBool(JB_ConVars[46]);
	j_DoubleJump = GetConVarBool(JB_ConVars[47]);
	j_Airblast = GetConVarBool(JB_ConVars[48]);
	GetConVarString(JB_ConVars[49], Particle_Freekiller, sizeof(Particle_Freekiller));
	GetConVarString(JB_ConVars[50], Particle_Rebellion, sizeof(Particle_Rebellion));
	GetConVarString(JB_ConVars[51], Particle_Freeday, sizeof(Particle_Freeday));
	j_WardenVoice = GetConVarInt(JB_ConVars[52]);
	j_WardenWearables = GetConVarBool(JB_ConVars[53]);
	j_FreedayTeleports = GetConVarBool(JB_ConVars[54]);
	j_WardenStabProtection = GetConVarInt(JB_ConVars[55]);
	j_KillPointServerCommand = GetConVarBool(JB_ConVars[56]);
	j_RemoveFreedayOnLR = GetConVarBool(JB_ConVars[57]);
	j_RemoveFreedayOnLastGuard = GetConVarBool(JB_ConVars[58]);
	j_Reftype = GetConVarInt(JB_ConVars[59]);
	
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
		
		ResetVotes();
		ParseConfigs();
		
		Jail_Log("%s Jailbreak has successfully loaded.", TAG);
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
				if (e_steamtools)
				{
					Steam_SetGameDescription("Team Fortress");
				}
				for (new i = 1; i <= MaxClients; i++)
				{
					if (j_WardenModel && IsWarden(i))
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
				if (e_steamtools)
				{
					decl String:gameDesc[64];
					Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
					Steam_SetGameDescription(gameDesc);
				}
				for (new i = 1; i <= MaxClients; i++)
				{
					if (j_WardenModel && IsWarden(i))
					{
						decl String:s[PLATFORM_MAX_PATH];
						Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
						SetModel(i, s);
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
				ClearTimer(hTimer_Advertisement);
			}
		case 1:
			{
				j_Advertise = true;
				ClearTimer(hTimer_Advertisement);
				StartAdvertisement();
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
						CreateTimer(0.1, ManageWeapons, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
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
						decl String:s[PLATFORM_MAX_PATH];
						Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
						SetModel(i, s);
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
					case 1:	if (g_CellsOpened) MutePlayer(i);
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
		case 0: j_DeadMute = false;
		case 1: j_DeadMute = true;
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
	
	else if (cvar == JB_ConVars[57])
	{
		switch (iNewValue)
		{
		case 0:	j_RemoveFreedayOnLR = false;
		case 1:	j_RemoveFreedayOnLR = true;
		}
	}
	
	else if (cvar == JB_ConVars[58])
	{
		switch (iNewValue)
		{
		case 0:	j_RemoveFreedayOnLastGuard = false;
		case 1:	j_RemoveFreedayOnLastGuard = true;
		}
	}
	
	else if (cvar == JB_ConVars[59])
	{
		j_Reftype = iNewValue;
	}
}

#if defined _updater_included
public Action:Updater_OnPluginChecking() Jail_Log("%s Checking if TF2Jail requires an update...", TAG);
public Action:Updater_OnPluginDownloading() Jail_Log("%s New version has been found, downloading new files...", TAG);
public Updater_OnPluginUpdated() Jail_Log("%s Download complete, updating files...", TAG);
public Updater_OnPluginUpdating() Jail_Log("%s Updates complete! You may now reload the plugin or wait for map change/server restart.", TAG);
#endif

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public OnMapStart()
{
	if (j_Enabled)
	{
		if (j_Advertise)
		{
			StartAdvertisement();
		}
		if (g_bLateLoad)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					OnClientConnected(i);
					g_HasBeenWarden[i] = 0;
				}
			}
		}
		
		if (j_WardenModel)
		{
			decl String:s[PLATFORM_MAX_PATH];
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
			if (PrecacheModel(s, true))
			{
				new String:extensions[][] = { ".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy" };
				new String:extensionsb[][] = { ".vtf", ".vmt" };
				decl i;
				for (i = 0; i < sizeof(extensions); i++)
				{
					Format(s, PLATFORM_MAX_PATH, "%s%s", WARDEN_MODEL, extensions[i]);
					if (FileExists(s, true)) AddFileToDownloadsTable(s);
				}
				
				for (i = 0; i < sizeof(extensionsb); i++)
				{
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/NineteenEleven%s", extensionsb[i]);
					AddFileToDownloadsTable(s);
					
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/warden_body%s", extensionsb[i]);
					AddFileToDownloadsTable(s);
					
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/warden_hat%s", extensionsb[i]);
					AddFileToDownloadsTable(s);
					
					Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/warden/warden_head%s", extensionsb[i]);
					AddFileToDownloadsTable(s);
				}
			}
			else
			{
				Jail_Log("Error precaching model, please check configurations and file integrity.");
				j_WardenModel = false;
			}
		}
		
		PrecacheSound("ui/system_message_alert.wav", true);
		
		g_1stRoundFreeday = true;
		g_bActiveRound = false;
		g_Voters = 0;
		g_VotesNeeded = 0;
		WardenLimit = 0;
		g_bLockWardenLR = false;
		
		ResetVotes();
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
				g_HasBeenWarden[i] = 0;
				
				if (IsWarden(i))
				{
					RemoveModel(i);
				}
				
				hTimer_ParticleTimers[i] = INVALID_HANDLE;
				hTimer_RebelTimers[i] = INVALID_HANDLE;
			}
		}

		g_bActiveRound = false;
		g_bLockWardenLR = false;
		WardenLimit = 0;
		ResetVotes();
		
		ConvarsSet(false);
		
		hTimer_Advertisement = INVALID_HANDLE;
		hTimer_FreekillingData = INVALID_HANDLE;
		hTimer_OpenCells = INVALID_HANDLE;
		hTimer_FriendlyFireEnable = INVALID_HANDLE;
		hTimer_WardenLock = INVALID_HANDLE;
		
		Jail_Log("%s Jailbreak has been unloaded successfully.", TAG);
		
	}
}

public OnClientConnected(client)
{
	g_Voted[client] = false;
	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
}

public OnClientCookiesCached(client)
{
	decl String:value[8];
	GetClientCookie(client, g_hRoleCookie, value, sizeof(value));
	
	g_bRolePreference[client] = (value[0] != '\0' && StringToInt(value));
}

public OnClientPutInServer(client)
{
	g_IsMuted[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, PlayerTakeDamage);
}

public Action:PlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!j_Enabled) return Plugin_Continue;
	if (IsValidClient(client) && IsValidClient(attacker))
	{
		if (client != attacker)
		{
			switch (GetClientTeam(attacker))
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
			if (j_WardenStabProtection == 2)
			{
				if (IsWarden(client))
				{
					decl String:szClassName[64];
					GetEntityClassname(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), szClassName, sizeof(szClassName));
					if (StrEqual(szClassName, "tf_weapon_knife") && (damagetype & DMG_CRIT == DMG_CRIT))
					{
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	if (j_Enabled)
	{
		CreateTimer(4.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)
{
	if (!j_Enabled) return;

	if (IsValidClient(client))
	{
		if (g_Voted[client])
		{
			g_Votes--;
		}
		
		g_Voters--;
		g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
		
		if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded)
		{
			if (j_WVotesPostAction == 1)
			{
				return;
			}
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
		
		ClearTimer(hTimer_ParticleTimers[client]);
	}
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return;

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
							while ((ent = FindEntityByClassnameSafe(ent, "tf_wearable_demoshield")) != -1)
							{
								AcceptEntityInput(ent, "kill");
							}
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
}

public PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(client) && IsValidClient(client_attacker))
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
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_IsFreedayActive[client])
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsValidClient(client))
	{
		if (IsValidClient(client_killer))
		{
			if (client_killer != client)
			{
				if (j_Freekillers)
				{
					if (GetClientTeam(client_killer) == _:TFTeam_Blue)
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
			}
		}
		
		new red_count = Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE);
		new blue_count = Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE);
		
		if (j_LRSAutomatic && g_bLRConfigActive)
		{
			if (red_count == 1)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						LastRequestStart(i);
						Jail_Log("%N has received last request for being the last prisoner alive.", i);
					}
				}
			}
		}
		
		if (j_RemoveFreedayOnLastGuard)
		{
			if (blue_count == 1)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (g_IsFreedayActive[i])
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
		
		if (hTimer_ParticleTimers[client])
		{
			ClearTimer(hTimer_ParticleTimers[client]);
		}
		
		if (IsWarden(client))
		{
			WardenUnset(client);
			PrintCenterTextAll("%t", "warden killed", client);
		}
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return;

	if (j_1stDayFreeday && g_1stRoundFreeday)
	{
		DoorHandler(OPEN);
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
	g_bIsWardenLocked = true;
}

public ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return;
	
	if (j_Balance)
	{
		new Float:Ratio;
		for (new i = 1; i <= MaxClients; i++)
		{
			Ratio = Float:GetTeamClientCount(_:TFTeam_Blue)/Float:GetTeamClientCount(_:TFTeam_Red);
			if (Ratio <= j_BalanceRatio || GetTeamClientCount(_:TFTeam_Red) == 2)
			{
				break;
			}
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				if (j_Reftype == 1 && !g_bRolePreference[i])
				{
					CPrintToChat(i, "%s %t", TAG_COLORED, "preference against blue");
					continue;
				}
				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);
				CPrintToChat(i, "%s %t", TAG_COLORED, "moved for balance");
				if (g_HasModel[i])
				{
					RemoveModel(i);
				}
				Jail_Log("%N has been moved to prisoners team for balance.", i);
			}
		}
	}
	
	if (g_IsMapCompatible && j_DoorOpenTimer != 0.0)
	{
		new autoopen = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", TAG_COLORED, "cell doors open start", autoopen);
		hTimer_OpenCells = CreateTimer(j_DoorOpenTimer, Open_Doors, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		g_CellsOpened = true;
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
			CreateTimer(j_RedMuteTime, UnmuteReds, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
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
		
		new String:buffer[255], String:number[255];
		if (KvGotoFirstSubKey(LastRequestConfig))
		{
			do
			{
				IntToString(LR_Number, number, sizeof(number));
				KvGetSectionName(LastRequestConfig, buffer, sizeof(buffer));
				
				if (StrEqual(buffer, number))
				{
					new bool:IsFreedayRound = false, String:ServerCommands[255];
					
					if (KvGetString(LastRequestConfig, "ServerCommand", ServerCommands, sizeof(ServerCommands)))
					{
						if (!StrEqual(ServerCommands, ""))
						{
							ServerCommand("%s", ServerCommands);
						}
					}
					
					if (KvJumpToKey(LastRequestConfig, "Parameters"))
					{
						if (KvGetNum(LastRequestConfig, "IsFreedayType", 0) != 0)
						{
							IsFreedayRound = true;
						}

						if (KvGetNum(LastRequestConfig, "OpenCells", 0) == 1)
						{
							DoorHandler(OPEN);
						}
						
						if (KvGetNum(LastRequestConfig, "VoidFreekills", 0) == 1)
						{
							g_VoidFreekills = true;
						}
						
						if (KvGetNum(LastRequestConfig, "TimerStatus", 1) == 0)
						{
							RoundTimer_Stop();
						}
						
						if (KvGetNum(LastRequestConfig, "LockWarden", 0) == 1)
						{
							g_bLockWardenLR = true;
						}
						
						if (KvJumpToKey(LastRequestConfig, "KillWeapons"))
						{
							for (new i = 1; i < MaxClients; i++)
							{
								if (IsValidClient(i) && IsPlayerAlive(i))
								{
									switch (GetClientTeam(i))
									{
									case TFTeam_Red:
										{
											if (KvGetNum(LastRequestConfig, "Red", 0) == 1)
											{
												StripToMelee(i);
											}
										}
									case TFTeam_Blue:
										{
											if (KvGetNum(LastRequestConfig, "Blue", 0) == 1)
											{
												StripToMelee(i);
											}
										}
									}
									
									if (KvGetNum(LastRequestConfig, "Warden", 0) == 1 && IsWarden(i))
									{
										StripToMelee(i);
									}
								}
							}
							KvGoBack(LastRequestConfig);
						}
						
						if (KvJumpToKey(LastRequestConfig, "FriendlyFire"))
						{
							if (KvGetNum(LastRequestConfig, "Status", 0) == 1)
							{
								new Float:TimeFloat = KvGetFloat(LastRequestConfig, "Timer", 1.0);
								if (TimeFloat >= 0.1)
								{
									hTimer_FriendlyFireEnable = CreateTimer(TimeFloat, EnableFFTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
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
							FreedayForAll();
						}
						else
						{
							Format(ActiveAnnounce, sizeof(ActiveAnnounce), "%s %s", TAG_COLORED, ActiveAnnounce);
							CPrintToChatAll(ActiveAnnounce);
						}
					}
				}
			} while (KvGotoNextKey(LastRequestConfig));
		}
		LR_Number = -1;
		CloseHandle(LastRequestConfig);
	}
	
	FindRandomWarden();
	g_bIsWardenLocked = false;
}

public RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if (!j_Enabled) return;

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
			ClearTimer(hTimer_RebelTimers[i]);
		}
	}
	
	SetConVarBool(JB_EngineConVars[0], false);

	if (GetConVarBool(JB_EngineConVars[1]))
	{
		SetConVarBool(JB_EngineConVars[1], false);
	}
	
	g_bIsWardenLocked = true;
	g_bOneGuardLeft = false;
	g_bActiveRound = false;
	g_VoidFreekills = false;
	FreedayLimit = 0;
	g_bLockWardenLR = false;
	
	ClearTimer(hTimer_OpenCells);
	ClearTimer(hTimer_WardenLock);
	ClearTimer(hTimer_FriendlyFireEnable);
	
	CloseAllMenus();
}

public RegeneratePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (j_Enabled)
	{
		CreateTimer(0.1, ManageWeapons, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
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
		
		if (j_KillPointServerCommand)
		{
			//Crashing on Linux
			/*if (StrContains(classname, "point_servercommand", false) != -1)
			{
				if (j_KillPointServerCommand)
				{
					AcceptEntityInput(entity, "Kill");
				}
			}*/
		}
	}
}

public Action:InterceptBuild(client, const String:command[], args)
{
	if (j_Enabled)
	{
		if (IsValidClient(client) && GetClientTeam(client) == _:TFTeam_Red)
		{
			return Plugin_Handled;
		}
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

	if (IsValidClient(client))
	{
		if (j_WVotesPassedLimit != 0)
		{
			if (WardenLimit < j_WVotesPassedLimit)
			{
				AttemptFireWarden(client);
			}
			else
			{
				PrintToChat(client, "You are not allowed to vote again, the warden fire limit has been reached.");
			}
		}
		else
		{
			AttemptFireWarden(client);
		}
	}
	else
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
	}
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
	if (!j_Enabled) return Plugin_Handled;
	
	if (!StrEqual(GCellNames, ""))
	{
		new cell_door = Entity_FindByName(GCellNames, "func_door");
		switch (Entity_IsValid(cell_door))
		{
		case false: CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Doors Undetected");
		case true: CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Doors Detected");
		}
	}
	
	if (!StrEqual(GCellOpener, ""))
	{
		new open_cells = Entity_FindByName(GCellOpener, "func_button");		
		switch (Entity_IsValid(open_cells))
		{
		case false: CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Opener Undetected");
		case true: CReplyToCommand(client, "%s %t", TAG, "Map Compatibility Cell Opener Detected");
		}
	}

	CShowActivity2(client, TAG, "%t", "Admin Scan Map Compatibility", client);
	Jail_Log("Admin %N has checked the map for compatibility.", client);
	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	g_Voters = 0;
	g_VotesNeeded = 0;
	ResetVotes();
	
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
		g_HasBeenWarden[i] = 0;
		
		if (IsClientConnected(i))
		{
			OnClientConnected(i);
		}
	}

	g_CellsOpened = false;
	g_1stRoundFreeday = false;
	g_VoidFreekills = false;
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	g_bOneGuardLeft = false;
	g_bLateLoad = false;
	g_bLockWardenLR = false;

	Warden = -1;
	WardenLimit = 0;
	FreedayLimit = 0;

	EnumWardenMenu = Open;
	
	ParseConfigs();

	CShowActivity2(client, TAG, "%t", "Admin Reset Plugin", client);
	Jail_Log("Admin %N has reset the plugin of all it's bools, integers and floats.", client);

	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (g_IsMapCompatible)
	{
		DoorHandler(OPEN);
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
		DoorHandler(CLOSE);
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
		DoorHandler(LOCK);
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
		DoorHandler(UNLOCK);
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
		FindWardenRandom(client);
	}
	else
	{
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));

		new target = FindTarget(client, arg1);
		if (target != -1 || target <= 2 || target != client)
		{
			if (j_Reftype == 2)
			{
				if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) != 1)
				{
					if (!g_bRolePreference[target])
					{
						WardenSet(target);
						CShowActivity2(client, TAG, "%t", "Admin Force warden", client, target);
						Jail_Log("Admin %N has forced a %N Warden.", client, target);
					}
					else
					{
						CPrintToChat(client, "%s %t", "Admin Force Warden Not Preferred", TAG_COLORED, target);
						Jail_Log("Client %N has their preference set to prisoner only, finding another client...", target);
					}
				}
				else
				{
					WardenSet(target);
					CShowActivity2(client, TAG, "%t", "Admin Force warden", client, target);
					Jail_Log("Admin %N has forced a %N Warden.", client, target);
				}
			}
			else
			{
				WardenSet(target);
				CShowActivity2(client, TAG, "%t", "Admin Force warden", client, target);
				Jail_Log("Admin %N has forced a %N Warden.", client, target);
			}
		}
	}
	return Plugin_Handled;
}

FindWardenRandom(client)
{
	new Random = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
	if (IsValidClient(Random))
	{
		if (j_Reftype == 2)
		{
			if (Team_GetClientCount(_:TFTeam_Blue, CLIENTFILTER_ALIVE) != 1)
			{
				if (!g_bRolePreference[Random])
				{
					WardenSet(Random);
					CShowActivity2(client, TAG, "%t", "Admin Force warden Random", client, Random);
					Jail_Log("Admin %N has given %N Warden by Force.", client, Random);
				}
				else
				{
					CPrintToChat(client, "%s %t", "Admin Force Random Warden Not Preferred", TAG_COLORED, Random);
					Jail_Log("Client %N has their preference set to prisoner only, finding another client...", Random);
					FindWardenRandom(client);
				}
			}
			else
			{
				WardenSet(Random);
				CShowActivity2(client, TAG, "%t", "Admin Force warden Random", client, Random);
				Jail_Log("Admin %N has given %N Warden by Force.", client, Random);
			}
		}
	}
}

public Action:AdminForceLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	else if (!g_bLRConfigActive)
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
		if (target != -1 || target != client)
		{
			CShowActivity2(client, TAG, "%t", "Admin Force Last Request", client, target);
			LastRequestStart(target, false);
			Jail_Log("Admin %N has gave %N a Last Request by admin.", client, target);
		}
	}
	
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	if (g_bLRConfigActive)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_IsFreeday[i])
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "admin removed freeday");
				g_IsFreeday[i] = false;
			}
			
			if (g_IsFreedayActive[i])
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "admin removed freeday active");
				g_IsFreedayActive[i] = false;
			}
		}
		
		g_bIsLRInUse = false;
		LR_Number = -1;
		
		CShowActivity2(client, TAG, "%t", "Admin Deny Last Request", client);
		Jail_Log("Admin %N has denied all currently queued last requests and reset the last request system.", client);
	}
	else
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
	}
	return Plugin_Handled;
}

public Action:AdminPardonFreekiller(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	if (j_Freekillers)
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
		CShowActivity2(client, TAG, "%t", "Admin Pardon Freekillers", client);
		Jail_Log("Admin %N has pardoned all currently marked Freekillers.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "freekillers system disabled");
	}
	return Plugin_Handled;
}

public Action:AdminGiveFreeday(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	if (g_bLRConfigActive)
	{
		if (IsValidClient(client))
		{
			GiveFreedaysMenu(client);
		}
		else
		{
			CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		}
	}
	else
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
	}
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
			if (IsValidClient(target))
			{
				GiveFreeday(target);
				Jail_Log("%N has given %N a Freeday.", target, client);
			}
			else
			{
				PrintToChat(client, "Client is not valid.");
			}
			GiveFreedaysMenu(client);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:AdminRemoveFreeday(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	if (g_bLRConfigActive)
	{
		if (IsValidClient(client))
		{
			RemoveFreedaysMenu(client);
		}
		else
		{
			CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		}
	}
	else
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
	}
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
			if (IsValidClient(target))
			{
				RemoveFreeday(target);
				Jail_Log("%N has removed %N's Freeday.", target, client);
			}
			else
			{
				PrintToChat(client, "Client is not valid.");
			}
			RemoveFreedaysMenu(client);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:AdminAcceptWardenChange(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	switch (EnumWardenMenu)
	{
	case Open:
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "no current requests");
		}
	case FriendlyFire:
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CShowActivity2(client, TAG, "%t", "Admin Accept Request FF", client, Warden);
			CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire enabled");
			Jail_Log("Admin %N has accepted %N's request to enable Friendly Fire.", client, Warden);
		}
	case Collision:
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CShowActivity2(client, TAG, "%t", "Admin Accept Request CC", client, Warden);
			CPrintToChatAll("%s %t", TAG_COLORED, "collision enabled");
			Jail_Log("Admin %N has accepted %N's request to enable Collision.", client, Warden);
		}
	}
	return Plugin_Handled;
}

public Action:AdminCancelWardenChange(client, args)
{
	if (!j_Enabled) return Plugin_Handled;

	switch (EnumWardenMenu)
	{
	case Open:
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "no active warden commands");
		}
	case FriendlyFire:
		{
			SetConVarBool(JB_EngineConVars[0], false);
			CShowActivity2(client, TAG, "%t", "Admin Cancel Active FF", client);
			CPrintToChatAll("%s %t", TAG_COLORED, "friendlyfire disabled");
			Jail_Log("Admin %N has cancelled %N's request for Friendly Fire.", client, Warden);
		}
	case Collision:
		{
			SetConVarBool(JB_EngineConVars[1], false);
			CShowActivity2(client, TAG, "%t", "Admin Cancel Active CC", client);
			CPrintToChatAll("%s %t", TAG_COLORED, "collision disabled");
			Jail_Log("Admin %N has cancelled %N's request for Collision.", client, Warden);
		}
	}
	EnumWardenMenu = Open;
	return Plugin_Handled;
}

public Action:AdminDebugging(client, args)
{
	return Plugin_Handled;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:BecomeWarden(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!j_Warden)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "warden disabled");
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
	
	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "current warden", Warden);
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
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
		
		if (g_LockedFromWarden[client])
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "voted off of warden");
			return Plugin_Handled;
		}
		
		if (GetClientTeam(client) != _:TFTeam_Blue)
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "guards only");
			return Plugin_Handled;
		}
		
		if (j_Reftype == 2)
		{
			if (!g_bRolePreference[client])
			{
				CPrintToChatAll("%s %t", TAG_COLORED, "new warden", client);
				CPrintToChat(client, "%s %t", TAG_COLORED, "warden message");
				WardenSet(client);
			}
			else
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "preference set against guards or warden");
			}
		}
		else
		{
			CPrintToChatAll("%s %t", TAG_COLORED, "new warden", client);
			CPrintToChat(client, "%s %t", TAG_COLORED, "warden message");
			WardenSet(client);
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "dead warden");
	}
	return Plugin_Handled;
}

public Action:WardenMenuC(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (IsValidClient(client))
	{
		if (IsWarden(client))
		{
			WardenMenu(client);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
		}
	}
	else
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
	}

	return Plugin_Handled;
}

WardenMenu(client)
{
	if (!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(MenuHandle_WardenMenu, MENU_ACTIONS_ALL);
		SetMenuTitle(menu, "Available Warden Commands:");
		AddMenuItem(menu, "1", "Open Cells");
		AddMenuItem(menu, "2", "Close Cells");
		AddMenuItem(menu, "3", "Toggle Friendlyfire");
		AddMenuItem(menu, "4", "Toggle Collision");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
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
		EnumWardenMenu = FriendlyFire;
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
		EnumWardenMenu = Collision;
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
	
	if (IsValidClient(client))
	{
		if (j_DoorControl)
		{
			if (g_IsMapCompatible)
			{
				if (IsWarden(client))
				{
					DoorHandler(OPEN);
					Jail_Log("%N has opened the cell doors using door controls as warden.", client);
				}
				else
				{
					CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
				}
			}
			else
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "door controls disabled");
		}
	}
	else
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
	}
	return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (IsValidClient(client))
	{
		if (j_DoorControl)
		{
			if (g_IsMapCompatible)
			{
				if (IsWarden(client))
				{
					DoorHandler(CLOSE);
					Jail_Log("%N has closed the cell doors using door controls as warden.", client);
				}
				else
				{
					CPrintToChat(client, "%s %t", TAG_COLORED, "not warden");
				}
			}
			else
			{
				CPrintToChat(client, "%s %t", TAG_COLORED, "incompatible map");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG_COLORED, "door controls disabled");
		}
	}
	else
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
	}
	return Plugin_Handled;
}

public Action:GiveLR(client, args)
{
	if (!j_Enabled) return Plugin_Handled;
	
	if (!j_LRSEnabled)
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "lr system disabled");
		return Plugin_Handled;
	}
	else if (!g_bLRConfigActive)
	{
		CReplyToCommand(client, "%s %t", TAG, "last request config invalid");
		return Plugin_Handled;
	}
	
	if (IsValidClient(client))
	{
		if (IsWarden(client))
		{
			if (!g_bIsLRInUse)
			{
				if (!IsVoteInProgress())
				{
					new Handle:menu = CreateMenu(MenuHandle_GiveLR, MENU_ACTIONS_ALL);
					SetMenuTitle(menu,"Choose a Player:");
					AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
					DisplayMenu(menu, client, 20);
					Jail_Log("%N is giving someone a last request...", client);
				}
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
	}
	else
	{
		CReplyToCommand(client, "%s%t", TAG, "Command is in-game only");
		return Plugin_Handled;
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
			GetMenuItem(menu, item, info, sizeof(info));
			new iUserid = GetClientOfUserId(StringToInt(info));
			
			decl String:Name[32];
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

public Action:CurrentLR(client, args)
{
	if (LR_Number != -1)
	{
		new String:number[255];
		new Handle:LastRequestConfig = CreateKeyValues("TF2Jail_LastRequests");
		if (FileToKeyValues(LastRequestConfig, LRConfig_File))
		{
			IntToString(LR_Number, number, sizeof(number));
			if (KvGotoFirstSubKey(LastRequestConfig))
			{
				decl String:ID[64], String:Name[255];
				do
				{
					KvGetSectionName(LastRequestConfig, ID, sizeof(ID));    
					KvGetString(LastRequestConfig, "Name", Name, sizeof(Name));
					if (StrEqual(ID, number))
					{
						CPrintToChat(client, "%s %s is the current last request queued.", TAG_COLORED, Name);
					}
				}
				while (KvGotoNextKey(LastRequestConfig));
			}
		}
		CloseHandle(LastRequestConfig);
	}
	else
	{
		CPrintToChat(client, "%s No current last requests queued.", TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:ListLRs(client, args)
{
	if (IsVoteInProgress()) return Plugin_Handled;

	new Handle:LRMenu_Handle = CreateMenu(MenuHandle_ListLRs);
	SetMenuTitle(LRMenu_Handle, "Last Requests List");

	ParseLastRequests(LRMenu_Handle);

	SetMenuExitButton(LRMenu_Handle, true);
	DisplayMenu(LRMenu_Handle, client, 30 );
	return Plugin_Handled;
}

public MenuHandle_ListLRs(Handle:menu, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			
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
		new Health = GetClientHealth(client);
		TF2_SetPlayerClass(client, TFClass_Soldier);
		TF2_RegeneratePlayer(client);
		new Health2 = GetClientHealth(client);
		if (Health < Health2)
		{
			SetEntityHealth(client, Health);
		}
	}

	if (j_WardenModel)
	{
		decl String:s[PLATFORM_MAX_PATH];
		Format(s, PLATFORM_MAX_PATH, "%s.mdl", WARDEN_MODEL);
		SetModel(client, s);
	}
	
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
	
	ClearTimer(hTimer_WardenLock);
	
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
	
	hTimer_WardenLock = CreateTimer(20.0, DisableWarden, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	
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
		if (j_WardenWearables)
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
LastRequestStart(client, bool:Timer = true)
{
	if (IsVoteInProgress()) return;

	new Handle:LRMenu_Handle = CreateMenu(MenuHandle_LR);
	SetMenuTitle(LRMenu_Handle, "Last Request Menu");

	ParseLastRequests(LRMenu_Handle);

	SetMenuExitButton(LRMenu_Handle, true);
	DisplayMenu(LRMenu_Handle, client, 30 );
	
	CPrintToChat(client, "%s %t", TAG_COLORED, "warden granted lr");
	g_bIsLRInUse = true;
	
	if (!Timer)
	{
		RoundTimer_Stop();
	}
}

public MenuHandle_LR(Handle:menu, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			if (g_bActiveRound)
			{
				new Handle:LastRequestConfig = CreateKeyValues("TF2Jail_LastRequests");
				FileToKeyValues(LastRequestConfig, LRConfig_File);

				if (KvGotoFirstSubKey(LastRequestConfig))
				{
					new String:buffer[255];
					new String:choice[255];
					GetMenuItem(menu, item, choice, sizeof(choice));     

					do
					{
						KvGetSectionName(LastRequestConfig, buffer, sizeof(buffer));
						if (StrEqual(buffer, choice))
						{
							new bool:ActiveRound = false;
							if (KvJumpToKey(LastRequestConfig, "Parameters"))
							{
								if (KvGetNum(LastRequestConfig, "ActiveRound", 0) == 1)
								{
									ActiveRound = true;
								}
							}
							KvGoBack(LastRequestConfig);
							
							if (ActiveRound)
							{
								decl String:Active[255], String:ClientName[32];
								if (KvGetString(LastRequestConfig, "Activated", Active, sizeof(Active)))
								{
									GetClientName(client, ClientName, sizeof(ClientName));
									ReplaceString(Active, sizeof(Active), "%M", ClientName, true);
									Format(Active, sizeof(Active), "%s %s", TAG_COLORED, Active);
									CPrintToChatAll(Active);
								}
								
								if (KvJumpToKey(LastRequestConfig, "Parameters"))
								{
									switch (KvGetNum(LastRequestConfig, "IsFreedayType", 0))
									{
									case 1:
										{
											GiveFreeday(client);
										}
									case 2:
										{
											FreedayforClientsMenu(client, true, true);
										}
									case 3:
										{
											FreedayForAll(false);
										}
									}
									
									if (KvGetNum(LastRequestConfig, "IsSuicide", 0) == 1)
									{
										ForcePlayerSuicide(client);
									}
									
									if (KvJumpToKey(LastRequestConfig, "KillWeapons"))
									{
										for (new i = 1; i < MaxClients; i++)
										{
											if (IsValidClient(i) && IsPlayerAlive(i))
											{
												switch (GetClientTeam(i))
												{
												case TFTeam_Red:
													{
														if (KvGetNum(LastRequestConfig, "Red", 0) == 1)
														{
															StripToMelee(i);
														}
													}
												case TFTeam_Blue:
													{
														if (KvGetNum(LastRequestConfig, "Blue", 0) == 1)
														{
															StripToMelee(i);
														}
													}
												}
												
												if (KvGetNum(LastRequestConfig, "Warden", 0) == 1 && IsWarden(i))
												{
													StripToMelee(i);
												}
											}
										}
										KvGoBack(LastRequestConfig);
									}
									
									if (KvJumpToKey(LastRequestConfig, "FriendlyFire"))
									{
										if (KvGetNum(LastRequestConfig, "Status", 0) == 1)
										{
											new Float:TimeFloat = KvGetFloat(LastRequestConfig, "Timer", 1.0);
											if (TimeFloat >= 0.1)
											{
												hTimer_FriendlyFireEnable = CreateTimer(TimeFloat, EnableFFTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
											}
											else
											{
												Jail_Log("[ERROR] Timer is set to a value below 0.1! Timer could not be created.");
											}
										}
									}
									KvGoBack(LastRequestConfig);
								}
								KvGoBack(LastRequestConfig);
							}
							else
							{
								if (KvJumpToKey(LastRequestConfig, "Parameters"))
								{
									switch (KvGetNum(LastRequestConfig, "IsFreedayType", 0))
									{
									case 1:
										{
											g_IsFreeday[client] = true;
										}
									case 2:
										{
											FreedayforClientsMenu(client, false, true);
										}
									case 3:
										{
											FreedayForAll(true);
										}
									}
									KvGoBack(LastRequestConfig);
								}
								
								decl String:QueueAnnounce[255], String:ClientName[32];
								if (KvGetString(LastRequestConfig, "Queue_Announce", QueueAnnounce, sizeof(QueueAnnounce)))
								{
									GetClientName(client, ClientName, sizeof(ClientName));
									ReplaceString(QueueAnnounce, sizeof(QueueAnnounce), "%M", ClientName, true);
									Format(QueueAnnounce, sizeof(QueueAnnounce), "%s %s", TAG_COLORED, QueueAnnounce);
									CPrintToChatAll(QueueAnnounce);
								}
								
								LR_Number = StringToInt(choice);
							}
						}
					}while (KvGotoNextKey(LastRequestConfig));
					
					CloseHandle(LastRequestConfig);
				}
				else
				{
					CloseHandle(LastRequestConfig);
					CloseHandle(menu);
				}
			}
			else
			{
				CloseHandle(menu);
			}
			
			if (j_RemoveFreedayOnLR)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (g_IsFreedayActive[i])
					{
						RemoveFreeday(i);
					}
				}
				CPrintToChatAll("%s %t", TAG_COLORED, "last request freedays removed");
			}
			
			g_bIsWardenLocked = true;
		}
	case MenuAction_Cancel:
		{
			if (g_bActiveRound)
			{
				g_bIsLRInUse = false;
				CPrintToChatAll("%s %t", TAG_COLORED, "last request closed");
			}
			else
			{
				g_bIsLRInUse = false;
			}
		}
	case MenuAction_End: CloseHandle(menu), g_bIsLRInUse = false;
	}
}

FreedayforClientsMenu(client, bool:active = false, bool:rep = false)
{
	if (IsVoteInProgress()) return;

	if (rep) CPrintToChatAll("%s %t", TAG_COLORED, "lr freeday picking clients", client);
	
	if (active)
	{
		new Handle:menu1 = CreateMenu(MenuHandle_FreedayForClientsActive, MENU_ACTIONS_ALL);
		SetMenuTitle(menu1, "Choose a Player");
		SetMenuExitBackButton(menu1, false);
		AddTargetsToMenu2(menu1, 0, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
		DisplayMenu(menu1, client, MENU_TIME_FOREVER);
	}
	else
	{
		new Handle:menu2 = CreateMenu(MenuHandle_FreedayForClients, MENU_ACTIONS_ALL);
		SetMenuTitle(menu2, "Choose a Player");
		SetMenuExitBackButton(menu2, false);
		AddTargetsToMenu2(menu2, 0, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
		DisplayMenu(menu2, client, MENU_TIME_FOREVER);
	}
}

public MenuHandle_FreedayForClientsActive(Handle:menu2, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu2, item, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));
			
			if (IsValidClient(client))
			{
				if (!IsValidClient(target))
				{
					CPrintToChat(client, "%s %t", TAG_COLORED, "Player no longer available");
					FreedayforClientsMenu(client, true);
				}
				else if (g_IsFreedayActive[target])
				{
					CPrintToChat(client, "%s %t", TAG_COLORED, "freeday currently queued", target);
					FreedayforClientsMenu(client, true);
				}
				else
				{
					if (FreedayLimit < j_FreedayLimit)
					{
						GiveFreeday(client);
						FreedayLimit++;
						CPrintToChatAll("%s %t", TAG_COLORED, "lr freeday picked clients", client, target);
						FreedayforClientsMenu(client, true);
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
GiveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CPrintToChat(client, "%s %t", TAG_COLORED, "lr freeday message");
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	if (j_FreedayTeleports && g_bFreedayTeleportSet) TeleportEntity(client, free_pos, NULL_VECTOR, NULL_VECTOR);
	
	ClearTimer(hTimer_ParticleTimers[client]);
	hTimer_ParticleTimers[client] = CreateTimer(2.0, Timer_FreedayParticle, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = true;
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
		DoorHandler(OPEN);
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
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	CPrintToChatAll("%s %t", TAG_COLORED, "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	g_IsFreedayActive[client] = false;
	ClearTimer(hTimer_ParticleTimers[client]);
	Jail_Log("%N is no longer a Freeday.", client);
}

MarkRebel(client)
{
	g_IsRebel[client] = true;
	
	ClearTimer(hTimer_ParticleTimers[client]);
	hTimer_ParticleTimers[client] = CreateTimer(2.0, Timer_RebelParticle, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CPrintToChatAll("%s %t", TAG_COLORED, "prisoner has rebelled", client);
	if (j_RebelsTime >= 1.0)
	{
		new time = RoundFloat(j_RebelsTime);
		CPrintToChat(client, "%s %t", TAG_COLORED, "rebel timer start", time);
		hTimer_RebelTimers[client] = CreateTimer(j_RebelsTime, RemoveRebel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
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
			hTimer_FreekillingData = CreateDataTimer(j_FreekillersWave, BanClientTimerFreekiller, hPack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hPack, client);
			WritePackCell(hPack, GetClientUserId(client));
			WritePackString(hPack, sAuth);
			if (hTimer_FreekillingData != INVALID_HANDLE)
			{
				PushArrayCell(hPack, hTimer_FreekillingData);
			}
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
	switch (EnumCommsList)
	{
	case Basecomms:
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
	case Sourcecomms:
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
	if (client == Warden)
	{
		return true;
	}
	else
	{
		return false;
	}
}

MutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && !g_IsMuted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		g_IsMuted[client] = true;
		CPrintToChat(client, "%s %t", TAG_COLORED, "muted player");
	}
}

UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && g_IsMuted[client])
	{
		Client_Unmuted(client);
		g_IsMuted[client] = false;
		CPrintToChat(client, "%s %t", TAG_COLORED, "unmuted player");
	}
}

ParseLastRequests(Handle:menu)
{
	new Handle:LastRequestConfig = CreateKeyValues("TF2Jail_LastRequests");
	
	if (FileToKeyValues(LastRequestConfig, LRConfig_File))
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
					switch (KvGetNum(LastRequestConfig, "Disabled", 0))
					{
					case 0:	AddMenuItem(menu, LR_ID, LR_NAME);
					case 1:	AddMenuItem(menu, LR_ID, LR_NAME, ITEMDRAW_DISABLED);
					}
					KvGoBack(LastRequestConfig);
				}
			}
			while (KvGotoNextKey(LastRequestConfig));
			g_bLRConfigActive = true;
		}
	}
	else
	{
		g_bLRConfigActive = false;
	}
	CloseHandle(LastRequestConfig);
}

ParseConfigs()
{
	new Handle:MapConfig = CreateKeyValues("TF2Jail_MapConfig");
	
	decl String:MapConfig_File[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, MapConfig_File, sizeof(MapConfig_File), "configs/tf2jail/mapconfig.cfg");
	
	decl String:g_Mapname[128];
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));

	Jail_Log("Loading last request configuration entry - %s...", g_Mapname);

	if (FileToKeyValues(MapConfig, MapConfig_File))
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
					g_IsMapCompatible = false;
				}
			}
			else
			{
				g_IsMapCompatible = false;
			}
			
			KvGetString(MapConfig, "CellsButton", CellsButton, sizeof(CellsButton), "");
			if (!StrEqual(CellsButton, ""))
			{
				new CellsButton_H = Entity_FindByName(CellsButton, "func_button");
				if (Entity_IsValid(CellsButton_H))
				{
					GCellOpener = CellsButton;
				}
			}
			
			if (KvJumpToKey(MapConfig, "Freeday"))
			{
				if (KvJumpToKey(MapConfig, "Teleport"))
				{
					g_bFreedayTeleportSet = (KvGetNum(MapConfig, "Status", 1) == 1);
					
					free_pos[0] = KvGetFloat(MapConfig, "Coordinate_X", 0.0);
					free_pos[1] = KvGetFloat(MapConfig, "Coordinate_Y", 0.0);
					free_pos[2] = KvGetFloat(MapConfig, "Coordinate_Z", 0.0);
				}
				else
				{
					g_bFreedayTeleportSet = false;
				}
			}
			else
			{
				g_bFreedayTeleportSet = false;
			}
		}
		else
		{
			g_IsMapCompatible = false;
			g_bFreedayTeleportSet = false;
		}
	}
	else
	{
		g_IsMapCompatible = false;
		g_bFreedayTeleportSet = false;
	}
	CloseHandle(MapConfig);
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
	CPrintToChat(client, "%s %t", TAG_COLORED, "stripped weapons and ammo");
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

Jail_Log(const String:format[], any:...)
{
	switch (j_Logging)
	{
	case 1:
		{
			decl String:buffer[256];
			VFormat(buffer, sizeof(buffer), format, 2);
			LogMessage("%s", buffer);
		}
	case 2:
		{
			decl String:buffer[256], String:path[PLATFORM_MAX_PATH];
			VFormat(buffer, sizeof(buffer), format, 2);
			BuildPath(Path_SM, path, sizeof(path), "logs/TF2Jail.log");
			LogToFileEx(path, "%s", buffer);
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
					CPrintToChatAll("%s %t", TAG_COLORED, "doors manual open");
					g_CellsOpened = false;
				}
				else
				{
					CPrintToChatAll("%s %t", TAG_COLORED, "doors opened");
				}
			}
		case CLOSE: CPrintToChatAll("%s %t", TAG_COLORED, "doors closed");
		case LOCK: CPrintToChatAll("%s %t", TAG_COLORED, "doors locked");
		case UNLOCK: CPrintToChatAll("%s %t", TAG_COLORED, "doors unlocked");
		}
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
			CreateTimer(time, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
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

stock RemoveValveHat(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
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
	while((edict = FindEntityByClassnameSafe(edict, "tf_powerup_bottle")) != -1)
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

stock Client_Unmuted(client)
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
	if (j_WardenAuto)
	{
		new client = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE|CLIENTFILTER_NOBOTS);
		if (IsValidClient(client))
		{
			if (j_Reftype == 2)
			{
				if (!g_bRolePreference[client])
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

public RolePrefHandler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
	case CookieMenuAction_DisplayOption:
		{
		}
		
	case CookieMenuAction_SelectOption:
		{
			OnClientCookiesCached(client);
		}
	}
}

StartAdvertisement()
{
	hTimer_Advertisement = CreateTimer(120.0, TimerAdvertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
	CPrintToChatAll("%s %t", TAG_COLORED, "red team unmuted");
	Jail_Log("All players have been unmuted.");
}

public Action:Open_Doors(Handle:hTimer)
{
	hTimer_OpenCells = INVALID_HANDLE;
	if (g_CellsOpened)
	{
		DoorHandler(OPEN);
		new time = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", TAG_COLORED, "cell doors open end", time);
		g_CellsOpened = false;
		Jail_Log("Doors have been automatically opened by a timer.");
	}
}

public Action:TimerAdvertisement (Handle:hTimer)
{
	CPrintToChatAll("%s %t", TAG_COLORED, "plugin advertisement");
	return Plugin_Continue;
}

public Action:Timer_Welcome(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (j_Enabled && IsValidClient(client))
	{
		CPrintToChat(client, "%s %t", TAG_COLORED, "welcome message");
	}
}

public Action:ManageWeapons(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	switch (GetClientTeam(client))
	{
	case TFTeam_Red:
		{
			if (j_RedMelee)
			{
				EmptyWeaponSlots(client);
			}
		}
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
		switch (j_FreekillersAction)
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
		}
	}
	else
	{
		if (j_FreekillersAction == 2)
		{
			GetConVarString(JB_ConVars[38], BanMsgDC, sizeof(BanMsgDC));
			BanIdentity(sAuth, j_FreekillersBantimeDC, BANFLAG_AUTHID, BanMsgDC);
			Jail_Log("%N has been banned via identity.", BANFLAG_AUTHID);
		}
	}
	CloseHandle(hPack);
}

public Action:EnableFFTimer(Handle:hTimer)
{
	hTimer_FriendlyFireEnable = INVALID_HANDLE;
	SetConVarBool(JB_EngineConVars[0], true);
}

public Action:DeleteParticle(Handle:timer, any:Edict)
{	
	if (IsValidEdict(Edict))
	{
		RemoveEdict(Edict);
	}
}

public Action:RemoveRebel(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	hTimer_RebelTimers[client] = INVALID_HANDLE;
	
	if (IsValidClient(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		CPrintToChat(client, "%s %t", TAG_COLORED, "rebel timer end");
		ClearTimer(hTimer_ParticleTimers[client]);
		Jail_Log("%N is no longer a Rebeller.", client);
	}
}

public Action:DisableWarden(Handle:hTimer)
{
	hTimer_WardenLock = INVALID_HANDLE;
	CPrintToChatAll("%s %t", TAG_COLORED, "warden locked timer");
	g_bIsWardenLocked = true;
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

/* Native Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Native_ExistWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden)
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
	if (!j_Enabled || !j_Warden)
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
	if (!j_Enabled || !j_Warden)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Warden System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (Warden == -1)
	{
		if (j_Reftype == 2)
		{
			if (!g_bRolePreference[client])
			{
				WardenSet(client);
			}
			else
			{
				ThrowNativeError(SP_ERROR_INDEX, "Client index %i has their preference set to prisoner only.", client);
			}
		}
		else
		{
			WardenSet(client);
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Warden is currently in use, cannot execute native function.");
	}
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden)
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
	if (!j_Enabled || !j_LRSEnabled) ThrowNativeError(SP_ERROR_INDEX, "Plugin or Last Request System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (g_IsFreeday[client] || g_IsFreedayActive[client])
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
	if (!j_Enabled || !j_LRSEnabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin or Last Request System is disabled");
	}

	new client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	if (!g_IsFreedayActive[client])
	{
		if (g_IsFreeday[client])
		{
			g_IsFreeday[client] = false;
		}
		GiveFreeday(client);
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is already a Freeday.", client);
	}
}

public Native_IsRebel(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Rebels)
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
	if (!j_Enabled || !j_Rebels)
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
	if (!j_Enabled || !j_Freekillers)
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
	if (!j_Enabled || !j_Freekillers)
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
	if (!j_Enabled)
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
		CreateTimer(0.1, ManageWeapons, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is currently not alive to strip ammo.", client);
	}
}

public Native_StripAllWeapons(Handle:plugin, numParams)
{
	if (!j_Enabled)
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