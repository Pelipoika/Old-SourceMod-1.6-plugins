#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

new Float:gf_RocketDamage = 69.0;			//Rocket damage
new Float:gf_RocketDistance = 2250000.0;	//See range of dispenser
new Float:gf_RocketSpeed = 250.0;			//Speed of rocket
//new Float:gf_RocketSpeedMult = 1.1;			//Rocket speed acceleration rate UNUSED atm

new Handle:hDisp = INVALID_HANDLE;

new MapStarted = false;						//Prevents a silly error from occuring with the AttachParticle stock

#define MDL_ROCKET	"models/props_mvm/mvm_human_skull.mdl"
#define SND_SHOOT	"mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
//#define SND_SHOOT	"npc/strider/fire.wav"

//mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav
//mvm/giant_soldier/giant_soldier_rocket_shoot.wav
//mvm/giant_demoman/giant_demoman_grenade_shoot.wav

enum HomingProjectileTargetMode
{
	Target_Closest,
	Target_Weakest
};

public Plugin:myinfo = 
{
	name = "[TF2] Dispenser rockets",
	author = "Pelipoika",
	description = "Makes dispensers shoot homing rockets",
	version = "3.0",
	url = ""
}

public OnPluginStart()
{
	hDisp = CreateTimer(2.0, timer_hDisp, _, TIMER_REPEAT);				//This controlls how often the dispenser fires a rocket
	
	HookEvent("building_info_changed", Event_BuildingInfoChanged);
}

public OnPluginEnd()
{
	if (hDisp != INVALID_HANDLE)
    {
        KillTimer(hDisp);
        hDisp = INVALID_HANDLE;
    }
}

public OnMapStart()
{
	PrecacheModel(MDL_ROCKET);
	PrecacheSound(SND_SHOOT);
	
	MapStarted = true;
}

public OnMapEnd()
{
	MapStarted = false;
}

public Action:timer_hDisp(Handle:timer)
{
	Handle_DispenserRockets();
}

public Action:Event_BuildingInfoChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	//I cant remember what i was supposed to do XD
}

