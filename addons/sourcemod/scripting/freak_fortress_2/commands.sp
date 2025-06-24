#pragma semicolon 1
#pragma newdecls required

enum FF2FilterSearch 
{
	FF2FilterSearch_Boss,
	FF2FilterSearch_Minion
}

void Command_PluginStart()
{
	AddMultiTargetFilter("@hale", FF2TargetFilter, "all current bosses", false);
	AddMultiTargetFilter("@!hale", FF2TargetFilter, "all current non-boss players", false);
	AddMultiTargetFilter("@boss", FF2TargetFilter, "all current bosses", false);
	AddMultiTargetFilter("@!boss", FF2TargetFilter, "all current non-boss players", false);
	AddMultiTargetFilter("@minion", FF2TargetFilter, "all current minion players", false);
	AddMultiTargetFilter("@!minion", FF2TargetFilter, "all current non-minion players", false);

	AddCommandListener(Command_Voicemenu, "voicemenu");
	AddCommandListener(Command_KermitSewerSlide, "explode");
	AddCommandListener(Command_KermitSewerSlide, "kill");
	AddCommandListener(Command_Spectate, "spectate");
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_AutoTeam, "autoteam");
	AddCommandListener(Command_JoinClass, "joinclass");
	AddCommandListener(Command_EurekaTeleport, "eureka_teleport");
}

static bool FF2TargetFilter(const char[] pattern, ArrayList clients)
{
	FF2FilterSearch filterSearch = StrContains(pattern, "minion", true) != -1 ? FF2FilterSearch_Minion : FF2FilterSearch_Boss;
	bool isOppositeFilter = pattern[1] == '!';

	switch(filterSearch)
	{
		case FF2FilterSearch_Boss:
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client))
					continue;

				if(Client(client).IsBoss)
				{
					if(!isOppositeFilter)
						clients.Push(client);
				}
				else if(isOppositeFilter)
				{
					clients.Push(client);
				}
			}
		}
		case FF2FilterSearch_Minion:
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client))
					continue;

				if(Client(client).MinionType)
				{
					if(!isOppositeFilter)
						clients.Push(client);
				}
				else if(isOppositeFilter)
				{
					clients.Push(client);
				}
			}
		}
	}

	return true;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	if((Client(client).IsBoss || Client(client).MinionType == 2) && IsPlayerAlive(client) && (!Enabled || RoundStatus == 1))
	{
		char buffer[64];
		kv.GetSectionName(buffer, sizeof(buffer));
		if(StrEqual(buffer, "+helpme_server", false))
			return UseRage(client);
	}
	return Plugin_Continue;
}

static Action Command_Voicemenu(int client, const char[] command, int args)
{
	if(client && args == 2 && (Client(client).IsBoss || Client(client).MinionType == 2) && IsPlayerAlive(client) && (!Enabled || RoundStatus == 1))
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		if(arg[0] == '0')
		{
			GetCmdArg(2, arg, sizeof(arg));
			if(arg[0] == '0')
				return UseRage(client);
		}
	}
	return Plugin_Continue;
}

