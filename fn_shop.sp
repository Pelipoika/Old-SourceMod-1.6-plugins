#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2items>
#include <tf2_build>
#include <tf2_meter>
#include <tf2_stocks>
#include <tf2_objects>
#include <tf2_uber>
#include <tf2itemsinfo>
#include <sdkhooks>
#include <morecolors>
#include <geoip>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#include <MerbosMagic>
 
#pragma semicolon 1 

// #define DEBUG

#define SOUND_OBJECTGRABBED					"vo/medic_mvm_get_upgrade03.wav"
#define SOUND_KEYFROMGRAB					"vo/scout_sf12_goodmagic04.wav"
#define SOUND_GIFTISTIMEBOMB				"vo/heavy_cartmovingforwardoffense15.wav"
#define SOUND_ACHIEVEMENTUNLOCKED			"misc/achievement_earned.wav"
#define SOUND_ITEMPICKUP					"items/gift_pickup.wav"
#define SOUND_EXPLODE						"items/cart_explode.wav"
#define SOUND_TF2ANTHEM						"ui/gamestartup1.mp3"

#define SOUND_CUSTOM_NO 					"MerbosMagic/demoman_no_earrape.wav"
#define SOUND_CUSTOM_FREEFORMJAZZ 			"MerbosMagic/freeformjazz.wav"
#define SOUND_CUSTOM_SMOKEWEEDEVERYDAY 		"MerbosMagic/medic_swed.wav"
#define SOUND_CUSTOM_IAMDEADTHATSGOODAMEN 	"MerbosMagic/soldier_ded.wav"
#define SOUND_CUSTOM_SURPRISEMOFO 			"MerbosMagic/surprise_mofo.wav"
#define SOUND_CUSTOM_DONTSTOPMENOW 			"MerbosMagic/tf_domination_dontstopmenow.wav"
#define SOUND_CUSTOM_LEMONS 				"MerbosMagic/airblast_lemons.wav"
#define SOUND_CUSTOM_SAVEASDMX				"MerbosMagic/save as .dmx.wav"

#define MODEL_PUMPKINLOOT					"models/props_halloween/pumpkin_loot.mdl"
#define MODEL_HALLOWEENGIFT					"models/props_halloween/halloween_gift.mdl"
#define MODEL_GIFT							"models/items/tf_gift.mdl"

/*
 * GLOBALS
 * 
 * Objects accessible anywhere in this file
 */

enum GiftType
{
	GIFTTYPE_SUPER,
	GIFTTYPE_REGEN,
	GIFTTYPE_CREDITS,
	GIFTTYPE_DEFAULT
};	
 
#define GiftPositions__achievement_idle_merbo_count 15
new Float:GiftPositions__achievement_idle_merbo[GiftPositions__achievement_idle_merbo_count][3] =
{
	{1405.041015, 31.043567, 477.412658},
	{1082.464355, 32.445129, 470.298065},
	{778.227050, 31.928030, 473.849182},
	{1026.706787, 605.531860, 407.273925},
	{1026.593994, -432.889648, 409.925048},
	{-202.984664, 424.962219, 295.507019},
	{-208.143402, 44.608348, 383.621551},
	{-124.078674, -391.929168, 293.984283},
	{160.233367, -45.848838, -118.885665},
	{191.778335, 116.217658, -115.674530},
	{-808.152893, 36.796947, 20.405906},
	{-3971.770751, -690.155761, 289.735229},
	{-85.101127, -298.931182, 2611.511718},
	{1968.865722, 1031.861816, 2611.164794},
	{2376.998046, 25.457355, 1704.946533}
};

#define GiftPositions__merbosmagic_minecraft_count 7
new Float:GiftPositions__merbosmagic_minecraft[GiftPositions__merbosmagic_minecraft_count][3] =
{
	{-999.847167, -662.388305, -760.750000},
	{999.847167,  -662.388305, -760.750000},
	{1496.468383,  36.458190, 64.164924},
	{-1496.468383, 36.458190, 64.164924},
	{-1503.004150, -1567.863525, 68.022224},
	{1503.004150,  -1567.863525, 68.022224},
	{935.521850, -3752.433593, -1995.793212}
};

#define GiftPositions__merbosmagic_idle_count 10
new Float:GiftPositions__merbosmagic_idle[GiftPositions__merbosmagic_idle_count][3] =
{
	{0.905937, -907.224792, 127.597778},
	{923.065185, -944.634399, 293.629577},
	{-2.739831, 295.650939, 1054.237792},
	{1.941331, -680.275756, 783.789672},
	{0.418946, -1855.785278, 997.485046},
	{-0.647483, -2463.093017, 1111.020996},
	{-767.596374, -1408.015747, 1017.025878},
	{767.666564, -1375.567993, 1017.025878},
	{936.074707, -873.322753, 405.610992},
	{-930.484375, -873.304382, 407.108459}
};

/*
 * CVARS
 * 
 * Variables settable in console
 */
new Handle:sm_shop_url = INVALID_HANDLE;
new Handle:sm_shop_default_credits = INVALID_HANDLE;
new Handle:sm_customitems_enabled = INVALID_HANDLE;
new Handle:sm_gamble_cost = INVALID_HANDLE;
new Handle:sm_gamble_timer = INVALID_HANDLE;
new Handle:sm_enable_anti_wm1 = INVALID_HANDLE;
new Handle:sm_disable_sentrybusters = INVALID_HANDLE;
 
new Handle:ClientsRegenerating[MAXPLAYERS + 1]; 
new clientWM1[MAXPLAYERS + 1];

new Float:cheapshotClients[MAXPLAYERS + 1];
new Float:facestabClients[MAXPLAYERS + 1];

/*
 * BASIC PLUGIN INFORMATION
 * 
 * Allows sourcemod to load plugin and get information
 */
 
public Plugin:myinfo =
{
	name = "mm_Shop",
	author = "Merbo",
	description = "MerbosMagic Shop Plugin",
	version = "1.0.0.0",
	url = "http://tf2.merbo.org"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    decl String:strModName[32];
    GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf"))
    {
        Format(error, err_max, "This plugin is only for Team Fortress 2");
        return APLRes_Failure;
    }
    if (!IsDedicatedServer())
    {
        Format(error, err_max, "This plugin should only be run on a dedicated server");
        return APLRes_Failure;
    }

    if (late)
    {
    	FixPlayerSDKHooks();
    }

    return APLRes_Success;
}

