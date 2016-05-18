#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <tf2>
#include <tf2_stocks>
#include <tf2items_giveweapon>
#include <gmg\misc>
//#include <gmg\server>
#include <gmg\users>
#include <gmg\bosses>
//#include <gmg\items>
#include <gmg\core>
//#include <soundlib>
#pragma semicolon 1

#define SOUND_START			"fn/welcome/boss_time.mp3"
#define SOUND_MUSIC			"fn/welcome/boss_loop.mp3"
#define SOUND_END			"fn/welcome/boss_win.mp3"
#define SOUND_CHARGED		"items/cart_explode_trigger.wav"
#define SOUND_SHIELD_DEAD	"physics/glass/glass_largesheet_break1.wav"
#define SOUND_SHIELD_ONLINE	"weapons/physcannon/physcannon_pickup.wav"
#define SOUND_FINALEXPLODE	"items/cart_explode.wav"
#define SOUND_FINALRISE		"player/taunt_medic_heroic.wav"
#define SOUND_FINALRISE2	"player/taunt_v01.wav"
#define SOUND_KISSME		"vo/heavy_generic01.wav"

#define SOUND_BOO			"vo/taunts/spy_taunts06.wav"
#define SOUND_INVISIBLE		"player/spy_uncloak.wav"
#define SOUND_LAUGH			"vo/spy_laughshort01.wav"

#define SOUND_FREEZE		"weapons/saxxy_impact_gen_06.wav"
#define SOUND_EXPLODE		"items/pumpkin_explode1.wav"
#define SOUND_PIANO			"npc/antlion/attack_double1.wav"
#define SOUND_COW			"ambient/cow1.wav"
#define SOUND_FALCON		"ambient/medieval_falcon.wav"
#define SOUND_CREEPER		"vo/demoman_jeers02.wav"
#define SOUND_FROST			"weapons/saxxy_turntogold_05.wav"
#define SOUND_SLICE			"weapons/samurai/TF_katana_slice_01.wav"
#define SOUND_FUS			"fn/welcome/dragonborn.wav"
#define SOUND_DEMO			"vo/taunts/demoman_taunts08.wav"
#define SOUND_CUTE			"ambient/creatures/teddy.wav"

#define MODEL_EXPLODE		"models/props_halloween/pumpkin_explode.mdl"
#define MODEL_PIANO			"models/props_manor/baby_grand_01.mdl"
#define MODEL_SENTRY1		"models/buildables/sentry1.mdl"
#define MODEL_SENTRY2		"models/buildables/sentry2.mdl"
#define MODEL_SENTRY3		"models/buildables/sentry3.mdl"
#define MODEL_COW			"models/props_2fort/cow001_reference.mdl"
#define MODEL_DYS			"models/bots/soldier_boss/bot_soldier_boss.mdl"

#define POSITION_SPAWN {0.0, 0.0, 0.0}
#define POSITION_SPAWN_BOSS {61.0, -22.0, 1005.0}

/*new String:shieldSounds[][] =
{
	"physics/glass/glass_impact_bullet1.wav",
	"physics/glass/glass_impact_bullet2.wav",
	"physics/glass/glass_impact_bullet3.wav",
	"physics/glass/glass_impact_bullet4.wav"
};*/

new String:shieldSounds[][] =
{
	"weapons/fx/rics/ric1.wav",
	"weapons/fx/rics/ric2.wav",
	"weapons/fx/rics/ric3.wav",
	"weapons/fx/rics/ric4.wav"
};

new String:explodeSounds[][] =
{
	"weapons/explode3.wav",
	"weapons/explode4.wav",
	"weapons/explode5.wav"
};

new String:darkAuraSounds[][] =
{
	"items/samurai/TF_samurai_noisemaker_setB_01.wav",
	"items/samurai/TF_samurai_noisemaker_setB_02.wav",
	"items/samurai/TF_samurai_noisemaker_setB_03.wav"
};

new BossTeam=_:TFTeam_Red;
new boss = 0;
new bossType = 0;
new bossShield = 0;
new lastAttacker = 0;
new bossTarget = 0;
new freelanceType = 0;
new bool:deathSequence = false;

new String:oldName[64];

new Handle:hudTimer = INVALID_HANDLE;
new Handle:bossHud = INVALID_HANDLE;
new Handle:bossHudShield = INVALID_HANDLE;
new Handle:musicTimer = INVALID_HANDLE;

new beamSprite;
new haloSprite;

new healthbar = 0;

new votes[2] = {0, 0};

public Plugin:myinfo = 
{
	name = "Boss Battles",
	author = "Pelipoika",
	description = "Fighting the big guys",
	version = "1.5",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("kill", Command_Kill);
	RegConsoleCmd("explode", Command_Kill);
	RegAdminCmd("sm_doboss", Command_Boss, ADMFLAG_ROOT);
	RegAdminCmd("sm_bossvote", Command_VoteBoss, ADMFLAG_ROOT);
	
	bossHud = CreateHudSynchronizer();
	bossHudShield = CreateHudSynchronizer();
	
	CreateTimer(14400.0, Timer_Ask);
	
	HookEvent("player_spawn", Event_Spawn);	
	
	
	//TF2Items_CreateWeapon(6018, const String:TF_WEAPON_GRENADELAUNCHER, 19, 1, 9, 69, const String:weaponAttribs[] = "", weaponAmmo = -1, const String:weaponModel[] = "", bool:overwrite = false);
}

public OnMapStart()
{
	PrecacheSound(SOUND_START);
	PrecacheSound(SOUND_MUSIC);
	PrecacheSound(SOUND_FINALEXPLODE);
	PrecacheSound(SOUND_END);
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_CHARGED);
	PrecacheSound(SOUND_SHIELD_ONLINE);
	PrecacheSound(SOUND_PIANO);
	PrecacheSound(SOUND_FALCON);
	PrecacheSound(SOUND_SHIELD_DEAD);
	PrecacheSound(SOUND_CREEPER);
	PrecacheSound(SOUND_FROST);
	PrecacheSound(SOUND_FINALRISE);
	PrecacheSound(SOUND_FINALRISE2);
	PrecacheSound(SOUND_COW);
	PrecacheSound(SOUND_SLICE);
	PrecacheSound(SOUND_FUS);
	PrecacheSound(SOUND_DEMO);
	PrecacheSound(SOUND_CUTE);
	PrecacheSound(SOUND_KISSME);
	
	PrecacheSound(SOUND_BOO);
	PrecacheSound(SOUND_INVISIBLE);
	PrecacheSound(SOUND_LAUGH);
	
	PrecacheModel(MODEL_EXPLODE);
	PrecacheModel(MODEL_PIANO);
	PrecacheModel(MODEL_SENTRY1);
	PrecacheModel(MODEL_SENTRY2);
	PrecacheModel(MODEL_SENTRY3);
	PrecacheModel(MODEL_COW);
	PrecacheModel(MODEL_DYS);
	
	beamSprite = PrecacheModel("materials/sprites/laser.vmt");
	haloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	for(new i=0; i<sizeof(shieldSounds); i++) PrecacheSound(shieldSounds[i]);
	for(new i=0; i<sizeof(explodeSounds); i++) PrecacheSound(explodeSounds[i]);
	for(new i=0; i<sizeof(darkAuraSounds); i++) PrecacheSound(darkAuraSounds[i]);
}

