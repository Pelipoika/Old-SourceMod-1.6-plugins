#include <sourcemod>
#include <sdktools>
#include <steamtools>
#pragma semicolon 1

new String:g_szBuying[MAXPLAYERS+1][64];
new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_footsounds", OnPoserCmd, ADMFLAG_CUSTOM6, "Footstep sounds list.");
	RegAdminCmd("sm_footsound", Command_Buying, ADMFLAG_CUSTOM2);
	
	AddNormalSoundHook(SoundHook);
}

public OnConfigsExecuted()
{
	g_hPoseMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(g_hPoseMenu, "-- Footstep Sounds --");
	AddMenuItem(g_hPoseMenu, "1", "Nothing to see here");
}

public OnClientPostAdminCheck(client)
{
	g_szBuying[client] = "";
}

public Action:Command_Buying(client, args)
{
	GetCmdArgString(g_szBuying[client], sizeof(g_szBuying[]));
	StripQuotes(g_szBuying[client]);
	TrimString(g_szBuying[client]);
	
	ReplyToCommand(client, "You have set your footstep sound to:");
	ReplyToCommand(client, "\"%s\"", g_szBuying[client]);
	
	return Plugin_Handled;
}

public Action:OnPoserCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_footsound_access", ADMFLAG_CUSTOM6))
	{
		ReplyToCommand(client, "[SM] You don't have acces to this command.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "Cannot use command from RCON.");
		return Plugin_Handled;
	}
	DisplayMenuSafely(g_hPoseMenu, client);
	return Plugin_Handled;
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		switch (param2)
		{
			case 0:
            {
				
				DisplayMenuSafely(g_hPoseMenu, param1);
            }
		}
	}
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (IsValidEntity(ent) && ent < 1 || ent > MaxClients || channel < 1)
		return Plugin_Continue;
		
	if (IsValidClient(ent))
	{
		if (StrContains(sound, "player/footsteps/", false) != -1)
		{
			Format(sound, sizeof(sound), g_szBuying[ent]);
			pitch = GetRandomInt(50, 150);
			EmitSoundToAll(sound, ent);//, _, _, _, 0.25, pitch);
			return Plugin_Changed;
		}
		PrecacheSound(sound);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if (client != 0)
    {
        if (menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open FootSounds Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}

public OnMapEnd()
{
    if (g_hPoseMenu != INVALID_HANDLE)
    {
        CloseHandle(g_hPoseMenu);
        g_hPoseMenu = INVALID_HANDLE;
    }
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}