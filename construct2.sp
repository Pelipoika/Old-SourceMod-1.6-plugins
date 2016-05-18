#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <construct>

#define SOUND_DELETE	"buttons/button15.wav"
#define SOUND_ERROR		"replay/cameracontrolerror.wav"
#define SOUND_UNGRAB	"ui/item_crate_drop.wav"
#define SOUND_GRAB		"ui/item_default_pickup.wav"
#define SOUND_EDIT		"ui/item_acquired.wav"
#define SOUND_SOLID		"physics/wood/wood_solid_impact_bullet5.wav"
#define SOUND_SPAWN		"ui/chime_rd_2base_pos.wav"

new g_iOwner[2049];
new g_iPreviousColor[2049][4];
new g_iGrabbedEnt[MAXPLAYERS + 1];
new Float:g_vecSelectedPropPrevPos[MAXPLAYERS+1][3];
new Float:g_vecSelectedPropPrevAng[MAXPLAYERS+1][3];
new Float:g_fSelectedPropDist[MAXPLAYERS+1];
new Float:g_fSelectedPropAng[MAXPLAYERS+1];
new Float:g_vecLockedAng[MAXPLAYERS+1][3];
new Float:g_vecNoclipStartPos[MAXPLAYERS+1][3];
new bool:g_bInConstructZone[MAXPLAYERS+1];
new bool:g_bIsNoclipping[MAXPLAYERS+1];
new bool:g_bAlphaManip[MAXPLAYERS+1];

new String:g_sAuthID[MAXPLAYERS + 1][64];
new Handle:h_array_SpawnEnts[MAXPLAYERS + 1] = INVALID_HANDLE;

new g_particle1[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ... };
new g_particle2[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ... };

new g_iPropLimit;
new Handle:AdtPropList = INVALID_HANDLE;
new Handle:g_hPropLimit = INVALID_HANDLE;
new Handle:g_hMainMenu = INVALID_HANDLE;
new Handle:g_hControlMenu = INVALID_HANDLE;
new Handle:g_hManipMenu = INVALID_HANDLE;
new Handle:g_hPropMenu = INVALID_HANDLE;
new Handle:g_hColorMenu = INVALID_HANDLE;
new Handle:g_hResizeMenu = INVALID_HANDLE;
new Handle:g_hParticleMenu = INVALID_HANDLE;
new Handle:g_hTipsMenu = INVALID_HANDLE;
new Handle:g_hAdminMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name		= "[TF2] Construct V2",
	author		= "Pelipoika",
	description	= "Build things in a specific area",
	version		= "1.0",
	url			= "Nah"
};

//Make stacker get the max height of the prop so you dont have to tell it how to do shit.
//Add lamps/lights
//	osoitta esim johonkin nurkkaan ja valo heijastaa suoraan kohti itseäs missä seisot
//Add Gmod style rotating
//Replace disconnect saving with 5 minute timer of prop disappear.

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SaveProps", Native_SaveProps);
	CreateNative("LoadProps", Native_LoadProps);
	CreateNative("Construct_IsInZone", Native_InConstructZone);
	CreateNative("Construct_GetPropOwner", Native_GetPropOwner);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	RegConsoleCmd("construct_rotate", 		RotateEntity, 		"Rotate an entity");
	RegConsoleCmd("construct_remove", 		RemoveEntity, 		"Remove an entity, won't remove player by accident");
	RegConsoleCmd("construct_menu", 		BuildMenu,			"Spawn Menu");
	RegConsoleCmd("construct_spawnitem", 	SpawnItem,			"Spawn a prop_dynamic entity");
	RegConsoleCmd("construct_listmyspawns", SpawnList,			"List your spawns");
	RegConsoleCmd("construct_removeall", 	DeleteMySpawns,		"Remove all your spawned items");
	RegConsoleCmd("construct_removelast", 	RemoveLastSpawn,	"Remove your last spawn");
	RegConsoleCmd("construct_removefirst", 	RemoveFirstSpawn,	"Remove your first spawn");
	RegConsoleCmd("construct_save", 		Save_Prop,			"Save your props");
	RegConsoleCmd("construct_load", 		Load_Prop,			"Load your props");
	RegConsoleCmd("construct_autobuild",	Command_Stack, 		"Stacker tool");
	RegConsoleCmd("construct_noclip",		Construct_Noclip,	"Noclip for the construction zone");
	RegConsoleCmd("construct_alpha",		Construct_Alpha,	"Do you want your props to become see through on grab?");
	
	RegConsoleCmd("entitiesdump",			DumpEntities);
	
	g_hPropLimit = CreateConVar("construct_proplimit", "70", 	"This sets the number of props players can spawn.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_hPropLimit, OnSettingsChange);
	g_iPropLimit = GetConVarInt(g_hPropLimit);
	
	AdtPropList = ConvertAndSortArray(g_sPropList);
	
	for(new i = 1; i <= MAXPLAYERS; i++) 
	{
		if(IsValidClient(i))
			OnClientPutInServer(i);
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerDeath);
}

public OnClientDisconnect(client)
{
	if(IsValidEntity(g_iGrabbedEnt[client]))
	{
		SDKUnhook(client, SDKHook_PreThink, PropManip);
		AcceptEntityInput(g_iGrabbedEnt[client], "Kill");
	}
	if (IsValidEntity(g_particle1[client]))
	{
		AcceptEntityInput(g_particle1[client], "Kill");
		g_particle1[client] = INVALID_ENT_REFERENCE;
	}
	if (IsValidEntity(g_particle2[client]))
	{
		AcceptEntityInput(g_particle2[client], "Kill");
		g_particle2[client] = INVALID_ENT_REFERENCE;
	}
	
	if(h_array_SpawnEnts[client] != INVALID_HANDLE && GetArraySize(h_array_SpawnEnts[client]) > 0)
	{
		SaveProps(client, "disconnect");
		
		while(GetArraySize(h_array_SpawnEnts[client]))
		{
			if(IsValidEntity(GetArrayCell(h_array_SpawnEnts[client], 0)))
			{
				g_iOwner[GetArrayCell(h_array_SpawnEnts[client], 0)] = -1;
				AcceptEntityInput(GetArrayCell(h_array_SpawnEnts[client], 0), "Kill");
			}
		
			RemoveFromArray(h_array_SpawnEnts[client], 0);
		}
		
		CloseHandle(h_array_SpawnEnts[client]);
	}
	
	g_iGrabbedEnt[client] = -1;
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		decl String:sAuth[64];
		GetClientAuthString(client, sAuth, sizeof(sAuth)-1);

		ReplaceString(sAuth, sizeof(sAuth)-1, ":", "-");
		FormatEx(g_sAuthID[client], sizeof(g_sAuthID[]), "%s", sAuth);
		
		g_iGrabbedEnt[client] = -1;
		g_bInConstructZone[client] = false;
		g_bIsNoclipping[client] = false;
		g_bAlphaManip[client] = false;
		g_fSelectedPropAng[client] = 0.0;
		g_fSelectedPropDist[client] = 0.0;
		h_array_SpawnEnts[client] = CreateArray();
	}
}

public OnMapStart()
{
	for(new i=0; i<sizeof(g_sPropList); i++)
		PrecacheModel(g_sPropList[i][0]);
		
	PrecacheSound(SOUND_DELETE);
	PrecacheSound(SOUND_ERROR);
	PrecacheSound(SOUND_SOLID);
	PrecacheSound(SOUND_EDIT);
	PrecacheSound(SOUND_GRAB);
	PrecacheSound(SOUND_UNGRAB);
	PrecacheSound(SOUND_SPAWN);
}

