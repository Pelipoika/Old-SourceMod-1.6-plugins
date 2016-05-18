#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gmg\users>
#include <gmg\colors>
#include <gmg\misc>
#pragma semicolon 1

#define SOUND_DEFINE 	"items/flashlight1.wav"
#define SOUND_LOCK 		"physics/plaster/ceiling_tile_impact_hard3.wav"
#define SOUND_DELETE	"physics/plaster/drywall_impact_hard1.wav"
#define SOUND_PAINT		"physics/flesh/flesh_squishy_impact_hard2.wav"
#define SOUND_DENIED	"replay/record_fail.wav"

#define PROP_PATH 0
#define PROP_NAME 1

new ColorRed[4] = { 255, 0, 0, 200 };
new ColorGreen[4] = { 0, 255, 0, 200 };
new ColorBlue[4] = { 0, 0, 255, 200 };

new g_iHalo;
new g_iBeamIndex;
new g_iOwner[4096];
new bool:g_bKillProp[4096];
new bool:g_bSpinProp[4096];
new g_iPropCount[MAXPLAYERS+1];
new g_iLastProp[MAXPLAYERS+1];
new g_iSelectedProp[MAXPLAYERS+1];
new Float:g_fSelectedPropDist[MAXPLAYERS+1];
new Float:g_fSelectedPropAng[MAXPLAYERS+1];
new bool:g_bPerformance[MAXPLAYERS+1];
new bool:g_bConstructing[MAXPLAYERS+1];
new Float:g_vecLockedAng[MAXPLAYERS+1][3];
new Float:g_vecSelectedPropPrevPos[MAXPLAYERS+1][3];
new Float:g_vecSelectedPropPrevAng[MAXPLAYERS+1][3];
new Handle:g_hTimerHud[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hHudOwner = INVALID_HANDLE;
new g_iCurLocation[MAXPLAYERS+1];

new bool:g_bFlying[MAXPLAYERS + 1];
new bool:g_bPaused[MAXPLAYERS + 1];

new const String:g_sPropList[][][] =
{
//	{"Model",			"Name"},
	{"models/props_hydro/barrel_crate_half.mdl", 			"Crate"},
	{"models/props_hydro/barrel_crate.mdl",					"Stacked Crates"},
	{"models/props_lakeside/wood_crate_01.mdl", 			"Large Crate"},
	{"models/props_farm/concrete_block001.mdl", 			"Concrete Block"},
	{"models/props_coalmines/wood_fence_short_256.mdl", 	"Short Fence"},
	{"models/props_coalmines/wood_fence_256.mdl", 			"Large Fence"},
	{"models/props_gameplay/security_fence_section01.mdl",	"Small Gate"},
	{"models/props_gameplay/security_fence256_gate01.mdl",	"Large Gate"},
	{"models/props_mining/fence001_reference.mdl", 			"Wooden Fence"},
	{"models/props_farm/stairs_wood001a.mdl", 				"Small Stairs"},
	{"models/props_farm/stairs_wood001b.mdl", 				"Large Stairs"},
	{"models/props_hydro/dumptruck_empty.mdl", 				"Truck"},
	{"models/egypt/palm_tree/palm_tree.mdl", 				"Palm Tree"},
	{"models/props_foliage/tree_pine_extrasmall.mdl", 		"Pine Tree"},
	{"models/props_trainyard/crane_platform001.mdl", 				"Crane Platform"},
	{"models/props_trainyard/crane_platform001b.mdl", 				"Crane Platform Bottom"},
	{"models/props_doomsday/power_core_type1.mdl",					"Power Coil Type 1"},
	{"models/props_doomsday/power_core_type1b.mdl",					"Power Coil Type 1b"},
	{"models/weapons/c_models/c_sandwich/c_robo_sandwich.mdl",		"Robo Sandwich"},
	{"models/items/plate_robo_sandwich.mdl",						"Robo Sandwich on a Plate"},
	{"models/weapons/c_models/c_sandwich/c_sandwich.mdl",			"Sandwich"},
	{"models/items/plate.mdl",										"SandWich on a Plate"},
	{"models/weapons/c_models/c_buffalo_steak/c_buffalo_steak.mdl",	"The Buffalo Steak"},
	{"models/items/plate_steak.mdl",								"The Buffalo Steak on a Plate"},
	{"models/weapons/c_models/c_sandwich/c_sandwich_xmas.mdl",		"Festive Sandwich"},
	{"models/items/plate_sandwich_xmas.mdl",						"Festive Sandwich on a Plate"},
	{"models/props_2fort/oildrum.mdl",								"Oildrum"},
	{"models/props_gameplay/sign_barricade001a.mdl",	"Barricade Sign"},
	{"models/props_2fort/tire002.mdl",					"Stack of Tires"},
	{"models/props_2fort/tire001.mdl",					"Tire"},
	{"models/props_farm/oilcan02.mdl",					"Oil Can"},
	{"models/props_2fort/miningcrate001.mdl",			"Dynamite Crate"},
	{"models/props_2fort/waterpump001.mdl",				"Water Pump"},
	{"models/props_gameplay/cap_point_base.mdl",		"Control Point"},
	{"models/props_2fort/metalbucket001.mdl",			"Metal Bucket"},
	{"models/props_2fort/lantern001_off.mdl",			"Lantern"},
	{"models/props_2fort/trainwheel003.mdl",			"Stack of Trainwheels"},
	{"models/props_2fort/corrugated_metal003.mdl",		"Corrugated Metal"},
	{"models/props_2fort/milkjug001.mdl",				"Milk Jug"},
	{"models/props_2fort/mop_and_bucket.mdl",			"Mop and Bucket"},
	{"models/props_2fort/propane_tank_tall01.mdl",		"Propane Tank"},
	{"models/props_halloween/tombstone_01.mdl",			"Tombstone"},
	{"models/props_badlands/barrel01.mdl",				"Biohazard Barrel"},
	{"models/props_farm/pallet001.mdl",					"Wood Pallet"},
	{"models/props_farm/concrete_block001.mdl",			"Concrete Block"},
	{"models/props_farm/wood_pile.mdl",					"Wood Pile"},
	{"models/props_farm/welding_machine01.mdl",			"Welding Machine"},
	{"models/props_foliage/cactus01.mdl",				"Giant Cactus"},
	{"models/props_granary/grain_sack.mdl",				"Grain Sack"},
	{"models/props_gameplay/orange_cone001.mdl",		"Traffic Cone"},
	{"models/props_forest/milk_crate.mdl",				"Milk Crate"},
	{"models/props_nature/rock_worn001.mdl",			"Rock"},
	{"models/props_well/computer_cart01.mdl",			"Computer Cart"},
	{"models/props_mining/sign001.mdl",					"Skull Sign"},
	{"models/props_gameplay/haybale.mdl",				"Hay Bale"},
	{"models/props_spytech/watercooler.mdl",			"Water Cooler"},
	{"models/props_spytech/tv001.mdl",					"Television"},
	{"models/props_halloween/jackolantern_02.mdl",		"Jackolantern"},
	{"models/props_spytech/terminal_chair.mdl",			"Terminal Chair"},
	{"models/props_well/hand_truck01.mdl",				"Hand Truck"},
	{"models/props_2fort/sink001.mdl",					"Sink"},
	{"models/props_2fort/chimney005.mdl",				"Chimney"},
	{"models/props_manor/chair_01.mdl",					"Chair"},
	{"models/props_manor/bookcase_132_01.mdl",			"Bookcase"},
	{"models/props_manor/chandelier_01.mdl",			"Chandelier"},
	{"models/props_manor/couch_01.mdl",					"Couch"},
	{"models/props_manor/gothic_fence_01.mdl",			"Gothic Fenc"},
	{"models/props_manor/ornate_rug_01.mdl",			"Rug"},
	{"models/props_halloween/tombstone_02.mdl",			"The Tenth Class"},
	{"models/props_manor/table_02.mdl",					"Table"},
	{"models/props_manor/tractor_01.mdl",				"Tractor"},
	{"models/props_medieval/fort_wall.mdl",				"Fort Wall"},
	{"models/props_medieval/fort_wall_short.mdl",		"Short Fort Wall"},
	{"models/props_medieval/target/target.mdl",			"Target"},
	{"models/props_training/target_demoman.mdl",		"Demoman"},
	{"models/props_training/target_engineer.mdl",		"Engineer"},
	{"models/props_training/target_heavy.mdl",			"Heavy"},
	{"models/props_training/target_medic.mdl",			"Medic"},
	{"models/props_training/target_pyro.mdl",			"Pyro"},
	{"models/props_training/target_scout.mdl",			"Scout"},
	{"models/props_training/target_sniper.mdl",			"Sniper"},
	{"models/props_training/target_soldier.mdl",		"Soldier"},
	{"models/props_training/target_spy.mdl",			"Spy"},
	{"models/props_farm/wooden_barrel.mdl",				"Barrel"},
	{"models/ambulance.mdl",							"Ambulance"},
	{"models/props_manor/table_03.mdl",					"Table_03"},
	{"models/props_soho/bus001.mdl",					"Bus"},
	{"models/egypt/pillar/pillar.mdl",					"Pillar"},
	{"models/egypt/tent/tent.mdl",						"Tent"},
	{"models/harvest/pumpkin/pumpkin_small.mdl",		"Pumpkin Small"},
	{"models/harvest/pumpkin/pumpkin_big.mdl",			"Pumpkin Big"},
	{"models/props_c17/furniturebed001a.mdl",			"Bed Frame"},
	{"models/props_doomsday/western_wood_door001.mdl",	"Western Wood Door"},
	{"models/props_farm/tree001.mdl",					"Tree"},
	{"models/props_manor/baby_grand_01.mdl",			"Grand Piano"},
	{"models/props_manor/clocktower_01.mdl",			"Clocktower"},
	{"models/props_manor/coffin_01.mdl",				"Coffin"},
	{"models/props_manor/doorframe_01.mdl",				"Doorframe"},
	{"models/props_spytech/computer_low.mdl",			"Computer"},
	{"models/props_manor/external_window_04c.mdl",		"Window"},
	{"models/props_manor/front_doors.mdl",				"Front Doors"},
	{"models/props_medieval/anvil.mdl",					"Anvil"},
	{"models/props_medieval/bar_table.mdl",				"Bar Table"},
	{"models/props_medieval/medieval_door_frame.mdl",	"Medieval Door Frame"},
	{"models/props_movies/campervan/campervan.mdl",		"Campervan"},
	{"models/props_mvm/construction_light02.mdl",		"Construction Light"},
	{"models/props_mvm/mannco_lit_sign.mdl",			"MannCo Sign"},
	{"models/props_mvm/mvm_sign_arrow02.mdl",			"Arrow Sign"},
	{"models/props_mvm/sign_forsale.mdl",				"ForSale Sign"},
	{"models/props_forest/kitchen_shelf.mdl",			"Kitchen Shelf"},
	{"models/props_forest/kitchen_stove.mdl",			"Kitchen Stove"},
	{"models/props_wasteland/kitchen_counter001d.mdl",	"Kitchen Counter"},
	{"models/props_wasteland/kitchen_shelf001a.mdl",	"Kitchen Shelf"},
	{"models/props_wasteland/kitchen_stove002a.mdl",	"Stacked Stoves"}
};

public Plugin:myinfo = 
{
	name = "Building Area",
	author = "Pelipoika(ish)",
	description = "Build shit",
	version = "1.0.8",
	url = ""
}

//////////
// INIT //
//////////

public OnPluginStart()
{
	RegConsoleCmd("sm_construct", Command_Construct);
	RegConsoleCmd("sm_autobuild", Command_Stack);
	RegConsoleCmd("construct_rotate", Rotate_Prop);
	RegConsoleCmd("construct_move", Move_Prop);
	
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_hHudOwner = CreateHudSynchronizer();
	HookEntityOutput("trigger_multiple", "OnStartTouch", StartTouch);
	
//	g_iBeamIndex = PrecacheModel("materials/sprites/purplelaser1.vmt");
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_iBeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public OnMapStart()
{
	PrecacheSound(SOUND_DEFINE);
	PrecacheSound(SOUND_LOCK);
	PrecacheSound(SOUND_DELETE);
	PrecacheSound(SOUND_PAINT);
	PrecacheSound(SOUND_DENIED);
	
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_iBeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	
	for(new i=0; i<sizeof(g_sPropList); i++)
		PrecacheModel(g_sPropList[i][PROP_PATH]);
}

public OnClientConnected(client)
{
	g_bConstructing[client] = false;
	g_bPerformance[client] = false;
	g_iCurLocation[client] = 0;
}

public OnClientDisconnect(client)
{
	ClearAllProps(client);
	SafeKillTimer(g_hTimerHud[client]);
}

//////////
// BASE //
//////////

public Action:Command_Construct(client, args)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		EnterConstruction(client);
		ReplyToCommand(client, "Entered Construction Mode.");
		
		if(User_GetLocation(client) != LOCATION_CONSTRUCT)
		{
			ReplyToCommand(client, "You can't do this here.");
			ShowMenu_Main(client);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "\x01You need to be a \x06V.I.P\x01 to use this.");
		ReplyToCommand(client, "\x01To get \x06V.I.P\x01, check out !donate");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Timer_Hud(Handle:timer, any:client)
{
	if (client > 0 && IsClientInGame(client) && IsClientConnected(client))
	{
		new target = GetClientAimTarget(client, false);
		if(target > 0)
		{
			if(g_iOwner[target] != client && g_iOwner[target] != 0)
			{
				SetHudTextParams(-1.0, 0.6, 0.1, 255, 255, 255, 255, _, _, 0.0, 0.0);
				ShowSyncHudText(client, g_hHudOwner, "Built by: %N", g_iOwner[target]);
			}
		}
	}
}

ShowMenu_Main(client)
{
	new Handle:menu = CreateMenu(Menu_Main);
	SetMenuTitle(menu, "Construction - Main");
	
	AddMenuItem(menu, "1", "Spawnlist");
	AddMenuItem(menu, "2", "Manipulate Prop");
	AddMenuItem(menu, "3", "Color Properties");
	AddMenuItem(menu, "4", "Toggle Collision");
	AddMenuItem(menu, "5", "Undo Last Prop");
	AddMenuItem(menu, "6", "Delete Prop");
	AddMenuItem(menu, "7", "Clear All Props");
	if(IsClientInGame(client) && GetUserFlagBits(client) & ADMFLAG_ROOT)
		AddMenuItem(menu, "8", "Admin Control Panel");
	else
		AddMenuItem(menu, "8", "Admin Control Panel", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "9", "Resize Prop");
	AddMenuItem(menu, "10", "Straighten Prop");
	AddMenuItem(menu, "11", "Toggle Performance Mode");
	AddMenuItem(menu, "12", "Show Prop Info");
	if(IsClientInGame(client) && g_bFlying[client])
		AddMenuItem(menu, "13", "Toggle Flying: On");
	else
		AddMenuItem(menu, "13", "Toggle Flying: Off");
	AddMenuItem(menu, "14", "Create 3D Axis visualisation");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

StraightenAimProp(client)
{
	new target = GetClientAimTarget(client, false);
	if(CanModifyProp(client, target))
	{
		decl Float:f_angles[3];
		f_angles[0] = 0.0, f_angles[1] = 0.0, f_angles[2] = 0.0;
					
		TeleportEntity(target, NULL_VECTOR, f_angles, NULL_VECTOR);
	}
	ShowMenu_Main(client);
}

ToggleFly(client)
{
	if(User_GetLocation(client) != LOCATION_CONSTRUCT)
	{
		ReplyToCommand(client, "You can't do this here.");
		ShowMenu_Main(client);
//		return Plugin_Handled;
	}
	if(g_bFlying[client])
	{
		new Float:_fVelocity[3];
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVelocity);
		SetEntityMoveType(client, MOVETYPE_WALK);
		PrintToChat(client, "\x05Toggle Fly: Off");
		g_bFlying[client] = false;
	}
	else
	{
		SetEntityMoveType(client, MOVETYPE_FLY);
		PrintToChat(client, "\x04Toggle Fly: On");
		g_bFlying[client] = true;
	}
//	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_bFlying[client] && User_GetLocation(client) == LOCATION_CONSTRUCT)
	{
		if(buttons & IN_ATTACK2)
		{
			new Float:_fVelocity[3];
			SetEntityMoveType(client, MOVETYPE_NONE);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVelocity);
			g_bPaused[client] = true;
		}
		else if(g_bPaused[client])
		{
			g_bPaused[client] = false;
			SetEntityMoveType(client, MOVETYPE_FLY);	
		}
	}
}

CreateAxis(client)
{
	if (IsPlayerAlive(client))
	{
		decl Float:fClientO[3], Float:fClientX[3], Float:fClientY[3], Float:fClientZ[3];
	
		GetClientAbsOrigin(client, fClientO);
		GetClientAbsOrigin(client, fClientX);
		GetClientAbsOrigin(client, fClientY);
		GetClientAbsOrigin(client, fClientZ);
		
		fClientX[0] = fClientX[0] + 50;
		fClientY[1] += 50;
		fClientZ[2] += 50;
		
		TE_SetupBeamPoints(fClientO, fClientX, g_iBeamIndex, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, ColorRed, 10);
		TE_SendToClient(client, 0.0);

		TE_SetupBeamPoints(fClientO, fClientY, g_iBeamIndex, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, ColorGreen, 10);
		TE_SendToClient(client, 0.0);

		TE_SetupBeamPoints(fClientO, fClientZ, g_iBeamIndex, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, ColorBlue, 10);
		TE_SendToClient(client, 0.0);
		
		PrintToChat(client, "\x04Created a 3D Axis. Red: X Green: Y Blue: Z");
	}
	else
	{
		PrintToChat(client, "You must be alive to use this command!");
	//	return Plugin_Handled;
	}
//	return Plugin_Handled;
}

public Action:Rotate_Prop(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04USAGE: construct_rotate <x> <y> <z>");
		return Plugin_Handled;
	}
	
	new target = GetClientAimTarget(client, false);
	
	if(CanModifyProp(client, target))
	{
		decl Float:g_angles[3], Float:g_angles2[3];
		decl String:sArg[32], String:sArg2[32], String:sArg3[32];

		GetCmdArg(1, sArg, sizeof(sArg));
		GetCmdArg(2, sArg2, sizeof(sArg2));
		GetCmdArg(3, sArg3, sizeof(sArg3));
			
		new x = StringToInt(sArg), y = StringToInt(sArg2), z = StringToInt(sArg3);
		
		GetEntPropVector(target, Prop_Send, "m_angRotation", g_angles);
		
		g_angles2[0] = (g_angles[0] += x);
		g_angles2[1] = (g_angles[1] += y);
		g_angles2[2] = (g_angles[2] += z);
		
		TeleportEntity(target, NULL_VECTOR, g_angles2, NULL_VECTOR);
	}
	return Plugin_Handled;
}

