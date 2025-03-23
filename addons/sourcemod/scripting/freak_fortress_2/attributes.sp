#pragma semicolon 1
#pragma newdecls required

static float JarateDamage[MAXTF2PLAYERS];
static int JarateApplyer[MAXTF2PLAYERS];
static float MarkDamage[MAXTF2PLAYERS];
static int MarkApplyer[MAXTF2PLAYERS];

void Attributes_PluginStart()
{
	HookUserMessage(GetUserMessageId("PlayerJarated"), Attributes_OnJarateBoss);
}

static Action Attributes_OnJarateBoss(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int attacker = bf.ReadByte();
	int victim = bf.ReadByte();
	if(Client(victim).IsBoss)
	{
		if(Attrib_FindOnPlayer(attacker, "rage on kill"))
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
					float duration = 1500.0;

					CustomAttrib_OnJarateBoss(victim, attacker, weapon, duration);

					if(duration > 0.0)
					{
						if(JarateDamage[victim] < 0.0)
							JarateDamage[victim] = 0.0;
						
						JarateDamage[victim] += 1500.0;
						JarateApplyer[victim] = attacker;
					}
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

static void ReapplyMilk(DataPack pack)
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

bool Attributes_OnBackstabBoss(int attacker, int victim, float &damage, int weapon, bool backstab)
{
	if(Attrib_FindOnPlayer(attacker, "add cloak on hit"))
	{
		// Nerfs the insane power of the L'Etranger
		SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime() + 2.0);
	}
	
	if(Attrib_FindOnWeapon(attacker, weapon, "sanguisuge"))
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
	
	float value = Attrib_FindOnPlayer(attacker, "sapper kills collect crits");
	if(value)
		SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+RoundFloat(value));
	
	value = Attrib_FindOnWeapon(attacker, weapon, "armor piercing");
	if(value)
		damage += damage * 0.01 * value;
	
	if(Attrib_FindOnWeapon(attacker, weapon, "disguise on backstab"))
	{
		DataPack pack = new DataPack();
		RequestFrame(Attributes_RedisguiseFrame, pack);
		pack.WriteCell(GetClientUserId(attacker));
		
		if(TF2_IsPlayerInCondition(attacker, TFCond_Disguised))
		{
			pack.WriteCell(GetEntProp(attacker, Prop_Send, "m_nDisguiseTeam"));
			pack.WriteCell(GetEntProp(attacker, Prop_Send, "m_nDisguiseClass"));
			pack.WriteCell(GetEntPropEnt(attacker, Prop_Send, "m_hDisguiseTarget"));
			pack.WriteCell(GetEntProp(attacker, Prop_Send, "m_iDisguiseHealth"));
		}
		else
		{
			pack.WriteCell(GetClientTeam(victim));
			pack.WriteCell(TF2_GetPlayerClass(victim));
			pack.WriteCell(victim);
			pack.WriteCell(GetClientHealth(victim));
		}
	}
	
	bool silent = view_as<bool>(Attrib_FindOnWeapon(attacker, weapon, "silent killer"));
	
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
	event.SetString("weapon", backstab ? "backstab" : "market_gardener");
	event.SetString("weapon_logclassname", "ff2_notice");
	event.SetInt("damagebits", DMG_CRIT);
 	event.SetInt("customkill", backstab ? TF_CUSTOM_BACKSTAB : 0);
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
	
	return silent;
}

static void Attributes_RedisguiseFrame(DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		TF2_AddCondition(client, TFCond_Disguised, -1.0);
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", pack.ReadCell());
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", pack.ReadCell());
		SetEntPropEnt(client, Prop_Send, "m_hDisguiseTarget", pack.ReadCell());
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", pack.ReadCell());
	}

	delete pack;
}

