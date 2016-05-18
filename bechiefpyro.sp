#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "1.3"

#define HHH "models/bots/pyro_boss/bot_pyro_boss.mdl"
#define SPAWN "mvm/mvm_deploy_giant.wav"
#define DEATH "mvm/giant_soldier/giant_soldier_explode.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Chief Pyro",
	author = "Pelipoika	(FlamingSarge)",
	description = "Op as well",
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
	CreateConVar("bethechiefpyro_version", PLUGIN_VERSION, "[TF2] Be the C. Punch Soldier version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	g_hCvarThirdPerson = CreateConVar("bethechiefpyro_thirdperson", "0", "Whether or not C. Punch ought to be in third-person", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd("sm_bechief", Command_Horsemann, ADMFLAG_ROOT, "It's a good time to run");
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
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveModel(client);
	if (g_bIsHHH[client])
	{
		new weapon = GetPlayerWeaponSlot(client, 0); 
		TF2Attrib_RemoveAll(weapon);
		
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
		new weapon = GetPlayerWeaponSlot(client, 0); 
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
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Chief Pyro!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

MakeHorsemann(client)
{
	TF2_SetPlayerClass(client, TFClass_Pyro);
	SetWearableAlpha(client);
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
//	TF2_RemoveWeaponSlot(client, 0);
//	TF2_RemoveWeaponSlot(client, 1);
//	TF2_RemoveWeaponSlot(client, 5);
//	TF2_RemoveWeaponSlot(client, 3);
	
	TF2_SetHealth(client, 55000);
	
	new String:clientName[128];
	GetClientName(client, clientName, sizeof(clientName));
	ServerCommand("sm_resize %s 1.9", clientName);
	
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
	new weapon = GetPlayerWeaponSlot(client, 0); 
	
	TF2Attrib_SetByName(weapon, "max health additive bonus", 55000.0);
	TF2Attrib_SetByName(weapon, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(weapon, "ammo regen", 100.0);
	TF2Attrib_SetByName(weapon, "airblast pushback scale", 2.0);
	TF2Attrib_SetByName(weapon, "damage bonus", 5.0);
	TF2Attrib_SetByName(weapon, "move speed bonus", 0.4);
	TF2Attrib_SetByName(weapon, "health regen", 500.0);
	TF2Attrib_SetByName(weapon, "damage force reduction", 0.3);
	TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(weapon, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(weapon, "airblast vertical vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(weapon, "rage giving scale", 0.1);
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

stock SetWearableAlpha(client)
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