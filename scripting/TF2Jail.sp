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
#include <morecolors>
#include <smlib>
#include <autoexecconfig>
#include <tf2jail>
#include <banning>

#undef REQUIRE_EXTENSIONS
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#include <steamtools>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <sourcebans>
#include <adminmenu>
#include <tf2attributes>
#include <sourcecomms>
#include <basecomm>
#include <betherobot>
#include <betheskeleton>
#include <voiceannounce_ex>
#include <tf2items>
#include <tf2items_giveweapon>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME     "[TF2] Jailbreak"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "5.0.4"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

#define CLAN_TAG_COLOR	"{community}[TF2Jail]"
#define CLAN_TAG		"[TF2Jail]"
#define CONVARS			53

#define WARDEN_MODEL			"models/jailbreak/warden/warden_v2.mdl"

//ConVar Handles, Globals, etc..
new Handle:JB_ConVars[CONVARS] = {INVALID_HANDLE, ...};

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
new gwardenColor[3];
new gRebelColor[3];
new gFreedayColor[3];
new j_WardenVoice = 1;

//Plugins/Extension bools
new bool:e_tf2items = false;
new bool:e_tf2attributes = false;
new bool:e_betherobot = false;
new bool:e_betheskeleton = false;
new bool:e_voiceannounce_ex = false;
new bool:e_sourcebans = false;
new bool:e_steamtools = false;

//Plugin Global Bools
new bool:g_IsMapCompatible = false;
new bool:g_CellDoorTimerActive = false;
new bool:g_1stRoundFreeday = false;
new bool:g_VoidFreekills = false;
new bool:g_bIsLRInUse = false;
new bool:g_bIswardenLocked = false;
new bool:g_bIsLowGravRound = false;
new bool:g_bIsDiscoRound = false;
new bool:g_bOneGuardLeft = false;
new bool:g_bTimerStatus = true;
new bool:g_bActiveRound = false;
new bool:g_bFreedayTeleportSet = false;
new bool:g_ScoutsBlockedDoubleJump[MAXPLAYERS+1];
new bool:g_MovementSpeedFTW[MAXPLAYERS+1];
new bool:g_PyrosDisableAirblast[MAXPLAYERS+1];
new bool:g_RobotRoundClients[MAXPLAYERS+1];
new bool:g_SkeletonRoundClients[MAXPLAYERS+1];
new bool:g_IsMuted[MAXPLAYERS+1];
new bool:g_IsRebel[MAXPLAYERS + 1];
new bool:g_IsFreeday[MAXPLAYERS + 1];
new bool:g_IsFreedayActive[MAXPLAYERS + 1];
new bool:g_IsFreekiller[MAXPLAYERS + 1];
new bool:g_HasTalked[MAXPLAYERS+1];
new bool:g_LockedFromwarden[MAXPLAYERS+1];
new bool:g_HasModel[MAXPLAYERS+1];
new bool:g_bLateLoad = false;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

//Plugin Global Integers, Floats, Strings, etc..
new Warden = -1;
new g_Voters = 0;
new g_Votes = 0;
new g_VotesNeeded = 0;
new g_VotesPassed = 0;
new g_FirstKill[MAXPLAYERS + 1];
new g_Killcount[MAXPLAYERS + 1];
new g_AmmoCount[MAXPLAYERS + 1];
new wardenLimit = 0;
new FreedayLimit = 0;
new g_HasBeenwarden[MAXPLAYERS + 1] = 0;
new Float:free_pos[3];
new String:DoorList[][] = {"func_door", "func_door_rotating", "func_movelinear"};
new String:g_Mapname[128];

//Handles
new Handle:g_hArray_Pending = INVALID_HANDLE;
new Handle:g_fward_onBecome = INVALID_HANDLE;
new Handle:g_fward_onRemove = INVALID_HANDLE;
new Handle:g_adverttimer = INVALID_HANDLE;
new Handle:g_checkweapontimer = INVALID_HANDLE;
new Handle:g_refreshspellstimer = INVALID_HANDLE;
new Handle:DataTimerF = INVALID_HANDLE;
new Handle:WardenName;
new Handle:JB_EngineConVars[3] = {INVALID_HANDLE, ...};

//Enumerators
enum LastRequests
{
	LR_Disabled = 0,
	LR_FreedayForAll,
	LR_FreedayForClients,
	LR_PersonalFreeday,
	LR_GuardsMeleeOnly,
	LR_HHHKillRound,
	LR_LowGravity,
	LR_SpeedDemon,
	LR_HungerGames,
	LR_RoboticTakeOver,
	LR_SkeletonsAttack,
	LR_HideAndSeek,
	LR_DiscoDay,
	LR_MagicianWars
};
new LastRequests:enumLastRequests;

enum wardenMenuAccept
{
	WM_Disabled = 0,
	WM_FFChange,
	WM_CCChange
};
new wardenMenuAccept:enumwardenMenuAccept;

