#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

new bool:shouldJump[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(client))
	{
		shouldJump[client] = false;
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(client))
	{
		new rand = GetRandomInt(1,3);
		switch(rand)
		{
			case 1: shouldJump[client] = true;
		}
	}
} 

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (IsFakeClient(iClient) && IsPlayerAlive(iClient)) 
	{
		iButtons &= ~IN_DUCK;	//Works
		iButtons &= ~IN_BACK;	//Dun work :v
		SetEntProp(iClient, Prop_Send, "m_bDucking", 0);
		SetEntProp(iClient, Prop_Send, "m_bDucked", 0);
		
		if (!TF2_IsPlayerInCondition(iClient, TFCond_Zoomed) && !TF2_IsPlayerInCondition(iClient, TFCond_Slowed) && !TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged) && shouldJump[iClient])
		{  
			if(iButtons |= IN_JUMP)
				iButtons &= ~IN_JUMP;

			iButtons |= IN_JUMP;
			shouldJump[iClient] = false;
			return Plugin_Changed;
		}
		return Plugin_Changed;
	}
} 

/*
sm_dump_admcache : cmd : : Dumps the admin cache for debugging
sm_dump_classes : cmd : : Dumps the class list as a text file
sm_dump_datamaps : cmd : : Dumps the data map list as a text file
sm_dump_handles : cmd : : Dumps Handle usage to a file for finding Handle leaks
sm_dump_netprops : cmd : : Dumps the networkable property table as a text file
sm_dump_netprops_xml : cmd : : Dumps the networkable property table as an XML file
sm_dump_teprops : cmd : : Dumps tempentity props to a file
*/