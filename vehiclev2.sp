#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sendproxy>
#pragma semicolon 1

#define VEHICLE_TYPE_CAR_WHEELS			(1 << 0) //1
#define VEHICLE_TYPE_CAR_RAYCAST		(1 << 1) //2
#define VEHICLE_TYPE_JETSKI_RAYCAST		(1 << 2) //4
#define VEHICLE_TYPE_AIRBOAT_RAYCAST	(1 << 3) //8

new bool:CanThirdperson[MAXPLAYERS+1];
new g_vViewControll[2048+1] = {INVALID_ENT_REFERENCE, ... };

public OnPluginStart()
{
	RegAdminCmd("vh_buggy", CMD_VehicleBuggy, ADMFLAG_ROOT);
	RegConsoleCmd("carview", CMD_ViewCar);

	AddCommandListener(MEEM, "voicemenu");
	
	HookEntityOutput("prop_vehicle_driveable", "PlayerOn", PlayerOn);
	HookEntityOutput("prop_vehicle_driveable", "PlayerOff", PlayerOff);
	
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Death, EventHookMode_Pre);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnPluginEnd()
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "prop_vehicle_driveable")) != -1)
	{
		if(GetEntPropEnt(ent, Prop_Send, "m_hPlayer") != -1)
		{
			CalcExit(GetEntPropEnt(ent, Prop_Send, "m_hPlayer"), ent);
		}
		AcceptEntityInput(ent, "kill");
	}	
}

public Action:CMD_ViewCar(client, args)
{
	new Vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if(Vehicle != -1)
	{
		SetClientViewEntity(client, g_vViewControll[Vehicle]);
	}
	else
	{
		PrintToChat(client, "Invalid vehicle");
		
	/*	new i = -1;
		while ((i = FindEntityByClassname(i, "point_viewcontrol")) != -1)
		{
			if (IsValidEntity(i))
			{
				SetClientViewEntity(client, i);
				break;
			}
		}*/
	}
		
	return Plugin_Handled;
}

public PlayerOn(const String:output[], caller, activator, Float:delay)
{
	PrintToChatAll("%N Entered car", activator);
	
	if(IsValidEntity(g_vViewControll[caller]))
		SetClientViewEntity(activator, g_vViewControll[caller]);
	else
		PrintToChat(activator, "Failed to set camera");
	CreateTimer(0.1, Timer_PlayerOn, activator);
}

public PlayerOff(const String:output[], caller, activator, Float:delay)
{
	PrintToChatAll("%N Exit car", activator);
	SetClientViewEntity(activator, activator);
}
 
public Action:Timer_PlayerOn(Handle:timer, any:activator)
{
	new EntEffects = GetEntProp(activator, Prop_Send, "m_fEffects");
	EntEffects &= ~32;
	SetEntProp(activator, Prop_Send, "m_fEffects", EntEffects);
	new hud = GetEntProp(activator, Prop_Send, "m_iHideHUD");
	hud &= ~1;
	hud &= ~256;
	hud &= ~1024;
	SetEntProp(activator, Prop_Send, "m_iHideHUD", hud);
	SetEntProp(activator, Prop_Send, "m_bDucked", 1);
	SetEntProp(activator, Prop_Send, "m_bDucking", 1);
	SetEntityFlags(activator, GetEntityFlags(activator)|FL_DUCKING);
	if(GetPlayerWeaponSlot(activator, 2) != -1)
	{
		SetEntPropEnt(activator, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(activator, 2));
	}
	new String:model[PLATFORM_MAX_PATH];
	GetClientModel(activator, model, sizeof(model));
	SetVariantString(model);
	AcceptEntityInput(activator, "SetCustomModel", activator, activator);
	SetVariantInt(1);
	AcceptEntityInput(activator, "SetCustomModelRotates", activator, activator);
	SetEntProp(activator, Prop_Send, "m_bUseClassAnimations", 1);
	CreateTimer(0.1, Timer_DisableAnim, activator);
	SetEntProp(activator, Prop_Send, "m_bDrawViewmodel", 0);
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > MaxClients || client <= 0) return;
	if (GetEventInt(event, "death_flags") & 32) return;
	new ViewEnt = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
	
	if (ViewEnt > MaxClients)
	{
		new String:cls[25];
		GetEntityClassname(ViewEnt, cls, sizeof(cls));
		if (StrEqual(cls, "point_viewcontrol", false)) SetClientViewEntity(client, client);
	}
}

