/*
	"rage_cloneattack"
	{
		"slot"				"0"			// Ability slot
		"amount"			"n/3 + 1"	// Amount of clones to summon
		"die on boss death"	"true"		// If clones die when the boss dies
		"allow bosses"		"false"		// Allow bosses to become minions (in the process the boss becomes normal player)
		"rival"				"false"		// Whether players will spawn on ally or rival team
		"move to spawn"		"false"		// Whether player should be moved to spawnroom
		"low prio"			"false"		// If clones can be resummoned while still alive and bypasses "allow bosses" (if true, does not resummon other low prio)
		"high prio"			"false"		// If the clone is NOT considered a minion
		"weapons only"		"false"		// If the clone is NOT considered a boss (will use config to setup, then removed after)

		"character"
		{
			// Boss Config
		}
		
		"plugin_name"		"ff2r_default_abilities"
	}
	
	
	"rage_explosive_dance"
	{
		"slot"			"0"		// Ability slot
		"initial"		"0.15"	// Initial delay before explosions
		"delay"			"0.12"	// Delay between ticks
		"count"			"35"	// Amount of ticks
		"taunt"			"true"	// Force taunt on first explosion
		
		"amount"		"5"		// Amount of explosions per a tick
		"damage"		"180.0"	// Explosion damage force
		"distance"		"350.0"	// Max spawn distance from the boss
		"magnitude"		"280"	// Explosion magnitude
		"radius"		"200"	// Explosion radius
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"rage_instant_teleport"
	{
		"slot"			"0"		// Ability slot
		"friendly"		"false"	// If to prefer teleporting to allies
		"stun"			"2.0"	// Self stun time
		"slowdown"		"0.0"	// Stun slowdown
		"flags"			"97"	// Stun flags
		"sound"			"false"	// Stun sound
		"particle"		""		// Stun particle effect
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"rage_tradespam"
	{	
		"slot"			"0"									// Ability slot
		"path"			"freak_fortress_2/demopan/trade_"	// Filepath (Numbers are added to the end with the count)
		"duration"		"6.0"								// Overlay duration
		"blind"			"0"									// If to blind the player (1 = Last Only, 2 = All)
		"muffle"		"1"									// If to confuse the player (1 = Last Only, 2 = All)
		
		"count"			"12"		// Amount of phases
		"delay"			"1.0 / n"	// Delay between phases (n is phase here)
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	"sound_tradespam"
	{
		"ui/notification_alert.wav"
		{
			"mode"		"2"
			"channel"	"0"
			"volume"	"1.0"
		}
	}
	
	
	"rage_matrix_attack"
	{
		"slot"			"0"			// Ability slot
		"timescale"		"0.1"		// Server timescale
		"duration"		"6.0"		// Ability duration (Timescale taken into account)
		"initial"		"0.5"		// Initial delay between strikes (Timescale taken into account)
		"delay"			"2.0"		// Delay between strikes (Timescale taken into account)
		"speed"			"2012.0"	// Strike push force
		"distance"		"1500.0"	// Max strike distance
		"damage"		"850.0"		// Strike damage
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	"sound_time_speedup"
	{
		"replay/exitperformancemode.wav"	""
	}
	"sound_time_speeddown"
	{
		"replay/enterperformancemode.wav"	""
	}
	
	
	"rage_new_weapon"
	{
		"slot"			"0"								// Ability slot
		"classname"		"tf_weapon_compound_bow"		// Weapon classname
		"attributes"	"2 ; 3.0 ; 6 ; 0.5 ; 37 ; 0.0"	// Weapon attributes (Values can be formulas)
		"weapon slot"	"0"								// Weapon slot (Auto detects if removed)
		"index"			"1005"							// Weapon index
		"level"			"101"							// Weapon level
		"quality"		"5"								// Weapon quality
		"preserve"		"true"							// Preserve weapon attributes
		"rank"			"19"							// Weapon strange rank
		"clip"			"1"								// Weapon clip
		"ammo"			"n"								// Weapon ammo
		"max"			"5"								// Max weapon ammo (For forumla purposes)
		"show"			"true"							// Weapon visibility
		"worldmodel"	""								// Weapon worldmodel
		"alpha"			"255"							// Weapon alpha
		"red"			"255"							// Weapon red
		"green"			"255"							// Weapon green
		"blue"			"255"							// Weapon blue
		"class"			""								// Override class setup
		"force switch"	"false"							// Always force weapon switch
		"lifetime"		""								// Weapon lifetime (Won't replace weapon slot if used)
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"rage_overlay"
	{
		"slot"			"0"									// Ability slot
		"path"			"freak_fortress_2/demopan/trade_12"	// Filepath
		"duration"		"6.0"								// Overlay duration
		"blind"			"false"								// If to blind the player (For full-screen overlays)
		"muffle"		"true"								// If to confuse the player (For majority screen blocking overlays)
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"rage_stun"
	{
		"slot"			"0"			// Ability slot
		"delay"			"0.1"		// Ability delay
		"duration"		"2.25"		// Base stun duration
		"distance"		"800.0"		// Stun radius
		"flags"			"97"		// Stun flags
		"slowdown"		"0.34"		// Stun slowdown
		"sound"			"false"		// Stun sound
		"particle"		"yikes_fx"	// Stun particle effect
		"uber"			"0"			// Penerate Uber (1 = Uber, 2 = Quick-Fix, 3 = Both)
		"friendly"		""			// Friendly fire (Auto detects if removed)
		"basejumper"	"false"		// Removes base jumper effect
		"add"			"0.75"		// Duration added per player hit
		"max"			"6.0"		// Max stun duration
		"solo"			"2.5"		// Stun duration on single hit
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"rage_stunsg"
	{
		"slot"			"0"			// Ability slot
		"delay"			"0.1"		// Ability delay
		"duration"		"5.0"		// Base stun duration
		"distance"		"800.0"		// Stun radius
		"health"		"0.6"		// Building health multiplier
		"ammo"			"0.5"		// Building ammo/metal multiplier
		"rocket"		"0.4"		// Sentry rocket multiplier
		"particle"		"yikes_fx"	// Stun particle effect
		"building"		"1"			// Building types (1 = Sentry, 2 = Dispenser, 4 = Teleporter)
		"friendly"		""			// Friendly fire (Auto detects if removed)
		"add"			"1.0"		// Duration added per building hit
		"max"			"10.0"		// Max stun duration
		"solo"			"5.75"		// Stun duration on single hit
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"rage_uber"
	{
		"slot"			"0"		// Ability slot
		"duration"		"10.0"	// Base uration
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"spawn_many_objects_on_death"
	{
		"model"			"models/player/saxton_hale/w_easteregg.mdl"	// Pickup model
		"skin"			"1"											// Model skin
		"amount"		"4"											// Pickup count
		"distance"		"30.0"										// Spawn position offset upwards
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"spawn_many_objects_on_kill"
	{
		"model"			"models/player/saxton_hale/w_easteregg.mdl"	// Pickup model
		"skin"			"1"											// Model skin
		"amount"		"n / 3"										// Pickup count
		"distance"		"30.0"										// Spawn position offset upwards
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"special_anchor"
	{
		"basic"			"0.5"	// Crouch time before gaining knockback resistance
		"full"			"3.5"	// Crouch time before gaining stun & airblast resistance
		"speed"			"175.0"	// Movement speed while crouching (Capped at 173 HU/s by default TF2)
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"special_cbs_multimelee"
	{
		// Weapon indexes
		"1"				"171"
		"2"				"193"
		"3"				"232"
		"4"				"401"
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"special_democharge"
	{
		"slot"			"0"		// Charge slot
		"button"		"13"	// Button type (11=M2, 13=Reload, 25=M3)
		"minimum"		"10.0"	// Minimum charge amount
		"maximum"		"90.0"	// Maximum charge amount
		"rage"			"1.0"	// Charge to drain if within minimum and maximum
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"special_dissolve"
	{
		"plugin_name"	"ff2r_default_abilities"
	}
	
	
	"special_dropprop"
	{
		"model"				"models/freak_fortress_2/demopan/giant_shako.mdl"	// Model
		"remove ragdolls"	"true"												// Remove ragdoll
		"duration"			"120.0"												// Prop lifetime
		
		"plugin_name"		"ff2r_default_abilities"
	}
	
	
	"special_projectile_model"
	{
		"tf_projectile_pipe"
		{
			"model"	"models/player/saxton_hale/w_easteregg.mdl"
			"scale"	"1.0"
		}
		
		"plugin_name"			"ff2r_default_abilities"
	}
	
	
	"special_mobility"
	{
		"slot"				"1"						// Charge slot (Only used for sound_ability)
		"options"			"1"						// Mobility flags (1=Super Jump, 2=Teleport)
		"button"			"11"					// Button type (11=M2, 13=Reload, 25=M3)
		"charge"			"1.5"					// Time to fully charge
		"cooldown"			"5.0"					// Cooldown after use
		"delay"				"5.0"					// Delay before first use
		"upward"			"750 + (n * 3.25)"		// Super Jump upward velocity set (n=0.0 ~ 100.0)
		"forward"			"1.0 + (n * 0.00275)"	// Super Jump forward velocity multi (n=0.0 ~ 100.0)
		"emergency"			"2000.0"				// Super Jump upward velocity added when touching a hazard
		"stun"				"2.0"					// Teleport stun duration
		"flags"				"97"					// Teleport stun flags
		"slowdown"			"1.0"					// Teleport stun slowdown
		"sound"				"false"					// Teleport stun sound
		"particle"			""						// Teleport stun particle effect
		"reset on attack"	"false"					// Reset charge on attack
		"targets"			"3"						// Teleport targets (1=Teammates, 2=Enemies)
		
		"plugin_name"		"ff2r_default_abilities"
	}
	
	"sound_ability"
	{
		"vo/null.mp3"	"1"
	}
	
	"special_noanims"
	{
		"custom model animation"	"false"	// Playermodel plays animations
		"custom model rotates"		"true"	// Playermodel rotates
		
		"plugin_name"				"ff2r_default_abilities"
	}
	
	
	"special_weighdown"
	{
		"slot"			"2"			// Charge slot (Only used for sound_ability)
		"delay"			"3.0"		// Airtime before being able to use
		"gravity"		"6.0"		// Weighdown gravity
		"velocity"		"1000.0"	// Downward velocity
		
		"plugin_name"	"ff2r_default_abilities"
	}
	
	"sound_ability"
	{
		"vo/null.mp3"	"2"
	}
	
	
	"ff2r_default_abilities"
	{
		"health"	"1.0"
		"nolives"	"0"
		"nopassive"	"0"
		
		"multiply"
		{
		}
		"override"
		{
		}
	}
*/

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <cfgmap>
#include <ff2r>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define FAR_FUTURE		100000000.0

