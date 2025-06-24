/*
	"rage_random_slot"
	{
		"slot"			"0"	// Ability slot
		
		"low"			"10"	// Lowest slot to activate
		"high"			"14"	// Highest slot to activate
		"count"			"1"		// How many unique slots to activate
		"repeat"		"false"	// If can cast the same slot when count is enabled
		
		"plugin_name"	"ff2r_gray_abilities"
	}


	"rage_sentry_buster"
	{
		"slot"			"0"	// Ability slot
		
		"death"			"true"	// Use ability on death
		"thirdperson"	"true"	// Spawn in thirdperson

		"plugin_name"	"ff2r_gray_abilities"
	}


	"special_announcer"
	{
		"plugin_name"	"ff2r_gray_abilities"
	}


	"special_bomb_point"
	{
		"minions"	"true"	// If only minions can pick up the bomb

		"plugin_name"	"ff2r_gray_abilities"
	}

	"sound_bomb_spawn"
	{
	}


	"special_interval"
	{
		"mintime"	"20.0"	// Minimum time between activations. If left blank, "mintime" is used. Formulas supported
		"maxtime"	"20.0"	// Maximum time between activations. If left blank, "maxtime" is used. Formulas supported
		
		"low"		"6"		// Lowest ability slot to activate. If left blank, "low" is used
		"high"		"6"		// Highest ability slot to activate. If left blank, "high" is used
		"rand"		"false"	// If to randomly pick one ability slot instead of all

		"plugin_name"	"ff2r_gray_abilities"
	}


	"special_minion_master"
	{
		"stun on death"	"20.0"	// Time to stun team's minions on death
		"boss refund"	"40.0"	// RAGE refund for killing a boss minion

		"plugin_name"	"ff2r_gray_abilities"
	}


	"special_mvm_teleporter"
	{
		"plugin_name"	"ff2r_gray_abilities"
	}


	"special_robot"
	{
		"giant"	"0"	// If to use giant sound variants (2 for Sentry Buster)
		"vip"	"0"	// Announce their arrival (1 is Engineer, 2 is Spy, 3 is Sentry Buster, 4 is Boss Bot)

		"plugin_name"	"ff2r_gray_abilities"
	}

	"sound_mega_spawn"
	{
	}
	
	
	"ff2r_gray_abilities"
	{
		"nopassive"	"0"
	}
*/

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
//#include <adt_trie_sort>
#include <cfgmap>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define FAR_FUTURE		100000000.0

enum
{
	Announce_Engineer,
	Announce_EngineerDead,
	Announce_Spy,
	Announce_SpyDead,
	Announce_SentryBuster,
	Announce_Destruction,
	Announce_BombReset,
	Announce_BombEntered,
	Announce_BombNearby,
	Announce_ControlPoint,
	Announce_Death,
	Announce_Win,
	Announce_Lose,

	Announce_MAX
}

static const char BotClassNames[][] =
{
	"",
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"heavy",
	"pyro",
	"spy",
	"engineer"
};

static const char LoopingSounds[][] =
{
	"MVM.SentryBusterLoop",
	"MVM.GiantScoutLoop",
	"",
	"MVM.GiantSoldierLoop",
	"MVM.GiantDemomanLoop",
	"",
	"MVM.GiantHeavyLoop",
	"MVM.GiantPyroLoop",
	"",
	""
};

static const char LoopingRawSounds[][] =
{
	"mvm/sentrybuster/mvm_sentrybuster_loop.wav",
	"mvm/giant_scout/giant_scout_loop.wav",
	"",
	"mvm/giant_soldier/giant_soldier_loop.wav",
	"mvm/giant_demoman/giant_demoman_loop.wav",
	"",
	")mvm/giant_heavy/giant_heavy_loop.wav",
	"mvm/giant_pyro/giant_pyro_loop.wav",
	"",
	""
};

native void FF2_SetClientGlow(int client, float add, float set=-1.0);

Handle SDKEquipWearable;
int PlayersAlive[4];

ConVar CvarFriendlyFire;
ConVar CvarTags;
ConVar CvarDebug;

Handle IntervalTimer[MAXTF2PLAYERS];
int RobotSounds[MAXTF2PLAYERS];
int RobotVIP[MAXTF2PLAYERS];
Handle RobotRemoveTimer[MAXTF2PLAYERS];
int PlayingRobotLoop[MAXTF2PLAYERS] = {-1, ...};
bool Teleporters[MAXTF2PLAYERS];
ArrayList TeleporterList;
int BombEnabled[4];
int BombRef = -1;
int BombCarrier;
int BombLevel;
float BombNextAt;
Handle BombTimer;
int PointsCapping;
int TheAnnouncer = -1;
int AnnouncedBefore[Announce_MAX];
Handle AnnounceTimer;
ArrayList AnnounceList;

#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/subplugin.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Gray Abilities",
	author		=	"Batfoxkid",
	description	=	"I must I must I must",
	version		=	PLUGIN_VERSION,
	url		=	"https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Attrib_PluginLoad();
	TF2U_PluginLoad();
	TFED_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	if(!TranslationPhraseExists("Gray Mann Sentry Buster Spawned"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	gamedata = new GameData("ff2");
	
	delete gamedata;
	
	Attrib_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	VScript_PluginStart();

	CvarFriendlyFire = FindConVar("mp_friendlyfire");
	CvarTags = FindConVar("sv_tags");
	
	AddNormalSoundHook(OnNormalSHook);

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Post);
	HookEvent("teamplay_flag_event", OnFlagEvent, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);

	Subplugin_PluginStart();
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
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && FF2R_GetBossData(client))
			FF2R_OnBossRemoved(client);
	}
}