public OnClientDisconnect(client)
{
	if(client == boss) 
	{	
		EndBoss();
		if(musicTimer != INVALID_HANDLE)
		{
			KillTimer(musicTimer);
			musicTimer = INVALID_HANDLE;
		}
	}
	
}

public Action:Command_Kill(client, args)
{
	if(boss != 0)
	{
		ReplyToCommand(client, "You can't do that right now.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Command_VoteBoss(client, args)
{
	CreateTimer(1.0, Timer_Ask);
}

public Action:Timer_Ask(Handle:timer)
{
	votes[0] = 0;
	votes[1] = 0;
	if(GetClientCount(true) < 10) return;
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		new Handle:menu = CreateMenu(Menu_Vote);
		SetMenuTitle(menu, "Would you like to participate in a boss battle?");
		AddMenuItem(menu, "1", "Yes");
		AddMenuItem(menu, "2", "No");
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, i, 60);
	}
	CreateTimer(60.0, Timer_VoteEnd);
}

public Menu_Vote(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		votes[option]++;
		PrintToChat(client, "Your vote has been submitted.");
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action:Timer_VoteEnd(Handle:timer)
{
	new Float:voteRatio = (float(votes[0]) / float(votes[1]));
	if(voteRatio >= 1.0)
	{
		ServerCommand("sm_start");
		PrintCenterTextAll("A Boss Battle will begin in 10 seconds.");
		PrintToChatAll("A Boss Battle will begin in 10 seconds.");
		CreateTimer(11.0, Timer_Begin);
	}
	else
	{
		PrintToChatAll("Vote failed, not enough yes votes.");
	}
}

public Action:Timer_Begin(Handle:timer)
{
	if(boss != 0)
	{
		PrintToChatAll("Boss Battle failed.");
		PrintCenterTextAll("Boss Battle failed. One is already in progress.");
		return;
	}
	new iClients[MaxClients+1];
	new iNumClients;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			iClients[iNumClients++] = i;
		}
	}
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	PrintToChat(iRandomClient, "You will become the boss.");
	bossType = GetRandomInt(0, TOTAL_BOSSES);
	boss = iRandomClient;
	StartBattle();
}

public Action:Command_Boss(client, args)
{
	if(boss != 0)
	{
		ReplyToCommand(client, "There is already a boss battle in progress.");
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(Menu_Boss);
	SetMenuTitle(menu, "Boss Battle Select Boss");
	
	for(new i=0; i<sizeof(bossInfo); i++)
		AddMenuItem(menu, bossInfo[i][iName], bossInfo[i][iName]);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public Menu_Boss(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		bossType = option;
		new Handle:panel = CreatePanel();
		SetPanelTitle(panel, "Boss Battle Boss Overview");
		DrawPanelText(panel, " ");
		
		DrawPanelText(panel, "[Boss Name]");
		DrawPanelText(panel, bossInfo[bossType][iName]);
		DrawPanelText(panel, bossInfo[bossType][iDesc]);
		DrawPanelText(panel, " ");
		
		DrawPanelText(panel, "[Weapon Restrictions]");
		DrawPanelText(panel, bossInfo[bossType][iRestrictions]);
		DrawPanelText(panel, " ");
		
		DrawPanelText(panel, "[Passive Ability]");
		DrawPanelText(panel, bossInfo[bossType][iPassive]);
		DrawPanelText(panel, " ");
		
		DrawPanelText(panel, "[Right Click Ability]");
		DrawPanelText(panel, bossInfo[bossType][iUse]);
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, "Use Boss");
		DrawPanelItem(panel, "Go Back");
		
		SendPanelToClient(panel, client, Menu_Overview, 60);
		CloseHandle(panel);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Menu_Overview(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option != 1) return;
		
		new Handle:menu2 = CreateMenu(Menu_Player);
		SetMenuTitle(menu2, "Boss Battle Select Player");
		for(new i=1; i<=GetMaxClients(); i++)
		{
			if(!IsValidEntity(i)) continue;
			if(!IsClientInGame(i)) continue;
			if(IsFakeClient(i)) continue;
			decl String:idStr[4], String:name[64];
			GetClientName(i, name, sizeof(name));
			Format(idStr, sizeof(idStr), "%i", i);
			AddMenuItem(menu2, idStr, name);
		}
		SetMenuExitButton(menu2, true);
		DisplayMenu(menu2, client, 60);
	}
}

public Menu_Player(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:idStr[4];
		GetMenuItem(menu, option, idStr, sizeof(idStr));
		boss = StringToInt(idStr);
		StartBattle();
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public StartBattle()
{	
	EmitSoundToAll(SOUND_START);
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		if(i == boss)
			ChangeClientTeam(i, 2);
		else
			ChangeClientTeam(i, 3);
		TF2_RespawnPlayer(i);
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		ShowHudText(i, -1, "A wild %s has appeared!", bossInfo[bossType][iName]);
		ServerCommand("mp_disable_respawn_times 0");
		ServerCommand("mp_respawnwavetime 6");
		ServerCommand("sm plugins unload shapeshift");
		ServerCommand("sm plugins unload friendly");
	}
	GetClientName(boss, oldName, sizeof(oldName));
	SetEntProp(boss, Prop_Send, "m_bGlowEnabled", 1, 1);
	
//	decl Float:pos[3] = POSITION_SPAWN_BOSS;
//	TeleportEntity(boss, pos, NULL_VECTOR, NULL_VECTOR);
	
	if(bossType != BOSS_NORMAL)
		SetClientInfo(boss, "name", bossInfo[bossType][iName]);
	else
		SetClientInfo(boss, "name", "The Boss");
		
	decl String:className[64], String:entname[64];
	for(new i=1; i<=GetMaxEntities(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, className, sizeof(className));
			if(StrEqual(className, "func_door"))
			{
				GetEntPropString(i, Prop_Data, "m_iName", entname, sizeof(entname));
				if(StrEqual(entname, "deathmatch_lock", false)) 
				{
					AcceptEntityInput(i, "Close");
				}
			}
		}
	}
	
	if(bossType != BOSS_DYS)
		CreateTimer(5.0, Timer_Music);
	
	CreateTimer(0.2, Timer_Effects);
	hudTimer = CreateTimer(0.5, Timer_Hud, _, TIMER_REPEAT);
	SDKHook(boss, SDKHook_PreThink, OnBossThink);
}

