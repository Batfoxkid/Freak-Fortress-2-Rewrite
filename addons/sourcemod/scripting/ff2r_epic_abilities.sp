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
				"name"		"RAGE"	// Name, can use "name_en", etc. If left blank, section name is used instead
				"delay"		"10.0"	// Initial cooldown
				"cooldown"	"30.0"	// Cooldown on use
				"cost"		"100.0"	// RAGE cost to use
				"consume"	"true"	// Consumes RAGE on use
				"flags"		"0x0003"// Casting flags
				// 0x0001: Magic (Sapper effect prevents casting)
				// 0x0002: Mind (Stun effects DOESN'T prevent casting)
				// 0x0004: Summon (Requires a dead summonable player to cast)
				// 0x0008: Partner (Requires a teammate boss alive to cast)
				// 0x0010: Last Life (Requires a single life left to cast)
				// 0x0020: Grounded (Requires being on the ground to cast)
				
				"cast_low"		"8"	// Lowest ability slot to activate on cast. If left blank, "cast_high" is used
				"cast_high"		"8"	// Highest ability slot to activate on cast. If left blank, "cast_low" is used
				
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
		"timescale"		"0.5"	// Server timescale (Will only apply in Arena)
		"speed"			"520.0"	// Movement speed (Capped at 520 HU/s by default TF2)
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"rage_random_slot"
	{
		"slot"			"0"	// Ability slot
		
		"delay"			"0.0"	// Activation delay
		"low"			"10"	// Lowest slot to activate
		"high"			"14"	// Highest slot to activate
		"count"			"1"	// How many unique slots to activate
		
		"plugin_name"	"ff2r_epic_abilities"
	}
	
	
	"rage_weapon_pickups"
	{
		"slot"			"0"	// Ability slot
		
		"fists"			"1 ; 0.5"	// Attributes applied on players with stolen melees (aka they just have fists now with exception of Heavy & Engineer)
		
		"attributes"	"28 ; 0.5 ; 138 ; 0.6667"	// Attributes applied on stolen weapons
		
		"classswap"		"true"	// If to swap to the correct class
		"animswap"		"true"	// If to swap animations to the correct class
		
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
#include <adt_trie_sort>
#include <cfgmap>
#include <ff2r>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#include "freak_fortress_2/formula_parser.sp"

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	36
#define FAR_FUTURE		100000000.0

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
#define SHIELD_HIT	"vo/null.mp3"
#define WALL_JUMP	"General.banana_slip"

#define MAG_MAGIC		0x0001	// Can be blocked by sapper effect
#define MAG_MIND		0x0002	// Can't be blocked by stun effects
#define MAG_SUMMON		0x0004	// Require dead players to use
#define MAG_PARTNER		0x0008	// Require an teammate to use
#define MAG_LASTLIFE	0x0010	// Require having no extra lives left
#define MAG_GROUND		0x0020	// Require being on the ground

Handle SDKEquipWearable;
Handle SDKGetMaxHealth;
Handle SDKCreate;
Handle SDKInitDroppedWeapon;
int PlayersAlive[4];
Handle SyncHud;
bool SpecTeam;

bool HookedWeaponSwap[MAXTF2PLAYERS];

int HasAbility[MAXTF2PLAYERS];

bool CanPickup[MAXTF2PLAYERS];
bool StealNext[MAXTF2PLAYERS];

bool HookedRazorback;
UserMsg PlayerShieldBlocked;
bool RazorbackDeployed[MAXTF2PLAYERS];
int RazorbackRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};

