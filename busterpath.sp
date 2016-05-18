#include <sourcemod>
#include <sdktools>
#include <profiler>
#include <navmesh>

new g_iPathLaserModelIndex = -1;

new Handle:g_hCongaPath[MAXPLAYERS+1];
new g_iCongaCurrentPathNode[MAXPLAYERS+1] = { -1, ... };
new Float:g_flCongaGoalPos[MAXPLAYERS+1][3];

public OnPluginStart()
{
	RegAdminCmd("sm_path", Command_NavMeshBuildPath, 0);
}

public OnMapStart()
{
	g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action:Command_NavMeshBuildPath(client, args)
{
	if (!NavMesh_Exists()) return Plugin_Handled;
	
	new index = -1;
	while ((index = FindEntityByClassname(index, "obj_sentrygun")) != -1) //Loop through all the sentries
	{	
		if(IsValidClient(client))
		{
			new Float:sPos[3];
			new Float:position[3];
			GetClientAbsOrigin(client, position)							//Client
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", sPos);		//Sentry
			
			new iCurrentAreaIndex = NavMesh_GetNearestArea(position);			//Get Player pos
			if (iCurrentAreaIndex != -1)
			{
				new iGoalSentryAreaIndex = NavMesh_GetNearestArea(sPos);		//Get sentry pos
				if (iGoalSentryAreaIndex != -1)
				{
					new Handle:hAreas = NavMesh_GetAreas();
					if (hAreas == INVALID_HANDLE) return Plugin_Handled;
					
					new iStartAreaIdIndex = NavMesh_GetNearestArea(position);
					new iSAreaID = GetArrayCell(hAreas, iStartAreaIdIndex, NavMeshArea_ID);
					PrintToChatAll("Nearest area from %N ID: %d", client, iSAreaID);
					
					new iEndAreaIndex = NavMesh_GetNearestArea(sPos);
					new iEAreaID = GetArrayCell(hAreas, iEndAreaIndex, NavMeshArea_ID);
					PrintToChatAll("Nearest area ID from sentry: %d", iEAreaID);
					
					new iStartAreaIndex = FindValueInArray(hAreas, iSAreaID);
					new iGoalAreaIndex = FindValueInArray(hAreas, iEAreaID);
					
					if (iStartAreaIndex == -1 || iGoalAreaIndex == -1) return Plugin_Handled;
					
					decl Float:flGoalPos[3];
					NavMeshArea_GetCenter(iGoalAreaIndex, flGoalPos);
					
					new iColor[4] = {0, 255, 0, 255};
					
					new Float:flMaxPathLength = 0.0;
					if (args > 2)
					{
						decl String:sMaxPathLength[64];
						GetCmdArg(3, sMaxPathLength, sizeof(sMaxPathLength));
						flMaxPathLength = StringToFloat(sMaxPathLength);
						
						if (flMaxPathLength < 0.0) return Plugin_Handled;
					}
					
					new iClosestAreaIndex = 0;
					
					new Handle:hProfiler = CreateProfiler();
					StartProfiling(hProfiler);
					
					new bool:bBuiltPath = NavMesh_BuildPath(iStartAreaIndex, iGoalAreaIndex, flGoalPos, NavMeshShortestPathCost, _, iClosestAreaIndex, flMaxPathLength);
					
					StopProfiling(hProfiler);
					
					new Float:flProfileTime = GetProfilerTime(hProfiler);
					
					CloseHandle(hProfiler);
					
					if (client > 0) 
					{
						PrintToChatAll("Path built!\nBuild path time: %f\nReached goal: %d", flProfileTime, bBuiltPath);
						
						new iTempAreaIndex = iClosestAreaIndex;
						new iParentAreaIndex = NavMeshArea_GetParent(iTempAreaIndex);
						new iNavDirection;
						new Float:flHalfWidth;
						
						decl Float:flCenterPortal[3], Float:flClosestPoint[3];
						
						new Handle:hPositions = CreateArray(3);
						
						PushArrayArray(hPositions, flGoalPos, 3);
						
						while (iParentAreaIndex != -1)
						{
							decl Float:flTempAreaCenter[3], Float:flParentAreaCenter[3];
							NavMeshArea_GetCenter(iTempAreaIndex, flTempAreaCenter);
							NavMeshArea_GetCenter(iParentAreaIndex, flParentAreaCenter);
							
							iNavDirection = NavMeshArea_ComputeDirection(iTempAreaIndex, flParentAreaCenter);
							NavMeshArea_ComputePortal(iTempAreaIndex, iParentAreaIndex, iNavDirection, flCenterPortal, flHalfWidth);
							NavMeshArea_ComputeClosestPointInPortal(iTempAreaIndex, iParentAreaIndex, iNavDirection, flCenterPortal, flClosestPoint);
							
							flClosestPoint[2] = NavMeshArea_GetZ(iTempAreaIndex, flClosestPoint);
							
							PushArrayArray(hPositions, flClosestPoint, 3);
							
							iTempAreaIndex = iParentAreaIndex;
							iParentAreaIndex = NavMeshArea_GetParent(iTempAreaIndex);
						}
						
						decl Float:flStartPos[3];
						NavMeshArea_GetCenter(iStartAreaIndex, flStartPos);
						PushArrayArray(hPositions, flStartPos, 3);
						
						for (new i = GetArraySize(hPositions) - 1; i > 0; i--)
						{
							decl Float:flFromPos[3], Float:flToPos[3];
							GetArrayArray(hPositions, i, flFromPos, 3);
							GetArrayArray(hPositions, i - 1, flToPos, 3);
																														  //Life
							TE_SetupBeamPoints(flFromPos, flToPos, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 30.0, 5.0, 5.0, 5, 0.0, iColor,30);
								
							TE_SendToAll();
						}
					}
					else 
					{
						PrintToServer("Path built!\nBuild path time: %f\nReached goal: %d", flProfileTime, bBuiltPath);
					}
				}
				else
				{
					PrintToServer("Failed to create new path for sentry %d: destination is not on nav mesh!", index);
				}
			}
			else
			{
				PrintToServer("Failed to create new path for client %d: client is not on nav mesh!", client);
			}
		}
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}