#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

new Float:Vec1[3];
new Float:Yaw1;
new Float:YawRate1;
new Float:Something1;
new Float:Speed1;
new Float:Time1;

public OnPluginStart() 
{
	HookUserMessage(GetUserMessageId("SpawnFlyingBird"), HookFade, true);
	
	RegConsoleCmd("sm_burd", Command_Burd);
	RegConsoleCmd("sm_burd2", Command_Burd2);
}

public Action:HookFade(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
	BfReadVecCoord(bf, Vec1);
	Yaw1 = BfReadFloat(bf);
	YawRate1 = BfReadFloat(bf);
	Something1 = BfReadFloat(bf);
	Speed1 = BfReadFloat(bf);
	Time1 = BfReadFloat(bf);
	
	PrintToServer("Vec: {%f, %f, %f} Yaw: %f YawRate: %f Something: %f Speed: %f Time %f", Vec1[0], Vec1[1], Vec1[2], Yaw1, YawRate1, Something1, Speed1, Time1);
}

public Action:Command_Burd(client, args)
{
	SpawnFlyingBird(Vec1, Yaw1, YawRate1, Something1, Speed1, Time1);
	
	return Plugin_Handled;
}

public Action:Command_Burd2(client, args)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 5.0;
	SpawnFlyingBirdRandom(vec);
	
	return Plugin_Handled;
}

stock SpawnFlyingBird(Float:vec[3], Float:Yaw, Float:YawRate, Float:Something, Float:Speed, Float:Time)
{
	new Handle:message = StartMessageAll("SpawnFlyingBird");
	BfWriteVecCoord(message, Vec1);
	BfWriteFloat(message, Yaw1);		//yaw
	BfWriteFloat(message, YawRate1);	//yaw rate
	BfWriteFloat(message, Something1);
	BfWriteFloat(message, Speed1);		//speed
	BfWriteFloat(message, Time1);		//time til starts flapping
	EndMessage();
}

stock SpawnFlyingBirdRandom(Float:vec[3])
{
	new Handle:message = StartMessageAll("SpawnFlyingBird");
	BfWriteVecCoord(message, vec);
	BfWriteFloat(message, GetRandomFloat(-3.0, 3.0));			//yaw
	BfWriteFloat(message, GetRandomFloat(-1.0, 1.0));			//yaw rate
	BfWriteFloat(message, GetRandomFloat(0.5, 2.0));			//Curve up rate
	BfWriteFloat(message, GetRandomFloat(300.0, 500.0));		//speed
	BfWriteFloat(message, GetRandomFloat(0.0, 1.0));			//time til starts flapping
	EndMessage();
}
