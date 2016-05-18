#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <steamtools>
#include <morecolors>

public Plugin:myinfo = 
{
	name = "[TF2] F2P Control",
	author = "Pelipoika",
	description = "Stuff to make the lives of F2P's miserable",
	version = "1.0",
	url = "myg0t.com"
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_GetMaxHealth, GetMaxHealthBot);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientConnected(client)
{
	if(!IsClientF2P(client))
	{
		new cClients = 0;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				cClients++;
			}
		}
		
		if(cClients >= 30)
		{	
			new F2PClients = 0;
			new P2PClients = 0;
			decl playerarray[MAXPLAYERS+1];
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && IsClientF2P(i, false))
				{
					playerarray[F2PClients] = i;	
					F2PClients++;
				}
				else if(IsValidClient(i) && !IsClientF2P(i, false))
				{
					P2PClients++;
				}
			}
			
			if(F2PClients)
			{
				new F2P = playerarray[GetRandomInt(0, F2PClients-1)];		//Choose a random F2P
				{
					if(IsValidClient(F2P))
					{
						CPrintToChatAllEx(F2P, "{default}Kicked {grey}[F2P] {teamcolor}%N{default} to free some space..", F2P);
						KickClient(F2P, "Sorry, You were kicked to make room for a connecting P2P player.");
					}
				}
			}
			
			CPrintToChatAll("{gray}F2P{default}: {green}%.2f%% (%i){default} {gold}P2P{default}: {green}%.2f%% (%i){default}", float(F2PClients) / float(cClients) * 100, F2PClients, float(P2PClients) / float(cClients) * 100, P2PClients);
			
			F2PClients = 0;
			P2PClients = 0;
		}
		cClients = 0;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new bool:Modified = false;
	
	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
		
	if (damagecustom == TF_CUSTOM_BACKSTAB)
	{
		if (!IsFakeClient(attacker) && !IsFakeClient(victim) && IsClientF2P(attacker, false) && !IsClientF2P(victim, false))
		{
			damage = 0.0;
			Modified = true;
			CPrintToChat(attacker, "{default}Free to Plays can't backstab {gold}Pay to Plays{default}!");
		}
	}
	if (damagetype & DMG_CRIT)
	{
		if (!IsFakeClient(attacker) && !IsFakeClient(victim) && IsClientF2P(attacker, false) && !IsClientF2P(victim, false))
		{
			damagetype &= ~DMG_CRIT;
			Modified = true;
			CPrintToChat(attacker, "{default}Free to Plays do not do crit damage to {gold}Pay to Plays{default}!");
		}
	}
	//F2P Damage towards real players
	if (!IsFakeClient(attacker) && !IsFakeClient(victim) && IsClientF2P(attacker, false) && !IsClientF2P(victim, false))
	{
		damage *= 0.45;
		TF2_RemoveCondition(victim, TFCond_OnFire);
		Modified = true;
	}
	//Heh...
//	if(IsPeli(victim) && !IsPeli(attacker))
//	{
//		damage *= 0.45;
//		Modified = true;
//	}
	
	if (attacker > MaxClients || attacker < 1)
		return Plugin_Continue;
		
	//Bot damage vs humans
	if (IsFakeClient(attacker) && !IsFakeClient(victim))
	{
		damage *= 0.66;
		Modified = true;
	}
	
	if (Modified)
		return Plugin_Changed;
		
	return Plugin_Continue;
}

public Action:GetMaxHealthBot(client, &MaxHealth)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			MaxHealth = RoundToNearest(MaxHealth * 0.5);
			return Plugin_Changed;
		}
		new bool:Modified = false;
		if (IsClientF2P(client, false))
		{
			MaxHealth = RoundToNearest(MaxHealth * 0.75);
			Modified = true;
		}
		if (Modified)
			return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
    SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
}

public Action:OnSceneSpawned(entity)
{
    new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
    GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
    if (StrEqual(scenefile, "scenes/player/spy/low/taunt05.vcd"))
    {
        if (IsPeli(client))
        {
        	if (GetRandomInt(1, 6) == 5)
        	{
				PrintToChat(client, "Spycrab taunt allowed!");
			}
			else
			{
				PrintToChat(client, "Spycrab taunt bypassed!");
				AcceptEntityInput(entity, "kill");
				TF2_RemoveCondition(client, TFCond_Taunting);
			}
        }
    }
} 

stock bool:IsClientF2P(client, bool:UseName=false)
{
	if (UseName)
	{
		decl String:Name[MAX_NAME_LENGTH];
		GetClientName(client, Name, sizeof(Name));
		return (StrContains(Name, "[F2P]", true) != -1);
	}
	else
	{
		if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsPeli(client)
{
	if (client > MaxClients || client <= 0 || !IsClientConnected(client) || IsFakeClient(client))
		return false;
	decl String:SteamID[64];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	return (strcmp(SteamID, "STEAM_0:0:32552944") == 0);
}

stock PrintToMerbo(String:Print[], any:...)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsPeli(i))
		{
			decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
			SetGlobalTransTarget(i);
			Format(buffer, sizeof(buffer), "\x01%s", Print);
			VFormat(buffer2, sizeof(buffer2), buffer, 2);
			PrintToChat(i, buffer2);
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}