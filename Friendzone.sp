#pragma semicolon 1
#include <sourcemod>
#include <devzones>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "3.0"

new bool:IsInZone[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name        =    "Friend Zone",
	author        =    "Pelipoika",
	description    =    "specified area.",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	HookEvent("player_spawn", Event_Spawn);
	
	RegAdminCmd("sm_killzoners", Command_ZoneKill, ADMFLAG_ROOT);
}

public Action:Command_ZoneKill(client, args)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsInZone[i]) continue;
		ForcePlayerSuicide(i);
	//	PrintToChat(i, "Next time, Try following my orders");
	}
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsInZone[client])
	{	
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
		IsInZone[client] = false;
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsInZone[client])
	{	
	//	PrintToChat(client, "Left Firendzone");
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
		IsInZone[client] = false;
	}
}

public Zone_OnClientEntry(client, String:zone[])
{
	if (StrContains(zone, "Friendzone", false) == 0 && IsValidClient(client))
	{
		if (TF2_GetPlayerClass(client) != TFClass_Medic)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Item1);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Item2);
			
			new weapon = GetPlayerWeaponSlot(client, 2);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);  
		}
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 10);
		
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			
		IsInZone[client] = true;
		PrintCenterText(client, "Welcome to the Friendzone!");
	}
	
	if (StrContains(zone, "killzone", false) == 0 && IsValidClient(client))
		SDKHooks_TakeDamage(client, client, client, 900000.0);
}

public Zone_OnClientLeave(client, String:zone[])
{
	if (StrContains(zone, "Friendzone", false) == 0 && IsValidClient(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
		
		IsInZone[client] = false;
		TF2_RegeneratePlayer(client);

		TF2_RemoveCondition(client, TFCond_Ubercharged);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsValidClient(victim ) || !IsValidClient(attacker))
		return Plugin_Continue;
	
	if (IsInZone[attacker] && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool:IsValidClient(client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return false;

    return true;
}