public OnConfigsExecuted()
{
	g_hMainMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(g_hMainMenu, "[Construct] Build Menu");
	AddMenuItem(g_hMainMenu, "1", "Controlls");
	AddMenuItem(g_hMainMenu, "2", "Manipulate prop");
	AddMenuItem(g_hMainMenu, "3", "Proplist");
	AddMenuItem(g_hMainMenu, "4", "Color prop");
	AddMenuItem(g_hMainMenu, "5", "Resize Prop");
	AddMenuItem(g_hMainMenu, "6", "Add a particle");
	AddMenuItem(g_hMainMenu, "7", "Toggle prop collision");
	AddMenuItem(g_hMainMenu, "8", "Straighten Prop");
	AddMenuItem(g_hMainMenu, "9", "Construct information & Tips");
	AddMenuItem(g_hMainMenu, "10", "Admin controlls");
	SetMenuExitButton(g_hMainMenu, true);
	
	g_hControlMenu = CreateMenu(MenuControlHandler);
	SetMenuTitle(g_hControlMenu, "[Construct] Controls");
	AddMenuItem(g_hControlMenu, "construct_removefirst",	"Remove your first spawn");
	AddMenuItem(g_hControlMenu, "construct_removelast",		"Remove your last spawn");
	AddMenuItem(g_hControlMenu, "construct_remove",			"Remove object aiming at");
	AddMenuItem(g_hControlMenu, "construct_noclip",			"Toggle noclip");
	AddMenuItem(g_hControlMenu, "construct_alpha",			"Toggle grab alpha");
	AddMenuItem(g_hControlMenu, "construct_listmyspawns",	"List Your Spawned");
	AddMenuItem(g_hControlMenu, "construct_removeall",		"Remove all your spawned items");
	SetMenuExitBackButton(g_hControlMenu, true); 
	
	g_hManipMenu = CreateMenu(MenuManipHandler);
	SetMenuTitle(g_hManipMenu, "WASD = Move Forward/Left/Back/Right\nJump + Duck = Move Up/Down\nAlt-Fire + Mouse = Rotate\nAlt-Fire + Mouse + Reload = Rotate without up/down");
	AddMenuItem(g_hManipMenu, "1", "Save");
	AddMenuItem(g_hManipMenu, "2", "Revert");
	SetMenuExitBackButton(g_hManipMenu, false); 
	SetMenuExitButton(g_hManipMenu, false);
	
	g_hPropMenu = CreateMenu(MenuPropHandler);
	SetMenuTitle(g_hPropMenu, "[Construct] Proplist");
	for(new i = 0; i < GetArraySize(AdtPropList); i++)
		AddMenuItem(g_hPropMenu, GetModelFromArray(AdtPropList, i), GetNameFromArray(AdtPropList, i));
	/*for(new i=0; i<sizeof(g_sPropList); i++)
		AddMenuItem(g_hPropMenu, g_sPropList[i][PROP_PATH], g_sPropList[i][PROP_NAME]);*/
	SetMenuExitBackButton(g_hPropMenu, true); 

	g_hColorMenu = CreateMenu(MenuColorHandler);
	SetMenuTitle(g_hColorMenu, "[Construct] Color Modifier");
	AddMenuItem(g_hColorMenu, "1", "Normal");
	AddMenuItem(g_hColorMenu, "2", "Red");
	AddMenuItem(g_hColorMenu, "3", "Green");
	AddMenuItem(g_hColorMenu, "4", "Blue");
	AddMenuItem(g_hColorMenu, "5", "Yellow");
	AddMenuItem(g_hColorMenu, "6", "Pink");
	AddMenuItem(g_hColorMenu, "7", "Cyan");
	AddMenuItem(g_hColorMenu, "8", "Black");
	AddMenuItem(g_hColorMenu, "9", "See-Through");
	AddMenuItem(g_hColorMenu, "10", "Desaturate");
	SetMenuExitBackButton(g_hColorMenu, true); 
	
	g_hResizeMenu = CreateMenu(MenuResizeHandler);
	SetMenuTitle(g_hResizeMenu, "Construction - Size Modifier");
	AddMenuItem(g_hResizeMenu, "0.5", "Size 0.5x");
	AddMenuItem(g_hResizeMenu, "0.6", "Size 0.6x");
	AddMenuItem(g_hResizeMenu, "0.7", "Size 0.7x");
	AddMenuItem(g_hResizeMenu, "0.8", "Size 0.8x");
	AddMenuItem(g_hResizeMenu, "0.9", "Size 0.9x");
	AddMenuItem(g_hResizeMenu, "1.0", "Size 1.0x");
	AddMenuItem(g_hResizeMenu, "1.1", "Size 1.1x");
	AddMenuItem(g_hResizeMenu, "1.2", "Size 1.2x");
	AddMenuItem(g_hResizeMenu, "1.3", "Size 1.3x");
	AddMenuItem(g_hResizeMenu, "1.4", "Size 1.4x");
	AddMenuItem(g_hResizeMenu, "1.5", "Size 1.5x");
	AddMenuItem(g_hResizeMenu, "1.6", "Size 1.6x");
	AddMenuItem(g_hResizeMenu, "1.7", "Size 1.7x");
	AddMenuItem(g_hResizeMenu, "1.8", "Size 1.8x");
	AddMenuItem(g_hResizeMenu, "1.9", "Size 1.9x");
	AddMenuItem(g_hResizeMenu, "2.0", "Size 2.0x");
	SetMenuExitBackButton(g_hResizeMenu, true); 
	
	g_hParticleMenu = CreateMenu(MenuParticleHandler);
	SetMenuTitle(g_hParticleMenu, "[Construct] Particle Effects");
	AddMenuItem(g_hParticleMenu, "halloween_ghost_smoke",		"Clear particle");
	AddMenuItem(g_hParticleMenu, "community_sparkle", 			"Community Sparkle");
	AddMenuItem(g_hParticleMenu, "ghost_pumpkin", 				"Horsemann Flames");
	AddMenuItem(g_hParticleMenu, "ghost_pumpkin_blueglow",	 	"Horsemann Blue Glow");
	AddMenuItem(g_hParticleMenu, "burningplayer_red", 			"Burningplayer Flames RED");
	AddMenuItem(g_hParticleMenu, "burningplayer_blue", 			"Burningplayer Flames BLUE");
	AddMenuItem(g_hParticleMenu, "burningplayer_rainbow", 		"Burningplayer Rainbow");
	AddMenuItem(g_hParticleMenu, "burningplayer_rainbow_red",	"Burningplayer Rainbow RED");
	AddMenuItem(g_hParticleMenu, "burningplayer_rainbow_blue",	"Burningplayer Rainbow BLUE");
	AddMenuItem(g_hParticleMenu, "hwn_skeleton_glow_blue", 		"Blue Skeleton Glow");
	AddMenuItem(g_hParticleMenu, "hwn_skeleton_glow_red", 		"Red Skeleton Glow");
	AddMenuItem(g_hParticleMenu, "halloween_pickup_active",		"Halloween Gift");
	SetMenuExitBackButton(g_hParticleMenu, true); 
	
	g_hTipsMenu = CreatePanel(g_hTipsMenu);
	DrawPanelText(g_hTipsMenu, "[Construct] Tips 'n tricks \n \n");
	DrawPanelItem(g_hTipsMenu, "Close \n \n");
	DrawPanelText(g_hTipsMenu, "You can save your props with !construct_save <savename>");
	DrawPanelText(g_hTipsMenu, "You can load your save with !construct_load <savename>");
	DrawPanelText(g_hTipsMenu, "Saves are map specific. \n \n");
	DrawPanelText(g_hTipsMenu, "You can stack props using !construct_autobuild <amount> <x> <y> <z>");
	DrawPanelText(g_hTipsMenu, "For example: !construct_autobuild 5 0 0 100");
	DrawPanelText(g_hTipsMenu, "Would build 5 props up with 100 hammer units between each one. \n \n");
	DrawPanelText(g_hTipsMenu, "If you crash you can load your props back by typing !construct_load disconnect");
	DrawPanelText(g_hTipsMenu, "This loads the last props you had on the map before you left the server.");
	
	g_hAdminMenu = CreateMenu(MenuAdminHandler);
	SetMenuTitle(g_hAdminMenu, "[Construct] Admin Menu");
	AddMenuItem(g_hAdminMenu, "1", "Remove all of aimed props owners props");
	AddMenuItem(g_hAdminMenu, "2", "Remove aimed prop");
	AddMenuItem(g_hAdminMenu, "3", "Grab aimed user");
	SetMenuExitBackButton(g_hAdminMenu, true); 
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		switch (param2)
		{
			case 0: DisplayMenuSafely(g_hControlMenu, param1);
			case 1: StartManipulation(param1);
			case 2: DisplayMenuSafely(g_hPropMenu, param1);
			case 3: DisplayMenuSafely(g_hColorMenu, param1);
			case 4: DisplayMenuSafely(g_hResizeMenu, param1);
			case 5: DisplayMenuSafely(g_hParticleMenu, param1);
			case 6: ToggleAimCollision(param1);
			case 7: StraightenAimProp(param1);
			case 8: SendPanelToClient(g_hTipsMenu, param1, MenuTipHandled, MENU_TIME_FOREVER);
			case 9: DisplayMenuSafely(g_hAdminMenu, param1);
		}
	}
}

public MenuControlHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public StartManipulation(client)
{
	if (IsAccessGranted(client))
	{
		new target = GetClientAimTarget(client, false);
		
		if(IsValidEntity(target) && g_iOwner[target] == client)
		{
			//bombonomicon_spell_trail
			AttachControlPointParticle(client, "bombonomicon_spell_trail", target);
			new Float:vecPlayerPos[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", vecPlayerPos);

			g_iGrabbedEnt[client] = target;
			GetEntPropVector(g_iGrabbedEnt[client], Prop_Data, "m_angRotation", g_vecSelectedPropPrevAng[client]);
			GetEntPropVector(g_iGrabbedEnt[client], Prop_Data, "m_vecOrigin", 	g_vecSelectedPropPrevPos[client]);

			new Float:vecTempAng[3];
			new Float:vecTempPos[3];

			SubtractVectors(g_vecSelectedPropPrevPos[client], vecPlayerPos, vecTempPos);
			GetVectorAngles(vecTempPos, vecTempAng);

			g_fSelectedPropAng[client] = vecTempAng[1];
			g_fSelectedPropDist[client] = GetVectorLength(vecTempPos);
			
			g_iGrabbedEnt[client] = target;

			SetEntProp(g_iGrabbedEnt[client], Prop_Data, "m_CollisionGroup", 1);
			if(g_bAlphaManip[client])
			{
				SetEntityRenderFx(g_iGrabbedEnt[client], RENDERFX_DISTORT);
				SetEntityRenderColor(g_iGrabbedEnt[client], 0, 255, 0, 128);
			}

			SetEntityMoveType(client, MOVETYPE_NONE);
			SDKHook(client, SDKHook_PreThink, PropManip);
			EmitAmbientSound(SOUND_GRAB, g_vecSelectedPropPrevPos[client], target);
			
			DisplayMenuSafely(g_hManipMenu, client);
		}
		else
		{
			EmitSoundToClient(client, SOUND_ERROR);
			CPrintToChat(client, "{unique}[Construct]{default} {fullred}Error{default}: Hey!, That's not yours");
			DisplayMenuSafely(g_hMainMenu, client);
		}
	}
}

public MenuManipHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new zone = -1;
		while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != -1)
		{
			decl String:sTargetName[256];
			GetEntPropString(zone, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
			
			if(StrContains(sTargetName, "sm_devzone construct", false) != -1)
			{
				new Float:m_vecAreaMins[3], Float:m_vecAreaMaxs[3], Float:m_vecAreaOrigin[3], Float:m_vecPropOrigin[3];
				
				GetEntPropVector(zone, Prop_Send, "m_vecMins", m_vecAreaMins);
				GetEntPropVector(zone, Prop_Send, "m_vecMaxs", m_vecAreaMaxs);
				GetEntPropVector(zone, Prop_Data, "m_vecOrigin", m_vecAreaOrigin);
				GetEntPropVector(g_iGrabbedEnt[param1], Prop_Data, "m_vecOrigin", m_vecPropOrigin);

				for (new i = 0; i <= 2; i++)
				{
					m_vecAreaMins[i] = m_vecAreaOrigin[i] + m_vecAreaMins[i];
					m_vecAreaMaxs[i] = m_vecAreaOrigin[i] + m_vecAreaMaxs[i];
				}
				
				if(IsPropInSideZone(m_vecPropOrigin, m_vecAreaMins, m_vecAreaMaxs))
				{
					g_fSelectedPropAng[param1] = 0.0;
					g_fSelectedPropDist[param1] = 0.0;
					if(g_bIsNoclipping[param1])
						SetEntityMoveType(param1, MOVETYPE_NOCLIP);
					else
						SetEntityMoveType(param1, MOVETYPE_WALK);
						
					if (IsValidEntity(g_particle1[param1]))
					{
						AcceptEntityInput(g_particle1[param1], "Kill");
						g_particle1[param1] = INVALID_ENT_REFERENCE;
					}
					if (IsValidEntity(g_particle2[param1]))
					{
						AcceptEntityInput(g_particle2[param1], "Kill");
						g_particle2[param1] = INVALID_ENT_REFERENCE;
					}
						
					SDKUnhook(param1, SDKHook_PreThink, PropManip);
					DisplayMenuSafely(g_hMainMenu, param1);
					
					if(param2 == 1)
						TeleportEntity(g_iGrabbedEnt[param1], g_vecSelectedPropPrevPos[param1], g_vecSelectedPropPrevAng[param1], NULL_VECTOR);
						
					if (g_iGrabbedEnt[param1] != -1 && IsValidEntity(g_iGrabbedEnt[param1]))
					{
						if (g_iPreviousColor[g_iGrabbedEnt[param1]][0] == 255)
							SetEntityRenderFx(g_iGrabbedEnt[param1], RENDERFX_NONE);
						else
							SetEntityRenderMode(g_iGrabbedEnt[param1], RENDER_TRANSALPHA);
					
						SetEntityRenderColor(g_iGrabbedEnt[param1], g_iPreviousColor[g_iGrabbedEnt[param1]][0], g_iPreviousColor[g_iGrabbedEnt[param1]][1], g_iPreviousColor[g_iGrabbedEnt[param1]][2], g_iPreviousColor[g_iGrabbedEnt[param1]][3]);
						
						new Float:m_vecMins[3], Float:m_vecMaxs[3], Float:endpos[3], Float:position[3];
						GetEntPropVector(g_iGrabbedEnt[param1], Prop_Send, "m_vecMins", m_vecMins);
						GetEntPropVector(g_iGrabbedEnt[param1], Prop_Send, "m_vecMaxs", m_vecMaxs);
						GetEntPropVector(g_iGrabbedEnt[param1], Prop_Send, "m_vecOrigin", position);
						
						endpos[0] = position[0];
						endpos[1] = position[1];
						endpos[2] = position[2] += m_vecMaxs[2];
						
						AcceptEntityInput(g_iGrabbedEnt[param1], "DisableMotion");
						AcceptEntityInput(g_iGrabbedEnt[param1], "EnableCollision");
						AcceptEntityInput(g_iGrabbedEnt[param1], "TurnOn");
						EmitAmbientSound(SOUND_UNGRAB, position, g_iGrabbedEnt[param1]);
						
						TR_TraceHullFilter(endpos, position, m_vecMins, m_vecMaxs, MASK_SOLID, TraceFilterClients, g_iGrabbedEnt[param1]);
						if(TR_DidHit())
						{
							new String:class[32];
							new object = TR_GetEntityIndex();
							GetEntityClassname(object, class, sizeof(class));

							if(StrContains(class, "player") != -1)
							{
								CreateTimer(5.0, Timer_ReTrace, EntIndexToEntRef(g_iGrabbedEnt[param1]));
								SetEntProp(g_iGrabbedEnt[param1], Prop_Data, "m_CollisionGroup", 1);
								CPrintToChat(param1, "{unique}[Construct]{default} %N is in the way", object);
							}
							else
							{
								EmitAmbientSound(SOUND_SOLID, position, g_iGrabbedEnt[param1]);
								SetEntProp(g_iGrabbedEnt[param1], Prop_Data, "m_CollisionGroup", 0);
								TE_ParticleToAll("ping_circle", position, position, NULL_VECTOR, g_iGrabbedEnt[param1], _, _, false);
							}
						}
						else
						{
							EmitAmbientSound(SOUND_SOLID, position, g_iGrabbedEnt[param1]);
							SetEntProp(g_iGrabbedEnt[param1], Prop_Data, "m_CollisionGroup", 0);
							TE_ParticleToAll("ping_circle", position, position, NULL_VECTOR, g_iGrabbedEnt[param1], _, _, false);
						}
					}
					
					g_iGrabbedEnt[param1] = -1;
				}
				else
				{
					EmitSoundToClient(param1, SOUND_ERROR);
					CPrintToChat(param1, "{unique}[Construct]{default} {fullred}ERROR{default}: Can't place that there");
					
					DisplayMenuSafely(g_hManipMenu, param1);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public MenuPropHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
	//	FakeClientCommand(param1, "construct_spawnitem a %s", g_sPropList[param2][PROP_PATH]);
		FakeClientCommand(param1, "construct_spawnitem a %s", GetModelFromArray(AdtPropList, param2));
		DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER); 
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public MenuColorHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		if (IsAccessGranted(param1))
		{
			EmitSoundToClient(param1, SOUND_EDIT);
			new target = GetClientAimTarget(param1, false);
			
			if(IsValidEntity(target) && g_iOwner[target] == param1)
			{
				switch(param2)
				{
					case 0:
					{	
						SetEntityRenderColor(target, 255, 255, 255, 255);
						g_iPreviousColor[target][0] = 255;
						g_iPreviousColor[target][1] = 255;
						g_iPreviousColor[target][2] = 255;
						g_iPreviousColor[target][3] = 255;
					}
					case 1:
					{
						SetEntityRenderColor(target, 255, 0, 0, 255);
						g_iPreviousColor[target][0] = 255;
						g_iPreviousColor[target][1] = 0;
						g_iPreviousColor[target][2] = 0;
						g_iPreviousColor[target][3] = 255;
					}
					case 2:
					{
						SetEntityRenderColor(target, 0, 255, 0, 255);
						g_iPreviousColor[target][0] = 0;
						g_iPreviousColor[target][1] = 255;
						g_iPreviousColor[target][2] = 0;
						g_iPreviousColor[target][3] = 255;
					}
					case 3: 
					{
						SetEntityRenderColor(target, 0, 0, 255, 255);
						g_iPreviousColor[target][0] = 0;
						g_iPreviousColor[target][1] = 0;
						g_iPreviousColor[target][2] = 255;
						g_iPreviousColor[target][3] = 255;
					}
					case 4: 
					{
						SetEntityRenderColor(target, 255, 255, 0, 255);
						g_iPreviousColor[target][0] = 255;
						g_iPreviousColor[target][1] = 255;
						g_iPreviousColor[target][2] = 0;
						g_iPreviousColor[target][3] = 255;
					}
					case 5: 
					{
						SetEntityRenderColor(target, 255, 0, 255, 255);
						g_iPreviousColor[target][0] = 255;
						g_iPreviousColor[target][1] = 0;
						g_iPreviousColor[target][2] = 255;
						g_iPreviousColor[target][3] = 255;
					}
					case 6: 
					{
						SetEntityRenderColor(target, 0, 255, 255, 255);
						g_iPreviousColor[target][0] = 0;
						g_iPreviousColor[target][1] = 255;
						g_iPreviousColor[target][2] = 255;
						g_iPreviousColor[target][3] = 255;
					}
					case 7: 
					{
						SetEntityRenderColor(target, 0, 0, 0, 255);
						g_iPreviousColor[target][0] = 0;
						g_iPreviousColor[target][1] = 0;
						g_iPreviousColor[target][2] = 0;
						g_iPreviousColor[target][3] = 255;
					}
					case 8:
					{
						SetEntityRenderMode(target, RENDER_TRANSALPHA);
						new offset = GetEntSendPropOffs(target, "m_clrRender");
						SetEntData(target, offset + 3, 128, 1, true);
					}
					case 9:
					{
						SetEntityRenderMode(target, RENDER_TRANSALPHA);
						new offset = GetEntSendPropOffs(target, "m_clrRender");
						for(new i=0; i<=2; i++)
						{
							if(GetEntData(target, offset + i, 1) == 0)
								SetEntData(target, offset + i, 128, 1, true);
						}
					}
				}
				
				DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER); 
			}
			else
			{
				EmitSoundToClient(param1, SOUND_ERROR);
				CPrintToChat(param1, "{unique}[Construct]{default} {fullred}Error{default}: Hey!, That's not yours");
			}
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public MenuAdminHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		if (GetUserFlagBits(param1) & ADMFLAG_CUSTOM2 || GetUserFlagBits(param1) & ADMFLAG_ROOT)
		{
			EmitSoundToClient(param1, SOUND_EDIT);
			new target = GetClientAimTarget(param1, false);
			
			if(IsValidEntity(target) && g_iOwner[target] > 0)
			{
				switch(param2)
				{
					case 0:
					{	
						DeleteMySpawns(g_iOwner[target], g_iOwner[target]);
						CPrintToChat(g_iOwner[target], "{unique}[Construct]{default} {fullred}An Administrator has removed all you props");
					}
					case 1:
					{
						g_iOwner[target] = -1;
						EmitSoundToClient(param1, SOUND_DELETE);
						AcceptEntityInput(target, "Kill");

						RemoveFromLimit(g_iOwner[target], target);
						CPrintToChat(g_iOwner[target], "{unique}[Construct]{default} {fullred}An Administrator has removed one of your props");
					}
					case 2: FakeClientCommandEx(param1, "sm_cgrab");
				}
				
				DisplayMenuSafely(g_hAdminMenu, param1);
			}
		}
		else
			CPrintToChat(param1, "{unique}[Construct]{default} {fullred}Error{default}: You cannot acces the admin things");
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public MenuResizeHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		if (IsAccessGranted(param1))
		{
			new target = GetClientAimTarget(param1, false);
			
			if(IsValidEntity(target) && g_iOwner[target] == param1)
			{
				decl String:info[128];
				GetMenuItem(menu, param2, info, sizeof(info));
				SetEntPropFloat(target, Prop_Send, "m_flModelScale", StringToFloat(info));
				EmitSoundToClient(param1, SOUND_EDIT);
			}
			else
			{
				EmitSoundToClient(param1, SOUND_ERROR);
				CPrintToChat(param1, "{unique}[Construct]{default} {fullred}Error{default}: Hey!, That's not yours");
			}
		}
		DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER); 
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public MenuParticleHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		if (IsAccessGranted(param1))
		{
			new target = GetClientAimTarget(param1, false);
			
			if(IsValidEntity(target) && g_iOwner[target] == param1)
			{
				decl String:info[128];
				GetMenuItem(menu, param2, info, sizeof(info));
				TE_ParticleToAll(info, _, _, _, target);
				EmitSoundToClient(param1, SOUND_EDIT);
			}
			else
			{
				EmitSoundToClient(param1, SOUND_ERROR);
				CPrintToChat(param1, "{unique}[Construct]{default} {fullred}Error{default}: Hey!, That's not yours");
			}
		}
		DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER); 
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		DisplayMenuSafely(g_hMainMenu, param1);
}

public MenuTipHandled(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuSafely(g_hMainMenu, param1);
	}
}

