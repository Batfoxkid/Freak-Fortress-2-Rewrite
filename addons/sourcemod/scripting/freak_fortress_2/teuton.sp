#pragma semicolon 1
#pragma newdecls required

#define TEUTON_MODEL	"models/bots/demo/bot_demo.mdl"

static int MercTeam;

void Teuton_MapStart()
{
	PrecacheModel(TEUTON_MODEL);

	int entity = FindEntityByClassname(-1, "tf_player_manager");
	if(entity != -1)
		SDKHook(entity, SDKHook_ThinkPost, Teuton_PlayerManagerThink);
}

void Teuton_RoundStart(int team)
{
	MercTeam = team;
}

void Teuton_PlayerDeath(int victim)
{
	if(Client(victim).MinionType == 2)
	{
		SetEntPropFloat(victim, Prop_Send, "m_flModelScale", 1.0);
		SetEntityCollisionGroup(victim, 5);
		SetEntityRenderColor(victim, _, _, _, 255);
		CreateTimer(0.05, Timer_RemoveRagdoll, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!MercTeam || RoundStatus != 1 || !Cvar[Teutons].BoolValue)
		return;
	
	bool found;
	for(int i; i < MaxClients; i++)
	{
		int client = FindClientOfBossIndex(i);
		if(client != -1)
		{
			if(Client(client).Cfg.GetBool("noteuton", found) && found)
				return;
		}
	}

	CreateTimer(6.0, Teuton_SpawnTimer, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
}

static Action Teuton_SpawnTimer(Handle timer, any userid)
{
	if(Enabled && MercTeam && RoundStatus == 1)
	{
		int client = GetClientOfUserId(userid);
		if(client && !IsPlayerAlive(client) && GetClientTeam(client) > TFTeam_Spectator)
		{
			ChangeClientTeam(client, MercTeam);
			TF2_RespawnPlayer(client);
			TF2_SetPlayerClass(client, TFClass_DemoMan);
			TF2_RemoveAllItems(client);
			Client(client).MinionType = 2;
			
			int i, entity;
			while(TF2U_GetWearable(client, entity, i))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:
					{
						// Action slot items
					}
					default:
					{
						// Wearables
						TF2_RemoveWearable(client, entity);
					}
				}
			}

			SetVariantString(TEUTON_MODEL);
			AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
			
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.6);
			SetEntityCollisionGroup(client, 1);
			TF2_AddCondition(client, TFCond_DisguisedAsDispenser);	// Makes Sentries ignore the player
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, _, _, _, 128);
			SetEntityHealth(client, 1);
			
			static WeaponData items[2];
			if(!items[0].Index)
			{
				// Weapon
				items[0].Setup("tf_weapon_sword", 132, "", false);
				items[0].Quality = 6;
				items[0].Level = 5;
				items[0].Alpha = 128;
			}

			if(!items[1].Index)
			{
				// Hat
				items[1].Setup("tf_wearable", 30969, "", false);
				items[1].Quality = 6;
				items[1].Level = 5;
				items[1].Alpha = 128;
			}
			
			entity = TF2Items_CreateFromStruct(client, items[0]);
			if(entity != -1)
			{
				Attrib_Set(entity, "damage penalty", 1, 0.3076);
				Attrib_Set(entity, "fire rate penalty", 5, 1.3);
				Attrib_Set(entity, "crit mod disabled", 15, 0.0);
				Attrib_Set(entity, "move speed bonus", 107, 1.25);
				Attrib_Set(entity, "max health additive penalty", 125, -999.0);
				Attrib_Set(entity, "dmg taken increased", 412, 0.0);
				Attrib_Set(entity, "dmg penalty vs buildings", 775, 0.0);
				Attrib_Set(entity, "no_duck", 820, 1.0);
				Attrib_Set(entity, "voice pitch scale", 2048, 0.0);
			}

			TF2Items_CreateFromStruct(client, items[1]);
		}
	}
	return Plugin_Continue;
}

static Action Timer_RemoveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(ragdoll))
			AcceptEntityInput(ragdoll, "Kill");
	}
	return Plugin_Continue;
}

static void Teuton_PlayerManagerThink(int entity)
{
	static int offset = -1;
	if(offset == -1) 
		offset = FindSendPropInfo("CTFPlayerResource", "m_bAlive");

	bool[] alive = new bool[MaxClients+1];

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			// Alive and not a teuton
			alive[client] = (IsPlayerAlive(client) && Client(client).MinionType != 2);
		}
	}

	SetEntDataArray(entity, offset, alive, MaxClients + 1);
}