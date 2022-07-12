/*
	void NativeOld_PluginLoad()
*/

#pragma semicolon 1

#define FF2FLAG_UBERREADY			(1<<1)		//Used when medic says "I'm charged!"
#define FF2FLAG_ISBUFFED			(1<<2)		//Used when soldier uses the Battalion's Backup
#define FF2FLAG_CLASSTIMERDISABLED 		(1<<3)		//Used to prevent clients' timer
#define FF2FLAG_HUDDISABLED			(1<<4)		//Used to prevent custom hud from clients' timer
#define FF2FLAG_BOTRAGE				(1<<5)		//Used by bots to use Boss's rage
#define FF2FLAG_TALKING				(1<<6)		//Used by Bosses with "sound_block_vo" to disable block for some lines
#define FF2FLAG_ALLOWSPAWNINBOSSTEAM		(1<<7)		//Used to allow spawn players in Boss's team
#define FF2FLAG_USEBOSSTIMER			(1<<8)		//Used to prevent Boss's timer
#define FF2FLAG_USINGABILITY			(1<<9)		//Used to prevent Boss's hints about abilities buttons
#define FF2FLAG_CLASSHELPED			(1<<10)
#define FF2FLAG_HASONGIVED			(1<<11)
#define FF2FLAG_CHANGECVAR			(1<<12)		//Used to prevent SMAC from kicking bosses who are using certain rages (NYI)
#define FF2FLAG_ALLOW_HEALTH_PICKUPS		(1<<13)		//Used to prevent bosses from picking up health
#define FF2FLAG_ALLOW_AMMO_PICKUPS		(1<<14)		//Used to prevent bosses from picking up ammo
#define FF2FLAG_ROCKET_JUMPING			(1<<15)		//Used when a soldier is rocket jumping
#define FF2FLAG_ALLOW_BOSS_WEARABLES		(1<<16)		//Used to allow boss having wearables (only for Official FF2)
#define FF2FLAGS_SPAWN				~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_TALKING & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & ~FF2FLAG_CHANGECVAR & ~FF2FLAG_ROCKET_JUMPING & FF2FLAG_USEBOSSTIMER & FF2FLAG_USINGABILITY