bool WallJumper[MAXTF2PLAYERS];
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

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	if(!TranslationPhraseExists("Ability Delay"))
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
		LogError("[Gamedata] Could not find CTFDroppedWeapon::Create");
	
	delete gamedata;
	
	PlayerShieldBlocked = GetUserMessageId("PlayerShieldBlocked");
	
	SyncHud = CreateHudSynchronizer();
	
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

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	bool hookSwapping;
	
	if(!CanPickup[client])
	{
		AbilityData ability = boss.GetAbility("rage_weapon_pickups");
		if(ability.IsMyPlugin())
		{
			bool found;
			for(int i = 1; i <= MaxClients; i++)
			{
				if(CanPickup[client])
				{
					found = true;
					break;
				}
			}
			
			CanPickup[client] = true;
			
			if(!found)
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						SDKHook(i, SDKHook_TraceAttack, StealingTraceAttack);
						break;
					}
				}
			}
		}
	}
	
	if(!WallJumper[client])
	{
		AbilityData ability = boss.GetAbility("special_wall_jump");
		if(ability.IsMyPlugin())
			WallJumper[client] = true;
	}
	
	if(RazorbackRef[client] == INVALID_ENT_REFERENCE)
	{
		AbilityData ability = boss.GetAbility("special_razorback_shield");
		if(ability.IsMyPlugin())
		{
			int weapon = -1;
			if(ability.GetBool("secondary"))
			{
				weapon = CreateEntityByName("tf_weapon_pistol");
			}
			else
			{
				weapon = CreateEntityByName("tf_weapon_scattergun");	//TODO: Change to Shortstop
			}
			
			if(weapon != -1)
			{
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 0);
				SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
				
				SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 6);
				SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 101);
				
				DispatchSpawn(weapon);
				
				EquipPlayerWeapon(client, weapon);
				
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 57);
				
				TF2Attrib_SetByDefIndex(weapon, 128, 1.0);
				TF2Attrib_SetByDefIndex(weapon, 303, -1.0);
				TF2Attrib_SetByDefIndex(weapon, 821, 1.0);
				
				RazorbackRef[client] = EntIndexToEntRef(weapon);
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
		}
	}
	
	if(!setup)
	{
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
						
						if(HasAbility[client] == -1 && (entries > buttons || ability.GetBool("cycler")))
						{
							HasAbility[client] = entries;
							ChangeAbility(client, boss, ability, cfg, snap, false);
						}
						
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
	
	if(hookSwapping && !HookedWeaponSwap[client])
	{
		HookedWeaponSwap[client] = true;
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	}
}

public void FF2R_OnBossRemoved(int client)
{
	HasAbility[client] = 0;
	WallJumper[client] = false;
	StealNext[client] = false;
	
	if(RazorbackRef[client] != INVALID_ENT_REFERENCE)
	{
		RazorbackRef[client] = INVALID_ENT_REFERENCE;
		CheckRazorbackHooks();
	}
	
	if(HookedWeaponSwap[client])
		RemoveWeaponSwapHooks(client);
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

public void OnClientPutInServer(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(CanPickup[client])
		{
			SDKHook(client, SDKHook_TraceAttack, StealingTraceAttack);
			break;
		}
	}
}

