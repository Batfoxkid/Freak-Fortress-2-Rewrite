/*
	void Native_PluginLoad()
*/

void Native_PluginLoad()
{
	CreateNative("FF2R_GetBossData", Native_GetBossData);
	CreateNative("FF2R_SetBossData", Native_SetBossData);
	CreateNative("FF2R_EmitBossSound", Native_EmitBossSound);
	CreateNative("FF2R_DoBossSlot", Native_DoBossSlot);
	
	RegPluginLibrary("ff2r");
}

public any Native_GetBossData(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not in-game", client);
	
	return Client(client).Cfg;
}

public any Native_SetBossData(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not in-game", client);
	
	if(Client(client).Cfg)
		DeleteCfg(Client(client).Cfg);
	
	Client(client).Cfg = GetNativeCell(2);
	return 0;
}

public any Native_EmitBossSound(Handle plugin, int params)
{
	int boss = GetNativeCell(4);
	if(boss < 0 || boss > MaxClients || !Client(boss).Cfg)
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not a boss", boss);
	
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
	if(client < 0 || client > MaxClients || !Client(client).Cfg)
		return ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not a boss", client);
	
	int low = GetNativeCell(2);
	int high = GetNativeCell(3);
	if(high < low)
		high = low;
	
	Bosses_UseSlot(client, low, high);
	return 0;
}