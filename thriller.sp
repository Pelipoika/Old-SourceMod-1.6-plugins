#pragma semicolon 1
#include <sourcemod>
#include <tf2>

#define SOUND_THRILL "misc/halloween/hwn_dance_loop.wav"

new Handle:g_hConVar_Taunt = INVALID_HANDLE;

public OnPluginStart() 
{
    g_hConVar_Taunt = CreateConVar("sm_taunt_thrill", "1", "Apply thriller while taunting", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

public OnMapStart() 
{
    PrecacheSound(SOUND_THRILL);
}

public TF2_OnConditionAdded(iClient, TFCond:iCond) 
{
    if(!GetConVarBool(g_hConVar_Taunt)) return;
    if(iClient <= 0 || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) return;
    if(iCond == TFCond_Taunting) 
	{
        TF2_RemoveCondition(iClient, TFCond_Taunting);
        TF2_AddCondition(iClient, TFCond_HalloweenThriller, 2.0);
        FakeClientCommand(iClient, "taunt");
    }
}  