enum CommsList
{
	None = 0,
	Basecomms,
	Sourcecomms
};
new CommsList:enumCommsList;

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
	PrintToServer("%s Jailbreak is now loading...", CLAN_TAG);
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
	JB_ConVars[8] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_enable", "1", "Allow wardens: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[9] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_auto", "1", "Automatically assign a random warden on round start: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[10] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_model", "1", "Does warden have a model: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[11] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_forcesoldier", "1", "Force warden to be Soldier class: (1 = yes, 0 = no)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[12] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_friendlyfire", "1", "Allow warden to manage friendly fire: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[13] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_collision", "1", "Allow warden to manage collision: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[14] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_request", "0", "Require admin acceptance for cvar changes: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[15] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_limit", "3", "Number of allowed wardens per user per map: (1.0 - 12.0) (0.0 = unlimited)", FCVAR_PLUGIN, true, 0.0, true, 12.0);
	JB_ConVars[16] = AutoExecConfig_CreateConVar("sm_tf2jail_door_controls", "1", "Allow wardens and Admins door control: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[17] = AutoExecConfig_CreateConVar("sm_tf2jail_cell_timer", "60", "Time after Arena round start to open doors: (1.0 - 60.0) (0.0 = off)", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	JB_ConVars[18] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_red", "2", "Mute Red team: (2 = mute prisoners alive and all dead, 1 = mute prisoners on round start based on redmute_time, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[19] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_red_time", "15", "Mute time for redmute: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_ConVars[20] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_blue", "2", "Mute Blue players: (2 = always except warden, 1 = while warden is active, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_ConVars[21] = AutoExecConfig_CreateConVar("sm_tf2jail_mute_dead", "1", "Mute Dead players: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[22] = AutoExecConfig_CreateConVar("sm_tf2jail_microphonecheck_enable", "1", "Check blue clients for microphone: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[23] = AutoExecConfig_CreateConVar("sm_tf2jail_microphonecheck_type", "1", "Block blue team or warden if no microphone: (1 = Blue, 0 = warden only)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[24] = AutoExecConfig_CreateConVar("sm_tf2jail_rebelling_enable", "1", "Enable the Rebel system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[25] = AutoExecConfig_CreateConVar("sm_tf2jail_rebelling_time", "30.0", "Rebel timer: (1.0 - 60.0, 0 = always)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_ConVars[26] = AutoExecConfig_CreateConVar("sm_tf2jail_criticals", "1", "Which team gets crits: (0 = off, 1 = blue, 2 = red, 3 = both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	JB_ConVars[27] = AutoExecConfig_CreateConVar("sm_tf2jail_criticals_type", "2", "Type of crits given: (1 = mini, 2 = full)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
	JB_ConVars[28] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_votesneeded", "0.60", "Percentage of players required for fire warden vote: (default 0.60 - 60%) (0.05 - 1.0)", 0, true, 0.05, true, 1.00);
	JB_ConVars[29] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_minplayers", "0", "Minimum amount of players required for fire warden vote: (0 - MaxPlayers)", 0, true, 0.0, true, float(MAXPLAYERS));
	JB_ConVars[30] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_postaction", "0", "Fire warden instantly on vote success or next round: (0 = instant, 1 = Next round)", _, true, 0.0, true, 1.0);
	JB_ConVars[31] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_veto_passlimit", "3", "Limit to wardens fired by players via votes: (1 - 10, 0 = unlimited)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
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
	JB_ConVars[43] = AutoExecConfig_CreateConVar("sm_tf2jail_lastrequest_lock_warden", "1", "Lock warden during last request rounds: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[44] = AutoExecConfig_CreateConVar("sm_tf2jail_freeday_limit", "3", "Max number of freedays for the lr: (1.0 - 16.0)", FCVAR_PLUGIN, true, 1.0, true, 16.0);
	JB_ConVars[45] = AutoExecConfig_CreateConVar("sm_tf2jail_1stdayfreeday", "1", "Status of the 1st day freeday: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[46] = AutoExecConfig_CreateConVar("sm_tf2jail_democharge", "1", "Allow demomen to charge: (1 = disable, 0 = enable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[47] = AutoExecConfig_CreateConVar("sm_tf2jail_doublejump", "1", "Deny scouts to double jump: (1 = disable, 0 = enable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[48] = AutoExecConfig_CreateConVar("sm_tf2jail_airblast", "1", "Deny pyros to airblast: (1 = disable, 0 = enable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_ConVars[49] = AutoExecConfig_CreateConVar("sm_tf2jail_color_warden", "125 150 250", "warden color flags: (0 = off) (Disabled if warden model enabled)", FCVAR_PLUGIN);
	JB_ConVars[50] = AutoExecConfig_CreateConVar("sm_tf2jail_color_rebel", "0 255 0", "Rebel color flags: (0 = off)", FCVAR_PLUGIN);
	JB_ConVars[51] = AutoExecConfig_CreateConVar("sm_tf2jail_color_freeday", "125 0 0", "Freeday color flags: (0 = off)", FCVAR_PLUGIN);
	JB_ConVars[52] = AutoExecConfig_CreateConVar("sm_tf2jail_warden_voice", "1", "Voice management for warden: (0 = disabled, 1 = unmuted, 2 = warning, no unmute)", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	AutoExecConfig_ExecuteFile();

	gwardenColor[0] = 125;
	gwardenColor[1] = 150;
	gwardenColor[2] = 250;
	gRebelColor[0] = 0;
	gRebelColor[1] = 255;
	gRebelColor[2] = 0;
	gFreedayColor[0] = 125;
	gFreedayColor[1] = 0;
	gFreedayColor[2] = 0;

	for (new i = 0; i < sizeof(JB_ConVars); i++)
	{
		HookConVarChange(JB_ConVars[i], HandleCvars);
	}

	PluginEvents(true);

	RegConsoleCmd("sm_fire", Command_Firewarden);
	RegConsoleCmd("sm_firewarden", Command_Firewarden);
	RegConsoleCmd("sm_w", BecomeWarden);
	RegConsoleCmd("sm_warden", BecomeWarden);
	RegConsoleCmd("sm_uw", Exitwarden);
	RegConsoleCmd("sm_unwarden", Exitwarden);
	RegConsoleCmd("sm_wmenu", wardenMenuC);
	RegConsoleCmd("sm_wardenmenu", wardenMenuC);
	RegConsoleCmd("sm_open", OnOpenCommand);
	RegConsoleCmd("sm_close", OnCloseCommand);
	RegConsoleCmd("sm_wff", wardenFriendlyFire);
	RegConsoleCmd("sm_wcc", wardenCollision);
	RegConsoleCmd("sm_givelr", GiveLR);
	RegConsoleCmd("sm_givelastrequest", GiveLR);
	RegConsoleCmd("sm_removelr", RemoveLR);
	RegConsoleCmd("sm_removelastrequest", RemoveLR);

	RegAdminCmd("sm_rw", AdminRemovewarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", AdminRemovewarden, ADMFLAG_GENERIC);
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
	RegAdminCmd("sm_accept", AdminAcceptwardenChange, ADMFLAG_GENERIC);
	RegAdminCmd("sm_cancel", AdminCancelwardenChange, ADMFLAG_GENERIC);

	JB_EngineConVars[0] = FindConVar("mp_friendlyfire");
	JB_EngineConVars[1] = FindConVar("tf_avoidteammates_pushaway");
	JB_EngineConVars[2] = FindConVar("sv_gravity");

	WardenName = CreateHudSynchronizer();

	AddMultiTargetFilter("@warden", WardenGroup, "the warden", false);
	AddMultiTargetFilter("@rebels", RebelsGroup, "all rebellers", false);
	AddMultiTargetFilter("@freedays", FreedaysGroup, "all freedays", false);
	AddMultiTargetFilter("@!warden", NotWardenGroup, "all but the warden", false);
	AddMultiTargetFilter("@!rebels", NotRebelsGroup, "all but rebellers", false);
	AddMultiTargetFilter("@!freedays", NotFreedaysGroup, "all but freedays", false);

	g_fward_onBecome = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	g_fward_onRemove = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);

	AddServerTag("Jailbreak");

	MapCheck();

	g_hArray_Pending = CreateArray();

	AutoExecConfig_CleanFile();
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
	CreateNative("TF2Jail_GiveFreeday", Native_GiveFreeday);
	CreateNative("TF2Jail_IsRebel", Native_IsRebel);
	CreateNative("TF2Jail_MarkRebel", Native_MarkRebel);
	CreateNative("TF2Jail_IsFreekiller", Native_IsFreekiller);
	CreateNative("TF2Jail_MarkFreekiller", Native_MarkFreekill);
	RegPluginLibrary("TF2Jail");

	g_bLateLoad = late;

	return APLRes_Success;
}

public OnAllPluginsLoaded()
{	
	e_steamtools = LibraryExists("SteamTools");
	e_betherobot = LibraryExists("betherobot");
	e_betheskeleton = LibraryExists("betheskeleton");
	e_tf2items = LibraryExists("tf2items");
	e_voiceannounce_ex = LibraryExists("voiceannounce_ex");
	e_tf2attributes = LibraryExists("tf2attributes");
	e_sourcebans = LibraryExists("sourcebans");
	if (LibraryExists("sourcecomms")) enumCommsList = Sourcecomms;
	if (LibraryExists("basecomm")) enumCommsList = Basecomms;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false)) e_steamtools = true;
	if (StrEqual(name, "sourcebans")) e_sourcebans = true;
	if (StrEqual(name, "sourcecomms")) enumCommsList = Sourcecomms;
	if (StrEqual(name, "basecomm")) enumCommsList = Basecomms;
	if (StrEqual(name, "voiceannounce_ex")) e_voiceannounce_ex = true;
	if (StrEqual(name, "betherobot")) e_betherobot = true;
	if (StrEqual(name, "betheskeleton")) e_betheskeleton = true;
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
	if (StrEqual(name, "betherobot")) e_betherobot = false;
	if (StrEqual(name, "betheskeleton")) e_betheskeleton = false;
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

		PrintToServer("%s Jailbreak has successfully loaded.", CLAN_TAG);
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
	if (cvar == JB_ConVars[1])
	{
		if (iNewValue == 1)
		{
			j_Enabled = true;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin enabled");
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
		else if (iNewValue == 0)
		{
			j_Enabled = false;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin disabled");
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
				if (g_IsRebel[i] && j_Rebels)
				{
					SetEntityRenderColor(i, 255, 255, 255, 255);
					g_IsRebel[i] = false;
				}
			}
		}
	}

	if (cvar == JB_ConVars[2])
	{
		if (iNewValue == 1)
		{
			j_Advertise = true;
			if (g_adverttimer == INVALID_HANDLE)
			{
				g_adverttimer = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT);
			}
		}
		else if (iNewValue == 0)
		{
			j_Advertise = false;
			if (g_adverttimer != INVALID_HANDLE)
			{
				ClearTimer(g_adverttimer);
			}
		}
	}

	if (cvar == JB_ConVars[3])
	{
		if (iNewValue == 1)
		{
			j_Cvars = true;
			ConvarsSet(true);
		}
		else if (iNewValue == 0)
		{
			j_Cvars = false;
			ConvarsSet(false);
		}
	}

	if (cvar == JB_ConVars[4])
	{
		j_Logging = iNewValue;
	}

	if (cvar == JB_ConVars[5])
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

	if (cvar == JB_ConVars[6])
	{
		j_BalanceRatio = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[7])
	{
		if (iNewValue == 1)
		{
			j_RedMelee = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && IsPlayerAlive(i))
				{
					CreateTimer(0.1, ManageWeapons, i);
				}
			}
		}
		else if (iNewValue == 0)
		{
			j_RedMelee = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && GetClientTeam(i) == _:TFTeam_Red && IsPlayerAlive(i))
				{
					TF2_RegeneratePlayer(i);
				}
			}
		}
	}

	if (cvar == JB_ConVars[8])
	{
		if (iNewValue == 1)
		{
			j_Warden = true;
		}
		else if (iNewValue == 0)
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
	}

	if (cvar == JB_ConVars[9])
	{
		if (iNewValue == 1)
		{
			j_WardenAuto = true;
		}
		else if (iNewValue == 0)
		{
			j_WardenAuto = false;
		}
	}

	if (cvar == JB_ConVars[10])
	{
		if (iNewValue == 1)
		{
			j_WardenModel = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsWarden(i))
				{
					SetEntityRenderColor(i, 255, 255, 255, 255);
					SetModel(i, WARDEN_MODEL);
				}
			}
		}
		else if (iNewValue == 0)
		{
			j_WardenModel = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsWarden(i))
				{
					SetEntityRenderColor(i, gwardenColor[0], gwardenColor[1], gwardenColor[2], 255);
					RemoveModel(i);
				}
			}
		}
	}

	if (cvar == JB_ConVars[11])
	{
		if (iNewValue == 1)
		{
			j_WardenForceSoldier = true;
		}
		else if (iNewValue == 0)
		{
			j_WardenForceSoldier = false;
		}
	}

	if (cvar == JB_ConVars[12])
	{
		if (iNewValue == 1)
		{
			j_WardenFF = true;
		}
		else if (iNewValue == 0)
		{
			j_WardenFF = false;
		}
	}

	if (cvar == JB_ConVars[13])
	{
		if (iNewValue == 1)
		{
			j_WardenCC = true;
		}
		else if (iNewValue == 0)
		{
			j_WardenCC = false;
		}
	}

	if (cvar == JB_ConVars[14])
	{
		if (iNewValue == 1)
		{
			j_WardenRequest = true;
		}
		else if (iNewValue == 0)
		{
			j_WardenRequest = false;
		}
	}

	if (cvar == JB_ConVars[15])
	{
		j_WardenLimit = iNewValue;
	}

	if (cvar == JB_ConVars[16])
	{
		if (iNewValue == 1)
		{
			j_DoorControl = true;
		}
		else if (iNewValue == 0)
		{
			j_DoorControl = false;
		}
	}

	if (cvar == JB_ConVars[17])
	{
		j_DoorOpenTimer = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[18])
	{
		j_RedMute = iNewValue;
		switch (iNewValue)
		{
		case 0:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						UnmutePlayer(i);
					}
				}
			}
		case 1:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						if (g_CellDoorTimerActive) MutePlayer(i);
					}
				}
			}
		case 2:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						if (g_bActiveRound) MutePlayer(i);
					}
				}
			}
		}
	}

	if (cvar == JB_ConVars[19])
	{
		j_RedMuteTime = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[20])
	{
		j_BlueMute = iNewValue;
		switch (iNewValue)
		{
		case 0:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
					{
						UnmutePlayer(i);
					}
				}
			}
		case 1:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
					{
						MutePlayer(i);
					}
				}
			}
		case 2:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
					{
						if (i != Warden) MutePlayer(i);
					}
				}
			}
		}
	}

	if (cvar == JB_ConVars[21])
	{
		if (iNewValue == 1)
		{
			j_DeadMute = true;
		}
		else if (iNewValue == 0)
		{
			j_DeadMute = false;
		}
	}

	if (cvar == JB_ConVars[22])
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

	if (cvar == JB_ConVars[23])
	{
		if (iNewValue == 1)
		{
			j_MicCheckType = true;
		}
		else if (iNewValue == 0)
		{
			j_MicCheckType = false;
		}
	}

	if (cvar == JB_ConVars[24])
	{
		if (iNewValue == 1)
		{
			j_Rebels = true;
		}
		else if (iNewValue == 0)
		{
			j_Rebels = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (g_IsRebel[i])
				{
					SetEntityRenderColor(i, 255, 255, 255, 255);
					g_IsRebel[i] = false;
				}
			}
		}
	}

	if (cvar == JB_ConVars[25])
	{
		j_RebelsTime = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[26])
	{
		j_Criticals = iNewValue;
	}

	if (cvar == JB_ConVars[27])
	{
		j_Criticalstype = iNewValue;
	}

	if (cvar == JB_ConVars[28])
	{
		j_WVotesNeeded = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[29]) 
	{
		j_WVotesMinPlayers = iNewValue;
	}

	if (cvar == JB_ConVars[30]) 
	{
		j_WVotesPostAction = iNewValue;
	}

	if (cvar == JB_ConVars[31]) 
	{
		j_WVotesPassedLimit = iNewValue;
	}

	if (cvar == JB_ConVars[32])
	{
		if (iNewValue == 1)
		{
			j_Freekillers = true;
		}
		else if (iNewValue == 0)
		{
			j_Freekillers = false;
		}
	}

	if (cvar == JB_ConVars[33])
	{
		j_FreekillersTime = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[34])
	{
		j_FreekillersKills = iNewValue;
	}

	if (cvar == JB_ConVars[35])
	{
		j_FreekillersWave = StringToFloat(newValue);
	}

	if (cvar == JB_ConVars[36])
	{
		j_FreekillersAction = iNewValue;
	}
	
	//37, 38

	if (cvar == JB_ConVars[39])
	{
		j_FreekillersBantime = iNewValue;
	}

	if (cvar == JB_ConVars[40])
	{
		j_FreekillersBantimeDC = iNewValue;
	}

	if (cvar == JB_ConVars[41])
	{
		if (iNewValue == 1)
		{
			j_LRSEnabled = true;
		}
		else if (iNewValue == 0)
		{
			j_LRSEnabled = false;
		}
	}

	if (cvar == JB_ConVars[42])
	{
		if (iNewValue == 1)
		{
			j_LRSAutomatic = true;
		}
		else if (iNewValue == 0)
		{
			j_LRSAutomatic = false;
		}
	}

	if (cvar == JB_ConVars[43])
	{
		if (iNewValue == 1)
		{
			j_LRSLockWarden = true;
		}
		else if (iNewValue == 0)
		{
			j_LRSLockWarden = false;
		}
	}

	if (cvar == JB_ConVars[44])
	{
		j_FreedayLimit = iNewValue;
	}

	if (cvar == JB_ConVars[45])
	{
		if (iNewValue == 1)
		{
			j_1stDayFreeday = true;
		}
		else if (iNewValue == 0)
		{
			j_1stDayFreeday = false;
		}
	}

	if (cvar == JB_ConVars[46])
	{
		if (iNewValue == 1)
		{
			j_DemoCharge = true;
		}
		else if (iNewValue == 0)
		{
			j_DemoCharge = false;
		}
	}

	if (cvar == JB_ConVars[47])
	{
		if (iNewValue == 1)
		{
			j_DoubleJump = true;
		}
		else if (iNewValue == 0)
		{
			j_DoubleJump = false;
		}
	}

	if (cvar == JB_ConVars[48])
	{
		if (iNewValue == 1)
		{
			j_Airblast = true;
		}
		else if (iNewValue == 0)
		{
			j_Airblast = false;
		}
	}

	if (cvar == JB_ConVars[49])
	{
		gwardenColor = SplitColorString(newValue);
	}

	if (cvar == JB_ConVars[50])
	{
		gRebelColor = SplitColorString(newValue);
	}

	if (cvar == JB_ConVars[51])
	{
		gFreedayColor = SplitColorString(newValue);
	}
	
	if (cvar == JB_ConVars[52])
	{
		j_WardenVoice = iNewValue;
	}
}

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
			g_HasBeenwarden[i] = 0;
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
		wardenLimit = 0;

		MapCheck();
	}
}

