#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <bonemerge_test>

new stringTable;
new g_visibleweapon[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ... };

public Plugin:myinfo = 
{
	name		= "[TF2] Weapon/wearable visibilizer",
	author		= "Pelipoika",
	description	= "Makes things a player doesnt own visible",
	version		= "1337.0",
	url			= "Nah"
};

public OnPluginStart()
{
	stringTable = FindStringTable("modelprecache");
	
	for(new i=1; i<=GetMaxClients(); i++)
		if(IsValidClient(i))
			OnClientPutInServer(i);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_InvApp);
}

public OnMapStart()
{
	PrecacheModel("models/buildables/toolbox_placement.mdl");
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if(StrContains(classname, "tf_wearable", false) != -1 && GetEntProp(entityIndex, Prop_Send, "m_iAccountID") <= 0 && !IsFakeClient(client))
		RequestFrame(GetHatInfo, EntIndexToEntRef(entityIndex));
	else if(StrContains(classname, "tf_weapon", false) != -1 && GetEntProp(entityIndex, Prop_Send, "m_iAccountID") <= 0 && !IsFakeClient(client))
		RequestFrame(GetExtraWearable, EntIndexToEntRef(entityIndex));
}

public GetHatInfo(any:entityIndex)
{
	new entity = EntRefToEntIndex(entityIndex);
	if(IsValidEntity(entity) && entityIndex != INVALID_ENT_REFERENCE)
	{
		new String:strModelPath[PLATFORM_MAX_PATH];
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		GetEntPropString(entity, Prop_Data, "m_ModelName", strModelPath, PLATFORM_MAX_PATH);
		Attachable_CreateAttachable(client, client, strModelPath);
	}
}

public GetExtraWearable(any:entityIndex)
{
	new entity = EntRefToEntIndex(entityIndex);
	if(IsValidEntity(entity) && entityIndex != INVALID_ENT_REFERENCE)
	{
		new eWearable = GetEntPropEnt(entity, Prop_Send, "m_hExtraWearable"); 
		if(eWearable != -1)
		{
			new String:strModelPath[PLATFORM_MAX_PATH];
			new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			GetEntPropString(eWearable, Prop_Data, "m_ModelName", strModelPath, PLATFORM_MAX_PATH);
			
			Attachable_CreateAttachable(client, client, strModelPath);
		}
	}
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwich);
		
	g_visibleweapon[client] = INVALID_ENT_REFERENCE;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
		Attachable_RemoveAll(client);
}
	
public Action:Event_InvApp(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
		Attachable_RemoveAll(client);
}
	
public OnWeaponSwich(client)
{
	new String:strModelPath[PLATFORM_MAX_PATH];
	new aWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(aWeapon) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) || !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if(g_visibleweapon[client] != INVALID_ENT_REFERENCE)
		{
			Attachable_UnhookEntity(client, EntRefToEntIndex(g_visibleweapon[client]));
			g_visibleweapon[client] = INVALID_ENT_REFERENCE;
		}
		
		if(GetEntProp(aWeapon, Prop_Send, "m_iAccountID") <= 0)
		{
			ReadStringTable(stringTable, GetEntProp(aWeapon, Prop_Send, "m_iWorldModelIndex"), strModelPath, PLATFORM_MAX_PATH);  
			new iItemIndex = GetEntProp(aWeapon, Prop_Send, "m_iItemDefinitionIndex");

			if(iItemIndex == 169)
				g_visibleweapon[client] = EntIndexToEntRef(Attachable_CreateAttachable(client, client, strModelPath, GetClientTeam(client)+6));	//8
			else if(iItemIndex == 1071)
				g_visibleweapon[client] = EntIndexToEntRef(Attachable_CreateAttachable(client, client, strModelPath, GetClientTeam(client)));
			else
				g_visibleweapon[client] = EntIndexToEntRef(Attachable_CreateAttachable(client, client, strModelPath));
		}
	}
}

public TF2_OnConditionAdded(client, TFCond:condition) 
{
    if(IsValidClient(client))
	{
		if(condition == TFCond_Taunting && GetEntProp(client, Prop_Send, "m_iTauntIndex") > 0)
		{
			if(g_visibleweapon[client] != INVALID_ENT_REFERENCE)
			{
				Attachable_UnhookEntity(client, EntRefToEntIndex(g_visibleweapon[client]));
				g_visibleweapon[client] = INVALID_ENT_REFERENCE;
			}
		}
		if(condition == TFCond_Cloaked || condition == TFCond_Disguised)
		{
			if(g_visibleweapon[client] != INVALID_ENT_REFERENCE)
			{
				Attachable_UnhookEntity(client, EntRefToEntIndex(g_visibleweapon[client]));
				g_visibleweapon[client] = INVALID_ENT_REFERENCE;
			}
			
			Attachable_RemoveAll(client);
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition) 
{
    if(IsValidClient(client))
	{
		if(condition == TFCond_Cloaked || condition == TFCond_Disguised)
		{
			if(g_visibleweapon[client] != INVALID_ENT_REFERENCE)
			{
				Attachable_UnhookEntity(client, EntRefToEntIndex(g_visibleweapon[client]));
				g_visibleweapon[client] = INVALID_ENT_REFERENCE;
			}
			
			new String:strModelPath[PLATFORM_MAX_PATH];
			new aWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(aWeapon) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) || !TF2_IsPlayerInCondition(client, TFCond_Disguised))
			{
				if(aWeapon != -1 && GetEntProp(aWeapon, Prop_Send, "m_iAccountID") <= 0)
				{
					ReadStringTable(stringTable, GetEntProp(aWeapon, Prop_Send, "m_iWorldModelIndex"), strModelPath, PLATFORM_MAX_PATH);  
					new iItemIndex = GetEntProp(aWeapon, Prop_Send, "m_iItemDefinitionIndex");

					if(iItemIndex == 169)
						g_visibleweapon[client] = EntIndexToEntRef(Attachable_CreateAttachable(client, client, strModelPath, GetClientTeam(client)+6));	//8
					else if(iItemIndex == 1071)
						g_visibleweapon[client] = EntIndexToEntRef(Attachable_CreateAttachable(client, client, strModelPath, GetClientTeam(client)));
					else
						g_visibleweapon[client] = EntIndexToEntRef(Attachable_CreateAttachable(client, client, strModelPath));
				}
			}
		}
	}
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}