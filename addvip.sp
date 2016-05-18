#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Add Donator",
	author = "Array",
	description = "Adds a donator to admins.cfg",
	version = "",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_adddonator", Command_AddDonator, ADMFLAG_ROOT, "Adds a donator to admins.cfg.");
}

public Action:Command_AddDonator(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_adddonator <steamid> <name>");
		return Plugin_Handled;
	}

	new String:steamID[32];
	new String:clientName[128];
	GetCmdArg(1, steamID, sizeof(steamID));
	GetCmdArg(2, clientName, sizeof(clientName));

	new String:configPath[256];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/admins.cfg");

	new Handle:file = OpenFile(configPath, "r+");
	new String:formattedString[512];
	Format(formattedString, sizeof(formattedString), "\n\t\"%s\"//DONATOR\n\t{\n\t\t\"auth\"\"steam\"\n\t\t\"identity\"\"%s\"\n\t\t\"flags\"\"atbjo\"\n\t\t\"immunity\"\"40\"\n\t}\n}", clientName, steamID);
	FileSeek(file, -2, SEEK_END);
	WriteFileString(file, formattedString, false);
	CloseHandle(file);
	
	ServerCommand("sm_reloadadmins");

	return Plugin_Handled;
}