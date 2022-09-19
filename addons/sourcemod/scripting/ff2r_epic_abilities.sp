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

#pragma semicolon 1
#pragma newdecls required

#include "freak_fortress_2/formula_parser.sp"

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	36
#define FAR_FUTURE		100000000.0

#define AMS_DENYUSE	"common/wpn_denyselect.wav"
#define AMS_SWITCH	"common/wpn_moveselect.wav"
#define WALL_JUMP	"vo/null.mp3"

#define MAG_MAGIC		0x0001	// Can be blocked by sapper effect
#define MAG_MIND		0x0002	// Can't be blocked by stun effects
#define MAG_SUMMON		0x0004	// Require dead players to use
#define MAG_PARTNER		0x0008	// Require an teammate to use
#define MAG_LASTLIFE	0x0010	// Require having no extra lives left
#define MAG_GROUND		0x0020	// Require being on the ground

Handle SDKEquipWearable;
Handle SDKGetMaxHealth;
int PlayersAlive[4];
Handle SyncHud;
bool SpecTeam;
ConVar WeaponLifetime;
int LastWeaponLifetime;

bool HookedWeaponSwap[MAXTF2PLAYERS];

int HasAbility[MAXTF2PLAYERS];

bool HookedRazorback;
int PlayerShieldBlocked;
bool RazorbackDeployed[MAXTF2PLAYERS];
int RazorbackRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};

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
	
	PlayerShieldBlocked = GetUserMessageId("PlayerShieldBlocked");
	
	SyncHud = CreateHudSynchronizer();
	
	// Lateload Support
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			BossData cfg = FF2R_GetBossData(client);
			if(cfg)
				FF2R_OnBossCreated(client, cfg, false);
		}
	}
}

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	bool hookSwapping;
	
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
				weapon = CreateEntityByName("tf_weapon_scattergun");
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
			
			weapon = EquipRazorback(client);
			if(weapon != -1)
				ability.SetInt("wearableref", EntIndexToEntRef(weapon));
			
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
	
	if(RazorbackRef[client] != INVALID_ENT_REFERENCE)
	{
		RazorbackRef[client] = INVALID_ENT_REFERENCE;
		CheckRazorbackHooks();
	}
	
	if(HookedWeaponSwap[client])
	{
		HookedWeaponSwap[client] = false;
		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
		OnWeaponSwitch(client, -2);
	}
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
		AbilityData ability = boss.GetAbility("rage_ability_management");
		if(ability.IsMyPlugin())
			boss.Remove("rage_ability_management");
	}
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
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
	int attacker = bf.ReadByte();
	int victim = bf.ReadByte();
	if(RazorbackRef[victim] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(RazorbackRef[victim]);
		if(entity != INVALID_ENT_REFERENCE)
		{
			TF2_RemoveItem(client, entity);
			if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == entity)
			{
				entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				if(entity != -1)
				{
					char buffer[36];
					if(GetEntityClassname(entity, buffer, sizeof(buffer)))
						FakeClientCommand(client, "use %s", buffer);
				}
			}
		}
		
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_razorback_shield")))
		{
			entity = EntRefToEntIndex(ability.GetInt("wearableref", INVALID_ENT_REFERENCE));
			if(entity != INVALID_ENT_REFERENCE)
				TF2_RemoveWearable(client, entity);
		}
		
		RazorbackRef[victim] = INVALID_ENT_REFERENCE;
		CheckRazorbackHooks();
	}
}

public void OnWeaponSwitch(int client, int weapon)
{
	if(RazorbackRef[client] != INVALID_ENT_REFERENCE && EntRefToEntIndex(RazorbackRef[client]) == weapon)
	{
		if(!RazorbackDeployed[client])
		{
			//TODO: Blah blah, custom viewmodels soon TM
			
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