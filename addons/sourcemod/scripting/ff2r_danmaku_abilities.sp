/*
	"rage_danmaku_condition"
	{
		"slot"		"0"		// Ability slot
		"damage"	"1.5"	// Damage multiplier
		"duration"	"15.0"	// Damage multiplier duration
		"scare"		"400.0"	// Victim reaction range

		"conditions"
		{
			"28"	"15.0"	// Index and Duration
		}
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_danmaku_reaction"
	{
		"vo/heavy_sf13_magic_reac01.mp3"	"heavy"
	}


	"rage_danmaku_teleport"
	{
		"slot"			"0"		// Ability slot
		"charges"		"2"		// Teleports charges on ability
		"add"			"true"	// Add charges instead of overriding
		
		"button"		"11"			// Button type (11=M2, 13=Reload, 25=M3)
		"distance"		"9999.9"		// Maximum distance
		"oldparticle"	"ghost_smoke"	// Particle at old position
		"newparticle"	"ghost_smoke"	// Particle at new position
		"preserve"		"true"			// Preserve momentum
		"emptyclip"		"false"			// Empty current weapon's clip
		"delay"			"1.0"			// Attack delay
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_danmaku_teleport"
	{
		"buttons/blip1.wav"	""
	}


	"rage_danmaku_resupply"
	{
		"slot"			"0"			// Ability slot
		"difficulty"	"0"			// Difficulty increase
		"section"		"weapons"	// Section in special_danmaku_soul to give weapons
		"reequip"		"15.0"		// Equip again after time
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_danmaku_resupply"
	{
		"vo/medic_taunts08.mp3"		"medic"
		"vo/soldier_taunts16.mp3"	"soldier"
	}


	"special_danmaku_soul"
	{
		"projectiles"	"true"		// If to remove all owned projectiles on swap
		"killmelee"		"sawblade"	// Kill feed for melee
		"killrange"		"firedeath"	// Kill feed for ranged
		"rageonkill"	"5.0"		// RAGE gain on kill
		"critmulti"		"0.5"		// Crit damage multiplier

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
			"tracker"	"1"		// Raise and decrease difficulty per map with wins/losses (2 for mapless)

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

	"sound_danmaku_difficulty"
	{
		"mvm/mvm_warning.wav"	""
	}


	"special_danmaku_changes"
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
		"time"				"(15*w)+60"	// Time between waves, w being current wave ("Wave 1/5" = 0)
		"maxwaves"			"5"			// Max number of waves, if over, boss loses
		"resupply"			"true"		// Resupply bosses with danmaku souls on wave end
		"revivewave"		"true"		// If to revive players on wave end
		"revivemarkers"		"true"		// If to spawn revive markers
		"reviveshared"		"n"			// Shared number of revives for all players
		"revivepersonal"	"1"			// Max number of revives per player
		
		"plugin_name"	"ff2r_danmaku_abilities"
	}

	"sound_danmaku_wave"
	{
		"misc/halloween/clock_tick.wav"			"tick"
		"misc/halloween/strongman_bell_01.wav"	"end"
	}
	"sound_danmaku_killed"
	{
		"mvm/mvm_player_died.wav"	"revive"
		"#music/mvm_lost_wave.wav"	"dead"
	}


	"special_danmaku_killtrack"
	{
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
#tryinclude <tf_ontakedamage>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define FAR_FUTURE		100000000.0

#include "freak_fortress_2/tf2tools.sp"

static const char ReflectSound[][] =
{
	"mvm/melee_impacts/bottle_hit_robo01.wav",
	"mvm/melee_impacts/bottle_hit_robo02.wav",
	"mvm/melee_impacts/bottle_hit_robo03.wav"
};

#define WAVE_RESUPPLY		(1 << 0)
#define WAVE_REVIVEWAVE		(1 << 1)
#define WAVE_REVIVEMARKER	(1 << 2)

ConVar CvarFriendlyFire;
ConVar CvarTeutons;
ConVar CvarRankLose;
Handle SDKEquipWearable;
Database DataBase;
StringMap BossRank;
StringMap BossKills;
Handle SyncHudTele;
bool OTDLoaded;

int PlayersAlive[TFTeam_MAXLimit];
bool SpecTeam;
int CurrentDifficulty;

float DamageMulti[MAXTF2PLAYERS];
float DamageMultiFor[MAXTF2PLAYERS];
Handle EquipBossTimer[MAXTF2PLAYERS];
float CritDamageMulti[MAXTF2PLAYERS] = {1.0, ...};

int RenderModelRef[MAXTF2PLAYERS];

int CurrentWeaponChanger;
bool ShowWeaponChanges[MAXTF2PLAYERS];

bool KillTrack[MAXTF2PLAYERS];

int PointTeleports[MAXTF2PLAYERS];

char WaveTime[64];
int CurrentWave;
int WaveMax;
int WaveFlags;
int WaveRevives;
int WaveTeam;
int WaveSoundTarget;
int PlayerRevives[MAXTF2PLAYERS];
bool RespawnIdle[MAXTF2PLAYERS];
int WaveTimerRef = -1;
Handle WaveTimer;

#define OTD_LIBRARY	"tf_ontakedamage"
#define CUSTOM_ATTRIBS
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/customattrib.sp"
#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/subplugin.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2items.sp"
#include "freak_fortress_2/tf2tools.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"
#include "freak_fortress_2/core/weapons.sp"

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
	CustomAttrib_PluginLoad();
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
	CustomAttrib_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	VScript_PluginStart();
	Weapons_PluginStart();

	CvarFriendlyFire = FindConVar("mp_friendlyfire");
	SyncHudTele = CreateHudSynchronizer();

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Post);
	HookEvent("revive_player_complete", OnRevivePlayer, EventHookMode_Post);
	HookEvent("teamplay_round_start", OnRoundSetup, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);

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
	CvarTeutons = FindConVar("ff2_game_teutons");
	CvarRankLose = FindConVar("ff2_game_ranks_lose");
	
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
	if(WaveTimerRef != -1 && IsValidEntity(WaveTimerRef))
		AcceptEntityInput(WaveTimerRef, "Kill");

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
	for(int i; i < sizeof(ReflectSound); i++)
	{
		PrecacheSound(ReflectSound[i]);
	}
}

public void OnMapEnd()
{
	delete BossRank;
}

public void OnLibraryAdded(const char[] name)
{
	Attrib_LibraryAdded(name);
	CustomAttrib_LibraryAdded(name);
	Subplugin_LibraryAdded(name);
	TF2Tools_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	Weapons_LibraryAdded(name);

	if(!OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = true;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKUnhook(client, SDKHook_OnTakeDamage, PlayerTakeDamage);
		}
	}
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	CustomAttrib_LibraryRemoved(name);
	Subplugin_LibraryRemoved(name);
	TF2Tools_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	Weapons_LibraryRemoved(name);

	if(OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = false;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKHook(client, SDKHook_OnTakeDamage, PlayerTakeDamage);
		}
	}
}

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	PrintToChatAll("FF2R_OnBossCreated");
	AbilityData ability = boss.GetAbility("special_danmaku_soul");
	if(ability.IsMyPlugin())
	{
		CritDamageMulti[client] = ability.GetFloat("critmulti", 1.0);

		int difficulty;

		ConfigData cfg = ability.GetSection("difficulty");
		if(cfg)
		{
			char buffer[PLATFORM_MAX_PATH];
			boss.GetString("filename", buffer, sizeof(buffer));
			if(buffer[0])
			{
				if(setup)
				{
					int tracker = cfg.GetInt("tracker");
					if(tracker)
						CacheBossRank(buffer, tracker, DBPrio_High);
				}
				else if(BossRank)
				{
					BossRank.GetValue(buffer, difficulty);
				}
			}
		}

		if(!setup)
		{
			if(cfg)
			{
				difficulty += cfg.GetInt("basediff", 1);
				ChangeDifficulty(client, difficulty);
			}
			
			RemoveRenderMode(client, true);

			delete EquipBossTimer[client];
			EquipBossTimer[client] = CreateTimer(0.1, RequipTimer, client);
		}
	}

	if(!KillTrack[client])
	{
		ability = boss.GetAbility("special_danmaku_killtrack");
		if(ability.IsMyPlugin())
		{
			char buffer[PLATFORM_MAX_PATH];
			boss.GetString("filename", buffer, sizeof(buffer));
			if(buffer[0])
				CacheBossKills(buffer, DBPrio_High);
			
			KillTrack[client] = true;
		}
	}

	if(!setup && !CurrentWeaponChanger)
	{
		ability = boss.GetAbility("special_danmaku_changes");
		if(ability.IsMyPlugin())
		{
			CurrentWeaponChanger = client;

			for(int target = 1; target <= MaxClients; target++)
			{
				if(client != target && IsClientInGame(target) && IsPlayerAlive(target) && !FF2R_GetBossData(target) && !FF2R_GetClientMinion(target))
				{
					ShowWeaponChanges[target] = true;
					TF2_RemoveAllItems(target);
					
					int entity, i;
					while(TF2U_GetWearable(client, entity, i))
					{
						TF2Tools_RemoveWearable(client, entity);
					}

					TF2Tools_RegeneratePlayer(target);
				}
			}
		}
	}

	if(!setup && WaveTimerRef == -1 && !WaveRevives)
	{
		ability = boss.GetAbility("special_danmaku_waves");
		if(ability.IsMyPlugin())
		{
			WaveFlags = 0;
			WaveSoundTarget = client;
			WaveTeam = GetClientTeam(client) == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;

			ability.GetString("time", WaveTime, sizeof(WaveTime));
			if(WaveTime[0])
			{
				WaveMax = RoundFloat(GetFormula(ability, "maxwaves", 10.0, client));
				CurrentWave = 0;

				delete WaveTimer;
				WaveTimer = CreateTimer(10.0, ShowWaveCount, _, TIMER_REPEAT);
				TriggerTimer(WaveTimer);

				float time = ParseExpr(WaveTime, Formula_Danmaku);

				int entity = -1;
				while((entity = FindEntityByClassname(entity, "team_round_timer")) != -1)
				{
					SetVariantInt(0);
					AcceptEntityInput(entity, "ShowInHUD");
				}

				while((entity = FindEntityByClassname(entity, "game_round_win")) != -1)
				{
					RemoveEntity(entity);
				}

				CreateRoundTimer(time);
			}

			if(ability.GetBool("resupply", true))
				WaveFlags |= WAVE_RESUPPLY;

			if(ability.GetBool("revivewave", true))
				WaveFlags |= WAVE_REVIVEWAVE;

			if(ability.GetBool("revivemarkers", true))
				WaveFlags |= WAVE_REVIVEMARKER;
			
			WaveRevives = RoundToFloor(GetFormula(ability, "reviveshared", 0.0, client));
			int player = RoundFloat(GetFormula(ability, "revivepersonal", 0.0, client));

			for(int target = 1; target <= MaxClients; target++)
			{
				if(client != target && IsClientInGame(target) && IsPlayerAlive(target) && !FF2R_GetBossData(target))
					PlayerRevives[target] = player;
			}
		}
	}
}

public void FF2R_OnBossEquipped(int client, bool weapons)
{
	PrintToChatAll("FF2R_OnBossEquipped");
	if(weapons)
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability = boss.GetAbility("special_danmaku_soul");
		if(ability.IsMyPlugin() && ability.GetInt("__currentdiff", -1) != -1)
		{
			RemoveRenderMode(client, true);
			
			delete EquipBossTimer[client];
			EquipBossTimer[client] = CreateTimer(0.1, RequipTimer, client);
		}
	}
}

public void FF2R_OnAbility(int client, const char[] name, AbilityData ability)
{
	if(!StrContains(name, "rage_danmaku_condition", false))
	{
		DamageMulti[client] = ability.GetFloat("damage", 1.0);
		DamageMultiFor[client] = GetGameTime() + ability.GetFloat("duration");

		float scare = ability.GetFloat("scare");
		if(scare > 0.0)
		{
			scare *= scare;

			int team = GetClientTeam(client);
			char classname[16];
			float pos1[3], pos2[3];
			GetClientAbsOrigin(client, pos1);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(client != target && IsClientInGame(target) && !FF2R_GetBossData(target) && IsPlayerAlive(target) && !IsInvuln(target) && GetClientTeam(target) != team)
				{
					GetClientEyePosition(target, pos2);
					if(GetVectorDistance(pos1, pos2, true) < scare)
					{
						TF2Tools_GetClassName(TF2_GetPlayerClass(target), classname, sizeof(classname));
						FF2R_EmitBossSoundToAll("sound_danmaku_reaction", client, classname, target, SNDCHAN_VOICE, 90);
					}
				}
			}
		}

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

				TF2Tools_AddCondition(client, view_as<TFCond>(StringToInt(key)), conds.GetFloat(key, TFCondDuration_Infinite));
			}

			delete snap;
		}
	}
	else if(!StrContains(name, "rage_danmaku_resupply", false))
	{
		int difficulty = ability.GetInt("difficulty");
		if(difficulty)
		{
			AbilityData soul = FF2R_GetBossData(client).GetAbility("special_danmaku_soul");
			if(soul.IsMyPlugin())
				ChangeDifficulty(client, soul.GetInt("__currentdiff") + difficulty);
		}

		int length = strlen(name) + 2;
		char[] buffer = new char[length];
		ability.GetString("section", buffer, length, "weapons");
		EquipBoss(client, buffer);

		strcopy(buffer, length, name);
		ReplaceString(buffer, length, "rage_", "sound_", false);

		char classname[16];
		TF2Tools_GetClassName(TF2_GetPlayerClass(client), classname, sizeof(classname));
		FF2R_EmitBossSoundToAll(buffer, client, classname);

		float duration = ability.GetFloat("reequip");
		if(duration > 0.0)
		{
			delete EquipBossTimer[client];
			EquipBossTimer[client] = CreateTimer(duration, RequipTimer, client);
		}
	}
	else if(!StrContains(name, "rage_danmaku_teleport", false))
	{
		if(!PointTeleports[client])
		{
			AbilityData cfg = FF2R_GetBossData(client).GetAbility("special_mobility");
			if(cfg)
			{
				cfg.SetBool("incooldown", true);
				cfg.SetFloat("delayfor", GetGameTime() + 9999.9);
			}
		}

		if(ability.GetBool("add", true))
		{
			PointTeleports[client] += ability.GetInt("charges", 1);
		}
		else
		{
			PointTeleports[client] = ability.GetInt("charges", 1);
		}
	}
}

public void FF2R_OnBossRemoved(int client)
{
	RemoveRenderMode(client, false);

	if(CurrentWeaponChanger == client)
		CurrentWeaponChanger = 0;
	
	if(WaveSoundTarget == client)
		WaveSoundTarget = 0;
	
	DamageMultiFor[client] = 0.0;
	CritDamageMulti[client] = 1.0;
	delete EquipBossTimer[client];
	PointTeleports[client] = 0;

	if(KillTrack[client])
	{
		KillTrack[client] = false;

		char buffer[PLATFORM_MAX_PATH];
		FF2R_GetBossData(client).GetString("filename", buffer, sizeof(buffer));
		if(buffer[0])
			SyncBossKills(buffer);
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
		if(ability.IsMyPlugin())
		{
			ConfigData cfg = ability.GetSection("difficulty");
			if(cfg)
			{
				int tracker = cfg.GetInt("tracker");
				if(tracker)
				{
					char buffer[PLATFORM_MAX_PATH];
					boss.GetString("filename", buffer, sizeof(buffer));
					CacheBossRank(buffer, tracker);
				}
			}
		}

		ability = boss.GetAbility("special_danmaku_killtrack");
		if(ability.IsMyPlugin())
		{
			char buffer[PLATFORM_MAX_PATH];
			boss.GetString("filename", buffer, sizeof(buffer));
			CacheBossKills(buffer);
		}
	}
}

public void OnClientPutInServer(int client)
{
}

public void OnClientDisconnect(int client)
{
	RespawnIdle[client] = false;

	if(WaveFlags & WAVE_REVIVEMARKER)
		RemoveReviveMarker(client);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if(RespawnIdle[client] && (buttons || vel[0] || vel[1] || vel[2]))
	{
		TF2Tools_RemoveCondition(client, TFCond_DisguisedAsDispenser);
		TF2Tools_RemoveCondition(client, TFCond_UberchargedOnTakeDamage);
		TF2Tools_RemoveCondition(client, TFCond_MegaHeal);
	}

	if(PointTeleports[client])
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("rage_danmaku_teleport")))
		{
			if(IsPlayerAlive(client))
			{
				bool hud;
				int holding = ability.GetInt("_holding");
				int button = ability.GetInt("button", 11);
				float gameTime = GetGameTime();

				if(holding)
				{
					if(!(buttons & (1 << button)))
					{
						holding = 0;
						ability.SetInt("_holding", 0);
					}
				}
				else if(buttons & (1 << button))
				{
					hud = true;

					if(TryTeleport(client, ability))
					{
						holding = 1;

						PointTeleports[client]--;
						if(PointTeleports[client] < 1)
						{
							AbilityData cfg = boss.GetAbility("special_mobility");
							if(cfg)
							{
								cfg.SetBool("incooldown", true);
								cfg.SetFloat("delayfor", GetGameTime() + 1.0);
							}
						}
					}
					else
					{
						holding = 2;
						ClientCommand(client, "common/wpn_denyselect.wav");
					}

					ability.SetInt("_holding", holding);
				}
				
				if(!(buttons & IN_SCORE) && (hud || ability.GetFloat("hudin") < gameTime) && GameRules_GetRoundState() != RoundState_TeamWin)
				{
					if(PointTeleports[client])
					{
						ability.SetFloat("hudin", gameTime + 0.09);
						
						SetGlobalTransTarget(client);
						
						char help[32];
						if(holding)
						{
							strcopy(help, sizeof(help), "Boss Mobility Release");
						}
						else
						{
							FormatEx(help, sizeof(help), "Boss Click %d", button);
						}

						SetHudTextParams(-1.0, 0.88, 0.1, 255, holding ? 64 : 255, holding ? 64 : 255, 255);

						if(holding == 2)
						{
							ShowSyncHudText(client, SyncHudTele, "%t%t", "Danmaku Teleport Stuck", help);
						}
						else
						{
							ShowSyncHudText(client, SyncHudTele, "%t%t", holding ? "Danmaku Teleport Not Ready" : "Danmaku Teleport Ready", PointTeleports[client], help);
						}
					}
					else
					{
						ClearSyncHud(client, SyncHudTele);
					}
				}
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	Weapons_EntityCreated(entity, classname);

	if(!StrContains(classname, "tf_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawn);
	}
	else if(!StrContains(classname, "tf_wea") || !StrContains(classname, "tf2c_wea") || !StrContains(classname, "tf_powerup_bottle"))
	{
		SDKHook(entity, SDKHook_SpawnPost, WeaponSpawn);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	switch(cond)
	{
		case TFCond_DisguisedAsDispenser:
		{
			RespawnIdle[client] = false;
		}
	}
}

Action PlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CritType crit = (damagetype & DMG_CRIT) ? CritType_Crit : CritType_None;
	return TF2_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, crit);
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	Action action = Plugin_Continue;

	if(attacker > 0 && attacker <= MaxClients)
	{
		if((damagetype & DMG_CRIT) && CritDamageMulti[attacker] != 1.0)
		{
			damage *= CritDamageMulti[attacker];
			action = Plugin_Changed;	
		}

		if(DamageMultiFor[attacker] > GetGameTime())
		{
			damage *= DamageMulti[attacker];
			action = Plugin_Changed;	
		}
	}

	return action;
}

void OnInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		if(ShowWeaponChanges[client])
		{
			ShowWeaponChanges[client] = false;

			DataPack pack;
			CreateDataTimer(2.4, ShowWeaponChangeTimer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			pack.WriteCell(userid);
			pack.WriteCell(0);
		}
	}
}

void OnRoundSetup(Event event, const char[] namee, bool dontBroadcast)
{
	WaveTimerRef = -1;
	delete WaveTimer;
	WaveRevives = 0;
	WaveFlags = 0;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		PlayerRevives[client] = 0;
		ShowWeaponChanges[client] = false;
	}
}

void OnRoundEnd(Event event, const char[] namee, bool dontBroadcast)
{
	if(WaveTimerRef != -1 && IsValidEntity(WaveTimerRef))
		AcceptEntityInput(WaveTimerRef, "Pause");

	delete WaveTimer;

	int winner = event.GetInt("team");
	if(winner > TFTeam_Spectator)
	{
		float lose = (CvarRankLose ? CvarRankLose.FloatValue : 1.0);
		if(lose < 0.8)
			lose = 0.8;

		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				BossData boss = FF2R_GetBossData(client);
				AbilityData ability = boss.GetAbility("special_danmaku_soul");
				if(ability.IsMyPlugin())
				{
					ConfigData cfgDiff = ability.GetSection("difficulty");
					if(cfgDiff)
					{
						int tracker = cfgDiff.GetInt("tracker");
						if(tracker)
						{
							char name[64], message[64], map[64], buffer[PLATFORM_MAX_PATH];

							if(tracker > 1)
							{
								strcopy(buffer, sizeof(buffer), "_any");
							}
							else
							{
								GetCurrentMap(buffer, sizeof(buffer));
								GetMapDisplayName(buffer, map, sizeof(map));
								int pos = FindCharInString(map, '_');
								strcopy(map, sizeof(map), map[pos+1]);
								map[0] = CharToUpper(map[0]);
							}

							int change;
							int health, par;
							
							if(winner != GetClientTeam(client))
							{
								// Lost the round, increase by 1
								change = 1;
								strcopy(message, sizeof(message), "Danmaku Rank Increased");
							}
							else if(lose < 1.0)
							{
								// Only decrease if high health
								float maxhealth = float(boss.MaxHealth * boss.MaxLives);
								if(maxhealth < 1.0)
									maxhealth = 1.0;
								
								health = RoundToCeil((GetClientHealth(client) + (boss.MaxHealth * (boss.Lives - 1))) / maxhealth * 100.0);
								par = RoundToCeil((float(boss.MaxHealth * boss.MaxLives) * (1.0 - lose)) / maxhealth * 100.0);

								if(health >= par)
								{
									change = -1;
									strcopy(message, sizeof(message), "Danmaku Rank Decreased Score");
								}
								else
								{
									strcopy(message, sizeof(message), "Danmaku Rank Saved Score");
								}
							}
							else
							{
								change = RoundToCeil(lose - 0.01);
								strcopy(message, sizeof(message), "Danmaku Rank Decreased");
							}

							if(tracker < 2)
								StrCat(message, sizeof(message), " Map");

							boss.GetString("filename", buffer, sizeof(buffer));

							if(change)
								UpdateBossRank(buffer, tracker, change);
							
							int value;
							if(BossRank && BossRank.GetValue(buffer, value))
							{
								IntToString(value + cfgDiff.GetInt("basediff", 1), name, sizeof(name));
								cfgDiff = cfgDiff.GetSection(name);

								if(cfgDiff)
								{
									for(int i = 1; i <= MaxClients; i++)
									{
										if(IsClientInGame(i) && !IsFakeClient(i))
										{
											int lang = GetClientLanguage(i);
											if(GetBossNameCfg(boss, name, sizeof(name), lang) && GetBossNameCfg(cfgDiff, buffer, sizeof(buffer), lang))
											{
												if(tracker < 2)
												{
													FPrintToChatEx(i, client, "%t", message, name, map, buffer, health, par);
												}
												else
												{
													FPrintToChatEx(i, client, "%t", message, name, buffer, health, par);
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

void RemoveRenderMode(int client, bool models)
{
	if(RenderModelRef[client] != -1)
	{
		int entity = EntRefToEntIndex(RenderModelRef[client]);
		if(entity == -1)
			TF2Tools_RemoveWearable(client, entity);
		
		if(models)
		{
			BossData boss = FF2R_GetBossData(client);
			if(boss)
			{
				char model[PLATFORM_MAX_PATH];
				boss.GetString("model", model, sizeof(model));
				if(model[0])
				{
					SetVariantString(model);
					AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
				}
			}
		}

		SetEntityRenderMode(client, RENDER_NORMAL);
		RenderModelRef[client] = -1;
	}
}

Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim)
	{
		RemoveRenderMode(victim, true);

		if(WaveFlags & WAVE_REVIVEMARKER)
		{
			if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
			{
				if(victim && GetClientTeam(victim) == WaveTeam && !FF2R_GetBossData(victim) && FF2R_GetClientMinion(victim) != 2)
				{
					if(WaveRevives > 0 || PlayerRevives[victim] > 0)
					{
						int entity = CreateEntityByName("entity_revive_marker");
						if(entity != -1)
						{
							float pos[3], ang[3];
							GetClientAbsOrigin(victim, pos);
							GetClientAbsAngles(victim, ang);
							pos[2] += 50.0;
							
							TeleportEntity(entity, pos, ang);
							SetEntPropEnt(entity, Prop_Send, "m_hOwner", victim);
							SetEntProp(entity, Prop_Send, "m_iTeamNum", WaveTeam);
							SetEntProp(entity, Prop_Send, "m_nBody", GetEntProp(victim, Prop_Send, "m_iClass") - 1); 
							DispatchSpawn(entity);

							if(!CvarTeutons || !CvarTeutons.BoolValue)
							{
								static int offset;
								if(!offset)
									offset = FindSendPropInfo("CTFPlayer", "m_nForcedSkin");
								
								SetEntDataEnt2(victim, offset + 4, entity);	// m_hReviveMarker
							}
						}

						if(WaveSoundTarget)
							FF2R_EmitBossSoundToClient(victim, "sound_danmaku_killed", WaveSoundTarget, "revive");
					}
					else if(WaveSoundTarget)
					{
						FF2R_EmitBossSoundToClient(victim, "sound_danmaku_killed", WaveSoundTarget, "dead", .volume = 1.0);
					}
				}
			}
		}
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker)
	{
		BossData boss = FF2R_GetBossData(attacker);
		if(boss)
		{
			if(KillTrack[attacker] && BossKills)
			{
				char buffer[PLATFORM_MAX_PATH];
				FF2R_GetBossData(attacker).GetString("filename", buffer, sizeof(buffer));
				if(buffer[0])
				{
					int kills;
					if(BossKills.GetValue(buffer, kills))
					{
						kills++;
						BossKills.SetValue(buffer, kills);

						int entity, i;
						while(TF2_GetItem(attacker, entity, i))
						{
							ApplyKillStrange(entity, kills);
						}
						
						i = 0;
						while(TF2U_GetWearable(attacker, entity, i))
						{
							ApplyKillStrange(entity, kills);
						}
					}
				}
			}

			AbilityData ability = boss.GetAbility("special_danmaku_soul");
			if(ability.IsMyPlugin())
			{
				char buffer[64];

				if(event.GetInt("damagebits") & (DMG_CLUB|DMG_SLASH))
				{
					ability.GetString("killmelee", buffer, sizeof(buffer));
				}
				else
				{
					ability.GetString("killrange", buffer, sizeof(buffer));
				}

				if(buffer[0])
					event.SetString("weapon", buffer);
				
				event.SetString("weapon_logclassname", "special_danmaku_soul");

				float rage = ability.GetFloat("rageonkill");
				if(rage > 0.0)
				{
					float current = GetBossCharge(boss, "0");
					float maxrage = boss.RageMax;
					if(current < maxrage)
					{
						current += rage;
						if(current > maxrage)
							current = maxrage;
						
						SetBossCharge(boss, "0", current);
					}
				}

				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

void OnRevivePlayer(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("entindex");
	if(client < 1 || client >= MaxClients)
		return;

	int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(entity != -1 && HasEntProp(entity, Prop_Send, "m_hHealingTarget"))
	{
		int target = GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget");
		if(target == -1)
		{
			target = GetEntPropEnt(target, Prop_Send, "m_hOwner");
			if(target > 0 && target <= MaxClients)
			{
				RevivePlayer(target, false);
			}
		}
	}
}

void CreateRoundTimer(float time)
{
	if(WaveTimerRef != -1 && IsValidEntity(WaveTimerRef))
		RemoveEntity(WaveTimerRef);
	
	int entity = CreateEntityByName("team_round_timer");
	if(entity != -1)
	{
		DispatchKeyValueFloat(entity, "timer_length", time);
		DispatchKeyValueFloat(entity, "max_length", time);
		DispatchKeyValueInt(entity, "start_paused", false);
		DispatchKeyValueInt(entity, "auto_countdown", false);

		DispatchSpawn(entity);

		SetVariantInt(1);
		AcceptEntityInput(entity, "ShowInHUD");
		AcceptEntityInput(entity, "Resume");

		HookSingleEntityOutput(entity, "On5SecRemain", WaveTimerTick);
		HookSingleEntityOutput(entity, "On4SecRemain", WaveTimerTick);
		HookSingleEntityOutput(entity, "On3SecRemain", WaveTimerTick);
		HookSingleEntityOutput(entity, "On2SecRemain", WaveTimerTick);
		HookSingleEntityOutput(entity, "On1SecRemain", WaveTimerTick);
		HookSingleEntityOutput(entity, "OnFinished", WaveTimerFinish);
		
		WaveTimerRef = EntIndexToEntRef(entity);
	}
}

void WaveTimerTick(const char[] output, int caller, int activator, float delay)
{
	if(WaveSoundTarget)
		FF2R_EmitBossSoundToAll("sound_danmaku_wave", WaveSoundTarget, "tick", .volume = 1.0);
}

void WaveTimerFinish(const char[] output, int caller, int activator, float delay)
{
	if(WaveSoundTarget)
		FF2R_EmitBossSoundToAll("sound_danmaku_wave", WaveSoundTarget, "end", .volume = 1.0);
	
	CurrentWave++;
	if(CurrentWave < WaveMax)
	{
		if(WaveTimer)
			TriggerTimer(WaveTimer, true);
		
		CreateRoundTimer(ParseExpr(WaveTime, Formula_Danmaku));

		bool revives = WaveRevives > 0;
		
		int count, alive;
		int[][] dead = new int[MaxClients][3];
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				BossData boss = FF2R_GetBossData(client);

				if(WaveFlags & WAVE_RESUPPLY)
				{
					if(boss)
					{
						AbilityData ability = boss.GetAbility("special_danmaku_soul");
						if(ability.IsMyPlugin())
							EquipBoss(client);
					}
					else
					{
						for(int i = 1; i < 4; i++)
						{
							GivePlayerAmmo(client, 499, i, true);
						}

						TF2Tools_AddCondition(client, TFCond_HalloweenQuickHeal, 3.0);
					}
				}
				
				if(WaveFlags & WAVE_REVIVEWAVE)
				{
					int team = GetClientTeam(client);
					if(team == WaveTeam)
					{
						if(IsPlayerAlive(client) && FF2R_GetClientMinion(client) != 2)
						{
							alive = client;
						}
						else if(!boss)
						{
							dead[count][0] = client;
							dead[count][1] = FF2R_GetClientScore(client);
							dead[count][2] = alive;

							if(IsPlayerAlive(client))
							{
								dead[count][2] = client;
							}
							else if(IsClientObserver(client))
							{
								int observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
								if(observing > 0 && observing <= MaxClients)
								{
									if(IsPlayerAlive(observing) && GetClientTeam(observing) == team && FF2R_GetClientMinion(observing) != 2)
										dead[count][2] = observing;
								}
							}

							count++;
						}
					}
				}
			}
		}

		if(count)
		{
			SortCustom2D(dead, count, Sort_HighRight);

			int entity = -1;
			while((entity = FindEntityByClassname(entity, "entity_revive_marker")) != -1)
			{
				RemoveEntity(entity);
			}

			for(int i; i < count; i++)
			{
				int client = dead[i][0];

				if(WaveRevives > 0 || PlayerRevives[client] > 0)
				{
					if(IsPlayerAlive(client))
						ForcePlayerSuicide(client);
					
					TF2Tools_RespawnPlayer(client);

					RevivePlayer(client, true, !revives);

					int target = dead[i][2];
					if(!target)
						target = alive;
					
					if(target)
					{
						float pos[3];
						GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
						TeleportEntity(client, pos, _, {0.0, 0.0, 0.0});
					}

					ClientCommand(client, "playgamesound mvm/mvm_revive.wav");
				}
			}

			if(revives)
				ShowTeamRevives();
		}
	}
	else
	{
		delete WaveTimer;
		
		int entity = FindEntityByClassname(-1, "game_round_win");
		if(entity == -1)
		{
			entity = CreateEntityByName("game_round_win");
			if(entity != -1)
			{
				DispatchKeyValue(entity, "force_map_reset", "1");
				DispatchSpawn(entity);
			}
		}

		if(entity != -1)
		{
			SetVariantInt(WaveTeam);
			AcceptEntityInput(entity, "SetTeam");
			AcceptEntityInput(entity, "RoundWin");
		}

		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != WaveTeam)
				ForcePlayerSuicide(client);
		}
	}
}

void ShowTeamRevives()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == WaveTeam)
			ShowGameText(client, _, 2, "%t", "Danmaku Team Revives", WaveRevives);
	}
}

void ShowPlayerRevives(int client, bool forceWaves = false)
{
	if(WaveRevives > 0 || forceWaves)
	{
		ShowGameText(client, _, 2, "%t", "Danmaku Team Revives", WaveRevives);
	}
	else
	{
		ShowGameText(client, _, 2, "%t", "Danmaku Player Revives", PlayerRevives[client]);
	}
}

void RevivePlayer(int client, bool waves, bool msg = true)
{
	SetEntProp(client, Prop_Send, "m_bDucked", true);
	SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);

	if(TF2Tools_Loaded())
	{
		RespawnIdle[client] = true;
		TF2Tools_AddCondition(client, TFCond_HalloweenKartNoTurn, waves ? 2.0 : 1.0);
		TF2Tools_AddCondition(client, TFCond_DisguisedAsDispenser, 10.0);
		TF2Tools_AddCondition(client, TFCond_UberchargedOnTakeDamage, 10.0);
		TF2Tools_AddCondition(client, TFCond_MegaHeal, 10.0);
		SDKHook(client, SDKHook_OnTakeDamage, ReviveTakeDamage);
	}
	
	if(WaveRevives > 0)
	{
		WaveRevives--;
		if(msg)
			ShowPlayerRevives(client, true);
	}
	else
	{
		PlayerRevives[client]--;
		if(msg)
			ShowPlayerRevives(client);

		if(PlayerRevives[client] < 1)
			TF2Tools_AddCondition(client, TFCond_MarkedForDeath);
	}
}

Action ReviveTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(RespawnIdle[victim])
	{
		if(attacker > MaxClients && damage > 10.0)
		{
			int team = GetClientTeam(victim);
			
			for(int target = MaxClients; target > 0; target--)
			{
				if(!RespawnIdle[target] && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == team)
				{
					float pos[3];
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
					TeleportEntity(target, pos);
					return Plugin_Handled;
				}
			}
		}
	}
	else
	{
		SDKUnhook(victim, SDKHook_OnTakeDamage, ReviveTakeDamage);
	}
	return Plugin_Continue;
}

void RemoveReviveMarker(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "entity_revive_marker")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwner") == client)
		{
			RemoveEntity(entity);
			break;
		}
	}
}

Action ShowWaveCount(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
			SendDialogToOne(client, {0, 255, 0, 255}, "%t", "Danmaku Waves", CurrentWave + 1, WaveMax);
	}
	return Plugin_Continue;
}

Action ShowWeaponChangeTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		int slot = pack.ReadCell();

		int weapon = TF2U_GetPlayerLoadoutEntity(client, slot);
		if(weapon != -1)
			Weapons_ShowChanges(client, weapon);
		
		if(slot < 3)
			GivePlayerAmmo(client, 499, slot + 1, true);
		
		if(slot < 6)
		{
			pack.Position--;
			pack.WriteCell(slot + 1, false);
			return Plugin_Continue;
		}
	}

	return Plugin_Stop;
}

// From sarysa
bool TryTeleport(int client, ConfigData ability)
{
	float size = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	float startPos[3], endPos[3], testPos[3], tmpPos[3];
	int team = GetClientTeam(client);
	GetClientEyePosition(client, startPos);
	GetClientEyeAngles(client, tmpPos);
	TR_TraceRayFilter(startPos, tmpPos, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_TeamPlayers, team);
	TR_GetEndPosition(endPos);

	// don't even try if the distance is less than 82
	float distance = GetVectorDistance(startPos, endPos);
	if(distance < 82.0)
		return false;
	
	float maxDist = ability.GetFloat("distance", 9999.9);
	
	if(maxDist > (distance - 1.0))
		maxDist = distance - 1.0;	// shave just a tiny bit off the end position so our point isn't directly on top of a wall
	
	ConstrainDistance(startPos, endPos, distance, maxDist);
		
	float mins[3] = {-24.0, -24.0, 0.0};
	float maxs[3] = {24.0, 24.0, 82.0};
	ScaleVector(mins, size);
	ScaleVector(maxs, size);
	
	// now for the tests. I go 1 extra on the standard mins/maxs on purpose.
	bool found = false;
	for(int x; x < 3; x++)
	{
		if(found)
			break;

		float xOffset;
		if(x == 1)
		{
			xOffset = 12.5 * size;
		}
		else if(x != 0)
		{
			xOffset = 25.0 * size;
		}
		
		if(endPos[0] < startPos[0])
		{
			testPos[0] = endPos[0] + xOffset;
		}
		else if(endPos[0] > startPos[0])
		{
			testPos[0] = endPos[0] - xOffset;
		}
		else if(xOffset != 0.0)
		{
			break; // super rare but not impossible, no sense wasting on unnecessary tests
		}
	
		for(int y; y < 3; y++)
		{
			if(found)
				break;

			float yOffset;
			if(y == 1)
			{
				yOffset = 12.5 * size;
			}
			else if(y != 0)
			{
				yOffset = 25.0 * size;
			}

			if(endPos[1] < startPos[1])
			{
				testPos[1] = endPos[1] + yOffset;
			}
			else if(endPos[1] > startPos[1])
			{
				testPos[1] = endPos[1] - yOffset;
			}
			else if(yOffset != 0.0)
			{
				break; // super rare but not impossible, no sense wasting on unnecessary tests
			}
		
			for(int z; z < 3; z++)
			{
				if(found)
					break;

				float zOffset;
				if(z == 1)
				{
					zOffset = 41.5 * size;
				}
				else if(z != 0)
				{
					zOffset = 83.0 * size;
				}

				if(endPos[2] < startPos[2])
				{
					testPos[2] = endPos[2] + zOffset;
				}
				else if(endPos[2] > startPos[2])
				{
					testPos[2] = endPos[2] - zOffset;
				}
				else if(zOffset != 0.0)
				{
					break; // super rare but not impossible, no sense wasting on unnecessary tests
				}

				// before we test this position, ensure it has line of sight from the point our player looked from
				// this ensures the player can't teleport through walls
				Handle trace = TR_TraceRayFilterEx(endPos, testPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceRay_WallsOnly);
				TR_GetEndPosition(tmpPos, trace);
				delete trace;

				if(testPos[0] != tmpPos[0] || testPos[1] != tmpPos[1] || testPos[2] != tmpPos[2])
					continue;
				
				// isspotstuck
				trace = TR_TraceHullFilterEx(testPos, testPos, mins, maxs, MASK_PLAYERSOLID, TraceRay_TeamPlayers, team);
				found = TR_DidHit(trace);
				delete trace;
			}
		}
	}
	
	if(!found)
		return false;
	
	TeleportEntity(client, testPos, _, ability.GetBool("preserve") ? NULL_VECTOR : {0.0, 0.0, 0.0});
	FF2R_EmitBossSoundToAll("sound_danmaku_teleport", client);

	char buffer[64];
	if(ability.GetString("oldparticle", buffer, sizeof(buffer)))
		ParticleEffectAt(startPos, buffer);
	
	if(ability.GetString("newparticle", buffer, sizeof(buffer)))
		ParticleEffectAt(testPos, buffer);
	
	// empty clip?
	if(ability.GetBool("emptyclip"))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			if(clip > 0)
			{
				int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
				if(type >= 0)
					SetEntProp(client, Prop_Data, "m_iAmmo", GetEntProp(client, Prop_Data, "m_iAmmo", _, type) + clip, _, type);
				
				SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
			}
		}
	}
	
	// attack delay?
	float delay = ability.GetFloat("delay");
	if(delay > 0.0)
	{
		delay += GetGameTime();
		
		float current = GetEntPropFloat(client, Prop_Send, "m_flNextAttack");
		if(delay > current)
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", delay);
	}
		
	return true;
}

void ChangeDifficulty(int client, int changediff)
{
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility("special_danmaku_soul");

	int newdiff = changediff;
	if(newdiff < 0)
		newdiff = 0;
	
	int difficulty = ability.GetInt("__currentdiff", -1);
	if(difficulty != newdiff)
	{
		ConfigData cfg = ability.GetSection("difficulty");
		if(cfg)
		{
			char name[64];

			// difficulty.1
			for(int a = newdiff; a >= 0; a--)
			{
				IntToString(a, name, sizeof(name));
				ConfigData cfgDiff = cfg.GetSection(name);
				if(cfgDiff)
				{
					if(difficulty != a)
					{
						ability.SetInt("__currentdiff", a);

						char buffer[256];
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !IsFakeClient(i))
							{
								int lang = GetClientLanguage(i);
								if(GetBossNameCfg(boss, name, sizeof(name), lang) && GetBossNameCfg(cfgDiff, buffer, sizeof(buffer), lang))
								{
									SetGlobalTransTarget(i);
									Format(buffer, sizeof(buffer), "%t", difficulty == -1 ? "Danmaku Difficulty Set" : (a > difficulty) ? "Danmaku Difficulty Increased" : "Danmaku Difficulty Decreased", name, buffer);
									FPrintToChatEx(i, client, buffer);

									CRemoveTags(buffer, sizeof(buffer));

									if(difficulty == -1)
									{
										DataPack pack;
										CreateDataTimer(2.5, DelayedGameText, pack, TIMER_FLAG_NO_MAPCHANGE);
										pack.WriteCell(GetClientUserId(i));
										pack.WriteString(buffer);
									}
									else
									{
										ShowGameText(client, "ico_notify_on_fire", 0, buffer);
									}
								}
							}
						}

						if(difficulty == -1)
						{
							float health = cfgDiff.GetFloat("health", 1.0);
							if(health != 1.0)
							{
								int maxhealth = RoundFloat(boss.MaxHealth * health);
								boss.MaxHealth = maxhealth;
								SetEntityHealth(client, maxhealth);
								FF2R_UpdateBossAttributes(client);
							}
						}
						else
						{
							FF2R_EmitBossSoundToAll("sound_danmaku_difficulty", client);
						}
					}

					return;
				}
			}
		}
	}
}

Action DelayedGameText(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		char buffer[256];
		pack.ReadString(buffer, sizeof(buffer));
		ShowGameText(client, "ico_notify_on_fire", 0, buffer);
	}

	return Plugin_Continue;
}

Action RequipTimer(Handle timer, int client)
{
	EquipBossTimer[client] = null;
	if(IsPlayerAlive(client))
		EquipBoss(client, _, false);
	
	return Plugin_Continue;
}

void EquipBoss(int client, const char[] section = "", bool dissolve = true)
{
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility("special_danmaku_soul");

	if(dissolve && ability.GetBool("projectiles", true))
		DissolveProjectiles(client);

	CurrentDifficulty = ability.GetInt("__currentdiff");
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
				FF2R_UpdateBossAttributes(client);

				cfg.GetString(classname, buffer, sizeof(buffer));
				if(strlen(buffer) > 4)
				{
					SetVariantString(buffer);
					AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
				}
				else
				{
					if(!IsValidEntity(RenderModelRef[client]))
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
								RenderModelRef[client] = EntIndexToEntRef(wearable);
								PrintToChatAll("DDDDD");
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

	cfg = ability.GetSection(section[0] ? section : "weapons");
	if(!cfg && section[0])
		cfg = ability.GetSection("weapons");
	
	if(cfg)
	{
		ConfigData cfgDiff = ability.GetSection("difficulty");
		if(cfgDiff)
		{
			// difficulty.1
			IntToString(CurrentDifficulty, buffer, sizeof(buffer));
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
					TF2Items_StructFromCfg(data, "", cfgWeapon, true, equip, Formula_Danmaku);

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
							TF2Items_StructFromCfg(data, data.Classname, cfgMods, false, equip, Formula_Danmaku);
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

void CacheBossRank(const char[] filename, int type, DBPriority priority = DBPrio_Normal)
{
	if(DataBase)
	{
		if(!BossRank || !BossRank.ContainsKey(filename))
		{
			char map[64];
			if(type > 1)
			{
				strcopy(map, sizeof(map), "_any");
			}
			else
			{
				GetCurrentMap(map, sizeof(map));
			}

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

bool UpdateBossRank(const char[] filename, int type, int change)
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
			if(type > 1)
			{
				strcopy(map, sizeof(map), "_any");
			}
			else
			{
				GetCurrentMap(map, sizeof(map));
			}

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
	char map[64], boss[PLATFORM_MAX_PATH], buffer[512];

	pack.Reset();
	pack.ReadString(buffer, sizeof(buffer));
	if(GetCurrentMap(map, sizeof(map)) && StrEqual(map, buffer))
	{
		if(!BossRank)
			BossRank = new StringMap();
		
		pack.ReadString(boss, sizeof(boss));
		if(results[0].FetchRow())
		{
			BossRank.SetValue(boss, results[0].FetchInt(0));
		}
		else
		{
			BossRank.SetValue(boss, 0);

			Transaction tr = new Transaction();

			DataBase.Format(buffer, sizeof(buffer), "INSERT INTO ff2_danmaku_v1 (boss, map) VALUES ('%s', '%s')", buffer, map);
			tr.AddQuery(buffer);

			DataBase.Execute(tr, Database_Success, Database_Fail);
		}
	}

	delete pack;
}

void CacheBossKills(const char[] filename, DBPriority priority = DBPrio_Normal)
{
	if(DataBase)
	{
		if(!BossKills || !BossKills.ContainsKey(filename))
		{
			Transaction tr = new Transaction();
			
			char buffer[512];
			DataBase.Format(buffer, sizeof(buffer), "SELECT kills FROM ff2_killtrack_v1 WHERE boss = '%s';", filename);
			tr.AddQuery(buffer);
			
			DataPack pack = new DataPack();
			pack.WriteString(filename);
			DataBase.Execute(tr, Database_CacheBossKills, Database_FailHandle, pack, priority);
		}
	}
}

void SyncBossKills(const char[] filename)
{
	if(DataBase && BossKills && BossKills.ContainsKey(filename))
	{
		int value;
		BossKills.GetValue(filename, value);

		Transaction tr = new Transaction();
		
		char buffer[512];
		DataBase.Format(buffer, sizeof(buffer), "UPDATE ff2_killtrack_v1 SET kills = '%d' WHERE boss = '%s';", value, filename);
		tr.AddQuery(buffer);
		
		DataBase.Execute(tr, Database_Success, Database_Fail);
	}
}

void Database_CacheBossKills(Database db, DataPack pack, int numQueries, DBResultSet[] results, any[] queryData)
{
	char boss[PLATFORM_MAX_PATH], buffer[512];

	pack.Reset();

	if(!BossKills)
		BossKills = new StringMap();
	
	pack.ReadString(boss, sizeof(boss));
	if(results[0].FetchRow())
	{
		BossKills.SetValue(boss, results[0].FetchInt(0));
	}
	else
	{
		BossKills.SetValue(boss, 0);

		Transaction tr = new Transaction();

		DataBase.Format(buffer, sizeof(buffer), "INSERT INTO ff2_killtrack_v1 (boss) VALUES ('%s')", buffer);
		tr.AddQuery(buffer);

		DataBase.Execute(tr, Database_Success, Database_Fail);
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
		
		tr.AddQuery("CREATE TABLE IF NOT EXISTS ff2_killtrack_v1 ("
		... "boss TEXT NOT NULL, "
		... "kills INTEGER NOT NULL DEFAULT 0);");
		
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

void WeaponSpawn(int entity)
{
	RequestFrame(WeaponSpawnFrame, EntIndexToEntRef(entity));
}

void WeaponSpawnFrame(int ref)
{
	if(BossKills)
	{
		int entity = EntRefToEntIndex(ref);
		if(entity != -1)
		{
			int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(client > 0 && client <= MaxClients && KillTrack[client])
			{
				char buffer[PLATFORM_MAX_PATH];
				FF2R_GetBossData(client).GetString("filename", buffer, sizeof(buffer));
				if(buffer[0])
				{
					int kills;
					BossKills.GetValue(buffer, kills);
					ApplyKillStrange(entity, kills);
				}
			}
		}
	}
}

void ApplyKillStrange(int weapon, int kills)
{
	Attrib_SetInt(weapon, "kill eater", 214, kills);
	if(HasEntProp(weapon, Prop_Send, "m_bDisguiseWearable"))
		Attrib_SetInt(weapon, "strange restriction type 1", 454, 64);
}

bool Weapons_ConfigEnabled()
{
	return CurrentWeaponChanger != 0;
}

ConfigMap FindMatchingLoadout()
{
	return FF2R_GetBossData(CurrentWeaponChanger).GetAbility("special_danmaku_changes");
}

void ProjectileSpawn(int entity)
{
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
	if(weapon == -1)
		return;
	
	float value;
	if(CustomAttrib_Get(weapon, "danmaku bounce", value))
		SDKHook(entity, SDKHook_StartTouch, ProjectileStartTouch);
	
	if(CustomAttrib_Get(weapon, "danmaku gravity", value))
	{
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value * GetTickInterval());
		RequestFrame(ProjectileGravityFrame, pack);
	}
	
	if(CustomAttrib_Get(weapon, "danmaku clock", value))
	{
		if(!GetEntProp(weapon, Prop_Send, "m_bFlipViewModel"))
			value = -value;

		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value * GetTickInterval());
		pack.WriteFloat(90.0);
		pack.WriteCell(0);
		RequestFrame(ProjectileClockFrame, pack);
	}
	else if(CustomAttrib_Get(weapon, "danmaku clock x", value))
	{
		if(!GetEntProp(weapon, Prop_Send, "m_bFlipViewModel"))
			value = -value;

		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value * GetTickInterval());
		pack.WriteFloat(90.0);
		pack.WriteCell(1);
		RequestFrame(ProjectileClockFrame, pack);
	}
	else if(CustomAttrib_Get(weapon, "danmaku clock y", value))
	{
		if(!GetEntProp(weapon, Prop_Send, "m_bFlipViewModel"))
			value = -value;

		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value * GetTickInterval());
		pack.WriteFloat(90.0);
		pack.WriteCell(2);
		RequestFrame(ProjectileClockFrame, pack);
	}
	
	if(CustomAttrib_Get(weapon, "danmaku ring", value))
	{
		int flip = GetEntProp(weapon, Prop_Send, "m_bFlipViewModel") != 0;
		if(flip)
			value = -value;
		
		float ang[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
		ang[1] += (flip ? 90.0 : -90.0);

		while(ang[1] > 360.0)
			ang[1] -= 360.0;

		while(ang[1] < 0.0)
			ang[1] += 360.0;

		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value * GetTickInterval());
		pack.WriteFloat(ang[1]);
		RequestFrame(ProjectileRingFrame, pack);
	}
	
	if(CustomAttrib_Get(weapon, "danmaku split", value))
	{
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat((entity % 2) ? value : -value);
		RequestFrame(ProjectileSplitFrame, pack);
	}
	
	if(CustomAttrib_Get(weapon, "danmaku drunk", value))
	{
		if(GetGameTickCount() % 2)
			value = -value;
		
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value * GetTickInterval());
		RequestFrame(ProjectileDrunkFrame, pack);
	}
	
	if(CustomAttrib_Get(weapon, "danmaku speedup", value))
	{
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(1.0 + ((value - 1.0) * GetTickInterval()));
		RequestFrame(ProjectileSpeedUpFrame, pack);
	}
	
	if(CustomAttrib_Get(weapon, "danmaku deviation", value))
	{
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteFloat(value);
		RequestFrame(ProjectileDeviationFrame, pack);
	}
}

Action ProjectileStartTouch(int entity, int target)
{
	if(IsEntityTarget(target))
		return Plugin_Continue;
	
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
	if(weapon == -1)
		return Plugin_Continue;
	
	float value;
	if(!CustomAttrib_Get(weapon, "danmaku bounce", value) || RoundFloat(value) <= GetEntProp(entity, Prop_Send, "m_iDeflected"))
		return Plugin_Continue;
	
	SDKHook(entity, SDKHook_Touch, ProjectileTouch);
	return Plugin_Handled;
}

Action ProjectileTouch(int entity, int target)
{
	float vec1[3], vec2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec1);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vec2);
	
	Handle trace = TR_TraceRayFilterEx(vec1, vec2, MASK_SHOT, RayType_Infinite, TraceRay_DontHitSelf, entity);
	if(!TR_DidHit(trace) || (TR_GetSurfaceFlags(trace) & SURF_SKY))
	{
		delete trace;
		return Plugin_Continue;
	}
	
	TR_GetPlaneNormal(trace, vec1);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vec2);
	delete trace;
	
	ScaleVector(vec1, GetVectorDotProduct(vec1, vec2) * 2.0);
	
	SubtractVectors(vec2, vec1, vec2);
	GetVectorAngles(vec2, vec1);
	
	TeleportEntity(entity, _, vec1, vec2);
	SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vec2);

	EmitSoundToAll(ReflectSound[GetURandomInt() % sizeof(ReflectSound)], entity, SNDCHAN_WEAPON, 70);

	SetEntProp(entity, Prop_Send, "m_iDeflected", GetEntProp(entity, Prop_Send, "m_iDeflected") + 1);
	SDKUnhook(entity, SDKHook_Touch, ProjectileTouch);
	return Plugin_Handled;
}

void ProjectileGravityFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity == -1)
	{
		delete pack;
		return;
	}

	float ang[3], vel[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
	vel[2] -= pack.ReadFloat();
	GetVectorAngles(vel, ang);
	TeleportEntity(entity, _, ang, vel);
	RequestFrame(ProjectileGravityFrame, pack);
}

void ProjectileClockFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity == -1)
	{
		delete pack;
		return;
	}

	float change = pack.ReadFloat();
	float current = pack.ReadFloat();	// 0.0 at top of the 'clock'
	int type = pack.ReadCell();

	float ang[3], vel[3];

	float x = current - 90.0;
	if(x > 180.0)
		x -= 180.0;
	
	if(x < 0.0)
		x += 180.0;
	
	x = Fabs(x - 90.0) / 90.0;
	x = change * x * 45.0;
	if(current < 180.0)	// Right of 'clock'
		x = -x;
	
	float y = current;
	if(y > 180.0)
		y -= 180.0;
	
	if(y < 0.0)
		y += 180.0;
	
	y = Fabs(y - 90.0) / 90.0;
	y = change * y * 45.0;
	if(current > 90.0 && current < 270.0)	// Bottom of 'clock'
		y = -y;
	
	GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ang);

	float fwd[3], right[3], up[3];
	GetVectorAngles(ang, fwd);
	GetAngleVectors(fwd, fwd, right, up);
	//PrintCenterTextAll("F %f %f %f\nR %f %f %f\nU %f %f %f", fwd[0], fwd[1], fwd[2], right[0], right[1], right[2], up[0], up[1], up[2]);

	for(int i; i < 3; i++)
	{
		vel[i] = Fabs(fwd[i]) * ang[i];
		if(type == 0 || type == 1)
			vel[i] += Fabs(right[i]) * x;
		
		if(type == 0 || type == 2)
			vel[i] += Fabs(up[i]) * y;
	}

	//PrintCenterTextAll("%f | %f %f", current, x, y);

	GetVectorAngles(vel, ang);
	TeleportEntity(entity, _, ang, vel);

	current += change;
	while(current > 360.0)
		current -= 360.0;
	
	while(current < 0.0)
		current += 360.0;
	
	pack.Position--;
	pack.Position--;
	pack.WriteFloat(current, false);
	RequestFrame(ProjectileClockFrame, pack);
}

void ProjectileRingFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity == -1)
	{
		delete pack;
		return;
	}

	float change = pack.ReadFloat();
	float current = pack.ReadFloat();	// 0.0 at top of the 'clock'

	float ang[3], vel[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);

	float x = current - 90.0;
	if(x > 180.0)
		x -= 180.0;
	
	if(x < 0.0)
		x += 180.0;
	
	x = Fabs(x - 90.0) / 90.0;
	x = change * x * 90.0;
	if(current > 180.0)	// Left of 'clock'
		x = -x;
	
	float y = current;
	if(y > 180.0)
		y -= 180.0;
	
	if(y < 0.0)
		y += 180.0;
	
	y = Fabs(y - 90.0) / 90.0;
	y = change * y * 90.0;
	if(current > 90.0 && current < 270.0)	// Bottom of 'clock'
		y = -y;
	
	GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ang);

	float fwd[3], right[3], up[3];
	GetVectorAngles(ang, fwd);
	GetAngleVectors(fwd, fwd, right, up);
	//PrintCenterTextAll("F %f %f %f\nR %f %f %f\nU %f %f %f", fwd[0], fwd[1], fwd[2], right[0], right[1], right[2], up[0], up[1], up[2]);
	
	for(int i; i < 2; i++)
	{
		float force = Fabs(fwd[i]);
		vel[i] = force * ang[i] * (0.35 + ((i ? y : x) / 277.0));
		vel[i] += (1.0 - force) * (i ? y : x);
	}

	GetVectorAngles(vel, ang);
	TeleportEntity(entity, _, ang, vel);

	current += change;
	while(current > 360.0)
		current -= 360.0;
	
	while(current < 0.0)
		current += 360.0;
	
	pack.Position--;
	pack.WriteFloat(current, false);
	RequestFrame(ProjectileRingFrame, pack);
}

void ProjectileSplitFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity != -1)
	{
		float change = pack.ReadFloat();

		float vel[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
		float speed = GetLinearVelocity(vel);

		float ang[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
		ang[1] += change;

		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vel, speed);
		TeleportEntity(entity, _, ang, vel);
	}
	delete pack;
}

void ProjectileDrunkFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity == -1)
	{
		delete pack;
		return;
	}

	float change = pack.ReadFloat();

	float vel[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
	float speed = GetLinearVelocity(vel);

	float ang[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
	ang[entity % 2] += change;

	GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vel, speed);
	TeleportEntity(entity, _, ang, vel);
	
	RequestFrame(ProjectileDrunkFrame, pack);
}

void ProjectileSpeedUpFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity == -1)
	{
		delete pack;
		return;
	}

	float change = pack.ReadFloat();

	float vel[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
	ScaleVector(vel, change);
	TeleportEntity(entity, _, _, vel);
	
	RequestFrame(ProjectileSpeedUpFrame, pack);
}

void ProjectileDeviationFrame(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity != -1)
	{
		float change = pack.ReadFloat();

		float vel[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
		float speed = GetLinearVelocity(vel);

		float ang[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
		ang[0] += GetRandomFloat(-change, change);
		ang[1] += GetRandomFloat(-change, change);

		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vel, speed);
		TeleportEntity(entity, _, ang, vel);
	}
	delete pack;
}

void AddAttributes()
{
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();

	attrib.SetName("danmaku bounce");
	attrib.SetClass("ff2.danmaku_bounce");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku gravity");
	attrib.SetClass("ff2.danmaku_gravity");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku clock");
	attrib.SetClass("ff2.danmaku_clock");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku clock x");
	attrib.SetClass("ff2.danmaku_clockx");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku clock y");
	attrib.SetClass("ff2.danmaku_clocky");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku ring");
	attrib.SetClass("ff2.danmaku_ring");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku split");
	attrib.SetClass("ff2.danmaku_split");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku drunk");
	attrib.SetClass("ff2.danmaku_drunk");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();

	attrib.SetName("danmaku speedup");
	attrib.SetClass("ff2.danmaku_speedup");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.Register();

	attrib.SetName("danmaku deviation");
	attrib.SetClass("ff2.danmaku_deivation");
	attrib.SetDescriptionFormat("additive");
	attrib.Register();
	
	delete attrib;
}

float GetFormula(ConfigData cfg, const char[] key, float defaul = 0.0, int client = 0)
{
	static char buffer[1024];
	if(!cfg.GetString(key, buffer, sizeof(buffer)))
		return defaul;
	
	return ParseExpr(buffer, Formula_Danmaku, client);
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

void PrintSayText2(int client, int author, bool chat = true, const char[] message, const char[] param1 = NULL_STRING, const char[] param2 = NULL_STRING, const char[] param3 = NULL_STRING, const char[] param4 = NULL_STRING)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)); 
	
	bf.WriteByte(author);
	bf.WriteByte(chat);
	
	bf.WriteString(message); 
	
	bf.WriteString(param1); 
	bf.WriteString(param2); 
	bf.WriteString(param3);
	bf.WriteString(param4);
	
	EndMessage();
}

void DissolveProjectiles(int owner)
{
	int dissolver = CreateEntityByName("env_entity_dissolver");
	if(dissolver != -1)
	{
		DispatchKeyValue(dissolver, "dissolvetype", "3");
		DispatchKeyValue(dissolver, "magnitude", "1");
		DispatchKeyValue(dissolver, "target", "blitzedfromthestart");

		int entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_proj*")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == owner)
				DispatchKeyValue(entity, "targetname", "blitzedfromthestart");
		}

		AcceptEntityInput(dissolver, "Dissolve");
		AcceptEntityInput(dissolver, "Kill");
	}
}

bool IsEntityTarget(int entity)
{
	if(entity < 1)
		return false;
	
	return GetEntProp(entity, Prop_Data, "m_takedamage") == 2;
}

stock void AngleMatrix(const float angles[3], float matrix[4][3])
{
	float cp = DegToRad(angles[0]);
	float sp = Sine(cp);
	cp = Cosine(cp);
	
	float cy = DegToRad(angles[1]);
	float sy = Sine(cy);
	cy = Cosine(cy);
	
	float cr = DegToRad(angles[2]);
	float sr = Sine(cr);
	cr = Cosine(cr);

	// matrix = (YAW * PITCH) * ROLL
	matrix[0][0] = cp*cy;
	matrix[0][1] = cp*sy;
	matrix[0][2] = -sp;

	float crcy = cr*cy;
	float crsy = cr*sy;
	float srcy = sr*cy;
	float srsy = sr*sy;
	matrix[1][0] = sp*srcy-crsy;
	matrix[1][1] = sp*srsy+crcy;
	matrix[1][2] = sr*cp;

	matrix[2][0] = (sp*crcy+srsy);
	matrix[2][1] = (sp*crsy-srcy);
	matrix[2][2] = cr*cp;

	matrix[3][0] = 0.0;
	matrix[3][1] = 0.0;
	matrix[3][2] = 0.0;
}

stock void VectorRotate(const float vec[3], const float ang[3], float result[3])
{
	float matrix[4][3];
	AngleMatrix(ang, matrix);
	VectorRotateMatrix(vec, matrix, result);
}

stock void VectorRotateMatrix(const float vec[3], const float matrix[4][3], float result[3])
{
	for(int i; i < 3; i++)
	{
		result[i] = GetVectorDotProduct(vec, matrix[i]);
	}
}

float GetLinearVelocity(float vec[3])
{
	return SquareRoot((vec[0] * vec[0]) + (vec[1] * vec[1]) + (vec[2] * vec[2]));
}

void SendDialogToOne(int client, const int color[4], const char[] text, any ...)
{
	char message[100];
	VFormat(message, sizeof(message), text, 4);	
	
	KeyValues kv = new KeyValues("Stuff", "title", message);
	kv.SetColor("color", color[0], color[1], color[2], color[3]);
	kv.SetNum("level", 3);
	kv.SetNum("time", 11);
	
	CreateDialog(client, kv, DialogType_Msg);

	delete kv;
}

void ConstrainDistance(const float startPoint[3], float endPoint[3], float distance, float maxDistance)
{
	float constrainFactor = maxDistance / distance;

	for(int i; i < 3; i++)
	{
		endPoint[i] = ((endPoint[i] - startPoint[i]) * constrainFactor) + startPoint[i];
	}
}

int ParticleEffectAt(const float position[3], const char[] effectName, float duration = 0.1)
{
	int particle = CreateEntityByName("info_particle_system");
	if(particle != -1)
	{
		TeleportEntity(particle, position);
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		if(duration > 0.0)
		{
			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%.1f:1", duration);
			SetVariantString(buffer);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
	}

	return particle;
}

int Sort_HighRight(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if(elem1[1] > elem2[1])
		return -1;
	
	if(elem1[1] < elem2[1])
		return 1;
	
	return (elem1[0] > elem2[0]) ? 1 : -1;
}

void Formula_Danmaku(const char[] var_name, int var_name_len, float &f, any data)
{
	if(CharToLower(var_name[0]) == 'n')
	{
		f = float(TotalPlayersAliveEnemy((data && !CvarFriendlyFire.BoolValue) ? GetClientTeam(data) : -1));
	}
	else if(CharToLower(var_name[0]) == 'd')
	{
		f = float(CurrentDifficulty);
	}
	else if(CharToLower(var_name[0]) == 'w')
	{
		f = float(CurrentWave);
	}
}

bool TraceRay_TeamPlayers(int entity, int mask, any data)
{
	if(entity > 0 && entity <= MaxClients)
		return GetClientTeam(entity) != data;
	
	return IsValidEntity(entity);
}

bool TraceRay_WallsOnly(int entity, int mask)
{
	return false;
}

bool TraceRay_DontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}
