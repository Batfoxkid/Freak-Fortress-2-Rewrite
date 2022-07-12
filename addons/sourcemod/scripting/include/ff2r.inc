#include <sdktools_sound>

#if defined _ff2r_included
	#endinput
#endif
#define _ff2r_included

#define SNDVOL_BOSS	2.0

/**
 * Activates a range of abilities within slots
 * 
 * @param boss	Boss's client index
 * @param low	Low ability slot
 * @param high	High ability slot
 * 
 * @error		Invalid client index or client is not a boss
 * 
 * @return		True if the sound was found, false otherwise
 */
native void FF2R_DoBossSlot(int boss, int low, int high = -2147483647);

/**
 * Emits a boss's random sound to a list of clients.
 * 
 * @param clients		Array of client indexes
 * @param numClients	Number of clients in the array
 * @param key			Boss's sound key
 * @param boss			Boss's client index
 * @param required		Required value for a sound
 * @param entity		Entity to emit from
 * @param channel		Channel to emit with
 * @param level			Sound level
 * @param flags			Sound flags
 * @param volume		Sound volume
 * @param pitch			Sound pitch
 * @param speakerentity	Unknown
 * @param origin		Sound origin
 * @param dir			Sound direction
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for
 * 
 * @error				Invalid client index or client is not a boss
 * 
 * @return				True if the sound was found, false otherwise
 */
native bool FF2R_EmitBossSound(const int[] clients, int numClients, const char[] key, int boss, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_BOSS, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = false, float soundtime = 0.0);

/**
 * Gets if a player is considered a minion which ignores weapon changes and players alive count
 * 
 * @param client	Client index
 * 
 * @error			Invalid client index
 * 
 * @return			True if the player is a minion, false otherwise
 */
native bool FF2R_GetClientMinion(int client);

/**
 * Sets if a player is considered a minion which ignores weapon changes and players alive count
 * 
 * @note			Minion status is removed when a player dies
 * 
 * @param client	Client index
 * @param value		If the player is a minion
 * 
 * @error			Invalid client index or client is not in game
 * 
 * @noreturn
 */
native void FF2R_SetClientMinion(int client, bool value);

/**
 * Gets the player's score in the current round
 * 
 * @note			Score is reset once a new round begins
 * 
 * @param client	Client index
 * @param damage	Damage dealt by the player
 * @param healing	Healing done by the player
 * @param assist	Assisting done by the player
 * 
 * @error			Invalid client index
 * 
 * @return			Total score the player has
 */
native int FF2R_GetClientScore(int client, int &damage = 0, int &healing = 0, int &assist = 0);

/**
 * Called when a player spawns, dies, disconnects, etc.
 * 
 * @note		Players counted as minions aren't counted
 *
 * @param alive	Array of players alive on team number
 * @param total	Array of total players on team number
 * 
 * @return		Plugin_Changed if the count was changed, Plugin_Handled to also prevent lastman and control point logic, Plugin_Stop to also prevent post forwards from being called
 */
forward Action FF2R_OnAliveChange(int alive[4], int total[4]);

/**
 * Called when a player spawns, dies, disconnects, etc.
 * 
 * @note		Players counted as minions aren't counted
 *
 * @param alive	Array of players alive on team number
 * @param total	Array of total players on team number
 * 
 * @noreturn
 */
forward void FF2R_OnAliveChanged(const int alive[4], const int total[4]);

/**
 * Called when a boss gets removed
 * 
 * @param client	Client index, however they may not always be in-game or have a boss cfg
 * 
 * @noreturn
 */
forward void FF2R_OnBossRemoved(int client);

/**
 * Wrapper to emit sound to one client.
 * 
 * @param client		Client index
 * @param key			Boss's sound key
 * @param boss			Boss's client index
 * @param required		Required value for a sound
 * @param entity		Entity to emit from
 * @param channel		Channel to emit with
 * @param level			Sound level
 * @param flags			Sound flags
 * @param volume		Sound volume
 * @param pitch			Sound pitch
 * @param speakerentity	Unknown
 * @param origin		Sound origin
 * @param dir			Sound direction
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for
 * 
 * @error				Invalid client index or client is not a boss
 * 
 * @return				True if the sound was found, false otherwise
 */