void NativeOld_PluginLoad()
{
	CreateNative("FF2_IsFF2Enabled", NativeOld_IsEnabled);
	CreateNative("FF2_GetFF2Version", NativeOld_FF2Version);
	CreateNative("FF2_IsBossVsBoss", NativeOld_IsVersus);
	CreateNative("FF2_GetForkVersion", NativeOld_ForkVersion);
	CreateNative("FF2_GetBossUserId", NativeOld_GetBoss);
	CreateNative("FF2_GetBossIndex", NativeOld_GetIndex);
	CreateNative("FF2_GetBossTeam", NativeOld_GetTeam);
	CreateNative("FF2_GetBossSpecial", NativeOld_GetSpecial);
	CreateNative("FF2_GetBossName", NativeOld_GetName);
	CreateNative("FF2_GetBossHealth", NativeOld_GetBossHealth);
	CreateNative("FF2_SetBossHealth", NativeOld_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", NativeOld_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", NativeOld_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", NativeOld_GetBossLives);
	CreateNative("FF2_SetBossLives", NativeOld_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", NativeOld_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", NativeOld_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", NativeOld_GetBossCharge);
	CreateNative("FF2_SetBossCharge", NativeOld_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", NativeOld_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", NativeOld_SetBossRageDamage);
	CreateNative("FF2_GetClientDamage", NativeOld_GetDamage);
	CreateNative("FF2_GetRoundState", NativeOld_GetRoundState);
	CreateNative("FF2_GetSpecialKV", NativeOld_GetSpecialKV);
	CreateNative("FF2_StartMusic", NativeOld_StartMusic);
	CreateNative("FF2_StopMusic", NativeOld_StopMusic);
	CreateNative("FF2_GetRageDist", NativeOld_GetRageDist);
	CreateNative("FF2_HasAbility", NativeOld_HasAbility);
	CreateNative("FF2_DoAbility", NativeOld_DoAbility);
	CreateNative("FF2_GetAbilityArgument", NativeOld_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", NativeOld_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", NativeOld_GetAbilityArgumentString);
	CreateNative("FF2_GetArgNamedI", NativeOld_GetArgNamedI);
	CreateNative("FF2_GetArgNamedF", NativeOld_GetArgNamedF);
	CreateNative("FF2_GetArgNamedS", NativeOld_GetArgNamedS);
	CreateNative("FF2_RandomSound", NativeOld_RandomSound);
	CreateNative("FF2_EmitVoiceToAll", NativeOld_EmitVoiceToAll);
	CreateNative("FF2_GetFF2flags", NativeOld_GetFF2flags);
	CreateNative("FF2_SetFF2flags", NativeOld_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", NativeOld_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", NativeOld_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", NativeOld_GetClientGlow);
	CreateNative("FF2_SetClientGlow", NativeOld_SetClientGlow);
	CreateNative("FF2_GetClientShield", NativeOld_GetClientShield);
	CreateNative("FF2_SetClientShield", NativeOld_SetClientShield);
	CreateNative("FF2_RemoveClientShield", NativeOld_RemoveClientShield);
	CreateNative("FF2_LogError", NativeOld_LogError);
	CreateNative("FF2_ReportError", NativeOld_LogError);
	CreateNative("FF2_Debug", NativeOld_Debug);
	CreateNative("FF2_SetCheats", NativeOld_SetCheats);
	CreateNative("FF2_GetCheats", NativeOld_GetCheats);
	CreateNative("FF2_MakeBoss", NativeOld_MakeBoss);
	CreateNative("FF2_SelectBoss", NativeOld_ChooseBoss);
	
	CreateNative("FF2Data.Unknown", NativeOld_GetIndex);
	CreateNative("FF2Data.FF2Data", NativeOld_FF2Data);
	CreateNative("FF2Data.boss.get", NativeOld_FF2DataBoss);
	CreateNative("FF2Data.client.get", NativeOld_FF2DataClient);
	CreateNative("FF2Data.Config.get", NativeOld_GetSpecialKV);
	CreateNative("FF2Data.Health.get", NativeOld_GetBossHealth);
	CreateNative("FF2Data.Health.set", NativeOld_SetBossHealth);
	CreateNative("FF2Data.MaxHealth.get", NativeOld_GetBossMaxHealth);
	CreateNative("FF2Data.MaxHealth.set", NativeOld_SetBossMaxHealth);
	CreateNative("FF2Data.Lives.get", NativeOld_GetBossLives);
	CreateNative("FF2Data.Lives.set", NativeOld_SetBossLives);
	CreateNative("FF2Data.MaxLives.get", NativeOld_GetBossMaxLives);
	CreateNative("FF2Data.MaxLives.set", NativeOld_SetBossMaxLives);
	CreateNative("FF2Data.RageDmg.get", NativeOld_GetBossRageDamage);
	CreateNative("FF2Data.RageDmg.set", NativeOld_SetBossRageDamage);
	CreateNative("FF2Data.Change", NativeOld_FF2Data);
	CreateNative("FF2Data.GetArgI", NativeOld_FF2DataArgI);
	CreateNative("FF2Data.GetArgF", NativeOld_FF2DataArgF);
	CreateNative("FF2Data.GetArgB", NativeOld_FF2DataArgB);
	CreateNative("FF2Data.GetArgS", NativeOld_FF2DataArgS);
	CreateNative("FF2Data.HasAbility", NativeOld_FF2DataHasAbility);
	CreateNative("FF2Data.BossTeam", NativeOld_GetTeam);
	
	CreateNative("VSH_IsSaxtonHaleModeMap", NativeOld_VSHIsVSHMap);
	CreateNative("VSH_IsSaxtonHaleModeEnabled", NativeOld_IsEnabled);
	CreateNative("VSH_GetSaxtonHaleUserId", NativeOld_VSHGetHale);
	CreateNative("VSH_GetSaxtonHaleTeam", NativeOld_GetTeam);
	CreateNative("VSH_GetSpecialRoundIndex", NativeOld_VSHGetSpecial);
	CreateNative("VSH_GetSaxtonHaleHealth", NativeOld_VSHGetHealth);
	CreateNative("VSH_GetSaxtonHaleHealthMax", NativeOld_VSHGetHealthMax);
	CreateNative("VSH_GetClientDamage", NativeOld_GetDamage);
	CreateNative("VSH_GetRoundState", NativeOld_VSHGetRoundState);
	
	RegPluginLibrary("freak_fortress_2");
	RegPluginLibrary("saxtonhale");
}

public any NativeOld_IsEnabled(Handle plugin, int params)
{
	return (Enabled && !GameRules_GetProp("m_bInWaitingForPlayers", 1));
}

public any NativeOld_FF2Version(Handle plugin, int params)
{
	static const int version[] = { 1, 11, 0 };
	SetNativeArray(1, version, sizeof(version));
	return true;
}

public any NativeOld_IsVersus(Handle plugin, int params)
{
	return true;
}

public any NativeOld_ForkVersion(Handle plugin, int params)
{
	static const int version[] = { 2, 0, 0 };
	SetNativeArray(1, version, sizeof(version));
	return true;
}

public any NativeOld_GetBoss(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	return client == -1 ? client : GetClientUserId(client);
}

public any NativeOld_GetIndex(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client > 0 && client < MAXTF2PLAYERS && Client(client).IsBoss)
		return Client(GetNativeCell(1)).Index;
	
	return -1;
}

public any NativeOld_GetTeam(Handle plugin, int params)
{
	return Bosses_GetBossTeam();
}

public any NativeOld_GetSpecial(Handle plugin, int params)
{
	int index = GetNativeCell(1);
	if(index < 0)
		return false;
	
	int size = GetNativeCell(3);
	char[] buffer = new char[size];
	if(GetNativeCell(4))
	{
		ConfigMap cfg = Bosses_GetConfig(index);
		if(!cfg)
			return false;
		
		Bosses_GetBossNameCfg(cfg, buffer, size);
	}
	else
	{
		index = FindClientOfBossIndex(index);
		if(index == -1 || !Client(index).IsBoss)
			return false;
		
		Bosses_GetBossNameCfg(Client(index).Cfg, buffer, size);
	}
	
	SetNativeString(2, buffer, size);
	return true;
}

public any NativeOld_GetName(Handle plugin, int params)
{
	int index = GetNativeCell(1);
	if(index < 0)
		return false;
	
	int lang = GetNativeCell(5);
	if(lang < 0 || lang > MaxClients || !IsClientInGame(lang))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", lang);
	
	lang = lang ? GetClientLanguage(lang) : GetServerLanguage();
	
	int size = GetNativeCell(3);
	char[] buffer = new char[size];
	if(GetNativeCell(4))
	{
		ConfigMap cfg = Bosses_GetConfig(index);
		if(!cfg)
			return false;
		
		Bosses_GetBossNameCfg(cfg, buffer, size, lang);
	}
	else
	{
		index = FindClientOfBossIndex(index);
		if(index == -1 || !Client(index).IsBoss)
			return false;
		
		Bosses_GetBossNameCfg(Client(index).Cfg, buffer, size, lang);
	}
	
	SetNativeString(2, buffer, size);
	return true;
}

public any NativeOld_GetBossHealth(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		return Client(client).Health;
	
	return 0;
}

public any NativeOld_SetBossHealth(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		int lastHealth = Client(client).Health;
		int newHealth = GetNativeCell(2);
		Client(client).Health = newHealth;
		
		Bosses_SetSpeed(client);
		Gamemode_UpdateHUD(GetClientTeam(client), newHealth > lastHealth);
	}
	
	return 0;
}

public any NativeOld_GetBossMaxHealth(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		return Client(client).MaxHealth;
	
	return 0;
}

public any NativeOld_SetBossMaxHealth(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		int lastHealth = Client(client).MaxHealth;
		int newHealth = GetNativeCell(2);
		Client(client).MaxHealth = newHealth;
		
		Bosses_UpdateHealth(client);
		Bosses_SetSpeed(client);
		Gamemode_UpdateHUD(GetClientTeam(client), (newHealth > lastHealth && Client(client).Lives > 1));
	}
	
	return 0;
}