FixPlayerSDKHooks()
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_OBJECTGRABBED);
	PrecacheSound(SOUND_KEYFROMGRAB);
	PrecacheSound(SOUND_GIFTISTIMEBOMB);
	PrecacheSound(SOUND_ACHIEVEMENTUNLOCKED);
	PrecacheSound(SOUND_ITEMPICKUP);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_TF2ANTHEM);
	
	AddSoundToDownloadsTable(SOUND_CUSTOM_DONTSTOPMENOW);
	AddSoundToDownloadsTable(SOUND_CUSTOM_FREEFORMJAZZ);
	AddSoundToDownloadsTable(SOUND_CUSTOM_IAMDEADTHATSGOODAMEN);
	AddSoundToDownloadsTable(SOUND_CUSTOM_NO);
	AddSoundToDownloadsTable(SOUND_CUSTOM_SMOKEWEEDEVERYDAY);
	AddSoundToDownloadsTable(SOUND_CUSTOM_SURPRISEMOFO);
	AddSoundToDownloadsTable(SOUND_CUSTOM_LEMONS);
	AddSoundToDownloadsTable(SOUND_CUSTOM_SAVEASDMX);
	
	PrecacheModel(MODEL_PUMPKINLOOT, true);
	PrecacheModel(MODEL_HALLOWEENGIFT, true);
	PrecacheModel(MODEL_GIFT, true);
	
	CreateTimer(600.0, Timer_Spam, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(30.0, Timer_AssignTeam, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, Timer_CheckWM1, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "achievement_idle_merbo", false) > -1 ||
		StrContains(MapName, "merbosmagic_minecraft", false) > -1  ||
		StrContains(MapName, "merbosmagic_idle_", false) > -1)
	{
		PrintHintTextToAll("Random gift spawning enabled!");
		CreateTimer(45.0, Timer_CreateGift, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Spam(Handle:Timer)
{
	Event_Spam(INVALID_HANDLE, "", false);
}

/*
 * OnPluginStart()
 * Called when plugin starts
 * Almost like an entry point
 */
 
public OnPluginStart()
{

	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_shop", Command_Shop, "Shows the MerbosMagic shop");
	RegConsoleCmd("sm_register", Command_Register, "Allows a person to register to the shop");
	RegConsoleCmd("sm_r", Command_Register, "Allows a person to register to the shop");
	RegConsoleCmd("sm_buycredits", Command_BuyCredits, "Allows a person to purchase credits using the shop");
	RegConsoleCmd("sm_credits", Command_Credits, "Allows a person to view their credits");
	RegConsoleCmd("sm_tp", Command_TP, "Allows a player to teleport to another player at the cost of credits");
	RegConsoleCmd("sm_destroy", Command_Destroy, "Allows a person to pay credits for the destruction of an engi building that they're looking at.");
	RegConsoleCmd("sm_gamble", Command_Gamble, "Allows a player to gamble credits for a chance at more credits");
	RegConsoleCmd("sm_checkitemcost", Command_CheckItemCost, "Allows a player to check a custom item's cost");
	RegConsoleCmd("sm_paypumpkin", Command_PayPumpkin, "Allows a player to spawn a pumpkin for credits");
	RegConsoleCmd("sm_paygift", Command_PayGift, "Allows a player to spawn a fake halloween gift for credits");
	RegConsoleCmd("sm_payrage", Command_PayRage, "Allows a player to pay for full rage");
	RegConsoleCmd("sm_payregen", Command_PayRegen, "Allows a player to pay for health regeneration");
	
	RegAdminCmd("sm_customitems", Command_CustomItems, ADMFLAG_SLAY, "Allows an admin to turn on/off custom items.");
	RegAdminCmd("sm_myfov", Command_FoV, ADMFLAG_CHEATS, "Sets your FoV.");
	RegAdminCmd("sm_modcredits", Command_ModCredits, ADMFLAG_ROOT, "Allows an admin to give/take credits on a user's SQL account.");
	RegAdminCmd("sm_give", Command_Give, ADMFLAG_SLAY, "Allows an admin to give another user an item.");
	RegAdminCmd("sm_violenttimebomb", Command_ViolentTimeBomb, ADMFLAG_SLAY, "Allows an admin to timebomb somebody and cause a very violent death");
	RegAdminCmd("sm_reloadshoplate", Command_CheckPlayers, ADMFLAG_SLAY, "Reruns all player checks");
 
	sm_shop_url = CreateConVar("sm_shop_url", "http://173.48.94.88/TF2/Shop.aspx", "Default shop page URL");
	sm_shop_default_credits = CreateConVar("sm_shop_default_credits", "1000", "Default amount of credits clients using /register get.");
	sm_customitems_enabled = CreateConVar("sm_customitems_enabled", "1", "Enable custom items?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_gamble_cost = CreateConVar("sm_gamble_cost", "1024", "How much should it cost to gamble?");
	sm_gamble_timer = CreateConVar("sm_gamble_timer", "5", "How long will it take for the gamble timer to count down?", 0, true, 5.0);
	sm_enable_anti_wm1 = CreateConVar("sm_enable_anti_wm1", "1", "Blow up pyros that W+M1?", 0, true, 0.0, true, 1.0);
	sm_disable_sentrybusters = CreateConVar("sm_disable_sentrybusters", "1", "Kill all sentry busters?", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "mm_Shop");
	
	AddCommandListener(say, "say");
	AddCommandListener(say_team, "say_team");

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("mvm_begin_wave", Event_Spam);
	HookEvent("christmas_gift_grab", Event_GrabbedObject);
	HookEvent("halloween_pumpkin_grab", Event_GrabbedObject);
	HookEvent("object_destroyed", Event_ObjDestroyed);
	HookEvent("mvm_tank_destroyed_by_players", Event_TankDestroyed);
	HookEvent("player_teleported", Event_PlayerTeleported);
	HookEvent("player_destroyed_pipebomb", Event_PipebombDestroyed);
	HookEvent("player_healed", Event_PlayerHealed);
	HookEvent("item_found", Event_ItemFound);
	HookEvent("player_chargedeployed", Event_UberDeployed);
	HookEvent("object_deflected", Event_Airblast);
	HookEvent("ctf_flag_captured", Event_FlagCapped);
	HookEvent("medic_death", Event_MedicDeath);
	HookEvent("player_changename", Event_PlayerChangeName);
	HookEvent("player_spawn", Event_PlayerSpawn);

	
	AddTempEntHook("Player Decal", OnClientSpray);
	
	AddCommandListener(voicemenu, "voicemenu");
	
	InitSQL();
	InitSDK();
}

public OnClientConnected(client)
{
	ClientsRegenerating[client] = INVALID_HANDLE;
	clientWM1[client] = 0;
}
public OnClientDisconnect(client)
{
	ClientsRegenerating[client] = INVALID_HANDLE;
	clientWM1[client] = 0;

	cheapshotClients[client] = 0.0;
	facestabClients[client] = 0.0;
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_GetMaxHealth, GetMaxHealthBot);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	decl String:Name[MAX_NAME_LENGTH];
	GetClientName(client, Name, sizeof(Name));
	GetClientNameWithInfo(client, Name, sizeof(Name));
	new Handle:Datapack = INVALID_HANDLE;
	CreateDataTimer(15.0, Timer_Rename, Datapack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	WritePackCell(Datapack, GetClientUserId(client));
	WritePackString(Datapack, Name);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new bool:Modified = false;
	
	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	if (damagecustom == TF_CUSTOM_BACKSTAB)
	{
		if (!IsFakeClient(attacker) && !IsFakeClient(victim) && IsClientF2P(attacker, true) && !IsClientF2P(victim, true) && !IsRegistered(attacker, mm_hDatabaseSQL, false, true) && IsRegistered(victim, mm_hDatabaseSQL, false, true))
		{
			damage = 0.0;
			Modified = true;
			CPrintToChat(attacker, "{default}Unregistered free to plays can't backstab registered pay to plays!");
		}
	}
	if (damagetype & DMG_CRIT)
	{
		if (!IsFakeClient(attacker) && !IsFakeClient(victim) && IsClientF2P(attacker, true) && !IsClientF2P(victim, true) && !IsRegistered(attacker, mm_hDatabaseSQL, false, true) && IsRegistered(victim, mm_hDatabaseSQL, false, true))
		{
			damagetype &= ~DMG_CRIT;
			Modified = true;
			CPrintToChat(attacker, "{default}Unregistered free to plays do not do crit damage to registered pay to plays!");
		}
	}

	if (IsMerbo(victim))
	{
		if (damagetype & DMG_CRIT)
		{
			damage *= 0.75;
			Modified = true;
		}
		else
		{
			if (!IsFakeClient(attacker) && IsClientF2P(attacker, true))
			{
				damage *= 0.5;
				Modified = true;
			}
		}
	}
	if (IsMerbo(attacker))
	{
		if (weapon > 0)
		{
			new ItemDef = GetWeaponItemDef(weapon);
			if (ItemDef == 4 || ItemDef == 194 || ItemDef == 665 || ItemDef == 225 || ItemDef == 356 || 
				ItemDef == 461 || ItemDef == 574 || ItemDef == 649 || ItemDef == 423 || ItemDef == 638 || 
				ItemDef == 727) //Knives
			{
				if (GetRandomInt(1, 
					(TF2_GetPlayerClass(victim) == TFClass_Pyro || TF2_GetPlayerClass(victim) == TFClass_Spy) ? 4 : 
					((damage >= GetClientHealth(victim)) ? 2 : 8)
					) == 1 && damagecustom != TF_CUSTOM_BACKSTAB)
				{
					damagecustom = TF_CUSTOM_BACKSTAB;
					damagetype |= DMG_CRIT;
					Modified = true;
					damage = 6.0 * float(GetClientHealth(victim));
					if (ItemDef == 356)
					{
						new m_OffsetHealth = FindDataMapOffs(attacker, "m_iHealth");
						SetEntData(attacker, m_OffsetHealth, (GetClientHealth(victim) + GetClientHealth(attacker) > 180 ? 180 : GetClientHealth(victim) + GetClientHealth(attacker)), 4, true);
					}
					facestabClients[victim] = GetEngineTime();
					if (ItemDef == 4 || ItemDef == 194 || ItemDef == 665)
						SetViewmodelAnimation(attacker, 6);
					if (ItemDef == 225 || ItemDef == 356 || ItemDef == 461 || ItemDef == 574 || ItemDef == 649)
						SetViewmodelAnimation(attacker, 11);
					if (ItemDef == 423) SetViewmodelAnimation(attacker, 11);
					if (ItemDef == 638) SetViewmodelAnimation(attacker, 27);
					if (ItemDef == 727) SetViewmodelAnimation(attacker, 37);
				}
			}
			else if (ItemDef == 1006) //Amby
			{
				if (GetRandomInt(1, (TF2_GetPlayerClass(victim) == TFClass_Pyro || TF2_GetPlayerClass(victim) == TFClass_Sniper ? 3 : 6)) == 1 && damagecustom != TF_CUSTOM_HEADSHOT)
				{
					damagecustom = TF_CUSTOM_HEADSHOT;
					damage = 48.4;
					damagetype |= DMG_CRIT;
					Modified = true;
					cheapshotClients[victim] = GetEngineTime();
				}
			}
			else if (ItemDef == 201) //Strange sniper
			{
				if (GetRandomInt(1, (TF2_GetPlayerClass(victim) == TFClass_Sniper ? 3 : 6)) == 1 && damagecustom != TF_CUSTOM_HEADSHOT)
				{
					damagecustom = TF_CUSTOM_HEADSHOT;
					damage = 50.0 * GetRandomFloat(1.0, 3.0);
					damagetype |= DMG_CRIT;
					Modified = true;
					cheapshotClients[victim] = GetEngineTime();
				}
			}
		}
	}
	if (attacker > MaxClients || attacker < 1)
		return Plugin_Continue;
	if (IsFakeClient(attacker) && !IsFakeClient(victim))
	{
		damage *= 0.66;
		Modified = true;
	}
	if (Modified)
		return Plugin_Changed;
	return Plugin_Continue;
}
public Action:GetMaxHealthBot(client, &MaxHealth)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsFakeClient(client))
		{
			MaxHealth = RoundToNearest(MaxHealth * 0.5);
			return Plugin_Changed;
		}
		new bool:Modified = false;
		if (IsClientF2P(client, true))
		{
			MaxHealth = RoundToNearest(MaxHealth * 0.75);
			Modified = true;
		}
		if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
		{
			MaxHealth = RoundToNearest(MaxHealth * 0.875);
			Modified = true;
		}
		if (Modified)
			return Plugin_Changed;
	}
	return Plugin_Continue;
}
/* 
 * COMMANDS
 * 
 * Executable by players only, mostly
 */
 

public Action:Command_ModCredits(client, args)
{
	decl String:sTarget[256-16];
	decl String:sCredits[16];
	decl String:full[256];

	if (args != 2)
	{
		CReplyToCommand(client, "{urple}Usage: {default}/modcredits <{cyan}\"target\"{default}> <{blue}amount{default}>");
		return Plugin_Handled;
	}
		
	GetCmdArgString(full, sizeof(full));
	for (new i=1; i<=args; i++)
	{
		if (i == 1)
			GetCmdArg(i, sTarget, sizeof(sTarget));
		else if (i == 2)
			GetCmdArg(i, sCredits, sizeof(sCredits));
	}
	
	new Target = FindTarget(client, sTarget, true, false);
	new Credits = StringToInt(sCredits);
	
	if (Target == -1)
	{
		CReplyToCommand(client, "{red}The client {cyan}\"%s\" {red}does not exist.", sTarget);
		return Plugin_Handled;
	}
	
	if (Credits == 0)
	{
		CReplyToCommand(client, "{red}Why would you make a change of 0?");
		return Plugin_Handled;
	}
	
	decl String:AdminName[64];
	decl String:TargetName[64];
	
	GetClientName(client, AdminName, sizeof(AdminName));
	GetClientName(Target, TargetName, sizeof(TargetName));
	
	if (!IsRegistered(Target, mm_hDatabaseSQL, false, true))
	{
		ReplyToCommand(client, "{red}The client {cyan}\"%s\" {red}is not registered.", TargetName);
		return Plugin_Handled;
	}
	
	decl String:Query[256];
	decl String:SteamID[64];
	GetClientAuthString(Target, SteamID, sizeof(SteamID));
	
	Format(Query, sizeof(Query), "UPDATE users SET credits = credits + %d WHERE steamid = '%s'", Credits, SteamID);
	
	SQL_TFastQuery(mm_hDatabaseSQLT, Query);
	
	CReplyToCommand(client, "Modified {blue}%s{default}'s credits by %s%d.", TargetName, (Credits < 0) ? "{red}" : "{green}" ,Credits);
	CPrintToChat(Target, "{blue}%s {default}has modified your credits by %s%d.", AdminName, (Credits < 0) ? "{red}" : "{green}", Credits);
	
	return Plugin_Handled;
}
 
public Action:Command_Shop(client, args)
{
	decl String:URL[128];
	GetConVarString(sm_shop_url, URL, sizeof(URL));
	
	if (IsRegistered(client, mm_hDatabaseSQL, false, true))
		ShowMOTDPanel(client, "Fragnet Shop", URL, MOTDPANEL_TYPE_URL);
	else
		CPrintToChat(client, "Type {red}/register {default}first. You must register to use the shop.");
	return Plugin_Handled;
} 

public Action:Command_Register(client, args)
{
	decl String:username[128];
	decl String:password[128];
	decl String:full[256];
	decl String:SteamID[64];
	
	if (args != 2)
	{
		CReplyToCommand(client, "{purple}Usage: {default}/register <{cyan}\"username\"{default}> <{cyan}\"password\"{default}>");
		CReplyToCommand(client, "{purple}Example: {default}/register {cyan}\"Jonathan\" \"HuntingWaffles\"");
		CReplyToCommand(client, "In this example, the username is {cyan}Jonathan {default}and the password is {cyan}HuntingWaffles{default}.");
		CReplyToCommand(client, "{default}Your username and password do not need to match your steam info.");
		return Plugin_Handled;
	}
 
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	GetCmdArgString(full, sizeof(full));
	for (new i=1; i<=args; i++)
	{
		if (i == 1)
			GetCmdArg(i, username, sizeof(username));
		else if (i == 2)
			GetCmdArg(i, password, sizeof(password));
	}
	
	decl String:Query[2048];
	Format(Query, sizeof(Query), "INSERT INTO users (steamid, username, steamid_64, password, isadmin, credits, amountKeys) VALUES('%s', '%s', SteamToInt('%s'), '%s', 0, %d, 0)", SteamID, username, SteamID, password, GetConVarInt(sm_shop_default_credits));
	SQL_TFastQuery(mm_hDatabaseSQLT, Query);
	
	CReplyToCommand(client, "You've registered, {blue}%s{default}. Type {red}/credits {default}to check your balance.", username);
	
	return Plugin_Handled;
} 