public void OnMapStart()
{
	PrecacheModel("models/props_td/atom_bomb.mdl");
	
	PrecacheScriptSound("MVM.BotStep");
	PrecacheScriptSound("MVM.GiantScoutStep");
	PrecacheScriptSound("MVM.GiantSoldierStep");
	PrecacheScriptSound("MVM.GiantPyroStep");
	PrecacheScriptSound("MVM.GiantDemomanStep");
	PrecacheScriptSound("MVM.GiantHeavyStep");
	PrecacheScriptSound("MVM.FallDamageBots");
	PrecacheScriptSound("MVM.GiantCommonExplodes");
	PrecacheScriptSound("MVM.GiantHeavyExplodes");

	PrecacheScriptSound("MVM.SentryBusterExplode");
	PrecacheScriptSound("MVM.SentryBusterSpin");
	PrecacheScriptSound("MVM.SentryBusterIntro");
	PrecacheScriptSound("MVM.SentryBusterStep");

	PrecacheScriptSound("MVM.Robot_Teleporter_Deliver");
	PrecacheScriptSound("MVM.BombExplodes");
	PrecacheScriptSound("MVM.BombWarning");
	PrecacheScriptSound("MVM.Warning");
	PrecacheScriptSound("Announcer.MVM_Another_Engineer_Teleport_Spawned");
	PrecacheScriptSound("Announcer.MVM_First_Engineer_Teleport_Spawned");
	PrecacheScriptSound("Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
	PrecacheScriptSound("Announcer.MVM_An_Engineer_Bot_Is_Dead");
	PrecacheScriptSound("Announcer.MVM_Spy_Alert");
	PrecacheScriptSound("Announcer.mvm_spybot_death_all");
	PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert_Another");
	PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert");
	PrecacheScriptSound("Announcer.MVM_General_Destruction");
	PrecacheScriptSound("Announcer.MVM_Bomb_Reset");
	PrecacheScriptSound("Announcer.MVM_Bomb_Alert_Entered");
	PrecacheScriptSound("Announcer.MVM_Bomb_Alert_Near_Hatch");
	PrecacheScriptSound("Announcer.MVM_All_Dead");
	PrecacheScriptSound("Announcer.MVM_Final_Wave_End");
	PrecacheScriptSound("Announcer.MVM_Game_Over_Loss");

	for(int i; i < sizeof(LoopingSounds); i++)
	{
		if(LoopingSounds[i][0])
			PrecacheScriptSound(LoopingSounds[i]);
	}
}

public void OnMapEnd()
{
	OnRoundEnd(null, NULL_STRING, false);
}

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	if(FF2R_GetGamemodeType() == 2)
	{
		int team = GetClientTeam(client);

		if(!BombEnabled[team])
		{
			AbilityData ability = boss.GetAbility("special_bomb_point");
			if(ability.IsMyPlugin())
			{
				if(!BombEnabled[0] && !BombEnabled[1] && !BombEnabled[2] && !BombEnabled[3])
					HookEntityOutput("tf_logic_arena", "OnCapEnabled", OnCapEnabled);
				
				BombEnabled[team] = ability.GetBool("minions") ? 2 : 1;
			}
		}

		if(TheAnnouncer == -1)
		{
			AbilityData ability = boss.GetAbility("special_announcer");
			if(ability.IsMyPlugin())
			{
				TheAnnouncer = team;
			}
		}
	}

	if(!Teleporters[client])
	{
		AbilityData ability = boss.GetAbility("special_mvm_teleporter");
		if(ability.IsMyPlugin())
		{
			Teleporters[client] = true;

			if(!TeleporterList)
				TeleporterList = new ArrayList();
		}
	}

	if(!setup)
	{
		if(!IntervalTimer[client])
		{
			AbilityData ability = boss.GetAbility("special_interval");
			if(ability.IsMyPlugin())
			{
				int players;
				for(int i; i < 4; i++)
				{
					players += PlayersAlive[i];
				}
				
				float mintime, maxtime;
				GetMinMaxFromFormula(mintime, maxtime, ability, "time", players, "0.2");
				IntervalTimer[client] = CreateTimer(GetRandomFloat(mintime, maxtime), Interval_Timer, client);
			}
		}
	}
}

