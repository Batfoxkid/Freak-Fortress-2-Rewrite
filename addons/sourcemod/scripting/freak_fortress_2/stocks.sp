/*
	void RegFreakCmd(const char[] cmd, ConCmd callback, const char[] description = NULL_STRING, int flags = 0)
	SectionType GetSectionType(const char[] buffer)
	int FindClientOfBossIndex(int boss = 0)
	TFClassType GetClassOfName(const char[] buffer)
	void GetClassWeaponClassname(TFClassType class, char[] name, int length)
	int TotalPlayersAlive()
	int GetKillsOfWeaponRank(int rank = -1, int index = 0)
	int GetKillsOfCosmeticRank(int rank = -1, int index = 0)
	void ShowGameText(int client, const char[] icon = "leaderboard_streak", int color = 0, const char[] buffer, any ...)
	void ApplyAllyHealEvent(int healer, int patient, int amount)
	void ApplySelfHealEvent(int entindex, int amount)
	int DamageGoal(int goal, int current, int last)
	bool TF2_GetItem(int client, int &weapon, int &pos)
	void TF2_RemoveItem(int client, int weapon)
	void TF2_RemoveAllItems(int client)
	bool IsInvuln(int client)
	bool TF2_IsCritBoosted(int client)
	int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
	bool GetControlPoint()
	void SetControlPoint(bool enable)
	void SetArenaCapEnableTime(float time)
	int GetRoundStatus()
	void ScreenShake(const float pos[3], float amplitude, float frequency, float duration, float radius)
	void FPrintToChat(int client, const char[] message, any ...)
	void FPrintToChatEx(int client, int author, const char[] message, any ...)
	void FPrintToChatAll(const char[] message, any ...)
	void FReplyToCommand(int client, const char[] message, any ...)
	void FShowActivity(int client, const char[] message, any ...)
	void PrintSayText2(int client, int author, bool chat = true, const char[] message, const char[] param1 = NULL_STRING, const char[] param2 = NULL_STRING, const char[] param3 = NULL_STRING, const char[] param4 = NULL_STRING)
	void Debug(const char[] buffer, any ...)
	any Min(any value, any min)
	any Max(any value, any max)
	any Clamp(any value, any min, any max)
*/

#pragma semicolon 1
#pragma newdecls required

void RegFreakCmd(const char[] cmd, ConCmd callback, const char[] description = NULL_STRING, int flags = 0)
{
	static const char Prefixes[][] = { "ff2_", "ff2", "hale_", "hale", "vsh_", "vsh", "pony_", "pony" };
	
	int length = strlen(cmd)+6;
	char[] command = new char[length];
	for(int i; i < sizeof(Prefixes); i++)
	{
		Format(command, length, "%s%s", Prefixes[i], cmd);
		RegConsoleCmd(command, callback, description, i ? flags|FCVAR_HIDDEN : flags);
	}
}

SectionType GetSectionType(const char[] buffer)
{
	if(!StrContains(buffer, "sound_") || !StrContains(buffer, "catch_"))
		return Section_Sound;

	if(StrEqual(buffer, "precache"))
		return Section_Precache;

	if(StrEqual(buffer, "mod_download"))
		return Section_Model;

	if(StrEqual(buffer, "mod_precache"))
		return Section_ModCache;

	if(StrEqual(buffer, "mat_download"))
		return Section_Material;

	if(StrEqual(buffer, "download"))
		return Section_Download;

	if(!StrContains(buffer, "map_"))
		return Section_Map;

	if(!StrContains(buffer, "weapon") || !StrContains(buffer, "wearable") || !StrContains(buffer, "tf_") || StrEqual(buffer, "saxxy"))
		return Section_Weapon;

	return Section_Ability;
}

int FindClientOfBossIndex(int boss = 0)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(Client(client).Index == boss)
		{
			if(IsClientInGame(client))
				return client;
			
			Client(client).Index = -1;
			break;
		}
	}
	return -1;
}

TFClassType GetClassOfName(const char[] buffer)
{
	TFClassType class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
		class = TF2_GetClass(buffer);
	
	return class;
}

void GetClassWeaponClassname(TFClassType class, char[] name, int length)
{
	if(!StrContains(name, "saxxy"))
	{ 
		switch(class)
		{
			case TFClass_Scout:	strcopy(name, length, "tf_weapon_bat");
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_fireaxe");
			case TFClass_DemoMan:	strcopy(name, length, "tf_weapon_bottle");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_fists");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_wrench");
			case TFClass_Medic:	strcopy(name, length, "tf_weapon_bonesaw");
			case TFClass_Sniper:	strcopy(name, length, "tf_weapon_club");
			case TFClass_Spy:	strcopy(name, length, "tf_weapon_knife");
			default:		strcopy(name, length, "tf_weapon_shovel");
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun"))
	{
		switch(class)
		{
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_shotgun_pyro");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_shotgun_hwg");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_shotgun_primary");
			default:		strcopy(name, length, "tf_weapon_shotgun_soldier");
		}
	}
}

