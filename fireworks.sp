#include <sourcemod>
#include <sdktools>
#include <gmg\server>
#include <gmg\misc>
#pragma semicolon 1

#define SOUND_SHOOT "weapons/flare_detonator_launch.wav"
#define SOUND_SHOOT_LOW "weapons/underwater_explode3.wav"
#define SOUND_EXPLODE "weapons/flare_detonator_explode.wav"
#define SOUND_EXPLODE_LOW "weapons/explode3.wav"
//#define MUSIC_FOURTH "gmg/music/four.mp3"

new bool:show = false;
new sprites[8];

new Float:minWait = 0.4;
new Float:maxWait = 1.2;

//new Handle:hudText = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Fireworks",
	author = "Pelipoika",
	description = "Whoosh",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_fire", Command_Firework, ADMFLAG_ROOT);
	RegAdminCmd("sm_show", Command_StartShow, ADMFLAG_ROOT);
	
	sprites[0] = PrecacheModel("materials/sprites/yellowglow1.vmt");
	sprites[1] = PrecacheModel("materials/sprites/blueglow1.vmt");
	sprites[2] = PrecacheModel("materials/sprites/redglow1.vmt");
	sprites[3] = PrecacheModel("materials/sprites/greenglow1.vmt");
	sprites[4] = PrecacheModel("materials/sprites/yellowglow1.vmt");
	sprites[5] = PrecacheModel("materials/sprites/purpleglow1.vmt");
	sprites[6] = PrecacheModel("materials/sprites/orangeglow1.vmt");
	sprites[7] = PrecacheModel("materials/sprites/glow1.vmt");
	
//	hudText = CreateHudSynchronizer();
	
//	HookEvent("player_spawn", Event_Spawn);
}

public OnMapStart()
{
	/*if(!Server_IsHistorical())
		MapFX();*/
	
	PrecacheSound(SOUND_SHOOT);
	PrecacheSound(SOUND_SHOOT_LOW);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_EXPLODE_LOW);
//	PrecacheSound(MUSIC_FOURTH);
	
	//AddFileToDownloadsTable("sound/gmg/music/four.mp3");
}

public Action:Command_Firework(client, args)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	LaunchFirework(pos);
	return Plugin_Handled;
}

public Action:Command_StartShow(client, args)
{
	show = true;
//	EmitSoundToAll(MUSIC_FOURTH);
	CreateTimer(1.0, Timer_Launch);
	CreateTimer(200.0, Timer_Finale);
	CreateTimer(230.0, Timer_EndShow);
//	AddNormalSoundHook(NormalSHook:SoundHook_Normal);
	
	minWait = 0.4;
	maxWait = 1.2;
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
//		SetThirdPerson(i, 1);
	}
	return Plugin_Handled;
}

public Action:Timer_Launch(Handle:timer)
{
	decl Float:pos[3];
	if(Server_IsChambers())
	{
		switch(2)
		{
			case 1:
			{
				pos[0] = GetRandomFloat(0.0, 1.0);
				pos[1] = GetRandomFloat(0.0, 1.0);
				pos[2] = -635.0; //Y
			}
			case 2:
			{
				pos[0] = GetRandomFloat(-790.0, 790.0);
				pos[1] = GetRandomFloat(-5480.0, 140.0);
				pos[2] = -3416.0; //Z
			}
			case 3:
			{
				pos[0] = GetRandomFloat(0.0, 1.0);
				pos[1] = GetRandomFloat(0.0, 1.0);
				pos[2] = -635.0; //X
			}
		}
	}
//	else if(Server_IsTunnels()) [SM] Your location is currently X = -859, Y = -608, Z = -3451
//	{
//		pos[0] = GetRandomFloat(-1000.0, 480.0);
//		pos[1] = GetRandomFloat(-400.0, 1500.0);
//		pos[2] = 64.0;
//	}
	LaunchFirework(pos);
	
	if(show)
		CreateTimer(GetRandomFloat(minWait, maxWait), Timer_Launch);
}

/*public Action:SoundHook_Normal(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrEqual(sample, SOUND_EXPLODE) || StrEqual(sample, SOUND_SHOOT) || StrEqual(sample, MUSIC_FOURTH))
		return Plugin_Continue;
	
	volume = 0.2;
	return Plugin_Changed;
}*/

public Action:Timer_Finale(Handle:timer)
{
	minWait = 0.1;
	maxWait = 0.2;
}

public Action:Timer_EndShow(Handle:timer)
{
	show = false;
//	RemoveNormalSoundHook(SoundHook_Normal);
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
//		SetThirdPerson(i, 0);
		
//		SetHudTextParams(0.133, 0.9, 3.0, 255, 128, 0, 255);
//		SetHudTextParams(-1.0, 0.3, 7.0, 255, 128, 64, 255, _, _, 1.0, 1.0);
//		ShowSyncHudText(i, hudText, "Happy Fourth of July, %N!", i);
	}
}

