#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

new bool:g_bAutoGift[MAXPLAYERS+1];
new CurrentArrayPosition[MAXPLAYERS+1];
new Handle:g_hTelePortTimer;

new Float:koth_lakeside_event[][] =
{
	{0.863767, 673.279114, 91.031319},	
	{-57.108898, 670.744019, 91.031319},
	{76.407875, 672.885559, 91.031319},
	{-0.788521, 598.335754, 91.031319},
	{-825.747986, 866.590210, -132.968689},
	{-826.278687, 966.351685, -132.968689},
	{-822.705994, 1056.375244, -132.968689},
	{-935.576477, 1063.024902, -132.968689},
	{-934.622009, 954.442810, -132.968689},
	{-933.893188, 871.580994, -132.968689},
	{828.178894, 860.575439, -132.968750},
	{826.865966, 1011.999572, -132.968750},
	{830.427795, 1079.968750, -132.968750},
	{913.289978, 1079.456665, -132.968750},
	{912.583312, 989.462402, -132.968750},
	{911.723510, 879.966552, -132.968750},
	{979.021789, 874.405029, -120.151702},
	{981.279296, 958.592956, -132.968750},
	{981.012145, 1069.103515, -132.968750},
	{963.985839, -169.682495, -154.744750},
	{964.590759, -83.407058, -153.218383},
	{965.139526, -5.138356, -153.758590},
	{965.732299, 79.404769, -154.924057},
	{966.280456, 157.591262, -155.218017},
	{894.395324, 159.909805, -156.516799},
	{891.812255, 105.255439, -155.646438},
	{891.151733, 11.035088, -154.136795},
	{890.537780, -76.537101, -152.867507},
	{888.896728, -193.454055, -151.894088},
	{511.920745, 86.299278, -96.272659},
	{507.653869, -6.677435, -96.261032},
	{509.522766, -90.731216, -98.486785},
	{-976.198913, -178.846664, -155.448379},
	{-975.751403, -127.468566, -153.841018},
	{-973.790527, -46.789840, -153.366714},
	{-972.818481, 55.139274, -154.525863},
	{-968.038391, 143.095367, -155.170318},
	{-511.037231, 124.160118, -96.237792},
	{-513.984924, 48.252674, -96.765258},
	{-521.347229, -41.546741, -100.369979},
	{-517.754760, -119.627662, -100.942352},
	{-317.492462, -535.959289, -70.005004},
	{-396.786254, -543.460754, -84.463394},
	{-477.488739, -550.300231, -98.843490},
	{-505.514373, -583.570190, -104.228179},
	{-537.549499, -649.122314, -105.964691},
	{-568.539672, -737.240112, -110.178161},
	{-577.971862, -835.545410, -106.450698},
	{-824.494140, -835.551452, -148.562210},
	{-911.736022, -1153.024169, -130.401763},
	{-977.709533, -1089.270751, -134.803848},
	{-844.501281, -1038.117675, -135.790374},
	{11.293111, -995.585876, 91.031250},
	{390.441925, -1050.150756, 91.031250},
	{-354.791900, -1052.169677, 91.031250},
	{-3.994790, -1867.308837, 91.031250},
	{-2.232105, -1797.697143, 91.031250},
	{-94.303672, -1790.961547, 91.031250},
	{-105.870330, -1879.039428, 91.031250},
	{103.797012, -1878.802856, 91.031250},
	{94.440750, -1789.827392, 91.031250},
	{310.775939, -550.142211, -68.716232},
	{387.873352, -547.403442, -82.817550},
	{484.793487, -567.301269, -100.125015},
	{517.030212, -648.721191, -101.947952},
	{565.814697, -754.451538, -109.351043},
	{558.045410, -849.418701, -99.842666},
	{809.775573, -1131.923217, -121.628143},
	{875.689880, -1131.901489, -130.743240},
	{951.380554, -1132.937988, -131.393203},
	{977.913696, -1070.529785, -136.652008},
	{931.821838, -1018.610778, -143.057968},
	{7.774456, -843.931213, 123.031250},
	{895.823852, -1080.282958, -144.992599},
	{-976.617614, -1148.706176, -136.441360},
	{429.736694, -68.120468, 52.031250},
	{428.008209, -1.507311, 52.031250},
	{430.294433, 84.235801, 52.031250},
	{-418.669586, -78.772460, 52.031250},
	{-425.862609, -0.582819, 52.031250},
	{-410.686859, 97.384124, 52.031250},
	{1155.134155, -1372.003784, 63.322490},
	{1143.131591, -1490.259521, 74.853057},
	{1132.459716, -1605.340332, 82.657455},
	{-1157.236450, -1400.647216, 64.781524},
	{-1156.220825, -1463.532348, 72.396133},
	{-1161.180053, -1541.618164, 83.638496},
	{-186.153259, -557.041748, 59.031250},
	{-98.794044, -556.373840, 59.031250},
	{-8.780454, -559.872924, 59.031250},
	{86.292602, -561.377563, 59.031250},
	{170.102020, -562.703674, 59.031250},
	{-1133.595092, -1845.983520, 82.093399},
	{-1136.259155, -1758.659667, 86.354591},
	{-1134.010375, -1653.318481, 92.703269},
	{1152.500122, -1640.144287, 97.560424},
	{1151.844482, -1738.250244, 87.298851},
	{1135.900024, -1823.441284, 83.039154},
	{335.966369, -1064.016845, 81.031250},
	{-918.676208, 12.317320, -164.372360}
	
	/*
	{-362.000000, -1061.000000, 91.031250},
	{941.262329, -1890.707031, 77.349861},
	{931.987121, 10.022208, -154.242675},
	{-521.000000, -13.000000, -99.636245},
	{4.000000, -1826.000000, 91.031250},
	{-941.262329, -1890.707031, 77.349853},
	{-1120.027709, -1808.357421, 158.527526},
	{-944.655761, -1108.417846, -133.852325},
	{973.000000, -1144.000000, -129.949676},
	{973.000000, -1144.000000, -129.949676},
	{0.000000, -862.000000, 123.031250},
	{580.000000, -831.000000, -107.473098},
	{-575.935607, -838.613891, -60.736129},
	{-327.000000, -544.000000, -48.527702},
	{-208.000000, -526.000000, 59.031250},
	{209.000000, -524.000000, 59.031250},
	{209.000000, -524.000000, 59.031250},
	{292.000000, -549.000000, -65.289901},
	{515.000000, -12.000000, -98.114837},
	{-939.000000, -4.000000, -153.991561},
	{845.000000, 1039.000000, -94.743743},
	{845.000000, 1039.000000, -132.993743},
	{-822.000000, 1051.000000, -132.968750},
	{447.000000, -4.000000, 70.031250},
	{-362.000000, -1061.000000, 91.031250},
	*/
};