int TotalPlayersAlive()
{
	int amount = PlayersAlive[TFTeam_Red] + PlayersAlive[TFTeam_Blue];
	if(Cvar[SpecTeam].BoolValue)
		amount += PlayersAlive[TFTeam_Unassigned] + PlayersAlive[TFTeam_Spectator];
	
	return amount;
}

int GetKillsOfWeaponRank(int rank = -1, int index = 0)
{
	switch(rank)
	{
		case 0:
		{
			return GetRandomInt(0, 9);
		}
		case 1:
		{
			return GetRandomInt(10, 24);
		}
		case 2:
		{
			return GetRandomInt(25, 44);
		}
		case 3:
		{
			return GetRandomInt(45, 69);
		}
		case 4:
		{
			return GetRandomInt(70, 99);
		}
		case 5:
		{
			return GetRandomInt(100, 134);
		}
		case 6:
		{
			return GetRandomInt(135, 174);
		}
		case 7:
		{
			return GetRandomInt(175, 224);
		}
		case 8:
		{
			return GetRandomInt(225, 274);
		}
		case 9:
		{
			return GetRandomInt(275, 349);
		}
		case 10:
		{
			return GetRandomInt(350, 499);
		}
		case 11:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(500, 748);
			}
			else
			{
				return GetRandomInt(500, 749);
			}
		}
		case 12:
		{
			if(index == 656)	// Holiday Punch
			{
				return 749;
			}
			else
			{
				return GetRandomInt(750, 998);
			}
		}
		case 13:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(750, 999);
			}
			else
			{
				return 999;
			}
		}
		case 14:
		{
			return GetRandomInt(1000, 1499);
		}
		case 15:
		{
			return GetRandomInt(1500, 2499);
		}
		case 16:
		{
			return GetRandomInt(2500, 4999);
		}
		case 17:
		{
			return GetRandomInt(5000, 7499);
		}
		case 18:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(7500, 7922);
			}
			else
			{
				return GetRandomInt(7500, 7615);
			}
		}
		case 19:
		{
			if(index == 656)	// Holiday Punch
			{
				return GetRandomInt(7923, 8499);
			}
			else
			{
				return GetRandomInt(7616, 8499);
			}
		}
		case 20:
		{
			return GetRandomInt(8500, 9999);
		}
		default:
		{
			return GetRandomInt(0, 9999);
		}
	}
}

int GetKillsOfCosmeticRank(int rank = -1, int index = 0)
{
	switch(rank)
	{
		case 0:
		{
			if(index == 133 || index == 444 || index == 655)	// Gunboats, Mantreads, or Spirit of Giving
			{
				return 0;
			}
			else
			{
				return GetRandomInt(0, 14);
			}
		}
		case 1:
		{
			if(index == 133 || index == 444 || index == 655)	// Gunboats, Mantreads, or Spirit of Giving
			{
				return GetRandomInt(1, 2);
			}
			else
			{
				return GetRandomInt(15, 29);
			}
		}
		case 2:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(3, 4);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(3, 6);
			}
			else
			{
				return GetRandomInt(30, 49);
			}
		}
		case 3:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(5, 6);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(7, 11);
			}
			else
			{
				return GetRandomInt(50, 74);
			}
		}
		case 4:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(7, 9);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(12, 19);
			}
			else
			{
				return GetRandomInt(75, 99);
			}
		}
		case 5:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(10, 13);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(20, 27);
			}
			else
			{
				return  GetRandomInt(100, 134);
			}
		}
		case 6:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(14, 17);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(28, 36);
			}
			else
			{
				return GetRandomInt(135, 174);
			}
		}
		case 7:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(18, 22);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(37, 46);
			}
			else
			{
				return GetRandomInt(175, 249);
			}
		}
		case 8:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(23, 27);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(47, 56);
			}
			else
			{
				return GetRandomInt(250, 374);
			}
		}
		case 9:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(28, 34);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(57, 67);
			}
			else
			{
				return GetRandomInt(375, 499);
			}
		}
		case 10:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(35, 49);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(68, 78);
			}
			else
			{
				return GetRandomInt(500, 724);
			}
		}
		case 11:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(50, 74);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(79, 90);
			}
			else
			{
				return GetRandomInt(725, 999);
			}
		}
		case 12:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(75, 98);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(91, 103);
			}
			else
			{
				return GetRandomInt(1000, 1499);
			}
		}
		case 13:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return 99;
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(104, 119);
			}
			else
			{
				return GetRandomInt(1500, 1999);
			}
		}
		case 14:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(100, 149);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(120, 137);
			}
			else
			{
				return GetRandomInt(2000, 2749);
			}
		}
		case 15:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(150, 249);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(138, 157);
			}
			else
			{
				return GetRandomInt(2750, 3999);
			}
		}
		case 16:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(250, 499);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(158, 178);
			}
			else
			{
				return GetRandomInt(4000, 5499);
			}
		}
		case 17:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(500, 749);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(179, 209);
			}
			else
			{
				return GetRandomInt(5500, 7499);
			}
		}
		case 18:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(750, 783);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(210, 249);
			}
			else
			{
				return GetRandomInt(7500, 9999);
			}
		}
		case 19:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(784, 849);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(250, 299);
			}
			else
			{
				return GetRandomInt(10000, 14999);
			}
		}
		case 20:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(850, 999);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(300, 399);
			}
			else
			{
				return GetRandomInt(15000, 19999);
			}
		}
		default:
		{
			if(index == 133 || index == 444)	// Gunboats or Mantreads
			{
				return GetRandomInt(0, 999);
			}
			else if(index == 655)	// Spirit of Giving
			{
				return GetRandomInt(0, 399);
			}
			else
			{
				return GetRandomInt(0, 19999);
			}
		}
	}
}