public Menu_Main(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(User_GetLocation(client) != LOCATION_CONSTRUCT)
		{
			ReplyToCommand(client, "You can't do this here.");
			ShowMenu_Main(client);
			return;
		}
		ShowMenu_Main(client);
		switch(option)
		{
			case 0: ShowMenu_Spawn(client);
			case 1: ShowMenu_Manip(client);
			case 2: ShowMenu_Color(client);
			case 3: ToggleAimCollision(client);
			case 4: DeleteLastProp(client);
			case 5: DeleteAimProp(client);
			case 6: ShowMenu_Clear(client);
			case 7: ShowMenu_Admin(client);
			case 8: ShowMenu_Resize(client);
			case 9: StraightenAimProp(client);
			case 10: ShowMenu_Performance(client);
			case 11: ShowPropInfo(client);
			case 12: ToggleFly(client);
			case 13: CreateAxis(client);
		}
	}
	else if(action == MenuAction_Cancel)
		ExitConstruction(client);
}

ShowMenu_Resize(client)
{
	new Handle:menu = CreateMenu(Menu_Resize);
	SetMenuTitle(menu, "Construction - Size Modifier");
	
	AddMenuItem(menu, "1", "Size 0.5x");
	AddMenuItem(menu, "2", "Size 0.6x");
	AddMenuItem(menu, "3", "Size 0.7x");
	AddMenuItem(menu, "4", "Size 0.8x");
	AddMenuItem(menu, "5", "Size 0.9x");
	AddMenuItem(menu, "6", "Size 1.0x");
	AddMenuItem(menu, "7", "Size 1.1x");
	AddMenuItem(menu, "8", "Size 1.2x");
	AddMenuItem(menu, "9", "Size 1.3x");
	AddMenuItem(menu, "10", "Size 1.4x");
	AddMenuItem(menu, "11", "Size 1.5x");
	AddMenuItem(menu, "12", "Size 1.6x");
	AddMenuItem(menu, "13", "Size 1.7x");
	AddMenuItem(menu, "14", "Size 1.8x");
	AddMenuItem(menu, "15", "Size 1.9x");
	AddMenuItem(menu, "16", "Size 2.0x");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

public Menu_Resize(Handle:menu, MenuAction:action, client, option)
{	
	if(action == MenuAction_Select)
	{
		new target = GetClientAimTarget(client, false);
		if(CanModifyProp(client, target))
		{
			switch(option)
			{
				case 0: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 0.5);
				case 1: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 0.6);
				case 2: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 0.7);
				case 3: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 0.8);
				case 4: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 0.9);
				case 5: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.0);
				case 6: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.1);
				case 7: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.2);
				case 8: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.3);
				case 9: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.4);
				case 10: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.5);
				case 11: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.6);
				case 12: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.7);
				case 13: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.8);
				case 14: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 1.9);
				case 15: SetEntPropFloat(target, Prop_Send, "m_flModelScale", 2.0);
			}
		}
		ShowMenu_Resize(client);
	}
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

