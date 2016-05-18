#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define VEHICLE_TYPE_CAR_WHEELS			(1 << 0) //1

public OnPluginStart()
{
	RegAdminCmd("create", CMD_VehicleCreate, ADMFLAG_ROOT);
	RegAdminCmd("killcars", CMD_VehicleKill, ADMFLAG_ROOT);
	RegConsoleCmd("sm_exit", CMD_exit);
}

public Action:CMD_VehicleCreate(client, args)
{
	new Vehicle = CreateEntityByName("prop_vehicle_driveable");
	if(Vehicle != -1)
	{
		new String:Name[10];
		new Float:pos[3];
		IntToString(Vehicle, Name, 10);
		DispatchKeyValue(Vehicle, "targetname", Name);
		DispatchKeyValue(Vehicle, "model", "models/buggy.mdl");
		DispatchKeyValue(Vehicle, "vehiclescript", "scripts/vehicles/jeep_test.txt");
		DispatchKeyValue(Vehicle, "solid", "6");
		DispatchKeyValue(Vehicle, "skin", "0");
		DispatchKeyValue(Vehicle, "spawnflags", "1");
		DispatchKeyValue(Vehicle, "VehicleLocked", "0");
		DispatchSpawn(Vehicle);
		ActivateEntity(Vehicle);
		AcceptEntityInput(Vehicle, "HandBrakeOff");
		SetEntProp(Vehicle, Prop_Send, "m_bEnterAnimOn", 0);
		SetEntProp(Vehicle, Prop_Send, "m_bExitAnimOn", 0);
		SetEntProp(Vehicle, Prop_Data, "m_bHasGun", 0);
		SetEntProp(Vehicle, Prop_Send, "m_iTeamNum", GetEntProp(client, Prop_Send, "m_iTeamNum"));
		GetClientAbsOrigin(client, pos);
		TeleportEntity(Vehicle, pos, NULL_VECTOR, NULL_VECTOR);
		SDKHook(Vehicle, SDKHook_Think, OnThink);
	}
	
	return Plugin_Handled;
}

public OnThink(entity)
{
	SetEntProp(entity, Prop_Send, "m_bEnterAnimOn", 0);
	SetEntProp(entity, Prop_Send, "m_bExitAnimOn", 0);
}

//vehicle_driver_eyes

public Action:CMD_VehicleKill(client, args)
{
	new car = -1;
	while ((car = FindEntityByClassname(car, "prop_vehicle_driveable")) != -1)
	{
		if (IsValidEntity(car))
		{
			PrintToChat(client, "Killed a car");
			SDKUnhook(car, SDKHook_Think, OnThink);
			AcceptEntityInput(car, "Kill");
		}
	}
	
	return Plugin_Handled;
}

public Action:CMD_exit(client, args)
{
	new Vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if(Vehicle != -1)
	{
		CalcExit(client, Vehicle);
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vec[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new Vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if(Vehicle != -1)
	{
		if(buttons & IN_FORWARD)
		{
			PrintToServer("IN_FORWARD");
			SetEntProp(Vehicle, Prop_Send, "m_nSpeed", 1);
			SetEntProp(Vehicle, Prop_Send, "m_nRPM", 1);
			SetEntPropFloat(Vehicle, Prop_Send, "m_flThrottle", 1.0);
			SetVariantFloat(1.0);
			AcceptEntityInput(Vehicle, "Throttle", client, client);
		}
		
		if(buttons & IN_BACK)
		{
			PrintToServer("IN_BACK");
			SetEntProp(Vehicle, Prop_Send, "m_nSpeed", -1);
			SetEntProp(Vehicle, Prop_Send, "m_nRPM", -1);
			SetEntPropFloat(Vehicle, Prop_Send, "m_flThrottle", -1.0);
			SetVariantFloat(-1.0);
			AcceptEntityInput(Vehicle, "Throttle", client, client);
		}
		
		if(!(buttons & IN_FORWARD) && !(buttons & IN_BACK))
		{
			SetEntProp(Vehicle, Prop_Send, "m_nSpeed", 0);
			SetEntProp(Vehicle, Prop_Send, "m_nRPM", 0);
			SetEntPropFloat(Vehicle, Prop_Send, "m_flThrottle", 0.0);
			SetVariantFloat(0.0);
			AcceptEntityInput(Vehicle, "Throttle", client, client);
		}
		
		if(buttons & IN_MOVELEFT && !(buttons & IN_MOVERIGHT))
		{
			PrintToServer("IN_MOVELEFT");
			SetVariantFloat(-1.0);
			AcceptEntityInput(Vehicle, "Steer", client, client);
		}
		
		if(buttons & IN_MOVERIGHT && !(buttons & IN_MOVELEFT))
		{
			PrintToServer("IN_MOVERIGHT");
			SetVariantFloat(1.0);
			AcceptEntityInput(Vehicle, "Steer", client, client);
		}
		
		if(!(buttons & IN_MOVELEFT) && !(buttons & IN_MOVERIGHT))
		{
			SetVariantFloat(0.0);
			AcceptEntityInput(Vehicle, "Steer", client, client);
		}
	}
}

public bool:TraceASDF(entity, mask, any:data)
{
	return data != entity;
}

public TraceToEntity(client)
{
	new Float:vecClientEyePos[3];
	new Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);    
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceASDF, client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		return(TR_GetEntityIndex(INVALID_HANDLE));
	}
	return -1;
}

