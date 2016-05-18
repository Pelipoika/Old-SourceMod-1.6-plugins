#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <equipwearable>

// ---- Engine flags ---------------------------------------------------------------
#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)

new soul[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

public OnPluginStart()
{
	RegAdminCmd("sm_zombie", AFO, ADMFLAG_ROOT);
}

public Action:AFO(client, args)
{
/*	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout:		
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5617, 6, 69));
			BoneMergeToSoul(client, 5617);
		}
		case TFClass_Soldier:
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5618, 6, 69));
			BoneMergeToSoul(client, 5618);
		}
		case TFClass_DemoMan:
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5620, 6, 69));
			BoneMergeToSoul(client, 5620);
		}
		case TFClass_Medic:		
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5622, 6, 69));
			BoneMergeToSoul(client, 5622);
		}
		case TFClass_Pyro:		
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5624, 6, 69));
			BoneMergeToSoul(client, 5624);
		}
		case TFClass_Spy:		
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5623, 6, 69));
			BoneMergeToSoul(client, 5623);
		}
		case TFClass_Engineer:	
		{	
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5621, 6, 69));
			BoneMergeToSoul(client, 5621);
		}
		case TFClass_Sniper:	
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5625, 6, 69));
			BoneMergeToSoul(client, 5625);
		}
		case TFClass_Heavy:		
		{
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5619, 6, 69));
			BoneMergeToSoul(client, 5619);
		}
	}*/
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout:		
		{	
			soul[client] = EntIndexToEntRef(TF2_PlayerGiveWearable(client, 5617, 6, 69));
			BoneMergeToSoul(client, 5617);
		
			SetVariantString("models/player/items/scout/scout_zombie.mdl");
			AcceptEntityInput(client, "SetCustomModel");
		}
		case TFClass_Soldier:
		{
			SetEntityModel(client,"models/player/items/soldier/soldier_zombie.mdl");
		}
		case TFClass_DemoMan:
		{
			SetEntityModel(client,"models/player/items/demo/demo_zombie.mdl");
		}
		case TFClass_Medic:		
		{
			SetEntityModel(client,"models/player/items/medic/medic_zombie.mdl");
		}
		case TFClass_Pyro:		
		{
			SetEntityModel(client,"models/player/items/pyro/pyro_zombie.mdl");
		}
		case TFClass_Spy:		
		{
			SetEntityModel(client,"models/player/items/spy/spy_zombie.mdl");
		}
		case TFClass_Engineer:	
		{	
			SetEntityModel(client,"models/player/items/engineer/engineer_zombie.mdl");
		}
		case TFClass_Sniper:	
		{
			SetEntityModel(client,"models/player/items/sniper/sniper_zombie.mdl");
		}
		case TFClass_Heavy:		
		{
			SetEntityModel(client,"models/player/items/heavy/heavy_zombie.mdl");
		}
	}
	
	return Plugin_Handled;
}

stock BoneMergeToSoul(client, iItemIndex)
{
	new link1 = CreateEntityByName("tf_wearable");
	new link2 = CreateEntityByName("tf_wearable");
	if(IsValidEntity(link1) && IsValidEntity(link2))
	{
		DispatchSpawn(link1);
		DispatchSpawn(link2);
		
		new iSoul = EntRefToEntIndex(soul[client]);
	
		SetVariantString("!activator");
		AcceptEntityInput(link1, "SetParent", client);
		
		SetVariantString("!activator");
		AcceptEntityInput(link2, "SetParent", client);
		
		SetVariantString("head");
		AcceptEntityInput(link1, "SetParentAttachment", client);
		
		SetVariantString("head");
		AcceptEntityInput(link2, "SetParentAttachment", client);
	
		SetEntProp(link1, Prop_Send, "m_iItemDefinitionIndex", iItemIndex);
		SetEntProp(link2, Prop_Send, "m_iItemDefinitionIndex", iItemIndex);
		
		new TFClassType:class = TF2_GetPlayerClass(client);
		switch(class)
		{
			case TFClass_Scout:		
			{
				SetEntityModel(link1,"models/player/items/scout/scout_zombie.mdl");
				SetEntityModel(link2,"models/player/items/scout/scout_zombie.mdl");
			}
			case TFClass_Soldier:
			{
				SetEntityModel(link1,"models/player/items/soldier/soldier_zombie.mdl");
			}
			case TFClass_DemoMan:
			{
				SetEntityModel(link1,"models/player/items/demo/demo_zombie.mdl");
			}
			case TFClass_Medic:		
			{
				SetEntityModel(link1,"models/player/items/medic/medic_zombie.mdl");
			}
			case TFClass_Pyro:		
			{
				SetEntityModel(link1,"models/player/items/pyro/pyro_zombie.mdl");
			}
			case TFClass_Spy:		
			{
				SetEntityModel(link1,"models/player/items/spy/spy_zombie.mdl");
			}
			case TFClass_Engineer:	
			{	
				SetEntityModel(link1,"models/player/items/engineer/engineer_zombie.mdl");
			}
			case TFClass_Sniper:	
			{
				SetEntityModel(link1,"models/player/items/sniper/sniper_zombie.mdl");
			}
			case TFClass_Heavy:		
			{
				SetEntityModel(link1,"models/player/items/heavy/heavy_zombie.mdl");
			}
		}
		
		SetEntProp(link1, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
		SetEntProp(link2, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
	}
}

stock TF2_PlayerGiveWearable(iClient, iItemIndex, iQuality = 9, iLevel = 0) 
{
	new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL || FORCE_GENERATION);
	TF2Items_SetClassname(hItem, "tf_wearable");
	TF2Items_SetItemIndex(hItem, 0);
	TF2Items_SetQuality(hItem, iQuality);
	TF2Items_SetLevel(hItem, iLevel);
	TF2Items_SetNumAttributes(hItem, 0);

	new iEntity = TF2Items_GiveNamedItem(iClient, hItem);
	SetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex", iItemIndex);
	EquipPlayerWearable(iClient, iEntity);
	CloseHandle(hItem);
	return iEntity;
}