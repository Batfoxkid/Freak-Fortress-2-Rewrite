#if defined _ff2r_included
	#endinput
#endif
#define _ff2r_included

#include <sdktools_sound>

#pragma semicolon 1
#pragma newdecls required

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
native bool FF2R_DoBossSlot(int boss, int low, int high = -2147483647);

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
native bool FF2R_EmitBossSound(const int[] clients, int numClients, const char[] key, int boss, const char[] required = NULL_STRING, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_BOSS, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = false, float soundtime = 0.0);

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
 * Gets the plugin's handle, useful in cases where ConfigMap cloning is needed
 * 
 * @return	FF2's plugin handle
 */
native Handle FF2R_GetPluginHandle();

/**
 * Get's the current status of FF2
 * 
 * @return	0 if no bosses are loaded, 1 if bosses are loaded, 2 if arena-styled gamemode is enabled
 */
native int FF2R_GetGamemodeType();

/**
 * Calls CLagCompensationManager::StartLagCompensation
 * 
 * @note			Make sure to call FF2R_FinishLagCompensation afterwards
 * 
 * @param client	Client index
 * 
 * @error			Invalid client index or client is not in game
 * 
 * @noreturn
 */
native void FF2R_StartLagCompensation(int client);

/**
 * Calls CLagCompensationManager::FinishLagCompensation
 * 
 * @note			Make sure to call FF2R_StartLagCompensation first
 * 
 * @param client	Client index
 * 
 * @error			Invalid client index or client is not in game
 * 
 * @noreturn
 */
native void FF2R_FinishLagCompensation(int client);

/**
 * Updates max health, speed attributes, and the health bar
 * 
 * @param boss	Boss's client index
 * 
 * @error		Invalid client index or client is not a boss
 * 
 * @noreturn
 */
native void FF2R_UpdateBossAttributes(int boss);

/**
 * Gets if client has HUDs enabled
 * 
 * @param client	Client index
 * 
 * @error		Invalid client index
 * 
 * @return		If the client has HUDs enabled
 */
native bool FF2R_GetClientHud(int client);

/**
 * Sets if the client can see HUDs
 * 
 * @param client	Client index
 * @param status	If the client can see HUDs
 * 
 * @error		Invalid client index or client is not in game
 * 
 * @noreturn
 */
native void FF2R_SetClientHud(int client, bool status);

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
 * @note			Client could not be in-game or have a boss config
 * 
 * @param client	Client index
 * 
 * @noreturn
 */
forward void FF2R_OnBossRemoved(int client);

/**
 * Called when a player tries to pick up a dropped item
 * 
 * @param client	Client index
 * @param weapon	Entity index of dropped weapon
 * 
 * @return		Plugin_Changed to let the game decide, Plugin_Handled to allow pickup, Plugin_Stop to block pickup
 */
forward Action FF2R_OnPickupDroppedWeapon(int client, int weapon);

/**
 * Called when a boss equips their loadout
 * 
 * @param client	Client index
 * @param weapons	If weapons were given
 * 
 * @noreturn
 */