void ShowGameText(int client, const char[] icon = "leaderboard_streak", int color = 0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(client)
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	
	if(bf)
	{
		char message[512];
		SetGlobalTransTarget(client);
		VFormat(message, sizeof(message), buffer, 5);
		CRemoveTags(message, sizeof(message));
		
		bf.WriteString(message);
		bf.WriteString(icon);
		bf.WriteByte(color);
		EndMessage();
	}
}

void ApplyAllyHealEvent(int healer, int patient, int amount)
{
	Event event = CreateEvent("player_healed", true);

	event.SetInt("healer", healer);
	event.SetInt("patient", patient);
	event.SetInt("amount", amount);

	event.Fire();
}

void ApplySelfHealEvent(int entindex, int amount)
{
	Event event = CreateEvent("player_healonhit", true);

	event.SetInt("entindex", entindex);
	event.SetInt("amount", amount);

	event.Fire();
}

int DamageGoal(int goal, int current, int last)
{
	return (current / goal) - (last / goal);
}

bool TF2_GetItem(int client, int &weapon, int &pos)
{
	//TODO: Find out if we need to check m_bDisguiseWeapon
	
	static int maxWeapons;
	if(!maxWeapons)
		maxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(pos < 0)
		pos = 0;
	
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;
		
		if(weapon != -1)
			return true;
	}
	return false;
}

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

void TF2_RemoveAllItems(int client)
{
	int entity, i;
	while(TF2_GetItem(client, entity, i))
	{
		TF2_RemoveItem(client, entity);
	}
}

bool IsInvuln(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

bool TF2_IsCritBoosted(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) ||
			TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) ||
			TF2_IsPlayerInCondition(client, TFCond_CritCanteen) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnWin) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnKill) ||
			TF2_IsPlayerInCondition(client, TFCond_CritMmmph) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) ||
			TF2_IsPlayerInCondition(client, TFCond_CritRuneTemp));
}

