#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <construct>

#define SOUND_GRAB_TF "ui/item_default_pickup.wav"      // grab
#define SOUND_TOSS_TF "ui/item_default_drop.wav"        // throw

#define SOUND_GRAB_OM "buttons/combine_button5.wav"     // grab
#define SOUND_TOSS_OM "buttons/combine_button5.wav"     // throw

#define THROW_FORCE 1000.0
#define GRAB_DISTANCE 150.0

#define PLUGIN_NAME     "Admin Player Grabber"
#define PLUGIN_AUTHOR   "Friagram"
#define PLUGIN_VERSION  "1.0.2"
#define PLUGIN_DESCRIP  "Allows Admins to Grab Players"
#define PLUGIN_CONTACT  "http://steamcommunity.com/groups/poniponiponi"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIP,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

new g_grabbedClient[MAXPLAYERS+1];              // track client's grabbed player
new Float:gDistance[MAXPLAYERS+1];              // track distance of grabbed player

new bool:g_bGameTF;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ForceDropClient", Native_ForceDrop);
	return APLRes_Success;
}

public Native_ForceDrop(Handle:plugin, numParams)
{	
	new client = GetNativeCell(1);
	if(IsValidClient(client))
		CThrowClient(client);
}

public OnPluginStart()
{
	CreateConVar("adminplayergrab_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);

	RegConsoleCmd("sm_grab", Command_Grab_Toggle, "Grab a Player");
	RegAdminCmd("sm_cgrab", Command_CGrab_Toggle, ADMFLAG_CUSTOM2);

	HookEvent("player_death", OnPlayerSpawn);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_team", OnPlayerSpawn);

	for (new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && CheckCommandAccess(client, "admin_grab", ADMFLAG_SLAY) || GetUserFlagBits(client) & ADMFLAG_CUSTOM2)
		{
			SDKHook(client, SDKHook_PreThink, OnPreThink);
		}
	}

	new String:gamedir[30];
	GetGameFolderName(gamedir, 30);
	if(StrEqual(gamedir,"tf",false))
	{
		g_bGameTF = true;
	}
	else
	{
		g_bGameTF = false;
	}
}

public OnMapStart()
{
	for (new client=1; client<=MaxClients; client++)
	{
		g_grabbedClient[client] = 0;
	}

	if(g_bGameTF)
	{
		PrecacheSound(SOUND_GRAB_TF, true);
		PrecacheSound(SOUND_TOSS_TF, true);
	}
	else
	{
		PrecacheSound(SOUND_GRAB_OM, true);
		PrecacheSound(SOUND_TOSS_OM, true);
	}
}

public OnClientPostAdminCheck(client)
{
	if(CheckCommandAccess(client, "admin_grab", ADMFLAG_SLAY) || GetUserFlagBits(client) & ADMFLAG_CUSTOM2)
	{
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
}

public OnClientPutInServer(client)
{
	g_grabbedClient[client] = 0;
}

//////////////////////////////////////////////////////////////////////
/////////////                  Commands                  /////////////
//////////////////////////////////////////////////////////////////////

public Action:Command_Grab_Toggle(client, args)
{
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetClientOfUserId(g_grabbedClient[client]) != 0)
		{
			ThrowClient(client);
		}
		else
		{
			GrabClient(client);
		}
	}

	return Plugin_Handled;
}

public Action:Command_CGrab_Toggle(client, args)
{
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetClientOfUserId(g_grabbedClient[client]) != 0)
		{
			CThrowClient(client);
		}
		else
		{
			CGrabClient(client);
		}
	}

	return Plugin_Handled;
}

CGrabClient(client)
{
	new grabbed = TraceToPlayer(client);
	if (grabbed != 0)
	{
		if(Construct_IsInZone(client) && Construct_IsInZone(grabbed))
		{
			if(GetClientButtons(client) & IN_ATTACK2)              // Store and maintain distance
			{
				decl Float:VecPos_grabbed[3], Float:VecPos_client[3];
				GetClientAbsOrigin(grabbed, VecPos_grabbed);
				GetClientEyePosition(client, VecPos_client);
				gDistance[client] = GetVectorDistance(VecPos_grabbed, VecPos_client);
			}
			else
			{
				gDistance[client] = GRAB_DISTANCE;             // Use prefab distance
			}

			SetEntityMoveType(grabbed, MOVETYPE_WALK);

			static const Float:nullVel[3] = {0.0, 0.0, 0.0};
			TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, nullVel);

			g_grabbedClient[client] = GetClientUserId(grabbed);

			if(g_bGameTF)
			{
				EmitSoundToClient(client, SOUND_GRAB_TF);
			}
			else
			{
				EmitSoundToClient(client, SOUND_GRAB_OM);
			}

			PrintHintText(client,"Grabbing %N",grabbed);
			PrintHintText(grabbed,"%N is grabbing you!",client);
		}
	}
}

