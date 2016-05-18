#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <gmg\server>
#include <gmg\users>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Airblast Control",
	author = "noodleboy347",
	description = "No airblast",
	version = "2.0.3",
	url = "http://www.goldenmachinegun.com"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	//new String:wepon[64];
	//GetClientWeapon(client, wepon, sizeof(wepon));
	//if(StrEqual(wepon, "tf_weapon_flaregun", true)) return Plugin_Continue;
	
	if(TF2_GetPlayerClass(client) != TFClass_Pyro) return Plugin_Continue;
	if(Server_IsChambers())
		if(User_GetLocation(client) == LOCATION_ARENA) return Plugin_Continue;
	if(GetUserFlagBits(client) & ADMFLAG_GENERIC) return Plugin_Continue;
	
	if(buttons & IN_ATTACK2)
		buttons &= ~IN_ATTACK2;
	return Plugin_Continue;
}