public OnSettingsChange(Handle:hCvar, const String:sOld[], const String:sNew[])
{
	if (hCvar == g_hPropLimit) g_iPropLimit = StringToInt(sNew);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidEntity(g_iGrabbedEnt[client]))
	{
		g_fSelectedPropAng[client] = 0.0;
		g_fSelectedPropDist[client] = 0.0;
		SetEntityMoveType(client, MOVETYPE_WALK);
	
		if (IsValidEntity(g_particle1[client]))
		{
			AcceptEntityInput(g_particle1[client], "Kill");
			g_particle1[client] = INVALID_ENT_REFERENCE;
		}
		if (IsValidEntity(g_particle2[client]))
		{
			AcceptEntityInput(g_particle2[client], "Kill");
			g_particle2[client] = INVALID_ENT_REFERENCE;
		}
	
		TeleportEntity(g_iGrabbedEnt[client], g_vecSelectedPropPrevPos[client], g_vecSelectedPropPrevAng[client], NULL_VECTOR);
		SDKUnhook(client, SDKHook_PreThink, PropManip);
		
		SetEntityRenderColor(g_iGrabbedEnt[client], g_iPreviousColor[g_iGrabbedEnt[client]][0], g_iPreviousColor[g_iGrabbedEnt[client]][1], g_iPreviousColor[g_iGrabbedEnt[client]][2], g_iPreviousColor[g_iGrabbedEnt[client]][3]);

		if (g_iPreviousColor[g_iGrabbedEnt[client]][0] == 255)
			SetEntityRenderFx(g_iGrabbedEnt[client], RENDERFX_NONE);
		else
			SetEntityRenderMode(g_iGrabbedEnt[client], RENDER_TRANSALPHA);
		
		new Float:m_vecMins[3], Float:m_vecMaxs[3], Float:endpos[3], Float:position[3];
		GetEntPropVector(g_iGrabbedEnt[client], Prop_Send, "m_vecMins", m_vecMins);
		GetEntPropVector(g_iGrabbedEnt[client], Prop_Send, "m_vecMaxs", m_vecMaxs);
		GetEntPropVector(g_iGrabbedEnt[client], Prop_Send, "m_vecOrigin", position);
		
		endpos[0] = position[0];
		endpos[1] = position[1];
		endpos[2] = position[2] += m_vecMaxs[2];
		
		EmitAmbientSound(SOUND_UNGRAB, position, g_iGrabbedEnt[client]);
		
		TR_TraceHullFilter(endpos, position, m_vecMins, m_vecMaxs, MASK_SOLID, TraceFilterClients, g_iGrabbedEnt[client]);
		if(TR_DidHit())
		{
			new String:class[32];
			new object = TR_GetEntityIndex();
			GetEntityClassname(object, class, sizeof(class));

			if(StrContains(class, "player") != -1)
			{
				CreateTimer(5.0, Timer_ReTrace, EntIndexToEntRef(g_iGrabbedEnt[client]));
				SetEntProp(g_iGrabbedEnt[client], Prop_Data, "m_CollisionGroup", 1);
				CPrintToChat(client, "{unique}[Construct]{default} %N is in the way", object);
			}
			else
			{
				EmitAmbientSound(SOUND_SOLID, position, g_iGrabbedEnt[client]);
				SetEntProp(g_iGrabbedEnt[client], Prop_Data, "m_CollisionGroup", 0);
				TE_ParticleToAll("ping_circle", position, position, NULL_VECTOR, g_iGrabbedEnt[client], _, _, false);
			}
		}
		else
		{
			EmitAmbientSound(SOUND_SOLID, position, g_iGrabbedEnt[client]);
			SetEntProp(g_iGrabbedEnt[client], Prop_Data, "m_CollisionGroup", 0);
			TE_ParticleToAll("ping_circle", position, position, NULL_VECTOR, g_iGrabbedEnt[client], _, _, false);
		}
		
		g_iGrabbedEnt[client] = -1;
	}
	g_bInConstructZone[client] = false;
	
	return Plugin_Continue;
}

public Action:SpawnList(client,args)
{
	new String:modelname[128];
	new ent;
	new size = GetArraySize(h_array_SpawnEnts[client]);
	if(size == 0)
	{
		CPrintToChat(client,"{unique}[Construct]{default} You have 0 spawned objects");
		return Plugin_Handled;
	}
	for(new i=0;i<size;i++)
	{
		ent = GetArrayCell(h_array_SpawnEnts[client], i);
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		CPrintToChat(client, "{unique}[Construct]{default} %i. Ent: %i Model: %s", i +1, ent, modelname);
	}
	return Plugin_Handled;
}

public Action:DeleteMySpawns(client, args)
{
	while(GetArraySize(h_array_SpawnEnts[client]))
	{
		if(IsValidEntity(GetArrayCell(h_array_SpawnEnts[client], 0)))
			AcceptEntityInput(GetArrayCell(h_array_SpawnEnts[client], 0), "Kill");
	
		EmitSoundToClient(client, SOUND_DELETE);
		RemoveFromArray(h_array_SpawnEnts[client], 0);
	}
	
	CPrintToChat(client,"{unique}[Construct]{default} Removed all your objects. You now have %i objects.", GetArraySize(h_array_SpawnEnts[client]));
	return Plugin_Handled;
}

public Action:RemoveFirstSpawn(client,args)
{
	if(GetArraySize(h_array_SpawnEnts[client]) > 0)
	{
		new ent = GetArrayCell(h_array_SpawnEnts[client], 0 );
		if(IsValidEntity(ent))
		{
			EmitSoundToClient(client, SOUND_DELETE);
			AcceptEntityInput(ent, "Kill");
			new String:modelname[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
			CPrintToChat(client, "{unique}[Construct]{default} Removed: Model: %s", modelname);
		}
		RemoveFromArray(h_array_SpawnEnts[client], 0);
	}
}

public Action:RemoveLastSpawn(client,args)
{
	if(GetArraySize(h_array_SpawnEnts[client]) > 0)
	{
		new ent = GetArrayCell(h_array_SpawnEnts[client], GetArraySize(h_array_SpawnEnts[client]) - 1 );
		if(IsValidEntity(ent))
		{
			EmitSoundToClient(client, SOUND_DELETE);
			AcceptEntityInput(ent, "Kill");
			new String:modelname[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
			CPrintToChat(client, "{unique}[Construct]{default} Removed: Model: %s", modelname);
		}
		RemoveFromArray(h_array_SpawnEnts[client], GetArraySize(h_array_SpawnEnts[client]) - 1 );
	}
}

public Action:Command_Stack(iClient, iArgs)
{
	if (iArgs < 2)
	{
		CPrintToChat(iClient, "{unique}[Construct]{default} sm_autobuild <amount> <x> <y> <z> accepts units");
		return Plugin_Handled;
	}

	new iEnt = GetClientAimTarget(iClient, false);
	if(IsValidEntity(iEnt) && g_iOwner[iEnt] == iClient)
	{
		decl String:sClass[32];
		GetEntityClassname(iEnt, sClass, sizeof(sClass));

		decl String:sArg[5], String:sArg2[8], String:sArg3[8], String:sArg4[8], Float:fOrigin[3];
				
		GetCmdArg(1, sArg, sizeof(sArg));	//Amount
		GetCmdArg(2, sArg2, sizeof(sArg2));	//X
		GetCmdArg(3, sArg3, sizeof(sArg3));	//Y
		GetCmdArg(4, sArg4, sizeof(sArg4));	//Z

		if (StringToInt(sArg) > 5)
		{
			CPrintToChat(iClient, "{unique}[Construct]{default} {fullred}ERROR{default}: You can't autobuild more than 5 props at one time!");
			return Plugin_Handled;
		} 
		else if (StringToInt(sArg) == 0)
		{
			CPrintToChat(iClient, "{unique}[Construct]{default} {fullred}ERROR{default}: You can't autobuild 0 props!");
			return Plugin_Handled;
		}

		fOrigin[0] = StringToFloat(sArg2);
		fOrigin[1] = StringToFloat(sArg3);
		fOrigin[2] = StringToFloat(sArg4);

		new iCount = 0, Float:fDelay = 0.05;

		new String:red[10], String:green[10], String:blue[10], String:alpha[10];
		IntToString(g_iPreviousColor[iEnt][0], red, sizeof(red));
		IntToString(g_iPreviousColor[iEnt][1], green, sizeof(green));
		IntToString(g_iPreviousColor[iEnt][2], blue, sizeof(blue));
		IntToString(g_iPreviousColor[iEnt][3], alpha, sizeof(alpha));
		
		while (iCount < StringToInt(sArg))
		{
			iCount++;

			new Handle:hDataPack;
			CreateDataTimer(fDelay, Timer_Stack, hDataPack);
			WritePackCell(hDataPack, iClient);
			WritePackCell(hDataPack, iEnt);
			WritePackFloat(hDataPack, fOrigin[0] * iCount);
			WritePackFloat(hDataPack, fOrigin[1] * iCount);
			WritePackFloat(hDataPack, fOrigin[2] * iCount);
			WritePackString(hDataPack, red);
			WritePackString(hDataPack, green);
			WritePackString(hDataPack, blue);
			WritePackString(hDataPack, alpha);

			fDelay += 0.05;
		}
	}
	return Plugin_Handled;
}

public Action:Save_Prop(client, iArgs)
{
	if (iArgs < 1)
	{
		CPrintToChat(client, "{unique}[Construct]{default} Usage: construct_save <savename>");
		return Plugin_Handled;
	}

	decl String:sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));

	SaveProps(client, sArg);

	return Plugin_Handled;
}

public Action:Load_Prop(client, iArgs)
{
	if (iArgs < 1)
	{
		CPrintToChat(client, "{unique}[Construct]{default} Usage: construct_load <savename>");
		return Plugin_Handled;
	}

	decl String:sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));

	LoadProps(client, sArg);

	return Plugin_Handled;
}

public Action:BuildMenu(client,args)
{
	if (!IsAccessGranted(client))
	{
		return Plugin_Handled;
	}
	
	if (IsValidEntity(g_particle1[client]))
	{
		AcceptEntityInput(g_particle1[client], "Kill");
		g_particle1[client] = INVALID_ENT_REFERENCE;
	}
	if (IsValidEntity(g_particle2[client]))
	{
		AcceptEntityInput(g_particle2[client], "Kill");
		g_particle2[client] = INVALID_ENT_REFERENCE;
	}
	
	DisplayMenuSafely(g_hMainMenu, client);
	return Plugin_Handled;
}

StraightenAimProp(client)
{
	new target = GetClientAimTarget(client, false);
	if(IsValidEntity(target) && g_iOwner[target] == client)
	{
		decl Float:f_angles[3];
		f_angles[0] = 0.0, f_angles[1] = 0.0, f_angles[2] = 0.0;
					
		TeleportEntity(target, NULL_VECTOR, f_angles, NULL_VECTOR);
	}
	else
	{
		EmitSoundToClient(client, SOUND_ERROR);
		CPrintToChat(client, "{unique}[Construct]{default} {fullred}Error{default}: Hey!, That's not yours");
	}
	DisplayMenuSafely(g_hMainMenu, client);
}

