/*
	void Events_PluginStart()
	void Events_RoundSetup()
	void Events_CheckAlivePlayers(int exclude = 0, bool alive = true, bool resetMax = false)
*/

#pragma semicolon 1

static bool FirstBlood;
static bool LastMann;
static Handle YourHud;
static Handle TopHud;

void Events_PluginStart()
{
	YourHud = CreateHudSynchronizer();
	TopHud = CreateHudSynchronizer();
	
	HookEvent("arena_round_start", Events_RoundStart, EventHookMode_Pre);
	HookEvent("arena_win_panel", Events_WinPanel, EventHookMode_Pre);
	HookEvent("object_deflected", Events_ObjectDeflected, EventHookMode_Post);
	HookEvent("player_spawn", Events_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_healed", Events_PlayerHealed, EventHookMode_Post);
	HookEvent("player_hurt", Events_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Events_PlayerDeath, EventHookMode_Post);
	HookEvent("player_team", Events_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("post_inventory_application", Events_InventoryApplication, EventHookMode_Pre);
	HookEvent("rps_taunt_event", Events_RPSTaunt, EventHookMode_Post);
	HookEvent("teamplay_broadcast_audio", Events_BroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_round_win", Events_RoundEnd, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", Events_RoundStart, EventHookMode_Post);
}

void Events_RoundSetup()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			ClearSyncHud(client, YourHud);
			ClearSyncHud(client, TopHud);
		}
	}
}

void Events_CheckAlivePlayers(int exclude = 0, bool alive = true, bool resetMax = false)
{
	for(int i; i < TFTeam_MAX; i++)
	{
		PlayersAlive[i] = 0;
	}
	
	bool spec = CvarSpecTeam.BoolValue;
	int redBoss, bluBoss;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != exclude && IsClientInGame(i) && !Client(i).Minion)
		{
			int team = GetClientTeam(i);
			if((spec || team > TFTeam_Spectator) && ((!alive && team > TFTeam_Spectator) || IsPlayerAlive(i)))
			{
				PlayersAlive[team]++;
				if(team == TFTeam_Blue && !bluBoss && Client(i).IsBoss && Client(i).Cfg.GetSection("sound_lastman"))
				{
					bluBoss = i;
				}
				else if(team != TFTeam_Blue && !redBoss && Client(i).IsBoss && Client(i).Cfg.GetSection("sound_lastman"))
				{
					redBoss = i;
				}
			}
		}
	}
	
	for(int i; i < TFTeam_MAX; i++)
	{
		if(resetMax || MaxPlayersAlive[i] < PlayersAlive[i])
			MaxPlayersAlive[i] = PlayersAlive[i];
	}
	
	Action action = Forward_OnAliveChange();
	if(action == Plugin_Stop)
		return;
	
	int team = Bosses_GetBossTeam();
	ForwardOld_OnAlivePlayersChanged(PlayersAlive[team == 3 ? 2 : 3], PlayersAlive[team == 3 ? 3 : 2]);
	if(action == Plugin_Handled)
		return;
	
	int total = TotalPlayersAlive();
	if(alive && RoundStatus == 1 && !LastMann && total == 2)
	{
		LastMann = true;
		
		bool found;
		for(int i = CvarSpecTeam.BoolValue ? 0 : 2; i < sizeof(PlayersAlive); i++)
		{
			if(PlayersAlive[i])
			{
				if(found)
				{
					int reds, blus;
					int[] red = new int[MaxClients];
					int[] blu = new int[MaxClients];
					for(int client = 1; client <= MaxClients; client++)
					{
						if(IsClientInGame(client))
						{
							if(!IsPlayerAlive(client) || !Client(client).IsBoss || !Bosses_PlaySoundToClient(client, client, "sound_lastman", _, client, SNDCHAN_AUTO, _, _, 2.0))
							{
								if((redBoss && (!bluBoss && GetClientTeam(client) == 3)) || (redBoss == client && !bluBoss))
								{
									red[reds++] = client;
								}
								else if(bluBoss)
								{
									blu[blus++] = client;
								}
							}
						}
					}
					
					if(reds)
						Bosses_PlaySound(redBoss, red, reds, "sound_lastman", _, _, _, _, _, 2.0);
					
					if(blus)
						Bosses_PlaySound(bluBoss, blu, blus, "sound_lastman", _, _, _, _, _, 2.0);
					
					break;
				}
				
				found = true;
			}
		}
	}
	
	if(Enabled && RoundStatus == 1)
		Gamemode_CheckPointUnlock(total, !LastMann);
}