ShowMenu_Spawn(client)
{	
	new Handle:menu = CreateMenu(Menu_Spawn);
	SetMenuTitle(menu, "Construction - Spawn Props (Count: %i)", g_iPropCount[client]);
	
	for(new i=0; i<sizeof(g_sPropList); i++)
		AddMenuItem(menu, g_sPropList[i][PROP_PATH], g_sPropList[i][PROP_NAME]);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

public Menu_Spawn(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(User_GetLocation(client) != LOCATION_CONSTRUCT)
		{
			ReplyToCommand(client, "You can't do this here.");
			ShowMenu_Main(client);
			return;
		}
		else 
			ShowMenu_Main(client);
			
		if((g_iPropCount[client] >= 60) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			PrintToChat(client, "\x04You can't spawn any more props.");
			ShowMenu_Main(client);
			return;
		}
		decl Float:origin[3], Float:angles[3], Float:pos[3], Float:ang[3];
		GetClientAbsAngles(client, ang);
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angles);
		new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
		
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace);
			
//		Anti build-on-player code
//		--------------------------------------------------------------------------
			for(new i=1; i<=GetMaxClients(); i++)
			{
				if(!IsValidEntity(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(client == i) continue;

				decl Float:clientPos[3];
				GetClientAbsOrigin(i, clientPos);
				
				if(GetVectorDistance(clientPos, pos) <= 156.0)
				{
					EmitSoundToClient(client, SOUND_DENIED);
					TE_SetupBeamRingPoint(pos, 156.0, 156.0, g_iBeamIndex, g_iHalo, 0, 15, 1.0, 32.0, 0.5, ColorRed, 10, FBEAM_SOLID);
					TE_SendToClient(client);
					PrintToChat(client, "\x06You cannot build on players!");
					return;
				}
			}
//		--------------------------------------------------------------------------
			
			CreateParticle("ping_circle", pos);
			EmitSoundToClient(client, SOUND_DEFINE, _, _, _, _, _, 50);
			
			new ent = CreateEntityByName("prop_dynamic_override");
			SetEntityModel(ent, g_sPropList[option][PROP_PATH]);
			DispatchKeyValue(ent, "solid", "6");
			DispatchSpawn(ent);
			angles[0] = 0.0;
			TeleportEntity(ent, pos, angles, NULL_VECTOR);
			SetEntityMoveType(ent, MOVETYPE_NONE);
			SetEntityRenderMode(ent, RENDER_TRANSALPHA);
			
			SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
			
			g_iOwner[ent] = client;
			g_iPropCount[client]++;
			g_iLastProp[client] = ent;
//			LogToFile("logs/construction/spawn.txt", "%L spawned %s", client, g_sPropList[option][PROP_NAME]);
		}
		
		ShowMenu_Spawn(client);
	}
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

