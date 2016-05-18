#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <gmg\misc>
#pragma semicolon 1

#define MODEL_BOMB "models/props_lakeside_event/bomb_temp.mdl"
#define SOUND_FUSE "fn/welcome/fuse.wav"
#define SOUND_EXPLODE "weapons/diamond_back_01.wav"
#define SOUND_FREEZE "weapons/saxxy_impact_gen_06.wav"
#define SOUND_FUN "misc/happy_birthday_tf_13.wav"

#define BOMBTYPE_NORMAL 1
#define BOMBTYPE_TRIP 2
#define BOMBTYPE_FROST 3
#define BOMBTYPE_FIRE 4
#define BOMBTYPE_FUN 5

new bomb[MAXPLAYERS+1];
new bombColor[MAXPLAYERS+1];
new bombType[MAXPLAYERS+1];
new Float:bombPos[MAXPLAYERS+1][3];

new Handle:tripTimer[MAXPLAYERS+1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Bomb",
	author = "Pelipoika",
	description = "Bombing",
	version = "1.2.3",
	url = ""
}

public OnClientPutInServer(client)
{
	bomb[client] = 0;
}

public OnMapStart()
{
	PrecacheModel(MODEL_BOMB);
	PrecacheSound(SOUND_FUSE);
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_FUN);
}

public CreateBomb(client, type, Float:pos[3])
{
	if(bomb[client] != 0)
	{
		PrintToChat(client, "You already have a placed bomb.");
		return;
	}
	
	bombPos[client][0] = pos[0];
	bombPos[client][1] = pos[1];
	bombPos[client][2] = pos[2];
	
	decl Float:ang[3];
	ang[1] = GetRandomFloat(0.0, 360.0);
	
	bomb[client] = CreateEntityByName("prop_dynamic_override");
	SetEntityModel(bomb[client], MODEL_BOMB);
	TeleportEntity(bomb[client], pos, ang, NULL_VECTOR);
	DispatchSpawn(bomb[client]);
	SetEntityMoveType(bomb[client], MOVETYPE_NONE);
	bombColor[client] = 255;
	bombType[client] = type;
	
	switch(type)
	{
		case BOMBTYPE_NORMAL:
		{
			CreateTimer(0.1, Timer_Tick, client, TIMER_REPEAT);
			CreateTimer(1.6, Timer_Explode, client);
			EmitAmbientSound(SOUND_FUSE, pos);
		}
		case BOMBTYPE_TRIP:
		{
			tripTimer[client] = CreateTimer(0.4, Timer_TripCheck, client, TIMER_REPEAT);
		}
		case BOMBTYPE_FROST:
		{
			SetEntityRenderColor(bomb[client], 0, 128, 255, 255);
			tripTimer[client] = CreateTimer(0.4, Timer_TripCheck, client, TIMER_REPEAT);
		}
		case BOMBTYPE_FIRE:
		{
			SetEntityRenderColor(bomb[client], 255, 0, 0, 255);
			tripTimer[client] = CreateTimer(0.4, Timer_TripCheck, client, TIMER_REPEAT);
		}
		case BOMBTYPE_FUN:
		{
			SetEntityRenderColor(bomb[client], 255, 127, 127, 255);
			tripTimer[client] = CreateTimer(0.4, Timer_TripCheck, client, TIMER_REPEAT);
		}
	}
}

public Action:Timer_TripCheck(Handle:timer, any:client)
{
	decl Float:pos[3];
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(client) == GetClientTeam(i)) continue;
		
		GetClientAbsOrigin(i, pos);
		if(GetVectorDistance(pos, bombPos[client]) < 256.0)
		{
			CreateTimer(0.1, Timer_Tick, client, TIMER_REPEAT);
			CreateTimer(1.6, Timer_Explode, client);
			EmitAmbientSound(SOUND_FUSE, bombPos[client]);
			KillTimer(tripTimer[client]);
			tripTimer[client] = INVALID_HANDLE;
			
/*			if(tripTimer != INVALID_HANDLE)
			{
				KillTimer(tripTimer[client]);
				tripTimer[client] = INVALID_HANDLE;
			}*/
		}
	}
}

