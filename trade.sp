public OnPluginStart() 
{
    RegConsoleCmd("sm_trade", Command_Trade);
	
	LoadTranslations("common.phrases");
}

public Action:Command_Trade(client, args)
{
	if (args > 0) 
	{
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

		if(iTargetCount > 1)
		{
			ReplyToCommand(client, "[Fast Trade] More than 1 client matched name");
			return Plugin_Handled;
		}
		else
		{
			for (new i = 0; i < iTargetCount; i++)
			{
				ShowTradeMenu(client, iTargetList[i]);
			}
		}
	} 
	else 
		TradeMenu(client);
	
	return Plugin_Handled;
}

public TradeMenu(client)
{
	new Handle:menu2 = CreateMenu(Menu_Tele);
	SetMenuTitle(menu2, "Trade", client);
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(IsFakeClient(i)) continue;
		if(client == i) continue;
		decl String:info[8], String:display[32];
		Format(info, sizeof(info), "%i", i);
		Format(display, sizeof(display), "%N", i);
		AddMenuItem(menu2, info, display);
	}
	SetMenuExitButton(menu2, true);
	DisplayMenu(menu2, client, 60);
}

public Menu_Tele(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:idStr[8];
		GetMenuItem(menu, option, idStr, sizeof(idStr));
		new target = StringToInt(idStr);
		
		ShowTradeMenu(client, target);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowTradeMenu(iClient, target) 
{
	if (iClient && IsClientConnected(iClient)) 
	{
		new Handle:hKV = CreateKeyValues("menu");
		KvSetString(hKV, "title", "Trade menu, hit ESC");
		KvSetNum(hKV, "level", 1);
		KvSetColor(hKV, "color", 128, 255, 0, 255);
		KvSetNum(hKV, "time", 20);
        
		decl String:szBuffer[192];
		Format(szBuffer, sizeof(szBuffer), "Trade Menu \nYou'll be trading: \"%N\"", target);
		KvSetString(hKV, "msg", szBuffer);
        
		KvSavePosition(hKV);

		KvJumpToKey(hKV, "1", true);
		KvSetString(hKV, "msg", "Press me to Trade!");
		Format(szBuffer, sizeof(szBuffer), "cl_trade \"%N\"", target);
		KvSetString(hKV, "command", szBuffer);

		CreateDialog(iClient, hKV, DialogType_Menu);
		if(hKV != INVALID_HANDLE)
		{
			CloseHandle(hKV);
			hKV = INVALID_HANDLE;
		}
	}
}