/*
	void SDKHook_PluginStart()
	void SDKHook_HookClient(int client)
*/

void SDKHook_PluginStart()
{
	AddNormalSoundHook(SDKHook_NormalSHook);
}

void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, SDKHook_TakeDamagePost);
	//SDKHook(client, SDKHook_SDKHook_TakeDamageAlive, SDKHook_TakeDamageAlive);
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
}

public Action SDKHook_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
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
			if(IsInvuln(victim))
				return Plugin_Continue;
			
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
					
					float multi = 0.666667;
					if(!Client(attacker).IsBoss)
					{
						// 75% with stock knife, 50% with Kunai
						float lowest = float(SDKCall_GetMaxHealth(attacker) + 40) / 220.0;
						
						// 25 sec with stock knife, 37.5 sec with Kunai to restore full damage
						multi = lowest*0.8 + ((gameTime - Client(attacker).LastStabTime) / 62.5);
						multi = clamp(multi, lowest, 1.0);
					}
					
					damage = 750.0 * multi;	// 2250 max damage
					damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
					
					Client(attacker).LastStabTime = gameTime;
					
					if(!Client(attacker).IsBoss)
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", gameTime+0.5);
						
						gameTime += 2.0;
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime);
						SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", gameTime);
						
						int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
						if(viewmodel > MaxClients)
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
					
					bool silent = Attributes_OnBackstabBoss(attacker, victim, damage, weapon);
					if(!silent)
					{
						if(Client(attacker).IsBoss)
						{
							if(!Bosses_PlaySoundToAll(victim, "sound_stabbed_boss", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0))
								Bosses_PlaySoundToAll(victim, "sound_stabbed", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
						}
						else
						{
							EmitSoundToClient(victim, "player/spy_shield_break.wav", _, _, _, _, 0.7);
							EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7);
							Bosses_PlaySoundToAll(victim, "sound_stabbed", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
						}
					}
					
					Bosses_UseSlot(victim, 6, 6);
					
					if(action == Plugin_Continue)
						action = Plugin_Changed;
					
					return action;
				}
				case TF_CUSTOM_TELEFRAG:
				{
					damage = 2000.0;
					damagetype |= DMG_CRIT;
					
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
					for(int i=1; i<=MaxClients; i++)
					{
						if(i == attacker || i == assister || i == victim || (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team))
							event.FireToClient(i);
					}
					
					event.Cancel();
					
					Bosses_PlaySoundToAll(victim, "sound_telefraged", _, victim, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, _, 2.0);
					return Plugin_Changed;
				}
			}
			
			ScaleVector(damageForce, 1.3 - (Client(victim).Health / Client(victim).MaxHealth / Client(victim).MaxLives));
			Attributes_OnHitBossPre(attacker, victim, damage, damagetype, weapon);
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
			pressure = min(pressure, 0.0);
			
			if(action == Plugin_Continue)
			{
				// Cap of 1500 damage every 2.5 seconds, or 300 every 1/2 second
				float cap = 1500.0 - pressure;
				if(cap > damage)
				{
					damage = cap;
					action = Plugin_Changed;
				}
			}
			
			Client(victim).LastTriggerTime = gameTime;
			Client(victim).LastTriggerDamage = pressure + damage;
			return Plugin_Changed;
		}
	}
	else if(attacker > 0 && attacker <= MaxClients && Client(attacker).IsBoss)
	{
		if(!IsInvuln(victim))
		{
			bool changed;
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
			
			if(TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) ||
			   TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffNoCritBlock))
			{
				// 35% resist to 50% resist
				damage /= 1.3;
				changed = true;
			}
			
			if((damagetype & DMG_CRIT) &&
			   GetEntProp(victim, Prop_Send, "m_bFeignDeathReady") &&
			   damage/4.0 < GetClientHealth(victim))
			{
				// Make random crits less brutal
				damagetype &= ~DMG_CRIT;
				changed = true;
			}
			
			return changed ? Plugin_Changed : Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void SDKHook_TakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(Client(victim).IsBoss)
	{
		if(victim != attacker && attacker > 0 && attacker <= MaxClients)
		{
			if(!IsInvuln(victim))
			{
				if(damagecustom != TF_CUSTOM_TELEFRAG)
				{
					int team = GetClientTeam(attacker);
					for(int i=1; i<=MaxClients; i++)
					{
						if(attacker != i && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==team)
						{
							int entity = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
							if(entity > MaxClients &&
							   HasEntProp(entity, Prop_Send, "m_bHealing") &&
							   GetEntProp(entity, Prop_Send, "m_bHealing") &&
							   GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget") == attacker)
							{
								Client(i).Assist += RoundFloat(damage);
							}
						}
					}
				}
				
				Attributes_OnHitBoss(attacker, victim, damage, weapon, damagecustom);
			}
		}
	}
}

public Action SDKHook_NormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(entity > 0 && entity <= MaxClients && (channel == SNDCHAN_VOICE || (channel == SNDCHAN_STATIC && !StrContains(sample, "vo", false))))
	{
		int client = entity;
		if(TF2_IsPlayerInCondition(entity, TFCond_Disguised))
		{
			for(int i; i<numClients; i++)
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
			SoundEnum sound;
			sound.Entity = entity;
			sound.Channel = channel;
			sound.Level = level;
			sound.Flags = flags;
			sound.Volume = volume;
			sound.Pitch = pitch;
			if(Bosses_GetRandomSound(client, "catch_replace", sound, sample) || Bosses_GetRandomSound(client, "catch_phrase", sound))
			{
				int[] clients2 = new int[numClients];
				int amount;
				
				for(int i; i<numClients; i++)
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
				for(int i=1; i<count; i++)
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