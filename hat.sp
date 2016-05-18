#include <tf2items>
#include <equipwearable>
#include <tf2itemsinfo>

public OnPluginStart()
{
	RegAdminCmd("sm_givemehat", Command_GiveHat, ADMFLAG_ROOT);
}

public Action:Command_GiveHat(client, args)
{
	if(IsValidClient(client))
	{
		decl String:arg1[16], String:arg2[16], String:arg3[16], String:arg4[16];
		GetCmdArg(2, arg1, sizeof(arg1));
		GetCmdArg(3, arg2, sizeof(arg2));
		GetCmdArg(4, arg3, sizeof(arg3));
		GetCmdArg(5, arg4, sizeof(arg4));
		new iIndex = StringToInt(arg1);
		new iQuality = StringToInt(arg2);
		new iLevel = StringToInt(arg3);
		new Float:fEffectID = StringToFloat(arg4);
	
		if (args < 1) 
		{
			ReplyToCommand(client, "[GiveHat] Usage: sm_givemehat <client> <index> <quality> <level> <effectid>");
			ReplyToCommand(client, "Qualities:\n Normal 0\nGenuine 1\nVintage 3\nUnique 6\nCommunity 7\nValve 8\nSelfmade 9\nCustomized10\nStrange 11\nCompleted 12\nHaunted 13\nCollectors 14");
			return Plugin_Handled;
		}

		decl String:szTarget[65];
		GetCmdArg(1, szTarget, sizeof(szTarget));

		decl String:szTargetName[MAX_TARGET_LENGTH+1];
		decl iTargetList[MAXPLAYERS+1], iTargetCount, bool:bTnIsMl;

		if ((iTargetCount = ProcessTargetString
		(
				szTarget,
				client,
				iTargetList,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				szTargetName,
				sizeof(szTargetName),
				bTnIsMl)) <= 0)
		{
			ReplyToTargetError(client, iTargetCount);
			return Plugin_Handled;
		}

		for (new i = 0; i < iTargetCount; i++)
		{
			if(IsValidClient(iTargetList[i]))
				TF2_PlayerGiveWearable(iTargetList[i], iIndex, iQuality, iLevel, fEffectID);
		}
	}
	return Plugin_Handled;
}

stock TF2_PlayerGiveWearable(iClient, iItemIndex, iQuality = 9, iLevel = 0, Float:fEffectID = 0.0) 
{
	new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL || FORCE_GENERATION);
	TF2Items_SetClassname(hItem, "tf_wearable");
	TF2Items_SetItemIndex(hItem, 0);
	TF2Items_SetQuality(hItem, iQuality);
	TF2Items_SetLevel(hItem, iLevel);
	if(fEffectID == 0.0)
	{
		TF2Items_SetNumAttributes(hItem, 0);
	}
	else
	{
		TF2Items_SetAttribute(hItem, 0, 134, fEffectID);
		TF2Items_SetNumAttributes(hItem, 1);
	}

	new iEntity = TF2Items_GiveNamedItem(iClient, hItem);
	if(IsWearable(iEntity))
	{
		SetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex", iItemIndex);
		EquipPlayerWearable(iClient, iEntity);
	}
	else
		AcceptEntityInput(iEntity, "Kill");
	CloseHandle(hItem);
	
	return iEntity;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}