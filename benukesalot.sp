#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <benukesalot>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0"

#define HHH		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"#mvm/giant_common/giant_common_explodes_01.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"
#define SHOOT	"mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

#define LEFTFOOT	")mvm/giant_demoman/giant_demoman_step_01.wav"
#define LEFTFOOT1	")mvm/giant_demoman/giant_demoman_step_02.wav"
#define RIGHTFOOT	")mvm/giant_demoman/giant_demoman_step_03.wav"
#define RIGHTFOOT1	")mvm/giant_demoman/giant_demoman_step_04.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Sir Nukesalot",
	author = "Pelipoika	(FlamingSarge)",
	description = "Play as Sir Nukesalot from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

new bool:g_IsModel[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsHHH[MAXPLAYERS + 1] = {false, ...};

//sm_gi @me 996 1 50 6 0 0 tf_weapon_cannon 
//"466 ; 0" "318 ; 1.8" "6 ; 2" "3 ; 0.5" "103 ; 0.8" "411 ; 5" "2 ; 7" "522 ; 1" "99 ; 1.2" "521 ; 1" "112 ; 1" "107 ; 0.35" "252 ; 0.4" "329 ; 0.4" "330 ; 4" "236 ; 1" "26 ; 49825"

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_benukesalot", Command_Deflector, ADMFLAG_ROOT, "It's a good time to run");
	
	AddNormalSoundHook(DeflectorSH);
	
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	HookEvent("player_death", Event_Death,  EventHookMode_Post);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("BeNukesalot_MakeNuker", Native_SetNuker);
	CreateNative("BeNukesalot_IsNuker", Native_IsNuker);
	RegPluginLibrary("benukesalot");
	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}

public OnClientDisconnect_Post(client)
{
	g_IsModel[client] = false;
	g_bIsHHH[client] = false;
}

public OnMapStart()
{
	PrecacheModel(HHH, true);
	PrecacheSound(SPAWN, true);
	PrecacheSound(DEATH, true);
	PrecacheSound(LOOP, true);
	PrecacheSound(SHOOT, true);
	
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
			StopSound(client, SNDCHAN_AUTO, LOOP);
			
			TF2Attrib_RemoveAll(client);
			EmitSoundToAll(DEATH);
		}
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond_HalloweenCritCandy, 9999.9);
		TF2_AddCondition(client, TFCond_Kritzkrieged, 999999.0);
	
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
		
		TF2Attrib_RemoveAll(weapon);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		UpdatePlayerHitbox(client, 1.0);

		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_IsModel[client] = false;
	}
}
public Action:Command_Deflector(client, args)
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
		MakeNuker(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" Sir Nukesalot!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

MakeNuker(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);
	EmitSoundToAll(LOOP, client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, HHH);
	
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 2);
	TF2_RemoveWeaponSlot(client, 1);
	
	TF2_SetHealth(client, 25000);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.6);
	UpdatePlayerHitbox(client, 1.6);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.5);
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
		GiveDeflector(client);
}

stock GiveDeflector(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0); 
	
	TF2Attrib_SetByName(weapon, "grenade launcher mortar mode", 0.0);
	TF2Attrib_SetByName(weapon, "faster reload rate", 1.8);
	TF2Attrib_SetByName(weapon, "fire rate bonus", 2.0);
	TF2Attrib_SetByName(weapon, "clip size penalty", 0.5);
	TF2Attrib_SetByName(weapon, "Projectile speed increased", 0.8);
	TF2Attrib_SetByName(weapon, "projectile spread angle penalty", 5.0);
	TF2Attrib_SetByName(weapon, "damage bonus", 7.0);
	TF2Attrib_SetByName(weapon, "damage causes airblast", 1.0);
	TF2Attrib_SetByName(weapon, "blast radius increased", 1.2);
	TF2Attrib_SetByName(weapon, "use large smoke explosion", 1.0);
	
	TF2Attrib_SetByName(weapon, "move speed bonus", 0.35);
	TF2Attrib_SetByName(weapon, "damage force reduction", 0.4);
	TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier", 0.4);
	
	TF2Attrib_SetByName(weapon, "mod weapon blocks healing", 1.0);
	TF2Attrib_SetByName(weapon, "max health additive bonus", 24825.0); 
	TF2Attrib_SetByName(weapon, "health from packs decreased", 0.001);
	TF2Attrib_SetByName(weapon, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(weapon, "ammo regen", 1.0);
	//TF2Attrib_SetByName(weapon, "override footstep sound set", 4.0);	//We don't need you, we have our own footstep system
	
	TF2_RemoveAllWearables(client);
}

public Action:DeflectorSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT);
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(entity)) return Plugin_Continue;
	new client = entity;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (g_bIsHHH[client])
	{
		if (StrContains(sample, "vo/", false) == -1) return Plugin_Continue;
		if (StrContains(sample, "announcer", false) != -1) return Plugin_Continue;
		if (volume == 0.99997) return Plugin_Continue;
		ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
		ReplaceString(sample, sizeof(sample), "_", "_m_", false);
		ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false);
		new String:classname[10], String:classname_mvm[15];
		TF2_GetNameOfClass(class, classname, sizeof(classname));
		Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
		ReplaceString(sample, sizeof(sample), classname, classname_mvm, false);
		new String:soundchk[PLATFORM_MAX_PATH];
		Format(soundchk, sizeof(soundchk), "sound/%s", sample);
		PrecacheSound(sample);
		return Plugin_Changed;
	}
	return Plugin_Continue;
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

stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}

public Native_SetNuker(Handle:plugin, args)
	MakeNuker(GetNativeCell(1));
	
public Native_IsNuker(Handle:plugin, args)
	return g_bIsHHH[GetNativeCell(1)];

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock TF2_RemoveAllWearables(client)
{
	new wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}