#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <attachments>

new g_CarriedDispenser[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

#define DISPENSER_BLUEPRINT	"models/buildables/dispenser_blueprint.mdl"
#define SOUND_PICKUP		"weapons/sentry_upgrading2.wav"

//#define DEBUG

//Make a plugin that lets you sap buildings via cmd

public OnPluginStart()
{
	RegConsoleCmd("sm_pickthatp", Command_Test);

	HookEvent("player_carryobject", Event_CarryObject);
	HookEvent("player_dropobject", Event_DropObject);
	HookEvent("player_death", Event_death);
}

public OnMapStart()
{
	PrecacheModel(DISPENSER_BLUEPRINT);
	PrecacheSound(SOUND_PICKUP);
}

public OnClientAuthorized(client)
{
	g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
}

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (client >= 1 && client <= MaxClients && IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if(g_CarriedDispenser[client] == INVALID_ENT_REFERENCE)
		{
			if(iButtons & IN_RELOAD && GetEntProp(client, Prop_Send, "m_bCarryingObject") != 1)
				Command_Test(client, client);
		}
		else if(g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 200.0);
			if((iButtons & IN_RELOAD && iButtons & IN_ATTACK2) && g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
			{
				UnEquipDispenser(client);
			}
		}
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(iEntity)
{
	if(IsValidEntity(iEntity))
	{
		decl String:classname[64];
		GetEntityClassname(iEntity, classname, sizeof(classname));
		
		if(StrContains(classname, "obj_dispenser", false) != -1)
		{	
			new builder = GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder");
			if(builder >= 1 && builder <= MaxClients && IsClientInGame(builder))
			{
				/*
				if(linkent[iEntity] != INVALID_ENT_REFERENCE)
				{
					PrintToChatAll("Linked entity was valid");
					AcceptEntityInput(EntRefToEntIndex(linkent[iEntity]), "Kill");
					PrintToChatAll("Killed it");
					linkent[iEntity] = INVALID_ENT_REFERENCE;
				}
				*/
			
				if(g_CarriedDispenser[builder] != INVALID_ENT_REFERENCE)
				{
					new Dispenser = EntRefToEntIndex(g_CarriedDispenser[builder]);
					CDetach(Dispenser);
					g_CarriedDispenser[builder] = INVALID_ENT_REFERENCE;
				}

				SetEntPropFloat(builder, Prop_Send, "m_flMaxspeed", 300.0);
				TF2_RemoveCondition(builder, TFCond_MarkedForDeath);
			}
		}
	}
}

public Action:Command_Test(client, args)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		new target = GetClientAimTarget(client, false);
		if(IsValidEntity(target))
		{
			decl String:classname[64];
			GetEntityClassname(target, classname, sizeof(classname));
			
			if(StrContains(classname, "dispenser", false) != -1 && GetEntProp(target, Prop_Send, "m_bBuilding") != 1 
			&& g_CarriedDispenser[client] == INVALID_ENT_REFERENCE && GetEntPropEnt(target, Prop_Send, "m_hBuilder") == client)
			{
				EquipEntity(client, target);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Event_death(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
	{
		new Dispenser = EntRefToEntIndex(g_CarriedDispenser[client]);
		CDetach(Dispenser);
	
		SetVariantInt(500);
		AcceptEntityInput(Dispenser, "RemoveHealth");
		
		g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
		
		#if defined DEBUG
		PrintToChatAll("Event_death");
		#endif
	}
}

public Action:Event_DropObject(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFObjectType:object = TFObjectType:GetEventInt(event, "object");
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && object == TFObject_Dispenser)
	{
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding))
		{
			SetEntProp(iBuilding, Prop_Send, "m_usSolidFlags", 4);
			
			#if defined DEBUG
			PrintToChatAll("Event_DropObject");
			#endif
			
			if(EntRefToEntIndex(g_CarriedDispenser[client]) == iBuilding)
			{
				UnEquipDispenser(client);
				
				#if defined DEBUG
				PrintToChatAll("UnEquipDispenser in Event_DropObject g_CarriedDispenser matched iBuilding");
				#endif
			}
		}
	}
}

public Action:Event_CarryObject(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFObjectType:object = TFObjectType:GetEventInt(event, "object");
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && object == TFObject_Dispenser)
	{
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding))
		{
			#if defined DEBUG
			PrintToChatAll("Event_CarryObject");
			#endif
		
			if(EntRefToEntIndex(g_CarriedDispenser[client]) == iBuilding)
			{
				UnEquipDispenser(client);
				
				#if defined DEBUG
				PrintToChatAll("UnEquipDispenser in Event_CarryObject g_CarriedDispenser matched iBuilding");
				#endif
			}
		}
	}
}

