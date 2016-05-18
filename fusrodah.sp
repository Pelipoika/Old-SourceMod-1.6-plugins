#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define SOUND_FUS			"fn/welcome/dragonborn.wav"
#define COLOR_NORMAL		{255,255,255,255}
#define COLOR_INVIS			{255,255,255,0}

public OnPluginStart()
{
	RegAdminCmd("sm_fus", Command_FusroDuh, ADMFLAG_ROOT);
}

public OnMapStart()
	PrecacheSound(SOUND_FUS);

public Action:Command_FusroDuh(client, args)
{
	if(IsValidClient(client))
	{
		new Float:pos[3];
		new Float:ClientEyeAngle[3];
		new Float:Velocity[3];
		new	target = GetClientsInFrontOf(client);
		
		GetClientAbsOrigin(client, pos);
		GetClientEyeAngles(client, ClientEyeAngle);
		
		new Float:EyeAngleZero = ClientEyeAngle[0];
		ClientEyeAngle[0] = -30.0;
		GetAngleVectors(ClientEyeAngle, Velocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(Velocity, 5000.0);
		Velocity[2] = 5000.0;
		ClientEyeAngle[0] = EyeAngleZero;
		
		EmitAmbientSound(SOUND_FUS, pos, client);
		
		if(IsValidClient(target))
		{
			PrintToChatAll("%N got shouted at", target);
			EmitAmbientSound(SOUND_FUS, pos, client);
			
			SetEntityMoveType(target, MOVETYPE_NONE);
			ColorizePlayer(target, COLOR_INVIS);
			
			new iRagDoll = CreateRagdoll(target, 7.5, Velocity);
			if(iRagDoll > MaxClients && IsValidEntity(iRagDoll))
			{
				SetClientViewEntity(target, iRagDoll);
				SetThirdPerson(target, true);
			}
		}
	}
	
	return Plugin_Handled;
}

stock GetClientsInFrontOf(client)
{
	decl Float:flOrigin[3];
	decl Float:flMins[3];
	decl Float:flMaxs[3];
	decl Float:flEAng[3];
	
	GetClientAbsAngles(client, flEAng);
	GetClientAbsOrigin(client, flOrigin);
	flOrigin[2] += 40.0;
	GetEntPropVector(client, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", flMaxs);

	decl Float:vDir[3];
	decl Float:vReturn[3];
	GetAngleVectors(flEAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = flOrigin;
	vReturn[0] += vDir[0] * 164.0;
	vReturn[1] += vDir[1] * 164.0;
	
	new index = -1;
	
	TR_TraceHullFilter(flOrigin, vReturn, flMins, flMaxs, MASK_SOLID, TraceFilterNotSelf, client);
	if(TR_DidHit())
	{
		index = TR_GetEntityIndex();
	}

	return index;
}

public bool:TraceFilterNotSelf(entity, contentsMask, any:client)
{
	if (entity > 0 && entity <= MaxClients)
	{
		if(IsClientConnected(entity) && IsPlayerAlive(entity) && entity != client)
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

stock ColorizePlayer(client, iColor[4])
{
	SetEntityColor(client, iColor);
	
	for(new i=0; i<3; i++)
	{
		new iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntityColor(iWeapon, iColor);
		}
	}
	
	decl String:strClass[20];
	for(new i=MaxClients+1; i<GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, strClass, sizeof(strClass));
			if((strncmp(strClass, "tf_wearable", 11) == 0 || strncmp(strClass, "tf_powerup", 10) == 0) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityColor(i, iColor);
			}
		}
	}

	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		SetEntityColor(iWeapon, iColor);
	}
}

stock SetEntityColor(iEntity, iColor[4])
{
	SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}

CreateRagdoll(client, Float:flSelfDestruct=0.0, Float:Velocity[3])
{
	new iRag = CreateEntityByName("tf_ragdoll");
	if(iRag > MaxClients && IsValidEntity(iRag))
	{
		new Float:flPos[3];
		new Float:flAng[3];

		GetClientAbsOrigin(client, flPos);
		GetClientAbsAngles(client, flAng);
		
		DispatchKeyValueVector(iRag, "origin", flPos);
		DispatchKeyValueVector(iRag, "angles", flAng);
		
		SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
		SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
		SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", iRag);
		
		SetEntityMoveType(iRag, MOVETYPE_FLY);

		DispatchSpawn(iRag);

		SetEntPropVector(iRag, Prop_Send, "m_vecForce", Velocity);
		SetEntPropVector(iRag, Prop_Send, "m_vecRagdollVelocity", Velocity);
	
		if(flSelfDestruct > 0.0) CreateTimer(flSelfDestruct, Timer_DeleteParticle, client);
		
		return iRag;
	}
	
	return 0;
}

//taunt_demo_nuke_shroom1_base
//taunt_demo_nuke_shroom2_collumn
//taunt_demo_nuke_shroom3_ring
//taunt_demo_nuke_shroom4_base
//taunt_demo_nuke_shroom_ring
//taunt_demo_nuke_shroomcloud
//vo/taunts/demo/taunt_demo_nuke_8_explosion.wav

public Action:Timer_DeleteParticle(Handle:hTimer, any:client)
{
	new iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidClient(client) && IsValidEntity(iRagdoll))
	{
		new Float:flPos[3]; 
		GetEntPropVector(iRagdoll, Prop_Data, "m_vecOrigin", flPos); 
		flPos[2] += 5.0;
		TeleportEntity(client, flPos, NULL_VECTOR, NULL_VECTOR);
		SetClientViewEntity(client, client);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		ColorizePlayer(client, COLOR_NORMAL);
		SetThirdPerson(client, false);
		
		AcceptEntityInput(iRagdoll, "Kill");
	}
	
	return Plugin_Handled;
}

SetThirdPerson(client, bool:bEnabled)
{
	if(bEnabled)
	{
		SetVariantInt(1);
	}
	else
	{
		SetVariantInt(0);
	}
	
	AcceptEntityInput(client, "SetForcedTauntCam");
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}