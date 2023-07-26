/*
	"rage_ability_management"
	{
		"slot"		"0"			// Ability slot, if 0, will override "ragemode" and "ragemin" values
		"altfire"	"false"		// Can use alt-fire to activate/cycle abilities
		"reload"	"true"		// Can use reload to activate/cycle abilities
		"special"	"true"		// Can use special attack to activate/cycle abilities
		"cycler"	"false"		// Force to use a cycler regardless of other factors
		
		"spells"
		{
			"0"	// Sorted in number and ABC order
			{
				"name"		"RAGE"				// Name, can use "name_en", etc. If left blank, section name is used instead
				"desc"		"Use your magic"	// Description, can use "desc_en", etc.
				"delay"		"10.0"				// Initial cooldown
				"cooldown"	"30.0"				// Cooldown on use
				"cost"		"100.0"				// RAGE cost to use
				"consume"	"true"				// Consumes RAGE on use
				"flags"		"0x0003"			// Casting flags
				// 0x0001: Magic (Sapper effect prevents casting)
				// 0x0002: Mind (Stun effects DOESN'T prevent casting)
				// 0x0004: Summon (Requires a dead summonable player to cast)
				// 0x0008: Partner (Requires a teammate boss alive to cast)
				// 0x0010: Last Life (Requires a single life left to cast)
				// 0x0020: Grounded (Requires being on the ground to cast)
				
				"cast_low"	"8"	// Lowest ability slot to activate on cast. If left blank, "cast_high" is used
				"cast_high"	"8"	// Highest ability slot to activate on cast. If left blank, "cast_low" is used
				
				"nocast_low"	"9"	// Lowest ability slot to activate trying to cast but unable. If left blank, "nocast_high" is used
				"nocast_high"	"9"	// Lowest ability slot to activate trying to cast but unable. If left blank, "nocast_low" is used
			}
		}
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"rage_dodge_hitscan"
	{
		"slot"			"0"	// Ability slot
		
		"duration"		"7.5"	// Duration (Timescale taken into account)
		"timescale"		"0.5"	// Server timescale
		"speed"			"520.0"	// Movement speed (Capped at 520 HU/s by default TF2)
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	"sound_time_speedup"
	{
		"replay/exitperformancemode.wav"	""
	}
	"sound_time_speeddown"
	{
		"replay/enterperformancemode.wav"	""
	}
	
	
	"rage_random_slot"
	{
		"slot"			"0"	// Ability slot
		
		"low"			"10"	// Lowest slot to activate
		"high"			"14"	// Highest slot to activate
		"count"			"1"		// How many unique slots to activate
		"repeat"		"false"	// If can cast the same slot when count is enabled
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"rage_weapon_steal"
	{
		"slot"			"0"	// Ability slot
		
		"pickups"		"true"										// Can passively pick up weapons
		"classswap"		"true"										// If to swap to the correct class
		"animswap"		"true"										// If to swap animations to the correct class
		"hands"			"models/weapons/c_models/c_scout_arms.mdl"	// Arm model if doing class swap, blank to use default
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"special_razorback_shield"
	{
		"secondary"		"false"	// Use secondary weapon slot instead of primary
		"durability"	"2250"	// Damage that can be absorbed before breaking
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"special_wall_jump"
	{
		"walljumps"		"true"	// If to allow wall jumps
		"stale"			"false"	// Wall jump cooldown increases each jump until landed
		
		// Applies on a wall jump
		"wall_jump"		"2.0"	// Jump height multiplier
		"wall_speed"	"1.3"	// Jump speed multiplier (Capped at 520 HU/s by default TF2)
		"wall_air"		"10.0"	// Air control multiplier that decays over time
		"double"		"true"	// Restore double jumps after wall jump
		
		// Applies on a double jump
		"double_jump"	"1.0"	// Jump height multiplier
		"double_speed"	"1.3"	// Jump speed multiplier (Capped at 520 HU/s by default TF2)
		"double_air"	"5.0"	// Air control multiplier that decays over time
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"ff2r_epic_abilities"
	{
		"nopassive"	"0"
	}
*/

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <dhooks>
#include <adt_trie_sort>
#include <cfgmap>
#include <ff2r>
#include <tf2attributes>
#include <tf_econ_data>
#undef REQUIRE_PLUGIN
#tryinclude <tf2utils>

#pragma semicolon 1
#pragma newdecls required

#include "freak_fortress_2/formula_parser.sp"

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define FAR_FUTURE		100000000.0

#define TF2U_LIBRARY	"nosoop_tf2utils"

#define	HITGROUP_GENERIC	0
#define	HITGROUP_HEAD		1
#define	HITGROUP_CHEST		2
#define	HITGROUP_STOMACH	3
#define HITGROUP_LEFTARM	4
#define HITGROUP_RIGHTARM	5
#define HITGROUP_LEFTLEG	6
#define HITGROUP_RIGHTLEG	7
#define HITGROUP_GEAR		10

#define AMS_DENYUSE	"common/wpn_denyselect.wav"
#define AMS_SWITCH	"common/wpn_moveselect.wav"
#define SHIELD_HIT	"Wood_Box.BulletImpact"
#define WALL_JUMP	"player/taunt_yeti_standee_engineer_kick.wav"

#define STEAL_REACT	"sound_steal_react"

#define MAG_MAGIC		0x0001	// Can be blocked by sapper effect
#define MAG_MIND		0x0002	// Can't be blocked by stun effects
#define MAG_SUMMON		0x0004	// Require dead players to use
#define MAG_PARTNER		0x0008	// Require an teammate to use
#define MAG_LASTLIFE	0x0010	// Require having no extra lives left
#define MAG_GROUND		0x0020	// Require being on the ground

enum
{
	EF_BONEMERGE			= 0x001,	// Performs bone merge on client side
	EF_BRIGHTLIGHT 			= 0x002,	// DLIGHT centered at entity origin
	EF_DIMLIGHT 			= 0x004,	// player flashlight
	EF_NOINTERP				= 0x008,	// don't interpolate the next frame
	EF_NOSHADOW				= 0x010,	// Don't cast no shadow
	EF_NODRAW				= 0x020,	// don't draw entity
	EF_NORECEIVESHADOW		= 0x040,	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= 0x080,	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK			= 0x100,	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES		= 0x200,	// always assume that the parent entity is animating
	EF_MAX_BITS = 10
};

#if defined __nosoop_tf2_utils_included
bool TF2ULoaded;
#endif

Handle SDKCanAirDash;
Handle SDKCreate;
Handle SDKEquipWearable;
Handle SDKGiveNamedItem;
Handle SDKInitDroppedWeapon;
Handle SDKInitPickedUpWeapon;
Handle SDKSetSpeed;
int PlayersAlive[4];
Handle SyncHud;
bool SpecTeam;

ConVar CvarDebug;
ConVar CvarCheats;
ConVar CvarFriendlyFire;
ConVar CvarTimeScale;
ConVar CvarUnlag;
ConVar CvarMaxUnlag;

bool HookedWeaponSwap[MAXTF2PLAYERS];

int HasAbility[MAXTF2PLAYERS];

Handle TimescaleTimer;
float DodgeFor[MAXTF2PLAYERS];
float DodgeSpeed[MAXTF2PLAYERS];

int BodyRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};
int WeapRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};
int HandRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};
TFClassType ClassSwap[MAXTF2PLAYERS];
bool AnimSwap[MAXTF2PLAYERS];
int HandSwap[MAXTF2PLAYERS];
bool CanPickup[MAXTF2PLAYERS];
int StealNext[MAXTF2PLAYERS];
int SetHealthTo[MAXTF2PLAYERS];

bool HookedRazorback;
UserMsg PlayerShieldBlocked;
int RazorbackDeployed[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};
int RazorbackRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};

bool WallInLagComp;
bool WallLagComped[MAXTF2PLAYERS];
bool WallJumper[MAXTF2PLAYERS];
int WallStale[MAXTF2PLAYERS];
float WallSpeedMulti[MAXTF2PLAYERS] = {1.0, ...};
float WallJumpMulti[MAXTF2PLAYERS] = {1.0, ...};
float WallAirMulti[MAXTF2PLAYERS] = {1.0, ...};

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Epic Abilities",
	author		=	"Batfoxkid",
	description	=	"You gotta be kidding me!",
	version		=	PLUGIN_VERSION,
	url			=	"https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite"
}

