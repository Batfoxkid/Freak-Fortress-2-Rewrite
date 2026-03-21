/*
	"rage_danmaku_condition"
	{
		"slot"		"0"	// Ability slot

		"conditions"
		{
			"28"	"15.0"	// Index and Duration
		}
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}


	"rage_danmaku_resupply"
	{
		"slot"			"0"	// Ability slot
		"difficulty"	"0"	// Difficulty increase
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_danmaku_resupply"
	{
		"vo/medic.mp3"	"medic"
		"vo/medic.mp3"	"soldier"
	}


	"special_danmaku_soul"
	{
		// Class to randomly swap to and their model
		// If model is blank, bonemerge is used instead
		"classes"
		{
			"soldier"	""
			"medic"		""
		}

		// Weapons to swap to, either randomly or based on class
		"weapons"
		{
			"0"
			{
				"1"
				{
					"name"	"tf_weapon_rocketlauncher"
					"index"	"205"
				}
			}
			"2"
			{
				"medic"
				{
					"name"	"tf_weapon_knife"
					"index"	"1003"
				}
			}
		}

		// Difficulty levels and modifiers to weapons
		"difficulty"
		{
			"basediff"	"1"		// Default starting difficulty
			"tracker"	"true"	// Raise and decrease difficulty per map with wins/losses

			"1"
			{
				"name"		"Normal"	// Display difficulty (support languages)
				"name_en"	"Normal"
				"health"	"1.0"	// Health multiplier

				"tf_weapon_rocketlauncher"
				{
					"attributes"
					{
						"fire rate bonus"	"0.9"
					}
				}
			}
			"2"
			{
				"name"		"Hard"
				"name_en"	"Hard"

				"tf_weapon_rocketlauncher"
				{
					"attributes"
					{
						"fire rate bonus"	"0.8"
					}
				}
			}
		}
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_difficulty_change"
	{
	}


	"special_danmaku_buffs"
	{
		// If a weapon is found, it will override the specific attribute (over FF2 weapon changes)
		// If "strip" is on, it will remove ALL attributes including FF2 weapon changes
		"CWX"
		{
		}
		"Indexes"
		{
		}
		"Classnames"
		{
		}
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}


	"special_danmaku_waves"
	{
		"time"			"(15*n)+60"	// Time between waves, n being current wave ("Wave 1/5" = 0)
		"maxwaves"		"5"			// Max number of waves, if over, boss loses
		"revivewave"	"true"		// If to revive players on wave end
		"revivemarkers"	"true"		// If to spaewn revive markers
		"revivelimit"	"2"			// Max number of revives per player
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_danmaku_wave"
	{
		"misc/halloween/clock_tick.wav"			"tick"
		"misc/halloween/strongman_bell_01.wav"	"end"
	}
	"sound_danmaku_killed"
	{
		"#misc/halloween/clock_tick.wav"		"revive"
		"#misc/halloween/strongman_bell_01.wav"	"dead"
	}


	"special_danmaku_killtrack"
	{
		"start"	"0"	// Starting amount of kills
		"plugin_name"	"ff2r_danmaku_abilities"
	}
*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <morecolors>
#include <adt_trie_sort>
#include <cfgmap>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define FAR_FUTURE		100000000.0

#include "freak_fortress_2/tf2tools.sp"

ConVar CvarDebug;
ConVar CvarFriendlyFire;
Handle SDKEquipWearable;
Database DataBase;
StringMap BossRank;

int PlayersAlive[TFTeam_MAXLimit];
bool SpecTeam;

bool RenderModified[MAXTF2PLAYERS];

#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/subplugin.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2items.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Blitzrkrieg Abilities",
	author		=	"Batfoxkid",
	description	=	"Where dm_playerdeath.mp3",
	version		=	PLUGIN_VERSION,
	url		=	"https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Attrib_PluginLoad();
	TF2Items_PluginLoad();
	TF2U_PluginLoad();
	TFED_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	if(!TranslationPhraseExists("Danmaku Difficulty Increased"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
	TF2Tools_PluginStart();
	
	if(TF2Tools_Loaded())
	{
		GameData gamedata = new GameData("sm-tf2.games");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		SDKEquipWearable = EndPrepSDKCall();
		if(!SDKEquipWearable)
			LogError("[Gamedata] Could not find RemoveWearable");
		
		delete gamedata;
	}
	else
	{
		GameData gamedata = new GameData("ff2");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetVirtual(gamedata.GetOffset("CBasePlayer::EquipWearable"));
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		SDKEquipWearable = EndPrepSDKCall();
		if(!SDKEquipWearable)
			LogError("[Gamedata] Could not find CBasePlayer::EquipWearable");
		
		delete gamedata;
	}
	
	Attrib_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	VScript_PluginStart();

	CvarFriendlyFire = FindConVar("mp_friendlyfire");
/*
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Post);
	HookEvent("teamplay_flag_event", OnFlagEvent, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
*/
	Subplugin_PluginStart();
	
	if(SQL_CheckConfig("ff2"))
	{
		Database.Connect(Database_Connected, "ff2");
	}
	else
	{
		char error[512];
		Database db = SQLite_UseDatabase("ff2", error, sizeof(error));
		Database_Connected(db, error, 0);
	}
}