#define TF_PLAYER_ENEMY_BLASTED_ME (1 << 2)

Handle SDKEquipWearable;
Handle SDKGetMaxHealth;
Handle SDKSetSpeed;
Handle SDKSetBlastJumpState;
Handle SyncHud;

int PlayersAlive[4];
bool SpecTeam;

ArrayList BossTimers[MAXTF2PLAYERS];

bool SoloVictim[MAXTF2PLAYERS];

float SpecialUber[MAXTF2PLAYERS];

Handle OverlayTimer[MAXTF2PLAYERS];
bool OverlayMuffled[MAXTF2PLAYERS];

bool PlayerSuicide[MAXTF2PLAYERS];
int CloneOwner[MAXTF2PLAYERS];
int CloneLastTeam[MAXTF2PLAYERS];
bool CloneIdle[MAXTF2PLAYERS];
bool CloneLowPrio[MAXTF2PLAYERS];
bool CloneRemoveCfg[MAXTF2PLAYERS];
Handle CloneTimer[MAXTF2PLAYERS];

Handle TimescaleTimer;
float MatrixFor[MAXTF2PLAYERS];
float MatrixDelay[MAXTF2PLAYERS];
char MatrixName[MAXTF2PLAYERS][64];

MoveType LastMoveType[MAXTF2PLAYERS];

bool SpecialCharge[MAXTF2PLAYERS];
int SpecialChargeButton[MAXTF2PLAYERS];

bool MobilityEnabled[MAXTF2PLAYERS];

float WeighdownAirTimeAt[MAXTF2PLAYERS];
float WeighdownLastGravity[MAXTF2PLAYERS] = {-69.42, ...};
float WeighdownCurrentGravity[MAXTF2PLAYERS];

float AnchorStartTime[MAXTF2PLAYERS];
float AnchorLastAttrib[MAXTF2PLAYERS] = {-69.42, ...};

bool NoAbilities[MAXTF2PLAYERS];

ConVar CvarCheats;
ConVar CvarFriendlyFire;
ConVar CvarTimeScale;

#include "freak_fortress_2/customattrib.sp"
#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2items.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Default Abilities",
	author		=	"Batfoxkid",
	description	=	"Contains too much excitement!",
	version		=	PLUGIN_VERSION,
	url			=	"https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite"
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
	if(!TranslationPhraseExists("Boss Demo Charge 13"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
	
	delete gamedata;
	
	gamedata = new GameData("ff2");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	SDKSetSpeed = EndPrepSDKCall();
	if(!SDKSetSpeed)
		LogError("[Gamedata] Could not find CTFPlayer::TeamFortress_SetSpeed");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::SetBlastJumpState");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKSetBlastJumpState = EndPrepSDKCall();
	if (!SDKSetBlastJumpState)
		LogError("[Gamedata] Could not find CTFPlayer::SetBlastJumpState");
	
	delete gamedata;
	
	Attrib_PluginStart();
	CustomAttrib_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	VScript_PluginStart();
	
	SyncHud = CreateHudSynchronizer();
	
	CvarCheats = FindConVar("sv_cheats");
	CvarFriendlyFire = FindConVar("mp_friendlyfire");
	CvarTimeScale = FindConVar("host_timescale");
	
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_setup_finished", OnRoundStart, EventHookMode_PostNoCopy);
	
	AddCommandListener(OnKermitSewerSlide, "explode");
	AddCommandListener(OnKermitSewerSlide, "kill");
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
			
			BossData cfg = FF2R_GetBossData(client);
			if(cfg)
			{
				FF2R_OnBossCreated(client, cfg, false);
				FF2R_OnBossEquipped(client, true);
			}
		}
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(OverlayTimer[client])
				TriggerTimer(OverlayTimer[client]);
			
			if(FF2R_GetBossData(client))
				FF2R_OnBossRemoved(client);
		}
	}
}

public void OnMapStart()
{
	PrecacheSound("replay/enterperformancemode.wav");
	PrecacheSound("replay/exitperformancemode.wav");
}

public void OnMapEnd()
{
	if(TimescaleTimer)
		TriggerTimer(TimescaleTimer);
}

public void OnLibraryAdded(const char[] name)
{
	Attrib_LibraryAdded(name);
	CustomAttrib_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	VScript_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	CustomAttrib_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	VScript_LibraryRemoved(name);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	if(TimescaleTimer && !IsFakeClient(client))
		CvarCheats.ReplicateToClient(client, "1");
}

