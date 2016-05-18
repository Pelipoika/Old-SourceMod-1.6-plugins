#pragma semicolon 1                  // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools> 
#include <tf2>
#include <tf2_stocks>
#include <colors>
#include <sdkhooks>

#define MAX_ROCKETS             100
#define MAX_ROCKET_CLASSES      50
#define MAX_SPAWNER_CLASSES     50
#define MAX_SPAWN_POINTS        100

#define FPS_LOGIC_RATE          20.0
#define FPS_LOGIC_INTERVAL      1.0 / FPS_LOGIC_RATE

new	bool:g_bRocketIsValid[MAX_ROCKETS];
new	g_iRocketEntity[MAX_ROCKETS];
new	g_iRocketTarget[MAX_ROCKETS];
new	g_iRocketDeflections[MAX_ROCKETS];
new g_iRocketsFired;
new g_iLastCreatedRocket;
new	Float:g_fRocketLastDeflectionTime[MAX_ROCKETS];
new	Float:g_fRocketSpeed[MAX_ROCKETS];
new	Float:g_fRocketDirection[MAX_ROCKETS][3];
new Float:flCheckDelay = 3.0;

new Handle:g_hLogicTimer;           // Logic timer

#define POSITION_RSPAWN	{5337.0, -156.0, -8067.0}

public OnPluginStart()
{
	RegAdminCmd("sm_rockets", Command_StartRockets, ADMFLAG_ROOT);
	RegAdminCmd("sm_rocketsoff", Command_OffRockets, ADMFLAG_ROOT);
}

public Action:Command_StartRockets(client, args)
{   
	g_hLogicTimer = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
	g_iRocketsFired	= 0;
}

public Action:Command_OffRockets(client, args)
{   
	if (g_hLogicTimer != INVALID_HANDLE)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;
	}
	
	g_iRocketsFired	= 0;
}

public Action:OnDodgeBallGameFrame(Handle:hTimer, any:Data)
{
	CreateRocket();

	// Manage the active rockets
	new iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
		HomingRocketThink(iIndex);
	}
}

public CreateRocket()
{    
	static Float:flLastSpawn;
	if(GetEngineTime() - flCheckDelay <= flLastSpawn)	//Lets not spam the server with rockets now shall we
		return;
	
	new iIndex = FindFreeRocketSlot();
	if (iIndex != -1)
    {
		// Create rocket entity.
		new iEntity = CreateEntityByName("tf_projectile_rocket");
		if (iEntity && IsValidEntity(iEntity))
		{
			// Fetch spawn point's location and angles.
			new Float:fAngles[3], Float:fDirection[3];
		//	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
			GetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
			GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			
			new iTargetTeam;
			switch(GetRandomInt(1,2))
			{
				case 1: iTargetTeam = 2;
				case 2: iTargetTeam = 3;
			}
			
			// Setup rocket entity.
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
			SetEntProp(iEntity,    Prop_Send, "m_bCritical",  	0);
			SetEntProp(iEntity,    Prop_Send, "m_iTeamNum",     iTargetTeam);
			SetEntProp(iEntity,    Prop_Send, "m_iDeflected",   1);
			new Float:pos[3] = POSITION_RSPAWN;
			TeleportEntity(iEntity, pos, Float:{0.0, 0.0, -180.0}, Float:{0.0, 0.0, 0.0});
			
			// Setup rocket structure with the newly created entity.
			new iTarget         = SelectTarget(iTargetTeam);
			g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
			
			if(g_iRocketTarget[iIndex] != INVALID_ENT_REFERENCE)
			{
				new Float:fModifier = CalculateModifier(iTargetTeam);
				g_bRocketIsValid[iIndex]           	= true;
				g_iRocketEntity[iIndex]             = EntIndexToEntRef(iEntity);
				g_iRocketDeflections[iIndex]       	= 0;
				g_fRocketLastDeflectionTime[iIndex]	= GetGameTime();
				g_fRocketSpeed[iIndex]             	= CalculateRocketSpeed(fModifier);
				
				CopyVectors(fDirection, g_fRocketDirection[iIndex]);
				SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(fModifier), true);
				DispatchSpawn(iEntity);
				SDKHook(iEntity, SDKHook_StartTouch, Event_StartTouch);
				UpdateRocketSkin(iEntity, iTargetTeam);
				// Done
				//g_iRocketsFired++;
				
				flLastSpawn = GetEngineTime();
			}
		}
	}
}

public Event_StartTouch(entity, other)
{
	SDKUnhook(entity, SDKHook_StartTouch, Event_StartTouch);

	AcceptEntityInput(entity, "Explode", -1, -1, 0);
}

HomingRocketThink(iIndex)
{
	// Retrieve the rocket's attributes.
	new iEntity            = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	new iTarget            = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	new iTargetTeam        = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
	new iDeflectionCount   = GetEntProp(iEntity, Prop_Send, "m_iDeflected") - 1;
	new Float:fModifier    = CalculateModifier(iDeflectionCount);

	// Check if the target is available
	if (!IsValidClient(iTarget, true))
	{
		iTarget = SelectTarget(iTargetTeam);
		if (!IsValidClient(iTarget, true)) return;
		g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
	}
	// Has the rocket been deflected recently? If so, set new target.
	else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
	{
		// Calculate new direction from the player's forward
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(iClient))
		{
			new Float:fViewAngles[3], Float:fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			UpdateRocketSkin(iEntity, iTargetTeam);
		}
		
		// Set new target & deflection count
		iTarget = SelectTarget(iTargetTeam, iIndex);
		g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
		g_iRocketDeflections[iIndex]        = iDeflectionCount;
		g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
		g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(fModifier);
		SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(fModifier), true);
	}
	else
	{
		// If the delay time since the last reflection has been elapsed, rotate towards the client.
		if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= 0.01)
		{
			// Calculate turn rate and retrieve directions.
			new Float:fTurnRate = CalculateRocketTurnRate(fModifier);
			decl Float:fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);

			// Smoothly change the orientation to the new one.
			LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
		}
	}

	// Done
	ApplyRocketParameters(iIndex);
}