public Action:Command_Credits(client, args)
{
	new bool:ClientModified = false;
	new Target = client;
	if (args != 0)
	{
		decl String:sTarget[256];
		GetCmdArgString(sTarget, sizeof(sTarget));
		Target = FindTarget(client, sTarget, true, false);
		ClientModified = true;
	}
	
	if (!IsRegistered(Target, mm_hDatabaseSQL, false, true))
	{
		CReplyToCommand(client, "{red}%s not registered! See /register.", (ClientModified) ? "That person is" : "You are");
		return Plugin_Handled;
	}
	decl String:Query[256];
	decl String:strAuth[64];
	
	GetClientAuthString(Target, strAuth, sizeof(strAuth));
	
	new Handle:hQuery = INVALID_HANDLE;
	
	Format(Query, sizeof(Query), "SELECT credits, amountKeys FROM users WHERE steamid='%s'", strAuth);
	hQuery = SQL_Query(mm_hDatabaseSQL, Query);
	
	SQL_FetchRow(hQuery);
	
	CReplyToCommand(client, "%s {green}%d {default}credits and {yellow}%d {default}keys.", (ClientModified) ? "That person has" : "You have" , SQL_FetchInt(hQuery, 0), SQL_FetchInt(hQuery, 1));
	
	CloseHandle(hQuery);
	
	return Plugin_Handled;
}
public Action:Command_FoV(client, args)
{
	if (args != 1)
	{
		CPrintToChat(client, "{red}You poon, you're doing it wrong!");
		return Plugin_Handled;
	}
	
	decl String:FoV[4];
	GetCmdArg(1, FoV, sizeof(FoV));
	
	new iFoV = StringToInt(FoV);

	if (iFoV > 9 && iFoV < 151)
	{
		SetClientFoV(client, iFoV);
		CPrintToChat(client, "Set your FoV to %i.", iFoV);
	}
	else
	{
		CPrintToChat(client, "{red}'no'");
	}

	return Plugin_Handled;
}

public Action:Command_BuyCredits(client, args)
{
	decl String:creditsToBuy[8];
	decl String:full[256];
	decl String:strAuth[64];
	
	if (args != 1)
	{
		CReplyToCommand(client, "{purple}Usage: {red}/buycredits <credits>");
		return Plugin_Handled;
	}
	
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CReplyToCommand(client, "{red}You must be registered to use /buycredits. See /register.");
		return Plugin_Handled;
	}
	
	GetCmdArgString(full, sizeof(full));
	GetCmdArg(1, creditsToBuy, sizeof(creditsToBuy));
	
	new credits = StringToInt(creditsToBuy);
	
	new currentCash = GetEntProp(client, Prop_Send, "m_nCurrency");
	if (currentCash + credits > 30000)
	{
		credits -= currentCash;
	}
	if (currentCash + credits < 0)
	{
		CReplyToCommand(client, "{red}That value would send your credits below 0.");
		return Plugin_Handled;
	}
	
	if (credits < 1 || credits > 30000)
	{
		CReplyToCommand(client, "{red}The range of credits that you may purchase are from 1-30000.");
		return Plugin_Handled;
	}
	
	new Float:fshopCredits = float(credits);
	fshopCredits /= 5;
	
	new shopCredits = RoundToNearest(fshopCredits);
	new needCreds = HasCredits(client, shopCredits, mm_hDatabaseSQL);
	
	if (needCreds != -1)
	{
		CReplyToCommand(client, "{red}You do not have enough shop credits. You need %d more.", needCreds);
		return Plugin_Handled;
	}
	
	GetClientAuthString(client, strAuth, sizeof(strAuth));
	
	
	SetEntProp(client, Prop_Send, "m_nCurrency", currentCash + credits);

	decl String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "UPDATE users SET credits = credits - %d WHERE steamid='%s'", shopCredits, strAuth);
	SQL_TFastQuery(mm_hDatabaseSQLT, sQuery);
	
	CReplyToCommand(client, "{default}You have purchased {green}%d {default}credits for {red}%d {default}shop credits.", credits, shopCredits);
	
	return Plugin_Handled;
}

