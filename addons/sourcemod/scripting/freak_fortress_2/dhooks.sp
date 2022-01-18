/*
	void DHook_Setup()
	void DHook_MapStart()
	void DHook_PluginEnd()
	void DHook_HookClient(int client)
	void DHook_UnhookClient(int client)
*/

static DynamicHook GetCaptureValue;
static DynamicHook RoundRespawn;
static DynamicHook ForceRespawn;

static int ForceRespawnPreHook[MAXTF2PLAYERS];
static int ForceRespawnPostHook[MAXTF2PLAYERS];

static int PrefClass;

void DHook_Setup()
{
	GameData gamedata = new GameData("ff2");
	
	CreateDetour(gamedata, "CTFPlayer::CanPickupDroppedWeapon", DHook_CanPickupDroppedWeaponPre);
	CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DHook_DropAmmoPackPre);
	CreateDetour(gamedata, "CTFPlayer::RegenThink", DHook_RegenThinkPre, DHook_RegenThinkPost);
	
	RoundRespawn = CreateHook(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
	GetCaptureValue = CreateHook(gamedata, "CTFGameRules::GetCaptureValueForPlayer");
	ForceRespawn = CreateHook(gamedata, "CBasePlayer::ForceRespawn");
	
	delete gamedata;
}

static DynamicHook CreateHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if(!hook)
		LogError("[Gamedata] Could not find %s", name);
	
	return hook;
}

static void CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback != INVALID_FUNCTION && !DHookEnableDetour(detour, false, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback != INVALID_FUNCTION && !DHookEnableDetour(detour, true, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);
		
		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

void DHook_MapStart()
{
	if(GetCaptureValue)
		GetCaptureValue.HookGamerules(Hook_Post, DHook_GetCaptureValue);
	
	if(!RoundRespawn || RoundRespawn.HookGamerules(Hook_Pre, DHook_RoundRespawn) == INVALID_HOOK_ID)
		HookEvent("teamplay_round_start", DHook_RoundSetup, EventHookMode_PostNoCopy);
}

void DHook_HookClient(int client)
{
	if(ForceRespawn)
	{
		ForceRespawnPreHook[client] = ForceRespawn.HookEntity(Hook_Pre, client, DHook_ForceRespawnPre);
		ForceRespawnPostHook[client] = ForceRespawn.HookEntity(Hook_Post, client, DHook_ForceRespawnPost);
	}
}

void DHook_PluginEnd()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
			DHook_UnhookClient(client);
	}
}

void DHook_UnhookClient(int client)
{
	DynamicHook.RemoveHook(ForceRespawnPreHook[client]);
	DynamicHook.RemoveHook(ForceRespawnPostHook[client]);
}

public void DHook_RoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	DHook_RoundRespawn();	// Back up plan
}

public MRESReturn DHook_RoundRespawn()
{
	Gamemode_RoundSetup();
	return MRES_Ignored;
}

public MRESReturn DHook_CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
	if(Client(client).IsBoss || Client(client).Minion)
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn DHook_DropAmmoPackPre(int client, DHookParam param)
{
	return (Client(client).Minion || Client(client).IsBoss) ? MRES_Supercede : MRES_Ignored;
}

public MRESReturn DHook_ForceRespawnPre(int client)
{
	PrefClass = 0;
	if(Client(client).IsBoss)
	{
		int class;
		Client(client).Cfg.GetInt("class", class);
		if(class)
		{
			PrefClass = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
		}
	}
	return MRES_Ignored;
}

public MRESReturn DHook_ForceRespawnPost(int client)
{
	if(PrefClass)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", PrefClass);
	
	return MRES_Ignored;
}

public MRESReturn DHook_GetCaptureValue(DHookReturn ret, DHookParam param)
{
	int client = param.Get(1);
	if(!Client(client).IsBoss || Attributes_FindOnPlayer(client, 68))
		return MRES_Ignored;
	
	ret.Value += TF2_GetPlayerClass(client) == TFClass_Scout ? 1 : 2;
	return MRES_Override;
}

public MRESReturn DHook_RegenThinkPre(int client, DHookParam param)
{
	if(Client(client).IsBoss && TF2_GetPlayerClass(client) == TFClass_Medic)
		TF2_SetPlayerClass(client, TFClass_Unknown);
	
	return MRES_Ignored;
}

public MRESReturn DHook_RegenThinkPost(int client, DHookParam param)
{
	if(Client(client).IsBoss && TF2_GetPlayerClass(client) == TFClass_Unknown)
		TF2_SetPlayerClass(client, TFClass_Medic);
	
	return MRES_Ignored;
}