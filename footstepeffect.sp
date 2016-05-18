#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <tf2attributes>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name        =    "[TF2] Footsteps",
	author        =    "Pelipoika",
	description    =    "Give yourself a footstep effect!",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_footstep", OnPoserCmd, ADMFLAG_CUSTOM6, "misc Resizer Menu.");
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
	SetMenuTitle(g_hPoseMenu, "-- Footstep Effects --");
	AddMenuItem(g_hPoseMenu, "1", "Halloween Spell: Team Spirit Footprints");
	AddMenuItem(g_hPoseMenu, "2", "Halloween Spell: Gangreen Footprints");
	AddMenuItem(g_hPoseMenu, "3", "Halloween Spell: Corpse Gray Footprints");
	AddMenuItem(g_hPoseMenu, "4", "Halloween Spell: Violent Violet Footprints");
	AddMenuItem(g_hPoseMenu, "5", "Halloween Spell: Bruised Purple Footprints");
	AddMenuItem(g_hPoseMenu, "6", "Halloween Spell: Headless Horseshoes");
	AddMenuItem(g_hPoseMenu, "7", "Halloween Spell: Rotten Orange Footprints");
	AddMenuItem(g_hPoseMenu, "8", "Halloween Spell: None");
}

public Action:OnPoserCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_footeffect_access", ADMFLAG_CUSTOM6))
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
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 14540032.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 1:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 39168.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 2:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 3100495.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 3:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 16742399.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 4:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 2490623.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 5:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 2.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 6:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 16737280.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 7:
            {
				TF2Attrib_SetByName(param1, "SPELL: set Halloween footstep type", 0.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
		}
	}
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if (client != 0)
    {
        if (menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Misc Resizer Menu.");
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