public Action:Command_TP(client, args)
{
	if (args != 1)
	{
		CPrintToChat(client, "{purple}Usage: {default}!tp <{blue}\"player\"{default}>");
		return Plugin_Handled;
	}
	
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(client, "{red}You must be registered to use this command! See /register.");
		return Plugin_Handled;
	}
	
	decl String:argFull[256];
	decl String:sTarget[256];
	decl String:sActual[256];
	new Target;
	new creditCost;
	
	GetCmdArgString(argFull, sizeof(argFull));
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	if ((Target = FindTarget(client, sTarget, false, false)) != -1)
	{
		if (Target == client)
		{
			CPrintToChat(client, "{yellow}You're a genius. Don't teleport to yourself.");
			return Plugin_Handled;
		}
		GetClientName(Target, sActual, sizeof(sActual));
		new Float:clientPos[3], Float:targetPos[3], Float:targetAng[3], Float:teleportPos[3];
		
		GetClientAbsOrigin(client, clientPos);
		GetClientAbsOrigin(Target, targetPos);
		GetClientAbsAngles(Target, targetAng);
		
		new Float:fDistanceTotal = GetDistanceTotal(clientPos, targetPos);
		
		new smallDistance = RoundToNearest(fDistanceTotal / 7.5);
		
		creditCost = RoundToNearest(100.0 + (smallDistance * GetRandomFloat(0.25, 1.75)));
		
		new missingCredits = HasCredits(client, creditCost, mm_hDatabaseSQL);
		if (missingCredits != -1)
		{
			CPrintToChat(client, "{red}You don't have enough credits. You need %d more.", missingCredits);
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
		
		CPrintToChat(client, "Teleported to {green}%s {default}for {red}%d {default}credits.", sActual, creditCost);
		ModifyCredits(client, creditCost * -1);
	}
	else
	{
		CPrintToChat(client, "{red}Player {blue}\"%s\" {red}not found.", sTarget);
		return Plugin_Handled;	
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
		
		if (Object == TFExtObjectType:TFObject_Sentry)
		{
			credits = 300;
			Format(ObjectName, sizeof(ObjectName), "sentry gun");
		}
		else if (Object == TFExtObjectType:TFObject_MiniSentry)
		{
			credits = 250;
			Format(ObjectName, sizeof(ObjectName), "mini sentry");
		}
		else if (Object == TFExtObjectType:TFObject_Amplifier)
		{
			credits = 350;
			Format(ObjectName, sizeof(ObjectName), "amplifier");
		}
		else if (Object == TFExtObjectType:TFObject_Sapper)
		{
			credits = 50;
			Format(ObjectName, sizeof(ObjectName), "sapper");
		}
		else if (Object == TFExtObjectType:TFObject_TeleporterEntry)
		{
			credits = 500;
			Format(ObjectName, sizeof(ObjectName), "teleporter entrance");
		}
		else if (Object == TFExtObjectType:TFObject_TeleporterExit)
		{
			credits = 500;
			Format(ObjectName, sizeof(ObjectName), "teleporter exit");
		}
		else if (Object == TFExtObjectType:TFObject_RepairNode)
		{
			credits = 750;
			Format(ObjectName, sizeof(ObjectName), "repair node");
		}
		else if (Object == TFExtObjectType:TFObject_Dispenser)
		{
			credits = 750;
			Format(ObjectName, sizeof(ObjectName), "dispenser");
		}
		else
		{
			decl String:class[64];
			GetEdictClassname(Entity, class, sizeof(class));
			if(strcmp(class, "player") == 0 ||
			   strcmp(class, "tf_bot") == 0)
			{
			   	credits = 3000;
				Format(ObjectName, sizeof(ObjectName), "player");
			}
			else if (strcmp(class, "headless_hatman") == 0)
			{
				credits = 4500;
				Format(ObjectName, sizeof(ObjectName), "headless horseless horsemann");
			}
			else if (strcmp(class, "eyeball_boss") == 0)
			{
				credits = 6000;
				Format(ObjectName, sizeof(ObjectName), "monoculus");
			}
			else if (strcmp(class, "merasmus") == 0)
			{
				credits = 6000;
				Format(ObjectName, sizeof(ObjectName), "merasmus");
			}
			else if (strcmp(class, "tank_boss") == 0)
			{
				credits = 10000;
				Format(ObjectName, sizeof(ObjectName), "tank");
			}
			else 
			{
				CPrintToChat(client, "{red}I do not recognize entity %s yet.", class);
				return Plugin_Handled;
			}
			new missingCredits = HasCredits(client, credits, mm_hDatabaseSQL);
			if (missingCredits == -1)
			{
				SetVariantInt(0);
				AcceptEntityInput(Entity, "SetHealth", client, client);
				
				ModifyCredits(client, credits * -1);
				CPrintToChat(client, "Killed {purple}%s {default}for {red}%d {default}credits.", ObjectName, credits);
			}
			else 
			{
				CPrintToChat(client, "{red}You don't have enough credits. You need %d more.", missingCredits);
				return Plugin_Handled;
			}
			return Plugin_Handled;
		}
		
		new missingCredits = HasCredits(client, credits, mm_hDatabaseSQL);
		if (missingCredits == -1)
		{
			SetVariantInt(9999);
			AcceptEntityInput(Entity, "RemoveHealth", client, client);
			
			ModifyCredits(client, credits * -1);
			CPrintToChat(client, "Destroyed {purple}%s {default}for {red}%d {default}credits.", ObjectName, credits);
		}
		else 
		{
			CPrintToChat(client, "{red}You don't have enough credits. You need %d more.", missingCredits);
			return Plugin_Handled;
		}
	}
	else
	{
		CPrintToChat(client, "{red}You must be aiming at something for this to work.");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}
public Action:Command_CustomItems(client, args)
{
	if (args != 1)
	{
		CPrintToChat(client, "{urple}Usage: {default}/customitems <{cyan}on{default}/{cyan}off{default}>");
		return Plugin_Handled;
	}
	
	decl String:val[8];
	GetCmdArg(1, val, sizeof(val));
	
	if (strcmp(val, "on", false) == 0 ||
		strcmp(val, "1", false) == 0)
	{
		SetConVarBool(sm_customitems_enabled, true, false, true);
		for (new i = 1; i <= GetEntityCount(); i++)
		{
			if (IsValidWeapon(i))
			{
				new owner = GetWeaponOwner(i);
				//If they have custom items, let's give 'em
				if (IsRegistered(owner, mm_hDatabaseSQL, false, true))
				{
					new index = GetWeaponItemDef(i);
					
					if (!TF2II_IsValidItemID(index))
						continue;
					
					decl String:classname[64];
					TF2II_GetItemClass(index, classname, sizeof(classname));
					
					
					
					new Handle:hItem = FindItem(owner, index, mm_hDatabaseSQL);
					if (hItem != INVALID_HANDLE)
					{
						TF2Items_SetClassname(hItem, classname);
						TF2Items_SetFlags(hItem, TF2Items_GetFlags(hItem) | FORCE_GENERATION);
						
						new slot = _:TF2II_GetItemSlot(index);
						TF2_RemoveWeaponSlot(owner, slot);
						
						TF2Items_GiveNamedItem(owner, hItem);
					}
					else
					{
						hItem = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
						TF2Items_SetClassname(hItem, classname);
						TF2Items_SetItemIndex(hItem, index);
						
						TF2Items_SetLevel(hItem, TF2II_GetItemLevelByID(index));
						TF2Items_SetQuality(hItem, _:TF2II_GetItemQuality(index));
						
						new attribCount = 0;
						for (new j = 0; j < 16; j++)
						{
							new id, Float:value;
							id = TF2II_GetItemAttributeID(index, j);
							if (id <= 0)
								break;
							value = TF2II_GetItemAttributeValue(index, j);
							
							TF2Items_SetAttribute(hItem, j, id, value);
							attribCount++;
						}
						
						TF2Items_SetNumAttributes(hItem, attribCount);
						
						new slot = _:TF2II_GetItemSlot(index);
						TF2_RemoveWeaponSlot(owner, slot);
						
						TF2Items_GiveNamedItem(owner, hItem);
					}
				}
			}
		}
	}
	else if (strcmp(val, "off", false) == 0 ||
			 strcmp(val, "0", false) == 0)
	{
		SetConVarBool(sm_customitems_enabled, false, false, true);
		for (new i = 1; i <= GetEntityCount(); i++)
		{
			if (IsValidWeapon(i))
			{
				new owner = GetWeaponOwner(i);
				//Set back to defaults, if they were custom
				if (IsRegistered(owner, mm_hDatabaseSQL, false, true))
				{
					new index = GetWeaponItemDef(i);
					
					if (!TF2II_IsValidItemID(index))
						continue;
					
					decl String:classname[64];
					TF2II_GetItemClass(index, classname, sizeof(classname));
					
					new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
					TF2Items_SetClassname(hItem, classname);
					TF2Items_SetItemIndex(hItem, index);
						
					TF2Items_SetLevel(hItem, TF2II_GetItemLevelByID(index));
					TF2Items_SetQuality(hItem, _:TF2II_GetItemQuality(index));
						
					new attribCount = 0;
					for (new j = 0; j < 16; j++)
					{
						new id, Float:value;
						id = TF2II_GetItemAttributeID(index, j);
						if (id <= 0)
							break;
						value = TF2II_GetItemAttributeValue(index, j);
						
						TF2Items_SetAttribute(hItem, j, id, value);
						attribCount++;
					}
						
					TF2Items_SetNumAttributes(hItem, attribCount);
					
					new slot = _:TF2II_GetItemSlot(index);
					TF2_RemoveWeaponSlot(owner, slot);
					
					TF2Items_GiveNamedItem(owner, hItem);
				}
			}
		}
	}
	else
	{
		CPrintToChat(client, "{purple}Usage: /customitems <{cyan}on{default}/{cyan}off{default}>");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:Command_Gamble(client, args)
{
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(client, "{red}You must be registered to use this! See /register.");
		return Plugin_Handled;
	}
	
	new Cost = GetConVarInt(sm_gamble_cost);
	new Time = GetConVarInt(sm_gamble_timer);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	
	new MissingCredits = HasCredits(client, Cost, mm_hDatabaseSQL);
	if (MissingCredits != -1)
	{
		CPrintToChat(client, "{red}You don't have enough credits! You need %d more.", MissingCredits);
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "You have paid {red}%d {default}shop credits to gamble.", Cost);
	
	ModifyCredits(client, Cost * -1);
	
	new Handle:datapack = INVALID_HANDLE;
	CreateDataTimer(1.0, Timer_GambleCountDown, datapack, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
	WritePackCell(datapack, client);
	WritePackCell(datapack, Cost);
	WritePackCell(datapack, Time);
	WritePackString(datapack, name);
	
	return Plugin_Handled;
}
public Action:Command_CheckItemCost(client, args)
{
	decl String:Args[256];
	GetCmdArgString(Args, sizeof(Args));
	
	CPrintToChat(client, "{blue}\"%s\" {default}costs {red}%d {default}shop credits.", Args, GetWeaponCreditCost(Args, mm_hDatabaseSQL));
	
	return Plugin_Handled;
}

public Action:Command_Give(client, args)
{
	if (args != 3)
	{
		CPrintToChat(client, "{purple}Usage: {default}/give <{blue}\"client\"{default}> <{green}ItemID{default}> <{green}Slot{default}>");
		return Plugin_Handled;
	}
	
	decl String:TargetString[64];
	decl String:ItemID[8];
	decl String:Slot[2];
	
	GetCmdArg(1, TargetString, sizeof(TargetString));
	GetCmdArg(2, ItemID, sizeof(ItemID));
	GetCmdArg(3, Slot, sizeof(Slot));
	
	new iTarget = FindTarget(client, TargetString, true, true);
	new iItemID = StringToInt(ItemID);
	new iSlot = StringToInt(Slot);
	
	if (iItemID <= 0 || iSlot < 0)
	{
		CPrintToChat(client, "{red}Bad ItemID/Slot");
		return Plugin_Handled;
	}
	
	new Handle:hItem = INVALID_HANDLE; 
	hItem = FindItem(iTarget, iItemID, mm_hDatabaseSQL);
	
	if (hItem == INVALID_HANDLE)
	{
		CPrintToChat(client, "{yellow}The client doesn't own that weapon.");
		return Plugin_Handled;
	}
	
	decl String:ItemClass[64];
	
	TF2II_GetItemClass(iItemID, ItemClass, sizeof(ItemClass));
	
	if (StrContains(ItemClass, "tf_wearable", false) > -1)
	{
		CPrintToChat(client, "{yellow}Wearables may not be equipped.");
		return Plugin_Handled;
	}
	
	TF2Items_SetClassname(hItem, ItemClass);
	TF2Items_SetFlags(hItem, OVERRIDE_ALL | FORCE_GENERATION);
	
	new iEntityID = TF2Items_GiveNamedItem(iTarget, hItem);
	
	EquipPlayerWeapon(iTarget, iEntityID);
	
	CloseHandle(hItem);
	
	CPrintToChat(client, "Done.");
	return Plugin_Handled;
}

public Action:Command_PayPumpkin(client, args)
{
	new iCreditCost = 125;
	
	decl Float:Position[3];
	if(!SetTeleportEndPoint(client, Position))
	{
		CPrintToChat(client, "{red}Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		CPrintToChat(client, "{red}Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}
	
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(client, "{red}Please /register.");
		return Plugin_Handled;
	}
	
	new iCreditsMissing = HasCredits(client, iCreditCost, mm_hDatabaseSQL);
	if (iCreditsMissing > 0)
	{
		CPrintToChat(client, "{red}You need %d more credits!", iCreditsMissing);
		return Plugin_Handled;
	}
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		Position[2] -= 10.0;
		TeleportEntity(iPumpkin, Position, NULL_VECTOR, NULL_VECTOR);
		CPrintToChat(client, "You have paid {red}%d {default}credits to spawn a pumpkin.", iCreditCost);
		ModifyCredits(client, iCreditCost * -1);
	}
	
	return Plugin_Handled;
}

public Action:Command_PayGift(client, args)
{
	new iCreditCost = 750;
	
	decl Float:Position[3];
	if(!SetTeleportEndPoint(client, Position))
	{
		CPrintToChat(client, "{red}Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities() - 32)
	{
		CPrintToChat(client, "{red}Entity limit is reached. Can't spawn anymore gifts. Change maps.");
		return Plugin_Handled;
	}
	
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(client, "{red}Please /register.");
		return Plugin_Handled;
	}
	
	new iCreditsMissing = HasCredits(client, iCreditCost, mm_hDatabaseSQL);
	if (iCreditsMissing > 0)
	{
		CPrintToChat(client, "{red}You need %d more credits!", iCreditsMissing);
		return Plugin_Handled;
	}
	
	new iGift = CreateEntityByName("prop_physics_override");
	
	if(IsValidEntity(iGift))
	{		
		SetEntityModel(iGift, MODEL_GIFT);
		DispatchKeyValue(iGift, "StartDisabled", "false");
		DispatchSpawn(iGift);
		
		Position[2] -= 10.0;
		TeleportEntity(iGift, Position, NULL_VECTOR, NULL_VECTOR);
		
		SetEntityMoveType(iGift, MOVETYPE_NONE);
		DispatchKeyValue(iGift, "ExplodeRadius", "150");
		DispatchKeyValue(iGift, "ExplodeDamage", "375");
		SetEntProp(iGift, Prop_Data, "m_takedamage", 2);
		AcceptEntityInput(iGift, "Enable");
		HookSingleEntityOutput(iGift, "OnBreak", OnGiftBreak, true);
		SDKHook(iGift, SDKHook_Touch, OnGiftTouch);
		
		CPrintToChat(client, "You have paid {red}%d {default}credits to spawn a gift at {yellow}(%f, %f, %f){default}.", iCreditCost, Position[0], Position[1], Position[2]);
		ModifyCredits(client, iCreditCost * -1);
	}
	
	return Plugin_Handled;
}

public Action:Command_PayRage(client, args)
{
	new iCreditCost = -150;
	
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(client, "{red}Please /register.");
		return Plugin_Handled;
	}
	
	new iCreditsMissing = HasCredits(client, iCreditCost * -1, mm_hDatabaseSQL);
	if (iCreditsMissing > 0)
	{
		CPrintToChat(client, "{red}You need %d more credits!", iCreditsMissing);
		return Plugin_Handled;
	}
	
	TF2_SetRageMeter(client, 100.0);
	CPrintToChat(client, "{default}Granted full rage for {red}%d{default} credits.", iCreditCost);
	ModifyCredits(client, iCreditCost);
	return Plugin_Handled;
}

public Action:Command_CheckPlayers(client, args)
{
	FixPlayerSDKHooks();
	return Plugin_Handled;
}

public Action:Command_ViolentTimeBomb(client, args)
{
	if (args != 2)
	{
		CReplyToCommand(client, "{purple}Usage:{default} !violenttimebomb <{red}fTime{default}> <{blue}\"player\"{default}>");
		return Plugin_Handled;
	}
	decl String:sTime[16];
	decl String:sTarget[256];
	GetCmdArg(1, sTime, sizeof(sTime));
	GetCmdArg(2, sTarget, sizeof(sTarget));
	
	new iTarget = FindTarget(client, sTarget, true, true);
	new Float:fTime = StringToFloat(sTime);
	
	if (iTarget > MaxClients || iTarget < 0)
	{
		CReplyToCommand(client, "{red}Invalid target.");
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(iTarget))
	{
		CReplyToCommand(client, "{red}Target must be alive.");
		return Plugin_Handled;
	}
	
	decl String:SteamID[64];
	GetClientAuthString(iTarget, SteamID, sizeof(SteamID));
	
	new Handle:dataPack = INVALID_HANDLE;
	CreateDataTimer(fTime, Timer_BlowUpClient, dataPack, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, iTarget);
	WritePackString(dataPack, SteamID);
		
	EmitSoundToAll(SOUND_GIFTISTIMEBOMB, iTarget);
	CReplyToCommand(client, "%N is set to explode in %f seconds.", iTarget, fTime);
	TF2_AddCondition(iTarget, TFCond_Bonked, fTime);
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
		Interval = StringToFloat(Arg2);
	}
	if (args >= 3)
	{
		decl String:Arg3[8];
		GetCmdArg(3, Arg3, sizeof(Arg3));
		AmountHeal = StringToInt(Arg3);
	}
	
	new iCreditCost = RoundToNearest(Length * (Pow(Interval, -1.0)) * AmountHeal);
	
	if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(client, "{red}Please /register.");
		return Plugin_Handled;
	}
	
	new iCreditsMissing = HasCredits(client, iCreditCost * -1, mm_hDatabaseSQL);
	if (iCreditsMissing > 0)
	{
		CPrintToChat(client, "{red}You need %d more credits!", iCreditsMissing);
		return Plugin_Handled;
	}
	
	if (!SetClientRegenerateHealth(client, true, Length, Interval, AmountHeal))
	{
		CPrintToChat(client, "{red}You're currently in a regen loop!");
		return Plugin_Handled;
	}
	CPrintToChat(client, "{default}You've paid {red}%d{default} credits for health regeneration.", iCreditCost);
	ModifyCredits(client, iCreditCost * -1);
	return Plugin_Handled;
}
/*
 * TIMER FUNCTIONS
 * 
 * Functions called by timers
 */
 
