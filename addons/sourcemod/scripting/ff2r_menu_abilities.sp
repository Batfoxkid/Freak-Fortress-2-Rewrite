/*
	"special_menu_manager"
	{
		"slot"		"0"			// Ability slot to count for refresh rage flag
		"tickrate"	"0.1"		// Menu tick rate
		"weapon"	"-1"		// Weapon slot (0-9) or weapon index (10+)
		"limit"		"-1"		// Max amount of spells to choose from at once
		"refresh"	"0"	// When to refresh spell list if limit is enabled
		// 1: On Kill
		// 2: On Spell Cast
		// 4: On Rage (Uses "slot")
		
		"manas"
		{
			"0"	// Ability Slot, eg. 0 syncs with RAGE meter. Don't use slots 1, 2, 3 or your going to have a bad time.
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
				"global cooldown"	"30.0"	// Like 'cooldown', but applies to all spells
				"low"		"8"		// Lowest ability slot to activate. If left blank, "high" is used
				"high"		"8"		// Highest ability slot to activate. If left blank, "low" is used
				"flags"		"1"		// Casting flags
				// 1: Magic (Sapper effect prevents casting)
				// 2: Mind (Stun effects DOESN'T prevent casting)
				// 4: Summon (Requires a dead summonable player to cast)
				// 8: Partner (Requires a teammate boss alive to cast)
				// 16: Last Life (Requires a single life left to cast)
				// 32: Grounded (Requires being on the ground to cast)
				// 64: Priority (Will always appear when "limit" is on)
				
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
	}
	
	"ff2r_menu_abilities"
	{
		"manarate"	"1.0"
		"nomana"	"0"
		"nomenu"	"0"
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

#define ABILITY_NAME	"special_menu_manager"

#define MAXTF2PLAYERS	MAXPLAYERS+1
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
int ViewingPage[MAXTF2PLAYERS];
bool SetupMode[MAXTF2PLAYERS];
int PlayersAlive[4];
bool SpecTeam;

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Menu Abilities",
	author		=	"Batfoxkid",
	description	=	"Watch what happens when I cast a spell I don't know!",
	version		=	PLUGIN_VERSION,
	url			=	"https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite"
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	LoadTranslations("core.phrases");
	if(!TranslationPhraseExists("Ability Delay"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
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
	if((!setup || FF2R_GetGamemodeType() != 2) && !MenuTimer[client])
	{
		AbilityData ability = boss.GetAbility(ABILITY_NAME);
		if(ability.IsMyPlugin())
		{
			float tickrate = ability.GetFloat("tickrate");
			if(tickrate < 0.0)
				tickrate = 0.0;
			
			if(MenuTimer[client])
				KillTimer(MenuTimer[client]);
			
			bool wasInSetup = SetupMode[client];
			
			MenuTimer[client] = CreateTimer(tickrate, Timer_MenuTick, client, TIMER_REPEAT);
			SetupMode[client] = setup;
			Enabled = true;
			
			if(!SetupMode[client])
			{
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
							SetFloatFromFormula(mana, "onkill", players);
							SetFloatFromFormula(mana, "onbossdeath", players);
							SetFloatFromFormula(mana, "onhurt", players);
							SetFloatFromFormula(mana, "ondamage", players);
							SetFloatFromFormula(mana, "onairblast", players);
						}
					}
					
					delete snap;
				}
				
				ConfigData cfg = ability.GetSection("spells");
				if(cfg)
				{
					float gameTime = GetGameTime();
					StringMapSnapshot snap = cfg.Snapshot();
					
					int entries = snap.Length;
					for(int i; i < entries; i++)
					{
						int length = snap.KeyBufferSize(i)+1;
						char[] key = new char[length];
						snap.GetKey(i, key, length);
						
						ConfigData spell = cfg.GetSection(key);
						if(spell)
						{
							SetFloatFromFormula(spell, "cooldown", players);
							
							float delay = SetFloatFromFormula(spell, "delay", players);
							if(delay > 0.0)
								spell.SetFloat("delay", delay + gameTime);
							
							if(manas)
							{
								ConfigData cost = spell.GetSection("cost");
								if(cost)
								{
									SortedSnapshot snap2 = CreateSortedSnapshot(cost);
									
									int entries2 = snap2.Length;
									for(int a; a < entries2; a++)
									{
										length = snap2.KeyBufferSize(a)+1;
										char[] key2 = new char[length];
										snap2.GetKey(a, key2, length);
										
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
					
					delete snap;
				}
			}
			
			if(!wasInSetup && ability.GetInt("limit") > 0)
				RefreshSpells(client, boss, ability);
		}
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

public void FF2R_OnBossRemoved(int client)
{
	if(MenuTimer[client])
	{
		KillTimer(MenuTimer[client]);
		MenuTimer[client] = null;
	}
	
	if(ViewingMenu[client])
		CancelClientMenu(client, false);
	
	SetupMode[client] = false;
	ViewingPage[client] = 0;
	
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

public void FF2R_OnBossModifier(int client, ConfigData cfg)
{
	BossData boss = FF2R_GetBossData(client);
	
	if(boss.GetBool("nomenu"))
	{
		AbilityData ability = boss.GetAbility(ABILITY_NAME);
		if(ability.IsMyPlugin())
			boss.Remove(ABILITY_NAME);
	}
	else if(boss.GetBool("nomana"))
	{
		AbilityData ability = boss.GetAbility(ABILITY_NAME);
		if(ability.IsMyPlugin())
		{
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
						SetBossCharge(boss, key, 0.0);
						mana.SetFloat("maximum", 0.0);
					}
				}
				
				delete snap;
			}
		}
	}
	else
	{
		float multi = cfg.GetFloat("manarate", -1.0);
		if(multi >= 0.0 && multi != 1.0)
		{
			AbilityData ability = boss.GetAbility(ABILITY_NAME);
			if(ability.IsMyPlugin())
			{
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
							SetBossCharge(boss, key, GetBossCharge(boss, key) * multi);
							
							mana.SetFloat("ontick", mana.GetFloat("ontick") * multi);
							mana.SetFloat("onkill", mana.GetFloat("onkill") * multi);
							mana.SetFloat("onbossdeath", mana.GetFloat("onbossdeath") * multi);
							mana.SetFloat("onhurt", mana.GetFloat("onhurt") * multi);
							mana.SetFloat("ondamage", mana.GetFloat("ondamage") * multi);
							mana.SetFloat("onairblast", mana.GetFloat("onairblast") * multi);
						}
					}
					
					delete snap;
				}
			}
		}
	}
}

public Action Timer_MenuTick(Handle timer, int client)
{
	if(IsClientInGame(client) && ShowMenuAll(client, !SetupMode[client]))
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
			int var1 = ability.GetInt("weapon", -1);
			bool enabled = IsPlayerAlive(client);
			if(enabled && var1 >= 0)
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
			
			if(enabled && (ViewingMenu[client] || GetClientMenu(client) == MenuSource_None))
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
	
	Format(buffer1, sizeof(buffer1), "%s\n%t\n", buffer1, "Boss HP", alive ? GetClientHealth(client) : 0, GetClientMaxHealth(client));
	
	int var1 = boss.GetInt("lives", 1);
	if(var1 > 1)
	{
		int lives = alive ? boss.GetInt("livesleft", 1) : 0;
		Format(buffer1, sizeof(buffer1), "%s%t\n", buffer1, "Boss Lives", lives, var1);
	}
	
	static char buffer2[64];
	ConfigData manas = ability.GetSection("manas");
	if(manas)
	{
		SortedSnapshot snap = CreateSortedSnapshot(manas);
		
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
						SetBossCharge(boss, key, amount);
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
					Format(buffer1, sizeof(buffer1), "%s%d / %d %s\n", buffer1, RoundToFloor(amount), RoundToFloor(maximum), buffer2);
				}
				else
				{
					Format(buffer1, sizeof(buffer1), "%s%d %s\n", buffer1, RoundToFloor(amount), buffer2);
				}
			}
		}
		
		delete snap;
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
		
		limited = view_as<bool>(ability.GetInt("limit"));
		
		int team = GetClientTeam(client);
		int dead, allies;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i))
			{
				if(FF2R_GetBossData(i))
				{
					if(IsPlayerAlive(i) && GetClientTeam(i) == team)
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
						menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_DISABLED|ITEMDRAW_NOTEXT);
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
							
							int entries2 = snap2.Length;
							for(int a; a < entries2; a++)
							{
								length = snap2.KeyBufferSize(a)+1;
								char[] key2 = new char[length];
								snap2.GetKey(a, key2, length);
								
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
				
				if(SetupMode[client])
				{
					float cooldown = spell.GetFloat("delay");
					if(cooldown < 0.0)
						cooldown = 0.0;
					
					if(cooldown < 1000.0)
						Format(buffer1, sizeof(buffer1), "%s [%.1f]", buffer1, cooldown);
					
					blocked = true;
				}
				else
				{
					float cooldown = spell.GetFloat("delay") - gameTime;
					if(cooldown > 0.0)
					{
						if(cooldown < 1000.0)
							Format(buffer1, sizeof(buffer1), "%s [%.1f]", buffer1, cooldown);
						
						blocked = true;
					}
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
					menu.AddItem(NULL_STRING, buffer1, ITEMDRAW_DISABLED);
				}
				else
				{
					menu.AddItem(key, buffer1);
				}
			}
		}
		
		delete snap;
	}
	
	if(!var1)
	{
		menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);
	}
	else if(var1 > 10)
	{
		for(int i = 7; ; i += 10)
		{
			if(i == 7)
			{
				menu.InsertItem(i, NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);	// 8. 
			}
			else
			{
				Format(buffer2, sizeof(buffer2), "%t", "Previous");
				
				if(i >= var1)	// Not enough items for a new page
				{
					while(i > var1)
					{
						menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);	// 2-7. 
						var1++;
					}
					
					menu.AddItem("#", buffer2);	// 8. Back
					break;
				}
				else
				{
					menu.InsertItem(i, "#", buffer2);	// 8. Back
				}
			}
			
			Format(buffer2, sizeof(buffer2), "%t", "Next");
			menu.InsertItem(i + 1, "@", buffer2);		// 9. Next
			menu.InsertItem(i + 2, NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);	// 0. 
			var1 += 3;
		}
	}
	else
	{
		ViewingPage[client] = 0;
	}
	
	menu.Pagination = 0;
	menu.ExitButton = false;
	menu.OptionFlags |= MENUFLAG_NO_SOUND;
	ViewingMenu[target] = menu.DisplayAt(target, ViewingPage[client] * 10, RoundToCeil(tickrate + 0.1));
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
					int var1 = ability.GetInt("weapon", -1);
					bool enabled = (!SetupMode[client] && IsPlayerAlive(client));
					if(enabled && var1 >= 0)
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
						if(buffer[0] == '@')
						{
							ViewingPage[client]++;
						}
						else if(buffer[0] == '#')
						{
							ViewingPage[client]--;
						}
						else if(buffer[0])
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
													if(IsPlayerAlive(i) && GetClientTeam(i) == team)
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
												FF2R_DoBossSlot(client, spell.GetInt("low", slot), slot);
												
												if(ability.GetInt("refresh") & RAN_ONUSE)
													RefreshSpells(client, boss, ability);

												float globalCooldown = spell.GetFloat("global cooldown");
												ConfigData cfg = ability.GetSection("spells");
												if(cfg)
												{
													StringMapSnapshot snap = cfg.Snapshot();

													int entries = snap.Length;
													for(int i; i < entries; i++)
													{
														int length = snap.KeyBufferSize(i)+1;
														char[] key = new char[length];
														snap.GetKey(i, key, length);

														ConfigData spell2 = cfg.GetSection(key);

														if(spell2)
														{
															if(spell2.GetFloat("delay") < gameTime + globalCooldown)
																spell2.SetFloat("delay", gameTime + globalCooldown);
														}
													}
													delete snap;
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
					if(IsPlayerAlive(i) && GetClientTeam(i) == team)
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
				if(MenuTimer[attacker] && !SetupMode[attacker])
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

void AddManaEvent(int client, const char[] event, float multi = 1.0)
{
	if(MenuTimer[client] && !SetupMode[client])
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
