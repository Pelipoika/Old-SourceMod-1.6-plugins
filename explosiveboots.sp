#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new bool:g_TeleportAtFrameEnd[MAXPLAYERS+1] = false;
new Float:g_TeleportAtFrameEnd_Vel[MAXPLAYERS+1][3];

new Handle:g_hForwardOnStomp;
new Handle:g_hForwardOnStompPost;

#pragma semicolon 1

#define ITEM_MANTREADS    444

public OnPluginStart()
{
	g_hForwardOnStomp = CreateGlobalForward("OnStomp", ET_Event, Param_Cell, Param_Cell, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hForwardOnStompPost = CreateGlobalForward("OnStompPost", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Float);
}

public OnClientPutInServer(client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
    if(IsValidEntity(weapon) && IsValidEntity(victim) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == ITEM_MANTREADS) 
	{
		decl Float:pos[3];
		GetClientAbsOrigin(victim, pos);
			
		CreateParticle("ExplosionCore_MidAir", pos);
		CreateParticle("Explosions_MA_Dustup_2", pos);
		CreateParticle("ExplosionCore_sapperdestroyed", pos);
		CreateParticle("bday_balloon02", pos);
		CreateParticle("bday_balloon01", pos);
			
		CreateExplosion(pos, victim, _, 100);
			
		//GOOMBA
		new Float:jumpPower = 8000;

		new Float:modifiedJumpPower = jumpPower;

		// Launch forward
		decl Action:stompForwardResult;

		Call_StartForward(g_hForwardOnStomp);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushFloatRef(modifiedJumpPower);
		Call_Finish(stompForwardResult);

		if(stompForwardResult == Plugin_Changed)
		{
			jumpPower = modifiedJumpPower;
		}
		else if(stompForwardResult == Plugin_Handled)
		{
			return false;
		}

		if(jumpPower > 0.0)
		{
			decl Float:vecAng[3], Float:vecVel[3];
			GetClientEyeAngles(attacker, vecAng);
			GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", vecVel);
			vecAng[0] = DegToRad(vecAng[0]);
			vecAng[1] = DegToRad(vecAng[1]);
			vecVel[0] = jumpPower * Cosine(vecAng[0]) * Cosine(vecAng[1]);
			vecVel[1] = jumpPower * Cosine(vecAng[0]) * Sine(vecAng[1]);
			vecVel[2] = jumpPower + 100.0;

			g_TeleportAtFrameEnd[attacker] = true;
			g_TeleportAtFrameEnd_Vel[attacker] = vecVel;
		}

		// Launch forward
		Call_StartForward(g_hForwardOnStompPost);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushFloat(jumpPower);
		Call_Finish();

		return true;
    }
    return Plugin_Continue;
}  

public OnPreThinkPost(client)
{
 //   if (IsClientInGame(client) && IsPlayerAlive(client))
	if (IsClientInGame(client))
    {
        if(g_TeleportAtFrameEnd[client])
        {
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, g_TeleportAtFrameEnd_Vel[client]);
        }
    }
	g_TeleportAtFrameEnd[client] = false;
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