ToggleAimCollision(client)
{
	new target = GetClientAimTarget(client, false);
	if(IsValidEntity(target) && g_iOwner[target] == client)
	{
		new col = GetEntProp(target, Prop_Send, "m_nSolidType");
		if(col != 0)
		{
			SetEntProp(target, Prop_Send, "m_nSolidType", 0);
			CPrintToChat(client, "{unique}[Construct]{default} Collision disabled.");
			EmitSoundToClient(client, SOUND_EDIT);
		}
		else
		{
			EmitSoundToClient(client, SOUND_EDIT);
			SetEntProp(target, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(target, Prop_Send, "m_nSolidType", 6);
			CPrintToChat(client, "{unique}[Construct]{default} Collision enabled.");
		}
	}
	DisplayMenuSafely(g_hMainMenu, client);
}

public Native_SaveProps(Handle:plugin, numParams)
{	
	new client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	new String:sName[len+1];
	GetNativeString(2, sName, len+1);
	
	if (len <= 0)
		return;
	
	decl String:FileName[PLATFORM_MAX_PATH], String:sPath[PLATFORM_MAX_PATH], String:sMap[256];
	new iProps = 0;

	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/saves/%s", sMap);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);

	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/saves/%s/%s", sMap, g_sAuthID[client]);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
		
	BuildPath(Path_SM, FileName, sizeof(FileName), "simple-build/saves/%s/%s/%s.txt", sMap, g_sAuthID[client], sName);
	if (FileExists(FileName, true))
	{
		DeleteFile(FileName);
		CPrintToChat(client, "{unique}[Construct]{default} Save already exists: \x04%s\x01 ... Overriding old save ...", sName);
	}
	
	new i = -1;
	while ((i = FindEntityByClassname(i, "prop_dynamic*")) != -1)
	{
		if (IsValidEntity(i) && g_iOwner[i] == client)
		{
			decl String:sTargetName[256];
			GetEntPropString(i, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
			if(StrContains(sTargetName, "SimpleBuild:", false) != -1 || StrContains(sTargetName, "construct", false) != -1)
			{		
				decl String:sModel[128], String:sBuffers[13][128], Float:fOrigin[3], Float:fAngles[3], String:SaveBuffer[255];
				
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOrigin);
				GetEntPropVector(i, Prop_Send, "m_angRotation", fAngles);
				
				IntToString(RoundFloat(fOrigin[0]), sBuffers[1], 32);   
				IntToString(RoundFloat(fOrigin[1]), sBuffers[2], 32);
				IntToString(RoundFloat(fOrigin[2]), sBuffers[3], 32);
				
				sBuffers[0] = sModel;
				IntToString(GetEntProp(i, Prop_Send, "m_CollisionGroup"), sBuffers[7], 128);
				
				IntToString(RoundFloat(fAngles[0]), sBuffers[4], 32);
				IntToString(RoundFloat(fAngles[1]), sBuffers[5], 32);
				IntToString(RoundFloat(fAngles[2]), sBuffers[6], 32);
				
				new offset = GetEntSendPropOffs(i, "m_clrRender"); // Thanks Panda!!!
		 
				if (offset > 0) 
				{
					IntToString((GetEntData(i, offset, 1)), sBuffers[8], sizeof(sBuffers));
					IntToString((GetEntData(i, offset + 1, 1)), sBuffers[9], sizeof(sBuffers));
					IntToString((GetEntData(i, offset + 2, 1)), sBuffers[10], sizeof(sBuffers));
					IntToString((GetEntData(i, offset + 3, 1)), sBuffers[11], sizeof(sBuffers));
				}
				FloatToString(GetEntPropFloat(i, Prop_Send, "m_flModelScale"), sBuffers[12], sizeof(sBuffers));

				ImplodeStrings(sBuffers, 13, " ", SaveBuffer, 255);
					
				decl String:buffer[512];
				
				VFormat(buffer, sizeof(buffer), SaveBuffer, 2);
				
				new Handle:_hFile = OpenFile(FileName, "a+");
				if(_hFile != INVALID_HANDLE)
				{
					WriteFileLine(_hFile, "%s", buffer);
					
					FlushFile(_hFile);
					CloseHandle(_hFile);
					
					iProps++;
				}
				else
				{
					if(IsValidClient(client))
					{
						EmitSoundToClient(client, SOUND_ERROR);
						CPrintToChat(client, "{unique}[Construct]{default} {fullred}ERROR{default: Some kind of error appeared while trying to save your prop");
					}
				}
			}
		}
	}
	if(IsValidClient(client))
		CPrintToChat(client, "{unique}[Construct]{default} Saving %i props under alias: \x04%s\x01", iProps, sName);
}

public Native_LoadProps(Handle:plugin, numParams)
{	
	new client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	new String:sName[len+1];
	GetNativeString(2, sName, len+1);
	
	if(len <= 0)
		return;
	
	decl String:FileName[PLATFORM_MAX_PATH], String:sMap[256];

	GetCurrentMap(sMap, sizeof(sMap));

	new Handle:_hFile, Float:fDelay = 0.10, iProps = 0;
	decl String:_sFileBuffer[512];

	BuildPath(Path_SM, FileName, sizeof(FileName), "simple-build/saves/%s/%s/%s.txt", sMap, g_sAuthID[client], sName);

	if (FileExists(FileName, true))
	{
		_hFile = OpenFile(FileName, "r");
		
		while (ReadFileLine(_hFile, _sFileBuffer, sizeof(_sFileBuffer)))
		{
			new Handle:hTemp;
			CreateDataTimer(fDelay, Timer_Load, hTemp);
			
			WritePackCell(hTemp, client);
			WritePackString(hTemp, _sFileBuffer);
			
			iProps++, fDelay += 0.10;
		}
		
		FlushFile(_hFile);
		CloseHandle(_hFile);
		
		CPrintToChat(client, "{unique}[Construct]{default} Loading %i props from alias: \x04%s\x01", iProps, sName);
	} 
	else
	{
		EmitSoundToClient(client, SOUND_ERROR);
		CPrintToChat(client, "{unique}[Construct]{default} {fullred}Error{default}: That save alias does not exist for this map: \x04%s\x01", sName);
	}
}

public Action:Timer_Load(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new iClient = ReadPackCell(hPack);
	
	if(!UnderLimit(iClient)) 
	{
		EmitSoundToClient(iClient, SOUND_ERROR);
		CPrintToChat(iClient, "{unique}[Construct]{default} You have exceeded the spawn limit of %i", g_iPropLimit);
	}
	else
	{
		decl String:sbuffer[256], String:sBuffers[13][256], iColor[3];
		ReadPackString(hPack, sbuffer, sizeof(sbuffer));
		
		ExplodeString(sbuffer, " ", sBuffers, 13, 255);
		
		decl Float:fOrigin[3], Float:fAngles[3], String:sTarget[64], String:sAuth[64];
		
		new iEntity = CreateEntityByName("prop_dynamic_override");
		
		GetClientAuthString(iClient, sAuth, sizeof(sAuth));
		
		Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
		DispatchKeyValue(iEntity, "targetname", sTarget);
		
		PrecacheModel(sBuffers[0]);
		DispatchKeyValue(iEntity, "model", sBuffers[0]);
		
		fOrigin[0] = StringToFloat(sBuffers[1]);
		fOrigin[1] = StringToFloat(sBuffers[2]);
		fOrigin[2] = StringToFloat(sBuffers[3]);
		
		fAngles[0] = StringToFloat(sBuffers[4]);
		fAngles[1] = StringToFloat(sBuffers[5]);
		fAngles[2] = StringToFloat(sBuffers[6]);
		
		iColor[0] = StringToInt(sBuffers[8]);
		iColor[1] = StringToInt(sBuffers[9]);
		iColor[2] = StringToInt(sBuffers[10]);
		
		g_iPreviousColor[iEntity][0] = iColor[0];
		g_iPreviousColor[iEntity][1] = iColor[1];
		g_iPreviousColor[iEntity][2] = iColor[2];
		g_iPreviousColor[iEntity][3] = StringToInt(sBuffers[11]);

		DispatchKeyValue(iEntity, "rendermode", "5");
		DispatchKeyValue(iEntity, "renderamt", sBuffers[11]);

		if (!DispatchSpawn(iEntity)) LogError("didn't spawn");

		SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], StringToInt(sBuffers[11]));
		SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", StringToInt(sBuffers[7]));
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", StringToFloat(sBuffers[12]));
		if(StringToInt(sBuffers[7]) == 0)
			SetEntProp(iEntity, Prop_Send, "m_nSolidType", 6);

		AcceptEntityInput(iEntity, "DisableMotion");
		
		g_iOwner[iEntity] = iClient;
		AddToLimit(iClient, iEntity);
		
		TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
	}
}

public Action:Timer_Stack(Handle:Timer, Handle:hDataPack)
{
	ResetPack(hDataPack);
	
	new iClient = ReadPackCell(hDataPack);
	new iEnt = ReadPackCell(hDataPack);

	if(!UnderLimit(iClient)) 
	{
		EmitSoundToClient(iClient, SOUND_ERROR);
		CPrintToChat(iClient, "{unique}[Construct]{default} You have exceeded the spawn limit of %i", g_iPropLimit);
	}
	else
	{
		decl Float:fDegree[3];
		fDegree[0] = ReadPackFloat(hDataPack);
		fDegree[1] = ReadPackFloat(hDataPack);
		fDegree[2] = ReadPackFloat(hDataPack);
		
		new String:sred[10], String:sgreen[10], String:sblue[10], String:salpha[10];
		ReadPackString(hDataPack, sred, sizeof(sred));
		ReadPackString(hDataPack, sgreen, sizeof(sgreen));
		ReadPackString(hDataPack, sblue, sizeof(sblue));
		ReadPackString(hDataPack, salpha, sizeof(salpha));
		
		new red, green, blue, alpha;
		red = StringToInt(sred);
		green = StringToInt(sgreen);
		blue = StringToInt(sblue);
		alpha = StringToInt(salpha);
		
		decl iSolid;
		decl String:sClass[32], String:sModel[256], Float:fEntOrigin[3], Float:fEntAng[3], String:sTarget[64], String:sAuth[32];

		GetEdictClassname(iEnt, sClass, sizeof(sClass));
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntOrigin);
		GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fEntAng);
		GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		iSolid = GetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 4, 0);

		new iEntity = CreateEntityByName("prop_dynamic_override");
		
		GetClientAuthString(iClient, sAuth, sizeof(sAuth));
		Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
		DispatchKeyValue(iEntity, "targetname", sTarget);

		DispatchKeyValue(iEntity, "model", sModel);
		DispatchKeyValue(iEntity, "rendermode", "5");

		if (!DispatchSpawn(iEntity)) LogError("didn't spawn");
		EmitSoundToClient(iClient, SOUND_SPAWN);

		AddVectors(fEntOrigin, fDegree, fEntOrigin);

		SetEntityRenderColor(iEntity, red, green, blue, alpha);
		
		SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", iSolid, 4, 0);
		if(iSolid == 0)
			SetEntProp(iEntity, Prop_Send, "m_nSolidType", 6);

		SetEntityMoveType(iEntity, MOVETYPE_NONE);
		g_iPreviousColor[iEntity][0] = red;
		g_iPreviousColor[iEntity][1] = green;
		g_iPreviousColor[iEntity][2] = blue;
		g_iPreviousColor[iEntity][3] = alpha;
		
		TeleportEntity(iEntity, fEntOrigin, fEntAng, NULL_VECTOR);
		
		new zone = -1;
		while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != -1)
		{
			decl String:sTargetName[256];
			GetEntPropString(zone, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
			
			if(StrContains(sTargetName, "sm_devzone construct", false) != -1)
			{
				new Float:m_vecAreaMins[3], Float:m_vecAreaMaxs[3], Float:m_vecAreaOrigin[3], Float:m_vecPropOrigin[3];
				
				GetEntPropVector(zone, Prop_Send, "m_vecMins", m_vecAreaMins);
				GetEntPropVector(zone, Prop_Send, "m_vecMaxs", m_vecAreaMaxs);
				GetEntPropVector(zone, Prop_Data, "m_vecOrigin", m_vecAreaOrigin);
				GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", m_vecPropOrigin);

				for (new i = 0; i <= 2; i++)
				{
					m_vecAreaMins[i] = m_vecAreaOrigin[i] + m_vecAreaMins[i];
					m_vecAreaMaxs[i] = m_vecAreaOrigin[i] + m_vecAreaMaxs[i];
				}
				
				if(IsPropInSideZone(m_vecPropOrigin, m_vecAreaMins, m_vecAreaMaxs))
				{
					AddToLimit(iClient, iEntity);
					g_iOwner[iEntity] = iClient;
				}
				else
				{
					EmitSoundToClient(iClient, SOUND_ERROR);
					CPrintToChat(iClient, "{unique}[Construct]{default} {fullred}ERROR{default}: Autobuild tried to bypass zone restrictions.. removing prop");
					AcceptEntityInput(iEntity, "Kill");
				}
			}
		}
	}
}