//public Action:SoundHook_Normal(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
//{
//	return Plugin_Stop;
//}

public Action:Timer_Music(Handle:timer)
{
	EmitSoundToAll(SOUND_MUSIC);
//	new Handle:snd = OpenSoundFile(SOUND_MUSIC);
//	new Float:length = float(GetSoundLength(snd));
	musicTimer = CreateTimer(13.0, Timer_MusicLoop, _, TIMER_REPEAT);
}

public Action:Timer_MusicLoop(Handle:timer)
{
	EmitSoundToAll(SOUND_MUSIC);
}

public Action:Timer_Hud(Handle:timer)
{
	new health = RoundToCeil((float(GetClientHealth(boss))/float(bossInfo[bossType][iHealth])) * 100);
	if(health > 100)
		SetEntityHealth(boss, bossInfo[bossType][iHealth]);
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		if(health <= 10) SetHudTextParams(-1.0, 0.18, 0.5, 255, 0, 0, 255);
		else if(health <= 40) SetHudTextParams(-1.0, 0.18, 0.5, 255, 128, 0, 255);
		else SetHudTextParams(-1.0, 0.18, 0.5, 128, 255, 0, 255);
		ShowSyncHudText(i, bossHud, "%s's Health: %i\%", bossInfo[bossType][iName], health);
		
		if(bossShield > 0)
		{
			new shield = RoundToNearest((float(bossShield)/float(bossInfo[bossType][iShield])) * 100);
			SetHudTextParams(-1.0, 0.21, 1.0, 192, 255, 0, 255);
			ShowSyncHudText(i, bossHudShield, "%s's Shield: %i\%", bossInfo[bossType][iName], shield);
		}
	}
}

public Menu_Desc(Handle:menu, MenuAction:action, client, option)
{
	
}

public Action:Timer_Effects(Handle:timer)
{
	new Handle:panel = CreatePanel();
	
	decl String:text[128];
	Format(text, sizeof(text), "Boss Battle - %s", bossInfo[bossType][iName]);
	SetPanelTitle(panel, text);
	
	DrawPanelText(panel, bossInfo[bossType][iDesc]);
	DrawPanelText(panel, " ");
	
	Format(text, sizeof(text), "Weapon Restrictions: %s", bossInfo[bossType][iRestrictions]);
	DrawPanelText(panel, text);
	
	Format(text, sizeof(text), "Passive Ability: %s", bossInfo[bossType][iPassive]);
	DrawPanelText(panel, text);
	
	Format(text, sizeof(text), "Alt-Fire Ability: %s", bossInfo[bossType][iUse]);
	DrawPanelText(panel, text);
	
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "Close");
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		SendPanelToClient(panel, i, Menu_Desc, 15);
//		User_SetLocation(i, LOCATION_ARENA);
	}

	CloseHandle(panel);
	
	SDKHook(boss, SDKHook_PreThink, OnBossPreThink);
	PrintToChatAll("\x01A wild \x04%s\x01 has appeared!", bossInfo[bossType][iName]);
	PrintCenterTextAll("A wild %s has appeared!", bossInfo[bossType][iName]);
	if(bossType != BOSS_NORMAL)
		TF2_SetPlayerClass(boss, bossInfo[bossType][iClass]);
	bossShield = bossInfo[bossType][iShield];
	TF2_RegeneratePlayer(boss);
	SetEntityHealth(boss, bossInfo[bossType][iHealth]);
	TF2_AddCondition(boss, TFCond_Buffed, 9999.0);
	TF2_AddCondition(boss, TFCond_MegaHeal, 9999.0);
	
//	decl Float:pos[3] = POSITION_SPAWN_BOSS;
//	TeleportEntity(boss, pos, NULL_VECTOR, NULL_VECTOR);
	
	healthbar = CreateEntityByName("monster_resource");
	DispatchSpawn(healthbar);
	
//	SetEntPropFloat(boss, Prop_Send, "m_flModelScale", 1.5);
//	SetEntPropFloat(boss, Prop_Send, "m_flStepSize", 27.0);
	
	switch(bossInfo[bossType][iColor])
	{
		case BCOLOR_RED: SetEntityRenderColor(boss, 255, 0, 0, 255);
		case BCOLOR_GREEN: SetEntityRenderColor(boss, 0, 255, 0, 255);
		case BCOLOR_BLUE: SetEntityRenderColor(boss, 0, 0, 255, 255);
		case BCOLOR_ORANGE: SetEntityRenderColor(boss, 255, 128, 0, 255);
		case BCOLOR_PURPLE: SetEntityRenderColor(boss, 255, 0, 255, 255);
		case BCOLOR_BLACK: SetEntityRenderColor(boss, 0, 0, 0, 255);
		case BCOLOR_INVIS: SetEntityRenderMode(boss, RENDER_NONE);
	}
	switch(bossType)
	{
		case BOSS_PSYCHE:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 45);
			TF2Items_GiveWeapon(boss, 46);
			TF2Items_GiveWeapon(boss, 450);
			SetEntityGravity(boss, 0.5);
		}
		case BOSS_EAGLE:
		{
			SetEntityGravity(boss, 0.25);
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 414);
		}
		case BOSS_VIPER:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 38);
		}
		case BOSS_COW:
		{
			TF2_RemoveAllWeapons(boss);
			SetVariantString(MODEL_COW);
			AcceptEntityInput(boss, "SetCustomModel");
			SetThirdPerson(boss, 1);
			Client_SetDrawViewModel(boss, false);
		}
		case BOSS_BLACK:
		{
			TF2_RemoveWeaponSlot(boss, 1);
		}
		case BOSS_CREEPER:
		{
			TF2_RemoveAllWeapons(boss);
			TF2_StunPlayer(boss, 9999.0, _, TF_STUNFLAGS_NORMALBONK);
			SetThirdPerson(boss, 1);
		}
		case BOSS_KING:
		{
			TF2_RemoveWeaponSlot(boss, 0);
			TF2_RemoveWeaponSlot(boss, 1);
		}
		case BOSS_LIGHT:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 312);
		}
		case BOSS_HARDWARE:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 22);
		}
		case BOSS_HUNTER:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 526);
		}
		case BOSS_PIANO:
		{
			TF2_RemoveAllWeapons(boss);
			SetVariantString(MODEL_PIANO);
			AcceptEntityInput(boss, "SetCustomModel");
			SetThirdPerson(boss, 1);
			Client_SetDrawViewModel(boss, false);
		}
		case BOSS_NINJA:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 357);
			TF2_AddCondition(boss, TFCond_SpeedBuffAlly, 9999.0);
		}
		case BOSS_ADVENTURE:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 9003); 
		}
		case BOSS_F2P:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 40);
		}
		case BOSS_SURGEON:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 8);
		}
		case BOSS_TESLA:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 528);
		}
		case BOSS_FREELANCE:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 12);
			freelanceType = 0;
		}
		case BOSS_DYS:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 513);
			SetVariantString(MODEL_DYS);
			AcceptEntityInput(boss, "SetCustomModel");
			SetEntProp(boss, Prop_Send, "m_bUseClassAnimations", 1);
			SetThirdPerson(boss, 1);