stock bool FF2R_EmitBossSoundToClient(int client, const char[] key, int boss, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_BOSS, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = false, float soundtime = 0.0)
{
	int clients[1];
	clients[0] = client;
	
	/* Save some work for SDKTools and remove SOUND_FROM_PLAYER references */
	if(entity == SOUND_FROM_PLAYER)
		entity = client;
	
	return FF2R_EmitBossSound(clients, 1, key, boss, required, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

/**
 * Wrapper to emit sound to all clients.
 * 
 * @param key			Boss's sound key
 * @param boss			Boss's client index
 * @param required		Required value for a sound
 * @param entity		Entity to emit from
 * @param channel		Channel to emit with
 * @param level			Sound level
 * @param flags			Sound flags
 * @param volume		Sound volume
 * @param pitch			Sound pitch
 * @param speakerentity	Unknown
 * @param origin		Sound origin
 * @param dir			Sound direction
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for
 * 
 * @error				Invalid client index or client is not a boss
 * 
 * @return				True if the sound was found, false otherwise
 */
stock bool FF2R_EmitBossSoundToAll(const char[] key, int boss, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_BOSS, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = false, float soundtime = 0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			clients[total++] = i;
	}
	
	return FF2R_EmitBossSound(clients, total, key, boss, required, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

/**
 *	Below is related to using ConfigMap, though cfgmap is not required for this include, needed for the below
 */
#if defined CFGMAP_FF2R

methodmap ConfigData < ConfigMap
{
	public int GetInt(const char[] key, int defaul = 0, int base = 10)
	{
		int value = defaul;
		view_as<ConfigMap>(this).GetInt(key, value, base);
		return value;
	}
	
	public float GetFloat(const char[] key, float defaul = 0.0)
	{
		float value = defaul;
		view_as<ConfigMap>(this).GetFloat(key, value);
		return value;
	}
	
	public int GetString(const char[] key, char[] buffer, int length, const char[] defaul = "")
	{
		int size = view_as<ConfigMap>(this).Get(key, buffer, length);
		if(!size)
			size = strcopy(buffer, length, defaul);
		
		return size;
	}
	
	public bool GetBool(const char[] key, bool defaul = false)
	{
		bool value = defaul;
		view_as<ConfigMap>(this).GetBool(key, value, false);
		return value;
	}
	
	public ConfigData GetSection(const char[] key)
	{
		return view_as<ConfigData>(view_as<ConfigMap>(this).GetSection(key));
	}
	
	public void SetString(const char[] key, const char[] value)
	{
		view_as<ConfigMap>(this).Set(key, value);
	}
	
	public void SetBool(const char[] key, bool value)
	{
		view_as<ConfigMap>(this).SetInt(key, value ? 1 : 0);
	}
	
	public ConfigData SetSection(const char[] key)
	{
		return view_as<ConfigData>(view_as<ConfigMap>(this).SetSection(key));
	}
	
	public void Remove(const char[] key)
	{
		view_as<ConfigMap>(this).DeleteSection(key);
	}
}

methodmap AbilityData < ConfigData
{
	public bool IsMyPlugin()
	{
		if(!this)
			return false;
		
		char plugin[64];
		if(this.GetString("plugin_name", plugin, sizeof(plugin), ""))
		{
			char buffer[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, buffer, sizeof(buffer));
			int pos = FindCharInString(buffer, '.', true);
			if(pos != -1)
				buffer[pos] = '\0';
			
			int highest = -1;
			for(int i = strlen(buffer)-1; i > 0; i--)
			{
				if(buffer[i] == '/' || buffer[i] == '\\')
				{
					highest = i;
					break;
				}
			}
			
			if(!StrEqual(buffer[highest+1], plugin))
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
 * Get's the ConfigMap of the boss the player's playing as
 * 
 * @note			Don't close this handle
 * 
 * @param client	Client index
 * 
 * @error			Invalid client index
 * 
 * @return			ConfigMap handle if found, null otherwise
 */
native BossData FF2R_GetBossData(int client);

/**
 * Changes primary handle the boss uses
 * 
 * @note			The previous handle the boss contains will be closed
 * @note			Handle input is cloned and calling plugin may still DeleteCfg when necessary
 * 
 * @param client	Client index
 * @param cfg		ConfigMap handle, can be null to remove boss 
 * @param forwards	If to call FF2R_OnBossCreated and FF2R_OnBossRemoved respectively
 * 
 * @error			Invalid client index or client is not in game
 * 
 * @noreturn
 */
native void FF2R_SetBossData(int client, ConfigMap cfg = null, bool forwards = false);

/**
 * Creates or removes a boss on a player
 * 
 * @note			Handle input is cloned and calling plugin may still DeleteCfg when necessary
 * 
 * @param client	Client index
 * @param cfg		ConfigMap handle, can be null to remove boss 
 * @param team		Team number the player is assigned to
 * 
 * @error			Invalid client index or client is not in game
 * 
 * @return			ConfigMap handle of created boss, null given on boss remove
 */
native BossData FF2R_CreateBoss(int client, ConfigMap cfg = null, int team = 0);

/**
 * Called when an ability is about to be activated
 * 
 * @param client	Client index
 * @param ability	Ability name
 * @param result	True if the ability will activate, false otherwise
 * @param cfg		Boss's ConfigMap of the ability
 * 
 * @return			Plugin_Changed if result was changed, Plugin_Handled to ignore FF2_PreAbility, Plugin_Stop to stop the ability
 */
forward Action FF2R_OnAbilityPre(int client, const char[] ability, AbilityData cfg, bool &result);

/**
 * Called when an ability is activated, only called if the ability has no plugin_name or named for your plugin
 * 
 * @param client	Client index
 * @param ability	Ability name
 * @param cfg		Boss's ConfigMap of the ability
 * 
 * @noreturn		
 */
forward void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg);

/**
 * Called when after an ability was activated
 * 
 * @param client	Client index
 * @param ability	Ability name
 * @param cfg		Boss's ConfigMap of the ability
 * 
 * @noreturn		
 */
forward void FF2R_OnAbilityPost(int client, const char[] ability, AbilityData cfg);

/**
 * Called when a boss gets created or updated, can get called more than once
 * 
 * @param client	Client index
 * @param cfg		Boss's ConfigMap
 * @param setup		Setup is active
 * 
 * @noreturn
 */
forward void FF2R_OnBossCreated(int client, BossData cfg, bool setup);

/**
 * Called before a boss gets loaded
 * 
 * @note			The cfg at this state contains every key the boss has without clean up
 * 
 * @param cfg		Boss's ConfigMap
 * @param enabled	If the boss will be precached and playable
 * 
 * @return			Plugin_Changed if the result was changed, Plugin_Handled to ignore precache logic such as downloads, Plugin_Stop to blockk the boss from being loaded
 */
forward Action FF2R_OnBossPrecache(BossData cfg, bool &enabled);

/**
 * Called after a boss gets loaded
 * 
 * @param cfg		Boss's ConfigMap
 * @param enabled	If the boss is precached and playable
 * @param index		Boss's assigned index
 * 
 * @noreturn
 */
forward void FF2R_OnBossPrecached(BossData cfg, bool enabled, int index);

#else

native bool FF2R_GetBossData(int client);
native void FF2R_SetBossData(int client, bool forwards = true);
native bool FF2R_GetSpecialData(int special);
native bool FF2R_CreateBoss(int client);
//forward Action FF2R_OnAbilityPre(int client, const char[] ability, any cfg, bool &result);
forward void FF2R_OnAbility(int client, const char[] ability);
forward void FF2R_OnAbilityPost(int client, const char[] ability);
//forward void FF2R_OnBossCreated(int client, any cfg, bool setup);
//forward Action FF2R_OnBossPrecache(any cfg, bool &enabled);
//forward void FF2R_OnBossPrecached(any cfg, bool enabled, int index);

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
	MarkNativeAsOptional("FF2R_DoBossSlot");
	MarkNativeAsOptional("FF2R_EmitBossSound");
	MarkNativeAsOptional("FF2R_GetBossData");
	MarkNativeAsOptional("FF2R_SetBossData");
	MarkNativeAsOptional("FF2R_GetSpecialData");
	MarkNativeAsOptional("FF2R_CreateBoss");
}
#endif
