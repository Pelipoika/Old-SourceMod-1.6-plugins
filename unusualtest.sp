#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <tf2attributes>
#include <tf2itemsinfo>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name        =    "UnusualHat",
	author        =    "Pelipoika",
	description    =    "TF2Attribute your hats!",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_unusuel", OnValvesHatedCmd, ADMFLAG_CUSTOM6, "Unusual Menu.");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "[TF2] This plugin only works in TF2 (Duh)");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnConfigsExecuted()
{
	g_hPoseMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(g_hPoseMenu, "Pelis Unusual Particle Menu");
	AddMenuItem(g_hPoseMenu, "1", "Set Particle: NONE");
	AddMenuItem(g_hPoseMenu, "2", "Set Particle: Community Sparkle");
	AddMenuItem(g_hPoseMenu, "3", "Set Particle: Green Confetti");
	AddMenuItem(g_hPoseMenu, "4", "Set Particle: Purple Confetti");
	AddMenuItem(g_hPoseMenu, "5", "Set Particle: Ghosts");
	AddMenuItem(g_hPoseMenu, "6", "Set Particle: Green Energy");
	AddMenuItem(g_hPoseMenu, "7", "Set Particle: Purple Energy");
	AddMenuItem(g_hPoseMenu, "8", "Set Particle: Circling TF Logo");
	AddMenuItem(g_hPoseMenu, "9", "Set Particle: Massed Flies");
	AddMenuItem(g_hPoseMenu, "10", "Set Particle: Burning Flames");
	AddMenuItem(g_hPoseMenu, "11", "Set Particle: Scorching Flames");
	AddMenuItem(g_hPoseMenu, "12", "Set Particle: Searing Plasma");
	AddMenuItem(g_hPoseMenu, "13", "Set Particle: Vivid Plasma");
	AddMenuItem(g_hPoseMenu, "14", "Set Particle: Sunbeams");
	AddMenuItem(g_hPoseMenu, "15", "Set Particle: Circling Peace Sign");
	AddMenuItem(g_hPoseMenu, "16", "Set Particle: Circling Heart");
	AddMenuItem(g_hPoseMenu, "17", "Set Particle: Stormy Storm");
	AddMenuItem(g_hPoseMenu, "18", "Set Particle: Blizzardy Storm");
	AddMenuItem(g_hPoseMenu, "19", "Set Particle: Nuts n' Bolts");
	AddMenuItem(g_hPoseMenu, "20", "Set Particle: Orbiting Planets");
	AddMenuItem(g_hPoseMenu, "21", "Set Particle: Orbiting Fire");
	AddMenuItem(g_hPoseMenu, "22", "Set Particle: Bubbling");
	AddMenuItem(g_hPoseMenu, "23", "Set Particle: Smoking");
	AddMenuItem(g_hPoseMenu, "24", "Set Particle: Steaming");
	AddMenuItem(g_hPoseMenu, "25", "Set Particle: Flaming Lantern");
	AddMenuItem(g_hPoseMenu, "26", "Set Particle: Cloudy Moon");
	AddMenuItem(g_hPoseMenu, "27", "Set Particle: Cauldron Bubbles");
	AddMenuItem(g_hPoseMenu, "28", "Set Particle: Eerie Orbiting Fire");
	AddMenuItem(g_hPoseMenu, "29", "Set Particle: Knifestorm");
	AddMenuItem(g_hPoseMenu, "30", "Set Particle: Misty Skull");
	AddMenuItem(g_hPoseMenu, "31", "Set Particle: Harvest Moon");
	AddMenuItem(g_hPoseMenu, "32", "Set Particle: It's A Secret To Everybody");
	AddMenuItem(g_hPoseMenu, "33", "Set Particle: Stormy 13th Hour");
	AddMenuItem(g_hPoseMenu, "34", "Set Particle: Aces High Blue");
	AddMenuItem(g_hPoseMenu, "35", "Set Particle: Aces High Red");
	AddMenuItem(g_hPoseMenu, "36", "Set Particle: Kill-a-Watt");
	AddMenuItem(g_hPoseMenu, "37", "Set Particle: Terror-Watt");
	AddMenuItem(g_hPoseMenu, "38", "Set Particle: Cloud 9");
	AddMenuItem(g_hPoseMenu, "39", "Set Particle: Dead Presidents");
	AddMenuItem(g_hPoseMenu, "40", "Set Particle: Miami Nights");
	AddMenuItem(g_hPoseMenu, "41", "Set Particle: Disco Beat Down");
	AddMenuItem(g_hPoseMenu, "42", "Set Particle: Phosphorous");
	AddMenuItem(g_hPoseMenu, "43", "Set Particle: Sulphurous");
	AddMenuItem(g_hPoseMenu, "44", "Set Particle: Memory Leak");
	AddMenuItem(g_hPoseMenu, "45", "Set Particle: Overclocked");
	AddMenuItem(g_hPoseMenu, "46", "Set Particle: Electrostatic");
	AddMenuItem(g_hPoseMenu, "47", "Set Particle: Power Surge");
	AddMenuItem(g_hPoseMenu, "48", "Set Particle: Anti-Freeze");
	AddMenuItem(g_hPoseMenu, "49", "Set Particle: Time Warp");
	AddMenuItem(g_hPoseMenu, "50", "Set Particle: Green Black Hole");
	AddMenuItem(g_hPoseMenu, "51", "Set Particle: Roboactive");
}

