//#include <sdktools>
//#include <morecolors>
//#tryinclude <tf2items>

#if defined _ff2r_included
	#endinput
#endif
#define _ff2r_included

/**
 * Called when a boss gets removed
 *
 * @param client	Client index, however they may not always be in-game
 *
 * @noreturn
 */
forward void FF2R_OnBossRemoved(int client);

// Below is related to using ConfigMap, though cfgmap is not required for this include, needed for the below
#if defined CFGMAP_FF2R

/**
 * Get's the ConfigMap of the boss the player's playing as
 *
 * @note			Don't close this handle
 *
 * @param client	Client index
 *
 * @return			ConfigMap handle if found, null otherwise
 */
native ConfigMap FF2R_GetBossData(int client);

/**
 * Changes primary handle the boss uses
 *
 * @note			The previous handle the boss contains will be closed
 *
 * @param client	Client index
 * @param cfg		ConfigMap handle, can be null to remove boss
 *
 * @noreturn
 */
native void FF2R_SetBossData(int client, ConfigMap cfg=null);

methodmap ConfigData < ConfigMap
{
	public int GetInt(const char[] key, int defaul=0, int base=10)
	{
		int value = defaul;
		view_as<ConfigMap>(this).GetInt(key, value, base);
		return value;
	}
	public float GetFloat(const char[] key, float defaul=0.0)
	{
		float value = defaul;
		view_as<ConfigMap>(this).GetFloat(key, value);
		return value;
	}
	public int GetString(const char[] key, char[] buffer, int length, const char[] defaul="")
	{
		int size = view_as<ConfigMap>(this).Get(key, buffer, length);
		if(!size)
			size = strcopy(buffer, length, defaul);
		
		return size;
	}
	public bool GetBool(const char[] key, bool defaul=false)
	{
		bool value = defaul;
		view_as<ConfigMap>(this).GetBool(key, value, false);
		return value;
	}
	public void SetString(const char[] key, const char[] value)
	{
		view_as<ConfigMap>(this).Set(key, value);
	}
	public void SetBool(const char[] key, bool value)
	{
		view_as<ConfigMap>(this).SetInt(key, value ? 1 : 0);
	}
	public void Remove(const char[] key)
	{
		view_as<ConfigMap>(this).SetVal(key, _, -1);
	}
}

