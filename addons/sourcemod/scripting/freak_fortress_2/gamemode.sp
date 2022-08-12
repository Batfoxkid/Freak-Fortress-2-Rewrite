/*
	void Gamemode_PluginStart()
	void Gamemode_MapStart()
	void Gamemode_RoundSetup()
	void Gamemode_RoundStart()
	void Gamemode_CheckPointUnlock(int alive, bool notice)
	void Gamemode_OverrideWinner(int team = -1)
	void Gamemode_RoundEnd(int winteam)
	void Gamemode_UpdateHUD(int team, bool healing = false, bool nobar = false)
	void Gamemode_SetClientGlow(int client, float duration)void Gamemode_SetClientGlow(int client, float duration)
	void Gamemode_PlayerRunCmd(int client)
	void Gamemode_ConditionAdded(int client, TFCond cond)
	void Gamemode_ConditionRemoved(int client, TFCond cond)
*/

#pragma semicolon 1

static bool Waiting;
static float HealingFor;
static int WinnerOverride;
static int PointUnlock;
static Handle SelfSyncHud;
static Handle TeamSyncHud[TFTeam_MAX];
static Handle HudTimer[TFTeam_MAX];
static bool HasBoss[TFTeam_MAX];

void Gamemode_PluginStart()
{
	SelfSyncHud = CreateHudSynchronizer();
	
	for(int i; i < TFTeam_MAX; i++)
	{
		TeamSyncHud[i] = CreateHudSynchronizer();
	}
}

