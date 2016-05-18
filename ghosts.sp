#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <gmg\misc>

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	{
		decl Float:pos[3];
		GetClientAbsOrigin(victim, pos);
		pos[2] += 16.0;
		if (GetClientTeam(victim) == TFTeam_Blue)
		{
			CreateParticle("halloween_player_death_blue", pos);
		}
		else if (GetClientTeam(victim) == TFTeam_Red)
		{
			CreateParticle("halloween_player_death", pos);
		}
	}
}