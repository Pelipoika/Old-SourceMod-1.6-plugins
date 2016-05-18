#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <morecolors>
#pragma semicolon 1

#define SOUND_SUCCESS	"ui/trade_success.wav"
#define SOUND_FAIL		"ui/trade_failure.wav"
#define SOUND_CHANGED 	"ui/trade_changed.wav"

new tradeTarget[MAXPLAYERS+1];
new tradeCoins[MAXPLAYERS+1];
new bool:trading[MAXPLAYERS+1];
new bool:ready[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_trade", Command_Trade);
}

public OnMapStart()
{
	PrecacheSound(SOUND_SUCCESS);
	PrecacheSound(SOUND_FAIL);
	PrecacheSound(SOUND_CHANGED);}

public Action:Command_Trade(client, args)
{
	new Handle:menu = CreateMenu(Menu_Player);
	SetMenuTitle(menu, "Who do you want to trade with?");
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(i == client) continue;
		if(IsFakeClient(i)) continue;
		
		decl String:info[8], String:display[64];
		Format(info, sizeof(info), "%i", i);
		Format(display, sizeof(display), "%N", i);
		AddMenuItem(menu, info, display);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	
	return Plugin_Handled;
}

public Menu_Player(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:strTemp[8];
		GetMenuItem(menu, option, strTemp, sizeof(strTemp));
		tradeTarget[client] = StringToInt(strTemp);
		
		if(trading[tradeTarget[client]])
		{
			PrintToChat(client, "%N is already in a trading with someone.", tradeTarget[client]);
			return;
		}
		
		tradeTarget[tradeTarget[client]] = client;
		trading[client] = trading[tradeTarget[client]] = true;
		tradeCoins[client] = tradeCoins[tradeTarget[client]] = 0;
		ready[client] = ready[tradeTarget[client]] = false;
		
		new Handle:menu2 = CreateMenu(Menu_Request);
		SetMenuTitle(menu2, "%N wants to trade with you.", client);
		AddMenuItem(menu2, "1", "Accept");
		AddMenuItem(menu2, "2", "Decline");
		SetMenuExitButton(menu2, false);
		DisplayMenu(menu2, tradeTarget[client], 60);
		PrintToChat(client, "Your trade request has been sent.");
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Menu_Request(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{			
			TradeMenu(client);
			TradeMenu(tradeTarget[client]);
		}
		else
		{
			EndTrade(client);
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	else EndTrade(client);
}

public Menu_Item(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(TradingCoins(tradeTarget[client]))
		{
			PrintToChat(client, "%N is already trading you Fraglets.", tradeTarget[client]);
			TradeMenu(client);
			return;
		}
		
		decl String:strTemp[8], String:slotData[2][8];
		GetMenuItem(menu, option, strTemp, sizeof(strTemp));
		ExplodeString(strTemp, ":", slotData, 2, 8);
		
		new Handle:menu2 = CreateMenu(Menu_Coins);
		SetMenuTitle(menu2, "How many Fraglets would you like to trade?");
		for(new i=10; i<=User_GetCoins(client); i+=10)
		{
			decl String:amountStr[8];
			Format(amountStr, sizeof(amountStr), "%i", i);
			AddMenuItem(menu2, amountStr, amountStr);
		}
		SetMenuExitButton(menu2, true);
		DisplayMenu(menu2, client, 60);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	else EndTrade(client);
}

public Menu_Coins(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:strTemp[8];
		GetMenuItem(menu, option, strTemp, sizeof(strTemp));
		tradeCoins[client] = StringToInt(strTemp);
		
		if(ReadyToTrade(tradeTarget[client]))
		{
			new Handle:menu2 = CreateMenu(Menu_ConfirmCoins);
			SetMenuTitle(menu2, "Confirm trading %i Fraglets for %N's %s.", tradeCoins[client], tradeTarget[client]);
			AddMenuItem(menu2, "1", "Confirm");
			AddMenuItem(menu2, "2", "Decline");
			SetMenuExitButton(menu2, true);
			DisplayMenu(menu2, client, 60);
			SetMenuTitle(menu2, "Confirm trading your %s for %N's %i coins.", client, tradeCoins[client]);
			DisplayMenu(menu2, tradeTarget[client], 60);
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	else EndTrade(client);
}

public Menu_ConfirmCoins(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{	
			
			if(TradingCoins(client))
			{
				User_GiveCoins(tradeTarget[client], tradeCoins[client], COINDISPLAY_NONE);
				User_GiveCoins(client, -tradeCoins[client], COINDISPLAY_NONE);
				CPrintToChatAllEx(tradeTarget[client], "{teamcolor}%N{default} traded for: {olive}%i coins", tradeTarget[client], tradeCoins[client]);
			}
			else if(TradingCoins(tradeTarget[client]))
			{
				User_GiveCoins(tradeTarget[client], -tradeCoins[tradeTarget[client]], COINDISPLAY_NONE);
				User_GiveCoins(client, tradeCoins[tradeTarget[client]], COINDISPLAY_NONE);
				CPrintToChatAllEx(client, "{teamcolor}%N{default} traded for: {olive}%i coins", client, tradeCoins[tradeTarget[client]]);
			}
		}
		else
		{
			EndTrade(client);
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	else EndTrade(client);
}

public TradeMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Item);
	SetMenuTitle(menu, "What do you want to trade?");
	AddMenuItem(menu, "-1", "Fraglets");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public FinishTrade(client)
{
	EmitSoundToClient(client, SOUND_SUCCESS);
	EmitSoundToClient(tradeTarget[client], SOUND_SUCCESS);
	trading[client] = trading[tradeTarget[client]] = false;
	tradeCoins[client] = tradeCoins[tradeTarget[client]] = 0;
}

public EndTrade(client)
{
	tradeCoins[client] = tradeCoins[tradeTarget[client]] = 0;
	
	PrintToChat(client, "You ended the trade.");
	PrintToChat(tradeTarget[client], "%N ended the trade.", client);
	
	EmitSoundToClient(client, SOUND_FAIL);
	EmitSoundToClient(tradeTarget[client], SOUND_FAIL);
	
	trading[client] = trading[tradeTarget[client]] = false;
	ready[client] = ready[tradeTarget[client]] = false;
}

public bool:TradingCoins(client)
{
	if(tradeCoins[client] == -1)
		return true;
	return false;
}

public bool:ReadyToTrade(client)
{
	if(tradeCoins[client] != 0)
		return true;
	return false;
}