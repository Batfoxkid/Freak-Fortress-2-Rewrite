/*
	void Gamemode_RoundSetup()
	void Gamemode_RoundStart()
	void Gamemode_RoundEnd()
*/

static bool Waited;

void Gamemode_RoundSetup()
{
	RoundActive = false;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			Client(client).ResetByRound();
			if(Client(client).IsBoss)
				Bosses_Remove(client);
		}
	}
	
	if(Enabled)
	{
		if(!Waited)
		{
			CvarTournament.BoolValue = true;
			CvarMovementFreeze.BoolValue = false;
			ServerCommand("mp_waitingforplayers_restart 1");
		}
		else if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
		{
			//int bvb = CvarBossVsBoss.IntValue;
			
			
		}
	}
}

public void TF2_OnWaitingForPlayersStart()
{
	if(Enabled)
	{
		Waited = true;
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
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1 && GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))
			TF2_RespawnPlayer(client);
	}
	GameRules_SetProp("m_bInWaitingForPlayers", true, 1);
	return Plugin_Continue;
}

void Gamemode_RoundStart()
{
	if(Enabled && !GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		RoundActive = true;
		
		int players[4];
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				int team = GetClientTeam(client);
				if(team >= 0 && team < 4)
					players[team]++;
				
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
			if(Client(client).IsBoss && IsClientInGame(client) && IsPlayerAlive(client))
			{
				int team = GetClientTeam(client);
				int amount = 0;
				for(int i = specTeam ? 0 : 2; i<4; i++)
				{
					if(team != i)
						amount += players[i];
				}
				Bosses_SetHealth(client, amount);
			}
		}
	}
}

void Gamemode_RoundEnd()
{
	RoundActive = false;
}