public Plugin:myinfo =
{
	name		= "[TF2] Halloween Farmer",
	author		= "Pelipoika",
	description	= "Wasting electricity",
	version		= "1.0",
	url			= ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_autogift", Command_ToggleGiftFarm, "Toggle automatic Gift Grabbing");
	RegConsoleCmd("sm_getloc", Command_GetLocation, "Prints coords to console");
	RegAdminCmd("sm_forcegift", Command_ForceGift, ADMFLAG_ROOT);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
	
	g_hTelePortTimer = CreateTimer(0.5, Timer_TeleportAllToGifts, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(30.0, Timer_AssignTeam, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnPluginEnd()
{
	if (g_hTelePortTimer != INVALID_HANDLE)
    {
        KillTimer(g_hTelePortTimer);
        g_hTelePortTimer = INVALID_HANDLE;
    }
}

public OnClientAuthorized(client)
{
	g_bAutoGift[client] = false;
	CurrentArrayPosition[client] = 0;
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname,"tf_projectile_spelltransposeteleport"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnMarkerSpawn);
    }
}

public OnMarkerSpawn(entity)
{
    if(IsValidEntity(entity))
        AcceptEntityInput(entity, "Kill");
}  

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:time[20] = "43200";
	new bool:bEntityFound = false;
	
	new entityTimer = MaxClients+1;
	while((entityTimer = FindEntityByClassname(entityTimer, "team_round_timer")) != -1)
	{
		bEntityFound = true;

		SetVariantInt(StringToInt(time));
		AcceptEntityInput(entityTimer, "SetTime");
	}

	if (!bEntityFound)
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, StringToFloat(time) / 60);
		CloseHandle(timelimit);
	}

	CPrintToChatAll("{unusual}Time was set to %i second(s)", StringToInt(time));
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	
	if (IsValidClient(client) && !(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		CPrintToChat(client, "{yellow}Type {red}!autogift{yellow} to auto farm Gifts");
		RequestFrame(Respawn, GetClientSerial(client));
	}
}

public Respawn(any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if(IsValidClient(client))
	{
		new team = GetClientTeam(client);
		if(!IsPlayerAlive(client) && team != _:TFTeam_Spectator)
		{
			TF2_RespawnPlayer(client);
		}
	}
}

