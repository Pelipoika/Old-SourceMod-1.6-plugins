#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

new bool:Locked1[MAXPLAYERS+1];
new bool:Locked2[MAXPLAYERS+1];
new bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Deflectus Maximus",
	author = "Pelipoika",
	description = "",
	version = "1.0",
	url = ""
}

public OnMapStart()
{
	PrecacheSound(SOUND_GUNFIRE);
	PrecacheSound(SOUND_GUNSPIN);
	PrecacheSound(SOUND_WINDUP);
	PrecacheSound(SOUND_WINDDOWN);
}

public OnGameFrame() 
{
	for (new iClient = 1; iClient < MaxClients + 1; iClient++) 
	{
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) 
		{	
			if (GetClientButtons(iClient) & IN_ATTACK || IN_ATTACK2) 
			{
				decl String:sWeaponCurrent[64];
				GetClientWeapon(iClient, sWeaponCurrent, sizeof(sWeaponCurrent));
				if (StrEqual(sWeaponCurrent, "tf_weapon_minigun", false))
				{
					new iWeapon = GetPlayerWeaponSlot(iClient, 0);
					new iWeaponState = GetEntProp(iWeapon, Prop_Send, "m_iWeaponState");
						
					if (iWeaponState == 1 && !Locked1[iClient])
					{
						EmitSoundToAll(SOUND_WINDUP, iClient, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, _, 1.0, _, _, _, _, true, _);
						//PrintToChatAll("WeaponState = Windup");
						
						Locked1[iClient] = true;
						Locked2[iClient] = false;
						Locked3[iClient] = false;
						CanWindDown[iClient] = true;
						
						StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
						StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
					}
					else if (iWeaponState == 2 && !Locked2[iClient])
					{
						EmitSoundToAll(SOUND_GUNFIRE, iClient, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, _, 1.0, _, _, _, _, true, _);
						//PrintToChatAll("WeaponState = Firing");
						
						Locked2[iClient] = true;
						Locked1[iClient] = true;
						Locked3[iClient] = false;
						CanWindDown[iClient] = true;
						
						StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
						StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
					}
					else if (iWeaponState == 3 && !Locked3[iClient])
					{
						EmitSoundToAll(SOUND_GUNSPIN, iClient, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, _, 1.0, _, _, _, _, true, _);
						//PrintToChatAll("WeaponState = Spun Up");
						
						Locked3[iClient] = true;
						Locked1[iClient] = true;
						Locked2[iClient] = false;
						CanWindDown[iClient] = true;
						
						StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
						StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
					}
					else if (iWeaponState == 0)
					{
						if (CanWindDown[iClient])
						{
						//	PrintToChatAll("WeaponState = WindDown");
							EmitSoundToAll(SOUND_WINDDOWN, iClient, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, _, 1.0, _, _, _, _, true, _);
							CanWindDown[iClient] = false;
						}
						
						StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
						StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
						
						Locked1[iClient] = false;
						Locked2[iClient] = false;
						Locked3[iClient] = false;
					}
				}
			}
		}
	}
}

/*
Maybe. 0 is idle, 1 is spinning up, 2 is firing, and 3 is spun up but not firing. 

    AC_STATE_IDLE=0, 
    AC_STATE_STARTFIRING, 
    AC_STATE_FIRING, 
    AC_STATE_SPINNING 

mvm\giant_heavy\giant_heavy_gunfire.wav
mvm\giant_heavy\giant_heavy_gunspin.wav
mvm\giant_heavy\giant_heavy_gunwinddown.wav
mvm\giant_heavy\giant_heavy_gunwindup.wav

	Random
ambient\creatures\teddy.wav
items\pyro_guitar_solo_no_verb.wav
player\taunt_shake_it.wav
player\taunt_rubberglove_snap.wav
player\taunt_rubberglove_stretch.wav
 */