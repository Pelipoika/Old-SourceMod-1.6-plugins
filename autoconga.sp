#include <sourcemod>
#include <tf2items>
#include <sdktools>
#include <sdkhooks>
#include <navmesh>

new g_iPathLaserModelIndex = -1;

new Handle:hPositions[MAXPLAYERS+1];
new Handle:hPlayTaunt;

new bool:ForceWalk[MAXPLAYERS+1];
new Float:flTargetPos[MAXPLAYERS+1][3];

//Add looking ahead

public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("tf2.tauntem");
	
	if (conf == INVALID_HANDLE)
	{
		SetFailState("Unable to load gamedata/tf2.tauntem.txt. Good luck figuring that out.");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	
	hPlayTaunt = EndPrepSDKCall();
	
	if (hPlayTaunt == INVALID_HANDLE)
	{
		SetFailState("Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Wait patiently for a fix.");
		CloseHandle(conf);
		return;
	}
	
	CloseHandle(conf);

	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_path", Command_NavMeshGoal, 0);
	RegAdminCmd("sm_unpath", Command_NavMeshGoalOff, 0);
}

public OnMapStart()
{
	g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action:Command_NavMeshGoalOff(client, args)
{
	new target = GetClientAimTarget(client, true);
	if(IsValidClient(target))
	{
		SDKUnhook(target, SDKHook_PreThink, UpdatePath);
		ForceWalk[target] = false;
		PrintToChat(client, "UnHooked %N", target);
	}
	else	
	{
		ForceWalk[client] = false;
		SDKUnhook(client, SDKHook_PreThink, UpdatePath);
	}
		
	return Plugin_Handled;
}

public Action:Command_NavMeshGoal(client, args)
{
	new target = GetClientAimTarget(client, true);
	if(IsValidClient(target))
	{
		SDKHook(target, SDKHook_PreThink, UpdatePath);
		ForceWalk[target] = true;
		PrintToChat(client, "Hooked %N", target);
	}
	else	
	{
		SDKHook(client, SDKHook_PreThink, UpdatePath);
		ForceWalk[client] = true;
	}
	
/*	new ent = MakeCEIVEnt(client, 1118);
	if (!IsValidEntity(ent))
	{
		ReplyToCommand(client, "[SM] Couldn't create entity for taunt");
		return Plugin_Handled;
	}
	new Address:pEconItemView = GetEntityAddress(ent) + Address:FindSendPropInfo("CTFWearable", "m_Item");
	if (pEconItemView <= Address_MinimumValid)
	{
		ReplyToCommand(client, "[SM] Couldn't find CEconItemView for taunt");
		return Plugin_Handled;
	}
	SDKCall(hPlayTaunt, client, pEconItemView) ? 1 : 0;
	AcceptEntityInput(ent, "Kill");*/
	
	return Plugin_Handled;
}
	
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (IsPlayerAlive(iClient) && ForceWalk[iClient]) 
	{
		iButtons |= IN_FORWARD;
		fVel[0] = 300.0;
	
	/*	new Float:vector[3];
		new Float:clientloc[3];
		
		GetClientAbsOrigin(iClient, clientloc);
		MakeVectorFromPoints(flTargetPos[iClient], clientloc, vector);
		NormalizeVector(vector, vector);
		ScaleVector(vector, -300.0);

		if(vector[2] > 1.0)
		{
			vector[2] = 0.0;
		}
		
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vector)*/
	//	fVel[0] = vector[0];
	//	fVel[1] = vector[1];
	//	fVel[2] = vector[2];
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
	
public UpdatePath(client)
{
	new Float:fClientEyePosition[3], Float:flClientAbsPosition[3];
	new Float:flToPos[3];
	
	GetClientEyePosition(client, fClientEyePosition);
	GetClientAbsOrigin(client, flClientAbsPosition);
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1) //Loop through all the sentries
	{
		if(IsPlayerAlive(client))
			PathFind(client, entity);
		
		new Float:pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		
	//	PrintToChatAll("%f %f %f", flTargetPos[client][0], flTargetPos[client][1], flTargetPos[client][2]);

		if(hPositions[client] != INVALID_HANDLE && GetArraySize(hPositions[client]) > 0)
		{
			GetArrayArray(hPositions[client], 1, flToPos, 3);
			
			new Float:distance = GetVectorDistance(flClientAbsPosition, flToPos);
			
			if(distance >= 60.0)
			{
				new arraypos1 = (GetArraySize(hPositions[client]) + 1 - GetArraySize(hPositions[client]));
				GetArrayArray(hPositions[client], arraypos1, flToPos, 3);

				LookAt(client, flToPos);
				
				PrintCenterText(client, "Far %f", distance);
			}
			else
			{
				if(GetArraySize(hPositions[client]) > 2)
				{
					new arraypos2 = (GetArraySize(hPositions[client]) + 2 - GetArraySize(hPositions[client]));
					GetArrayArray(hPositions[client], arraypos2, flToPos, 3);
					
					if(CheckIfPointVisible(fClientEyePosition, flToPos))
					{
						LookAt(client, flToPos);
						
						PrintCenterText(client, "Close %f", distance);
					}
					else
					{
						new arraypos1 = (GetArraySize(hPositions[client]) + 1 - GetArraySize(hPositions[client]));
						GetArrayArray(hPositions[client], arraypos1, flToPos, 3);
						
						LookAt(client, flToPos);
					}
				}
			}
			
			flTargetPos[client][0] = flToPos[0];
			flTargetPos[client][1] = flToPos[1];
			flTargetPos[client][2] = flToPos[2];
		}
	}
}

public PathFind(entity, target)	//Fix memory leak pls
{
	if(IsValidEntity(target))
	{
		new Float:EntityPos[3];
		new Float:TargetPos[3];
		
		GetClientAbsOrigin(entity, TargetPos);
		GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", EntityPos);
		
		new iClosestAreaIndex = 0;
		
		new bool:bBuiltPath = NavMesh_BuildPath(NavMesh_GetNearestArea(EntityPos), NavMesh_GetNearestArea(TargetPos), TargetPos, NavMeshShortestPathCost, _, iClosestAreaIndex, 0.0);
		
		if(bBuiltPath)
		{
			new iTempAreaIndex = iClosestAreaIndex;
			new iParentAreaIndex = NavMeshArea_GetParent(iTempAreaIndex);
			new iNavDirection;
			
			new Float:flHalfWidth;
			new Float:flCenterPortal[3];
			new Float:flClosestPoint[3];
			
			if(hPositions[entity] != INVALID_HANDLE)
			{
				ClearArray(hPositions[entity]);
				hPositions[entity] = INVALID_HANDLE;
			}
			
			hPositions[entity] = CreateArray(3);
			
			PushArrayArray(hPositions[entity], TargetPos, 3);
			
			while(iParentAreaIndex != -1)
			{
				new Float:flTempAreaCenter[3];
				new Float:flParentAreaCenter[3];
				
				NavMeshArea_GetCenter(iTempAreaIndex, flTempAreaCenter);
				NavMeshArea_GetCenter(iParentAreaIndex, flParentAreaCenter);
				
				iNavDirection = NavMeshArea_ComputeDirection(iTempAreaIndex, flParentAreaCenter);
				
				NavMeshArea_ComputePortal(iTempAreaIndex, iParentAreaIndex, iNavDirection, flCenterPortal, flHalfWidth);
				NavMeshArea_ComputeClosestPointInPortal(iTempAreaIndex, iParentAreaIndex, iNavDirection, flCenterPortal, flClosestPoint);
				
				flClosestPoint[2] = NavMeshArea_GetZ(iTempAreaIndex, flClosestPoint);
				
				PushArrayArray(hPositions[entity], flClosestPoint, 3);
				
				iTempAreaIndex = iParentAreaIndex;
				iParentAreaIndex = NavMeshArea_GetParent(iTempAreaIndex);
			}
			
			PushArrayArray(hPositions[entity], EntityPos, 3);
			
			for(new i = GetArraySize(hPositions[entity]) - 1; i > 0; i--)
			{
				new Float:flFromPos[3];
				new Float:flToPos[3];
				
				GetArrayArray(hPositions[entity], i, flFromPos, 3);
				GetArrayArray(hPositions[entity], i - 1, flToPos, 3);
				
				TE_SetupBeamPoints(flFromPos, flToPos, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 0.1, 5.0, 5.0, 5, 0.0, {0, 255, 0, 255}, 30);
				TE_SendToAll();
			}
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}

stock MakeCEIVEnt(client, itemdef)
{
	static Handle:hItem;
	if (hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
		TF2Items_SetNumAttributes(hItem, 0);
	}
	TF2Items_SetItemIndex(hItem, itemdef);
	return TF2Items_GiveNamedItem(client, hItem);
}

public bool:CheckIfPointVisible(Float:start[3], Float:end[3])
{
	new bool:isVisible = false;

	end[2] += 5.0;
	
	if (IsPointVisible(start, end))
		isVisible = true;

	return isVisible;
}

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_OPAQUE, RayType_EndPoint, TraceEntityFilterStuff);

	return TR_GetFraction() >= 0.75;
}

static LookAt(client, Float:position[3])
{
	decl Float:targetPos[3], Float:EyePos[3], Float:AimOnHunter[3], Float:AimAngles[3];

	if (IsClientInGame(client))
	{
		GetClientAbsOrigin(client, targetPos);
		if (GetVectorDistance(targetPos, position) < 500)
		{
			GetClientEyePosition(client, EyePos);
			MakeVectorFromPoints(EyePos, position, AimOnHunter);
			GetVectorAngles(AimOnHunter, AimAngles);
			TeleportEntity(client, NULL_VECTOR, AimAngles, NULL_VECTOR); // make the Survivor Bot aim on the Victim
		}
	}
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}  

stock Float:GetDifferenceBetweenAngles(Float:fA[3], Float:fB[3])
{
    decl Float:fFwdA[3]; GetAngleVectors(fA, fFwdA, NULL_VECTOR, NULL_VECTOR);
    decl Float:fFwdB[3]; GetAngleVectors(fB, fFwdB, NULL_VECTOR, NULL_VECTOR);
    return RadToDeg(ArcCosine(fFwdA[0] * fFwdB[0] + fFwdA[1] * fFwdB[1] + fFwdA[2] * fFwdB[2]));
}