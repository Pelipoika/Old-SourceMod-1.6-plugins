#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2_objects>
#include <tf2attributes>
#include <bedeflector>
#include <benukesalot>
#include <misc>
#include <morecolors>
#include <clientprefs>
#include <fraglets>

#define GAME_LUCKY 0
#define GAME_RPS 1

#define RPS_HEAVY 0
#define RPS_SPY 1
#define RPS_PYRO 2

#define SOUND_TF2ANTHEM		"ui/gamestartup1.mp3"
#define SOUND_BUY			"mvm/mvm_bought_upgrade.wav"
#define SOUND_BFAIL			"replay/record_fail.wav"
#define SOUND_DISAPPEAR		"mvm/mvm_money_vanish.wav"
#define SOUND_JUMP 			"misc/banana_slip.wav"

#define SOUND_SUCCESS		"ui/trade_success.wav"
#define SOUND_FAIL			"ui/trade_failure.wav"
#define SOUND_CHANGED 		"ui/trade_changed.wav"

#define SOUND_HEAVY_WIN		"vo/heavy_cheers01.wav"
#define SOUND_SPY_WIN		"vo/spy_laughhappy01.wav"
#define SOUND_PYRO_WIN		"vo/pyro_laughevil01.wav"
#define SOUND_HEAVY_LOSE	"vo/heavy_yell1.wav"
#define SOUND_SPY_LOSE		"vo/spy_paincrticialdeath03.wav"
#define SOUND_PYRO_LOSE		"vo/pyro_paincrticialdeath02.wav"

#define SOUND_INSERT		"ambient/levels/labs/coinslot1.wav"
#define SOUND_TUNE			"fn/welcome/tune.wav"
#define SOUND_WIN			"fn/welcome/win.wav"
#define SOUND_FAIL2			"fn/welcome/fail.wav"

#define SOUND_COIN			"mvm/mvm_money_pickup.wav"
#define SOUND_MUSIC			"items/tf_music_upgrade_machine.wav"

#define MDL_BARREL			"models/props_foliage/spikeplant01.mdl"
#define MDL_PALM			"models/egypt/palm_tree/palm_tree.mdl"
#define MDL_CACTUS			"models/props_foliage/cactus01.mdl"
#define MDL_INFECTED		"models/bots/skeleton_sniper/skeleton_sniper.mdl"
#define MDL_COW     		"models/props_2fort/cow001_reference.mdl"
#define MDL_GIFT			"models/items/tf_gift.mdl"
#define MDL_TELE			"models/props_spytech/tv001.mdl"
#define MDL_BIRD			"models/props_forest/bird.mdl"
#define MDL_SPY				"models/props_training/target_spy.mdl"

#define CASH_EXPIRE			"mvm_cash_explosion"
#define BOUNTY_ACTIVE		"bot_radio_waves"

//Integers
new exp[MAXPLAYERS+1] = 0;
new g_iVikTokens[MAXPLAYERS+1] = 0;
new g_iTokenEffect[MAXPLAYERS+1] = 0;
new ClientBounty[MAXPLAYERS+1];

//Bools
new bool:g_bIsPROP[MAXPLAYERS + 1] = {false, ...};
new bool:g_bIsSKELETON[MAXPLAYERS + 1] = {false, ...};
new bool:g_bHasGiantHead[MAXPLAYERS + 1] = {false, ...};
new bool:roundRunning = true;				//Is ze round running?
new bool:jumping[MAXPLAYERS+1];				//Using High RJ
new bool:NoRegen[MAXPLAYERS+1] = false;		//Should player not regen in func_regen?
new bool:g_bWithDrawListen[MAXPLAYERS+1];
new bool:g_bDepositListen[MAXPLAYERS+1];

//Handles
new Handle:Cookie_Exp;
new Handle:Cookie_Token;
new Handle:Cookie_TokenEffect;
new Handle:ClientsRegenerating[MAXPLAYERS + 1]; 
new Handle:g_hMenuMain = INVALID_HANDLE;
new Handle:hDatabase = INVALID_HANDLE;

//Timer handles
new Handle:hTimer = INVALID_HANDLE;	//Save da Fraglets!
new Handle:hDrop = INVALID_HANDLE;	//Give peeps free fraglets for playing on the server!

new g_delay[MAXPLAYERS+1];		//pay cooldown
new g_TPdelay[MAXPLAYERS+1];

new Float:NextRareSpellUse[MAXPLAYERS+1];	//Rare spell cooldown
new Float:NextSpellUse[MAXPLAYERS+1];		//Spell cooldown
new Float:NextPumpkinUse[MAXPLAYERS+1];		//Pumpkin cooldown
new Float:flNextSpinTime = 0.0;				//Wheel spin cooldown

//Client particles
new g_particleEnt[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ... };

public OnPluginStart()
{
	SQL_TConnect(OnDatabaseConnect, "GlobalWallet");

	RegConsoleCmd("sm_rs", SetScoreTo0);
	RegConsoleCmd("sm_buy", OnDonateCmd);
	RegConsoleCmd("sm_store", OnDonateCmd);
	RegConsoleCmd("sm_shop", OnDonateCmd);
	RegConsoleCmd("sm_fraglets", ShowFraglets);
	RegConsoleCmd("sm_VikCoins", ShowFraglets);
	RegConsoleCmd("sm_VikCoins", ShowFraglets);
	RegConsoleCmd("sm_moni", ShowFraglets);
	RegConsoleCmd("sm_money", ShowFraglets);
	RegConsoleCmd("sm_givefraglets", GiveFraglets);
	RegConsoleCmd("sm_givemoney", GiveFraglets);
	RegConsoleCmd("sm_pay", GiveFraglets);
	RegConsoleCmd("sm_bounty", Command_Bounty);
	RegAdminCmd("sm_steal", RobFraglets, ADMFLAG_ROOT);
	
	RegAdminCmd("sm_setlevel", SetScore, ADMFLAG_ROOT);
	RegAdminCmd("sm_deletemoni", DeleteAllMoney, ADMFLAG_ROOT);
	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_ROOT);
	
//	http://puu.sh/gWpwU/18354da4c4.txt
	
	RegConsoleCmd("sm_gamble", Command_Gamble, "Allows a player to gamble Fraglets for a chance at more Fraglets!");
	RegConsoleCmd("sm_teleport", Command_TP, "Allows a player to teleport to another player at the cost of fraglets");
	RegConsoleCmd("sm_destroy", Command_Destroy, "Allows a person to pay fraglets for the destruction of an engi building that they're looking at.");
	RegConsoleCmd("sm_paypumpkin", Command_PayPumpkin, "Allows a player to spawn a pumpkin for fraglets");
	RegConsoleCmd("sm_payrage", Command_PayRage, "Allows a player to pay for full rage");
	RegConsoleCmd("sm_payregen", Command_PayRegen, "Allows a player to pay for health regeneration");
	RegConsoleCmd("sm_rollrarespell", Command_RareSpell, "Allows a player to pay for a rare spell");
	RegConsoleCmd("sm_rollspell", Command_Spell, "Allows a player to pay for a regular spell");
	RegConsoleCmd("sm_big", Command_Big, "Allows a player to pay for Giant Baby Man size!");
	RegConsoleCmd("sm_buyspeed", Command_Speed, "Displinary action speed boost!");
	RegConsoleCmd("sm_buyprop", Command_Prop, "Disguise as a random prop");
	RegConsoleCmd("sm_buyskele", Command_Skeleton, "Use the Skeleton model");
	RegConsoleCmd("sm_jumps", Command_Jump, "Buy higher rocket jumps");
	RegConsoleCmd("sm_buydeflector", Command_Deflector, "Play as the Giant Deflector Heavy");
	RegConsoleCmd("sm_buynukesalot", Command_BeNuker, "Play as Sir Nukesalot");
	RegConsoleCmd("sm_buybighead", Command_BigHead, "Oh god my head is huge");
	RegConsoleCmd("sm_buysmallheal", Command_SmallHead, "Wee head, my head is wee.");
	RegConsoleCmd("sm_wheel", Command_SpinWheel, "The Wheel of Faith Spins!");
	RegConsoleCmd("sm_showfraglets", DisplayLevel);
	RegConsoleCmd("sm_buycart", Command_Cart, "BUMPERCARS!");
	RegConsoleCmd("sm_wallet", Command_Wallet, "Acces your global wallet");
	RegConsoleCmd("sm_bank", Command_Wallet, "Acces your global wallet");

	LoadTranslations("common.phrases");
	
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
//	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PlayerSpawn);
	HookEvent("player_death", Event_DeathDisablesNoRegen);
	HookEvent("rocket_jump", Event_RocketJump);
	HookEvent("sticky_jump", Event_RocketJump);
	HookEvent("player_disconnect", 	Event_Disconnect, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);
	
	Cookie_Exp = RegClientCookie("HUDLevel_exp", "Store exp", CookieAccess_Protected);
	Cookie_Token = RegClientCookie("Fraglets_VikTokens", "VikToken amount", CookieAccess_Protected);
	Cookie_TokenEffect = RegClientCookie("Fraglets_TokenEffects", "VikToken effect", CookieAccess_Protected);
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!AreClientCookiesCached(i)) continue;
		
		decl String:sCookie_Exp[11];
		GetClientCookie(i, Cookie_Exp, sCookie_Exp, sizeof(sCookie_Exp));
		exp[i] = RoundToFive(StringToInt(sCookie_Exp));
		
		decl String:sCookie_Token[11];
		GetClientCookie(i, Cookie_Token, sCookie_Token, sizeof(sCookie_Token));
		g_iVikTokens[i] = StringToInt(sCookie_Token);
		
		decl String:sCookie_TokenEffect[11];
		GetClientCookie(i, Cookie_TokenEffect, sCookie_TokenEffect, sizeof(sCookie_TokenEffect));
		g_iTokenEffect[i] = StringToInt(sCookie_TokenEffect);
    }
	
	hTimer = CreateTimer(15.0, Timer_SaveFraglets, _, TIMER_REPEAT);
	hDrop = CreateTimer(600.0, Timer_GiveFraglets, _, TIMER_REPEAT);
	
	AddCommandListener(Command_Say, "say_team");
	AddCommandListener(Command_Say, "say");
}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[fraglets.smx] Database failure: %s", error);
	} 
	else 
	{
		PrintToServer("[fraglets.smx] Succesfully connected to database");
		hDatabase = hndl;
	}
}

public Action:Command_Wallet(client, args)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		new userid = GetClientUserId(client);
		
		new String:query[255], String:auth[32];
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		if(!StrEqual(auth, ""))
		{
			Format(query, sizeof(query), "SELECT steamid FROM globalwallet.`global wallet` WHERE steamid = '%s'", auth);
			SQL_TQuery(hDatabase, T_CheckSteamID, query, userid);
		}
		
		PrintToChat(client, "Checking if you are in the database...");
	}
	
	return Plugin_Handled;
}

