#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <morecolors>

#pragma semicolon 1

#define EVOLTYPE_ADMIN		1
#define EVOLTYPE_VIP		2
#define EVOLTYPE_DEMOTION	3

#define SOUND_CUE		"fn/welcome/cue.wav"
#define SOUND_SONG		"fn/welcome/tune.mp3"
#define SOUND_DONE		"fn/welcome/complete.wav"
#define SOUND_DEMOTION	"fn/welcome/complete_demotion.wav"
#define SOUND_FAIL		"items/cart_warning_single.wav"

#define POSITION_EVOLVE {897.0, -529.0, 140.0}

new bool:evolving[MAXPLAYERS+1];
new evolutionType[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Evolution",
	author = "Pelipoika",
	description = "Pokaymawn",
	version = "1.1.1",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_evolve", Command_Evolve, ADMFLAG_ROOT);
	HookEvent("player_death", Event_Death);
}

public OnMapStart()
{
	PrecacheSound(SOUND_CUE);
	PrecacheSound(SOUND_SONG);
	PrecacheSound(SOUND_DONE);
	PrecacheSound(SOUND_FAIL);
	PrecacheSound(SOUND_DEMOTION);
}

public Action:Command_Evolve(client, args)
{
	decl String:arg1[64], String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
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
		Evolve(target_list[i], StringToInt(arg2));
	}	
	return Plugin_Handled;
}

public Evolve(client, type)
{
	EmitSoundToAll(SOUND_CUE);
	CPrintToChatAllEx(client, "What's this? {teamcolor}%N{default} is {green}ascending!", client);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	TF2_StunPlayer(client, 19.0, 0.0, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
	decl Float:pos[3] = POSITION_EVOLVE;
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	evolutionType[client] = type;
	
	CreateTimer(1.0, Timer_Begin, client);
}

EndEvolution(client)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		StopSound(i, SNDCHAN_AUTO, SOUND_SONG);
	}
	CPrintToChatAllEx(client, "{teamcolor}%N's{default} ascension was interrupted.", client);
	EmitSoundToAll(SOUND_FAIL);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	evolving[client] = false;
}

public Action:Timer_Begin(Handle:timer, any:client)
{
	evolving[client] = true;
	EmitSoundToAll(SOUND_SONG);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	CreateTimer(18.0, Timer_End, client);

}

public OnPreThink(client)
{
	decl Float:pos[3], Float:ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	pos[2] += 0.2;
	ang[1] += 0.4;
	TeleportEntity(client, pos, ang, NULL_VECTOR);
	
	static Float:flLastCall;
	if(GetEngineTime() - 4.0 <= flLastCall)
		return;
	
	flLastCall = GetEngineTime();
	
	AttachParticle(client, "god_rays");
}

public Action:Timer_End(Handle:timer, any:client)
{
	if(!evolving[client]) return;
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	ServerCommand("sm_reloadadmins");
	ServerCommand("sm_reloadccc");

	switch(evolutionType[client])
	{
		case EVOLTYPE_ADMIN:
		{
			CPrintToChatAllEx(client, "Congratulations! {teamcolor}%N{default} has ascended to the {green}MODERATOR{default} Masterrace!", client);
			EmitSoundToAll(SOUND_DONE);
			TF2_AddCondition(client, TFCond_Ubercharged, 10.0);
		}
		case EVOLTYPE_VIP:
		{
			CPrintToChatAllEx(client, "Congratulations! {teamcolor}%N{default} has ascended to the {green}VIP{default} {unique}Masterrace!", client);
			EmitSoundToAll(SOUND_DONE);
			TF2_AddCondition(client, TFCond_Ubercharged, 10.0);
			CPrintToChat(client, "Congratulations {teamcolor}%N{default} Now that you are a part of the {unique}GLORIOUS {green}VIP{default} masterrace, why don't you look at all the awesome stuff you were just granted! With {unique}!donator", client);
		}
		case EVOLTYPE_DEMOTION:
		{
			CPrintToChatAllEx(client, "{teamcolor}%N{default} was {green}DEMOTED", client);
			EmitSoundToAll(SOUND_DEMOTION);
			ClientCommand(client, "explode");
		}
	}
	evolving[client] = false;
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