public OnMapEnd()
{
	if (j_Enabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i))
			{
				g_HasTalked[i] = false;
				g_IsMuted[i] = false;
				g_IsFreeday[i] = false;
				g_LockedFromwarden[i] = false;
			}
		}

		g_IsMapCompatible = false;
		g_bActiveRound = false;
		
		ResetVotes();
		
		enumLastRequests = LR_Disabled;
		
		ConvarsSet(false);
		RemoveServerTag("Jailbreak");
		ClearTimer(g_checkweapontimer);
		ClearTimer(g_adverttimer);
		PrintToServer("%s Jailbreak has been unloaded successfully.", CLAN_TAG);
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

	if (!Client_IsIngame(client) || !Client_IsIngame(attacker)) return Plugin_Continue;

	new team = GetClientTeam(attacker);

	if (attacker > 0 && client != attacker)
	{
		switch (team)
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
	if (IsFakeClient(client) && !j_Enabled) return;

	if (g_Voted[client]) g_Votes--;
	g_Voters--;

	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
	
	if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded )
	{
		if (j_WVotesPostAction == 1)
		{
			return;
		}
		FirewardenCall();
	}

	if (IsWarden(client))
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden disconnected");
		PrintCenterTextAll("%t", "warden disconnected center");
		Warden = -1;
	}
	
	if (g_MovementSpeedFTW[client])
	{
		RemoveAttribute(client, "move speed bonus");
		g_MovementSpeedFTW[client] = false;
	}

	g_HasTalked[client] = false;
	g_IsMuted[client] = false;
	g_ScoutsBlockedDoubleJump[client] = false;
	g_PyrosDisableAirblast[client] = false;
	g_RobotRoundClients[client] = false;
	g_SkeletonRoundClients[client] = false;
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

	if (Client_IsIngame(client) && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		CreateTimer(0.1, ManageWeapons, client);
		switch (team)
		{
			case TFTeam_Red:
				{
					//SetEntityFlags(client, FL_NOTARGET);

					if (j_DemoCharge)
					{
						new ent = -1;
						while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1) AcceptEntityInput(ent, "kill");
					}
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
								CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone unverified");
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
	if (!Client_IsIngame(client) || !Client_IsIngame(client_attacker)) return Plugin_Continue;

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
	return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new TFClassType:class = ClassIdToType(GetClientOfUserId(GetEventInt(event, "class")));
	
	if (g_IsFreedayActive[client])
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		SetEntityRenderColor(client, gFreedayColor[0], gFreedayColor[1], gFreedayColor[2], 255);
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
	if (!Client_IsIngame(client) || !Client_IsIngame(client_killer)) return Plugin_Continue;

	decl String:clientname[64];
	GetClientName(client, clientname, sizeof(clientname));

	new time = GetTime();

	if (j_Freekillers)
	{
		if (client_killer != client && GetClientTeam(client_killer) == _:TFTeam_Blue)
		{
			if ((g_FirstKill[client_killer] + j_FreekillersTime) >= time)
			{
				if (++g_Killcount[client_killer] == j_FreekillersKills)
				{
					if (!g_VoidFreekills)
					{
						MarkFreekiller(client_killer);
					}
					else
					{
						CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "freekiller flagged while void", client_killer);
					}
				}
			}
			else
			{
				g_Killcount[client_killer] = 1;
				g_FirstKill[client_killer] = time;
			}
		}
	}
	
	if (j_LRSAutomatic)
	{
		if (Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE) == 1)
		{
			if (IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
			{
				LastRequestStart(client);
				Jail_Log("%N has received last request for being the last prisoner alive.", client);
			}
		}
	}
	
	if (IsWarden(client))
	{
		WardenUnset(Warden);
		PrintCenterTextAll("%t", "warden killed", Warden);
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
	
	if (g_MovementSpeedFTW[client])
	{
		RemoveAttribute(client, "move speed bonus");
		g_MovementSpeedFTW[client] = false;
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

	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	if (j_1stDayFreeday && g_1stRoundFreeday)
	{
		OpenCells();
		PrintCenterTextAll("1st round freeday");
		g_1stRoundFreeday = false;
		Jail_Log("1st day freeday has been activated.");
	}

	if (g_IsMapCompatible)
	{
		new open_cells = Entity_FindByName("open_cells", "func_button");
		if (Entity_IsValid(open_cells))
		{
			if (j_DoorControl)
			{
				Entity_Lock(open_cells);
				Jail_Log("Door controls are disabled, button to open cells has been locked if there is one.");
			}
			else
			{
				Entity_UnLock(open_cells);
				Jail_Log("Door controls are enabled, button to open cells has been unlocked if there is one.");
			}
		}
	}
	else
	{
		Jail_Log("Map is incompatible, disabling check for door controls command variable.");
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
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
	
	g_bIswardenLocked = false;

	new Float:Ratio;
	if (j_Balance)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			Ratio = Float:GetTeamClientCount(_:TFTeam_Blue)/Float:GetTeamClientCount(_:TFTeam_Red);
			if (Ratio <= j_BalanceRatio || GetTeamClientCount(_:TFTeam_Red) == 1)
			{
				break;
			}
			if (Client_IsIngame(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);
				CPrintToChat(i, "%s %t", CLAN_TAG_COLOR, "moved for balance");
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
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "cell doors open start", autoopen);
		CreateTimer(j_DoorOpenTimer, Open_Doors, _);
		g_CellDoorTimerActive = true;
		Jail_Log("Cell doors have been auto opened via automatic timer if they exist.");
	}

	switch(j_RedMute)
	{
	case 0:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red mute system disabled");
			Jail_Log("Mute system has been disabled this round, nobody has been muted.");
		}
	case 1:
		{
			new time = RoundFloat(j_RedMuteTime);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team muted temporarily", time);
			CreateTimer(j_RedMuteTime, UnmuteReds, _, TIMER_FLAG_NO_MAPCHANGE);
			Jail_Log("Red team has been temporarily muted and will wait %s seconds to be unmuted.", time);
		}
	case 2:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team muted");
			Jail_Log("Red team has been muted permanently this round.");
		}
	}
	
	switch(enumLastRequests)
	{
	case LR_FreedayForAll:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr free for all executed");
			g_VoidFreekills = true;
			Jail_Log("LR Freeday For All has been activated this round.");
		}
	case LR_PersonalFreeday:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && g_IsFreedayActive[i])
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday executed", i);
					Jail_Log("Freeday has been given to %N for a last request.", i);
				}
			}
			Jail_Log("LR Personal Freeday has been activated this round.");
		}
	case LR_FreedayForClients:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && g_IsFreedayActive[i])
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday executed", i);
					Jail_Log("Freeday has been given to %N for a last request.", i);
				}
			}
			Jail_Log("LR Personal Freeday has been activated this round.");
		}
	case LR_GuardsMeleeOnly:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr guards melee only executed");
			Jail_Log("LR Guards Melee Only has been activated this round.");
		}
	case LR_HHHKillRound:
		{
			ServerCommand("sm_behhh @all");
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hhh kill round executed");
			CreateTimer(10.0, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			g_VoidFreekills = true;
			if (g_bTimerStatus)
			{
				ServerCommand("sm_countdown_enabled 0");
				g_bTimerStatus = false;
			}
			Jail_Log("LR HHH Kill Round has been activated this round.");
		}
	case LR_LowGravity:
		{
			g_bIsLowGravRound = true;
			SetConVarInt(JB_EngineConVars[2], 300, false, false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr low gravity round executed");
			Jail_Log("LR Low Gravity has been activated this round.");
		}
	case LR_SpeedDemon:
		{
			decl Float:baseSpeed[10] = {0.0, 400.0, 300.0, 240.0, 280.0, 320.0, 230.0, 300.0, 300.0, 300.0};
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i))
				{
					new TFClassType:Class = TF2_GetPlayerClass(i);
					new Float:ClientSpeed = baseSpeed[Class];
					AddAttribute(i, "move speed bonus", 520.0/ClientSpeed);
					g_MovementSpeedFTW[i] = true;
				}
			}
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr speed demon round executed");
			Jail_Log("LR Speed Demon has been activated this round.");
		}
	case LR_HungerGames:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hunger games executed");
			CreateTimer(10.0, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			g_VoidFreekills = true;
			if (g_bTimerStatus)
			{
				ServerCommand("sm_countdown_enabled 0");
				g_bTimerStatus = false;
			}
			Jail_Log("LR Hunger Games has been activated this round.");
		}
	case LR_RoboticTakeOver:
		{
			if (e_betherobot)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i))
					{
						g_RobotRoundClients[i] = true;
						BeTheRobot_SetRobot(i, true);
					}
				}
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr robotic takeover executed");
				Jail_Log("LR Robotic Takeover has been activated this round.");
			}
			else
			{
				Jail_Log("Robotic Takeover cannot be executed due to lack of the Plug-in being installed, please check that the plug-in is installed and running properly.");
			}
		}
	case LR_SkeletonsAttack:
		{
			if (e_betheskeleton)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Client_IsIngame(i))
					{
						g_SkeletonRoundClients[i] = true;
						TF2_SetPlayerClass(i, TFClass_Sniper);
						BeTheSkeleton_SetSkeleton(i, true);
					}
				}
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr skeletons attack executed");
				Jail_Log("LR Skeletons Attack has been activated this round.");
			}
			else
			{
				Jail_Log("Skeletons Attack cannot be executed due to lack of the Plug-in being installed, please check that the plug-in is installed and running properly.");
			}
		}
	case LR_HideAndSeek:
		{
			OpenCells();
			ServerCommand("sm_freeze @blue 45");
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
				{
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				}
			}
			CreateTimer(30.0, LockBlueteam, _, TIMER_FLAG_NO_MAPCHANGE);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hide and seek executed");
			g_VoidFreekills = true;
			if (g_bTimerStatus)
			{
				ServerCommand("sm_countdown_enabled 0");
				g_bTimerStatus = false;
			}
			Jail_Log("LR Hide & Seek has been activated this round.");
		}
	case LR_DiscoDay:
		{
			ServerCommand("sm_disco");
			g_bIsDiscoRound = true;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr disco day executed");
			Jail_Log("LR Disco Day has been activated this round.");
		}
	case LR_MagicianWars:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr magician wars executed");
			CreateTimer(10.0, StartMagicianWars, _, TIMER_FLAG_NO_MAPCHANGE);
			g_VoidFreekills = true;
			Jail_Log("LR Magician Wars has been activated this round.");
		}
	}
	
	if (j_WardenAuto)
	{
		new Random = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE|CLIENTFILTER_NOBOTS);
		if (Client_IsIngame(Random) && Warden == -1)
		{
			WardenSet(Random);
			Jail_Log("%N has been set to warden automatically at the start of this arena round.", Random);
		}
	}
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	g_bIswardenLocked = true;
	g_bOneGuardLeft = false;
	g_bActiveRound = false;
	FreedayLimit = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			UnmutePlayer(i);
			if (g_RobotRoundClients[i])
			{
				BeTheRobot_SetRobot(i, false);
				g_RobotRoundClients[i] = false;
			}
			if (g_SkeletonRoundClients[i])
			{
				BeTheSkeleton_SetSkeleton(i, false);
				g_SkeletonRoundClients[i] = false;
			}
			if (g_MovementSpeedFTW[i])
			{
				RemoveAttribute(i, "move speed bonus");
				g_MovementSpeedFTW[i] = false;
			}
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
	
	if (enumLastRequests != LR_Disabled && !g_bIsLRInUse)
	{
		enumLastRequests = LR_Disabled;
	}
	
	ClearTimer(g_refreshspellstimer);
	
	CloseLRMenu();

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
	}
}