public T_CheckSteamID(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0) return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("[main.smx] T_CheckSteamID Query failed! %s", error);
		KickClient(client, "Authorization failed! Please try re-connecting");
	}
	else
	{
		new String:auth[32];
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		
		if (!SQL_GetRowCount(hndl)) //Didnt find players steamid in database
		{
			new String:query[255];		
			Format(query, sizeof(query), "INSERT INTO globalwallet.`global wallet` (steamid, stored) VALUES ('%s', '0')", auth);
			SQL_TQuery(hDatabase, T_ExecuteQuery, query, data);
			
			PrintToChat(client, "Created a Global Wallet account for you because you didnt have one, please re open the wallet");
		}
		else
		{
			new String:Query[256];
			Format(Query, sizeof(Query), "SELECT stored FROM globalwallet.`global wallet` WHERE steamid = '%s'", auth);
			SQL_TQuery(hDatabase, T_CreditAmount, Query, data);
			
			PrintToChat(client, "Getting the amount of money you have in your bank \n(Your steamID %s)", auth);
		}
	}
}

public T_CreditAmount(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0) return;
	if (hndl == INVALID_HANDLE) LogError("[fraglets.smx] T_CreditAmount Query failed! %s", error);
	
	if (SQL_GetRowCount(hndl))
	{
		SQL_FetchRow(hndl);
		new String:title[255];
		Format(title, 255, "Your Global Wallet %i Fraglets\nYou have %i Fraglets", SQL_FetchInt(hndl, 0), exp[client]);
		new Handle:menu = CreateMenu(MenuWalletHandler);
		SetMenuTitle(menu, title);
		AddMenuItem(menu, "1", "Withdraw Fraglets");
		AddMenuItem(menu, "2", "Deposit Fraglets");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuWalletHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0: 
			{
				new String:title[255];
				Format(title, 255, "Withdraw how much?\nYou have %i Fraglets\n", exp[param1]);
				new Handle:menu2 = CreateMenu(MenuWithDrawHandler);
				SetMenuTitle(menu2, title);
				AddMenuItem(menu2, "1", "10");
				AddMenuItem(menu2, "2", "100");
				AddMenuItem(menu2, "3", "1000");
				AddMenuItem(menu2, "4", "10 000");
				AddMenuItem(menu2, "5", "100 000");
				SetMenuExitButton(menu2, true);
				DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
			}
			case 1: 
			{
				new String:title[255];
				Format(title, 255, "Deposit how much?\nYou have %i Fraglets\n", exp[param1]);
				new Handle:menu2 = CreateMenu(MenuDepositHandler);
				SetMenuTitle(menu2, title);
				AddMenuItem(menu2, "1", "10");
				AddMenuItem(menu2, "2", "100");
				AddMenuItem(menu2, "3", "1000");
				AddMenuItem(menu2, "4", "10 000");
				AddMenuItem(menu2, "5", "100 000");
				AddMenuItem(menu2, "6", "Everything");
				SetMenuExitButton(menu2, true);
				DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
}

public MenuWithDrawHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:strAuth[64], String:Query[256];
		GetClientAuthId(param1, AuthId_Steam2, strAuth, sizeof(strAuth));
		new amount = 0;
		
		switch(param2)
		{
			case 0: amount = 10;
			case 1: amount = 100;
			case 2: amount = 1000;
			case 3: amount = 10000;
			case 4: amount = 100000;
		}
		
		if(GetStoredAmount(param1) >= amount)
		{
			exp[param1] += amount;
			Format(Query, sizeof(Query), "UPDATE globalwallet.`global wallet` SET stored = stored - %i WHERE steamid = '%s'", amount, strAuth);
			SQL_TQuery(hDatabase, T_ExecuteQuery, Query);
		}
		else
			PrintToChat(param1, "You dont have that much money in the Wallet");
	}
	else if(action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
}

public MenuDepositHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:strAuth[64], String:Query[256];
		GetClientAuthId(param1, AuthId_Steam2, strAuth, sizeof(strAuth));
		new amount = 0;
		new bool:everything = false;
		
		switch(param2)
		{
			case 0: amount = 10;
			case 1: amount = 100;
			case 2: amount = 1000;
			case 3: amount = 10000;
			case 4: amount = 100000;
			case 5: everything = true;
		}
		
		if(everything)
		{
			Format(Query, sizeof(Query), "UPDATE globalwallet.`global wallet` SET stored = stored + %i WHERE steamid = '%s'", exp[param1], strAuth);
			SQL_TQuery(hDatabase, T_ExecuteQuery, Query);
			exp[param1] = 0;
		}
		else
		{
			if(exp[param1] >= amount)
			{
				exp[param1] -= amount;
				Format(Query, sizeof(Query), "UPDATE globalwallet.`global wallet` SET stored = stored + %i WHERE steamid = '%s'", amount, strAuth);
				PrintToChat(param1, "%s", Query);
				SQL_TQuery(hDatabase, T_ExecuteQuery, Query);
			}
			else
				PrintToChat(param1, "You dont have enough money");
		}
	}
	else if(action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
}

stock GetStoredAmount(client)
{
	new amount = -1;

	decl String:strAuth[64];
	GetClientAuthString(client, strAuth, sizeof(strAuth));
	
	decl String:query[256];
	Format(query, sizeof(query), "SELECT stored FROM globalwallet.`global wallet` WHERE steamid = '%s'", strAuth);
	
	new Handle:Query = SQL_Query(hDatabase, query);
	if (Query == INVALID_HANDLE)
	{
		new String:error[255];
		SQL_GetError(hDatabase, error, sizeof(error));
		PrintToServer("GetStoredAmount Failed to query (error: %s)", error);
	} 
	else 
	{
		SQL_FetchRow(Query)
		amount = SQL_FetchInt(Query, 0);
	 
		/* Free the Handle */
		CloseHandle(Query);		
	}
	
	return amount;
}

public Action:Command_Say(client, const String:command[], argc) 
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		new String:strChat[100], String:strAuth[64], String:Query[256];
		GetCmdArgString(strChat, sizeof(strChat));
		GetClientAuthId(client, AuthId_Steam2, strAuth, sizeof(strAuth));
		
		new amount = StringToInt(strChat);
		if(amount > 0 && g_bDepositListen[client])
		{		
			exp[client] += amount;
			Format(Query, sizeof(Query), "UPDATE globalwallet.`global wallet` SET stored = stored + %i WHERE steamid = '%s'", amount, strAuth);
			
			SQL_TQuery(hDatabase, T_ExecuteQuery, Query);
			
			g_bDepositListen[client] = false;
		}
		else if(amount < 0 && g_bWithDrawListen[client])
		{
			exp[client] -= amount;
			Format(Query, sizeof(Query), "UPDATE globalwallet.`global wallet` SET stored = stored - %i WHERE steamid = '%s'", amount, strAuth);
			
			SQL_TQuery(hDatabase, T_ExecuteQuery, Query);
			
			g_bWithDrawListen[client] = false;
		}
	}
}

public T_ExecuteQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE) LogError("[fraglets.smx] T_ExecuteQuery Query failed! %s", error);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Fraglets_GetFraglets", Native_GetFraglets);
	CreateNative("Fraglets_SetFraglets", Native_SetFraglets);
	CreateNative("Fraglets_AddFraglets", Native_AddFraglets);
	RegPluginLibrary("fraglets");
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheSound(SOUND_TF2ANTHEM);
	PrecacheSound(SOUND_BUY);
	PrecacheSound(SOUND_DISAPPEAR);
	PrecacheSound(SOUND_JUMP);
	PrecacheSound(SOUND_BFAIL);
	
	PrecacheSound(SOUND_SUCCESS);
	PrecacheSound(SOUND_FAIL);
	PrecacheSound(SOUND_CHANGED);
	
	PrecacheSound(SOUND_TUNE);
	PrecacheSound(SOUND_WIN);
	PrecacheSound(SOUND_FAIL2);
	PrecacheSound(SOUND_INSERT);
	
	PrecacheSound(SOUND_COIN);
	PrecacheSound(SOUND_MUSIC);
	
	PrecacheSound(SOUND_HEAVY_WIN);
	PrecacheSound(SOUND_SPY_WIN);
	PrecacheSound(SOUND_PYRO_WIN);
	PrecacheSound(SOUND_HEAVY_LOSE);
	PrecacheSound(SOUND_SPY_LOSE);
	PrecacheSound(SOUND_PYRO_LOSE);
	
	PrecacheModel(MDL_PALM);
	PrecacheModel(MDL_CACTUS);
	PrecacheModel(MDL_BARREL);
	PrecacheModel(MDL_INFECTED);
	
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl");
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl");
	PrecacheModel("models/props_halloween/bumpercar_cage.mdl");
	PrecacheModel("models/props_halloween/hwn_kart_ball01.mdl");
	
	PrecacheGeneric(CASH_EXPIRE);
	PrecacheGeneric(BOUNTY_ACTIVE);
	
	flNextSpinTime = 0.0;
}

