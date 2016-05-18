#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new const String:genericFiles[][] =
{
	"sound/fn/welcome/cue.wav",
	"sound/fn/welcome/tune.mp3",
	"sound/fn/welcome/complete.wav",
	"sound/fn/welcome/01.mp3",
	"sound/fn/welcome/02.mp3",
	"sound/fn/welcome/03.mp3",
	"sound/fn/welcome/04.mp3",
	"sound/fn/welcome/05.mp3",
	"sound/fn/welcome/06.mp3",
	"sound/fn/welcome/07.mp3",
	"sound/fn/welcome/08.mp3",
	"sound/fn/welcome/09.mp3",
	"sound/fn/welcome/10.mp3",
	"sound/fn/welcome/admin_join.wav",
	"sound/fn/welcome/fuse.wav",
	"sound/fn/welcome/boss_win.mp3",
	"sound/fn/welcome/boss_loop.mp3",
	"sound/fn/welcome/boss_time.mp3",
	"sound/fn/welcome/dragonborn.wav",
	"sound/fn/welcome/pootis.wav",
	"sound/fn/welcome/meem.wav",
	"sound/fn/welcome/gottam.wav",
	"sound/fn/welcome/painis.wav",
	"sound/fn/welcome/cee.wav",
	"sound/fn/welcome/pancakes.wav",
	"sound/fn/welcome/tune.mp3",
	"sound/fn/welcome/win.wav",
	"sound/fn/welcome/fail.wav",
	"sound/fn/welcome/spy_seduce01.wav",
	"sound/fn/welcome/spy_seduce02.wav",
	"sound/fn/welcome/spy_seduce03.wav"
};

new const String:weaponFiles[][] =
{
//	TommyGun-----------------------------------------------------------
	"models/custom/weapons/c_models/c_pro_smg/doom_sniper_smg.dx90.vtx",
	"models/custom/weapons/c_models/c_pro_smg/doom_sniper_smg.dx80.vtx",
	"models/custom/weapons/c_models/c_pro_smg/doom_sniper_smg.mdl",
	"models/custom/weapons/c_models/c_pro_smg/doom_sniper_smg.sw.vtx",
	"models/custom/weapons/c_models/c_pro_smg/doom_sniper_smg.vvd",
	"materials/models/weapons/c_items/sniper_tommy.vmt",
	"materials/models/weapons/c_items/sniper_tommy.vtf",
//	Heavy Artillery----------------------------------------------------
	"models/custom/weapons/c_models/c_gatling_gun/artillery.dx90.vtx",
	"models/custom/weapons/c_models/c_gatling_gun/artillery.dx80.vtx",
	"models/custom/weapons/c_models/c_gatling_gun/artillery.mdl",
	"models/custom/weapons/c_models/c_gatling_gun/artillery.sw.vtx",
	"models/custom/weapons/c_models/c_gatling_gun/artillery.vvd",
	"models/custom/weapons/c_models/c_gatling_gun/artillery.phy",
	"materials/models/weapons/c_items/c_machinegun.vmt",
	"materials/models/weapons/c_items/c_machinegun.vtf",
//	The Van de Graaff Wrath----------------------------------------------
	"models/custom/weapons/c_models/c_tomislav/c_tomislav.dx90.vtx",
	"models/custom/weapons/c_models/c_tomislav/c_tomislav.dx80.vtx",
	"models/custom/weapons/c_models/c_tomislav/c_tomislav.mdl",
	"models/custom/weapons/c_models/c_tomislav/c_tomislav.sw.vtx",
	"models/custom/weapons/c_models/c_tomislav/c_tomislav.vvd",
	"models/custom/weapons/c_models/c_tomislav/c_tomislav.phy",
	"materials/models/weapons/c_items/c_miniraygun.vmt",
	"materials/models/weapons/c_items/c_miniraygun.vtf",
	"materials/models/weapons/c_items/c_miniraygun_blue.vmt",
	"materials/models/weapons/c_items/c_miniraygun_blue.vtf"
};

public OnMapStart()
{
	for(new i=0; i<sizeof(genericFiles); i++)
	{
		AddFileToDownloadsTable(genericFiles[i]);
		PrecacheSound(genericFiles[i]);
	}
	
//	for(new i=0; i<sizeof(weaponFiles); i++)
//		AddFileToDownloadsTable(weaponFiles[i]);
}