void Attributes_OnHitBoss(int attacker, int victim, int inflictor, float fdamage, int damagetype, int weapon, int damagecustom)
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
			{
				slot = TFWeaponSlot_Grenade;
			}
			else if(slot == -1)
			{
				slot = TFWeaponSlot_Building;
			}
		}
	}
	
	int lastPlayerDamage = Client(attacker).Damage;
	int lastWeaponDamage = Client(attacker).GetDamage(slot);
	
	int idamage = RoundFloat(fdamage);
	Client(attacker).Damage = lastPlayerDamage + idamage;
	Client(attacker).SetDamage(slot, lastWeaponDamage + idamage);
	
	CustomAttrib_OnHitBossPost(attacker, Client(attacker).Damage, lastPlayerDamage);
	
	float value = Attrib_FindOnPlayer(attacker, "drop health pack on kill");
	if(value > 0.0)
	{
		int amount = DamageGoal(RoundFloat(270.0 / value), Client(attacker).Damage, lastPlayerDamage);
		if(amount)
		{
			float position[3];
			GetClientAbsOrigin(victim, position);
			position[2] += 20.0;
			
			float velocity[3];
			velocity[2] = 75.0;
			
			int team = GetClientTeam(attacker);  
			for(int i; i < amount; i++)
			{
				int entity = CreateEntityByName("item_healthkit_small");
				if(IsValidEntity(entity))
				{
					DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
					TeleportEntity(entity, position);
					velocity[0] = GetRandomFloat(-75.0, 75.0);
					velocity[1] = GetRandomFloat(-75.0, 75.0);
					SDKCall_DropSingleInstance(entity, velocity, attacker, 0.1);
				}
			}
		}
	}
	
	if(Attrib_FindOnPlayer(attacker, "rage on kill"))
	{
		float rage = 33.34;
		if(slot != TFWeaponSlot_Primary)
			rage = fdamage / 3.8993;	// 33.34% every 130 damage
		
		rage += GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
		if(rage > 100.0)
			rage = 100.0;
		
		SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
	}

	int i;
	int entity = -1;
	while(TF2_GetItem(attacker, entity, i))
	{
		if(Attrib_Get(entity, "boost on damage", value) && value > 0.0)
		{
			DataPack pack;
			if(Enabled)
			{
				value = 1.0;
				CustomAttrib_Get(entity, "boost on damage drain multi", value);
				if(value)
				{
					CreateDataTimer(0.1, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					pack.WriteCell(GetClientUserId(attacker));
					pack.WriteFloat(fdamage / 1000.0 * value);
				}
			}
			else
			{
				CreateDataTimer(0.5, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(attacker));
				pack.WriteFloat(fdamage / 2.0);
			}

			break;
		}
	}
	
	if(damagetype & DMG_CLUB)
	{
		value = Attrib_FindOnPlayer(attacker, "kill refills meter");
		if(value)
		{
			float charge = GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter") + value;
			if(charge > 100.0)
				charge = 100.0;
			
			SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge);
		}
	}
	
	if(damagecustom != TF_CUSTOM_BURNING && damagecustom != TF_CUSTOM_BLEEDING)
	{
		if(Attrib_FindOnWeapon(attacker, weapon, "fists have radial buff"))
		{
			int team = GetClientTeam(attacker);
			float pos1[3], pos2[3];
			GetClientAbsOrigin(attacker, pos1);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(attacker != target && IsClientInGame(target) && GetClientTeam(target) == team && IsPlayerAlive(target))
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
						
						Client(attacker).Assist += 100;
						Client(attacker).RefreshAt = 0.0;
						
						i = 0;
						while(TF2_GetItem(target, entity, i))
						{
							SetEntProp(entity, Prop_Send, "m_iAccountID", 0);

							value = 1.0;
							Attrib_Get(entity, "crit mod disabled hidden", value);
							Attrib_Set(entity, "crit mod disabled hidden", value + 0.1);
						}
					}
				}
			}
		}
	
		value = Attrib_FindOnWeapon(attacker, weapon, "critboost on kill");
		if(value)
			TF2_AddCondition(attacker, TFCond_CritOnKill, value);
		
		value = Attrib_FindOnWeapon(attacker, weapon, "add cloak on kill");
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
		
		if(Attrib_FindOnWeapon(attacker, weapon, "jarate duration"))
		{
			if(JarateDamage[victim] < 0)
				JarateDamage[victim] = 0.0;
			
			JarateApplyer[victim] = attacker;
			JarateDamage[victim] += fdamage;
		}
		else if(Attrib_FindOnWeapon(attacker, weapon, "mark for death"))
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
		
		value = Attrib_FindOnWeapon(attacker, weapon, "heal on kill");
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
		
		if(Attrib_FindOnWeapon(attacker, weapon, "decapitate type") && !StrContains(classname, "tf_weapon_sword"))	// Eyelander
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
		
		value = Attrib_FindOnWeapon(attacker, weapon, "restore health on kill");
		if(value)
		{
			int maxhealth = SDKCall_GetMaxHealth(attacker);
			int health = GetClientHealth(attacker);
			
			int maxoverheal = TF2U_GetMaxOverheal(attacker);
			if(health < maxoverheal)
			{
				int healing = RoundFloat(float(maxhealth) * value / 200.0);
				
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
		
		if(weapon != -1 && Attrib_FindOnWeapon(attacker, weapon, "honorbound"))
		{
			SetEntProp(weapon, Prop_Send, "m_bIsBloody", true);
			SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")+1);
		}
		
		if(Attrib_FindOnWeapon(attacker, weapon, "kill forces attacker to laugh"))
			TF2_StunPlayer(attacker, 2.0, 1.0, TF_STUNFLAGS_NORMALBONK);
		
		value = Attrib_FindOnWeapon(attacker, weapon, "minicritboost on kill");
		if(value)
			TF2_AddCondition(attacker, TFCond_MiniCritOnKill, value);
		
		if(Attrib_FindOnWeapon(attacker, weapon, "clipsize increase on kill"))
		{
			int amount = DamageGoal(375, Client(attacker).GetDamage(slot), lastWeaponDamage);
			if(amount)
				SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+amount);
		}
		
		value = Attrib_FindOnWeapon(attacker, weapon, "speed_boost_on_kill");
		if(value)
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, value);
		
		if(Attrib_FindOnWeapon(attacker, weapon, "add_head_on_kill"))
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
		
		if(damagecustom == TF_CUSTOM_HEADSHOT && StrEqual(classname, "tf_weapon_sniperrifle_decap")) // Bazaar Bargain
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
	}
	
	int amount = DamageGoal(Cvar[StreakDamage].IntValue, Client(attacker).GetDamage(slot), lastWeaponDamage);
	if(amount)
	{
		if(slot == TFWeaponSlot_Building)
		{
			if(inflictor != -1 && GetEntityClassname(inflictor, classname, sizeof(classname)) && !StrContains(classname, "obj_sentrygun"))
				SetEntProp(inflictor, Prop_Send, "m_iKills", GetEntProp(inflictor, Prop_Send, "m_iKills") + 1);
			
			weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Grenade);
			slot = TFWeaponSlot_Grenade;
		}
		
		if(Attrib_FindOnWeapon(attacker, weapon, "killstreak tier"))
		{
			int lastStreak = GetEntProp(attacker, Prop_Send, "m_nStreaks", _, slot);
			int streak = lastStreak + amount;
			SetEntProp(attacker, Prop_Send, "m_nStreaks", streak, _, slot);
			
			int total = streak;
			for(i = 0; i < 4; i++)
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
				event.SetInt("kill_streak_wep", streak / 5 * 5);
				event.SetInt("crit_type", streak > 10);
				event.SetString("weapon_logclassname", "ff2_killstreak");
				
				if(weapon != -1)
				{
					char buffer[32];
					if(TFED_GetItemDefinitionString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), "item_iconname", buffer, sizeof(buffer)))
						event.SetString("weapon", buffer);
				}
				
				int team = GetClientTeam(attacker);
				for(i = 1; i <= MaxClients; i++)
				{
					if(i == attacker || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
						event.FireToClient(i);
				}
				
				event.Cancel();
			}
		}
	}
}

static Action Attributes_BoostDrainStack(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client && IsPlayerAlive(client))
	{
		float hype = GetEntPropFloat(client, Prop_Send, "m_flHypeMeter") - pack.ReadFloat();
		if(hype < 0.0)
			hype = 0.0;
		
		SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", hype);
		if(Enabled && RoundStatus == 1)
			return Plugin_Continue;
	}
	return Plugin_Stop;
}