public void OnClientDisconnect(int client)
{
	SpecialUber[client] = 0.0;
	SoloVictim[client] = false;
	OverlayMuffled[client] = false;
	CloneOwner[client] = 0;
	CloneIdle[client] = false;
	CloneLowPrio[client] = false;
	delete CloneTimer[client];
	WeighdownLastGravity[client] = -69.42;
	AnchorLastAttrib[client] = -69.42;
	
	delete OverlayTimer[client];
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	bool changed;
	if(SpecialCharge[client] && SpecialChargeButton[client] > 11)
	{
		int button = (1 << SpecialChargeButton[client]);
		bool attack2 = view_as<bool>(buttons & IN_ATTACK2);
		bool pressed = view_as<bool>(buttons & button);
		
		if(!(attack2 && pressed))
		{
			if(attack2)
			{
				buttons &= ~IN_ATTACK2;
				buttons |= button;
				changed = true;
			}
			else if(pressed)
			{
				buttons &= ~button;
				buttons |= IN_ATTACK2;
				changed = true;
			}
		}
	}
	
	if(MatrixFor[client] && (buttons & IN_ATTACK) && IsPlayerAlive(client))
	{
		float gameTime = GetGameTime();
		if(MatrixFor[client] > gameTime)
		{
			bool block = true;
			if(MatrixDelay[client] < gameTime)
			{
				BossData boss = FF2R_GetBossData(client);
				AbilityData ability;
				if(boss && (ability = boss.GetAbility(MatrixName[client])))
				{
					int team1 = CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client);
					int alive = TotalPlayersAliveEnemy(team1);
					float timescale = CvarTimeScale.FloatValue;
					
					MatrixDelay[client] = gameTime + (GetFormula(ability, "delay", alive, 2.0) * timescale);
					
					FF2R_StartLagCompensation(client);
					
					float pos[3], vec[3];
					GetClientEyePosition(client, pos);
					
					Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitSelf, client);
					TR_GetEndPosition(vec, trace);
					
					vec[2] += 100;
					float distance = GetVectorDistance(pos, vec, true);
					float speed = GetFormula(ability, "speed", alive, 2012.0);
					float maximum = GetFormula(ability, "distance", alive, 1500.0);
					maximum = maximum * maximum;
					
					if(distance > maximum)
						ConstrainDistance(pos, vec, distance, maximum);
					
					SubtractVectors(vec, pos, vec);
					NormalizeVector(vec, vec);
					ScaleVector(vec, speed);
					TeleportEntity(client, _, _, vec);
					
					bool finished;
					if(distance < maximum)
					{
						int target = TR_GetEntityIndex(trace);
						if(target > 0 && target <= MaxClients)
						{
							int team2 = GetClientTeam(target);
							if(SpecTeam || team2 > view_as<int>(TFTeam_Spectator))
							{
								bool friendly = (team1 == team2);
								if(friendly || !IsInvuln(target))
								{
									if(friendly)	// Lag compenstated location only if they damaged attack
									{
										finished = true;
										FF2R_FinishLagCompensation(client);
									}
									
									GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
									
									if(!finished)
									{
										finished = true;
										FF2R_FinishLagCompensation(client);
									}

									if(friendly || FF2R_GetGamemodeType() == 2 || !TF2U_IsInRespawnRoom(target))	// Don't teleport in spawn rooms on non-arena
									{
										if(!friendly)
										{
											SDKHooks_TakeDamage(target, client, client, GetFormula(ability, "damage", alive, 850.0), _, _, _, _, false);
											block = false;
										}
										
										SetEntProp(client, Prop_Send, "m_bDucked", true);
										SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
										TeleportEntity(client, pos);
									}
								}
							}
						}
					}
					
					delete trace;
					
					if(!finished)
						FF2R_FinishLagCompensation(client);
				}
				else
				{
					MatrixFor[client] = 0.0;
				}
			}
			
			if(block)
			{
				buttons &= ~IN_ATTACK;
				changed = true;
			}
		}
		else
		{
			MatrixFor[client] = 0.0;
		}
	}
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3])
{
	if(CloneIdle[client] && (buttons || vel[0] || vel[1] || vel[2]))
	{
		if(!TF2_IsPlayerInCondition(client, TFCond_HalloweenKartNoTurn))
		{
			TF2_RemoveCondition(client, TFCond_DisguisedAsDispenser);
			TF2_RemoveCondition(client, TFCond_UberchargedOnTakeDamage);
			TF2_RemoveCondition(client, TFCond_MegaHeal);
		}
	}
	
	if(AnchorStartTime[client])
	{
		if(IsPlayerAlive(client))
		{
			int flags = GetEntityFlags(client);
			if((flags & FL_ONGROUND) && (flags & FL_DUCKING))
			{
				float gameTime = GetGameTime();
				if(AnchorStartTime[client] == 1.0)
				{
					AnchorStartTime[client] = gameTime;
				}
				else
				{
					BossData boss = FF2R_GetBossData(client);
					AbilityData ability;
					if(boss && (ability = boss.GetAbility("special_anchor")))
					{
						if(AnchorStartTime[client] < (gameTime - ability.GetFloat("full", 3.5)))
						{
							TF2_AddCondition(client, TFCond_MegaHeal, 0.05, client);
							if(SDKSetSpeed && GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 5.0)
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", ability.GetFloat("speed", 175.0) * 3.0);
						}
						else if(AnchorStartTime[client] < (gameTime - ability.GetFloat("basic", 0.5)))
						{
							if(AnchorLastAttrib[client] == -69.42)
							{
								AnchorLastAttrib[client] = 1.0;
								Attrib_Get(client, "damage force reduction", AnchorLastAttrib[client]);
							}
							
							Attrib_Set(client, "damage force reduction", 0.0);
							TF2_AddCondition(client, TFCond_InHealRadius, 0.05, client);
							if(SDKSetSpeed && GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 5.0)
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", ability.GetFloat("speed", 175.0) * 3.0);
						}
					}
					else
					{
						AnchorStartTime[client] = 0.0;
					}
				}
			}
			else if(AnchorStartTime[client] != 1.0)
			{
				AnchorStartTime[client] = 1.0;
				if(SDKSetSpeed)
					SDKCall(SDKSetSpeed, client);
			}
		}
		else
		{
			AnchorStartTime[client] = 1.0;
		}
	}
	
	if(AnchorLastAttrib[client] != -69.42 && AnchorStartTime[client] <= 1.0)
	{
		float value;
		if(!Attrib_Get(client, "damage force reduction", value) || !value)
			Attrib_Set(client, "damage force reduction", AnchorLastAttrib[client]);
		
		AnchorLastAttrib[client] = -69.42;
	}
	
	if(MobilityEnabled[client])
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_mobility")))
		{
			if(IsPlayerAlive(client))
			{
				float gameTime = GetGameTime();
				bool emergency = ability.GetFloat("emergencyfor") > gameTime;
				bool cooldown = ability.GetBool("incooldown", true);
				float timeIn = ability.GetFloat("delay");
				bool hud;
				
				if(cooldown)
				{
					if(timeIn < gameTime)
					{
						cooldown = false;
						timeIn = 0.0;
						
						ability.SetBool("incooldown", cooldown);
						ability.SetFloat("delay", timeIn);
						
						hud = true;
					}
				}
				else
				{
					int button = ability.GetInt("button", 11);
					if(SpecialCharge[client])
					{
						if(button == 11)
						{
							button = SpecialChargeButton[client];
						}
						else if(button == SpecialChargeButton[client])
						{
							button = 11;
						}
					}
					
					if(((buttons & IN_ATTACK) || (button != 11 && (buttons & IN_ATTACK2))) && ability.GetBool("reset on attack", false))
					{
						if(timeIn)
						{
							timeIn = 0.0;
							ability.SetFloat("delay", 0.0);
							
							hud = true;
						}
					}
					else if(buttons & (1 << button))
					{
						if(!timeIn)
						{
							timeIn = gameTime;
							ability.SetFloat("delay", timeIn);
							
							hud = true;
						}
					}
					else if(timeIn && (emergency || !TF2_IsPlayerInCondition(client, TFCond_Dazed)) && GetEntityMoveType(client) != MOVETYPE_NONE)
					{
						hud = true;
						
						button = ability.GetInt("options", 1);
						bool jump = view_as<bool>(button & 1);
						bool tele = view_as<bool>(button & 2);
						
						float charge = ability.GetFloat("charge", 1.5);
						if(charge < 0.001)
							charge = 0.001;
						
						charge = emergency ? 100.0 : ((gameTime - timeIn) / charge * 100.0);
						if(charge >= 100.0 && tele)
						{
							int target = -1;
							
							button = ability.GetInt("targets", 3);
							bool friendly = view_as<bool>(button & 1);
							bool enemies = view_as<bool>(button & 2);

							float pos1[3];

							if(!emergency)
							{
								FF2R_StartLagCompensation(client);
								
								GetClientEyePosition(client, pos1);
								
								Handle trace = TR_TraceRayFilterEx(pos1, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitSelf, client);
								TR_GetEndPosition(pos1, trace);
								delete trace;
							}
							
							float distance;
							float pos2[3];
							float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
							bool arena = FF2R_GetGamemodeType() == 2;
							int team1 = GetClientTeam(client);
							
							for(int i = 1; i <= MaxClients; i++)
							{
								if(i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
									continue;
								
								int team2 = GetClientTeam(i);
								
								if(!friendly)
								{
									if(team1 == team2)
										continue;
								}
								
								if(!enemies)
								{
									if(team1 != team2)
										continue;
								}

								// Don't teleport into spawn rooms
								if(team1 != team2 && !arena && TF2U_IsInRespawnRoom(target))
									continue;

								if(team1 > view_as<int>(TFTeam_Spectator) && !SpecTeam && team2 <= view_as<int>(TFTeam_Spectator))
									continue;
								
								if(scale < GetEntPropFloat(i, Prop_Send, "m_flModelScale"))
									continue;
								
								if(emergency)
								{
									target = i;
									break;
								}

								GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
								float dist = GetVectorDistance(pos1, pos2, true);
								if(target == -1 || dist < distance)
								{
									distance = dist;
									target = i;
								}
							}
							
							if(!emergency)
							{
								FF2R_FinishLagCompensation(client);
							}
							
							if(target != -1)
							{
								Rage_TeleportToTarget(client, target, ability);
								
								char buffer[8];
								if(ability.GetString("slot", buffer, sizeof(buffer)))
									FF2R_EmitBossSoundToAll("sound_ability", client, buffer, client, _, SNDLEVEL_TRAFFIC);
								
								cooldown = true;
								ability.SetBool("incooldown", cooldown);
								
								timeIn = gameTime + ability.GetFloat("cooldown", 5.0);
								ability.SetFloat("delay", timeIn);
							}
							else
							{
								timeIn = 0.0;
								ability.SetFloat("delay", 0.0);
							}
						}
						else if(jump && angles[0] < -20.0)
						{
							float velocity[3];
							GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
							
							int power = RoundToFloor(charge);
							if(power > 100)
								power = 100;
							
							static char buffer[512];
							
							ability.GetString("forward", buffer, sizeof(buffer), "1.0 + (n * 0.00275)");
							float velo = ParseFormula(buffer, power);
							velocity[0] *= velo;
							velocity[1] *= velo;
							
							ability.GetString("upward", buffer, sizeof(buffer), "750 + (n * 3.25)");
							velocity[2] = ParseFormula(buffer, power);

							if(emergency)
								velocity[2] += ability.GetFloat("emergency", 2000.0);
							
							TeleportEntity(client, _, _, velocity);
							
							SetEntProp(client, Prop_Send, "m_bJumping", true);

							SDKCall_SetJumpBlastState(client, TF_PLAYER_ENEMY_BLASTED_ME);
							TF2_AddCondition(client, TFCond_BlastJumping, _, client);
							
							if(ability.GetString("slot", buffer, sizeof(buffer)))
								FF2R_EmitBossSoundToAll("sound_ability", client, buffer, client, _, SNDLEVEL_TRAFFIC);
							
							cooldown = true;
							ability.SetBool("incooldown", cooldown);
							
							timeIn = gameTime + ability.GetFloat("cooldown", 5.0);
							ability.SetFloat("delay", timeIn);
						}
						else
						{
							timeIn = 0.0;
							ability.SetFloat("delay", 0.0);
						}
					}
				}
				
				if(!(buttons & IN_SCORE) && (hud || ability.GetFloat("hudin") < gameTime))
				{
					ability.SetFloat("hudin", gameTime + 0.09);
					
					int button = ability.GetInt("options", 1);
					bool jump = view_as<bool>(button & 1);
					bool tele = view_as<bool>(button & 2);
					
					if(jump || tele)
					{
						SetGlobalTransTarget(client);
						if(!emergency && cooldown)
						{
							float time = timeIn - gameTime + 0.09;
							if(time < 999.9)
							{
								SetHudTextParams(-1.0, 0.88, 0.1, 255, 64, 64, 255);
								if(jump && tele)
								{
									ShowSyncHudText(client, SyncHud, "%t", "Boss Mobility Time", time);
								}
								else if(tele)
								{
									ShowSyncHudText(client, SyncHud, "%t", "Boss Tele Time", time);
								}
								else
								{
									ShowSyncHudText(client, SyncHud, "%t", "Boss Jump Time", time);
								}
							}
						}
						else
						{
							button = ability.GetInt("button", 11);
							SetHudTextParams(-1.0, 0.88, 0.1, 255, 255, 255, 255);
							
							float charge = ability.GetFloat("charge", 1.5);

							if(timeIn)
							{
								if(emergency || jump || charge < 999.9)
								{
									if(charge < 0.001)
										charge = 0.001;
									
									charge = emergency ? 100.0 : ((gameTime - timeIn) / charge * 100.0);
									if(charge >= 100.0)
									{
										if(tele)
										{
											ShowSyncHudText(client, SyncHud, "%t%t", "Boss Tele Ready", 100, "Boss Tele Look");
										}
										else
										{
											ShowSyncHudText(client, SyncHud, "%t%t", "Boss Jump Ready", 100, "Boss Jump Look");
										}
									}
									else if(jump)
									{
										ShowSyncHudText(client, SyncHud, "%t%t", "Boss Jump Ready", RoundToCeil(charge), "Boss Jump Look");
									}
									else if(button >= 0)
									{
										char help[32];
										FormatEx(help, sizeof(help), "Boss Mobility %d", button);
										ShowSyncHudText(client, SyncHud, "%t%t", "Boss Tele Charge", RoundToCeil(charge), help);
									}
								}
							}
							else if(button >= 0 && (jump || charge < 999.9))
							{
								char help[32];
								FormatEx(help, sizeof(help), "Boss Mobility %d", button);
								
								if(jump && tele)
								{
									ShowSyncHudText(client, SyncHud, "%t%t", "Boss Mobility Charge", 0, help);
								}
								else if(tele)
								{
									ShowSyncHudText(client, SyncHud, "%t%t", "Boss Tele Charge", 0, help);
								}
								else
								{
									ShowSyncHudText(client, SyncHud, "%t%t", "Boss Jump Charge", 0, help);
								}
							}
						}
					}
				}
			}
		}
		else
		{
			MobilityEnabled[client] = false;
		}
	}
	
	if(WeighdownLastGravity[client] != -69.42)
	{
		int flags = GetEntityFlags(client);
		if((flags & FL_ONGROUND) || (flags & (FL_SWIM|FL_INWATER)))
		{
			if(GetEntityGravity(client) == WeighdownCurrentGravity[client])
				SetEntityGravity(client, WeighdownLastGravity[client]);
			
			WeighdownLastGravity[client] = -69.42;
		}
	}
	else if(WeighdownAirTimeAt[client] && IsPlayerAlive(client))
	{
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			BossData boss = FF2R_GetBossData(client);
			AbilityData ability;
			if(boss && (ability = boss.GetAbility("special_weighdown")))
			{
				WeighdownAirTimeAt[client] = GetGameTime() + ability.GetFloat("delay", 3.0);
			}
			else
			{
				WeighdownAirTimeAt[client] = 0.0;
			}
		}
		
		if(WeighdownAirTimeAt[client] && (buttons & IN_DUCK) && angles[0] > 60.0 && WeighdownAirTimeAt[client] < GetGameTime() && !TF2_IsPlayerInCondition(client, TFCond_Dazed) && GetEntityMoveType(client) != MOVETYPE_NONE)
		{
			BossData boss = FF2R_GetBossData(client);
			AbilityData ability;
			if(boss && (ability = boss.GetAbility("special_weighdown")))
			{
				WeighdownAirTimeAt[client] = FAR_FUTURE;
				WeighdownLastGravity[client] = GetEntityGravity(client);
				WeighdownCurrentGravity[client] = ability.GetFloat("gravity", 6.0);
				
				SetEntityGravity(client, WeighdownCurrentGravity[client]);
				
				float velocity[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				velocity[2] = -ability.GetFloat("velocity", 1000.0);
				TeleportEntity(client, _, _, velocity);
			}
			else
			{
				WeighdownAirTimeAt[client] = 0.0;
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!StrContains(classname, "tf_projectile"))
		SDKHook(entity, SDKHook_SpawnPost, Hook_ProjectileSpawned);
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	switch(cond)
	{
		case TFCond_Charging:
		{
			if(SpecialCharge[client])
			{
				BossData boss = FF2R_GetBossData(client);
				AbilityData ability = boss.GetAbility("special_democharge");
				if(ability.IsMyPlugin())
				{
					char slot[8];
					ability.GetString("slot", slot, sizeof(slot), "0");
					float charge = GetBossCharge(boss, slot);
					
					int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
					
					if(GetFormula(ability, "minimum", alive, 10.0) < charge && GetFormula(ability, "maximum", alive, 90.0) > charge)
					{
						charge -= GetFormula(ability, "rage", alive, 1.0);
						if(charge < 0.0)
							charge = 0.0;
						
						SetBossCharge(boss, slot, charge);
					}
				}
				else
				{
					SpecialCharge[client] = false;
				}
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	switch(cond)
	{
		case TFCond_Dazed:
		{
			if(SoloVictim[client])
			{
				SoloVictim[client] = false;
				CPrintToChatAll("%t%t", "Prefix", "Boss Solo Rage Failure");
			}
		}
		case TFCond_DisguisedAsDispenser:
		{
			CloneIdle[client] = false;
		}
		case TFCond_UberchargedOnTakeDamage:
		{
			if(SpecialUber[client])
			{
				SpecialUber[client] = 0.0;
				SetEntProp(client, Prop_Data, "m_takedamage", 2);
			}
		}
	}
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(attacker > MaxClients || (!attacker && (inflictor || !(damagetype & DMG_FALL))))
	{
		if(MobilityEnabled[victim])
		{
			BossData boss = FF2R_GetBossData(victim);
			AbilityData ability;
			if(boss && (ability = boss.GetAbility("special_mobility")))
			{
				ability.SetBool("incooldown", true);
				ability.SetFloat("delay", 0.0);
				ability.SetFloat("emergencyfor", GetGameTime() + 1.5);
				return;
			}
			
			MobilityEnabled[victim] = false;
		}
		
		SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
}

public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
	if(!BossTimers[client])
		BossTimers[client] = new ArrayList();
	
	if(!setup || FF2R_GetGamemodeType() != 2)
	{
		AbilityData ability;
		if(!AnchorStartTime[client])
		{
			ability = cfg.GetAbility("special_anchor");
			if(ability.IsMyPlugin())
				AnchorStartTime[client] = 1.0;
		}
		
		if(!SpecialCharge[client])
		{
			ability = cfg.GetAbility("special_democharge");
			if(ability.IsMyPlugin())
			{
				SpecialCharge[client] = true;
				SpecialChargeButton[client] = ability.GetInt("button", 13);
				char buffer[24];
				switch(SpecialChargeButton[client]) {
					case 11:
						buffer = "Boss Demo Charge 11";
					
					case 25:
						buffer = "Boss Demo Charge 25";
					
					default:
					{
						buffer = "Boss Demo Charge 13";
						SpecialChargeButton[client] = 13;
					}
				}
				
				PrintCenterText(client, "%t", buffer);
				PrintToChat(client, "%t", buffer);
			}
		}
		
		if(!MobilityEnabled[client])
		{
			ability = cfg.GetAbility("special_mobility");
			if(ability.IsMyPlugin())
			{
				MobilityEnabled[client] = true;
				ability.SetFloat("delay", GetGameTime() + ability.GetFloat("delay", 5.0));
				SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			}
		}
		
		ability = cfg.GetAbility("special_weighdown");
		if(ability.IsMyPlugin())
			WeighdownAirTimeAt[client] = FAR_FUTURE;
	}
}

public void FF2R_OnBossRemoved(int client)
{
	MatrixFor[client] = 0.0;
	SpecialCharge[client] = false;
	WeighdownAirTimeAt[client] = 0.0;
	AnchorStartTime[client] = 0.0;
	NoAbilities[client] = false;
	CloneRemoveCfg[client] = false;
	
	int length = BossTimers[client].Length;
	for(int i; i<length; i++)
	{
		Handle timer = BossTimers[client].Get(i);

		delete timer;
	}
	
	delete BossTimers[client];
	
	for(int target = 1; target <= MaxClients; target++)
	{
		if(CloneOwner[target] == client)
			ForcePlayerSuicide(target);
	}
	
	if(MobilityEnabled[client])
	{
		MobilityEnabled[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
	
	if(SpecialUber[client])
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
}

public Action FF2R_OnAbilityPre(int client, const char[] ability, AbilityData cfg, bool &result)
{
	return NoAbilities[client] ? Plugin_Stop : Plugin_Continue;
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "rage_stunsg", false))
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(GetFormula(cfg, "delay", TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client))), Timer_RageStunSg, pack));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(ability);
	}
	else if(!StrContains(ability, "rage_stun", false))
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(GetFormula(cfg, "delay", TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client))), Timer_RageStun, pack));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(ability);
	}
	else if(!StrContains(ability, "rage_uber", false))
	{
		float duration = GetFormula(cfg, "duration", TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client)), 5.0);
		
		SpecialUber[client] = GetGameTime() + duration;
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, duration, client);
	}
	else if(!StrContains(ability, "rage_overlay", false))
	{
		char file[128];
		cfg.GetString("path", file, sizeof(file));
		
		int team = CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client);
		float duration = GetFormula(cfg, "duration", TotalPlayersAliveEnemy(team), 6.0);
		bool blind = cfg.GetBool("blind");
		bool muffle = cfg.GetBool("muffle");
		float distance = cfg.GetFloat("distance");
		distance = distance * distance;
		
		float pos1[3], pos2[3];
		GetClientEyePosition(client, pos1);

		int victims;
		int[] victim = new int[MaxClients - 1];
		SetVariantString(file);
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target != client && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != team)
			{
				GetClientEyePosition(target, pos2);
				if(GetVectorDistance(pos1, pos2, true) > distance)
					continue;
				
				delete OverlayTimer[target];

				AcceptEntityInput(target, "SetScriptOverlayMaterial", target, target);
				OverlayTimer[target] = CreateTimer(duration, Timer_RemoveOverlay, target);
				
				if(blind)
					victim[victims++] = target;
				
				OverlayMuffled[target] = muffle;
			}
		}

		if(victims)
		{
			BfWrite msg = view_as<BfWrite>(StartMessage("Fade", victim, victims));
			msg.WriteShort(100);
			msg.WriteShort(RoundFloat(duration * 500.0));
			msg.WriteShort(0x0001);
			msg.WriteByte(0);
			msg.WriteByte(0);
			msg.WriteByte(0);
			msg.WriteByte(255);
			EndMessage();
		}
	}
	else if(!StrContains(ability, "rage_instant_teleport", false))
	{
		bool friendly = cfg.GetBool("friendly");
		bool arena = FF2R_GetGamemodeType() == 2;
		int team1 = GetClientTeam(client);
		
		float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
		
		int victims;
		int[] victim = new int[MaxClients - 1];
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target == client || !IsClientInGame(target) || !IsPlayerAlive(target))
				continue;
			
			int team2 = GetClientTeam(target);
			if(!SpecTeam && team2 <= view_as<int>(TFTeam_Spectator))
				continue;
			
			if(friendly)
			{
				if(team1 != team2)
					continue;
			}
			else
			{
				if(team1 == team2)
					continue;
				
				if(!arena && TF2U_IsInRespawnRoom(target))
					continue;
			}
			
			if(GetEntPropFloat(target, Prop_Send, "m_flModelScale") < scale)
				continue;
			
			victim[victims++] = target;
		}
		
		if(!victims)
		{
			for(int target = 1; target <= MaxClients; target++)
			{
				if(target == client || !IsClientInGame(target) || !IsPlayerAlive(target))
					continue;
				
				int team2 = GetClientTeam(target);
				if(!SpecTeam && team2 <= view_as<int>(TFTeam_Spectator))
					continue;
				
				if(team1 != team2 && !arena && TF2U_IsInRespawnRoom(target))
					continue;
				
				if(GetEntPropFloat(target, Prop_Send, "m_flModelScale") < scale)
					continue;
				
				victim[victims++] = target;
			}
		}
		
		if(victims)
		{
			Rage_TeleportToTarget(client, victim[GetRandomInt(0, victims-1)], cfg);
		}
	}
	else if(!StrContains(ability, "rage_tradespam", false))
	{
		Rage_TradeSpam(client, cfg, ability, 1);
	}
	else if(!StrContains(ability, "rage_new_weapon", false))
	{
		Rage_NewWeapon(client, cfg, ability);
	}
	else if(!StrContains(ability, "rage_cloneattack", false))
	{
		Rage_CloneAttack(client, cfg);
	}
	else if(!StrContains(ability, "rage_matrix_attack", false))
	{
		Rage_MatrixAttack(client, cfg, ability);
	}
	else if(!StrContains(ability, "rage_explosive_dance", false))
	{
		LastMoveType[client] = GetEntityMoveType(client);
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(GetFormula(cfg, "initial", TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client)), 0.15), Timer_RageExplosiveDance, pack));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(ability);
		pack.WriteCell(0);
	}
}