forward void FF2R_OnBossEquipped(int client, bool weapons);

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
stock bool FF2R_EmitBossSoundToClient(int client, const char[] key, int boss, const char[] required = NULL_STRING, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_BOSS, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = false, float soundtime = 0.0)
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
stock bool FF2R_EmitBossSoundToAll(const char[] key, int boss, const char[] required = NULL_STRING, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_BOSS, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = false, float soundtime = 0.0)
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
	
	public int GetString(const char[] key, char[] buffer, int length, const char[] defaul = NULL_STRING)
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
		if(this.GetString("plugin_name", plugin, sizeof(plugin)))
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
	// Get's the ConfigMap of the boss the player's playing as
	// 
	// @note			Don't close this handle
	// @param client	Client index
	// @error			Invalid client index
	// @return			ConfigMap handle if found, null otherwise
	public BossData(int client)
	{
		return view_as<BossData>(FF2R_GetBossData(client));
	}
	
	// Get's the ConfigMap of the boss the player's playing as
	// 
	// @note		Don't close this handle
	// @param key	Get's a section from a name
	// @return		ConfigMap handle if found, null otherwise
	public AbilityData GetAbility(const char[] key)
	{
		return view_as<AbilityData>(view_as<ConfigMap>(this).GetSection(key));
	}
	
	// Creates or removes a boss on a player
	// 
	// @note			Handle input is cloned and calling plugin may still DeleteCfg when necessary
	// @param client	Client index
	// @param team		Team number the player is assigned to
	// @error			Invalid client index or client is not in game
	// @return			ConfigMap handle of created boss, null given on boss remove
	public BossData CreateBoss(int client, int team = 0)
	{
		return FF2R_CreateBoss(client, this, team);
	}
	
	// Gets charge from a charge slot
	//
	// @param slot	Slot number
	// @return	Amount of charge, eg. 100% RAGE returns 100.0
	public float GetCharge(int slot)
	{
		char buffer[8];
		FormatEx(buffer, sizeof(buffer), "charge%d", slot);
		return this.GetFloat(buffer);
	}
	
	// Sets charge from a charge slot
	// 
	// @param slot	Slot number
	// @param value	Amount of charge
	public void SetCharge(int slot, float value)
	{
		char buffer[8];
		FormatEx(buffer, sizeof(buffer), "charge%d", slot);
		this.SetFloat(buffer, value);
	}
	
	// Index where the boss was generated from in the boss list, -1 if none
	property int Special
	{
		public get()
		{
			return this.GetInt("special", -1);
		}
		public set(int value)
		{
			this.SetInt("special", value);
		}
	}
	
	// Amount of lives remaining on user
	property int Lives
	{
		public get()
		{
			return this.GetInt("livesleft", 1);
		}
		public set(int value)
		{
			this.SetInt("livesleft", value);
		}
	}
	
	// Starting amount of lives
	property int MaxLives
	{
		public get()
		{
			return this.GetInt("lives", 1);
		}
		public set(int value)
		{
			this.SetInt("lives", value);
		}
	}
	
	// Starting health and when losing a life
	property int MaxHealth
	{
		public get()
		{
			return this.GetInt("maxhealth");
		}
		public set(int value)
		{
			this.SetInt("maxhealth", value);
		}
	}
	
	// Amount of damage to fill up 100% of RAGE
	property float RageDamage
	{
		public get()
		{
			return this.GetFloat("ragedmg");
		}
		public set(float value)
		{
			this.SetFloat("ragedmg", value);
		}
	}
	
	// Minimum amount of rage required to activate
	property float RageMin
	{
		public get()
		{
			return this.GetFloat("ragemin", 100.0);
		}
		public set(float value)
		{
			this.SetFloat("ragemin", value);
		}
	}
	
	// Maximum amount of rage the boss can hold
	property float RageMax
	{
		public get()
		{
			return this.GetFloat("ragemax", 100.0);
		}
		public set(float value)
		{
			this.SetFloat("ragemax", value);
		}
	}
	
	// How rage is consumed when activating
	// 0 = Default, removes all rage on use
	// 1 = Only consume minimum required on use
	// 2 = Can't activate rage
	property int RageMode
	{
		public get()
		{
			return this.GetInt("ragemode");
		}
		public set(int value)
		{
			this.SetInt("ragemode", value);
		}
	}
	
	// If to block normal class voicelines
	property bool BlockVo
	{
		public get()
		{
			return this.GetBool("sound_block_vo");
		}
		public set(bool value)
		{
			this.SetBool("sound_block_vo", value);
		}
	}
	
	// If can randomly critical hit
	property bool Crits
	{
		public get()
		{
			return this.GetBool("crits", true);
		}
		public set(bool value)
		{
			this.SetBool("crits", value);
		}
	}
	
	// If to triple all damage that deals less than 160
	property bool Triple
	{
		public get()
		{
			return this.GetBool("triple");
		}
		public set(bool value)
		{
			this.SetBool("triple", value);
		}
	}
	
	// If to allow rocket jumping, 2 means to also deal self damage
	property int Knockback
	{
		public get()
		{
			return this.GetInt("knockback");
		}
		public set(int value)
		{
			this.SetInt("knockback", value);
		}
	}
	
	// If to allow picking up health/ammo kits
	// 0 = Allow None
	// 1 = Allow Health
	// 2 = Allow Ammo
	// 3 = Allow Both
	property int Pickups
	{
		public get()
		{
			return this.GetInt("pickups");
		}
		public set(int value)
		{
			this.SetInt("pickups", value);
		}
	}
	
	// The game time since the last backstab taken
	property float LastStabTime
	{
		public get()
		{
			return this.GetFloat("laststabtime");
		}
		public set(float value)
		{
			this.SetFloat("laststabtime", value);
		}
	}
	
	// The last amount of trigger damage taken
	property float LastTriggerDamage
	{
		public get()
		{
			return this.GetFloat("lasttriggerdamage");
		}
		public set(float value)
		{
			this.SetFloat("lasttriggerdamage", value);
		}
	}
	
	// The game time since the last trigger damage taken
	property float LastTriggerTime
	{
		public get()
		{
			return this.GetFloat("lasttriggertime");
		}
		public set(float value)
		{
			this.SetFloat("lasttriggertime", value);
		}
	}
	
	// The current kill spree for the sound
	property int KillSpree
	{
		public get()
		{
			return this.GetInt("killspree");
		}
		public set(int value)
		{
			this.SetInt("killspree", value);
		}
	}
	
	// The game time since the last kill
	property float LastKillTime
	{
		public get()
		{
			return this.GetFloat("lastkilltime");
		}
		public set(float value)
		{
			this.SetFloat("lastkilltime", value);
		}
	}
	
	// The game time until passive charge slots are activated
	property float PassiveAt
	{
		public get()
		{
			return this.GetFloat("passivetimeat");
		}
		public set(float value)
		{
			this.SetFloat("passivetimeat", value);
		}
	}
	
	// If the boss is currently speaking in this SoundHook
	property bool Speaking
	{
		public get()
		{
			return this.GetBool("speaking");
		}
		public set(bool value)
		{
			this.SetBool("speaking", value);
		}
	}
	
	// RPS lose count
	property int RPSHit
	{
		public get()
		{
			return this.GetInt("rpshit");
		}
		public set(int value)
		{
			this.SetInt("rpshit", value);
		}
	}
	
	// First RPS damage taken
	property int RPSDamage
	{
		public get()
		{
			return this.GetInt("rpsdmg");
		}
		public set(int value)
		{
			this.SetInt("rpsdmg", value);
		}
	}
	
	// Multiplies the amount of rage gained from the next damage taken
	property float RageDebuff
	{
		public get()
		{
			return this.GetFloat("ragedebuff", 1.0);
		}
		public set(float value)
		{
			this.SetFloat("ragedebuff", value);
		}
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
 * Get's the ConfigMap of the boss in the boss list
 * 
 * @note			Don't close this handle
 * 
 * @param special	Special index
 * 
 * @return			ConfigMap handle if found, null otherwise
 */
native BossData FF2R_GetSpecialData(int client);

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

/**
 * Called when a modifier is applied to a boss, only called if the modifier has no plugin name or named for your plugin
 * 
 * @param client	Client index
 * @param cfg		Modifier ConfigMap
 * 
 * @noreturn
 */
forward void FF2R_OnBossModifier(int client, ConfigData cfg);

#else

native bool FF2R_GetBossData(int client);
native void FF2R_SetBossData(int client, bool forwards = true);
native bool FF2R_GetSpecialData(int special);
native bool FF2R_CreateBoss(int client);
forward void FF2R_OnAbility(int client, const char[] ability);
forward void FF2R_OnAbilityPost(int client, const char[] ability);
forward void FF2R_OnBossModifier(int client);

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
	MarkNativeAsOptional("FF2R_GetClientMinion");
	MarkNativeAsOptional("FF2R_SetClientMinion");
	MarkNativeAsOptional("FF2R_GetClientScore");
	MarkNativeAsOptional("FF2R_GetPluginHandle");
	MarkNativeAsOptional("FF2R_GetGamemodeType");
	MarkNativeAsOptional("FF2R_StartLagCompensation");
	MarkNativeAsOptional("FF2R_FinishLagCompensation");
	MarkNativeAsOptional("FF2R_UpdateBossAttributes");
	MarkNativeAsOptional("FF2R_GetClientHud");
	MarkNativeAsOptional("FF2R_SetClientHud");
	MarkNativeAsOptional("FF2R_GetBossData");
	MarkNativeAsOptional("FF2R_SetBossData");
	MarkNativeAsOptional("FF2R_GetSpecialData");
	MarkNativeAsOptional("FF2R_CreateBoss");
}
#endif