public bool:UnderLimit(client)
{
	if(GetArraySize(h_array_SpawnEnts[client]) >= g_iPropLimit) 
	{
		PrintToServer("[Construct] %N hit limit of %i.", client, g_iPropLimit);
		return false;
	}
	else
		return true;
}

AddToLimit(client, ent)
{
	PushArrayCell(h_array_SpawnEnts[client], ent);
	CPrintToChat(client,"{unique}[Construct]{default} You now have %i spawned objects. Max: %i", GetArraySize(h_array_SpawnEnts[client]), g_iPropLimit);
}

RemoveFromLimit(client, ent)
{
	new foundindex;
	for(new i=1;i<=MAXPLAYERS;i++) 
	{
		if(h_array_SpawnEnts[i] != INVALID_HANDLE)
		{
			foundindex = FindValueInArray(h_array_SpawnEnts[i], ent);
			if(foundindex >= 0) 
			{
				RemoveFromArray(h_array_SpawnEnts[i],foundindex);
				if(client == i)
					CPrintToChat(i,"{unique}[Construct]{default} You removed ent: %i. You now have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[i]));
				else 
				{
					CPrintToChat(i,"{unique}[Construct]{default} %s removed ent: %i. You now have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[i]));
					CPrintToChat(client,"{unique}[Construct]{default} That was %N's object (ent:%i). %N's was reduced, but you still have %i spawned objects.", client, ent, client, GetArraySize(h_array_SpawnEnts[client]));
				}
				return;
			}
		}
	}
	CPrintToChat(client,"{unique}[Construct]{default} Object (ent: %i) removed, but not in any player spawned list. You still have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[client]));
	return;
}

//Grab 
public PropManip(client)
{
	if(IsValidClient(client))
	{
		new btns = GetClientButtons(client);
		decl Float:pos[3], Float:ang[3], Float:pAng[3], Float:pPos[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		if (IsValidEntity(g_iGrabbedEnt[client]))
		{
			new String:class[64];
			GetEntityClassname(g_iGrabbedEnt[client], class, sizeof(class));

			if(StrContains(class, "prop_dynamic") != -1)
			{
				decl String:sTargetName[256];
				GetEntPropString(g_iGrabbedEnt[client], Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
				if(StrContains(sTargetName, "SimpleBuild:", false) != -1 || StrContains(sTargetName, "construct", false) != -1)
				{
					GetEntPropVector(g_iGrabbedEnt[client], Prop_Data, "m_angRotation", pAng);
					GetEntPropVector(g_iGrabbedEnt[client], Prop_Data, "m_vecOrigin", pPos);
				
					pos[2] -= 32.0;
					
					if(btns & IN_JUMP)
						pPos[2] += 1.0;
					else if(btns & IN_DUCK)
						pPos[2] -= 1.0;

					if(g_fSelectedPropDist[client] == 0.0)
						g_fSelectedPropDist[client] = GetVectorDistance(pos, pPos);
					if(g_fSelectedPropAng[client] == 0.0)
						g_fSelectedPropAng[client] = pAng[1];
					
					new Float:rad = g_fSelectedPropAng[client] * (3.14 / 180);
						
					if(btns & IN_MOVELEFT)
					{
						g_fSelectedPropAng[client] += 0.5;
						pAng[1] += 0.5;
					}
					else if(btns & IN_MOVERIGHT)
					{
						g_fSelectedPropAng[client] -= 0.5;
						pAng[1] -= 0.5;
					}
					
					if(btns & IN_FORWARD)
						g_fSelectedPropDist[client] += 1;
					else if(btns & IN_BACK)
						g_fSelectedPropDist[client] -= 1;
					
					if(g_fSelectedPropDist[client] < 16.0)
						g_fSelectedPropDist[client] = 16.0;
					
					pPos[0] = pos[0] + g_fSelectedPropDist[client] * Cosine(rad);
					pPos[1] = pos[1] + g_fSelectedPropDist[client] * Sine(rad);
					
					if(btns & IN_ATTACK2)
					{
						if(btns & IN_RELOAD)
						{
							new change = RoundToNearest(g_vecLockedAng[client][1] - ang[1]);
							pAng[1] += float(change);

							TeleportEntity(client, NULL_VECTOR, g_vecLockedAng[client], NULL_VECTOR);
						}
						else
						{
							for(new i=0; i<=2; i++)
							{
								new change = RoundToNearest(g_vecLockedAng[client][i] - ang[i]);
								pAng[i] += float(change);
							}
							TeleportEntity(client, NULL_VECTOR, g_vecLockedAng[client], NULL_VECTOR);
						}
					}
					else
						GetClientEyeAngles(client, g_vecLockedAng[client]);
						
					TeleportEntity(g_iGrabbedEnt[client], pPos, pAng, NULL_VECTOR);	
				}
			}
		}
	}
}

//SPAWN ITEM
public Action:SpawnItem(client, args)
{
	if (!IsAccessGranted(client))
		return Plugin_Handled;

	if (args < 2)
	{
		ReplyToCommand(client, "Usage: construct_spawnitem <i|a> \"filename.mdl\" [1|-1]\n i = spawn in front of you\n a = spawn at where you aim\n 1 = place facing toward you\n -1 = place facing against you");
		return Plugin_Handled;
	}
	
	if(!UnderLimit(client)) 
	{
		EmitSoundToClient(client, SOUND_ERROR);
		CPrintToChat(client, "{unique}[Construct]{default} You have exceeded the spawn limit of %i. Delete one of your obects to spawn more.", g_iPropLimit);
		return Plugin_Handled;	
	}
	
	new bool:isInFront = false;
	decl String:param[100];
	GetCmdArg(1, param, sizeof(param));
	
	if (strcmp(param, "i") == 0)
	{
		isInFront = true;
	}
	else if(strcmp(param, "a") != 0)
	{
		ReplyToCommand(client, "unknown parameter: %s", param);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetCmdArg(2, modelname, sizeof(modelname));
	
	new facing = 0;
	if (args > 2)
	{
		GetCmdArg(3, param, sizeof(param));
		facing = StringToInt(param);
	}
	
	new index = CreateEntity(client, "prop_dynamic_override", "dynamic item", modelname);
	
	if (index != -1)
	{
		decl Float:min[3], Float:max[3];
		GetEntPropVector(index, Prop_Send, "m_vecMins", min);
		GetEntPropVector(index, Prop_Send, "m_vecMaxs", max);
		SetEntProp(index, Prop_Data, "m_CollisionGroup", 0);
		SetEntProp(index, Prop_Send, "m_nSolidType", 6);
		
		decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
		if (isInFront)
		{
			new Float:distance = 50.0;
			if (facing == 0)
				distance += SquareRoot((max[0] - min[0]) * (max[0] - min[0]) + (max[1] - min[1]) * (max[1] - min[1])) * 0.5;
			else if (facing > 0)
				distance += max[0];
			else
				distance -= min[0];
			
			GetClientFrontLocationData(client, position, ang_eye, distance);
			normal[0] = 0.0;
			normal[1] = 0.0;
			normal[2] = 1.0;
		}
		else
		{
			if (GetClientAimedLocationData(client, position, ang_eye, normal) == -1)
			{
				EmitSoundToClient(client, SOUND_DELETE);
				AcceptEntityInput(index, "Kill");
				ReplyToCommand(client, "Can't find a location to place, remove entity (%i)", index);
				return Plugin_Handled;
			}
		}
		
		NegateVector(normal);
		GetVectorAngles(normal, ang_ent);
		ang_ent[0] -= 90.0;
		
		// the created entity will face a default direction based on ground normal
		if (facing != 0)
		{
			// here we will rotate the entity to let it face or back to you
			decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
			GetAngleVectors(ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR);
			GetAngleVectors(ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR);
			GetVectorCrossProduct(vec_eye, normal, cross);
			new Float:yaw = GetAngleBetweenVectors(vec_ent, cross, normal);
			if (facing > 0)
				RotateYaw(ang_ent, yaw - 90.0);
			else
				RotateYaw(ang_ent, yaw + 90.0);
		}
		
		// avoid some model burying under ground/in wall
		// don't forget the normal was negated
		position[0] += normal[0] * min[2];
		position[1] += normal[1] * min[2];
		position[2] += normal[2] * min[2];

		SetEntProp(index, Prop_Data, "m_spawnflags", 256);
		DispatchKeyValueVector(index, "Origin", position);
		DispatchKeyValueVector(index, "Angles", ang_ent);
		
		new String:sAuth[64], String:sTarget[64];
		GetClientAuthString(client, sAuth, sizeof(sAuth));
		Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
		DispatchKeyValue(index, "targetname", sTarget);
	
		DispatchSpawn(index);
		
		new zone = -1;
		while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != -1)
		{
			decl String:sTargetName[256];
			GetEntPropString(zone, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
			
			if(StrContains(sTargetName, "sm_devzone construct", false) != -1)
			{
				new Float:m_vecAreaMins[3], Float:m_vecAreaMaxs[3], Float:m_vecAreaOrigin[3], Float:m_vecPropOrigin[3];
				
				GetEntPropVector(zone, Prop_Send, "m_vecMins", m_vecAreaMins);
				GetEntPropVector(zone, Prop_Send, "m_vecMaxs", m_vecAreaMaxs);
				GetEntPropVector(zone, Prop_Data, "m_vecOrigin", m_vecAreaOrigin);
				GetEntPropVector(index, Prop_Data, "m_vecOrigin", m_vecPropOrigin);

				for (new i = 0; i <= 2; i++)
				{
					m_vecAreaMins[i] = m_vecAreaOrigin[i] + m_vecAreaMins[i];
					m_vecAreaMaxs[i] = m_vecAreaOrigin[i] + m_vecAreaMaxs[i];
				}
				
				if(IsPropInSideZone(m_vecPropOrigin, m_vecAreaMins, m_vecAreaMaxs))
				{
					EmitSoundToClient(client, SOUND_SPAWN);
					g_iPreviousColor[index][0] = 255;
					g_iPreviousColor[index][1] = 255;
					g_iPreviousColor[index][2] = 255;
					g_iPreviousColor[index][3] = 255;
					g_iOwner[index] = client;

					AcceptEntityInput(index, "DisableMotion");
					AcceptEntityInput(index, "EnableCollision");
					AcceptEntityInput(index, "TurnOn");
					
					new Float:m_vecMins[3], Float:m_vecMaxs[3], Float:endpos[3];
					GetEntPropVector(index, Prop_Send, "m_vecMins", m_vecMins);
					GetEntPropVector(index, Prop_Send, "m_vecMaxs", m_vecMaxs);
					
					endpos[0] = position[0];
					endpos[1] = position[1];
					endpos[2] = position[2] += m_vecMaxs[2];
					
					TR_TraceHullFilter(endpos, position, m_vecMins, m_vecMaxs, MASK_SOLID, TraceFilterClients, index);
					if(TR_DidHit())
					{
						new String:class[32];
						new object = TR_GetEntityIndex();
						GetEntityClassname(object, class, sizeof(class));

						if(StrContains(class, "player") != -1)
						{
							CreateTimer(5.0, Timer_ReTrace, EntIndexToEntRef(index));
							SetEntProp(index, Prop_Data, "m_CollisionGroup", 1);
							CPrintToChat(client, "{unique}[Construct]{default} %N is in the way", object);
						}
						else
						{
							SetEntProp(index, Prop_Data, "m_CollisionGroup", 0);
							TE_ParticleToAll("ping_circle", position, position, ang_ent, index, _, _, false);
						}
					}
					else
					{
						SetEntProp(index, Prop_Data, "m_CollisionGroup", 0);
						TE_ParticleToAll("ping_circle", position, position, ang_ent, index, _, _, false);
					}
				}
				else
				{
					AcceptEntityInput(index, "Kill");
					EmitSoundToClient(client, SOUND_ERROR);
					CPrintToChat(client, "{unique}[Construct]{default} {fullred}Error{default}: Can't place that there.");
					return Plugin_Handled;
				}
			}
		}
	}
	
	if(IsValidEntity(index))
		AddToLimit(client, index);
	else
	{
		EmitSoundToClient(client, SOUND_ERROR);
		CPrintToChat(client, "{unique}[Construct]{default} {fullred}Error{default}: Invalid Entity - Object unable to spawn.");
	}
		
	return Plugin_Handled;
}

//bombonomicon_spell_trail		//Hold
//bomibomicon_ring				//Spawn
//mvm_loot_smoke				//Spawn
//halloween_boss_axe_hit_world	//Spawn
//merasmus_shoot				//Spawn

public bool:TraceFilterClients(entity, contentsMask, any:data) 
{	
	if (entity > 0 && entity <= MaxClients) 
	{ 
		return true; 
	}
	else 
	{ 
		return false; 
	} 
}

public Action:Timer_ReTrace(Handle:timer, any:entity)
{
	new ent = EntRefToEntIndex(entity);
	if(IsValidEntity(ent))
	{
		new client = g_iOwner[ent];
		if(g_iGrabbedEnt[client] == -1)
		{
			new Float:m_vecMins[3], Float:m_vecMaxs[3], Float:endpos[3], Float:m_vecOrigin[3];
			GetEntPropVector(ent, Prop_Send, "m_vecMins", m_vecMins);
			GetEntPropVector(ent, Prop_Send, "m_vecMaxs", m_vecMaxs);
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", m_vecOrigin);
			
		//	PrintToChatAll("%f %f %f", m_vecOrigin[0], m_vecOrigin[1], m_vecOrigin[2]);
			
			endpos[0] = m_vecOrigin[0];
			endpos[1] = m_vecOrigin[1];
			endpos[2] = m_vecOrigin[2] += m_vecMaxs[2];
			
			TR_TraceHullFilter(endpos, m_vecOrigin, m_vecMins, m_vecMaxs, MASK_SOLID, TraceFilterClients, ent);
			if(TR_DidHit())
			{
				CreateTimer(5.0, Timer_ReTrace, EntIndexToEntRef(ent));
			}
			else
			{
				new String:modelname[128];
				SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
				GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
				
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(IsValidClient(i) && g_iOwner[ent] == i)
					{
						EmitAmbientSound(SOUND_SOLID, m_vecOrigin, ent);
						CPrintToChat(i, "{unique}[Construct]{default} {arcana}%s Solidified succesfully", modelname);
					}
				}
				TE_ParticleToAll("ping_circle", m_vecOrigin, m_vecOrigin, NULL_VECTOR, ent, _, _, false);
			}
		}
	}
}

// Rotate the aimed entity
public Action:RotateEntity(client, args)
{
	if (!IsAccessGranted(client))
	{
		return Plugin_Handled;
	}
	
	new player = GetPlayerIndex(client);
	if (player == 0)
	{
		ReplyToCommand( player, "[Construct] Cannot spawn entity over rcon/server console" );
		return Plugin_Handled;
	}

	new index = GetClientAimTarget(client, false);
	if (index <= 0)
	{
		if(g_iOwner[index] != client)
		{
			CPrintToChat(client, "{unique[Construct]{default} That is not yours!");
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand( player, "[Construct] Nothing picked to rotate" );
			return Plugin_Handled;
		}
	}
	
	new String:param[128];
	new Float:degree;
	if (args > 0)
	{
		GetCmdArg(1, param, sizeof(param));
		degree = StringToFloat(param);
	}
	else 
	{
		CPrintToChat(client, "{unique[Construct]{default} Usage: construct_rotate <amount>");
		return Plugin_Handled;
	}
	
	decl Float:angles[3];
	GetEntPropVector(index, Prop_Data, "m_angRotation", angles);
	RotateYaw(angles, degree);
	
	DispatchKeyValueVector(index, "Angles", angles);

	return Plugin_Handled;
}

//Remove the entity you aim at
//Anything but player can be removed by this function
public Action:RemoveEntity(client, args)
{
	if (!IsAccessGranted(client))
	{
		return Plugin_Handled;
	}
	
	new index = GetClientAimTarget(client, false);
	if (IsValidEntity(index) && g_iOwner[index] == client)
	{
		if(g_iGrabbedEnt[g_iOwner[index]] == index)
			g_iGrabbedEnt[g_iOwner[index]] = -1;
			
		EmitSoundToClient(client, SOUND_DELETE);
		AcceptEntityInput(index, "Kill");

		//ReplyToCommand(player, "[Construct] Entity (index %i) removed", index);
		RemoveFromLimit(client, index);
		g_iOwner[index] = -1;
	}
	else
	{
		EmitSoundToClient(client, SOUND_ERROR);
		CPrintToChat(client, "{unique}[Construct]{default} {fullred}Error{default}: Hey!, That's not yours");
	}

	return Plugin_Handled;
}

//Interior functions
//Spawn a given entity type and assign it a model
CreateEntity(client, const String:entity_name[], const String:item_name[], const String:model[] = "")
{
	new player = GetPlayerIndex(client);
	
	if (player == 0)
	{
		ReplyToCommand(player, "[Construct] Cannot spawn entity over rcon/server console");
		return -1;
	}

	new index = CreateEntityByName(entity_name);
	if (index == -1)
	{
		ReplyToCommand( player, "[Construct] Failed to create %s !", item_name );
		return -1;
	}

	if (strlen(model) != 0)
	{
		if (!IsModelPrecached(model))
		{
			PrecacheModel(model);
		}
		SetEntityModel(index, model);
	}

//	ReplyToCommand(player, "[Construct] Successfully create %s (index %i)", item_name, index);

	return index;
}

//Do a specific rotation on the given angles
RotateYaw(Float:angles[3], Float:degree)
{
	decl Float:direction[3], Float:normal[3];
	GetAngleVectors(angles, direction, NULL_VECTOR, normal);
	
	new Float:sin = Sine(degree * 0.01745328);	 // Pi/180
	new Float:cos = Cosine(degree * 0.01745328);
	new Float:a = normal[0] * sin;
	new Float:b = normal[1] * sin;
	new Float:c = normal[2] * sin;
	new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
	new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
	new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;
	
	GetVectorAngles(direction, angles);

	decl Float:up[3];
	GetVectorVectors(direction, NULL_VECTOR, up);

	new Float:roll = GetAngleBetweenVectors(up, normal, direction);
	angles[2] += roll;
}

//Return 0 if it is a server
GetPlayerIndex(client)
{
	if (client == 0)
	{
		return 1;
	}
	
	return client;
}

//Check if this MOD can be used by specific client
bool:IsAccessGranted(client)
{
	new bool:granted = true;

	if (g_bInConstructZone[client])
	{
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM6 || GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			granted = true;
		}
		else
		{
			ReplyToCommand(client, "[Construct] You do not have acces to this command");
			granted = false;
		}
	}
	else
	{
		ReplyToCommand(client, "[Construct] You are not in the construction zone");
		granted = false;
	}

	return granted;
}

//The filter function for TR_TraceRayFilterEx
public bool:TraceEntityFilterPlayers(entity, contentsMask, any:data)
{
	return entity > MaxClients && entity != data;
}

//Get position, angles and normal of aimed location if the parameters are not NULL_VECTOR
//Return the index of entity you aimed
GetClientAimedLocationData(client, Float:position[3], Float:angles[3], Float:normal[3])
{
	new index = -1;
	new player = GetPlayerIndex(client);

	decl Float:_origin[3], Float:_angles[3];
	GetClientEyePosition(player, _origin);
	GetClientEyeAngles(player, _angles);

	new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
	if(!TR_DidHit(trace))
	{ 
		ReplyToCommand(player, "[Construct] Failed to pick the aimed location");
		index = -1;
	}
	else
	{
		TR_GetEndPosition(position, trace);
		TR_GetPlaneNormal(trace, normal);
		angles[0] = _angles[0];
		angles[1] = _angles[1];
		angles[2] = _angles[2];

		index = TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);
	
	return index;
}

//Get position just in front of you and the angles you are facing in horizontal
GetClientFrontLocationData(client, Float:position[3], Float:angles[3], Float:distance = 50.0)
{
	new player = GetPlayerIndex(client);

	decl Float:_origin[3], Float:_angles[3];
	GetClientAbsOrigin(player, _origin);
	GetClientEyeAngles(player, _angles);

	decl Float:direction[3];
	GetAngleVectors(_angles, direction, NULL_VECTOR, NULL_VECTOR);
	
	position[0] = _origin[0] + direction[0] * distance;
	position[1] = _origin[1] + direction[1] * distance;
	position[2] = _origin[2];
	
	angles[0] = 0.0;
	angles[1] = _angles[1];
	angles[2] = 0.0;
}

//Calculate the angle between 2 vectors
//The direction will be used to determine the sign of angle (right hand rule)
//All of the 3 vectors have to be normalized
Float:GetAngleBetweenVectors(const Float:vector1[3], const Float:vector2[3], const Float:direction[3])
{
	decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
	NormalizeVector(direction, direction_n);
	NormalizeVector(vector1, vector1_n);
	NormalizeVector(vector2, vector2_n);
	new Float:degree = ArcCosine(GetVectorDotProduct(vector1_n, vector2_n)) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct(vector1_n, vector2_n, cross);
	
	if (GetVectorDotProduct(cross, direction_n) < 0.0)
	{
		degree *= -1.0;
	}

	return degree;
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if(IsValidClient(client))
    {
        if(menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}

AttachControlPointParticle(ent, String:strParticle[], controlpoint)
{
	new particle  = CreateEntityByName("info_particle_system");
	new particle2 = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{ 
		new String:tName[128];
		Format(tName, sizeof(tName), "SimpleBuild:%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		new String:cpName[128];
		Format(cpName, sizeof(cpName), "SimpleBuild:%s", g_sAuthID[ent]);
		DispatchKeyValue(controlpoint, "targetname", cpName);

		new String:cp2Name[128];
		Format(cp2Name, sizeof(cp2Name), "tf2particle%i", controlpoint);

		DispatchKeyValue(particle2, "targetname", cp2Name);
		DispatchKeyValue(particle2, "parentname", cpName);

		new Float:pos[3], Float:m_vecMaxs[3], Float:cAng[3];
		GetClientAbsAngles(ent, cAng);
		GetEntPropVector(controlpoint, Prop_Data, "m_vecOrigin", pos);
		GetEntPropVector(controlpoint, Prop_Send, "m_vecMaxs", m_vecMaxs);
		
		pos[2] += (m_vecMaxs[2] / 2.0);
		
		SetEntPropVector(particle, Prop_Data, "m_angRotation", cAng);
		SetEntPropVector(particle2, Prop_Data, "m_vecOrigin", pos);
		
		SetVariantString(cpName);
		AcceptEntityInput(particle2, "SetParent");

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", strParticle);
		DispatchKeyValue(particle, "cpoint1", cp2Name);

		DispatchSpawn(particle);

		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent");

		SetVariantString("flag");
		AcceptEntityInput(particle, "SetParentAttachment");

		//The particle is finally ready
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	
		g_particle1[ent] = EntIndexToEntRef(particle);
		g_particle2[ent] = EntIndexToEntRef(particle2);
	}
}

public Action:Construct_Noclip(client, args)
{
	if(IsValidClient(client) && g_bInConstructZone[client])
	{
		if(!(GetEntityMoveType(client) & MOVETYPE_NOCLIP))
		{
			if(g_iGrabbedEnt[client] == -1)
			{
				CPrintToChat(client, "{unique}[Construct]{default} Noclip: {arcana}On{default}!");
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				GetClientAbsOrigin(client, g_vecNoclipStartPos[client]);
				g_bIsNoclipping[client] = true;
			}
			else
			{
				CPrintToChat(client, "{unique}[Construct]{default} {fullred}ERROR{default}: You can't noclip while grabbing something!");
				EmitSoundToClient(client, SOUND_ERROR);
				return Plugin_Handled;
			}
		}
		else
		{
			CPrintToChat(client, "{unique}[Construct]{default} Noclip: {arcana}Off{default}!");
			SetEntityMoveType(client, MOVETYPE_WALK);
			g_bIsNoclipping[client] = false;
		}
	}
	
	return Plugin_Handled;
}

public Action:Construct_Alpha(client, args)
{
	if(IsValidClient(client) && g_bInConstructZone[client])
	{
		if(!g_bAlphaManip[client])
		{
			CPrintToChat(client, "{unique}[Construct]{default} Grab Alpha: {arcana}On{default}!");
			g_bAlphaManip[client] = true;
		}
		else
		{
			CPrintToChat(client, "{unique}[Construct]{default} Grab Alpha: {arcana}Off{default}!");
			g_bAlphaManip[client] = false;
		}
	}
	
	return Plugin_Handled;
}

public Action:DumpEntities(client, args)
{
	new edicts, ents, edicts_max = GetMaxEntities(), ents_max = edicts_max;
	for (new i = 1; i <= ents_max*2; i++)
	{
		if (IsValidEdict(i)) edicts++;
		else if (IsValidEntity(i)) ents++;
	}
	ReplyToCommand(client, "        Count     Free      Used");
	ReplyToCommand(client, "Edicts: %i        %i        %.0f%c", edicts, edicts_max-edicts, 100.0*(float(edicts)/float(edicts_max)), '%');
	ReplyToCommand(client, "Other:  %i        %i        %.0f%c", ents, ents_max-ents, 100.0*(float(ents)/float(ents_max)), '%');
	return Plugin_Handled;
}

public Zone_OnClientEntry(client, String:zone[])
{
	if (StrContains(zone, "construct", false) != -1 && IsValidClient(client) && !g_bInConstructZone[client] && GetClientTeam(client) != _:TFTeam_Spectator)
	{
		CPrintToChat(client, "{unique}[Construct]{default} Welcome to the {unique}Construction Zone{default}!");
		CPrintToChat(client, "{unique}[Construct]{default} Use {arcana}!construct_menu{default}");
		g_bInConstructZone[client] = true;
	}
}

public Zone_OnClientLeave(client, String:zone[])
{
	if (StrContains(zone, "construct", false) != -1 && IsValidClient(client) && g_bInConstructZone[client] && GetClientTeam(client) != _:TFTeam_Spectator)
	{
		if(GetEntityMoveType(client) & MOVETYPE_NOCLIP)
		{
			CPrintToChat(client, "{unique}[Construct]{default} {fullred}You are not allowed to noclip anywhere else but in the construct zone!");
			EmitSoundToClient(client, SOUND_ERROR);
			new Float:zonecenter[3];
			Zone_GetZonePosition("construct", false, zonecenter);
			SetEntityMoveType(client, MOVETYPE_WALK);
			TeleportEntity(client, zonecenter, NULL_VECTOR, NULL_VECTOR);
			g_bIsNoclipping[client] = false;
		}
		else
			g_bInConstructZone[client] = false;
			
	//	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2 || GetUserFlagBits(client) & ADMFLAG_ROOT)
		//	ForceDropClient(client);
	}
}

public OnMapEnd()
{
	if(g_hMainMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hMainMenu);
		g_hMainMenu = INVALID_HANDLE;
	}
	if(g_hControlMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hControlMenu);
		g_hControlMenu = INVALID_HANDLE;
	}
	if(g_hManipMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hManipMenu);
		g_hManipMenu = INVALID_HANDLE;
	}
	if(g_hPropMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hPropMenu);
		g_hPropMenu = INVALID_HANDLE;
	}
	if(g_hColorMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hColorMenu);
		g_hColorMenu = INVALID_HANDLE;
	}
	if(g_hResizeMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hResizeMenu);
		g_hResizeMenu = INVALID_HANDLE;
	}
	if(g_hParticleMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hParticleMenu);
		g_hParticleMenu = INVALID_HANDLE;
	}
	if(g_hTipsMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hTipsMenu);
		g_hTipsMenu = INVALID_HANDLE;
	}
	if(g_hAdminMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hAdminMenu);
		g_hAdminMenu = INVALID_HANDLE;
	}
}