public OnMapEnd()
{
	if (g_hMenuMain != INVALID_HANDLE)
	{
		CloseHandle(g_hMenuMain);
		g_hMenuMain = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	ClientBounty[client] = 0;
	g_bIsPROP[client] = false;
	g_bIsSKELETON[client] = false;
	g_bHasGiantHead[client] = false;
	jumping[client] = false;
	NoRegen[client] = false;
	NextRareSpellUse[client] = 0.0;
	NextSpellUse[client] = 0.0;
	NextPumpkinUse[client] = 0.0;
	NextPumpkinUse[client] = 0.0;
	g_bWithDrawListen[client] = false;
	g_bDepositListen[client] = false;
}

public OnClientCookiesCached(client)
{
	decl String:sCookie_Exp[11];
	GetClientCookie(client, Cookie_Exp, sCookie_Exp, sizeof(sCookie_Exp));
	exp[client] = RoundToFive(StringToInt(sCookie_Exp));
	
	decl String:sCookie_Token[11];
	GetClientCookie(client, Cookie_Token, sCookie_Token, sizeof(sCookie_Token));
	g_iVikTokens[client] = StringToInt(sCookie_Token);
	
	decl String:sCookie_TokenEffect[11];
	GetClientCookie(client, Cookie_TokenEffect, sCookie_TokenEffect, sizeof(sCookie_TokenEffect));
	g_iTokenEffect[client] = StringToInt(sCookie_TokenEffect);
}

public Action:Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0)
	{
		new Final = RoundToFive(exp[client])
		decl String:sCookie_Exp[11];	
		IntToString(Final, sCookie_Exp, sizeof(sCookie_Exp));
		SetClientCookie(client, Cookie_Exp, sCookie_Exp);
		
		decl String:sCookie_Token[11];	
		IntToString(g_iVikTokens[client], sCookie_Token, sizeof(sCookie_Token));
		SetClientCookie(client, Cookie_Token, sCookie_Token);
		
		decl String:sCookie_TokenEffect[11];
		IntToString(g_iTokenEffect[client], sCookie_TokenEffect, sizeof(sCookie_TokenEffect));
		SetClientCookie(client, Cookie_TokenEffect, sCookie_TokenEffect);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	roundRunning = true;
	
	new i = -1;
	while((i = FindEntityByClassname(i, "func_regenerate")) != -1) 
	{
		SDKHook(i, SDKHook_TouchPost, OnTouchResupply);
		SDKHook(i, SDKHook_StartTouchPost, OnTouchResupply);
		
		SDKHook(i, SDKHook_EndTouch, OnTouchEnd);
		SDKHook(i, SDKHook_EndTouchPost, OnTouchEnd);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	roundRunning = false;
}

public OnTouchResupply(entity, other) 
{
	if(other < 1 || other > MaxClients || !IsPlayerAlive(other) || !roundRunning) 
	{
		return;
	}
	
	if(NoRegen[other])
		AcceptEntityInput(entity, "Disable");
}

public OnTouchEnd(entity, other) 
{
	if(other < 1 || other > MaxClients || !IsClientInGame(other) || !IsPlayerAlive(other) || !roundRunning) 
	{
		return;
	}
	
	AcceptEntityInput(entity, "Enable");
}

public OnPluginEnd()
{
	if (hTimer != INVALID_HANDLE)
    {
        KillTimer(hTimer);
        hTimer = INVALID_HANDLE;
    }

	if (hDrop != INVALID_HANDLE)
    {
        KillTimer(hDrop);
        hDrop = INVALID_HANDLE;
    }
	
	for(new i = 1; i <= GetMaxClients(); i++)
    {
		new Final = RoundToFive(exp[i])
		decl String:sCookie_Exp[11];	
		IntToString(Final, sCookie_Exp, sizeof(sCookie_Exp));
		SetClientCookie(i, Cookie_Exp, sCookie_Exp);
		
		decl String:sCookie_Token[11];	
		IntToString(g_iVikTokens[i], sCookie_Token, sizeof(sCookie_Token));
		SetClientCookie(i, Cookie_Token, sCookie_Token);
		
		decl String:sCookie_TokenEffect[11];
		IntToString(g_iTokenEffect[i], sCookie_TokenEffect, sizeof(sCookie_TokenEffect));
		SetClientCookie(i, Cookie_TokenEffect, sCookie_TokenEffect);
	}
}

public Action:Timer_SaveFraglets(Handle:timer)
{
	for(new i = 1; i <= GetMaxClients(); i++)
    {
		if(IsValidClient(i))
		{
			new Final = RoundToFive(exp[i])
			decl String:sCookie_Exp[11];	
			IntToString(Final, sCookie_Exp, sizeof(sCookie_Exp));
			SetClientCookie(i, Cookie_Exp, sCookie_Exp);
			
			decl String:sCookie_Token[11];	
			IntToString(g_iVikTokens[i], sCookie_Token, sizeof(sCookie_Token));
			SetClientCookie(i, Cookie_Token, sCookie_Token);
			
			decl String:sCookie_TokenEffect[11];
			IntToString(g_iTokenEffect[i], sCookie_TokenEffect, sizeof(sCookie_TokenEffect));
			SetClientCookie(i, Cookie_TokenEffect, sCookie_TokenEffect);
		}
	}
}

public Action:Timer_GiveFraglets(Handle:timer)
{
	for(new i = 1; i <= GetMaxClients(); i++)
    {
		if(IsValidClient(i))
		{
			new amount = RoundToFive(GetRandomInt(25, 100));
			exp[i] += amount;
			PrintHintText(i, "You have been given %i VikCoins for playing on the server! [%i]", amount, exp[i]);
			
			if(GetRandomInt(0, 10) == 5)
			{
				g_iVikTokens[i]++;
				CPrintToChat(i, "{gold}You found a VikToken! (You have %i)", g_iVikTokens[i]);
			}
		}
	}
}

public Action:GiveFraglets(client, args)
{
	if (IsValidClient(client))
	{
		decl String:arg1[100];
		decl String:arg2[100];
		
		if(args != 2)
		{
			CPrintToChat(client, "Usage: !givemoney <Name> <Ammount>");
			return Plugin_Handled;
		}
		
		if (g_delay[client] > 0)
		{
			CPrintToChat(client, "{green}Please wait {cyan}%i {green}seconds", g_delay[client]);
			return Plugin_Handled;
		}
		
		GetCmdArg(1, arg1, 100);
		GetCmdArg(2, arg2, 100);
		
		new target = FindTarget(client, arg1, false, false);
		new ammountConverted = StringToInt(arg2);
		
		if(target == -1)
			return Plugin_Handled;
		
		if (exp[client] < ammountConverted)
		{
			CPrintToChat(client, "{red}You don't have enough VikCoins!");
			return Plugin_Handled;
		}
		
		if (ammountConverted <= 100)
		{
			CPrintToChat(client, "{red}You must send more than 100 VikCoins!");
			return Plugin_Handled;
		}
		
		if(client != target)
		{
			Delay(client);
			exp[client] -= ammountConverted;
			exp[target] += ammountConverted;
		}
		else
		{
			CPrintToChat(client, "{red}You can't target yourself!");
			return Plugin_Handled;
		}

		CPrintToChatAllEx(client, "{teamcolor}%N {default}has given {green}%i VikCoins{default} to {green}%N", client, ammountConverted, target);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:RobFraglets(client, args)
{
	if (IsValidClient(client))
	{
		decl String:arg1[100];
		decl String:arg2[100];
		
		if(args != 2)
		{
			CPrintToChat(client, "Usage: !steal <Name> <Ammount>");
			return Plugin_Handled;
		}
		
		if (g_delay[client] > 0)
		{
			CPrintToChat(client, "{green}Please wait {cyan}%i {green}seconds", g_delay[client]);
			return Plugin_Handled;
		}
		
		GetCmdArg(1, arg1, 100);
		GetCmdArg(2, arg2, 100);
		
		new target = FindTarget(client, arg1, false, false);
		new ammountConverted = StringToInt(arg2);
		
		if(target == -1)
			return Plugin_Handled;
		
		if (exp[target] < ammountConverted)
		{
			CPrintToChat(client, "{red}Your target doesnt have that many VikCoins!");
			return Plugin_Handled;
		}
		
		if(client != target)
		{
			Delay(client);
			exp[client] += ammountConverted;
			exp[target] -= ammountConverted;
		}
		else
		{
			CPrintToChat(client, "{red}You can't target yourself!");
			return Plugin_Handled;
		}

		CPrintToChatAllEx(client, "{teamcolor}%N {default}has stolen {green}%i VikCoins{default} from {green}%N", client, ammountConverted, target);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:OnDonateCmd(client, args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "Cannot use command from RCON.");
        return Plugin_Handled;
    }
    
    DisplayMenuSafely(g_hMenuMain, client);
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
				FakeClientCommandEx(param1, "sm_gamble");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
            case 1:
            {
				FakeClientCommandEx(param1, "sm_teleport");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
            case 2:
            {
				FakeClientCommandEx(param1, "sm_destroy");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
            case 3:
            {
				FakeClientCommandEx(param1, "sm_paypumpkin");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
			case 4:
            {
				FakeClientCommandEx(param1, "sm_payrage");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
            case 5:
            {
				FakeClientCommandEx(param1, "sm_payregen");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
			case 6:
            {
				FakeClientCommandEx(param1, "sm_rollspell");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
			case 7:
            {
				FakeClientCommandEx(param1, "sm_rollrarespell");
				DisplayMenuSafely(g_hMenuMain, param1);
            }
			case 8:
            {
				FakeClientCommandEx(param1, "sm_big");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 9:
            {
				FakeClientCommandEx(param1, "sm_buyspeed");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 10:
			{
				FakeClientCommand(param1, "sm_buyprop");
				NoRegen[param1] = true;
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 11:
			{
				FakeClientCommand(param1, "sm_buyskele");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 12:
			{
				FakeClientCommand(param1, "sm_jumps");
				NoRegen[param1] = true;
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 13:
			{
				FakeClientCommand(param1, "sm_buydeflector");
				NoRegen[param1] = true;
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 14:
			{
				FakeClientCommand(param1, "sm_buynukesalot");
				NoRegen[param1] = true;
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 15:
			{
				FakeClientCommand(param1, "sm_buybighead");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 16:
			{
				FakeClientCommand(param1, "sm_buysmallheal");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 17:
			{
				FakeClientCommand(param1, "sm_wheel");
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 18:
			{
				if(!TF2_IsPlayerInCondition(param1, TFCond:82))
					FakeClientCommand(param1, "sm_buycart");
				else
					CPrintToChat(param1, "{red}Already Bumpercarting");
					
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 19:
			{
				if(!BeDeflector_IsDeflector(param1) && !BeNukesalot_IsNuker(param1))
				{
					if(GetEntityMoveType(param1) != MOVETYPE_NOCLIP)	//Jos pelaaja EI noclippaa
					{
						new iCreditCost = 15000;				//Maksu joka peritÃ¤Ã¤n pelaajalta 

						if (exp[param1] < iCreditCost)		//Tarkistetaan onko pelaajalla varaa ostokseen
						{
							EmitSoundToClient(param1, SOUND_BFAIL);										//Lol vitun kÃ¶yhÃ¤
							CPrintToChat(param1, "{red}You need at least %d Fraglets!", iCreditCost);	//Ei sul oo varaa
							return;														//I'm done
						}

						EmitSoundToClient(param1, SOUND_BUY);
						SetEntityMoveType(param1, MOVETYPE_NOCLIP);
						
						CPrintToChat(param1, "{red}Noclip: {lime}On!", iCreditCost);
						exp[param1] -= iCreditCost;
					}
					else	//Muuten
						CPrintToChat(param1, "{haunted}Already in Noclip");
				}
				else	//Muuten
					CPrintToChat(param1, "{haunted}Noclip is not available for Deflectors or Nukers");
				
				DisplayMenuSafely(g_hMenuMain, param1);			//NÃ¤ytÃ¤ pÃ¤Ã¤menu uudestaan
			}
			case 20:
			{
				if(!TF2_IsPlayerInCondition(param1, TFCond:55))	//Jos pelaaja EI ole conditiossa 55 teemme tÃ¤mÃ¤n function koodipÃ¤tkÃ¤n
				{
					new iCreditCost = 500;				//Maksu joka peritÃ¤Ã¤n pelaajalta

					if (exp[param1] < iCreditCost)		//Tarkistetaan onko pelaajalla varaa ostokseen
					{
						EmitSoundToClient(param1, SOUND_BFAIL);										//Lol vitun kÃ¶yhÃ¤
						CPrintToChat(param1, "{red}You need at least %d Fraglets!", iCreditCost);	//Ei sul oo varaa
						return;														//I'm done
					}

					EmitSoundToClient(param1, SOUND_BUY);							//Soita pelaajalle ostoÃ¤Ã¤ni
					TF2_AddCondition(param1, TFCond:55, TFCondDuration_Infinite);	//LisÃ¤Ã¤ Condition 55 pelaajaan
					
					CPrintToChat(param1, "{red}Oh {haunted}YEAH {red}Do not taunt or you lose condition", iCreditCost);	//Printtaa pelaajan chattiin
					exp[param1] -= iCreditCost;													//VÃ¤hennÃ¤ ostoksen hinta pelaajan rahamÃ¤Ã¤rÃ¤stÃ¤
				}
				else	//Muuten
					CPrintToChat(param1, "{red}Already in condition");		//Jos pelaajalla on jo conditio ilmoita hÃ¤nelle siitÃ¤.
					
				DisplayMenuSafely(g_hMenuMain, param1);	
			}
			case 21:
			{
				if(!TF2_IsPlayerInCondition(param1, TFCond:55))
				{
					new iCreditCost = 3000;	

					if (exp[param1] < iCreditCost)
					{
						EmitSoundToClient(param1, SOUND_BFAIL);	
						CPrintToChat(param1, "{red}You need at least %d Fraglets!", iCreditCost);
						return;
					}

					EmitSoundToClient(param1, SOUND_BUY);
					TF2_AddCondition(param1, TFCond:86, TFCondDuration_Infinite);	
					
					CPrintToChat(param1, "{haunted}Now Swim in Freedom", iCreditCost);
					exp[param1] -= iCreditCost;
				}
				else	//Muuten
					CPrintToChat(param1, "{red}Already Can Swim");
					
				DisplayMenuSafely(g_hMenuMain, param1);	
			}
			case 22:
			{
				if(!TF2_IsPlayerInCondition(param1, TFCond:50))	
				{
					new iCreditCost = 100;

					if (exp[param1] < iCreditCost)
					{
						EmitSoundToClient(param1, SOUND_BFAIL);
						CPrintToChat(param1, "{red}You need at least %d Fraglets!", iCreditCost);
						return;
					}

					EmitSoundToClient(param1, SOUND_BUY);
					TF2_AddCondition(param1, TFCond:50, TFCondDuration_Infinite);
					
					CPrintToChat(param1, "{haunted}Spy sapped your Head", iCreditCost);
					exp[param1] -= iCreditCost;	
				}
				else	//Muuten
					CPrintToChat(param1, "{red}Your brains are dead already");	
					
				DisplayMenuSafely(g_hMenuMain, param1);
			}
			case 23:
			{
				new iCreditCost = 10000;
				
				if (exp[param1] < iCreditCost)
				{
					EmitSoundToClient(param1, SOUND_BFAIL);
					CPrintToChat(param1, "{red}You need at least %d Fraglets!", iCreditCost);
					return;
				}

				g_iVikTokens[param1]++;
				EmitSoundToClient(param1, SOUND_BUY);
				CPrintToChat(param1, "{gold}Bough a VikToken (You have %i)", iCreditCost, g_iVikTokens[param1]);
				exp[param1] -= iCreditCost;	
			}
			case 24:
			{
				if (g_iVikTokens[param1] < 20)
				{
					EmitSoundToClient(param1, SOUND_BFAIL);
					CPrintToChat(param1, "{red}BRO! You need like 20 VikTokens!");
					return;
				}

				switch(GetRandomInt(1, 1))
				{
					case 1:
					{
						g_iTokenEffect[param1] = 1;
						TF2_AddCondition(param1, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						CPrintToChat(param1, "You rolled: Speed Boost!");
					}
					case 2:
					{
						g_iTokenEffect[param1] = 2;
						CPrintToChat(param1, "You rolled: Cash Bonus! (You gain extra money from money piles)");
					}
					case 3:
					{
						g_iTokenEffect[param1] = 3;
						TF2_AddCondition(param1, TFCond_SmallFireResist, TFCondDuration_Infinite);
						CPrintToChat(param1, "You rolled: Fire Resistance!");
					}
				}
				
				EmitSoundToClient(param1, SOUND_BUY);
				g_iVikTokens[param1] -= 2;	
			}
        }
    }
}

public Action:Command_Big(client, args)
{
	new iCreditCost = 500;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	EmitSoundToClient(client, SOUND_BUY);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	UpdatePlayerHitbox(client, 1.75);
	CPrintToChat(client, "{default}Granted {red}Giant Size{default} for {cyan}%d{default} VikCoins.", iCreditCost);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Speed(client, args)
{
	new iCreditCost = 200;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	EmitSoundToClient(client, SOUND_BUY);
	if(TF2_IsPlayerInCondition(client, TFCond:82))
		TF2_AddCondition(client, TFCond:83, TFCondDuration_Infinite);
	else
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, -1.0)
		
	CPrintToChat(client, "{default}Granted {red}Speed Boost{default} for {cyan}%d{default} VikCoins.", iCreditCost);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_BigHead(client, args)
{
	new iCreditCost = 50;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	EmitSoundToClient(client, SOUND_BUY);
	TF2Attrib_SetByName(client, "head scale", 3.5);
	g_bHasGiantHead[client] = true;
	CPrintToChat(client, "{default}Granted {red}Giant Head{default} for {cyan}%d{default} VikCoins.", iCreditCost);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_SmallHead(client, args)
{
	new iCreditCost = 50;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	EmitSoundToClient(client, SOUND_BUY);
	TF2Attrib_SetByName(client, "head scale", 0.5);
	g_bHasGiantHead[client] = true;
	CPrintToChat(client, "{default}Granted {red}Small Head{default} for {cyan}%d{default} VikCoins.", iCreditCost);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Cart(client, args)
{
	new iCreditCost = 600;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	EmitSoundToClient(client, SOUND_BUY);
//	TF2_RemoveAllWeapons(client);
	TF2_AddCondition(client, TFCond:82, TFCondDuration_Infinite);
	
	CPrintToChat(client, "{red}WOOOO!!!! {haunted}BUMPERCARS", iCreditCost);
	exp[client] -= iCreditCost;
	
	return Plugin_Handled;
}

public Action:Command_SpinWheel(client, args)
{
	new iCreditCost = 1000;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	new i = -1;
	new found = false;
	new Float:flGameTime = GetGameTime();
	if (flNextSpinTime > flGameTime)
	{
		ReplyToCommand(client, "[SM] Cannot spin wheel for another %.1f second(s).", flNextSpinTime - flGameTime);
		return Plugin_Handled;
	}
	while ((i = FindEntityByClassname(i, "wheel_of_doom")) != -1)
	{
		AcceptEntityInput(i, "Spin");
		found = true;
	}
	if (found)
	{
		EmitSoundToClient(client, SOUND_BUY);
		CPrintToChatAllEx(client, "{teamcolor}%N {default}Spun {unusual}The Wheel of Fate {default}for {unique}%d{default} VikCoins.", client, iCreditCost);
		exp[client] -= iCreditCost;
		flNextSpinTime = flGameTime + 900.0;
		return Plugin_Handled;
	}
	else
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{unique}Error 404: {red}Wheel not found");
		return Plugin_Handled;
	}
}

public Action:Command_Prop(client, args)
{
	new iCreditCost = 250;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	EmitSoundToClient(client, SOUND_BUY);
	TF2_RemoveAllWeapons(client);
	KillWearables(client);
	g_bIsPROP[client] = true;
	NoRegen[client] = true;
	switch(GetRandomInt(1, 5))
	{
		case 1: 
		{
			SetVariantString(MDL_GIFT);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			CPrintToChat(client, "{default}You were disguised as a {green}Jar Of PISS{default} for {cyan}%d{default} VikCoins.", iCreditCost);
		}
		case 2:
		{
			SetVariantString(MDL_BIRD);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			CPrintToChat(client, "{default}You were disguised as a {green}Archimedes{default} for {cyan}%d{default} VikCoins.", iCreditCost);
		}
		case 3:	
		{
			SetVariantString(MDL_SPY);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			CPrintToChat(client, "{default}You were disguised as a {green}Spy{default} for {cyan}%d{default} VikCoins.", iCreditCost);
		}
		case 4:	
		{
			SetVariantString(MDL_COW);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			CPrintToChat(client, "{default}You were disguised as a {green}Demon Cow{default} for {cyan}%d{default} VikCoins.", iCreditCost);
		}
		case 5:	
		{
			SetVariantString(MDL_TELE);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			CPrintToChat(client, "{default}You were disguised as a {green}Television{default} for {cyan}%d{default} VikCoins.", iCreditCost);
		}
	}
	
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Skeleton(client, args)
{
	new iCreditCost = 250;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}

	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		EmitSoundToClient(client, SOUND_BUY);
		SetVariantString(MDL_INFECTED);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		g_bIsSKELETON[client] = true;
		NoRegen[client] = true;
		exp[client] -= iCreditCost;
	}
	else
	{
		CPrintToChat(client, "{red}Sniper only!");
	}	
	return Plugin_Handled;
}

public Action:Command_Jump(client, args)
{
	new iCreditCost = 1250;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d !", iCreditCost);
		return Plugin_Handled;
	}
	
	EmitSoundToClient(client, SOUND_BUY);
	CPrintToChat(client, "{default}Granted Super Rocket Jumps for {red}%d{default} VikCoins.", iCreditCost);
	jumping[client] = true;
	NoRegen[client] = true;
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Buster(client, args)
{
	new iCreditCost = 6000;
	
	if (exp[client] < iCreditCost)
	{
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	EmitSoundToClient(client, SOUND_BUY);
	CPrintToChatAll("{green}%N {default}is now playing as a {grey}Sentry Buster", client);
	CPrintToChat(client, "{default}You are now playing as a {grey}Sentry Buster{default}  -{red}%d{default} VikCoins.", iCreditCost);
	ServerCommand("sm_buster \"%N\"", client);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Deflector(client, args)
{
	new iCreditCost = 16000;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) != _:TFTeam_Spectator)
	{
		EmitSoundToClient(client, SOUND_BUY);
		CPrintToChatAll("{green}%N {default}is now playing as a {gray}Giant Deflector Heavy", client);
		CPrintToChat(client, "{default}You are now playing as a {gray}Giant Deflector Heavy{default}  {red}-%d{default} VikCoins.", iCreditCost);
		//ServerCommand("sm_bedeflector \"%N\"", client);
		BeDeflector_MakeDeflector(client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		exp[client] -= iCreditCost;
	}
	return Plugin_Handled;
}

public Action:Command_BeNuker(client, args)
{
	new iCreditCost = 20000;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	new LooseCannon = GetPlayerWeaponSlot(client, 0);
	
	if(IsValidEntity(LooseCannon))
	{
		new weaponindex = GetEntProp(LooseCannon, Prop_Send, "m_iItemDefinitionIndex");
	
		if(weaponindex == 996 && GetClientTeam(client) != _:TFTeam_Spectator)
		{
			EmitSoundToClient(client, SOUND_BUY);
			CPrintToChatAll("{green}%N {default}is now playing as {gray}Sir Nukesalot", client);
			CPrintToChat(client, "{default}You are now playing as a {gray}Sir Nukesalot{default}  {red}-%d{default} VikCoins.", iCreditCost);
			//ServerCommand("sm_benukesalot \"%N\"", client);
			BeNukesalot_MakeNuker(client);
			SetEntityMoveType(client, MOVETYPE_WALK);
			exp[client] -= iCreditCost;
		}
		else
		{
			EmitSoundToClient(client, SOUND_BFAIL);
			CPrintToChat(client, "{default}Please equip your {unique}Loose Cannon{default}!");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Horsemann(client, args)
{
	new iCreditCost = 5000;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	EmitSoundToClient(client, SOUND_BUY);
	CPrintToChatAll("{green}%N {default}is now playing as a {unusual}The Horseless Headless Horseman", client);
	CPrintToChat(client, "{default}You are now playing as a {unusual}The Horseless Headless Horseman{default}  {red}-%d{default} VikCoins.", iCreditCost);
	ServerCommand("sm_fbehhh \"%N\"", client);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Bounty(client, args)
{
	decl String:arg1[256];
	decl String:arg2[256];
	
	if(args != 2)
	{
		PrintToChat(client, "Usage: sm_bounty [PLAYER] [BOUNTY]");
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new target = FindTarget(client, arg1, false, false);
	new bounty = StringToInt(arg2);
	
	if(bounty >= 5)
	{
		if(bounty <= exp[client])
		{
			if(ClientBounty[target] <= 0)
				AttachParticle2(target, BOUNTY_ACTIVE, "head"); 
			
			exp[client] -= bounty;
			ClientBounty[target] += bounty;
			CPrintToChatAllEx(target, "{gray}%N{default} succesfully set a bounty of {lime}$%i {default}on {teamcolor}%N {lime}[$%i]", client, bounty, target, ClientBounty[target]);
			CPrintToChat(target, "{red}Watch out, {gray}%N{red} has put a bounty of {lime}$%i{red} on you.", client, bounty);
		}
		else
		{
			CPrintToChat(client, "{red}You dont have enough {lime}VikCoins");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Goto(client, args)
{
	if(IsValidClient(client))
	{
		if(args != 1)
		{
			ReplyToCommand(client, "Usage: sm_goto <player>");
			return Plugin_Handled;
		}
		
		if (BeDeflector_IsDeflector(client) || BeNukesalot_IsNuker(client))
		{
			CPrintToChat(client, "{red}Giant Robots are too heavy to be teleported.");
			return Plugin_Handled;
		}
		
		decl String:arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
		if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
		{
			ReplyInvalidTarget(client);
			return Plugin_Handled;
		}
		
		if (g_TPdelay[client] > 0)
		{
			CPrintToChat(client, "{green}Please Calm down. You must wait{cyan}%i {green}seconds untill you can teleport to {cyan}%N ",targetList, g_TPdelay[client]);
			return Plugin_Handled;
		}
		
		if(targetList[0] == client)
		{
			ReplyInvalidTarget(client);
			return Plugin_Handled;
		}
		
		if(ClientBounty[targetList[0]] > 0 || NoRegen[targetList[0]])
		{
			CPrintToChat(client, "{red}You can't teleport to that guy right now.");
			return Plugin_Handled;
		}
		
		decl Float:pos[3];
		GetClientAbsOrigin(targetList[0], pos);
		if(GetClientTeam(client) != GetClientTeam(targetList[0]))
			pos[2] += 128.0;
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		TPDelay(client);
		CPrintToChatAllEx(targetList[0], "{green}%N{default} teleported to {teamcolor}%N", client, targetList[0]);
	}
	return Plugin_Handled;
}

public Action:SetScore(client, args)
{
	decl String:arg1[100];
	decl String:arg2[100];
	
	if(args != 2)
	{
		PrintToChat(client, "Usage : sm_setlevel [PLAYER] [FRAGLETS]");
	}
	
	GetCmdArg(1, arg1, 100);
	GetCmdArg(2, arg2, 100);
	
	new target = FindTarget(client, arg1);
	
	new new_money = StringToInt(arg2);
	exp[target] = new_money;
	
	SetClientCookie(target, Cookie_Exp, arg2);
	return Plugin_Handled;
}

public Action:DeleteAllMoney(client, args)
{
	new moni = -1;
	while ((moni = FindEntityByClassname(moni, "item_currencypack_*")) != -1)
	{
		if (IsValidEntity(moni))
		{
			PrintToChat(client, "Deleted..");
			AcceptEntityInput(moni, "Kill");
		}
	}
}

public Action:SetScoreTo0(client, args)
{
	if(IsValidClient(client))
	{
		exp[client]	= 0;
	}
	return Plugin_Handled;
}

public Action:ShowFraglets(client, args)
{
	if(IsValidClient(client))
	{
		CPrintToChat(client, "{default}You have {gold}%i {default}VikCoins!", exp[client]);
	}
	return Plugin_Handled;
}

public Action:DisplayLevel(client, args)
{
	if(args == 0)
	{
		DisplayPlayerMenu(client);
		return Plugin_Handled;
	}
	else
	{
		CPrintToChat(client, "{green}[VikCoins]{default} Usage : !showfraglets");
		return Plugin_Continue;
	}
}

//This is to prevent a kart bug
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	
	if(IsValidClient(client) && team != _:TFTeam_Spectator)
	{
		SDKHooks_TakeDamage(client, client, client, 9999999999.0);
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathflags = GetEventInt(event, "death_flags");
	
	if(g_bHasGiantHead[client])
	{	
		TF2Attrib_SetByName(client, "head scale", 1.0);
		g_bHasGiantHead[client] = false;
		CPrintToChat(client, "{default}You no longer have a {unusual}Abnormally sized{default}! head");
	}
	
	if(IsValidClient(client) && IsValidClient(killer))
	{
		if (deathflags != TF_DEATHFLAG_DEADRINGER && client != killer)
		{
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			pos[2] += 10.0;
			createMoni(client, pos);
		}
	}
	
	if(IsValidKill(client, killer) && deathflags != TF_DEATHFLAG_DEADRINGER)
	{
		if(ClientBounty[client] > 0)
		{
			CPrintToChatEx(killer, client, "{gray}You{default} succesfully claimed the bounty of {lime}$%i {default}on {teamcolor}%N", ClientBounty[client], client);
			CPrintToChatAllEx(killer, "The bounty of {lime}$%i{default} on {gray}%N{default} has been claimed by {teamcolor}%N", ClientBounty[client], client, killer)
			
			if (IsValidEntity(g_particleEnt[client]))
			{
				AcceptEntityInput(g_particleEnt[client], "Kill");
				g_particleEnt[client] = INVALID_ENT_REFERENCE;
			}
			
			exp[killer] += ClientBounty[client];
			ClientBounty[client] = 0;
		}
	}
	
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(jumping[client])
	{
		jumping[client] = false;
		CPrintToChat(client, "!!!{red}You are no longer Super Rocket Jumping{default}!!!");
	}
	
	if (g_bIsPROP[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		CPrintToChat(client, "!!!{red}You are no longer a prop{default}!!!");
		g_bIsPROP[client] = false;
	}
	
	if (g_bIsSKELETON[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		CPrintToChat(client, "!!!{red}You are no longer a Skeleton{default}!!!");
		g_bIsSKELETON[client] = false;
	}
	
	CreateTimer(0.5, Timer_ApplyEffects, GetClientUserId(client));
}

public Action:Timer_ApplyEffects(Handle:timer, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		switch(g_iTokenEffect[client])
		{
			case 1:
			{
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
			}
			case 3:
			{
				TF2_AddCondition(client, TFCond_SmallFireResist, TFCondDuration_Infinite);
			}
		}
	}
	
	return Plugin_Handled;
}

public Event_DeathDisablesNoRegen(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
		NoRegen[client] = false;
}

public Action:Event_RocketJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(jumping[client])
	{
		new Float:speed[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
		if(!(speed[0] <= -1))
			speed[0] *= 1.5;	//X
		if(!(speed[1] <= -1))
			speed[1] *= 1.5;	//Y
		if(!(speed[2] <= -1))
			speed[2] *= 1.5;	//Z
		
		EmitSoundToAll(SOUND_JUMP, client);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
	}
}

public createMoni(client, Float:pos[3]) 
{
	if(IsValidClient(client))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			{
				new moni = CreateEntityByName("item_currencypack_small");
				
				if(IsValidEntity(moni))
				{
					DispatchSpawn(moni);
					SetEntPropEnt(moni, Prop_Send, "m_hOwnerEntity", client);
					
			//		HookSingleEntityOutput(moni, "OnPlayerTouch", PickedSmall, true);
					SDKHook(moni, SDKHook_Touch, PickedSmall);
					SDKHook(moni, SDKHook_StartTouch, PickedSmall);
					CreateTimer(30.0, DeleteMoney, EntIndexToEntRef(moni));	
					
					TeleportEntity(moni, pos, NULL_VECTOR, NULL_VECTOR); 
				}
			}
			case 2:
			{
				new moni = CreateEntityByName("item_currencypack_medium");
				
				if(IsValidEntity(moni))
				{
					DispatchSpawn(moni);
					SetEntPropEnt(moni, Prop_Send, "m_hOwnerEntity", client);
					
			//		HookSingleEntityOutput(moni, "OnPlayerTouch", PickedMedium, true);
					SDKHook(moni, SDKHook_Touch, PickedMedium);
					SDKHook(moni, SDKHook_StartTouch, PickedMedium);
					CreateTimer(30.0, DeleteMoney, EntIndexToEntRef(moni));
					
					TeleportEntity(moni, pos, NULL_VECTOR, NULL_VECTOR); 
				}
			}
			case 3:
			{
				new moni = CreateEntityByName("item_currencypack_large");
				
				if(IsValidEntity(moni))
				{
					DispatchSpawn(moni);
					SetEntPropEnt(moni, Prop_Send, "m_hOwnerEntity", client);
					
			//		HookSingleEntityOutput(moni, "OnPlayerTouch", PickedLarge, true);
					SDKHook(moni, SDKHook_Touch, PickedLarge);
					SDKHook(moni, SDKHook_StartTouch, PickedLarge);
					CreateTimer(30.0, DeleteMoney, EntIndexToEntRef(moni));	
					
					TeleportEntity(moni, pos, NULL_VECTOR, NULL_VECTOR); 
				}
			}
		}
	}
}

public PickedSmall(entity, client)
{
	if(IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		MoneyTalk(client);
		if(g_iTokenEffect[client] == 2)
		{
			exp[client] += 20;
			PrintHintText(client, "You collected 20 VikCoins! [%i]", exp[client]);
		}
		else
		{
			exp[client] += 10;
			PrintHintText(client, "You collected 10 VikCoins! [%i]", exp[client]);
		}
		
		AcceptEntityInput(entity, "Kill");
	}
}

public PickedMedium(entity, client)
{
	if(IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		MoneyTalk(client);
		
		if(g_iTokenEffect[client] == 2)
		{
			exp[client] += 30;
			PrintHintText(client, "You collected 30 VikCoins! [%i]", exp[client]);
		}
		else
		{
			exp[client] += 20;
			PrintHintText(client, "You collected 20 VikCoins! [%i]", exp[client]);
		}

		AcceptEntityInput(entity, "Kill");
	}
}

public PickedLarge(entity, client)
{
	if(IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		MoneyTalk(client);

		if(g_iTokenEffect[client] == 2)
		{
			exp[client] += 70;
			PrintHintText(client, "You collected 70 VikCoins! [%i]", exp[client]);
		}
		else
		{
			exp[client] += 50;
			PrintHintText(client, "You collected 50 VikCoins! [%i]", exp[client]);
		}
		
		AcceptEntityInput(entity, "Kill");
	}
}

MoneyTalk(client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		SetVariantString("randomnum:100");
		AcceptEntityInput(client, "AddContext");

		SetVariantString("IsMvMDefender:1");
		AcceptEntityInput(client, "AddContext");
		
		SetVariantString("TLK_MVM_MONEY_PICKUP");
		AcceptEntityInput(client, "SpeakResponseConcept");
		
		AcceptEntityInput(client, "ClearContext");
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		SetVariantString("randomnum:100");
		AcceptEntityInput(client, "AddContext");

		SetVariantString("IsMvMDefender:1");
		AcceptEntityInput(client, "AddContext");
		
		SetVariantString("TLK_MVM_MONEY_PICKUP");
		AcceptEntityInput(client, "SpeakResponseConcept");
		
		AcceptEntityInput(client, "ClearContext");
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		SetVariantString("randomnum:100");
		AcceptEntityInput(client, "AddContext");

		SetVariantString("IsMvMDefender:1");
		AcceptEntityInput(client, "AddContext");
		
		SetVariantString("TLK_MVM_ENCOURAGE_MONEY");
		AcceptEntityInput(client, "SpeakResponseConcept");
		
		AcceptEntityInput(client, "ClearContext");
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		SetVariantString("randomnum:100");
		AcceptEntityInput(client, "AddContext");

		SetVariantString("IsMvMDefender:1");
		AcceptEntityInput(client, "AddContext");
		
		SetVariantString("TLK_MVM_ENCOURAGE_MONEY");
		AcceptEntityInput(client, "SpeakResponseConcept");
		
		AcceptEntityInput(client, "ClearContext");
	}
}

public Action:Command_Gamble(client, args)
{
	new Cost = 125;
	new Time = 5;
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	
	if (g_delay[client] > 0)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{green}Please wait {cyan}%i {green}seconds", g_delay[client]);
		return Plugin_Handled;
	}
	if (exp[client] < Cost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You don't have enough VikCoins! You need at least 200 VikCoins.");
		return Plugin_Handled;
	}
	else
	{
		EmitSoundToClient(client, SOUND_BUY);
		CPrintToChat(client, "You have paid {red}%d {default}VikCoins to gamble.", Cost);
		exp[client] -= Cost;
	}
	
	new Handle:datapack = INVALID_HANDLE;
	CreateDataTimer(1.0, Timer_GambleCountDown, datapack, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
	WritePackCell(datapack, client);
	WritePackCell(datapack, Cost);
	WritePackCell(datapack, Time);
	WritePackString(datapack, name);
	Delay(client);
	return Plugin_Handled;
}

public Action:Command_TP(client, args)
{
	if(IsValidClient(client))
	{
		if (args != 1)
		{
			CPrintToChat(client, "{purple}Usage: {default}!teleport <{blue}player{default}>");
			return Plugin_Handled;
		}
		
		if (BeDeflector_IsDeflector(client) || BeNukesalot_IsNuker(client))
		{
			CPrintToChat(client, "{red}Giant Robots are too heavy to be teleported.");
			return Plugin_Handled;
		}
		
		decl String:argFull[256];
		decl String:sTarget[256];
		
		new Target;
		new creditCost;
		
		GetCmdArgString(argFull, sizeof(argFull));
		GetCmdArg(1, sTarget, sizeof(sTarget));
		
		if ((Target = FindTarget(client, sTarget, false, false)) != -1)
		{
			if (Target == client)
			{
				EmitSoundToClient(client, SOUND_BFAIL);
				CPrintToChat(client, "{yellow}You're a genius. Don't teleport to yourself.");
				return Plugin_Handled;
			}
			
			if(GetClientTeam(Target) == 1)
			{
				EmitSoundToClient(client, SOUND_BFAIL);
				CPrintToChat(client, "{yellow}You're a genius. Don't teleport to a Spectator.");
				return Plugin_Handled;
			}
			
			if(ClientBounty[Target] > 0)
			{
				CPrintToChat(client, "{yellow}You can't teleport to someone who has a bounty on them.");
				return Plugin_Handled;
			}
			
			if(NoRegen[Target])
			{
				CPrintToChat(client, "{yellow}You can't teleport to this guy right now.");
				return Plugin_Handled;
			}
			
			new Float:clientPos[3], Float:targetPos[3], Float:targetAng[3], Float:teleportPos[3];
			
			GetClientAbsOrigin(client, clientPos);
			GetClientAbsOrigin(Target, targetPos);
			GetClientAbsAngles(Target, targetAng);
			
			new Float:fDistanceTotal = GetDistanceTotal(clientPos, targetPos);
			
			new smallDistance = RoundToNearest(fDistanceTotal / 7.5);
			
			creditCost = RoundToFive(RoundToNearest(100.0 + (smallDistance * GetRandomFloat(0.25, 1.75))));
			
			if (exp[client] < creditCost)
			{
				EmitSoundToClient(client, SOUND_BFAIL);
				CPrintToChat(client, "{red}You don't have enough VikCoins. You need at least %d!.", creditCost);
				return Plugin_Handled;
			}
			
			for (new i = 0; i < 3; i++)
			{
				if (i == 2)
					teleportPos[i] = targetPos[i] + 100; 
				else
					teleportPos[i] = targetPos[i];
			}
			
			TeleportEntity(client, teleportPos, targetAng, Float:{ 0.0, 0.0, 0.0 });
			
			EmitSoundToClient(client, SOUND_BUY);
			CPrintToChatAllEx(client, "{teamcolor}%N {default}Teleported to {green}%N {default}for {red}%d {default}VikCoins.", client, Target, creditCost);
			exp[client] -= creditCost;
		}
		else
		{
			CPrintToChat(client, "{red}Player {blue}\"%s\" {red}not found.", sTarget);
			return Plugin_Handled;	
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Destroy(client, args)
{
	new Entity = GetClientAimTarget(client, false);
	if (Entity > 0)
	{
		new TFExtObjectType:Object = TF2_GetExtObjectType(Entity, true);
		
		new credits;
		decl String:ObjectName[64];
		
		if (Object == TFExtObjectType:TFObject_Sentry && GetEntProp(Entity, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
		{
			credits = 300;
			Format(ObjectName, sizeof(ObjectName), "Sentry gun");
		}
		else if (Object == TFExtObjectType:TFObject_MiniSentry && GetEntProp(Entity, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
		{
			credits = 250;
			Format(ObjectName, sizeof(ObjectName), "Mini sentry");
		}
		else if (Object == TFExtObjectType:TFObject_Sapper && GetEntProp(Entity, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
		{
			credits = 50;
			Format(ObjectName, sizeof(ObjectName), "Sapper");
		}
		else if (Object == TFExtObjectType:TFObject_TeleporterEntry && GetEntProp(Entity, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
		{
			credits = 500;
			Format(ObjectName, sizeof(ObjectName), "Teleporter entrance");
		}
		else if (Object == TFExtObjectType:TFObject_TeleporterExit && GetEntProp(Entity, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
		{
			credits = 500;
			Format(ObjectName, sizeof(ObjectName), "Teleporter exit");
		}
		else if (Object == TFExtObjectType:TFObject_Dispenser && GetEntProp(Entity, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
		{
			credits = 750;
			Format(ObjectName, sizeof(ObjectName), "Dispenser");
		}
		else
		{
			decl String:class[64];
			GetEdictClassname(Entity, class, sizeof(class));
			if(strcmp(class, "player") == 0 || strcmp(class, "tf_bot") == 0)
			{
				if(GetEntPropFloat(Entity, Prop_Data, "m_flModelScale") > 1.0 && GetClientTeam(Entity) != GetClientTeam(client) && ClientBounty[Entity] == 0)
				{
					credits = 3000;
					Format(ObjectName, sizeof(ObjectName), "%N", Entity);
				}
				else
				{
					CPrintToChat(client, "{red}Can't touch this.");
					return Plugin_Handled;
				}
			}
			if (strcmp(class, "headless_hatman") == 0)
			{
				credits = 4500;
				Format(ObjectName, sizeof(ObjectName), "Headless Horseless Horsemann");
			}
			else if (strcmp(class, "eyeball_boss") == 0)
			{
				credits = 6000;
				Format(ObjectName, sizeof(ObjectName), "Monoculus");
			}
			else if (strcmp(class, "merasmus") == 0)
			{
				credits = 6000;
				Format(ObjectName, sizeof(ObjectName), "Merasmus");
			}
			else if (strcmp(class, "tank_boss") == 0)
			{
				credits = 10000;
				Format(ObjectName, sizeof(ObjectName), "Tank");
			}
			else 
			{
				CPrintToChat(client, "{red}I do not recognize entity %s yet.", class);
				return Plugin_Handled;
			}
			
			if (exp[client] >= credits)
			{
			//	SetVariantInt(0);
			//	AcceptEntityInput(Entity, "SetHealth", client, client);
			
				SDKHooks_TakeDamage(Entity, client, client, 99999.0, DMG_SHOCK|DMG_ALWAYSGIB);
				
				EmitSoundToClient(client, SOUND_BUY);
				exp[client] -= credits
				CPrintToChatAll("{green}%N {default}killed {arcana}%s {default}for {red}%d {unique}VikCoins.", client, ObjectName, credits);
			}
			else 
			{
				EmitSoundToClient(client, SOUND_BFAIL);
				CPrintToChat(client, "{red}You don't have enough VikCoins. You need at least %d!.", credits);
				return Plugin_Handled;
			}
			return Plugin_Handled;
		}
		
		if (exp[client] >= credits)
		{
			SetVariantInt(9999);
			AcceptEntityInput(Entity, "RemoveHealth", client, client);
			
			EmitSoundToClient(client, SOUND_BUY);
			exp[client] -= credits
			CPrintToChatAll("{green}%N {default}destroyed {green}%s {default}for {red}%d {default}VikCoins.", client, ObjectName, credits);
		}
		else 
		{
			EmitSoundToClient(client, SOUND_BFAIL);
			CPrintToChat(client, "{red}You don't have enough VikCoins. You need at least %d!.", credits);
			return Plugin_Handled;
		}
	}
	else
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You must be aiming at something for this to work.");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_PayPumpkin(client, args)
{
	new iCreditCost = 125;
	
	decl Float:Position[3];
	if(!SetTeleportEndPoint(client, Position))
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities() - 32)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) == _:TFTeam_Spectator)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}No.");
		return Plugin_Handled
	}
	
	if(NextPumpkinUse[client] >= GetTickedTime())
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}Please wait %.1f seconds!", NextPumpkinUse[client] - GetTickedTime());
		return Plugin_Handled;
	}
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		Position[2] -= 10.0;
		TeleportEntity(iPumpkin, Position, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToClient(client, SOUND_BUY);
		CPrintToChat(client, "You have paid {red}%d {default}VikCoins to spawn a {orange}Pumpkin{default}.", iCreditCost);
		exp[client] -= iCreditCost;
		NextPumpkinUse[client] = GetTickedTime() + 10.0;
	}
	
	return Plugin_Handled;
}

public Action:Command_PayRage(client, args)
{
	new iCreditCost = 150;
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	EmitSoundToClient(client, SOUND_BUY);
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	CPrintToChat(client, "{default}Granted full rage for {red}%d{default} VikCoins.", iCreditCost);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

public Action:Command_Spell(client, args)
{
	if(IsValidClient(client))
	{
		new iCreditCost = 250;
		
		if(NextSpellUse[client] >= GetTickedTime())
		{
			EmitSoundToClient(client, SOUND_BFAIL);
			CPrintToChat(client, "{red}Please wait %.1f seconds!", NextSpellUse[client] - GetTickedTime());
			return Plugin_Handled;
		}
		
		new book = FindBook(client);
		if (book == -1)
		{
			EmitSoundToClient(client, SOUND_BFAIL);
			CPrintToChat(client, "{selfmade}Please equip your {cyan}Spell Book{selfmade}!");
			return Plugin_Handled;
		}
		
		if (exp[client] < iCreditCost)
		{
			EmitSoundToClient(client, SOUND_BFAIL);
			CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
			return Plugin_Handled;
		}
		
		EmitSoundToClient(client, SOUND_BUY);
		
		new rint = GetRandomInt(0,6);
		new charges = GetRandomInt(1,3);
		SetEntProp(book, Prop_Send, "m_iSelectedSpellIndex", rint);
		SetEntProp(book, Prop_Send, "m_iSpellCharges", charges);

		SetHudTextParams(-1.0, 0.65, 6.0, 0, 255, 0, 255);

		if (rint == 0)
			ShowHudText(client, -1, "Rolled spell: Fire Ball [%i Uses]", charges);
		else if (rint == 1)
			ShowHudText(client, -1, "Rolled spell: Bats [%i Uses]", charges);
		else if (rint == 2)
			ShowHudText(client, -1, "Rolled spell: Heal Allies [%i Uses]", charges);
		else if (rint == 3)
			ShowHudText(client, -1, "Rolled spell: Explosive Pumpkins [%i Uses]", charges);
		else if (rint == 4)
			ShowHudText(client, -1, "Rolled spell: Super Jump [%i Uses]", charges);
		else if (rint == 5)
			ShowHudText(client, -1, "Rolled spell: Invisibility [%i Uses]", charges);
		else if (rint == 6)
			ShowHudText(client, -1, "Rolled spell: Teleport [%i Uses]", charges);
		else if (rint == 7)		//Rare spells
			ShowHudText(client, -1, "Rolled spell: Magnetic Bolt");
		else if (rint == 8)
			ShowHudText(client, -1, "Rolled spell: Shrink");
		else if (rint == 9)
			ShowHudText(client, -1, "Rolled spell: Summon MONOCULUS!");
		else if (rint == 10)
			ShowHudText(client, -1, "Rolled spell: Fire Storm");
		else if (rint == 11)
			ShowHudText(client, -1, "Rolled spell: Summon Skeletons");
		
		CPrintToChat(client, "{default}You rolled a {cyan}Regular Spell{default} for {red}%d{default} VikCoins.", iCreditCost);
		exp[client] -= iCreditCost;
		NextSpellUse[client] = GetTickedTime() + 60.0;
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_RareSpell(client, args)
{
	new iCreditCost = 350;
	
	if(NextRareSpellUse[client] >= GetTickedTime())
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}Please wait %.1f seconds!", NextRareSpellUse[client] - GetTickedTime());
		return Plugin_Handled;
	}
	
	new book = FindBook(client);
	if (book == -1)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{selfmade}Please equip your {cyan}Spell Book{selfmade}!", iCreditCost);
		return Plugin_Handled;
	}
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	EmitSoundToClient(client, SOUND_BUY);
	AcceptEntityInput(client, "RollRareSpell");
	CPrintToChat(client, "{default}You rolled a {cyan}Rare Spell{default} for {red}%d{default} VikCoins.", iCreditCost);
	exp[client] -= iCreditCost;
	NextRareSpellUse[client] = GetTickedTime() + 120.0;
	return Plugin_Handled;
}

public Action:Command_PayRegen(client, args)
{
	new Float:Length = 30.0;
	new Float:Interval = 0.1;
	new AmountHeal = 1;
	if (args >= 1)
	{
		decl String:Arg1[8];
		GetCmdArg(1, Arg1, sizeof(Arg1));
		Length = StringToFloat(Arg1);
	}
	if (args >= 2)
	{
		decl String:Arg2[8];
		GetCmdArg(2, Arg2, sizeof(Arg2));
		Interval = FloatAbs(StringToFloat(Arg2));
	}
	if (args >= 3)
	{
		decl String:Arg3[8];
		GetCmdArg(3, Arg3, sizeof(Arg3));
		AmountHeal = StringToInt(Arg3);
	}
	
	new iCreditCost = RoundToNearest(Length * (Pow(Interval, -1.0)) * AmountHeal);
	
	if (exp[client] < iCreditCost)
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You need at least %d VikCoins!", iCreditCost);
		return Plugin_Handled;
	}
	
	if (!SetClientRegenerateHealth(client, true, Length, Interval, AmountHeal))
	{
		EmitSoundToClient(client, SOUND_BFAIL);
		CPrintToChat(client, "{red}You're currently in a regen loop!");
		return Plugin_Handled;
	}
	
	EmitSoundToClient(client, SOUND_BUY);
	CPrintToChat(client, "{default}You've paid {red}%d{default} VikCoins for health regeneration.", iCreditCost);
	exp[client] -= iCreditCost;
	return Plugin_Handled;
}

stock bool:SetClientRegenerateHealth(client, bool:Regen, Float:RegenTime=0.0, Float:RegenRate=0.0, RegenAmount=0)
{
	if (Regen)
	{
		if (ClientsRegenerating[client] != INVALID_HANDLE)
			return false;
		new Handle:Pack = INVALID_HANDLE;
		new Handle:Timer = INVALID_HANDLE;
		Timer = CreateDataTimer(RegenRate, Timer_RegenHealth, Pack, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
		WritePackCell(Pack, client);
		WritePackCell(Pack, RegenAmount);
		WritePackFloat(Pack, RegenTime);
		WritePackFloat(Pack, RegenRate);
		ClientsRegenerating[client] = Timer;
		EmitSoundToAll(SOUND_TF2ANTHEM, client, _, _, _, _, _, _, _, _, _, RegenTime);
		return true;
	}
	else
	{
		if (ClientsRegenerating[client] != INVALID_HANDLE)
			KillTimer(ClientsRegenerating[client], true);
		ClientsRegenerating[client] = INVALID_HANDLE;
		PrintCenterText(client, "");
		return true;
	}
}

public Action:Timer_RegenHealth(Handle:timer, Handle:Datapack)
{
	ResetPack(Datapack);
	new client = ReadPackCell(Datapack);
	if(IsValidClient(client))
	{
		new amount = ReadPackCell(Datapack);
		new Float:fTimeLeft = ReadPackFloat(Datapack);
		new Float:fTimeInterval = ReadPackFloat(Datapack);
		fTimeLeft -= fTimeInterval;
		ResetPack(Datapack, true);
		WritePackCell(Datapack, client);
		WritePackCell(Datapack, amount);
		WritePackFloat(Datapack, fTimeLeft);
		WritePackFloat(Datapack, fTimeInterval);
		
		new m_OffsetHealth = FindDataMapOffs(client, "m_iHealth");
		new m_OffsetMaxHealth = FindDataMapOffs(client, "m_iMaxHealth");
		new Health = GetEntData(client, m_OffsetHealth, 4);
		new MaxHealth = GetEntData(client, m_OffsetMaxHealth, 4);
		if (Health + amount < MaxHealth)
			SetEntData(client, m_OffsetHealth, Health + amount, 4, true);
		//else
			//SetEntData(client, m_OffsetHealth, MaxHealth, 4, true);
			
		else if (Health + amount >= MaxHealth && Health + RoundToCeil(amount * 0.5) <= MaxHealth * 2.5)
		{
			if (RoundToCeil(amount * 0.5) == 1)
				amount *= 2;
			SetEntData(client, m_OffsetHealth, Health + RoundToCeil(amount * 0.5), 4, true);
		}
		//else if (Health > MaxHealth * 2.5)
		//{
			//SetEntData(client, m_OffsetHealth, Health, 4, true);
		//}
		
		TF2_AddCondition(client, TFCond_MegaHeal, fTimeInterval + 0.1);
		
		PrintCenterText(client, "%.1f", fTimeLeft);
		
		if (fTimeLeft <= 0)
		{
			SetClientRegenerateHealth(client, false);
			PrintCenterText(client, "");
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:Timer_GambleCountDown(Handle:timer, Handle:datapack)
{
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	new Cost = ReadPackCell(datapack);
	new Time = ReadPackCell(datapack);
	decl String:name[256];
	decl String:newname[256];
	ReadPackString(datapack, name, sizeof(name));
	
	if (IsClientInGame(client))
		GetClientName(client, newname, sizeof(newname));
	else
		return Plugin_Stop;
 
	Time--;
	if (strcmp(name, newname, true) != 0)
		return Plugin_Stop;
	
	ResetPack(datapack);
	WritePackCell(datapack, client);
	WritePackCell(datapack, Cost);
	WritePackCell(datapack, Time);
	WritePackString(datapack, name);
	
	PrintCenterText(client, "%d", Time);
	
	if (Time == 0)
	{
		new Credits = GetRandomInt(-500, 500);
		Credits = RoundToFive(Credits);
		PrintCenterText(client, " ");
		
		if(Credits > 0)
			CPrintToChat(client, "{green}Winnings{default}: {green}%d {default}VikCoins", Credits);
		else
		{
			new loss = exp[client] -= Credits;
			if(loss <= -1)
			{
				Credits = 0;
				exp[client] = Credits;
				CPrintToChat(client, "{red}Losses{default}: {red}ALL {default}your VikCoins!");
			}
			else
				CPrintToChat(client, "{red}Losses{default}: {red}%d {default}VikCoins", Credits);
		}
		
		exp[client] += Credits;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:DeleteMoney(Handle:timer, any:entity) 
{
	new ent = EntRefToEntIndex(entity);
	if (ent != INVALID_ENT_REFERENCE && ent > 0 && IsValidEntity(ent))
	{
		decl String:sClass[32];
		GetEntityClassname(ent, sClass, sizeof(sClass));
	
		if(StrEqual(sClass, "item_currencypack_small") || StrEqual(sClass, "item_currencypack_medium") || StrEqual(sClass, "item_currencypack_large"))
		{
			new Float:zPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", zPos);
			CreateParticle("mvm_cash_explosion", zPos);
			EmitSoundToAll(SOUND_DISAPPEAR, ent);
			AcceptEntityInput(ent, "Kill");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public DisplayPlayerScoreMenu(client, target)
{
	decl String:item2[200];
	decl String:item4[200];
	decl String:p_name[200];
	
	Format(item2, sizeof(item2), "VikCoins : %i", exp[target]);
	GetClientName(target, p_name, sizeof(p_name))
	Format(item4, sizeof(item4), "%ss Stats", p_name);
	
	new Handle:menu = CreateMenu(MenuHandler1); 
	SetMenuTitle(menu, item4);
	AddMenuItem(menu, "VikCoins", item2); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)  
{        
	if (action == MenuAction_End)  
	{  
		if(menu != INVALID_HANDLE)
		{
			CloseHandle(menu);
		} 
	} 
} 

public Action:DisplayPlayerMenu(client)
{
	decl String:name[200];
	decl String:random_g[80];
	new Handle:menuPlayer = CreateMenu(MenuHandler2); 
	SetMenuTitle(menuPlayer, "Select a player :");
	
	if(MaxClients == 1)
	{
		CPrintToChat(client, "{green}[VikCoins] You are the only player now !");
		return Plugin_Stop;
	}
	
	for(new i = 0; i < MaxClients; i++) 
	{ 
		if(i > 0 && i <= MaxClients && IsClientInGame(i) && i != client) 
		{
			GetClientName(i, name, sizeof(name)); 
			IntToString(i, random_g, sizeof(random_g));
			AddMenuItem(menuPlayer, random_g, name);
		} 
	}  
	SetMenuExitButton(menuPlayer, true); 
	DisplayMenu(menuPlayer, client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

public MenuHandler2(Handle:menu, MenuAction:action, client, param2)  
{    
	if (action == MenuAction_Select && IsClientInGame(client))  
	{
		decl String:szInfo[8];
		GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
		new target = StringToInt(szInfo)
		DisplayPlayerScoreMenu(client, target);
	}
	else if (action == MenuAction_End)  
	{  
		if(menu != INVALID_HANDLE)
		{
			CloseHandle(menu);
		} 
	} 
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock RoundToCeilPowerOfTwo(i)
{
	new bool:BelowZero = (i < 0);
	
	if (BelowZero)
		i *= -1;
	i--;
	i |= i >> 1;
	i |= i >> 2;
	i |= i >> 4;
	i |= i >> 8;
	i |= i >> 16;
	i++;
	
	if (BelowZero)
		i *= -1;
	
	return i;
}

stock Float:GetDistanceTotal(Float:vec1[3], Float:vec2[3])
{
	new Float:vec[3];
	for (new i = 0; i < 3; i++)
	{
		vec[i] = (vec1[i] > vec2[i]) ? vec1[i] - vec2[i] : vec2[i] - vec1[i];
	}
	return SquareRoot(Pow(vec[0], 2.0) + Pow(vec[1], 2.0) + Pow(vec[2], 2.0));
}

public Delay(client)
{
	g_delay[client] = 10;
	CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	g_delay[client]--;
	if (g_delay[client])
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public TPDelay(client)
{
	g_TPdelay[client] = 8;
	CreateTimer(1.0, Timer_TPDelay, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_TPDelay(Handle:timer, any:client)
{
	g_TPdelay[client]--;
	if (g_TPdelay[client])
		CreateTimer(1.0, Timer_TPDelay, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

bool:SetTeleportEndPoint(client, Float:Position[3])
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer2);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		Position[0] = vStart[0] + (vBuffer[0]*Distance);
		Position[1] = vStart[1] + (vBuffer[1]*Distance);
		Position[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer2(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

stock UpdatePlayerHitbox(const client, const Float:fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
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

stock FindBook(client)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
		{
			return i;
		}
	}
	return -1;
}

stock KillWearables(client)
{
	new count;
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[35];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue;
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue;
		
		AcceptEntityInput(z, "Kill");
		count++;
	}
	return count;
}

stock RoundToFive(input)
{
	new bool:BelowZero = (input < 0);

	new remainder = input % 5;
	if (remainder == 0) return input;
	if (remainder == 1 || remainder == 2) return (input-remainder);
	if (remainder == 3 || remainder == 4) return (input+(5-remainder));
	
	if (BelowZero)
		remainder *= -5;
		
	return remainder;
}

stock bool:IsValidKill(client, attacker)
{
	if(client != 0 && attacker != 0 && client != attacker && client <= MaxClients && attacker <= MaxClients && GetClientTeam(client) != GetClientTeam(attacker))
		return true;
		
	return false
}

stock DisplayMenuSafely(Handle:menu, client)
{
	if (client != 0)
	{
		g_hMenuMain = CreateMenu(MenuMainHandler);
		SetMenuTitle(g_hMenuMain, "Spend your VikCoins [%i] : [%i] VikTokens", exp[client], g_iVikTokens[client]);
		AddMenuItem(g_hMenuMain, "1", "Gamble [125]");
		AddMenuItem(g_hMenuMain, "2", "Teleport [Dist. Based]");
		AddMenuItem(g_hMenuMain, "3", "Destroy [Targ. Based]");
		AddMenuItem(g_hMenuMain, "4", "Buy a pumpkin [125]");
		AddMenuItem(g_hMenuMain, "5", "Buy rage [150]");
		AddMenuItem(g_hMenuMain, "6", "Buy regen [Dur. Based]");
		AddMenuItem(g_hMenuMain, "7", "Buy a random Regular Spell [250]");
		AddMenuItem(g_hMenuMain, "8", "Buy a random Rare Spell [350]");
		AddMenuItem(g_hMenuMain, "9", "Become a Giant [500]");
		AddMenuItem(g_hMenuMain, "10", "Buy a Speed Boost [200]");
		AddMenuItem(g_hMenuMain, "11", "Disguise as a random prop [250]");
		AddMenuItem(g_hMenuMain, "12", "Become the Sp00py skeleton [250]");
		AddMenuItem(g_hMenuMain, "13", "Enable High Rocket Jumps [1250]");
		AddMenuItem(g_hMenuMain, "14", "Be the Giant Deflector Heavy [16,000]");
		AddMenuItem(g_hMenuMain, "15", "Be Sir Nukesalot [20,000]");
		AddMenuItem(g_hMenuMain, "16", "Buy a Big Head [50] SALE!");
		AddMenuItem(g_hMenuMain, "17", "Buy a Small Head [50] SALE!");
		AddMenuItem(g_hMenuMain, "18", "Spin the wheel [1000]");
		AddMenuItem(g_hMenuMain, "19", "BUMPERCARS! [600]");
		AddMenuItem(g_hMenuMain, "20", "Noclip [15,000]");
		AddMenuItem(g_hMenuMain, "21", "TeamHeal [Dur. Based][400]");
		AddMenuItem(g_hMenuMain, "22", "Swim in air [3000]");
		AddMenuItem(g_hMenuMain, "23", "Make you shine [100]");
		AddMenuItem(g_hMenuMain, "24", "Buy VikToken [10,000]");
		AddMenuItem(g_hMenuMain, "25", "Buy Infinite SpeedBoost [20 VikTokens]");
		DisplayMenu(g_hMenuMain, client, MENU_TIME_FOREVER);
	}
}

stock AttachParticle2(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flZOffset=0.0, Float:flSelfDestruct=0.0) 
{ 
	new iParticle = CreateEntityByName("info_particle_system"); 
	if( !IsValidEdict(iParticle) ) 
		return 0; 
	 
	new Float:flPos[3]; 
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos); 
	flPos[2] += flZOffset; 
	 
	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR); 
	 
	DispatchKeyValue(iParticle, "effect_name", strParticleEffect); 
	DispatchSpawn(iParticle); 
	 
	SetVariantString("!activator"); 
	AcceptEntityInput(iParticle, "SetParent", iEntity); 
	ActivateEntity(iParticle); 
	 
	if(strlen(strAttachPoint)) 
	{ 
		SetVariantString(strAttachPoint); 
		AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset"); 
	} 
	 
	AcceptEntityInput(iParticle, "start"); 
	 
	g_particleEnt[iEntity] = EntIndexToEntRef(iParticle);
	 
	if(flSelfDestruct > 0.0)
		CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle)); 
	 
	return iParticle; 
}

public Action:Timer_DeleteParticle(Handle:hTimer2, any:iRefEnt) 
{ 
    new iEntity = EntRefToEntIndex(iRefEnt); 
    if(iEntity > MaxClients) 
        AcceptEntityInput(iEntity, "Kill"); 
     
    return Plugin_Handled; 
}

public Native_GetFraglets(Handle:plugin, args)
{
	return exp[GetNativeCell(1)];
}

public Native_SetFraglets(Handle:plugin, args)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);

	if (amount <= 0) 
		return;
	
	if(IsValidClient(client))
	{
		exp[client] = amount;
	}
}
	
public Native_AddFraglets(Handle:plugin, args)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);

	if (amount <= 0) 
		return;
	
	if(IsValidClient(client))
	{
		exp[client] += amount;
	}
}