public Action:Timer_BlowUpClient(Handle:timer, Handle:datapack)
{
	ResetPack(datapack);
	new iClient = ReadPackCell(datapack);
	decl String:SteamIDPack[64], String:SteamID[64];
	ReadPackString(datapack, SteamIDPack, sizeof(SteamIDPack));
	GetClientAuthString(iClient, SteamID, sizeof(SteamID));
	
	if (strcmp(SteamIDPack, SteamID) != 0)
	{
		return Plugin_Stop;
	}
	
	if (!IsClientInGame(iClient))
	{
		return Plugin_Stop;
	}
	
	EmitSoundToAll(SOUND_EXPLODE, iClient);
	
	new explosion = CreateEntityByName("env_explosion");
		
	new Float:clientPos[3];
	GetClientAbsOrigin(iClient, clientPos);
		

	new iRagdoll = CreateEntityByName("tf_ragdoll");
	if(IsValidEdict(iRagdoll)) 
	{
		SetEntPropVector(iRagdoll, Prop_Send, "m_vecRagdollOrigin", clientPos);
		SetEntProp(iRagdoll, Prop_Send, "m_iPlayerIndex", iClient);
		SetEntPropVector(iRagdoll, Prop_Send, "m_vecForce", NULL_VECTOR);
		SetEntPropVector(iRagdoll, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR);
		SetEntProp(iRagdoll, Prop_Send, "m_bGib", 1);

		DispatchSpawn(iRagdoll);

		CreateTimer(0.1, RemoveBody, iClient);
		CreateTimer(15.0, RemoveGibs, iRagdoll);
	}
	
		
	if (IsValidEdict(explosion))
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		new Float:zPos[3];
		GetClientAbsOrigin(i, zPos);
		new Float:Dist = GetDistanceTotal(clientPos, zPos);
		if (Dist > 750.0) continue;
		DoDamage(iClient, i, 2500);
	}
	for (new i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		decl String:cls[20];
		GetEntityClassname(i, cls, sizeof(cls));
		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;
		new Float:zPos[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", zPos);
		new Float:Dist = GetDistanceTotal(clientPos, zPos);
		if (Dist > 750.0) continue;
		SetVariantInt(2500);
		AcceptEntityInput(i, "RemoveHealth");
	}
		
	AttachParticle(iClient, "fluidSmokeExpl_ring_mvm");
	FakeClientCommand(iClient, "kill");
	return Plugin_Continue;
}

