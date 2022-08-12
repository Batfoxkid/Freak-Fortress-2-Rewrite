/*
	void SDKHook_PluginStart()
	void SDKHook_LibraryAdded(const char[] name)
	void SDKHook_LibraryRemoved(const char[] name)
	void SDKHook_HookClient(int client)
	void SDKHook_BossCreated(int client)
*/

#pragma semicolon 1

#tryinclude <tf_ontakedamage>

#define OTD_LIBRARY		"tf_ontakedamage"

#if !defined __tf_ontakedamage_included
enum CritType
{
	CritType_None = 0,
	CritType_MiniCrit,
	CritType_Crit
};
#endif

static char SoundCache[MAXTF2PLAYERS][PLATFORM_MAX_PATH];
static bool OTDLoaded;

void SDKHook_PluginStart()
{
	AddNormalSoundHook(SDKHook_NormalSHook);
	
	OTDLoaded = LibraryExists(OTD_LIBRARY);
}

void SDKHook_LibraryAdded(const char[] name)
{
	if(!OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = true;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKUnhook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
		}
	}
}

void SDKHook_LibraryRemoved(const char[] name)
{
	if(OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = false;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
		}
	}
}

void SDKHook_HookClient(int client)
{
	if(!OTDLoaded)
		SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
	
	SDKHook(client, SDKHook_OnTakeDamagePost, SDKHook_TakeDamagePost);
	SDKHook(client, SDKHook_WeaponSwitchPost, SDKHook_SwitchPost);
}

void SDKHook_BossCreated(int client)
{
	SoundCache[client][0] = 0;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_healthkit") != -1)
	{
		SDKHook(entity, SDKHook_StartTouch, SDKHook_HealthTouch);
		SDKHook(entity, SDKHook_Touch, SDKHook_HealthTouch);
	}
	else if(StrContains(classname, "item_ammopack") != -1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_StartTouch, SDKHook_AmmoTouch);
		SDKHook(entity, SDKHook_Touch, SDKHook_AmmoTouch);
	}
	else if(Enabled && StrEqual(classname, "team_round_timer"))
	{
		SDKHook(entity, SDKHook_Spawn, SDKHook_TimerSpawn);
	}
	else if(Enabled && StrEqual(classname, "obj_attachment_sapper"))
	{
		//SDKHook(entity, SDKHook_Spawn, SDKHook_SapperSpawn);
		//SDKHook(entity, SDKHook_SpawnPost, SDKHook_SapperSpawnPost);
	}
	else
	{
		DHook_EntityCreated(entity, classname);
		Weapons_EntityCreated(entity, classname);
	}
}

public void OnEntityDestroyed(int entity)
{
	DHook_EntityDestoryed();
}