EquipEntity(client, target)
{
	new Float:dPos[3], Float:bPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", dPos);
	GetClientAbsOrigin(client, bPos);
	if(GetVectorDistance(dPos, bPos) <= 125.0 && GetEntProp(target, Prop_Send, "m_iState") == 0)
	{				
		EmitSoundToAll(SOUND_PICKUP, target);
		new Float:pPos[3], Float:pAng[3];
	
		new trigger = -1;
		while ((trigger = FindEntityByClassname(trigger, "dispenser_touch_trigger")) != -1)
		{
			if(IsValidEntity(trigger))
			{
				new ownerentity = GetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity");
				if(ownerentity == target)
				{
					SetVariantString("!activator");
					AcceptEntityInput(trigger, "SetParent", target);
				}
			}
		}
	
		if(g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
		{
			new Dispenser = EntRefToEntIndex(g_CarriedDispenser[client]);
			CDetach(Dispenser);
			AcceptEntityInput(g_CarriedDispenser[client], "ClearParent");
		}
		
		CAttach(target, client, "flag");

		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pPos);
		GetEntPropVector(target, Prop_Send, "m_angRotation", pAng);
		
		pPos[1] += 35.0;	//This moves it up/down
		pPos[2] += 15.0;
		
		pAng[2] += 90.0;
		pAng[0] += 90.0;
		
		SetEntPropVector(target, Prop_Send, "m_vecOrigin", pPos);
		SetEntPropVector(target, Prop_Send, "m_angRotation", pAng);
		
		SetEntProp(target, Prop_Send, "m_usSolidFlags", 2);
		SetEntProp(target, Prop_Send, "m_fEffects", 16|64);
		
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 200.0);
		
		TF2_AddCondition(client, TFCond_MarkedForDeath, -1.0);
		
		g_CarriedDispenser[client] = EntIndexToEntRef(target);
		SetEntityRenderMode(target, RENDER_NORMAL);
		SetEntityRenderColor(target, 255, 255, 255, 255);
	}
}

UnEquipDispenser(client)
{
	new buildtool = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
	
	decl String:classname[64];
	GetEntityClassname(buildtool, classname, sizeof(classname));
	
	if(IsValidEntity(buildtool) && StrContains(classname, "build", false) != -1)
	{
		new Dispenser = EntRefToEntIndex(g_CarriedDispenser[client]);
		if(GetEntProp(Dispenser, Prop_Send, "m_iState") == 0)
		{
			CDetach(Dispenser);
			AcceptEntityInput(g_CarriedDispenser[client], "ClearParent");
		
			SetEntPropEnt(buildtool, Prop_Send, "m_hObjectBeingBuilt", g_CarriedDispenser[client]);
			SetEntProp(buildtool, Prop_Send, "m_iBuildState", 2);
			SetEntProp(buildtool, Prop_Send, "m_iState", 2);
			SetEntProp(buildtool, Prop_Send, "m_fEffects", 129);
			SetEntProp(buildtool, Prop_Send, "m_nSequence", 34);
			
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", buildtool);
			SetEntPropEnt(client, Prop_Send, "m_hCarriedObject", g_CarriedDispenser[client]);
			SetEntProp(client, Prop_Send, "m_bCarryingObject", 1);
			
			SetEntityModel(g_CarriedDispenser[client], DISPENSER_BLUEPRINT);

			SetEntProp(g_CarriedDispenser[client], Prop_Send, "m_flSimulationTime", 123);
			SetEntProp(g_CarriedDispenser[client], Prop_Send, "m_bCarried", 1);
			SetEntProp(g_CarriedDispenser[client], Prop_Send, "m_bPlacing", 1);
			SetEntProp(g_CarriedDispenser[client], Prop_Send, "m_fEffects", 0);
			SetEntProp(g_CarriedDispenser[client], Prop_Send, "m_bBuilding", 1);
			SetEntPropFloat(g_CarriedDispenser[client], Prop_Send, "m_flPercentageConstructed", 0.04);
			
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
			
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
			TF2_RemoveCondition(client, TFCond_MarkedForDeath);
			SetEntityRenderMode(Dispenser, RENDER_NORMAL);
			SetEntityRenderColor(Dispenser, 255, 255, 255, 255);
			SetEntProp(Dispenser, Prop_Send, "m_iHealth", 100);
			g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
		}
	}
}