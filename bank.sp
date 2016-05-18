#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <gmg\colors>
#include <gmg\core>
#include <gmg\users>

new Handle:g_hBankMenu[MAXPLAYERS+1];

new const String:g_szBankResponses[][][] =
{
	{ // welcome
		"Welcome to the Safecoin Bank, {playername}!",
		"Welcome to the Safecoin Bank!",
		"Hello and welcome to the bank!",
		"Thanks for stopping by, how can we help you today?"
	},
	{ // deposit
		"How many coins would you like to deposit?",
		"Yes, we can help you with that.",
		"How many coins would you like us to store for you?",
		"So you'd like to deposit your coins..."
	},
	{ // withdraw
		"How many coins would you like to withdraw?",
		"Yes, we can help you with that.",
		"How many coins would you like us to give back to you?",
		"So you'd like to withdraw your coins..."
	},
	{ // interest
		"We offer daily interest. Interested?",
		"Would you like to collect today's interest?",
		"Look how many coins you can collect!",
		"You may collect today's coin interest."
	},
	{ // can't withdraw
		"Sorry, but you don't have any stored coins.",
		"You need to have deposited coins to withdraw them.",
		"Unfortunately, you have no coins to withdraw.",
		"You can withdraw coins after you've deposited some."
	}
};

#define RESPONSE_WELCOME 0
#define RESPONSE_DEPOSIT 1
#define RESPONSE_WITHDRAW 2
#define RESPONSE_INTEREST 3
#define RESPONSE_WITHDRAW_FAIL 4

public Plugin:myinfo = 
{
	name = "Bank",
	author = "noodleboy347",
	description = "oh how fun",
	version = "1.0.2",
	url = "http://www.goldenmachinegun.com"
}

public OnPluginStart()
{
	HookEntityOutput("trigger_multiple", "OnStartTouch", StartTouch);
}

