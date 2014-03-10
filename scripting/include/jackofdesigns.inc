#if defined _jackofdesigns_included
  #endinput
#endif
#define _jackofdesigns_included

#undef REQUIRE_PLUGIN
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN

#if defined _tf2attributes_included
new bool:attributes = false;
#endif

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

stock Jack_OnAllPluginsLoaded()
{
	attributes = LibraryExists("tf2attributes");
}

stock Jack_OnLibraryAdded(const String:name[])
{
	attributes = StrEqual(name, "tf2attributes");
}

stock Jack_OnLibraryRemoved(const String:name[])
{
	attributes = StrEqual(name, "tf2attributes");
}

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return false;
	return true;
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

#if defined _tf2attributes_included
stock AddAttribute(client, String:attribute[], Float:value)
{
	if (attributes && IsValidClient(client))
	{
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock RemoveAttribute(client, String:attribute[])
{
	if (attributes && IsValidClient(client))
	{
		TF2Attrib_RemoveByName(client, attribute);
	}
}
#endif

stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
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
		LogError("Could not create info_particle_system");
	}
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, any:Edict)
{	
	if (IsValidEdict(Edict))
	{
		RemoveEdict(Edict);
	}
}