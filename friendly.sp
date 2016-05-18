#pragma semicolon 1

#include <sourcemod>
#include <tf2>

new bool:IsGhost[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "[TF2] Friendly Ghost",
	author = "Pelipoika",
	description = "Be a Friendly sp00py Ghost!",
	version = "1.0",
	url = ""
}

public OnClientAuthorized(client)
{
	IsGhost[client] = false;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_friendly", OnTestCmd);
	RegConsoleCmd("sm_ghost", OnTestCmd);
}

public OnMapStart()
{
	PrecacheModel("models/props_halloween/ghost_no_hat.mdl", true);
	PrecacheSound("vo/halloween_boo1.wav", true);
	PrecacheSound("vo/halloween_boo2.wav", true);
	PrecacheSound("vo/halloween_boo3.wav", true);
	PrecacheSound("vo/halloween_boo4.wav", true);
	PrecacheSound("vo/halloween_boo5.wav", true);
	PrecacheSound("vo/halloween_boo6.wav", true);
	PrecacheSound("vo/halloween_boo7.wav", true);
}

public Action:OnTestCmd(client, args)
{
	if(IsValidClient(client) && !IsGhost[client])
	{
		TF2_AddCondition(client, TFCond_HalloweenGhostMode, -1.0);
		PrintToChat(client, "You are now a GHOST!");
		PrintToChat(client, "Type !ghost again to disable Ghost.");
		IsGhost[client] = true;
		return Plugin_Handled;
	}
	else
	{
		TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
		TF2_RespawnPlayer(client);
		PrintToChat(client, "You are no longer a Ghost!");
		IsGhost[client] = false;
		return Plugin_Handled;
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}