CThrowClient(client)
{
	new grabbed = GetClientOfUserId(g_grabbedClient[client]);
	if(grabbed != 0)
	{
		if(g_bGameTF)
		{
			EmitSoundToClient(client, SOUND_TOSS_TF);
		}
		else
		{
			EmitSoundToClient(client, SOUND_TOSS_OM);
		}
	}
	g_grabbedClient[client] = 0;
}

GrabClient(client)
{
	new grabbed = TraceToPlayer(client);
	if (grabbed != 0)
	{
		if(GetClientButtons(client) & IN_ATTACK2)              // Store and maintain distance
		{
			decl Float:VecPos_grabbed[3], Float:VecPos_client[3];
			GetClientAbsOrigin(grabbed, VecPos_grabbed);
			GetClientEyePosition(client, VecPos_client);
			gDistance[client] = GetVectorDistance(VecPos_grabbed, VecPos_client);
		}
		else
		{
			gDistance[client] = GRAB_DISTANCE;             // Use prefab distance
		}

		SetEntityMoveType(grabbed, MOVETYPE_WALK);

		static const Float:nullVel[3] = {0.0, 0.0, 0.0};
		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, nullVel);

		g_grabbedClient[client] = GetClientUserId(grabbed);

		if(g_bGameTF)
		{
			EmitSoundToClient(client, SOUND_GRAB_TF);
		}
		else
		{
			EmitSoundToClient(client, SOUND_GRAB_OM);
		}

		PrintHintText(client,"Grabbing %N",grabbed);
		PrintHintText(grabbed,"%N is grabbing you!",client);
	}
}

ThrowClient(client)
{
	new grabbed = GetClientOfUserId(g_grabbedClient[client]);
	if(grabbed != 0)
	{
		if(GetClientButtons(client) & IN_ATTACK2)
		{
			new Float:vecView[3], Float:vecFwd[3], Float:vecPos[3], Float:vecVel[3];

			GetClientEyeAngles(client, vecView);
			GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, vecPos);

			vecPos[0]+=vecFwd[0]*THROW_FORCE;
			vecPos[1]+=vecFwd[1]*THROW_FORCE;
			vecPos[2]+=vecFwd[2]*THROW_FORCE;

			GetClientAbsOrigin(grabbed, vecFwd);

			SubtractVectors(vecPos, vecFwd, vecVel);
			ScaleVector(vecVel, 10.0);

			TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
		}        

		if(g_bGameTF)
		{
			EmitSoundToClient(client, SOUND_TOSS_TF);
		}
		else
		{
			EmitSoundToClient(client, SOUND_TOSS_OM);
		}
	}
	g_grabbedClient[client] = 0;
}

//////////////////////////////////////////////////////////////////////
/////////////                  Prethink                  /////////////
//////////////////////////////////////////////////////////////////////

public OnPreThink(client)
{
	new grabbed = GetClientOfUserId(g_grabbedClient[client]);
	if (grabbed != 0)
	{
		decl Float:vecView[3], Float:vecFwd[3], Float:vecPos[3], Float:vecVel[3];

		GetClientEyeAngles(client, vecView);
		GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);

		vecPos[0]+=vecFwd[0]*gDistance[client];
		vecPos[1]+=vecFwd[1]*gDistance[client];
		vecPos[2]+=vecFwd[2]*gDistance[client];

		GetClientAbsOrigin(grabbed, vecFwd);

		SubtractVectors(vecPos, vecFwd, vecVel);
		ScaleVector(vecVel, 10.0);

		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
	}
}

//////////////////////////////////////////////////////////////////////
/////////////                    Events                  /////////////
//////////////////////////////////////////////////////////////////////

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{               
		g_grabbedClient[client] = 0;                                    // Clear their grabs
		for(new i=1; i<=MaxClients; i++)
		{
			if(GetClientOfUserId(g_grabbedClient[i]) == client)
			{
				g_grabbedClient[i] = 0;                         // Clear grabs on them
				//return;                                       // It's possible for multiple players to grab them at once
			}
		}
	}

	return;
}

//////////////////////////////////////////////////////////////////////
/////////////                    Trace                   /////////////
//////////////////////////////////////////////////////////////////////

public TraceToPlayer(client)
{
	new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayer, client);

	if (TR_DidHit(INVALID_HANDLE))
	{
		new ent = TR_GetEntityIndex(INVALID_HANDLE);
		if(ent != 0)
		{
			return ent;
		}
	}

	return 0;
}

public bool:TraceRayPlayer(entityhit, mask, any:self) 
{
	if(entityhit > 0 && entityhit <= MaxClients && IsPlayerAlive(entityhit) && entityhit != self)
	{
		return true;
	}

	return false;
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}