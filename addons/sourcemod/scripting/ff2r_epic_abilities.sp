/*
	"special_ability_management"
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
				"flags"		"0x0001"// Casting flags
				// 0x0001: Magic (Sapper effect prevents casting)
				// 0x0002: Mind (Stun effects DOESN'T prevent casting)
				// 0x0004: Summon (Requires a dead summonable player to cast)
				// 0x0008: Partner (Requires a teammate boss alive to cast)
				// 0x0010: Last Life (Requires a single life left to cast)
				// 0x0020: Grounded (Requires being on the ground to cast)
				
				"cast_low"		"4"	// Lowest ability slot to activate on cast. If left blank, "cast_high" is used
				"cast_high"		"4"	// Highest ability slot to activate on cast. If left blank, "cast_low" is used
				
				"nocast_low"	"5"	// Lowest ability slot to activate trying to cast but unable. If left blank, "nocast_high" is used
				"nocast_high"	"5"	// Lowest ability slot to activate trying to cast but unable. If left blank, "nocast_low" is used
			}
		}
		
		"plugin_name"		"ff2r_epic_abilities"
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

#define MAG_MAGIC		0x0001	// Can be blocked by sapper effect
#define MAG_MIND		0x0002	// Can't be blocked by stun effects
#define MAG_SUMMON		0x0004	// Require dead players to use
#define MAG_PARTNER		0x0008	// Require an teammate to use
#define MAG_LASTLIFE	0x0010	// Require having no extra lives left
#define MAG_GROUND		0x0020	// Require being on the ground

Handle SDKGetMaxHealth;
int PlayersAlive[4];
Handle SyncHud;
bool SpecTeam;

int HasAbility[MAXTF2PLAYERS];

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
	GameData gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
	
	delete gamedata;
	
	LoadTranslations("ff2_rewrite.phrases");
	
	SyncHud = CreateHudSynchronizer();
	
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Post);
	
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
	if(!setup)
	{
		if(!HasAbility[client])
		{
			AbilityData ability = boss.GetAbility("special_ability_management");
			if(ability.IsMyPlugin())
			{
				HasAbility[client] = -1;
				
				int buttons;
				if(boss.GetInt("slot") == 0)
				{
					boss.SetInt("ragemode", 1);
					buttons++;
				}
				
				int players;
				for(int i; i < 4; i++)
				{
					players += PlayersAlive[i];
				}
				
				if(boss.GetBool("altfire", false))
					buttons++;
				
				if(boss.GetBool("reload", true))
					buttons++;
				
				if(boss.GetBool("special", true))
					buttons++;
				
				ConfigData cfg = ability.GetSection("spells");
				if(cfg)
				{
					StringMapSnapshot snap = cfg.Snapshot();
					
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
								SetFloatFromFormula(spell, "cost", players);
								
								float delay = SetFloatFromFormula(spell, "delay", players);
								if(delay > 0.0)
									spell.SetFloat("delay", delay + gameTime);
							}
						}
						
						delete snap;
						
						if(HasAbility[client] == -1 && (entries > buttons || boss.GetBool("cycler")))
							HasAbility[client] = 1;
						
						return;
					}
					
					delete snap;
				}
				
				HasAbility[client] = 0;
				
				char buffer[64];
				boss.GetString("filename", buffer, sizeof(buffer));
				LogError("[Boss] '%s' is missing 'spells' for 'special_ability_management'", buffer);
			}
		}
	}
}

public void FF2R_OnBossRemoved(int client)
{
	HasAbility[client] = 0;
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
	if(cfg.GetInt("refresh") & RAN_ONRAGE)
		RefreshSpells(client, FF2R_GetBossData(client), cfg);
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
		AbilityData ability = boss.GetAbility("special_ability_management");
		if(ability.IsMyPlugin())
			boss.Remove("special_ability_management");
	}
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
	if(HasAbility[client])
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		ConfigData cfg;
		if(boss && (ability = boss.GetAbility("special_ability_management")) && (cfg = ability.GetSection("spells")))
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
				
				GetButtons(ability, false, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 1)
					{
						snap = CreateSortedSnapshot(cfg);
						
						if(HasAbility[client] == -1 && snap.Length > i)
						{
							hud = ActivateAbility(client, boss, snap, i, gameTime, dead, allies);
						}
						else
						{
							hud = ChangeAbility(i == count);
						}
						break;
					}
				}
			}
			else if(buttons & IN_RELOAD)
			{
				holding[client] = IN_RELOAD;
				
				GetButtons(ability, false, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 2)
					{
						snap = CreateSortedSnapshot(cfg);
						
						if(HasAbility[client] == -1 && snap.Length > i)
						{
							hud = ActivateAbility(client, boss, snap, i, gameTime, dead, allies);
						}
						else
						{
							hud = ChangeAbility(i == count);
						}
						break;
					}
				}
			}
			else if(buttons & IN_ATTACK3)
			{
				holding[client] = IN_ATTACK3;
				
				GetButtons(ability, false, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 3)
					{
						snap = CreateSortedSnapshot(cfg);
						
						if(HasAbility[client] == -1 && snap.Length > i)
						{
							hud = ActivateAbility(client, boss, snap, i, gameTime, dead, allies);
						}
						else
						{
							hud = ChangeAbility(i == count);
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
							snap = CreateSortedSnapshot(cfg);
						
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
							cfg.GetArray(key, val, sizeof(val));
							
							if(val.tag == KeyValType_Section && val.cfg)
							{
								if(!(buttons & IN_DUCK) || !GetBossNameCfg(val.cfg, val.data, sizeof(val.data), lang, "description"))
								{
									if(!GetBossNameCfg(val.cfg, val.data, sizeof(val.data), lang))
										strcopy(val.data, sizeof(val.data), key);
								}
								
								if(buttons & IN_DUCK)
								{
									switch(button[i])
									{
										case 0:
											Format(val.data, sizeof(val.data), "[Call for Medic] %s", val.data);
										
										case 1:
											Format(val.data, sizeof(val.data), "[Alt-Fire] %s", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "[Reload] %s", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "[Special Attack] %s", val.data);
									}
									
									int cost = val.cfg.GetFloat("cost");
									if(cost)
										Format(val.data, sizeof(val.data), "%s (%d%%)", val.data, cost);
								}
								else
								{
									switch(button[i])
									{
										case 0:
											Format(val.data, sizeof(val.data), "[E] %s", val.data);
										
										case 1:
											Format(val.data, sizeof(val.data), "[M2] %s", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "[R] %s", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "[M3] %s", val.data);
									}
									
									int flags = val.cfg.GetInt("flags");
									if((flags & MAG_SUMMON) && GetDeadCount(client, dead, allies) && !dead)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Summon");
									}
									else if((flags & MAG_PARTNER) && GetDeadCount(client, dead, allies) && !allies)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Partner");
									}
									else if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs One Life");
									}
									else
									{
										float delay = val.cfg.GetFloat("delay");
										if(delay > gameTime)
										{
											Format(val.data, sizeof(val.data), "%s (%.1fs)", val.data, delay - gameTime + 0.1);
										}
										else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
										{
											Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Ground");
										}
										else
										{
											int cost = val.cfg.GetFloat("cost");
											if(cost)
												Format(val.data, sizeof(val.data), "%s (%d%%)", val.data, cost);
										}
									}
								}
								
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
							snap = CreateSortedSnapshot(cfg);
						
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
						cfg.GetArray(key, val, sizeof(val));
						
						if(val.tag == KeyValType_Section && val.cfg)
						{
							if(!(buttons & IN_DUCK) || !GetBossNameCfg(val.cfg, val.data, sizeof(val.data), lang, "description"))
							{
								if(!GetBossNameCfg(val.cfg, val.data, sizeof(val.data), lang))
									strcopy(val.data, sizeof(val.data), key);
							}
							
							if(buttons & IN_DUCK)
							{
							}
							else
							{
								int cost = val.cfg.GetFloat("cost");
								if(cost)
								{
									Format(buffer, sizeof(buffer), "(%d%% RAGE)", cost);
								}
								else
								{
									buffer[0] = 0;
								}
								
								float delay = val.cfg.GetFloat("delay");
								if(delay > gameTime)
									Format(buffer, sizeof(buffer), "%s (%.1fs)", buffer, delay - gameTime + 0.1);
								
								int flags = val.cfg.GetInt("flags");
								if((flags & MAG_SUMMON) && GetDeadCount(client, dead, allies) && !dead)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs Summon");
								}
								else if((flags & MAG_PARTNER) && GetDeadCount(client, dead, allies) && !allies)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs Partner");
								}
								else if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs One Life");
								}
								else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
								{
									Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Rage Needs Ground");
								}
								else
								{
									float delay = val.cfg.GetFloat("delay");
									if(delay > gameTime)
									{
										Format(buffer, sizeof(buffer), "%s (%.1fs)", buffer, delay - gameTime + 0.1);
									}
									else
									{
										int cost = val.cfg.GetFloat("cost");
										if(cost)
											Format(buffer, sizeof(buffer), "%s (%d%%)", buffer, cost);
									}
								}
							}
								
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

bool ActivateAbility(int client, BossData boss, SortedSnapshot snap, int index, float gameTime, int &dead, int &allies)
{
	int length = snap.KeyBufferSize(index)+1;
	char[] key = new char[length];
	snap.GetKey(index, key, length);
	
	static PackVal val;
	cfg.GetArray(key, val, sizeof(val));
	if(val.tag == KeyValType_Section && val.cfg)
	{
		if(spell.GetFloat("delay") < gameTime)
		{
			int flags = spell.GetInt("flags");
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
				float rage = GetBossCharge(boss, "0");
				float cost = spell.GetFloat("cost");
				if(rage >= cost)
				{
					if(spell.GetBool("consume", true))
						SetBossCharge(boss, "0", rage - cost);
					
					spell.SetFloat("delay", gameTime + spell.GetFloat("cooldown"));
					
					int slot = spell.GetInt("cast_high", spell.GetInt("cast_low"));
					FF2R_DoBossSlot(client, spell.GetInt("cast_low", slot), slot);
					return true;
				}
			}
		}
		
		int slot = spell.GetInt("nocast_high", spell.GetInt("nocast_low", -2147483647));
		if(slot != -2147483647)
		{
			FF2R_DoBossSlot(client, spell.GetInt("nocast_low", slot), slot);
			return true;
		}
	}
	return false;
}

bool GetDeadCount(int client, int &dead, int &allies)
{
	if(dead == -1 || allies == -1)
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
	
	return true;
}

void GetButtons(ConfigData ability, bool cycle, int &count, int buttons[4])
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

public int ShowMenuH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			ViewingMenu[client] = false;
		}
		case MenuAction_Select:
		{
			BossData boss = FF2R_GetBossData(client);
			if(boss)
			{
				AbilityData ability = boss.GetAbility(ABILITY_NAME);
				if(ability)
				{
					int var1;
					bool enabled = (!SetupMode[client] && IsPlayerAlive(client));
					if(enabled && ability.GetInt("weapon", var1) && var1 >= 0)
					{
						if(var1 > 9)
						{
							int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
							if(weapon<=MaxClients || !IsValidEntity(weapon) || !HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") || GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != var1)
								enabled = false;
						}
						else if(GetPlayerWeaponSlot(client, var1) != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
						{
							enabled = false;
						}
					}
					
					if(enabled)
					{
						char buffer[64];
						menu.GetItem(selection, buffer, sizeof(buffer));
						if(buffer[0])
						{
							Format(buffer, sizeof(buffer), "spells.%s", buffer);
							
							ConfigData spell = ability.GetSection(buffer);
							if(spell)
							{
								float gameTime = GetGameTime();
								if(spell.GetFloat("delay") < gameTime)
								{
									bool blocked;
									var1 = spell.GetInt("flags");
									if(var1 & MAG_SUMMON|MAG_PARTNER)
									{
										int team = GetClientTeam(client);
										int dead, allies;
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
										
										if((var1 & MAG_SUMMON) && !dead)
										{
											blocked = true;
										}
										else if((var1 & MAG_PARTNER) && allies)
										{
											blocked = true;
										}
									}
									
									if(!blocked)
									{
										if((var1 & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
										{
											blocked = true;
										}
										else if((var1 & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
										{
											blocked = true;
										}
										else
										{
											ConfigData cost = spell.GetSection("cost");
											if(cost)
											{
												StringMapSnapshot snap = cost.Snapshot();
												
												int entries = snap.Length;
												for(int i; i < entries; i++)
												{
													int length = snap.KeyBufferSize(i)+1;
													char[] key = new char[length];
													snap.GetKey(i, key, length);
													
													float amount;
													ConfigData mana = cost.GetSection(key);
													if(mana)
													{
														amount = mana.GetFloat("cost");
													}
													else
													{
														amount = cost.GetFloat(key);
													}
													
													if(GetBossCharge(boss, key) < amount)
													{
														blocked = true;
														break;
													}
												}
												
												if(!blocked)
												{
													for(int i; i < entries; i++)
													{
														int length = snap.KeyBufferSize(i)+1;
														char[] key = new char[length];
														snap.GetKey(i, key, length);
														
														float amount;
														ConfigData mana = cost.GetSection(key);
														if(!mana)
														{
															amount = cost.GetFloat(key);
														}
														else if(mana.GetBool("consume", true))
														{
															amount = mana.GetFloat("cost");
														}
														
														SetBossCharge(boss, key, GetBossCharge(boss, key) - amount);
													}
												}
												
												delete snap;
											}
											
											if(!blocked)
											{
												spell.SetFloat("delay", gameTime + spell.GetFloat("cooldown"));
												
												int slot = spell.GetInt("high", spell.GetInt("low"));
												FF2R_DoBossSlot(client, slot, spell.GetInt("low", slot));
												
												if(ability.GetInt("refresh") & RAN_ONUSE)
													RefreshSpells(client, boss, ability);
											}
										}
									}
								}
							}
						}
					}
				}
			}
			
			ShowMenuAll(client, false);
		}
	}
	return 0;
}

public void RefreshSpells(int client, BossData boss, AbilityData ability)
{
	ConfigData cfg = ability.GetSection("spells");
	if(cfg)
	{
		int team = GetClientTeam(client);
		int allies;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i))
			{
				if(FF2R_GetBossData(i))
				{
					if(GetClientTeam(i) == team)
						allies++;
				}
			}
		}
		
		int slots = ability.GetInt("limit");	
		float gameTime = GetGameTime();
		
		StringMapSnapshot snap = cfg.Snapshot();
		
		int rands;
		int entries = snap.Length;
		int[] rand = new int[entries];
		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] key = new char[length];
			snap.GetKey(i, key, length);
			
			ConfigData spell = cfg.GetSection(key);
			if(spell)
			{
				int flags = spell.GetInt("flags");
				if(flags & MAG_PRIORITY)
				{
					spell.SetBool("disabled", false);
					slots--;
				}
				else
				{
					spell.SetBool("disabled", true);
					rand[rands++] = i;
				}
			}
		}
		
		if(slots > 0)
		{
			SortIntegers(rand, rands, Sort_Random);
			for(int i; i < rands; i++)
			{
				int length = snap.KeyBufferSize(rand[i])+1;
				char[] key = new char[length];
				snap.GetKey(rand[i], key, length);
				
				ConfigData spell = cfg.GetSection(key);
				if(spell)
				{
					int flags = spell.GetInt("flags");
					if((flags & MAG_PARTNER) && allies)
						continue;
					
					if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
						continue;
					
					if(spell.GetFloat("delay") > gameTime)
						continue;
					
					spell.SetBool("disabled", false);
					if(--slots < 1)
						break;
				}
			}
		}
		
		if(slots > 0)
		{
			for(int i; i < rands; i++)
			{
				int length = snap.KeyBufferSize(rand[i])+1;
				char[] key = new char[length];
				snap.GetKey(rand[i], key, length);
				
				ConfigData spell = cfg.GetSection(key);
				if(spell && spell.GetBool("disabled"))
				{
					int flags = spell.GetInt("flags");
					if((flags & MAG_PARTNER) && allies)
						continue;
					
					if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
						continue;
					
					spell.SetBool("disabled", false);
					if(--slots < 1)
						break;
				}
			}
		}
		
		if(slots > 0)
		{
			for(int i; i < rands; i++)
			{
				int length = snap.KeyBufferSize(rand[i])+1;
				char[] key = new char[length];
				snap.GetKey(rand[i], key, length);
				
				ConfigData spell = cfg.GetSection(key);
				if(spell && spell.GetBool("disabled"))
				{
					spell.SetBool("disabled", false);
					if(--slots < 1)
						break;
				}
			}
		}
		
		delete snap;
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		if(victim)
		{
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(victim != attacker && attacker > 0 && attacker <= MaxClients)
			{
				if(MenuTimer[attacker])
				{
					BossData boss = FF2R_GetBossData(attacker);
					if(boss)
					{
						AbilityData ability = boss.GetAbility(ABILITY_NAME);
						if(ability)
						{
							bool found;
							ConfigData manas = ability.GetSection("manas");
							if(manas)
							{
								StringMapSnapshot snap = manas.Snapshot();
								
								int entries = snap.Length;
								for(int i; i < entries; i++)
								{
									int length = snap.KeyBufferSize(i)+1;
									char[] key = new char[length];
									snap.GetKey(i, key, length);
									
									ConfigData mana = manas.GetSection(key);
									if(mana)
									{
										float amount = mana.GetFloat("onkill");
										if(amount)
										{
											amount += GetBossCharge(boss, key);
											
											if(amount < 0.0)
											{
												amount = 0.0;
											}
											else 
											{
												float maximum = mana.GetFloat("maximum");
												if(maximum > 0.0 && amount > maximum)
													amount = maximum;
											}
											
											SetBossCharge(boss, key, amount);
											found = true;
										}
									}
								}
								
								delete snap;
							}
							
							if(ability.GetInt("refresh") & RAN_ONKILL)
							{
								RefreshSpells(attacker, boss, ability);
								found = true;
							}
							
							if(found)
								ShowMenuAll(attacker, false);
						}
					}
				}
			}
			
			if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i == victim || i == attacker || IsClientInGame(i))
						AddManaEvent(i, "onbossdeath");
				}
			}
		}
	}
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		if(victim)
		{
			float damage = float(event.GetInt("damageamount"));	// If we get neagtive damage, not my fault!
			AddManaEvent(victim, "onhurt", damage);
			
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(victim != attacker && attacker > 0 && attacker <= MaxClients)
				AddManaEvent(attacker, "ondamage", damage);
		}
	}
}

public void OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled && !event.GetInt("weaponid")) 
	{
		int client = GetClientOfUserId(event.GetInt("ownerid"));
		if(client > 0 && client <= MaxClients)
			AddManaEvent(client, "onairblast");
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

int GetClientMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}