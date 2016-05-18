#include <sourcemod>
#include <gmg\server>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Time Manager",
	author = "noodleboy347",
	description = "",
	version = "1.0.1",
	url = "http://www.goldenmachinegun.com"
}

public OnPluginStart()
{
	if(!Server_IsChambers())
		SetFailState("Not Chambers");
	CreateTimer(600.0, Timer_Check, _, TIMER_REPEAT);
}

public OnMapStart()
{
	CheckChangeMap();
}

public Action:Timer_Check(Handle:timer, any:client)
{
	CheckChangeMap();
}

CheckChangeMap()
{
	decl String:time[8];
	FormatTime(time, sizeof(time), "%d");
	new day = StringToInt(time);
	
	if((day % 2) != 0)
	{
		decl String:map[64];
		GetCurrentMap(map, sizeof(map));
		if(map[strlen(map)-1] != 'n')
		{
			Format(map, sizeof(map), "%sn", map);
			PrintToServer("%s - night", map);
			ServerCommand("changelevel %s", map);
		}
	}
	else
	{
		decl String:map[64];
		GetCurrentMap(map, sizeof(map));
		if(map[strlen(map)-1] == 'n')
		{
			map[strlen(map)-1] = 0;
			PrintToServer("%s - night", map);
			ServerCommand("changelevel %s", map);
		}
	}
	/*DispatchKeyValue(0, "skyname", "sky_night_01");
	SetLightStyle(0, "i");
	
	new ent = FindEntityByClassname(-1, "env_fog_controller");
	if(ent != -1)
	{
		DispatchKeyValue(ent, "fogblend", "0");
		DispatchKeyValue(ent, "fogcolor", "0 0 0");
		DispatchKeyValueFloat(ent, "fogstart", -1.0);
		DispatchKeyValueFloat(ent, "fogend", -1.0);
		DispatchKeyValueFloat(ent, "fogmaxdensity", -1.0);
	}*/
	
}