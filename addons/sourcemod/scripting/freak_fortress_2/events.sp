/*
	void Events_PluginStart()
*/

static bool FirstBlood;
static bool LastMann;

void Events_PluginStart()
{
	HookEvent("arena_round_start", Events_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Events_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Events_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("post_inventory_application", Events_InventoryApplication, EventHookMode_Pre);
	HookEvent("player_hurt", Events_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Events_PlayerDeath, EventHookMode_Post);
}

public void Events_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	FirstBlood = true;
	LastMann = false;
	Events_CheckAlivePlayers();
	Gamemode_RoundStart();
}

public void Events_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundEnd();
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
			Bosses_Equip(client);
	}
	return Plugin_Continue;
}

public Action Events_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	bool changed;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(Client(victim).IsBoss)
	{
		int damage = event.GetInt("damageamount");
		PrintToChat(victim, "%d", damage);
		
		float rage = Client(victim).GetCharge(0) + (damage * 100.0 / Client(victim).RageDamage);
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
					char buffer[64];
					
					int bosses, mercs;
					int[] boss = new int[MaxClients];
					int[] merc = new int[MaxClients];
					
					int team = GetClientTeam(victim);
					for(int i=1; i<=MaxClients; i++)
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
						Bosses_PlaySound(victim, boss, bosses, "sound_lifeloss", buffer, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					else if(lives == 1 && Bosses_PlaySound(victim, merc, mercs, "sound_last_life", _, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					{
						Bosses_PlaySound(victim, boss, bosses, "sound_last_life", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					else if(Bosses_PlaySound(victim, merc, mercs, "sound_nextlife", _, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					{
						Bosses_PlaySound(victim, boss, bosses, "sound_nextlife", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					break;
				}
			}
			
			Client(victim).Lives = lives;
		}
	}
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void Events_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || RoundActive)
	{
		int userid = event.GetInt("userid");
		int victim = GetClientOfUserId(userid);
		if(victim)
		{	
			int bosses, mercs;
			int[] boss = new int[MaxClients];
			int[] merc = new int[MaxClients];
			
			bool deadRinger = view_as<bool>(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER);
			for(int i=1; i<=MaxClients; i++)
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
			
			if(!deadRinger)
				Events_CheckAlivePlayers(victim);
			
			if(Client(victim).IsBoss)
			{
				if(Bosses_PlaySound(victim, merc, mercs, "sound_death", _, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
					Bosses_PlaySound(victim, boss, bosses, "sound_death", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
			}
			
			int alive = TotalPlayersAlive();
			
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(attacker)
			{
				if(Client(attacker).IsBoss)
				{
					if(alive > 2)
					{
						if(!FirstBlood || !Bosses_PlaySoundToAll(victim, "sound_first_blood", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0))
						{
							
						}
					}
				}
				
				FirstBlood = false;
			}
			
			if(!deadRinger)
			{
				if(Client(victim).IsBoss)
				{
					Bosses_UseSlot(victim, 5, 5);
					
					if(!Enabled)
						RequestFrame(Events_RemoveBossFrame, userid);
				}
				
				if(Enabled || Client(victim).IsBoss)
				{
					int entity = MaxClients + 1;
					while((entity=FindEntityByClassname(entity, "obj_sentrygun")) != -1)
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

public void Events_RemoveBossFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
		Bosses_Remove(client);
}

void Events_CheckAlivePlayers(int exclude=0)
{
	PlayersAlive[0] = 0;
	PlayersAlive[1] = 0;
	PlayersAlive[2] = 0;
	PlayersAlive[3] = 0;
	
	int redBoss, bluBoss;
	for(int i=1; i<=MaxClients; i++)
	{
		if(i != exclude && IsClientInGame(i) && IsPlayerAlive(i) && !Client(i).Minion)
		{
			int team = GetClientTeam(i);
			PlayersAlive[team]++;
			if(team == 3 && !bluBoss && Client(i).IsBoss && Client(i).Cfg.GetSection("sound_lastman"))
			{
				bluBoss = i;
			}
			else if(team != 3 && !redBoss && Client(i).IsBoss && Client(i).Cfg.GetSection("sound_lastman"))
			{
				redBoss = i;
			}
		}
	}
	
	int team = Bosses_GetBossTeam();
	ForwardOld_OnAlivePlayersChanged(PlayersAlive[team==3 ? 2 : 3], PlayersAlive[team==3 ? 3 : 2]);
	
	if(!LastMann && TotalPlayersAlive() == 2)
	{
		LastMann = true;
		
		int reds, blus;
		int[] red = new int[MaxClients];
		int[] blu = new int[MaxClients];
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				if(!IsPlayerAlive(client) || !Client(client).IsBoss || !Bosses_PlaySoundToClient(client, client, "sound_lastman", _, client, SNDCHAN_VOICE, _, _, 2.0))
				{
					if(redBoss && (!bluBoss && GetClientTeam(client) == 3))
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
	}
}