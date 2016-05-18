#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>
#pragma semicolon 1

#define SOUND_HURT "fn/harvest/murder.wav"
#define SOUND_SCARE1 "fn/harvest/scare1.wav"
#define SOUND_SCARE2 "fn/harvest/scare2.wav"
#define SOUND_SCREAM1 "fn/harvest/scream1.wav"
#define SOUND_SCREAM2 "fn/harvest/scream2.wav"

new kills = 0;

new const String:chambersFiles[][] =
{
	"materials/fn/harvest/treadmill.vmt",
	"materials/fn/harvest/treadmill_slow.vmt",
	"sound/fn/harvest/murder.wav",
	"sound/fn/harvest/scare1.wav",
	"sound/fn/harvest/scare2.wav",
	"sound/fn/harvest/scream1.wav",
	"sound/fn/harvest/scream2.wav",
	"harvest.raw"
};

public Plugin:myinfo = 
{
	name = "Tunnels",
	author = "Pelipoika",
	description = "Scawy",
	version = "1.1.2",
	url = ""
}

public OnPluginStart()
{
	CreateTimer(30.0, Timer_Calc, _, TIMER_REPEAT);
	CreateTimer(1800.0, Timer_Horsemann, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_start", Event_Round);
}

public Action:Timer_Horsemann(Handle:timer)
{
	if(GetClientCount(true) > 1)
	{
		new ent = CreateEntityByName("headless_hatman");
		//if(GetRandomInt(1, 2) == 1) ent = CreateEntityByName("eyeball_boss");
		new Float:pos[3] = {-366.0, 590.0, 16.0};
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Timer_Calc(Handle:timer, any:client)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		decl Float:pos[3];
		GetClientAbsOrigin(i, pos);
		if(pos[2] >= -256.0) continue;
		
		new random = GetRandomInt(1, 16);			
		switch(random)
		{
			case 1: Scare(i);
			case 2: ClientCommand(i, "sm_possess");
			case 3: EmitSoundToClient(i, SOUND_SCARE1);
			case 4: EmitSoundToClient(i, SOUND_SCARE2);
			case 5: EmitSoundToClient(i, SOUND_SCREAM1);
			case 6: EmitSoundToClient(i, SOUND_SCREAM2);
		}
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_HURT);
	PrecacheSound(SOUND_SCARE1);
	PrecacheSound(SOUND_SCARE2);
	PrecacheSound(SOUND_SCREAM1);
	PrecacheSound(SOUND_SCREAM2);
	
	for(new i=0; i<sizeof(chambersFiles); i++)
	{
		PrecacheGeneric(chambersFiles[i]);
		AddFileToDownloadsTable(chambersFiles[i]);
	}
}

public Action:Event_Round(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:className[64], String:entname[64];
	for(new i=1; i<=GetMaxEntities(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, className, sizeof(className));
			if(StrEqual(className, "trigger_teleport"))
			{
				GetEntPropString(i, Prop_Data, "m_iName", entname, sizeof(entname));
				if(StrEqual(entname, "mpex_trig", true)) 
				{
					//PrintToChatAll("removeD");
					RemoveEdict(i);
				}
			}
		}
	}
}

Scare(client)
{
	new random = GetRandomInt(1, 2);
	switch(random)
	{
		case 1: EmitSoundToClient(client, SOUND_SCREAM1);
		case 2: EmitSoundToClient(client, SOUND_SCREAM2);
	}
	Client_Shake(client, _, 96.0, 128.0, 4.0);
	ClientCommand(client, "r_screenoverlay effects/red");
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	CreateTimer(2.0, Timer_Murder, client);
}


public Action:Timer_Murder(Handle:timer, any:client)
{
	EmitSoundToClient(client, SOUND_HURT);
	CreateTimer(0.2, Timer_Sound, client);
}

public Action:Timer_Sound(Handle:timer, any:client)
{
	EmitSoundToClient(client, SOUND_SCARE1);
	Entity_Hurt(client, 9999, _, DMG_ACID);
	ClientCommand(client, "r_screenoverlay 0");
	kills++;
	
	new const String:killText[][] =
	{
		"slaughtered",
		"murdered",
		"mauled",
		"massacred",
		"wiped out",
		"decimated",
		"mangled",
		"wrecked",
		"raped",
		"fucked up"
	};
	CPrintToChatAllEx(client, "{teamcolor}%N{default} was %s by {olive}The Dystopian", client, killText[GetRandomInt(0, sizeof(killText)-1)]);
	CreateTimer(2.0, Timer_Stats, client);
}

public Action:Timer_Stats(Handle:timer, any:client)
{
	CPrintToChatAll("{olive}The Dystopian{default} has taken {green}%i{default} %s", kills, (kills == 1) ? "life" : "lives");
}