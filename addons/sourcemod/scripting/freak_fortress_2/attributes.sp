/*
	void Attributes_PluginStart()
	bool Attributes_OnBackstabBoss(int client, int victim, float &damage, int weapon)
	void Attributes_OnHitBossPre(int client, int victim, float damage, int &damagetype, int weapon)
	void Attributes_OnHitBoss(int client, int victim, int inflictor, float fdamage, int weapon, int damagecustom)
	float Attributes_FindOnPlayer(int client, int index, bool multi=false, float defaul=0.0)
	float Attributes_FindOnWeapon(int client, int entity, int index, bool multi=false, float defaul=0.0)
*/

static float JarateDamage[MAXTF2PLAYERS];
static int JarateApplyer[MAXTF2PLAYERS];
static float MarkDamage[MAXTF2PLAYERS];
static int MarkApplyer[MAXTF2PLAYERS];

void Attributes_PluginStart()
{
	HookUserMessage(GetUserMessageId("PlayerJarated"), Attributes_OnJarateBoss);
}

public Action Attributes_OnJarateBoss(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int attacker = bf.ReadByte();
	int victim = bf.ReadByte();
	if(Client(victim).IsBoss)
	{
		if(Attributes_FindOnPlayer(attacker, 387))	// rage on kill
		{
			float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") + 0.115;
			if(rage > 100.0)
				rage = 100.0;
			
			SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
		}
		
		int weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Secondary);
		if(weapon > MaxClients)
		{
			char classname[36];
			if(GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				if(StrEqual(classname, "tf_weapon_jar"))
				{
					if(JarateDamage[victim] < 0.0)
						JarateDamage[victim] = 0.0;
					
					JarateDamage[victim] += 600.0;
					JarateApplyer[victim] = attacker;
				}
				else if(StrEqual(classname, "tf_weapon_jar_milk"))
				{
					TF2_RemoveCondition(victim, TFCond_Milked);
					TF2_AddCondition(victim, TFCond_Milked, 5.0, attacker);
				}
			}
		}
	}
	return Plugin_Continue;
}

