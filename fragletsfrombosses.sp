#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <fraglets>

public Plugin:myinfo =
{
	name		= "[TF2] Fraglets for killing halloween bosses",
	author		= "Pelipoika",
	description	= "the name",
	version		= "1.0",
	url			= ""
};

public OnPluginStart()
{
	HookEvent("eyeball_boss_killer", Event_MonoculusKilled);
	HookEvent("eyeball_boss_killed", Event_BlockThis);
}

public Action:Event_BlockThis(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, false);
	dontBroadcast = true;
	return Plugin_Continue;
}

public Action:Event_MonoculusKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player_entindex");
	
	if(IsValidClient(client))
	{
		Fraglets_AddFraglets(client, 1000);
		CPrintToChatAllEx(client, "{teamcolor}%N {default}was awarded {unusual}1000 Spooklets {default}for killing {unusual}MONOCULUS!", client);
	}
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}