static Action UseRage(int client)
{
	if(!Client(client).IsBoss)
		return Plugin_Handled;
	
	float rageDamage = Client(client).RageDamage;
	if(rageDamage >= 0.0 && rageDamage < 99999.0)
	{
		int rageType = Client(client).RageMode;
		if(rageType != 2)
		{
			float rageMin, charge;
			if(rageDamage <= 1.0 || (charge = Client(client).GetCharge(0)) >= (rageMin = Client(client).RageMin))
			{
				if(rageDamage > 1.0)
				{
					if(rageType == 1)
					{
						Client(client).SetCharge(0, charge - rageMin);
					}
					else if(rageType == 0)
					{
						Client(client).SetCharge(0, 0.0);
					}
				}
				
				Bosses_UseSlot(client, 0, 0);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

static Action Command_KermitSewerSlide(int client, const char[] command, int args)
{
	if(Enabled)
	{
		if((Client(client).IsBoss || Client(client).MinionType == 1) && (RoundStatus == 0 || (RoundStatus == 1 && !Cvar[BossSewer].BoolValue)))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

static Action Command_Spectate(int client, const char[] command, int args)
{
	if((!Client(client).IsBoss && Client(client).MinionType != 1 && (!Enabled || GameRules_GetProp("m_bInWaitingForPlayers", 1))) || IsEmptyServer())
		return Plugin_Continue;
	
	return SwapTeam(client, TFTeam_Spectator);
}

static Action Command_AutoTeam(int client, const char[] command, int args)
{
	if((!Client(client).IsBoss && Client(client).MinionType != 1 && (!Enabled || GameRules_GetProp("m_bInWaitingForPlayers", 1))) || IsEmptyServer())
		return Plugin_Continue;
	
	int reds, blus;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(client != i && IsClientInGame(i))
		{
			int team = GetClientTeam(i);
			if(team == 3)
			{
				blus++;
			}
			else if(team == 2)
			{
				reds++;
			}
		}
	}
	
	int team;
	if(reds > blus)
	{
		team = TFTeam_Blue;
	}
	else if(reds < blus)
	{
		team = TFTeam_Red;
	}
	else if(GetClientTeam(client) == TFTeam_Red)
	{
		team = TFTeam_Blue;
	}
	else
	{
		team = TFTeam_Red;
	}
	
	return SwapTeam(client, team);
}

static Action Command_JoinTeam(int client, const char[] command, int args)
{
	if((!Client(client).IsBoss && Client(client).MinionType != 1 && (!Enabled || GameRules_GetProp("m_bInWaitingForPlayers", 1))) || IsEmptyServer())
		return Plugin_Continue;
	
	char buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	int team = TFTeam_Unassigned;
	if(StrEqual(buffer, "red", false))
	{
		team = TFTeam_Red;
	}
	else if(StrEqual(buffer, "blue", false))
	{
		team = TFTeam_Blue;
	}
	else if(StrEqual(buffer, "auto", false))
	{
		return Command_AutoTeam(client, command, args);
	}
	else if(StrEqual(buffer, "spectate", false))
	{
		team = TFTeam_Spectator;
	}
	else
	{
		team = GetClientTeam(client);
	}
	
	return SwapTeam(client, team);
}

static Action SwapTeam(int client, int wantTeam)
{
	int newTeam = wantTeam;
	if(Enabled)
	{
		// No suicides
		if(RoundStatus != 2 && !Cvar[BossSewer].BoolValue && IsPlayerAlive(client) && (Client(client).IsBoss || Client(client).MinionType == 1))
			return Plugin_Handled;
		
		// Prevent going to spectate with cvar disabled
		if(newTeam <= TFTeam_Spectator && !Cvar[AllowSpectators].BoolValue)
			return Plugin_Handled;
		
		int currentTeam = GetClientTeam(client);
		
		// Prevent going to same team unless spec team trying to actually spec
		if(currentTeam > TFTeam_Spectator && newTeam == currentTeam)
			return Plugin_Handled;
		
		if(Client(client).IsBoss || Client(client).MinionType == 1)
		{
			// Prevent swapping to a different team unless to spec
			if(newTeam > TFTeam_Spectator)
				return Plugin_Handled;
		}
		else if(!Cvar[BossVsBoss].BoolValue)
		{
			// Prevent swapping to a different team unless in spec or going to spec
			if(currentTeam > TFTeam_Spectator && newTeam > TFTeam_Spectator)
				return Plugin_Handled;
			
			// Manage which team we should assign
			if(newTeam > TFTeam_Spectator)
				newTeam = Bosses_GetBossTeam() == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
		}
	}
	else if(Client(client).IsBoss)
	{
		if(newTeam <= TFTeam_Spectator && !Cvar[AllowSpectators].BoolValue)
			return Plugin_Handled;
	}
	
	if(Client(client).IsBoss || Client(client).MinionType)
	{
		// Remove properties
		Bosses_Remove(client);
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, newTeam);
		return Plugin_Handled;
	}
	
	if(Enabled)
	{
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, newTeam);
		if(newTeam > TFTeam_Spectator)
			ShowVGUIPanel(client, newTeam == TFTeam_Red ? "class_red" : "class_blue");
		
		if(Cvar[AggressiveSwap].BoolValue)
		{
			DataPack pack = new DataPack();
			CreateDataTimer(0.2, Command_AggressiveSwap, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(newTeam);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

static Action Command_AggressiveSwap(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		int team = pack.ReadCell();
		if(GetClientTeam(client) != team)
		{
			ChangeClientTeam(client, team);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

static Action Command_JoinClass(int client, const char[] command, int args)
{
	if(Client(client).IsBoss || Client(client).MinionType)
	{
		if(Enabled)
		{
			char class[16];
			GetCmdArg(1, class, sizeof(class));
			TFClassType num = TF2_GetClass(class);
			if(num != TFClass_Unknown)
				SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", num);
		
			return Plugin_Handled;
		}
		else
		{
			Bosses_Remove(client);
			ForcePlayerSuicide(client);
		}
	}
	return Plugin_Continue;
}

static Action Command_EurekaTeleport(int client, const char[] command, int args)
{
	if(Enabled && RoundStatus == 1 && IsPlayerAlive(client))
	{
		char buffer[4];
		GetCmdArg(1, buffer, sizeof(buffer));
		if ( StringToInt(buffer) == 0)
		{
			return Plugin_Handled;
		}
		else
		{
			int entity = MaxClients + 1;
			while((entity = FindEntityByClassname(entity, "obj_teleporter")) != -1)
			{
				if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client && GetEntProp(entity, Prop_Send, "m_iObjectMode") == view_as<int>(TFObjectMode_Exit))
				{
					if(!GetEntProp(entity, Prop_Send, "m_bBuilding"))
					{
						return Plugin_Continue;
					}
					break;
				}
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

static bool IsEmptyServer()
{
	return GameRules_GetRoundState() < RoundState_StartGame;
}