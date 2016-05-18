#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public OnPluginStart()
{
	RegAdminCmd("sm_da", Command_Aim, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_silence", Command_Silence, ADMFLAG_CUSTOM2);
}

public Action:Command_Aim(client, args)
{
	if(IsValidClient(client))
	{
		new target = GetClientAimTarget(client, false);
		if(IsValidEntity(target))
		{
			decl String:ClassName[64];
			GetEntityClassname(target, ClassName, sizeof(ClassName));
			
			if(StrContains(ClassName, "obj_*", false))
			{
				SetVariantInt(999999999);
				AcceptEntityInput(target, "RemoveHealth");
			}
			else
				PrintToChat(client, "[SM] This is not an engineer building.");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Silence(client, args)
{
	if(IsValidClient(client))
	{
		new soundscape = -1;
		while ((soundscape = FindEntityByClassname(soundscape, "env_soundscape")) != -1)
		{
			if (IsValidEntity(soundscape))
			{
				AcceptEntityInput(soundscape, "Disable");
				PrintToChatAll("Disabled an env_soundscape");
			}
		}
		
		new soundproxy = -1;
		while ((soundproxy = FindEntityByClassname(soundproxy, "env_soundscape_proxy")) != -1)
		{
			if (IsValidEntity(soundproxy))
			{
				AcceptEntityInput(soundproxy, "Kill");
				PrintToChatAll("Removed an env_soundscape_proxy");
			}
		}
	}
	
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}