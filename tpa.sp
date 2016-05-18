#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1

new teleHost[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Teleport Request",
	author = "Pelipoika",
	description = "Gold",
	version = "1.2.11",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_tpa", Command_Goto, ADMFLAG_CUSTOM2);
	LoadTranslations("common.phrases");
}

public OnClientPutInServer(client)
{
	teleHost[client] = 0;
}

public Action:Command_Goto(client, args)
{
	if (args > 0) 
	{
		new String:szBuffer[64];
		GetCmdArg(1, szBuffer, sizeof(szBuffer));
		new target = FindTarget(client, szBuffer, true, false);
		if (IsValidEntity(target) && target != client) 
		{
			new Handle:menu2 = CreateMenu(Menu_TeleResponse);
			SetMenuTitle(menu2, "%N wants to teleport to you.", client);
			AddMenuItem(menu2, "1", "Allow");
			AddMenuItem(menu2, "2", "Deny");
			SetMenuExitButton(menu2, true);
			DisplayMenu(menu2, target, 60);
			PrintToChat(client, "\x04A request has been sent to %N.", target);
			teleHost[target] = client;
		} 
		else GotoMenu(client);
	} 
	else GotoMenu(client);
	
	return Plugin_Handled;
}

public GotoMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Goto);
	SetMenuTitle(menu, "Teleport Menu");
	AddMenuItem(menu, "1", "Go To Player");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public Menu_Goto(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0:
			{
				new Handle:menu2 = CreateMenu(Menu_Tele);
				SetMenuTitle(menu2, "Go To Player", client);
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsValidEntity(i)) continue;
					if(!IsClientInGame(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(IsFakeClient(i)) continue;
					if(client == i) continue;
					decl String:info[8], String:display[32];
					Format(info, sizeof(info), "%i", i);
					Format(display, sizeof(display), "%N", i);
					AddMenuItem(menu2, info, display);
				}
				SetMenuExitButton(menu2, true);
				DisplayMenu(menu2, client, 60);
			}
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_Tele(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:idStr[8];
		GetMenuItem(menu, option, idStr, sizeof(idStr));
		new target = StringToInt(idStr);
		
		new Handle:menu2 = CreateMenu(Menu_TeleResponse);
		SetMenuTitle(menu2, "%N wants to teleport to you.", client);
		AddMenuItem(menu2, "1", "Allow");
		AddMenuItem(menu2, "2", "Deny");
		SetMenuExitButton(menu2, true);
		DisplayMenu(menu2, target, 60);
		PrintToChat(client, "\x04A request has been sent to %N.", target);
		teleHost[target] = client;
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_TeleResponse(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{
			decl Float:pos[3], Float:oldPos[3];
			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(teleHost[client], oldPos);
			pos[2] += 40.0;
			pos[1] += -60.0;
			if(GetClientTeam(client) != _:TFTeam_Spectator)
			{
				// NEW
				new iTeam = GetClientTeam(client);
				new iSpell = CreateEntityByName("tf_projectile_spelltransposeteleport");
			
				SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", teleHost[client]);
				SetEntPropEnt(iSpell, Prop_Send, "m_hThrower", teleHost[client]);
				SetEntProp(iSpell,	Prop_Send, "m_iTeamNum", iTeam, 1);
				SetEntProp(iSpell,	Prop_Send, "m_nSkin", (iTeam-2));
			
				DispatchSpawn(iSpell);
				
				TeleportEntity(iSpell, pos, NULL_VECTOR, NULL_VECTOR);
				//OLD
				
				//TeleportPlayer(teleHost[client], pos, true);
				PrintToChat(teleHost[client], "\x04%N has accepted your request.", client);
			}
			else
				ReplyToCommand(client, "You cannot teleport to a spectator");
		}
		else
			PrintToChat(teleHost[client], "\x04%N has denied your request.", client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}