public void FF2R_OnAliveChanged(const int alive[4], const int total[4])
{
	for(int i; i < 4; i++)
	{
		PlayersAlive[i] = alive[i];
	}
	
	SpecTeam = (total[TFTeam_Unassigned] || total[TFTeam_Spectator]);
}

public void FF2R_OnBossEquipped(int client, bool weapons)
{
	AbilityData ability = FF2R_GetBossData(client).GetAbility("special_noanims");
	if(ability.IsMyPlugin())
	{
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", ability.GetBool("custom model animation"));
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", ability.GetBool("custom model rotates"));
	}

	if(weapons && CloneRemoveCfg[client])
		RequestFrame(RemoveCloneCfg, GetClientUserId(client));
}

void RemoveCloneCfg(int userid)
{
	int client = GetClientOfUserId(userid);
	if(CloneRemoveCfg[client])
	{
		FF2R_SetBossData(client, null, true);
		SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", 0);
		Attrib_Remove(client, "major move speed bonus");
		Attrib_Remove(client, "max health additive bonus");
		Attrib_Remove(client, "healing received penalty");
		Attrib_Remove(client, "reduced_healing_from_medics");
	}
}

public void FF2R_OnBossModifier(int client, ConfigData cfg)
{
	BossData boss = FF2R_GetBossData(client);
	bool update;
	
	if(cfg.GetBool("nolives"))
	{
		int lives = boss.GetInt("lives");
		if(lives > 1)
		{
			boss.SetInt("lives", 1);
			boss.SetInt("livesleft", 1);
			
			int health = boss.GetInt("maxhealth");
			if(health)
			{
				boss.SetInt("maxhealth", health * lives);
			}
			else
			{
				float hp;
				Attrib_Get(client, "max health additive bonus", hp);
				
				hp += float(SDKCall_GetMaxHealth(client) * (lives - 1));
				
				Attrib_Set(client, "max health additive bonus", hp);
			}
			
			SetEntityHealth(client, GetClientHealth(client) * lives);
			update = true;
		}
	}
	
	float multi = cfg.GetFloat("health");
	if(multi > 0.0 && multi != 1.0)
	{
		int health = boss.GetInt("maxhealth");
		if(health)
		{
			boss.SetInt("maxhealth", RoundToZero(float(health) * multi));
		}
		else
		{
			float hp;
			Attrib_Get(client, "max health additive bonus", hp);
			
			hp += float(SDKCall_GetMaxHealth(client)) * (multi - 1.0);
			
			Attrib_Set(client, "max health additive bonus", hp);
		}
		
		SetEntityHealth(client, RoundToZero(float(GetClientHealth(client)) * multi));
		update = true;
	}
	
	if(cfg.GetBool("nopassive"))
	{
		NoAbilities[client] = true;
		AnchorStartTime[client] = 0.0;
		MobilityEnabled[client] = false;
		SpecialCharge[client] = false;
		
		if(boss.GetAbility("spawn_many_objects_on_kill").IsMyPlugin())
			boss.Remove("spawn_many_objects_on_kill");
	}
	
	ConfigData cfgsub = cfg.GetSection("multiply");
	if(cfgsub)
	{
		ModifiyBoss(boss, cfgsub, true);
		update = true;
	}
	
	cfgsub = cfg.GetSection("override");
	if(cfgsub)
	{
		ModifiyBoss(boss, cfgsub, false);
		update = true;
	}
	
	if(update)
		FF2R_UpdateBossAttributes(client);
}