public Action:Timer_DisableAnim(Handle:timer, any:activator)
{
	SetEntProp(activator, Prop_Send, "m_bUseClassAnimations", 0);
}

public OnClientPutInServer(client)
{
	CanThirdperson[client] = true;
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

public OnConfigsExecuted()
{
	SetConVarInt(FindConVar("tf_allow_player_use"), 1, true);
}

public SpawnVehicle(client, const String:model[], const String:script[], vehicletype)
{
	new Vehicle = CreateEntityByName("prop_vehicle_driveable");
	if(Vehicle != -1)
	{
		new String:Name[10];
		new Float:pos[3], ang[3];
		GetClientEyeAngles(client, Float:ang);
		GetClientAbsOrigin(client, Float:pos); 
		IntToString(Vehicle, Name, 10);
		DispatchKeyValue(Vehicle, "targetname", Name);
		DispatchKeyValue(Vehicle, "model", model);
		DispatchKeyValue(Vehicle, "vehiclescript", script);
		DispatchKeyValue(Vehicle, "solid", "6");
		DispatchKeyValue(Vehicle, "skin", "0");
		DispatchKeyValue(Vehicle, "spawnflags", "1");
		DispatchKeyValue(Vehicle, "VehicleLocked", "0");
		DispatchKeyValue(Vehicle, "actionScale", "1");
		DispatchKeyValue(Vehicle, "EnableGun", "0");
		DispatchKeyValue(Vehicle, "ignorenormals", "0");
		DispatchKeyValue(Vehicle, "fadescale", "1");
		DispatchKeyValue(Vehicle, "fademindist", "-1");
		DispatchKeyValue(Vehicle, "screenspacefade", "0");
		DispatchKeyValueVector(Vehicle, "origin", Float:pos); 
		DispatchKeyValueVector(Vehicle, "angles", Float:ang); 
		DispatchSpawn(Vehicle);
		ActivateEntity(Vehicle);
		SetEntProp(Vehicle, Prop_Send, "m_iTeamNum", GetEntProp(client, Prop_Send, "m_iTeamNum"));	
		SetEntProp(Vehicle, Prop_Send, "m_bEnterAnimOn", 0);
		SetEntProp(Vehicle, Prop_Send, "m_bExitAnimOn", 0);
		SetEntProp(Vehicle, Prop_Data, "m_nVehicleType", vehicletype);
		SetVariantFloat(0.0);
		AcceptEntityInput(Vehicle, "Throttle", client, client);
		SetVariantFloat(0.0);
		AcceptEntityInput(Vehicle, "Steer", client, client);
		AcceptEntityInput(Vehicle, "TurnOn");
		AcceptEntityInput(Vehicle, "HandBrakeOff");
		SetEntityMoveType(Vehicle, MOVETYPE_VPHYSICS);
		SendProxy_Hook(Vehicle, "m_bEnterAnimOn", Prop_Int, DisableAnim);
		SendProxy_Hook(Vehicle, "m_bExitAnimOn", Prop_Int, DisableAnim);
		
		CreateCamera(Vehicle, Name, Float:ang);
	}
}

stock CreateCamera(entity, const String:entityname[], Float:ang[3])
{
	new entCamera = CreateEntityByName("point_viewcontrol"); 
	if(IsValidEntity(entCamera)) 
	{ 
		DispatchKeyValue(entCamera, "targetname", "viewcontrol"); 
//		DispatchKeyValue(entCamera, "spawnflags", "10");	//Follow player & Infinite Hold Time
		SetVariantString("!activator");
		AcceptEntityInput(entCamera, "SetParent", entity);
		
		DispatchKeyValueVector(entCamera, "angles", Float:ang); 
		
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(entCamera, "SetParentAttachment", entity);
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(entCamera, "SetParentAttachmentMaintainOffset"); 
		
		DispatchSpawn(entCamera);
		ActivateEntity(entCamera);
		g_vViewControll[entity] = EntIndexToEntRef(entCamera);
		
		PrintToChatAll("Created camera for car %i", entity);
	}
}

public Action:DisableAnim(entity, const String:PropName[], &iValue, element)
{
	iValue = 0;
	return Plugin_Changed;
}

public Action:OnClientTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(damagetype & DMG_VEHICLE)
	{
		new String:classname[30];
		GetEntityClassname(inflictor, classname, sizeof(classname));
		if(StrEqual("prop_vehicle_driveable", classname, false))
		{
			new Driver = GetEntPropEnt(inflictor, Prop_Send, "m_hPlayer");
			if(Driver != -1)
			{
				damage *= 2.0;
				if(victim != Driver)
				{
					new DriverTeam = GetEntProp(Driver, Prop_Send, "m_iTeamNum");
					new VictimTeam = GetEntProp(victim, Prop_Send, "m_iTeamNum");
					if(VictimTeam == DriverTeam)
					{
						return Plugin_Handled;
					}
					attacker = Driver;
					return Plugin_Changed;
				}
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:CMD_VehicleBuggy(client, args)
{
	SpawnVehicle(client, "models/buggy.mdl", "scripts/vehicles/buggy.txt", VEHICLE_TYPE_CAR_WHEELS);
	return Plugin_Handled;
}

public Action:MEEM(client, const String:command[], argc)
{
	if (client < 1 || client > MaxClients)
	{
		return Plugin_Continue;
	}
	
	new String:args[5];
	GetCmdArgString(args, sizeof(args));
	if (StrEqual(args, "0 0"))
	{
		new Vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if(Vehicle != -1 && IsPlayerAlive(client))
		{
			CalcExit(client, Vehicle);
		}
	}

	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vec[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new Vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if(Vehicle != -1)
	{
		new Float:ang[3];
		GetEntPropVector(Vehicle, Prop_Data, "m_angRotation", ang);
		ang[0] = 0.0;
		ang[1] += 90.0;
		ang[2] = 0.0;
		SetVariantVector3D(ang);
		AcceptEntityInput(client, "SetCustomModelRotation", client, client);
		if(buttons & IN_FORWARD)
		{
			SetVariantFloat(1.0);
			AcceptEntityInput(Vehicle, "Throttle", client, client);
		}
		if(buttons & IN_BACK)
		{
			SetVariantFloat(-1.0);
			AcceptEntityInput(Vehicle, "Throttle", client, client);
		}
		if(!(buttons & IN_FORWARD) && !(buttons & IN_BACK))
		{
			SetVariantFloat(0.0);
			AcceptEntityInput(Vehicle, "Throttle", client, client);
		}
		if(buttons & IN_MOVELEFT && !(buttons & IN_MOVERIGHT))
		{
			SetVariantFloat(-1.0);
			AcceptEntityInput(Vehicle, "Steer", client, client);
		}
		if(buttons & IN_MOVERIGHT && !(buttons & IN_MOVELEFT))
		{
			SetVariantFloat(1.0);
			AcceptEntityInput(Vehicle, "Steer", client, client);
		}
		if(!(buttons & IN_MOVELEFT) && !(buttons & IN_MOVERIGHT))
		{
			SetVariantFloat(0.0);
			AcceptEntityInput(Vehicle, "Steer", client, client);
		}
		if(buttons & IN_DUCK)
		{
			if(CanThirdperson[client] == true)
			{
				switch(GetEntProp(client, Prop_Send, "m_nForceTauntCam"))
				{
					case 1: SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
					case 0: SetEntProp(client, Prop_Send, "m_nForceTauntCam", 1);
				}
				CanThirdperson[client] = false;
				CreateTimer(1.0, Timer_ResetThirdperson, client);
			}
		}
	}
}

public CalcExit(client, vehicle)
{
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
					if(TR_DidHit())
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
							PrintToChat(client, "\x04No safe exit point found\x05");
							return;
						}
					}
					else
					{
						PrintToChat(client, "\x04No safe exit point found\x05");
						return;
					}
				}
			}
		}
	}
	SetVariantFloat(0.0);
	AcceptEntityInput(vehicle, "Throttle", client, client);
	SetVariantFloat(0.0);
	AcceptEntityInput(vehicle, "Steer", client, client);
	SetEntPropEnt(client, Prop_Send, "m_hVehicle", -1);
	SetEntPropEnt(vehicle, Prop_Send, "m_hPlayer", -1);
	SetEntityMoveType(client, MOVETYPE_WALK);
	AcceptEntityInput(client, "ClearParent", client, client);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	new EntEffects = GetEntProp(client, Prop_Send, "m_fEffects");
	EntEffects &= ~32;
	SetEntProp(client, Prop_Send, "m_fEffects", EntEffects);
	new hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	hud &= ~1;
	hud &= ~256;
	hud &= ~1024;
	SetEntProp(client, Prop_Send, "m_iHideHUD", hud);
	new Float:ExitAng[3];
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", ExitAng);
	ExitAng[0] = 0.0;
	ExitAng[1] += 90.0;
	ExitAng[2] = 0.0;
	TeleportEntity(client, ExitPoint, ExitAng, NULL_VECTOR);
	SetEntProp(client, Prop_Send, "m_bDucked", 0);
	SetEntProp(client, Prop_Send, "m_bDucking", 0);
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_DUCKING);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetEntPropEnt(client, Prop_Send, "m_hLastWeapon"));
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel", client, client);
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	SetVariantVector3D(Float:{0.0, 0.0, 0.0});
	AcceptEntityInput(client, "SetCustomModelRotation", client, client);
	SetClientViewEntity(client, client);
	if(GetEntProp(client, Prop_Send, "m_nForceTauntCam") == 1)
	{
		SetEntProp(client, Prop_Send, "m_nForceTauntCam", 0);
	}
}