void Gamemode_MapStart()
{
	//TODO: If a round as been played before, Waiting for Players will never end - Late loading without players on breaks FF2 currently
	Waiting = true;
	for(int i = 1; i <= MaxClients; i++)
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
	HealingFor = 0.0;
	RoundStatus = 0;
	WinnerOverride = -1;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			Client(client).ResetByRound();
			if(GetClientTeam(client) > TFTeam_Spectator)
				Bosses_Remove(client);
			
			for(int i; i < TFTeam_MAX; i++)
			{
				ClearSyncHud(client, TeamSyncHud[i]);
			}
		}
	}
	
	Events_RoundSetup();
	
	if(Enabled)
	{
		if(Waiting)
		{
			CvarTournament.BoolValue = true;
			CvarMovementFreeze.BoolValue = false;
			ServerCommand("mp_waitingforplayers_restart 1");
		}
		else if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
		{
			Goomba_RoundSetup();
			
			float preround = CvarPreroundTime.FloatValue;
			CreateTimer(preround / 2.857143, Gamemode_IntroTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(preround - 0.1, Gamemode_SetControlPoint, _, TIMER_FLAG_NO_MAPCHANGE);
			
			int bosses = CvarBossVsBoss.IntValue;
			if(bosses > 0)	// Boss vs Boss
			{
				int reds;
				int[] red = new int[MaxClients];
				for(int client = 1; client <= MaxClients; client++)
				{
					if(IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
						red[reds++] = client;
				}
					
				if(reds)
				{
					SortIntegers(red, reds, Sort_Random);
					
					int team = TFTeam_Red + (GetTime() % 2);
					for(int i; i < reds; i++)
					{
						ChangeClientTeam(red[i], team);
						team = team == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
					}
					
					reds = Preference_GetBossQueue(red, MaxClients, false, TFTeam_Red);
					
					int[] blu = new int[MaxClients];
					int blus = Preference_GetBossQueue(blu, MaxClients, false, TFTeam_Blue);
					
					for(int i; i < bosses && i < blus; i++)
					{
						if(!Client(blu[i]).IsBoss)
						{
							Bosses_CreateFromSpecial(blu[i], Preference_PickBoss(blu[i], TFTeam_Blue), TFTeam_Blue);
							Client(blu[i]).Queue = 0;
						}
					}
					
					for(int i; i < bosses && i < reds; i++)
					{
						if(!Client(red[i]).IsBoss)
						{
							Bosses_CreateFromSpecial(red[i], Preference_PickBoss(red[i], TFTeam_Red), TFTeam_Red);
							Client(red[i]).Queue = 0;
						}
					}
				}
			}
			else	// Standard FF2
			{
				int boss[1];
				if(Preference_GetBossQueue(boss, 1, false))
				{
					int team;
					int special = Preference_PickBoss(boss[0]);
					ConfigMap cfg;
					if((cfg = Bosses_GetConfig(special)))
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
						
						Bosses_CreateFromSpecial(boss[0], special, team);
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
					for(int client = 1; client <= MaxClients; client++)
					{
						if(!Client(client).IsBoss && IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
							players[count++] = client;
					}
					
					team = team == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
					for(int i; i < count; i++)
					{
						ChangeClientTeam(players[i], team);
					}
				}
				else	// No boss, normal Arena time
				{
					int count;
					int[] players = new int[MaxClients];
					for(int client = 1; client <= MaxClients; client++)
					{
						if(IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
							players[count++] = client;
					}
					
					if(count)
					{
						SortIntegers(players, count, Sort_Random);
						
						int team = TFTeam_Red + (GetTime() % 2);
						for(int i; i < count; i++)
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
	if(Enabled && GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		Waiting = false;
		CvarTournament.BoolValue = false;
		CreateTimer(4.0, Gamemode_TimerRespawn, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public void TF2_OnWaitingForPlayersEnd()
{
	if(Enabled)
		CvarMovementFreeze.BoolValue = true;
}

public Action Gamemode_TimerRespawn(Handle timer)
{
	if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
		return Plugin_Stop;

	GameRules_SetProp("m_bInWaitingForPlayers", false, 1);
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1 && GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))
			TF2_RespawnPlayer(client);
	}
	GameRules_SetProp("m_bInWaitingForPlayers", true, 1);
	return Plugin_Continue;
}

public Action Gamemode_IntroTimer(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(!Client(client).IsBoss || !ForwardOld_OnMusicPerBoss(client) || !Bosses_PlaySoundToClient(client, client, "sound_begin", _, _, _, _, _, 2.0))
			{
				int team = GetClientTeam(client);
				int i;
				for(; i < MaxClients; i++)
				{
					int boss = FindClientOfBossIndex(i);
					if(boss != -1 && GetClientTeam(boss) != team && Bosses_PlaySoundToClient(boss, client, "sound_begin", _, _, _, _, _, 2.0))
						break;
				}
				
				if(i == MaxClients)
				{
					int boss = FindClientOfBossIndex(0);
					if(boss != -1)
						Bosses_PlaySoundToClient(boss, client, "sound_begin", _, _, _, _, _, 2.0);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Gamemode_SetControlPoint(Handle timer)
{
	Events_CheckAlivePlayers();
	
	PointUnlock = 0;
	int players = TotalPlayersAlive();
	
	float time;
	bool found;
	for(int i; i < MaxClients; i++)
	{
		int client = FindClientOfBossIndex(i);
		if(client != -1)
		{
			if(Client(client).Cfg.GetFloat("pointtime", time))
			{
				found = true;
				
				int delay;
				if(Client(client).Cfg.GetInt("pointdelay", delay))
					time = float(delay * players) + time;
			}
			
			if(Client(client).Cfg.GetInt("pointalive", PointUnlock))
				found = true;
				
			if(found)
				break;
		}
	}
		
	if(!found)
	{
		char buffer[256];
		CvarCaptureTime.GetString(buffer, sizeof(buffer));
		time = ParseFormula(buffer, players);
		
		CvarCaptureAlive.GetString(buffer, sizeof(buffer));
		PointUnlock = RoundToCeil(ParseFormula(buffer, players));
	}
	
	if(time > 0.001)
	{
		SetArenaCapEnableTime(time);
	}
	else if(time > -0.001)
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

void Gamemode_RoundStart()
{
	RoundStatus = 1;
	
	Events_CheckAlivePlayers(_, _, true);
	
	bool enabled = (Enabled && !GameRules_GetProp("m_bInWaitingForPlayers", 1));
	
	int[] merc = new int[MaxClients];
	int[] boss = new int[MaxClients];
	int mercs, bosses;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(Client(client).IsBoss)
			{
				boss[bosses++] = client;
			}
			else
			{
				merc[mercs++] = client;
				
				if(enabled && IsPlayerAlive(client))
				{
					TF2_RegeneratePlayer(client);
					
					int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_flChargeLevel"))
						SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", 0.0);
				}
			}
		}
	}
	
	char buffer[512];
	bool specTeam = CvarSpecTeam.BoolValue;
	for(int i; i < bosses; i++)
	{
		int team = GetClientTeam(boss[i]);
		int amount = 1;
		for(int a = specTeam ? TFTeam_Unassigned : TFTeam_Spectator; a < TFTeam_MAX; a++)
		{
			if(team != a)
				amount += PlayersAlive[a];
		}
		
		int maxhealth = Bosses_SetHealth(boss[i], amount);
		if(enabled)
		{
			int maxlives = Client(boss[i]).MaxLives;
			
			for(int a; a < mercs; a++)
			{
				Bosses_GetBossNameCfg(Client(boss[i]).Cfg, buffer, sizeof(buffer), GetClientLanguage(merc[a]));
				if(maxlives > 1)
				{
					FPrintToChatEx(merc[a], boss[i], "%t", "Boss Spawned As Lives", boss[i], buffer, maxhealth, maxlives);
					if(bosses == 1)
						ShowGameText(merc[a], _, 0, "%t", "Boss Spawned As Lives", boss[i], buffer, maxhealth, maxlives);
				}
				else
				{
					FPrintToChatEx(merc[a], boss[i], "%t", "Boss Spawned As", boss[i], buffer, maxhealth);
					if(bosses == 1)
						ShowGameText(merc[a], _, 0, "%t", "Boss Spawned As", boss[i], buffer, maxhealth);
				}
			}
		}
		
		if(Client(boss[i]).Cfg.Get("command", buffer, sizeof(buffer)))
			ServerCommand(buffer);
		
		Forward_OnBossCreated(boss[i], Client(boss[i]).Cfg, false);
	}
	
	Music_RoundStart();
}

void Gamemode_CheckPointUnlock(int alive, bool notice)
{
	if(PointUnlock > 0 && alive <= PointUnlock)
	{
		if(notice && !GetControlPoint())
		{
			EmitGameSoundToAll("Announcer.AM_CapEnabledRandom");
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client) && IsPlayerAlive(client))
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Point Unlocked");
			}
		}
		
		SetArenaCapEnableTime(0.0);
		SetControlPoint(true);
		PointUnlock = 0;
	}
}

void Gamemode_OverrideWinner(int team = -1)
{
	WinnerOverride = team;
}

void Gamemode_RoundEnd(int winteam)
{
	RoundStatus = 2;
	
	// If we overrided the winner, such as spec teams
	int winner = WinnerOverride == -1 ? winteam : WinnerOverride;
	
	int[] clients = new int[MaxClients];
	int[] teams = new int[MaxClients];
	int total;
	
	bool overlay = CvarAggressiveOverlay.BoolValue;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			teams[total] = GetClientTeam(client);
			clients[total++] = client;
			if(overlay)
				Client(client).OverlayFor = 1.0;
		}
	}
	
	Music_RoundEnd(clients, total, winner);
	
	/*
		Welcome to overly complicated land:
		
		Center Huds:
			Checks for "group" to find team name for that team lowest boss index takes prio
			Gathers health and max health of that team
			Saves lastBoss[] in case of solo boss
		
		Sounds:
			Gets the lowest boss index of each team that have sound_win (if they won) or sound_fail (if they lost and alive)
			Other bosses play sound_win on themself if they also won
			Other bosses play sound_fail on themself if the global sound wasn't a sound_win, they lost, and alive or if no there was no global sound
		
			I hear my win sound			- My team won, I have a sound_win, Lowest boss index of my team
			I hear my lose sound		- My team lost, I have a sound_fail, Winners don't have a sound_win, I'm alive or there wasn't a global lose sound
			I hear other's win sound	- My team lost or my team won but I don't have sound_win
			I hear other's lose sound	- Winners don't have a sound_win, My team won or don't have a sound_fail or I'm dead and there was a global lose sound
			I hear nothing				- No winners have sound_win and no losers have sound_fail
	*/
	
	char buffer[64];
	int bosses[TFTeam_MAX], totalHealth[TFTeam_MAX], totalMax[TFTeam_MAX], lastBoss[TFTeam_MAX], lowestBoss[TFTeam_MAX], lowestIndex[TFTeam_MAX], teamName[TFTeam_MAX], teamIndex[TFTeam_MAX];
	for(int i; i < total; i++)
	{
		if(Client(clients[i]).IsBoss)
		{
			bosses[teams[i]]++;					// If it's a team or a single boss
			lastBoss[teams[i]] = clients[i];	// For single boss health left HUD
			
			bool alive = IsPlayerAlive(clients[i]);
			int index = Client(clients[i]).Index;
			
			// Find the best boss to play their sound
			if(!lowestBoss[teams[i]] || index < lowestIndex[teams[i]])
			{
				bool found = (alive || winner == teams[i]);
				if(found)
					found = Client(clients[i]).Cfg.GetSection(winner == teams[i] ? "sound_win" : "sound_fail") != null;
				
				if(found)
				{
					lowestBoss[teams[i]] = clients[i];
					lowestIndex[teams[i]] = index;
				}
			}
			
			int maxhealth = Client(clients[i]).MaxHealth * Client(clients[i]).MaxLives;
			totalMax[teams[i]] += maxhealth;
			
			// Show chat message version
			if(alive)
			{
				int health = Client(clients[i]).Health;
				if(health > 0)
				{
					totalHealth[teams[i]] += health;
				}
				else
				{
					health = 0;
				}
				
				for(int a; a < total; a++)
				{
					if(health || !Client(clients[a]).IsBoss)
					{
						Bosses_GetBossNameCfg(Client(clients[i]).Cfg, buffer, sizeof(buffer), GetClientLanguage(clients[a]));
						FPrintToChatEx(clients[a], clients[i], "%t", "Boss Had Health Left", buffer, clients[i], health, maxhealth);
					}
				}
			}
			
			// Use a team name if a boss has one
			if(!teamName[teams[i]] || index < teamIndex[teams[i]])
			{
				if(Client(clients[i]).Cfg.GetSize("group"))
				{
					teamName[teams[i]] = clients[i];
					teamIndex[teams[i]] = index;
				}
			}
			
			// Move em back from spec team
			if(teams[i] <= TFTeam_Spectator)
				SDKCall_ChangeClientTeam(clients[i], teams[i] + 2);
		}
	}
	
	bool spec = CvarSpecTeam.BoolValue;
	for(int i; i < TFTeam_MAX; i++)
	{
		if(HasBoss[i] && bosses[i])
		{
			SetHudTextParamsEx(-1.0, 0.25 + (i * 0.05), 15.0, TeamColors[i], TeamColors[winner], 2, 0.1, 0.1);
			for(int a; a < total; a++)
			{
				if(!Client(clients[a]).NoHud)
				{
					SetGlobalTransTarget(clients[a]);
					
					if(teamName[i])	// Team with a Name
					{
						Bosses_GetBossNameCfg(Client(teamName[i]).Cfg, buffer, sizeof(buffer), GetClientLanguage(clients[a]), "group");
						ShowSyncHudText(clients[a], TeamSyncHud[i], "%t", "Team Had Health Left Hud", "_s", buffer, totalHealth[i], totalMax[i]);
					}
					else if(bosses[i] == 1)	// Solo Boss
					{
						Bosses_GetBossNameCfg(Client(lastBoss[i]).Cfg, buffer, sizeof(buffer), GetClientLanguage(clients[a]));
						ShowSyncHudText(clients[a], TeamSyncHud[i], "%t", "Boss Had Health Left Hud", buffer, lastBoss[i], totalHealth[i], totalMax[i]);
					}
					else	// Team without a Name
					{
						FormatEx(buffer, sizeof(buffer), "Team %d", i);
						ShowSyncHudText(clients[a], TeamSyncHud[i], "%t", "Team Had Health Left Hud", buffer, totalHealth[i], totalMax[i]);
					}
				}
			}
		}
		else if(Enabled && MaxPlayersAlive[i] && (spec || i > TFTeam_Spectator))
		{
			SetHudTextParamsEx(-1.0, 0.25 + (i * 0.05), 15.0, TeamColors[i], TeamColors[winner], 2, 0.1, 0.1);
			for(int a; a < total; a++)
			{
				if(!Client(clients[a]).NoHud)
				{
					SetGlobalTransTarget(clients[a]);
					FormatEx(buffer, sizeof(buffer), "Team %d", i);
					ShowSyncHudText(clients[a], TeamSyncHud[i], "%t", "Team Had Players Left Hud", buffer, PlayersAlive[i], MaxPlayersAlive[i]);
				}
			}
		}
		else if(HasBoss[i])
		{
			for(int a; a < total; a++)
			{
				ClearSyncHud(clients[a], TeamSyncHud[i]);
			}
		}
		
		HasBoss[i] = false;
		
		if(HudTimer[i])
		{
			KillTimer(HudTimer[i]);
			HudTimer[i] = null;
		}
	}
	
	// Figure out which boss we should play
	int globalBoss, globalTeam;
	if(lowestBoss[winner])
	{
		globalBoss = lowestBoss[winner];
		globalTeam = winner;
	}
	else
	{
		int index = 99;
		for(int i; i < TFTeam_MAX; i++)
		{
			if(lowestIndex[i] < index)
			{
				globalBoss = lowestBoss[i];
				globalTeam = i;
			}
		}
	}
	
	// Gather who hears global and play locals
	int globalCount;
	int[] globalSound = new int[total];
	for(int i; i < total; i++)
	{
		if(clients[i] != globalBoss && Client(clients[i]).IsBoss)
		{
			if(winner == teams[i])
			{
				// Play sound_win for themself if they are on the winning team
				if(Bosses_PlaySoundToClient(clients[i], clients[i], "sound_win", _, _, _, _, _, 2.0))
					continue;
			}
			else if(globalTeam != winner)
			{
				// Play sound_fail for themself if: Global sound wasn't a sound_win, Global sound didn't exist or they're alive
				if(!globalBoss || IsPlayerAlive(clients[i]))
				{
					if(Bosses_PlaySoundToClient(clients[i], clients[i], "sound_fail", _, _, _, _, _, 2.0))
						continue;
				}
			}
		}
		
		globalSound[globalCount++] = clients[i];
	}
	
	// Play global sound
	if(globalBoss)
		Bosses_PlaySound(globalBoss, globalSound, globalCount, globalTeam == winner ? "sound_win" : "sound_fail", _, _, _, _, _, 2.0);
	
	// Give Queue Points
	if(Enabled && total)
	{
		int[] points = new int[MaxClients+1];
		for(int i; i < total; i++)
		{
			points[clients[i]] = (Client(clients[i]).IsBoss || (GetClientTeam(clients[i]) <= TFTeam_Spectator && !IsPlayerAlive(clients[i]))) ? 0 : 10;
		}
		
		if(ForwardOld_OnAddQueuePoints(points, MaxClients+1))
		{
			for(int i; i < total; i++)
			{
				Client(clients[i]).Queue += points[clients[i]];
			}
		}
	}
}

void Gamemode_UpdateHUD(int team, bool healing = false, bool nobar = false)
{
	if(!Enabled || RoundStatus == 1)
	{
		int setting = CvarHealthBar.IntValue;
		if(setting)
		{
			int lastCount, count;
			if(HasBoss[team])
			{
				for(int i; i < TFTeam_MAX; i++)
				{
					if(HasBoss[i])
						count++;
				}
				
				lastCount = count;
			}
			else
			{
				count++;
				HasBoss[team] = true;
				for(int i; i < TFTeam_MAX; i++)
				{
					if(i != team && HasBoss[i])
					{
						count++;
						lastCount++;
						Gamemode_UpdateHUD(i, healing, true);
					}
				}
			}
			
			int[] clients = new int[MaxClients];
			int total;
			
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client))
					clients[total++] = client;
			}
			
			int health, lives, maxhealth, maxcombined, combined, bosses;
			for(int i; i < total; i++)
			{
				if(Client(clients[i]).IsBoss && GetClientTeam(clients[i]) == team)
				{
					if(IsPlayerAlive(clients[i]))
					{
						bosses++;
						int hp = GetClientHealth(clients[i]);
						if(hp > 0)
						{
							health += hp;
							lives += Client(clients[i]).Lives;
							combined += Client(clients[i]).Health;
						}
					}
					
					int maxhp = SDKCall_GetMaxHealth(clients[i]);
					maxhealth += maxhp;
					maxcombined += maxhp + (Client(clients[i]).MaxHealth * (Client(clients[i]).MaxLives - 1));
				}
			}
			
			if(setting > 1 && maxcombined)
			{
				if(count > 1)
				{
					float x = (team == TFTeam_Red || team == TFTeam_Spectator) ? 0.53 : 0.43;
					float y = team <= TFTeam_Spectator ? 0.18 : 0.12;
					for(int i; i < total; i++)
					{
						if(Client(clients[i]).NoHud || (GetClientButtons(clients[i]) & IN_SCORE))
							continue;
						
						if(IsPlayerAlive(clients[i]))
						{
							SetHudTextParamsEx(x, y, 3.0, TeamColors[team], TeamColors[team], 0, 0.35, 0.0, 0.1);
						}
						else
						{
							SetHudTextParamsEx(x, y+0.1, 3.0, TeamColors[team], TeamColors[team], 0, 0.35, 0.0, 0.1);
						}
						
						if(bosses > 1)
						{
							ShowSyncHudText(clients[i], TeamSyncHud[team], "%d", combined);
						}
						else if(lives > 1)
						{
							ShowSyncHudText(clients[i], TeamSyncHud[team], "%d (x%d)", health, lives);
						}
						else
						{
							ShowSyncHudText(clients[i], TeamSyncHud[team], "%d", health);
						}
					}
				}
				else
				{
					for(int i; i < total; i++)
					{
						if(Client(clients[i]).NoHud || (GetClientButtons(clients[i]) & IN_SCORE))
							continue;
						
						if(IsPlayerAlive(clients[i]))
						{
							SetHudTextParams(-1.0, 0.12, 3.0, 200, 255, 200, 255, 0, 0.35, 0.0, 0.1);
						}
						else
						{
							SetHudTextParams(-1.0, 0.22, 3.0, 200, 255, 200, 255, 0, 0.35, 0.0, 0.1);
						}
						
						if(bosses > 1)
						{
							ShowSyncHudText(clients[i], TeamSyncHud[team], "%d / %d", combined, maxcombined);
						}
						else if(lives > 1)
						{
							ShowSyncHudText(clients[i], TeamSyncHud[team], "%d / %d (x%d)", health, maxhealth, lives);
						}
						else
						{
							ShowSyncHudText(clients[i], TeamSyncHud[team], "%d / %d", health, maxhealth);
						}
					}
				}
			}
			
			float refresh = CvarRefreshTime.FloatValue;
			if(setting == 1 || nobar)
			{
			}
			else if(count < 3)
			{
				int entity = MaxClients + 1;
				while((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
				{
					if(GetEntProp(entity, Prop_Send, "m_iTeamNum") > TFTeam_Blue)
						break;
				}
				
				if(entity == -1)
				{
					entity = FindEntityByClassname(MaxClients+1, "monster_resource");
					if(!maxcombined)
					{
						RemoveEntity(entity);
					}
					else
					{
						if(entity == -1)
						{
							entity = CreateEntityByName("monster_resource");
							DispatchSpawn(entity);
						}
						
						float gameTime = GetGameTime();
						if(healing)
							HealingFor = gameTime + 1.0;
						
						if(HealingFor > gameTime)
						{
							SetEntProp(entity, Prop_Send, "m_iBossState", true);
							refresh = HealingFor - gameTime;
						}
						else
						{
							SetEntProp(entity, Prop_Send, "m_iBossState", false);
						}
						
						int amount;
						if(count == 2)
						{
							amount = SetTeamBasedHealthBar(combined, team);
						}
						else if(combined)
						{
							amount = combined * 255 / maxcombined;
							if(!amount)
								amount = 1;
						}
						
						SetEntProp(entity, Prop_Send, "m_iBossHealthPercentageByte", amount, 2);
					}
				}
			}
			else if(lastCount < 3)
			{
				int entity = FindEntityByClassname(MaxClients+1, "monster_resource");
				if(entity != -1)
					RemoveEntity(entity);
			}
			
			if(HudTimer[team])
			{
				KillTimer(HudTimer[team]);
				HudTimer[team] = null;
			}
			
			if(health > 0 && RoundStatus != 2)
				HudTimer[team] = CreateTimer(refresh, Gamemode_UpdateHudTimer, team);
		}
	}
}

static int SetTeamBasedHealthBar(int health1, int team1)
{
	int team2;
	for(int i; i < TFTeam_MAX; i++)
	{
		if(i != team1 && HasBoss[i])
		{
			team2 = i;
			break;
		}
	}
	
	int health2 = 1;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(Client(client).IsBoss && GetClientTeam(client) == team2 && IsPlayerAlive(client))
		{
			int health = Client(client).Health;
			if(health > 0)
				health2 += health;
		}
	}
	
	if(team1 > team2)
	{
		if(health1 > health2)
		{
			health2 = RoundToCeil((1.0 - (float(health2) / float(health1) / 2.0)) * 255.0);
		}
		else if(health2)
		{
			health2 = health1 * 255 / health2 / 2;
			if(!health2)
				health2 = 1;
		}
	}
	else if(!health1)
	{
		health2 = 0;
	}
	else if(health2 > health1)
	{
		health2 = RoundToCeil((1.0 - (float(health1) / float(health2) / 2.0)) * 255.0);
	}
	else
	{
		health2 = health2 * 255 / health1 / 2;
		if(!health2)
			health2 = 1;
	}
	
	return health2;
}

public Action Gamemode_UpdateHudTimer(Handle timer, int team)
{
	HudTimer[team] = null;
	Gamemode_UpdateHUD(team);
	return Plugin_Continue;
}

void Gamemode_SetClientGlow(int client, float duration)
{
	float time = GetGameTime() + duration;
	float current = Client(client).GlowFor;
	if(current < time)
		Client(client).GlowFor = time;
}

void Gamemode_PlayerRunCmd(int client, int buttons)
{
	if(IsPlayerAlive(client))
	{
		if(Enabled && RoundStatus == 1 && !Client(client).IsBoss && !Client(client).Minion)
		{
			int team = GetClientTeam(client);
			if(PlayersAlive[team] < 3)
				TF2_AddCondition(client, TF2_GetPlayerClass(client) == TFClass_Scout ? TFCond_Buffed : TFCond_CritCola, 0.5);
			
			if(PlayersAlive[team] < 2) 
			{
				TF2_AddCondition(client, TFCond_CritOnDamage, 0.5);
				if (CvarPlayerGlow.BoolValue)
				{
					Gamemode_SetClientGlow(client, 5.0);
				}
			}
		}
		
		if(Client(client).Glowing)
		{
			if(Client(client).GlowFor < GetGameTime())
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", false, 1);
				Client(client).Glowing = false;
			}
		}
		else if(!GetEntProp(client, Prop_Send, "m_bGlowEnabled", 1) && Client(client).GlowFor > GetGameTime())
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", true, 1);
			Client(client).Glowing = true;
		}
	}
	
	float time = GetEngineTime();
	if(Enabled && RoundStatus == 1 && !Client(client).IsBoss && !Client(client).NoHud && !Client(client).NoDmgHud && !(buttons & IN_SCORE))
	{
		if(Client(client).RefreshAt < time)
		{
			Client(client).RefreshAt = time + 0.2;
			
			SetGlobalTransTarget(client);
			
			int target = client;
			if(IsPlayerAlive(client))
			{
				int aim = GetClientAimTarget(client, true);
				if(aim != -1)
				{
					int team = GetClientTeam(client);
					bool show = team == GetClientTeam(aim);
					if(!show && TF2_IsPlayerInCondition(aim, TFCond_Disguised) && GetEntProp(aim, Prop_Send, "m_nDisguiseTeam") == team)
					{
						show = true;
						
						int disguise = GetEntProp(aim, Prop_Send, "m_iDisguiseTargetIndex");
						if(disguise > 0 && disguise <= MaxClients && IsClientInGame(disguise))
							aim = disguise;
					}
					
					if(show)
						target = aim;
				}
			}
			else if(IsClientObserver(client))
			{
				int aim = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(aim != client && aim > 0 && aim <= MaxClients && IsClientInGame(aim) && GetClientTeam(client) == GetClientTeam(aim))
					target = aim;
			}
			
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if(target == client)
			{
				ShowSyncHudText(client, SelfSyncHud, "%t", "Current Stats Hud", Client(client).TotalDamage, Client(client).Healing, Client(client).TotalAssist);
			}
			else
			{
				ShowSyncHudText(client, SelfSyncHud, "%t", "Viewing Stats Hud", target, Client(target).TotalDamage, Client(target).Healing, Client(target).TotalAssist);
			}
		}
	}
	
	if(Client(client).OverlayFor && Client(client).OverlayFor < time)
	{
		Client(client).OverlayFor = 0.0;
		
		int flags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay off");
		SetCommandFlags("r_screenoverlay", flags);
	}
}

void Gamemode_ConditionAdded(int client, TFCond cond)
{
	if(cond == TFCond_Disguised && CvarDisguiseModels.BoolValue)
		TriggerTimer(CreateTimer(0.1, Gamemode_DisguiseTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT));
}

void Gamemode_ConditionRemoved(int client, TFCond cond)
{
	if(cond == TFCond_Disguised && CvarDisguiseModels.BoolValue)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, 0);
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, 3);
	}
}

public Action Gamemode_DisguiseTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		int target = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
		if(target > 0 && target <= MaxClients && GetEntProp(target, Prop_Send, "m_iClass") == GetEntProp(client, Prop_Send, "m_nDisguiseClass"))
		{
			bool team = view_as<bool>(GetClientTeam(client) % 2);
			
			static char model[PLATFORM_MAX_PATH];
			GetEntPropString(team ? client : target, Prop_Data, "m_ModelName", model, sizeof(model));
			if(model[0])
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", PrecacheModel(model), _, 0);
			
			GetEntPropString(team ? target : client, Prop_Data, "m_ModelName", model, sizeof(model));
			if(model[0])
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", PrecacheModel(model), _, 3);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, 0);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, 3);
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}