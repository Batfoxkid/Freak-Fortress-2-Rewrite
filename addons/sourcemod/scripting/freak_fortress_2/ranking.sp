#pragma semicolon 1
#pragma newdecls required

static bool ActiveRanking[MAXTF2PLAYERS];
static bool UpdateDataBase[MAXTF2PLAYERS];
static StringMap RankListing[MAXTF2PLAYERS];

void Ranking_AddBoss(int client, const char[] boss, int rank)
{
	if(!RankListing[client])
		RankListing[client] = new StringMap();
	
	RankListing[client].SetValue(boss, rank);
}

bool Ranking_ShouldUpdate(int client)
{
	return UpdateDataBase[client];
}

void Ranking_Clear(int client)
{
	delete RankListing[client];
	UpdateDataBase[client] = true;
}

StringMapSnapshot Ranking_GetSnapshot(int client)
{
	if(RankListing[client])
		return RankListing[client].Snapshot();
	
	return null;
}

int Ranking_GetRank(int client, const char[] boss)
{
	int rank;
	if(RankListing[client])
		RankListing[client].GetValue(boss, rank);
	
	return rank;
}

int Ranking_ApplyEffects(int client, float &multi)
{
	if(IsFakeClient(client))
	{
		multi = 1.0;
		return 0;
	}
	
	char name[64];
	Bosses_GetBossNameCfg(Client(client).Cfg, name, sizeof(name), _, "filename");

	int rank = Ranking_GetRank(client, name);
	multi = Ranking_GetHealthMulti(rank);
	if(multi != 1.0)
	{
		Client(client).MaxHealth *= multi;

		if(IsPlayerAlive(client))
		{
			SetEntityHealth(client, Client(client).MaxHealth);
			Bosses_UpdateHealth(client);
		}
	}

	ActiveRanking[client] = true;

	return rank;
}

void Ranking_BossRemoved(int client, bool disconnect)
{
	if(ActiveRanking[client])
	{
		ActiveRanking[client] = false;

		// Rank loss when disconnecting
		if(Enabled && disconnect && Cvar[RankingLose].FloatValue > 0.0)
		{
			char name[64];
			Bosses_GetBossNameCfg(Client(client).Cfg, name, sizeof(name), _, "filename");
			if(name[0])
			{
				int rank = Ranking_GetRank(client, name);
				if(rank > 0)
				{
					Ranking_AddBoss(client, name, rank - 1);
					UpdateDataBase[client] = true;
				}
			}
		}
	}
}

float Ranking_GetHealthMulti(int rank)
{
	float stats = Cvar[RankingStats].FloatValue;
	if(!stats)
		return 1.0;
	
	return Pow(1.0 - Cvar[RankingStats].FloatValue, float(rank));
}

void Ranking_RoundEnd(int[] clients, int amount, int winner)
{
	bool display = Cvar[RankingStyle].IntValue > 0;
	float lose = Cvar[RankingLose].FloatValue;
	char name[64], file[64];
	int kills, par;

	for(int i; i < amount; i++)
	{
		if(ActiveRanking[clients[i]] && Client(clients[i]).IsBoss)
		{
			ActiveRanking[clients[i]] = false;
			Bosses_GetBossNameCfg(Client(clients[i]).Cfg, name, sizeof(name), GetClientLanguage(clients[i]));
			Bosses_GetBossNameCfg(Client(clients[i]).Cfg, file, sizeof(file), _, "filename");
			int team = GetClientTeam(clients[i]);

			if(winner == team)
			{
				// Won the round, increase by 1
				int rank = Ranking_GetRank(clients[i], file) + 1;
				Ranking_AddBoss(clients[i], file, rank);
				UpdateDataBase[clients[i]] = true;
				
				if(display)
					CPrintToChatEx(clients[i], clients[i], "%t", "Boss Rank Increased", name, rank);
				
				continue;
			}
			else if(lose <= 0.0)
			{
				// No penalty
				continue;
			}
			else if(lose < 1.0)
			{
				// Only if score is low
				int alive, total;
				for(int b; b < TFTeam_MAX; b++)
				{
					if(b != team)
					{
						alive += PlayersAlive[i];
						total += MaxPlayersAlive[i];
					}
				}

				kills = total - alive;
				par = RoundFloat(total * lose);

				if(kills >= par)
				{
					if(display)
					{
						int rank = Ranking_GetRank(clients[i], file);
						if(rank > 0)
							CPrintToChatEx(clients[i], clients[i], "%t", "Boss Rank Saved Score", name, rank, kills, par);
					}
					
					continue;
				}
			}
			
			// Lost the round, decrease by X
			int rank = Ranking_GetRank(clients[i], file);
			if(rank > 0)
			{
				rank -= RoundToCeil(lose - 0.01);
				if(rank < 0)
					rank = 0;
				
				Ranking_AddBoss(clients[i], file, rank);
				UpdateDataBase[clients[i]] = true;

				if(display)
				{
					if(par)
					{
						CPrintToChatEx(clients[i], clients[i], "%t", "Boss Rank Decreased Score", name, rank, kills, par);
					}
					else
					{
						CPrintToChatEx(clients[i], clients[i], "%t", "Boss Rank Decreased", name, rank);
					}
				}
			}
		}
	}
}

bool Ranking_Active()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(ActiveRanking[client])
			return true;
	}

	return false;
}

void Ranking_Disable()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		ActiveRanking[client] = false;
	}
}