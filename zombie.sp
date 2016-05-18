#include <sourcemod>
#include <sdktools>
#include <tf2items>
#include <tf2>
#include <tf2_stocks>
#include <equipwearable>

// ---- Engine flags -------------------------
#define EF_BONEMERGE            (1 << 0)
#define EF_NODRAW				(1 << 1)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)

new Handle:attachments_array = INVALID_HANDLE;
new bool:delete_enabled[MAXPLAYERS+1] = false;

new gItem[MAXPLAYERS+1];
new gLink[MAXPLAYERS+1];
new gClass1[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name			= "[TF2] Be The Zombie",
	author			= "Pelipoika",
	description		= "Play as a zombie",
	version			= "1.0",
	url				= ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_zombie", AFO, ADMFLAG_ROOT);
	RegAdminCmd("sm_zomboff", NFO, ADMFLAG_ROOT);
	
	HookEvent("player_team", Event_PlayerTeam);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && delete_enabled[client] == true)
	{
		NFO(client, client);
	}
}

public TF2_OnConditionAdded(client, TFCond:cond) 
{ 
    if (IsValidClient(client) && delete_enabled[client] == true && cond == TFCond_HalloweenGhostMode)
	{
		NFO(client, client);
	}
}

public Action:AFO(client, args)
{
	NFO(client, client);
	
	if(!TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		switch(class)
		{
			case TFClass_Scout:		
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
				TF2_PlayerGiveWearable(client, 5617, 6, 69);
			}
			case TFClass_Soldier:
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
				TF2_PlayerGiveWearable(client, 5618, 6, 69);
			}
			case TFClass_DemoMan:
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
				TF2_PlayerGiveWearable(client, 5620, 6, 69);
			}
			case TFClass_Medic:		
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
				TF2_PlayerGiveWearable(client, 5622, 6, 69);
			}
			case TFClass_Pyro:		
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
				TF2_PlayerGiveWearable(client, 5624, 6, 69);
			}
			case TFClass_Spy:		
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
				TF2_PlayerGiveWearable(client, 5623, 6, 69);
			}
			case TFClass_Engineer:	
			{	
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
				TF2_PlayerGiveWearable(client, 5621, 6, 69);
			}
			case TFClass_Sniper:	
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
				TF2_PlayerGiveWearable(client, 5625, 6, 69);
			}
			case TFClass_Heavy:		
			{
				gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
				TF2_PlayerGiveWearable(client, 5619, 6, 69);
			}
				
			/*
			case TFClass_Scout:		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
			case TFClass_Soldier:	gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
			case TFClass_DemoMan:	gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
			case TFClass_Medic:		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
			case TFClass_Pyro:		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/pyrp.mdl");
			case TFClass_Spy:		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
			case TFClass_Engineer:	gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
			case TFClass_Sniper:	gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
			case TFClass_Heavy:		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
			*/
		}
	//	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	//Testaa tehä gClassista näkymätön
	//	SetEntityRenderColor(client, 255, 255, 255, 0);
	}
	else
		ReplyToCommand(client, "Nope.");
		
	return Plugin_Handled;
}

stock TF2_PlayerGiveWearable(iClient, iItemIndex, iQuality = 9, iLevel = 0) 
{
/*	new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL || FORCE_GENERATION);
	TF2Items_SetClassname(hItem, "tf_wearable");
	TF2Items_SetItemIndex(hItem, 0);
	TF2Items_SetQuality(hItem, iQuality);
	TF2Items_SetLevel(hItem, iLevel);
	TF2Items_SetNumAttributes(hItem, 0);

	new iEntity = TF2Items_GiveNamedItem(iClient, hItem);
	SetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex", iItemIndex);
	EquipPlayerWearable(iClient, iEntity);
	CloseHandle(hItem);
	return iEntity;*/
}

public Action:NFO(client, args)
{
	SetEntityRenderColor( client, 255, 255, 255, 255 ); 
	Attachable_UnhookEntity(client, gClass1[client]);
	
	return Plugin_Handled;
}

stock CAttach(child, parent, client, String:modelname[]) 
{
	if (attachments_array == INVALID_HANDLE) attachments_array = CreateArray(2);
	if (!IsValidEntity(child)) return false;
	if (!IsValidEntity(parent)) return false;
	new link = CGetLink(child);
	if (link == -1 || !IsValidEntity(link)) link = CAddLink(child, client, modelname);
	if (link == -1 || !IsValidEntity(link)) 
	{
		decl String:Classname[128];
		if (GetEdictClassname(child, Classname, sizeof(Classname))) ThrowError("Unable to create link for entity %s", Classname);
		else ThrowError("Unable to create link for unknown entity");
		return false;
	}
	
	new String:name[16];
	Format(name, sizeof(name), "target%i", parent);
	DispatchKeyValue(parent, "targetname", name);

	new String:name2[32];
	GetEntPropString(parent, Prop_Data, "m_iName", name2, sizeof(name2));
	DispatchKeyValue(link, "parentname", name2);
	
	SetVariantString(name2);
	AcceptEntityInput(link, "SetParent", link, link, 0);
	
	SetVariantString("head");
	AcceptEntityInput(link, "SetParentAttachment", link, link, 0);
	
	return true;
}