public any NativeOld_GetBossLives(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		return Client(client).Lives;
	
	return 0;
}

public any NativeOld_SetBossLives(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		int lastLives = Client(client).Lives;
		int newLives = GetNativeCell(2);
		SetEntityHealth(client, GetClientHealth(client) - ((newLives - lastLives) * Client(client).MaxHealth));
		Client(client).Lives = newLives;
		
		Bosses_SetSpeed(client);
		Gamemode_UpdateHUD(GetClientTeam(client), newLives > lastLives);
	}
	
	return 0;
}

public any NativeOld_GetBossMaxLives(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		return Client(client).MaxLives;
	
	return 0;
}

public any NativeOld_SetBossMaxLives(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		Client(client).MaxLives = GetNativeCell(2);
		
		Bosses_SetSpeed(client);
		Gamemode_UpdateHUD(GetClientTeam(client));
	}
	
	return 0;
}

public any NativeOld_GetBossCharge(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		return Client(client).GetCharge(GetNativeCell(2));
	
	return 0.0;
}

public any NativeOld_SetBossCharge(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		Client(client).SetCharge(GetNativeCell(2), GetNativeCell(3));
	
	return 0;
}

public any NativeOld_GetBossRageDamage(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		return RoundFloat(Client(client).RageDamage);
	
	return 0;
}

