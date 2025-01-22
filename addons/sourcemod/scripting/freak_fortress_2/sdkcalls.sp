#pragma semicolon 1
#pragma newdecls required

static Handle SDKEquipWearable;
static Handle SDKGetMaxHealth;
static Address SDKGetCurrentCommand;
static Handle SDKStartLagCompensation;
static Handle SDKFinishLagCompensation;
static Handle SDKTeamAddPlayer;
static Handle SDKTeamRemovePlayer;
static Handle SDKIncrementStat;
static Handle SDKCheckBlockBackstab;
static Handle SDKGetMaxAmmo;
static Handle SDKSetSpeed;
static Handle SDKDropSingleInstance;

void SDKCall_Setup()
{
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	
	gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
	
	delete gamedata;
	
	
	gamedata = new GameData("ff2");
	
	SDKGetCurrentCommand = view_as<Address>(gamedata.GetOffset("GetCurrentCommand"));
	if(SDKGetCurrentCommand == view_as<Address>(-1))
		LogError("[Gamedata] Could not find GetCurrentCommand");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CLagCompensationManager::StartLagCompensation");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
	SDKStartLagCompensation = EndPrepSDKCall();
	if(!SDKStartLagCompensation)
		LogError("[Gamedata] Could not find CLagCompensationManager::StartLagCompensation");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CLagCompensationManager::FinishLagCompensation");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKFinishLagCompensation = EndPrepSDKCall();
	if(!SDKFinishLagCompensation)
		LogError("[Gamedata] Could not find CLagCompensationManager::FinishLagCompensation");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamAddPlayer = EndPrepSDKCall();
	if(!SDKTeamAddPlayer)
		LogError("[Gamedata] Could not find CTeam::AddPlayer");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamRemovePlayer = EndPrepSDKCall();
	if(!SDKTeamRemovePlayer)
		LogError("[Gamedata] Could not find CTeam::RemovePlayer");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFGameStats::IncrementStat");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKIncrementStat = EndPrepSDKCall();
	if(!SDKIncrementStat)
		LogError("[Gamedata] Could not find CTFGameStats::IncrementStat");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::CheckBlockBackstab");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	SDKCheckBlockBackstab = EndPrepSDKCall();
	if(!SDKCheckBlockBackstab)
		LogError("[Gamedata] Could not find CTFPlayer::CheckBlockBackstab");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxAmmo = EndPrepSDKCall();
	if(!SDKGetMaxAmmo)
		LogError("[Gamedata] Could not find CTFPlayer::GetMaxAmmo");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	SDKSetSpeed = EndPrepSDKCall();
	if(!SDKSetSpeed)
		LogError("[Gamedata] Could not find CTFPlayer::TeamFortress_SetSpeed");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPowerup::DropSingleInstance");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	SDKDropSingleInstance = EndPrepSDKCall();
	if(!SDKDropSingleInstance)
		LogError("[Gamedata] Could not find CTFPowerup::DropSingleInstance");
	
	delete gamedata;
}

bool SDKCall_CheckBlockBackstab(int client, int attacker)
{
	if(SDKCheckBlockBackstab)
		return SDKCall(SDKCheckBlockBackstab, client, attacker);
	
	return false;
}

void SDKCall_EquipWearable(int client, int entity)
{
	if(SDKEquipWearable)
	{
		SDKCall(SDKEquipWearable, client, entity);
	}
	else
	{
		RemoveEntity(entity);
	}
}

void SDKCall_FinishLagCompensation(int client)
{
	if(SDKStartLagCompensation && SDKFinishLagCompensation && SDKGetCurrentCommand != view_as<Address>(-1))
	{
		Address value = DHook_GetLagCompensationManager();
		if(value)
			SDKCall(SDKFinishLagCompensation, value, client);
	}
}

int SDKCall_GetMaxAmmo(int client, int type, int class = -1)
{
	return SDKGetMaxAmmo ? SDKCall(SDKGetMaxAmmo, client, type, class) : -1;
}

int SDKCall_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

void SDKCall_IncrementStat(int client, TFStatType_t stat, int amount)
{
	if(SDKIncrementStat)
	{
		Debug("%N %d %d", client, stat, amount);
		Address address = DHook_GetGameStats();
		if(address != Address_Null)
			SDKCall(SDKIncrementStat, address, client, stat, amount);
	}
}

void SDKCall_SetSpeed(int client)
{
	if(SDKSetSpeed)
	{
		SDKCall(SDKSetSpeed, client);
	}
	else
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}

void SDKCall_StartLagCompensation(int client)
{
	if(SDKStartLagCompensation && SDKFinishLagCompensation && SDKGetCurrentCommand != view_as<Address>(-1))
	{
		Address value = DHook_GetLagCompensationManager();
		if(value)
			SDKCall(SDKStartLagCompensation, value, client, GetEntityAddress(client) + SDKGetCurrentCommand);
	}
}

void SDKCall_ChangeClientTeam(int client, int newTeam)
{
	int clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	if(newTeam == clientTeam)
		return;
	
	if(SDKTeamAddPlayer && SDKTeamRemovePlayer)
	{
		int entity = MaxClients+1;
		while((entity = FindEntityByClassname(entity, "tf_team")) != -1)
		{
			int entityTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
			if(entityTeam == clientTeam)
			{
				SDKCall(SDKTeamRemovePlayer, entity, client);
			}
			else if(entityTeam == newTeam)
			{
				SDKCall(SDKTeamAddPlayer, entity, client);
			}
		}
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", newTeam);
	}
	else
	{
		if(newTeam < TFTeam_Red)
			newTeam += 2;
		
		int state = GetEntProp(client, Prop_Send, "m_lifeState");
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, newTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", state);
	}
	
	if(Cvar[DisguiseModels].BoolValue)
	{
		if(newTeam % 2)
		{
			Attrib_Remove(client, "vision opt in flags");
		}
		else
		{
			Attrib_Set(client, "vision opt in flags", 4.0);
		}
	}
}

void SDKCall_DropSingleInstance(int entity, const float velocity[3], int thrower, float throwerTouchDelay, float resetTime = 0.0)
{
	if(SDKDropSingleInstance)
		SDKCall(SDKDropSingleInstance, entity, velocity, thrower, throwerTouchDelay, resetTime);
}