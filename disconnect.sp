#pragma semicolon 1

#include <sourcemod>
#include <steamtools>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

//http://backpack.tf/api/users
//http://backpack.tf/api/IGetUsers/v3/?steamids=76561198025371616
//backpack_value = refined * 0.255(refinedin arvo USD)

//513ae98dba2536e05300000e

new bool:ShouldBeAnnounced[MAXPLAYERS+1];
new bool:PrivateBackpack[MAXPLAYERS+1];
new SteamLevel[MAXPLAYERS+1];
new TF2Hours[MAXPLAYERS+1];
new TF2Items[MAXPLAYERS+1];
new TF2Value[MAXPLAYERS+1];

public OnPluginStart() 
{
	HookEvent("player_disconnect", 	OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnClientAuthorized(client, const String:auth[]) 
{
	ShouldBeAnnounced[client] = true;
	PrivateBackpack[client] = false;
	SteamLevel[client] = -1;
	TF2Hours[client] = -1;
	TF2Items[client] = -1;
	TF2Value[client] = -1;
	
	if(IsFakeClient(client) || StrEqual(auth, "BOT", false)) 
	{
		return;
	}
		
	decl String:steamid[64];
	Steam_GetCSteamIDForClient(client, steamid, sizeof(steamid));
	
	//Get clients Steam LVL
	/*
	new Handle:Rekest = Steam_CreateHTTPRequest(HTTPMethod_GET, "http://api.steampowered.com/IPlayerService/GetSteamLevel/v0001/");
	
	Steam_SetHTTPRequestGetOrPostParameter(Rekest, "key", "584A7508A22A45AA36042E9A02F52ACF");
	Steam_SetHTTPRequestGetOrPostParameter(Rekest, "steamid", steamid);
	Steam_SetHTTPRequestGetOrPostParameter(Rekest, "format", "vdf");
	Steam_SendHTTPRequest(Rekest, OnSteamAPI, GetClientUserId(client));*/
	
	//Get clients TF2 Hours
	new Handle:Rekest2 = Steam_CreateHTTPRequest(HTTPMethod_GET, "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/");
	
	Steam_SetHTTPRequestGetOrPostParameter(Rekest2, "key", "584A7508A22A45AA36042E9A02F52ACF");
	Steam_SetHTTPRequestGetOrPostParameter(Rekest2, "steamid", steamid);
	Steam_SetHTTPRequestGetOrPostParameter(Rekest2, "format", "vdf");
	Steam_SetHTTPRequestGetOrPostParameter(Rekest2, "include_played_free_games", "1");
	Steam_SendHTTPRequest(Rekest2, OnSteamAPI2, GetClientUserId(client));
	
	//Get the amount of items the client has & if their backpack is private
	new Handle:Rekest3 = Steam_CreateHTTPRequest(HTTPMethod_GET, "http://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001/");
	http://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001/?key=584A7508A22A45AA36042E9A02F52ACF&steamid=76561198025371616&format=vdf
	Steam_SetHTTPRequestGetOrPostParameter(Rekest3, "key", "584A7508A22A45AA36042E9A02F52ACF");
	Steam_SetHTTPRequestGetOrPostParameter(Rekest3, "steamid", steamid);
	Steam_SetHTTPRequestGetOrPostParameter(Rekest3, "format", "vdf");
	Steam_SendHTTPRequest(Rekest3, OnSteamAPI3, GetClientUserId(client));
	
	//Get the value of a players backpack
	new HTTPRequestHandle:request = Steam_CreateHTTPRequest(HTTPMethod_GET, "http://backpack.tf/api/IGetUsers/v3/");

	Steam_SetHTTPRequestGetOrPostParameter(request, "steamids", steamid);
	Steam_SetHTTPRequestGetOrPostParameter(request, "format", "vdf");
	Steam_SendHTTPRequest(request, OnBackpackTFComplete, GetClientUserId(client));
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) < 2)
		return; // Spawning into spectate or Unassigned
		
	if(ShouldBeAnnounced[client])
	{
		if(TF2Items[client] == -1)
		{
			CPrintToChatAllEx(client, "{lime}I| {teamcolor}%N{default} has clocked {lime}%i{default} hours on TF2{default}", client, TF2Hours[client]);
		}
		else
		{
			if(!PrivateBackpack[client])
			{
				CPrintToChatAllEx(client, "{lime}I| {teamcolor}%N{default} has clocked {lime}%i{default} hours on TF2 {unique}(%i Items {selfmade}%i${unique}){default}", client, TF2Hours[client], TF2Items[client], TF2Value[client]);
			}
			else
			{
				CPrintToChatAllEx(client, "{lime}I| {teamcolor}%N{default}'s Backpack is {strange}Private{default}!", client);
			}
		}
			
		ShouldBeAnnounced[client] = false;
	}
}

