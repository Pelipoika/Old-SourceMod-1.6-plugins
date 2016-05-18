#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SND_HAX		"vo/npc/male01/hacks01.wav"
#define SND_HAX2	"vo/npc/male01/hacks02.wav"

//#define MDL_MONITOR	"models/props_spytech/tv001.mdl"
#define	MDL_MONITOR	"models/props_lab/monitor02.mdl"

public OnPluginStart()
{
	RegAdminCmd("sm_hax", Cmd_Hax, ADMFLAG_ROOT);
}

public OnMapStart()
{
	PrecacheSound(SND_HAX);
	PrecacheSound(SND_HAX2);
	
	PrecacheModel(MDL_MONITOR);
}

public Action:Cmd_Hax(client, args)
{
	if(IsValidClient(client))
	{
		decl Float:pos[3];
		decl Float:ePos[3];
		decl Float:angs[3];
		decl Float:vecs[3];			
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, angs);
		GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
				
		new Handle:trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(ePos, trace);
			if (GetVectorDistance(ePos, pos, false) < 45.0)
			{
				PrintToChat(client, "[SM] You are too close to a wall or something to do that...");
				return Plugin_Handled;
			}
		}
		CloseHandle(trace);			
				
		pos[0] += vecs[0] * 32.0;
		pos[1] += vecs[1] * 32.0;
				
		ScaleVector(vecs, 5000.0);

		new ent = CreateEntityByName("prop_physics_override");

		if(IsValidEntity(ent))
		{				
			DispatchKeyValue(ent, "model", MDL_MONITOR);
	//		DispatchKeyValue(ent, "solid", "6");
	//		DispatchKeyValue(ent, "renderfx", "0");
	//		DispatchKeyValue(ent, "rendercolor", "255 255 255");
	//		DispatchKeyValue(ent, "renderamt", "255");					
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
			SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
			DispatchSpawn(ent);
			
			EmitSoundToAll(SND_HAX, client);
			
			SDKHook(ent, SDKHook_StartTouch, ProjectileTouchHook);
			SDKHook(ent, SDKHook_Touch, ProjectileTouchHook);
			
			TeleportEntity(ent, pos, NULL_VECTOR, vecs);

			CreateTimer(10.0, KillItWithFire, ent);
		}
		else
		{
			PrintToChat(client, "[SM] Could not create a monitor for some odd reason! :(");
		}
	}
	return Plugin_Handled;
}

public Action:ProjectileTouchHook(entity, other)
{
	if(other > 0 && other <= MaxClients)
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			SDKHooks_TakeDamage(other, client, client, GetRandomFloat(50.0, 100.0), DMG_SHOCK|DMG_ALWAYSGIB);
		}
	}
}

public Action:KillItWithFire(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill");
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}
	
stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}