public Action:Timer_AssignTeam(Handle:timer, any:data)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (client > MaxClients || client < 1 || !IsClientInGame(client) || !IsClientConnected(client))
			return Plugin_Continue;
		if (TFTeam:GetClientTeam(client) == TFTeam_Unassigned)
		{
			new TFTeam:Team = TFTeam_Red;
			if (GetTeamClientCount(_:TFTeam_Blue) < GetTeamClientCount(_:TFTeam_Red))
				Team = TFTeam_Blue;
			ChangeClientTeam(client, _:Team);
			TF2_SetPlayerClass(client, TFClassType:GetRandomInt(1, 9));
			PrintToChatAll("%N was automatically forced to join team %s", client, (Team == TFTeam_Red ? "RED" : "BLU"));
		}
	}
	return Plugin_Handled;
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
		new Credits = GetRandomInt(-8192, 8192);
		Credits = RoundToCeilPowerOfTwo(Credits);
		PrintCenterText(client, " ");
		
		new bool:AllCredits = false;
		
		if (Credits < 0)
		{
			new MissingCredits = HasCredits(client, Credits * -1, mm_hDatabaseSQL);
			if (MissingCredits >= 0)
			{
				Credits -= MissingCredits;
				AllCredits = true;
			}
		}
		 
		CPrintToChat(client, "%s{default}: {red}%d {default}shop credits {red}%s", (Credits > 0) ? "{green}Winnings" : "{red}Losses", Credits, (AllCredits) ? "(all of your credits)" : "");
		
		ModifyCredits(client, Credits);
		return Plugin_Stop;
	}
 
	return Plugin_Continue;
}
public Action:Timer_CreateGift(Handle:timer, any:data)
{
	new Float:Position[3];
	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "achievement_idle_merbo", false) > -1)
	{
		new GiftLocation = GetRandomInt(0, GiftPositions__achievement_idle_merbo_count - 1);
		for (new i = 0; i < 3; i++)
		{
			Position[i] = GiftPositions__achievement_idle_merbo[GiftLocation][i];
		}
	}
	else if (StrContains(MapName, "merbosmagic_minecraft", false) > -1)
	{
		new GiftLocation = GetRandomInt(0, GiftPositions__merbosmagic_minecraft_count - 1);
		for (new i = 0; i < 3; i++)
		{
			Position[i] = GiftPositions__merbosmagic_minecraft[GiftLocation][i];
		}
	}
	else if (StrContains(MapName, "merbosmagic_idle_", false) > -1)
	{
		new GiftLocation = GetRandomInt(0, GiftPositions__merbosmagic_idle_count - 1);
		for (new i = 0; i < 3; i++)
		{
			Position[i] = GiftPositions__merbosmagic_idle[GiftLocation][i];
		}
	}
	
	if(GetEntityCount() >= GetMaxEntities() -32)
	{
		return Plugin_Continue;
	}
	
	new iGift = CreateEntityByName("prop_physics_override");
	
	if(IsValidEntity(iGift))
	{		
		SetEntityModel(iGift, MODEL_HALLOWEENGIFT);
		DispatchKeyValue(iGift, "StartDisabled", "false");
		DispatchSpawn(iGift);
		
		Position[2] -= 10.0;
		TeleportEntity(iGift, Position, NULL_VECTOR, NULL_VECTOR);
		
		SetEntityMoveType(iGift, MOVETYPE_NONE);
		DispatchKeyValue(iGift, "ExplodeRadius", "150");
		DispatchKeyValue(iGift, "ExplodeDamage", "375");
		SetEntProp(iGift, Prop_Data, "m_takedamage", 2);
		AcceptEntityInput(iGift, "Enable");
		HookSingleEntityOutput(iGift, "OnBreak", OnGiftBreak, true);
		SDKHook(iGift, SDKHook_Touch, OnGiftTouch);
		
		PrintHintTextToAll("A gift has been spawned on the map, go find it!");
		
		CreateTimer(180.0, Timer_DestroyGift, EntIndexToEntRef(iGift));
	}
	
	return Plugin_Continue;
}
public Action:Timer_DestroyGift(Handle:timer, any:iGiftEntityRef)
{
	new iGiftEntity = EntRefToEntIndex(iGiftEntityRef);
 
	if (iGiftEntity == INVALID_ENT_REFERENCE)
	{
		return Plugin_Continue;
	}
	if (!IsValidEntity(iGiftEntity))
		return Plugin_Continue;
	decl String:className[256];
	if (!GetEntityClassname(iGiftEntity, className, sizeof(className)))
		return Plugin_Continue;
	if (strcmp(className, "prop_physics_override", false) != 0 &&
		strcmp(className, "prop_physics", false) != 0)
		return Plugin_Continue;
	UnhookSingleEntityOutput(iGiftEntity, "OnBreak", OnGiftBreak);
	AcceptEntityInput(iGiftEntity, "kill");
	
	return Plugin_Continue;
}
public Action:Timer_CheckWM1(Handle:timer, any:null)
{
	if (!GetConVarBool(sm_enable_anti_wm1))
		return Plugin_Continue;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		if (clientWM1[i] >= 125)
		{
			FakeClientCommand(i, "kill");
			CPrintToChat(i, "{red}Don't W+M1!");
		}
	}
	return Plugin_Continue;
}
public Action:Timer_Rename(Handle:timer, Handle:pack)
{
	decl String:NewName[MAX_NAME_LENGTH];
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, NewName, sizeof(NewName));
	
	if (client != 0)
	{
		SetClientInfo(client, "name", NewName);
	}
		
	return Plugin_Stop;
}
public Action:Timer_RegenHealth(Handle:timer, Handle:Datapack)
{
	ResetPack(Datapack);
	new client = ReadPackCell(Datapack);
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
/*
 * FORWARDS
 */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client))
	{
		if (buttons & IN_ATTACK3 == IN_ATTACK3)
		{
			new iWeapon = GetPlayerWeaponSlot(client, 2);
			if (iWeapon != -1)
			{
				new ItemDef = GetWeaponItemDef(iWeapon);
				if (ItemDef == 225) //Your eternal reward
				{
					TF2_AddCondition(client, TFCond_DisguisedAsDispenser, 0.2);
				}
			}	
		}
	}
	return Plugin_Continue;
}  
public Action:TF2Items_OnGiveNamedItem(iClient, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{	
	//If another plugin fucked with it
	if (hItemOverride != INVALID_HANDLE)
		return Plugin_Continue;
	
	if (!IsRegistered(iClient, mm_hDatabaseSQL, false, true))
		return Plugin_Continue; 
	 
	new Handle:hItem = FindItem(iClient, iItemDefinitionIndex, mm_hDatabaseSQL, GetConVarBool(sm_customitems_enabled));
	if (hItem != INVALID_HANDLE)
	{
		hItemOverride = hItem;
		return Plugin_Changed;
	}
	
	// We've found nothing to change.
	return Plugin_Continue;
}

/* 
 * EVENTS
 * 
 * Mostly used for giving players credits on their SQL accounts
 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new assisterId = GetEventInt(event, "assister");
	new deathFlags = GetEventInt(event, "death_flags");
	new customKill = GetEventInt(event, "customkill");
	new penetrated = GetEventInt(event, "playerpenetratecount");
	new weaponid = GetEventInt(event, "weaponid");
	new damageBits = GetEventInt(event, "damagebits");
 
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);
	new assister = GetClientOfUserId(assisterId);
	
	new bool:VictimRegistered = IsRegistered(victim, mm_hDatabaseSQL, false, true);
	new bool:AttackerRegistered = IsRegistered(attacker, mm_hDatabaseSQL, false, true);
	new bool:AssisterRegistered = IsRegistered(assister, mm_hDatabaseSQL, false, true);
	
	new AttackerPoints = 4;
		
	new VictimPoints = 2;
	
	new AssisterPoints = 2;
	
	decl String:AttackerComment[512];
	decl String:VictimComment[512];
	decl String:AssisterComment[512];
	
	AttackerComment = "";
	VictimComment = "";
	AssisterComment = "";

	if(GetEngineTime() - facestabClients[victim] <= 0.1) // 0.02246
	{			
		SetEventInt(event, "damagebits",  damageBits |= DMG_CRIT);
		SetEventString(event, "weapon_logclassname", "facestab");
		SetEventInt(event, "customkill", TF_CUSTOM_BACKSTAB);
		SetEventInt(event, "playerpenetratecount", 0);
		facestabClients[victim] = 0.0;
		Format(AttackerComment, sizeof(AttackerComment), "%s {yellow} You're a facestabbing douche!", AttackerComment);
	}
	facestabClients[victim] = 0.0;
	if(GetEngineTime() - cheapshotClients[victim] <= 0.1) // 0.02246
	{			
		SetEventInt(event, "damagebits",  damageBits |= DMG_CRIT);
		SetEventString(event, "weapon_logclassname", "cheapshot");
		SetEventInt(event, "customkill", TF_CUSTOM_HEADSHOT);
		SetEventInt(event, "playerpenetratecount", 0);
		cheapshotClients[victim] = 0.0;
		Format(AttackerComment, sizeof(AttackerComment), "%s {yellow} You're a cheapshotting douche!", AttackerComment);
	}
	cheapshotClients[victim] = 0.0;

	if (deathFlags & TF_DEATHFLAG_KILLERDOMINATION)
	{
		AttackerPoints += 32;
		Format(AttackerComment, sizeof(AttackerComment), "%s Nice domination!", AttackerComment);
		EmitSoundToAll(SOUND_CUSTOM_DONTSTOPMENOW, attacker);
	}
	if (deathFlags & TF_DEATHFLAG_ASSISTERDOMINATION)
	{
		AssisterPoints += 32;
		Format(AssisterComment, sizeof(AssisterComment), "%s Nice domination!", AssisterComment);
		EmitSoundToAll(SOUND_CUSTOM_DONTSTOPMENOW, assister);
	}
	if (deathFlags & TF_DEATHFLAG_KILLERREVENGE)
	{
		AttackerPoints += 16;
		Format(AttackerComment, sizeof(AttackerComment), "%s Nice revenge!", AttackerComment);
		
	}
	if (deathFlags & TF_DEATHFLAG_ASSISTERREVENGE)
	{
		AssisterPoints += 16;
		Format(AssisterComment, sizeof(AssisterComment), "%s Nice revenge!", AssisterComment);
	}
	
	decl String:VictimName[64];	
	
	GetClientName(victim, VictimName, sizeof(VictimName));
	
	if (weaponid == TF_WEAPON_BAT_FISH && customKill != TF_CUSTOM_FISH_KILL)
	{
		//Fish hit
		return Plugin_Continue;
	}
	
	if (IsMerbo(victim))
	{
		AttackerPoints += 32;
		AssisterPoints += 4;
		Format(AttackerComment, sizeof(AttackerComment), "%s {green}Congratulations, you killed Pelipoika!", AttackerComment);
		Format(AssisterComment, sizeof(AssisterComment), "%s {green}Congratulations, you assisted in killing Pelipoika!", AssisterComment);
	}
	else if (assister != 0 && IsMerbo(assister))
	{
		AttackerPoints += 2;
		VictimPoints += 2;
		Format(AttackerComment, sizeof(AttackerComment), "%s {green}Pelipoika helped you with that!", AttackerComment);
		Format(VictimComment, sizeof(VictimComment), "%s {green}Pelipoika helped kill you!", VictimComment);
	}
	else if (IsMerbo(attacker))
	{
		AssisterPoints += 2;
		VictimPoints += 2;
		Format(AssisterComment, sizeof(AssisterComment), "%s {green}You helped Pelipoika with that!", AssisterComment);
		Format(VictimComment, sizeof(VictimComment), "%s {green}Pelipoika killed you!", VictimComment);
	}
	
	if (customKill == TF_CUSTOM_HEADSHOT || customKill == TF_CUSTOM_HEADSHOT_DECAPITATION)
	{
		AttackerPoints += 32;
		if (weaponid == TF_WEAPON_COMPOUND_BOW)
		{
			Format(AttackerComment, sizeof(AttackerComment), "%s {cyan}Nice {beige}huntsman {cyan}headshot!", AttackerComment);
		}
		else
			Format(AttackerComment, sizeof(AttackerComment), "%s {cyan}Nice headshot!", AttackerComment);
	}	
	else if (customKill == TF_CUSTOM_BACKSTAB)
	{
		AttackerPoints += 8;
		Format(AttackerComment, sizeof(AttackerComment), "%s {yellow}Nice backstab!", AttackerComment);
		Format(VictimComment, sizeof(VictimComment), "%s {red}That was some cruel espionage.", VictimComment);
		EmitSoundToAll(SOUND_CUSTOM_SURPRISEMOFO, attacker);
	}
	else if (customKill == TF_CUSTOM_TELEFRAG)
	{
		AttackerPoints += 256;
		Format(AttackerComment, sizeof(AttackerComment), "%s {mediumaquamarine}EXCELLENT TELEFRAG!", AttackerComment);
		Format(VictimComment, sizeof(VictimComment), "%s {red}That was pretty unfortunate, no?", VictimComment);
	}
	else if (customKill == TF_CUSTOM_CLEAVER || customKill == TF_CUSTOM_CLEAVER_CRIT)
	{
		AttackerPoints += 32;
		Format(AttackerComment, sizeof(AttackerComment), "%s {lightsteelblue}Nice cleaver kill!", AttackerComment);
	}
	else if (customKill == TF_CUSTOM_PENETRATE_HEADSHOT)
	{
		AttackerPoints += 64;
		Format(AttackerComment, sizeof(AttackerComment), "%s {lightsteelblue}Excellent penetration headshot!", AttackerComment);
	}
	else if (customKill == TF_CUSTOM_TAUNT_ARMAGEDDON || customKill == TF_CUSTOM_TAUNT_ARROW_STAB ||
			 customKill == TF_CUSTOM_TAUNT_BARBARIAN_SWING || customKill == TF_CUSTOM_TAUNT_ENGINEER_ARM ||
			 customKill == TF_CUSTOM_TAUNT_ENGINEER_SMASH || customKill == TF_CUSTOM_TAUNT_FENCING ||
			 customKill == TF_CUSTOM_TAUNT_GRAND_SLAM || customKill == TF_CUSTOM_TAUNT_GRENADE ||
			 customKill == TF_CUSTOM_TAUNT_HADOUKEN || customKill == TF_CUSTOM_TAUNT_HIGH_NOON ||
			 customKill == TF_CUSTOM_TAUNT_UBERSLICE)
	{
		AttackerPoints += 128;
		Format(AttackerComment, sizeof(AttackerComment), "%s {green}Great taunt kill!", AttackerComment);	 	
	}
	else if (customKill == TF_CUSTOM_BURNING || customKill == TF_CUSTOM_BURNING_ARROW ||
			 customKill == TF_CUSTOM_BURNING_FLARE || customKill == TF_CUSTOM_FLYINGBURN)
	{
		AttackerPoints += 8;
		Format(AttackerComment, sizeof(AttackerComment), "%s {red}Nice burn kill!", AttackerComment);	 	
	}
	else if (customKill == TF_CUSTOM_BLEEDING)
	{
		AttackerPoints += 16;
		Format(AttackerComment, sizeof(AttackerComment), "%s {red}Nice bleed kill!", AttackerComment);	 	
	}

	if (weaponid == TF_WEAPON_SENTRY_REVENGE)
	{
		AttackerPoints += 8;
		Format(AttackerComment, sizeof(AttackerComment), "%s {green}Nice sentry revenge kill!", AttackerComment);	
	}
	else if (weaponid == TF_WEAPON_SENTRY_BULLET)
	{
		AttackerPoints += 4;
		Format(AttackerComment, sizeof(AttackerComment), "%s {green}Nice sentry kill!", AttackerComment);	
	}
	else if (weaponid == TF_WEAPON_SENTRY_ROCKET)
	{
		AttackerPoints += 6;
		Format(AttackerComment, sizeof(AttackerComment), "%s {green}Nice sentry rocket kill!", AttackerComment);	
	}
	
	
	if (damageBits & DMG_CRIT)
	{
		AttackerPoints += 2;
		Format(AttackerComment, sizeof(AttackerComment), "%s {cyan}Nice crit!", AttackerComment);
	}
	
	if (deathFlags & TF_DEATHFLAG_GIBBED)
	{
		AttackerPoints += 2;
		Format(AttackerComment, sizeof(AttackerComment), "%s {brown}Nice gib!", AttackerComment);
	}
	
	AttackerPoints *= (penetrated + 1);
	if (penetrated > 0)
		Format(AttackerComment, sizeof(AttackerComment), "%s {lightsteelblue}Amazing penetration kill!", AttackerComment);

	if (IsFakeClient(victim))
	{
		AttackerPoints = RoundToNearest(float(AttackerPoints / 2));
		AssisterPoints = RoundToNearest(float(AssisterPoints / 2));
		Format(AttackerComment, sizeof(AttackerComment), "%s {grey}Nice bot kill.", AttackerComment);
	}

	if (deathFlags & TF_DEATHFLAG_DEADRINGER)
	{
		VictimPoints = 8;
		
		new bool:AdminKnew = false;

		if (AttackerRegistered)
		{
			if (GetUserAdmin(attacker) != INVALID_ADMIN_ID && IsMerbo(victim))
			{
				AdminKnew = true;
				Format(AttackerComment, sizeof(AttackerComment), "%s {gold}DEAD RINGER!", AttackerComment);
			}
			decl String:killingString[128];
			Format(killingString, sizeof(killingString), "killing %N", victim);
			ModifyCreditsEx(attacker, AttackerPoints, killingString, AttackerComment, true);
		}
		if (AssisterRegistered)
		{
			if (GetUserAdmin(assister) != INVALID_ADMIN_ID && IsMerbo(victim))
			{
				AdminKnew = true;
				Format(AssisterComment, sizeof(AssisterComment), "%s {gold}DEAD RINGER!", AssisterComment);
			}
			decl String:killingString[128];
			Format(killingString, sizeof(killingString), "assisting in killing %N", victim);
			ModifyCreditsEx(assister, AssisterPoints, killingString, AssisterComment, true);
		}

		if (VictimRegistered)
		{
			if (AdminKnew)
				Format(VictimComment, sizeof(VictimComment), "%s {gray}An admin knows of your dead ringer!", VictimComment); 
			ModifyCreditsEx(victim, VictimPoints, "feigning your death", VictimComment);
		}
		return Plugin_Continue;
	}
	
	if (attacker == victim)
	{
		if (VictimRegistered)
		{
			VictimPoints = -8;
			ModifyCreditsEx(victim, VictimPoints, "killing yourself", VictimComment);
		}
	}
	else if (attacker == 0 && weaponid != TF_WEAPON_NONE)
	{
		if (VictimRegistered)
		{
			VictimPoints = -8;
			ModifyCreditsEx(victim, VictimPoints, "killing yourself", VictimComment);
		}
	}
	else if (attacker == 0 && weaponid == TF_WEAPON_NONE && customKill == TF_CUSTOM_TRIGGER_HURT)
	{
		if (VictimRegistered)
		{
			VictimPoints = -1;
			ModifyCreditsEx(victim, VictimPoints, "dying an idler's death", VictimComment);
		}
	}
	else
	{
		if (AttackerRegistered)
		{
			decl String:killingString[128];
			Format(killingString, sizeof(killingString), "killing %N", victim);
			ModifyCreditsEx(attacker, AttackerPoints, killingString, AttackerComment);
		}
		if (AssisterRegistered)
		{
			decl String:killingString[256];
			Format(killingString, sizeof(killingString), "assisting in %N's death", victim);
			ModifyCreditsEx(assister, AssisterPoints, killingString, AssisterComment);
		}
		if (VictimRegistered)
		{
			ModifyCreditsEx(victim, VictimPoints, "dying", VictimComment);
		}
	}
	
	SetClientRegenerateHealth(victim, false);
	return Plugin_Continue;
}

public Event_Spam(Handle:event, const String:name[], bool:dontBroadcast)
{
 	for (new i = 1; i < GetMaxClients(); i++) 
	{
		if(!IsRegistered(i, mm_hDatabaseSQL, false, true)) 
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				CPrintToChat(i, "Type {red}/register {default}to see how to register on the {orange}Frag{cyan}Net {default}server.");
				CPrintToChat(i, "{default}The username and password do not need to match your steam information!");
			}
		}
	}
}


public Event_GrabbedObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerId = GetEventInt(event, "userid");
	new player = GetClientOfUserId(playerId);
	
	GiveGift(player, IsRegistered(player, mm_hDatabaseSQL), GIFTTYPE_DEFAULT);
}

public Event_ObjDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new assisterId = GetEventInt(event, "assister");
	new entity = GetEventInt(event, "index");
	new bool:Building = GetEventBool(event, "was_building");
 
	new attacker = GetClientOfUserId(attackerId);
	new assister = GetClientOfUserId(assisterId);
	
	new credits = 4;
	
	new TFExtObjectType:objectType = TF2_GetExtObjectType(entity, true);
	
	decl String:Object[32];
	decl String:Comment[256];
	Comment[0] = '\0';
	
	Format(Object, sizeof(Object), "building");
	
	if (objectType == TFExtObjectType:TFObject_Dispenser)
	{
		Format(Object, sizeof(Object), "dispenser");
		credits += 2;
	}
	else if (objectType == TFExtObjectType:TFObject_TeleporterEntry)
	{
		Format(Object, sizeof(Object), "teleporter entrance");
		credits += 8;
	}
	else if (objectType == TFExtObjectType:TFObject_TeleporterExit)
	{
		Format(Object, sizeof(Object), "teleporter exit");
		credits += 8;
	}
	else if (objectType == TFExtObjectType:TFObject_Sentry)
	{
		Format(Object, sizeof(Object), "sentry gun");
		credits += 16;
	}
	else if (objectType == TFExtObjectType:TFObject_Sapper)
	{
		Format(Object, sizeof(Object), "sapper");
		credits += 4;
	}
	else if (objectType == TFExtObjectType:TFObject_MiniSentry)
	{
		Format(Object, sizeof(Object), "mini sentry");
		credits += 8;
	}
	else if (objectType == TFExtObjectType:TFObject_Amplifier)
	{
		Format(Object, sizeof(Object), "amplifier");
		credits += 32;
	}
	else if (objectType == TFExtObjectType:TFObject_RepairNode)
	{
		Format(Object, sizeof(Object), "repair node");
		credits += 32;
	}
	
	if (Building)
	{
		Format(Comment, sizeof(Comment), "%s {cyan}You destroyed it while it was still building!", Comment);
		credits += 8;
	}
	
	if (IsRegistered(attacker, mm_hDatabaseSQL, false, true))
	{
		CPrintToChat(attacker, "You gained {green}%d {default}shop credits for destroying that {blue}%s{default}.%s", credits, Object, Comment);
		ModifyCredits(attacker, credits);
	}
	if (IsRegistered(assister, mm_hDatabaseSQL, false, true))
	{
		if (credits % 2 == 1)
			credits -= 1;
		
		credits /= 2;
		
		CPrintToChat(assister, "You gained {green}%d {default}shop credits for assisting in destroying that {blue}%s{default}.", credits, Object);
		ModifyCredits(assister, credits);
	}
}
public Event_TankDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	for( new i = 0; i < GetMaxClients(); i++ ) 
	{
		if(IsRegistered(i, mm_hDatabaseSQL, false, true)) 
		{
			new Credits = 256;
			
			ModifyCredits(i, Credits);
		}
	}
}

public Event_PlayerTeleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new engineer = GetClientOfUserId(GetEventInt(event, "builderid"));
	new Float:Distance = GetEventFloat(event, "dist");
	
	EmitSoundToAll(SOUND_CUSTOM_FREEFORMJAZZ, player);
	
	if (engineer == player)
	{
		return;
	}
	
	if (IsRegistered(engineer, mm_hDatabaseSQL, false, true))
	{
		decl String:playerName[256];
		GetClientName(player, playerName, sizeof(playerName));
		new iCreditsGained = RoundToNearest(Distance / 5);
		CPrintToChat(engineer, "You've gained {green}%d {default}credits for teleporting {blue}%s{default}.", iCreditsGained, playerName);
		ModifyCredits(engineer, iCreditsGained);
	}
	else
	{
		CPrintToChat(engineer, "You could get credits for having your teammates use your teleporter. See {red}/register{default}.");
	}
}
public Event_PipebombDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsRegistered(client, mm_hDatabaseSQL, false, true))
	{
		new iCredits = 2;
		CPrintToChat(client, "You got {green}%d {default}credits for destroying that stickybomb.", iCredits);
		ModifyCredits(client, iCredits);
	}
}
public Event_PlayerHealed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Medic = GetClientOfUserId(GetEventInt(event, "healer"));
	new Patient = GetClientOfUserId(GetEventInt(event, "patient"));
	
	if (IsRegistered(Medic, mm_hDatabaseSQL, false, true))
	{
		decl String:patientName[256];
		GetClientName(Patient, patientName, sizeof(patientName));
		
		new Float:iHeal = float(GetEventInt(event, "amount"));
		new iCredits = RoundToNearest(iHeal / 5);
		
		if (iCredits == 0)
			return;
		
		CPrintToChat(Medic, "You've gained {green}%d {default}credits for healing {red}%d HP {default}back into {blue}%s{default}.", iCredits, RoundToNearest(iHeal), patientName);
		ModifyCredits(Medic, iCredits);
	}
}
public Event_ItemFound(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new Quality = GetEventInt(event, "quality");
	if (Quality == 5)
	{
		new allCredits = 1024;
		decl String:ClientName[64];
		GetClientName(client, ClientName, sizeof(ClientName));
		PrintHintTextToAll("%s has gotten an unusual! +%d credits for all!", ClientName, allCredits);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsRegistered(i, mm_hDatabaseSQL, false, true))
			{
				ModifyCredits(i, allCredits);
			}
		}
	}
}

public Action:Timer_CheckPlayerHealTarget_Kritz(Handle:Timer, Handle:Datapack)
{
	ResetPack(Datapack);
	new medic = GetClientOfUserId(ReadPackCell(Datapack));
	new Float:TimeLeft = ReadPackFloat(Datapack);

	TimeLeft -= 0.5;
	new target = TF2_GetHealingTarget(medic);
	if (target > 0 && target < MaxClients)
	{
		TF2_AddCondition(target, TFCond_CritOnWin, 0.5);
	}
	TF2_AddCondition(medic, TFCond_CritOnWin, 0.5);

	ResetPack(Datapack);
	WritePackCell(Datapack, GetClientUserId(medic));
	WritePackFloat(Datapack, TimeLeft);

	if (TimeLeft == 0.5)
		return Plugin_Stop;
	else
		return Plugin_Continue;
}

public Event_UberDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new medic = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsRegistered(medic, mm_hDatabaseSQL, false, true))
	{
		new credits = 64;
		if (GetWeaponItemDef(GetPlayerWeaponSlot(medic, 1)) == 998)
			credits /= 4;
		CPrintToChat(medic, "{default}You've gained {green}%d{default} credits for deploying that ubercharge.", credits);
		ModifyCredits(medic, credits);

		if (PlayerHasItem(medic, 211, mm_hDatabaseSQL))
		{
			if (GetRandomInt(1, 2) == 1)
			{
				new Handle:Datapack = INVALID_HANDLE;
				CreateDataTimer(0.5, Timer_CheckPlayerHealTarget_Kritz, Datapack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
				WritePackCell(Datapack, GetClientUserId(medic));
				WritePackFloat(Datapack, 8.0);
			}
		}
	}
	
	EmitSoundToAll(SOUND_CUSTOM_SMOKEWEEDEVERYDAY, medic);
}
public Event_Airblast(Handle:event, const String:name[], bool:dontBroadcast)
{
	new pyro = GetClientOfUserId(GetEventInt(event, "userid"));
	new object = GetEventInt(event, "object_entindex");
	
	if (GetEventInt(event, "weaponid") != 0)
	{
		decl String:class[128], String:ItemName[64];
		GetEntityClassname(object, class, sizeof(class));
		
		new creditsEarned = 4;
		
		if (strcmp(class, "tf_projectile_arrow") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "arrow");
		}
		else if (strcmp(class, "tf_projectile_ornament") == 0)
		{
			creditsEarned += 8;
			Format(ItemName, sizeof(ItemName), "wrap assassin ball");
		}
		else if (strcmp(class, "tf_projectile_cleaver") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "flying guillotine");
		}
		else if (strcmp(class, "tf_projectile_energy_ball") == 0)
		{
			creditsEarned += 8;
			Format(ItemName, sizeof(ItemName), "cow mangler projectile");
		}
		else if (strcmp(class, "tf_projectile_energy_ring") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "laser");
		}
		else if (strcmp(class, "tf_projectile_flare") == 0)
		{
			creditsEarned += 2;
			Format(ItemName, sizeof(ItemName), "flare");
		}
		else if (strcmp(class, "tf_projectile_healing_bolt") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "arrow");
		}
		else if (strcmp(class, "tf_projectile_jar") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "jarate");
		}
		else if (strcmp(class, "tf_projectile_jar_milk") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "mad milk");
		}
		else if (strcmp(class, "tf_projectile_pipe") == 0)
		{
			creditsEarned += 8;
			Format(ItemName, sizeof(ItemName), "grenade");
		}
		else if (strcmp(class, "tf_projectile_pipe_remote") == 0)
		{
			creditsEarned += 2;
			Format(ItemName, sizeof(ItemName), "stickybomb");
		}
		else if (strcmp(class, "tf_projectile_rocket") == 0)
		{
			creditsEarned += 2;
			Format(ItemName, sizeof(ItemName), "rocket");
		}
		else if (strcmp(class, "tf_projectile_sentryrocket") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "sentry rocket");
		}
		else if (strcmp(class, "tf_projectile_stun_ball") == 0)
		{
			creditsEarned += 16;
			Format(ItemName, sizeof(ItemName), "sandman ball");
		}
		else if (strcmp(class, "tf_projectile_syringe") == 0)
		{
			creditsEarned += 0;
			Format(ItemName, sizeof(ItemName), "syringe");
		}
		
		decl String:Disp[256];
		Format(Disp, sizeof(Disp), "deflecting that %s", ItemName);
		ModifyCreditsEx(pyro, creditsEarned, Disp);
		
		EmitSoundToAll(SOUND_CUSTOM_LEMONS, pyro);
	}
}
public Event_FlagCapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new TFTeam:Team = TFTeam:GetEventInt(event, "capping_team");
	
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsRegistered(i, mm_hDatabaseSQL, false, true) && 
			TFTeam:GetClientTeam(i) == Team)
		{
			new Credits = 32;
			ModifyCredits(i, Credits);
			CPrintToChat(i, "{default}You've gained {green}%d {default}credits for your team's flag capture.", Credits);
		}
	}
}
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarBool(sm_disable_sentrybusters))
	{
		if (IsMvM())
		{
			decl String:Name[MAX_NAME_LENGTH];
			GetClientName(client, Name, sizeof(Name));
			if (StrEqual(Name, "Sentry Buster", false))
				KickClient(client, "Busted");
		}
	}
}
public Action:Event_PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client))
	{
		return;
	}
	decl String:Name[MAX_NAME_LENGTH], String:NewName[MAX_NAME_LENGTH];
	GetEventString(event, "newname", Name, sizeof(Name));
	GetEventString(event, "newname", NewName, sizeof(NewName));

	GetClientNameWithInfo(client, NewName, sizeof(NewName));
	
	if (!StrEqual(Name, NewName))
	{	
		new Handle:Datapack = INVALID_HANDLE;
		CreateDataTimer(2.5, Timer_Rename, Datapack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		WritePackCell(Datapack, GetClientUserId(client));
		WritePackString(Datapack, NewName);
	}
}
public Event_MedicDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new medic = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:charged = GetEventBool(event, "charged");
	
	if (charged && !IsFakeClient(medic))
	{
		new Float:medicPos[3];
		new buffcount = 0;
		new hurtcount = 0;
		GetClientAbsOrigin(medic, medicPos);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && i != medic && GetClientTeam(i) == GetClientTeam(medic)) 
			{
				new Float:playerPos[3];
				GetClientAbsOrigin(i, playerPos);
				if (GetDistanceTotal(playerPos, medicPos) <= 450.0)
				{
					buffcount++;
					TF2_AddCondition(i, TFCond_Ubercharged, 4.0);
					TF2_AddCondition(i, TFCond_SpeedBuffAlly, 4.0);
					TF2_AddCondition(i, TFCond_Kritzkrieged, 2.0);
					CPrintToChat(i, "{cyan}You have been given 4 seconds of uber and 2 seconds of kritz because %N was killed with full ubercharge.", medic);
				}
			}
			else if (IsClientInGame(i) && IsPlayerAlive(i) && i != medic && GetClientTeam(i) != GetClientTeam(medic))
			{
				new Float:playerPos[3];
				GetClientAbsOrigin(i, playerPos);
				if (GetDistanceTotal(playerPos, medicPos) <= 450.0)
				{
					hurtcount++;
					TF2_AddCondition(i, TFCond_Jarated, 4.0);
					TF2_AddCondition(i, TFCond_Milked, 4.0);
					CPrintToChat(i, "{cyan}You have been jarated and mad milked for being near a fully ubered %N who is now dead.", medic);
				}
			}
		}
		if (buffcount > 0 || hurtcount > 0)
		{
			CPrintToChat(medic, "{cyan}Your death was not useless! You gave %d player%s 4 seconds of uber and 2 seconds of kritz when you died,", buffcount, (buffcount != 1 ? "s" : ""));
			CPrintToChat(medic, "  {cyan}and gave %d player%s 4 seconds of mad milk and jarate.", hurtcount, (hurtcount != 1 ? "s" : ""));
		}
	}
}
/*
 * METHODS
 */
 
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
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

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

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}
 