int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
{
	if(StrContains(classname, "tf_weapon_"))
	{
		return -1;
	}
	else if(!StrContains(classname, "tf_weapon_scattergun") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_primary") ||
	  !StrContains(classname, "tf_weapon_soda_popper") ||
	  !StrContains(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	  !StrContains(classname, "tf_weapon_particle_cannon") ||
	  !StrContains(classname, "tf_weapon_flamethrower") ||
	  !StrContains(classname, "tf_weapon_grenadelauncher") ||
	  !StrContains(classname, "tf_weapon_cannon") ||
	  !StrContains(classname, "tf_weapon_minigun") ||
	  !StrContains(classname, "tf_weapon_shotgun_primary") ||
	  !StrContains(classname, "tf_weapon_sentry_revenge") ||
	  !StrContains(classname, "tf_weapon_drg_pomson") ||
	  !StrContains(classname, "tf_weapon_shotgun_building_rescue") ||
	  !StrContains(classname, "tf_weapon_syringegun_medic") ||
	  !StrContains(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	  !StrContains(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_secondary") ||
	  !StrContains(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	  !StrContains(classname, "tf_weapon_buff_item") ||
	  !StrContains(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	  !StrContains(classname, "tf_weapon_laser_pointer") ||
	  !StrContains(classname, "tf_weapon_mechanical_arm") ||
	  !StrContains(classname, "tf_weapon_medigun") ||
	  !StrContains(classname, "tf_weapon_smg") ||
	  !StrContains(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_re"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

bool GetControlPoint()
{
	int entity = MaxClients + 1;
	while((entity = FindEntityByClassname(entity, "team_control_point")) != -1)
	{
		if(GetEntProp(entity, Prop_Data, "m_bLocked"))
			return false;
	}
	return true;
}

void SetControlPoint(bool enable)
{
	if(enable)
	{
		Debug("Unlocked Control Point");
		
		int entity = FindEntityByClassname(-1, "tf_logic_arena");
		if(entity != -1)
			FireEntityOutput(entity, "OnCapEnabled", entity);
		
		entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "team_control_point")) != -1)
		{
			AcceptEntityInput(entity, "ShowModel");
			SetVariantInt(0);
			AcceptEntityInput(entity, "SetLocked");
		}
	}
	else
	{
		Debug("Locked Control Point");
		
		int entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "team_control_point")) != -1)
		{
			AcceptEntityInput(entity, "HideModel");
			SetVariantInt(1);
			AcceptEntityInput(entity, "SetLocked");
		}
	}
}

void SetArenaCapEnableTime(float time)
{
	Debug("Set unlock time to: %f", time);
	
	int entity = FindEntityByClassname(-1, "tf_logic_arena");
	if(entity != -1)
		DispatchKeyValueFloat(entity, "CapEnableDelay", time);
}

int GetRoundStatus()
{
	if(RoundStatus || Enabled)
		return RoundStatus;
	
	if(GameRules_GetProp("m_bInSetup", 1))
		return 0;
	
	return 1;
}

void ScreenShake(const float pos[3], float amplitude, float frequency, float duration, float radius)
{
	int entity = CreateEntityByName("env_shake");
	if(entity != -1)
	{
		DispatchKeyValueFloat(entity, "amplitude", amplitude);
		DispatchKeyValueFloat(entity, "radius", radius);
		DispatchKeyValueFloat(entity, "duration", duration);
		DispatchKeyValueFloat(entity, "frequency", frequency);
		
		DispatchSpawn(entity);
		
		TeleportEntity(entity, pos);
		AcceptEntityInput(entity, "StartShake");
		
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1,0,1", duration + 0.1);
		SetVariantString(buffer);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

void FPrintToChat(int client, const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	CReplaceColorCodes(buffer2);
	CSendMessage(client, buffer2);
}

void FPrintToChatEx(int client, int author, const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2, author);
	CSendMessage(client, buffer2, author);
}

void FPrintToChatAll(const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || CSkipList[i])
		{
			CSkipList[i] = false;
			continue;
		}
		
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 2);
		CReplaceColorCodes(buffer2);
		CSendMessage(i, buffer2);
	}
}

void FReplyToCommand(int client, const char[] message, any ...)
{
	char buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "[FF2] %s", buffer);
	}
	else
	{
		FPrintToChat(client, "%s", buffer);
	}
}

void FShowActivity(int client, const char[] message, any ...)
{
	char tag[MAX_BUFFER_LENGTH], buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	Format(tag, sizeof(tag), "%t", "Prefix");
	CShowActivity2(client, tag, "%s", buffer);
}

void PrintSayText2(int client, int author, bool chat = true, const char[] message, const char[] param1 = NULL_STRING, const char[] param2 = NULL_STRING, const char[] param3 = NULL_STRING, const char[] param4 = NULL_STRING)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)); 
	
	bf.WriteByte(author);
	bf.WriteByte(chat);
	
	bf.WriteString(message); 
	
	bf.WriteString(param1); 
	bf.WriteString(param2); 
	bf.WriteString(param3);
	bf.WriteString(param4);
	
	EndMessage();
}

void Debug(const char[] buffer, any ...)
{
	if(Cvar[Debugging].BoolValue)
	{
		char message[192];
		VFormat(message, sizeof(message), buffer, 2);
		CPrintToChatAll("{olive}[FF2 {darkorange}DEBUG{olive}]{default} %s", message);
		PrintToServer("[FF2 DEBUG] %s", message);
	}
}

any Min(any value, any min)
{
	if(value < min)
		return min;
	
	return value;
}

stock any Max(any value, any max)
{
	if(value > max)
		return max;
	
	return value;
}

any Clamp(any value, any min, any max)
{
	if(value > max)
		return max;
	
	if(value < min)
		return min;
	
	return value;
}