static void ModifiyBoss(ConfigData boss, ConfigData cfg, bool type)
{
	StringMapSnapshot snap = cfg.Snapshot();
	
	int entries = snap.Length;
	if(entries)
	{
		PackVal val;
		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] ability = new char[length];
			snap.GetKey(i, ability, length);
			cfg.GetArray(ability, val, sizeof(val));
			switch(val.tag)
			{
				case KeyValType_Section:
				{
					if(val.cfg)
					{
						ConfigData sub = boss.GetSection(ability);
						if(sub)
						{
							ModifiyBoss(sub, view_as<ConfigData>(val.cfg), type);
						}
						else
						{
							boss.Remove(ability);
							
							val.cfg = val.cfg.Clone(FF2R_GetPluginHandle());
							boss.SetArray(ability, val, sizeof(val));
						}
					}
				}
				case KeyValType_Value:
				{
					if(type)
					{
						float value = boss.GetFloat(ability, -69.42);
						if(value != -69.42)
							boss.SetFloat(ability, value * StringToFloat(val.data));
					}
					else
					{
						boss.SetString(ability, val.data);
					}
				}
			}
		}
	}
	
	delete snap;
}

void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	if(victim)
	{
		if(SoloVictim[victim])
		{
			SoloVictim[victim] = false;
			CPrintToChatAll("%t%t", "Prefix", "Boss Solo Rage Success");
		}
		
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(victim != attacker && attacker > 0 && attacker <= MaxClients)
		{
			BossData boss = FF2R_GetBossData(attacker);
			if(boss)
			{
				AbilityData ability = boss.GetAbility("spawn_many_objects_on_kill");
				if(ability.IsMyPlugin())
					SpawnManyObjects(attacker, victim, ability);
				
				ability = boss.GetAbility("special_dissolve");
				if(ability.IsMyPlugin())
					CreateTimer(0.1, Timer_DissolveRagdoll, userid, TIMER_FLAG_NO_MAPCHANGE);
				
				ability = boss.GetAbility("special_cbs_multimelee");
				if(ability.IsMyPlugin())	// TODO: Change this for the "melee steal" ideaa
				{
					int index = -1;
					StringMapSnapshot snap = ability.Snapshot();
					
					int length = snap.Length - 1;
					if(length > 0)
					{
						int entry = GetURandomInt() % length;
						
						length = snap.KeyBufferSize(entry) + 1;
						char[] buffer = new char[length];
						snap.GetKey(entry, buffer, length);
						
						index = ability.GetInt(buffer, index);
					}
					
					delete snap;
					
					int entity = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
					if(IsValidEntity(entity))
					{
						char classname[36];
						if(GetEntityClassname(entity, classname, sizeof(classname)))
						{
							snap = boss.Snapshot();
							
							int entries = snap.Length;
							for(int i; i < entries; i++)
							{
								length = snap.KeyBufferSize(i) + 1;
								char[] buffer = new char[length];
								snap.GetKey(i, buffer, length);
								if(StrEqual(buffer, classname))
								{
									ConfigData cfg = boss.GetSection(buffer);
									if(index != -1)
										cfg.SetInt("index", index);
									
									Rage_NewWeapon(attacker, cfg, buffer);
									break;
								}
							}
							
							delete snap;
						}
					}
				}
				
				ability = boss.GetAbility("special_dropprop");
				if(ability.IsMyPlugin())
				{
					char model[128];
					ability.GetString("model", model, sizeof(model), "error.mdl");
					
					if(ability.GetBool("remove ragdolls"))
						CreateTimer(0.05, Timer_RemoveRagdoll, userid, TIMER_FLAG_NO_MAPCHANGE);
					
					int entity = CreateEntityByName("prop_physics_override");
					if(IsValidEntity(entity))
					{
						PrecacheModel(model);
						SetEntityModel(entity, model);
						SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
						SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
						SetEntProp(entity, Prop_Send, "m_usSolidFlags", 16);
						DispatchSpawn(entity);
						
						float pos[3];
						GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
						pos[2] += 20;
						TeleportEntity(entity, pos);
						
						float duration = GetFormula(ability, "duration", TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(attacker)), 0.0);
						if(duration > 0.5)
						{
							FormatEx(model, sizeof(model), "OnUser1 !self:Kill::%.1f:1", duration);
							SetVariantString(model);
							AcceptEntityInput(entity, "AddOutput");
							AcceptEntityInput(entity, "FireUser1");
						}
					}
				}
			}
		}
		
		BossData boss = FF2R_GetBossData(victim);
		if(boss)
		{
			AbilityData ability = boss.GetAbility("spawn_many_objects_on_death");
			if(ability.IsMyPlugin())
				SpawnManyObjects(victim, victim, ability);
		}
		
		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			for(int target = 1; target <= MaxClients; target++)
			{
				if(CloneOwner[target] == victim)
					ForcePlayerSuicide(target);
			}

			if(OverlayTimer[victim])
				TriggerTimer(OverlayTimer[victim]);
			
			delete CloneTimer[victim];
			CloneTimer[victim] = CreateTimer(0.5, Timer_RemoveCloneStatus, victim);
		}
	}
}

Action Timer_RemoveCloneStatus(Handle timer, int client)
{
	if(CloneOwner[client])
	{
		CloneOwner[client] = 0;
		FF2R_CreateBoss(client, null);
		ChangeClientTeam(client, CloneLastTeam[client]);
	}
	
	CloneIdle[client] = false;
	CloneLowPrio[client] = false;
	CloneTimer[client] = null;
	return Plugin_Continue;
}

void OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(!event.GetInt("weaponid")) 
	{
		int client = GetClientOfUserId(event.GetInt("ownerid"));
		if(client > 0 && client <= MaxClients && SpecialUber[client])
		{
			float duration = SpecialUber[client] + 1.5;
			
			SpecialUber[client] = 0.0;
			TF2_RemoveCondition(client, TFCond_UberchargedOnTakeDamage);
			
			SpecialUber[client] = duration;
			duration -= GetGameTime();
			TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, duration, client);
		}
	}
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		PlayerSuicide[client] = false;
	}
}

void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			BossData boss = FF2R_GetBossData(client);
			if(boss)
			{
				AbilityData ability = boss.GetAbility("special_mobility");
				if(ability.IsMyPlugin())
					ability.SetFloat("hudin", FAR_FUTURE);
			}
			
			CloneOwner[client] = 0;
			CloneIdle[client] = false;
			CloneLowPrio[client] = false;
			delete CloneTimer[client];
		}
	}
	
	if(TimescaleTimer)
		TriggerTimer(TimescaleTimer);
}

Action OnKermitSewerSlide(int client, const char[] command, int argc)
{
	// Punish kill binding during the round (pro or anti clone)
	PlayerSuicide[client] = true;
	return Plugin_Continue;
}

Action Hook_SetTransmit(int client, int target)
{
	if(client != target && target > 0 && target <= MaxClients && OverlayMuffled[target] && IsPlayerAlive(target))
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public void Hook_ProjectileSpawned(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && client <= MaxClients)
	{
		BossData boss = FF2R_GetBossData(client);
		if(boss)
		{
			AbilityData ability = boss.GetAbility("special_projectile_model");
			if(ability.IsMyPlugin())
			{
				char buffer[64];
				GetEntityClassname(entity, buffer, sizeof(buffer));
				ConfigData cfg = ability.GetSection(buffer);
				if(cfg)
				{
					if(cfg.GetString("model", buffer, sizeof(buffer)))
						SetEntityModel(entity, buffer);
					
					float scale = cfg.GetFloat("scale", 1.0);
					if(scale != 1.0 && scale > 0.0)
						SetEntPropFloat(entity, Prop_Send, "m_flModelScale", GetEntPropFloat(entity, Prop_Send, "m_flModelScale") * scale);
				}
			}
			else
			{
				ability = boss.GetAbility("model_projectile_replace");
				if(ability.IsMyPlugin())
				{
					char buffer[64];
					GetEntityClassname(entity, buffer, sizeof(buffer));
					if(ability.GetString(buffer, buffer, sizeof(buffer)))
						SetEntityModel(entity, buffer);
				}
			}
		}
	}
}

