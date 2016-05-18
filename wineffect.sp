#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <morecolors>

#pragma semicolon 1

#define SOUND_CUE		"ui/holiday/gamestartup_saxxy.mp3"
#define SOUND_FAIL		"items/cart_warning_single.wav"

new bool:evolving[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[TF2] Win effect thing",
	author = "Pelipoika",
	description = " I dont know.",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Pelipoika&description=&search=1"
}

public OnPluginStart()
{
	RegAdminCmd("sm_winner", Command_Evolve, ADMFLAG_ROOT);
	HookEvent("player_death", Event_Death);
}

public OnMapStart()
{
	PrecacheSound(SOUND_CUE);
	PrecacheSound(SOUND_FAIL);
	PrecacheGeneric("god_rays");
}

public Action:Command_Evolve(client, args)
{
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i=0; i<target_count; i++)
	{
		if(IsPlayerAlive(target_list[i]))
			Evolve(target_list[i]);
	}	
	return Plugin_Handled;
}

public Evolve(client)
{
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 265.0;
	
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	EmitSoundToAll(SOUND_CUE);	//play sound on activation: "Saxxy Theme" ui/holiday/gamestartup_saxxy.mp3

	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);
	SetEntProp(client, Prop_Data, "m_takedamage", 0);	//set player in godmode
	
	TF2_StunPlayer(client, 18.5, 0.0, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT);	//user has bonk effect applied, remove sound + bonk particle so just the bonk animation like your !home plugin.
	
	evolving[client] = true;
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	CreateTimer(18.0, Timer_End, client);
}

EndEvolution(client)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		StopSound(i, SNDCHAN_AUTO, SOUND_CUE);
	}
	CPrintToChatAllEx(client, "{teamcolor}%N's{default} descension was interrupted.", client);
	EmitSoundToAll(SOUND_FAIL);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	evolving[client] = false;
}

public OnPreThink(client)	//user slowly descends towards the ground
{
	decl Float:pos[3], Float:ang[3];
	GetClientAbsOrigin(client, pos);
	SpawnFlyingBirdRandom(pos);
	GetClientAbsAngles(client, ang);
	pos[2] -= 0.2;
	ang[1] += 0.4;
	TeleportEntity(client, pos, ang, NULL_VECTOR);
	
	static Float:flLastCall;
	if(GetEngineTime() - 4.0 <= flLastCall)
		return;
	
	flLastCall = GetEngineTime();
	
	AttachParticle(client, "god_rays");
}

public Action:Timer_End(Handle:timer, any:client)	//when user reaches ground remove godmode and all effects.
{
	if(!evolving[client]) return;
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);

	TF2_AddCondition(client, TFCond_Ubercharged, 10.0);
	CPrintToChatAllEx(client, "{teamcolor}%N{default} is the {green}Winner{default}!", client);	//Print to chat: %N is The Winner!
			
	evolving[client] = false;
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		StopSound(i, SNDCHAN_AUTO, SOUND_CUE);
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(evolving[client]) EndEvolution(client);
}

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flZOffset=0.0, Float:flSelfDestruct=0.0) 
{ 
	new iParticle = CreateEntityByName("info_particle_system"); 
	if( !IsValidEdict(iParticle) ) 
		return 0; 
	 
	new Float:flPos[3]; 
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos); 
	flPos[2] += flZOffset; 
	 
	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR); 
	 
	DispatchKeyValue(iParticle, "effect_name", strParticleEffect); 
	DispatchSpawn(iParticle); 
	 
	SetVariantString("!activator"); 
	AcceptEntityInput(iParticle, "SetParent", iEntity); 
	ActivateEntity(iParticle); 
	 
	if(strlen(strAttachPoint)) 
	{ 
		SetVariantString(strAttachPoint); 
		AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset"); 
	} 
	 
	AcceptEntityInput(iParticle, "start"); 
	 
	if(flSelfDestruct > 0.0)
		CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle)); 
	 
	return iParticle; 
}

public Action:Timer_DeleteParticle(Handle:hTimer2, any:iRefEnt) 
{ 
    new iEntity = EntRefToEntIndex(iRefEnt); 
    if(iEntity > MaxClients) 
        AcceptEntityInput(iEntity, "Kill"); 
     
    return Plugin_Handled; 
}

stock SpawnFlyingBirdRandom(Float:vec[3])
{
	new Handle:message = StartMessageAll("SpawnFlyingBird");
	BfWriteVecCoord(message, vec);
	BfWriteFloat(message, GetRandomFloat(-3.0, 3.0));			//yaw
	BfWriteFloat(message, GetRandomFloat(-1.0, 1.0));			//yaw rate
	BfWriteFloat(message, GetRandomFloat(0.5, 2.0));			//Curve up rate
	BfWriteFloat(message, GetRandomFloat(300.0, 500.0));		//speed
	BfWriteFloat(message, GetRandomFloat(0.0, 1.0));			//time til starts flapping
	EndMessage();
}