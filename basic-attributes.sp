#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>
#include <customweaponstf>
#include <tf2attributes>

#define SOUND_LAZR	"weapons/physcannon/physcannon_charge.wav"

new bool:HasAttribute[2049];
new bool:FiresTracers[2049];

//Lazer things
new bool:IsChargeLaserGun[2049];
new Float:flCharge[2049];
new bool:PlaySound[2049];

new Float:CrouchAccuracyBonus[2049];
new Float:CrouchFiringSpeedPenalty[2049];
new Float:CrouchDamageBonus[2049];

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public OnMapStart()
{
	PrecacheSound(SOUND_LAZR);
}

public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
	if (!StrEqual(plugin, "basic-attributes")) return Plugin_Continue;
	
	new Action:action;
	if (StrEqual(attrib, "fires tracer bullets"))
	{
		if(StringToInt(value) == 0)
			FiresTracers[weapon] = false;
		else
			FiresTracers[weapon] = true;
		
		action = Plugin_Handled;
	}
	
	if (StrEqual(attrib, "accuracy bonus while crouching"))
	{
		CrouchAccuracyBonus[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	
	if (StrEqual(attrib, "firing speed penalty while crouching"))
	{
		CrouchFiringSpeedPenalty[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	
	if (StrEqual(attrib, "damage bonus while crouching"))
	{
		CrouchDamageBonus[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	
	if (StrEqual(attrib, "hold charge shoots laser"))
	{
		if(StringToInt(value) == 0)
			IsChargeLaserGun[weapon] = false;
		else
			IsChargeLaserGun[weapon] = true;

		action = Plugin_Handled;
	}
	
	if (!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;

	return action;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue; // Attacker isn't valid, so the weapon won't be either.
	if (weapon == -1) return Plugin_Continue; 							// Weapon is invalid, so it won't be custom.
	if (!HasAttribute[weapon]) return Plugin_Continue;					// Weapon is valid, but doesn't have one of our attributes. We don't care!
	
	new Action:action;

	return action;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if (attacker <= 0 || attacker > MaxClients) return;
	if (weapon == -1) return;
	if (!HasAttribute[weapon]) return;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"); // We have to get the weapon manually, sadly; this also means that
	if (weapon == -1) return Plugin_Continue;							// attributes that use this can only be applied to "hitscan" weapons.
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon2)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon <= 0 || weapon > 2048) return Plugin_Continue;
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	new Action:action;
	if(CrouchAccuracyBonus[weapon] != 0.0)
	{
		if(GetEntProp(client, Prop_Send, "m_bDucked") == 1)
			TF2Attrib_SetByName(weapon, "weapon spread bonus", CrouchAccuracyBonus[weapon]);
		else
			TF2Attrib_RemoveByName(weapon, "weapon spread bonus");
			
		action = Plugin_Changed;
	}
	
	if(CrouchFiringSpeedPenalty[weapon] != 0.0)
	{
		if(GetEntProp(client, Prop_Send, "m_bDucked") == 1)
			TF2Attrib_SetByName(weapon, "fire rate penalty", CrouchFiringSpeedPenalty[weapon]);
		else
			TF2Attrib_RemoveByName(weapon, "fire rate penalty");
			
		action = Plugin_Changed;
	}	
	
	if(CrouchDamageBonus[weapon] != 0.0)
	{
		if(GetEntProp(client, Prop_Send, "m_bDucked") == 1)
			TF2Attrib_SetByName(weapon, "damage bonus", CrouchDamageBonus[weapon]);
		else
			TF2Attrib_RemoveByName(weapon, "damage bonus");
			
		action = Plugin_Changed;
	}
	
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:sWeaponName[], &bool:result)
{
	if (weapon <= 0 || weapon > 2048) return Plugin_Continue;
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	if (FiresTracers[weapon])
	{
		// TRACE!
	}
	
	if(IsChargeLaserGun[weapon])
	{
		if(GetEntProp(weapon, Prop_Send, "m_iWeaponState") == 3)
		{
			if(flCharge[weapon] <= GetTickedTime())
			{
				decl Float:flStartPos[3], Float:flEyeAng[3], Float:flEndPos[3];
				GetClientEyePosition(client, flStartPos);
				GetClientEyeAngles(client, flEyeAng);
					
				new Handle:hTrace = TR_TraceRayFilterEx(flStartPos, flEyeAng, MASK_SHOT, RayType_Infinite, TraceRayDontHitEntity, client);
				TR_GetEndPosition(flEndPos, hTrace);
				CloseHandle(hTrace);
				
				ShootLaser(weapon, "merasmus_zap", flStartPos, flEndPos);
				SetEntProp(weapon, Prop_Send, "m_nSequence", 25);
				PlaySound[weapon] = true;
				flCharge[weapon] = GetTickedTime() + 2.0;
			}
			
			if (PlaySound[weapon])
			{
				EmitSoundToAll(SOUND_LAZR, client);
				flCharge[weapon] = GetTickedTime() + 2.0;
				PlaySound[weapon] = false;
			}
		}
		
		action = Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public bool:TraceRayDontHitEntity(entity, mask, any:data)
{
	if (entity == data) return false;
	return true;
}

public OnEntityDestroyed(Ent)
{
	if (Ent <= 0 || Ent > 2048) return;
	HasAttribute[Ent] = false;
	FiresTracers[Ent] = false;
	CrouchAccuracyBonus[Ent] = 0.0;
	CrouchFiringSpeedPenalty[Ent] = 0.0;
	CrouchDamageBonus[Ent] = 0.0;
}

stock AttachParticle(entity, const String:strParticle[], const String:strAttachPoint[])
{
	new iParticle = CreateEntityByName("info_particle_system"); 
	if(IsValidEdict(iParticle))
	{
		DispatchKeyValue(iParticle, "effect_name", strParticle); 
		DispatchSpawn(iParticle); 
		
		SetVariantString("!activator"); 
		AcceptEntityInput(iParticle, "SetParent", entity); 
		
		ActivateEntity(iParticle); 

		SetVariantString(strAttachPoint);
		AcceptEntityInput(iParticle, "SetParentAttachment", entity);
		
		AcceptEntityInput(iParticle, "start"); 
	}
}

stock ModRateOfFire(client, Float:Amount)
{
	new ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(ent))
	{
		new Float:m_flNextPrimaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack");
		new Float:m_flNextSecondaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack");
		if (Amount > 12)
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 12.0);
		else
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", Amount);
		
		new Float:GameTime = GetGameTime();
		
		new Float:PeTime = (m_flNextPrimaryAttack - GameTime) - ((Amount - 1.0) / 50);
		new Float:SeTime = (m_flNextSecondaryAttack - GameTime) - ((Amount - 1.0) / 50);
		new Float:FinalP = PeTime+GameTime;
		new Float:FinalS = SeTime+GameTime;
	
		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", FinalP);
		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", FinalS);
	}
}

stock ShootLaser(weapon, const String:strParticle[], Float:flStartPos[3], Float:flEndPos[3])
{
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE) 
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	new i;
	for (i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, strParticle, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", strParticle);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", flStartPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", flStartPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", flStartPos[2] -= 32.0);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", weapon);
	TE_WriteNum("m_iAttachType", 2);
	TE_WriteNum("m_iAttachmentPointIndex", 0);
	TE_WriteNum("m_bResetParticles", 0);    
	TE_WriteNum("m_bControlPoint1", 1);    
	TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", 5);  
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", flEndPos[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", flEndPos[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", flEndPos[2]);
	TE_SendToAll();
}