bool Attributes_OnBackstabBoss(int client, int victim, float &damage, int weapon)
{
	if(Attributes_FindOnPlayer(client, 166))	// add cloak on hit
	{
		// Nerfs the insane power of the L'Etranger
		SetEntPropFloat(client, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);
	}
	
	if(Attributes_FindOnWeapon(client, weapon, 217))	// sanguisuge
	{
		int maxoverheal = SDKCall_GetMaxHealth(client) * 7 / 2;	// 250% overheal (from 200% overheal)
		int health = GetClientHealth(health);
		if(health < maxoverheal)
		{
			SetEntityHealth(client, maxoverheal);
			ApplySelfHealEvent(client, maxoverheal - health);
			
			if(TF2_IsPlayerInCondition(client, TFCond_OnFire))
				TF2_RemoveCondition(client, TFCond_OnFire);
			
			if(TF2_IsPlayerInCondition(client, TFCond_Bleeding))
				TF2_RemoveCondition(client, TFCond_Bleeding);
			
			if(TF2_IsPlayerInCondition(client, TFCond_Plague))
				TF2_RemoveCondition(client, TFCond_Plague);
		}
	}
	
	float value = Attributes_FindOnPlayer(client, 296);	// sapper kills collect crits
	if(value)
		SetEntProp(client, Prop_Send, "m_iRevengeCrits", GetEntProp(client, Prop_Send, "m_iRevengeCrits")+RoundFloat(value));
	
	int assister = -1;
	for(int i=1; i<=MaxClients; i++)
	{
		if(client != i && IsClientInGame(i) && IsPlayerAlive(i))
		{
			int entity = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
			if(entity > MaxClients &&
			   HasEntProp(entity, Prop_Send, "m_bHealing") &&
			   GetEntProp(entity, Prop_Send, "m_bHealing") &&
			   GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget") == client)
			{
				assister = i;
				break;
			}
		}
	}
	
	bool silent = view_as<bool>(Attributes_FindOnWeapon(client, weapon, 217));
	
	Event event = CreateEvent("player_death", true);
	
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("attacker", GetClientUserId(client));
	event.SetInt("assister", assister == -1 ? assister : GetClientUserId(assister));
	event.SetInt("weaponid", weapon);
	event.SetString("weapon", "backstab");
	event.SetString("weapon_logclassname", "ff2_notice");
	event.SetInt("customkill", TF_CUSTOM_BACKSTAB);
	event.SetInt("crit_type", 2);
	
	int stabs = ++Client(client).Stabs;
	event.SetInt("kill_streak_total", stabs);
	event.SetInt("kill_streak_wep", stabs);
	
	int team = GetClientTeam(client);
	for(int i=1; i<=MaxClients; i++)
	{
		if(i == client || i == assister || (!silent && i == victim) || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
			event.FireToClient(i);
	}
	
	event.Cancel();
	return silent;
}

void Attributes_OnHitBossPre(int client, int victim, float damage, int &damagetype, int weapon)
{
	if((TF2_IsPlayerInCondition(client, TFCond_BlastJumping) && Attributes_FindOnWeapon(client, weapon, 621)) ||	// rocketjump attackrate bonus
	   (TF2_IsPlayerInCondition(client, TFCond_DisguiseRemoved) && Attributes_FindOnWeapon(client, weapon, 410))) 	// damage bonus while disguised
	{
		TF2_AddCondition(client, TFCond_MiniCritOnKill, 0.001);
	}
	
	if(weapon > MaxClients)
	{
		if(Attributes_FindOnWeapon(client, weapon, 44))	// scattergun has knockback
		{
			// Force-a-Nature gets slower the more times it hits
			Address address = TF2Attrib_GetByDefIndex(weapon, 96);
			if(address == Address_Null)
			{
				TF2Attrib_SetByDefIndex(weapon, 96, 0.98);
				SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			}
			else
			{
				TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) + 0.02);
				TF2Attrib_SetByDefIndex(weapon, 403, view_as<float>(222153573));	// Update attribute
			}
		}
		
		if(damage > 5.0 && Attributes_FindOnWeapon(client, weapon, 416))	// mod flaregun fires pellets with knockback
		{
			// Scorch Shot gets slower the more times it hits
			Address address = TF2Attrib_GetByDefIndex(weapon, 5);
			if(address == Address_Null)
			{
				TF2Attrib_SetByDefIndex(weapon, 5, 1.0);
				SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			}
			else
			{
				TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) + 0.025);
				TF2Attrib_SetByDefIndex(weapon, 403, view_as<float>(222153573));	// Update attribute
			}
		}
		
		char classname[36];
		if(GetEntityClassname(weapon, classname, sizeof(classname)))
		{
			if(StrEqual(classname, "tf_wepaon_cannon"))
			{
				// Loose Cannon gets slower the more times it hits
				Address address = TF2Attrib_GetByDefIndex(weapon, 96);
				if(address == Address_Null)
				{
					TF2Attrib_SetByDefIndex(weapon, 96, 0.98);
					SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
				}
				else
				{
					TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) + 0.02);
					TF2Attrib_SetByDefIndex(weapon, 403, view_as<float>(222153573));	// Update attribute
				}
			}
			else if(StrEqual(classname, "tf_wepaon_stickbomb"))
			{
				// Ullapool Caber gets a critical explosion
				if(!GetEntProp(weapon, Prop_Send, "m_iDetonated"))
				{
					Bosses_PlaySoundToAll(victim, "sound_cabered", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
					damagetype |= DMG_CRIT;
				}
			}
		}
	}
}