//			AddNormalSoundHook(NormalSHook:SoundHook_Normal);
		}
		case BOSS_SHARK:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 9004);
		}
		case BOSS_CUDDLY:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 656);
			TF2_AddCondition(boss, TFCond_Kritzkrieged, 999999.0);
			TF2_AddCondition(boss, TFCond_SpeedBuffAlly, 999999.0);
			SetEntPropFloat(boss, Prop_Send, "m_flModelScale", 0.75);
		}
		case BOSS_STALKER:
		{
			TF2_RemoveAllWeapons(boss);
			TF2Items_GiveWeapon(boss, 727);
//			TF2Items_GiveWeapon(boss, 224);
			TF2_AddCondition(boss, TFCond_Kritzkrieged, 999999.0);
			SetEntProp(boss, Prop_Send, "m_bGlowEnabled", 0, 1);
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(attacker == victim) return Plugin_Continue;
	if(attacker == 0 || attacker > GetMaxClients()) return Plugin_Continue;
	if(victim == 0 || victim > GetMaxClients()) return Plugin_Continue;
	
	if(attacker == boss)
	{
		switch(bossType)
		{
			case BOSS_SNOW:
			{
				FreezePlayer(victim, (damage / 40));
				damage *= 0.6;
			}
			case BOSS_VIPER:
			{
				TF2_MakeBleed(victim, attacker, 9999.0);
				damage = 16.0;
			}
			case BOSS_KING:
			{
				damage = 10000.0;
			}
			case BOSS_HUNTER:
			{
				SetEntityRenderColor(victim, 255, 0, 0, 255);
				SetEntityHealth(victim, 5);
				SetEntProp(victim, Prop_Send, "m_bGlowEnabled", 1, 1);
				CreateTimer(2.4, Timer_Explode, victim);
				damage = 1.0;
				Client_ScreenFade(victim, 100, FFADE_IN, -1, 200, 0, 0, 240);
			}
			case BOSS_SURGEON:
			{
				decl Float:pos[3];
				GetClientAbsOrigin(victim, pos);
				
				TeleportEntity(boss, pos, NULL_VECTOR, NULL_VECTOR);
			}
			case BOSS_TESLA:
			{
				damage *= 6.0;
			}
			case BOSS_CUDDLY:
			{
				SetEntityRenderColor(victim, 255, 0, 255, 255);
				SetEntProp(victim, Prop_Send, "m_bGlowEnabled", 1, 1);
				CreateTimer(3.0, Timer_Laughsplosion, victim);
				EmitSoundToAll(SOUND_KISSME);
				damage = 1.0;
			}
			case BOSS_FREELANCE:
			{
				switch(freelanceType)
				{
					case 0:
					{
						TF2_AddCondition(victim, TFCond_Bleeding, 8.0);
						damage *= 0.75;
					}
					case 1:
					{
						FreezePlayer(victim, 3.0);
						damage *= 1.25;
					}
					case 2:
					{
						TF2_IgnitePlayer(victim, boss);
					}
				}
			}
		}
		return Plugin_Changed;
	}
	
	if(victim == boss)
	{
		if(damage > 298.0) damage = 298.0;
		if(deathSequence || (bossTarget != 0))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		else
			lastAttacker = attacker;
		
		if((GetClientHealth(boss) - RoundToNearest(damage)) <= 300)
		{
			decl Float:pos[3];
			GetClientAbsOrigin(boss, pos);
			CreateParticle("god_rays", pos);
			
			deathSequence = true;
			SetEntityHealth(boss, 50);
			
//			TF2_StunPlayer(boss, 8.0, _, TF_STUNFLAGS_BIGBONK);
//			TF2_StunPlayer(boss, 8.0, _, TF_STUNFLAG_CHEERSOUND|TF_STUNFLAG_BONKSTUCK);
			TF2_StunPlayer(boss, 8.0, _, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
			SetEntityMoveType(boss, MOVETYPE_NONE);
			SDKHook(boss, SDKHook_PreThink, OnDeathSequenceThink);
			SDKUnhook(boss, SDKHook_PreThink, OnBossPreThink);
			SDKUnhook(boss, SDKHook_PreThink, OnBossThink);
			
			EmitSoundToAll(SOUND_FINALRISE, _, _, _, _, _, 60);
			EmitSoundToAll(SOUND_FINALRISE2, _, _, _, _, _, 50);
			EmitSoundToAll(SOUND_FINALRISE2, _, _, _, _, _, 50);
			EmitSoundToAll(SOUND_FINALRISE2, _, _, _, _, _, 50);
			EmitSoundToAll(SOUND_FINALRISE2, _, _, _, _, _, 50);
			CreateTimer(0.2, Timer_BossBoom);
			CreateTimer(8.0, Timer_EndDeath);
			
			for(new i=1; i<=GetMaxClients(); i++)
			{
				if(!IsValidEntity(i)) continue;
				if(!IsClientInGame(i)) continue;
				StopSound(i, SNDCHAN_AUTO, SOUND_MUSIC);
			}
			
			if(musicTimer != INVALID_HANDLE)
			{
				KillTimer(musicTimer);
				musicTimer = INVALID_HANDLE;
			}
			
			if(hudTimer != INVALID_HANDLE)
			{
				KillTimer(hudTimer);
				hudTimer = INVALID_HANDLE;
			}
			damage = 0.0;
			return Plugin_Changed;
		}
		if(bossShield > 0)
		{
			decl Float:pos[3];
			GetClientAbsOrigin(boss, pos);
			damage *= 0.05;
			bossShield -= RoundToCeil(damage);
			EmitAmbientSound(shieldSounds[GetRandomInt(0, (sizeof(shieldSounds)-1))], pos);
			CreateParticle("impact_glass", pos);
			if(bossShield <= 0)
			{
				bossShield = 0;
				PrintCenterTextAll("%s's shield is down!", bossInfo[bossType][iName]);
				EmitSoundToAll(SOUND_SHIELD_DEAD, _, _, _, _, _, 70);
				EmitSoundToAll(SOUND_SHIELD_DEAD, _, _, _, _, _, 70);
				CreateTimer(16.0, Timer_Shield); 
				ClientCommand(boss, "r_screenoverlay 0");
			}
		}
		
		new percent = RoundToCeil((float(GetClientHealth(boss))/float(bossInfo[bossType][iHealth])) * 255);
		SetEntProp(healthbar, Prop_Send, "m_iBossHealthPercentageByte", percent);
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:Timer_Shield(Handle:timer)
{
	if(deathSequence || boss == 0) return;
	bossShield = bossInfo[bossType][iShield];
	ClientCommand(boss, "r_screenoverlay effects/combine_binocoverlay");
	EmitSoundToAll(SOUND_SHIELD_ONLINE, _, _, _, _, _, 40);
	EmitSoundToAll(SOUND_SHIELD_ONLINE, _, _, _, _, _, 40);
	EmitSoundToAll(SOUND_SHIELD_ONLINE, _, _, _, _, _, 40);
	PrintCenterTextAll("%s's shield has recharged!", bossInfo[bossType][iName]);
}

public Action:Timer_Laughsplosion(Handle:timer, any:client)
{
	if(!IsPlayerAlive(client)) return;
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	EmitAmbientSound(SOUND_CUTE, pos);
	CreateParticle("finishline_confetti", pos);
	CreateParticle("xms_snowburst", pos);
	ForcePlayerSuicide(client);
}

public FreezePlayer(client, Float:duration)
{
	decl Float:origin[3];
	GetClientAbsOrigin(client, origin);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 128);
	CreateTimer(duration, Timer_Unfreeze, client);
	EmitAmbientSound(SOUND_FREEZE, origin);
	CreateParticle("teleportedin_blue", origin);
	CreateParticle("xms_snowburst", origin);
}

public OnBossThink(client)
{
	if(bossType != BOSS_FREELANCE)
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", bossInfo[bossType][iSpeed]);
	else
	{
		switch(freelanceType)
		{
			case 0: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 350.0);
			case 1: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
			case 2: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 260.0);
		}
	}
	
	new weapon = Client_GetActiveWeapon(client);
	if(IsValidEntity(weapon))
	{
		Weapon_SetPrimaryClip(weapon, 99);
		Weapon_SetPrimaryAmmoCount(weapon, 99);
	}
	if(bossShield > 0)
	{
		ClientCommand(client, "r_screenoverlay effects/combine_binocoverlay");
	}
}

