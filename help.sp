#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Help",
	author = "noodleboy347",
	description = "Info",
	version = "1.0",
	url = "http://www.goldenmachinegun.com"
}

public OnPluginStart()
{
	RegConsoleCmd("help", Command_Help);
	RegConsoleCmd("info", Command_Help);
}

public Action:Command_Help(client, args)
{
	DisplayHelpMenu(client);
	return Plugin_Handled;
}

DisplayHelpMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Help);
	SetMenuTitle(menu, "Golden Machine Gun Help Menu");
	AddMenuItem(menu, "1", "Rules");
	AddMenuItem(menu, "2", "Items");
	AddMenuItem(menu, "3", "Ranks");
	AddMenuItem(menu, "4", "Admins");
	AddMenuItem(menu, "5", "Other Servers");
	AddMenuItem(menu, "6", "Websites");
	AddMenuItem(menu, "7", "Troubleshooting");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public Menu_Help(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Server Rules");
				DrawPanelText(panel, "- No random deathmatching without a reason");
				DrawPanelText(panel, "- No exploiting the map or the game");
				DrawPanelText(panel, "- No using airblast/jarate/stunballs to grief");
				DrawPanelText(panel, "- No griefing in general");
				DrawPanelText(panel, "- No ban evasion");
				DrawPanelText(panel, "- No evading votebans/kicks/mutes");
				DrawPanelText(panel, "- No micspamming anything");
				DrawPanelText(panel, "- No spamming the chat (especially with trade requests)");
				DrawPanelText(panel, "- No ignoring/disrespecting admins");
				DrawPanelText(panel, "- No trade scamming");
				DrawPanelText(panel, "- No baiting players into killing you");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 1:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Items");
				DrawPanelText(panel, "- Found by random Pokeball drops in the servers");
				DrawPanelText(panel, "- Personal drops found every once in a while");
				DrawPanelText(panel, "- Can be used with !pack command");
				DrawPanelText(panel, "- Can be purchased with !shop command");
				DrawPanelText(panel, "- Can be traded with !stats -> Trade Item");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 2:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Ranks");
				DrawPanelText(panel, "Gold Account");
				DrawPanelText(panel, "- Obtained when you donate $5+ to GMG");
				DrawPanelText(panel, "- Access to !gold menu features");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Platinum Account");
				DrawPanelText(panel, "- Obtained via item drops");
				DrawPanelText(panel, "- Requires Gold Account");
				DrawPanelText(panel, "- Access to !platinum menu features");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Community Contributor");
				DrawPanelText(panel, "- Obtained by contributing greatly to GMG");
				DrawPanelText(panel, "- Access to infinite usage Community Item");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Administrator");
				DrawPanelText(panel, "- Obtained by submitting an application");
				DrawPanelText(panel, "- Access to admin commands and abilities");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 3:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Administrators");
				DrawPanelText(panel, "- Rule enforcers and achievement helpers");
				DrawPanelText(panel, "- Keep the servers fun and lively");
				DrawPanelText(panel, "- Occasionally host fun events");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 4:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Other Servers");
				DrawPanelText(panel, "Chamber Achievements");
				DrawPanelText(panel, "64.79.106.130:27015");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Tunnel Achievements");
				DrawPanelText(panel, "64.79.106.130:27016");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Historical Server");
				DrawPanelText(panel, "64.79.106.130:27017");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 5:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Websites");
				DrawPanelText(panel, "Official Website");
				DrawPanelText(panel, "www.goldenmachinegun.com");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Discussion Forums");
				DrawPanelText(panel, "www.goldenmachinegun.com/forums/");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "Information Wiki");
				DrawPanelText(panel, "www.goldenmachinegun.com/wiki");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 6:
			{
				new Handle:menu2 = CreateMenu(Menu_Trouble);
				SetMenuTitle(menu2, "Troubleshooting");
				AddMenuItem(menu2, "1", "Missing models/textures/sounds");
				AddMenuItem(menu2, "2", "Accessing the console");
				AddMenuItem(menu2, "3", "Forgiveness");
				SetMenuExitButton(menu2, true);
				DisplayMenu(menu2, client, 60);
			}
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_Trouble(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Missing models/textures/sounds");
				DrawPanelText(panel, "If you are missing any server materials, please go to:");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "C:\\Program Files\\Steam\\steamapps\\{name}\\team fortress 2\\tf");
				DrawPanelText(panel, "or for 64-bit users:");
				DrawPanelText(panel, "C:\\Program Files (x86)\\Steam\\steamapps\\{name}\\team fortress 2\\tf");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "and delete the following folders:");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "- materials/gmg/");
				DrawPanelText(panel, "- models/gmg/");
				DrawPanelText(panel, "- sound/gmg/");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "When you connect to the server, it will redownload the files again.");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 1:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Accessing the console");
				DrawPanelText(panel, "1) Pause (ESC)");
				DrawPanelText(panel, "2) Options");
				DrawPanelText(panel, "3) Keyboard");
				DrawPanelText(panel, "4) Advanced");
				DrawPanelText(panel, "5) Tick 'Enable developer console'");
				DrawPanelText(panel, "6) Return to game and press the ~ key under the ESC key");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
			case 2:
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Forgiveness");
				DrawPanelText(panel, "Forgiveness is a system that punishes deathmatching.");
				DrawPanelText(panel, "If you kill someone without their permission,");
				DrawPanelText(panel, "they can unforgive you, adding a warning.");
				DrawPanelText(panel, "Obtain 6 warnings and you'll be temporarily banned.");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "Back to Help");
				SendPanelToClient(panel, client, Menu_Topic, 300);
			}
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_Topic(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		DisplayHelpMenu(client);
	}
}