public void Events_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	FirstBlood = true;
	LastMann = false;
	Gamemode_RoundStart();
}

public void Events_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundEnd(event.GetInt("team"));
}

public Action Events_BroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		char sound[64];
		event.GetString("sound", sound, sizeof(sound));
		if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.AM_RoundStartRandom", false))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Events_ObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("weaponid") || !Client(GetClientOfUserId(event.GetInt("ownerid"))).IsBoss)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			// Airblast gets slower the more times it hits
			Address address = TF2Attrib_GetByDefIndex(weapon, 256);
			if(address == Address_Null)
			{
				TF2Attrib_SetByDefIndex(weapon, 256, 1.0);
				SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			}
			else
			{
				TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) + 0.25);
				TF2Attrib_SetByDefIndex(weapon, 403, view_as<float>(222153573));	// Update attribute
			}
		}
	}
	return Plugin_Continue;
}

public void Events_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Events_CheckAlivePlayers();
}

public Action Events_InventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
	{
		if(Client(client).IsBoss)
		{
			Bosses_Equip(client);
		}
		else if(Enabled && !Client(client).Minion)
		{
			// Because minion plugins don't swap em back
			SetVariantString("");
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
			
			if(RoundStatus == 0 && GetClientMenu(client) == MenuSource_None)
				Weapons_ChangeMenu(client, CvarPreroundTime.IntValue);
		}
	}
	return Plugin_Continue;
}

public void Events_PlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	if(CvarRefreshDmg.BoolValue)
	{
		int client = GetClientOfUserId(event.GetInt("patient"));
		if(Client(client).IsBoss)
			Gamemode_UpdateHUD(GetClientTeam(client), true);
	}
}