void FF2R_PluginLoaded()
{
	CvarDebug = FindConVar("ff2_debug");
	
	// Lateload Support
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
			
			BossData cfg = FF2R_GetBossData(client);
			if(cfg)
				FF2R_OnBossCreated(client, cfg, false);
		}
	}
}

public void OnPluginEnd()
{
	if(Subplugin_Enabled())
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && FF2R_GetBossData(client))
				FF2R_OnBossRemoved(client);
		}
	}
}

public void OnMapStart()
{
}

public void OnMapEnd()
{
	delete BossRank;
	//OnRoundEnd(null, NULL_STRING, false);
}

public void OnLibraryAdded(const char[] name)
{
	Attrib_LibraryAdded(name);
	Subplugin_LibraryAdded(name);
	TF2Tools_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	Subplugin_LibraryRemoved(name);
	TF2Tools_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
}

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	AbilityData ability = boss.GetAbility("special_danmaku_soul");
	if(ability.IsMyPlugin())
	{
		int difficulty = ability.GetInt("basediff", 1);
		
		char buffer[PLATFORM_MAX_PATH];
		boss.GetString("filename", buffer, sizeof(buffer));
		if(buffer[0])
		{
			if(setup)
			{
				if(ability.GetBool("tracker", true))
					CacheBossRank(buffer, DBPrio_High);
			}
			else if(BossRank)
			{
				BossRank.GetValue(buffer, difficulty);
			}
		}

		if(!setup)
		{
			ConfigData cfg = ability.GetSection("difficulty");
			if(cfg)
			{
				cfg = cfg.GetSection(buffer);
			}

			ChangeDifficulty(client, difficulty);
			EquipBoss(client);
		}
	}
}

public void FF2R_OnBossEquipped(int client, bool weapons)
{
	if(weapons)
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability = boss.GetAbility("special_danmaku_soul");
		if(ability.IsMyPlugin() && ability.GetInt("__currentdiff", -1) != -1)
		{
			EquipBoss(client);
		}
	}
}

public void FF2R_OnAbility(int client, const char[] name, AbilityData ability)
{
	if(!StrContains(name, "rage_danmaku_condition", false))
	{
		ConfigData conds = ability.GetSection("conditions");
		if(conds)
		{
			StringMapSnapshot snap = conds.Snapshot();

			int length = snap.Length;
			for(int i; i < length; i++)
			{
				int size = snap.KeyBufferSize(i) + 1;
				char[] key = new char[size];
				snap.GetKey(i, key, size);

				TF2_AddCondition(client, view_as<TFCond>(StringToInt(key)), conds.GetFloat(key, TFCondDuration_Infinite));
			}

			delete snap;
		}
	}
	else if(!StrContains(name, "rage_danmaku_resupply", false))
	{
		EquipBoss(client);

		int length = strlen(name) + 2;
		char[] buffer = new char[length];
		strcopy(buffer, length, name);
		ReplaceString(buffer, length, "rage_", "sound_", false);

		char classname[16];
		TF2Tools_GetClassName(TF2_GetPlayerClass(client), classname, sizeof(classname));
		FF2R_EmitBossSoundToAll(buffer, client, classname);
	}
}