public OnBossPreThink(client)
{
	if(boss == 0)
	{
		SDKUnhook(client, SDKHook_PreThink, OnBossPreThink);
		return;
	}
	
	new buttons = GetClientButtons(client); // ABILITIES
	if(buttons & IN_ATTACK2)
	{
		switch(bossType)
		{
			case BOSS_PSYCHE:
			{
				decl Float:origin[3], Float:angles[3], Float:endPos[3];
				GetClientEyePosition(client, origin);
				GetClientEyeAngles(client, angles);
				new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(endPos, trace);
					if(GetVectorDistance(origin, endPos) < 2024.0)
					{
						TeleportPlayer(client, endPos);
						CreateTimer(7.0, Timer_AltWait, client);
					}
					else
					{
						PrintToChat(client, "Too far!");
						CreateTimer(0.5, Timer_AltWait, client);
					}
				}
			}
			case BOSS_CREEPER:
			{
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				EmitAmbientSound(SOUND_CREEPER, pos);
				EmitAmbientSound(SOUND_CREEPER, pos);
				CreateTimer(1.0, Timer_Creeper, client);
				CreateTimer(4.0, Timer_AltWait, client);
			}
			case BOSS_BLACK:
			{
				decl Float:origin[3], Float:angles[3], Float:pos[3];
				GetClientEyePosition(client, origin);
				GetClientEyeAngles(client, angles);
				new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
				
				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(pos, trace);
					User_PlaceBomb(client, BOMBTYPE_NORMAL, pos);
				}
				CreateTimer(3.0, Timer_AltWait, client);			
			}
			
			case BOSS_PIANO:
			{
				decl Float:bossPos[3], Float:pos[3];
				GetClientAbsOrigin(boss, bossPos);
				
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsValidEntity(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(i == boss) continue;
					
					GetClientAbsOrigin(i, pos);
					if(GetVectorDistance(bossPos, pos) <= 1024.0)
					{
						Client_Shake(i, _, 32.0, 255.0, 5.0);
						Entity_Hurt(i, 40, boss, DMG_NERVEGAS, "tremble_clef");
					}
				}
				EmitSoundToAll(SOUND_PIANO, _, _, _, _, _, 150);
				EmitSoundToAll(SOUND_PIANO, _, _, _, _, _, 150);
				CreateTimer(5.0, Timer_AltWait, client);
			}
			
			case BOSS_COW:
			{
				decl Float:bossPos[3], Float:pos[3];
				GetClientAbsOrigin(boss, bossPos);
				
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsValidEntity(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(i == boss) continue;
					
					GetClientAbsOrigin(i, pos);
					if(GetVectorDistance(bossPos, pos) <= 1024.0)
					{
						Client_Shake(i, _, 64.0, 255.0, 3.0);
						Entity_Hurt(i, 26, boss, DMG_NERVEGAS, "udder_destruction");
						TF2_AddCondition(i, TFCond_Milked, 5.4);
					}
				}
				EmitSoundToAll(SOUND_COW);
				EmitSoundToAll(SOUND_COW);
				EmitSoundToAll(SOUND_COW);
				EmitSoundToAll(SOUND_COW);
				CreateTimer(3.0, Timer_AltWait, client);
			}
			
			case BOSS_HARDWARE:
			{
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				
				new ent = CreateEntityByName("obj_sentrygun"); 
				DispatchSpawn(ent); 
				TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_bPlacing"), 0, 2); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_bBuilding"), 0, 2); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_bDisabled"), 0, 2); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iObjectType"), 3); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iState"), 1); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iTeamNum"), 2); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iUpgradeMetal"), 0); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_bHasSapper"), 0, 2); 
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_hBuilder"), client, 1); 
				
				if(bossShield > 200)
				{
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iUpgradeLevel"), 1, 4);
					SetEntityModel(ent, MODEL_SENTRY1);
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iHealth"), 300, 4); 
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iMaxHealth"), 300, 4);
				}
				else if(bossShield > 50)
				{
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iUpgradeLevel"), 2, 4);
					SetEntityModel(ent, MODEL_SENTRY2);
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iHealth"), 400, 4); 
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iMaxHealth"), 400, 4);
				}
				else
				{
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iUpgradeLevel"), 3, 4);
					SetEntityModel(ent, MODEL_SENTRY3);
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iHealth"), 500, 4); 
					SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iMaxHealth"), 500, 4);
				}
				
				SetEntData(ent, FindSendPropOffs("CObjectSentrygun", "m_iAmmoShells"), 500, 4);  
				SetEntDataFloat(ent, FindSendPropOffs("CObjectSentrygun", "m_flPercentageConstructed"), 1.0);
				SetEntityHealth(ent, 1000);
				CreateTimer(5.0, Timer_AltWait, client);
			}
			
			case BOSS_KING:
			{
				TF2_AddCondition(client, TFCond_Charging, 2.0);
				CreateTimer(7.0, Timer_AltWait, client);
			}
			
			case BOSS_EAGLE:
			{
				decl Float:pos[3], Float:vel[3];
				GetClientAbsOrigin(client, pos);
				EmitAmbientSound(SOUND_FALCON, pos);
				EmitAmbientSound(SOUND_FALCON, pos);
				pos[2] += 1.0;
				vel[2] = 800.0;
				TeleportEntity(client, pos, NULL_VECTOR, vel);
				CreateTimer(8.0, Timer_AltWait, client);
				CreateParticle("asplode_hoodoo_dust", pos);
				CreateParticle("asplode_hoodoo_embers", pos);
			}
			
			case BOSS_SNOW:
			{
				decl Float:bossPos[3], Float:pos[3];
				GetClientAbsOrigin(boss, bossPos);
				
				TE_SetupBeamRingPoint(bossPos, 10.0, 768.0, beamSprite, haloSprite, 0, 15, 1.0, 32.0, 0.5, {128, 192, 255, 255}, 10, 0);
				TE_SendToAll();
				EmitAmbientSound(SOUND_FROST, bossPos);
				EmitAmbientSound(SOUND_FROST, bossPos);
				
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsValidEntity(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(boss == i) continue;
					GetClientAbsOrigin(i, pos);
					if(GetVectorDistance(bossPos, pos) <= 768.0)
					{
						FreezePlayer(i, 4.0);
					}
				}
				CreateTimer(8.0, Timer_AltWait, client);
			}
			
			case BOSS_NINJA:
			{
				new target = GetClientAimTarget(client);
				if(target != -1)
				{
					bossTarget = target;
					EmitSoundToAll(darkAuraSounds[GetRandomInt(0, 2)]);
					SetEntityMoveType(client, MOVETYPE_NONE);
					SetEntityMoveType(target, MOVETYPE_NONE);
					Client_ScreenFade(client, 100, FFADE_IN, -1, 0, 0, 0, 200);
					Client_ScreenFade(target, 100, FFADE_IN, -1, 0, 0, 0, 200);
					
					//particles, rise
					
					CreateTimer(GetRandomFloat(4.0, 8.0), Timer_Showdown, bossTarget);
					CreateTimer(10.0, Timer_AltWait, client);
				}
				else
					CreateTimer(1.0, Timer_AltWait, client);
			}
			
			case BOSS_ADVENTURE:
			{
				decl Float:bossPos[3];
				GetClientAbsOrigin(boss, bossPos);
				EmitAmbientSound(SOUND_FUS, bossPos, boss);
				EmitAmbientSound(SOUND_FUS, bossPos, boss);
				EmitAmbientSound(SOUND_FUS, bossPos, boss);
				
				CreateTimer(0.5, Timer_Fus, client);
				CreateTimer(8.0, Timer_AltWait, client);
			}
			
			case BOSS_F2P:
			{
				TF2_AddCondition(client, TFCond_Charging, 3.0);
				CreateTimer(10.0, Timer_AltWait, client);
			}
			
			case BOSS_SHARK:
			{
				decl Float:pos[3];
				decl Float:pos2[3];
				
				new duration = 6 + 4;
				
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				for(new i=1;i<=MaxClients;i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
						if ((GetVectorDistance(pos,pos2)<600))
						{
							SDKHook(i, SDKHook_PreThink, DrownEvent);
						}
					}	
				}
				CreateTimer(float(duration), EndDrowning);
				CreateTimer(20.0, Timer_AltWait, client);
			}
			
			case BOSS_FREELANCE:
			{
				freelanceType++;
				if(freelanceType > 2)
					freelanceType = 0;
				
				switch(freelanceType)
				{
					case 0: SetEntityRenderColor(boss, 0, 255, 0, 255);
					case 1: SetEntityRenderColor(boss, 0, 0, 255, 255);
					case 2: SetEntityRenderColor(boss, 255, 0, 0, 255);
				}
				
				CreateTimer(2.0, Timer_AltWait, client);
			}
			
			case BOSS_TESLA:
			{
				decl Float:bossPos[3], Float:pos[3];
				GetClientAbsOrigin(boss, bossPos);
				
				new ent = CreateEntityByName("point_tesla");
				DispatchKeyValue(ent, "m_flRadius", "512.0");
				DispatchKeyValue(ent, "beamcount_min", "18");
				DispatchKeyValue(ent, "beamcount_max", "22");
				DispatchKeyValue(ent, "texture", "sprites/physbeam.vmt");
				DispatchKeyValue(ent, "m_Color", "255 255 255");
				DispatchKeyValue(ent, "thick_min", "1.0");
				DispatchKeyValue(ent, "thick_max", "10.0");
				DispatchKeyValue(ent, "lifetime_min", "0.3");
				DispatchKeyValue(ent, "lifetime_max", "0.3");
				DispatchKeyValue(ent, "interval_min", "0.1");
				DispatchKeyValue(ent, "interval_max", "0.2");
				DispatchSpawn(ent);
				
				TeleportEntity(ent, bossPos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(ent, "DoSpark"); 
				
				CreateTimer(1.0, Timer_Remove, ent);
				
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsValidEntity(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(boss == i) continue;
					GetClientAbsOrigin(i, pos);
					if(GetVectorDistance(bossPos, pos) <= 512.0)
					{
						TF2_StunPlayer(i, GetRandomFloat(2.0, 5.0), _, TF_STUNFLAG_NOSOUNDOREFFECT);
						Entity_Hurt(i, GetRandomInt(8, 16), boss, DMG_SHOCK, "tesla_coil");
					}
				}
				CreateTimer(8.0, Timer_AltWait, client);
			}
			
			case BOSS_STALKER:
			{
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsValidEntity(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					TF2_AddCondition(client, TFCond_Cloaked, -1.0);
//					PrintCenterText(client, "You are Invisible for 10 seconds.");
					CreateTimer(9.0, Timer_Appear, client);
					
					EmitSoundToAll(SOUND_INVISIBLE);
					EmitSoundToAll(SOUND_LAUGH);
					
					TF2_RemoveCondition(client, TFCond_Buffed);
					TF2_RemoveCondition(client, TFCond_MegaHeal);
					TF2_RemoveCondition(client, TFCond_OnFire);
					
					SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 200.0);
					SetEntProp(client, Prop_Send, "m_CollisionGroup", 10);
					SetEntProp(client, Prop_Data, "m_takedamage", 0);
				}
				CreateTimer(30.0, Timer_AltWait, client);
			}
		}
		SDKUnhook(client, SDKHook_PreThink, OnBossPreThink);
	}
}

