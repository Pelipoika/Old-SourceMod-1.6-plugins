#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

public OnPluginStart()
{
	RegAdminCmd("sm_dominate", Cmd_msg, ADMFLAG_ROOT);
}

public Action:Cmd_msg(client, args)
{
	if(IsValidClient(client))
	{
		SpawnManyAmmoPacks(client, "models/items/tf_gift.mdl", 1, 10, 90.0);
		
	/*	for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i) && i != client)
			{
				SendDeathMessage(client, i);
			}
		}*/
	}
	
	return Plugin_Handled;
}

stock SpawnManyAmmoPacks(client, String:model[], skin = 0, num = 14, Float:offsz = 30.0)
{
	FakeClientCommand(client, "taunt");

	decl Float:pos[3], Float:vel[3], Float:ang[3];
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	GetClientAbsOrigin(client, pos);
	pos[2] += offsz;

	for (new i = 0; i < num; i++)
	{
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(300.0, 500.0);
		pos[0] += GetRandomFloat(-5.0, 5.0);
		pos[1] += GetRandomFloat(-5.0, 5.0);
		
		new ent = CreateEntityByName("tf_bonus_duck_pickup");
		if (IsValidEntity(ent))
		{
			DispatchKeyValueVector(ent, "origin", pos);
			DispatchKeyValueVector(ent, "angles", ang);
		//	DispatchKeyValue(ent, "model", model);
			DispatchKeyValueVector(ent, "basevelocity", vel);
			DispatchKeyValueVector(ent, "velocity", vel);
			DispatchKeyValue(ent, "OnPlayerTouch", "!self,Kill,,0,-1"); 		
			DispatchSpawn(ent);
			
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
			
			SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
			SetEntProp(ent, Prop_Data, "m_iEFlags", 35913728);
			SetEntPropFloat(ent, Prop_Data, "m_flFriction", 1.0);
			
			decl String:addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::20:1");
			SetVariantString(addoutput);
			
			AcceptEntityInput(ent, "AddOutput");
			AcceptEntityInput(ent, "FireUser1");
			
		//	SetEntProp(ent, Prop_Send, "m_bSpecial", GetRandomInt(0, 1));
			SetEntProp(ent, Prop_Send, "m_nSkin", GetRandomInt(0, 21));
			
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetRandomFloat(0.5, 1.5));
		}
	}
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}