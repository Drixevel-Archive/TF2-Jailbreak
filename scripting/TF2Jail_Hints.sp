#pragma semicolon 1

#include <sourcemod>
#include <tf2jail>

new bool:g_bNotMinimumHud[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TF2Jail] Freeday Godmode",
	author = "Keith Warren (Shaders Allen)",
	description = "Gives Freedays Godmode on start & removes on exit.",
	version = "1.0.0",
	url = "http://www.shadersallen.com/"
};

public OnClientPostAdminCheck(client)
{
	g_bNotMinimumHud[client] = true;
	QueryClientConVar(client, "cl_hud_minmode", CheckClientConVar);
}

public CheckClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	if (result != ConVarQuery_Okay)
	{
		CreateTimer(5.0, CheckClientConVarTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	new bool:bCurrent = StringToInt(cvarValue) ? true : false;
	
	switch (bCurrent)
	{
		case true: g_bNotMinimumHud[client] = true;
		case false: g_bNotMinimumHud[client] = false;
	}
	
	g_bNotMinimumHud[client]
}

public Action:CheckClientConVarTimer(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	QueryClientConVar(client, "cl_hud_minmode", CheckClientConVar);
	return Plugin_Continue;
}

GiveHint(client, const String:sHint[])
{
	switch (g_bNotMinimumHud[client])
	{
		case true: //PrintTFText(String:message[], team = 0, color = 0,	Float:displayTime = 0.0, String:icon[] = "ico_build");
		case false: PrintHintText(client, const String:format[], any:...);
	}
}