public void FF2R_OnBossRemoved(int client)
{
	if(RenderModified[client])
	{
		SetEntityRenderFx(client, RENDERFX_NONE);
		RenderModified[client] = false;
	}
}

public void FF2R_OnAliveChanged2(const int[] alive, const int[] total, int teams)
{
	for(int i; i < teams && i < sizeof(PlayersAlive); i++)
	{
		PlayersAlive[i] = alive[i];
	}
	
	SpecTeam = (total[TFTeam_Unassigned] || total[TFTeam_Spectator]);
}

public void FF2R_OnBossPrecached(BossData boss, bool enabled, int index)
{
	if(enabled)
	{
		AbilityData ability = boss.GetAbility("special_danmaku_soul");
		if(ability.IsMyPlugin() && ability.GetBool("tracker", true))
		{
			char buffer[PLATFORM_MAX_PATH];
			boss.GetString("filename", buffer, sizeof(buffer));
			CacheBossRank(buffer);
		}
	}
}

public void OnClientPutInServer(int client)
{
}

public void OnClientDisconnect(int client)
{
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
}

public void OnEntityCreated(int entity, const char[] classname)
{
}

static void ChangeDifficulty(int client, int newdiff)
{
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility("special_danmaku_soul");
	
	int difficulty = ability.GetInt("__currentdiff", -1);
	if(difficulty != newdiff)
	{
		ConfigData cfgDiff = ability.GetSection("difficulty");
		if(cfgDiff)
		{
			// difficulty.1
			for(int a = newdiff; a >= 0; a--)
			{
				char buffer[64];
				IntToString(a, buffer, sizeof(buffer));
				cfgDiff = cfgDiff.GetSection(buffer);
				if(cfgDiff)
				{
					if(difficulty != a)
					{
						ability.SetInt("__currentdiff", a);

						char name[64];
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !IsFakeClient(i))
							{
								int lang = GetClientLanguage(client);
								if(GetBossNameCfg(boss, name, sizeof(name), lang) && GetBossNameCfg(cfgDiff, buffer, sizeof(buffer), lang))
								{
									FPrintToChatEx(i, client, "%t", difficulty == -1 ? "Danmaku Difficulty Set" : (a > difficulty) ? "Danmaku Difficulty Increased" : "Danmaku Difficulty Decreased", name, buffer);
								}
							}
						}
					}

					return;
				}
			}
		}
	}
}

