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
			
			entity = CreateTeutonItem(client, "tf_weapon_sword", 132, false);
			if(entity != -1)
			{
				Attrib_Set(entity, "damage penalty", 0.3076);
				Attrib_Set(entity, "fire rate penalty", 1.3);
				Attrib_Set(entity, "crit mod disabled", 0.0);
				Attrib_Set(entity, "move speed bonus", 1.25);
				Attrib_Set(entity, "max health additive penalty", -999.0);
				Attrib_Set(entity, "dmg taken increased", 0.0);
				Attrib_Set(entity, "dmg penalty vs buildings", 0.0);
				Attrib_Set(entity, "no_duck", 1.0);
				Attrib_Set(entity, "voice pitch scale", 0.0);
			}

			CreateTeutonItem(client, "tf_wearable", 30969, true);
		}
	}
	return Plugin_Continue;
}

static int CreateTeutonItem(int client, const char[] classname, int index, bool wearable)
{
	int entity = CreateEntityByName(classname);
	if(entity != -1)
	{
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(entity, Prop_Send, "m_bInitialized", true);

		char netclass[32];
		GetEntityNetClass(entity, netclass, sizeof(netclass));
		SetEntData(entity, FindSendPropInfo(netclass, "m_iEntityQuality"), 6);
		SetEntData(entity, FindSendPropInfo(netclass, "m_iEntityLevel"), 5);

		SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
		SetEntProp(entity, Prop_Send, "m_iEntityLevel", 5);
		
		DispatchSpawn(entity);

		if(wearable)
		{
			TF2U_EquipPlayerWearable(client, entity);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);
			EquipPlayerWeapon(client, entity);
		}
		
		int offset = FindSendPropInfo(netclass, "m_iItemIDHigh");
		
		SetEntData(entity, offset - 8, 0);	// m_iItemID
		SetEntData(entity, offset - 4, 0);	// m_iItemID
		SetEntData(entity, offset, 0);		// m_iItemIDHigh
		SetEntData(entity, offset + 4, 0);	// m_iItemIDLow
		
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));

		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, _, _, _, 128);
	}
	return entity;
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