Action Timer_RageStun(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if(!client)
		return Plugin_Handled;
	
	// If we error out here, something went wrong somewhere else
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	
	char buffer[64];
	pack.ReadString(buffer, sizeof(buffer));
	
	BossData boss = FF2R_GetBossData(client);
	AbilityData cfg = boss.GetAbility(buffer);
	if(cfg.IsMyPlugin())
	{
		int team = GetClientTeam(client);
		bool friendly = cfg.GetBool("friendly", CvarFriendlyFire.BoolValue);
		int alive = TotalPlayersAliveEnemy(friendly ? -1 : team);
		
		float duration = GetFormula(cfg, "duration", alive, 5.0);
		float distance = GetFormula(cfg, "distance", alive, 800.0);
		distance = distance * distance;
		
		int flags = cfg.GetInt("flags", TF_STUNFLAGS_LOSERSTATE);
		float slowdown = GetFormula(cfg, "slowdown", alive, 0.34);
		bool sound = cfg.GetBool("sound");
		int uber = cfg.GetInt("uber");
		bool basejumper = cfg.GetBool("basejumper");
		float maxduration = GetFormula(cfg, "max", alive, duration);
		float addduration = GetFormula(cfg, "add", alive, 0.0);
		float soloduration = GetFormula(cfg, "solo", alive, duration);
		
		char particle[48];
		cfg.GetString("particle", particle, sizeof(particle), "yikes_fx");
		
		FF2R_StartLagCompensation(client);
		
		float pos1[3], pos2[3];
		GetClientEyePosition(client, pos1);
		
		int victims;
		int[] victim = new int[MaxClients - 1];
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target == client || !IsClientInGame(target) || !IsPlayerAlive(target))
				continue;
			
			if(!friendly)
			{
				if(GetClientTeam(target) == team)
					continue;
			}
			
			if(uber < 1 || uber == 2)
			{
				if(IsInvuln(target))
					continue;
			}
			
			if(uber < 2)
			{
				if(TF2_IsPlayerInCondition(target, TFCond_MegaHeal))
					continue;
			}
			
			GetClientEyePosition(target, pos2);
			if(GetVectorDistance(pos1, pos2, true) > distance)
				continue;
			
			victim[victims++] = target;
		}
		
		FF2R_FinishLagCompensation(client);
		
		if(victims == 0)
		{
			duration = 0.0;
		}
		else if(victims == 1)
		{
			duration = soloduration;
			SoloVictim[victim[0]] = true;
			
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target))
				{
					GetBossNameCfg(boss, buffer, sizeof(buffer), GetClientLanguage(target));
					CPrintToChatEx(target, client, "%t%t", "Prefix", "Boss Solo Rage", buffer);
				}
			}
		}
		else
		{
			duration += victims * addduration;
			if(duration > maxduration)
				duration = maxduration;
		}
		
		if(duration > 0.0)
		{
			for(int i; i<victims; i++)
			{
				if(basejumper)
					TF2_RemoveCondition(victim[i], TFCond_Parachute);
				
				TF2_StunPlayer(victim[i], duration * GetPlayerStunMulti(victim[i]), slowdown, flags, sound ? client : 0);
				
				if(particle[0])
					AttachParticle(victim[i], particle, duration);
			}
		}
	}

	return Plugin_Continue;
}

Action Timer_RageStunSg(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if(!client)
		return Plugin_Handled;
	
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	
	char buffer[64];
	pack.ReadString(buffer, sizeof(buffer));
	
	BossData boss = FF2R_GetBossData(client);
	AbilityData cfg = boss.GetAbility(buffer);
	if(cfg.IsMyPlugin())
	{
		int team = GetClientTeam(client);
		bool friendly = cfg.GetBool("friendly", CvarFriendlyFire.BoolValue);
		int alive = TotalPlayersAliveEnemy(friendly ? -1 : team);
		
		float duration = GetFormula(cfg, "duration", alive, 7.0);
		float distance = GetFormula(cfg, "distance", alive, 800.0);
		distance = distance * distance;
		
		float health = GetFormula(cfg, "health", alive, 0.6);
		float ammo = GetFormula(cfg, "ammo", alive, 0.5);
		float rockets = GetFormula(cfg, "rocket", alive, 0.4);
		
		int buildings = cfg.GetInt("building", 1);
		
		float maxduration = GetFormula(cfg, "max", alive, duration);
		float addduration = GetFormula(cfg, "add", alive, 0.0);
		float soloduration = GetFormula(cfg, "solo", alive, duration);
		
		char particle[48];
		cfg.GetString("particle", particle, sizeof(particle), "yikes_fx");
		
		float pos1[3], pos2[3];
		GetClientEyePosition(client, pos1);
		
		int victims;
		int[] victim = new int[MaxClients - 1];
		
		int entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "obj_*")) != -1)
		{
			GetEntityClassname(entity, buffer, sizeof(buffer));
			if(!StrContains(buffer, "obj_sentrygun"))
			{
				if(buildings != 1 && buildings != 4 && buildings != 5 && buildings < 7)
					continue;
			}
			else if(!StrContains(buffer, "obj_dispenser"))
			{
				if(buildings != 2 && buildings != 4 && buildings < 6)
					continue;
			}
			else if(!StrContains(buffer, "obj_teleporter"))
			{
				if(buildings != 3 && buildings < 5)
					continue;
			}
			
			if(GetEntProp(entity, Prop_Send, "m_bCarried") || GetEntProp(entity, Prop_Send, "m_bPlacing"))
				continue;
			
			if(!friendly)
			{
				if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == team)
					continue;
			}
			
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) > distance)
				continue;
			
			victim[victims++] = entity;
		}
		
		if(victims == 1)
		{
			duration = soloduration;
		}
		else if(victims)
		{
			duration += victims * addduration;
			if(duration > maxduration)
				duration = maxduration;
		}
		
		for(int i; i<victims; i++)
		{
			if(health > 0.0)
			{
				if(ammo != 1.0)
				{
					if(HasEntProp(victim[i], Prop_Send, "m_iAmmoShells"))
					{
						SetEntProp(victim[i], Prop_Send, "m_iAmmoShells", RoundToFloor(float(GetEntProp(victim[i], Prop_Send, "m_iAmmoShells")) * ammo));
					}
					else if(HasEntProp(victim[i], Prop_Send, "m_iAmmoMetal"))
					{
						SetEntProp(victim[i], Prop_Send, "m_iAmmoMetal", RoundToFloor(float(GetEntProp(victim[i], Prop_Send, "m_iAmmoMetal")) * ammo));
					}
				}
				
				if(rockets != 1.0 && HasEntProp(victim[i], Prop_Send, "m_iAmmoRockets"))
					SetEntProp(victim[i], Prop_Send, "m_iAmmoRockets", RoundToFloor(float(GetEntProp(victim[i], Prop_Send, "m_iAmmoRockets")) * rockets));
				
				if(duration > 0.0 && !GetEntProp(victim[i], Prop_Send, "m_bDisabled"))
				{
					SetEntProp(victim[i], Prop_Send, "m_bDisabled", true);
					CreateTimer(duration * GetBuildingStunMulti(victim[i]), Timer_EnableBuilding, EntIndexToEntRef(victim[i]), TIMER_FLAG_NO_MAPCHANGE);
				}
				
				if(health != 1.0)
					SDKHooks_TakeDamage(victim[i], client, client, GetEntProp(victim[i], Prop_Data, "m_iMaxHealth") * (1.0 - health), DMG_GENERIC, -1, _, _, false);
			}
			else
			{
				SDKHooks_TakeDamage(victim[i], client, client, GetEntProp(victim[i], Prop_Data, "m_iMaxHealth") * 4.0, DMG_GENERIC, -1, _, _, false);
			}
			
			if(particle[0] && duration > 0.0)
				AttachParticle(victim[i], particle, duration);
		}
	}
	return Plugin_Continue;
}

Action Timer_RageTradeSpam(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if(!client)
		return Plugin_Handled;
	
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	
	char buffer[64];
	pack.ReadString(buffer, sizeof(buffer));
	
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility(buffer);
	if(ability.IsMyPlugin())
		Rage_TradeSpam(client, ability, buffer, pack.ReadCell());

	return Plugin_Handled;
}

void Rage_TradeSpam(int client, ConfigData cfg, const char[] ability, int phase)
{
	char file[128];
	cfg.GetString("path", file, sizeof(file), "freak_fortress_2/demopan/trade_");
	
	int team = CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client);
	
	
	float duration = GetFormula(cfg, "duration", TotalPlayersAliveEnemy(team), 6.0);
	bool more = cfg.GetInt("count", 12) > phase;
	int blind = cfg.GetInt("blind");
	int muffle = cfg.GetInt("muffle", 1);
	float distance = cfg.GetFloat("distance");
	distance = distance * distance;
	
	float pos1[3], pos2[3];
	GetClientEyePosition(client, pos1);
	
	int victims;
	int[] victim = new int[MaxClients - 1];

	char temp[128];
	FormatEx(temp, sizeof(temp), "%s%d", file, phase);
	SetVariantString(temp);
	for(int target = 1; target <= MaxClients; target++)
	{
		if(target != client && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != team)
		{
			GetClientEyePosition(target, pos2);
			if(GetVectorDistance(pos1, pos2, true) > distance)
				continue;
			
			delete OverlayTimer[target];

			AcceptEntityInput(target, "SetScriptOverlayMaterial", target, target);
			
			OverlayTimer[target] = CreateTimer(duration, Timer_RemoveOverlay, target);
			
			victim[victims++] = target;
			
			OverlayMuffled[target] = (muffle > 1 || (!more && muffle));
		}
	}
	
	
	if(victims)
	{
		FF2R_EmitBossSound(victim, victims, "sound_tradespam", client);
		
		if(blind > 1 || (!more && blind))
		{
			BfWrite msg = view_as<BfWrite>(StartMessage("Fade", victim, victims));
			msg.WriteShort(100);
			msg.WriteShort(RoundFloat(duration * 500.0));
			msg.WriteShort(0x0001);
			msg.WriteByte(0);
			msg.WriteByte(0);
			msg.WriteByte(0);
			msg.WriteByte(255);
			EndMessage();
		}
	}
	
	if(more)
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(GetFormula(cfg, "delay", phase, 0.5), Timer_RageTradeSpam, pack));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(ability);
		pack.WriteCell(phase + 1);
	}
}