public Action SDKHook_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CritType crit = (damagetype & DMG_CRIT) ? CritType_Crit : CritType_None;
	return TF2_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, crit);
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(Client(victim).IsBoss)
	{
		if(!attacker)
		{
			if(damagetype & DMG_FALL)
			{
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if(victim == attacker)
		{
			if(!Client(victim).Knockback)
			{
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if(attacker > 0 && attacker <= MaxClients)
		{
			if(damagetype == DMG_GENERIC && Client(victim).RPSHit == attacker)
			{
				Client(victim).RPSHit = 0;
				damage = float(Client(victim).RPSDamage);
				critType = CritType_None;
				return Plugin_Changed;
			}
			
			if(IsInvuln(victim))
				return Plugin_Continue;
			
			Weapons_OnHitBossPre(attacker, victim, damage, weapon, view_as<int>(critType), damagecustom);
			
			switch(damagecustom)
			{
				case TF_CUSTOM_BACKSTAB:
				{
					Action action = ForwardOld_OnBackstabbed(victim, attacker);
					if(action == Plugin_Stop)
					{
						damage = 0.0;
						return Plugin_Handled;
					}
					
					float gameTime = GetGameTime();
					
					damage = 750.0;	// 2250 max damage
					damagetype |= DMG_PREVENT_PHYSICS_FORCE|DMG_CRIT;
					critType = CritType_Crit;
					
					if(!Client(attacker).IsBoss && weapon != -1)
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", gameTime+0.5);
						
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime + 2.0);
						SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", gameTime + 2.0);
						
						int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
						if(viewmodel != -1)
						{
							int animation = 42;
							switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
							{
								case 225, 356, 423, 461, 574, 649, 1071, 30758:  // Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
									animation = 16;
	
								case 638:  //Sharp Dresser
									animation = 32;
							}
							SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
						}
					}
					
					bool silent = Attributes_OnBackstabBoss(attacker, victim, damage, weapon, true);
					if(!silent)
					{
						EmitSoundToClient(victim, "player/spy_shield_break.wav", _, _, _, _, 0.7);
						EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7);
						
						if(CvarSoundType.BoolValue)
						{
							if(!Client(attacker).IsBoss || !Bosses_PlaySoundToAll(victim, "sound_stabbed_boss", _, _, _, _, _, 2.0))
								Bosses_PlaySoundToAll(victim, "sound_stabbed", _, _, _, _, _, 2.0);
						}
						else if(!Client(attacker).IsBoss || !Bosses_PlaySoundToAll(victim, "sound_stabbed_boss", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0))
						{
							Bosses_PlaySoundToAll(victim, "sound_stabbed", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
						}
					}
					
					float stale, time;
					Weapons_OnBackstabBoss(victim, damage, weapon, time, stale);
					
					float multi = 0.666667;
					if(!Client(attacker).IsBoss)
					{
						if(stale)
						{
							if(Client(victim).LastStabTime + time > gameTime)
							{
								multi = stale;
							}
							else
							{
								multi = 1.0;
							}
						}
						else
						{
							// 75% with stock knife, 50% with Kunai
							float lowest = float(SDKCall_GetMaxHealth(attacker) + 40) / 220.0;
							
							// 25 sec with stock knife, 37.5 sec with Kunai to restore full damage
							multi = lowest * 0.8 + ((gameTime - Client(victim).LastStabTime) / 62.5);
							multi = Clamp(multi, lowest, 1.0);
						}
					}
					
					damage *= multi;
					Client(victim).LastStabTime = gameTime;
					
					Bosses_UseSlot(victim, 6, 6);
					
					if(action == Plugin_Continue)
						action = Plugin_Changed;
					
					return action;
				}
				case TF_CUSTOM_TELEFRAG:
				{
					damage = 1666.67;
					damagetype |= DMG_CRIT;
					critType = CritType_Crit;
					
					int assister;
					int entity = GetEntPropEnt(attacker, Prop_Send, "m_hGroundEntity");
					if(entity > MaxClients)
					{
						char classname[32];
						if(GetEntityClassname(entity, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter"))
						{
							assister = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
							if(assister != attacker && assister > 0 && assister <= MaxClients && GetClientTeam(assister) == GetClientTeam(attacker))
							{
								Client(assister).Assist += 6000;
								Client(assister).RefreshAt = 0.0;
							}
							else
							{
								assister = -1;
							}
						}
					}
					
					Event event = CreateEvent("player_death", true);
					
					event.SetInt("userid", GetClientUserId(victim));
					event.SetInt("attacker", GetClientUserId(attacker));
					event.SetInt("assister", assister == -1 ? assister : GetClientUserId(assister));
					event.SetString("weapon", "telefrag");
					event.SetString("weapon_logclassname", "ff2_notice");
					event.SetInt("customkill", damagecustom);
					event.SetInt("crit_type", 2);
					
					int team = GetClientTeam(attacker);
					for(int i = 1; i <= MaxClients; i++)
					{
						if(i == attacker || i == assister || i == victim || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
							event.FireToClient(i);
					}
					
					event.Cancel();
					
					if(CvarSoundType.BoolValue)
					{
						Bosses_PlaySoundToAll(victim, "sound_telefraged", _, _, _, _, _, 2.0);
					}
					else
					{
						Bosses_PlaySoundToAll(victim, "sound_telefraged", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					return Plugin_Changed;
				}
			}
			
			if(Client(attacker).IsBoss)
			{
				if(damage <= 160.0 && Client(attacker).Triple)
				{
					// The thing everyone hates but can't remove
					damage *= 3.0;
				}
			}
			else
			{
				Attributes_OnHitBossPre(attacker, victim, damagetype, weapon);
			}
			
			if(critType == CritType_None && (damagetype & DMG_CRIT))
				critType = CritType_Crit;
			
			return Plugin_Changed;
		}
		else
		{
			Action action = ForwardOld_OnTriggerHurt(victim, attacker, damage);
			if(action == Plugin_Handled || action == Plugin_Stop)
			{
				damage = 0.0;
				return Plugin_Handled;
			}
			
			float gameTime = GetGameTime();
			float pressure = (1.0 - ((gameTime - Client(victim).LastTriggerTime) / 2.5)) * Client(victim).LastTriggerDamage;
			pressure = Min(pressure, 0.0);
			
			if(action == Plugin_Continue)
			{
				// Cap of 1500 damage every 2.5 seconds, or 300 every 1/2 second
				float cap = 1500.0 - pressure;
				if(damage > cap)
					damage = cap;
			}
			
			Client(victim).LastTriggerTime = gameTime;
			Client(victim).LastTriggerDamage = pressure + damage;
			
			if(critType == CritType_None && (damagetype & DMG_CRIT))
				critType = CritType_Crit;
			
			return Plugin_Changed;
		}
	}
	else if(attacker > 0 && attacker <= MaxClients && Client(attacker).IsBoss)
	{
		if(!IsInvuln(victim))
		{
			bool changed;
			bool melee = ((damagetype & DMG_CLUB) || (damagetype & DMG_SLASH));
			if(melee && SDKCall_CheckBlockBackstab(victim, attacker))
			{
				if(TF2_IsPlayerInCondition(victim, TFCond_RuneResist))
					TF2_RemoveCondition(victim, TFCond_RuneResist);
				
				EmitGameSoundToAll("Player.Spy_Shield_Break", victim, _, victim, damagePosition);
				return Plugin_Handled;
			}
			
			if(damage <= 160.0 && Client(attacker).Triple)
			{
				// The thing everyone hates but can't remove
				damage *= 3.0;
				changed = true;
			}
			
			if(TF2_IsPlayerInCondition(victim, TFCond_Disguised))
			{
				// 25% resist while disguised, a good middle ground
				// which requires a Spy to be both disguised and cloaked
				// to a tank a hit from a standard boss
				damage *= 0.75;
				changed = true;
			}
			
			/*if(TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) ||
			   TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffNoCritBlock))
			{
				// 35% resist to 50% resist
				damage /= 1.3;
				changed = true;
			}*/
			
			if(melee)
			{
				if(critType == CritType_Crit && GetEntProp(victim, Prop_Send, "m_bFeignDeathReady") && !TF2_IsCritBoosted(attacker))
				{
					// Make random crits less brutal for Dead Ringers
					critType = CritType_None;	//TODO: See if tf_ontakedamage needs an manual mini-crit boost check
					damagetype &= ~DMG_CRIT;
					changed = true;
				}
				
				// Vaccinator conditions
				for(TFCond cond = TFCond_UberBulletResist; cond <= TFCond_UberFireResist; cond++)
				{
					if(TF2_IsPlayerInCondition(victim, cond))
					{
						// Uber Variant
						damage *= 0.5;
						critType = CritType_None;
						damagetype &= ~DMG_CRIT;
						changed = true;
					}
					
					// TODO: Figure out if uber and passive of the same type is or can be applied at the same time
					if(TF2_IsPlayerInCondition(victim, cond + view_as<TFCond>(3)))
					{
						// Passive Variant
						damage *= 0.9;
						changed = true;
					}
				}
			}
			
			if(TF2_IsPlayerInCondition(victim, TFCond_Disguised))
			{
				// 25% resist while disguised, a good middle ground
				// which requires a Spy to be both disguised and cloaked
				// to a tank a hit from a standard boss
				damage *= 0.75;
				changed = true;
			}
			
			if(changed && critType == CritType_None && (damagetype & DMG_CRIT))
				critType = CritType_Crit;
			
			return changed ? Plugin_Changed : Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void SDKHook_TakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(Client(victim).IsBoss)
	{
		if(victim != attacker && attacker > 0 && attacker <= MaxClients && !IsInvuln(victim) && !Client(attacker).IsBoss)
			Attributes_OnHitBoss(attacker, victim, inflictor, damage, weapon, damagecustom);
		
		Bosses_SetSpeed(victim);
	}
}

public void SDKHook_SwitchPost(int client, int weapon)
{
	Weapons_OnWeaponSwitch(client, weapon);
}

public Action SDKHook_NormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(entity > 0 && entity <= MaxClients && (channel == SNDCHAN_VOICE || (channel == SNDCHAN_STATIC && !StrContains(sample, "vo", false))))
	{
		int client = entity;
		if(TF2_IsPlayerInCondition(entity, TFCond_Disguised))
		{
			for(int i; i < numClients; i++)
			{
				if(clients[i] == entity)	// Get the sound from the Spy/enemies to avoid teammates hearing it
				{
					client = GetEntProp(entity, Prop_Send, "m_iDisguiseTargetIndex");
					if(client < 1 || client > MaxClients || view_as<TFClassType>(GetEntProp(entity, Prop_Send, "m_nDisguiseClass")) != TF2_GetPlayerClass(client))
						client = entity;
					
					break;
				}
			}
		}
		
		if(Client(client).IsBoss && !Client(entity).Speaking)
		{
			static SoundEnum sound;
			sound.Entity = entity;
			sound.Channel = channel;
			sound.Level = level;
			sound.Flags = flags;
			sound.Volume = volume;
			sound.Pitch = pitch;
			
			bool found = StrEqual(SoundCache[client], sample);
			if(!found)
				strcopy(SoundCache[client], sizeof(SoundCache[]), sample);
			
			if(found || Bosses_GetRandomSound(client, "catch_replace", sound, sample) || Bosses_GetRandomSound(client, "catch_phrase", sound))
			{
				int[] clients2 = new int[numClients];
				int amount;
				
				for(int i; i < numClients; i++)
				{
					if(!Client(clients[i]).NoVoice)
					{
						clients2[amount] = clients[i];
						clients[amount] = clients2[amount];
						amount++;
					}
				}
				
				numClients = amount;
				
				if(sound.Entity == SOUND_FROM_LOCAL_PLAYER)
					sound.Entity = entity;
				
				int count = RoundToCeil(sound.Volume);
				if(count > 1)
					sound.Volume /= float(count);
				
				entity = sound.Entity;
				channel = sound.Channel;
				level = sound.Level;
				flags = sound.Flags;
				volume = sound.Volume;
				pitch = sound.Pitch;
				strcopy(sample, sizeof(sample), sound.Sound);
				
				Client(entity).Speaking = true;
				for(int i = 1; i < count; i++)
				{
					EmitSound(clients, numClients, sample, entity, channel, level, flags, volume, pitch);
				}
				Client(entity).Speaking = false;
				return Plugin_Changed;
			}
			
			if(Client(client).BlockVo)
				return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action SDKHook_HealthTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients && (Client(client).Minion || (Client(client).IsBoss && (Client(client).Pickups != 1 && Client(client).Pickups < 3))))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHook_AmmoTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients && (Client(client).Minion || (Client(client).IsBoss && Client(client).Pickups < 2)))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHook_TimerSpawn(int entity)
{
	DispatchKeyValue(entity, "auto_countdown", "0");
	return Plugin_Continue;
}

public void SDKHook_SapperSpawn(int entity)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
}

public void SDKHook_SapperSpawnPost(int entity)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
}