#if defined __nosoop_tf2_utils_included
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("TF2Util_EquipPlayerWearable");
	return APLRes_Success;
}
#endif

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	if(!TranslationPhraseExists("Boss Weapon Pickups"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	gamedata = new GameData("tf2.items");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKGiveNamedItem = EndPrepSDKCall();
	if(!SDKGiveNamedItem)
		LogError("[Gamedata] Could not find GiveNamedItem");
	
	delete gamedata;
	
	gamedata = new GameData("ff2");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::Create");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKCreate = EndPrepSDKCall();
	if(!SDKCreate)
		LogError("[Gamedata] Could not find CTFDroppedWeapon::Create");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::InitDroppedWeapon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	SDKInitDroppedWeapon = EndPrepSDKCall();
	if(!SDKInitDroppedWeapon)
		LogError("[Gamedata] Could not find CTFDroppedWeapon::InitDroppedWeapon");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::InitPickedUpWeapon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKInitPickedUpWeapon = EndPrepSDKCall();
	if(!SDKInitPickedUpWeapon)
		LogError("[Gamedata] Could not find CTFDroppedWeapon::InitPickedUpWeapon");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::CanAirDash");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	SDKCanAirDash = EndPrepSDKCall();
	if(!SDKCanAirDash)
		LogError("[Gamedata] Could not find CTFPlayer::CanAirDash");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	SDKSetSpeed = EndPrepSDKCall();
	if(!SDKSetSpeed)
		LogError("[Gamedata] Could not find CTFPlayer::TeamFortress_SetSpeed");
	
	CreateDetour(gamedata, "CTFPlayer::CanAirDash", CanAirDashPre, CanAirDashPost);
	CreateDetour(gamedata, "CTFPlayer::PickupWeaponFromOther", PickupWeaponFromOtherPre);
	
	delete gamedata;
	
	#if defined __nosoop_tf2_utils_included
	TF2ULoaded = LibraryExists(TF2U_LIBRARY);
	#endif
	
	PlayerShieldBlocked = GetUserMessageId("PlayerShieldBlocked");
	
	SyncHud = CreateHudSynchronizer();
	
	CvarCheats = FindConVar("sv_cheats");
	CvarFriendlyFire = FindConVar("mp_friendlyfire");
	CvarTimeScale = FindConVar("host_timescale");
	CvarUnlag = FindConVar("sv_unlag");
	CvarMaxUnlag = FindConVar("sv_maxunlag");
}

void CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback != INVALID_FUNCTION && !detour.Enable(Hook_Pre, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback != INVALID_FUNCTION && !detour.Enable(Hook_Post, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);
		
		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

public void OnAllPluginsLoaded()
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
	OnMapEnd();
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && FF2R_GetBossData(client))
			FF2R_OnBossRemoved(client);
	}
}

public void OnMapStart()
{
	PrecacheSound("replay/enterperformancemode.wav");
	PrecacheSound("replay/exitperformancemode.wav");
	PrecacheSound(WALL_JUMP);
}

public void OnMapEnd()
{
	if(TimescaleTimer)
		TriggerTimer(TimescaleTimer);
}

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	SetHealthTo[client] = 0;
	
	if(!CanPickup[client] && !ClassSwap[client])
	{
		AbilityData ability = boss.GetAbility("rage_weapon_steal");
		if(ability.IsMyPlugin())
		{
			if(ability.GetBool("classswap", true))
			{
				ClassSwap[client] = TF2_GetPlayerClass(client);
				
				char buffer[PLATFORM_MAX_PATH];
				ability.GetString("hands", buffer, sizeof(buffer));
				HandSwap[client] = buffer[0] ? PrecacheModel(buffer) : 0;
				AnimSwap[client] = ability.GetBool("animswap", false);
				
				if(!HookedWeaponSwap[client])
				{
					Debug("Hooked Swapping on %N", client);
					HookedWeaponSwap[client] = true;
					SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
				}
			}
			
			CanPickup[client] = (SDKGiveNamedItem && SDKInitPickedUpWeapon && ability.GetBool("pickups", true));
			if(CanPickup[client])
			{
				PrintCenterText(client, "%t", "Boss Weapon Pickups");
				PrintToChat(client, "%t", "Boss Weapon Pickups");
			}
		}
	}
	
	if(!setup || FF2R_GetGamemodeType() != 2)
	{
		if(!WallJumper[client] && SDKCanAirDash && SDKSetSpeed)
		{
			AbilityData ability = boss.GetAbility("special_wall_jump");
			if(ability.IsMyPlugin())
			{
				WallJumper[client] = true;
				PrintCenterText(client, "%t", "Boss Wall Jump");
				PrintToChat(client, "%t", "Boss Wall Jump");
			}
		}
		
		if(!HasAbility[client])
		{
			AbilityData ability = boss.GetAbility("rage_ability_management");
			if(ability.IsMyPlugin())
			{
				HasAbility[client] = -1;
				
				bool medic;
				int buttons;
				if(ability.GetInt("slot") == 0)
				{
					boss.SetInt("ragemode", 1);
					buttons++;
					medic = true;
				}
				
				int players;
				for(int i; i < 4; i++)
				{
					players += PlayersAlive[i];
				}
				
				if(ability.GetBool("altfire", false))
					buttons++;
				
				if(ability.GetBool("reload", true))
					buttons++;
				
				if(ability.GetBool("special", true))
					buttons++;
				
				ConfigData cfg = ability.GetSection("spells");
				if(cfg)
				{
					SortedSnapshot snap = CreateSortedSnapshot(cfg);
					
					int entries = snap.Length;
					if(entries)
					{
						float gameTime = GetGameTime();
						for(int i; i < entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							char[] key = new char[length];
							snap.GetKey(i, key, length);
							
							ConfigData spell = cfg.GetSection(key);
							if(spell)
							{
								SetFloatFromFormula(spell, "cooldown", players);
								float cost = SetFloatFromFormula(spell, "cost", players);
								
								float delay = SetFloatFromFormula(spell, "delay", players);
								if(delay > 0.0)
									spell.SetFloat("delay", delay + gameTime);
								
								if(medic && !i)
									boss.SetFloat("ragemin", cost);
							}
						}
						
						if(entries > buttons || ability.GetBool("cycler"))
						{
							HasAbility[client] = entries;
							ChangeAbility(client, boss, ability, cfg, snap, false);
						}
						
						Debug("Found %d buttons, %d spells, using cycler: %d", buttons, entries, HasAbility[client]);
						
						delete snap;
						return;
					}
					
					delete snap;
				}
				
				HasAbility[client] = 0;
				
				char buffer[64];
				boss.GetString("filename", buffer, sizeof(buffer));
				LogError("[Boss] '%s' is missing 'spells' for 'rage_ability_management'", buffer);
			}
		}
	}
}

public void FF2R_OnBossRemoved(int client)
{
	HasAbility[client] = 0;
	CanPickup[client] = false;
	WallJumper[client] = false;
	WallLagComped[client] = false;
	ClassSwap[client] = TFClass_Unknown;
	StealNext[client] = 0;
	
	if(DodgeFor[client])
		DodgeFor[client] = 1.0;
	
	if(RazorbackRef[client] != INVALID_ENT_REFERENCE)
	{
		RazorbackRef[client] = INVALID_ENT_REFERENCE;
		CheckRazorbackHooks();
	}
	
	if(HookedWeaponSwap[client])
		CheckWeaponSwapHooks(client);
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
	if(HasAbility[client] && !StrContains(ability, "rage_ability_management", false))
	{
		ConfigData spells = cfg.GetSection("spells");
		if(spells)
		{
			bool hud;
			SortedSnapshot snap;
			
			if(HasAbility[client] != -1)
			{
				snap = CreateSortedSnapshot(spells);
				if(snap.Length >= HasAbility[client])
					hud = ActivateAbility(client, FF2R_GetBossData(client), spells, snap, HasAbility[client] - 1, GetGameTime());
			}
			else if(cfg.GetInt("slot") == 0)
			{
				snap = CreateSortedSnapshot(spells);
				hud = ActivateAbility(client, FF2R_GetBossData(client), spells, snap, 0, GetGameTime());
			}
			
			delete snap;
			
			if(hud)
				cfg.SetFloat("hudin", 0.0);
		}
	}
	else if(!StrContains(ability, "rage_weapon_steal", false))
	{
		StealNext[client]++;
	}
	else if(!StrContains(ability, "rage_random_slot", false))
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
	else if(!StrContains(ability, "rage_dodge_hitscan", false))
	{
		float timescale = cfg.GetFloat("timescale", 1.0);
		if(timescale <= 0.0)
			timescale = 1.0;
		
		float duration = cfg.GetFloat("duration", 7.5) * timescale;
		
		char particle[48];
		if(cfg.GetString("particle", particle, sizeof(particle), GetClientTeam(client) % 2 ? "scout_dodge_blue" : "scout_dodge_red"))
		{
			AttachParticle(client, particle, duration);
			TF2_AddCondition(client, TFCond_Stealthed, duration);
		}
		
		if(!DodgeFor[client])
			SDKHook(client, SDKHook_TraceAttack, DodgeTraceAttack);
		
		DodgeFor[client] = GetGameTime() + duration;
		DodgeSpeed[client] = cfg.GetFloat("speed");
		
		TimescaleSound(client, CvarTimeScale.FloatValue, timescale);
		
		CvarTimeScale.FloatValue = timescale;
		if(!TimescaleTimer)
		{
			HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && !IsFakeClient(target))
					CvarCheats.ReplicateToClient(target, "1");
			}
		}
		else
		{
			delete TimescaleTimer;
		}
		
		TimescaleTimer = CreateTimer(duration, Timer_RestoreTime, GetClientUserId(client));
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

public void FF2R_OnBossModifier(int client, ConfigData cfg)
{
	BossData boss = FF2R_GetBossData(client);
	
	if(boss.GetBool("nopassive"))
	{
		WallJumper[client] = false;
		
		AbilityData ability = boss.GetAbility("rage_ability_management");
		if(ability.IsMyPlugin())
			boss.Remove("rage_ability_management");
	}
}

public void FF2R_OnBossEquipped(int client, bool weapons)
{
	if(ClassSwap[client])
		ClassSwap[client] = TF2_GetPlayerClass(client);
	
	if(weapons)
	{
		AbilityData ability = FF2R_GetBossData(client).GetAbility("special_razorback_shield");
		if(ability.IsMyPlugin())
		{
			int weapon = CreateEntityByName(ability.GetBool("secondary") ? "tf_weapon_pistol" : "tf_weapon_handgun_scout_primary");
			if(weapon != -1)
			{
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 200);
				SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
				
				SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 0);
				SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 1);
				
				DispatchSpawn(weapon);
				SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", true);
				SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
				
				EquipPlayerWeapon(client, weapon);
				
				TF2Attrib_SetByDefIndex(weapon, 128, 1.0);
				TF2Attrib_SetByDefIndex(weapon, 303, -1.0);
				TF2Attrib_SetByDefIndex(weapon, 821, 1.0);
				
				RazorbackRef[client] = EntIndexToEntRef(weapon);
				
				int durability = ability.GetInt("durability");
				ability.SetInt("current", durability);
				SetEntProp(weapon, Prop_Send, "m_iClip1", durability / 10);
			}
			
			if(weapon != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				weapon = EquipRazorback(client);
				if(weapon != -1)
					ability.SetInt("wearableref", EntIndexToEntRef(weapon));
			}
			
			if(!HookedRazorback)
			{
				HookedRazorback = true;
				HookUserMessage(PlayerShieldBlocked, OnShieldBlocked);
			}
			
			if(!HookedWeaponSwap[client])
			{
				Debug("Hooked Swapping on %N", client);
				HookedWeaponSwap[client] = true;
				SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			}
		}
		
		if(SetHealthTo[client])
		{
			SetEntityHealth(client, SetHealthTo[client]);
			FF2R_UpdateBossAttributes(client);
			SetHealthTo[client] = 0;
		}
	}
}