public Action:InterceptBuild(client, const String:command[], args)
{
	if (j_Enabled && Client_IsIngame(client) && GetClientTeam(client) == _:TFTeam_Red)
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
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone verified");
	}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:Command_Firewarden(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}

	if (j_WVotesPassedLimit != 0)
	{
		if (wardenLimit < j_WVotesPassedLimit) AttemptFirewarden(client);
		else
		{
			PrintToChat(client, "You are not allowed to vote again, the warden fire limit has been reached.");
			return Plugin_Handled;
		}
	}
	else AttemptFirewarden(client);

	return Plugin_Handled;
}

AttemptFirewarden(client)
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

	if (g_Votes >= g_VotesNeeded) FirewardenCall();
}

FirewardenCall()
{
	if (Warden != -1)
	{
		for (new i=1; i<=MAXPLAYERS; i++)
		{
			if (IsWarden(i))
			{
				WardenUnset(i);
				g_LockedFromwarden[i] = true;
			}
		}
		ResetVotes();
		g_VotesPassed++;
		wardenLimit++;
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
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	new open_cells = Entity_FindByName("open_cells", "func_button");
	new cell_door = Entity_FindByName("cell_door", "func_door");
	
	if (Entity_IsValid(open_cells))
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "Map Compatibility Cell Opener Detected");
	}
	else
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "Map Compatibility Cell Opener Undetected");
	}
	
	if (Entity_IsValid(cell_door))
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "Map Compatibility Cell Doors Detected");
	}
	else
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "Map Compatibility Cell Doors Detected");
	}
	CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Scan Map Compatibility", client);
	Jail_Log("Admin %N has checked the map for compatibility.", client);

	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_ScoutsBlockedDoubleJump[i] = false;
		g_PyrosDisableAirblast[i] = false;
		g_RobotRoundClients[i] = false;
		g_SkeletonRoundClients[i] = false;
		g_IsMuted[i] = false;
		g_IsRebel[i] = false;
		g_IsFreeday[i] = false;
		g_IsFreedayActive[i] = false;
		g_IsFreekiller[i] = false;
		g_HasTalked[i] = false;
		g_LockedFromwarden[i] = false;
		g_HasModel[i] = false;

		g_FirstKill[i] = 0;
		g_Killcount[i] = 0;
		g_AmmoCount[i] = 0;
		g_HasBeenwarden[i] = 0;
		
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
	g_bIswardenLocked = false;
	g_bIsLowGravRound = false;
	g_bIsDiscoRound = false;
	g_bOneGuardLeft = false;
	g_bTimerStatus = true;
	g_bLateLoad = false;

	Warden = -1;
	wardenLimit = 0;
	FreedayLimit = 0;

	enumLastRequests = LR_Disabled;
	enumwardenMenuAccept = WM_Disabled;
	
	MapCheck();

	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin reset plugin");
	CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Reset Plugin", client);
	Jail_Log("Admin %N has reset the plugin of all it's bools, integers and floats.", client);

	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		OpenCells();
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Open Cells", client);
		Jail_Log("Admin %N has opened the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminCloseCells(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		CloseCells();
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Close Cells", client);
		Jail_Log("Admin %N has closed the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminLockCells(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		LockCells();
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Lock Cells", client);
		Jail_Log("Admin %N has locked the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}
	
	return Plugin_Handled;
}

public Action:AdminUnlockCells(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (g_IsMapCompatible)
	{
		UnlockCells();
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Unlock Cells", client);
		Jail_Log("Admin %N has unlocked the cells using admin.", client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminForceWarden(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "current warden", Warden);
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		new Random = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
		if (Client_IsIngame(Random))
		{
			WardenSet(Random);
			CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Force warden Random", client, Random);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "forced warden", client, Random);
			Jail_Log("Admin %N has given %N warden by Force.", client, Random);
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
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Force warden", client, target);
		WardenSet(target);
		Jail_Log("Admin %N has forced a random warden. The person who received warden was %N", client, target);
	}
	
	return Plugin_Handled;
}

public Action:AdminForceLR(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Force Last Request Self", client);
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
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Force Last Request", client, target);
		LastRequestStart(target);
		Jail_Log("Admin %N has gave %N a Last Request by admin.", client, target);
	}
	
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_RobotRoundClients[i])
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed robot");
			g_RobotRoundClients[i] = false;
		}
		if (g_SkeletonRoundClients[i])
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed skeleton");
			g_SkeletonRoundClients[i] = false;
		}
		if (g_IsFreeday[i])
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed freeday");
			g_IsFreeday[i] = false;
		}
		if (g_IsFreedayActive[i])
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed freeday");
			g_IsFreedayActive[i] = false;
		}
	}
	
	g_bIsLRInUse = false;
	g_bIswardenLocked = false;
	enumLastRequests = LR_Disabled;
	
	CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Deny Last Request", client);
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin deny lr");
	Jail_Log("Admin %N has denied all currently queued last requests and reset the last request system.", client);

	return Plugin_Handled;
}

