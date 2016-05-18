#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAXENTITIES 2048 

new MapStarted = false;						//Prevents a silly error from occuring with the AttachParticle stock

public Plugin:myinfo = 
{
	name = "[TF2] Control Point Effects",
	author = "Pelipoika",
	description = "Makes Control Points look pretty",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_StuffHapening);
	HookEvent("teamplay_point_captured", Event_StuffHapening);
}

public OnMapStart()
{
	PrecacheModel("hwn_cart_cap_neutral");
	PrecacheModel("hwn_cart_cap_red");
	PrecacheModel("hwn_cart_cap_blue");
	
	PrecacheModel("hwn_cart_drips_blue");
	PrecacheModel("hwn_cart_drips_red");
	
	MapStarted = true;
}

public OnMapEnd()
{
	MapStarted = false;
}

public Event_StuffHapening(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	KillParticles();
	
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		new team = GetEntProp(ent, Prop_Data, "m_iTeamNum");
		
		switch(team)
		{
			case 0:	//Neutral
			{
			//	PrintToChatAll("Added particle");
				AttachParticle(ent, "hwn_cart_cap_neutral");
			}
			case 2:	//Red
			{
			//	PrintToChatAll("Added particle");
				AttachParticle(ent, "hwn_cart_cap_red");
				AttachParticle(ent, "hwn_cart_drips_red", _, 128.0);
			}
			case 3: //Blue
			{
			//	PrintToChatAll("Added particle");
				AttachParticle(ent, "hwn_cart_cap_blue");
				AttachParticle(ent, "hwn_cart_drips_blue", _, 128.0);
			}
		}
	} 
}

KillParticles()
{
	new particle = -1;	//First we must delete all particles!
	while ((particle = FindEntityByClassname(particle, "info_particle_system")) != -1)
	{
		decl String:name[32];
		GetEntPropString(particle, Prop_Data, "m_iName", name, 128, 0);
		if(StrEqual(name, "killme%dp@later")) 
		{
		//	PrintToChatAll("Killed some particles");
			AcceptEntityInput(particle, "Kill");
		}
	}
}

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flZOffset=0.0, Float:flSelfDestruct=0.0) 
{ 
	if (MapStarted)
	{
		new iParticle = CreateEntityByName("info_particle_system"); 
		if(!IsValidEdict(iParticle))
			return 0; 
		 
		new Float:flPos[3]; 
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos); 
		flPos[2] += flZOffset; 
		 
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR); 
		
		DispatchKeyValue(iParticle, "targetname", "killme%dp@later");
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect); 
		DispatchSpawn(iParticle); 
		 
		SetVariantString("!activator"); 
		AcceptEntityInput(iParticle, "SetParent", iEntity); 
		ActivateEntity(iParticle); 
		 
		if(strlen(strAttachPoint)) 
		{ 
			SetVariantString(strAttachPoint); 
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset"); 
		} 
		
		AcceptEntityInput(iParticle, "start");

		if(flSelfDestruct > 0.0) 
			CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle)); 

		return iParticle; 
	}
	return 0;
} 

public Action:Timer_DeleteParticle(Handle:hTimer, any:iRefEnt) 
{ 
    new iEntity = EntRefToEntIndex(iRefEnt); 
    if(iEntity > MaxClients) 
        AcceptEntityInput(iEntity, "Kill"); 
     
    return Plugin_Handled; 
}