public Action FF2R_OnPickupDroppedWeapon(int client, int weapon)
{
	Debug("FF2R_OnPickupDroppedWeapon::%N", client);
	return CanPickup[client] ? (ClassSwap[client] ? Plugin_Handled : Plugin_Changed) : Plugin_Continue;
}

#if defined __nosoop_tf2_utils_included
public void OnLibraryAdded(const char[] name)
{
	if(!TF2ULoaded && StrEqual(name, TF2U_LIBRARY))
		TF2ULoaded = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(TF2ULoaded && StrEqual(name, TF2U_LIBRARY))
		TF2ULoaded = false;
}
#endif

public void OnClientPutInServer(int client)
{
	if(TimescaleTimer && !IsFakeClient(client))
		CvarCheats.ReplicateToClient(client, "1");
	
	SDKHook(client, SDKHook_TraceAttack, StealingTraceAttack);
}

public void OnClientDisconnect(int client)
{
	DodgeFor[client] = 0.0;
	WallAirMulti[client] = 1.0;
	WallJumpMulti[client] = 1.0;
	WallSpeedMulti[client] = 1.0;
	BodyRef[client] = INVALID_ENT_REFERENCE;
	HandRef[client] = INVALID_ENT_REFERENCE;
	WeapRef[client] = INVALID_ENT_REFERENCE;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(DodgeFor[client])
	{
		if(DodgeFor[client] < GetGameTime() || !IsPlayerAlive(client))
		{
			DodgeFor[client] = 0.0;
			SDKUnhook(client, SDKHook_TraceAttack, DodgeTraceAttack);
			if(SDKSetSpeed)
				SDKCall(SDKSetSpeed, client);
		}
		else if(SDKSetSpeed && DodgeSpeed[client])
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", DodgeSpeed[client]);
		}
	}
	
	if(WallJumper[client] && IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_ONGROUND) && CvarUnlag.BoolValue && GetEntProp(client, Prop_Data, "m_bLagCompensation") && !IsFakeClient(client))
	{
		WallInLagComp = true;
		SDKCall(SDKCanAirDash, client);
		WallInLagComp = false;
	}
	else
	{
		WallLagComped[client] = false;
	}
	
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
	if(WallStale[client] || WallSpeedMulti[client] != 1.0 || WallJumpMulti[client] != 1.0)
	{
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			JumperAttribRestore(client, 107, WallSpeedMulti[client]);
			JumperAttribRestore(client, 443, WallJumpMulti[client]);
			WallStale[client] = 0;
		}
	}
	
	if(WallAirMulti[client] != 1.0)
	{
		float value = WallAirMulti[client] * 0.95;
		if(value < 1.0)
			value = 1.0;
		
		JumperAttribApply(client, 610, WallAirMulti[client], value);
	}
	
	if(HasAbility[client] && IsPlayerAlive(client))
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		ConfigData spells;
		if(boss && (ability = boss.GetAbility("rage_ability_management")) && (spells = ability.GetSection("spells")))
		{
			bool hud;
			float gameTime = GetGameTime();
			
			int dead = -1;
			int allies = -1;
			int count = -1;
			static int button[4];
			SortedSnapshot snap;
			
			static int holding[MAXTF2PLAYERS];
			if(holding[client])
			{
				if(!(buttons & holding[client]))
					holding[client] = 0;
			}
			else if(buttons & IN_ATTACK2)
			{
				holding[client] = IN_ATTACK2;
				
				GetButtons(ability, HasAbility[client] != -1, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 1)
					{
						snap = CreateSortedSnapshot(spells);
						
						int length = snap.Length;
						if(HasAbility[client] == -1 && length > i)
						{
							hud = ActivateAbility(client, boss, spells, snap, i, gameTime, dead, allies);
						}
						else
						{
							hud = ChangeAbility(client, boss, ability, spells, snap, (i == count - 1));
						}
						break;
					}
				}
			}
			else if(buttons & IN_RELOAD)
			{
				holding[client] = IN_RELOAD;
				
				GetButtons(ability, HasAbility[client] != -1, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 2)
					{
						snap = CreateSortedSnapshot(spells);
						
						int length = snap.Length;
						if(HasAbility[client] == -1 && length > i)
						{
							hud = ActivateAbility(client, boss, spells, snap, i, gameTime, dead, allies);
						}
						else
						{
							hud = ChangeAbility(client, boss, ability, spells, snap, (i == count - 1));
						}
						break;
					}
				}
			}
			else if(buttons & IN_ATTACK3)
			{
				holding[client] = IN_ATTACK3;
				
				GetButtons(ability, HasAbility[client] != -1, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 3)
					{
						snap = CreateSortedSnapshot(spells);
						
						int length = snap.Length;
						if(HasAbility[client] == -1 && length > i)
						{
							hud = ActivateAbility(client, boss, spells, snap, i, gameTime, dead, allies);
						}
						else
						{
							hud = ChangeAbility(client, boss, ability, spells, snap, (i == count - 1));
						}
						break;
					}
				}
			}
			
			if(!(buttons & IN_SCORE))
			{
				if(!hud)
				{
					static bool wasDucking[MAXTF2PLAYERS];
					if(buttons & IN_DUCK)
					{
						if(!wasDucking[client])
						{
							hud = true;
							wasDucking[client] = true;
						}
					}
					else if(!wasDucking[client])
					{
						hud = true;
						wasDucking[client] = false;
					}
				}
				
				if(hud || ability.GetFloat("hudin") < gameTime)
				{
					ability.SetFloat("hudin", gameTime + 0.09);
					
					SetGlobalTransTarget(client);
					int lang = GetClientLanguage(client);
					
					static char buffer[512];
					static PackVal val;
					if(HasAbility[client] == -1)
					{
						GetButtons(ability, false, count, button);
						
						if(!snap)
							snap = CreateSortedSnapshot(spells);
						
						int entries = snap.Length;
						if(entries > count)
						{
							Debug("Somehow, we have less buttons or spells now");
							HasAbility[client] = 1;
							delete snap;
							return;
						}
						
						for(int i; i < entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							char[] key = new char[length];
							snap.GetKey(i, key, length);
							spells.GetArray(key, val, sizeof(val));
							
							if(val.tag == KeyValType_Section && val.cfg)
							{
								ConfigData cfg = view_as<ConfigData>(val.cfg);
								if(!(buttons & IN_DUCK) || !GetBossNameCfg(cfg, val.data, sizeof(val.data), lang, "desc"))
								{
									if(!GetBossNameCfg(cfg, val.data, sizeof(val.data), lang))
										strcopy(val.data, sizeof(val.data), key);
								}
								
								bool blocked = true;
								
								if(buttons & IN_DUCK)
								{
									switch(button[i])
									{
										case 0:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button E", val.data);
										
										case 1:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button 11", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button 13", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button 25", val.data);
									}
									
									int cost = RoundToCeil(cfg.GetFloat("cost"));
									if(cost > 0)
										Format(val.data, sizeof(val.data), "%s (%d%%)", val.data, cost);
								}
								else
								{
									switch(button[i])
									{
										case 0:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short E", val.data);
										
										case 1:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short 11", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short 13", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short 25", val.data);
									}
									
									int flags = cfg.GetInt("flags");
									if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs One Life");
									}
									else if((flags & MAG_PARTNER) && GetDeadCount(client, dead, allies) && !allies)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Partner");
									}
									else if((flags & MAG_SUMMON) && GetDeadCount(client, dead, allies) && !dead)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Summon");
									}
									else
									{
										float delay = cfg.GetFloat("delay");
										if(delay > gameTime)
										{
											Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Ability Delay", delay - gameTime + 0.1);
										}
										else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
										{
											Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Ground");
										}
										else
										{
											float fcost = cfg.GetFloat("cost");
											int cost = RoundToCeil(fcost);
											if(cost > 0)
												Format(val.data, sizeof(val.data), "%s (%d%%)", val.data, cost);
											
											if(button[i] == 0 && GetBossCharge(boss, "0") >= fcost)
												blocked = false;
										}
									}
								}
								
								if(button[i] == 0)
									boss.SetInt("ragemode", blocked ? 2 : 1);
								
								if(i)
								{
									Format(buffer, sizeof(buffer), "%s\n%s", buffer, val.data);
								}
								else
								{
									strcopy(buffer, sizeof(buffer), val.data);
								}
							}
						}
						
						if(boss.GetInt("lives") < 2)
							entries--;
						
						SetHudTextParams(-1.0, 0.78 - (float(entries) * 0.05), 0.1, 255, 255, 255, 255, _, _, 0.01, 0.5);
					}
					else
					{
						if(!snap)
							snap = CreateSortedSnapshot(spells);
						
						int entries = snap.Length;
						if(!entries)
						{
							HasAbility[client] = 0;
							delete snap;
							return;
						}
						
						if(HasAbility[client] > entries)
							HasAbility[client] = 1;
						
						int length = snap.KeyBufferSize(HasAbility[client] - 1) + 1;
						char[] key = new char[length];
						snap.GetKey(HasAbility[client] - 1, key, length);
						spells.GetArray(key, val, sizeof(val));
						
						if(val.tag == KeyValType_Section && val.cfg)
						{
							ConfigData cfg = view_as<ConfigData>(val.cfg);
							if(!(buttons & IN_DUCK) || !GetBossNameCfg(cfg, val.data, sizeof(val.data), lang, "desc"))
							{
								if(!GetBossNameCfg(cfg, val.data, sizeof(val.data), lang))
									strcopy(val.data, sizeof(val.data), key);
							}
							
							GetButtons(ability, true, count, button);
							
							bool blocked = true;
							if((buttons & IN_DUCK) && count)
							{
								switch(button[0])
								{
									case 1:
										Format(buffer, sizeof(buffer), "[%t] -->", "Button 11");
									
									case 2:
										Format(buffer, sizeof(buffer), "[%t] -->", "Button 13");
									
									case 3:
										Format(buffer, sizeof(buffer), "[%t] -->", "Button 25");
									
									default:
										buffer[0] = 0;
								}
								
								if(count > 1)
								{
									switch(button[count - 1])
									{
										case 1:
											Format(buffer, sizeof(buffer), "<-- [%t] | %s", "Button 11", buffer);
										
										case 2:
											Format(buffer, sizeof(buffer), "<-- [%t] | %s", "Button 13", buffer);
										
										case 3:
											Format(buffer, sizeof(buffer), "<-- [%t] | %s", "Button 25", buffer);
									}
								}
								
								Format(buffer, sizeof(buffer), "%s\n%s", buffer, val.data);
							}
							else
							{
								if(count)
								{
									switch(button[0])
									{
										case 1:
											Format(val.data, sizeof(val.data), "%s [%t] -->", val.data, "Short 11");
										
										case 2:
											Format(val.data, sizeof(val.data), "%s [%t] -->", val.data, "Short 13");
										
										case 3:
											Format(val.data, sizeof(val.data), "%s [%t] -->", val.data, "Short 25");
									}
									
									if(count > 1)
									{
										switch(button[count - 1])
										{
											case 1:
												Format(val.data, sizeof(val.data), "<-- [%t] %s", "Short 11", val.data);
											
											case 2:
												Format(val.data, sizeof(val.data), "<-- [%t] %s", "Short 13", val.data);
											
											case 3:
												Format(val.data, sizeof(val.data), "<-- [%t] %s", "Short 25", val.data);
										}
									}
								}
								
								float fcost = cfg.GetFloat("cost");
								int cost = RoundToCeil(fcost);
								if(cost > 0)
								{
									Format(buffer, sizeof(buffer), "%t", "Boss Rage", cost);
								}
								else
								{
									buffer[0] = 0;
								}
								
								if(ability.GetInt("slot") == 0 && GetBossCharge(boss, "0") >= fcost)
									blocked = false;
								
								float delay = cfg.GetFloat("delay");
								if(delay > gameTime)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Ability Delay", delay - gameTime + 0.1);
									blocked = true;
								}
								
								int flags = cfg.GetInt("flags");
								if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs One Life");
									blocked = true;
								}
								
								if((flags & MAG_PARTNER) && GetDeadCount(client, dead, allies) && !allies)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs Partner");
									blocked = true;
								}
								
								if((flags & MAG_SUMMON) && GetDeadCount(client, dead, allies) && !dead)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs Summon");
									blocked = true;
								}
								
								if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs Ground");
									blocked = true;
								}
								
								Format(buffer, sizeof(buffer), "%s\n%s", val.data, buffer);
							}
							
							if(ability.GetInt("slot") == 0)
								boss.SetInt("ragemode", blocked ? 2 : 1);
						}
						
						SetHudTextParams(-1.0, 0.68 - (boss.GetInt("lives") > 1 ? 0.05 : 0.0), 0.1, 255, 255, 255, 255, _, _, 0.01, 0.5);
					}
					
					ShowSyncHudText(client, SyncHud, buffer);
				}
			}
			
			delete snap;
		}
		else
		{
			HasAbility[client] = 0;
		}
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			BossData boss = FF2R_GetBossData(client);
			if(boss)
			{
				AbilityData ability = boss.GetAbility("rage_ability_management");
				if(ability.IsMyPlugin())
					ability.SetFloat("hudin", FAR_FUTURE);
			}
		}
	}
	
	TriggerTimer(TimescaleTimer);
}

