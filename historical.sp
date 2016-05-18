#include <sourcemod>
#include <smlib>
#pragma semicolon 1

#define TOTAL_MAPS 7

new const String:g_szMapList[TOTAL_MAPS][] =
{
	"achievement_chambers_lite",
	"achievement_chambers_v24",
	"achievement_chambers_v35",
	"achievement_chambers_v46",
	"achievement_chambers_v59_remix",
	"achievement_tunnels_v16",
	"achievement_tunnels_v19"
};

new const String:g_szMapNames[TOTAL_MAPS][] =
{
	"Chamber Achievements (Lite)",
	"Chamber Achievements (Version 24)",
	"Chamber Achievements (Version 35)",
	"Chamber Achievements (Version 46)",
	"Chamber Achievements (Version 59 Remix)",
	"Tunnel Achievements (Version 16)",
	"Tunnel Achievements (Version 19)"
};

new g_iVotes[TOTAL_MAPS];

public Plugin:myinfo = 
{
	name = "Historical",
	author = "noodleboy347",
	description = "ss",
	version = "1.0",
	url = "http://www.goldenmachinegun.com"
}

public OnPluginStart()
{
	if(Server_GetPort() != 27017) SetFailState("Not Historical");
	CreateTimer(18000.0, Timer_Server);
}

public OnMapStart()
{
	for(new i=0; i<sizeof(g_iVotes); i++)
		g_iVotes[i] = 0;
}

public Action:Timer_Server(Handle:timer)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		new Handle:menu = CreateMenu(Menu_Vote);
		SetMenuTitle(menu, "Which map do you want to visit?");
		for(new j=0; j<sizeof(g_szMapNames); j++)
		{
			decl String:map[64];
			GetCurrentMap(map, sizeof(map));
			
			if(!StrEqual(map, g_szMapList[i]))
				AddMenuItem(menu, "1", g_szMapNames[i]);
			else
				AddMenuItem(menu, "1", g_szMapNames[i], ITEMDRAW_DISABLED);
		}
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, i, 60);
	}
	
	CreateTimer(60.0, Timer_VoteEnd);
}

public Menu_Vote(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		g_iVotes[option-1]++;
		PrintToChat(client, "Vote submitted.");
	}
	else if(action == MenuAction_Cancel)
		CloseHandle(menu);
}

public Action:Timer_VoteEnd(Handle:timer)
{
	new winner = 0;
	for(new i=0; i<sizeof(g_iVotes); i++)
	{
		if(g_iVotes[i] > winner)
			winner = g_iVotes[i];
	}
	if(winner == 0)
		winner = GetRandomInt(0, TOTAL_MAPS-1);
	
	PrintToChatAll("%s won the vote. Changing in 20 seconds...", g_szMapNames[winner]);
	CreateTimer(20.0, Timer_Change, winner);
}

public Action:Timer_Change(Handle:timer, any:winner)
{
	ForceChangeLevel(g_szMapList[winner], "Swap");
}