public Action:Timer_Appear(Handle:timer, any:client)
{
	decl Float:bossPos[3], Float:pos[3];
	GetClientAbsOrigin(boss, bossPos);
	
	EmitSoundToAll(SOUND_BOO);
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(boss == i) continue;
		
		SetEntProp(i, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(i, Prop_Send, "m_CollisionGroup", 5);
		
		GetClientAbsOrigin(i, pos);
		if(GetVectorDistance(bossPos, pos) <= 768.0)
		{
			TF2_StunPlayer(i, 6.0, 0.3, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_SLOWDOWN);
		}
	}
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		
		if(i == boss)
		{
			TF2_RemoveCondition(i, TFCond_Cloaked);
			TF2_AddCondition(i, TFCond_Buffed, 9999.0);
			TF2_AddCondition(i, TFCond_MegaHeal, 9999.0);
			SetEntProp(i, Prop_Send, "m_CollisionGroup", 5);
			SetEntProp(i, Prop_Data, "m_takedamage", 2);
			SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 200.0);
		}
	
	}
}

public DrownEvent(client)
{
	PrintCenterText(client, "You feel wet...");
	SetEntProp(client, Prop_Send, "m_nWaterLevel", 3);    
}

public Action:EndDrowning(Handle:timer)
{
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_PreThink, DrownEvent);
		}
	}
}