Handle_DispenserRockets()
{
	new index = -1;
	while ((index = FindEntityByClassname(index, "obj_dispenser")) != -1) //Loop through all the dispensers
	{	
		decl Float:playerpos[3], Float:targetvector[3], Float:dAng[3];
		new Float:dPos[3];
		new client = GetEntPropEnt(index, Prop_Send, "m_hBuilder");
		new iAmmo = GetEntProp(index, Prop_Send, "m_iAmmoMetal");
		new newiAmmo = iAmmo -= 40;
		
		if(IsValidClient(client))
		{
			new bossteam = GetClientTeam(client);
			
			decl playerarray[MAXPLAYERS+1];
			new playercount;
				
			new bool:disBuilding = GetEntProp(index, Prop_Send, "m_bBuilding") == 1;
			new bool:disPlacing = GetEntProp(index, Prop_Send, "m_bPlacing") == 1;
			new bool:disCarried = GetEntProp(index, Prop_Send, "m_bCarried") == 1;
			
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", dPos);
			//GetEntPropVector(index, Prop_Send, "m_angRotation", dAng);

			if(!disBuilding && !disPlacing && !disCarried)
			{
				new disLevel = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");
				if(disLevel > 2) 		//This controls the level the dispenser has to be to be able to shoot rockets
				{
					dPos[0] += 0.0;		//X		set the rocket's spawn position to the dispensers top
					dPos[1] += 0.0;		//Y
					dPos[2] += 64.0;	//Z
						
					dAng[0] = 0.0;		//X		Makes sure the rocket is fired upwards
					dAng[1] = 0.0;		//Y
					dAng[2] = 95.0;		//Z

					TR_TraceRayFilter(dPos, dAng, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
					TR_GetEndPosition(targetvector);

					for(new player = 1; player <= MaxClients; player++)
					{
						if(player != client && IsClientInGame(player) && IsPlayerAlive(player))
						{
							if(HomingProjectile_IsValidTarget(player, index, GetEntProp(index, Prop_Send, "m_iTeamNum")))
							{
								GetClientEyePosition(player, playerpos);
								playerpos[2] -= 30.0;
								if(GetVectorDistance(dPos, playerpos, true) < gf_RocketDistance  && CanSeeTarget(dPos, playerpos, player, bossteam))
								{
									playerarray[playercount] = player;						//Make an array of valid targets
									playercount++;
								}
							}
						}
					}
						
					if(playercount)
					{
						if(iAmmo >= 40)
						{
							new target = playerarray[GetRandomInt(0, playercount-1)];		//Choose a random target
							AttachParticle(index, "ExplosionCore_sapperdestroyed", _, 64.0, 8.0);
							EmitAmbientSound(SND_SHOOT, dPos, index);
							SetEntProp(index, Prop_Send, "m_iAmmoMetal", newiAmmo);			//It costs 40 metal to shoot a rocket
							CreateProjectile(client, target, dPos);							//Fire a rocket at said target
						}
					}
				}
			}
		}
	}
}

CreateProjectile(client, target, Float:origin[3])								// Fires a single projectile
{
	new entity = CreateEntityByName("tf_projectile_rocket");					// because bison particles == blue balls of light on blue team
	if(entity != -1)
	{
		DispatchSpawn(entity);
	
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 4);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);				// store attacker
		SetEntPropEnt(entity, Prop_Send, "m_nForceBone", target);				// store intended target
		SetEntPropVector(entity, Prop_Send, "m_vecMins", Float:{0.0,0.0,0.0});	// the pellet size should be tiny... they will still collide normally
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", Float:{0.0,0.0,0.0});
		
		new Float:vAngles[3];
		vAngles[0] = -90.0;
		vAngles[1] = 0.0;
		vAngles[2] = 0.0;
		
		decl Float:vVelocity[3];
		decl Float:vBuffer[3];
		
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		vVelocity[0] = vBuffer[0]*gf_RocketSpeed;
		vVelocity[1] = vBuffer[1]*gf_RocketSpeed;
		vVelocity[2] = vBuffer[2]*gf_RocketSpeed;
		
		SetEntityModel(entity, MDL_ROCKET);
		SetEntProp(entity, Prop_Send, "m_bCritical", true);
		
		TeleportEntity(entity, origin, vAngles, vVelocity);
		
		SDKHook(entity, SDKHook_StartTouch, ProjectileTouchHook);				// force projectile to deal damage on touch
		CreateTimer(0.15, Timer_Seek, entity);	//Slight delay on making rockets seek a target
	}
}

public Action:Timer_Seek(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_Think, ProjectileThinkHook);					// force projectile to turn to target
	}
}

public Action:ProjectileTouchHook(entity, other)								// Wat happens when this projectile touches something
{
	if(other > 0 && other <= MaxClients)
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(client > 0 && client <= MaxClients && IsClientInGame(client))		// will probably just be -1, but whatever.
		{
			SDKHooks_TakeDamage(other, client, client, gf_RocketDamage, DMG_SHOCK|DMG_ALWAYSGIB);
		}
	}
}

public Action:ProjectileThinkHook(entity)
{
	new target = GetEntProp(entity, Prop_Send, "m_nForceBone");
	if(HomingProjectile_IsValidTarget(target, entity, GetEntProp(entity, Prop_Send, "m_iTeamNum")))
	{
		HomingProjectile_TurnToTarget(target, entity);
	}
	//else
	HomingProjectile_FindTarget(entity);
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)					// Test if projectile can "see" intended target still
{
	if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))						// if they are cloaked
		{
			if(TF2_IsPlayerInCondition(client, TFCond_CloakFlicker)				// check if they are partially visible
				|| TF2_IsPlayerInCondition(client, TFCond_OnFire)
				|| TF2_IsPlayerInCondition(client, TFCond_Jarated)
				|| TF2_IsPlayerInCondition(client, TFCond_Milked)
				|| TF2_IsPlayerInCondition(client, TFCond_Bleeding))
			{
				return true;
			}
			return false;
		}
	
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		{
			return false;
		}
		
		new Float:flStart[3];
		GetClientEyePosition(client, flStart);
		new Float:flEnd[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
		
		new Handle:hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
				return false;
			}
			
			CloseHandle(hTrace);
			return true;
		}
	}
	return false;
}

