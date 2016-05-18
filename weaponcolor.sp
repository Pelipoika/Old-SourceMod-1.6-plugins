#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <colors>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name        =    "WeaponColoriser",
	author        =    "Pelipoika",
	description    =    "Color your weapons!",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_colorweapon", OnPoserCmd, ADMFLAG_CUSTOM6, "Weapon Resizer Menu.");
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
	SetMenuTitle(g_hPoseMenu, "Weapon Coloriser Menu");
	AddMenuItem(g_hPoseMenu, "1", "Ruby Red");
	AddMenuItem(g_hPoseMenu, "2", "Grimy Green");
	AddMenuItem(g_hPoseMenu, "3", "Beautiful Blue");
	AddMenuItem(g_hPoseMenu, "4", "Youthful Yellow");
	AddMenuItem(g_hPoseMenu, "5", "Pretty Pink");
	AddMenuItem(g_hPoseMenu, "6", "Bitter Black");
	AddMenuItem(g_hPoseMenu, "7", "Wash Paint Off");
}

public Action:OnPoserCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_weaponcolor_access", ADMFLAG_CUSTOM6))
	{
		ReplyToCommand(client, "[SM] You don't have acces to this command.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Cannot use command from RCON.");
		return Plugin_Handled;
	}
	DisplayMenuSafely(g_hPoseMenu, client);
	return Plugin_Handled;
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		PaintPlayerWeapon(param1, param2);
		DisplayMenuSafely(g_hPoseMenu, param1);
	}
}

stock PaintPlayerWeapon(client, color)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new red_color[7] = {255, 0, 0, 255, 255, 0, 255};
	new green_color[7] = {0, 255, 0, 255, 0, 0, 255};
	new blue_color[7] = {0, 0, 255, 0, 255, 0, 255};
	SetEntityRenderColor(weapon, red_color[color], green_color[color], blue_color[color], 255);
	CPrintToChatEx(client, client, "{teamcolor}Your weapon should now look more FABULOUS than ever!");
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if (client != 0)
    {
        if (menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Weapon Color Menu.");
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