public Action OnShieldBlocked(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	bf.ReadByte();
	int victim = bf.ReadByte();
	if(RazorbackRef[victim] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(RazorbackRef[victim]);
		if(entity != INVALID_ENT_REFERENCE)
		{
			TF2_RemoveItem(victim, entity);
			if(GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon") == entity)
			{
				entity = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
				if(entity != -1)
				{
					char buffer[36];
					if(GetEntityClassname(entity, buffer, sizeof(buffer)))
						FakeClientCommand(victim, "use %s", buffer);
				}
			}
		}
		
		BossData boss = FF2R_GetBossData(victim);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_razorback_shield")))
		{
			entity = EntRefToEntIndex(ability.GetInt("wearableref", INVALID_ENT_REFERENCE));
			if(entity != INVALID_ENT_REFERENCE)
				TF2_RemoveWearable(victim, entity);
		}
		
		RazorbackRef[victim] = INVALID_ENT_REFERENCE;
		CheckRazorbackHooks();
		CheckWeaponSwapHooks(victim);
	}
	return Plugin_Continue;
}

public void OnWeaponSwitch(int client, int weapon)
{
	if(RazorbackRef[client] != INVALID_ENT_REFERENCE && EntRefToEntIndex(RazorbackRef[client]) == weapon)
	{
		if(RazorbackDeployed[client] == INVALID_ENT_REFERENCE)
		{
			BossData boss = FF2R_GetBossData(client);
			AbilityData ability;
			if(boss && (ability = boss.GetAbility("special_razorback_shield")))
			{
				int entity = EntRefToEntIndex(ability.GetInt("wearableref", INVALID_ENT_REFERENCE));
				if(entity != INVALID_ENT_REFERENCE)
				{
					int index = GetEntProp(entity, Prop_Send, "m_nModelIndex");
					if(index > 0)
					{
						char buffer[PLATFORM_MAX_PATH];
						ModelIndexToString(index, buffer, sizeof(buffer));
						TF2_RemoveWearable(client, entity);
						
						entity = CreateEntityByName("prop_dynamic");
						
						DispatchKeyValue(entity, "model", buffer);
						DispatchKeyValue(entity, "disablereceiveshadows", "0");
						DispatchKeyValue(entity, "disableshadows", "1");
						
						SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
						
						float pos[3], ang[3];
						GetClientAbsOrigin(client, pos);
						GetClientAbsAngles(client, ang);
						
						float offset = ang[1];
						if(offset > 90.0)
						{
							offset = 180.0 - offset;
						}
						else if(offset < -90.0)
						{
							offset = -180.0 - offset;
						}
						
						pos[0] += 15.0 * offset / 90.0;
						pos[1] -= 15.0 * (90.0 - Fabs(ang[1])) / 90.0;
						pos[2] -= 72.5;
						ang[1] += 180.0;
						
						TeleportEntity(entity, pos, ang, NULL_VECTOR);
						DispatchSpawn(entity);
						
						SetVariantString("!activator");
						AcceptEntityInput(entity, "SetParent", GetEntPropEnt(client, Prop_Send, "m_hViewModel"));
						
						SDKHook(entity, SDKHook_SetTransmit, FirstPersonTransmit);
						SDKHook(client, SDKHook_OnTakeDamageAlive, RazorbackTakeDamage);
						
						RazorbackDeployed[client] = EntIndexToEntRef(entity);
						
						entity = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
						if(entity != -1)
							SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
						
						entity = CreateEntityByName("tf_wearable");
						if(entity != -1)
						{
							SetEntProp(entity, Prop_Send, "m_nModelIndex", index);
							
							DispatchSpawn(entity);
							SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
							
							ability.SetInt("tpref", EntIndexToEntRef(entity));
							EquipWearable(client, entity);
							
							SetEntProp(entity, Prop_Send, "m_fEffects", 0);
							
							SetVariantString("!activator");
							AcceptEntityInput(entity, "SetParent", weapon);
							
							pos[0] = 5.0;
							pos[1] = -7.5;
							pos[2] = -60.0;
							ang[1] = 180.0;
							TeleportEntity(entity, pos, ang, NULL_VECTOR);
						}
					}
				}
			}
		}
	}
	else if(RazorbackDeployed[client] != INVALID_ENT_REFERENCE)
	{
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, RazorbackTakeDamage);
		
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_razorback_shield")))
		{
			if(RazorbackRef[client] != INVALID_ENT_REFERENCE)
			{
				int entity = EquipRazorback(client);
				if(entity != -1)
					entity = EntIndexToEntRef(entity);
				
				ability.SetInt("wearableref", entity);
			}
			
			int entity = EntRefToEntIndex(ability.GetInt("tpref", INVALID_ENT_REFERENCE));
			if(entity != INVALID_ENT_REFERENCE)
				TF2_RemoveWearable(client, entity);
			
			ability.SetInt("tpref", INVALID_ENT_REFERENCE);
		}
		
		int entity = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		if(entity != -1)
			SetEntProp(entity, Prop_Send, "m_fEffects", 0);
		
		entity = EntRefToEntIndex(RazorbackDeployed[client]);
		if(entity != INVALID_ENT_REFERENCE)
			RemoveEntity(entity);
		
		RazorbackDeployed[client] = INVALID_ENT_REFERENCE;
	}
	
	if(ClassSwap[client] && RazorbackDeployed[client] == INVALID_ENT_REFERENCE && weapon > MaxClients)
	{
		TFClassType class = TF2_GetWeaponClass(weapon, ClassSwap[client]);
		TF2_SetPlayerClass(client, class, _, false);
		FF2R_UpdateBossAttributes(client);
		
		if(AnimSwap[client] && EntRefToEntIndex(BodyRef[client]) == INVALID_ENT_REFERENCE)
		{
			int index = GetEntProp(client, Prop_Send, "m_nModelIndex");
			if(index > 0)
			{
				int entity = CreateEntityByName("tf_wearable");
				if(entity != -1)
				{
					SetEntProp(entity, Prop_Send, "m_nModelIndex", index);
					SetEntProp(entity, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
					SetEntProp(entity, Prop_Send, "m_nSkin", GetClientTeam(client) % 2);
					
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
					
					BodyRef[client] = EntIndexToEntRef(entity);
					EquipWearable(client, entity);
					
					SetEntityRenderFx(client, RENDERFX_FADE_FAST);
					
					SetVariantString(NULL_STRING);
					AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
				}
			}
		}
		
		if(HandSwap[client])
		{
			if(EntRefToEntIndex(HandRef[client]) == INVALID_ENT_REFERENCE)
			{
				int entity = CreateEntityByName("tf_wearable_vm");
				if(entity != -1)
				{
					SetEntProp(entity, Prop_Send, "m_nModelIndex", HandSwap[client]);
					SetEntProp(entity, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
					SetEntProp(entity, Prop_Send, "m_nSkin", GetClientTeam(client) % 2);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
					
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
					SDKHook(entity, SDKHook_SetTransmit, FirstPersonTransmit);
					
					HandRef[client] = EntIndexToEntRef(entity);
					EquipWearable(client, entity);
				}
			}
			
			int entity = EntRefToEntIndex(WeapRef[client]);
			if(entity != INVALID_ENT_REFERENCE)
				TF2_RemoveWearable(client, entity);
			
			entity = CreateEntityByName("tf_wearable_vm");
			if(entity != -1)
			{
				SetEntProp(entity, Prop_Send, "m_nModelIndex", GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex"));
				SetEntProp(entity, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				
				DispatchSpawn(entity);
				SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
				SDKHook(entity, SDKHook_SetTransmit, FirstPersonTransmit);
				
				WeapRef[client] = EntIndexToEntRef(entity);
				EquipWearable(client, entity);
				
				entity = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
				if(entity != -1)
					SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
			}
			else
			{
				WeapRef[client] = INVALID_ENT_REFERENCE;
			}
		}
	}
	else if(IsPlayerAlive(client))
	{
		if(BodyRef[client] != INVALID_ENT_REFERENCE)
		{
			int entity = EntRefToEntIndex(BodyRef[client]);
			if(entity != INVALID_ENT_REFERENCE)
			{
				int index = GetEntProp(entity, Prop_Send, "m_nModelIndex");
				if(index > 0)
				{
					char buffer[PLATFORM_MAX_PATH];
					ModelIndexToString(index, buffer, sizeof(buffer));
					
					SetVariantString(buffer);
					AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
				}
				
				TF2_RemoveWearable(client, entity);
			}
			
			SetEntityRenderFx(client, RENDERFX_NONE);
			BodyRef[client] = INVALID_ENT_REFERENCE;
		}
		
		if(WeapRef[client] != INVALID_ENT_REFERENCE || HandRef[client] != INVALID_ENT_REFERENCE)
		{
			int entity = EntRefToEntIndex(WeapRef[client]);
			if(entity != INVALID_ENT_REFERENCE)
				TF2_RemoveWearable(client, entity);
			
			entity = EntRefToEntIndex(HandRef[client]);
			if(entity != INVALID_ENT_REFERENCE)
				TF2_RemoveWearable(client, entity);
			
			if(RazorbackDeployed[client] == INVALID_ENT_REFERENCE)
			{
				entity = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
				if(entity != -1)
					SetEntProp(entity, Prop_Send, "m_fEffects", 0);
			}
			
			WeapRef[client] = INVALID_ENT_REFERENCE;
			HandRef[client] = INVALID_ENT_REFERENCE;
		}
	}
}

public Action FirstPersonTransmit(int entity, int client)
{
	if(client > 0 && client <= MaxClients)
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(owner == client)
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Taunting) || GetEntProp(client, Prop_Send, "m_nForceTauntCam"))
				return Plugin_Stop;
		}
		else if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") != owner || GetEntProp(client, Prop_Send, "m_iObserverMode") != 4)
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public MRESReturn CanAirDashPre(int client, DHookReturn ret)
{
	if(WallJumper[client] && WallLagComped[client])
	{
		WallLagComped[client] = false;
		SetEntProp(client, Prop_Send, "m_iAirDash", GetEntProp(client, Prop_Send, "m_iAirDash") + 1);
	}
	return MRES_Ignored;
}

public MRESReturn CanAirDashPost(int client, DHookReturn ret)
{
	if(WallJumper[client])
	{
		if(JumperTestJump(client, ret.Value))
		{
			ret.Value = true;
			return MRES_Override;
		}
	}
	return MRES_Ignored;
}

public MRESReturn PickupWeaponFromOtherPre(int client, DHookReturn ret, DHookParam param)
{
	if(CanPickup[client] && ClassSwap[client])
	{
		int slot = -1;
		int weapon = param.Get(1);
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		TFClassType class = TF2_GetDropClass(index, ClassSwap[client], slot);
		if(slot != -1 && slot != TFWeaponSlot_Melee)
		{
			TF2_RemoveWeaponSlot(client, slot);
			TF2_SetPlayerClass(client, class, _, false);
			
			char classname[36];
			TF2Econ_GetItemClassName(index, classname, sizeof(classname));
			TF2Econ_TranslateWeaponEntForClass(classname, sizeof(classname), class);
			
			static int offset = -1;
			if(offset == -1)
				offset = FindSendPropInfo("CTFDroppedWeapon", "m_Item");
			
			int entity = SDKCall(SDKGiveNamedItem, client, classname,
			(class == TFClass_Spy && (StrEqual(classname, "tf_weapon_builder") || StrEqual(classname, "tf_weapon_sapper"))) ? view_as<int>(TFObject_Sapper) : 0,
			GetEntityAddress(weapon) + view_as<Address>(offset), true);
			
			if(GetEntProp(entity, Prop_Send, "m_iItemIDHigh") == -1 && GetEntProp(entity, Prop_Send, "m_iItemIDLow") == -1)
			{
				GetEntityNetClass(entity, classname, sizeof(classname));
				int offse = FindSendPropInfo(classname, "m_iItemIDHigh");
				
				SetEntData(entity, offse - 8, 0);	// m_iItemID
				SetEntData(entity, offse - 4, 0);	// m_iItemID
				SetEntData(entity, offse, 0);		// m_iItemIDHigh
				SetEntData(entity, offse + 4, 0);	// m_iItemIDLow
			}
			
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
			EquipPlayerWeapon(client, entity);
			SDKCall(SDKInitPickedUpWeapon, weapon, client, entity);
			
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
			OnWeaponSwitch(client, entity);
		}
		else
		{
			ClientCommand(client, "playgamesound weapons/ball_buster_hit_02.wav");
		}
		
		ret.Value = true;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

bool ActivateAbility(int client, BossData boss, ConfigData spells, SortedSnapshot snap, int index, float gameTime, int &dead = -2, int &allies = -2)
{
	bool refund = dead == -2;
	
	int length = snap.KeyBufferSize(index)+1;
	char[] key = new char[length];
	snap.GetKey(index, key, length);
	
	static PackVal val;
	spells.GetArray(key, val, sizeof(val));
	if(val.tag == KeyValType_Section && val.cfg)
	{
		ConfigData cfg = view_as<ConfigData>(val.cfg);
		if(cfg.GetFloat("delay") < gameTime)
		{
			int flags = cfg.GetInt("flags");
			if((flags & MAG_SUMMON) && GetDeadCount(client, dead, allies) && !dead)
			{
			}
			else if((flags & MAG_PARTNER) && GetDeadCount(client, dead, allies) && !allies)
			{
			}
			else if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
			{
			}
			else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
			{
			}
			else
			{
				float rage = GetBossCharge(boss, "0") + (refund ? boss.GetFloat("ragemin") : 0.0);
				float cost = cfg.GetFloat("cost");
				if(rage >= cost)
				{
					if(cfg.GetBool("consume", true))
					{
						SetBossCharge(boss, "0", rage - cost);
					}
					else if(refund)
					{
						SetBossCharge(boss, "0", rage);
					}
					
					cfg.SetFloat("delay", gameTime + cfg.GetFloat("cooldown"));
					
					int slot = cfg.GetInt("cast_high", cfg.GetInt("cast_low"));
					FF2R_DoBossSlot(client, cfg.GetInt("cast_low", slot), slot);
					return true;
				}
				
				if(refund)
				{
					SetBossCharge(boss, "0", rage);
					refund = false;
				}
			}
		}
		
		if(refund)
			SetBossCharge(boss, "0", GetBossCharge(boss, "0") + boss.GetFloat("ragemin"));
		
		int slot = cfg.GetInt("nocast_high", cfg.GetInt("nocast_low", -2147483647));
		if(slot != -2147483647)
		{
			FF2R_DoBossSlot(client, cfg.GetInt("nocast_low", slot), slot);
			return true;
		}
	}
	
	ClientCommand(client, "playgamesound " ... AMS_DENYUSE);
	return false;
}

bool ChangeAbility(int client, BossData boss, ConfigData ability, ConfigData spells, SortedSnapshot snap, bool backwards)
{
	int length = snap.Length;
	if(length == 1)
		return false;
	
	if(backwards)
	{
		if(--HasAbility[client] < 1)
			HasAbility[client] = length;
	}
	else if(++HasAbility[client] > length)
	{
		HasAbility[client] = 1;
	}
	
	if(ability.GetInt("slot") == 0)
	{
		length = snap.KeyBufferSize(HasAbility[client] - 1) + 1;
		char[] key = new char[length];
		snap.GetKey(HasAbility[client] - 1, key, length);
		
		static PackVal val;
		spells.GetArray(key, val, sizeof(val));
		if(val.tag != KeyValType_Section || !val.cfg)
			return false;
		
		boss.SetFloat("ragemin", view_as<ConfigData>(val.cfg).GetFloat("cost"));
	}
	
	ClientCommand(client, "playgamesound " ... AMS_SWITCH);
	return true;
}

bool GetDeadCount(int client, int &dead, int &allies)
{
	if(dead < 0 || allies < 0)
	{
		dead = 0;
		allies = 0;
		
		int team = GetClientTeam(client);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i))
			{
				if(FF2R_GetBossData(i))
				{
					if(GetClientTeam(i) == team)
						allies++;
				}
				else if(GetClientTeam(i) > view_as<int>(TFTeam_Spectator))
				{
					if(!IsPlayerAlive(i))
						dead++;
				}
				else if(!SpecTeam && IsPlayerAlive(i))
				{
					dead++;
				}
			}
		}
	}
	return true;
}

void GetButtons(ConfigData ability, bool cycle, int &count, int button[4])
{
	if(count == -1)
	{
		count = 0;
		
		if(!cycle && ability.GetInt("slot") == 0)
			button[count++] = 0;
		
		if(ability.GetBool("altfire", false))
			button[count++] = 1;
		
		if(ability.GetBool("reload", true))
			button[count++] = 2;
		
		if(ability.GetBool("special", true))
			button[count++] = 3;
	}
}

void CheckWeaponSwapHooks(int client)
{
	if(RazorbackRef[client] == INVALID_ENT_REFERENCE && !ClassSwap[client] && BodyRef[client] == INVALID_ENT_REFERENCE && WeapRef[client] != INVALID_ENT_REFERENCE)
		RemoveWeaponSwapHooks(client);
}

void RemoveWeaponSwapHooks(int client)
{
	OnWeaponSwitch(client, -2);
	
	if(RazorbackRef[client] == INVALID_ENT_REFERENCE && !ClassSwap[client] && BodyRef[client] == INVALID_ENT_REFERENCE && WeapRef[client] != INVALID_ENT_REFERENCE)
	{
		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
		HookedWeaponSwap[client] = false;
	}
}

public Action DodgeTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	return Plugin_Handled;
}

