#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname,"tf_projectile_pipe_remote"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnMarkerSpawn); 
	}
}

public OnMarkerSpawn(entity) 
{ 
    if(IsValidEntity(entity)) 
    {
		new owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");

		new Float:flPos[3], Float:flAngle[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flPos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", flAngle);
	
		new sentry = SpawnSentry(1, flPos, flAngle, 1, true);
		
		if(IsValidEntity(sentry))
		{
			SetVariantString("!activator");
			AcceptEntityInput(sentry, "SetParent", entity);
		}
	}
}  

stock SpawnSentry(builder, Float:Position[3], Float:Angle[3], level, bool:mini=false, bool:disposable=false, flags=4)
{
	static const Float:m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, Float:m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const Float:m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, Float:m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	new sentry = CreateEntityByName("obj_sentrygun");
	
	if(IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);

		DispatchKeyValueVector(sentry, "origin", Position);
		DispatchKeyValueVector(sentry, "angles", Angle);
		
		if(mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
		}
		else if(disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
		}
	}
	
	return sentry;
}