public Action:OnValvesHatedCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_unusualmenu_access", ADMFLAG_CUSTOM6))
	{
		ReplyToCommand(client, "[SM] You don't have acces to this command.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "Cannot use command from RCON.");
		return Plugin_Handled;
	}
	DisplayMenuSafely(g_hPoseMenu, client);
	return Plugin_Handled;
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		switch (param2)
		{
			case 0:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_RemoveAll(iEnt);
				ReplyToCommand(param1, "Removed the unusual effect from your hat, Your hat was destroyed in the process :c #ItHadToBeDone");
				AcceptEntityInput(iEnt, "Kill");
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 1:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 4.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 2:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 6.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 3:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 7.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 4:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 8.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 5:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 9.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 6:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 10.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 7:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 11.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 8:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 12.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 9:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 13.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 10:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 14.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 11:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 15.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 12:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 16.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 13:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 17.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 14:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 18.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 15:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 19.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 16:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 29.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 17:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 30.0);
				TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 18:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 31.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 19:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 32.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 20:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 33.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 21:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 34.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 22:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 35.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 23:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 36.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 24:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 37.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 25:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 38.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 26:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 39.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 27:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 40.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 28:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 43.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 29:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 44.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 30:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 45.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 31:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 46.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 32:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 47.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 33:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 55.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 34:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 59.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 35:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 56.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 36:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 57.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 38:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 58.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 39:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 60.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 40:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 61.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 41:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 62.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 42:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 63.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 43:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 64.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 44:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 65.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 45:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 66.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 46:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 67.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 47:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 68.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 48:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 69.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 49:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 70.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 50:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 71.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 51:
            {
				new iEnt = FindClientHatEntity(param1);
				TF2Attrib_SetByName(iEnt, "attach particle effect", 72.0);
			//	TF2Attrib_SetByName(iEnt, "particle effect use head origin", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
		}
	}
}

stock FindClientHatEntity(client) 
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != -1) 
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client && TF2II_GetItemSlot(GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex"), TF2_GetPlayerClass(client)) == TF2ItemSlot_Hat) 
		{
			return iEnt;
		}
	}
	return 0;
}  

stock DisplayMenuSafely(Handle:menu, client)
{
    if (client != 0)
    {
        if (menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Unusual Effects Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}

public OnMapEnd()
{
    if (g_hPoseMenu != INVALID_HANDLE)
    {
        CloseHandle(g_hPoseMenu);
        g_hPoseMenu = INVALID_HANDLE;
    }
}  