ShowMenu_Manip(client)
{
	new target = GetClientAimTarget(client, false);
	if(User_GetLocation(client) != LOCATION_CONSTRUCT)
	{
		ReplyToCommand(client, "You can't do this here.");
		ShowMenu_Main(client);
		return;
	}
	if(CanModifyProp(client, target))
	{
		new Float:vecPlayerPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vecPlayerPos);

		g_iSelectedProp[client] = target;
		GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_angRotation", g_vecSelectedPropPrevAng[client]);
		GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_vecOrigin",   g_vecSelectedPropPrevPos[client]);

		new Float:vecTempAng[3];
		new Float:vecTempPos[3];

		SubtractVectors(g_vecSelectedPropPrevPos[client], vecPlayerPos, vecTempPos);
		GetVectorAngles(vecTempPos, vecTempAng);

		g_fSelectedPropAng[client] = vecTempAng[1];
		g_fSelectedPropDist[client] = GetVectorLength(vecTempPos);

		SetEntityMoveType(client, MOVETYPE_NONE);
		SDKHook(client, SDKHook_PreThink, PropManip);
		
		new Handle:menu = CreateMenu(Menu_Manip);
		SetMenuTitle(menu, "WASD = Move Forward/Left/Back/Right | Jump + Duck = Move Up/Down | Alt-Fire + Mouse = Rotate");
		
		AddMenuItem(menu, "1", "Save");
		AddMenuItem(menu, "2", "Revert");
		
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 360);
	}
}

