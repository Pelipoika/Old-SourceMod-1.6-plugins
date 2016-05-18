#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//Laser monoculus
//Attack is charged laser
//--------------
//Merasmus the head magnifier
//Spell makes peoples heads big, if too big, head go boom.

#define WEAPON_BIG_MALLET "models/weapons/c_models/c_big_mallet/c_big_mallet.mdl"

new flHHHAxe[2049] = {INVALID_ENT_REFERENCE, ... };
new g_bIsCustomBoss[2049] = false;

//weapons/bumper_car_hit_into_air.wav

public OnPluginStart()
{
	AddNormalSoundHook(HorsemannSH);
	HookEvent("player_death", player_death, EventHookMode_Pre);
}

public OnMapStart()
{
	PrecacheModel(WEAPON_BIG_MALLET);
	PrecacheSound("misc/halloween/strongman_fast_impact_01.wav");
	PrecacheGeneric("hammer_impact_button");
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "headless_hatman")) //m_hMoveChild
	{
		if(GetRandomFloat(0.0, 1.0) <= 0.25)
		{
			SDKHook(entity, SDKHook_SpawnPost, OnBossSpawn);
		}
	}
}

public OnBossSpawn(entity)
{
	if(IsValidEntity(entity))
	{
		new AXE = GetEntPropEnt(entity, Prop_Data, "m_hMoveChild");
		if(IsValidEntity(AXE))
		{
			SetEntityModel(AXE, WEAPON_BIG_MALLET);
			flHHHAxe[entity] = EntIndexToEntRef(AXE);
			g_bIsCustomBoss[entity] = true;
		}
	}
}

//necro_smasher

public Action:HorsemannSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(!IsValidEntity(entity)) return Plugin_Continue;
	if(!g_bIsCustomBoss[entity]) return Plugin_Continue;
	
	if(StrContains(sample, "knight_axe_miss", false) != -1)
	{
		Format(sample, sizeof(sample), "misc/halloween/strongman_fast_impact_01.wav");
		EmitSoundToAll(sample, entity);
		
		decl Float:pos[3], Float:pos2[3], Float:Vec[3], Float:AngBuff[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	
		TE_ParticleToAll("hammer_impact_button", pos, pos, NULL_VECTOR, entity, _, _, false);
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Send, "m_hGroundEntity") != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
				if (GetVectorDistance(pos, pos2) <= 300.0)
				{
					MakeVectorFromPoints(pos, pos2, Vec);
					GetVectorAngles(Vec, AngBuff);
					AngBuff[0] -= 30.0;                        // push him toward the direction of sky.
					GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(Vec, Vec);
					ScaleVector(Vec, 500.0);                // 500.0 is the push factor. Scale factor.. what ever..
					Vec[2] += 250.0;
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:player_death(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iEntity = GetEventInt(hEvent, "inflictor_entindex");
	
	if (IsValidEntity(iEntity) && g_bIsCustomBoss[iEntity])
	{
		SetEventString(hEvent, "weapon", "necro_smasher");
		SetEventString(hEvent, "weapon_logclassname", "necro_smasher");
	}
	
	return Plugin_Continue;
}

TE_ParticleToAll(String:Name[], Float:origin[3]=NULL_VECTOR, Float:start[3]=NULL_VECTOR, Float:angles[3]=NULL_VECTOR, entindex=-1,attachtype=-1,attachpoint=-1, bool:resetParticles=true)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToAll();
}