void Rage_NewWeapon(int client, ConfigData cfg, const char[] ability)
{
	static char classname[36];
	if(!cfg.GetString("classname", classname, sizeof(classname)))
		cfg.GetString("name", classname, sizeof(classname), ability);
	
	TFClassType class = TF2_GetPlayerClass(client);
	GetClassWeaponClassname(class, classname, sizeof(classname));
	bool wearable = StrContains(classname, "tf_weap") != 0;

	float lifetime = cfg.GetFloat("lifetime");

	int slot = wearable ? TFWeaponSlot_Item2 : cfg.GetInt("weapon slot", -99);
	if(slot == -99)
		slot = TF2_GetClassnameSlot(classname);
	
	if(!wearable && lifetime <= 0.0)
	{
		if(slot >= 0 && slot < 6)
			TF2_RemoveWeaponSlot(client, slot);
	}
	
	int entity = TF2Items_CreateFromCfg(client, classname, cfg, _, true);

	if(entity != -1 && !wearable)
	{
		if(lifetime > 0.0)
		{
			// Sets this weapon as the main weapon to switch to in this slot
			// Swaps weapons in m_hMyWeapons to do this
			
			int lowestSlot = -1;
			int lowestEnt = -1;
			int currentSlot = -1;

			static int length;
			if(!length)
				length = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
			
			char classname2[36];
			for(int i; i < length; i++)
			{
				int other = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if(other == entity)
				{
					currentSlot = i;

					if(lowestSlot != -1)
						break;
				}
				else if(lowestSlot == -1 && other != -1 && GetEntityClassname(other, classname2, sizeof(classname2)) && TF2_GetClassnameSlot(classname2) == slot)
				{
					lowestSlot = i;
					lowestEnt = other;

					if(currentSlot != -1)
						break;
				}
			}

			if(lowestSlot != -1 && currentSlot != -1)
			{
				SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", lowestEnt, currentSlot);
				SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", entity, lowestSlot);
			}
		}

		if(cfg.GetBool("force switch"))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
		}
		else
		{
			TF2U_SetPlayerActiveWeapon(client, entity);
		}
	}

	if(lifetime > 0.0)
	{
		DataPack pack;
		CreateDataTimer(lifetime, Timer_RemoveItem, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(wearable);
	}
}

Action Timer_RemoveItem(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity != INVALID_ENT_REFERENCE)
	{
		int client = GetClientOfUserId(pack.ReadCell());
		if(client)
		{
			if(pack.ReadCell())
			{
				TF2_RemoveWearable(client, entity);
			}
			else
			{
				if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == entity)
				{
					static int length;
					if(!length)
						length = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

					for(int i; i < length; i++)
					{
						int other = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
						if(other != entity)
						{
							if(HasEntProp(entity, Prop_Send, "m_iWeaponState")) //Reset minigun-like weapons
							{
								SetEntProp(entity, Prop_Send, "m_iWeaponState", 0);
								TF2_RemoveCondition(client, TFCond_Slowed);
							}

							TF2U_SetPlayerActiveWeapon(client, other);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", other);
							break;
						}
					}
				}

				TF2_RemoveItem(client, entity);
			}
		}
	}
	return Plugin_Continue;
}

void Rage_CloneAttack(int client, ConfigData cfg)
{
	int team1 = GetClientTeam(client);
	int amount = RoundToCeil(GetFormula(cfg, "amount", TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : team1), 1.0));
	if(amount > 0)
	{
		float pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
		int owner = cfg.GetBool("die on boss death", true) ? client : -1;
		bool allowBosses = cfg.GetBool("allow bosses", false);
		bool lowPrio = cfg.GetBool("low prio", false);

		ConfigData minion = cfg.GetSection("character");
		
		int victims;
		int[][] victim = new int[MaxClients - 1][2];
		for(int target = 1; target <= MaxClients; target++)
		{
			if(client == target || !IsClientInGame(target))
				continue;
			
			if(CloneLowPrio[target])
			{
				// Don't resummon low prio
				if(lowPrio)
					continue;
			}

			if(FF2R_GetBossData(target))
			{
				// Don't summon bosses (unless low prio)
				if(!CloneLowPrio[target] && !allowBosses)
					continue;
			}
			
			int team2 = GetClientTeam(target);

			// +4 for the same team
			int points = (team1 == team2) ? 4 : 0;

			if(IsPlayerAlive(target) && FF2R_GetClientMinion(target) != 2)
			{
				// Don't steal alive players
				if(team1 != team2)
					continue;
			}
			else
			{
				// Don't summon dead spectators
				if(team2 <= view_as<int>(TFTeam_Spectator))
					continue;
				
				// +2 for being dead already
				points += 2;
			}

			if(!PlayerSuicide[target])
			{
				// +1 for being a good person
				points++;
			}

			victim[victims][0] = target;
			victim[victims][1] = points;
			victims++;
		}
		
		if(victims)
		{
			if(victims > amount)
			{
				SortCustom2D(victim, victims, CloneSorting);
				victims = amount;
			}
			
			SpawnCloneList(victim, victims, minion, owner, team1, pos, cfg);
		}
	}
}

int CloneSorting(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if(elem1[1] > elem2[1])
		return -1;
	
	if(elem1[1] < elem2[1])
		return 1;
	
	return 0;
}

void SpawnCloneList(int[][] clients, int amount, ConfigData cfg, int owner, int team, const float pos[3], ConfigData ability)
{
	bool rivalTeam = ability.GetBool("rival", false);
	bool teleToSpawn = ability.GetBool("move to spawn", false);
	bool lowPrio = ability.GetBool("low prio", false);
	bool highPrio = ability.GetBool("high prio", false);
	bool weaponsOnly = (cfg && ability.GetBool("weapons only", false));
	
	if(rivalTeam)
		team = (team == 2) ? 3 : 2;
	
	float vel[3];
	for(int i; i < amount; i++)
	{
		int client = clients[i][0];
		
		if(!CloneOwner[client])
			CloneLastTeam[client] = GetClientTeam(client);
		
		CloneLowPrio[client] = lowPrio;
		CloneRemoveCfg[client] = weaponsOnly;
		delete CloneTimer[client];
		
		if(cfg)
		{
			FF2R_CreateBoss(client, cfg, team);
		}
		else
		{
			ChangeClientTeam(client, team);
		}

		FF2R_SetClientMinion(client, highPrio ? 0 : 1);
		
		CloneOwner[client] = owner;
		
		vel[0] = GetRandomFloat(-500.0, 500.0);
		vel[1] = GetRandomFloat(-500.0, 500.0);
		vel[2] = GetRandomFloat(300.0, 500.0);
		
		TF2_RespawnPlayer(client);
		SetEntProp(client, Prop_Send, "m_bDucked", true);
		SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);

		if(!teleToSpawn)
			TeleportEntity(client, pos, _, vel);
		
		// Lessen the strength cap between active and AFK players
		CloneIdle[client] = true;
		TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 2.0);
		TF2_AddCondition(client, TFCond_DisguisedAsDispenser, 20.0);
		TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, 20.0);
		TF2_AddCondition(client, TFCond_MegaHeal, 15.0);
		
		if(owner > 0)
			SDKHook(client, SDKHook_OnTakeDamage, CloneTakeDamage);

		ClientCommand(client, "playgamesound ui/system_message_alert.wav");
	}
}

Action CloneTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(CloneIdle[victim])
	{
		if(attacker > MaxClients && damage > 10.0)
		{
			if(CloneOwner[victim] > 0)
			{
				static const float vel[] = {90.0, 0.0, 0.0};
				
				float pos[3];
				GetEntPropVector(CloneOwner[victim], Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(victim, pos, _, vel);
				return Plugin_Handled;
			}
		}
	}
	else
	{
		SDKUnhook(victim, SDKHook_OnTakeDamage, CloneTakeDamage);
	}
	return Plugin_Continue;
}

void Rage_MatrixAttack(int client, ConfigData cfg, const char[] ability)
{
	int team = GetClientTeam(client);
	int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : team);
	float timescale = GetFormula(cfg, "timescale", alive, 0.1);
	if(timescale <= 0.0)
		timescale = 1.0;
	
	float duration = GetFormula(cfg, "duration", alive, 2.0) * timescale;
	
	char particle[48];
	if(cfg.GetString("particle", particle, sizeof(particle), team % 2 ? "scout_dodge_blue" : "scout_dodge_red"))
		AttachParticle(client, particle, duration);
	
	float gameTime = GetGameTime();
	MatrixFor[client] = gameTime + duration;
	MatrixDelay[client] = gameTime + (GetFormula(cfg, "initial", alive, 0.5) * timescale);
	strcopy(MatrixName[client], sizeof(MatrixName[]), ability);
	
	TimescaleSound(client, CvarTimeScale.FloatValue, timescale);
	
	CvarTimeScale.FloatValue = timescale;
	if(!TimescaleTimer)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && !IsFakeClient(target))
				CvarCheats.ReplicateToClient(target, "1");
		}
	}
	
	delete TimescaleTimer;
	
	TimescaleTimer = CreateTimer(duration, Timer_RestoreTime, GetClientUserId(client));
}

Action Timer_RestoreTime(Handle timer, int userid)
{
	TimescaleTimer = null;
	
	int client = GetClientOfUserId(userid);
	if(client && !FF2R_GetBossData(client))
		client = 0;
	
	TimescaleSound(client, CvarTimeScale.FloatValue, 1.0);
	
	CvarTimeScale.FloatValue = 1.0;
	if(!CvarCheats.BoolValue)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && !IsFakeClient(target))
				CvarCheats.ReplicateToClient(target, "0");
		}
	}
	return Plugin_Continue;
}

void TimescaleSound(int client, float current, float newvalue)
{
	if(current > newvalue)
	{
		if(!client || !FF2R_EmitBossSoundToAll("sound_time_speedup", client))
		{
			EmitSoundToAll("replay/enterperformancemode.wav");
			EmitSoundToAll("replay/enterperformancemode.wav");
		}
	}
	else if(current != newvalue)
	{
		if(!client || !FF2R_EmitBossSoundToAll("sound_time_speeddown", client))
		{
			EmitSoundToAll("replay/exitperformancemode.wav");
			EmitSoundToAll("replay/exitperformancemode.wav");
		}	
	}
}

Action Timer_RageExplosiveDance(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if(!client)
		return Plugin_Handled;
	
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	
	char buffer[64];
	pack.ReadString(buffer, sizeof(buffer));
	
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility(buffer);
	if(ability.IsMyPlugin())
		Rage_ExplosiveDance(client, ability, buffer, pack.ReadCell());

	return Plugin_Handled;
}

void Rage_ExplosiveDance(int client, ConfigData cfg, const char[] ability, int count)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}
	
	int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
	float damage = GetFormula(cfg, "damage", alive, 180.0);
	float distance = GetFormula(cfg, "distance", alive, 350.0);
	int magnitude = RoundFloat(GetFormula(cfg, "magnitude", alive, 280.0));
	int radius = RoundFloat(GetFormula(cfg, "radius", alive, 200.0));
	int amount = cfg.GetInt("amount", 5);
	
	if(count == 0 && cfg.GetBool("taunt", true))
		FakeClientCommand(client, "taunt");
	
	bool ground = view_as<bool>(GetEntityFlags(client) & FL_ONGROUND);
	
	float pos1[3], pos2[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
	for(int i; i < amount; i++)
	{
		int entity = CreateEntityByName("env_explosion");
		if(entity != -1)
		{
			DispatchKeyValueFloat(entity, "DamageForce", damage);
			SetEntProp(entity, Prop_Data, "m_iMagnitude", magnitude, 4);
			SetEntProp(entity, Prop_Data, "m_iRadiusOverride", radius, 4);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);

			DispatchSpawn(entity);
			
			pos2[0] = pos1[0] + GetRandomFloat(-distance, distance);
			pos2[1] = pos1[1] + GetRandomFloat(-distance, distance);
			
			if(ground)
			{
				pos2[2] = pos1[2] + GetRandomFloat(0.0, distance * 0.285714);
			}
			else
			{
				pos2[2] = pos1[2] + GetRandomFloat(distance * -0.428571, distance * 0.428571);
			}
			
			TeleportEntity(entity, pos2);
			AcceptEntityInput(entity, "Explode");
			AcceptEntityInput(entity, "kill");
		}
	}
	
	if(cfg.GetInt("count", 35) > count)
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(GetFormula(cfg, "delay", count, 0.12), Timer_RageExplosiveDance, pack));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(ability);
		pack.WriteCell(count + 1);
	}
	else
	{
		if(GetEntityMoveType(client) == MOVETYPE_NONE)
			SetEntityMoveType(client, LastMoveType[client]);
	}
}

