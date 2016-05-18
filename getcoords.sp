#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
	RegAdminCmd("sm_getcoords", GetCoords, ADMFLAG_GENERIC, "Get the Coordinates.");
}

public Action:GetCoords(client, args)
{
	new Float:l_pos[3];
	GetClientEyePosition(client, l_pos);
	ReplyToCommand(client, "[SM] Your location is currently X = %0.0f, Y = %0.0f, Z = %0.0f", l_pos[0], l_pos[1], l_pos[2]);
	return Plugin_Handled;
}