public OnGiftTouch(entity, iClient)
{
	if (iClient <= MaxClients)
	{
		GiveGift(iClient, IsRegistered(iClient, mm_hDatabaseSQL, false, true));
		OnGiftBreak(NULL_STRING, entity, iClient, 0.0);
	}
}

public OnGiftBreak(const String:output[], caller, activator, Float:delay)
{
	if (activator <= MaxClients && IsRegistered(activator, mm_hDatabaseSQL, false, true) && strcmp(output, NULL_STRING) != 0)
	{
		//Registered user shot this
		TF2_StunPlayer(activator, 2.5, 1.0, TF_STUNFLAGS_LOSERSTATE);
		TF2_AddCondition(activator, TFCond_Bonked, 15.0);
		
		decl String:SteamID[64];
		GetClientAuthString(activator, SteamID, sizeof(SteamID));
		
		new Handle:dataPack = INVALID_HANDLE;
		CreateDataTimer(0.1, Timer_BlowUpClient, dataPack, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dataPack, activator);
		WritePackString(dataPack, SteamID);
		
		EmitSoundToAll(SOUND_CUSTOM_NO, activator);
		
		CPrintToChat(activator, "{red}You're a registered user! Shooting gifts will only bring you pain.");
	}
	UnhookSingleEntityOutput(caller, "OnBreak", OnGiftBreak);
	AcceptEntityInput(caller, "kill");
}
stock bool:EarnAchievement(iClient, iAchievementID)
{
	decl String:achievementName[256];
	if (GetAchievement(iClient, iAchievementID, sizeof(achievementName), achievementName) == 0)
	{
		SetAchievement(iClient, iAchievementID);
		GenerateItemString(iClient, "has earned the achievement", achievementName, "");
		EmitSoundToAll(SOUND_ACHIEVEMENTUNLOCKED, iClient);
		AttachParticle(iClient, "achieved");
		AttachParticle(iClient, "mini_fireworks");	
		return true;
	}
	return false;
}
GiveGift(player, bool:clientRegistered = false, GiftType:Type = GIFTTYPE_SUPER)
{
	PlaySound(player, SOUND_ITEMPICKUP);
	if (!clientRegistered)
	{
		CPrintToChat(player, "These are much better if you {red}/register{default}.");
		CPrintToChat(player, "You get {orange}massive {default}boosts from them, credits, and credit {yellow}keys{default}.");
		if (player > MaxClients || player < 0)
			return;
		TF2_StunPlayer(player, 2.5, 1.0, TF_STUNFLAGS_LOSERSTATE);
		TF2_AddCondition(player, TFCond_Bonked, 15.0);
		
		decl String:SteamID[64];
		GetClientAuthString(player, SteamID, sizeof(SteamID));
		
		new Handle:dataPack = INVALID_HANDLE;
		CreateDataTimer(2.5, Timer_BlowUpClient, dataPack, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dataPack, player);
		WritePackString(dataPack, SteamID);
		
		PlaySound(player, SOUND_GIFTISTIMEBOMB, GetRandomFloat(0.75, 1.75));
		return;
	}
	
	EmitSoundToAll(SOUND_ITEMPICKUP, player);
	
	decl String:Name[64];	
	
	new Points = GetRandomInt(4, 256);
	
	new Float:EffectsTime = float(Points) / 8;
	
	GetClientName(player, Name, sizeof(Name));
	
	CPrintToChat(player, "{blue}%N {default}has found the gift!", player);
		
	if (EarnAchievement(player, 1))
	{
		new amountKeys = GetRandomInt(1, 5);
		CPrintToChat(player, "{cyan}Congratulations, you found %d keys!", amountKeys);
		ModifyKeys(player, amountKeys);
	}
			
	new random = GetRandomInt(1, 16);
		
	if (random == 1)
	{
		TF2_StunPlayer(player, 2.5, 1.0, TF_STUNFLAGS_LOSERSTATE);
		TF2_AddCondition(player, TFCond_Bonked, 15.0);
			
		decl String:SteamID[64];
		GetClientAuthString(player, SteamID, sizeof(SteamID));
			
		new Handle:dataPack = INVALID_HANDLE;
		CreateDataTimer(15.0, Timer_BlowUpClient, dataPack, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dataPack, player);
		WritePackString(dataPack, SteamID);
			
		PlaySound(player, SOUND_GIFTISTIMEBOMB, GetRandomFloat(0.75, 1.75));
		CPrintToChat(player, "{red}Sorry pal, you found the wrong gift. ");
	}
	
	CPrintToChat(player, "{green}Have a nice boost.");
	
	if (Type == GIFTTYPE_SUPER)
	{
		TF2_RegeneratePlayer(player);
		TF2_AddCondition(player, TFCond_SpeedBuffAlly, EffectsTime);
		TF2_AddCondition(player, TFCond_MegaHeal, EffectsTime);
		TF2_AddCondition(player, TFCond_CritCanteen, EffectsTime / 1.5);
		TF2_AddCondition(player, TFCond_UberchargedCanteen, EffectsTime / 2);
		TF2_AddCondition(player, TFCond_MarkedForDeath, EffectsTime * 2);
		TF2_ExSetUberLevel(player, 1.0);
	}
	if (Type == GIFTTYPE_DEFAULT)
	{
		TF2_AddCondition(player, TFCond_SpeedBuffAlly, EffectsTime);
		TF2_AddCondition(player, TFCond_CritCanteen, EffectsTime);
		TF2_AddCondition(player, TFCond_MarkedForDeath, EffectsTime * 1.5);
		TF2_ExSetUberLevel(player, TF2_GetUberLevel(player) + 0.25);
	}
	
	if (IsPowerOfTwo(Points))
	{
		new Keys = 1;
		CPrintToChat(player, "{cyan}Beautiful grab! {default}+{yellow}%d {default}key, +{green}%d {default}credits.", Keys, Points);
		ModifyKeys(player, Keys);
		ModifyCredits(player, Points);
		PlaySound(player, SOUND_KEYFROMGRAB, GetRandomFloat(0.75, 1.75));
		
		CPrintToChatAll("{purple}%s {default}found a {yellow}key {default}in a pickup box!", Name);
	}
	else
	{
		PlaySound(player, SOUND_OBJECTGRABBED, GetRandomFloat(0.75, 1.75));
		CPrintToChat(player, "{blue}Nice grab! {default}+{green}%d {default}credits.", Points);
		ModifyCredits(player, Points);
	}
}
public Action:RemoveBody(Handle:Timer, any:iClient) 
{
	new iBodyRagdoll;
	iBodyRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");

	if(IsValidEdict(iBodyRagdoll)) RemoveEdict(iBodyRagdoll);
}

