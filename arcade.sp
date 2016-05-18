#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <morecolors>
#include <soundlib>
#pragma semicolon 1

#define GAME_LUCKY 0
#define GAME_RPS 1

#define RPS_HEAVY 0
#define RPS_SPY 1
#define RPS_PYRO 2

#define SOUND_HEAVY_WIN		"vo/heavy_cheers01.wav"
#define SOUND_SPY_WIN		"vo/spy_laughhappy01.wav"
#define SOUND_PYRO_WIN		"vo/pyro_laughevil01.wav"
#define SOUND_HEAVY_LOSE	"vo/heavy_yell1.wav"
#define SOUND_SPY_LOSE		"vo/spy_paincrticialdeath03.wav"
#define SOUND_PYRO_LOSE		"vo/pyro_paincrticialdeath02.wav"

#define SOUND_INSERT		"ambient/levels/labs/coinslot1.wav"
#define SOUND_TUNE			"gmg/arcade/tune.wav"
#define SOUND_WIN			"gmg/arcade/win.wav"
#define SOUND_FAIL			"gmg/arcade/fail.wav"
#define SOUND_COIN			"mvm/mvm_money_pickup.wav"
#define SOUND_MUSIC			"items/tf_music_upgrade_machine.wav"

new g_iType[MAXPLAYERS+1];
new g_iLosses[MAXPLAYERS+1];
new g_iInsertedCoins[MAXPLAYERS+1];

new const String:g_szGameName[][] =
{
	"Lucky Number",
	"Heavy-Spy-Pyro"
};

new const Float:g_vecArcadeMusicPos[] = {-2670.0, 2760.0, 64.0};

public OnPluginStart()
{
	HookEntityOutput("trigger_multiple", "OnStartTouch", StartTouch);
	HookEntityOutput("trigger_multiple", "OnStartTouchAll", StartTouchAll);
	HookEntityOutput("trigger_multiple", "OnEndTouchAll", EndTouchAll);
}

public OnMapStart()
{	
	PrecacheSound(SOUND_TUNE);
	PrecacheSound(SOUND_WIN);
	PrecacheSound(SOUND_FAIL);
	PrecacheSound(SOUND_INSERT);
	PrecacheSound(SOUND_COIN);
	PrecacheSound(SOUND_MUSIC);
	
	PrecacheSound(SOUND_HEAVY_WIN);
	PrecacheSound(SOUND_SPY_WIN);
	PrecacheSound(SOUND_PYRO_WIN);
	PrecacheSound(SOUND_HEAVY_LOSE);
	PrecacheSound(SOUND_SPY_LOSE);
	PrecacheSound(SOUND_PYRO_LOSE);
	
	/*new Handle:snd = OpenSoundFile(SOUND_MUSIC);
	CreateTimer(float(GetSoundLength(snd)), Timer_Music, _, TIMER_REPEAT);*/
}

public Action:Timer_Music(Handle:timer)
{
	EmitAmbientSound(SOUND_MUSIC, g_vecArcadeMusicPos);
}

public OnClientPutInServer(client)
{
	g_iLosses[client] = 0;
}

