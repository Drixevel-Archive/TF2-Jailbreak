/*
	Private plugin for TF2Jail for the Dynamic Fortress [DYNF] and/or other networks/communities.
*/

#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <betherobot>
#include <betheskeleton>
//#include <bedeflector>
#include <morecolors>
#include <smlib>
//#include <fc>

#undef REQUIRE_PLUGIN
#include <boss_spawns>

//TF2Jail Includes
#include <tf2jail>

#define JTAG "[LR]"
#define JTAG_COLORED "{red}[LR]{default}"

new bool:g_bLateLoad = false;
new bool:g_bFallDamage = false;

new Handle:lockbluetimer = INVALID_HANDLE;
new Handle:trainraintimer = INVALID_HANDLE;
new Handle:pidgeonwar3timer = INVALID_HANDLE;
new Handle:apocdaystart = INVALID_HANDLE;
new Handle:apocdaystart_respawnplayers = INVALID_HANDLE;
new Handle:StartFreezeTagTimer = INVALID_HANDLE;
new Handle:SpellTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:FreezeCheck[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:g_MovementSpeedFTW[MAXPLAYERS+1] = false;
new bool:g_SkeletonRoundClients[MAXPLAYERS+1] = false;
new bool:g_RobotRoundClients[MAXPLAYERS+1] = false;
new bool:g_BumperCar[MAXPLAYERS+1] = false;

new bool:e_betheskeleton = false;
new bool:e_betherobot = false;
new bool:e_tf2attributes = false;

new bool:bMagicianWars = false;

new clientcount = 0;

new Handle:hWeapon;

new Float:TrainRainValue;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
public OnPluginStart()
{
	HookEvent("teamplay_round_win", RoundEnd);
	
	hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, "tf_weapon_spellbook");
	TF2Items_SetItemIndex(hWeapon, 1070);
	TF2Items_SetLevel(hWeapon, 100);
	TF2Items_SetQuality(hWeapon, 6);
	TF2Items_SetNumAttributes(hWeapon, 1);
	TF2Items_SetAttribute(hWeapon, 0, 547, 0.5);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnConfigsExecuted()
{
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		g_bLateLoad = false;
	}
}

public OnMapStart()
{
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl");
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl");
	
	PrecacheSound(")weapons/bumper_car_accelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate_quick.wav");
	PrecacheSound(")weapons/bumper_car_go_loop.wav");
	PrecacheSound(")weapons/bumper_car_hit_ball.wav");
	PrecacheSound(")weapons/bumper_car_hit_ghost.wav");
	PrecacheSound(")weapons/bumper_car_hit_hard.wav");
	PrecacheSound(")weapons/bumper_car_hit_into_air.wav");
	PrecacheSound(")weapons/bumper_car_jump.wav");
	PrecacheSound(")weapons/bumper_car_jump_land.wav");
	PrecacheSound(")weapons/bumper_car_screech.wav");
	PrecacheSound(")weapons/bumper_car_spawn.wav");
	PrecacheSound(")weapons/bumper_car_spawn_from_lava.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_start.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav");
	
	decl String:name[64];
	for(new i = 1; i <= 8; i++) {
		FormatEx(name, sizeof(name), "weapons/bumper_car_hit%d.wav", i);
		PrecacheSound(name);
	}
}

public OnAllPluginsLoaded()
{
	e_betheskeleton = LibraryExists("betheskeleton");
	e_betherobot = LibraryExists("betherobot");
	e_tf2attributes = LibraryExists("tf2attributes");
}

public OnLibraryAdded(const String:name[])
{
	e_betheskeleton = StrEqual(name, "betheskeleton");
	e_betherobot = StrEqual(name, "betherobot");
	e_tf2attributes = StrEqual(name, "tf2attributes");
}