public CalcExit(client, vehicle)
{
	new Float:ExitAng[3];
	new Float:ExitPoint[3];
	if(!IsExitClear(client, vehicle, 90.0, ExitPoint))
	{
		if(!IsExitClear(client, vehicle, -90.0, ExitPoint))
		{
			if(!IsExitClear(client, vehicle, 0.0, ExitPoint))
			{
				if(!IsExitClear(client, vehicle, 180.0, ExitPoint))
				{
					new Float:ClientEye[3];
					GetClientEyePosition(client, ClientEye);
					new Float:ClientMinHull[3];
					new Float:ClientMaxHull[3];
					GetEntPropVector(client, Prop_Send, "m_vecMins", ClientMinHull);
					GetEntPropVector(client, Prop_Send, "m_vecMaxs", ClientMaxHull);
					new Float:TraceEnd[3];
					TraceEnd = ClientEye;
					TraceEnd[2] += 500.0;
					TR_TraceHullFilter(ClientEye, TraceEnd, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
					new Float:CollisionPoint[3];
					if (TR_DidHit())
					{
						TR_GetEndPosition(CollisionPoint);
					}
					else
					{
						CollisionPoint = TraceEnd;
					}
					TR_TraceHull(CollisionPoint, ClientEye, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID);
					new Float:VehicleEdge[3];
					TR_GetEndPosition(VehicleEdge);
					new Float:ClearDistance = GetVectorDistance(VehicleEdge, CollisionPoint);
					if(ClearDistance >= 100.0)
					{
						ExitPoint = VehicleEdge;
						ExitPoint[2] += 100.0;
						if(TR_PointOutsideWorld(ExitPoint))
						{
							return;
						}
					}
					else
					{
						return;
					}
				}
			}
		}
	}
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", ExitAng);
	GetClientAbsOrigin(client, ExitPoint);
	ExitAng[0] = 0.0;
	ExitAng[1] += 90.0;
	ExitAng[2] = 0.0;
	SetEntPropEnt(client, Prop_Send, "m_hVehicle", -1);
	SetEntPropEnt(vehicle, Prop_Send, "m_hPlayer", -1);
	TeleportEntity(client, ExitPoint, ExitAng, NULL_VECTOR);
	SetEntityMoveType(client, MOVETYPE_WALK);
	AcceptEntityInput(client, "ClearParent");
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
}

public bool:DontHitClientOrVehicle(entity, contentsMask, any:data)
{
	new Vehicle = GetEntPropEnt(data, Prop_Send, "m_hVehicle");
	return ((entity != data) && (entity != Vehicle));
}

public bool:IsExitClear(client, vehicle, Float:direction, Float:exitpoint[3])
{
	new Float:ClientEye[3];
	new Float:VehicleAngle[3];
	new Float:ClientMinHull[3];
	new Float:ClientMaxHull[3];
	new Float:DirectionVec[3];
	new Float:TraceEnd[3];
	new Float:CollisionPoint[3];
	new Float:VehicleEdge[3];
	new Float:ClearDistance = GetVectorDistance(VehicleEdge, CollisionPoint);
	GetClientEyePosition(client, ClientEye);
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", VehicleAngle);
	GetEntPropVector(client, Prop_Send, "m_vecMins", ClientMinHull);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", ClientMaxHull);
	VehicleAngle[0] = 0.0;
	VehicleAngle[2] = 0.0;
	VehicleAngle[1] += direction;
	GetAngleVectors(VehicleAngle, NULL_VECTOR, DirectionVec, NULL_VECTOR);
	ScaleVector(DirectionVec, -500.0);
	AddVectors(ClientEye, DirectionVec, TraceEnd);
	TR_TraceHullFilter(ClientEye, TraceEnd, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
	if(TR_DidHit())
	{
		TR_GetEndPosition(CollisionPoint);
	}
	else
	{
		CollisionPoint = TraceEnd;
	}
	TR_TraceHull(CollisionPoint, ClientEye, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID);
	TR_GetEndPosition(VehicleEdge);
	if(ClearDistance >= 100.0)
	{
		MakeVectorFromPoints(VehicleEdge, CollisionPoint, DirectionVec);
		NormalizeVector(DirectionVec, DirectionVec);
		ScaleVector(DirectionVec, 100.0);
		AddVectors(VehicleEdge, DirectionVec, exitpoint);
		if(TR_PointOutsideWorld(exitpoint))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
	else
	{
		return false;
	}
}