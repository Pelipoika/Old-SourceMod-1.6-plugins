#pragma semicolon 1
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

Handle g_hCvarEnabled;
Handle g_hCvarSentryEnabled;
Handle g_hCvarDispenserEnabled;
Handle g_hCvarTeleEnabled;
Handle g_hCvarBuildingSizeMax;
Handle g_hCvarBuildingSizeMin;

#define PLUGIN_VERSION			"3.0"

public Plugin myinfo =
{
	name = "[TF2] Building Size Randomizer",
	author = "Pelipoika",
	description = "Upon building placed, gives it a random size",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_buildingresizer_enabled", "1.0", "Enable Randomly scaled buildings\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_hCvarSentryEnabled = CreateConVar("sm_resizesentry_enabled", "1.0", "Resize Sentry\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_hCvarDispenserEnabled = CreateConVar("sm_resizedispenser_enabled", "1.0", "Resize Dispenser\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_hCvarTeleEnabled = CreateConVar("sm_resizeteleporter_enabled", "1.0", "Resize Teleporter\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_hCvarBuildingSizeMin = CreateConVar("sm_building_minsize", "0.6", "Min size the building can randomly be scaled to", _, true, 0.0);
	g_hCvarBuildingSizeMax = CreateConVar("sm_building_maxsize", "2.0", "Max size the building can randomly be scaled to", _, true, 0.0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "obj_dispenser"))
	{
		if(GetConVarBool(g_hCvarDispenserEnabled)) 
			SDKHook(entity, SDKHook_SpawnPost, OnBuildingSpawned);
	}
	else if(StrEqual(classname, "obj_sentrygun"))
	{
		if(GetConVarBool(g_hCvarSentryEnabled)) 
			SDKHook(entity, SDKHook_SpawnPost, OnBuildingSpawned);
	}
	else if(StrEqual(classname, "obj_teleporter"))
	{
		if(GetConVarBool(g_hCvarTeleEnabled)) 
			SDKHook(entity, SDKHook_SpawnPost, OnBuildingSpawned);
	}
	else if(StrEqual(classname, "vgui_screen"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnScreenSpawned);
	}
}

public Action OnBuildingSpawned(int iEnt)
{
	char classname[32];
	GetEntityClassname(iEnt, classname, sizeof(classname));
	
	if(GetConVarBool(g_hCvarDispenserEnabled) && StrEqual(classname, "obj_dispenser")
	|| GetConVarBool(g_hCvarSentryEnabled) && StrEqual(classname, "obj_sentrygun")
	|| GetConVarBool(g_hCvarTeleEnabled) && StrEqual(classname, "obj_teleporter"))
	{
		float flSize = GetRandomFloat(GetConVarFloat(g_hCvarBuildingSizeMin), GetConVarFloat(g_hCvarBuildingSizeMax));
		char strSize[16];
		FloatToString(flSize, strSize, sizeof(strSize));
		
		SetVariantString(strSize);
		AcceptEntityInput(iEnt, "SetModelScale");
	}
}

public Action OnScreenSpawned(int iEnt)
{
	int iOwner = GetEntPropEnt(iEnt, Prop_Data, "m_hOwnerEntity");
	if(IsValidEntity(iOwner))
	{
		char strClass[64];
		GetEntityClassname(iOwner, strClass, sizeof(strClass));
		if(StrEqual(strClass, "obj_dispenser"))
		{
			float flOwnerScale = GetEntPropFloat(iOwner, Prop_Send, "m_flModelScale");
			
			PrintToChatAll("Width before: %f\nHeight before: %f", GetEntPropFloat(iEnt, Prop_Send, "m_flWidth"), GetEntPropFloat(iEnt, Prop_Send, "m_flHeight"));
			
			SetEntPropFloat(iEnt, Prop_Send, "m_flWidth", flOwnerScale * 20.0);
			SetEntPropFloat(iEnt, Prop_Send, "m_flHeight", flOwnerScale * 11.0);
			
			PrintToChatAll("Width after: %f\nHeight after: %f", GetEntPropFloat(iEnt, Prop_Send, "m_flWidth"), GetEntPropFloat(iEnt, Prop_Send, "m_flHeight"));
			
		//	PrintToChatAll("(%i) Dispenser Scale %f\n(%i) New Width: %f\n(%i) New Height: %f", iOwner, flOwnerScale, iEnt, flOwnerScale * 20.0, iEnt, flOwnerScale * 11.0);
		}
	}
}