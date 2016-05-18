#include <sourcemod>
#include <sdktools>
#include <scp>

public Plugin:myinfo = 
{
	name = "[TF2] Various chat things",
	author = "Pelipoika",
	description = "Changes messages prefixed with > to green.",
	version = "1.0",
	url = "forums.alliedmodders.com"
}

public OnMapStart()
{
	PrecacheSound("ui/message_update.wav");
}

public OnPluginStart()
{
//	AddCommandListener(Listener_Say, "say");
//	AddCommandListener(Listener_Say, "say_team");
}

public Action:OnChatMessage(&author, Handle:recepients, String:name[], String:message[]) 
{
	if (IsValidClient(author))
	{
		decl String:bit[64][11];
		ExplodeString(message, " ", bit, sizeof bit, sizeof bit[]);
		
		if(StrContains(bit[0], "/", false) != -1)
			return Plugin_Stop;
		
		if(!StrContains(bit[0], "!", false) != -1 || !StrContains(bit[0], "/", false) != -1)
		{
			if(StrContains(bit[0], "sell", false) != -1)
				Format(name, MAXLENGTH_NAME, "\x05[Sell] %s\x01", name);
			else if(StrContains(bit[0], "buy", false) != -1)
				Format(name, MAXLENGTH_NAME, "\x05[Buy] %s\x01", name);
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Handled;
}

public Action:Listener_Say(client, const String:command[], argc)
{
	if(!client || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;
	
	decl String:strChat[100];
	GetCmdArgString(strChat, sizeof(strChat));
	new iStart;
	if(strChat[iStart] == '"') iStart++;
	if(strChat[iStart] == '!') iStart++;
	new iLength = strlen(strChat[iStart]);
	if(strChat[iLength+iStart-1] == '"')
	{
		strChat[iLength--+iStart-1] = '\0';
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}