public bool:DontHitClientOrVehicle(entity, contentsMask, any:data)
{
	new Vehicle = GetEntPropEnt(data, Prop_Send, "m_hVehicle");
	return((entity != data) && (entity != Vehicle));
}

public bool:IsExitClear(client, vehicle, Float:direction, Float:exitpoint[3])
{
	new Float:ClientEye[3];
	new Float:VehicleAngle[3];
	GetClientEyePosition(client, ClientEye);
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", VehicleAngle);
	new Float:ClientMinHull[3];
	new Float:ClientMaxHull[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", ClientMinHull);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", ClientMaxHull);
	VehicleAngle[0] = 0.0;
	VehicleAngle[2] = 0.0;
	VehicleAngle[1] += direction;
	new Float:DirectionVec[3];
	GetAngleVectors(VehicleAngle, NULL_VECTOR, DirectionVec, NULL_VECTOR);
	ScaleVector(DirectionVec, -500.0);
	new Float:TraceEnd[3];
	AddVectors(ClientEye, DirectionVec, TraceEnd);
	TR_TraceHullFilter(ClientEye, TraceEnd, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
	new Float:CollisionPoint[3];
	if(TR_DidHit())
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

public Action:Timer_ResetThirdperson(Handle:timer, any:client)
{
	CanThirdperson[client] = true;
}