public any NativeOld_SetBossRageDamage(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
		Client(client).RageDamage = float(GetNativeCell(2));
	
	return 0;
}

public any NativeOld_GetRoundState(Handle plugin, int params)
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame, RoundState_StartGame, RoundState_Preround:
			return 0;
		
		case RoundState_RoundRunning, RoundState_Stalemate:
			return 1;
	}
	
	return 2;
}

public any NativeOld_GetRageDist(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client == -1 || !Client(client).IsBoss)
		return 0.0;
	
	float dist = 400.0;
	
	char ability[64];
	GetNativeString(3, ability, sizeof(ability));
	if(!ability[0] || !Bosses_GetArgFloat(client, ability, "dist", dist))
		Client(client).Cfg.GetFloat("ragedist", dist);
	
	return dist;
}

public any NativeOld_HasAbility(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char buffer1[64];
		GetNativeString(3, buffer1, sizeof(buffer1));
		ConfigMap cfg = Client(client).Cfg.GetSection(buffer1);
		if(cfg)
		{
			GetNativeString(2, buffer1, sizeof(buffer1));
			if(buffer1[0])
			{
				int pos = FindCharInString(buffer1, '.', true);
				if(pos != -1)
					buffer1[pos] = '\0';
				
				char buffer2[64];
				cfg.Get("plugin_name", buffer2, sizeof(buffer2));
				if(buffer2[0] && !StrEqual(buffer1, buffer2))
					return false;
			}
			
			return true;
		}
	}
	
	return false;
}

public any NativeOld_DoAbility(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char plugi[64], ability[64];
		GetNativeString(2, plugi, sizeof(plugi));
		GetNativeString(3, ability, sizeof(ability));
		Bosses_UseAbility(client, plugi, ability, GetNativeCell(4), GetNativeCell(5));
	}
	
	return 0;
}

public any NativeOld_GetAbilityArgument(Handle plugin, int params)
{
	int value = GetNativeCell(5);
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char ability[64];
		GetNativeString(3, ability, sizeof(ability));
		
		char arg[16];
		FormatEx(arg, sizeof(arg), "arg%d", GetNativeCell(4));
		
		Bosses_GetArgInt(client, ability, arg, value);
	}
	
	return value;
}

public any NativeOld_GetAbilityArgumentFloat(Handle plugin, int params)
{
	float value = GetNativeCell(5);
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char ability[64];
		GetNativeString(3, ability, sizeof(ability));
		
		char arg[16];
		FormatEx(arg, sizeof(arg), "arg%d", GetNativeCell(4));
		
		Bosses_GetArgFloat(client, ability, arg, value);
	}
	
	return value;
}

