#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1

new bool:Unheal[MAXPLAYERS+1];
new Handle:medicheck = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_unheal", Command_Unheal, ADMFLAG_ROOT);
	
	medicheck = CreateTimer(0.1, Timer_MedicCheck, _, TIMER_REPEAT);
}

public OnPluginEnd()
{
	if(medicheck != INVALID_HANDLE)
	{
		KillTimer(medicheck);
		medicheck = INVALID_HANDLE;
	}
}

public Action:Command_Unheal(client, args)
{
	if (Unheal[client] == false)
	{
		PrintCenterText(client, "Ze healing hurts");
		Unheal[client] = true;
		return Plugin_Handled;
	}
	else
	{
		PrintCenterText(client, "Ze healing heals");
		Unheal[client] = false;
		return Plugin_Handled;
	}
}

public Action:Timer_MedicCheck(Handle:timer)
{
	CheckHealers();
	return Plugin_Continue;
}

stock CheckHealers()
{
	new iTarget;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Unheal[i] && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
		{
			iTarget = TF2_GetHealingTarget(i);
			
			if (iTarget > 0)
			{
				decl Float:pos[3];
				GetClientAbsOrigin(iTarget, pos);
				
				new Float:dir[3] = {0.0, 0.0, 0.0};
				pos[2] += 45.0;
				TE_SetupSparks(pos, dir, 1500, 500);
				TE_SendToAll();
				TF2_AddCondition(iTarget, TFCond_HalloweenSpeedBoost, 0.5);
				TF2_AddCondition(i, TFCond_HalloweenSpeedBoost, 0.2);
				
				PrintCenterText(iTarget, "%N is giving you a Buff!", i);
				
				/*if (GetClientHealth(iTarget) < 0 && IsPlayerAlive(iTarget))
				{
					CreateExplosion(pos, iTarget, _, 100);
				}
				
				if (GetClientHealth(iTarget) > 0)
				{
					SetEntityHealth(iTarget, GetClientHealth(iTarget) - 15);
					TF2_MakeBleed(iTarget, i, 0.5);
				}*/
				
				//decl Float:pos2[3];
				//GetClientAbsOrigin(i, pos2);
				
				/*if (GetClientTeam(i) == 3)	//Blue
				{
					decl Float:pos2[3];
					GetClientAbsOrigin(i, pos2);
					pos2[2] += 80.0;
					CreateParticle("healthgained_blu", pos2);
				}
				else if (GetClientTeam(i) == 2)		//Red
				{
					decl Float:pos2[3];
					GetClientAbsOrigin(i, pos2);
					pos2[2] += 80.0;
					CreateParticle("healthgained_red", pos2);
				}
				
				SetEntityHealth(i, GetClientHealth(i) + 2);
				*/
			}
		}
	}
}

stock TF2_GetHealingTarget(client)
{
    new String:classname[64];
	
    TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));
    if(StrEqual(classname, "CWeaponMedigun"))
    {
        new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if(GetEntProp(index, Prop_Send, "m_bHealing") == 1)
        {
            return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
        }
    }
    return -1;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if(client > 0)
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock CreateParticle(String:particle[], Float:pos[3])
{
	new tblidx = FindStringTable("ParticleEffectNames");
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	for(new i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_SendToClient(i, 0.0);
	}
}

stock CreateExplosion(Float:pos[3], owner=0, Float:force=180.0, magnitude=512, radius=350)
{
	new ent = CreateEntityByName("env_explosion");
	DispatchKeyValueFloat(ent, "DamageForce", force);
	DispatchKeyValue(ent, "classname", "explosion");
	SetEntProp(ent, Prop_Data, "m_iMagnitude", magnitude, 4);
	SetEntProp(ent, Prop_Data, "m_iRadiusOverride", radius, 4);
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", owner);
	DispatchSpawn(ent);
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent, "Explode", -1, -1, 0);
}