void Attributes_OnHitBoss(int client, int victim, float fdamage, int weapon, int damagecustom)
{
	char classname[36];
	int slot = TFWeaponSlot_Building;
	if(weapon > MaxClients)
	{
		if(GetEntityClassname(weapon, classname, sizeof(classname)))
		{
			slot = TF2_GetClassnameSlot(classname);
			if(slot > TFWeaponSlot_Grenade)
				slot = TFWeaponSlot_Grenade;
		}
	}
	
	int lastPlayerDamage = Client(client).Damage;
	int lastWeaponDamage = Client(client).GetDamage(slot);
	
	int idamage = RoundFloat(fdamage);
	Client(client).Damage = lastPlayerDamage + idamage;
	Client(client).SetDamage(slot, lastWeaponDamage + idamage);
	
	float value = Attributes_FindOnPlayer(client, 203);	// drop health pack on kill
	if(value > 0.0)
	{
		int amount = DamageGoal(RoundFloat(270.0 / value), Client(client).Damage, lastPlayerDamage);
		if(amount)
		{
			float position[3];
			GetClientAbsOrigin(victim, position);
			position[2] += 20.0;
			
			float velocity[3];
			velocity[2] = 50.0;
			
			int team = GetClientTeam(client);  
			for(int i; i<amount; i++)
			{
				int entity = CreateEntityByName("item_healthkit_small");
				if(IsValidEntity(entity))
				{
					DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
					SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
					velocity[0] = GetRandomFloat(-10.0, 10.0);
					velocity[1] = GetRandomFloat(-10.0, 10.0);
					TeleportEntity(entity, position, NULL_VECTOR, velocity);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				}
			}
		}
	}
	
	if(Attributes_FindOnPlayer(client, 387))	// rage on kill
	{
		float rage = 33.34;
		if(slot != TFWeaponSlot_Primary)
			rage = fdamage / 3.8993;	// 33.34% every 130 damage
		
		rage += GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
		if(rage > 100.0)
			rage = 100.0;
		
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rage);
	}
	
	if(Attributes_FindOnPlayer(client, 418) > 0.0)	// boost on damage
	{
		DataPack pack = new DataPack();
		if(Enabled)
		{
			CreateDataTimer(0.1, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteFloat(fdamage / 1000.0);
		}
		else
		{
			CreateDataTimer(0.5, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteFloat(fdamage / 2.0);
		}
	}
	
	if(Attributes_FindOnWeapon(client, weapon, 30))	// fists have radial buff
	{
		int entity;
		float pos1[3], pos2[3];
		GetClientAbsOrigin(client, pos1);
		for(int target=1; target<=MaxClients; target++)
		{
			if(client!=target && IsClientInGame(target) && IsPlayerAlive(target))
			{
				GetClientAbsOrigin(target, pos2);
				if(GetVectorDistance(pos1, pos2, true) < 160000)
				{
					int maxhealth = SDKCall_GetMaxHealth(client);
					int health = GetClientHealth(health);
					if(health < maxhealth)
					{
						if(health+50 > maxhealth)
						{
							SetEntityHealth(target, maxhealth);
							ApplyAllyHealEvent(client, target, maxhealth - health);
							ApplySelfHealEvent(target, maxhealth - health);
						}
						else
						{
							SetEntityHealth(target, health + 50);
							ApplyAllyHealEvent(client, target, 50);
							ApplySelfHealEvent(target, 50);
						}
					}
					
					Client(client).Assist += 50;
					
					int i;
					while(TF2_GetItem(target, entity, i))
					{
						Address attrib = TF2Attrib_GetByDefIndex(entity, 28);
						if(attrib != Address_Null)
						{
							TF2Attrib_SetValue(attrib, TF2Attrib_GetValue(attrib)*1.1);
							TF2Attrib_SetByDefIndex(entity, 403, view_as<float>(222153573));	// Update attribute
						}
						else
						{
							TF2Attrib_SetByDefIndex(entity, 28, 1.1);
							SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
						}
					}
				}
			}
		}
	}

	value = Attributes_FindOnWeapon(client, weapon, 31);	// critboost on kill
	if(value)
		TF2_AddCondition(client, TFCond_CritOnKill, value);
	
	value = Attributes_FindOnWeapon(client, weapon, 158);	// add cloak on kill
	if(value)
	{
		float cloak = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") + value*100.0;
		if(cloak > 100)
		{
			cloak = 100.0;
		}
		else if(cloak < 0.0)
		{
			cloak = 0.0;
		}
		
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloak);
	}
	
	if(Attributes_FindOnWeapon(client, weapon, 175))	// jarate duration
	{
		JarateApplyer[victim] = client;
	}
	else if(TF2_IsPlayerInCondition(victim, TFCond_Jarated))
	{
		JarateDamage[victim] -= fdamage;
		if(JarateApplyer[victim])
			Client(JarateApplyer[victim]).Assist += fdamage * 0.35;
		
		if(JarateDamage[victim] <= 0.0)
			TF2_RemoveCondition(victim, TFCond_Jarated);
	}
	else if(Attributes_FindOnWeapon(client, weapon, 218))	// mark for death
	{
		MarkApplyer[victim] = client;
	}
	else if(TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath))
	{
		MarkDamage[victim] -= fdamage;
		if(MarkApplyer[victim])
			Client(MarkApplyer[victim]).Assist += fdamage * 0.35;
		
		if(MarkDamage[victim] <= 0.0)
			TF2_RemoveCondition(victim, TFCond_MarkedForDeath);
	}
	
	value = Attributes_FindOnWeapon(client, weapon, 180);	// heal on kill
	if(value)
	{
		int maxhealth = SDKCall_GetMaxHealth(client);
		int health = GetClientHealth(health);
		if(health < maxhealth)
		{
			int healing = RoundFloat(value);
			if(health + healing > maxhealth)
			{
				SetEntityHealth(client, maxhealth);
				ApplySelfHealEvent(client, maxhealth - health);
			}
			else
			{
				SetEntityHealth(client, health + healing);
				ApplySelfHealEvent(client, healing);
			}
		}
	}
	
	value = Attributes_FindOnWeapon(client, weapon, 220);
	if(value)	// restore health on kill
	{
		int maxhealth = SDKCall_GetMaxHealth(client);
		int health = GetClientHealth(health);
		
		int maxoverheal = maxhealth * 7 / 4;	// 75% overheal
		if(health < maxoverheal)
		{
			int healing = RoundFloat(float(maxhealth) * value / 100.0);
			
			if(health + healing > maxoverheal)
			{
				SetEntityHealth(client, maxoverheal);
				ApplySelfHealEvent(client, maxoverheal - health);
			}
			else
			{
				SetEntityHealth(client, health + healing);
				ApplySelfHealEvent(client, healing);
			}
		}
	}
	
	if(weapon > MaxClients && Attributes_FindOnWeapon(client, weapon, 226))	// honorbound
	{
		SetEntProp(weapon, Prop_Send, "m_bIsBloody", true);
		SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy")+1);
	}
	
	if(Attributes_FindOnWeapon(client, weapon, 292) == 6.0)	// Eyelander
	{
		SetEntProp(client, Prop_Send, "m_iDecapitations", GetEntProp(client, Prop_Send, "m_iDecapitations")+1);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		TF2_AddCondition(client, TFCond_DemoBuff);
		
		int maxoverheal = SDKCall_GetMaxHealth(client) * 7 / 4;	// 75% overheal
		int health = GetClientHealth(health);
		if(health < maxoverheal)
		{
			if(health + 15 > maxoverheal)
			{
				SetEntityHealth(client, maxoverheal);
				ApplySelfHealEvent(client, maxoverheal - health);
			}
			else
			{
				SetEntityHealth(client, health + 15);
				ApplySelfHealEvent(client, 15);
			}
		}
	}
	
	if(Attributes_FindOnWeapon(client, weapon, 409))	// kill forces attacker to laugh
		TF2_StunPlayer(client, 2.0, 1.0, TF_STUNFLAGS_NORMALBONK);

	value = Attributes_FindOnWeapon(client, weapon, 613);	// minicritboost on kill
	if(value)
		TF2_AddCondition(client, TFCond_MiniCritOnKill, value);

	if(Attributes_FindOnWeapon(client, weapon, 644))	// clipsize increase on kill
	{
		int amount = DamageGoal(375, Client(client).GetDamage(slot), lastWeaponDamage);
		if(amount)
			SetEntProp(client, Prop_Send, "m_iDecapitations", GetEntProp(client, Prop_Send, "m_iDecapitations")+amount);
	}
	
	value = Attributes_FindOnWeapon(client, weapon, 736);	// speed_boost_on_kill
	if(value)
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, value);
	
	if(Attributes_FindOnWeapon(client, weapon, 807))	// add_head_on_kill
		SetEntProp(client, Prop_Send, "m_iDecapitations", GetEntProp(client, Prop_Send, "m_iDecapitations")+1);
	
	if(damagecustom == TF_CUSTOM_HEADSHOT && StrEqual(classname, "tf_weapon_sniperrifle_decap")) // Bazaar Bargain
		SetEntProp(client, Prop_Send, "m_iDecapitations", GetEntProp(client, Prop_Send, "m_iDecapitations")+1);
	
	int amount = DamageGoal(450, Client(client).GetDamage(slot), lastWeaponDamage);
	if(amount)
	{
		if(slot == TFWeaponSlot_Building)
		{
			weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Grenade);
			slot = TFWeaponSlot_Grenade;
		}
		
		if(Attributes_FindOnWeapon(client, weapon, 2025))	// killstreak tier
		{
			int lastStreak = GetEntProp(client, Prop_Send, "m_nStreaks", _, slot);
			int streak = lastStreak + amount;
			SetEntProp(client, Prop_Send, "m_nStreaks", streak, _, slot);
			Debug("%d -> %d", lastStreak, streak);
			
			int total = streak;
			for(int i; i<4; i++)
			{
				if(i != slot)
					total += GetEntProp(client, Prop_Send, "m_nStreaks", _, i);
			}
			
			if(DamageGoal(5, streak, lastStreak))
			{
				Event event = CreateEvent("player_death", true);
				
				event.SetInt("userid", GetClientUserId(victim));
				event.SetInt("attacker", GetClientUserId(client));
				event.SetInt("weaponid", weapon);
				event.SetInt("kill_streak_total", total);
				event.SetInt("kill_streak_wep", streak);
				event.SetInt("crit_type", streak > 10);
				event.SetString("weapon_logclassname", "ff2_killstreak");
				
				if(weapon > MaxClients)
				{
					char buffer[32];
					if(TFED_GetItemDefinitionString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), "item_iconname", buffer, sizeof(buffer)))
						event.SetString("weapon", buffer);
				}
				
				int team = GetClientTeam(client);
				for(int i=1; i<=MaxClients; i++)
				{
					if(i == client || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
						event.FireToClient(i);
				}
				
				event.Cancel();
			}
		}
		else if(damagecustom != TF_CUSTOM_BACKSTAB && damagecustom != TF_CUSTOM_TELEFRAG && DamageGoal(2250, Client(client).GetDamage(slot), lastWeaponDamage))
		{
			int total;
			for(int i; i<4; i++)
			{
				total += GetEntProp(client, Prop_Send, "m_nStreaks", _, i);
			}
			
			Event event = CreateEvent("player_death", true);
			
			event.SetInt("userid", GetClientUserId(victim));
			event.SetInt("attacker", GetClientUserId(client));
			event.SetInt("weaponid", weapon);
			event.SetInt("kill_streak_total", total);
			event.SetInt("kill_streak_wep", 0);
			event.SetInt("crit_type", 0);
			event.SetString("weapon_logclassname", "ff2_killstreak");
			
			if(weapon > MaxClients)
			{
				char buffer[32];
				if(TFED_GetItemDefinitionString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), "item_iconname", buffer, sizeof(buffer)))
					event.SetString("weapon", buffer);
			}
			
			event.FireToClient(client);
			event.Cancel();
		}
	}
}