void SpawnManyObjects(int client, int target, ConfigData cfg)
{
	char model[128];
	cfg.GetString("model", model, sizeof(model), "error.mdl");
	
	int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
	int skin = cfg.GetInt("skin");
	int amount = RoundFloat(GetFormula(cfg, "amount", alive, 14.0));
	float distance = GetFormula(cfg, "distance", alive, 30.0);
	
	static const float ang[] = {90.0, 0.0, 0.0};
	
	float pos[3], vel[3];
	GetClientAbsOrigin(target, pos);
	pos[2] += distance;
	for(int i; i < amount; i++)
	{
		int entity = CreateEntityByName("tf_ammo_pack");
		if(entity != -1)
		{
			SetEntityModel(entity, model);
			DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
			
			SetEntProp(entity, Prop_Send, "m_nSkin", skin);
			SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
			SetEntProp(entity, Prop_Send, "m_usSolidFlags", 152);
			SetEntProp(entity, Prop_Send, "m_triggerBloat", 24);
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				
			vel[0] = GetRandomFloat(-400.0, 400.0);
			vel[1] = GetRandomFloat(-400.0, 400.0);
			vel[2] = GetRandomFloat(300.0, 500.0);
			
			DispatchSpawn(entity);
			TeleportEntity(entity, pos, ang, vel);
			
			static int offset;
			if(!offset)
				offset = GetEntSendPropOffs(entity, "m_vecInitialVelocity", true);
			
			SetEntData(entity, offset - 4, 1, _, true);
			
			SDKHook(entity, SDKHook_StartTouch, Hook_PickupDelay);
			SDKHook(entity, SDKHook_Touch, Hook_PickupDelay);
			
			CreateTimer(1.0, Timer_PickupDelay, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action Timer_PickupDelay(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		SDKUnhook(entity, SDKHook_StartTouch, Hook_PickupDelay);
		SDKUnhook(entity, SDKHook_Touch, Hook_PickupDelay);
	}
	return Plugin_Continue;
}

Action Hook_PickupDelay(int entity, int client)
{
	return Plugin_Handled;
}

void Rage_TeleportToTarget(int client, int target, ConfigData cfg)
{
	int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
	float stun = GetFormula(cfg, "stun", alive, 2.0);
	
	if(stun > 0.0)
	{
		int flags = cfg.GetInt("flags", TF_STUNFLAGS_LOSERSTATE);
		float slowdown = GetFormula(cfg, "slowdown", alive, 1.0);
		bool sound = cfg.GetBool("sound");

		if(slowdown > 0.0)
			TF2_RemoveCondition(client, TFCond_MegaHeal);
		
		TF2_StunPlayer(client, stun, slowdown, flags, sound ? client : 0);
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + stun);

		TF2_AddCondition(target, TFCond_UberchargedHidden, 0.2, client);

		char particle[48];
		if(cfg.GetString("particle", particle, sizeof(particle)))
			AttachParticle(client, particle, stun);

		DataPack pack;
		CreateDataTimer(stun, Timer_RestoreCollision, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(GetEntProp(client, Prop_Send, "m_CollisionGroup"));

		SetEntityCollisionGroup(client, 2);
	}
	
	float pos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	
	SetEntProp(client, Prop_Send, "m_bDucked", true);
	SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
	TeleportEntity(client, pos, _, view_as<float>({0.0, 0.0, 0.0}));
}

Action Timer_EnableBuilding(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
		SetEntProp(entity, Prop_Send, "m_bDisabled", false);
	
	return Plugin_Continue;
}

Action Timer_RemoveOverlay(Handle timer, int client)
{
	OverlayTimer[client] = null;
	OverlayMuffled[client] = false;
	
	if(IsClientInGame(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetScriptOverlayMaterial", client, client);
	}
	return Plugin_Continue;
}

Action Timer_DissolveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(ragdoll))
		{
			int dissolver = CreateEntityByName("env_entity_dissolver");
			if(dissolver != -1)
			{
				DispatchKeyValue(dissolver, "dissolvetype", "0");
				DispatchKeyValue(dissolver, "magnitude", "200");
				DispatchKeyValue(dissolver, "target", "!activator");
				
				AcceptEntityInput(dissolver, "Dissolve", ragdoll);
				AcceptEntityInput(dissolver, "Kill");
			}
		}
	}
	return Plugin_Continue;
}

Action Timer_RemoveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(ragdoll))
			AcceptEntityInput(ragdoll, "Kill");
	}
	return Plugin_Continue;
}

Action Timer_RestoreCollision(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client && GetEntProp(client, Prop_Send, "m_CollisionGroup") == 2)
		SetEntityCollisionGroup(client, pack.ReadCell());
	
	return Plugin_Continue;
}

int TotalPlayersAliveEnemy(int team = -1)
{
	int amount;
	for(int i = SpecTeam ? 0 : 2; i < sizeof(PlayersAlive); i++)
	{
		if(i != team)
			amount += PlayersAlive[i];
	}
	
	return amount;
}

float GetPlayerStunMulti(int client)
{
	int health = GetClientHealth(client);
	float multi = float(health);
	if(multi > 525.0)
		multi = 525.0;
	
	// 1 HP = x1.15
	// 150 HP = x1.0
	// 300 HP = x0.85
	multi = 1.15 - (multi * 0.001);
	
	// Ranged damage attributes
	multi *= Attrib_FindOnPlayer(client, "dmg taken from fire reduced", true) *
			 Attrib_FindOnPlayer(client, "dmg taken from fire increased", true) *
			 Attrib_FindOnPlayer(client, "dmg taken from blast reduced", true) *
			 Attrib_FindOnPlayer(client, "dmg taken from blast increased", true) *
			 Attrib_FindOnPlayer(client, "dmg taken from bullets reduced", true) *
			 Attrib_FindOnPlayer(client, "dmg taken from bullets increased", true) *
			 Attrib_FindOnPlayer(client, "dmg taken increased", true) *
			 Attrib_FindOnPlayer(client, "SET BONUS: dmg taken from fire reduced set bonus", true) *
			 Attrib_FindOnPlayer(client, "SET BONUS: dmg taken from bullets increased", true) *
			 Attrib_FindOnPlayer(client, "CARD: dmg taken from bullets reduced", true);
	
	// Mark-for-Death = x1.35
	if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) ||
	   TF2_IsPlayerInCondition(client, TFCond_MarkedForDeathSilent) ||
	   TF2_IsPlayerInCondition(client, TFCond_PasstimePenaltyDebuff))
		multi *= 1.35;
	
	// Ranged damage attributes
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	multi *= Attrib_FindOnWeapon(client, active, "dmg from ranged reduced", true) *
			 Attrib_FindOnWeapon(client, active, "dmg taken from fire reduced on active", true) *
			 Attrib_FindOnWeapon(client, active, "mult_dmgtaken_active", true);
	
	if(TF2_IsPlayerInCondition(client, TFCond_Slowed) && health < SDKCall_GetMaxHealth(client) / 2)
		multi *= Attrib_FindOnWeapon(client, active, "spunup_damage_resistance", true);
	
	return multi;
}

float GetBuildingStunMulti(int entity)
{
	if(GetEntProp(entity, Prop_Send, "m_bMiniBuilding"))
		return 0.8;
	
	return 0.9 + (float(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel")) * 0.1);
}

float GetFormula(ConfigData cfg, const char[] key, int players, float defaul = 0.0)
{
	static char buffer[1024];
	if(!cfg.GetString(key, buffer, sizeof(buffer)))
		return defaul;
	
	return ParseFormula(buffer, players);
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

int SDKCall_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
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

void SDKCall_SetJumpBlastState(int client, int state)
{
	if(SDKSetBlastJumpState)
		SDKCall(SDKSetBlastJumpState, client, state, false);
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

int AttachParticle(int entity, const char[] name, float lifetime)
{
	int particle = CreateEntityByName("info_particle_system");
	if(particle != -1)
	{
		float position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		position[2] += 75.0;
		TeleportEntity(particle, position);
		
		DispatchKeyValue(particle, "effect_name", name);
		DispatchSpawn(particle);
		
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%.1f:1", lifetime);
		SetVariantString(buffer);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
	return particle;
}

void ConstrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
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

TFClassType GetClassOfName(const char[] buffer)
{
	TFClassType class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
		class = TF2_GetClass(buffer);
	
	return class;
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

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
{
	if(StrEqual(classname, "player"))
	{
		return -1;
	}
	else if(StrEqual(classname, "tf_weapon_scattergun") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_primary") ||
	   StrEqual(classname, "tf_weapon_soda_popper") ||
	   StrEqual(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	   StrEqual(classname, "tf_weapon_particle_cannon") ||
	   StrEqual(classname, "tf_weapon_flamethrower") ||
	   StrEqual(classname, "tf_weapon_grenadelauncher") ||
	   StrEqual(classname, "tf_weapon_cannon") ||
	   StrEqual(classname, "tf_weapon_minigun") ||
	   StrEqual(classname, "tf_weapon_shotgun_primary") ||
	   StrEqual(classname, "tf_weapon_sentry_revenge") ||
	   StrEqual(classname, "tf_weapon_drg_pomson") ||
	   StrEqual(classname, "tf_weapon_shotgun_building_rescue") ||
	   StrEqual(classname, "tf_weapon_syringegun_medic") ||
	   StrEqual(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	   StrEqual(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_secondary") ||
	   StrEqual(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	   StrEqual(classname, "tf_weapon_buff_item") ||
	   StrEqual(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	   StrEqual(classname, "tf_weapon_laser_pointer") ||
	   StrEqual(classname, "tf_weapon_mechanical_arm") ||
	   StrEqual(classname, "tf_weapon_medigun") ||
	   StrEqual(classname, "tf_weapon_smg") ||
	   StrEqual(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_r"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(StrEqual(classname, "tf_weapon_sa"))	// Sapper
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

public bool TraceRay_DontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}