HomingProjectile_FindTarget(iProjectile)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	new Float:flPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
	
	new HomingProjectileTargetMode:Mode = Target_Closest;
	//new HomingProjectileTargetMode:Mode = Target_Weakest;

	new iBestTarget;
	new Float:flBestLength = 99999.9;
	new iBestHealth = 99999;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (HomingProjectile_IsValidTarget(i, iProjectile, iTeam))
		{
			switch (Mode)
			{
				case Target_Closest:
				{
					new Float:flPos2[3];
					GetClientEyePosition(i, flPos2);
					
					new Float:flDistance = GetVectorDistance(flPos1, flPos2);
					
					if (flDistance < flBestLength)
					{
						iBestTarget = i;
						flBestLength = flDistance;
					}
					break;
				}
				case Target_Weakest:
				{
					new Health = GetClientHealth(i);

					if (Health < iBestHealth)
					{
						iBestTarget = i;
						iBestHealth = Health;
					}
					break;
				}
			}
		}
	}
	
	if (iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
		SetEntPropEnt(iProjectile, Prop_Send, "m_nForceBone", iBestTarget);
	}
}

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)	// we want to hit everything except clients and the missile itself
{
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients))
	{
		return false;
	}
	return true;
}

HomingProjectile_TurnToTarget(client, iProjectile)						// update projectile position
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);
	new Float:flRocketVel[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", flRocketVel);
		
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
		
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
		
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);

	ScaleVector(flNewVec, gf_RocketSpeed);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return entity != data;
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
	if(entity > 0 && entity <=MaxClients)					// only hit the client we're aiming at
	{
		if(entity == data)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flZOffset=0.0, Float:flSelfDestruct=0.0) 
{ 
	if (MapStarted)
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
		 
		if( flSelfDestruct > 0.0 ) 
			CreateTimer( flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle) ); 
		 
		return iParticle; 
	}
	return 0;
} 

public Action:Timer_DeleteParticle(Handle:hTimer, any:iRefEnt) 
{ 
    new iEntity = EntRefToEntIndex(iRefEnt); 
    if(iEntity > MaxClients) 
        AcceptEntityInput(iEntity, "Kill"); 
     
    return Plugin_Handled; 
}

bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target, bossteam)		// Tests to see if vec1 > vec2 can "see" target
{
	TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);

	if(TR_GetEntityIndex() == target)
	{
		if(TF2_GetPlayerClass(target) == TFClass_Spy)							// if they are a spy, do extra tests (coolrocket stuff?)
		{
			if(TF2_IsPlayerInCondition(target, TFCond_Cloaked))					// if they are cloaked
			{
				if(TF2_IsPlayerInCondition(target, TFCond_CloakFlicker)			// check if they are partially visible
					|| TF2_IsPlayerInCondition(target, TFCond_OnFire)
					|| TF2_IsPlayerInCondition(target, TFCond_Jarated)
					|| TF2_IsPlayerInCondition(target, TFCond_Milked)
					|| TF2_IsPlayerInCondition(target, TFCond_Bleeding))
				{
					return true;
				}
				return false;
			}
			/*if(TF2_IsPlayerInCondition(target, TFCond_Disguised) && GetEntProp(target, Prop_Send, "m_nDisguiseTeam") == bossteam)
			{
				return false;
			}*/
			return true;
		}
		if(GetClientTeam(target) == bossteam)
		{
			return false;
		}
		return true;
	}
	return false;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}
