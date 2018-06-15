#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>

//TF2Jail Includes
#include <tf2jail>

#define PLUGIN_NAME     "[TF2] TF2Jail - Last Request"
#define PLUGIN_AUTHOR   "Keith Warren(Shaders Allen)"
#define PLUGIN_DESCRIPTION	"Allows Wardens to grant last requests to prisoners."
#define PLUGIN_CONTACT  "http://www.shadersallen.com/"

new iQuePnts[MAXPLAYERS+1] = {0,...};
new PlayerRanks[MAXPLAYERS+1] = {0,...};
new PlayerRanks2[MAXPLAYERS+1] = {0,...};

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
	RegAdminCmd("sm_rolequeue", QueuedList, ADMFLAG_RESERVATION);
}

public Action:QueuedList(client, args)
{
	QueueMenu(client);
	return Plugin_Handled;
}

QueueMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandle);
	SetMenuTitle(hMenu, "Choose a Player");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			decl String:sBuffer[MAX_NAME_LENGTH];
			GetClientName(PlayerRanks[i], sBuffer, sizeof(sBuffer));
			AddMenuItem(hMenu, PlayerRanks[i], sBuffer);
		}
	}
	
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle(Handle:hMenu, MenuAction:action, client, item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			//new String:info[64];
			//GetMenuItem(hMenu, item, info, sizeof(info));
			
			QueueMenu(client);
		}
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}