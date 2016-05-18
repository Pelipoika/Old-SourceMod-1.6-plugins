#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define MAX_ANNOTATION_COUNT 50
#define MAX_ANNOTATION_LENGTH 256
#define ANNOTATION_OFFSET 8750

new Handle:g_hViewTimer[MAXPLAYERS+1];

new bool:g_LookingAtClient[MAXPLAYERS+1];
new bool:g_AnnotationEnabled[MAX_ANNOTATION_COUNT];
new bool:g_AnnotationCanBeSeenByClient[MAX_ANNOTATION_COUNT][MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_hViewTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hViewTimer[client]);
		g_hViewTimer[client] = INVALID_HANDLE;
	}
	
	g_hViewTimer[client] = CreateTimer(0.1, Timer_ViewHud, client, TIMER_REPEAT);
	PrintToServer("Timer created");
}

public Action:Timer_ViewHud(Handle:timer, any:client)
{
	new target = GetClientAimTarget(client, false); 
	
	if(target <= 0 || target > MaxClients)
	{
		g_LookingAtClient[client] = false;
		
		for(new i; i < MAX_ANNOTATION_COUNT; i++)
		{
			if (g_AnnotationEnabled[i] && g_AnnotationCanBeSeenByClient[i][client])
			{
				Timer_ExpireAnnotation(INVALID_HANDLE, i);
			}
		}
	}
	else if(!g_LookingAtClient[client])
	{
		g_LookingAtClient[client] = true;

		new annotation_id = GetFreeAnnotationID(client);
		if(annotation_id == -1)
		{
			PrintToChat(client, "[SM] No free annotations!");
			return;
		}
		else
		{
			PrintToChatAll("ShowAnnotation(%N, %i, _)", client, annotation_id);
			g_AnnotationCanBeSeenByClient[annotation_id][client] = true;
			g_AnnotationEnabled[annotation_id] = true;
			ShowAnnotation(client, target, annotation_id, "Such Annotation\nOnly took 2 days to figure all this shit out\nWow\nI am frustrate.");
		}
	}
}

public GetFreeAnnotationID(client)
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) continue;
		return i;
	}
	return -1;
}

ShowAnnotation(client, target, annotation_id, const String:text[]) 
{ 
	new Handle:event = CreateEvent("show_annotation"); 
	if(event == INVALID_HANDLE) return; 

	SetEventInt(event, "follow_entindex", target); 
	SetEventFloat(event, "lifetime", 999999.0);
	SetEventInt(event, "id", annotation_id * MAXPLAYERS + target + ANNOTATION_OFFSET);
	SetEventString(event, "text", text);
	SetEventString(event, "play_sound", "vo/null.wav");
	SetEventString(event, "show_effect", "1");
	SetEventInt(event, "visibilityBitfield", (1 << client));
	
	FireEvent(event);
}

public HideAnnotationFromPlayer(client, annotation_id)
{
	new Handle:event = CreateEvent("hide_annotation");
	if (event == INVALID_HANDLE) return;
	
	SetEventInt(event, "id", annotation_id * MAXPLAYERS + client + ANNOTATION_OFFSET);
	FireEvent(event);
	
	PrintToChatAll("[SM] HideAnnotationFromPlayer(%N, %i)", client, annotation_id);
}

public Action:Timer_ExpireAnnotation(Handle:timer, any:annotation_id)
{	
	for(new client = 1; client < MaxClients; client++)
	{
		PrintToChatAll("[SM] Timer_ExpireAnnotation(timer, %i)", annotation_id);
		HideAnnotationFromPlayer(client, annotation_id);
		g_AnnotationCanBeSeenByClient[annotation_id][client] = false;
		g_AnnotationEnabled[annotation_id] = false;
	}	
	return Plugin_Handled;
}