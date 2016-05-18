#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#define PLUGIN_VERSION "1.2.0"

public Plugin:myinfo =
{
	name        =    "WeaponResizer",
	author        =    "Pelipoika",
	description    =    "Resize your weapons!",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_resizeweapon", OnPoserCmd, ADMFLAG_CUSTOM6, "Weapon Resizer Menu.");
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
	SetMenuTitle(g_hPoseMenu, "Weapon Resizer Menu");
	AddMenuItem(g_hPoseMenu, "1", "Weapon Size 1.0x");
	AddMenuItem(g_hPoseMenu, "2", "Weapon Size 1.3x");
	AddMenuItem(g_hPoseMenu, "3", "Weapon Size 1.5x");
	AddMenuItem(g_hPoseMenu, "4", "Weapon Size 2.0x");
	AddMenuItem(g_hPoseMenu, "5", "Weapon Size 2.5x");
	AddMenuItem(g_hPoseMenu, "6", "Weapon Size 3.0x");
	AddMenuItem(g_hPoseMenu, "7", "Weapon Size 0.5x");
	//PG 2
	AddMenuItem(g_hPoseMenu, "8", "Weapon Size -1.0x");
	AddMenuItem(g_hPoseMenu, "9", "Weapon Size -1.3x");
	AddMenuItem(g_hPoseMenu, "10", "Weapon Size -1.5x");
	AddMenuItem(g_hPoseMenu, "11", "Weapon Size -2.0x");
	AddMenuItem(g_hPoseMenu, "12", "Weapon Size -2.5x");
	AddMenuItem(g_hPoseMenu, "13", "Weapon Size -3.0x");
	AddMenuItem(g_hPoseMenu, "14", "Weapon Size -0.5x");
}

public Action:OnPoserCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_weaponresize_access", ADMFLAG_CUSTOM6))
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
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 1.0);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 1:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 1.3);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 2:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 1.5);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
			}
            case 3:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 2.0);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 4:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 2.5);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 5:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 3.0);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 6:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.5);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			//END OF PAGE 1
			case 7:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -1.0);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 8:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -1.3);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 9:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -1.5);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
			}
            case 10:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -2.0);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 11:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -2.5);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 12:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -3.0);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 13:
            {
				new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", -0.5);
					DisplayMenuSafely(g_hPoseMenu, param1);
				}
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
            PrintToConsole(client, "ERROR: Unable to open Weapon Resizer Menu.");
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