public OnLibraryRemoved(const String:name[])
{
	e_betheskeleton = StrEqual(name, "betheskeleton");
	e_betherobot = StrEqual(name, "betherobot");
	e_tf2attributes = StrEqual(name, "tf2attributes");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public TF2Jail_OnLastRequestExecute(const String:Handler[])
{
	if (StrEqual(Handler, "LR_FreezeTag"))
	{
		ServerCommand("sm_freeze @blue 45");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				switch (GetClientTeam(i))
				{
					case TFTeam_Red:
						{
							TF2_SetPlayerClass(i, TFClass_Scout);
							SetEntityHealth(i, 25);
							TF2_RegeneratePlayer(i);
							TF2Jail_StripToMelee(i);
						}
					case TFTeam_Blue:
						{
							TF2_SetPlayerClass(i, TFClass_Pyro);
							SetEntityHealth(i, 25);
							TF2_RegeneratePlayer(i);
							TF2Jail_StripToMelee(i);
							TF2_SetPlayerPowerPlay(i, true);
						}
				}
			}
		}
		StartFreezeTagTimer = CreateTimer(15.0, StartFreezeTag, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(Handler, "LR_MagicianWars"))
	{
		ServerCommand("tf_spells_enabled 1");
		ServerCommand("tf_player_spell_drop_on_death_rate 0.0");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				TF2Items_GiveNamedItem(i, hWeapon);
				GiveSpell(i, GetRandomInt(1, 12));
				SpellTimer[i] = CreateTimer(15.0, GrantSpell, GetClientUserId(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		bMagicianWars = true;
	}
	else if (StrEqual(Handler, "LR_HideAndSeek"))
	{
		ServerCommand("sm_freeze @blue 45");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				TF2_SetPlayerPowerPlay(i, true);
			}
		}
		ClearTimer(lockbluetimer);
		lockbluetimer = CreateTimer(30.0, LockBlueteam, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(Handler, "LR_SpeedDemon"))
	{
		if (e_tf2attributes)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					TF2_AddCondition(i, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
					g_MovementSpeedFTW[i] = true;
				}
			}
		}
	}
	else if (StrEqual(Handler, "LR_SkeletonsAttack"))
	{
		if (e_betheskeleton)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					TF2_SetPlayerClass(i, TFClass_Sniper);
					BeTheSkeleton_SetSkeleton(i, true);
					g_SkeletonRoundClients[i] = true;
				}
			}
		}
	}
	else if (StrEqual(Handler, "LR_RoboticTakeOver"))
	{
		if (e_betherobot)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					BeTheRobot_SetRobot(i, true);
					g_RobotRoundClients[i] = true;
				}
			}
		}
	}
	else if (StrEqual(Handler, "LR_RealismDay"))
	{
		g_bFallDamage = true;
	}
	else if (StrEqual(Handler, "LR_TrainRain"))
	{
		ClearTimer(trainraintimer);
		TrainRainValue = GetRandomFloat(5.0, 35.0);
		trainraintimer = CreateTimer(TrainRainValue, TrainRain, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(Handler, "LR_PidgeonWar3"))
	{
		ClearTimer(pidgeonwar3timer);
		pidgeonwar3timer = CreateTimer(15.0, SpawnPidgeonBombs, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(Handler, "LR_ApocDay"))
	{
		ClearTimer(apocdaystart);
		apocdaystart = CreateTimer(30.0, StartApocDay, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(Handler, "LR_BumperCars"))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				Kartify(i);
				g_BumperCar[i] = true;
			}
		}
	}
}

public Action:GrantSpell(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		GiveSpell(client, GetRandomInt(1, 12));
		return Plugin_Continue;
	}

	SpellTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		CleanAllLRs(client);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			CleanAllLRs(i);
		}
	}
	
	ClearTimer(lockbluetimer);
	ClearTimer(trainraintimer);
	ClearTimer(StartFreezeTagTimer);
	ClearTimer(pidgeonwar3timer);
	ClearTimer(apocdaystart_respawnplayers);
	
	if (bMagicianWars)
	{
		ServerCommand("tf_spells_enabled 0");
		ServerCommand("tf_player_spell_drop_on_death_rate 0.2");
		bMagicianWars = false;
	}
	
	g_bFallDamage = false;
}

