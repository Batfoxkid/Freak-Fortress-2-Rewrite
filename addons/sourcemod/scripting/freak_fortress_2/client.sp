/*
	bool IsBoss
	ConfigMap Cfg
	int Queue
	bool NoMusic
	bool MusicShuffle
	bool NoVoice
	bool NoChanges
	bool NoDmgHud
	bool NoHud
	int GetLastPlayed(char[] buffer, int length)
	void SetLastPlayed(const char[] buffer)
	bool Minion
	bool Glowing
	float GlowFor
	float OverlayFor
	float RefreshAt
	int Damage
	int TotalDamage
	int Healing
	int Assist
	int TotalAssist
	int Stabs
	int Index
	int GetDamage(int slot)
	void SetDamage(int slot, int damage)
	int Lives
	int MaxLives
	int MaxHealth
	int Health
	float RageDamage
	float RageMin
	float RageMax
	int RageMode
	bool BlockVo
	bool Crits
	bool Triple
	int Knockback
	int Pickups
	float LastStabTime
	float LastTriggerDamage
	float LastTriggerTime
	int KillSpree
	float LastKillTime
	float PassiveAt
	bool Speaking
	int RPSHit
	int RPSDamage
	float RageDebuff
	float GetCharge(int slot)
	void SetCharge(int slot, float value)
	void ResetByDeath()
	void ResetByRound()
	void ResetByAll()
*/

#pragma semicolon 1

static ConfigMap BossMap[MAXTF2PLAYERS] = {null, ...};
static int Queue[MAXTF2PLAYERS];
static bool NoMusic[MAXTF2PLAYERS];
static bool MusicShuffle[MAXTF2PLAYERS];
static bool NoVoice[MAXTF2PLAYERS];
static bool NoChanges[MAXTF2PLAYERS];
static bool NoDmgHud[MAXTF2PLAYERS];
static bool NoHud[MAXTF2PLAYERS];
static char LastPlayed[MAXTF2PLAYERS][64];
static bool Minion[MAXTF2PLAYERS];
static bool Glowing[MAXTF2PLAYERS];
static float GlowFor[MAXTF2PLAYERS];
static float OverlayFor[MAXTF2PLAYERS];
static float RefreshAt[MAXTF2PLAYERS];
static int Damage[MAXTF2PLAYERS][6];
static int TotalDamage[MAXTF2PLAYERS];
static int Assist[MAXTF2PLAYERS];
static int Index[MAXTF2PLAYERS];