public Action:AdminPardonFreekiller(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!j_Freekillers)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "freekillers system disabled");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_IsFreekiller[i])
		{
			SetEntityRenderColor(i, 255, 255, 255, 255);
			TF2_RegeneratePlayer(i);
			ServerCommand("sm_beacon #%d", GetClientUserId(i));
			g_IsFreekiller[i] = false;
			if (DataTimerF != INVALID_HANDLE) ClearTimer(DataTimerF);
		}
	}
	CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Pardon Freekillers", client);
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin pardoned freekillers");
	Jail_Log("Admin %N has pardoned all currently marked Freekillers.", client);
	
	return Plugin_Handled;
}

public Action:AdminGiveFreeday(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}

	new Handle:menu = CreateMenu(MenuHandle_FreedayAdmins, MENU_ACTIONS_ALL);
	SetMenuTitle(menu,"Choose a Player");
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	DisplayMenu(menu, client, 20);
	CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Give Freeday Menu", client);
	Jail_Log("Admin %N is giving someone a freeday...", client);
	return Plugin_Handled;
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
				Jail_Log("Admin %N has given %N a Freeday via admin.", client, target);
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:AdminRemoveFreeday(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(MenuHandle_RemoveFreedays, MENU_ACTIONS_ALL);
	SetMenuTitle(menu,"Choose a Player");
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	DisplayMenu(menu, client, 20);
	CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Remove Freeday Menu", client);
	Jail_Log("Admin %N is removing someone's freeday status...", client);
	return Plugin_Handled;
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
				Jail_Log("Admin %N has removed Freeday status from %N.", client, target);
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:AdminAcceptwardenChange(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	switch (enumwardenMenuAccept)
	{
	case WM_Disabled:
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "no current requests");
		}
	case WM_FFChange:
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire enabled");
			CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Accept Request FF", client, Warden);
			Jail_Log("Admin %N has accepted %N's request to enable Friendly Fire.", client, Warden);
		}
	case WM_CCChange:
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision enabled");
			CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Accept Request CC", client, Warden);
			Jail_Log("Admin %N has accepted %N's request to enable Collision.", client, Warden);
		}
	}
	return Plugin_Handled;
}

