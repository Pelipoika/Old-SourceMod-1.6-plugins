#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public OnPluginStart() 
{
	CreateTimer(1.0, Timer_UpdateListeners, _, TIMER_REPEAT);
}

public Action:Timer_UpdateListeners(Handle:timer) 
{
	for (new receiver = 1; receiver <= MaxClients; receiver++)
	{
		if (!IsClientInGame(receiver))
			continue;
			
		for (new sender = 1; sender <= MaxClients; sender++)
		{
			if (!IsClientInGame(sender) || sender == receiver)
				continue;
							
			new Float:distance = 0.0;

			if (IsPlayerAlive(receiver) && IsPlayerAlive(sender))
			{
				distance = 1000.0;
			}
			
			if (distance != 0.0)
			{
				SetListenOverride(receiver, sender, (GetEntitiesDistance(receiver, sender) > distance) ? Listen_No : Listen_Yes);
			}
		}
	}
}

stock Float:GetEntitiesDistance(ent1, ent2)
{
	new Float:orig1[3];
	new Float:orig2[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

	return GetVectorDistance(orig1, orig2);
}