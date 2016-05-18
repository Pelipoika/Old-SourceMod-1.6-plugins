#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <gmg\core>
#include <gmg\misc>
#pragma semicolon 1

//merasmus_tp			//Teleport
//mvm_loot_explosion	//Cool

new cmdTarget[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Generic Admin Commands",
	author = "Pelipoika",
	description = "A bunch of general admin commands",
	version = "1.3.2",
	url = "googlehammer.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_kickbyid", Command_Kickbyid, ADMFLAG_ROOT);
	RegAdminCmd("sm_kill", Command_Kill, ADMFLAG_ROOT);
	RegAdminCmd("sm_bring", Command_Teleport, ADMFLAG_ROOT);
	RegAdminCmd("sm_warp", Command_Warp, ADMFLAG_ROOT);
	RegAdminCmd("sm_crits", Command_Crits, ADMFLAG_ROOT);
	RegAdminCmd("sm_uber", Command_Uber, ADMFLAG_ROOT);
	RegAdminCmd("sm_stun", Command_Stun, ADMFLAG_ROOT);
	RegAdminCmd("sm_ignite", Command_Ignite, ADMFLAG_ROOT);
	RegAdminCmd("sm_health", Command_Health, ADMFLAG_ROOT);
	RegAdminCmd("sm_hp", Command_Health, ADMFLAG_ROOT);
	RegAdminCmd("sm_class", Command_Class, ADMFLAG_ROOT);
	RegAdminCmd("sm_team", Command_Team, ADMFLAG_ROOT);
	RegAdminCmd("sm_scramble", Command_Scramble, ADMFLAG_ROOT);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_players", Command_Players, ADMFLAG_ROOT);
	RegAdminCmd("sm_forcerestart", Command_ForceQuit, ADMFLAG_ROOT);
	RegAdminCmd("sm_update", Command_Update, ADMFLAG_ROOT);
	RegAdminCmd("sm_addcond", Command_Addcond, ADMFLAG_ROOT);
}

public OnMapStart()
{
	PrecacheSound(SOUND_TELE);
}

public Action:Command_Fly(client, args)
{	
	if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
		SetFlightType(client, MOVETYPE_NOCLIP);
	else
		SetFlightType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}

public Action:Command_Warp(client, args)
{
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You must be alive to do that.");
		return Plugin_Handled;
	}
	decl Float:origin[3], Float:angles[3], Float:endPos[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		TeleportPlayer(client, endPos, true);
	}
	return Plugin_Handled;
}

public Action:Command_Teleport(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_tele <player>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	if(targetList[0] == client)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	decl Float:origin[3], Float:angles[3], Float:endPos[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		TeleportPlayer(targetList[0], endPos, true);
		CPrintToChatAllEx(targetList[0], "{green}%N{default} teleported {teamcolor}%N", client, targetList[0]);
	}
	return Plugin_Handled;
}

public Action:Command_Kill(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_kill <player>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}

	SDKHooks_TakeDamage(targetList[0], client, client, 99999.0);
	CPrintToChatAllEx(targetList[0], "{green}%N{default} killed {teamcolor}%N", client, targetList[0]);
	
	return Plugin_Handled;
}

public Action:Command_Respawn(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_respawn <player>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	TF2_RespawnPlayer(targetList[0]);
	//CPrintToChatAllEx(targetList[0], "{green}%N{default} respawned {teamcolor}%N", client, targetList[0]);
	return Plugin_Handled;
}

public Action:Command_Crits(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_crits <player>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	TF2_AddCondition(targetList[0], TFCond_CritOnWin, -1.0);
	CPrintToChatAllEx(targetList[0], "{green}%N{default} gave crits to {teamcolor}%N", client, targetList[0]);
	return Plugin_Handled;
}

public Action:Command_Uber(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_uber <player>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	TF2_AddCondition(targetList[0], TFCond_Ubercharged, 9999.0);
	CPrintToChatAllEx(targetList[0], "{green}%N{default} ubercharged {teamcolor}%N", client, targetList[0]);
	return Plugin_Handled;
}

public Action:Command_Health(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "Usage: sm_health <player> <amount>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64], String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new health = StringToInt(arg2);
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	SetEntityHealth(targetList[0], health);
	if(health > 450)
		CPrintToChatAllEx(targetList[0], "{green}%N{default} changed {teamcolor}%N's{teamcolor} health to %i", client, targetList[0], health);
	return Plugin_Handled;
}