static void EquipBoss(int client)
{
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility("special_danmaku_soul");

	int difficulty = ability.GetInt("__currentdiff");
	char classname[32], buffer[PLATFORM_MAX_PATH];
	
	ConfigData cfg = ability.GetSection("classes");
	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
		int length = snap.Length;
		if(length)
		{
			snap.GetKey(GetURandomInt() % length, classname, sizeof(classname));
			TFClassType class = TF2Tools_GetClass(classname);
			if(class != TF2_GetPlayerClass(client))
			{
				TF2_SetPlayerClass(client, class, false, false);

				cfg.GetString(classname, buffer, sizeof(buffer));
				if(strlen(buffer) > 4)
				{
					SetVariantString(buffer);
					AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
				}
				else
				{
					RenderFx render = GetEntityRenderFx(client);

					// Don't give a bonemerge wearable, assume there's already one already
					if(render != RENDERFX_FADE_FAST && render != RENDERFX_FADE_SLOW)
					{
						GetClientModel(client, buffer, sizeof(buffer));
						if(buffer[0])
						{
							// Apply a fake playermodel
							static WeaponData data;
							if(data.Index == 0)
								data.Setup("tf_wearable", -1);

							data.Worldmodel = PrecacheModel(buffer);
							int wearable = TF2Items_CreateFromStruct(client, data);
							if(wearable != -1)
							{
								SetEntityModel(wearable, buffer);
								SetEntityRenderFx(client, RENDERFX_FADE_FAST);
								RenderModified[client] = true;
							}
						}
					}

					SetVariantString(NULL_STRING);
					AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
				}
			}
		}

		delete snap;
	}

	cfg = ability.GetSection("weapons");
	if(cfg)
	{
		ConfigData cfgDiff = ability.GetSection("difficulty");
		if(cfgDiff)
		{
			// difficulty.1
			IntToString(difficulty, buffer, sizeof(buffer));
			cfgDiff = cfgDiff.GetSection(buffer);
		}
		
		TF2_RemoveAllItems(client);

		if(!classname[0])
			TF2Tools_GetClassName(TF2_GetPlayerClass(client), classname, sizeof(classname));

		bool equip = true;
		SortedSnapshot snapSlots = CreateSortedSnapshot(cfg);
		int lengthSlots = snapSlots.Length;
		for(int a; a < lengthSlots; a++)
		{
			snapSlots.GetKey(a, buffer, sizeof(buffer));

			// weapons.1
			ConfigData cfgSlot = cfg.GetSection(buffer);
			if(cfgSlot)
			{
				// weapons.1.medic
				ConfigData cfgWeapon = cfgSlot.GetSection(classname);

				if(!cfgWeapon)
				{
					StringMapSnapshot snap = cfgSlot.Snapshot();
					int length = snap.Length;
					if(length)
					{
						snap.GetKey(GetURandomInt() % length, buffer, sizeof(buffer));
						cfgWeapon = cfgSlot.GetSection(buffer);
					}

					delete snap;
				}

				if(cfgWeapon)
				{
					ArrayList cfgs = new ArrayList();
					cfgs.Push(cfgWeapon);

					static WeaponData data;
					TF2Items_StructFromCfg(data, "", cfgWeapon, true, equip, difficulty);

					if(cfgDiff)
					{
						// difficulty.1.tf_weapon
						ConfigData cfgMods = cfgDiff.GetSection(data.Classname);
						if(!cfgMods)
						{
							IntToString(data.Index, buffer, sizeof(buffer));
							cfgMods = cfgDiff.GetSection(buffer);
						}

						if(cfgMods)
						{
							cfgs.Push(cfgMods);
							TF2Items_StructFromCfg(data, data.Classname, cfgMods, false, equip, difficulty);
						}
					}

					TF2Items_CreateFromStruct(client, data, cfgs);
					delete cfgs;
					equip = data.Equip;
				}
			}
		}

		delete snapSlots;
	}
}

void CacheBossRank(const char[] filename, DBPriority priority = DBPrio_Normal)
{
	if(DataBase)
	{
		if(!BossRank || !BossRank.ContainsKey(filename))
		{
			char map[64];
			GetCurrentMap(map, sizeof(map));

			Transaction tr = new Transaction();
			
			char buffer[512];
			DataBase.Format(buffer, sizeof(buffer), "SELECT rank FROM ff2_danmaku_v1 WHERE boss = '%s' AND map = '%s';", filename, map);
			tr.AddQuery(buffer);
			
			DataPack pack = new DataPack();
			pack.WriteString(map);
			pack.WriteString(filename);
			DataBase.Execute(tr, Database_CacheBossRank, Database_FailHandle, pack, priority);
		}
	}
}

bool UpdateBossRank(const char[] filename, int change)
{
	if(DataBase && change && BossRank && BossRank.ContainsKey(filename))
	{
		int value;
		BossRank.GetValue(filename, value);
		value += change;
		if(value > -5)
		{
			BossRank.SetValue(filename, value);
			
			char map[64];
			GetCurrentMap(map, sizeof(map));

			Transaction tr = new Transaction();
			
			char buffer[512];
			DataBase.Format(buffer, sizeof(buffer), "UPDATE ff2_danmaku_v1 SET rank = '%d' WHERE boss = '%s' AND map = '%s';", value, filename, map);
			tr.AddQuery(buffer);
			
			DataBase.Execute(tr, Database_Success, Database_Fail);
			return true;
		}
	}

	return false;
}