public Action Timer_RestoreTime(Handle timer, int userid)
{
	TimescaleTimer = null;
	UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	
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

public Action StealingTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(attacker > 0 && attacker <= MaxClients && StealNext[attacker] && RazorbackDeployed[victim] == INVALID_ENT_REFERENCE &&
	  ((damagetype & DMG_CLUB) || (damagetype & DMG_SLASH) || hitgroup == HITGROUP_LEFTARM || hitgroup == HITGROUP_RIGHTARM) &&
	  !IsInvuln(victim) && (GetClientTeam(victim) != GetClientTeam(attacker) || CvarFriendlyFire.BoolValue))
	{
		Debug("Attempted Steal");
		bool isBoss = view_as<bool>(FF2R_GetBossData(victim));
		
		int weapon = (TF2_IsPlayerInCondition(victim, TFCond_Cloaked) || GetEntProp(victim, Prop_Send, "m_bFeignDeathReady")) ? GetPlayerWeaponSlot(victim, TFWeaponSlot_Building) : GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			Debug("Valid Weapon %d", index);
			switch(index)
			{
				case 5, 195:	// Fists are immune
				{
					if(isBoss)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					
					return Plugin_Continue;
				}
			}
			
			char classname[36];
			if(GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				if(!StrContains(classname, "tf_weapon_robot_arm") ||
				   !StrContains(classname, "tf_weapon_builder") ||
				   !StrContains(classname, "tf_weapon_spellbook") ||
				   !StrContains(classname, "tf_weapon_grapplinghook"))
				{
					if(isBoss)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					else
					{
						index = CreateEntityByName("env_explosion");
						if(index != -1)
						{
							StealNext[attacker]--;
							
							DispatchKeyValueFloat(index, "DamageForce", float(GetClientHealth(victim)));
							SetEntPropEnt(index, Prop_Data, "m_hOwnerEntity", attacker);
							
							DispatchSpawn(index);
							
							float pos[3];
							GetClientAbsOrigin(victim, pos);
							pos[2] += 5.0;
							TeleportEntity(index, pos);
							
							AcceptEntityInput(index, "Explode");
							AcceptEntityInput(index, "kill");
						}
						
						damagetype |= DMG_ALWAYSGIB;
						return Plugin_Changed;
					}
				}
					
				if(!StrContains(classname, "tf_weapon_pda_engineer"))
				{
					if(isBoss)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					else
					{
						StealNext[attacker]--;
						TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Grenade);
						TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Building);
						TF2_RemoveWeaponSlot(victim, TFWeaponSlot_PDA);
						TF2_StunPlayer(victim, 0.4, 0.0, TF_STUNFLAG_BONKSTUCK);
						
						index = -1;
						while((index = FindEntityByClassname(index, "obj_*")) != -1)
						{
							if(GetEntPropEnt(index, Prop_Send, "m_hBuilder") == victim)
							{
								SetEntPropEnt(index, Prop_Send, "m_hBuilder", -1);
								SetEntProp(index, Prop_Send, "m_bDisabled", true);
							}
						}
						
						index = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
						if(index != -1 && GetEntityClassname(index, classname, sizeof(classname)))
							FakeClientCommand(victim, "use %s", classname);
						
						FF2R_EmitBossSoundToAll(STEAL_REACT, attacker, "9", victim, SNDCHAN_VOICE, 90, _, 1.0);
						return Plugin_Handled;
					}
				}
				
				if(!StrContains(classname, "tf_weapon_pda_spy"))
				{
					if(isBoss)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					else
					{
						StealNext[attacker]--;
						TF2_RemoveCondition(victim, TFCond_Disguised);
						TF2_RemoveItem(victim, weapon);
						TF2_StunPlayer(victim, 0.4, 0.0, TF_STUNFLAG_BONKSTUCK);
						TF2_AddCondition(attacker, TFCond_DisguisedAsDispenser, 20.0);
						TF2_StunPlayer(attacker, 20.0, 0.2, TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_SLOWDOWN);
						
						index = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
						if(index != -1 && GetEntityClassname(index, classname, sizeof(classname)))
							FakeClientCommand(victim, "use %s", classname);
						
						FF2R_EmitBossSoundToAll(STEAL_REACT, attacker, "8", victim, SNDCHAN_VOICE, 90, _, 1.0);
						return Plugin_Handled;
					}
				}
				
				if(!StrContains(classname, "tf_weapon_invis"))
				{
					if(isBoss)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					else
					{
						StealNext[attacker]--;
						SetEntProp(victim, Prop_Send, "m_bFeignDeathReady", false);
						TF2_RemoveCondition(victim, TFCond_Cloaked);
						TF2_RemoveItem(victim, weapon);
						TF2_StunPlayer(victim, 0.4, 0.0, TF_STUNFLAG_BONKSTUCK);
						TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, 15.0);
						
						if(index == 59)
						{
							TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);
							
							index = CreateEntityByName("tf_ragdoll");
							if(index != -1)
							{
								float pos[3], ang[3];
								GetClientAbsOrigin(attacker, pos);
								GetClientAbsAngles(attacker, ang);
								
								SetEntProp(index, Prop_Send, "m_iPlayerIndex", attacker);
								SetEntProp(index, Prop_Send, "m_iTeam", GetClientTeam(attacker));
								SetEntProp(index, Prop_Send, "m_iClass", TF2_GetPlayerClass(attacker));
								SetEntProp(index, Prop_Send, "m_bOnGround", 1);
								
								SetEntityMoveType(index, MOVETYPE_NONE);
								
								DispatchSpawn(index);
								ActivateEntity(index);
								
								SetVariantString("OnUser1 !self:Kill::15:1,0,1");
								AcceptEntityInput(index, "AddOutput");
								AcceptEntityInput(index, "FireUser1");
							}
						}
						
						FF2R_EmitBossSoundToAll(STEAL_REACT, attacker, "8", victim, SNDCHAN_VOICE, 90, _, 1.0);
						return Plugin_Handled;
					}
				}
				
				if(StrEqual(classname, "tf_weapon_lunchbox"))
				{
					if(isBoss)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					else
					{
						StealNext[attacker]--;
						TF2_RemoveItem(victim, weapon);
						TF2_StunPlayer(victim, 0.4, 0.0, TF_STUNFLAG_BONKSTUCK);
						
						index = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
						if(index != -1 && GetEntityClassname(index, classname, sizeof(classname)))
							FakeClientCommand(victim, "use %s", classname);
						
						FF2R_EmitBossSoundToAll(STEAL_REACT, attacker, "6", victim, SNDCHAN_VOICE, 90, _, 1.0);
						
						ApplyHealEvent(attacker, attacker, 600);
						SetEntityHealth(attacker, GetClientHealth(attacker) + 600);
						return Plugin_Handled;
					}
				}
				
				if(isBoss)
				{
					bool found;
					
					if(ClassSwap[attacker])
					{
						int slot = -1;
						TFClassType class = TF2_GetDropClass(index, ClassSwap[attacker], slot);
						if(slot != -1 && slot < TFWeaponSlot_Melee)
						{
							TF2_RemoveWeaponSlot(attacker, slot);
							TF2_SetPlayerClass(attacker, class, _, false);
							found = true;
						}
					}
					else if(TF2_GetClassnameSlot(classname) < TFWeaponSlot_Melee)
					{
						found = true;
					}
					
					if(!found)
					{
						for(int i; i < TFWeaponSlot_Melee; i++)
						{
							weapon = GetPlayerWeaponSlot(victim, i);
							if(weapon != -1 && GetEntityClassname(weapon, classname, sizeof(classname)))
							{
								index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
								if(ClassSwap[attacker])
								{
									int slot = -1;
									TFClassType class = TF2_GetDropClass(index, ClassSwap[attacker], slot);
									if(slot != -1 && slot < TFWeaponSlot_Melee)
									{
										TF2_RemoveWeaponSlot(attacker, slot);
										TF2_SetPlayerClass(attacker, class, _, false);
										found = true;
										break;
									}
								}
								else if(TF2_GetClassnameSlot(classname) < TFWeaponSlot_Melee)
								{
									found = true;
									break;
								}
							}
						}
					}
					
					if(!found)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					
					weapon = CreateEntityByName(classname);
					if(weapon == -1)
					{
						StealFromBoss(victim, attacker);
						return Plugin_Handled;
					}
					
					StealNext[attacker]--;
					SetEntityHealth(attacker, GetClientHealth(attacker) + 600);
					ApplyHealEvent(attacker, attacker, 600);
					
					SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", index);
					SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
					
					SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 5);
					SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 101);
					
					DispatchSpawn(weapon);
					SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", true);
					SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(attacker, false));
					
					EquipPlayerWeapon(attacker, weapon);
					
					if(HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
					{
						int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
						if(type >= 0)
							SetEntProp(attacker, Prop_Data, "m_iAmmo", 0, _, type);
					}
					
					float value = 1.0;
					Address attrib = TF2Attrib_GetByDefIndex(weapon, 2);
					if(attrib != Address_Null)
						value = TF2Attrib_GetValue(attrib);
					
					TF2Attrib_SetByDefIndex(weapon, 2, value * FF2R_GetBossData(attacker).GetFloat("bvbdmgmulti", 1.0));
					TF2Attrib_SetByDefIndex(weapon, 28, 0.1);
					
					int entity = CreateEntityByName("item_ammopack_medium");
					if(entity != -1)
					{
						DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
						DispatchSpawn(entity);
						
						SetVariantString("OnUser1 !self:Kill::1:1,0,1");
						AcceptEntityInput(entity, "AddOutput");
						AcceptEntityInput(entity, "FireUser1");
						
						float pos[3];
						GetClientAbsOrigin(attacker, pos);
						pos[2] += 16.0;
						
						TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					}
					return Plugin_Handled;
				}
				else
				{
					float pos[3], ang[3];
					GetClientEyePosition(victim, pos);
					GetClientEyeAngles(victim, ang);
					if(CreateDroppedWeapon(victim, weapon, pos, ang) != INVALID_ENT_REFERENCE)
					{
						StealNext[attacker]--;
						TF2_RemoveItem(victim, weapon);
						TF2_StunPlayer(victim, 0.4, 0.0, TF_STUNFLAG_BONKSTUCK);
						
						if(!StrContains(classname, "tf_weapon_wrench"))
						{
							index = MaxClients + 1;
							while((index = FindEntityByClassname(index, "obj_sentrygun")) != -1)
							{
								if(GetEntPropEnt(index, Prop_Send, "m_hBuilder") == victim && !GetEntProp(index, Prop_Send, "m_bMiniBuilding"))
								{
									FakeClientCommand(victim, "destroy 2");
									AcceptEntityInput(index, "kill");
								}
							}
							
							index = CreateEntityByName("tf_weapon_robot_arm");
							if(index != -1)
							{
								SetEntProp(index, Prop_Send, "m_iItemDefinitionIndex", 142);
								SetEntProp(index, Prop_Send, "m_bInitialized", 1);
								
								SetEntProp(index, Prop_Send, "m_iEntityQuality", 6);
								SetEntProp(index, Prop_Send, "m_iEntityLevel", 15);
								
								DispatchSpawn(index);
								SetEntProp(index, Prop_Send, "m_bValidatedAttachedEntity", true);
								
								EquipPlayerWeapon(victim, index);
							}
						}
						else if(TF2_GetClassnameSlot(classname) == TFWeaponSlot_Melee)
						{
							index = CreateEntityByName(classname);
							if(index != -1)
							{
								SetEntProp(index, Prop_Send, "m_iItemDefinitionIndex", 5);
								SetEntProp(index, Prop_Send, "m_bInitialized", 1);
								
								SetEntProp(index, Prop_Send, "m_iEntityQuality", 0);
								SetEntProp(index, Prop_Send, "m_iEntityLevel", 1);
								
								DispatchSpawn(index);
								SetEntProp(index, Prop_Send, "m_bValidatedAttachedEntity", true);
								
								EquipPlayerWeapon(victim, index);
								
								if(StrContains(classname, "tf_weapon_fists"))
									TF2Attrib_SetByDefIndex(index, 138, 0.5);
							}
						}
						else
						{
							index = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
							if(index != -1 && GetEntityClassname(index, classname, sizeof(classname)))
								FakeClientCommand(victim, "use %s", classname);
						}
						
						IntToString(view_as<int>(TF2_GetPlayerClass(victim)), classname, sizeof(classname));
						FF2R_EmitBossSoundToAll(STEAL_REACT, attacker, classname, victim, SNDCHAN_VOICE, 90, _, 1.0);
						return Plugin_Handled;
					}
				}
			}
			else if(isBoss)
			{
				StealFromBoss(victim, attacker);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

void StealFromBoss(int victim, int attacker)
{
	TF2_StunPlayer(victim, 0.4, 0.5, TF_STUNFLAG_SLOWDOWN, attacker);
	
	ApplyHealEvent(attacker, attacker, 600 * StealNext[attacker]);
	SetHealthTo[attacker] = GetClientHealth(attacker) + (600 * StealNext[attacker]);
	StealNext[attacker] = 0;
	
	TF2_RegeneratePlayer(attacker);
}

int CreateDroppedWeapon(int client, int weapon, const float pos1[3], const float ang[3])
{
	if(!SDKInitDroppedWeapon || !SDKCreate)
		return INVALID_ENT_REFERENCE;
	
	char buffer[PLATFORM_MAX_PATH];
	GetEntityNetClass(weapon, buffer, sizeof(buffer));
	int offset = FindSendPropInfo(buffer, "m_Item");
	if(offset < 0)
		return INVALID_ENT_REFERENCE;
	
	int index;
	if(HasEntProp(weapon, Prop_Send, "m_iWorldModelIndex"))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex");
	}
	else
	{
		index = GetEntProp(weapon, Prop_Send, "m_nModelIndex");
	}
	
	if(index < 1)
		return INVALID_ENT_REFERENCE;
	
	TR_TraceRayFilter(pos1, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_SOLID, RayType_Infinite, Trace_WorldOnly);
	if(!TR_DidHit())
		return INVALID_ENT_REFERENCE;
	
	float pos2[3];
	TR_GetEndPosition(pos2);
	
	ModelIndexToString(index, buffer, sizeof(buffer));
	
	bool mvm = view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
	if(mvm)
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	int entity = SDKCall(SDKCreate, client, pos2, ang, buffer, GetEntityAddress(weapon) + view_as<Address>(offset));
	
	if(mvm)
		GameRules_SetProp("m_bPlayingMannVsMachine", true);
	
	if(entity == INVALID_ENT_REFERENCE)
		return INVALID_ENT_REFERENCE;
	
	//DispatchSpawn(entity);
	SDKCall(SDKInitDroppedWeapon, entity, client, weapon, false, true);
	SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", 1.0);
	
	TeleportEntity(entity, pos1);
	return entity;
}