public Action:Timer_Remove(Handle:timer, any:ent)
{
	AcceptEntityInput(ent, "Kill");
}

public Action:Timer_Fus(Handle:timer, any:client)
{
	PrintToChatAll("Fus");
	decl Float:pos[3], Float:bossPos[3];
	GetClientAbsOrigin(boss, bossPos);
	TE_SetupBeamRingPoint(bossPos, 10.0, 2048.0, beamSprite, haloSprite, 0, 15, 1.0, 32.0, 0.5, {255, 200, 100, 255}, 10, 0);
	TE_SendToAll();
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(boss == i) continue;
		
		GetClientAbsOrigin(i, pos);
		if(GetVectorDistance(bossPos, pos) <= 1024.0)
		{
			decl Float:ang[3], Float:vel[3], Float:vec[3];
			GetClientAbsAngles(client, ang);
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
			GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
			vel[0] += vec[0] * 1024.0;
			vel[1] += vec[1] * 1024.0;
			vel[2] = 512.0;
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vel);
			TF2_StunPlayer(i, 1.2, _, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT, boss);
			Client_Shake(i, _, _, 255.0, 1.0);
		}
	}
	Client_Shake(boss, _, _, 255.0, 1.0);
}

public Action:Timer_Showdown(Handle:timer, any:client)
{
//	PrintToChatAll("test3");
	new Handle:menu = CreateMenu(Menu_Showdown);
	SetMenuTitle(menu, "Showdown");
	SetMenuExitButton(menu, false);
	
	new correct = GetRandomInt(1, 6);
	for(new i=1; i<=6; i++)
	{
		decl String:display[32];
		if(i != correct)
			Format(display, sizeof(display), "Miss");
		else
			Format(display, sizeof(display), "Strike");
			
		AddMenuItem(menu, display, display);
	}
	
	DisplayMenu(menu, boss, 5);
	DisplayMenu(menu, client, 5);
}

public Menu_Showdown(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(bossTarget == 0)
			return;
		
		decl String:info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		if(StrEqual(info, "Strike"))
		{
			if(client == boss)
			{
				PrintToChatAll("Ninja strikes.");
				Entity_Hurt(bossTarget, 1000, boss, DMG_CLUB, "showdown");
			}
			else
			{
				PrintToChatAll("Prisoner strikes.");
				Entity_Hurt(boss, 1000, client, DMG_CLUB, "showdown");
			}
			
		}
		else
		{
			if(client == boss)
			{
				PrintToChatAll("Ninja misses.");
				Entity_Hurt(boss, 1000, client, DMG_CLUB, "showdown");
			}
			else
			{
				PrintToChatAll("Prisoner misses.");
				Entity_Hurt(bossTarget, 1000, boss, DMG_CLUB, "showdown");
			}
		}
		EmitSoundToAll(SOUND_SLICE);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	
	bossTarget = 0;
	SetEntityMoveType(boss, MOVETYPE_WALK);
	SetEntityMoveType(client, MOVETYPE_WALK);
	Client_ScreenFade(client, 100, FFADE_IN, -1, 0, 0, 0, 0);
	Client_ScreenFade(boss, 100, FFADE_IN, -1, 0, 0, 0, 0);
}

public Action:Timer_Creeper(Handle:timer, any:client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	EmitAmbientSound(SOUND_EXPLODE, pos);
	CreateExplosion(pos, client, _, 200);
}

public Action:Timer_AltWait(Handle:timer, any:client)
{
	SDKHook(client, SDKHook_PreThink, OnBossPreThink);
	EmitSoundToClient(client, SOUND_CHARGED);
}

public Action:Timer_Explode(Handle:timer, any:client)
{
	if(!IsPlayerAlive(client)) return;
	
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	EmitAmbientSound(SOUND_EXPLODE, pos);
	
	CreateExplosion(pos);
}

public Action:Timer_Grenade(Handle:timer, any:client)//Demo grenades
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	User_PlaceBomb(client, BOMBTYPE_NORMAL, pos);
}

public Action:Timer_Unfreeze(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 0);
}

public OnDeathSequenceThink(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 0.7;
//	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public Action:Timer_BossBoom(Handle:timer)
{
	if(!deathSequence)
	{
		KillTimer(timer);
		return;
	}
	decl Float:pos[3];
	GetClientAbsOrigin(boss, pos);
	pos[0] += GetRandomFloat(-32.0, 32.0);
	pos[1] += GetRandomFloat(-32.0, 32.0);
	pos[2] += GetRandomFloat(-32.0, 96.0);
	CreateParticle("ExplosionCore_MidAir", pos);
	CreateParticle("Explosions_MA_Dustup_2", pos);
	EmitAmbientSound(explodeSounds[GetRandomInt(0, (sizeof(explodeSounds)-1))], pos);
	CreateTimer(GetRandomFloat(0.2, 1.0), Timer_BossBoom);
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		Client_Shake(i, _, 16.0, _, 1.0);
	}
}

