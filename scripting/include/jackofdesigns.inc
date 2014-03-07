#if defined _jackofdesigns_included
  #endinput
#endif
#define _jackofdesigns_included

#include <tf2attributes>

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
	{
		return false;
	}
	else
	{
		return true;
	}
}

stock ClearTimer(&Handle:timer)
{
    if(timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}  

stock FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

stock AddAttribute(client, String:attribute[], Float:value)
{
	if (IsValidClient(client))
	{
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock RemoveAttribute(client, String:attribute[])
{
	if (IsValidClient(client))
	{
		TF2Attrib_RemoveByName(client, attribute);
	}
}