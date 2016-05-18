#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>

//#define SOUND_CHARGE	"npc/vort/health_charge.wav"
#define SOUND_CHARGE	"misc/doomsday_missile_launch.wav"
#define SOUND_DISAPPEAR	"misc/halloween/spell_spawn_boss_disappear.wav"
#define SOUND_APPEAR	"misc/halloween/spell_spawn_boss.wav"

#define PRTCL_DISAPPEAR	"eb_tp_escape_bits"
#define PRTCL_APPEAR	"eb_tp_normal_bits"
#define PRTCL_CHARGE	"charge_up"

new bool:g_bTeleporting[MAXPLAYERS+1];

new dFov[MAXPLAYERS+1];
new Fov[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_home", Command_Home, "Teleport to spawn");
}

public OnMapStart()
{
	PrecacheSound(SOUND_CHARGE);
	PrecacheSound(SOUND_DISAPPEAR);
	PrecacheSound(SOUND_APPEAR);
	
	PrecacheGeneric(PRTCL_DISAPPEAR);
	PrecacheGeneric(PRTCL_APPEAR);
	PrecacheGeneric(PRTCL_CHARGE);
}

public OnClientAuthorized(client)
{
	g_bTeleporting[client] = false;
	
	QueryClientConVar(client, "fov_desired", OnFOVQueried);
}

public Action:Command_Home(client, args)
{
	if(IsValidClient(client))
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) >= 2)
		{
			if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			{
				if(g_bTeleporting[client])
				{
					ReplyToCommand(client, "[SM] You are already phasing away...");
					return Plugin_Handled;
				}
				new Float:pos[3];
				GetClientAbsOrigin(client, pos);
				pos[2] += 45.0;
				
				TF2_StunPlayer(client, 99999.0, _, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
				ShowParticle(pos, PRTCL_CHARGE, 4.5);
				EmitAmbientSound(SOUND_CHARGE, pos, client, _, _, _, 150);
						
				CreateTimer(3.376, Timer_Teleport, client);
				
				g_bTeleporting[client] = true;
			}
			else
				ReplyToCommand(client, "[SM] You must be on the ground to use this.");
		}
		else
			ReplyToCommand(client, "[SM] You must be alive to use this.");
	}
	return Plugin_Handled;
}

public Action:Timer_Teleport(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{	
		CreateTimer(1.024, Timer_ToSpawn, client);
	}
}

public Action:Timer_ToSpawn(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 40.0;
		
		ShowParticle(pos, "ghost_appearation", 2.0);
		ShowParticle(pos, PRTCL_DISAPPEAR, 6.1);
		EmitAmbientSound(SOUND_DISAPPEAR, pos, client);
	
		new Handle:hFadeClient = StartMessageOne("Fade", client);
		BfWriteShort(hFadeClient, 1024)
		BfWriteShort(hFadeClient, 256)
		BfWriteShort(hFadeClient, 18)
		BfWriteByte(hFadeClient, 255)
		BfWriteByte(hFadeClient, 255)
		BfWriteByte(hFadeClient, 255)
		BfWriteByte(hFadeClient, 255)
		EndMessage()
		CreateTimer(1.024, Timer_Spawn, client);
	}
}

public Action:Timer_Spawn(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		TF2_RespawnPlayer(client);
		TF2_StunPlayer(client, 1.0, _, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
		ScreenShake(client, _, 0.5);
		
		Fov[client] = Fov[client] + 60;
		
		SetEntProp(client, Prop_Send, "m_iFOV", Fov[client]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", Fov[client]);

		SDKHook(client, SDKHook_PreThink, PerformZoom);
		
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 40.0;
		
		ShowParticle(pos, "ghost_appearation", 2.0);
		ShowParticle(pos, PRTCL_APPEAR, 6.1);
		EmitAmbientSound(SOUND_APPEAR, pos, client);
		
		new Handle:hFadeClient = StartMessageOne("Fade", client);
		BfWriteShort(hFadeClient, 128)
		BfWriteShort(hFadeClient, 204)
		BfWriteShort(hFadeClient, 1)
		BfWriteByte(hFadeClient, 255)
		BfWriteByte(hFadeClient, 255)
		BfWriteByte(hFadeClient, 255)
		BfWriteByte(hFadeClient, 100)
		EndMessage()
		
		g_bTeleporting[client] = false;
	}
}

public PerformZoom(client)
{
	if(dFov[client] >= Fov[client])	//Fov is smaller than the client default fov let's set the fov to the clients normal one.
	{
		SetEntProp(client, Prop_Send, "m_iFOV", dFov[client]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", dFov[client]);
		Fov[client] = dFov[client];	//Don't forget to reset the value
		
		SDKUnhook(client, SDKHook_PreThink, PerformZoom);
	}
	else							//Let's continue decreasing the fov.
	{
		Fov[client] = Fov[client] - 2;
		SetEntProp(client, Prop_Send, "m_iFOV", Fov[client]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", Fov[client]);
	}
}

public OnFOVQueried(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) 
{
	if(result != ConVarQuery_Okay) 
	{
		return;
	}
	
	dFov[client] = StringToInt(cvarValue);
	Fov[client] = StringToInt(cvarValue);
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	new ent = EntRefToEntIndex(particle);

	if (ent != INVALID_ENT_REFERENCE)
	{
		new String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			AcceptEntityInput(ent, "kill");
	}
}

stock ScreenShake(target, Float:intensity=30.0, Float:duration=10.0, Float:frequency=3.0)
{
    new Handle:bf; 
    if ((bf = StartMessageOne("Shake", target)) != INVALID_HANDLE)
    {
        BfWriteByte(bf, 0);
        BfWriteFloat(bf, intensity);
        BfWriteFloat(bf, duration);
        BfWriteFloat(bf, frequency);
        EndMessage();
    }
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}