public any NativeOld_GetAbilityArgumentString(Handle plugin, int params)
{
	int size = GetNativeCell(6);
	char[] buffer = new char[size];
	
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char ability[64];
		GetNativeString(3, ability, sizeof(ability));
		
		char arg[16];
		FormatEx(arg, sizeof(arg), "arg%d", GetNativeCell(4));
		
		Bosses_GetArgString(client, ability, arg, buffer, size);
	}
	
	return SetNativeString(5, buffer, size);
}

public any NativeOld_GetArgNamedI(Handle plugin, int params)
{
	int value = GetNativeCell(5);
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char ability[64], arg[64];
		GetNativeString(3, ability, sizeof(ability));
		GetNativeString(4, arg, sizeof(arg));
		Bosses_GetArgInt(client, ability, arg, value);
	}
	
	return value;
}

public any NativeOld_GetArgNamedF(Handle plugin, int params)
{
	float value = GetNativeCell(5);
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char ability[64], arg[64];
		GetNativeString(3, ability, sizeof(ability));
		GetNativeString(4, arg, sizeof(arg));
		Bosses_GetArgFloat(client, ability, arg, value);
	}
	
	return value;
}

public any NativeOld_GetArgNamedS(Handle plugin, int params)
{
	int size = GetNativeCell(6);
	char[] buffer = new char[size];
	
	int client = FindClientOfBossIndex(GetNativeCell(1));
	if(client != -1)
	{
		char ability[64], arg[64];
		GetNativeString(3, ability, sizeof(ability));
		GetNativeString(4, arg, sizeof(arg));
		Bosses_GetArgString(client, ability, arg, buffer, size);
	}
	
	return SetNativeString(5, buffer, size);
}

public any NativeOld_GetDamage(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || Client(client).IsBoss || !IsClientInGame(client))
		return 0;
	
	return Client(client).TotalDamage;
}

public any NativeOld_GetFF2flags(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	int flags = FF2FLAG_USEBOSSTIMER|FF2FLAG_CLASSHELPED|FF2FLAG_HASONGIVED;
	
	if(Client(client).Minion)
		flags += FF2FLAG_CLASSTIMERDISABLED;
	
	if(Client(client).NoHud)
		flags += FF2FLAG_HUDDISABLED;
	
	if(Client(client).IsBoss)
	{
		if(Client(client).Speaking)
			flags += FF2FLAG_TALKING;
		
		int pickups = Client(client).Pickups;
		if(pickups == 1 || pickups > 2)
			flags += FF2FLAG_ALLOW_HEALTH_PICKUPS;
	
		if(pickups > 1)
			flags += FF2FLAG_ALLOW_AMMO_PICKUPS;
		
		bool cosmetics;
		if(Client(client).Cfg.GetBool("cosmetics", cosmetics, false) && cosmetics)
			flags += FF2FLAG_ALLOW_BOSS_WEARABLES;	// Not in Unofficial but in Official
	}
	else
	{
		flags += FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
		
		if(client && client <= MaxClients && IsClientInGame(client))
		{
			int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			if(IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_flChargeLevel") && GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") >= 100.0)
				flags += FF2FLAG_UBERREADY;
			
			// Does not account for buffs applied by others
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed) && GetEntProp(client, Prop_Send, "m_bRageDraining"))
				flags += FF2FLAG_ISBUFFED;
			
			if(TF2_IsPlayerInCondition(client, TFCond_BlastJumping))
				flags += FF2FLAG_ROCKET_JUMPING;
		}
	}
	
	return flags;
}