float Attributes_FindOnPlayer(int client, int index, bool multi=false, float defaul=0.0)
{
	float total = defaul;
	bool found = Attributes_GetByDefIndex(client, index, total);
	
	int i;
	int entity;
	float value;
	while(TF2_GetWearable(client, entity, i))
	{
		if(Attributes_GetByDefIndex(entity, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	while(TF2_GetItem(client, entity, i))
	{
		if(index != 128 && active != entity && Attributes_GetByDefIndex(entity, 128, value) && value)
			continue;
		
		if(Attributes_GetByDefIndex(entity, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

float Attributes_FindOnWeapon(int client, int entity, int index, bool multi=false, float defaul=0.0)
{
	float total = defaul;
	bool found = Attributes_GetByDefIndex(client, index, total);
	
	int i;
	int wear;
	float value;
	while(TF2_GetWearable(client, wear, i))
	{
		if(Attributes_GetByDefIndex(wear, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	if(entity > MaxClients)
	{
		if(Attributes_GetByDefIndex(entity, index, value))
		{
			if(!found)
			{
				total = value;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

bool Attributes_GetByDefIndex(int entity, int index, float &value)
{
	Address attrib = TF2Attrib_GetByDefIndex(entity, index);
	if(attrib != Address_Null)
	{
		value = TF2Attrib_GetValue(attrib);
		return true;
	}
	
	if(entity <= MaxClients)
		return false;
	
	static int indexes[20];
	static float values[20];
	int count = TF2Attrib_GetSOCAttribs(entity, indexes, values, 20);
	for(int i; i<count; i++)
	{
		if(indexes[i] == index)
		{
			value = values[i];
			return true;
		}
	}
	
	count = TF2Attrib_GetStaticAttribs(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), indexes, values, 20);
	for(int i; i<count; i++)
	{
		if(indexes[i] == index)
		{
			value = values[i];
			return true;
		}
	}
	
	return false;
}

public Action Attributes_BoostDrainStack(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client && IsPlayerAlive(client))
	{
		float hype = GetEntPropFloat(client, Prop_Send, "m_flHypeMeter") - pack.ReadFloat();
		if(hype < 0.0)
			hype = 0.0;
		
		SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", hype);
		if(Enabled || RoundActive)
			return Plugin_Continue;
	}
	return Plugin_Stop;
}

static int DamageGoal(int goal, int current, int last)
{
	return (current / goal) - (last / goal);
}