public void OnClientDisconnect(int client)
{
	WallAirMulti[client] = 1.0;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(WallJumper[client] && (buttons & IN_JUMP))
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_wall_jump")))
		{
			float gameTime = GetGameTime();
			if(ability.GetFloat("cooldown") < gameTime)
			{
				bool jumped;
				
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
						
						ability.SetFloat("cooldown", gameTime + 0.35);
						SetEntProp(client, Prop_Send, "m_iAirDash", ability.GetBool("double", true) ? 0 : -1);
						EmitGameSoundToAll(WALL_JUMP, client, _, client, pos);
						
						if(WallSpeedMulti[client] == 1.0)
						{
							WallSpeedMulti[client] = ability.GetFloat("wall_speed", 1.0);
							if(WallSpeedMulti[client] != 1.0)
								JumperAttribApply(client, 107, WallSpeedMulti[client]);
						}
						
						if(WallJumpMulti[client] == 1.0)
						{
							WallJumpMulti[client] = ability.GetFloat("wall_jump", 1.0);
							if(WallJumpMulti[client] != 1.0)
								JumperAttribApply(client, 443, WallJumpMulti[client]);
						}
						
						if(WallAirMulti[client] == 1.0)
						{
							WallAirMulti[client] = ability.GetFloat("wall_air", 1.0);
							if(WallAirMulti[client] != 1.0)
								JumperAttribApply(client, 610, WallAirMulti[client]);
						}
					}
					
					delete trace;
				}
				
				if(!jumped)
				{
					if(WallSpeedMulti[client] == 1.0)
					{
						WallSpeedMulti[client] = ability.GetFloat("double_speed", 1.0);
						if(WallSpeedMulti[client] != 1.0)
							JumperAttribApply(client, 107, WallSpeedMulti[client]);
					}
					
					if(WallJumpMulti[client] == 1.0)
					{
						WallJumpMulti[client] = ability.GetFloat("double_jump", 1.0);
						if(WallJumpMulti[client] != 1.0)
							JumperAttribApply(client, 443, WallJumpMulti[client]);
					}
					
					if(WallAirMulti[client] == 1.0)
					{
						WallAirMulti[client] = ability.GetFloat("double_air", 1.0);
						if(WallAirMulti[client] != 1.0)
							JumperAttribApply(client, 610, WallAirMulti[client]);
					}
				}
			}
		}
		else
		{
			WallJumper[client] = false;
		}
	}
	else if(WallAirMulti[client] != 1.0)
	{
		JumperAttribRestore(client, 610, WallAirMulti[client]);
		WallAirMulti[client] = 1.0;
	}
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
	if(WallSpeedMulti[client] != 1.0)
	{
		JumperAttribRestore(client, 107, WallSpeedMulti[client]);
		WallSpeedMulti[client] = 1.0;
	}
	
	if(WallJumpMulti[client] != 1.0)
	{
		JumperAttribRestore(client, 443, WallJumpMulti[client]);
		WallJumpMulti[client] = 1.0;
	}
	
	if(HasAbility[client])
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
							hud = ChangeAbility(client, boss, ability, spells, snap, i == count);
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
							hud = ChangeAbility(client, boss, ability, spells, snap, i == count);
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
							hud = ChangeAbility(client, boss, ability, spells, snap, i == count);
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
						if(entries >= count)
						{
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
								if(!(buttons & IN_DUCK) || !GetBossNameCfg(cfg, val.data, sizeof(val.data), lang, "description"))
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
						
						SetHudTextParams(-1.0, 0.78 + (float(entries) * 0.05), 0.1, 255, 255, 255, 255, _, _, 0.01, 0.5);
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
						
						if(entries > HasAbility[client])
							HasAbility[client] = 1;
						
						int length = snap.KeyBufferSize(HasAbility[client] - 1)+1;
						char[] key = new char[length];
						snap.GetKey(HasAbility[client] - 1, key, length);
						spells.GetArray(key, val, sizeof(val));
						
						if(val.tag == KeyValType_Section && val.cfg)
						{
							ConfigData cfg = view_as<ConfigData>(val.cfg);
							if(!(buttons & IN_DUCK) || !GetBossNameCfg(cfg, val.data, sizeof(val.data), lang, "description"))
							{
								if(!GetBossNameCfg(cfg, val.data, sizeof(val.data), lang))
									strcopy(val.data, sizeof(val.data), key);
							}
							
							if(buttons & IN_DUCK)
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
		if(!RazorbackDeployed[client])
		{
			//TODO: Blah blah, custom viewmodels soon TM
			
			SDKHook(client, SDKHook_OnTakeDamageAlive, RazorbackTakeDamage);
			
			BossData boss = FF2R_GetBossData(client);
			AbilityData ability;
			if(boss && (ability = boss.GetAbility("special_razorback_shield")))
			{
				int entity = EntRefToEntIndex(ability.GetInt("wearableref", INVALID_ENT_REFERENCE));
				if(entity != INVALID_ENT_REFERENCE)
					TF2_RemoveWearable(client, entity);
			}
			
			RazorbackDeployed[client] = true;
		}
	}
	else if(RazorbackDeployed[client])
	{
		if(RazorbackRef[client] != INVALID_ENT_REFERENCE)
		{
			SDKUnhook(client, SDKHook_OnTakeDamageAlive, RazorbackTakeDamage);
			
			BossData boss = FF2R_GetBossData(client);
			AbilityData ability;
			if(boss && (ability = boss.GetAbility("special_razorback_shield")))
			{
				int entity = EquipRazorback(client);
				if(entity != -1)
					entity = EntIndexToEntRef(entity);
				
				ability.SetInt("wearableref", entity);
			}
		}
		
		RazorbackDeployed[client] = false;
	}
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
		length = snap.KeyBufferSize(HasAbility[client] - 1)+1;
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
	if(RazorbackRef[client] == INVALID_ENT_REFERENCE)
		RemoveWeaponSwapHooks(client);
}

void RemoveWeaponSwapHooks(int client)
{
	HookedWeaponSwap[client] = false;
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	OnWeaponSwitch(client, -2);
}