void Database_CacheBossRank(Database db, DataPack pack, int numQueries, DBResultSet[] results, any[] queryData)
{
	char map[64], buffer[512];

	pack.Reset();
	pack.ReadString(buffer, sizeof(buffer));
	if(GetCurrentMap(map, sizeof(map)) && StrEqual(map, buffer))
	{
		if(!BossRank)
			BossRank = new StringMap();
		
		pack.ReadString(buffer, sizeof(buffer));
		if(results[0].FetchRow())
		{
			BossRank.SetValue(buffer, results[0].FetchInt(0));
		}
		else
		{
			BossRank.SetValue(buffer, 0);

			Transaction tr = new Transaction();

			DataBase.Format(buffer, sizeof(buffer), "INSERT INTO ff2_danmaku_v1 (boss, map) VALUES ('%s', '%s')", buffer, map);
			tr.AddQuery(buffer);

			DataBase.Execute(tr, Database_Success, Database_Fail);
		}
	}

	delete pack;
}

void Database_Connected(Database db, const char[] error, any data)
{
	if(db)
	{
		Transaction tr = new Transaction();
		
		tr.AddQuery("CREATE TABLE IF NOT EXISTS ff2_danmaku_v1 ("
		... "boss TEXT NOT NULL, "
		... "map TEXT NOT NULL, "
		... "rank INTEGER NOT NULL DEFAULT 0);");
		
		db.Execute(tr, Database_SetupCallback, Database_FailHandle, db);
	}
	else
	{
		LogError("[Database] %s", error);
	}
}

void Database_SetupCallback(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	DataBase = data;
}

void Database_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
}

void Database_Fail(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[Database] %s", error);
}

void Database_FailHandle(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[Database] %s", error);
	CloseHandle(data);
}

float GetBossCharge(ConfigData cfg, const char[] slot, float defaul = 0.0)
{
	int length = strlen(slot)+7;
	char[] buffer = new char[length];
	Format(buffer, length, "charge%s", slot);
	return cfg.GetFloat(buffer, defaul);
}

void SetBossCharge(ConfigData cfg, const char[] slot, float amount)
{
	int length = strlen(slot)+7;
	char[] buffer = new char[length];
	Format(buffer, length, "charge%s", slot);
	cfg.SetFloat(buffer, amount);
}

bool GetBossNameCfg(ConfigData cfg, char[] buffer, int length, int lang = -1, const char[] string = "name")
{
	if(lang != -1)
	{
		GetLanguageInfo(lang, buffer, length);
		Format(buffer, length, "%s_%s", string, buffer);
		if(!cfg.GetString(buffer, buffer, length))
			cfg.GetString(string, buffer, length);
	}
	else
	{
		cfg.GetString(string, buffer, length);
	}
	
	return view_as<bool>(buffer[0]);
}

float Fabs(float value)
{
	if(value < 0.0)
		return -value;
	
	return value;
}

