/*
	void Attributes_PluginStart()
	bool Attributes_OnBackstabBoss(int attacker, int victim, float &damage, int weapon, bool killfeed)
	void Attributes_OnHitBossPre(int attacker, int victim, int &damagetype, int weapon)
	void Attributes_OnHitBoss(int attacker, int victim, int inflictor, float fdamage, int weapon, int damagecustom)
	float Attributes_FindOnPlayer(int client, int index, bool multi = false, float defaul = 0.0)
	float Attributes_FindOnWeapon(int client, int entity, int index, bool multi = false, float defaul = 0.0)
	bool Attributes_GetByDefIndex(int entity, int index, float &value)
*/

#pragma semicolon 1

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
		if(weapon != -1)
		{
			char classname[36];
			if(GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				if(StrEqual(classname, "tf_weapon_jar"))
				{
					if(JarateDamage[victim] < 0.0)
						JarateDamage[victim] = 0.0;
					
					JarateDamage[victim] += 1500.0;
					JarateApplyer[victim] = attacker;
				}
				else if(StrEqual(classname, "tf_weapon_jar_milk"))
				{
					DataPack pack = new DataPack();
					RequestFrame(ReapplyMilk, pack);
					pack.WriteCell(GetClientUserId(victim));
					pack.WriteCell(GetClientUserId(attacker));
				}
			}
		}
	}
	return Plugin_Continue;
}

public void ReapplyMilk(DataPack pack)
{
	pack.Reset();
	
	int victim = GetClientOfUserId(pack.ReadCell());
	if(victim)
	{
		TF2_RemoveCondition(victim, TFCond_Milked);
		TF2_AddCondition(victim, TFCond_Milked, 5.0, GetClientOfUserId(pack.ReadCell()));
	}
	
	delete pack;
}

bool Attributes_OnBackstabBoss(int attacker, int victim, float &damage, int weapon, bool killfeed)
{
	if(Attributes_FindOnPlayer(attacker, 166))	// add cloak on hit
	{
		// Nerfs the insane power of the L'Etranger
		SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);
	}
	
	if(Attributes_FindOnWeapon(attacker, weapon, 217))	// sanguisuge
	{
		int maxoverheal = TF2U_GetMaxOverheal(attacker) * 2;	// 250% overheal (from 200% overheal)
		int health = GetClientHealth(attacker);
		if(health < maxoverheal)
		{
			SetEntityHealth(attacker, maxoverheal);
			ApplySelfHealEvent(attacker, maxoverheal - health);
			
			if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
				TF2_RemoveCondition(attacker, TFCond_OnFire);
			
			if(TF2_IsPlayerInCondition(attacker, TFCond_Bleeding))
				TF2_RemoveCondition(attacker, TFCond_Bleeding);
			
			if(TF2_IsPlayerInCondition(attacker, TFCond_Plague))
				TF2_RemoveCondition(attacker, TFCond_Plague);
		}
	}
	
	float value = Attributes_FindOnPlayer(attacker, 296);	// sapper kills collect crits
	if(value)
		SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+RoundFloat(value));
	
	bool silent = view_as<bool>(Attributes_FindOnWeapon(attacker, weapon, 217));
	
	if(killfeed)
	{
		int assister = -1;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(attacker != i && IsClientInGame(i) && IsPlayerAlive(i))
			{
				int entity = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
				if(entity != -1 &&
				   HasEntProp(entity, Prop_Send, "m_bHealing") &&
				   GetEntProp(entity, Prop_Send, "m_bHealing") &&
				   GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget") == attacker)
				{
					assister = i;
					break;
				}
			}
		}
		
		Event event = CreateEvent("player_death", true);
		
		event.SetInt("userid", GetClientUserId(victim));
		event.SetInt("attacker", GetClientUserId(attacker));
		event.SetInt("assister", assister == -1 ? assister : GetClientUserId(assister));
		event.SetInt("weaponid", weapon);
		event.SetString("weapon", "backstab");
		event.SetString("weapon_logclassname", "ff2_notice");
		event.SetInt("customkill", TF_CUSTOM_BACKSTAB);
		event.SetInt("crit_type", 2);
		
		int stabs = ++Client(attacker).Stabs;
		event.SetInt("kill_streak_total", stabs);
		event.SetInt("kill_streak_wep", stabs);
		
		int team = GetClientTeam(attacker);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i == attacker || i == assister || (!silent && i == victim) || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
				event.FireToClient(i);
		}
		
		event.Cancel();
	}
	return silent;
}