public Action:Command_ToggleGiftFarm(client, args)
{
	if(IsValidClient(client))
	{
		if(g_bAutoGift[client])
		{
			CPrintToChat(client, "{yellow}Automatic Gift Grabbing: {red}Disabled");
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	//		SetEntProp(client, Prop_Send, "m_collisiongroup", 5);
	
			new flags = GetEntityFlags(client)&~FL_NOTARGET;
			SetEntityFlags(client, flags);
			
			g_bAutoGift[client] = false;
			ForcePlayerSuicide(client);
		}
		else
		{
			CPrintToChat(client, "{yellow}Automatic Gift Grabbing: {lime}Enabled");
			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	//		SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
			
			new flags = GetEntityFlags(client)|FL_NOTARGET;
			SetEntityFlags(client, flags);
	
			CurrentArrayPosition[client] = FindFreeFarmSpot(client);
			g_bAutoGift[client] = true;
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_ForceGift(client, args)
{
	if(IsValidClient(client))
	{
		if(args < 1) 
		{ 
			ReplyToCommand(client, "[SM] Usage: smforcegift <#userid|@aim|@all>"); 
			return Plugin_Handled; 
		} 

		new String:arg[MAX_NAME_LENGTH]; 
		GetCmdArg(1, arg, sizeof(arg)); 

		new String:target_name[MAX_TARGET_LENGTH]; 
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml; 

		target_count = ProcessTargetString( 
				arg, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_NO_BOTS, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml); 

		if(target_count <= 0) 
		{ 
			ReplyToTargetError(client, target_count); 
			return Plugin_Handled; 
		} 

		for (new i = 0; i < target_count; i++) 
		{ 
			CurrentArrayPosition[target_list[i]] = i;
			
			CPrintToChat(target_list[i], "{red}An administrator has forced you to Farm Gifts.");
			SetVariantInt(1);
			AcceptEntityInput(target_list[i], "SetForcedTauntCam");
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);

			new flags = GetEntityFlags(target_list[i])|FL_NOTARGET;
			SetEntityFlags(target_list[i], flags);
	
			g_bAutoGift[target_list[i]] = true;
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_GetLocation(client, args)
{
	if(IsValidClient(client))
	{
		decl Float:pos[3];
		GetClientEyePosition(client, pos);
		PrintToConsole(client, "{%f, %f, %f},", pos[0], pos[1], pos[2]);
	}
	
	return Plugin_Handled;
}

public Action:Timer_TeleportAllToGifts(Handle:timer)
{
	for(new i = 1; i <= GetMaxClients(); i++)
    {
		if(IsValidClient(i) && IsPlayerAlive(i) && g_bAutoGift[i])
		{
			new ArraySize = sizeof(koth_lakeside_event);
			PrintCenterText(i, "Location: %i / %i | Lap time: 49.5 Seconds.", CurrentArrayPosition[i], ArraySize - 1);
		
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			TF2_RemoveAllWeapons(i);
			
			decl Float:vecTpPos[3];
			vecTpPos[0] = koth_lakeside_event[CurrentArrayPosition[i]][0];
			vecTpPos[1] = koth_lakeside_event[CurrentArrayPosition[i]][1];
			vecTpPos[2] = koth_lakeside_event[CurrentArrayPosition[i]][2];
			
			vecTpPos[2] -= 64.0;
			
			TeleportEntity(i, vecTpPos, NULL_VECTOR, NULL_VECTOR);
			
			CurrentArrayPosition[i]++;
			
			if(CurrentArrayPosition[i] > sizeof(koth_lakeside_event) -1)
			{
				CurrentArrayPosition[i] = 0;
			}
		}
	}
}

public Action:Timer_AssignTeam(Handle:timer, any:data)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (client > MaxClients || client < 1 || !IsClientInGame(client) || !IsClientConnected(client))
			return Plugin_Continue;
			
		if (TFTeam:GetClientTeam(client) == TFTeam_Unassigned)
		{
			new TFTeam:Team = TFTeam_Red;
			if (GetTeamClientCount(_:TFTeam_Blue) < GetTeamClientCount(_:TFTeam_Red))
				Team = TFTeam_Blue;
				
			ChangeClientTeam(client, _:Team);
			TF2_SetPlayerClass(client, TFClassType:GetRandomInt(1, 9));
			
			PrintToChatAll("%N was automatically forced to join team %s", client, (Team == TFTeam_Red ? "RED" : "BLU"));
		}
	}
	return Plugin_Handled;
}

stock FindFreeFarmSpot(client)
{
	new freeslot = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) || i != client)
		{
			if(g_bAutoGift[i] && CurrentArrayPosition[i] == freeslot)
			{
				freeslot++;
			}
		}
	}

	return freeslot;
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}