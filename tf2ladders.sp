#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define SOUND_STEP	"player/footsteps/concrete4.wav"

new bool:soundCooldown[MAXPLAYERS+1];
new onLadder[MAXPLAYERS+1];
new Float:lastZ[MAXPLAYERS+1];

new Float:ladderlocations[][] =
{
	{3532.0, -5110.0, 1004.0},
	{-40.0, -2973.5, 1.5},
	{4999.5, -3618.0, 638.0},
	{3576.0, -4335.5, -274.0},
	{5160.5, -4980.0, 980.0},
	{2400.5, -3126.0, 284.0},
	{4944.0, -4350.0, 212.83},
	{3946.57, -2495.16, 128.0},
	{3780.0, -1192.5, 160.0},
	{-464.0, -3432.51, -368.0},
	{3343.5, -552.0, 344.0},
	{3244.0, -624.5, 210.0},
	{108.5, -3008.0, 228.0},
	{3532.0, -4914.0, 1004.0},
	{3526.0, -4617.0, 1004.0},
	{2572.0, -980.5, 994.0},
	{4724.0, -4542.0, 170.55},
	{4999.5, -3812.0, 170.0},
	{3119.5, -576.0, 536.0},
	{2807.5, -240.0, 580.0},
	{3479.5, -1120.0, 220.0},
	{2840.0, -1180.5, 174.6},
	{3918.0, -4612.0, 144.0},
	{5324.0, -767.5, 976.0},
	{4816.0, -2463.5, 404.0},
	{3768.0, -1879.5, 427.98},
	{5324.0, -4812.5, 974.0},
	{371.49, -3151.99, 496.0},
	{1048.0, -3327.5, 556.0},
	{-464.01, -3432.51, -368.0},
	{5200.5, -3048.5, 506.0},
	{1048.0, -3327.5, 556.01},
	{3918.0, -4612.0, 144.0},
	{3526.0, -4617.0, 1004.0},
	{4670.33, -1412.43, 172.0}
};

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("teamplay_round_start", Event_OnRoundStart);
}

public OnMapStart()
{
	//LogMessage("Map Start");
	PrecacheSound(SOUND_STEP, true);
	PrecacheModel("models/props_hydro/barrel_crate_half.mdl");
}

public OnClientDisconnect(client)
	onLadder[client] = 0;

public Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrEqual(MapName, "zm_Zelda_OoT_Forest_TempleV2"))
	{
		decl Float:vPos[3], Float:vMins[3], Float:vMaxs[3];

		new ladder = -1;
		while ((ladder = FindEntityByClassname(ladder, "func_*")) != -1)
		{
			if (IsValidEntity(ladder))
			{
				GetEntPropVector(ladder, Prop_Send, "m_vecOrigin", vPos);
				
				for(new i = 0; i < sizeof(ladderlocations); i++)
				{
					if(vPos[0] == ladderlocations[i][0] && vPos[1] == ladderlocations[i][1] && vPos[2] == ladderlocations[i][2])
					{
					//	PrintToChatAll("func_illusionary location matched ladderlocations");
						
						GetEntPropVector(ladder, Prop_Send, "m_vecMaxs", vMaxs);
						GetEntPropVector(ladder, Prop_Send, "m_vecMins", vMins);

						CreateTriggerMultiple(vPos, vMaxs, vMins);
					}
				}
			}
		}
	}
}

CreateTriggerMultiple(Float:vPos[3], Float:vMaxs[3], Float:vMins[3])
{
	new trigger = CreateEntityByName("trigger_multiple");

	DispatchKeyValue(trigger, "targetname", "ladder");
	DispatchKeyValue(trigger, "StartDisabled", "0");
	DispatchKeyValue(trigger, "spawnflags", "1");
	
	DispatchKeyValueVector(trigger, "origin", vPos);
	
	DispatchSpawn(trigger);	
	SetEntityModel(trigger, "models/props_hydro/barrel_crate_half.mdl");
	
	new Float:flExpansion = 5.0;
	
	if(vMaxs[0] <= 0)
		vMaxs[0] -= flExpansion;
	else if(vMaxs[0] > 0)
		vMaxs[0] += flExpansion;
	if(vMaxs[1] <= 0)
		vMaxs[1] -= flExpansion;
	else if(vMaxs[1] > 0)
		vMaxs[1] += flExpansion;
		
	if(vMins[0] <= 0)
		vMins[0] -= flExpansion;
	else if(vMins[0] > 0)
		vMins[0] += flExpansion;
	if(vMins[1] <= 0)
		vMins[1] -= flExpansion;
	else if(vMins[1] > 0)
		vMins[1] += flExpansion;
	
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vMaxs);
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", vMins);
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);

	AcceptEntityInput(trigger, "Enable");

	HookSingleEntityOutput(trigger, "OnStartTouch", StartTouchTrigger);
	HookSingleEntityOutput(trigger, "OnEndTouch", EndTouchTrigger);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	onLadder[client] = 0;
}