public any NativeOld_SetFF2flags(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	else
	{
		int flags = GetNativeCell(2);
		
		Client(client).Minion = view_as<bool>(flags & FF2FLAG_CLASSTIMERDISABLED);
		Client(client).NoHud = view_as<bool>(flags & FF2FLAG_HUDDISABLED);
		
		if(Client(client).IsBoss)
		{
			Client(client).Speaking = view_as<bool>(flags & FF2FLAG_TALKING);
			
			int pickups = (flags & FF2FLAG_ALLOW_HEALTH_PICKUPS) ? 1 : 0;
			if(flags & FF2FLAG_ALLOW_AMMO_PICKUPS)
				pickups += 2;
			
			Client(client).Pickups = pickups;
			
			Client(client).Cfg.SetInt("cosmetics", (flags & FF2FLAG_ALLOW_BOSS_WEARABLES) ? 1 : 0);
		}
	}
	
	return 0;
}

public any NativeOld_GetQueuePoints(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	return Client(client).Queue;
}

public any NativeOld_SetQueuePoints(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 0 || client >= MAXTF2PLAYERS)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	else
	{
		Client(client).Queue = GetNativeCell(2);
	}
	
	return 0;
}

public any NativeOld_GetSpecialKV(Handle plugin, int params)
{
	int index = GetNativeCell(1);
	if(index != -1)
	{
		if(index < -1)
			return ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d", index);
		
		ConfigMap cfg;
		if(params < 2 || GetNativeCell(2))
		{
			cfg = Bosses_GetConfig(index);
		}
		else
		{
			index = FindClientOfBossIndex(index);
			if(index != -1)
				cfg = Client(index).Cfg;
		}
		
		if(cfg)
		{
			char filename[PLATFORM_MAX_PATH], filepath[PLATFORM_MAX_PATH];
			if(cfg.Get("filename", filename, sizeof(filename)))
			{
				BuildPath(Path_SM, filepath, sizeof(filepath), "%s/%s.cfg", FOLDER_CONFIGS, filename);
				
				char name[PLATFORM_MAX_PATH];
				GetPluginFilename(plugin, name, sizeof(name));
				
				KeyValues kv = new KeyValues("character");
				kv.ImportFromFile(filepath);
				kv.SetString("filename", filename);
				RequestFrame(NativeOld_DeleteHandle, kv);
				
				return kv;
			}
		}
	}
	
	return INVALID_HANDLE;
}

public void NativeOld_DeleteHandle(Handle handle)
{
	delete handle;
}

public any NativeOld_StartMusic(Handle plugin, int params)
{
	{
		char buffer[64];
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		Debug("FF2_StartMusic %s", buffer);
	}
	
	int client = GetNativeCell(1);
	if(client < 1)
	{
		Music_PlayNextSong();
	}
	else if(client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	else if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in-game", client);
	}
	else
	{
		Music_PlayNextSong(client);
	}
	
	return 0;
}

public any NativeOld_StopMusic(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1)
	{
		Music_PlaySongToAll();
	}
	else if(client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	else if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in-game", client);
	}
	else
	{
		Music_PlaySongToClient(client);
	}
	
	return 0;
}

public any NativeOld_RandomSound(Handle plugin, int params)
{
	SoundEnum sound;
	sound.Default();
	
	bool success;
	int client = FindClientOfBossIndex(GetNativeCell(4));
	if(client != -1)
	{
		int soundSize;
		GetNativeStringLength(1, soundSize);
		char[] soundBuffer = new char[++soundSize];
		GetNativeString(1, soundBuffer, soundSize);
		
		char arg[12];
		if(!StrContains(soundBuffer, "sound_ability", false))
			IntToString(GetNativeCell(5), arg, sizeof(arg));
		
		success = view_as<bool>(Bosses_GetRandomSound(client, soundBuffer, sound, arg));
	}
	
	SetNativeString(2, sound.Sound, GetNativeCell(3));
	return success;
}

