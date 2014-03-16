#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#include <autoexecconfig>
#include <jackofdesigns>

//TF2Jail Includes
#include <tf2jail>

#define PLUGIN_NAME     "[TF2] TF2Jail - Prisoner Uniforms"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "1.0.0"
#define PLUGIN_DESCRIPTION	"Gives uniforms to the prisoners. Special thanks to Kablowsion Inc or Nineteeneleven for the models."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

#define ScoutModel "models/jailbreak/scout/jail_scout_v2"
#define SoldierModel "models/jailbreak/soldier/jail_soldier"
#define PyroModel "models/jailbreak/pyro/jail_pyro"
#define DemomanModel "models/jailbreak/demo/jail_demo"
#define HeavyModel "models/jailbreak/heavy/jail_heavy"
#define EngineerModel "models/jailbreak/engie/jail_engineer"
#define MedicModel "models/jailbreak/medic/jail_medic"
#define SniperModel "models/jailbreak/sniper/jail_sniper"
#define SpyModel "models/jailbreak/spy/jail_spy"

new Handle:ConVars[3] = {INVALID_HANDLE, ...};
new bool:cv_Enabled = true, cv_Force = false;

new bool:g_UniformWanted[MAXPLAYERS+1] = true;
new bool:g_PrisonerUniformed[MAXPLAYERS+1] = false;

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
	AutoExecConfig_SetFile("TF2Jail_PrisonerUniforms");
	ConVars[0] = AutoExecConfig_CreateConVar("tf2jail_uniforms_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	ConVars[1] = AutoExecConfig_CreateConVar("sm_tf2jail_uniforms_status", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[2] = AutoExecConfig_CreateConVar("sm_tf2jail_uniforms_force", "0", "Force clients to use prison uniforms: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();

	for (new i = 0; i < sizeof(ConVars); i++)
	{
		HookConVarChange(ConVars[i], HandleCvars);
	}
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_changeclass", ChangeClass, EventHookMode_Pre);
	HookEvent("player_death", PlayerDeath);
	
	RegConsoleCmd("sm_prisonmodel", TogglePrisonerModel);
	
	RegAdminCmd("sm_resetpmodels", ResetPrisonerModels, ADMFLAG_GENERIC);
	
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(ConVars[1]);
	cv_Force = GetConVarBool(ConVars[2]);
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
		switch (iNewValue)
		{
		case 0:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && IsPlayerAlive(i))
					{
						RemoveModel(i);
						g_UniformWanted[i] = false;
					}
				}
			}
		}
	}

	else if (cvar == ConVars[2])
	{
		cv_Force = bool:iNewValue;
		switch (iNewValue)
		{
		case 0:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && IsPlayerAlive(i) && !g_UniformWanted[i])
					{
						RemoveModel(i);
					}
				}
			}
		case 1:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && IsPlayerAlive(i))
					{
						SetPrisonModel(i);
					}
				}
			}
		}
	}
}

public OnMapStart()
{
	if (!cv_Enabled) return;
	
	decl String:s[PLATFORM_MAX_PATH];
	new String:extensions[][] = { ".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy" };
	new String:extensionsb[][] = { ".vtf", ".vmt" };
	decl i;
	for (i = 0; i < sizeof(extensions); i++)
	{
		Format(s, PLATFORM_MAX_PATH, "%s%s", ScoutModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", SoldierModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", PyroModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);

		Format(s, PLATFORM_MAX_PATH, "%s%s", DemomanModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", HeavyModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", EngineerModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", MedicModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", SniperModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "%s%s", SpyModel, extensions[i]);
		if (FileExists(s, true)) AddFileToDownloadsTable(s);
	}
	
	for (i = 0; i < sizeof(extensionsb); i++)
	{
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/demo/jail_demo%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/engie/jail_engie%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/heavy/jail_heavy%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/medic/jail_medic%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/pyro/jail_pyro%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/scout/jail_scout%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/sniper/jail_sniper%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/soldier/jail_soldier%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		
		Format(s, PLATFORM_MAX_PATH, "materials/models/jailbreak/spy/jail_spy%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
	}

	Format(s, PLATFORM_MAX_PATH, "%s.mdl", ScoutModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", SoldierModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", PyroModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", DemomanModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", HeavyModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", EngineerModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", MedicModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", SniperModel);
	PrecacheModel(s, true);
	Format(s, PLATFORM_MAX_PATH, "%s.mdl", SpyModel);
	PrecacheModel(s, true);
	
	return;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
		if (g_UniformWanted[client])
		{
			SetPrisonModel(client);
		}
		else if (cv_Force)
		{
			SetPrisonModel(client);
		}
	}
	return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!cv_Enabled) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
		if (g_UniformWanted[client])
		{
			SetPrisonModel(client);
		}
		else if (cv_Force)
		{
			SetPrisonModel(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (cv_Enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		RemoveModel(client);
	}
}

public Action:TogglePrisonerModel(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	if (!client)
	{
		ReplyToCommand(client, "%t","Command is in-game only");
		return Plugin_Handled;
	}
		
	if (!g_UniformWanted[client])
	{
		g_UniformWanted[client] = true;
		if (IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
		{
			SetPrisonModel(client);
		}
		PrintToChat(client, "Prisoner mode enabled");
	}
	else
	{
		g_UniformWanted[client] = false;
		PrintToChat(client, "Prisoner mode disabled");
		RemoveModel(client);
	}
	return Plugin_Handled;
}

public Action:ResetPrisonerModels(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red && g_UniformWanted[i])
		{
			SetPrisonModel(i);
		}
	}
	ReplyToCommand(client, "Prisoner models have been reset.");
	return Plugin_Handled;
}

stock SetPrisonModel(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	decl String:s[PLATFORM_MAX_PATH];
	switch(class)
	{
		case TFClass_DemoMan:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", DemomanModel);
			SetModel(client, s);
		}
		case TFClass_Engineer:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", EngineerModel);
			SetModel(client, s);
		}
		case TFClass_Heavy:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", HeavyModel);
			SetModel(client, s);
		}
		case TFClass_Medic:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", MedicModel);
			SetModel(client, s);
		}
		case TFClass_Pyro:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", PyroModel);
			SetModel(client, s);
		}
		case TFClass_Scout:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", ScoutModel);
			SetModel(client, s);
		}
		case TFClass_Sniper:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", SniperModel);
			SetModel(client, s);
		}
		case TFClass_Soldier:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", SoldierModel);
			SetModel(client, s);
		}
		case TFClass_Spy:
		{
			Format(s, PLATFORM_MAX_PATH, "%s.mdl", SpyModel);
			SetModel(client, s);
		}
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !g_PrisonerUniformed[client])
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		RemoveValveHat(client, true);
		g_PrisonerUniformed[client] = true;
	}
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_PrisonerUniformed[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		RemoveValveHat(client, false);
		g_PrisonerUniformed[client] = false;
	}
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
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}