public void FF2R_OnBossEquipped(int client, bool weapons)
{
	BossData boss = FF2R_GetBossData(client);
	
	if((RobotRemoveTimer[client] || !RobotSounds[client]) && weapons)
	{
		AbilityData ability = boss.GetAbility("special_robot");
		if(ability.IsMyPlugin())
		{
			StopRobotSound(client);
			RobotSounds[client] = ability.GetInt("giant") + 1;
			RobotVIP[client] = ability.GetInt("vip");
			delete RobotRemoveTimer[client];
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);

			if(RobotSounds[client] == 3)
			{
				PlayingRobotLoop[client] = 0;
				EmitGameSoundToAll(LoopingSounds[0], client);
			}
			else if(RobotSounds[client] == 2)
			{
				int class = view_as<int>(TF2_GetPlayerClass(client));
				if(LoopingSounds[class][0])
				{
					PlayingRobotLoop[client] = class;
					EmitGameSoundToAll(LoopingSounds[class], client);
				}

				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
			}
			else
			{
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 90.0);
			}

			if(RobotSounds[client] > 1)
				FF2_SetClientGlow(client, 0.0, 999.0);

			switch(RobotVIP[client])
			{
				case 1:
				{
					RequestAnnouncement(Announce_Engineer);
				}
				case 2:
				{
					RequestAnnouncement(Announce_Spy);
				}
				case 3:
				{
					RequestAnnouncement(Announce_SentryBuster);
				}
				case 4:
				{
					int maxhealth = boss.GetInt("maxhealth");
					if(maxhealth < 1)
						maxhealth = GetClientHealth(client);
					
					int maxlives = boss.GetInt("lives", 1);
					int team = GetClientTeam(client);

					EmitGameSoundToAll("MVM.TankStart");

					char buffer[256];

					int leader;
					int count;
					int[] targets = new int[MaxClients];
					for(int target = 1; target <= MaxClients; target++)
					{
						if(IsClientInGame(target) && !IsFakeClient(target))
						{
							SetGlobalTransTarget(target);
							GetBossNameCfg(boss, buffer, sizeof(buffer), GetClientLanguage(client));

							if(maxlives > 1)
							{
								Format(buffer, sizeof(buffer), "%t", "Boss Spawned As Lives", client, buffer, maxhealth, maxlives);
							}
							else
							{
								Format(buffer, sizeof(buffer), "%t", "Boss Spawned As", client, buffer, maxhealth);
							}

							FPrintToChatEx(target, client, buffer);
							CRemoveTags(buffer, sizeof(buffer));
							ShowGameText(target, "ico_notify_on_fire", team, buffer);

							if(GetClientTeam(target) == team)
							{
								if(!leader && client != target && !FF2R_GetClientMinion(target) && FF2R_GetBossData(target))
									leader = target;
							}

							targets[count++] = target;
						}
					}

					if(leader)
						FF2R_EmitBossSound(targets, count, "sound_mega_spawn", leader);
				}
			}
		}
	}

	AbilityData ability = boss.GetAbility("rage_sentry_buster");
	if(ability.IsMyPlugin())
	{
		if(ability.GetBool("death", true))
			TF2_AddCondition(client, TFCond_PreventDeath);

		if(ability.GetBool("thirdperson"))
		{
			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
		}
	}
}

public void FF2R_OnBossRemoved(int client)
{
	delete IntervalTimer[client];
	Teleporters[client] = false;

	// Intentionally leak, used for non-boss minions
	if(!IsPlayerAlive(client))
		StopRobotSound(client);
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "rage_random_slot", false))
	{
		int count = cfg.GetInt("count", 1);
		int low = cfg.GetInt("low");
		int high = cfg.GetInt("high");
		
		if(count < 2 || cfg.GetBool("repeat"))
		{
			for(int i; i < count; i++)
			{
				FF2R_DoBossSlot(client, GetRandomInt(low, high));
			}
		}
		else
		{
			int range = high - low + 1;
			int[] slots = new int[range];
			
			for(int i; i < range; i++)
			{
				slots[i] = low + i;
			}
			
			SortIntegers(slots, range, Sort_Random);
			
			for(int i; i < count; i++)
			{
				FF2R_DoBossSlot(client, slots[i]);
			}
		}
	}
	else if(!StrContains(ability, "rage_sentry_buster", false))
	{
		DoSentryBuster(client);
	}
}

public void FF2R_OnAliveChanged(const int alive[4], const int total[4])
{
	for(int i; i < 4; i++)
	{
		PlayersAlive[i] = alive[i];
	}
}

public void FF2R_OnBossModifier(int client, ConfigData cfg)
{
	BossData boss = FF2R_GetBossData(client);
	
	if(boss.GetBool("nopassive"))
	{
		if(boss.GetAbility("special_interval").IsMyPlugin())
			boss.Remove("special_interval");
	}
}

public void OnLibraryAdded(const char[] name)
{
	Attrib_LibraryAdded(name);
	Subplugin_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	VScript_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	Subplugin_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	VScript_LibraryRemoved(name);
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
	if(TeleporterList)
	{
		if(!StrContains(classname, "obj_teleporter", false))
			SDKHook(entity, SDKHook_SpawnPost, OnTeleporterSpawn);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	switch(condition)
	{
		case TFCond_HalloweenKartNoTurn:
		{
			if(TeleporterList && FF2R_GetClientMinion(client) && !FF2R_GetBossData(client))
			{
				int length = TeleporterList.Length;
				if(length > 0)
				{
					int entity = TeleporterList.Get(GetURandomInt() % length);
					
					float pos[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
					TeleportEntity(client, pos);
					SetEntProp(client, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);

					TF2_RemoveCondition(client, TFCond_MegaHeal);
					TF2_RemoveCondition(client, TFCond_UberchargedOnTakeDamage);
					EmitGameSoundToClient(client, "MVM.Robot_Teleporter_Deliver");
				}
			}
		}
		case TFCond_PreventDeath:
		{
			BossData boss = FF2R_GetBossData(client);
			if(boss.GetAbility("rage_sentry_buster").IsMyPlugin())
			{
				DoSentryBuster(client);
			}
		}
	}
}

Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	if(victim)
	{
		if(RobotSounds[victim] == 2)
		{
			if(TF2_GetPlayerClass(victim) == TFClass_Heavy)
			{
				EmitGameSoundToAll("MVM.GiantHeavyExplodes");
			}
			else
			{
				EmitGameSoundToAll("MVM.GiantCommonExplodes");
			}

			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(attacker)
				ReactConcept(attacker, "TLK_MVM_GIANT_KILLED");
		}

		int team = GetClientTeam(victim);

		if(TheAnnouncer != team)
			RequestAnnouncement(Announce_Death, 1.25);

		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			// Announce dead class group
			if(TheAnnouncer != -1 && RobotVIP[victim])
			{
				bool foundOthers;
				
				for(int target = 1; target <= MaxClients; target++)
				{
					if(victim != target && RobotVIP[victim] == RobotVIP[target] && IsClientInGame(target) && IsPlayerAlive(target))
					{
						foundOthers = true;
						break;
					}
				}

				if(!foundOthers)
				{
					switch(RobotVIP[victim])
					{
						case 1:
							RequestAnnouncement(Announce_EngineerDead);
						
						case 2:
							RequestAnnouncement(Announce_SpyDead);
					}
				}
			}

			StopRobotSound(victim);

			// Transfer building ownership to the minion master
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && team == GetClientTeam(target))
				{
					BossData boss = FF2R_GetBossData(target);
					if(boss)
					{
						AbilityData ability = boss.GetAbility("special_minion_master");
						if(ability.IsMyPlugin())
						{
							int entity = -1;
							while((entity=FindEntityByClassname(entity, "obj_*")) != -1)
							{
								if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == victim)
									SetEntPropEnt(entity, Prop_Send, "m_hBuilder", target);
							}

							break;
						}
					}
				}
			}

			BossData boss = FF2R_GetBossData(victim);
			if(boss)
			{
				// Stun minions on death
				AbilityData ability = boss.GetAbility("special_minion_master");
				if(ability.IsMyPlugin())
				{
					float stun = ability.GetFloat("stun on death");
					if(stun > 0.0)
					{
						for(int target = 1; target <= MaxClients; target++)
						{
							if(IsClientInGame(target) && IsPlayerAlive(target) && team == GetClientTeam(target) && FF2R_GetClientMinion(target))
								TF2_StunPlayer(target, stun, 1.0, TF_STUNFLAGS_NORMALBONK);
						}
					}
				}

				if(!FF2R_GetClientMinion(victim) && TheAnnouncer == team)
				{
					RequestAnnouncement(Announce_Destruction);
					ReactConceptEnemy(team, "TLK_MVM_TAUNT");
				}
			}
		}
	}

	return Plugin_Continue;
}

void OnInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
	{
		// Disable robot sounds (if leaked)
		StopRobotSound(client);
	}
}

Action OnFlagEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(IsValidEntity(BombRef))
	{
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete TeleporterList;

	for(int i; i < sizeof(AnnouncedBefore); i++)
	{
		AnnouncedBefore[i] = false;
	}

	for(int client = 1; client <= MaxClients; client++)
	{
		delete IntervalTimer[client];
	}

	for(int i; i < sizeof(BombEnabled); i++)
	{
		BombEnabled[i] = 0;
	}

	if(event && TheAnnouncer != -1)
	{
		RequestAnnouncement(event.GetInt("team") == (TheAnnouncer == 3 ? 2 : 3) ? Announce_Win : Announce_Lose, 6.0, true);
	}

	// Explode the bomb on win
	if(event && event.GetInt("winreason") == 1 && IsValidEntity(BombRef) && BombCarrier)
	{
		float pos[3];
		GetEntPropVector(BombCarrier, Prop_Send, "m_vecOrigin", pos);
		TE_Particle("mvm_hatch_destroy", pos);
		EmitGameSoundToAll("MVM.BombExplodes", BombCarrier);
		ForcePlayerSuicide(BombCarrier);
		RemoveEntity(BombRef);
	}
}