public Action:Command_Team(client, args)
{
	if (args != 2) 
	{
		ReplyToCommand(client, "Usage: sm_team <player> <teamid>");
		return Plugin_Handled;
	}

	decl String:szTarget[65];
	GetCmdArg(1, szTarget, sizeof(szTarget));

	decl String:szTargetName[MAX_TARGET_LENGTH+1];
	decl iTargetList[MAXPLAYERS+1], iTargetCount, bool:bTnIsMl;

	if ((iTargetCount = ProcessTargetString
	(
			szTarget,
			client,
			iTargetList,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			szTargetName,
			sizeof(szTargetName),
			bTnIsMl)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	decl String:szScore[6];
	GetCmdArg(2, szScore, sizeof(szScore));

	for (new i = 0; i < iTargetCount; i++)
	{
		ChangeClientTeam(iTargetList[i], StringToInt(szScore));
		CPrintToChatAllEx(iTargetList[i], "{green}%N{default} changed {teamcolor}%N's{default} to %i", client, iTargetList[i], StringToInt(szScore));
	}

	return Plugin_Handled;
}

public Action:Command_Class(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "Usage: sm_class <player> <classid>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64], String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new class = StringToInt(arg2);
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	TF2_SetPlayerClass(targetList[0], TFClassType:class);
	CPrintToChatAllEx(targetList[0], "{green}%N{default} changed {teamcolor}%N's{teamcolor} class to %i", client, targetList[0], class);
	return Plugin_Handled;
}

public Action:Command_Addcond(client, args)
{
	if(args != 3)
	{
		ReplyToCommand(client, "Usage: sm_addcond <player> <condid> <duration>");
		return Plugin_Handled;
	}
	
	decl String:szTarget[65], String:strCond[64], String:strDur[10];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetCmdArg(2, strCond, sizeof(strCond));
	GetCmdArg(3, strDur, sizeof(strDur));

	decl String:szTargetName[MAX_TARGET_LENGTH+1];
	decl iTargetList[MAXPLAYERS+1], iTargetCount, bool:bTnIsMl;

	if ((iTargetCount = ProcessTargetString
	(
			szTarget,
			client,
			iTargetList,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			szTargetName,
			sizeof(szTargetName),
			bTnIsMl)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	new Float:duration = StringToFloat(strDur);
	new cond = StringToInt(strCond);
	
	for (new i = 0; i < iTargetCount; i++)
	{
		if(IsValidClient(iTargetList[i]))
		{
			TF2_AddCondition(iTargetList[i], TFCond:cond, duration);
			CPrintToChatAllEx(iTargetList[i], "{green}%N{default} added condition %i to {teamcolor}%N{default} for %.2f seconds", client, cond, iTargetList[i], duration);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Stun(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "Usage: sm_stun <player> <time>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64], String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	TF2_StunPlayer(targetList[0], StringToFloat(arg2), _, TF_STUNFLAGS_NORMALBONK);
	CPrintToChatAllEx(targetList[0], "{green}%N{default} stunned {teamcolor}%N{teamcolor} for %i seconds", client, targetList[0], StringToInt(arg2));
	return Plugin_Handled;
}

public Action:Command_Ignite(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_ignite <player>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl targetList[MAXPLAYERS], String:targetName[MAX_TARGET_LENGTH], bool:tnIsMl;
	if(ProcessTargetString(arg1, client, targetList, MAXPLAYERS, 0, targetName, sizeof(targetName), tnIsMl) != 1)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	TF2_IgnitePlayer(targetList[0], client);
	CPrintToChatAllEx(targetList[0], "{green}%N{default} ignited {teamcolor}%N", client, targetList[0]);
	return Plugin_Handled;
}

public Action:Command_Scramble(client, args)
{
	ServerCommand("mp_scrambleteams 1");
	ReplyToCommand(client, "\x04Scrambling the teams...");
	CPrintToChatAll("{green}%N{default} initiated a team scramble", client);
	return Plugin_Handled;
}

public Action:Command_Noclip(client, args)
{
	PrintCenterText(client, "You're probably looking for sm_fly");
	return Plugin_Handled;
}

public Action:Command_ForceQuit(client, args)
{
	LogToFile("logs/quit.txt", "%L issued a force quit", client);
	CreateTimer(10.0, Timer_Quit);
	PrintToChatAll("\x05%N has issued a server restart.", client);
	PrintToChatAll("\x05Server will restart in 10 seconds.");
	PrintCenterTextAll("SERVER WILL RESTART IN 10 SECONDS");
	return Plugin_Handled;
}

public Action:Timer_Quit(Handle:timer)
{
	ServerCommand("quit");
}

public Action:Command_Players(client, args)
{
	new Handle:menu = CreateMenu(Menu_PlayersList);
	SetMenuTitle(menu, "Player List");
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(client)) continue;
		
		decl String:info[8], String:display[64];
		Format(info, sizeof(info), "%i", i);
		Format(display, sizeof(display), "%N", i);
		AddMenuItem(menu, info, display);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public Action:Command_Update(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_update <plugin_path>");
		ReplyToCommand(client, "Example: sm_update plugin");
		ReplyToCommand(client, "Example: sm_update gmg/items");
		return Plugin_Handled;
	}
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	ServerCommand("sm plugins reload %s", arg1);
	ReplyToCommand(client, "Attempted to update %s.smx", arg1);
	return Plugin_Handled;
}

public Menu_PlayersList(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:strTemp[8];
		GetMenuItem(menu, option, strTemp, sizeof(strTemp));
		cmdTarget[client] = StringToInt(strTemp);
		
		decl String:text[64];
		GetClientName(cmdTarget[client], text, sizeof(text));
		
		new Handle:panel = CreatePanel();
		
		GetClientName(cmdTarget[client], text, sizeof(text));
		SetPanelTitle(panel, text);
		
		GetClientAuthString(client, text, sizeof(text));
		DrawPanelText(panel, text);
		
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, "Goto");
		
		SendPanelToClient(panel, client, Menu_PlayersAction, 60);
		CloseHandle(panel);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Menu_PlayersAction(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 1:
			{
				decl Float:pos[3];
				GetClientAbsOrigin(cmdTarget[client], pos);
				if(GetClientTeam(client) != GetClientTeam(cmdTarget[client]))
					pos[2] += 128.0;
				TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

public Action:Command_Kickbyid(client, args)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		KickClient(i, "Kicked by console");
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