methodmap Client
{
	public Client(int client)
	{
		return view_as<Client>(client);
	}
	
	property bool IsBoss
	{
		public get()
		{
			return BossMap[view_as<int>(this)] != null;
		}
	}
	
	property ConfigMap Cfg
	{
		public get()
		{
			return BossMap[view_as<int>(this)];
		}
		public set(ConfigMap cfg)
		{
			BossMap[view_as<int>(this)] = cfg;
		}
	}
	
	property int Queue
	{
		public get()
		{
			return Queue[view_as<int>(this)];
		}
		public set(int amount)
		{
			Queue[view_as<int>(this)] = amount;
		}
	}
	
	property bool NoMusic
	{
		public get()
		{
			return NoMusic[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoMusic[view_as<int>(this)] = value;
		}
	}
	
	property bool MusicShuffle
	{
		public get()
		{
			return MusicShuffle[view_as<int>(this)];
		}
		public set(bool value)
		{
			MusicShuffle[view_as<int>(this)] = value;
		}
	}
	
	property bool NoVoice
	{
		public get()
		{
			return NoVoice[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoVoice[view_as<int>(this)] = value;
		}
	}
	
	property bool NoChanges
	{
		public get()
		{
			return NoChanges[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoChanges[view_as<int>(this)] = value;
		}
	}
	
	property bool NoDmgHud
	{
		public get()
		{
			return NoDmgHud[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoDmgHud[view_as<int>(this)] = value;
		}
	}
	
	property bool NoHud
	{
		public get()
		{
			return NoHud[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoHud[view_as<int>(this)] = value;
		}
	}
	
	public int GetLastPlayed(char[] buffer, int length)
	{
		return strcopy(buffer, length, LastPlayed[view_as<int>(this)]);
	}
	
	public void SetLastPlayed(const char[] buffer)
	{
		strcopy(LastPlayed[view_as<int>(this)], sizeof(LastPlayed[]), buffer);
	}
	
	property bool Minion
	{
		public get()
		{
			return Minion[view_as<int>(this)];
		}
		public set(bool value)
		{
			Minion[view_as<int>(this)] = value;
		}
	}
	
	property bool Glowing
	{
		public get()
		{
			return Glowing[view_as<int>(this)];
		}
		public set(bool value)
		{
			Glowing[view_as<int>(this)] = value;
		}
	}
	
	property float GlowFor
	{
		public get()
		{
			return GlowFor[view_as<int>(this)];
		}
		public set(float time)
		{
			GlowFor[view_as<int>(this)] = time;
		}
	}
	
	property float OverlayFor
	{
		public get()
		{
			return OverlayFor[view_as<int>(this)];
		}
		public set(float time)
		{
			OverlayFor[view_as<int>(this)] = time;
		}
	}
	
	property float RefreshAt
	{
		public get()
		{
			return RefreshAt[view_as<int>(this)];
		}
		public set(float time)
		{
			RefreshAt[view_as<int>(this)] = time;
		}
	}
	
	property int Damage
	{
		public get()
		{
			return Damage[view_as<int>(this)][0];
		}
		public set(int amount)
		{
			Damage[view_as<int>(this)][0] = amount;
		}
	}
	
	property int TotalDamage
	{
		public get()
		{
			return TotalDamage[view_as<int>(this)];
		}
		public set(int amount)
		{
			TotalDamage[view_as<int>(this)] = amount;
		}
	}
	
	property int Healing	// m_RoundScoreData -> m_iHealPoints
	{
		public get()
		{
			return GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 11);
		}
	}
	
	property int Assist
	{
		public get()
		{
			return Assist[view_as<int>(this)];
		}
		public set(int amount)
		{
			Assist[view_as<int>(this)] = amount;
		}
	}
	
	property int TotalAssist
	{
		public get()
		{
			return Assist[view_as<int>(this)]
				+ (200 * GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 2))	// m_iKills
				+ (500 * GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 12))	// m_iInvulns
				+ (100 * GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 13))	// m_iTeleports
				+ (50 * GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 17))	// m_iKillAssists
				+ (100 * GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 18));	// m_iBonusPoints
		}
	}
	
	property int Stabs	// m_RoundScoreData -> m_iBackstabs
	{
		public get()
		{
			return GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 10);
		}
		public set(int amount)
		{
			SDKCall_IncrementStat(view_as<int>(this), TFSTAT_BACKSTABS, amount - GetEntProp(view_as<int>(this), Prop_Send, "m_RoundScoreData", 4, 10));
		}
	}
	
	property int Index
	{
		public get()
		{
			return Index[view_as<int>(this)];
		}
		public set(int index)
		{
			Index[view_as<int>(this)] = index;
		}
	}
	
	public int GetDamage(int slot)
	{
		return Damage[view_as<int>(this)][slot + 1];
	}
	
	public void SetDamage(int slot, int damage)
	{
		Damage[view_as<int>(this)][slot + 1] = damage;
	}
	
	// Below are helper functions
	
	property int Lives
	{
		public get()
		{
			int lives = 1;
			this.Cfg.GetInt("livesleft", lives);
			return lives;
		}
		public set(int lives)
		{
			this.Cfg.SetInt("livesleft", lives);
		}
	}
	
	property int MaxLives
	{
		public get()
		{
			int lives = 1;
			this.Cfg.GetInt("lives", lives);
			return lives;
		}
		public set(int lives)
		{
			this.Cfg.SetInt("lives", lives);
		}
	}
	
	property int MaxHealth
	{
		public get()
		{
			int health = 1;
			if(!this.Cfg.GetInt("maxhealth", health) || health < 1)
				health = SDKCall_GetMaxHealth(view_as<int>(this));
			
			return health;
		}
		public set(int health)
		{
			this.Cfg.SetInt("maxhealth", health);
		}
	}
	
	property int Health
	{
		public get()
		{
			int health = GetClientHealth(view_as<int>(this));
			if(this.IsBoss)
			{
				int lives = this.Lives;
				if(lives > 1)
					health += this.MaxHealth * (lives - 1);
			}
			return health;
		}
		public set(int amount)
		{
			int health = amount;
			if(this.IsBoss)
			{
				int lives = this.Lives;
				if(lives > 1)
					health -= this.MaxHealth * (lives - 1);
			}
			SetEntityHealth(view_as<int>(this), health);
		}
	}
	
	property float RageDamage
	{
		public get()
		{
			float amount = 0.0;
			this.Cfg.GetFloat("ragedmg", amount);
			return amount;
		}
		public set(float amount)
		{
			this.Cfg.SetFloat("ragedmg", amount);
		}
	}
	
	property float RageMin
	{
		public get()
		{
			float amount = 100.0;
			this.Cfg.GetFloat("ragemin", amount);
			return amount;
		}
		public set(float amount)
		{
			this.Cfg.SetFloat("ragemin", amount);
		}
	}
	
	property float RageMax
	{
		public get()
		{
			float amount = 100.0;
			this.Cfg.GetFloat("ragemax", amount);
			return amount;
		}
		public set(float amount)
		{
			this.Cfg.SetFloat("ragemax", amount);
		}
	}
	
	property int RageMode
	{
		public get()
		{
			int value = 0;
			this.Cfg.GetInt("ragemode", value);
			return value;
		}
		public set(int value)
		{
			this.Cfg.SetInt("ragemode", value);
		}
	}
	
	property bool BlockVo
	{
		public get()
		{
			bool value;
			this.Cfg.GetBool("sound_block_vo", value, false);
			return value;
		}
		public set(bool value)
		{
			this.Cfg.SetInt("sound_block_vo", value ? 1 : 0);
		}
	}
	
	property bool Crits
	{
		public get()
		{
			bool value = true;
			this.Cfg.GetBool("crits", value, false);
			return value;
		}
		public set(bool value)
		{
			this.Cfg.SetInt("crits", value ? 1 : 0);
		}
	}
	
	property bool Triple
	{
		public get()
		{
			bool value;
			this.Cfg.GetBool("triple", value, false);
			return value;
		}
		public set(bool value)
		{
			this.Cfg.SetInt("triple", value ? 1 : 0);
		}
	}
	
	property int Knockback
	{
		public get()
		{
			int value = 0;
			this.Cfg.GetInt("knockback", value);
			return value;
		}
		public set(int value)
		{
			this.Cfg.SetInt("knockback", value);
		}
	}
	
	property int Pickups
	{
		public get()
		{
			int value = 0;
			this.Cfg.GetInt("pickups", value);
			return value;
		}
		public set(int value)
		{
			this.Cfg.SetInt("pickups", value);
		}
	}
	
	property float LastStabTime
	{
		public get()
		{
			float time = 0.0;
			this.Cfg.GetFloat("laststabtime", time);
			return time;
		}
		public set(float time)
		{
			this.Cfg.SetFloat("laststabtime", time);
		}
	}
	
	property float LastTriggerDamage
	{
		public get()
		{
			float amount = 0.0;
			this.Cfg.GetFloat("lasttriggerdamage", amount);
			return amount;
		}
		public set(float amount)
		{
			this.Cfg.SetFloat("lasttriggerdamage", amount);
		}
	}
	
	property float LastTriggerTime
	{
		public get()
		{
			float time = 0.0;
			this.Cfg.GetFloat("lasttriggertime", time);
			return time;
		}
		public set(float time)
		{
			this.Cfg.SetFloat("lasttriggertime", time);
		}
	}
	
	property int KillSpree
	{
		public get()
		{
			int amount;
			this.Cfg.GetInt("killspree", amount);
			return amount;
		}
		public set(int amount)
		{
			this.Cfg.SetInt("killspree", amount);
		}
	}
	
	property float LastKillTime
	{
		public get()
		{
			float time = 0.0;
			this.Cfg.GetFloat("lastkilltime", time);
			return time;
		}
		public set(float time)
		{
			this.Cfg.SetFloat("lastkilltime", time);
		}
	}
	
	property float PassiveAt
	{
		public get()
		{
			float time = 0.0;
			this.Cfg.GetFloat("passivetimeat", time);
			return time;
		}
		public set(float time)
		{
			this.Cfg.SetFloat("passivetimeat", time);
		}
	}
	
	property bool Speaking
	{
		public get()
		{
			bool value;
			this.Cfg.GetBool("speaking", value);
			return value;
		}
		public set(bool value)
		{
			this.Cfg.SetInt("speaking", value ? 1 : 0);
		}
	}
	
	property int RPSHit
	{
		public get()
		{
			int value;
			this.Cfg.GetInt("rpshit", value);
			return value;
		}
		public set(int value)
		{
			this.Cfg.SetInt("rpshit", value);
		}
	}
	
	property int RPSDamage
	{
		public get()
		{
			int value;
			this.Cfg.GetInt("rpsdmg", value);
			return value;
		}
		public set(int value)
		{
			this.Cfg.SetInt("rpsdmg", value);
		}
	}
	
	property float RageDebuff
	{
		public get()
		{
			float value = 1.0;
			this.Cfg.GetFloat("ragedebuff", value);
			return value;
		}
		public set(float value)
		{
			this.Cfg.SetFloat("ragedebuff", value);
		}
	}
	
	public float GetCharge(int slot)
	{
		char buffer[8];
		FormatEx(buffer, sizeof(buffer), "charge%d", slot);
		
		float value;
		this.Cfg.GetFloat(buffer, value);
		return value;
	}
	
	public void SetCharge(int slot, float value)
	{
		char buffer[8];
		FormatEx(buffer, sizeof(buffer), "charge%d", slot);
		
		this.Cfg.SetFloat(buffer, value);
	}
	
	public void ResetByDeath()
	{
		this.GlowFor = 0.0;
		this.Minion = false;
	}
	
	public void ResetByRound()
	{
		this.Damage = 0;
		this.Assist = 0;
		this.TotalDamage = 0;
		this.SetDamage(TFWeaponSlot_Primary, 0);
		this.SetDamage(TFWeaponSlot_Secondary, 0);
		this.SetDamage(TFWeaponSlot_Melee, 0);
		this.SetDamage(TFWeaponSlot_Grenade, 0);
		this.SetDamage(TFWeaponSlot_Building, 0);
		
		this.ResetByDeath();
	}
	
	public void ResetByAll()
	{
		this.Queue = 0;
		this.NoMusic = false;
		this.MusicShuffle = false;
		this.NoVoice = false;
		this.NoDmgHud = false;
		this.NoHud = false;
		this.SetLastPlayed("");
		this.OverlayFor = 0.0;
		this.GlowFor = 0.0;
		this.Glowing = false;
		
		this.ResetByRound();
	}
}