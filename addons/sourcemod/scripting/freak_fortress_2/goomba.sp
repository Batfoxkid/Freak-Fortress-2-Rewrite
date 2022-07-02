/*
	void Goomba_RoundSetup()
	void Goomba_BossCreated(ConfigMap cfg)
*/

#pragma newdecls optional
#tryinclude <goomba>
#pragma newdecls required

#pragma semicolon 1

static int GoombaOverride = 1;

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
			if(Client(attacker).Minion)
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
	return Plugin_Continue;
}