public Menu_Manip(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		/*GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_vecOrigin", g_vecSelectedPropNewPos[client]);
		
		for(new i=1; i<=GetMaxClients(); i++)
		{
			if(!IsValidEntity(i)) continue;
			if(!IsPlayerAlive(i)) continue;
			if(client == i) continue;

			decl Float:clientPos[3];
			GetClientAbsOrigin(i, clientPos);
				
			if(GetVectorDistance(clientPos, g_vecSelectedPropNewPos[client]) <= 156.0)
			{
				EmitSoundToClient(client, SOUND_DENIED);
				TE_SetupBeamRingPoint(g_vecSelectedPropNewPos[client], 156.0, 156.0, g_iBeamIndex, g_iHalo, 0, 3, 0.5, 32.0, 1.0, {255, 0, 0, 255}, 10, 0);
				TE_SendToClient(client, 0.0);
				PrintToChat(client, "\x06You cannot build on players!");
				return;
			}
		}*/
	
		g_fSelectedPropAng[client] = 0.0;
		g_fSelectedPropDist[client] = 0.0;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SDKUnhook(client, SDKHook_PreThink, PropManip);
		EmitSoundToClient(client, SOUND_LOCK, _, _, _, _, _, 50);
		ShowMenu_Main(client);
		
		if(option == 1)
			TeleportEntity(g_iSelectedProp[client], g_vecSelectedPropPrevPos[client], g_vecSelectedPropPrevAng[client], NULL_VECTOR);
	}
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