bool IsInvuln(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
{
	if(StrContains(classname, "tf_weapon_"))
	{
		return -1;
	}
	else if(!StrContains(classname, "tf_weapon_scattergun") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_primary") ||
	  !StrContains(classname, "tf_weapon_soda_popper") ||
	  !StrContains(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	  !StrContains(classname, "tf_weapon_particle_cannon") ||
	  !StrContains(classname, "tf_weapon_flamethrower") ||
	  !StrContains(classname, "tf_weapon_grenadelauncher") ||
	  !StrContains(classname, "tf_weapon_cannon") ||
	  !StrContains(classname, "tf_weapon_minigun") ||
	  !StrContains(classname, "tf_weapon_shotgun_primary") ||
	  !StrContains(classname, "tf_weapon_sentry_revenge") ||
	  !StrContains(classname, "tf_weapon_drg_pomson") ||
	  !StrContains(classname, "tf_weapon_shotgun_building_rescue") ||
	  !StrContains(classname, "tf_weapon_syringegun_medic") ||
	  !StrContains(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	  !StrContains(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_secondary") ||
	  !StrContains(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	  !StrContains(classname, "tf_weapon_buff_item") ||
	  !StrContains(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	  !StrContains(classname, "tf_weapon_laser_pointer") ||
	  !StrContains(classname, "tf_weapon_mechanical_arm") ||
	  !StrContains(classname, "tf_weapon_medigun") ||
	  !StrContains(classname, "tf_weapon_smg") ||
	  !StrContains(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_r"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

void ShowGameText(int client, const char[] icon = "leaderboard_streak", int color = 0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(client)
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	
	if(bf)
	{
		char message[512];
		SetGlobalTransTarget(client);
		VFormat(message, sizeof(message), buffer, 5);
		
		bf.WriteString(message);
		bf.WriteString(icon);
		bf.WriteByte(color);
		EndMessage();
	}
}

void SetControlPoint(bool enable)
{
	if(enable)
	{
		Debug("Unlocked Control Point");
		
		int entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "team_control_point")) != -1)
		{
			AcceptEntityInput(entity, "ShowModel");
			SetVariantInt(0);
			AcceptEntityInput(entity, "SetLocked");
		}
	}
	else
	{
		Debug("Locked Control Point");
		
		int entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "team_control_point")) != -1)
		{
			AcceptEntityInput(entity, "HideModel");
			SetVariantInt(1);
			AcceptEntityInput(entity, "SetLocked");
		}
	}
}

void ReactConcept(int client, const char[] string)
{
	SetVariantString("IsMvMDefender:1");
	AcceptEntityInput(client, "AddContext");
	SetVariantString(string);
	AcceptEntityInput(client, "SpeakResponseConcept");
	AcceptEntityInput(client, "ClearContext");
}

void ReactConceptEnemy(int notTeam, const char[] string)
{
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != notTeam)
		{
			ReactConcept(target, string);
		}
	}
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

stock int SDKCall_GetMaxHealth(int client)
{
	return client;
}

bool TF2_GetItem(int client, int &weapon, int &pos)
{
	static int maxWeapons;
	if(!maxWeapons)
		maxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(pos < 0)
		pos = 0;
	
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;
		
		if(weapon != -1)
		{
			if(GetEntProp(weapon, Prop_Send, "m_bDisguiseWeapon"))
				continue;
			
			return true;
		}
	}
	return false;
}

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2Tools_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2Tools_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

void TF2_RemoveAllItems(int client)
{
	int entity, i;
	while(TF2_GetItem(client, entity, i))
	{
		TF2_RemoveItem(client, entity);
	}
}

void TE_Particle(const char[] Name, float origin[3]=NULL_VECTOR, float start[3]=NULL_VECTOR, float angles[3]=NULL_VECTOR, int entindex=-1, int attachtype=-1, int attachpoint=-1, bool resetParticles=true, int customcolors=0, float color1[3]=NULL_VECTOR, float color2[3]=NULL_VECTOR, int controlpoint=-1, int controlpointattachment=-1, float controlpointoffset[3]=NULL_VECTOR, float delay=0.0)
{
	// find string table
	int tblidx = FindStringTable("ParticleEffectNames");
	if(tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}

	// find particle index
	static char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for(int i; i<count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if(StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}

	if(stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return;
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);

	if(entindex != -1)
		TE_WriteNum("entindex", entindex);

	if(attachtype != -1)
		TE_WriteNum("m_iAttachType", attachtype);

	if(attachpoint != -1)
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);

	TE_WriteNum("m_bResetParticles", resetParticles ? 1:0);
	if(customcolors)
	{
		TE_WriteNum("m_bCustomColors", customcolors);
		TE_WriteVector("m_CustomColors.m_vecColor1", color1);
		if(customcolors == 2)
			TE_WriteVector("m_CustomColors.m_vecColor2", color2);
	}

	if(controlpoint != -1)
	{
		TE_WriteNum("m_bControlPoint1", controlpoint);
		if(controlpointattachment != -1)
		{
			TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
		}
	}

	TE_SendToAll(delay);
}

public bool Trace_WorldOnly(int entity, int contentsMask)
{
	return !entity;
}

void FPrintToChatEx(int client, int author, const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2, author);
	CSendMessage(client, buffer2, author);
}

