/*
	void Gamemode_MapStart()
	void Gamemode_RoundSetup()
	void Gamemode_RoundStart()
	void Gamemode_RoundEnd()
*/

static bool Waiting;
static Handle SyncHud[TFTeam_MAX];
static bool HasBoss[TFTeam_MAX];

void Gamemode_PluginStart()
{
	for(int i; i<TFTeam_MAX; i++)
	{
		SyncHud[i] = CreateHudSynchronizer();
	}
}

void Gamemode_MapStart()
{
	//TODO: If a round as been played before, Waiting for Players will never end - Late loading without players on breaks FF2 currently
	Waiting = true;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Waiting = false;
			break;
		}
	}
}

void Gamemode_RoundSetup()
{
	Debug("Gamemode_RoundSetup %d", Waiting ? 1 : 0);
	
	RoundActive = false;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			Client(client).ResetByRound();
			Bosses_Remove(client);
		}
	}
	
	if(Enabled)
	{
		if(Waiting)
		{
			CvarTournament.BoolValue = true;
			CvarMovementFreeze.BoolValue = false;
			ServerCommand("mp_waitingforplayers_restart 1");
			Debug("mp_waitingforplayers_restart 1");
		}
		else if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
		{
			CreateTimer(CvarPreroundTime.FloatValue / 2.857143, Gamemode_IntroTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			
			int bosses = CvarBossVsBoss.IntValue;
			if(bosses > 0)	// Boss vs Boss
			{
				int reds;
				int[] red = new int[MaxClients];
				for(int client=1; client<=MaxClients; client++)
				{
					if(IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
						red[reds++] = client;
				}
					
				if(reds)
				{
					SortIntegers(red, reds, Sort_Random);
					
					int team = TFTeam_Red + (GetTime() % 2);
					for(int i; i<reds; i++)
					{
						ChangeClientTeam(red[i], team);
						team = team == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
					}
					
					reds = GetBossQueue(red, MaxClients, TFTeam_Red);
					
					int[] blu = new int[MaxClients];
					int blus = GetBossQueue(blu, MaxClients, TFTeam_Blue);
					
					for(int i; i<bosses && i<blus; i++)
					{
						if(!Client(blu[i]).IsBoss)
						{
							Bosses_Create(blu[i], Preference_PickBoss(blu[i], TFTeam_Blue), TFTeam_Blue);
							Client(blu[i]).Queue = 0;
						}
					}
					
					for(int i; i<bosses && i<reds; i++)
					{
						if(!Client(red[i]).IsBoss)
						{
							Bosses_Create(red[i], Preference_PickBoss(red[i], TFTeam_Red), TFTeam_Red);
							Client(red[i]).Queue = 0;
						}
					}
				}
			}
			else	// Standard FF2
			{
				int[] boss = new int[1];
				if(GetBossQueue(boss, 1))
				{
					int team;
					int special = Preference_PickBoss(boss[0]);
					ConfigMap cfg;
					if((cfg=Bosses_GetConfig(special)))
					{
						cfg.GetInt("bossteam", team);
						switch(team)
						{
							case TFTeam_Spectator:
							{
								team = TFTeam_Red + (GetTime() % 2);
							}
							case TFTeam_Red, TFTeam_Blue:
							{
								
							}
							default:
							{
								team = TFTeam_Blue;
							}
						}
						
						Bosses_Create(boss[0], special, team);
						Client(boss[0]).Queue = 0;
					}
					else
					{
						char buffer[64];
						Bosses_GetCharset(Charset, buffer, sizeof(buffer));
						LogError("[!!!] Failed to find a valid boss in %s (#%d)", buffer, Charset);
					}
					
					int count;
					int[] players = new int[MaxClients];
					for(int client=1; client<=MaxClients; client++)
					{
						if(!Client(client).IsBoss && IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
							players[count++] = client;
					}
					
					team = team == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
					for(int i; i<count; i++)
					{
						ChangeClientTeam(players[i], team);
					}
				}
				else	// No boss, normal Arena time
				{
					int count;
					int[] players = new int[MaxClients];
					for(int client=1; client<=MaxClients; client++)
					{
						if(IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
							players[count++] = client;
					}
					
					if(count)
					{
						SortIntegers(players, count, Sort_Random);
						
						int team = TFTeam_Red + (GetTime() % 2);
						for(int i; i<count; i++)
						{
							ChangeClientTeam(players[i], team);
							team = team == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
						}
					}
				}
			}
		}
	}
}

public void TF2_OnWaitingForPlayersStart()
{
	Debug("TF2_OnWaitingForPlayersStart");
	if(GameRules_GetProp("m_bInWaitingForPlayers", 1) && Enabled)
	{
		Waiting = false;
		CvarTournament.BoolValue = false;
		CreateTimer(4.0, Gamemode_TimerRespawn, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public void TF2_OnWaitingForPlayersEnd()
{
	Debug("TF2_OnWaitingForPlayersEnd");
	if(Enabled)
		CvarMovementFreeze.BoolValue = true;
}

public Action Gamemode_TimerRespawn(Handle timer)
{
	if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
		return Plugin_Stop;

	GameRules_SetProp("m_bInWaitingForPlayers", false, 1);
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1 && GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))
			TF2_RespawnPlayer(client);
	}
	GameRules_SetProp("m_bInWaitingForPlayers", true, 1);
	return Plugin_Continue;
}

public Action Gamemode_IntroTimer(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(!Client(client).IsBoss || !ForwardOld_OnMusicPerBoss(client) || !Bosses_PlaySoundToClient(client, client, "sound_begin"))
			{
				int team = GetClientTeam(client);
				for(int i; i<MaxClients; i++)
				{
					int boss = FindClientOfBossIndex(i);
					if(boss != -1 && GetClientTeam(boss) != team && Bosses_PlaySoundToClient(boss, client, "sound_begin"))
						break;
				}
			}
		}
	}
	return Plugin_Continue;
}

void Gamemode_RoundStart()
{
	if(Enabled && !GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		RoundActive = true;
		
		Events_CheckAlivePlayers();
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(!Client(client).IsBoss)
				{
					TF2_RegeneratePlayer(client);
					
					int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_flChargeLevel"))
						SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", 0.0);
				}
			}
		}
		
		bool specTeam = CvarSpecTeam.BoolValue;
		for(int client=1; client<=MaxClients; client++)
		{
			if(Client(client).IsBoss && IsClientInGame(client))
			{
				int team = GetClientTeam(client);
				int amount = 0;
				for(int i = specTeam ? TFTeam_Unassigned : TFTeam_Spectator; i<TFTeam_MAX; i++)
				{
					if(team != i)
						amount += PlayersAlive[i];
				}
				Bosses_SetHealth(client, amount);
			}
		}
		
		Music_RoundStart();
	}
}