void Attributes_OnHitBossPre(int attacker, int victim, int &damagetype, int weapon)
{
	if((TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && Attributes_FindOnWeapon(attacker, weapon, 621)) ||	// rocketjump attackrate bonus
	   (TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved) && Attributes_FindOnWeapon(attacker, weapon, 410))) 	// damage bonus while disguised
	{
		TF2_AddCondition(attacker, TFCond_MiniCritOnKill, 0.001);
	}
	
	if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		char classname[36];
		if(GetEntityClassname(weapon, classname, sizeof(classname)))
		{
			if(StrEqual(classname, "tf_weapon_stickbomb"))
			{
				// Ullapool Caber gets a critical explosion
				if(!GetEntProp(weapon, Prop_Send, "m_iDetonated"))
				{
					damagetype |= DMG_CRIT;
					
					if(CvarSoundType.BoolValue)
					{
						Bosses_PlaySoundToAll(victim, "sound_cabered", _, _, _, _, _, 2.0);
					}
					else
					{
						Bosses_PlaySoundToAll(victim, "sound_cabered", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
				}
			}
		}
	}
}

void Attributes_OnHitBoss(int attacker, int victim, int inflictor, float fdamage, int weapon, int damagecustom)
{
	if(weapon != -1 && !HasEntProp(weapon, Prop_Send, "m_AttributeList"))
		weapon = -1;
	
	char classname[36];
	int slot = TFWeaponSlot_Building;
	if(weapon != -1)
	{
		if(GetEntityClassname(weapon, classname, sizeof(classname)))
		{
			slot = TF2_GetClassnameSlot(classname);
			if(slot > TFWeaponSlot_Grenade)
				slot = TFWeaponSlot_Grenade;
		}
	}
	
	int lastPlayerDamage = Client(attacker).Damage;
	int lastWeaponDamage = Client(attacker).GetDamage(slot);
	
	int idamage = RoundFloat(fdamage);
	Client(attacker).Damage = lastPlayerDamage + idamage;
	Client(attacker).SetDamage(slot, lastWeaponDamage + idamage);
	
	float value = Attributes_FindOnPlayer(attacker, 203);	// drop health pack on kill
	if(value > 0.0)
	{
		int amount = DamageGoal(RoundFloat(270.0 / value), Client(attacker).Damage, lastPlayerDamage);
		if(amount)
		{
			float position[3];
			GetClientAbsOrigin(victim, position);
			position[2] += 20.0;
			
			float velocity[3];
			velocity[2] = 50.0;
			
			int team = GetClientTeam(attacker);  
			for(int i; i < amount; i++)
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
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", attacker);
				}
			}
		}
	}
	
	if(Attributes_FindOnPlayer(attacker, 387))	// rage on kill
	{
		float rage = 33.34;
		if(slot != TFWeaponSlot_Primary)
			rage = fdamage / 3.8993;	// 33.34% every 130 damage
		
		rage += GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
		if(rage > 100.0)
			rage = 100.0;
		
		SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
	}
	
	if(Attributes_FindOnPlayer(attacker, 418) > 0.0)	// boost on damage
	{
		DataPack pack = new DataPack();
		if(Enabled)
		{
			CreateDataTimer(0.1, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			pack.WriteCell(GetClientUserId(attacker));
			pack.WriteFloat(fdamage / 1000.0);
		}
		else
		{
			CreateDataTimer(0.5, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(attacker));
			pack.WriteFloat(fdamage / 2.0);
		}
	}
	
	if(damagecustom != TF_CUSTOM_BURNING && damagecustom != TF_CUSTOM_BLEEDING)
	{
		if(Attributes_FindOnWeapon(attacker, weapon, 30))	// fists have radial buff
		{
			int entity;
			float pos1[3], pos2[3];
			GetClientAbsOrigin(attacker, pos1);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(attacker!=target && IsClientInGame(target) && IsPlayerAlive(target))
				{
					GetClientAbsOrigin(target, pos2);
					if(GetVectorDistance(pos1, pos2, true) < 160000)
					{
						int maxhealth = SDKCall_GetMaxHealth(attacker);
						int health = GetClientHealth(attacker);
						if(health < maxhealth)
						{
							if(health+50 > maxhealth)
							{
								SetEntityHealth(target, maxhealth);
								ApplyAllyHealEvent(attacker, target, maxhealth - health);
								ApplySelfHealEvent(target, maxhealth - health);
							}
							else
							{
								SetEntityHealth(target, health + 50);
								ApplyAllyHealEvent(attacker, target, 50);
								ApplySelfHealEvent(target, 50);
							}
						}
						
						Client(attacker).Assist += 50;
						Client(attacker).RefreshAt = 0.0;
						
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
	
		value = Attributes_FindOnWeapon(attacker, weapon, 31);	// critboost on kill
		if(value)
			TF2_AddCondition(attacker, TFCond_CritOnKill, value);
		
		value = Attributes_FindOnWeapon(attacker, weapon, 158);	// add cloak on kill
		if(value)
		{
			float cloak = GetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter") + value*100.0;
			if(cloak > 100)
			{
				cloak = 100.0;
			}
			else if(cloak < 0.0)
			{
				cloak = 0.0;
			}
			
			SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", cloak);
		}
		
		if(Attributes_FindOnWeapon(attacker, weapon, 175))	// jarate duration
		{
			if(JarateDamage[victim] < 0)
				JarateDamage[victim] = 0.0;
			
			JarateApplyer[victim] = attacker;
			JarateDamage[victim] += fdamage;
		}
		else if(Attributes_FindOnWeapon(attacker, weapon, 218))	// mark for death
		{
			MarkApplyer[victim] = attacker;
			MarkDamage[victim] = 500.0;
		}
		else if(TF2_IsPlayerInCondition(victim, TFCond_Jarated))
		{
			JarateDamage[victim] -= fdamage;
			if(JarateApplyer[victim])
			{
				Client(JarateApplyer[victim]).Assist += RoundFloat(fdamage * 0.35);
				Client(JarateApplyer[victim]).RefreshAt = 0.0;
			}
			
			if(JarateDamage[victim] <= 0.0)
				TF2_RemoveCondition(victim, TFCond_Jarated);
		}
		else if(TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath))
		{
			MarkDamage[victim] -= fdamage;
			if(MarkApplyer[victim])
			{
				Client(MarkApplyer[victim]).Assist += RoundFloat(fdamage * 0.35);
				Client(MarkApplyer[victim]).RefreshAt = 0.0;
			}
			
			if(MarkDamage[victim] <= 0.0)
				TF2_RemoveCondition(victim, TFCond_MarkedForDeath);
		}
		
		value = Attributes_FindOnWeapon(attacker, weapon, 180);	// heal on kill
		if(value)
		{
			int maxhealth = SDKCall_GetMaxHealth(attacker);
			int health = GetClientHealth(attacker);
			if(health < maxhealth)
			{
				int healing = RoundFloat(value);
				if(health + healing > maxhealth)
				{
					SetEntityHealth(attacker, maxhealth);
					ApplySelfHealEvent(attacker, maxhealth - health);
				}
				else
				{
					SetEntityHealth(attacker, health + healing);
					ApplySelfHealEvent(attacker, healing);
				}
			}
		}
		
		if(Attributes_FindOnWeapon(attacker, weapon, 219) && !StrContains(classname, "tf_weapon_sword"))	// Eyelander
		{
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
			TF2_AddCondition(attacker, TFCond_DemoBuff);
			SDKCall_SetSpeed(attacker);
			
			int maxoverheal = TF2U_GetMaxOverheal(attacker);
			int health = GetClientHealth(attacker);
			if(health < maxoverheal)
			{
				if(health + 15 > maxoverheal)
				{
					SetEntityHealth(attacker, maxoverheal);
					ApplySelfHealEvent(attacker, maxoverheal - health);
				}
				else
				{
					SetEntityHealth(attacker, health + 15);
					ApplySelfHealEvent(attacker, 15);
				}
			}
		}
		
		value = Attributes_FindOnWeapon(attacker, weapon, 220);
		if(value)	// restore health on kill
		{
			int maxhealth = SDKCall_GetMaxHealth(attacker);
			int health = GetClientHealth(attacker);
			
			int maxoverheal = TF2U_GetMaxOverheal(attacker);
			if(health < maxoverheal)
			{
				int healing = RoundFloat(float(maxhealth) * value / 100.0);
				
				if(health + healing > maxoverheal)
				{
					SetEntityHealth(attacker, maxoverheal);
					ApplySelfHealEvent(attacker, maxoverheal - health);
				}
				else
				{
					SetEntityHealth(attacker, health + healing);
					ApplySelfHealEvent(attacker, healing);
				}
			}
		}
		
		if(weapon != -1 && Attributes_FindOnWeapon(attacker, weapon, 226))	// honorbound
		{
			SetEntProp(weapon, Prop_Send, "m_bIsBloody", true);
			SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")+1);
		}
		
		if(Attributes_FindOnWeapon(attacker, weapon, 409))	// kill forces attacker to laugh
			TF2_StunPlayer(attacker, 2.0, 1.0, TF_STUNFLAGS_NORMALBONK);
	
		value = Attributes_FindOnWeapon(attacker, weapon, 613);	// minicritboost on kill
		if(value)
			TF2_AddCondition(attacker, TFCond_MiniCritOnKill, value);
	
		if(Attributes_FindOnWeapon(attacker, weapon, 644))	// clipsize increase on kill
		{
			int amount = DamageGoal(375, Client(attacker).GetDamage(slot), lastWeaponDamage);
			if(amount)
				SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+amount);
		}
		
		value = Attributes_FindOnWeapon(attacker, weapon, 736);	// speed_boost_on_kill
		if(value)
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, value);
		
		if(Attributes_FindOnWeapon(attacker, weapon, 807))	// add_head_on_kill
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
		
		if(damagecustom == TF_CUSTOM_HEADSHOT && StrEqual(classname, "tf_weapon_sniperrifle_decap")) // Bazaar Bargain
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
	}
	
	int amount = DamageGoal(450, Client(attacker).GetDamage(slot), lastWeaponDamage);
	if(amount)
	{
		if(slot == TFWeaponSlot_Building)
		{
			if(inflictor != -1 && GetEntityClassname(inflictor, classname, sizeof(classname)) && !StrContains(classname, "obj_sentrygun"))
				SetEntProp(inflictor, Prop_Send, "m_iKills", GetEntProp(inflictor, Prop_Send, "m_iKills") + 1);
			
			weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Grenade);
			slot = TFWeaponSlot_Grenade;
		}
		
		if(Attributes_FindOnWeapon(attacker, weapon, 2025))	// killstreak tier
		{
			int lastStreak = GetEntProp(attacker, Prop_Send, "m_nStreaks", _, slot);
			int streak = lastStreak + amount;
			SetEntProp(attacker, Prop_Send, "m_nStreaks", streak, _, slot);
			
			int total = streak;
			for(int i; i < 4; i++)
			{
				if(i != slot)
					total += GetEntProp(attacker, Prop_Send, "m_nStreaks", _, i);
			}
			
			if(DamageGoal(5, streak, lastStreak))
			{
				Event event = CreateEvent("player_death", true);
				
				event.SetInt("userid", GetClientUserId(victim));
				event.SetInt("attacker", GetClientUserId(attacker));
				event.SetInt("inflictor_entindex", inflictor);
				event.SetInt("weaponid", weapon);
				event.SetInt("kill_streak_total", total);
				event.SetInt("kill_streak_wep", streak);
				event.SetInt("crit_type", streak > 10);
				event.SetString("weapon_logclassname", "ff2_killstreak");
				
				if(weapon != -1)
				{
					char buffer[32];
					if(TFED_GetItemDefinitionString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), "item_iconname", buffer, sizeof(buffer)))
						event.SetString("weapon", buffer);
				}
				
				int team = GetClientTeam(attacker);
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i == attacker || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
						event.FireToClient(i);
				}
				
				event.Cancel();
			}
		}
		else if(damagecustom != TF_CUSTOM_BACKSTAB && damagecustom != TF_CUSTOM_TELEFRAG && DamageGoal(2250, Client(attacker).GetDamage(slot), lastWeaponDamage))
		{
			int total;
			for(int i; i < 4; i++)
			{
				total += GetEntProp(attacker, Prop_Send, "m_nStreaks", _, i);
			}
			
			Event event = CreateEvent("player_death", true);
			
			event.SetInt("userid", GetClientUserId(victim));
			event.SetInt("attacker", GetClientUserId(attacker));
			event.SetInt("inflictor_entindex", inflictor);
			event.SetInt("weaponid", weapon);
			event.SetInt("kill_streak_total", total);
			event.SetInt("kill_streak_wep", 0);
			event.SetInt("crit_type", 0);
			event.SetString("weapon_logclassname", "ff2_killstreak");
			
			if(weapon != -1)
			{
				char buffer[32];
				if(TFED_GetItemDefinitionString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), "item_iconname", buffer, sizeof(buffer)))
					event.SetString("weapon", buffer);
			}
			
			event.FireToClient(attacker);
			event.Cancel();
		}
	}
}