stock void Debug(const char[] buffer, any ...)
{
	if(CvarDebug.BoolValue)
	{
		char message[192];
		VFormat(message, sizeof(message), buffer, 2);
		PrintToChatAll("[FF2 DEBUG] %s", message);
		PrintToServer("[FF2 DEBUG] %s", message);
	}
}

void GetClassWeaponClassname(TFClassType class, char[] name, int length)
{
	if(!StrContains(name, "saxxy"))
	{ 
		switch(class)
		{
			case TFClass_Scout:			strcopy(name, length, "tf_weapon_bat");
			case TFClass_Pyro, TFClass_Heavy:	strcopy(name, length, "tf_weapon_fireaxe");
			case TFClass_DemoMan:			strcopy(name, length, "tf_weapon_bottle");
			case TFClass_Engineer:			strcopy(name, length, "tf_weapon_wrench");
			case TFClass_Medic:			strcopy(name, length, "tf_weapon_bonesaw");
			case TFClass_Sniper:			strcopy(name, length, "tf_weapon_club");
			case TFClass_Spy:			strcopy(name, length, "tf_weapon_knife");
			default:				strcopy(name, length, "tf_weapon_shovel");
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun"))
	{
		switch(class)
		{
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_shotgun_pyro");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_shotgun_hwg");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_shotgun_primary");
			default:		strcopy(name, length, "tf_weapon_shotgun_soldier");
		}
	}
}

int GetKillsOfWeaponRank(int rank = -1, int index = 0)
{
	switch(rank)
	{
		case 0:
		{
			return GetRandomInt(0, 9);
		}
		case 1:
		{
			return GetRandomInt(10, 24);
		}
		case 2:
		{
			return GetRandomInt(25, 44);
		}
		case 3:
		{
			return GetRandomInt(45, 69);
		}
		case 4:
		{
			return GetRandomInt(70, 99);
		}
		case 5:
		{
			return GetRandomInt(100, 134);
		}
		case 6:
		{
			return GetRandomInt(135, 174);
		}
		case 7:
		{
			return GetRandomInt(175, 224);
		}
		case 8:
		{
			return GetRandomInt(225, 274);
		}
		case 9:
		{
			return GetRandomInt(275, 349);
		}
		case 10:
		{
			return GetRandomInt(350, 499);
		}
		case 11:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(500, 748);
			}
			else
			{
				return GetRandomInt(500, 749);
			}
		}
		case 12:
		{
			if(index == 656)	// Holiday Punch
			{
				return 749;
			}
			else
			{
				return GetRandomInt(750, 998);
			}
		}
		case 13:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(750, 999);
			}
			else
			{
				return 999;
			}
		}
		case 14:
		{
			return GetRandomInt(1000, 1499);
		}
		case 15:
		{
			return GetRandomInt(1500, 2499);
		}
		case 16:
		{
			return GetRandomInt(2500, 4999);
		}
		case 17:
		{
			return GetRandomInt(5000, 7499);
		}
		case 18:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(7500, 7922);
			}
			else
			{
				return GetRandomInt(7500, 7615);
			}
		}
		case 19:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(7923, 8499);
			}
			else
			{
				return GetRandomInt(7616, 8499);
			}
		}
		case 20:
		{
			return GetRandomInt(8500, 9999);
		}
		default:
		{
			return GetRandomInt(0, 9999);
		}
	}
}

