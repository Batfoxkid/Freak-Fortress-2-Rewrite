/*
		"name"		"special_menu_manager"

		"slot"		"0"			// Ability slot to count for refresh rage flag
		"tickrate"	"0.1"		// Menu tick rate
		"weapon"	"-1"		// Weapon slot (0-9) or weapon index (10+)
		"limit"		"-1"		// Max amount of spells to choose from at once
		"refresh"	"0x0000"	// When to refresh spell list if limit is enabled
		// 0x0001: On Kill
		// 0x0002: On Spell Cast
		// 0x0004: On Rage (Uses "slot")
		
		"manas"
		{
			"0"	// Ability Slot, eg. 0 syncs with RAGE meter
			{
				"name"		"MP"	// Name, can use "name_en", etc. If left blank, section name is used instead
				"start"		"0.0"	// Starting amount
				"maximum"	"100.0"	// Maximum amount
				
				"display"	"0.0"	// Starting display amount. If left blank, "start" is used
				"rolling"	"0.0"	// Rolling animation speed
				
				"ontick"		"0.0"	// Gain every menu tick
				"onkill"		"0.0"	// Gain on a kill
				"onbossdeath"	"0.0"	// Gain when a boss dies
				"onhurt"		"0.0"	// Gain for every point of damage taken
				"ondamage"		"0.0"	// Gain for every point of damage dealt
				"onairblast"	"0.0"	// Gain when airblasted
			}
		}
		
		"spells"
		{
			"0"	// Sorted in number and ABC order
			{
				"name"		"RAGE"	// Name, can use "name_en", etc. If left blank, section name is used instead
				"delay"		"10.0"	// Initial cooldown
				"cooldown"	"30.0"	// Cooldown on use
				"low"		"4"		// Lowest ability slot to activate. If left blank, "high" is used
				"high"		"4"		// Highest ability slot to activate. If left blank, "low" is used
				"flags"		"0x0001"// Casting flags
				// 0x0001: Magic (Sapper effect prevents casting)
				// 0x0002: Mind (Stun effects DOESN'T prevent casting)
				// 0x0004: Summon (Requires a dead summonable player to cast)
				// 0x0008: Partner (Requires a teammate boss alive to cast)
				// 0x0010: Last Life (Requires a single life left to cast)
				// 0x0020: Grounded (Requires being on the ground to cast)
				// 0x0040: Priority (Will always appear when "limit" is on)
				
				"cost"	// Contains two different methods
				{
					"0"		"100.0"	// Cost of Mana 0
					
					"0"
					{
						"cost"		"100.0"	// Cost of Mana 0
						"consume"	"1"		// Consumes mana cost
					}
				}
			}
		}
		
		"plugin_name"	"ff2r_menu_abilities"
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

#define ABILITY_NAME	"special_menu_manager"

#define MAXTF2PLAYERS	36
#define FAR_FUTURE		100000000.0

#define MAG_MAGIC		0x0001	// Can be blocked by sapper effect
#define MAG_MIND		0x0002	// Can't be blocked by stun effects
#define MAG_SUMMON		0x0004	// Require dead players to use
#define MAG_PARTNER		0x0008	// Require an teammate to use
#define MAG_LASTLIFE	0x0010	// Require having no extra lives left
#define MAG_GROUND		0x0020	// Require being on the ground
#define MAG_PRIORITY	0x0040	// Priority in spell swap
 
#define RAN_ONKILL		0x0001	// Refresh on kill
#define RAN_ONUSE		0x0002	// Refresh on usage
#define RAN_ONRAGE		0x0004	// Refresh on rage

bool Enabled;
Handle SDKGetMaxHealth;
Handle MenuTimer[MAXTF2PLAYERS];
bool ViewingMenu[MAXTF2PLAYERS];
int PlayersAlive[4];
bool SpecTeam;

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Menu Abilities",
	author		=	"Batfoxkid",
	description	=	"I'm coming for you!",
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
		AbilityData ability = boss.GetAbility(ABILITY_NAME);
		if(ability.IsMyPlugin())
		{
			float tickrate = ability.GetFloat("tickrate");
			if(tickrate < 0.0)
				tickrate = 0.0;
			
			if(MenuTimer[client])
				KillTimer(MenuTimer[client]);
			
			MenuTimer[client] = CreateTimer(tickrate, Timer_MenuTick, client, TIMER_REPEAT);
			Enabled = true;
			
			int players;
			for(int i; i < 4; i++)
			{
				players += PlayersAlive[i];
			}
			
			char buffer[16];
			ConfigData manas = ability.GetSection("manas");
			if(manas)
			{
				StringMapSnapshot snap = manas.Snapshot();
				if(snap)
				{
					int entries = snap.Length;
					for(int i; i < entries; i++)
					{
						int length = snap.KeyBufferSize(i)+1;
						char[] key = new char[length];
						snap.GetKey(i, key, length);
						
						ConfigData mana = manas.GetSection(key);
						if(mana)
						{
							float start = SetFloatFromFormula(mana, "start", players);
							SetBossCharge(boss, key, start);
							
							FloatToString(start, buffer, sizeof(buffer));
							SetFloatFromFormula(mana, "display", players, buffer);
							SetFloatFromFormula(mana, "rolling", players);
							SetFloatFromFormula(mana, "maximum", players);
							SetFloatFromFormula(mana, "ontick", players);
						}
					}
					
					delete snap;
				}
			}
			
			ConfigData cfg = ability.GetSection("spells");
			if(cfg)
			{
				StringMapSnapshot snap = cfg.Snapshot();
				if(snap)
				{
					int entries = snap.Length;
					for(int i; i < entries; i++)
					{
						int length = snap.KeyBufferSize(i)+1;
						char[] key = new char[length];
						snap.GetKey(i, key, length);
						
						ConfigData spell = cfg.GetSection(key);
						if(spell)
						{
							SetFloatFromFormula(spell, "delay", players);
							SetFloatFromFormula(spell, "cooldown", players);
							
							if(manas)
							{
								ConfigData cost = spell.GetSection("cost");
								if(cost)
								{
									SortedSnapshot snap2 = CreateSortedSnapshot(cost);
									if(snap2)
									{
										int entries2 = snap2.Length;
										for(int a; a < entries2; a++)
										{
											length = snap2.KeyBufferSize(a)+1;
											char[] key2 = new char[length];
											snap.GetKey(a, key2, length);
											
											ConfigData mana = cost.GetSection(key2);
											if(mana)
											{
												SetFloatFromFormula(mana, "cost", players);
											}
											else
											{
												SetFloatFromFormula(cost, key2, players);
											}
										}
										
										delete snap2;
									}
								}
							}
						}
					}
					
					delete snap;
				}
			}
			
			if(ability.GetInt("limit") > 0)
				RefreshSpells(client, boss, ability);
		}
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

public void FF2R_OnBossRemoved(int client)
{
	if(MenuTimer[client])
	{
		KillTimer(MenuTimer[client]);
		MenuTimer[client] = null;
	}
	
	if(ViewingMenu[client])
		CancelClientMenu(client, false);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(MenuTimer[i])
			return;
	}
	
	Enabled = false;
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

public Action Timer_MenuTick(Handle timer, int client)
{
	if(IsClientInGame(client) && ShowMenuAll(client, true))
		return Plugin_Continue;
	
	// This shouldn't happen ever
	LogError("FF2R_OnBossRemoved was not called, yell at Batfoxkid");
	MenuTimer[client] = null;
	return Plugin_Stop;
}

public bool ShowMenuAll(int client, bool ticked)
{
	BossData boss = FF2R_GetBossData(client);
	if(boss)
	{
		AbilityData ability = boss.GetAbility(ABILITY_NAME);
		if(ability)
		{
			int var1;
			bool enabled = IsPlayerAlive(client);
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
			
			if(ViewingMenu[client] || (enabled && GetClientMenu(client) == MenuSource_None))
				ShowMenu(client, client, boss, ability, enabled, ticked);
			
			int team1 = GetClientTeam(client);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(client != i && IsClientInGame(i) && IsClientObserver(i) && GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client && (ViewingMenu[i] || (enabled && GetClientMenu(i) == MenuSource_None)))
				{
					int team2 = GetClientTeam(i);
					if(team2 == view_as<int>(TFTeam_Spectator) || team1 == team2)
						ShowMenu(i, client, boss, ability, enabled, false);
				}
			}
			
			return true;
		}
	}
	
	return false;
	
}

public void ShowMenu(int target, int client, BossData boss, AbilityData ability, bool alive, bool ticked)
{
	int lang = GetClientLanguage(target);
	
	static char buffer1[256];
	if(!GetBossNameCfg(boss, buffer1, sizeof(buffer1), lang))
		GetClientName(client, buffer1, sizeof(buffer1));
	
	Format(buffer1, sizeof(buffer1), "%s\n%d / %d HP\n", buffer1, alive ? GetClientHealth(client) : 0, GetClientMaxHealth(client));
	
	int var1 = boss.GetInt("lives", 1);
	if(var1 > 1)
	{
		int lives = alive ? boss.GetInt("livesleft", 1) : 0;
		Format(buffer1, sizeof(buffer1), "%s%d / %d Lives\n", buffer1, lives, var1);
	}
	
	static char buffer2[64];
	ConfigData manas = ability.GetSection("manas");
	if(manas)
	{
		SortedSnapshot snap = CreateSortedSnapshot(manas);
		if(snap)
		{
			var1 = snap.Length;
			for(int i; i < var1; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] key = new char[length];
				snap.GetKey(i, key, length);
				
				ConfigData mana = manas.GetSection(key);
				if(mana)
				{
					float maximum = mana.GetFloat("maximum");
					float amount;
					if(alive && ticked)
					{
						amount = mana.GetFloat("ontick");
						if(amount)
						{
							amount += GetBossCharge(boss, key);
							if(amount < 0.0)
							{
								amount = 0.0;
							}
							else if(maximum > 0.0 && amount > maximum)
							{
								amount = maximum;
							}
						}
						else
						{
							amount = GetBossCharge(boss, key);
						}
						
						float rolling = mana.GetFloat("rolling");
						if(rolling > 0.0)
						{
							float current = mana.GetFloat("display");
							if(current > amount)
							{
								current -= rolling;
								if(current < amount)
									current = amount;
								
								mana.SetFloat("display", current);
								amount = current;
							}
							else if(current < amount)
							{
								current += rolling;
								if(current > amount)
									current = amount;
								
								mana.SetFloat("display", current);
								amount = current;
							}
						}
						else
						{
							mana.SetFloat("display", amount);
						}
					}
					else
					{
						amount = mana.GetFloat("display");
					}
					
					if(!GetBossNameCfg(mana, buffer2, sizeof(buffer2), lang))
						strcopy(buffer2, sizeof(buffer2), key);
					
					if(maximum > 0.0)
					{
						Format(buffer1, sizeof(buffer1), "%s%d / %d %s\n", buffer1, amount, maximum, buffer2);
					}
					else
					{
						Format(buffer1, sizeof(buffer1), "%s%d %s\n", buffer1, amount, buffer2);
					}
				}
			}
			
			delete snap;
		}
	}
	
	Menu menu = new Menu(client == target ? ShowMenuH : SpecMenuH);
	menu.SetTitle(buffer1);
	
	bool limited;
	var1 = 0;
	
	float tickrate = ability.GetFloat("tickrate");
	
	ConfigData cfg = ability.GetSection("spells");
	if(cfg)
	{
		SortedSnapshot snap = CreateSortedSnapshot(cfg);
		if(snap)
		{
			limited = view_as<bool>(ability.GetInt("limit"));
			
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
			
			float gameTime = GetGameTime();
			
			int entries = snap.Length;
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] key = new char[length];
				snap.GetKey(i, key, length);
				
				ConfigData spell = cfg.GetSection(key);
				if(spell)
				{
					if(spell.GetInt("disabled"))
					{
						if(!limited)
						{
							menu.AddItem("", "", ITEMDRAW_DISABLED|ITEMDRAW_NOTEXT);
							var1++;
						}
						continue;
					}
					
					var1++;
					if(!GetBossNameCfg(spell, buffer1, sizeof(buffer1), lang))
						strcopy(buffer1, sizeof(buffer1), key);
					
					bool blocked = !alive;
					if(!blocked)
					{
						if(manas)
						{
							ConfigData cost = spell.GetSection("cost");
							if(cost)
							{
								SortedSnapshot snap2 = CreateSortedSnapshot(cost);
								if(snap2)
								{
									int entries2 = snap2.Length;
									for(int a; a < entries2; a++)
									{
										length = snap2.KeyBufferSize(a)+1;
										char[] key2 = new char[length];
										snap.GetKey(a, key2, length);
										
										float amount;
										ConfigData mana = cost.GetSection(key2);
										if(mana)
										{
											amount = mana.GetFloat("cost");
										}
										else
										{
											amount = cost.GetFloat(key2);
										}
										
										if(amount >= 0.0)
										{
											mana = manas.GetSection(key2);
											if(mana)
											{
												if(!GetBossNameCfg(mana, buffer2, sizeof(buffer2), lang))
													strcopy(buffer2, sizeof(buffer2), key2);
												
												if(mana.GetFloat("display") < amount || GetBossCharge(boss, key2) < amount)
													blocked = true;
											}
											else
											{
												strcopy(buffer2, sizeof(buffer2), key2);
											}
											
											Format(buffer1, sizeof(buffer1), "%s (%d %s)", buffer1, RoundToCeil(amount), buffer2);
										}
									}
									
									delete snap2;
								}
							}
						}
					}
					
					float cooldown = spell.GetFloat("delay") - gameTime;
					if(cooldown > 0.0)
					{
						if(cooldown < 1000.0)
							Format(buffer1, sizeof(buffer1), "%s [%.1f]", buffer1, cooldown);
						
						blocked = true;
					}
					
					if(!blocked)
					{
						int flags = spell.GetInt("flags");
						if((flags & MAG_SUMMON) && !dead)
						{
							blocked = true;
						}
						else if((flags & MAG_PARTNER) && !allies)
						{
							blocked = true;
						}
						else if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
						{
							blocked = true;
						}
						else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
						{
							blocked = true;
						}
					}
					
					if(blocked)
					{
						menu.AddItem("", buffer1, ITEMDRAW_DISABLED);
					}
					else
					{
						menu.AddItem(key, buffer1);
					}
				}
			}
			
			delete snap;
		}
	}
	
	if(!var1)
		menu.AddItem("", "", ITEMDRAW_SPACER);
	
	if(var1 < 11)
		menu.Pagination = 0;
	
	menu.ExitButton = false;
	menu.OptionFlags |= MENUFLAG_NO_SOUND;
	ViewingMenu[target] = menu.Display(target, RoundToCeil(tickrate + 0.1));
	if(!alive)
		ViewingMenu[target] = false;
}

public int SpecMenuH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel, MenuAction_Select:
		{
			ViewingMenu[client] = false;
		}
	}
	return 0;
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
					bool enabled = IsPlayerAlive(client);
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
												if(snap)
												{
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
		SortedSnapshot snap = CreateSortedSnapshot(cfg);
		if(snap)
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
								if(snap)
								{
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

void AddManaEvent(int client, const char[] event, float multi = 1.0)
{
	if(MenuTimer[client])
	{
		BossData boss = FF2R_GetBossData(client);
		if(boss)
		{
			AbilityData ability = boss.GetAbility(ABILITY_NAME);
			if(ability)
			{
				ConfigData manas = ability.GetSection("manas");
				if(manas)
				{
					StringMapSnapshot snap = manas.Snapshot();
					if(snap)
					{
						bool found;
						int entries = snap.Length;
						for(int i; i < entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							char[] key = new char[length];
							snap.GetKey(i, key, length);
							
							ConfigData mana = manas.GetSection(key);
							if(mana)
							{
								float amount = mana.GetFloat(event);
								if(amount)
								{
									amount *= multi;
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
						
						if(found)
							ShowMenuAll(client, false);
					}
				}
			}
		}
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

int GetClientMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}