void Gamemode_RoundEnd()
{
	RoundActive = false;
	
	int[] clients = new int[MaxClients];
	int total;
	
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
			clients[total++] = client;
	}
	
	Music_PlaySong(clients, total);
	
	for(int i; i<TFTeam_MAX; i++)
	{
		if(HasBoss[i])
		{
			HasBoss[i] = false;
			
			for(int a; a<total; a++)
			{
				ClearSyncHud(clients[a], SyncHud[i]);
			}
		}
	}
}

void Gamemode_UpdateHUD(int team)
{
	if(RoundActive)
	{
		int count;
		if(HasBoss[team])
		{
			for(int i; i<TFTeam_MAX; i++)
			{
				if(HasBoss[i])
					count++;
			}
		}
		else
		{
			count++;
			for(int i; i<TFTeam_MAX; i++)
			{
				if(HasBoss[i])
				{
					count++;
					Gamemode_UpdateHUD(i);
				}
			}
			
			HasBoss[team] = true;
		}
		
		int[] clients = new int[MaxClients];
		int total;
		
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client))
				clients[total++] = client;
		}
		
		int health, lives, maxhealth, maxlives, combined, bosses;
		for(int i; i<total; i++)
		{
			if(Client(clients[i]).IsBoss && GetClientTeam(clients[i]) == team)
			{
				bosses++;
				health += GetClientHealth(clients[i]);
				lives += Client(clients[i]).Lives;
				maxhealth += Client(clients[i]).MaxHealth;
				maxlives += Client(clients[i]).MaxLives;
				combined += Client(clients[i]).Health;
			}
		}
		
		if(count > 1)
		{
			float x = (team == TFTeam_Red || team == TFTeam_Spectator) ? 0.53 : 0.43;
			float y = team <= TFTeam_Spectator ? 0.18 : 0.12;
			int r = (team == TFTeam_Unassigned || team == TFTeam_Red) ? 255 : 100;
			int g = team <= TFTeam_Spectator ? 255 : 100;
			int b = team == TFTeam_Blue ? 255 : 100;
			for(int i; i<total; i++)
			{
				if(IsClientObserver(clients[i]))
				{
					SetHudTextParams(x, y+0.1, 45.0, r, g, b, 255, 0, 0.35, 0.0, 30.0);
				}
				else
				{
					SetHudTextParams(x, y, 45.0, r, g, b, 255, 0, 0.35, 0.0, 30.0);
				}
				
				if(bosses > 1)
				{
					ShowSyncHudText(clients[i], SyncHud[team], "%d", combined);
				}
				else if(lives > 1)
				{
					ShowSyncHudText(clients[i], SyncHud[team], "%d (x%d)", health, lives);
				}
				else
				{
					ShowSyncHudText(clients[i], SyncHud[team], "%d", health);
				}
			}
		}
		else
		{
			for(int i; i<total; i++)
			{
				if(IsClientObserver(clients[i]))
				{
					SetHudTextParams(-1.0, 0.22, 45.0, 200, 255, 200, 255, 0, 0.35, 0.0, 30.0);
				}
				else
				{
					SetHudTextParams(-1.0, 0.12, 45.0, 200, 255, 200, 255, 0, 0.35, 0.0, 30.0);
				}
				
				if(bosses > 1)
				{
					ShowSyncHudText(clients[i], SyncHud[team], "%d / %d", combined, maxhealth * maxlives);
				}
				else if(lives > 1)
				{
					ShowSyncHudText(clients[i], SyncHud[team], "%d / %d (x%d)", health, maxhealth, lives);
				}
				else
				{
					ShowSyncHudText(clients[i], SyncHud[team], "%d / %d", health, maxhealth);
				}
			}
		}
	}
}