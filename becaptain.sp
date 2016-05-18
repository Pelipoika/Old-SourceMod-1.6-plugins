#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "1.3"

#define HHH "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN	"mvm/mvm_deploy_giant.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_heavy/giant_heavy_loop.wav"
#define LEFTFOOT "mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1 "mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT "mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1 "mvm/giant_heavy/giant_heavy_step04.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Captain Punch",
	author = "Pelipoika	(FlamingSarge)",
	description = "Op as hell",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle:g_hCvarThirdPerson;
new bool:g_IsModel[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsTP[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsHHH[MAXPLAYERS + 1] = {false, ...};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("bethecaptain_version", PLUGIN_VERSION, "[TF2] Be the C. Punch Soldier version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	g_hCvarThirdPerson = CreateConVar("bethecaptain_thirdperson", "0", "Whether or not C. Punch ought to be in third-person", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd("sm_becaptain", Command_Horsemann, ADMFLAG_ROOT, "It's a good time to run");
	AddNormalSoundHook(HorsemannSH);
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	HookEvent("player_death", Event_Death,  EventHookMode_Post);
}
public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}
public OnClientDisconnect_Post(client)
{
	g_IsModel[client] = false;
	g_bIsTP[client] = false;
	g_bIsHHH[client] = false;
}
public OnMapStart()
{
	PrecacheModel(HHH, true);
	PrecacheSound(SPAWN, true);
	PrecacheSound(DEATH, true);
	PrecacheSound(LOOP, true);
	
	PrecacheSound(LEFTFOOT, true);
	PrecacheSound(LEFTFOOT1, true);
	PrecacheSound(RIGHTFOOT, true);
	PrecacheSound(RIGHTFOOT1, true);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveModel(client);
	if (g_bIsHHH[client])
	{
		new weapon = GetPlayerWeaponSlot(client, 2); 
		TF2Attrib_RemoveAll(weapon);
		
		StopSound(client, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_loop.wav");
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
	}
	g_bIsHHH[client] = false;
}
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsHHH[client])
		{
			StopSound(client, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_loop.wav");
			EmitSoundToAll(DEATH);
		}
	}
}
public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

		g_IsModel[client] = true;
	}
	
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_IsModel[client])
	{
		new weapon = GetPlayerWeaponSlot(client, 2); 
		new String:clientName[128];
		GetClientName(client, clientName, sizeof(clientName));
		
		TF2Attrib_RemoveAll(weapon);
		ServerCommand("sm_resize %s 1.0", clientName);
		
//		SetEntPropFloat( client, Prop_Send, "m_flModelScale", 1.0 );
//		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_IsModel[client] = false;
	}
}
public Action:Command_Horsemann(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		MakeHorsemann(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Captain Punch!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

MakeHorsemann(client)
{
	TF2_SetPlayerClass(client, TFClass_Heavy);
	EmitSoundToAll("mvm/giant_heavy/giant_heavy_loop.wav", client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, HHH);
	if (GetConVarBool(g_hCvarThirdPerson))
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	TF2_RemoveWeaponSlot(client, 0);
//	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	
	TF2_SetHealth(client, 60000);
	
	new String:clientName[128];
	GetClientName(client, clientName, sizeof(clientName));
	ServerCommand("sm_resize %s 1.6", clientName);
	
//	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.6 );
//	SetEntPropFloat(client, Prop_Send, "m_flStepSize", 28.8);
	g_bIsHHH[client] = true;
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveAxe(client);
}

stock GiveAxe(client)
{
	new weapon = GetPlayerWeaponSlot(client, 2); 
	
	TF2Attrib_SetByDefIndex(weapon, 205, 0.6);
//	; 205 ; 0.6	w
	TF2Attrib_SetByDefIndex(weapon, 206, 2.0);
//	; 206 ; 2	w
	TF2Attrib_SetByDefIndex(weapon, 177, 1.2);
//	; 177 ; 1.2	w
	TF2Attrib_SetByDefIndex(weapon, 6, 1.6);
//	; 6 ; 1.6	w
	TF2Attrib_SetByDefIndex(weapon, 2, 5.0);
//	; 2 ; 5		w
//	TF2Attrib_SetByDefIndex(weapon, 107, 0.4);
	TF2Attrib_SetByName(client, "move speed bonus", 0.4);
	
	//Weapons above
	
//	; 107 ; 0.4	p
	TF2Attrib_SetByDefIndex(weapon, 57, 250.0);
//	; 57 ; 250	p
	TF2Attrib_SetByDefIndex(weapon, 252, 0.3);
//	; 252 ; 0.3 p
	TF2Attrib_SetByDefIndex(weapon, 329, 0.3);
//	; 329 ; 0.3	p
//	TF2Attrib_SetByDefIndex(weapon, 330, 2.0);	//Footsteps
//	; 330 ; 2	p
	TF2Attrib_SetByDefIndex(weapon, 405, 0.1);
//	; 405 ; 0.1	p
	TF2Attrib_SetByDefIndex(weapon, 478, 0.1);
//	; 478 ; 0.1	p
	TF2Attrib_SetByDefIndex(weapon, 26, 59700.0);
//	; 26 ; 59700	p
	TF2Attrib_SetByDefIndex(weapon, 402, 1.0);
//	; 402 ; 1	p
	
	/*
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_fists");
		TF2Items_SetItemIndex(hWeapon, 331);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		new String:weaponAttribs[] = "205 ; 0.6 ; 206 ; 2 ; 177 ; 1.2 ; 6 ; 1.6 ; 2 ; 5 ; 107 ; 0.4 ; 57 ; 250 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2 ; 405 ; 0.1 ; 478 ; 0.1 ; 26 ; 59700 ; 402 ; 1";
		new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0)
		{
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) 
			{
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} 
		else //sm_gi @me 331 3 69 5 0 0 tf_weapon_fists "205 ; 0.6" "206 ; 2" "177 ; 1.2" "6 ; 1.6" "2 ; 5" "107 ; 0.4" "57 ; 250" "252 ; 0.3" "329 ; 0.3" "330 ; 2" "405 ; 0.1" "478 ; 0.1" "26 ; 59700" "402 ; 1"
		{
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);
	}*/
}
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}
public Action:HorsemannSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;
	
	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step04.wav");
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
stock bool:FindHHHSaxton(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 277 || idx == 278) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return true;
			}
		}
	}
	return false;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}