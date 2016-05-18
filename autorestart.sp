#include <sourcemod>
#include <steamtools>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Server Autoupdate",
	author = "noodleboy347",
	description = "Restarts the server when an update is available",
	version = "1.0",
	url = "http://www.goldenmachinegun.com"
}

public Action:Steam_RestartRequested()
{
	PrintToChatAll("\x04There is a TF2 update. The server will now restart.");
	CreateTimer(10.0, Timer_Restart);
	return Plugin_Continue;
}

public Action:Timer_Restart(Handle:timer)
{
	ServerCommand("quit");
}