methodmap AbilityData < ConfigData
{
	public bool IsMyPlugin()
	{
		char plugin[64];
		if(this.GetString("plugin_name", plugin, sizeof(plugin))
		{
			char buffer[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, buffer, sizeof(buffer));
			
			int highest;
			int size = strlen(buffer);
			for(int i; i<size; i++)
			{
				if(buffer[i] == '/' || buffer[i] == '\\')
					highest = i;
			}
			
			strcopy(buffer, sizeof(buffer), buffer[highest+1]);
			if(!StrEqual(buffer, plugin))
				return false;
		}
		return true;
	}
}

methodmap BossData < ConfigData
{
	public BossData(int client)
	{
		return view_as<BossData>(FF2R_GetBossData(client));
	}
	public AbilityData GetAbility(const char[] key)
	{
		return view_as<AbilityData>(view_as<ConfigMap>(this).GetSection(key));
	}
}

/**
 * Called when a boss gets created
 *
 * @param client	Client index
 * @param cfg		Boss's ConfigMap
 *
 * @noreturn
 */
forward void FF2R_OnBossCreated(int client, BossData &cfg);

#else

native void FF2R_SetBossData(int client, Handle cfg=null);
forward void FF2R_OnBossCreated(int client);

#endif

public SharedPlugin __pl_ff2r =
{
	name = "freak_fortress_2",
	file = "freak_fortress_2.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ff2r_SetNTVOptional()
{
	MarkNativeAsOptional("FF2_IsFF2Enabled");
	MarkNativeAsOptional("FF2_IsBossVsBoss");
	MarkNativeAsOptional("FF2_GetFF2Version");
	MarkNativeAsOptional("FF2_GetForkVersion");
	MarkNativeAsOptional("FF2_GetRoundState");
	MarkNativeAsOptional("FF2_GetBossUserId");
	MarkNativeAsOptional("FF2_GetBossIndex");
	MarkNativeAsOptional("FF2_GetBossTeam");
	MarkNativeAsOptional("FF2_GetBossSpecial");
	MarkNativeAsOptional("FF2_GetBossName");
	MarkNativeAsOptional("FF2_GetBossHealth");
	MarkNativeAsOptional("FF2_SetBossHealth");
	MarkNativeAsOptional("FF2_GetBossMaxHealth");
	MarkNativeAsOptional("FF2_SetBossMaxHealth");
	MarkNativeAsOptional("FF2_GetBossLives");
	MarkNativeAsOptional("FF2_SetBossLives");
	MarkNativeAsOptional("FF2_GetBossMaxLives");
	MarkNativeAsOptional("FF2_SetBossMaxLives");
	MarkNativeAsOptional("FF2_GetBossCharge");
	MarkNativeAsOptional("FF2_SetBossCharge");
	MarkNativeAsOptional("FF2_GetBossRageDamage");
	MarkNativeAsOptional("FF2_SetBossRageDamage");
	MarkNativeAsOptional("FF2_GetClientDamage");
	MarkNativeAsOptional("FF2_GetRageDist");
	MarkNativeAsOptional("FF2_HasAbility");
	MarkNativeAsOptional("FF2_DoAbility");
	MarkNativeAsOptional("FF2_GetAbilityArgument");
	MarkNativeAsOptional("FF2_GetAbilityArgumentFloat");
	MarkNativeAsOptional("FF2_GetAbilityArgumentString");
	MarkNativeAsOptional("FF2_GetArgNamedI");
	MarkNativeAsOptional("FF2_GetArgNamedF");
	MarkNativeAsOptional("FF2_GetArgNamedS");
	MarkNativeAsOptional("FF2_EmitVoiceToAll");
	MarkNativeAsOptional("FF2_RandomSound");
	MarkNativeAsOptional("FF2_StartMusic");
	MarkNativeAsOptional("FF2_StopMusic");
	MarkNativeAsOptional("FF2_GetSpecialKV");
	MarkNativeAsOptional("FF2_GetFF2flags");
	MarkNativeAsOptional("FF2_SetFF2flags");
	MarkNativeAsOptional("FF2_GetQueuePoints");
	MarkNativeAsOptional("FF2_SetQueuePoints");
	MarkNativeAsOptional("FF2_GetClientGlow");
	MarkNativeAsOptional("FF2_SetClientGlow");
	MarkNativeAsOptional("FF2_GetClientShield");
	MarkNativeAsOptional("FF2_RemoveClientShield");
	MarkNativeAsOptional("FF2_LogError");
	MarkNativeAsOptional("FF2_Debug");
	MarkNativeAsOptional("FF2_SetCheats");
	MarkNativeAsOptional("FF2_GetCheats");
	MarkNativeAsOptional("FF2_MakeBoss");
	MarkNativeAsOptional("FF2_ReportError");
	
	MarkNativeAsOptional("FF2Data.Unknown");
	MarkNativeAsOptional("FF2Data.FF2Data");
	MarkNativeAsOptional("FF2Data.Invalid");
	MarkNativeAsOptional("FF2Data.boss.get");
	MarkNativeAsOptional("FF2Data.client.get");
	MarkNativeAsOptional("FF2Data.Config.get");
	MarkNativeAsOptional("FF2Data.Health.get");
	MarkNativeAsOptional("FF2Data.Health.set");
	MarkNativeAsOptional("FF2Data.MaxHealth.get");
	MarkNativeAsOptional("FF2Data.MaxHealth.set");
	MarkNativeAsOptional("FF2Data.Lives.get");
	MarkNativeAsOptional("FF2Data.Lives.set");
	MarkNativeAsOptional("FF2Data.MaxLives.get");
	MarkNativeAsOptional("FF2Data.MaxLives.set");
	MarkNativeAsOptional("FF2Data.RageDmg.get");
	MarkNativeAsOptional("FF2Data.RageDmg.set");
	MarkNativeAsOptional("FF2Data.Change");
	MarkNativeAsOptional("FF2Data.GetArgI");
	MarkNativeAsOptional("FF2Data.GetArgF");
	MarkNativeAsOptional("FF2Data.GetArgB");
	MarkNativeAsOptional("FF2Data.GetArgS");
	MarkNativeAsOptional("FF2Data.HasAbility");
	MarkNativeAsOptional("FF2Data.BossTeam");
}
#endif