LaunchFirework(Float:pos[3])
{	
	CreateParticle("ghost_smoke", pos);
	new ent = CreateEntityByName("tf_projectile_rocket");
	if(ent)
	{
		decl Float:ang[3] = {-90.0, 0.0, 0.0}, Float:buf[3], Float:vel[3];
		GetAngleVectors(ang, buf, NULL_VECTOR, NULL_VECTOR);
		
		for(new i=0; i<=2; i++)
			vel[i] = buf[i] * GetRandomFloat(512.0, 768.0);
			
		if (IsValidEntity(ent))
		{
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", 0);
			SetEntPropEnt(ent, Prop_Send, "m_bCritical", 1);
			SetEntPropEnt(ent, Prop_Send, "m_iTeamNum", 1);
			SetEntProp(ent, Prop_Send, "m_nSolidType", 0);
			SetEntData(ent, FindSendPropOffs("CTFProjectile_Rocket", "m_nSkin"), 3, 1, true);
			SetEntDataFloat(ent, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, 1.0, true);
			TeleportEntity(ent, pos, ang, vel);
			SetVariantInt(1);
			AcceptEntityInput(ent, "TeamNum");
			SetVariantInt(1);
			AcceptEntityInput(ent, "SetTeam");
			DispatchSpawn(ent);
			
			CreateTimer(GetRandomFloat(1.2, 2.6), Timer_Explode, ent);
			EmitAmbientSound(SOUND_SHOOT, pos, ent, _, _, 0.4, GetRandomInt(80, 120));
			EmitAmbientSound(SOUND_SHOOT_LOW, pos, ent, _, _, _, GetRandomInt(40, 60));
		}
	}
}

public Action:Timer_Explode(Handle:timer, any:ent)
{
	if(IsValidEntity(ent))
	{
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		for(new i=1; i<=5; i++)
		{
			EmitAmbientSound(SOUND_EXPLODE, pos, ent, _, _, _, GetRandomInt(80, 100));
			EmitAmbientSound(SOUND_EXPLODE_LOW, pos, ent, _, _, _, GetRandomInt(40, 60));
			CreateParticle("ExplosionCore_MidAir", pos);
		}
		
		new Handle:pack;
		CreateDataTimer(0.1, Timer_Fx, pack);
		WritePackFloat(pack, pos[0]);
		WritePackFloat(pack, pos[1]);
		WritePackFloat(pack, pos[2]);
	
		AcceptEntityInput(ent, "Kill");
	}
}

public Action:Timer_Fx(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	decl Float:pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	ColorFX(pos);
	
}

/*public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	if(show)
//		SetThirdPerson(client, 1);	
}*/

ColorFX(Float:pos[3])
{
	new Float:rPos[3], Float:sPos[3];
	new Float:radius = 350.0, Float:phi, Float:theta, Float:live, Float:size, Float:delay, brightness;
	new color = GetRandomInt(0, 7);
	for(new i=0; i<256; i++)
	{
		delay = GetRandomFloat(0.0, 0.2);
		brightness = GetRandomInt(128, 255);
		live = 3.0 + delay;
		size = GetRandomFloat(0.2,1.4);
		phi = GetRandomFloat(0.0,6.283185);
		theta = GetRandomFloat(0.0,6.283185);
		sPos[0] = radius*Sine(phi)*Cosine(theta);
		sPos[1] = radius*Sine(phi)*Sine(theta);
		sPos[2] = radius*Cosine(phi);
		rPos[0] = pos[0] + sPos[0];
		rPos[1] = pos[1] + sPos[1];
		rPos[2] = pos[2] + sPos[2];
		
		if(GetRandomInt(1, 2) == 1)
			TE_SetupGlowSprite(rPos, sprites[GetRandomInt(0, 7)], live, size, brightness);
		else
			TE_SetupGlowSprite(rPos, sprites[color], live, size, brightness);
		TE_SendToAll(delay);
	}
}

/*MapFX()
{
	DispatchKeyValue(0, "skyname", "sky_halloween");
	
	new ent = FindEntityByClassname(-1, "env_fog_controller");
	DispatchKeyValue(ent, "fogcolor", "0 0 0");
	
	SetLightStyle(0, "i");
}*/

public Native_Firework(Handle:plugin, numParams)
{
	decl Float:pos[3];
	GetClientEyePosition(GetNativeCell(1), pos);
	LaunchFirework(pos);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("User_Firework", Native_Firework);
	return APLRes_Success;
}