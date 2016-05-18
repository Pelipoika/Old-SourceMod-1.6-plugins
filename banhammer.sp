#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1"
#define SOUND_FAILURE "vo/announcer_failure.wav"
#define SOUND_EXPLOSION "items/cart_explode.wav"

new Handle:g_cvDuration = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Ban-Hammer",
	author = "Pelipoika",
	description = "FUCKING 15 YEAR OLDS",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	g_cvDuration = CreateConVar("banhammer_duration", "1", "Ban time (in minutes)", FCVAR_PLUGIN, true, -1.0);
	HookConVarChange(g_cvDuration, OnConVarChanged_Duration);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart()
	PrecacheSound(SOUND_FAILURE, true);

public OnGameFrame()
{
	static Float:fLastGameTime;
	new iActiveWeapon, String:sWeaponClassName[128];
	if((GetEngineTime()-0.1) >= fLastGameTime)
	{
		fLastGameTime = GetEngineTime();
		for(new iClient=1; iClient<=MaxClients; iClient++)
			if(IsClientConnected(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient))
			{
				iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(iActiveWeapon) && IsValidEdict(iActiveWeapon))
				{
					GetEdictClassname(iActiveWeapon, sWeaponClassName, sizeof(sWeaponClassName));
					if (GetUserFlagBits(iClient) & ADMFLAG_ROOT)
						if(StrContains(sWeaponClassName, "tf_weapon", false) != -1)
							if(GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex") == 153) 	//if(GetEntProp(iActiveWeapon, Prop_Send, "m_iEntityLevel")==-13)
							{
								TF2_AddCondition(iClient, TFCond_Kritzkrieged, 0.125);
								TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 0.125);
							}
				}
			}
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(	iVictim<=0 || iVictim>MaxClients || !IsClientConnected(iVictim) || !IsClientAuthorized(iVictim) || iAttacker==iVictim
		|| iAttacker<=0 || iAttacker>MaxClients || !IsClientConnected(iAttacker))
		return Plugin_Continue;
	
	new iActiveWeapon = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
	if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_FIREAXE || !IsValidEntity(iActiveWeapon))
		return Plugin_Continue;
	
	if(GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex") == 153 && GetUserFlagBits(iAttacker) & ADMFLAG_ROOT)
	{
		SetEventString(hEvent, "weapon_logclassname", "banhammer");
		
		CreateTimer(0.1, Timer_LittleDelay, iVictim, TIMER_FLAG_NO_MAPCHANGE);
		
		new Handle:hMenu = CreateMenu(Menu_ConfirmBan);
		SetMenuTitle(hMenu, "Sure you want to ban %N ?", iVictim);
		AddMenuItem(hMenu, IntToString(iVictim), "Confirm");
		AddMenuItem(hMenu, "-1", "Cancel");
		SetMenuExitBackButton(hMenu, false);
		DisplayMenu(hMenu, iAttacker, 5);
		
		new Handle:hAEvent = CreateEvent("show_annotation");
		if(hAEvent!=INVALID_HANDLE)
		{
			decl Float:fPos[3];
			GetClientAbsOrigin(iVictim, fPos);
			SetEventInt(hAEvent, "id", GetRandomInt(1,10)*GetRandomInt(1,100)); // nevermind
			SetEventFloat(hAEvent, "worldPosX", fPos[0]);
			SetEventFloat(hAEvent, "worldPosY", fPos[1]);
			SetEventFloat(hAEvent, "worldPosZ", fPos[2]+30.0);
			SetEventInt(hAEvent, "visibilityBitfield", 16777215);
			SetEventString(hAEvent, "text", GetConVarInt(g_cvDuration)==-1?"KICKED":"BANNED");
			SetEventFloat(hAEvent, "lifetime", 3.5);
			FireEvent(hAEvent);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_LittleDelay(Handle:hTimer, any:iClient)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return Plugin_Handled;
	
	new Float:fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	EmitSoundToAll(SOUND_EXPLOSION, 0, SNDCHAN_WEAPON, _, _, _, _, _, fOrigin, NULL_VECTOR);
	
	ShowParticle(fOrigin, "cinefx_goldrush", 4.0);
	
	new iBodyEnt = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(iBodyEnt))
		AcceptEntityInput(iBodyEnt, "kill");
	
	PrintToChatAll("\x01* \x03%N\x01 humiliated with the \x05Ban-Hammer\x01", iClient);
		
	for(new iOtherClient=1; iOtherClient<=MaxClients; iOtherClient++)
		if(IsClientConnected(iOtherClient) && IsClientInGame(iOtherClient))
			EmitSoundToClient(iOtherClient, SOUND_FAILURE, _, _, SNDLEVEL_RAIDSIREN);
	
	return Plugin_Handled;
}

public Menu_ConfirmBan(Handle:hMenu, MenuAction:iAction, iClient, iMenuItem)
{
	if(iAction==MenuAction_Select)
	{
		new String:sSelection[4], iTarget;
		GetMenuItem(hMenu, iMenuItem, sSelection, sizeof(sSelection));
		iTarget = StringToInt(sSelection);
		if(iTarget>0 && iTarget<=MaxClients && IsClientInGame(iTarget))
		{
			decl iDuration, String:sReason[128], String:sKickMsg[128];
			iDuration = GetConVarInt(g_cvDuration);
			Format(sReason, sizeof(sReason), "Humiliated by Ban-Hammer");
			if(iDuration==0)
				Format(sKickMsg, sizeof(sKickMsg), "You're permanently banned on this server.");
			else if(iDuration==-1)
				Format(sKickMsg, sizeof(sKickMsg), "You're kicked from this server.");
			else
				Format(sKickMsg, sizeof(sKickMsg), "You're banned on this server for %i minutes.", iDuration);
			
			if(iDuration==-1 || IsFakeClient(iTarget))
				KickClient(iTarget, sKickMsg);
		}
	}
	else
		CloseHandle(hMenu);
}

public OnConVarChanged_Duration(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	new iNewValue = StringToInt(sNewValue);
	if(iNewValue<0 && iNewValue!=-1)
		SetConVarInt(g_cvDuration, iNewValue, false, false);
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            AcceptEntityInput(particle, "kill");
    }
}