public StartTouch(const String:name[], caller, activator, Float:delay)
{
	decl String:entName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", entName, sizeof(entName));
	
	if(StrContains(entName, "arcade") != -1)
	{
		decl String:nameBits[2][8];
		ExplodeString(entName, "_", nameBits, 2, 8);
		TF2_StunPlayer(activator, 99999.0, _, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
		
		g_iType[activator] = StringToInt(nameBits[1])-1;
		Arcade_Init(activator);
	}
}

public StartTouchAll(const String:name[], caller, activator, Float:delay)
{
	decl String:entName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", entName, sizeof(entName));
	
	if(StrContains(entName, "arcade") != -1)
	{
		decl String:nameBits[2][8];
		ExplodeString(entName, "_", nameBits, 2, 8);
		
		decl String:lightName[64], String:corLight[64];
		Format(corLight, sizeof(corLight), "arcade_light_%s", nameBits[1]);
		new index = -1;
		while((index = FindEntityByClassname(index, "light")) != -1)
		{
			GetEntPropString(index, Prop_Data, "m_iName", lightName, sizeof(lightName));
			if(StrEqual(lightName, corLight))
				AcceptEntityInput(index, "TurnOn");
		}
	}
}

public EndTouchAll(const String:name[], caller, activator, Float:delay)
{
	decl String:entName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", entName, sizeof(entName));
	
	if(StrContains(entName, "arcade") != -1)
	{
		decl String:nameBits[2][8];
		ExplodeString(entName, "_", nameBits, 2, 8);
		
		decl String:lightName[64], String:corLight[64];
		Format(corLight, sizeof(corLight), "arcade_light_%s", nameBits[1]);
		new index = -1;
		while((index = FindEntityByClassname(index, "light")) != -1)
		{
			GetEntPropString(index, Prop_Data, "m_iName", lightName, sizeof(lightName));
			if(StrEqual(lightName, corLight))
				AcceptEntityInput(index, "TurnOff");
		}
	}
}

Arcade_Init(client)
{
	new Handle:menu = CreateMenu(Menu_Coins);
	SetMenuTitle(menu, "%s - Insert Fraglets", g_szGameName[g_iType[client]]);
	
	AddMenuItem(menu, "1", "1 Fraglet");
	AddMenuItem(menu, "5", "5 Fraglets");
	AddMenuItem(menu, "10", "10 Fraglets");
	AddMenuItem(menu, "15", "15 Fraglets");
	AddMenuItem(menu, "20", "20 Fraglets");
	
	DisplayMenu(menu, client, 300);
}

public Menu_Coins(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:info[8];
		GetMenuItem(menu, option, info, sizeof(info));
		g_iInsertedCoins[client] = StringToInt(info);
		
		if(exp[client] < g_iInsertedCoins[client])
		{
			PrintToChat(client, "\x04You don't have enough Fraglets to play.");
			PlaySound(client, SOUND_FAIL);
			LeaveMachine(client);
			return;
		}
		
		if(g_iInsertedCoins[client] != 0)
		{
			PrintToChat(client, "\x04You inserted %i Fraglets.", g_iInsertedCoins[client]);
			exp[client] -= g_iInsertedCoins[client];
		}
		
		PlaySound(client, SOUND_INSERT);
		PlaySound(client, SOUND_TUNE);
		
		new Handle:menu2 = CreateMenu(Menu_Game);
		SetMenuTitle(menu2, "%s", g_szGameName[g_iType[client]]);
		switch(g_iType[client])
		{
			case GAME_LUCKY:
			{
				AddMenuItem(menu2, "1", "1");
				AddMenuItem(menu2, "2", "2");
				AddMenuItem(menu2, "3", "3");
				AddMenuItem(menu2, "4", "4");
				AddMenuItem(menu2, "5", "5");
			}
			case GAME_RPS:
			{
				AddMenuItem(menu2, "1", "Heavy");
				AddMenuItem(menu2, "2", "Spy");
				AddMenuItem(menu2, "3", "Pyro");
			}
		}
		SetMenuExitButton(menu2, false);
		DisplayMenu(menu2, client, 300);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
		LeaveMachine(client);
}

public Menu_Game(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(g_iType[client])
		{
			case GAME_LUCKY:
			{
				new Float:random = GetRandomFloat();
				if(random <= 0.05)
				{
					new unreward = GetRandomInt(1, g_iInsertedCoins[client]);
					exp[client] -= unreward;
					LoseEffects(client);
				}
				if(random <= 0.55)
				{
					PrintToChat(client, "\x04You lose! You get nothing.");
					LoseEffects(client);
				}
				else
				{
					new reward = GetRandomInt((g_iInsertedCoins[client]+1), (g_iInsertedCoins[client] * 3));
					exp[client] += reward;
					CPrintToChatEx(client, client, "{teamcolor}%N{default} has won: {green}%i coins", client, reward);
					WinEffects(client);
					PlaySound(client, SOUND_COIN);
				}
			}
			case GAME_RPS:
			{
				new enemy = GetRandomInt(0, 2);
				if(option == RPS_HEAVY && enemy == RPS_PYRO)
				{
					PrintToChat(client, "\x01You win! \x04Heavy\x01 beats \x04Pyro\x01");
					WinRPS(client, SOUND_HEAVY_WIN, SOUND_PYRO_LOSE);
				}
				else if(option == RPS_PYRO && enemy == RPS_SPY)
				{
					PrintToChat(client, "\x01You win! \x04Pyro\x01 beats \x04Spy\x01");
					WinRPS(client, SOUND_PYRO_WIN, SOUND_SPY_LOSE);
				}
				else if(option == RPS_SPY && enemy == RPS_HEAVY)
				{
					PrintToChat(client, "\x01You win! \x04Spy\x01 beats \x04Heavy\x01");
					WinRPS(client, SOUND_SPY_WIN, SOUND_HEAVY_LOSE);
				}
				else if(option == RPS_HEAVY && enemy == RPS_SPY)
				{
					PrintToChat(client, "\x01You lose! \x04Spy\x01 beats \x04Heavy\x01");
					LoseRPS(client, SOUND_SPY_WIN, SOUND_HEAVY_LOSE);
				}
				else if(option == RPS_PYRO && enemy == RPS_HEAVY)
				{
					PrintToChat(client, "\x01You lose! \x04Heavy\x01 beats \x04Pyro\x01");
					LoseRPS(client, SOUND_HEAVY_WIN, SOUND_PYRO_LOSE);
				}
				else if(option == RPS_SPY && enemy == RPS_PYRO)
				{
					PrintToChat(client, "\x01You lose! \x04Pyro\x01 beats \x04Spy\x01");
					LoseRPS(client, SOUND_PYRO_WIN, SOUND_SPY_LOSE);
				}
				else
				{
					PrintToChat(client, "\x01It was a \x04tie\x01!");
				}
			}
		}
		Arcade_Init(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
		LeaveMachine(client);
}

WinRPS(client, const String:win[], const String:lose[])
{
	exp[client] += (g_iInsertedCoins[client]*3);
	PlaySound(client, win);
	PlaySound(client, lose);
	WinEffects(client);
}

LoseRPS(client, const String:win[], const String:lose[])
{
	LoseEffects(client);
	EmitSoundToClient(client, win);
	EmitSoundToClient(client, lose);
}

public WinEffects(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	EmitAmbientSound(SOUND_WIN, pos);
	CreateParticle("finishline_confetti", pos);
	ClientCommand(client, "taunt");
	g_iLosses[client] = 0;
}

public LoseEffects(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	EmitAmbientSound(SOUND_FAIL, pos);
	CreateParticle("env_sawblood", pos);
	Entity_Hurt(client, 5, 0, DMG_BLAST, "arcade");
	Client_Shake(client, _, 16.0, 32.0, 2.0);
	g_iLosses[client]++;
	if(g_iLosses[client] == 10)
	{
		exp[client] += 5;
		PrintToChat(client, "\x01You earned 5\x01 Fraglets as a consolation prize.");
		g_iLosses[client] = 0;
	}
}

PlaySound(client, const String:sound[], pitch=100)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	EmitAmbientSound(sound, pos, _, _, _, _, pitch);
}

LeaveMachine(client)
{
	TF2_RemoveCondition(client, TFCond_Dazed);
}