int EquipRazorback(int client)
{
	int wearable = CreateEntityByName("tf_wearable");
	if(wearable != -1)
	{
		SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", 57);
		SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
		
		SetEntProp(wearable, Prop_Send, "m_iEntityQuality", 6);
		SetEntProp(wearable, Prop_Send, "m_iEntityLevel", 10);
		
		DispatchSpawn(wearable);
		SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntProp(wearable, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		
		EquipWearable(client, wearable);
	}
	return wearable;
}

public Action RazorbackTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker > 0 && attacker <= MaxClients && damagecustom != TF_CUSTOM_BACKSTAB && !IsInvuln(victim) && (GetClientTeam(victim) != GetClientTeam(attacker) || CvarFriendlyFire.BoolValue))
	{
		// Directly from the original rage_front_protection
		float pos1[3], pos2[3], ang[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos1);
		GetEntPropVector(IsValidEntity(inflictor) ? inflictor : attacker, Prop_Send, "m_vecOrigin", pos2);
		GetVectorAnglesTwoPoints(pos1, pos2, ang);
		GetClientEyeAngles(victim, pos2);
		
		float offset = FixAngle(FixAngle(ang[1]) - FixAngle(pos2[1]));
		if(offset > -75.0 && offset < 75.0)
		{
			BossData boss = FF2R_GetBossData(victim);
			AbilityData ability;
			if(RazorbackRef[victim] != INVALID_ENT_REFERENCE && boss && (ability = boss.GetAbility("special_razorback_shield")))
			{
				float hp = ability.GetFloat("current");
				if(hp > damage)
				{
					ability.SetFloat("current", hp - damage);
					EmitGameSoundToAll(SHIELD_HIT, victim, _, victim, pos1);
					
					int entity = EntRefToEntIndex(RazorbackRef[victim]);
					if(entity != INVALID_ENT_REFERENCE)
						SetEntProp(entity, Prop_Send, "m_iClip1", RoundToCeil(hp - damage) / 10);
				}
				else
				{
					ScreenShake(pos1, 25.0, 150.0, 1.0, 50.0);
					EmitGameSoundToAll("Player.Spy_Shield_Break", victim, _, victim, pos1);
					
					int entity = EntRefToEntIndex(RazorbackRef[victim]);
					if(entity != INVALID_ENT_REFERENCE)
					{
						TF2_RemoveItem(victim, entity);
						
						entity = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
						if(entity != -1)
						{
							char buffer[36];
							if(GetEntityClassname(entity, buffer, sizeof(buffer)))
								FakeClientCommand(victim, "use %s", buffer);
						}
					}
					
					entity = EntRefToEntIndex(ability.GetInt("wearableref", INVALID_ENT_REFERENCE));
					if(entity != INVALID_ENT_REFERENCE)
						TF2_RemoveWearable(victim, entity);
					
					RazorbackRef[victim] = INVALID_ENT_REFERENCE;
					CheckRazorbackHooks();
					CheckWeaponSwapHooks(victim);
				}
			}
			else
			{
				SDKUnhook(victim, SDKHook_OnTakeDamageAlive, RazorbackTakeDamage);
				return Plugin_Continue;
			}
			
			damage = 0.0;
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

void CheckRazorbackHooks()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(RazorbackRef[i] != INVALID_ENT_REFERENCE)
			return;
	}
	
	UnhookUserMessage(PlayerShieldBlocked, OnShieldBlocked);
	HookedRazorback = false;
}