public Action StealingTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(attacker > 0 && attacker <= MaxClients && StealNext[attacker] && ((damagetype & DMG_CLUB) || (damagetype & DMG_SLASH) || hitgroup == HITGROUP_LEFTARM || hitgroup == HITGROUP_RIGHTARM))
	{
		int weapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			if(FF2R_GetBossData(victim))
			{
			}
			else
			{
				switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 5, 195:	// Fists are immune
						return Plugin_Continue;
				}
				
				char classname[36];
				if(GetEntityClassname(entity, classname, sizeof(classname)))
				{
					if(!StrContains(classname, "tf_weapon_robot_arm") || !StrContains(classname, "tf_weapon_builder"))
					{
						// Gunslinger, Builder are immune
						return Plugin_Continue;
					}
					else if(!StrContains(classname, "tf_weapon_pda_engineer_build"))
					{
						
						return Plugin_Continue;
					}
					else if(!StrContains(classname, "tf_weapon_pda_engineer_destroy"))
					{
						
						return Plugin_Continue;
					}
					TF2_RemoveItem(victim, entity);
					if( == entity)
					{
						entity = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
						if(entity != -1)
						{
								FakeClientCommand(victim, "use %s", buffer);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

int CreateDroppedWeapon(int client, int weapon, const float pos1[3], const float ang[3])
{
	if(!SDKInitDroppedWeapon || !SDKCreate)
		return INVALID_ENT_REFERENCE;
	
	char classname[32];
	GetEntityNetClass(weapon, classname, sizeof(classname));
	int offset = FindSendPropInfo(classname, "m_Item");
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
	
	char model[PLATFORM_MAX_PATH];
	ModelIndexToString(index, model, sizeof(model));
	
	TR_TraceRayFilter(pos1, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_SOLID, RayType_Infinite, Trace_WorldOnly);
	if(!TR_DidHit())
		return INVALID_ENT_REFERENCE;
	
	float pos2[3];
	TR_GetEndPosition(pos2);
	
	bool mvm = view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
	if(mvm)
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	int entity = SDKCall(SDKCreate, client, pos2, ang, model, GetEntityAddress(weapon) + view_as<Address>(offset));
	
	if(mvm)
		GameRules_SetProp("m_bPlayingMannVsMachine", true);
	
	if(entity == INVALID_ENT_REFERENCE)
		return INVALID_ENT_REFERENCE;
	
	//DispatchSpawn(entity);
	SDKCall(SDKInitDroppedWeapon, entity, client, weapon, false, true);
	
	SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", 100.0);
	
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
		SetEntProp(wearable, Prop_Send, "m_iEntityLevel", 101);
		
		DispatchSpawn(wearable);
		
		EquipWearable(client, wearable);
	}
	return wearable;
}

public Action RazorbackTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker > 0 && attacker <= MaxClients && damagecustom != TF_CUSTOM_BACKSTAB && !IsInvuln(victim))
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
				float hp = ability.GetFloat("durability");
				if(hp > damage)
				{
					ability.SetFloat("durability", hp - damage);
					EmitGameSoundToAll(SHIELD_HIT, victim, _, victim, pos1);
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

void JumperAttribApply(int client, int index, float multi)
{
	float value = 1.0;
	Address attrib = TF2Attrib_GetByDefIndex(client, index);
	if(attrib != Address_Null)
		value = TF2Attrib_GetValue(attrib);
	
	value *= multi;
	if(value > 1.01 || value < 0.99)
	{
		TF2Attrib_SetByDefIndex(client, index, value * multi);
	}
	else if(attrib != Address_Null)
	{
		TF2Attrib_RemoveByDefIndex(client, index);
	}
}

void JumperAttribRestore(int client, int index, float multi)
{
	float value = 1.0;
	Address attrib = TF2Attrib_GetByDefIndex(client, index);
	if(attrib != Address_Null)
		value = TF2Attrib_GetValue(attrib);
	
	value /= multi;
	if(value > 1.01 || value < 0.99)
	{
		TF2Attrib_SetByDefIndex(client, index, value * multi);
	}
	else if(attrib != Address_Null)
	{
		TF2Attrib_RemoveByDefIndex(client, index);
	}
}

float SetFloatFromFormula(ConfigData cfg, const char[] key, int players, const char[] defaul = "")
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

void EquipWearable(int client, int entity)
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

int GetClientMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

public bool Trace_WorldOnly(int entity, int contentsMask)
{
	return !entity;
}