Action OnNormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(entity > 0 && entity <= MaxClients)
	{
		int client = entity;
		if(TF2_IsPlayerInCondition(entity, TFCond_Disguised))
		{
			for(int i; i < numClients; i++)
			{
				if(clients[i] == entity)	// Get the sound from the Spy/enemies to avoid teammates hearing it
				{
					client = GetEntPropEnt(entity, Prop_Send, "m_hDisguiseTarget");
					if(client == -1 || view_as<TFClassType>(GetEntProp(entity, Prop_Send, "m_nDisguiseClass")) != TF2_GetPlayerClass(client))
						client = entity;
					
					break;
				}
			}
		}

		if(RobotSounds[client])
		{
			TFClassType class = TF2_GetPlayerClass(client);
			
			if(StrContains(sample, "mvm/", false) != -1)
			{

			}
			else if(StrContains(sample, "vo/", false) != -1)
			{
				if(RobotSounds[client] == 3)
					return Plugin_Stop;
				
				static char buffer[PLATFORM_MAX_PATH];
				if(RobotSounds[client] == 2 && class != TFClass_Sniper && class != TFClass_Engineer && class != TFClass_Medic && class != TFClass_Spy)
				{
					ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
					Format(buffer, sizeof(buffer), "%s_mvm_m", BotClassNames[view_as<int>(class)]);
				}
				else
				{
					ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/norm/", false);
					Format(buffer, sizeof(buffer), "%s_mvm", BotClassNames[view_as<int>(class)]);
				}
				
				ReplaceString(sample, sizeof(sample), BotClassNames[view_as<int>(class)], buffer);
				
				Format(buffer, sizeof(buffer), "sound/%s", sample);
				if(FileExists(buffer, true))
				{
					PrecacheSound(sample);
					return Plugin_Changed;
				}
			}
			else if(StrContains(sample, "player/footsteps/", false) != -1)
			{
				if(RobotSounds[client] == 3)
				{
					EmitGameSoundToAll("MVM.SentryBusterStep", entity, flags);
					return Plugin_Stop;
				}

				if(RobotSounds[client] == 2)
				{
					switch(class)
					{
						case TFClass_Scout:
						{
							EmitGameSoundToAll("MVM.GiantScoutStep", entity, flags);
							return Plugin_Stop;
						}
						case TFClass_Soldier:
						{
							EmitGameSoundToAll("MVM.GiantSoldierStep", entity, flags);
							return Plugin_Stop;
						}
						case TFClass_Pyro:
						{
							EmitGameSoundToAll("MVM.GiantPyroStep", entity, flags);
							return Plugin_Stop;
						}
						case TFClass_DemoMan:
						{
							EmitGameSoundToAll("MVM.GiantDemomanStep", entity, flags);
							return Plugin_Stop;
						}
						case TFClass_Heavy:
						{
							EmitGameSoundToAll("MVM.GiantHeavyStep", entity, flags);
							return Plugin_Stop;
						}
					}
				}

				if(class != TFClass_Medic)
					EmitGameSoundToAll("MVM.BotStep", entity, flags);
				
				return Plugin_Stop;
			}
			else if(StrContains(sample, "player/pl_fallpain.wav", false) != -1)
			{
				EmitGameSoundToAll("MVM.FallDamageBots", entity, flags);
				return Plugin_Stop;
			}
		}
	}
	else if(!StrContains(sample, "vo/intel_", false))
	{
		if(IsValidEntity(BombRef))
			return Plugin_Stop;
	}

	return Plugin_Continue;
}

Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == GetClientTeam(attacker) && !CvarFriendlyFire.BoolValue)
	{
		if(victim != BombCarrier)
		{
			// Can only effect non-boss minions (including bomb carriers)
			if(RobotVIP[victim] > 2 || !FF2R_GetClientMinion(victim))
				return Plugin_Continue;
		}

		BossData boss = FF2R_GetBossData(attacker);
		if(boss)
		{
			AbilityData ability = boss.GetAbility("special_minion_master");
			if(ability.IsMyPlugin())
			{
				if(FF2R_GetBossData(victim))
				{
					float refund = ability.GetFloat("boss refund");
					if(refund > 0.0)
					{
						int health = GetClientHealth(victim);
						int maxhealth = FF2R_GetBossData(victim).GetInt("maxhealth");

						health += maxhealth * boss.GetInt("livesleft", 1);
						maxhealth *= boss.GetInt("lives", 1);

						if(health > 0 && maxhealth > 0)
						{
							if(health > maxhealth)
								health = maxhealth;
							
							refund *= float(health) / float(maxhealth);
							SetBossCharge(boss, "0", GetBossCharge(boss, "0") + refund);
							PrintHintText(attacker, "%t", "Gray Mann Refund", RoundFloat(refund));
						}
					}
				}

				int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

				int fflags = CvarFriendlyFire.Flags;
				CvarFriendlyFire.Flags = fflags & ~FCVAR_NOTIFY;

				int tflags = CvarTags.Flags;
				CvarTags.Flags = tflags & ~FCVAR_NOTIFY;
				
				CvarFriendlyFire.BoolValue = true;
				SDKHooks_TakeDamage(victim, inflictor, attacker, 3333.0, DMG_CRIT, weapon);
				CvarFriendlyFire.BoolValue = false;

				CvarFriendlyFire.Flags = fflags;
				CvarTags.Flags = tflags;

				FakeClientCommand(victim, "kill");
			}
		}
	}
	
	return Plugin_Continue;
}

void OnCapEnabled(const char[] output, int caller, int activator, float delay)
{
	UnhookEntityOutput("tf_logic_arena", "OnCapEnabled", OnCapEnabled);
	if(BombEnabled[0] || BombEnabled[1] || BombEnabled[2] || BombEnabled[3])
	{
		if(!IsValidEntity(BombRef))
		{
			static float pos[3];

			RequestAnnouncement(Announce_BombEntered);

			int entity = -1;
			while((entity=FindEntityByClassname(entity, "func_respawnroom")) != -1)
			{
				AcceptEntityInput(entity, "Kill");
			}

			int count;
			int boss;
			int[] targets = new int[MaxClients];
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client))
				{
					StopSound(client, 7, "vo/announcer_AM_CapEnabled01.mp3");
					StopSound(client, 7, "vo/announcer_AM_CapEnabled02.mp3");
					StopSound(client, 7, "vo/announcer_AM_CapEnabled03.mp3");
					StopSound(client, 7, "vo/announcer_AM_CapEnabled04.mp3");

					if(IsPlayerAlive(client))
					{
						ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Gray Mann Bomb Spawned");

						// Backup spawn position
						if(GetEntityFlags(client) & FL_ONGROUND)
							GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
						
						if(!boss && FF2R_GetBossData(client) && BombEnabled[GetClientTeam(client)])
							boss = client;
						
						if(OnBombTouch(0, client) == Plugin_Continue)
							targets[count++] = client;
					}
				}
			}

			if(count)
			{
				int target = targets[GetURandomInt() % count];
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);

				if(boss)
					FF2R_EmitBossSound(targets, count, "sound_bomb_spawn", boss);
			}

			ReactConceptEnemy(-1, "TLK_MVM_FIRST_BOMB_PICKUP");

			BombRef = CreateEntityByName("item_teamflag");
			if(BombRef != -1)
			{
				TeleportEntity(BombRef, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(BombRef, "Angles", "0 0 0");
				DispatchKeyValue(BombRef, "TeamNum", (BombEnabled[0] || BombEnabled[1] || BombEnabled[2]) ? ((BombEnabled[0] || BombEnabled[1] || BombEnabled[3]) ? "0" : "2") : "3");
				DispatchKeyValue(BombRef, "StartDisabled", "0");
				DispatchKeyValue(BombRef, "ReturnTime", "30");
				DispatchKeyValue(BombRef, "flag_model", "models/props_td/atom_bomb.mdl");
				DispatchKeyValue(BombRef, "trail_effect", "3");
				DispatchSpawn(BombRef);
				AcceptEntityInput(BombRef, "Enable");

				SDKHook(BombRef, SDKHook_Touch, OnBombTouch);

				HookSingleEntityOutput(BombRef, "OnPickup1", OnBombPickup);
				HookSingleEntityOutput(BombRef, "OnDrop1", OnBombDropped);
				HookSingleEntityOutput(BombRef, "OnReturn", OnBombReturn);

				BombRef = EntIndexToEntRef(BombRef);
			}

			PointsCapping = 0;

			entity = -1;
			while((entity = FindEntityByClassname(entity, "trigger_capture_area")) != -1)
			{
				SDKHook(entity, SDKHook_StartTouch, OnPointTouch);
				SDKHook(entity, SDKHook_Touch, OnPointTouch);
				HookSingleEntityOutput(entity, "OnStartCap", OnPointStartCap);
				HookSingleEntityOutput(entity, "OnBreakCap", OnPointBreakCap);
			}
		}
	}
}

