#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new g_iHalo;
new g_iBeamIndex;

public OnPluginStart()
{
	RegAdminCmd("sm_spawn", Command_SpawnProp, ADMFLAG_ROOT, "Spawns something at your crosshair location");
	
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_iBeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public Action:Command_SpawnProp(client, args)
{	
	decl Float:Position[3];
	if(!SetTeleportEndPoint(client, Position))
	{
		PrintToChat(client, "Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities() - 32)
	{
		PrintToChat(client, "Entity limit is reached. Can't spawn anymore entities. Change maps.");
		return Plugin_Handled;
	}
	
	new zombie = CreateEntityByName("bot_npc_archer");
	
	if (IsValidEntity(zombie))
	{
		DispatchSpawn(zombie);
		Position[2] += 10.0;
		
		TE_SetupBeamRingPoint(Position, 64.0, 64.0, g_iBeamIndex, g_iHalo, 2, 3, 0.5, 32.0, 0.5, {255, 0, 0, 255}, 10, 2);
		TE_SendToAll();
		
		AcceptEntityInput(zombie, "Enable");
		
		SetEntPropFloat(zombie, Prop_Send, "m_flModelScale", 1.5);
		SetEntProp(zombie, Prop_Data, "m_target", client);
		
		TeleportEntity(zombie, Position, NULL_VECTOR, NULL_VECTOR);
		PrintToChat(client, "spawed the entity at (%f, %f, %f).", Position[0], Position[1], Position[2]);
	}
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname,"bot_npc_decoy"))
	{
		PrintToChatAll("bot_npc_decoy");
	}
	else if (StrEqual(classname, "bot_npc_archer"))
	{
		PrintToChatAll("bot_npc_archer");
	}
}

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