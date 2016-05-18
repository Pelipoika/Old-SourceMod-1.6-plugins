#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hPowerupMenu = INVALID_HANDLE;
new Handle:g_hChargesMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_canteen", OnCanteenCmd, ADMFLAG_ROOT, "Canteen Powerups Menu.");
}

public OnConfigsExecuted()
{
	g_hPowerupMenu = CreateMenu(MenuPowerupHandler);
	SetMenuTitle(g_hPowerupMenu, "-- Select your Canteen Powerup --");
	AddMenuItem(g_hPowerupMenu, "1", "[69   Fraglets] Powerup: Recall");
	AddMenuItem(g_hPowerupMenu, "2", "[750  Fraglets] Powerup: Ubercharge");
	AddMenuItem(g_hPowerupMenu, "3", "[1000 Fraglets] Powerup: Critboost");
	AddMenuItem(g_hPowerupMenu, "4", "[500  Fraglets] Powerup: Building instant upgrade");
	AddMenuItem(g_hPowerupMenu, "5", "[150  Fraglets] Powerup: Refill ammo");
	
	g_hChargesMenu = CreateMenu(MenuChargesHandler);
	SetMenuTitle(g_hChargesMenu, "-- Select amount of Charges (Fraglet cost adds up!)--");
	AddMenuItem(g_hChargesMenu, "1", "Charges: 1 [No extra cost]");
	AddMenuItem(g_hChargesMenu, "2", "Charges: 2 [2x The price of what you bought]");
	AddMenuItem(g_hChargesMenu, "3", "Charges: 3 [3x The price of what you bought]");
}

public Action:OnCanteenCmd(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "Cannot use command from RCON.");
		return Plugin_Handled;
	}
	
	new bottle = FindBottle(client);
	if (bottle == -1)
	{
		PrintToChat(client, "Please equip your bottle");
		return Plugin_Handled;
	}
	
	DisplayMenuSafely(g_hPowerupMenu, client);
	return Plugin_Handled;
}

public MenuPowerupHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new bottle = FindBottle(param1);
		if (bottle != -1)
		{
			switch (param2)
			{
				case 0:
				{
					TF2Attrib_SetByName(bottle, "recall", 1.0);
					DisplayMenuSafely(g_hChargesMenu, param1);
				}
				case 1:
				{
					TF2Attrib_SetByName(bottle, "ubercharge", 1.0);
					DisplayMenuSafely(g_hChargesMenu, param1);
				}
				case 2:
				{
					TF2Attrib_SetByName(bottle, "critboost", 1.0);
					DisplayMenuSafely(g_hChargesMenu, param1);
				}
				case 3:
				{
					TF2Attrib_SetByName(bottle, "building instant upgrade", 1.0);
					DisplayMenuSafely(g_hChargesMenu, param1);
				}
				case 4:
				{
					TF2Attrib_SetByName(bottle, "refill_ammo", 1.0);
					DisplayMenuSafely(g_hChargesMenu, param1);
				}
			}
		}
		else
			PrintToChat(param1, "Please, equip your Powerup Canteen!");
	}
}

public MenuChargesHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new bottle = FindBottle(param1);
		if (bottle != -1)
		{
			switch (param2)
			{
				case 0:
				{
					SetEntProp(bottle, Prop_Send, "m_usNumCharges", 1);
				}
				case 1:
				{
					SetEntProp(bottle, Prop_Send, "m_usNumCharges", 2);
				}
				case 2:
				{
					SetEntProp(bottle, Prop_Send, "m_usNumCharges", 3);
				}
			}
		}
		else
			PrintToChat(param1, "Gosh darnit lad! Keep your bottle equipt!");
	}
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if (client != 0)
    {
        if (menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Canteen Charges Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}

stock FindBottle(client)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))
		{
			return i;
		}
	}
	return -1;
}

public OnMapEnd()
{
	if(g_hPowerupMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hPowerupMenu);
		g_hPowerupMenu = INVALID_HANDLE;
	}
	if(g_hChargesMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hChargesMenu);
		g_hChargesMenu = INVALID_HANDLE;
	}
}