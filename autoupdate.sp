#include <sourcemod>
#include <steamtools>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Autoupdate",
	author = "noodleboy347",
	description = "",
	version = "1.0",
	url = "http://www.goldenmachinegun.com"
}

public Action:Steam_RestartRequested()
{
	PrintToChatAll("A Team Fortress 2 update was released.");
	PrintToChatAll("The server will restart in 5 minutes.");
	PrintCenterTextAll("The server will restart in 5 minutes.");
	CreateTimer(240.0, Timer_Notify);
	CreateTimer(300.0, Timer_Restart);
	return Plugin_Continue;
}

public Action:Timer_Notify(Handle:timer)
{
	PrintToChatAll("A Team Fortress 2 update was released.");
	PrintToChatAll("The server will restart in 1 minute.");
	PrintCenterTextAll("The server will restart in 1 minute.");
}

public Action:Timer_Restart(Handle:timer)
{
	ServerCommand("quit");
}