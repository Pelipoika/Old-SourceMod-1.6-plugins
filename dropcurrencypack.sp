#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:hSDKDropCurrencyPack;

public OnPluginStart()
{
	//CTFPlayer::DropCurrencyPack(CurrencyRewards_t , int, CBasePlayer *)

	new Handle:hGameConf = LoadGameConfigFile("dropcurrencypack");
	if (hGameConf == INVALID_HANDLE)
	{
		SetFailState("Could not locate gamedata file dropcurrencypack.txt, pausing plugin");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "DropCurrencyPack");
	PrepSDKCall_AddParameter(SDKType_PlainOldData,	SDKPass_ByValue); 
	PrepSDKCall_AddParameter(SDKType_PlainOldData,	SDKPass_ByValue); 
	PrepSDKCall_AddParameter(SDKType_CBasePlayer,	SDKPass_Pointer);

	hSDKDropCurrencyPack = EndPrepSDKCall();
	if (hSDKDropCurrencyPack == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call to CTFPlayer::DropCurrencyPack");
	}
	
	RegConsoleCmd("sm_dropthemoni", Command_Drop, "Moni");
	HookEvent("player_death", Event_PlayerDeath);
}

public Action:Command_Drop(client, args)
{
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	//6 = Small
	//7 = Medium
	//8 = Large
	//9 = Custom
	SDKCall(hSDKDropCurrencyPack, client, 7, 25, client);
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKCall(hSDKDropCurrencyPack, client, GetRandomInt(6, 9), 25, client);
}