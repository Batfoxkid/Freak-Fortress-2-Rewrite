#tryinclude <goomba>

#pragma semicolon 1
#pragma newdecls required

static int GoombaOverride = 1;

void Goomba_PrintStatus()
{
	PrintToServer("'goomba' is %sloaded", LibraryExists("goomba") ? "" : "not ");
}

void Goomba_RoundSetup()
{
	GoombaOverride = 1;
}

void Goomba_BossCreated(ConfigMap cfg)
{
	if(Enabled)
		cfg.GetInt("goomba", GoombaOverride);
}

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(Client(attacker).MinionType == 2)
		return Plugin_Handled;
	
	switch(GoombaOverride)
	{
		case 0:
		{
			return Plugin_Handled;
		}
		case 2:	// Boss Team
		{
			if(GetClientTeam(attacker) != Bosses_GetBossTeam())
				return Plugin_Handled;
		}
		case 3:	// Merc Team
		{
			if(GetClientTeam(attacker) == Bosses_GetBossTeam())
				return Plugin_Handled;
		}
		case 4:	// Non-Bosses
		{
			if(Client(attacker).IsBoss)
				return Plugin_Handled;
		}
		case 5:	// No Minions
		{
			if(Client(attacker).MinionType)
				return Plugin_Handled;
		}
		case 6:	// Boss Only
		{
			if(!Client(attacker).IsBoss)
				return Plugin_Handled;
		}
	}
	
	if(damageMultiplier > 0.3 && victim > 0 && victim <= MaxClients && Client(victim).IsBoss)
	{
		damageMultiplier = 0.0;
		damageBonus = 585.0;
		JumpPower *= 1.5;
		return Plugin_Changed;
	}
	else if(Client(attacker).IsBoss)
	{
		JumpPower = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}