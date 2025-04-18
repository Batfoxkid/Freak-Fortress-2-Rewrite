#pragma semicolon 1
#pragma newdecls required

void Native_PluginLoad()
{
	CreateNative("FF2R_GetBossData", Native_GetBossData);
	CreateNative("FF2R_SetBossData", Native_SetBossData);
	CreateNative("FF2R_EmitBossSound", Native_EmitBossSound);
	CreateNative("FF2R_DoBossSlot", Native_DoBossSlot);
	CreateNative("FF2R_GetSpecialData", Native_GetSpecialData);
	CreateNative("FF2R_CreateBoss", Native_CreateBoss);
	CreateNative("FF2R_GetClientMinion", Native_GetClientMinion);
	CreateNative("FF2R_SetClientMinion", Native_SetClientMinion);
	CreateNative("FF2R_GetClientScore", Native_GetClientScore);
	CreateNative("FF2R_GetPluginHandle", Native_GetPluginHandle);
	CreateNative("FF2R_GetGamemodeType", Native_GetGamemodeType);
	CreateNative("FF2R_StartLagCompensation", Native_StartLagCompensation);
	CreateNative("FF2R_FinishLagCompensation", Native_FinishLagCompensation);
	CreateNative("FF2R_UpdateBossAttributes", Native_UpdateBossAttributes);
	CreateNative("FF2R_GetClientHud", Native_GetClientHud);
	CreateNative("FF2R_SetClientHud", Native_SetClientHud);
	CreateNative("FF2R_ClientHasFile", Native_ClientHasFile);
	
	RegPluginLibrary("ff2r");
}

static any Native_GetBossData(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	return Client(client).Cfg;
}

static any Native_SetBossData(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	ConfigMap cfg;
	bool forwards = true;
	
	if(params > 2)
	{
		cfg = GetNativeCell(2);
		if(cfg)
			cfg = cfg.Clone(ThisPlugin);
		
		forwards = GetNativeCell(3);
	}
	else
	{
		forwards = GetNativeCell(2);
	}

	bool wasBoss = Client(client).IsBoss;
	
	if(wasBoss)
	{
		if(forwards || !cfg)
			Forward_OnBossRemoved(client);
		
		DeleteCfg(Client(client).Cfg);
	}
	
	Client(client).Cfg = cfg;
	
	// Setup/remove required hooks (rest is up to the plugin to handle with this native)
	if(wasBoss && !cfg)
	{
		Client(client).Index = -1;
		DHook_UnhookBoss(client);
	}
	else if(!wasBoss && cfg)
	{
		if(Client(client).Index < 0)
		{
			for(int i; ; i++)
			{
				if(FindClientOfBossIndex(i) == -1)
				{
					Client(client).Index = i;
					break;
				}
			}
		}

		DHook_HookBoss(client);
	}

	if(forwards && Client(client).Cfg)
		Forward_OnBossCreated(client, cfg, GetRoundStatus() == 1);

	return 0;
}

static any Native_EmitBossSound(Handle plugin, int params)
{
	int boss = GetNativeCell(4);
	if(boss < 1 || boss > MaxClients || !Client(boss).Cfg)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not a boss", boss);
	
	int amount = GetNativeCell(2);
	int[] clients = new int[amount];
	GetNativeArray(1, clients, amount);
	
	int size;
	GetNativeStringLength(3, size);
	char[] sample = new char[++size];
	GetNativeString(3, sample, size);
	
	GetNativeStringLength(5, size);
	char[] required = new char[++size];
	GetNativeString(5, required, size);
	
	float origin[3], dir[3];
	GetNativeArray(13, origin, sizeof(origin));
	GetNativeArray(14, dir, sizeof(dir));
	
	return Bosses_PlaySound(boss, clients, amount, sample, required, GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), GetNativeCell(9), GetNativeCell(10), GetNativeCell(11), GetNativeCell(12), origin, dir, GetNativeCell(15), GetNativeCell(16));
}

static any Native_DoBossSlot(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !Client(client).Cfg)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not a boss", client);
	
	int low = GetNativeCell(2);
	int high = GetNativeCell(3);
	if(high < low)
		high = low;
	
	Bosses_UseSlot(client, low, high);
	return 0;
}

static any Native_GetSpecialData(Handle plugin, int params)
{
	return Bosses_GetConfig(GetNativeCell(1));
}

static any Native_CreateBoss(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	if(params > 2)
	{
		ConfigMap cfg = GetNativeCell(2);
		if(cfg)
		{
			Bosses_CreateFromConfig(client, cfg, GetNativeCell(3));
			return 0;
		}
	}
	
	Bosses_Remove(client);
	return 0;
}

static any Native_GetClientMinion(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	return Client(client).MinionType;
}

static any Native_SetClientMinion(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	Client(client).MinionType = GetNativeCell(2);
	return 0;
}

static any Native_GetClientScore(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	SetNativeCellRef(2, Client(client).TotalDamage);
	SetNativeCellRef(3, Client(client).Healing);
	SetNativeCellRef(4, Client(client).Assist);
	return Client(client).TotalDamage + Client(client).TotalAssist;
}

static any Native_GetPluginHandle(Handle plugin, int params)
{
	return ThisPlugin;
}

static any Native_GetGamemodeType(Handle plugin, int params)
{
	return Enabled ? 2 : (Charset != -1 ? 1 : 0);
}

static any Native_StartLagCompensation(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	SDKCall_StartLagCompensation(client);
	return 0;
}

static any Native_FinishLagCompensation(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	SDKCall_FinishLagCompensation(client);
	return 0;
}

static any Native_UpdateBossAttributes(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !Client(client).Cfg)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not a boss", client);
	
	Bosses_UpdateHealth(client);
	Bosses_SetSpeed(client);
	Gamemode_UpdateHUD(GetClientTeam(client));
	return 0;
}

static any Native_GetClientHud(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	return !Client(client).NoHud;
}

static any Native_SetClientHud(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	Client(client).NoHud = !GetNativeCell(2);
	return 0;
}

static any Native_ClientHasFile(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client != 0 && (client < 1 || client > MaxClients || !IsClientInGame(client)))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	int length;
	GetNativeStringLength(2, length);
	char[] file = new char[++length];
	GetNativeString(2, file, length);

	int table = FindStringTable("downloadables");
	if(table != INVALID_STRING_TABLE)
	{
		if(FindStringIndex(table, file) != INVALID_STRING_INDEX)
			return true;
	}

	return FileNet_HasFile(client, FileNet_FileProgress(file));
}
