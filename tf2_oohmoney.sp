#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[TF2] ConceptMvMLootUltraRare!",
	author = "FlamingSarge, Pelipoika",
	description = "Replaces the Mercs Battle Cry with the \"ConceptMvMLootUltraRare!\" sound",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	AddCommandListener(Cmd_BattleCry, "voicemenu");
}

public Action:Cmd_BattleCry(client, const String:command[], argc)
{
	if (client < 1 || client > MaxClients)
	{
		return Plugin_Continue;
	}
	
	new String:args[5];
	GetCmdArgString(args, sizeof(args));
	if (!StrEqual(args, "1 7"))
	{
		return Plugin_Continue;
	}
	
	switch(GetRandomInt(1, 3))
	{
		case 1:
		{
			SetVariantString("randomnum:100");
			AcceptEntityInput(client, "AddContext");

			SetVariantString("TLK_MVM_LOOT_COMMON");
			AcceptEntityInput(client, "SpeakResponseConcept");
			
			AcceptEntityInput(client, "ClearContext");
		}
		case 2:
		{
			SetVariantString("randomnum:100");
			AcceptEntityInput(client, "AddContext");

			SetVariantString("TLK_MVM_LOOT_RARE");
			AcceptEntityInput(client, "SpeakResponseConcept");
			
			AcceptEntityInput(client, "ClearContext");
		}
		case 3:
		{
			SetVariantString("randomnum:100");
			AcceptEntityInput(client, "AddContext");

			SetVariantString("TLK_MVM_LOOT_ULTRARARE");
			AcceptEntityInput(client, "SpeakResponseConcept");
			
			AcceptEntityInput(client, "ClearContext");
		}
	}
	return Plugin_Handled;
}

public TF2_OnConditionAdded(client, TFCond:cond)
{
	if (cond != TFCond_Ubercharged) return;
	
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		SetVariantString("randomnum:100");
		AcceptEntityInput(client, "AddContext");

		SetVariantString("TLK_MEDIC_HEAL_SHIELD");
		AcceptEntityInput(client, "SpeakResponseConcept");
		
		AcceptEntityInput(client, "ClearContext");
	}
}

//TLK_MVM_LOOT_COMMON
//TLK_MVM_LOOT_RARE
//TLK_MVM_LOOT_ULTRARARE