stock SelectTarget(iTeam, iRocket = -1)
{
	new iTarget = -1;
	decl Float:fRocketPosition[3];
	decl Float:fRocketDirection[3];
	new bool:bUseRocket;

	if (iRocket != -1)
	{
		new iEntity = EntRefToEntIndex(g_iRocketEntity[iRocket]);
		
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
		CopyVectors(g_fRocketDirection[iRocket], fRocketDirection);

		bUseRocket = true;
	}

	if (bUseRocket == true)
	{
		new iEntity = EntRefToEntIndex(g_iRocketEntity[iRocket]);
		new Float:pos[3] = POSITION_RSPAWN;
		decl Float:playerpos[3];

		for(new player = 1; player <= MaxClients; player++)
		{
			if(IsClientInGame(player) && IsPlayerAlive(player))
			{
				if(HomingProjectile_IsValidTarget(player, iEntity, iTeam))
				{
					GetClientEyePosition(player, playerpos);
					playerpos[2] -= 30.0;
					if(CanSeeTarget(pos, playerpos, player, iTeam))
					{
						iTarget = player;
					//	PrintToChatAll("Target aquired [Rocket]: %N", player);
						break;
					}
				}
			}
		}
	}
	else
	{
		new Float:pos[3] = POSITION_RSPAWN;
		decl Float:playerpos[3];

		for(new player = 1; player <= MaxClients; player++)
		{
			if(IsClientInGame(player) && IsPlayerAlive(player))
			{
				GetClientEyePosition(player, playerpos);
				playerpos[2] -= 30.0;
				if(CanSeeTarget(pos, playerpos, player, iTeam))
				{
					iTarget = player;
			//		PrintToChatAll("Target aquired [NoRocket]: %N", player);
					break;
				}
			}
		}
	}
		
	return iTarget;
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return false;
		
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
			return false;
		
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

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)
{
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients))
		return false;
	
	return true;
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
			return true;
		else
			return false;
	}
	return true;
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

Float:CalculateRocketSpeed(Float:fModifier)
{
    return 700.0 + 150.0 * fModifier;
}

Float:CalculateRocketDamage(Float:fModifier)
{
    return 50.0 + 25.0;// * fModifier;
}

Float:CalculateModifier(iDeflections)
{
    return  iDeflections + (g_iRocketsFired * 0.1);
}

Float:CalculateRocketTurnRate(Float:fModifier)
{
    return 0.170 + 0.0175 * fModifier;
}

stock Float:GetURandomFloatRange(Float:fMin, Float:fMax)
{
    return fMin + (GetURandomFloat() * (fMax - fMin));
}

stock LerpVectors(Float:fA[3], Float:fB[3], Float:fC[3], Float:t)
{
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    
    fC[0] = fA[0] + (fB[0] - fA[0]) * t;
    fC[1] = fA[1] + (fB[1] - fA[1]) * t;
    fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

stock CopyVectors(Float:fFrom[3], Float:fTo[3])
{
    fTo[0] = fFrom[0];
    fTo[1] = fFrom[1];
    fTo[2] = fFrom[2];
}

UpdateRocketSkin(iEntity, iTeam)
{
    SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam == _:TFTeam_Blue)? 0 : 1);
}

FindFreeRocketSlot()
{
    new iIndex = g_iLastCreatedRocket;
    new iCurrent = iIndex;
    
    do
    {
        if (!IsValidRocket(iCurrent)) return iCurrent;
        if ((++iCurrent) == MAX_ROCKETS) iCurrent = 0;
    } while (iCurrent != iIndex);
    
    return -1;
}

stock bool:IsValidClient(iClient, bool:bAlive = false)
{
    if (iClient >= 1 &&
    iClient <= MaxClients &&
    IsClientConnected(iClient) &&
    IsClientInGame(iClient) &&
    (bAlive == false || IsPlayerAlive(iClient)))
    {
        return true;
    }
    
    return false;
}

bool:IsValidRocket(iIndex)
{
    if ((iIndex >= 0) && (g_bRocketIsValid[iIndex] == true))
    {
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == -1)
        {
            g_bRocketIsValid[iIndex] = false;
            return false;
        }
        return true;
    }
    return false;
}

FindNextValidRocket(iIndex, bool:bWrap = false)
{
    for (new iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
        if (IsValidRocket(iCurrent))
            return iCurrent;
        
    return (bWrap == true)? FindNextValidRocket(-1, false) : -1;
}

CalculateDirectionToClient(iEntity, iClient, Float:fOut[3])
{
    decl Float:fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
    GetClientEyePosition(iClient, fOut);
    MakeVectorFromPoints(fRocketPosition, fOut, fOut);
    NormalizeVector(fOut, fOut);
}

ApplyRocketParameters(iIndex)
{
    new iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    decl Float:fAngles[3]; GetVectorAngles(g_fRocketDirection[iIndex], fAngles);
    decl Float:fVelocity[3]; CopyVectors(g_fRocketDirection[iIndex], fVelocity);
    ScaleVector(fVelocity, g_fRocketSpeed[iIndex]);
    SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
    SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}