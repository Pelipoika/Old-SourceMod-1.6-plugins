#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2items>
#include <tf2itemsinfo>

#define MAXWEARABLES 32

/* Requirements:
	TF2Items
	TF2ItemsInfo
	gamedata/tf2items.randomizer.txt
*/

public Plugin:myinfo = 
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = "",
}

enum playerWearable 
{
	bool:m_bValid,
	m_iItemIndex,
	m_iQuality,
	m_iLevel,
	m_iUnusualEffect,
	m_iPaintColor,
	m_iEntity
}

//new g_rgnShouldClientReconnect[MAXPLAYERS+1];
new g_rgPlayerWearables[MAXPLAYERS+1][MAXWEARABLES][playerWearable];

// Unusual Effect Attribute: 134
// Paint Attributes: 142, 261
// Halloween Attributes: 1004

new Handle:g_hSdkEquipWearable = INVALID_HANDLE;

public OnPluginStart() 
{
	new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSdkEquipWearable = EndPrepSDKCall();
	if (g_hSdkEquipWearable == INVALID_HANDLE) SetFailState("Ohoh! Something went horribly wrong here!");

	RegConsoleCmd("sm_equipwearable", cmdEquipWearable, "Equip a Wearable");
	RegConsoleCmd("sm_listwearables", cmdListWearables, "List Wearables You're Wearing");
	RegConsoleCmd("sm_removewearable", cmdRemoveWearable, "Remove a Wearable");
//	RegConsoleCmd("sm_rec", cmdForceReconnect, "");
	HookEvent("post_inventory_application", eventPostInventoryApplication);
}

public Action:cmdRemoveWearable(iClient, nArgs) 
{
	if (nArgs < 1) return Plugin_Handled;
	new String:szBuffer[64];
	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	new iSlot = StringToInt(szBuffer);
	if (g_rgPlayerWearables[iClient][iSlot][m_bValid] == true) 
	{
		g_rgPlayerWearables[iClient][iSlot][m_bValid] = false;
		new iEntity = g_rgPlayerWearables[iClient][iSlot][m_iEntity];
		if (IsValidEntity(iEntity)) AcceptEntityInput(iEntity, "Kill");
	}
	
	return Plugin_Handled;
}

public Action:cmdListWearables(iClient, nArgs) 
{
	new iItemIndex, iLevel, iUnusualEffect, iQuality;
	for (new i=0; i<32; i++) 
	{
		if (g_rgPlayerWearables[iClient][i][m_bValid] == true) 
		{
			iItemIndex = g_rgPlayerWearables[iClient][i][m_iItemIndex];
			iLevel = g_rgPlayerWearables[iClient][i][m_iLevel];
			iQuality = g_rgPlayerWearables[iClient][i][m_iQuality];
			iUnusualEffect = g_rgPlayerWearables[iClient][i][m_iUnusualEffect];

			new String:szItemName[64], String:szItemQuality[64];
			TF2II_GetItemName(iItemIndex, szItemName, sizeof(szItemName));
			TF2II_GetQualityName(iQuality, szItemQuality, sizeof(szItemQuality));

			ReplyToCommand(iClient, "Slot %d: %s %s with level %d and particle %d.", i, szItemQuality, szItemName, iLevel, iUnusualEffect);
		}
	}
	return Plugin_Handled;
}

/*public Action:cmdForceReconnect(iClient, nArgs) 
{
	if (nArgs < 1) return Plugin_Handled;
	new String:szBuffer[64];
	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	new iClient = StringToInt(szBuffer);
	if (IsClientConnected(iClient)) {ClientCommand(iClient, "retry");}

	return Plugin_Handled;
}*/

public Action:cmdEquipWearable(iClient, nArgs) 
{
	if(!(GetUserFlagBits(iClient) & ADMFLAG_ROOT))
	{
		ReplyToCommand(iClient, "\x01You Don't Have Acces to Use this Command.");
		return Plugin_Handled;
	}
	if(iClient<1||!IsClientInGame(iClient)||!IsPlayerAlive(iClient))
    {
		ReplyToCommand(iClient, "\x04[SM] \x05You need to be alive to use this command");
		return Plugin_Handled;
    }
	new String:szBuffer[64];
	new iItemIndex, iQuality, iLevel;
	new iUnusualEffect, iPaintColor, iSlot;
	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	iItemIndex = StringToInt(szBuffer);
	GetCmdArg(2, szBuffer, sizeof(szBuffer));
	iQuality = StringToInt(szBuffer);
	GetCmdArg(3, szBuffer, sizeof(szBuffer));
	iLevel = StringToInt(szBuffer);
	GetCmdArg(4, szBuffer, sizeof(szBuffer));
	iUnusualEffect = StringToInt(szBuffer);
	GetCmdArg(5, szBuffer, sizeof(szBuffer));
	iPaintColor = StringToInt(szBuffer, 16);
	if (nArgs > 5) 
	{
		GetCmdArg(6, szBuffer, sizeof(szBuffer));
		iSlot = StringToInt(szBuffer);
	} 
	else iSlot = -1;

	PlayerGiveWearable(iClient, iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor, iSlot);

	return Plugin_Handled;
}