stock CDetach(ent) 
{
	if (attachments_array == INVALID_HANDLE) attachments_array = CreateArray(2);
	if (!IsValidEntity(ent)) return false;
	
	new link = CGetLink(ent);
	if (link != -1) 
	{
		AcceptEntityInput(ent, "SetParent", -1, -1, 0);
		if (IsValidEntity(link)) AcceptEntityInput(link, "kill");
		for (new i = 0; i < GetArraySize(attachments_array); i++) 
		{
			new ent2 = GetArrayCell(attachments_array, i);
			if (ent == ent2) RemoveFromArray(attachments_array, i);
		}
		
		return true;
	}
	return false;
}

stock CGetLink(ent) 
{
	for (new i = 0; i < GetArraySize(attachments_array); i++) 
	{
		new ent2 = GetArrayCell(attachments_array, i);
		if (ent == ent2) return (GetArrayCell(attachments_array, i, 1));
	}
	return -1;
}

stock CAddLink(ent, client, String:modelname[]) 
{
	new String:name_ent[16]; 
	Format(name_ent, sizeof(name_ent), "target%i", ent);
	DispatchKeyValue(ent, "targetname", name_ent);

	new link = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(link)) 
	{
		new String:name_link[16]; 
		Format(name_link, sizeof(name_link), "target%i", link);
		DispatchKeyValue(link, "targetname", name_link);
		
		DispatchKeyValue(link, "classname", "prop_dynamic_override");
		DispatchKeyValue(link, "spawnflags", "1");
		
		SetEntProp(link, Prop_Send, "m_CollisionGroup", 11);
		SetEntProp(link, Prop_Send, "m_fEffects",				EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES|EF_BONEMERGE_FASTCULL);
	//	SetEntProp(link, Prop_Send, "m_fEffects", 32);
			
		new TFClassType:class = TF2_GetPlayerClass(client);
		switch(class)
		{
			case TFClass_Scout:		
			{
				SetEntityModel(link,"models/player/items/scout/scout_zombie.mdl");
			}
			case TFClass_Soldier:
			{
				SetEntityModel(link,"models/player/items/soldier/soldier_zombie.mdl");
			}
			case TFClass_DemoMan:
			{
				SetEntityModel(link,"models/player/items/demo/demo_zombie.mdl");
			}
			case TFClass_Medic:		
			{
				SetEntityModel(link,"models/player/items/medic/medic_zombie.mdl");
			}
			case TFClass_Pyro:		
			{
				SetEntityModel(link,"models/player/items/pyro/pyro_zombie.mdl");
			}
			case TFClass_Spy:		
			{
				SetEntityModel(link,"models/player/items/spy/spy_zombie.mdl");
			}
			case TFClass_Engineer:	
			{	
				SetEntityModel(link,"models/player/items/engineer/engineer_zombie.mdl");
			}
			case TFClass_Sniper:	
			{
				SetEntityModel(link,"models/player/items/sniper/sniper_zombie.mdl");
			}
			case TFClass_Heavy:		
			{
				SetEntityModel(link,"models/player/items/heavy/heavy_zombie.mdl");
			}
		}
		
		//SetEntityModel(link, "models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl");
		
		new iTeam = GetClientTeam(client);
		SetEntProp(link, Prop_Send, "m_nSkin",	(iTeam-2));
		
		SetVariantString(name_link);
		AcceptEntityInput(ent, "SetParent", ent, ent, 0);
		
		SetVariantString("head");
		AcceptEntityInput(ent, "SetParentAttachment", ent, ent, 0);
		
		new index = PushArrayCell(attachments_array, ent);
		SetArrayCell(attachments_array, index, link, 1);
		
		gLink[client] = link;
		
		return link;
	}
	return -1;
}

stock Attachable_CreateAttachable(client, parent, String:modelname[])
{
	new iTeam = GetClientTeam(client);
	gItem[client] = CreateEntityByName("prop_dynamic_override");
	
	if (IsValidEdict(gItem[client]))
	{
		SetEntProp(gItem[client], Prop_Send, "m_nSkin", (iTeam-2));
		SetEntProp(gItem[client], Prop_Send, "m_CollisionGroup", 11);
	//	SetEntProp(gItem[client], Prop_Send, "m_fEffects", 32);
		SetEntProp(gItem[client], Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);

		DispatchKeyValue(gItem[client], "model", modelname);
		
		DispatchSpawn(gItem[client]);
		ActivateEntity(gItem[client]);
		AcceptEntityInput(gItem[client], "Start");
		
		CAttach(gItem[client], parent, client, modelname);
		
		delete_enabled[client] = true;
	}
	
	return gItem[client];
}

stock Attachable_UnhookEntity(client, ent)
{
	if (delete_enabled[client] == true)
	{
		CDetach(ent);
		AcceptEntityInput(ent, "KillHierarchy");
	}
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}