public Action:LockBlueteam(Handle:hTimer)
{
	lockbluetimer = INVALID_HANDLE;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch (GetClientTeam(i))
			{
				case TFTeam_Red: TF2_StunPlayer(i, 99999.0, 0.90, TF_STUNFLAG_SLOWDOWN, 0);
				case TFTeam_Blue: TF2_SetPlayerPowerPlay(i, false);
			}
		}
	}
}

public Action:TrainRain(Handle:hTimer)
{
	trainraintimer = INVALID_HANDLE;
	ServerCommand("sm_trainrain");
	TrainRainValue = FloatDiv(TrainRainValue, 1.5);
	if (TrainRainValue < 3.0) TrainRainValue = 3.0;
	trainraintimer = CreateTimer(TrainRainValue, TrainRain, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:SpawnPidgeonBombs(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SpawnPidgeon(i);
		}
	}
}

public Action:ArmPidgeon(Handle:timer, any:data)
{
	new entity = EntRefToEntIndex(data);
	
	if (IsValidEntity(entity))
	{
		CreateTimer(1.0, ScanForPlayers, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:ScanForPlayers(Handle:timer, any:data)
{
	new entity = EntRefToEntIndex(data);
	
	if (IsValidEntity(entity))
	{
		decl Float:pos[3];
		Entity_GetAbsOrigin(entity, pos);
		
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && Entity_InRange(entity, i, 15.0))
			{
				AcceptEntityInput(entity, "kill");				
				ExplodeMine(owner, pos);
				break;
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:StartApocDay(Handle:hTimer)
{
	apocdaystart = INVALID_HANDLE;
	
	CPrintToChatAll("%s Doors have been opened for apocalpyse day!", JTAG_COLORED);
	TF2Jail_ManageCells(OPEN);
	
	ClearTimer(apocdaystart_respawnplayers);
	apocdaystart_respawnplayers = CreateTimer(1.0, CheckIfRespawn, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CheckIfRespawn(Handle:hTimer)
{
	new alive = Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE);
	new total = Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_INGAMEAUTH);
	
	new cap = total / 3;
	
	if (alive <= cap)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsPlayerAlive(i) || GetClientTeam(i) != _:TFTeam_Red) continue;
			
			TF2_RespawnPlayer(i);
		}
		CPrintToChatAll("%s Reds have been respawned!", JTAG_COLORED);
	}
	return Plugin_Continue;
}

public Action:StartFreezeTag(Handle:hTimer)
{
	StartFreezeTagTimer = INVALID_HANDLE;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == _:TFTeam_Blue)
			{
				FreezeCheck[i] = CreateTimer(0.5, SlowClientsNear, GetClientUserId(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:SlowClientsNear(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	new Float:pos[3], Float:tpos[3];
	
	new teamcount = Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Blue)
	{
		GetClientAbsOrigin(client, pos);
		for(new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
			{
				GetClientAbsOrigin(i, tpos);
				
				new Float:DistanceS = GetVectorDistance(pos, tpos);
				if (DistanceS < 25.0)
				{
					ServerCommand("sm_freeze #%d -1", GetClientUserId(i));
					clientcount++;
					
					new left = clientcount - teamcount;
					CPrintToChatAll("%s %N has been frozen. There are %i players remaining.", JTAG_COLORED, i, left);
				}
			}
		}
	}
		
	if (clientcount == teamcount)
	{
		Game_EndRound(_:TFTeam_Blue);
		CPrintToChatAll("%s Guards have frozen all players. Round is now Over.", JTAG_COLORED);
		clientcount = 0;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (g_bFallDamage && (damagetype & DMG_FALL))
	{
		damage = damage * 3.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

CleanAllLRs(client)
{
	if (g_MovementSpeedFTW[client])
	{
		TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
		g_MovementSpeedFTW[client] = false;
	}
	
	if (g_SkeletonRoundClients[client])
	{
		BeTheSkeleton_SetSkeleton(client, false);
		g_SkeletonRoundClients[client] = false;
	}
	
	if (g_RobotRoundClients[client])
	{
		BeTheRobot_SetRobot(client, false);
		g_RobotRoundClients[client] = false;
	}
	
	if (g_BumperCar[client])
	{
		Unkartify(client);
		g_BumperCar[client] = false;
	}

	ClearTimer(SpellTimer[client]);
	ClearTimer(FreezeCheck[client]);
	ClearTimer(FreezeCheck[client]);
}

ExplodeMine(owner, Float:pos[3])
{
	CreateExplosionEffects(pos);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{						
			decl Float:pos2[3];
			GetClientAbsOrigin(i, pos2);
			
			new Float:dist = GetVectorDistance(pos, pos2);
			if (dist <= 550)
			{
				new Float:damage = 300.0 * ClampFloat(500.0 - (dist - 50.0) / 500.0, 0.0, 1.0);
				PushDamagePlayer(i, owner, dist, damage, pos, pos2);
			}
		}
	}
}

SpawnPidgeon(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new entity = CreateEntityByName("prop_dynamic_override");
	
	if (IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", "models/props_forest/bird.mdl");
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
		Entity_SetName(entity, "pidgeon");
		
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
				
		CreateTimer(5.0, ArmPidgeon, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

CreateExplosionEffects(Float:pos[3])
{
	new ent = CreateEntityByName("info_particle_system");
	if (IsValidEntity(ent))
	{
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(ent, "effect_name", "asplode_hoodoo");
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "start");
		SetVariantString("OnUser1 !self:Kill::8:-1");
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
		EmitAmbientSound("weapons/explode3.wav", pos, _, SNDLEVEL_SCREAMING);
	}
}

PushDamagePlayer(client, attacker, Float:distance, Float:damage, Float:pos1[3], Float:pos2[3])
{
	decl Float:vel[3], Float:vel2[3];
	MakeVectorFromPoints(pos1, pos2, vel);
	NormalizeVector(vel, vel);
	ScaleVector(vel, 250 + ((550 - distance) / 550) * 500);
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel2);
	AddVectors(vel, vel2, vel);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	SDKHooks_TakeDamage(client, attacker, 0, damage, DMG_BLAST);
}

Float:ClampFloat(Float:val, Float:min, Float:max)
{
	return (val < min ? min : val > max ? max : val);
}

GiveSpell(client, spell_number)
{
	new ent;
	while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent) && GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
		{
			SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell_number);
			SetEntProp(ent, Prop_Send, "m_iSpellCharges", 10);
			
			SetHudTextParams(-1.0, 0.65, 6.0, 0, 255, 0, 255);
			switch (spell_number)
			{
				case 1: ShowHudText(client, -1, "Picked up the spell: Fire Ball");
				case 2: ShowHudText(client, -1, "Picked up the spell: Bats");
				case 3: ShowHudText(client, -1, "Picked up the spell: Heal Allies");
				case 4: ShowHudText(client, -1, "Picked up the spell: Explosive Pumpkins");
				case 5: ShowHudText(client, -1, "Picked up the spell: Super Jump");
				case 6: ShowHudText(client, -1, "Picked up the spell: Invisibility");
				case 7: ShowHudText(client, -1, "Picked up the spell: Teleport");
				case 8: ShowHudText(client, -1, "Picked up the spell: Magnetic Bolt");
				case 9: ShowHudText(client, -1, "Picked up the spell: Shrink");
				case 10: ShowHudText(client, -1, "Picked up the spell: Summon MONOCULUS!");
				case 11: ShowHudText(client, -1, "Picked up the spell: Fire Storm");
				case 12: ShowHudText(client, -1, "Picked up the spell: Summon Skeletons");
			}
		}
	}
}

Kartify(client)
{
	TF2_AddCondition(client, TFCond:82, TFCondDuration_Infinite);
	SetEntProp(client, Prop_Send, "m_iKartHealth", 60);
}

Unkartify(client)
{
	TF2_RemoveCondition(client, TFCond:82);
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}