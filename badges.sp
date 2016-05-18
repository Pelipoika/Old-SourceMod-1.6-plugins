#include <sourcemod>
#include <sdktools>
#include <colors>
#include <gmg\core>
#include <gmg\users>
#include <gmg\misc>
#include <gmg\badges>
#include <gmg\items>
#include <gmg\ranks>
#pragma semicolon 1

#define SOUND_BADGE "gmg/badge.wav"

public Plugin:myinfo = 
{
	name = "Badges",
	author = "pelipoika",
	description = "Server achievements",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_badges", Command_Badges);
	HookEvent("player_death", Event_Death);
	HookEvent("item_found", Event_Item);
	HookEvent("achievement_earned", Event_Achievement);
}

public Action:Command_Badges(client, args)
{
	new Handle:menu = CreateMenu(Menu_Badge);
	SetMenuTitle(menu, "Badges");
	for(new i=1; i<=sizeof(badgeInfo); i++)
	{
		decl String:info[8], String:display[64];
		Format(info, sizeof(info), "%i", i);
		if(User_GetBadgeAmount(client, i) != -1)
		{
			Format(display, sizeof(display), "%s (%i/%i)", badgeInfo[i][iName], User_GetBadgeAmount(client, i), badgeInfo[i][iMax]);
			AddMenuItem(menu, info, display, ITEMDRAW_DISABLED);
		}
		else
		{
			Format(display, sizeof(display), "%s (%i/%i)", badgeInfo[i][iName], badgeInfo[i][iMax], badgeInfo[i][iMax]);
			AddMenuItem(menu, info, display);
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public Menu_Badge(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:panelText[64];
		new Handle:panel = CreatePanel();
		
		Format(panelText, sizeof(panelText), "Badge Info - %s", badgeInfo[option+1][iName]);
		SetPanelTitle(panel, panelText);
		
		Format(panelText, sizeof(panelText), "%s", badgeInfo[option+1][iDesc]);
		DrawPanelText(panel, panelText);
		
		Format(panelText, sizeof(panelText), "%i/%i", badgeInfo[option+1][iMax], badgeInfo[option+1][iMax]);
		DrawPanelText(panel, panelText);
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, "Return to Badges");
		
		SendPanelToClient(panel, client, Menu_BadgeInfo, 60);
		CloseHandle(panel);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_BadgeInfo(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		ClientCommand(client, "sm_badges");
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(attacker == victim) return;
	if(attacker == 0) return;
	User_AddToBadge(victim, BADGE_STINGER, 1);
}

public Action:Event_Item(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetEventInt(event, "method") != 1) return;
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	User_AddToBadge(client, BADGE_PRIME, 1);
	User_GiveCoins(client, 3, COINDISPLAY_SELF);
}

public Action:Event_Achievement(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	User_AddToBadge(client, BADGE_MECHANICAL, 1);
	User_GiveCoins(client, 3, COINDISPLAY_SELF);
}

public OnMapStart()
{
	PrecacheSound(SOUND_BADGE);
}

public EarnBadge(client, id)
{
	User_SetBadgeAmount(client, id, -1);
	CPrintToChatAllEx(client, "{teamcolor}%N{default} has earned: {green}%s Badge", client, badgeInfo[id][iName]);
	EmitSoundToAll(SOUND_BADGE);
	LogToFile("logs/badges.txt", "%L earned %s", client, badgeInfo[id][iName]);
	ClientCommand(client, "sm_badges");
	ClientCommand(client, "taunt");
	User_GiveCoins(client, GetRandomInt(16, 32), COINDISPLAY_SELF);
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 64.0;
	CreateParticle("mini_fireworks", pos);
	
	decl String:query[255];
	Format(query, sizeof(query), "UPDATE users SET badge%i = -1 WHERE id = %i", id, User_GetID(client));
	QuickQuery(query);
}

public Native_EarnBadge(Handle:plugin, numParams) EarnBadge(GetNativeCell(1), GetNativeCell(2));

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("User_EarnBadge", Native_EarnBadge);
	return APLRes_Success;
}