public Action:AdminCancelwardenChange(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	switch (enumwardenMenuAccept)
	{
	case WM_Disabled:
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "no active warden commands");
		}
	case WM_FFChange:
		{
			SetConVarBool(JB_EngineConVars[0], false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire disabled");
			CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Cancel Active FF", client);
			Jail_Log("Admin %N has cancelled %N's request for Friendly Fire.", client, Warden);
		}
	case WM_CCChange:
		{
			SetConVarBool(JB_EngineConVars[1], false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision disabled");
			CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Cancel Active CC", client);
			Jail_Log("Admin %N has cancelled %N's request for Collision.", client, Warden);
		}
	}
	enumwardenMenuAccept = WM_Disabled;
	return Plugin_Handled;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Action:BecomeWarden(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}

	if (!j_Warden)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden disabled");
		return Plugin_Handled;
	}
	
	if (Warden != -1)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "current warden", Warden);
		return Plugin_Handled;
	}
	
	if (j_WardenLimit != 0)
	{
		if (g_HasBeenwarden[client] >= j_WardenLimit && GetClientTeam(client) == _:TFTeam_Blue)
		{	
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden limit reached", client, j_WardenLimit);
			return Plugin_Handled;
		}
	}
	
	if (j_MicCheck && !j_MicCheckType && !g_HasTalked[client])
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone check warden block");
		return Plugin_Handled;
	}
	
	if (g_1stRoundFreeday || g_bIswardenLocked)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden locked");
		return Plugin_Handled;
	}
	
	if (j_LRSLockWarden)
	{
		switch (enumLastRequests)
		{
		case LR_FreedayForAll, LR_HHHKillRound, LR_HungerGames, LR_SkeletonsAttack, LR_HideAndSeek, LR_MagicianWars:
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden locked lr round");
				return Plugin_Handled;
			}
		}
	}
	
	if (g_LockedFromwarden[client])
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "voted off of warden");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) == _:TFTeam_Blue)
	{
		if (Client_IsIngame(client) && IsPlayerAlive(client))
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
	
	return Plugin_Handled;
}