public Action:RemoveGibs(Handle:Timer, any:iEnt) 
{
	if(IsValidEntity(iEnt)) {
		decl String:sClassname[64];
		GetEdictClassname(iEnt, sClassname, sizeof(sClassname));

		if(StrEqual(sClassname, "tf_ragdoll", false)) {
			RemoveEdict(iEnt);
		}
	}
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
public Action:OnClientSpray(const String:te_name[], const clients[], client_count, Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	if(client && IsClientInGame(client))
	{		
		if (!IsClientAuthorized(client) || IsFakeClient(client))
		{
			return Plugin_Handled;
		}
		if (!IsRegistered(client, mm_hDatabaseSQL, false, true))
		{
			CPrintToChat(client, "{red}Sorry! Only registered players can use sprays!");	
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
stock AddSoundToDownloadsTable(String:Sound[], bool:Precache = true)
{
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "sound/%s", Sound);
	AddFileToDownloadsTable(path);
	if (Precache)
		PrecacheSound(Sound);
}
public Action:voicemenu(client, const String:szCommand[], argc)
{
	if (client == 0 || !IsClientInGame(client))
		return Plugin_Continue;

	new String:szBuffer[16];
	
	const MEDIC_VOICE_MENU = 0;
	const MEDIC_VOICE_SUBMENU = 0;

	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	if(StringToInt(szBuffer) != MEDIC_VOICE_MENU)
		return Plugin_Continue;

	GetCmdArg(2, szBuffer, sizeof(szBuffer));
	if(StringToInt(szBuffer) != MEDIC_VOICE_SUBMENU)
		return Plugin_Continue;

	new TeamEngineer = 0;	
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		if (GetClientTeam(client) != GetClientTeam(i))
			if (!TF2_IsPlayerInCondition(client, TFCond_Disguised))
				continue;
		if (TFClassType:TF2_GetPlayerClass(i) == TFClass_Engineer && i != client)
			TeamEngineer = i;
		if (TFClassType:TF2_GetPlayerClass(i) == TFClass_Medic && i != client && IsPlayerAlive(i))
			return Plugin_Continue;
	}

	CPrintToChat(client, "{red}There is no%s medic on your team%s, you may not call for a medic!", (TFClassType:TF2_GetPlayerClass(client) == TFClass_Medic ? " other" : " living"), (TF2_IsPlayerInCondition(client, TFCond_Disguised) ? " or the other team" : ""));
	if (TFClassType:TF2_GetPlayerClass(client) == TFClass_Engineer)
		CPrintToChat(client, "{red}Instead, go to your dispenser or build one.");
	else if (TeamEngineer != 0)
		CPrintToChat(client, "{red}Your team has an engineer. Find %N, find his dispenser, and use that to heal.", TeamEngineer);
	return Plugin_Handled;
}
public Action:say(client, const String:command[], argc)
{
	if (!client || client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Continue;
	decl String:Message[MAX_MESSAGE_LENGTH];
	GetCmdArgString(Message, sizeof(Message));
	StripQuotes(Message);
	if (strncmp(Message, ">", 1) == 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))	
				CPrintToChat(i, "%s%s%N {default}:  {lightgreen}%s", (IsPlayerAlive(client) ? "" : "*DEAD* "), ((TFTeam:GetClientTeam(client) == TFTeam:TFTeam_Red ? "{red}" : (TFTeam:GetClientTeam(client) == TFTeam:TFTeam_Blue ? "{blue}" : "{default}"))), client, Message);
		}
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}
public Action:say_team(client, const String:command[], argc)
{
	if (!client || client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Continue;
	decl String:Message[MAX_MESSAGE_LENGTH];
	GetCmdArgString(Message, sizeof(Message));
	StripQuotes(Message);
	if (strncmp(Message, ">", 1) == 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (GetClientTeam(i) == GetClientTeam(client) && (IsClientInGame(i)))
			{
				CPrintToChat(i, "%s(TEAM) %s%N {default}:  {lightgreen}%s", (IsPlayerAlive(client) ? "" : "*DEAD* "), ((TFTeam:GetClientTeam(client) == TFTeam:TFTeam_Red ? "{red}" : (TFTeam:GetClientTeam(client) == TFTeam:TFTeam_Blue ? "{blue}" : "{default}"))), client, Message);
			}
		}
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
    SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
}

public Action:OnSceneSpawned(entity)
{
    new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
    GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
    if (StrEqual(scenefile, "scenes/player/spy/low/taunt05.vcd"))
    {
        if (IsMerbo(client))
        {
        	if (GetRandomInt(1, 2) == 1)
        	{
				PrintToMerbo("Spycrab taunt allowed!");
			}
			else
			{
				PrintToMerbo("Spycrab taunt bypassed!");
				AcceptEntityInput(entity, "kill");
				TF2_RemoveCondition(client, TFCond_Taunting);
			}
        }
    }
}  