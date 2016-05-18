#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>

public OnPluginStart()
{
	HookEvent("player_upgradedobject", Event_Upgraded);
	AddNormalSoundHook(SoundHook);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(IsValidEntity(ent))
	{
		if(StrContains(sound, "sentry", false) != -1 && StrContains(sound, "shoot", false) != -1)
		{
			if(GetEntProp(ent, Prop_Send, "m_iUpgradeLevel") !=  1)
			{
				TE_ParticleToAll("nutsnbolts_upgrade", _, _, _, ent, 4, 1, true);
				TE_ParticleToAll("flamethrower", _, _, _, ent, 4, 2, false);
				TE_ParticleToAll("flamethrower", _, _, _, ent, 4, 1, false);
			}
			else
			{
				TE_ParticleToAll("nutsnbolts_upgrade", _, _, _, ent, 4, 1, true);
				TE_ParticleToAll("flamethrower_halloween", _, _, _, ent, 4, 4, false);
			}
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_Upgraded(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFObjectType:object = TFObjectType:GetEventInt(event, "object");
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && object == TFObject_Sentry)
	{
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding))
		{
			TE_ParticleToAll("nutsnbolts_upgrade", _, _, _, iBuilding, 4, 1, true);
		}
	}
}

//)weapons/sentry_shoot_mini.wav
//)weapons/sentry_shaft_shoot.wav
//)weapons/sentry_shaft_shoot2.wav
//)weapons/sentry_shaft_shoot3.wav

/*
lvl 1 = muzzle & m_nAttachmentIndex = 4
lvl 2 = muzzle_l & muzzle_r & m_nAttachmentIndex = 1 & 2
lvl 3 = muzzle_l & muzzle_r & m_nAttachmentIndex = 1 & 2

flamethrower
flamethrower_blue

----------------------------
Unrelated...

- "userid" = "2"
- "victim_entindex" = "1"
- "inflictor_entindex" = "349"
- "attacker" = "0"
- "weapon" = "merasmus_zap"
- "weaponid" = "0"
- "damagebits" = "8"
- "customkill" = "59"
- "assister" = "-1"
- "weapon_logclassname" = "merasmus_zap"
- "stun_flags" = "0"
- "death_flags" = "0"
- "silent_kill" = "0"
- "playerpenetratecount" = "0"
- "assister_fallback" = ""
- "kill_streak_total" = "0"
- "kill_streak_wep" = "0"
- "kill_streak_assist" = "0"
- "kill_streak_victim" = "0"
- "rocket_jump" = "0"
*/

TE_ParticleToAll(String:Name[], Float:origin[3]=NULL_VECTOR, Float:start[3]=NULL_VECTOR, Float:angles[3]=NULL_VECTOR, entindex=-1,attachtype=-1,attachpoint=-1, bool:resetParticles=true)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToAll();
}