public Action:wardenMenuC(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		wardenMenu(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

wardenMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandle_WardenMenu, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Available warden Commands:");
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

public Action:wardenFriendlyFire(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}

	if (!j_WardenFF)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden friendly fire manage disabled");
		return Plugin_Handled;
	}
	
	if (client != Warden)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		return Plugin_Handled;
	}

	if (!j_WardenRequest)
	{
		if (!GetConVarBool(JB_EngineConVars[0]))
		{
			SetConVarBool(JB_EngineConVars[0], true);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire enabled");
			Jail_Log("%N has enabled friendly fire as warden.", Warden);
		}
		else
		{
			SetConVarBool(JB_EngineConVars[0], false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire disabled");
			Jail_Log("%N has disabled friendly fire as warden.", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire request");
		enumwardenMenuAccept = WM_FFChange;
	}
	
	return Plugin_Handled;
}

public Action:wardenCollision(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!j_WardenCC)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden collision manage disabled");
		return Plugin_Handled;
	}
	
	if (client != Warden)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		return Plugin_Handled;
	}
	
	if (!j_WardenRequest)
	{
		if (!GetConVarBool(JB_EngineConVars[1]))
		{
			SetConVarBool(JB_EngineConVars[1], true);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision enabled");
			Jail_Log("%N has enabled collision as warden.", Warden);
		}
		else
		{
			SetConVarBool(JB_EngineConVars[1], false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision disabled");
			Jail_Log("%N has disabled collision as warden.", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision request");
		enumwardenMenuAccept = WM_CCChange;
	}

	return Plugin_Handled;
}

public Action:Exitwarden(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden retired", client);
		PrintCenterTextAll("%t", "warden retired center");
		WardenUnset(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

public Action:AdminRemovewarden(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (Warden != -1)
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden fired", client, Warden);
		PrintCenterTextAll("%t", "warden fired center");
		CShowActivity2(client, CLAN_TAG_COLOR, "%t", "Admin Remove warden", client, Warden);
		Jail_Log("Admin %N has removed %N's warden status with admin.", client, Warden);
		WardenUnset(Warden);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "no warden current");
	}

	return Plugin_Handled;
}

public Action:OnOpenCommand(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		if (j_DoorControl)
		{
			if (IsWarden(client))
			{
				OpenCells();
				Jail_Log("%N has opened the cell doors using door controls as warden.", client);
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

	return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}

	if (g_IsMapCompatible)
	{
		if (j_DoorControl)
		{
			if (IsWarden(client))
			{
				CloseCells();
				Jail_Log("%N has closed the cell doors using door controls as warden.", client);
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

	return Plugin_Handled;
}

public Action:GiveLR(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!j_LRSEnabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "lr system disabled");
		return Plugin_Handled;
	}
	
	if (IsWarden(client))
	{
		if (!g_bIsLRInUse)
		{
			new Handle:menu = CreateMenu(MenuHandle_GiveLR, MENU_ACTIONS_ALL);
			SetMenuTitle(menu,"Choose a Player:");
			AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
			DisplayMenu(menu, client, 20);
			Jail_Log("%N is giving someone a last request...", client);
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "last request in use");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
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
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request given", Warden, iUserid);
				Jail_Log("%N has given %N a Last Request as warden.", client, iUserid);
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:RemoveLR(client, args)
{
	if (!j_Enabled)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (!client)
	{
		CReplyToCommand(client, "%s%t", CLAN_TAG_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (client != Warden)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
		return Plugin_Handled;
	}
	
	g_bIsLRInUse = false;
	g_bIswardenLocked = false;
	enumLastRequests = LR_Disabled;
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = false;
	CPrintToChat(Warden, "%s %t", CLAN_TAG_COLOR, "warden removed lr");
	Jail_Log("warden %N has cleared all last requests currently queued.", client);

	return Plugin_Handled;
}

WardenSet(client)
{
	Warden = client;
	g_HasBeenwarden[client]++;
	
	switch (j_WardenVoice)
	{
		case 0: {}
		case 1: SetClientListeningFlags(client, VOICE_NORMAL);
		case 2: CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden voice muted", Warden);
	}
	
	if (j_WardenForceSoldier)
	{
		TF2_SetPlayerClass(client, TFClass_Soldier);
	}

	if (j_WardenModel)
	{
		SetModel(client, WARDEN_MODEL);
	}
	else
	{
		SetEntityRenderColor(client, gwardenColor[0], gwardenColor[1], gwardenColor[2], 255);
	}
	
	SetHudTextParams(-1.0, -1.0, 2.0, 255, 255, 255, 255, 1, _, 1.0, 1.0);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
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
	wardenMenu(client);
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
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
	}
	
	if (j_BlueMute == 1)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (Client_IsIngame(i) && GetClientTeam(i) == _:TFTeam_Blue && i != Warden)
			{
				UnmutePlayer(i);
			}
		}
	}
	
	Forward_OnWardenRemoved(client);
}

public Action:SetModel(client, const String:model[])
{
	if (Client_IsIngame(client) && IsPlayerAlive(client) && IsWarden(client) && !g_HasModel[client])
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		RemoveValveHat(client);
		g_HasModel[client] = true;
	}
}

public Action:RemoveModel(client)
{
	if (Client_IsIngame(client) && g_HasModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_HasModel[client] = false;
	}
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

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
LastRequestStart(client)
{
	new Handle:menu = CreateMenu(MenuHandle_LR, MENU_ACTIONS_ALL);
	decl String:buffer[100];

	SetMenuTitle(menu, "Last Request Menu");

	Format(buffer, sizeof(buffer), "%T", "menu Freeday for yourself", client);
	AddMenuItem(menu, "0", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Freeday for you and others", client);
	AddMenuItem(menu, "1", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Freeday for all", client);
	AddMenuItem(menu, "2", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Commit Suicide", client);
	AddMenuItem(menu, "3", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Guards Melee Only Round", client);
	AddMenuItem(menu, "4", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu HHH Kill Round", client);
	AddMenuItem(menu, "5", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Low Gravity Round", client);
	AddMenuItem(menu, "6", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Speed Demon Round", client);
	if (e_tf2attributes) AddMenuItem(menu, "7", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Hunger Games", client);
	AddMenuItem(menu, "8", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Robotic Takeover", client);
	if (e_betherobot)	AddMenuItem(menu, "9", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Skeletons Attack", client);
	if (e_betheskeleton)	AddMenuItem(menu, "10", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Hide & Seek", client);
	AddMenuItem(menu, "11", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Disco Day", client);
	AddMenuItem(menu, "12", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Magician Wars", client);
	AddMenuItem(menu, "13", buffer);
	Format(buffer, sizeof(buffer), "%T", "menu Custom Request", client);
	AddMenuItem(menu, "14", buffer);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30 );
}

public MenuHandle_LR(Handle:menu, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Display:
		{
			g_bIsLRInUse = true;
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden granted lr");
		}
	case MenuAction_Select:
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
					enumLastRequests = LR_FreedayForClients;
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
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr skeletons attack queued", client);
					enumLastRequests = LR_SkeletonsAttack;
				}
			case 11:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hide and seek queued", client);
					enumLastRequests = LR_HideAndSeek;
				}
			case 12:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr disco day queued", client);
					enumLastRequests = LR_DiscoDay;
				}
			case 13:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr magician wars queued", client);
					enumLastRequests = LR_MagicianWars;
				}
			case 14:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr custom message", client);
				}
			}

			g_bIswardenLocked = true;

			if (g_bTimerStatus)
			{
				ServerCommand("sm_countdown_enabled 0");
			}
		}
	case MenuAction_Cancel:
		{
			g_bIsLRInUse = false;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request closed");
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

FreedayforClientsMenu(client)
{
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
			
			if (Client_IsIngame(client) && !IsClientInKickQueue(client))
			{
				if (target == 0)
				{
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "Player no longer available");
					FreedayforClientsMenu(client);
				}
				else if (g_IsFreeday[target])
				{
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "freeday currently queued", target);
					FreedayforClientsMenu(client);
				}
				else
				{
					if (FreedayLimit < j_FreedayLimit)
					{
						g_IsFreeday[target] = true;
						FreedayLimit++;
						CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday picked clients", client, target);
						FreedayforClientsMenu(client);
					}
					else
					{
						CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday picked clients maxed", client);
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

GiveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	SetEntityRenderColor(client, gFreedayColor[0], gFreedayColor[1], gFreedayColor[2], 255);
	CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "lr freeday message");
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	if(g_bFreedayTeleportSet) TeleportEntity(client, free_pos, NULL_VECTOR, NULL_VECTOR);
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = true;
	Jail_Log("%N has been given a Freeday.", client);
}

RemoveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	g_IsFreedayActive[client] = false;
	Jail_Log("%N is no longer a Freeday.", client);
}

public Action:EnableFFTimer(Handle:hTimer)
{
	SetConVarBool(JB_EngineConVars[0], true);
}

MarkRebel(client)
{
	g_IsRebel[client] = true;
	SetEntityRenderColor(client, gRebelColor[0], gRebelColor[1], gRebelColor[2], 255);
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "prisoner has rebelled", client);
	if (j_RebelsTime >= 1.0)
	{
		new time = RoundFloat(j_RebelsTime);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "rebel timer start", time);
		CreateTimer(j_RebelsTime, RemoveRebel, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	Jail_Log("%N has been marked as a Rebeller.", client);
}

public Action:RemoveRebel(Handle:hTimer, any:client)
{
	if (Client_IsIngame(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "rebel timer end");
		Jail_Log("%N is no longer a Rebeller.", client);
	}
}

MarkFreekiller(client)
{
	g_IsFreekiller[client] = true;
	TF2_RemoveAllWeapons(client);
	ServerCommand("sm_beacon #%d", GetClientUserId(client));
	EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
	if (j_FreekillersWave >= 1.0)
	{
		new time = RoundFloat(j_FreekillersWave);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "freekiller timer start", client, time);

		decl String:sAuth[24];
		new Handle:hPack;
		DataTimerF = CreateDataTimer(j_FreekillersWave, BanClientTimerFreekiller, hPack);
		if (hPack != INVALID_HANDLE)
		{
			WritePackCell(hPack, client);
			WritePackCell(hPack, GetClientUserId(client));
			WritePackString(hPack, sAuth);
			PushArrayCell(hPack, DataTimerF);
		}
	}
	Jail_Log("%N has been marked as a Freekiller.", client);
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
			if (Client_IsIngame(client))
			{
				g_IsFreekiller[client] = false;
				TF2_RegeneratePlayer(client);
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
			}
		}
	case 1:
		{
			if (Client_IsIngame(client))
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

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
stock SetClip(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}

stock SetAmmo(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}

stock ClearTimer(&Handle:hTimer)
{
	if (hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

stock RemoveValveHat(client)
{
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == client)
		AcceptEntityInput(iEntity, "Kill");
	}
}

stock FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

stock AddAttribute(client, String:attribute[], Float:value)
{
	if (e_tf2attributes)
	{
		if (Client_IsIngame(client))
		{
			TF2Attrib_SetByName(client, attribute, value);
		}
	}
	else
	{
		Jail_Log("TF2 Attributes is not currently installed, skipping attribute set.");
	}
}

stock RemoveAttribute(client, String:attribute[])
{
	if (e_tf2attributes)
	{
		if (Client_IsIngame(client))
		{
			TF2Attrib_RemoveByName(client, attribute);
		}
	}
	else
	{
		Jail_Log("TF2 Attributes is not currently installed, skipping attribute set.");
	}
}

stock SplitColorString(const String:colors[])
{
	decl _iColors[3], String:_sBuffer[3][4];
	ExplodeString(colors, " ", _sBuffer, 3, 4);
	for (new i = 0; i <= 2; i++)
	_iColors[i] = StringToInt(_sBuffer[i]);
	
	return _iColors;
}

stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && Client_IsIngame(client) && IsPlayerAlive(client))
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

stock bool:AlreadyMuted(client)
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

stock ConvarsSet(bool:Status = false)
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

stock Jail_Log(const String:format[], any:...)
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

stock bool:IsWarden(client)
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

stock PluginEvents(bool:Enable = true)
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

stock MutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && !g_IsMuted[client])
	{
		Client_Mute(client);
		g_IsMuted[client] = true;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "muted player");
	}
}

stock UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_ROOT|ADMFLAG_RESERVATION) && g_IsMuted[client])
	{
		Client_UnMute(client);
		g_IsMuted[client] = false;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "unmuted player");
	}
}

stock MapCheck()
{
	new open_cells = Entity_FindByName("open_cells", "func_button");
	new cell_door = Entity_FindByName("cell_door", "func_door");
	if (Entity_IsValid(open_cells) && Entity_IsValid(cell_door))
	{
		g_IsMapCompatible = true;
		Jail_Log("The current map has passed all compatibility checks, plugin may proceed.");
	}
	else
	{
		g_IsMapCompatible = false;
		Jail_Log("The current map is incompatible with this plugin. Please verify the map or change it.");
		Jail_Log("Feel free to type !compatible in chat to check the map manually.");
	}
	
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));
	
	decl String:tidyname[2][32], String:confil[PLATFORM_MAX_PATH], String:maptidyname[128];
	ExplodeString(g_Mapname, "_", tidyname, 2, 32);
	Format(maptidyname, sizeof(maptidyname), "%s_%s", tidyname[0], tidyname[1]);
	BuildPath(Path_SM, confil, sizeof(confil), "data/tf2jail/maps/%s.cfg", maptidyname);
	
	new Handle:fl = CreateKeyValues("tf2jail_mapconfig");
	
	if(!FileToKeyValues(fl, confil))
	{
		Jail_Log("Config file for map %s not found at %s. Functionality required is disabled.", maptidyname, confil);
		g_bFreedayTeleportSet = false;
		CloseHandle(fl);
	}
	else
	{
		PrintToServer("Successfully loaded %s", confil);
		
		if (KvJumpToKey(fl, "Freeday_Teleport"))
		{
			free_pos[0] = KvGetFloat(fl, "Coordinate_X", 0.0);
			free_pos[1] = KvGetFloat(fl, "Coordinate_Y", 0.0);
			free_pos[2] = KvGetFloat(fl, "Coordinate_Z", 0.0);
			
			g_bFreedayTeleportSet = true;
			
			PrintToServer("Successfully parsed %s", confil);
			PrintToServer("Freeday Teleport Coordinates: %f, %f, %f", free_pos[0], free_pos[1], free_pos[2]);
		}
		else
		{
			Jail_Log("Invalid config! Could not access subkey: Freeday_Teleport");
			g_bFreedayTeleportSet = false;
		}
	}
	CloseHandle(fl);
}