public Action Events_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	bool changed;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(Client(victim).IsBoss)
	{
		int damage = event.GetInt("damageamount");
		
		float multi = 100.0;
		int weapon = event.GetInt("weaponid");
		if(weapon != -1)
			multi *= Weapons_PlayerHurt(weapon);
		
		float rage = Client(victim).GetCharge(0) + (damage * multi / Client(victim).RageDamage);
		float maxrage = Client(victim).RageMax;
		if(rage > maxrage)
			rage = maxrage;
		
		Client(victim).SetCharge(0, rage);
		
		if(event.GetBool("minicrit") && event.GetBool("allseecrit"))
		{
			event.SetBool("allseecrit", false);
			changed = true;
		}
		
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int team = GetClientTeam(victim);
		int health = GetClientHealth(victim);
		if(health < 1)
		{
			int maxhealth = Client(victim).MaxHealth;
			int maxlives = Client(victim).MaxLives;
			int lives = Client(victim).Lives;
			while(lives > 1)
			{
				switch(ForwardOld_OnLoseLife(victim, lives, maxlives))
				{
					case Plugin_Changed:
					{
						if(lives > maxlives)
							maxlives = lives;
					}
					case Plugin_Handled, Plugin_Stop:
					{
						return Plugin_Handled;
					}
				}
				
				Bosses_UseSlot(victim, -1, -1);
				
				lives--;
				if(Client(attacker).IsBoss)	// In Boss vs Boss, don't penerate lives
				{
					event.SetInt("damageamount", event.GetInt("damageamount")+health);
					changed = true;
					
					health = maxhealth;
				}
				else
				{
					health += maxhealth;
				}
				
				if(health > 0)
				{
					SetEntityHealth(victim, health);
					
					char buffer[64];
					
					int bosses, mercs;
					int[] boss = new int[MaxClients];
					int[] merc = new int[MaxClients];
					
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i))
						{
							if(Client(i).IsBoss)
							{
								boss[bosses++] = i;
							}
							else
							{
								merc[mercs++] = i;
								
								Bosses_GetBossNameCfg(Client(victim).Cfg, buffer, sizeof(buffer), GetClientLanguage(victim));
								if(lives == 1)
								{
									ShowGameText(i, "ico_notify_flag_moving_alt", team, "%t", "Lost Life", buffer);
								}
								else
								{
									ShowGameText(i, "ico_notify_flag_moving_alt", team, "%t", "Lost Lives", buffer, lives);
								}
							}	
						}
					}
					
					IntToString(lives, buffer, sizeof(buffer));
					if(Bosses_PlaySound(victim, merc, mercs, "sound_lifeloss", buffer, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					{
						Bosses_PlaySound(victim, boss, bosses, "sound_lifeloss", buffer, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					else if(lives == 1 && Bosses_PlaySound(victim, merc, mercs, "sound_last_life", _, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					{
						Bosses_PlaySound(victim, boss, bosses, "sound_last_life", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					else if(Bosses_PlaySound(victim, merc, mercs, "sound_nextlife", _, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					{
						Bosses_PlaySound(victim, boss, bosses, "sound_nextlife", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					break;
				}
			}
			
			Client(victim).Lives = lives;
			Client(victim).MaxLives = maxlives;
		}
		
		if(CvarRefreshDmg.BoolValue)
			Gamemode_UpdateHUD(team);
	}
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void Events_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || RoundStatus == 1)
	{
		int userid = event.GetInt("userid");
		int victim = GetClientOfUserId(userid);
		if(victim)
		{
			int bosses, mercs;
			while(TF2_GetItem(victim, bosses, mercs))
			{
				if(!GetEntProp(bosses, Prop_Send, "m_iAccountID"))
					TF2_RemoveItem(victim, bosses);
			}
			
			bool deadRinger = view_as<bool>(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER);
			if(!deadRinger)
				Events_CheckAlivePlayers(victim);
			
			if(Client(victim).IsBoss)
			{
				bosses = mercs = 0;
				int[] boss = new int[MaxClients];
				int[] merc = new int[MaxClients];
				
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(Client(i).IsBoss || deadRinger)
						{
							boss[bosses++] = i;
						}
						else
						{
							merc[mercs++] = i;
						}
					}
				}
				
				if(Bosses_PlaySound(victim, merc, mercs, "sound_death", _, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					Bosses_PlaySound(victim, boss, bosses, "sound_death", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
				
				if(!deadRinger)
					Gamemode_UpdateHUD(GetClientTeam(victim));
			}
			
			int alive = TotalPlayersAlive();
			
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(attacker)
			{
				if(Client(attacker).IsBoss)
				{
					float engineTime = GetEngineTime();
					
					if(alive > 2)
					{
						if(!FirstBlood || !Bosses_PlaySoundToAll(attacker, "sound_first_blood", _, attacker, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
						{
							int spree = 1;
							if(Client(attacker).LastKillTime > engineTime - 5.0)
								spree += Client(attacker).KillSpree;
							
							Client(attacker).KillSpree = spree;
							if(spree != 3 || !Bosses_PlaySoundToAll(attacker, "sound_kspree", _, attacker, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
							{
								bool played;
								if(GetURandomInt() % 2)
								{
									TFClassType class = Client(victim).IsBoss ? TFClass_Unknown : TF2_GetPlayerClass(victim);
									if(deadRinger && TF2_IsPlayerInCondition(victim, TFCond_Disguised) && GetClientTeam(attacker) == GetEntProp(victim, Prop_Send, "m_nDisguiseTeam"))
									{
										int target = GetEntProp(victim, Prop_Send, "m_iDisguiseTargetIndex");
										if(target > 0 && target <= MaxClients && target != attacker)
										{
											if(Client(target).IsBoss)
											{
												class = TFClass_Unknown;
											}
											else
											{
												class = view_as<TFClassType>(GetEntProp(victim, Prop_Send, "m_nDisguiseClass"));
											}
										}
									}
									
									static const char classnames[][] = {"custom", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
									if(class >= sizeof(classnames))
										class = TFClass_Unknown;
									
									char buffer[20];
									FormatEx(buffer, sizeof(buffer), "sound_kill_%s", classnames[class]);
									played = Bosses_PlaySoundToAll(attacker, buffer, _, attacker, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
									if(!played)
										played = Bosses_PlaySoundToAll(attacker, "sound_kill", classnames[class], attacker, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
								}
								
								if(!played && !Bosses_PlaySoundToAll(attacker, "sound_hit", _, attacker, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
									Bosses_PlaySoundToAll(attacker, "sound_kill", "0", attacker, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
							}
						}
					}
					
					Client(attacker).LastKillTime = engineTime;
				}
				
				FirstBlood = false;
			}
			
			if(!deadRinger)
			{
				if(Client(victim).IsBoss)
				{
					Bosses_UseSlot(victim, 5, 5);
					
					if(!Enabled)
						CreateTimer(0.1, Events_RemoveBossTimer, userid, TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(Enabled)
				{
					int entity = MaxClients + 1;
					while((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1)
					{
						if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == victim && !GetEntProp(entity, Prop_Send, "m_bMiniBuilding"))
						{
							FakeClientCommand(victim, "destroy 2");
							AcceptEntityInput(entity, "kill");
						}
					}
				}
				
				Client(victim).ResetByDeath();
			}
		}
	}
}

public Action Events_RemoveBossTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && !IsPlayerAlive(client))
		Bosses_Remove(client);
	
	return Plugin_Continue;
}

public Action Events_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		int team = -2;
		int[] clients = new int[MaxClients];
		int total;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				clients[total++] = client;
				
				if(Client(client).IsBoss)
				{
					int current = GetClientTeam(client);
					if(team == -2)
					{
						team = current;
					}
					else if(current != team)
					{
						team = -1;
					}
				}
			}
		}
		
		char top[3][64] = { "---", "---", "---" };
		int dmg[3];
		if(team > -1)
		{
			for(int i; i < total; i++)
			{
				if(!Client(clients[i]).IsBoss)
				{
					int damage = Client(clients[i]).TotalDamage + Client(clients[i]).Healing + Client(clients[i]).TotalAssist;
					if(damage > dmg[0])
					{
						top[2] = top[1];
						dmg[2] = dmg[1];
						top[1] = top[0];
						dmg[1] = dmg[0];
						
						GetClientName(clients[i], top[0], sizeof(top[]));
						dmg[0] = damage;
					}
					else if(damage > dmg[1])
					{
						top[2] = top[1];
						dmg[2] = dmg[1];
						
						GetClientName(clients[i], top[1], sizeof(top[]));
						dmg[1] = damage;
					}
					else if(damage > dmg[2])
					{
						GetClientName(clients[i], top[2], sizeof(top[]));
						dmg[2] = damage;
					}
				}
			}
		}
		
		for(int i; i < total; i++)
		{
			if(!Client(clients[i]).NoHud)
			{
				if(team > -1)
				{
					SetHudTextParamsEx(0.38, 0.7, 15.0, {255, 255, 255, 255}, TeamColors[GetClientTeam(clients[i])], 2, 0.1, 0.1);
					ShowSyncHudText(clients[i], TopHud, "%T", "Top Damage Hud", clients[i], top[0], dmg[0], top[1], dmg[1], top[2], dmg[2]);
				}
				
				if(team == -1 || !Client(clients[i]).IsBoss)
				{
					SetHudTextParamsEx(-1.0, 0.5, 15.0, {255, 255, 255, 255}, TeamColors[GetClientTeam(clients[i])], 2, 0.1, 0.1);
					ShowSyncHudText(clients[i], YourHud, "%T", "You Dealt Damage Hud", clients[i], Client(clients[i]).TotalDamage, Client(clients[i]).Healing, Client(clients[i]).TotalAssist);
				}
			}
		}
		
		if(team > -1)
			event.BroadcastDisabled = true;
		
		int score = event.GetInt("blue_score_prev");
		if(score > event.GetInt("blue_score"))
			event.SetInt("blue_score", score);
		
		score = event.GetInt("red_score_prev");
		if(score > event.GetInt("red_score"))
			event.SetInt("red_score", score);
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void Events_RPSTaunt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = event.GetInt("loser");
	if(Client(victim).IsBoss)
	{
		int attacker = event.GetInt("winner");
		if(GetClientTeam(victim) != GetClientTeam(attacker))
		{
			Client(victim).RPSHit = attacker;
			if(Client(victim).MaxLives > 1)
			{
				Client(victim).RPSDamage = GetClientHealth(victim);
			}
			else if(!Client(victim).RPSDamage)
			{
				int damage = Client(victim).Health / 2;
				if(damage < 999)
					damage = 999;
				
				Client(victim).RPSDamage = damage;
			}
		}
	}
	else if(Client(victim).Queue > 0)
	{
		int attacker = event.GetInt("winner");
		if(GetClientTeam(victim) == GetClientTeam(attacker))
		{
			int queue = 5;
			if(Client(victim).Queue < queue)
				queue = Client(victim).Queue;
			
			Client(victim).Queue -= queue;
			Client(attacker).Queue += queue;
		}
	}
}