public any NativeOld_EmitVoiceToAll(Handle plugin, int params)
{
	int size;
	GetNativeStringLength(1, size);
	char[] sample = new char[++size];
	GetNativeString(1, sample, size);
	
	int entity = GetNativeCell(2);
	int channel = GetNativeCell(3);
	int level = GetNativeCell(4);
	int flags = GetNativeCell(5);
	float volume = GetNativeCell(6);
	int pitch = GetNativeCell(7);
	int speakerentity = GetNativeCell(8);
	
	float origin[3], dir[3];
	GetNativeArray(9, origin, sizeof(origin));
	GetNativeArray(10, dir, sizeof(dir));
	
	bool updatePos = GetNativeCell(11);
	float soundtime = GetNativeCell(12);
	
	int[] clients = new int[MaxClients];
	int amount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !Client(i).NoVoice)
			clients[amount++] = i;
	}
	
	if(amount)
	{
		if(entity == SOUND_FROM_LOCAL_PLAYER)
			entity = SOUND_FROM_PLAYER;
		
		size = RoundToCeil(volume);
		if(size > 1)
			volume /= float(size);
		
		if(entity > 0 && entity < MAXTF2PLAYERS && Client(entity).IsBoss)
			Client(entity).Speaking = true;
		
		for(int i; i < size; i++)
		{
			EmitSound(clients, amount, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
		}
		
		if(entity > 0 && entity < MAXTF2PLAYERS && Client(entity).IsBoss)
			Client(entity).Speaking = false;
	}
	
	return 0;
}

public any NativeOld_GetClientGlow(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return -1.0;
	
	float duration = Client(client).GlowFor - GetGameTime();
	if(duration < 0.0)
		duration = 0.0;
	
	return duration;
}

public any NativeOld_SetClientGlow(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client >= 0 && client < MAXTF2PLAYERS)
	{
		float duration = GetNativeCell(3);
		if(duration >= 0.0)
		{
			Client(client).GlowFor = GetGameTime() + duration;
		}
		else
		{
			float gameTime = GetGameTime();
			if(Client(client).GlowFor < gameTime)
				Client(client).GlowFor = gameTime;
			
			Client(client).GlowFor += duration;
		}
	}
	
	return 0;
}

public any NativeOld_GetClientShield(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		int entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
				return 100.0;
		}
		
		entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_razorback")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
				return 100.0;
		}
	}
	
	return -1.0;
}

public any NativeOld_SetClientShield(Handle plugin, int params)
{
	return 0;
}

public any NativeOld_RemoveClientShield(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		int entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
				TF2_RemoveWearable(client, entity);
		}
		
		entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_razorback")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
				TF2_RemoveWearable(client, entity);
		}
	}
	
	return -1.0;
}

public any NativeOld_LogError(Handle plugin, int params)
{
	char buffer[256];
	FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	LogError(buffer);
	return 0;
}

public any NativeOld_Debug(Handle plugin, int params)
{
	return CvarDebug.BoolValue;
}

public any NativeOld_SetCheats(Handle plugin, int params)
{
	return 0;
}

public any NativeOld_GetCheats(Handle plugin, int params)
{
	return true;
}

public any NativeOld_MakeBoss(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		int boss = GetNativeCell(2);
		if(boss == -1)
		{
			Bosses_Remove(client);
		}
		else
		{
			int team = GetNativeCell(4);
			if(team == 0)
			{
				team = Bosses_GetBossTeam();
			}
			else if(team > 0)
			{
				team = Bosses_GetBossTeam() == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
			}
			else
			{
				team = -1 - team;
				if(team < 0 || team > TFTeam_Blue)
					team = 0;
			}
			
			int special = GetNativeCell(3);
			if(special < 0)
				special = Preference_PickBoss(client, team);
			
			Bosses_CreateFromSpecial(client, special, team);
			Client(client).Index = boss;
		}
	}
	
	return 0;
}

public any NativeOld_ChooseBoss(Handle plugin, int params)
{
	return false;
}

public any NativeOld_VSHIsVSHMap(Handle plugin, int params)
{
	return Enabled;
}

public any NativeOld_VSHGetHale(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(0);
	return client == -1 ? client : GetClientUserId(client);
}

public any NativeOld_VSHGetTeam(Handle plugin, int params)
{
	int team = TFTeam_Blue;
	int client = FindClientOfBossIndex(0);
	if(client != -1)
		team = GetClientTeam(client);
	
	return team;
}

