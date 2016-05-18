#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <tf2itemsinfo>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name        =    "HatResizer",
	author        =    "Pelipoika",
	description    =    "Resize your Hat!",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_resizehat", OnPoserCmd, ADMFLAG_CUSTOM6, "Hat Resizer Menu.");
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
	SetMenuTitle(g_hPoseMenu, "Hat Resizer Menu");
	AddMenuItem(g_hPoseMenu, "1", "Hat Size 1.0x");
	AddMenuItem(g_hPoseMenu, "2", "Hat Size 1.3x");
	AddMenuItem(g_hPoseMenu, "3", "Hat Size 1.5x");
	AddMenuItem(g_hPoseMenu, "4", "Hat Size 2.0x");
	AddMenuItem(g_hPoseMenu, "5", "Hat Size 2.5x");
	AddMenuItem(g_hPoseMenu, "6", "Hat Size 3.0x");
	AddMenuItem(g_hPoseMenu, "7", "Hat Size 0.5x");
	//PG 2
	AddMenuItem(g_hPoseMenu, "8", "Hat Size -1.0x");
	AddMenuItem(g_hPoseMenu, "9", "Hat Size -1.3x");
	AddMenuItem(g_hPoseMenu, "10", "Hat Size -1.5x");
	AddMenuItem(g_hPoseMenu, "11", "Hat Size -2.0x");
	AddMenuItem(g_hPoseMenu, "12", "Hat Size -2.5x");
	AddMenuItem(g_hPoseMenu, "13", "Hat Size -3.0x");
	AddMenuItem(g_hPoseMenu, "14", "Hat Size -0.5x");
}

public Action:OnPoserCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_hatresize_access", ADMFLAG_CUSTOM6))
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
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 1:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 1.3);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 2:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 1.5);
				DisplayMenuSafely(g_hPoseMenu, param1);
			}
            case 3:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 2.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 4:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 2.5);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 5:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 3.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 6:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", 0.5);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			//END OF PAGE 1
			case 7:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -1.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 8:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -1.3);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 9:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -1.5);
				DisplayMenuSafely(g_hPoseMenu, param1);
			}
            case 10:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -2.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
            case 11:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -2.5);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 12:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -3.0);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
			case 13:
            {
				new Hat = FindClientHatEntity(param1);
				SetEntPropFloat(Hat, Prop_Send, "m_flModelScale", -0.5);
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
		}
	}
}

stock FindClientHatEntity(param1) 
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != -1) 
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == param1 && TF2II_GetItemSlot(GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex"), TF2_GetPlayerClass(param1)) == TF2ItemSlot_Hat) 
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
            PrintToConsole(client, "ERROR: Unable to open Hat Resizer Menu.");
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