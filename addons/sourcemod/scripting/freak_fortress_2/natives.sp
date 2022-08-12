/*
	void Native_PluginLoad()
*/

#pragma semicolon 1

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
	
	RegPluginLibrary("ff2r");
}

public any Native_GetBossData(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	return Client(client).Cfg;
}

public any Native_SetBossData(Handle plugin, int params)
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
	
	if(Client(client).Cfg)
	{
		if(forwards)
			Forward_OnBossRemoved(client);
		
		DeleteCfg(Client(client).Cfg);
	}
	
	Client(client).Cfg = cfg;
	if(forwards)
		Forward_OnBossCreated(client, cfg, GetRoundStatus() == 1);
	
	return 0;
}

public any Native_EmitBossSound(Handle plugin, int params)
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

public any Native_DoBossSlot(Handle plugin, int params)
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

public any Native_GetSpecialData(Handle plugin, int params)
{
	return Bosses_GetConfig(GetNativeCell(1));
}

public any Native_CreateBoss(Handle plugin, int params)
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

public any Native_GetClientMinion(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	return Client(client).Minion;
}

public any Native_SetClientMinion(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in-game", client);
	
	Client(client).Minion = GetNativeCell(2);
	return 0;
}

public any Native_GetClientScore(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	SetNativeCellRef(2, Client(client).TotalDamage);
	SetNativeCellRef(3, Client(client).Healing);
	SetNativeCellRef(4, Client(client).Assist);
	return Client(client).TotalDamage + Client(client).Healing + Client(client).TotalAssist;
}