void OnBombPickup(const char[] output, int caller, int activator, float delay)
{
	delete BombTimer;
	BombTimer = CreateTimer(1.0, Timer_BombThink, _, TIMER_REPEAT);
	BombCarrier = activator;
	BombLevel = 0;
	BombNextAt = GetGameTime() + 4.5;
	SetControlPoint(true);

	if(activator > 0 && activator <= MaxClients)
	{
		PrintCenterText(activator, "%t", "Gray Mann Bomb Hint");
		
		if(FF2R_GetBossData(activator))
		{
			ReactConceptEnemy(GetClientTeam(activator), "TLK_MVM_GIANT_HAS_BOMB");
		}
		else
		{
			Attrib_Set(activator, "move speed penalty", 0.5);
			Attrib_Set(activator, "increase player capture value", 1.01);
			TF2_AddCondition(activator, TFCond_SpeedBuffAlly, 0.01);

			ReactConceptEnemy(GetClientTeam(activator), "TLK_MVM_BOMB_PICKUP");
		}
	}
}

void OnBombDropped(const char[] output, int caller, int activator, float delay)
{
	delete BombTimer;
	BombCarrier = 0;
	SetControlPoint(false);

	if(activator > 0 && activator <= MaxClients)
	{
		Attrib_Remove(activator, "move speed penalty");
		Attrib_Remove(activator, "increase player capture value");
		TF2_AddCondition(activator, TFCond_SpeedBuffAlly, 0.01);

		ReactConceptEnemy(GetClientTeam(activator), "TLK_MVM_BOMB_DROPPED");
	}
}

void OnBombReturn(const char[] output, int caller, int activator, float delay)
{
	delete BombTimer;
	BombCarrier = 0;
	SetControlPoint(true);
	RequestAnnouncement(Announce_BombReset);

	RemoveEntity(BombRef);

	ReactConceptEnemy(GetClientTeam(activator), "TLK_MVM_BOMB_DROPPED");
}

Action OnBombTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients)
	{
		int setting = BombEnabled[GetClientTeam(client)];
		if(!setting || (setting == 2 && !FF2R_GetClientMinion(client)))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

Action Timer_BombThink(Handle timer)
{
	if(!IsValidEntity(BombRef) || !BombCarrier)
	{
		BombTimer = null;
		return Plugin_Stop;
	}

	if(!FF2R_GetBossData(BombCarrier))
	{
		if(PointsCapping > 0)
		{
			float gameTime = GetGameTime();
			if(Fabs(BombNextAt - gameTime) > 4.0)
			{
				BombNextAt = gameTime;
				EmitGameSoundToAll("MVM.BombWarning");
			}
		}
		else if(BombLevel < 3)
		{
			float gameTime = GetGameTime();
			if(BombNextAt < gameTime)
			{
				BombNextAt = gameTime + 14.5;
				BombLevel++;

				FakeClientCommand(BombCarrier, "taunt");
				TF2_AddCondition(BombCarrier, TFCond_HalloweenKartNoTurn, 3.0);
				EmitGameSoundToAll("MVM.Warning");
			}
		}

		if(BombLevel > 0)
		{
			int team = GetClientTeam(BombCarrier);
			float pos1[3], pos2[3];
			GetEntPropVector(BombCarrier, Prop_Send, "m_vecOrigin", pos1);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == team && !FF2R_GetBossData(target))
				{
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2);
					if(GetVectorDistance(pos1, pos2, true) < 90000.0)
						TF2_AddCondition(target, TFCond_DefenseBuffNoCritBlock, 1.1);
				}
			}

			if(BombLevel > 1)
				TF2_AddCondition(BombCarrier, TFCond_HalloweenQuickHeal, 1.1);

			if(BombLevel > 2)
				TF2_AddCondition(BombCarrier, TFCond_HalloweenCritCandy, 1.1);
		}
	}
	return Plugin_Continue;
}