ShowMenu_Color(client)
{
	new Handle:menu = CreateMenu(Menu_Color);
	SetMenuTitle(menu, "Construction - Color Modifier");
	
	AddMenuItem(menu, "1", "Normal");
	AddMenuItem(menu, "2", "Red");
	AddMenuItem(menu, "3", "Green");
	AddMenuItem(menu, "4", "Blue");
	AddMenuItem(menu, "5", "Yellow");
	AddMenuItem(menu, "6", "Pink");
	AddMenuItem(menu, "7", "Cyan");
	AddMenuItem(menu, "8", "See-Through");
	AddMenuItem(menu, "9", "Desaturate");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

public Menu_Color(Handle:menu, MenuAction:action, client, option)
{	
	if(action == MenuAction_Select)
	{
		new target = GetClientAimTarget(client, false);
		if(CanModifyProp(client, target))
		{
			switch(option)
			{
				case 0: SetEntityRenderColor(target, 255, 255, 255, 255);
				case 1: SetEntityRenderColor(target, 255, 0, 0, 255);
				case 2: SetEntityRenderColor(target, 0, 255, 0, 255);
				case 3: SetEntityRenderColor(target, 0, 0, 255, 255);
				case 4: SetEntityRenderColor(target, 255, 255, 0, 255);
				case 5: SetEntityRenderColor(target, 255, 0, 255, 255);
				case 6: SetEntityRenderColor(target, 0, 255, 255, 255);
				case 7:
				{
					new offset = GetEntSendPropOffs(target, "m_clrRender");
					SetEntData(target, offset + 3, 128, 1, true);
					ShowMenu_Color(client);
				}
				case 8:
				{
					new offset = GetEntSendPropOffs(target, "m_clrRender");
					for(new i=0; i<=2; i++)
					{
						if(GetEntData(target, offset + i, 1) == 0)
							SetEntData(target, offset + i, 128, 1, true);
					}
					ShowMenu_Color(client);
				}
			}
		}
		ShowMenu_Color(client);
		if(option > 7)
			ClientCommand(client, "slot9");
		EmitSoundToClient(client, SOUND_PAINT, _, _, _, _, _, 120);
	}
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

ShowMenu_Clear(client)
{
	new Handle:menu = CreateMenu(Menu_Clear);
	SetMenuTitle(menu, "Are you sure you want to clear all props?");
	
	AddMenuItem(menu, "1", "Yes");
	AddMenuItem(menu, "2", "No");
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 360);
}

public Menu_Clear(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{
			ClearAllProps(client);
		}
		ShowMenu_Main(client);
	}
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

ShowMenu_Admin(client)
{
	new Handle:menu = CreateMenu(Menu_Admin);
	SetMenuTitle(menu, "Construction - Admin Control Panel");
	
	AddMenuItem(menu, "1", "Clear All Player Props");
	AddMenuItem(menu, "2", "Take Ownership");
	AddMenuItem(menu, "3", "Take Ownership (All Props)");
	AddMenuItem(menu, "4", "Display Prop Count");
	AddMenuItem(menu, "5", "Toggle No-Touch");
	AddMenuItem(menu, "6", "Toggle Spin");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

public Menu_Admin(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0:
			{
				for(new i=1; i<=GetMaxClients(); i++)
					ClearAllProps(i);
//				LogToFile("logs/construction/clearall.txt", "%L cleared all props", client);
			}
			case 1:
			{
				new target = GetClientAimTarget(client, false);
				if(g_iOwner[target] != client && g_iOwner[target] != 0)
					g_iOwner[target] = client;
			}
			case 2:
			{
				for(new i=1; i<sizeof(g_iOwner); i++)
				{
					if(g_iOwner[i] != 0)
						g_iOwner[i] = client;
				}
			}
			case 3:
			{
				new totalCount = 0;
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(g_iPropCount[i] == 0)
						continue;
					PrintToConsole(client, "[%i] %N", g_iPropCount[i], i);
					totalCount += g_iPropCount[i];
				}
				PrintToConsole(client, "TOTAL PROPS: %i", totalCount);
				PrintToChat(client, "\x04See console for results.");
			}
			case 4:
			{
				new target = GetClientAimTarget(client, false);
				if(CanModifyProp(client, target))
				{
					g_bKillProp[target] = !g_bKillProp[target];
					if(g_bKillProp[target])
					{
						SDKHook(target, SDKHook_StartTouch, NoTouch);
						PrintToChat(client, "No-touch enabled.");
					}
					else
					{
						SDKUnhook(target, SDKHook_StartTouch, NoTouch);
						SetEntProp(target, Prop_Send, "m_nSolidType", 6);
						PrintToChat(client, "No-touch disabled.");
					}
				}
				ShowMenu_Main(client);
			}
			case 5:
			{
				new target = GetClientAimTarget(client, false);
				if(CanModifyProp(client, target))
				{
					if(!g_bSpinProp[target])
					{
						SDKHook(target, SDKHook_PreThink, SpinProp);
						PrintToChat(client, "Spin enabled.");
					}
					else
					{
						SDKUnhook(target, SDKHook_PreThink, SpinProp);
						PrintToChat(client, "Spin disabled.");
						g_bSpinProp[target] = true;
					}
				}
				ShowMenu_Main(client);
			}
		}
		ShowMenu_Admin(client);
	}
	else if(action == MenuAction_Cancel)
		ShowMenu_Main(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

ShowMenu_Performance(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Construction - Toggle Performance Mode");
	DrawPanelText(panel, "You can enable Performance Mode if you are having crashing issues when using Construction.");
	DrawPanelText(panel, "Additionally, Performance Mode may be used if you get low FPS while using Construction.");
	DrawPanelText(panel, " ");
	if(!g_bPerformance[client])
		DrawPanelItem(panel, "Enable Performance Mode");
	else
		DrawPanelItem(panel, "Disable Performance Mode");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "Go Back");
	SendPanelToClient(panel,client, Menu_Performance, 360);
	CloseHandle(panel);
}

public Menu_Performance(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		if(option == 1)
		{
			ShowMenu_Main(client);
			return;
		}
		g_bPerformance[client] = !g_bPerformance[client];
		PrintToChat(client, "Performance Mode %s.", g_bPerformance[client] ? "enabled" : "disabled");
	}
	else if(action == MenuAction_Cancel)
		CloseHandle(menu);
}

public NoTouch(prop, client)
{
	if(g_iOwner[prop] == client)
		return;
	
	ForcePlayerSuicide(client);
	PrintToChat(client, "This prop is protected by No-Touch.");
}

public SpinProp(prop)
{
	decl Float:angles[3];
	GetEntPropVector(prop, Prop_Send, "m_angRotation", angles);
	angles[1] += 0.5;
	TeleportEntity(prop, NULL_VECTOR, angles, NULL_VECTOR);
}

