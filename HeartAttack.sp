#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#pragma semicolon 1

new SandvichesEaten[MAXPLAYERS +1] = 10;
new Float:flSoundDuration = 8.0;

#define SND_HEARTBEAT	"player/heartbeat1.wav"

static const String:strCloseCalls[][64] = 
{
	"vo/heavy_mvm_close_call01.wav",
	"vo/heavy_mvm_close_call02.wav"
};

static const String:strHeartPain[][64] = 
{
	"vo/heavy_painsharp01.wav",
	"vo/heavy_painsharp02.wav",
	"vo/heavy_painsharp03.wav",
	"vo/heavy_painsharp04.wav",
	"vo/heavy_painsharp05.wav"
};

static const String:strDontFeelGood[][64] = 
{
	"vo/heavy_sf12_badmagic07.wav",
	"vo/heavy_sf12_badmagic08.wav"
};

public OnPluginStart()
{
	HookEvent("player_death", OnPlayerSpawn);
}

public OnMapStart() 
{
	PrecacheSounds(strCloseCalls, sizeof(strCloseCalls));
	PrecacheSounds(strHeartPain, sizeof(strHeartPain));
	PrecacheSounds(strDontFeelGood, sizeof(strDontFeelGood));
	PrecacheSound(SND_HEARTBEAT);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client))
	{
		SandvichesEaten[client] = 10;
		StopSound(client, SNDCHAN_AUTO, SND_HEARTBEAT);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)	//Sanvich detection
{
	if (condition == TFCond_Taunting && TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		decl String:wep[64];
		GetClientWeapon(client, wep, sizeof(wep));
		if (strcmp(wep, "tf_weapon_lunchbox", false) == 0)
		{
			if(SandvichesEaten[client] < 2)
				ForcePlayerSuicide(client);
			else
				SandvichesEaten[client] -= 1;
				
			if(SandvichesEaten[client] == 2)
				EmitSoundToAll(SND_HEARTBEAT, client);
		}
	}
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 	//Heartattack logic
{
	if (IsValidClient(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Heavy)
	{
		if(iButtons & IN_FORWARD || iButtons & IN_BACK || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT)
		{
			static Float:flLastSound[MAXPLAYERS+1];
			
			if((GetEngineTime() - flSoundDuration) <= flLastSound[iClient])
				return;
			flLastSound[iClient] = GetEngineTime();
		
			switch(SandvichesEaten[iClient])
			{
				case 1: ForcePlayerSuicide(iClient);
				case 2:	EmitSoundToAll(strCloseCalls[GetRandomInt(0, sizeof(strCloseCalls)-1)], iClient);
				case 3: EmitSoundToAll(strHeartPain[GetRandomInt(0, sizeof(strHeartPain)-1)], iClient);
				case 4: EmitSoundToAll(strDontFeelGood[GetRandomInt(0, sizeof(strDontFeelGood)-1)], iClient);
			}
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}
	
stock PrecacheSounds(const String:strSounds[][], iArraySize)	//From Leonardos 'Be The Ghost' Plugin
{
	for(new i = 0; i < iArraySize; i++)
		if(!PrecacheSound(strSounds[i]))
			PrintToChatAll("Faild to precache sound: %s", strSounds[i]);
}