public StartTouch(const String:name[], caller, activator, Float:delay)
{
	decl String:entName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", entName, sizeof(entName));
	
	if(StrEqual(entName, "bank"))
	{
		ShowMenu_Main(activator);
		TF2_StunPlayer(activator, 9999.0, _, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
		PrintTellerResponse(activator, RESPONSE_WELCOME);
	}
}

public OnClientPutInServer(client)
{
	g_hBankMenu[client] = INVALID_HANDLE;
}

ShowMenu_Main(client)
{	
	g_hBankMenu[client] = CreateMenu(Menu_Main);
	SetMenuTitle(g_hBankMenu[client], "Safecoin Bank - %i Coins Stored", User_GetBank(client));
	
	AddMenuItem(g_hBankMenu[client], "0", "Deposit Coins");
	AddMenuItem(g_hBankMenu[client], "1", "Withdraw Coins");
	AddMenuItem(g_hBankMenu[client], "2", "Collect Interest");
	AddMenuItem(g_hBankMenu[client], "3", "Get Coin Loan (COMING SOON)", ITEMDRAW_DISABLED);
	AddMenuItem(g_hBankMenu[client], "4", "Information Center");
	DisplayMenu(g_hBankMenu[client], client, 60);
}

public Menu_Main(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0: ShowMenu_Deposit(client);
			case 1: ShowMenu_Widthdraw(client);
			case 2: ShowMenu_Interest(client);
			//case 3: ShowMenu_Loan(client);
			case 4: ShowMenu_Info(client);
			case 5: LeaveBank(client);
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
		LeaveBank(client);
}

ShowMenu_Deposit(client)
{
	g_hBankMenu[client] = CreateMenu(Menu_Deposit);
	SetMenuTitle(g_hBankMenu[client], "How many coins do you want to deposit?");
	
	AddMenuItem(g_hBankMenu[client], "-1", "All Coins");
	for(new i=10; i<=User_GetCoins(client); i+= 10)
	{
		decl String:display[8];
		IntToString(i, display, sizeof(display));
		AddMenuItem(g_hBankMenu[client], display, display);
	}
	
	SetMenuExitButton(g_hBankMenu[client], true);
	DisplayMenu(g_hBankMenu[client], client, 60);
	PrintTellerResponse(client, RESPONSE_DEPOSIT);
}

public Menu_Deposit(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		new amount = option * 10;
		if(amount == 0)
			amount = User_GetCoins(client);
		
		User_GiveCoins(client, -amount, COINDISPLAY_NONE);
		User_SetBank(client, User_GetBank(client) + amount);
		
		decl String:query[255];
		Format(query, sizeof(query), "UPDATE users SET bank = bank + %i WHERE userid = %i", amount, User_GetID(client));
		QuickQuery(query);
		
		PrintToChat(client, "\x01You deposited \x05%i\x01 coins.", amount);
		LogToFile("logs/bank_deposits.txt", "%N deposited %i coins", client, amount);
		ShowMenu_Main(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
}

ShowMenu_Widthdraw(client)
{
	if(User_GetBank(client) == 0)
	{
		PrintTellerResponse(client, RESPONSE_WITHDRAW_FAIL);
		ShowMenu_Main(client);
		return;
	}
	new fee = GetFee(client);
	
	g_hBankMenu[client] = CreateMenu(Menu_Widthdraw);
	SetMenuTitle(g_hBankMenu[client], "How many coins do you want to withdraw? (Fee: %i coins)", fee);
	
	AddMenuItem(g_hBankMenu[client], "-1", "All Coins");
	for(new i=10; i<=User_GetBank(client); i+= 10)
	{
		if(i > User_GetBank(client)) continue;
		
		decl String:display[8];
		IntToString(i, display, sizeof(display));
		AddMenuItem(g_hBankMenu[client], display, display);
	}
	
	SetMenuExitButton(g_hBankMenu[client], true);
	DisplayMenu(g_hBankMenu[client], client, 60);
	PrintTellerResponse(client, RESPONSE_WITHDRAW);
}

public Menu_Widthdraw(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		new amount = (option * 10);
		if(amount == 0)
			amount = User_GetBank(client);
		
		User_GiveCoins(client, amount, COINDISPLAY_NONE);
		User_GiveCoins(client, -GetFee(client), COINDISPLAY_SELF);
		User_SetBank(client, User_GetBank(client) - amount);
		
		decl String:query[255];
		Format(query, sizeof(query), "UPDATE users SET bank = bank - %i WHERE userid = %i", amount, User_GetID(client));
		QuickQuery(query);
		
		PrintToChat(client, "\x01You withdrew \x05%i\x01 coins.", amount);
		LogToFile("logs/bank_deposits.txt", "%N withdrew %i coins", client, amount);
		ShowMenu_Main(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
}

ShowMenu_Interest(client)
{
	g_hBankMenu[client] = CreateMenu(Menu_Interest);
	if(User_CanCollectInterest(client))
	{
		SetMenuTitle(g_hBankMenu[client], "You can collect %i coins in interest.", GetInterest(client));
		AddMenuItem(g_hBankMenu[client], "0", "Collect Interest");
		AddMenuItem(g_hBankMenu[client], "1", "Go Back");
	}
	else
	{
		SetMenuTitle(g_hBankMenu[client], "You have already collected your interest for today.");
		AddMenuItem(g_hBankMenu[client], "0", "Collect Interest", ITEMDRAW_DISABLED);
		AddMenuItem(g_hBankMenu[client], "1", "Go Back");
	}
	
	SetMenuExitButton(g_hBankMenu[client], false);
	DisplayMenu(g_hBankMenu[client], client, 60);
	PrintTellerResponse(client, RESPONSE_INTEREST);
}

public Menu_Interest(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{
			new amount = GetInterest(client);
			User_GiveCoins(client, amount, COINDISPLAY_NONE);
			PrintToChat(client, "\x01You collected \x05%i\x01 coins in interest.", amount);
			LogToFile("logs/interest.txt", "%L collected interest of %i", client, amount);
			User_CollectInterest(client);
		}
		ShowMenu_Main(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
}

ShowMenu_Info(client)
{
	g_hBankMenu[client] = CreatePanel();
	SetPanelTitle(g_hBankMenu[client], "Safecoin Bank - Information Center");
	DrawPanelText(g_hBankMenu[client], " ");
	DrawPanelText(g_hBankMenu[client], "Why us?");
	DrawPanelText(g_hBankMenu[client], "Safecoin Bank provides quality coin storage services FOR VERY LOW PRICES.");
	DrawPanelText(g_hBankMenu[client], "Avoid taxes AT NO RISK by storing your coins in our bank.");
	DrawPanelText(g_hBankMenu[client], "Not only that, but we also offer daily coin interest when you have money deposited.");
	DrawPanelText(g_hBankMenu[client], "Save coins in the Deathmatch Arena by letting us take care of your coins!");
	DrawPanelText(g_hBankMenu[client], " ");
	DrawPanelText(g_hBankMenu[client], "Why not?");
	DrawPanelText(g_hBankMenu[client], "We do ask for a small fee when you withdraw funds, but it's only a SMALL fee.");
	DrawPanelText(g_hBankMenu[client], "Seriously: trust us. We'll help you save more money.");
	DrawPanelText(g_hBankMenu[client], " ");
	DrawPanelItem(g_hBankMenu[client], "Go Back");
	SendPanelToClient(g_hBankMenu[client], client, Menu_Info, 60);
	CloseHandle(g_hBankMenu[client]);
}

public Menu_Info(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		ShowMenu_Main(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

GetFee(client)
{
	new fee = RoundToNearest(float(User_GetBank(client)) * 0.02);
	if(fee > 150)
		fee = 150;
	return fee;
}

GetInterest(client)
{
	new amount = RoundToNearest(float(User_GetBank(client)) * 0.008);
	if(amount > 50)
		amount = 50;
	return amount;
}

LeaveBank(client)
{
	g_hBankMenu[client] = INVALID_HANDLE;
	TF2_RemoveCondition(client, TFCond_Dazed);
}

PrintTellerResponse(client, type)
{
	decl String:text[128];
	strcopy(text, sizeof(text), g_szBankResponses[type][GetRandomInt(0, 3)]);
	NPCTalk(client, "Teller", text);
}