Action OnPointTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients)
	{
		if(IsValidEntity(BombRef))
		{
			if(BombCarrier != client)
				return Plugin_Handled;
		}
		else if(BombEnabled[GetClientTeam(client)])
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void OnPointStartCap(const char[] output, int caller, int activator, float delay)
{
	PointsCapping++;
	RequestAnnouncement(Announce_BombNearby);
}

void OnPointBreakCap(const char[] output, int caller, int activator, float delay)
{
	PointsCapping--;
}

void StopRobotSound(int client)
{
	delete RobotRemoveTimer[client];
	RobotRemoveTimer[client] = CreateTimer(0.1, StopRobotSoundTimer, client);

	if(PlayingRobotLoop[client] != -1)
	{
		StopSound(client, SNDCHAN_STATIC, LoopingRawSounds[PlayingRobotLoop[client]]);
		PlayingRobotLoop[client] = -1;
	}
}

Action StopRobotSoundTimer(Handle timer, int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	RobotSounds[client] = 0;
	RobotVIP[client] = 0;
	RobotRemoveTimer[client] = null;
	return Plugin_Continue;
}

Action Interval_Timer(Handle timer, int client)
{
	AbilityData ability = FF2R_GetBossData(client).GetAbility("special_interval");
	if(ability)
	{
		if(IsPlayerAlive(client))
		{
			if(ability.GetBool("rand"))
			{
				int high = ability.GetInt("high", ability.GetInt("low"));
				int low = ability.GetInt("low", high);
				int slot = GetRandomInt(low, high);
				FF2R_DoBossSlot(client, slot);
			}
			else
			{
				int slot = ability.GetInt("high", ability.GetInt("low"));
				FF2R_DoBossSlot(client, ability.GetInt("low", slot), slot);
			}
		}

		int players;
		for(int i; i < 4; i++)
		{
			players += PlayersAlive[i];
		}
		
		float mintime, maxtime;
		GetMinMaxFromFormula(mintime, maxtime, ability, "time", players, "0.2");
		IntervalTimer[client] = CreateTimer(GetRandomFloat(mintime, maxtime), Interval_Timer, client);
	}
	else
	{
		IntervalTimer[client] = null;
	}

	return Plugin_Continue;
}

void OnTeleporterSpawn(int building)
{
	if(TeleporterList)
	{
		int client = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
		if(Teleporters[client])
		{
			int particle = CreateEntityByName("trigger_push");
			if(particle != -1)
			{
				float pos[3];
				GetEntPropVector(building, Prop_Data, "m_vecOrigin", pos);
				TeleportEntity(particle, pos);
				
				DataPack pack = new DataPack();
				CreateTimer(2.0, Timer_ParticleWait, pack, TIMER_REPEAT);
				pack.WriteCell(EntIndexToEntRef(particle));
				pack.WriteCell(EntIndexToEntRef(building));
			}
		}
	}
}

Action Timer_ParticleWait(Handle timer, DataPack pack)
{
	pack.Reset();
	int ref = pack.ReadCell();
	int particle = EntRefToEntIndex(ref);
	if(particle != -1)
	{
		if(TeleporterList)
		{
			int building = EntRefToEntIndex(pack.ReadCell());
			if(building != -1)
			{
				if(GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing") || GetEntProp(building, Prop_Send, "m_bDisabled") || GetEntPropFloat(building, Prop_Send, "m_flPercentageConstructed")<1)
					return Plugin_Continue;
				
				float pos[3];
				GetEntPropVector(building, Prop_Data, "m_vecOrigin", pos);
				TeleportEntity(particle, pos);
				TE_Particle("teleported_mvm_bot", pos, _, _, particle, 1, 0);
				CreateTimer(0.5, Timer_ParticleActive, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);

				// Particle effect ends after 5 seconds, spawn a new one
				CreateTimer(5.0, Timer_ParticleRespawn, ref, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

				TeleporterList.Push(EntIndexToEntRef(particle));
				return Plugin_Stop;
			}
		}

		RemoveEntity(particle);
	}

	delete pack;
	return Plugin_Stop;
}

Action Timer_ParticleActive(Handle timer, DataPack pack)
{
	pack.Reset();
	int ref = pack.ReadCell();
	int particle = EntRefToEntIndex(ref);
	if(particle != -1)
	{
		if(TeleporterList)
		{
			int building = EntRefToEntIndex(pack.ReadCell());
			if(building != -1)
			{
				float pos[3];
				GetEntPropVector(building, Prop_Data, "m_vecOrigin", pos);
				TeleportEntity(particle, pos);
				return Plugin_Continue;
			}
		}

		RemoveEntity(particle);
	}

	if(TeleporterList)
		TeleporterList.Erase(TeleporterList.FindValue(ref));
	
	return Plugin_Stop;
}

Action Timer_ParticleRespawn(Handle timer, int ref)
{
	int particle = EntRefToEntIndex(ref);
	if(particle != -1)
	{
		float pos[3];
		GetEntPropVector(particle, Prop_Data, "m_vecOrigin", pos);
		TE_Particle("teleported_mvm_bot", pos, _, _, particle, 1, 0);
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

void DoSentryBuster(int client)
{
	if(!IsInvuln(client))
	{
		TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, 10.0);
		TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 15.0);

		SetEntityHealth(client, 1);
		SDKHook(client, SDKHook_PreThink, SentryBusterDelay);
	}
}

void SentryBusterDelay(int client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		return;

	SDKUnhook(client, SDKHook_PreThink, SentryBusterDelay);

	EmitGameSoundToAll("MVM.SentryBusterSpin", client);
	SetEntityMoveType(client, MOVETYPE_NONE);
	FakeClientCommand(client, "taunt");
	CreateTimer(2.1, SentryBusterExplode, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action SentryBusterExplode(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);

		float pos[3];
		GetClientAbsOrigin(client, pos);

		AbilityData ability = FF2R_GetBossData(client).GetAbility("rage_sentry_buster");

		EmitGameSoundToAll("MVM.SentryBusterExplode", SOUND_FROM_WORLD, .origin = pos);
		
		int entity = CreateEntityByName("env_explosion");
		if(entity != -1)
		{
			DispatchKeyValueFloat(entity, "DamageForce", ability.GetFloat("force", 200.0));
			DispatchKeyValueInt(entity, "iMagnitude", ability.GetInt("magnitude", 750));
			DispatchKeyValueInt(entity, "iRadiusOverride", ability.GetInt("radius", 300));
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			DispatchSpawn(entity);
			TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(entity, "Explode");
			AcceptEntityInput(entity, "Kill");

			TE_Particle("fluidSmokeExpl_ring_mvm", pos);
			ForcePlayerSuicide(client);
			RequestFrame(RemoveRagdollFrame, userid);
		}
	}
	return Plugin_Continue;
}

void RemoveRagdollFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(ragdoll != -1)
			AcceptEntityInput(ragdoll, "Kill");
	}
}

void RequestAnnouncement(int sound, float delay = 0.2, bool override = false)
{
	if(TheAnnouncer == -1)
		return;
	
	if(override)
	{
		delete AnnounceTimer;
		delete AnnounceList;
	}

	if(!AnnounceTimer)
		AnnounceTimer = CreateTimer(delay, AnnounceDelay);
	
	if(!AnnounceList)
		AnnounceList = new ArrayList();
	
	AnnounceList.Push(sound);
}

Action AnnounceDelay(Handle timer)
{
	AnnounceTimer = null;

	if(TheAnnouncer != -1 && AnnounceList && AnnounceList.Length)
	{
		int item = AnnounceList.Get(0);
		AnnounceList.Erase(0);

		int dupes;
		int pos;
		while((pos=AnnounceList.FindValue(item)) != -1)
		{
			dupes++;
			AnnounceList.Erase(pos);
		}

		int count;
		int[] targets = new int[MaxClients];
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && TheAnnouncer != GetClientTeam(target))
			{
				targets[count++] = target;

				switch(item)
				{
					case Announce_Engineer:
					{
						ShowGameText(target, "ico_metal", _, "%t", "Gray Mann Engineer Bot Spawned");
					}
					case Announce_Spy:
					{
						ShowGameText(target, "hud_spy_disguise_menu_icon", _, "%t", "Gray Mann Spy Bots Spawned");
					}
					case Announce_SentryBuster:
					{
						ShowGameText(target, "ico_demolish", _, "%t", "Gray Mann Sentry Buster Spawned");
						ReactConcept(target, "TLK_MVM_SENTRY_BUSTER");
					}
					case Announce_ControlPoint:
					{
						ShowGameText(target, "ico_notify_flag_moving_alt", TheAnnouncer == 3 ? 2 : 3, "%t", "Point Unlocked");
					}
				}
			}
		}

		switch(item)
		{
			case Announce_Engineer:
			{
				if(AnnouncedBefore[item])
				{
					EmitGameSound(targets, count, "Announcer.MVM_Another_Engineer_Teleport_Spawned");
				}
				else
				{
					EmitGameSound(targets, count, "Announcer.MVM_First_Engineer_Teleport_Spawned");
				}
			}
			case Announce_EngineerDead:
			{
				if(TeleporterList)
				{
					EmitGameSound(targets, count, "Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
				}
				else
				{
					EmitGameSound(targets, count, "Announcer.MVM_An_Engineer_Bot_Is_Dead");
				}
			}
			case Announce_Spy:
			{
				EmitGameSound(targets, count, "Announcer.MVM_Spy_Alert");
			}
			case Announce_SpyDead:
			{
				EmitGameSound(targets, count, "Announcer.mvm_spybot_death_all");
			}
			case Announce_SentryBuster:
			{
				if(AnnouncedBefore[item])
				{
					EmitGameSound(targets, count, "Announcer.MVM_Sentry_Buster_Alert_Another");
				}
				else
				{
					EmitGameSound(targets, count, "Announcer.MVM_Sentry_Buster_Alert");
				}
			}
			case Announce_Destruction:
			{
				EmitGameSoundToAll("Announcer.MVM_General_Destruction");
			}
			case Announce_BombReset:
			{
				EmitGameSoundToAll("Announcer.MVM_Bomb_Reset");
				AnnounceList.Push(Announce_ControlPoint);
			}
			case Announce_BombEntered:
			{
				EmitGameSound(targets, count, "Announcer.MVM_Bomb_Alert_Entered");
			}
			case Announce_BombNearby:
			{
				EmitGameSound(targets, count, "Announcer.MVM_Bomb_Alert_Near_Hatch");
			}
			case Announce_ControlPoint:
			{
				EmitGameSound(targets, count, "Announcer.AM_CapEnabledRandom");
			}
			case Announce_Death:
			{
				if(dupes > 2)
					EmitGameSound(targets, count, "Announcer.MVM_All_Dead");
			}
			case Announce_Win:
			{
				TheAnnouncer = -1;
				EmitGameSoundToAll("Announcer.MVM_Final_Wave_End");
			}
			case Announce_Lose:
			{
				TheAnnouncer = -1;
				EmitGameSoundToAll("Announcer.MVM_Game_Over_Loss");
			}
		}

		if(TheAnnouncer != -1)
		{
			AnnounceTimer = CreateTimer(4.0, AnnounceDelay);
			return Plugin_Continue;
		}
	}

	delete AnnounceList;
	return Plugin_Continue;
}

void GetMinMaxFromFormula(float &minn, float &maxx, ConfigData cfg, const char[] key, int players, const char[] defaul = NULL_STRING)
{
	static char key2[64], buffer1[512], buffer2[512];

	Format(key2, sizeof(key2), "min%s", key);
	cfg.GetString(key2, buffer1, sizeof(buffer1), ";");

	Format(key2, sizeof(key2), "max%s", key);
	cfg.GetString(key2, buffer2, sizeof(buffer2), ";");

	if(buffer1[0] == ';')
	{
		if(buffer2[0] == ';')
			strcopy(buffer2, sizeof(buffer2), defaul);
		
		maxx = ParseFormula(buffer2, players);
		minn = maxx;
	}
	else if(buffer2[0] == ';')
	{
		minn = ParseFormula(buffer1, players);
		maxx = minn;
	}
	else
	{
		minn = ParseFormula(buffer1, players);
		maxx = ParseFormula(buffer2, players);
	}
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
	//TODO: Find out if we need to check m_bDisguiseWeapon
	
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
			return true;
	}
	return false;
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