float Attributes_FindOnPlayer(int client, int index, bool multi = false, float defaul = 0.0)
{
	float total = defaul;
	bool found = Attributes_GetByDefIndex(client, index, total);
	
	int i;
	int entity;
	float value;
	while(TF2U_GetWearable(client, entity, i))
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

float Attributes_FindOnWeapon(int client, int entity, int index, bool multi = false, float defaul = 0.0)
{
	float total = defaul;
	bool found = Attributes_GetByDefIndex(client, index, total);
	
	int i;
	int wear;
	float value;
	while(TF2U_GetWearable(client, wear, i))
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
	
	if(entity != -1)
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
	
	// Players
	if(entity <= MaxClients)
		return false;
	
	static int indexes[20];
	static float values[20];
	int count = TF2Attrib_GetSOCAttribs(entity, indexes, values, 20);
	for(int i; i < count; i++)
	{
		if(indexes[i] == index)
		{
			value = values[i];
			return true;
		}
	}
	
	if(!GetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", 1))
	{
		count = TF2Attrib_GetStaticAttribs(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), indexes, values, 20);
		for(int i; i < count; i++)
		{
			if(indexes[i] == index)
			{
				value = values[i];
				return true;
			}
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
		if(Enabled || RoundStatus == 1)
			return Plugin_Continue;
	}
	return Plugin_Stop;
}

static int DamageGoal(int goal, int current, int last)
{
	return (current / goal) - (last / goal);
}