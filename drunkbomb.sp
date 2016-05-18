#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define SOUND_GIBBERISH		"vo/taunts/demoman_taunts01.wav"
#define SOUND_EXPLODE_PRE	"items/cart_explode_trigger.wav"
#define SOUND_EXPLODE		"items/cart_explode.wav"
#define SOUND_EXPLODE2		"weapons/explode2.wav"
#define MDL_BOMB			"models/props_td/atom_bomb.mdl"

new bool:WantsToBomb[MAXPLAYERS+1];

public OnMapStart()
{
	PrecacheSound(SOUND_GIBBERISH);
	PrecacheSound(SOUND_EXPLODE_PRE);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_EXPLODE2);
	PrecacheModel(MDL_BOMB);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
    SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
}

public Action:OnSceneSpawned(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
	if(IsValidClient(client))
	{
		GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
		if (StrEqual(scenefile, "scenes/player/demoman/low/taunt03_v1.vcd") || StrEqual(scenefile, "scenes/player/demoman/low/taunt03_v2.vcd") || StrEqual(scenefile, "scenes/player/demoman/low/taunt03_v3.vcd"))
		{
			WantsToBomb[client] = true;
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(IsValidClient(client) && condition == TFCond_Taunting && TF2_GetPlayerClass(client) == TFClass_DemoMan && WantsToBomb[client])
	{
		WantsToBomb[client] = false;
		
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, sizeof(SteamID));
		
		new Handle:dataPack = INVALID_HANDLE;
		CreateDataTimer(5.5, Timer_BlowUpClient, dataPack, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dataPack, client);
		WritePackString(dataPack, SteamID);
		
		EmitSoundToAll(SOUND_GIBBERISH, client);
		EmitSoundToAll(SOUND_EXPLODE_PRE, client);
		
		PrintCenterTextAll("Watchout for %N, He is a DRUNK BOM!", client);
		PrintCenterText(client, "You are a DRUNK BOMB!");
	}
}

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
	
	EmitSoundToAll(SOUND_EXPLODE_PRE, iClient);
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

stock bool:AttachParticle(Ent, String:particleType[], Float:timeUntilRemove=10.0, bool:cache=false)
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	new String:tName[128];
	new Float:f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", Ent);
	DispatchKeyValue(Ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(timeUntilRemove, DeleteParticle, particle);
	return true;
}

public Action:DeleteParticle(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
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

stock Float:GetDistanceTotal(Float:vec1[3], Float:vec2[3])
{
	new Float:vec[3];
	for (new i = 0; i < 3; i++)
	{
		vec[i] = (vec1[i] > vec2[i]) ? vec1[i] - vec2[i] : vec2[i] - vec1[i];
	}
	return SquareRoot(Pow(vec[0], 2.0) + Pow(vec[1], 2.0) + Pow(vec[2], 2.0));
}

stock DoDamage(client, target, amount)
{
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		new String:dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

/*
"cinefx_goldrush_embers"
"cinefx_goldrush_debris"
"cinefx_goldrush_initial_smoke"
"cinefx_goldrush_flames"
"cinefx_goldrush_flash"
"cinefx_goldrush_burningdebris"
"cinefx_goldrush_smoke"
"cinefx_goldrush_hugedustup"
*/