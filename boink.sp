#include <sourcemod>
#include <sdktools>
#include <steamtools>
#pragma semicolon 1

public OnPluginStart()
{
	AddNormalSoundHook(SoundHook);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (channel < 1)
		return Plugin_Continue;
		
	pitch = GetRandomInt(10, 250);
	PrecacheSound("vo/scout_specialcompleted02.wav");
	Format(sound, sizeof(sound), "vo/scout_specialcompleted02.wav");
//	EmitSoundToAll(sound, ent);//, _, _, _, 0.25, pitch);
	return Plugin_Changed;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}