bool JumperTestJump(int client, bool success)
{
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability;
	if(boss && (ability = boss.GetAbility("special_wall_jump")))
	{
		bool jumped;
		float gameTime = GetGameTime();
		
		if(WallInLagComp)
		{
			float correct = GetClientLatency(client, NetFlow_Outgoing) + GetEntPropFloat(client, Prop_Data, "m_fLerpTime");
			if(correct > 0.0)
			{
				float cap = CvarMaxUnlag.FloatValue;
				if(correct > cap)
					correct = cap;
				
				gameTime -= correct;
			}
		}
		
		if(ability.GetFloat("cooldown") < gameTime)
		{
			float pos[3];
			GetClientAbsOrigin(client, pos);
			
			static const float Mins[] = { -64.0, -64.0, 0.0 };
			static const float Maxs[] = { 64.0, 64.0, 64.0 };
			Handle trace = TR_TraceHullFilterEx(pos, pos, Mins, Maxs, MASK_SOLID, Trace_WorldOnly);
			if(trace)
			{
				if(TR_DidHit(trace))
				{
					jumped = true;
					
					if(WallInLagComp)
					{
						if(!success && !WallLagComped[client])
						{
							WallLagComped[client] = true;
							SetEntProp(client, Prop_Send, "m_iAirDash", GetEntProp(client, Prop_Send, "m_iAirDash") - 1);
						}
					}
					else
					{
						if(ability.GetBool("stale"))
							WallStale[client]++;
						
						ability.SetFloat("cooldown", gameTime + 0.2 + (WallStale[client] * 0.1));
						
						if(ability.GetBool("double", true))
						{
							SetEntProp(client, Prop_Send, "m_iAirDash", -1);
							EmitSoundToAll(WALL_JUMP, client, SNDCHAN_BODY, SNDLEVEL_DRYER, _, _, 90 + GetURandomInt() % 15, client, pos);
						}
						
						JumperAttribApply(client, 610, WallAirMulti[client], ability.GetFloat("wall_air", 1.0));
					}
					
					JumperAttribApply(client, 107, WallSpeedMulti[client], ability.GetFloat("wall_speed", 1.0));
					JumperAttribApply(client, 443, WallJumpMulti[client], ability.GetFloat("wall_jump", 1.0));
				}
				
				delete trace;
				
				if(jumped)
					return true;
			}
		}
		
		if(!jumped)
		{
			JumperAttribApply(client, 107, WallSpeedMulti[client], ability.GetFloat("double_speed", 1.0));
			JumperAttribApply(client, 443, WallJumpMulti[client], ability.GetFloat("double_jump", 1.0));
			
			if(!WallInLagComp)
				JumperAttribApply(client, 610, WallAirMulti[client], ability.GetFloat("double_air", 1.0));
		}
		else if(!WallInLagComp)
		{
			ClientCommand(client, "playgamesound " ... AMS_DENYUSE);
		}
	}
	else
	{
		WallJumper[client] = false;
	}
	return false;
}