//Alphabetical sorting
stock Handle:ConvertAndSortArray(const String:array[][][])
{
	new Handle:FullArray = CreateArray(PLATFORM_MAX_PATH, 0);
	
	for(new i=0; i<sizeof(g_sPropList); i++)
	{
		decl String:buffer[500];
		Format(buffer, sizeof(buffer), "%s<-245ç&/->%s", g_sPropList[i][1], g_sPropList[i][0]);
		PushArrayString(FullArray, buffer);
	}
	
	SortADTArray(FullArray, Sort_Ascending, Sort_String);
	
	return FullArray;
}

stock String:GetModelFromArray(Handle:array, index)
{
	decl String:buffer[PLATFORM_MAX_PATH];
	decl String:model[2][PLATFORM_MAX_PATH];
	GetArrayString(array, index, buffer, sizeof(buffer));
	ExplodeString(buffer, "<-245ç&/->", model, sizeof model, sizeof model[]);
	return model[1];
}

stock String:GetNameFromArray(Handle:array, index)
{
	decl String:buffer[PLATFORM_MAX_PATH];
	decl String:model[2][PLATFORM_MAX_PATH];
	GetArrayString(array, index, buffer, sizeof(buffer));
	ExplodeString(buffer, "<-245ç&/->", model, sizeof model, sizeof model[]);
	return model[0];
}

public Native_InConstructZone(Handle:plugin, numParams) 
{
	new client = GetNativeCell(1);
	
	if (!IsValidClient(client)) 
		return false;
	if (g_bInConstructZone[client]) 
		return true;
	else 
		return false;
}

public Native_GetPropOwner(Handle:plugin, numParams)
{
	new prop = GetNativeCell(1);
	
	if(IsValidEntity(prop))
	{
		new String:class[64];
		GetEntityClassname(prop, class, sizeof(class));

		if(StrContains(class, "prop_dynamic") != -1)
		{
			decl String:sTargetName[256];
			GetEntPropString(prop, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
			if(StrContains(sTargetName, "SimpleBuild:", false) != -1 || StrContains(sTargetName, "construct", false) != -1)
			{
				return g_iOwner[prop];
			}
			else
				return -1;
		}
		else
			return -1;
	}
	else
		return -1;
}