//////////
// FUNC //
//////////

public PropManip(client)
{
	new btns = GetClientButtons(client);
	decl Float:pos[3], Float:ang[3], Float:pAng[3], Float:pPos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_angRotation", pAng);
	GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_vecOrigin", pPos);
	if (IsValidEntity(g_iSelectedProp[client]))
	{
		pos[2] -= 32.0;
		
		if(!g_bPerformance[client])
		{						
			TE_SetupBeamPoints(pos, pPos, g_iBeamIndex, g_iHalo, 0, 15, 0.3, 1.8, 1.0, 1, 0.0, {0, 255, 0, 150}, 10);
			TE_SendToAll(0.0);
		}
		
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
			for(new i=0; i<=2; i++)
			{
				new change = RoundToNearest(g_vecLockedAng[client][i] - ang[i]);
				pAng[i] += float(change);
			}
			TeleportEntity(client, NULL_VECTOR, g_vecLockedAng[client], NULL_VECTOR);
		}
		else
			GetClientEyeAngles(client, g_vecLockedAng[client]);
			
		TeleportEntity(g_iSelectedProp[client], pPos, pAng, NULL_VECTOR);	
	}
}

EnterConstruction(client)
{
	g_bConstructing[client] = true;

	g_hTimerHud[client] = CreateTimer(0.1, Timer_Hud, client, TIMER_REPEAT);
	
//	LogToFile("logs/construction/entermode.txt", "%L", client);
	ShowMenu_Main(client);
}

ExitConstruction(client)
{
	g_bConstructing[client] = false;

	SafeKillTimer(g_hTimerHud[client]);
}

bool:CanModifyProp(client, prop)
{
	if(prop <= GetMaxClients())
	{
		PrintToChat(client, "\x04Not a valid prop.");
		return false;
	}
	if(g_iOwner[prop] != client)
	{
		PrintToChat(client, "\x04You do not own this prop.");
		return false;
	}
	return true;
}

ToggleAimCollision(client)
{
	new target = GetClientAimTarget(client, false);
	if(CanModifyProp(client, target))
	{
		new col = GetEntProp(target, Prop_Send, "m_nSolidType");
		if(col != 0)
		{
			SetEntProp(target, Prop_Send, "m_nSolidType", 0);
			PrintToChat(client, "\x04Collision disabled.");
		}
		else
		{
			SetEntProp(target, Prop_Send, "m_nSolidType", 6);
			PrintToChat(client, "\x04Collision enabled.");
		}
	}
	ShowMenu_Main(client);
}

ShowPropInfo(client)
{
	new Ent = -1;
	Ent = GetClientAimTarget(client, false);
		
	decl String:sClass[32];
	GetEntityClassname(Ent, sClass, sizeof(sClass));

	decl String:sModel[256];
	
	GetEntPropString(Ent, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	GetEntityClassname(Ent, sClass, sizeof(sClass));
		
	PrintToChat(client, "Displaying information For Entity: \x04%d\x01", Ent);
	PrintToChat(client, "Entity Owner:\x04 %N \x01", g_iOwner[Ent]);
	PrintToChat(client, "Entity ClassName:\x04 %s \x01", sClass);
	PrintToChat(client, "Entity Model:\x04 %s \x01", sModel);
}

public Action:Move_Prop(client, args)
{
	if(User_GetLocation(client) != LOCATION_CONSTRUCT)
	{
		ReplyToCommand(client, "You can't do this here.");
		ShowMenu_Main(client);
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "Usage: sm_move <x> <y> <z>");
		return Plugin_Handled;
	}

	new Ent = -1;
	Ent = GetClientAimTarget(client, false);
	
	if(CanModifyProp(client, Ent))
	{
		decl String:sClass[32];
		GetEntityClassname(Ent, sClass, sizeof(sClass));
			
		decl Float:g_origin[3], Float:g_origin2[3];
		decl String:sArg[32], String:sArg2[32], String:sArg3[32];
			
		GetCmdArg(1, sArg, sizeof(sArg));
		GetCmdArg(2, sArg2, sizeof(sArg2));
		GetCmdArg(3, sArg3, sizeof(sArg3));
			
		new x = StringToInt(sArg), y = StringToInt(sArg2), z = StringToInt(sArg3);

		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", g_origin);

		g_origin2[0] = (g_origin[0] += x);
		g_origin2[1] = (g_origin[1] += y);
		g_origin2[2] = (g_origin[2] += z);

		TeleportEntity(Ent, g_origin2, NULL_VECTOR, NULL_VECTOR);
			
		if (g_iOwner[Ent] == client) 
		{
			PrintToChat(client, "You have moved a prop.");
			return Plugin_Handled; 
		}
	}
	return Plugin_Handled;
}

public Action:Command_Stack(iClient, iArgs)
{
	if(User_GetLocation(iClient) != LOCATION_CONSTRUCT)
	{
		ReplyToCommand(iClient, "You can't do this here.");
		ShowMenu_Main(iClient);
		return Plugin_Handled;
	}
	
	if (iArgs < 2)
	{
		PrintToChat(iClient, "USAGE: \x04sm_autobuild <amount> <x> <y> <z> Z,Y,Z accept units");
		return Plugin_Handled;
	}

	new iEnt = GetClientAimTarget(iClient, false);

	if(CanModifyProp(iClient, iEnt))
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
			PrintToChat(iClient, "\x04You can't autobuild more than 5 props at one time!");
			return Plugin_Handled;
		} 
		else if (StringToInt(sArg) == 0)
		{
			PrintToChat(iClient, "\x04You can't autobuild 0 props!");
			return Plugin_Handled;
		}

		fOrigin[0] = StringToFloat(sArg2);
		fOrigin[1] = StringToFloat(sArg3);
		fOrigin[2] = StringToFloat(sArg4);

		new iCount = 0, Float:fDelay = 0.05;

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

			fDelay += 0.05;
		}
	}
	return Plugin_Handled;
}