public Action:eventPostInventoryApplication(Handle:hEvent, const String:szName[], bool:bDontBroadcast) 
{
	new iUserID = GetEventInt(hEvent, "userid");
	new iClient = GetClientOfUserId(iUserID);
	
	for (new i=0; i<MAXWEARABLES; i++) 
	{
		if (g_rgPlayerWearables[iClient][i][m_bValid] == true) 
		{
			new iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor;
			iItemIndex = g_rgPlayerWearables[iClient][i][m_iItemIndex];
			iQuality = g_rgPlayerWearables[iClient][i][m_iQuality];
			iLevel = g_rgPlayerWearables[iClient][i][m_iLevel];
			iUnusualEffect = g_rgPlayerWearables[iClient][i][m_iUnusualEffect];
			iPaintColor = g_rgPlayerWearables[iClient][i][m_iPaintColor];

			g_rgPlayerWearables[iClient][i][m_iEntity] = TF2_PlayerGiveWearable(iClient, iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor);
		}
	}
//	return Plugin_Handled;
}

//public Action:eventPlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast) 
//{

//}

stock PlayerGiveWearable(iClient, iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor, iSlot=-1) 
{
	if (iSlot == -1) 
	{
		iSlot = GetWearableAvailableSlot(iClient);
		if (iSlot == -1) return -1;
	} 
	else if (g_rgPlayerWearables[iClient][iSlot][m_bValid] == true) 
	{
		new iEntityOld = g_rgPlayerWearables[iClient][iSlot][m_iEntity];
		if (IsValidEntity(iEntityOld)) AcceptEntityInput(iEntityOld, "Kill");
	}
	new iEntity = TF2_PlayerGiveWearable(iClient, iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor);
	MakeWearablePersistent(iClient, iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor, iEntity, iSlot);

	return 0;
}

stock MakeWearablePersistent(iClient, iItemIndex, iQuality, iLevel, iUnusualEffect, iPaintColor, iEntity, iSlot=-1) 
{
	g_rgPlayerWearables[iClient][iSlot][m_bValid] = true;
	g_rgPlayerWearables[iClient][iSlot][m_iItemIndex] = iItemIndex;
	g_rgPlayerWearables[iClient][iSlot][m_iQuality] = iQuality;
	g_rgPlayerWearables[iClient][iSlot][m_iLevel] = iLevel;
	g_rgPlayerWearables[iClient][iSlot][m_iUnusualEffect] = iUnusualEffect;
	g_rgPlayerWearables[iClient][iSlot][m_iPaintColor] = iPaintColor;
	g_rgPlayerWearables[iClient][iSlot][m_iEntity] = iEntity;

	return iSlot;
}

stock GetWearableAvailableSlot(iClient) 
{
	new iSlot = -1;
	do 
	{
		iSlot++;
	} 
	while (g_rgPlayerWearables[iClient][iSlot][m_bValid] == true && iSlot < MAXWEARABLES-1);

	if (g_rgPlayerWearables[iClient][iSlot][m_bValid] == true) return -1; else return iSlot;
}


stock TF2_PlayerGiveWearable(iClient, iItemIndex, iQuality=9, iLevel=0, iUnusualEffect=-1, iPaintColor=-1) 
{
	new String:szBuffer[64];
	new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
	TF2Items_SetClassname(hItem, "tf_wearable");
	TF2Items_SetItemIndex(hItem, 0);
	TF2Items_SetQuality(hItem, iQuality);
	TF2Items_SetLevel(hItem, iLevel);
	TF2Items_SetNumAttributes(hItem, 0);
	if (iUnusualEffect != -1) 
	{
		TF2Items_SetNumAttributes(hItem, 1);
		TF2Items_SetAttribute(hItem, 0, 134, iUnusualEffect);
	}
	
	if (iPaintColor != -1) 
	{
		IntToString(iPaintColor, szBuffer, sizeof(szBuffer));
		new Float:flPaintColor = StringToFloat(szBuffer);
		TF2Items_SetNumAttributes(hItem, TF2Items_GetNumAttributes(hItem) + 2);
		TF2Items_SetAttribute(hItem, TF2Items_GetNumAttributes(hItem) - 2, 261, flPaintColor);
		TF2Items_SetAttribute(hItem, TF2Items_GetNumAttributes(hItem) - 1, 142, flPaintColor);
	}

	new iEntity = TF2Items_GiveNamedItem(iClient, hItem);
	SetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex", iItemIndex);
	for (new i=1; i<MaxClients;i++) 
	{
		if (IsClientConnected(i)) 
		{
		/*	for (new ii=0; ii<MAXWEARABLES; ii++) 
		{
				if (g_rgPlayerWearables[i][ii][m_bValid] == true) 
				{

				}
			}
		}*/
			TF2_EquipWearable(i, iEntity);
		}
	}
	TF2_EquipWearable(iClient, iEntity);
	CloseHandle(hItem);
	//ChangeEdictState(iEntity);
	return iEntity;
}

/*stock PlayerRemoveWearable(iClient, iSlot) 
{

}*/

stock TF2_EquipWearable(client, entity) 
{
	if (g_hSdkEquipWearable != INVALID_HANDLE)
		SDKCall(g_hSdkEquipWearable, client, entity);
}