int GetKillsOfCosmeticRank(int rank = -1, int index = 0)
{
	switch(rank)
	{
		case 0:
		{
			if(index == 133 || index == 444 || index == 655)	// Gunboats, Mantreads, or Spirit of Giving
			{
				return 0;
			}
			else
			{
				return GetRandomInt(0, 14);
			}
		}
		case 1:
		{
			if(index == 133 || index == 444 || index == 655)	// Gunboats, Mantreads, or Spirit of Giving
			{
				return GetRandomInt(1, 2);
			}
			else
			{
				return GetRandomInt(15, 29);
			}
		}
		case 2:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(3, 4);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(3, 6);
			}
			else
			{
				return GetRandomInt(30, 49);
			}
		}
		case 3:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(5, 6);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(7, 11);
			}
			else
			{
				return GetRandomInt(50, 74);
			}
		}
		case 4:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(7, 9);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(12, 19);
			}
			else
			{
				return GetRandomInt(75, 99);
			}
		}
		case 5:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(10, 13);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(20, 27);
			}
			else
			{
				return  GetRandomInt(100, 134);
			}
		}
		case 6:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(14, 17);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(28, 36);
			}
			else
			{
				return GetRandomInt(135, 174);
			}
		}
		case 7:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(18, 22);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(37, 46);
			}
			else
			{
				return GetRandomInt(175, 249);
			}
		}
		case 8:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(23, 27);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(47, 56);
			}
			else
			{
				return GetRandomInt(250, 374);
			}
		}
		case 9:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(28, 34);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(57, 67);
			}
			else
			{
				return GetRandomInt(375, 499);
			}
		}
		case 10:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(35, 49);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(68, 78);
			}
			else
			{
				return GetRandomInt(500, 724);
			}
		}
		case 11:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(50, 74);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(79, 90);
			}
			else
			{
				return GetRandomInt(725, 999);
			}
		}
		case 12:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(75, 98);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(91, 103);
			}
			else
			{
				return GetRandomInt(1000, 1499);
			}
		}
		case 13:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return 99;
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(104, 119);
			}
			else
			{
				return GetRandomInt(1500, 1999);
			}
		}
		case 14:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(100, 149);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(120, 137);
			}
			else
			{
				return GetRandomInt(2000, 2749);
			}
		}
		case 15:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(150, 249);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(138, 157);
			}
			else
			{
				return GetRandomInt(2750, 3999);
			}
		}
		case 16:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(250, 499);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(158, 178);
			}
			else
			{
				return GetRandomInt(4000, 5499);
			}
		}
		case 17:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(500, 749);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(179, 209);
			}
			else
			{
				return GetRandomInt(5500, 7499);
			}
		}
		case 18:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(750, 783);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(210, 249);
			}
			else
			{
				return GetRandomInt(7500, 9999);
			}
		}
		case 19:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(784, 849);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(250, 299);
			}
			else
			{
				return GetRandomInt(10000, 14999);
			}
		}
		case 20:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(850, 999);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(300, 399);
			}
			else
			{
				return GetRandomInt(15000, 19999);
			}
		}
		default:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(0, 999);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(0, 399);
			}
			else
			{
				return GetRandomInt(0, 19999);
			}
		}
	}
}

int TotalPlayersAliveEnemy(int team = -1)
{
	int amount;
	for(int i = SpecTeam ? TFTeam_Unassigned : TFTeam_Red; i < TFTeam_MAX; i++)
	{
		if(i != team)
			amount += PlayersAlive[i];
	}
	
	return amount;
}

bool GetBossNameCfg(ConfigMap cfg, char[] buffer, int length, int lang = -1, const char[] string = "name")
{
	if(lang != -1)
	{
		GetLanguageInfo(lang, buffer, length);
		Format(buffer, length, "%s_%s", string, buffer);
		if(!cfg.Get(buffer, buffer, length) && !cfg.Get(string, buffer, length))
			buffer[0] = 0;
	}
	else if(!cfg.Get(string, buffer, length))
	{
		buffer[0] = 0;
	}
	
	ReplaceString(buffer, length, "\\n", "\n");
	ReplaceString(buffer, length, "\\t", "\t");
	ReplaceString(buffer, length, "\\r", "\r");
	return view_as<bool>(buffer[0]);
}