public Action:Timer_EndDeath(Handle:timer)
{
	if(healthbar != 0)
	{
		RemoveEdict(healthbar);
		healthbar = 0;
	}
	
	decl Float:pos[3];
	GetClientAbsOrigin(boss, pos);
	CreateParticle("fireSmokeExplosion3", pos);
	EmitAmbientSound(SOUND_FINALEXPLODE, pos);
	
	SetEntPropFloat(boss, Prop_Send, "m_flModelScale", 1.0);
	SetEntPropFloat(boss, Prop_Send, "m_flStepSize", 18.0);
	
	SetVariantString("");
	AcceptEntityInput(boss, "SetCustomModel");
	
//	if(bossType == BOSS_DYS)
//		RemoveNormalSoundHook(SoundHook_Normal);
	
	deathSequence = false;
	SDKUnhook(boss, SDKHook_PreThink, OnDeathSequenceThink);
//	ServerCommand("mp_scrambleteams 1");
	ServerCommand("mp_disable_respawn_times 1");
	ServerCommand("mp_respawnwavetime 0");
	ServerCommand("sm plugins load shapeshift");
	ServerCommand("sm plugins load friendly");
	SetEntityRenderColor(boss, 255, 255, 255, 255);
	SetEntityRenderMode(boss, RENDER_NORMAL);
	SetEntityGravity(boss, 1.0);
	SetEntProp(boss, Prop_Send, "m_bGlowEnabled", 0, 1);
	EmitSoundToAll(SOUND_END);
//	PrintToChatAll("\x04A new Boss Battle Will Happen After 3 Hours!");
	CreateTimer(14400.0, Timer_Ask);
	PrintCenterTextAll("%s has been defeated!", bossInfo[bossType][iName]);
	PrintToChatAll("%N dealt the finishing blow", lastAttacker);
	SetClientInfo(boss, "name", oldName);
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		ClientCommand(boss, "r_screenoverlay 0");
		Client_Shake(i, _, _, _, 5.0);
		SetEntityRenderColor(i, 255, 255, 255, 255);
		FakeClientCommand(i, "voicemenu 2 4");
		
		if(i == boss) continue;
	}
	if(hudTimer != INVALID_HANDLE)
	{
		KillTimer(hudTimer);
		hudTimer = INVALID_HANDLE;
	}
	CreateExplosion(pos);
	boss = 0;
	
	decl String:className[64], String:entname[64];
	for(new i=1; i<=GetMaxEntities(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, className, sizeof(className));
			if(StrEqual(className, "func_door"))
			{
				GetEntPropString(i, Prop_Data, "m_iName", entname, sizeof(entname));
				if(StrEqual(entname, "deathmatch_lock", false)) 
				{
					AcceptEntityInput(i, "Open");
				}
			}
		}
	}
}

public EndBoss()
{
	if(healthbar != 0)
	{
		RemoveEdict(healthbar);
		healthbar = 0;
	}
	
	boss = 0;
	deathSequence = false;
//	TF2_StunPlayer(boss, 8.0, _, TF_STUNFLAG_CHEERSOUND|TF_STUNFLAG_BONKSTUCK);
	TF2_StunPlayer(boss, 8.0, _, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
//	ServerCommand("mp_scrambleteams 1");
	ServerCommand("mp_disable_respawn_times 1");
	ServerCommand("mp_respawnwavetime 0");
	ServerCommand("sm plugins load shapeshift");
	PrintCenterTextAll("%s has been disconnected!", bossInfo[bossType][iName]);
	CreateTimer(14400.0, Timer_Ask);
	EmitSoundToAll(SOUND_END);
//	if(bossType == BOSS_DYS)
//		RemoveNormalSoundHook(SoundHook_Normal);
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		ClientCommand(boss, "r_screenoverlay 0");
		SetEntityRenderColor(i, 255, 255, 255, 255);
		FakeClientCommand(i, "voicemenu 2 3");
	}
	if(hudTimer != INVALID_HANDLE)
	{
		KillTimer(hudTimer);
		hudTimer = INVALID_HANDLE;
	}
	if(musicTimer != INVALID_HANDLE)
	{
		KillTimer(musicTimer);
		musicTimer = INVALID_HANDLE;
	}
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(boss != 0 && client != boss && GetClientTeam(client) == 2 && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
	{
		ChangeClientTeam(client, 3);
		PrintToChat(client, "\x04There is a Boss Battle in progress.");
		PrintToChat(client, "\x04You cannot join that team right now.");
	}
	else if(boss != 0 && client != boss)
	{
		CreateTimer(1.0, Timer_BringToArena, client);
	}
}

public Action:Timer_BringToArena(Handle:timer, any:client)
{
//	decl Float:pos[3] = POSITION_SPAWN;
//	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public Native_IsBossBattle(Handle:plugin, numParams)
{
	return (boss != 0);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsBossBattle", Native_IsBossBattle);
	return APLRes_Success;
}

/*
TODO

Spy Boss that is invisible and upon becoming visible the "BOO" sound plays and players around him are scared and are thrown in the opposite direction of him


PotWalrus ||HCC||: Niin siis mun kaverin idea oli Spy, jolla on revolveri ja puukko, ei kelloja, sillä ei oo aluks sitä vihreetä glowia
 ja se olis alussa sillei himmeen läpinäkyvä, mutta sillei että sen voi nähdä kuitenkin. Kun sitä ampuu, nii se saa sen vihreen glowin
 ja kuuluu sama ääni, kuin Metal Geareissa, kun Solid Snake nähdään.
 
PotWalrus ||HCC||: Ja silloin kun sitä ei oo nähty, sillä olis critit
PotWalrus ||HCC||: Ability vois olla sillei että muuttuu läpinäkyväks, menettää vihreen glowin ja saa damage resistantin hetkeks
 ja tyyliin 5 sec jälkeen muuttuu samanlaiseks kuin alussa, sen voi nähä jotenkuten ja sillä on critit. Sit sen voi taas nähä. Ja se menettää critit.
 
PotWalrus ||HCC||: Se oli ilonen siihen mun toiseen ideaan. Se läpinäkyvyys ja damage resistant
PotWalrus ||HCC||: Stalker?
PotWalrus ||HCC||: Kaveri kysy, oisko L ètranger mahollinen
PotWalrus ||HCC||: Ja Black Rose

*/