public OnSteamAPI(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:statusCode, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if(client == 0) 
	{
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	if(!successful || statusCode != HTTPStatusCode_OK) 
	{
		if(successful && (_:statusCode < 500 || _:statusCode >= 600)) 
			LogError("%L Steam API error. Request %s, status code %d.", client, successful ? "successful" : "unsuccessful", _:statusCode);

		Steam_ReleaseHTTPRequest(request);
		return;
	}
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/steamlevel.txt");
	
	Steam_WriteHTTPResponseBody(request, path);
	Steam_ReleaseHTTPRequest(request);
	
	new Handle:kv = CreateKeyValues("response");
	
	if(!FileToKeyValues(kv, path)) 
	{
		LogError("%L Steam API returned invalid KeyValues.", client);
		CloseHandle(kv);
		return;
	}
	
	new status = KvGetNum(kv, "player_level");
	CloseHandle(kv);
	SteamLevel[client] = status;
}

public OnSteamAPI2(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:statusCode, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if(client == 0) 
	{
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	if(!successful || statusCode != HTTPStatusCode_OK) 
	{
		if(successful && (_:statusCode < 500 || _:statusCode >= 600)) 
			LogError("%L Steam API error. Request %s, status code %d.", client, successful ? "successful" : "unsuccessful", _:statusCode);

		Steam_ReleaseHTTPRequest(request);
		return;
	}
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/tf2hours.txt");
	
	Steam_WriteHTTPResponseBody(request, path);
	Steam_ReleaseHTTPRequest(request);
	
	new Handle:kv = CreateKeyValues("response");
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv))
		return;
	
	decl String:strSection[255];
	
	do
	{
		KvGetSectionName(kv, strSection, sizeof(strSection));    // == game_count OR games
		
		if(StrEqual("games", strSection, true)) //Not sure if it does work .-.
		{
			if (!KvGotoFirstSubKey(kv))
			{
				LogError("Steam API returned invalid KeyValues. (Empty file)");
				return;
			}
			
			do
			{
				decl String:appid[10];
				decl String:playtime_forever[255];
				
				KvGetString(kv, "appid", appid, sizeof(appid));
				if(StringToInt(appid) == 440)
				{
					KvGetString(kv, "playtime_forever", playtime_forever, sizeof(playtime_forever));
					TF2Hours[client] = StringToInt(playtime_forever) / 60;
				//	PrintToChatAll("Parsing KeyValue playtime_forever for %N: %s", client, playtime_forever);
					break;
				}
				
			} while (KvGotoNextKey(kv));
		}
		
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

public OnSteamAPI3(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:statusCode, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if(client == 0) 
	{
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	if(!successful || statusCode != HTTPStatusCode_OK) 
	{
		if(successful && (_:statusCode < 500 || _:statusCode >= 600)) 
			LogError("%L Steam API error. Request %s, status code %d.", client, successful ? "successful" : "unsuccessful", _:statusCode);

		Steam_ReleaseHTTPRequest(request);
		return;
	}
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/tf2items.txt");

	Steam_WriteHTTPResponseBody(request, path);
	Steam_ReleaseHTTPRequest(request);
	
	new Handle:kv = CreateKeyValues("response");
	FileToKeyValues(kv, path);
	
	new status = KvGetNum(kv, "status");	//Is the players backpack private?
	if(status == 15)
	{
		PrivateBackpack[client] = true;
		CloseHandle(kv);					//No need to keep the handle open anymore as were not gonna parse it anymore
		return;								//Yeah.
	}
	
	if (!KvGotoFirstSubKey(kv))
		return;
	
	decl String:strSection[255];
	decl String:strSection2[255];
	
	do
	{
		KvGetSectionName(kv, strSection, sizeof(strSection));
		
		if(StrEqual("items", strSection, true))
		{
			if (!KvGotoFirstSubKey(kv))
			{
				LogError("Steam API returned invalid KeyValues. (Empty file)");
			//	PrintToChatAll("Steam API returned invalid KeyValues. (Empty file)");
				return;
			}
			
			do
			{
				if(!KvGotoNextKey(kv))	//End of items section
				{
					KvGetSectionName(kv, strSection2, sizeof(strSection2));
					
				//	PrintToChatAll("Reached last KeyValue of 'items'");
				//	PrintToChatAll("Section: %s", strSection2);
					
					TF2Items[client] = StringToInt(strSection2) + 1;
				}
				
			} while (KvGotoNextKey(kv));
		}
		
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

public OnBackpackTFComplete(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:status, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if(client == 0) 
	{
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	
	if(status != HTTPStatusCode_OK || !successful) 
	{
		if(status == HTTPStatusCode_BadRequest) 
		{
			LogError("backpack.tf API failed: You have not set an API key");
			Steam_ReleaseHTTPRequest(request);
			return;
		}
		else if(status == HTTPStatusCode_Forbidden) 
		{
			LogError("backpack.tf API failed: Your API key is invalid");
			Steam_ReleaseHTTPRequest(request);
			return;
		}
		else if(status == HTTPStatusCode_PreconditionFailed) 
		{
			decl String:retry[16];
			Steam_GetHTTPResponseHeaderValue(request, "Retry-After", retry, sizeof(retry));
			LogError("backpack.tf API failed: We are being rate-limited by backpack.tf, next request allowed in %s seconds", retry);
		} 
		else if(status >= HTTPStatusCode_InternalServerError) 
		{
			LogError("backpack.tf API failed: An internal server error occurred");
		} 
		else if(status == HTTPStatusCode_OK && !successful) 
		{
			LogError("backpack.tf API failed: backpack.tf returned an OK response but no data");
		}
		else if(status != HTTPStatusCode_Invalid) 
		{
			LogError("backpack.tf API failed: Unknown error (status code %d)", _:status);
		} 
		else 
		{
			LogError("backpack.tf API failed: Unable to connect to server or server returned no data");
		}
		
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/tf2value.txt");

	Steam_WriteHTTPResponseBody(request, path);
	Steam_ReleaseHTTPRequest(request);
	
	new Handle:kv = CreateKeyValues("response");
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv))
		return;
	
	decl String:strSection[255];
		
	do
	{
		KvGetSectionName(kv, strSection, sizeof(strSection)); 
		
		if(StrEqual("players", strSection, true))
		{
			if (!KvGotoFirstSubKey(kv))
			{
				PrintToChat(client, "[1] bp.tf API returned invalid KeyValues. (Empty file)");
				return;
			}
			
			do
			{
				KvGetSectionName(kv, strSection, sizeof(strSection));	//We're at 76561198025371616 [64Bit steamId]
				
				if (KvJumpToKey(kv, "backpack_value", false))
				{
					decl String:appid[10];
					KvGetString(kv, "440", appid, sizeof(appid));
					TF2Value[client] = RoundToNearest(StringToFloat(appid) * 0.25);	//FUCK YEAH!
					break;
				}
				
			} while (KvGotoNextKey(kv));
		}
	
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);
}

public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (clientId == 0)
		return Plugin_Handled;
	
	decl String:steamID[24];
	GetClientAuthString(clientId, steamID, sizeof(steamID));
	
	if (clientId == 0)
		return Plugin_Continue;
	
	new String:disconnectReason[255];
	GetEventString(event, "reason", disconnectReason, sizeof(disconnectReason));
	
	if (StrContains(disconnectReason, "Disconnect by user", false) != -1)		// User disconnected. 
		return Plugin_Handled;
	if(StrContains(disconnectReason, "Sorry, You were kicked to make room for a connecting P2P player", false) != -1)
		return Plugin_Handled;
		
	else if (StrContains(disconnectReason, "Timed out", false) != -1)
		CPrintToChatAll("{orange}%N{default} Timed out.", clientId);
	else           
		CPrintToChatAll("{orange}%N {default}: {orangered}%s{default} left the server. ({orange}%s{default})", clientId, steamID, disconnectReason);
		
	return Plugin_Continue;
}