public Action:TimerAdvertisement (Handle:hTimer, any:client)
{
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin advertisement");
}

public Action:CheckWeapons (Handle:hTimer, any:client)
{
	if (Client_IsIngame(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
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
	if (Client_IsIngame(client))
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "welcome message");
	}
}

public Action:ManageWeapons(Handle:hTimer, any:client)
{
	new team = GetClientTeam(client);
	switch(enumLastRequests)
	{
	case LR_HungerGames, LR_HideAndSeek, LR_MagicianWars:
		{
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			TF2_RemoveWeaponSlot(client, 3);
			TF2_RemoveWeaponSlot(client, 4);
			TF2_RemoveWeaponSlot(client, 5);
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	case LR_GuardsMeleeOnly:
		{
			if (team == _:TFTeam_Blue)
			{
				TF2_RemoveWeaponSlot(client, 0);
				TF2_RemoveWeaponSlot(client, 1);
				TF2_RemoveWeaponSlot(client, 3);
				TF2_RemoveWeaponSlot(client, 4);
				TF2_RemoveWeaponSlot(client, 5);
				TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
			}
			if (j_RedMelee && team == _:TFTeam_Red) EmptyWeaponSlots(client);
		}
	case 0, 1, 2, 3, 5, 6, 7, 9, 10, 12, 14, 15:
		{
			if (j_RedMelee && team == _:TFTeam_Red) EmptyWeaponSlots(client);
		}
	}
}

stock EmptyWeaponSlots(client)
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
	CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "stripped weapons and ammo");
}

public Action:StartMagicianWars(Handle:hTimer, any:client)
{
	SetConVarBool(JB_EngineConVars[0], true);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsPlayerAlive(i))
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
		if (Client_IsIngame(i) && IsPlayerAlive(i))
		{
			GiveRandomSpell(i);
		}
	}
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

public Action:UnmuteReds(Handle:hTimer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			UnmutePlayer(i);
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team unmuted");
	Jail_Log("All players have been unmuted.");
}

public Action:Open_Doors(Handle:hTimer, any:client)
{
	if (g_CellDoorTimerActive)
	{
		OpenCells();
		new time = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "cell doors open end", time);
		g_CellDoorTimerActive = false;
		Jail_Log("Doors have been automatically opened by a timer.");
	}
}

public Action:LockBlueteam(Handle:hTimer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			TF2_StunPlayer(i, 120.0, 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
		}
	}
	Jail_Log("Players have been stunned on Hide & Seek.");
}

stock CloseLRMenu()
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
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public bool:WardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && Warden != -1 && IsWarden(i)) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NotWardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && Warden != -1 && i != Warden) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:RebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && g_IsRebel[i]) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NotRebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && !g_IsRebel[i]) PushArrayCell(hClients, i);
	}
	return true;
}

public bool:FreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && g_IsFreeday[i] || Client_IsIngame(i) && g_IsFreedayActive[i])PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NotFreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (Client_IsIngame(i) && !g_IsFreeday[i] || Client_IsIngame(i) && !g_IsFreedayActive[i]) PushArrayCell(hClients, i);
	}
	return true;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public Native_ExistWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden)
	ThrowNativeError(SP_ERROR_INDEX, "Plugin or warden System is disabled");

	if (Warden != -1) return true;
	return false;
}

public Native_IsWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin or warden System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (IsWarden(client)) return true;
	return false;
}

public Native_SetWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin or warden System is disabled");

	new client = GetNativeCell(1);
	if (!IsClientInGame(client) && !IsClientConnected(client)) ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (Warden == -1) WardenSet(client);
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	if (!j_Enabled || !j_Warden) ThrowNativeError(SP_ERROR_INDEX, "Plugin or warden System is disabled");

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
