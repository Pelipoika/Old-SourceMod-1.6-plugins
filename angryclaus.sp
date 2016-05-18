#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <morecolors>

#define PLUGIN_VERSION "1.3"

#define SOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define DEMOMAN		"models/bots/demo_boss/bot_demo_boss.mdl"
#define HEAVY		"models/bots/heavy_boss/bot_heavy_boss.mdl"
#define PYRO		"models/bots/pyro_boss/bot_pyro_boss.mdl"
#define SCOUT		"models/bots/scout_boss/bot_scout_boss.mdl"
#define SNIPER		"models/bots/sniper/bot_sniper.mdl"
#define SPY			"models/bots/spy/bot_spy.mdl"
#define MEDIC		"models/bots/medic/bot_medic.mdl"
#define ENGINEER	"models/bots/engineer/bot_engineer.mdl"

#define SPAWN	"mvm/mvm_deploy_giant.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Charged Soldier AngryClaus",
	author = "Pelipoika	(FlamingSarge)",
	description = "Name",
	version = PLUGIN_VERSION,
	url = ""
}

new bool:g_IsModel[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsTP[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsHHH[MAXPLAYERS + 1] = {false, ...};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_angryclaus", Command_Horsemann, ADMFLAG_ROOT, "It's a good time to run");
	
	AddNormalSoundHook(DeflectorSH);
	
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
	PrecacheModel(SOLDIER, true);
	PrecacheModel(DEMOMAN, true);
	PrecacheModel(HEAVY, true);
	PrecacheModel(PYRO, true);
	PrecacheModel(SCOUT, true);
	PrecacheModel(SNIPER, true);
	PrecacheModel(SPY, true);
	PrecacheModel(MEDIC, true);
	PrecacheModel(ENGINEER, true);

	PrecacheSound(SPAWN, true);
	PrecacheSound(DEATH, true);
	
	PrecacheGeneric("pumpkin_explode");
	PrecacheGeneric("merasmus_spawn");
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

		ServerCommand("sm_rtd_enabled 1");
		ServerCommand("sm plugins load endless_spree.smx");
		ServerCommand("sm_csay Angry Claus has Vanished!");
		ServerCommand("mp_autoteambalance 1");
	}
	g_bIsHHH[client] = false;
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if (g_bIsHHH[victim])
	{
		EmitSoundToAll(DEATH);
		CPrintToChatAll("[EGN] Angry Claus has been destroyed by %N \n[EGC] Assisted by %N", attacker, assister);
		
		new Float:pos[3];
		pos[2] += 40.0; //This can be used to offset the particle up/down
		GetClientAbsOrigin(victim, pos);
		CreateParticle("pumpkin_explode", pos);
	}
}

public Action:SetModel(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond_HalloweenCritCandy, 9999.9);
		TF2_AddCondition(client, TFCond_Kritzkrieged, 999999.0);
		
		new TFClassType:class = TF2_GetPlayerClass(client);
		switch(class)
		{
			case TFClass_Scout:		SetVariantString(SCOUT);
			case TFClass_Soldier:	SetVariantString(SOLDIER);
			case TFClass_DemoMan:	SetVariantString(DEMOMAN);
			case TFClass_Medic:		SetVariantString(MEDIC);
			case TFClass_Pyro:		SetVariantString(PYRO);
			case TFClass_Spy:		SetVariantString(SPY);
			case TFClass_Engineer:	SetVariantString(ENGINEER);
			case TFClass_Sniper:	SetVariantString(SNIPER);
			case TFClass_Heavy:		SetVariantString(HEAVY);
		}
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

		g_IsModel[client] = true;
	}
}

public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_IsModel[client])
	{
		TF2_RemoveCondition(client, TFCond_HalloweenCritCandy);
		SetEntPropFloat( client, Prop_Send, "m_flModelScale", 1.0 );
		UpdatePlayerHitbox(client, 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
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
		LogAction(client, target_list[i], "\"%L\" made \"%L\" an Angry Claus!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

MakeHorsemann(client)
{
	new Float:pos[3];
	pos[2] += 0.0; //This can be used to offset the particle up/down
	GetClientAbsOrigin(client, pos);
	CreateParticle("merasmus_spawn", pos);
	
	ServerCommand("sm_rtd_enabled 0");
	ServerCommand("sm plugins unload endless_spree.smx");
	ServerCommand("sm_csay Angry Claus has Spawned! Arghhh...");
	ServerCommand("mp_autoteambalance 0");

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_SetHealth(client, 4000);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.6 );
	UpdatePlayerHitbox(client, 1.6);
	SetEntPropFloat(client, Prop_Send, "m_flStepSize", 28.8);
	
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
		GiveAxe(client);
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

stock GiveAxe(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0); 

	TF2Attrib_SetByDefIndex(weapon, 289, 1.0);
	TF2Attrib_SetByDefIndex(weapon, 328, 1.0);
	TF2Attrib_SetByDefIndex(weapon, 26, 3800.0);
	TF2Attrib_SetByDefIndex(weapon, 475, 0.5);
	TF2Attrib_SetByDefIndex(weapon, 330, 3.0);
	TF2Attrib_SetByDefIndex(weapon, 329, 0.4);
	TF2Attrib_SetByDefIndex(weapon, 252, 0.4);
	TF2Attrib_SetByDefIndex(weapon, 107, 0.5);
	TF2Attrib_SetByDefIndex(weapon, 402, 1.0);
	TF2Attrib_SetByDefIndex(weapon, 96, 1.2);
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

public Action:DeflectorSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;
	
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

stock CreateParticle(String:particle[], Float:pos[3])
{
	new tblidx = FindStringTable("ParticleEffectNames");
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	for(new i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_SendToClient(i, 0.0);
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}