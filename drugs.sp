#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <tf2>
#include <gmg\misc>
#include <gmg\users>
#pragma semicolon 1

#define SOUND_DRUGS_MUSH "vo/announcer_am_lastmanforfeit03.wav"
#define SOUND_DRUGS_CHEAP "fn/welcome/crown_song01.mp3"
#define SOUND_DRUGS_EXPENSIVE "fn/welcome/music/crown_song02.mp3"

public Plugin:myinfo = 
{
	name = "Drugs",
	author = "pelipoika",
	description = "All of you think your better than me but im tha best aroused men",
	version = "1.0",
	url = ""
}

public OnMapStart()
{
	PrecacheSound(SOUND_DRUGS_MUSH);
	PrecacheSound(SOUND_DRUGS_CHEAP);
	PrecacheSound(SOUND_DRUGS_EXPENSIVE);
}

public OnDrugMushThink(client)
{
	SetEntityRenderColor(client, GetRandomInt(128, 255), GetRandomInt(128, 255), GetRandomInt(128, 255), 255);
	
	Client_Shake(client, _, 2.0, _, 1.0);
	Client_ScreenFade(client, 100, FFADE_OUT, 1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 128);
}

public OnDrugCheapThink(client)
{
	SetEntityRenderColor(client, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
	Client_Shake(client, _, 8.0, _, 1.0);
	Client_ScreenFade(client, 100, FFADE_OUT, 1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 128);
	Client_SetFOV(client, GetRandomInt(20, 70));
	Client_AddButtons(client, IN_ATTACK);
}

public OnDrugExpensiveThink(client)
{
	SetEntityRenderColor(client, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
	Client_Shake(client, _, 8.0, _, 1.0);
	Client_ScreenFade(client, 100, FFADE_OUT, 1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 800.0);	
}

public Action:Timer_DrugsMushEnd(Handle:timer, any:client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SDKUnhook(client, SDKHook_PreThink, OnDrugMushThink);
	Client_ScreenFade(client, 1, FFADE_IN, 1, _, _, _, 0);
	Client_SetDrawViewModel(client, true);
	ForcePlayerSuicide(client);
}

public Action:Timer_DrugsCheapEnd(Handle:timer, any:client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SDKUnhook(client, SDKHook_PreThink, OnDrugCheapThink);
	Client_ScreenFade(client, 1, FFADE_IN, 1, _, _, _, 0);
	Client_SetFOV(client, 90);
	Client_SetDrawViewModel(client, true);
	ForcePlayerSuicide(client);
}

public Action:Timer_DrugsExpensiveEnd(Handle:timer, any:client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SDKUnhook(client, SDKHook_PreThink, OnDrugExpensiveThink);
	Client_ScreenFade(client, 1, FFADE_IN, 1, _, _, _, 0);
	Client_SetFOV(client, 90);
	Client_SetDrawViewModel(client, true);
	ForcePlayerSuicide(client);
}

TakeDrug(client, type)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	CreateParticle("ghost_smoke", pos);
	
	if(type == 1)
	{
		SDKHook(client, SDKHook_PreThink, OnDrugMushThink);
		CreateTimer(8.0, Timer_DrugsMushEnd, client);
		Client_SetDrawViewModel(client, false);
		
		EmitAmbientSound(SOUND_DRUGS_MUSH, pos, client, _, _, _, 50);
	}
	if(type == 2)
	{
		SDKHook(client, SDKHook_PreThink, OnDrugCheapThink);
		CreateTimer(25.0, Timer_DrugsCheapEnd, client);
		Client_SetDrawViewModel(client, false);
		for(new i=0; i<=5; i++)
			EmitSoundToClient(client, SOUND_DRUGS_CHEAP, _, _, _, _, _, 75);
		
		EmitAmbientSound(SOUND_DRUGS_CHEAP, pos, client, _, _, _, 75);
	}
	else if(type == 3)
	{
		SDKHook(client, SDKHook_PreThink, OnDrugExpensiveThink);
		CreateTimer(25.0, Timer_DrugsExpensiveEnd, client);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 25.0);
		TF2_AddCondition(client, TFCond_TeleportedGlow, 25.0);
		TF2_AddCondition(client, TFCond_DefenseBuffed, 25.0);
		Client_SetFOV(client, 150);
		Client_SetDrawViewModel(client, false);
		
		for(new i=0; i<=5; i++)
			EmitSoundToClient(client, SOUND_DRUGS_EXPENSIVE, _, _, _, _, _, 75);
		
		EmitAmbientSound(SOUND_DRUGS_EXPENSIVE, pos, client, _, _, _, 75);
	}
}


public Native_TakeDrug(Handle:plugin, numParams)
{
	TakeDrug(GetNativeCell(1), GetNativeCell(2));
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("User_TakeDrug", Native_TakeDrug);
	return APLRes_Success;
}