public StartTouchTrigger(const String:name[], caller, activator, Float:delay)
{
//	PrintToChatAll("StartTouchTrigger");

	decl String:entityName[32];
	GetEntPropString(caller, Prop_Data, "m_iName", entityName, sizeof(entityName));

	if(StrContains(entityName, "ladder") != -1) 
	{
		// Occasionally I get 2 StartTouchTrigger events before an EndTouchTrigger when 
		// 2 ladders are placed close together.  The onLadder accumulator works around this. 
		if (++onLadder[activator] == 1) 
		{
			//LogMessage("Client %i: StartTouch %i", activator, onLadder[activator]);
			MountLadder(activator);
		}
	}
}

public EndTouchTrigger(const String:name[], caller, activator, Float:delay)
{
//	PrintToChatAll("EndTouchTrigger");

	decl String:entityName[32];
	GetEntPropString(caller, Prop_Data, "m_iName", entityName, sizeof(entityName));

	if(StrContains(entityName, "ladder") != -1) 
	{
		// Occasionally I get 2 StartTouchTrigger events before an EndTouchTrigger when 
		// 2 ladders are placed close together.  The onLadder accumulator works around this. 
		if (--onLadder[activator] <= 0) 
		{
			//LogMessage("Client %i: EndTouch %i", activator, onLadder[activator]);
			DismountLadder(activator);
		}
	}
}

MountLadder(client)
{
	//LogMessage("Client %i: MountLadder", client);

	//SetEntityMoveType(client, MOVETYPE_NONE);
	//SetEntityMoveType(client, MOVETYPE_FLY);
	//SetEntPropFloat(client, Prop_Data, "m_flFriction", 0.0,01);
	SetEntityGravity(client, 0.001);

	SDKHook(client, SDKHook_PreThink, MoveOnLadder);
}

DismountLadder(client)
{
	//LogMessage("Client %i: DismountLadder", client);

	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropFloat(client, Prop_Data, "m_flFriction", 1.0,);
	SetEntityGravity(client, 1.0);
	SDKUnhook(client, SDKHook_PreThink, MoveOnLadder);
}

PlayClimbSound(client)
{
	if(soundCooldown[client])
		return;

	EmitSoundToClient(client, SOUND_STEP);

	soundCooldown[client] = true;
	CreateTimer(0.35, Timer_Cooldown, client);
}

public Action:Timer_Cooldown(Handle:timer, any:client)
{
	soundCooldown[client] = false;
}

public MoveOnLadder(client)
{
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");

	decl buttons;
	buttons = GetClientButtons(client);

	decl Float:origin[3];
	GetClientAbsOrigin(client, origin);
	
	new bool:movingUp = (origin[2] > lastZ[client]);
	lastZ[client] = origin[2];

	decl Float:angles[3];
	GetClientEyeAngles(client, angles);

	decl Float:velocity[3];

	if(buttons & IN_FORWARD || buttons & IN_JUMP) 
	{
		velocity[0] = speed * Cosine(DegToRad(angles[1]));
		velocity[1] = speed * Sine(DegToRad(angles[1]));
		velocity[2] = -1 * speed * Sine(DegToRad(angles[0]));
		
		// Soldier and heavy do not achieve the required velocity to get off the 
		// ground.  The calculation below provides a boost when necessary.
		if (!movingUp && angles[0] < -25.0 && velocity[2] > 0 && velocity[2] < 250.0) {
			//LogMessage("Client %i: BOOST", client);
			// is friction on different surfaces an issue?
			velocity[2] = 251.0;
		}
		
		//LogMessage("Client %i: Forward %f %f", client, angles[0], velocity[2]);
		PlayClimbSound(client);
	} 
	else if(buttons & IN_MOVELEFT) 
	{
		velocity[0] = speed * Cosine(DegToRad(angles[1] + 45));
		velocity[1] = speed * Sine(DegToRad(angles[1] + 45));
		velocity[2] = -1 * speed * Sine(DegToRad(angles[0]));
		
		//LogMessage("Client %i: Left", client);
		PlayClimbSound(client);
	} 
	else if(buttons & IN_MOVERIGHT) 
	{
		velocity[0] = speed * Cosine(DegToRad(angles[1] - 45));
		velocity[1] = speed * Sine(DegToRad(angles[1] - 45));
		velocity[2] = -1 * speed * Sine(DegToRad(angles[0]));
		
		//LogMessage("Client %i: Right", client);
		PlayClimbSound(client);
	} 
	else if(buttons & IN_BACK) 
	{
		velocity[0] = -1 * speed * Cosine(DegToRad(angles[1]));
		velocity[1] = -1 * speed * Sine(DegToRad(angles[1]));
		velocity[2] = speed * Sine(DegToRad(angles[0]));

		//LogMessage("Client %i: Backwards", client);
		PlayClimbSound(client);
	} 
	else 
	{
		velocity[0] = 0.0;
		velocity[1] = 0.0;
		velocity[2] = 0.0;
	
		//LogMessage("Client %i: Hold", client);
	}
	
	TeleportEntity(client, origin, NULL_VECTOR, velocity);
}