void JumperAttribApply(int client, int index, float &current, float multi)
{
	if(multi != current)
	{
		float value = 1.0;
		Address attrib = TF2Attrib_GetByDefIndex(client, index);
		if(attrib != Address_Null)
			value = TF2Attrib_GetValue(attrib);
		
		value *= multi / current;
		if(value > 1.01 || value < 0.99)
		{
			TF2Attrib_SetByDefIndex(client, index, value);
		}
		else if(attrib != Address_Null)
		{
			TF2Attrib_RemoveByDefIndex(client, index);
		}
		
		current = multi;
		if(index == 107)
			SDKCall(SDKSetSpeed, client);
	}
}

void JumperAttribRestore(int client, int index, float &current)
{
	if(current != 1.0)
	{
		float value = 1.0;
		Address attrib = TF2Attrib_GetByDefIndex(client, index);
		if(attrib != Address_Null)
			value = TF2Attrib_GetValue(attrib);
		
		value /= current;
		if(value > 1.01 || value < 0.99)
		{
			TF2Attrib_SetByDefIndex(client, index, value);
		}
		else if(attrib != Address_Null)
		{
			TF2Attrib_RemoveByDefIndex(client, index);
		}
		
		current = 1.0;
		if(index == 107)
			SDKCall(SDKSetSpeed, client);
	}
}

float SetFloatFromFormula(ConfigData cfg, const char[] key, int players, const char[] defaul = NULL_STRING)
{
	static char buffer[1024];
	cfg.GetString(key, buffer, sizeof(buffer), defaul);
	float value = ParseFormula(buffer, players);
	cfg.SetFloat(key, value);
	return value;
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

float FixAngle(float angle)
{
	while(angle < -180.0)
	{
		angle = angle + 360.0;
	}
	while(angle > 180.0)
	{
		angle = angle - 360.0;
	}
	return angle;
}

void GetVectorAnglesTwoPoints(float startPos[3], float endPos[3], float angles[3])
{
	float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
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

void ScreenShake(const float pos[3], float amplitude, float frequency, float duration, float radius)
{
	int entity = CreateEntityByName("env_shake");
	if(entity != -1)
	{
		DispatchKeyValueFloat(entity, "amplitude", amplitude);
		DispatchKeyValueFloat(entity, "radius", radius);
		DispatchKeyValueFloat(entity, "duration", duration);
		DispatchKeyValueFloat(entity, "frequency", frequency);
		
		DispatchSpawn(entity);
		
		TeleportEntity(entity, pos);
		AcceptEntityInput(entity, "StartShake");
		
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1,0,1", duration + 0.1);
		SetVariantString(buffer);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
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

TFClassType TF2_GetDropClass(int index, TFClassType defaul, int &slot)
{
	slot = TF2Econ_GetItemLoadoutSlot(index, defaul);
	Debug("Index = %d | %d Slot = %d", index, defaul, slot);
	
	if(slot == -1)
	{
		Debug("No Default");
		for(TFClassType class=TFClass_Scout; class<=TFClass_Engineer; class++)
		{
			if(defaul != class)
			{
				slot = TF2Econ_GetItemLoadoutSlot(index, class);
				if(slot != -1)
				{
					if(class == TFClass_Spy)
						FixSpyClass(slot);
					
					Debug("%d Slot = %d", class, slot);
					return class;
				}
			}
		}
	}
	else if(defaul == TFClass_Spy)
	{
		FixSpyClass(slot);
	}
	
	Debug("Defaulted to %d", defaul);
	return defaul;
}

void FixSpyClass(int &slot)
{
	switch(slot)
	{
		case TFWeaponSlot_Secondary:
			slot = TFWeaponSlot_Primary;
		
		case TFWeaponSlot_Building:
			slot = TFWeaponSlot_Secondary;
	}
}

TFClassType TF2_GetWeaponClass(int weapon, TFClassType defaul)
{
	char classname[36];
	GetEntityClassname(weapon, classname, sizeof(classname));
	int slot = TF2_GetClassnameSlot(classname, true);
	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if(TF2Econ_GetItemLoadoutSlot(index, defaul) != slot)
	{
		for(TFClassType class=TFClass_Scout; class<=TFClass_Engineer; class++)
		{
			if(defaul != class && TF2Econ_GetItemLoadoutSlot(index, class) == slot)
				return class;
		}
	}
	return defaul;
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

void ApplyHealEvent(int patient, int healer, int amount)
{
	Event event = CreateEvent("player_healed", true);

	event.SetInt("patient", patient);
	event.SetInt("healer", healer);
	event.SetInt("heals", amount);

	event.Fire();
}

void EquipWearable(int client, int entity)
{
	#if defined __nosoop_tf2_utils_included
	if(TF2ULoaded)
	{
		TF2Util_EquipPlayerWearable(client, entity);
		return;
	}
	#endif
	
	if(SDKEquipWearable)
	{
		SDKCall(SDKEquipWearable, client, entity);
	}
	else
	{
		RemoveEntity(entity);
	}
}

public bool Trace_WorldOnly(int entity, int contentsMask)
{
	return !entity;
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