public Action:Command_Bomb(client, args)
{
	decl String:arg1[8];
	GetCmdArg(1, arg1, sizeof(arg1));
	new type = StringToInt(arg1);
	
	decl Float:origin[3], Float:angles[3], Float:pos[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CreateBomb(client, type, pos);
	}
	
	return Plugin_Handled;
}

public Action:Timer_Tick(Handle:timer, any:client)
{
	if(bomb[client] == 0)
	{
		KillTimer(timer);
		return;
	}
	bombColor[client] -= 16;
	SetEntityRenderColor(bomb[client], 255, bombColor[client], (bombColor[client]/2), 255);
}

public Action:Timer_Explode(Handle:timer, any:client)
{
	EmitAmbientSound(SOUND_EXPLODE, bombPos[client], _, _, _, _, 70);
	EmitAmbientSound(SOUND_EXPLODE, bombPos[client], _, _, _, _, 70);
	switch(bombType[client])
	{
		case BOMBTYPE_FUN:
		{
			CreateExplosion(bombPos[client], client, _, 0, 512);
			decl Float:pos[3];
			for(new i=1; i<=GetMaxClients(); i++)
			{
				if(!IsValidEntity(i)) continue;
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(GetClientTeam(client) == GetClientTeam(i)) continue;
				
				GetClientAbsOrigin(i, pos);
				if(GetVectorDistance(pos, bombPos[client]) < 512.0)
				{
					ClientCommand(i, "taunt");
					CreateParticle("finishline_confetti", pos);
					EmitAmbientSound(SOUND_FUN, pos);
				}
			}
		}
		case BOMBTYPE_FROST:
		{
			CreateExplosion(bombPos[client], client, _, 48, 512);
			decl Float:pos[3];
			for(new i=1; i<=GetMaxClients(); i++)
			{
				if(!IsValidEntity(i)) continue;
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(GetClientTeam(client) == GetClientTeam(i)) continue;
				
				GetClientAbsOrigin(i, pos);
				if(GetVectorDistance(pos, bombPos[client]) < 512.0)
					FreezePlayer(i, 4.0);
			}
			
		}
		case BOMBTYPE_FIRE:
		{
			CreateExplosion(bombPos[client], client, _, 48, 512);
			decl Float:pos[3];
			for(new i=1; i<=GetMaxClients(); i++)
			{
				if(!IsValidEntity(i)) continue;
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(GetClientTeam(client) == GetClientTeam(i)) continue;
				
				GetClientAbsOrigin(i, pos);
				if(GetVectorDistance(pos, bombPos[client]) < 512.0)
					TF2_IgnitePlayer(i, client);
			}
		}
		default:
		{
			CreateExplosion(bombPos[client], client, _, 192, 512);
		}
	}
	if(bomb[client] != 0)
		AcceptEntityInput(bomb[client], "Kill");
	bomb[client] = 0;	
}

public FreezePlayer(client, Float:duration)
{
	decl Float:origin[3];
	GetClientAbsOrigin(client, origin);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 128);
	CreateTimer(duration, Timer_Unfreeze, client);
	EmitAmbientSound(SOUND_FREEZE, origin);
	CreateParticle("teleportedin_blue", origin);
	CreateParticle("xms_snowburst", origin);
}

public Action:Timer_Unfreeze(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 0);
}

public Native_PlaceBomb(Handle:plugin, numParams)
{
	decl Float:pos[3];
	GetNativeArray(3, pos, 3);
	CreateBomb(GetNativeCell(1), GetNativeCell(2), pos);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("User_PlaceBomb", Native_PlaceBomb);
	return APLRes_Success;
}