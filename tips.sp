#include <sourcemod>
#pragma semicolon 1

#define TIPCOLOR		"\x07FFD700"
#define TIPHIGHLIGHT	"\x07ADE55C"

new bool:muteTips[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[TF2] Tips",
	author = "Pelipoika",
	description = "Tips",
	version = "1.0",
	url = "www.privateshit.com"
}

new const String:tips[][] =
{
	"You can recognize a moderator by the #~* in front of their name",
	"Join our Steam group @ #www.steamcommunity.com/groups/Fraglet",
	"Like this server? Add it to your #favorites!",
	"If you need some help, ask an #administrator.",
	"Want to have your idea added to the servers? Suggest it in our #group!",
	//"Want to get Donor Access? Type #!donate",
	"Type #!home* to return to your spawn.",
	"Type #!tips* to toggle tips on and off.",
	"You can use #!buy* if the map doesnt support shops.",
	//"You can give yourself a #!description*.",
	"You can use #!trade* to quickly trade someone.",
	"Engineers can pickup their dispensers by pressing #reload* on them.",
	"You can #vote* to spawn a halloween boss with #!voteboss*.",
	"You can acces your #inventory* with #!pack*.",
	"You can change your preferred backpack viewer via #!settings*.",
	"You can #vote* to change map with #!mapvote*."
	//"You can #!votemenu* to vote to get rid of annoying players."
};

public OnPluginStart()
{
	RegConsoleCmd("sm_tips", Command_Tips);
	CreateTimer(120.0, Timer_Tip);
}

public OnClientPutInServer(client)
{
	muteTips[client] = false;
}

public Action:Timer_Tip(Handle:timer)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(muteTips[i]) continue;
		
		decl String:displayTip[128];
		strcopy(displayTip, sizeof(displayTip), tips[GetRandomInt(0, (sizeof(tips)-1))]);
		ReplaceString(displayTip, sizeof(displayTip), "#", TIPHIGHLIGHT);
		ReplaceString(displayTip, sizeof(displayTip), "*", TIPCOLOR);
		PrintToChat(i, "%s%s", TIPCOLOR, displayTip);
	}
	CreateTimer(60.0, Timer_Tip);
}

public Action:Command_Tips(client, args)
{
	muteTips[client] = !muteTips[client];
	ReplyToCommand(client, "Tips have been %s.", muteTips[client] ? "disabled" : "enabled");
	return Plugin_Handled;
}