DeleteAimProp(client)
{
	new target = GetClientAimTarget(client, false);
	if(CanModifyProp(client, target))
	{
		DeleteProp(target);
		EmitSoundToClient(client, SOUND_DELETE, _, _, _, _, _, 50);
	}
	ShowMenu_Main(client);
}

DeleteLastProp(client)
{
	if(CanModifyProp(client, g_iLastProp[client]))
	{
		DeleteProp(g_iLastProp[client]);
		EmitSoundToClient(client, SOUND_DELETE, _, _, _, _, _, 50);
		g_iLastProp[client] = 0;
	}
}

DeleteProp(prop)
{
	g_iPropCount[g_iOwner[prop]]--;
	g_iOwner[prop] = 0;
	g_bKillProp[prop] = false;
}

ClearAllProps(client)
{
	for(new i=1; i<sizeof(g_iOwner); i++)
	{
		if(g_iOwner[i] != client)
			continue;
		DeleteProp(i);
	}
	if(IsValidEntity(client))
		EmitSoundToClient(client, SOUND_DELETE, _, _, _, _, _, 50);
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	if (IsValidEntity(g_iSelectedProp[client]))
	{
		TeleportEntity(g_iSelectedProp[client], g_vecSelectedPropPrevPos[client], g_vecSelectedPropPrevAng[client], NULL_VECTOR);
		SDKUnhook(client, SDKHook_PreThink, PropManip);
	}
	
	if(g_bFlying[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_bFlying[client] = g_bPaused[client] = false;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	if(g_bFlying[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_bFlying[client] = g_bPaused[client] = false;
	}
	return Plugin_Continue;
}

public Action:Timer_Stack(Handle:Timer, Handle:hDataPack)
{
	ResetPack(hDataPack);

	new iClient = ReadPackCell(hDataPack);
	new iEnt = ReadPackCell(hDataPack);

	decl Float:fDegree[3];

	fDegree[0] = ReadPackFloat(hDataPack);
	fDegree[1] = ReadPackFloat(hDataPack);
	fDegree[2] = ReadPackFloat(hDataPack);
	
	decl iSolid;
	decl String:sClass[32], String:sModel[256], Float:fEntOrigin[3], Float:fEntAng[3], String:sTarget[64], String:sAuth[32];

	GetEdictClassname(iEnt, sClass, sizeof(sClass));
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntOrigin);
	GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fEntAng);
	GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	iSolid = GetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 4, 0);

	new iEntity = StrEqual(sClass, "prop_dynamic", false) ? CreateEntityByName("prop_dynamic_override") : CreateEntityByName(sClass);
	
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
	Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
	DispatchKeyValue(iEntity, "targetname", sTarget);

	DispatchKeyValue(iEntity, "model", sModel);
	DispatchKeyValue(iEntity, "rendermode", "5");
	DispatchKeyValue(iEntity, "solid", "6");

	if (!DispatchSpawn(iEntity)) LogError("didn't spawn");

	AddVectors(fEntOrigin, fDegree, fEntOrigin);

	new offset = GetEntSendPropOffs(iEnt, "m_clrRender"); // Thanks Panda!!!
		 
	if (offset > 0) 
	{
		new iColorR = GetEntData(iEnt, offset, 1);
		new iColorG = GetEntData(iEnt, offset + 1, 1);
		new iColorB = GetEntData(iEnt, offset + 2, 1);
		new iAlpha =  GetEntData(iEnt, offset + 3, 1);

		SetEntityRenderColor(iEntity, iColorR, iColorG, iColorB, iAlpha);
	}
	
	SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", iSolid, 4, 0);

	SetEntityMoveType(iEntity, MOVETYPE_NONE);
	
	TeleportEntity(iEntity, fEntOrigin, fEntAng, NULL_VECTOR);

	g_iPropCount[iClient]++;
	g_iOwner[iEntity] = iClient;
}

//////////////////////////////////////////////////////DETECTION STUFF
public StartTouch(const String:name[], caller, activator, Float:delay)
{
	decl String:entName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", entName, sizeof(entName));
	
	if(StrEqual(entName, "buildzone"))
//		PrintCenterText(activator, "Entered Construction Zone");
		g_iCurLocation[activator] = LOCATION_CONSTRUCT;
	else if(StrEqual(entName, "endbuildzone"))
	{
		if (IsValidEntity(g_iSelectedProp[activator]))
		{
			TeleportEntity(g_iSelectedProp[activator], g_vecSelectedPropPrevPos[activator], g_vecSelectedPropPrevAng[activator], NULL_VECTOR);
			SDKUnhook(activator, SDKHook_PreThink, PropManip);
		}
		
		if(g_bFlying[activator])
		{
			new Float:_fVelocity[3];
			TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, _fVelocity);
			SetEntityMoveType(activator, MOVETYPE_WALK);
			PrintToChat(activator, "\x05Toggle Fly: Off");
			g_bFlying[activator] = false;
		}
//		PrintCenterText(activator, "Exited Construction Zone");
//		ExitConstruction(activator);
		g_iCurLocation[activator] = LOCATION_ERROR;
	}
	else
		return;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("User_GetLocation", Native_GetLocation);
	CreateNative("User_SetLocation", Native_SetLocation);
	return APLRes_Success;
}
public Native_GetLocation(Handle:plugin, numParams) return LOCATION_CONSTRUCT;/*g_iCurLocation[GetNativeCell(1)]*/
public Native_SetLocation(Handle:plugin, numParams) g_iCurLocation[GetNativeCell(1)] = GetNativeCell(2);