public any NativeOld_VSHGetSpecial(Handle plugin, int params)
{
	int special;
	int client = FindClientOfBossIndex(0);
	if(client != -1)
		Client(client).Cfg.GetInt("special", special);
	
	return special;
}

public any NativeOld_VSHGetHealth(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(0);
	if(client != -1)
		return Client(client).Health;
	
	return 0;
}

public any NativeOld_VSHGetHealthMax(Handle plugin, int params)
{
	int client = FindClientOfBossIndex(0);
	if(client != -1)
		return Client(client).MaxHealth*Client(client).MaxLives;
	
	return 0;
}

public any NativeOld_VSHGetRoundState(Handle plugin, int params)
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
			return -1;

		case RoundState_StartGame, RoundState_Preround:
			return 0;

		case RoundState_RoundRunning, RoundState_Stalemate:
			return 1;
	}
	
	return 2;
}

static char AbilityCache[13][64];
static char PluginCache[13][64];

public any NativeOld_FF2Data(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	if(boss < 0 || boss > 12)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d", boss);
	
	GetNativeString(3, AbilityCache[boss], sizeof(AbilityCache[]));
	GetNativeString(2, PluginCache[boss], sizeof(PluginCache[]));
	if(PluginCache[boss][0])
	{
		int pos = FindCharInString(PluginCache[boss], '.', true);
		if(pos != -1)
			PluginCache[boss][pos] = '\0';
	}
	return boss;
}

public any NativeOld_FF2DataBoss(Handle plugin, int params)
{
	return GetNativeCell(1);
}

public any NativeOld_FF2DataClient(Handle plugin, int params)
{
	return FindClientOfBossIndex(GetNativeCell(1));
}

public any NativeOld_FF2DataArgI(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	int value = GetNativeCell(3);
	if(boss >= 0 && boss < 13)
	{
		int client = FindClientOfBossIndex(boss);
		if(client != -1)
		{
			char arg[64];
			GetNativeString(2, arg, sizeof(arg));
			Bosses_GetArgInt(client, AbilityCache[boss], arg, value, GetNativeCell(4));
		}
	}
	
	return value;
}

public any NativeOld_FF2DataArgF(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	float value = GetNativeCell(3);
	if(boss >= 0 && boss < 13)
	{
		int client = FindClientOfBossIndex(boss);
		if(client != -1)
		{
			char arg[64];
			GetNativeString(2, arg, sizeof(arg));
			Bosses_GetArgFloat(client, AbilityCache[boss], arg, value);
		}
	}
	
	return value;
}

public any NativeOld_FF2DataArgB(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	bool value = GetNativeCell(3);
	if(boss >= 0 && boss < 13)
	{
		int client = FindClientOfBossIndex(boss);
		if(client != -1)
		{
			char arg[64];
			GetNativeString(2, arg, sizeof(arg));
			Bosses_GetArgBool(client, AbilityCache[boss], arg, value);
		}
	}
	
	return value;
}

public any NativeOld_FF2DataArgS(Handle plugin, int params)
{
	int size = GetNativeCell(4);
	char[] buffer = new char[size];
	
	int boss = GetNativeCell(1);
	if(boss >= 0 && boss < 13)
	{
		int client = FindClientOfBossIndex(boss);
		if(client != -1)
		{
			char arg[64];
			GetNativeString(2, arg, sizeof(arg));
			Bosses_GetArgString(client, AbilityCache[boss], arg, buffer, size);
		}
	}
	
	SetNativeString(3, buffer, size, _, boss);
	return boss;
}

public any NativeOld_FF2DataHasAbility(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	if(boss >= 0 && boss < 13)
	{
		int client = FindClientOfBossIndex(boss);
		if(client != -1)
		{
			ConfigMap cfg = Client(client).Cfg.GetSection(AbilityCache[boss]);
			if(cfg)
			{
				if(PluginCache[boss][0])
				{
					char buffer[64];
					cfg.Get("plugin_name", buffer, sizeof(buffer));
					if(buffer[0] && !StrEqual(buffer, PluginCache[boss]))
						return false;
				}
				
				return true;
			}
		}
	}
	
	return false;
}