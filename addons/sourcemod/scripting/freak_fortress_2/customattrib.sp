#if defined IS_MAIN_FF2
#tryinclude <tf_econ_dynamic>
#endif
#tryinclude <tf_custom_attributes>

#pragma semicolon 1
#pragma newdecls required

#define TFEY_LIBRARY	"tf2econdynamic"
#define TCA_LIBRARY		"tf2custattr"

#if !defined DEFAULT_VALUE_TEST
#define DEFAULT_VALUE_TEST	-69420.69
#endif

#if defined __tf_econ_dyn_included
static bool TFEYLoaded;
#endif

#if defined __tf_custom_attributes_included
static bool TCALoaded;
#endif

#if defined IS_MAIN_FF2
static int HasCritGlow[MAXTF2PLAYERS];
#endif

void CustomAttrib_PluginLoad()
{
	#if defined __tf_custom_attributes_included
	MarkNativeAsOptional("TF2CustAttr_GetFloat");
	MarkNativeAsOptional("TF2CustAttr_SetString");
	MarkNativeAsOptional("TF2CustAttr_GetString");
	MarkNativeAsOptional("TF2EconDynAttribute.TF2EconDynAttribute");
	MarkNativeAsOptional("TF2EconDynAttribute.SetClass");
	MarkNativeAsOptional("TF2EconDynAttribute.SetName");
	MarkNativeAsOptional("TF2EconDynAttribute.SetDescriptionFormat");
	MarkNativeAsOptional("TF2EconDynAttribute.SetCustom");
	MarkNativeAsOptional("TF2EconDynAttribute.Register");
	#endif
}

void CustomAttrib_PluginStart()
{
	#if defined __tf_econ_dyn_included
	TFEYLoaded = GetFeatureStatus(FeatureType_Native, "TF2EconDynAttribute.TF2EconDynAttribute") == FeatureStatus_Available;
	if(TFEYLoaded)
	{
		#if defined IS_MAIN_FF2
		AddAttributes();
		#endif
	}
	#endif

	#if defined __tf_custom_attributes_included
	TCALoaded = LibraryExists(TCA_LIBRARY);
	#endif
}

public void CustomAttrib_LibraryAdded(const char[] name)
{
	#if defined __tf_custom_attributes_included
	if(!TCALoaded && StrEqual(name, TCA_LIBRARY))
		TCALoaded = true;
	#endif
}

public void CustomAttrib_LibraryRemoved(const char[] name)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded && StrEqual(name, TCA_LIBRARY))
		TCALoaded = false;
	#endif
}

stock bool CustomAttrib_Loaded()
{
	#if defined __tf_econ_dyn_included
	if(TFEYLoaded)
	{
		if(GetFeatureStatus(FeatureType_Native, "TF2EconDynAttribute.TF2EconDynAttribute") != FeatureStatus_Available)
			TFEYLoaded = false;
		
		if(TFEYLoaded)
			return TFEYLoaded;
	}
	#endif

	#if defined __tf_custom_attributes_included
	if(TCALoaded)
		return TCALoaded;
	#endif

	return false;
}

stock void CustomAttrib_PrintStatus()
{
	#if defined __tf_econ_dyn_included
	if(GetFeatureStatus(FeatureType_Native, "TF2EconDynAttribute.TF2EconDynAttribute") != FeatureStatus_Available)
		TFEYLoaded = false;

	PrintToServer("'%s' is %sloaded", TFEY_LIBRARY, TFEYLoaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", TFEY_LIBRARY);
	#endif

	#if defined __tf_custom_attributes_included
	PrintToServer("'%s' is %sloaded", TCA_LIBRARY, TCALoaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", TCA_LIBRARY);
	#endif
}

void CustomAttrib_ApplyFromCfg(int entity, ConfigMap cfg)
{
	StringMapSnapshot snap = cfg.Snapshot();
	
	int entries = snap.Length;
	for(int i; i < entries; i++)
	{
		int length = snap.KeyBufferSize(i) + 1;
		
		char[] key = new char[length];
		snap.GetKey(i, key, length);
		
		static PackVal attribute;	
		cfg.GetArray(key, attribute, sizeof(attribute));
		if(attribute.tag == KeyValType_Value)
		{
			#if defined __tf_custom_attributes_included
			if(TCALoaded)
			{
				TF2CustAttr_SetString(entity, key, attribute.data);
				continue;
			}
			#endif

		#if defined IS_MAIN_FF2
			#if defined __tf_econ_dyn_included
			if(TFEYLoaded)
			{
				Attrib_SetString(entity, key, attribute.data);
				continue;
			}
			#endif
			
			if(StrEqual(key, "damage vs bosses"))
			{
				Attrib_Set(entity, "damage bonus HIDDEN", StringToFloat(attribute.data));
			}
			else if(StrEqual(key, "mod crit type on bosses"))
			{
				Attrib_Set(entity, "crit vs burning players", 1.0);
				Attrib_Set(entity, "crit vs non burning players", 1.0);

				if(StringToInt(attribute.data) == 1)
					Attrib_Set(entity, "crits_become_minicrits", 1.0);
			}
		#else
			Attrib_SetString(entity, key, attribute.data);
		#endif
		}
	}
	
	delete snap;
}

stock float CustomAttrib_FindOnPlayer(int client, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = CustomAttrib_Get(client, name, total);
	
	int i;
	int entity;
	float value;
	while(TF2U_GetWearable(client, entity, i))
	{
		if(CustomAttrib_Get(entity, name, value))
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
		if(active != entity && Attrib_Get(entity, "provide on active", value) && value)
			continue;
		
		if(CustomAttrib_Get(entity, name, value))
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

stock float CustomAttrib_FindOnWeapon(int client, int entity, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = CustomAttrib_Get(client, name, total);
	
	int i;
	int wear;
	float value;
	while(TF2U_GetWearable(client, wear, i))
	{
		if(CustomAttrib_Get(wear, name, value))
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
		char classname[18];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "tf_w") || StrEqual(classname, "tf_powerup_bottle"))
		{
			if(CustomAttrib_Get(entity, name, value))
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
	}
	
	return total;
}

stock bool CustomAttrib_Get(int weapon, const char[] name, float &value = 0.0)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded)
	{
		float result = TF2CustAttr_GetFloat(weapon, name, DEFAULT_VALUE_TEST);
		if(result != DEFAULT_VALUE_TEST)
		{
			value = result;
			return true;
		}
	}
	#endif

	return Attrib_Get(weapon, name, value);
}

stock bool CustomAttrib_GetString(int weapon, const char[] name, char[] buffer, int length)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded)
	{
		if(TF2CustAttr_GetString(weapon, name, buffer, length))
			return true;
	}
	#endif

	return Attrib_GetString(weapon, name, buffer, length);
}

#if !defined IS_MAIN_FF2
	#endinput
#endif

#if defined __tf_econ_dyn_included
static void AddAttributes()
{
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();

	attrib.SetName("damage vs bosses");
	attrib.SetClass("ff2.mult_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "damage vs bosses");
	attrib.Register();

	attrib.SetName("multi boss rage");
	attrib.SetClass("ff2.multi_victim_rage_on_hit");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "multi boss rage");
	attrib.Register();

	attrib.SetName("mid-air damage vs bosses");
	attrib.SetClass("ff2.mult_airborne_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "mid-air damage vs bosses");
	attrib.Register();

	attrib.SetName("charge outlines bosses");
	attrib.SetClass("ff2.mod_charge_outline_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "charge outlines bosses");
	attrib.Register();

	attrib.SetName("mod crit type on bosses");
	attrib.SetClass("ff2.set_critype_vs_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod crit type on bosses");
	attrib.Register();

	attrib.SetName("mod fire rate hit stale");
	attrib.SetClass("ff2.stale_boss_hit_firerate");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod fire rate hit stale");
	attrib.Register();

	attrib.SetName("mod reload time hit stale");
	attrib.SetClass("ff2.stale_boss_hit_reload");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod reload time hit stale");
	attrib.Register();

	attrib.SetName("primary damage vs bosses");
	attrib.SetClass("ff2.mult_slot0_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "primary damage vs bosses");
	attrib.Register();

	attrib.SetName("secondary damage vs bosses");
	attrib.SetClass("ff2.mult_slot1_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "secondary damage vs bosses");
	attrib.Register();

	attrib.SetName("melee damage vs bosses");
	attrib.SetClass("ff2.mult_slot2_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "melee damage vs bosses");
	attrib.Register();

	attrib.SetName("mod crit type glow");
	attrib.SetClass("ff2.set_critype");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod crit type glow");
	attrib.Register();

	attrib.SetName("primary ammo from damage");
	attrib.SetClass("ff2.mod_ammo1_gain_vs_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "primary ammo from damage");
	attrib.Register();

	attrib.SetName("secondary ammo from damage");
	attrib.SetClass("ff2.mod_ammo2_gain_vs_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "secondary ammo from damage");
	attrib.Register();

	attrib.SetName("backstab damage percent");
	attrib.SetClass("ff2.mod_old_backstab");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "backstab damage percent");
	attrib.Register();

	attrib.SetName("backstab stale restore");
	attrib.SetClass("ff2.stale_boss_stab_time");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "");
	attrib.Register();

	attrib.SetName("backstab stale multi");
	attrib.SetClass("ff2.stale_boss_stab_damage");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "");
	attrib.Register();

	attrib.SetName("mod airblast stale");
	attrib.SetClass("ff2.stale_boss_airblast_refire");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod airblast stale");
	attrib.Register();

	attrib.SetName("mod airblast rage");
	attrib.SetClass("ff2.mod_airblast_boss_rage");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod airblast rage");
	attrib.Register();

	attrib.SetName("medigun charge adds crit boost");
	attrib.SetClass("ff2.medigun_with_crits");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "medigun charge adds crit boost");
	attrib.Register();

	attrib.SetName("mod stun boss on hit");
	attrib.SetClass("ff2.mod_stun_on_hit");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod stun boss on hit");
	attrib.Register();

	attrib.SetName("mod rage loss on hit");
	attrib.SetClass("ff2.mod_rage_on_hit");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod rage loss on hit");
	attrib.Register();

	attrib.SetName("jarate is rage loss");
	attrib.SetClass("ff2.jarate_rage");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "jarate is rage loss");
	attrib.Register();

	attrib.SetName("melee sickle climb");
	attrib.SetClass("ff2.mod_melee_climb");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "melee sickle climb");
	attrib.Register();

	attrib.SetName("milk limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_1");
	attrib.SetCustom("description_ff2_string", "milk limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("hit stale DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_2");
	attrib.SetCustom("description_ff2_string", "hit stale DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("sentry death DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_3");
	attrib.SetCustom("description_ff2_string", "sentry death DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("jarate limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_4");
	attrib.SetCustom("description_ff2_string", "jarate limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("boost limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_5");
	attrib.SetCustom("description_ff2_string", "boost limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("teleport no spawn DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_6");
	attrib.SetCustom("description_ff2_string", "teleport no spawn DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("vaccinator DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_7");
	attrib.SetCustom("description_ff2_string", "vaccinator DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("cloak on hit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_8");
	attrib.SetCustom("description_ff2_string", "cloak on hit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("cloak and dagger no DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_9");
	attrib.SetCustom("description_ff2_string", "cloak and dagger no DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("laugh is slow DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_10");
	attrib.SetCustom("description_ff2_string", "laugh is slow DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("caber boss crit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_11");
	attrib.SetCustom("description_ff2_string", "caber boss crit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("start with uber DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_12");
	attrib.SetCustom("description_ff2_string", "start with uber DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("mark limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_13");
	attrib.SetCustom("description_ff2_string", "mark limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("health drop on damage DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_14");
	attrib.SetCustom("description_ff2_string", "health drop on damage DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("resist effects stuns DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_15");
	attrib.SetCustom("description_ff2_string", "resist effects stuns DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("kill effects boss hits DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_16");
	attrib.SetCustom("description_ff2_string", "kill effects boss hits DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("backstabs DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_17");
	attrib.SetCustom("description_ff2_string", "backstabs DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("disguise resistance DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_18");
	attrib.SetCustom("description_ff2_string", "disguise resistance DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("sapper boss effect DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_19");
	attrib.SetCustom("description_ff2_string", "sapper boss effect DISPLAY ONLY");
	attrib.Register();
	
	delete attrib;
}
#endif

void CustomAttrib_PlayerDeath(int client)
{
	HasCritGlow[client] = 0;
}

void CustomAttrib_OnHitBossPre(int attacker, int victim, float &damage, int &damagetype, int weapon, int damagecustom, int &critType)
{
	float value = CustomAttrib_FindOnWeapon(attacker, weapon, "damage vs bosses", true);
	if(value != 1.0)
		damage *= value;

	value = CustomAttrib_FindOnWeapon(attacker, weapon, "multi boss rage", true);
	if(value != 1.0)
		Client(victim).RageDebuff *= value;
	
	if(damagecustom == TF_CUSTOM_BURNING || damagecustom == TF_CUSTOM_BLEEDING || damagecustom == TF_CUSTOM_BURNING_FLARE || damagecustom == TF_CUSTOM_BURNING_ARROW)
		return;

	if(TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
	{
		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mid-air damage vs bosses", true);
		if(value != 1.0)
		{
			damage *= value;
			
			if(CustomAttrib_FindOnWeapon(attacker, weapon, "mod crit while airborne"))
			{
				if(!Attributes_OnBackstabBoss(attacker, victim, damage, weapon, false))
				{
					EmitGameSoundToClient(victim, "TFPlayer.DoubleDonk", attacker);
					EmitGameSoundToClient(attacker, "TFPlayer.DoubleDonk", victim);
					
					if(MultiBosses())
					{
						Bosses_PlaySoundToAll(victim, "sound_marketed", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					else
					{
						Bosses_PlaySoundToAll(victim, "sound_marketed", _, _, _, _, _, 2.0);
					}
				}
				
				CustomAttrib_OnBackstabBoss(victim, damage, weapon);
				
				Bosses_UseSlot(victim, 7, 7);
			}
		}
	}
	
	value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod stun boss on hit");
	if(value)
		TF2_StunPlayer(victim, value, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
	
	value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod rage loss on hit");
	if(value)
		ApplyRage(victim, attacker, -value);
	
	if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		if(critType != 2 && !(damagetype & DMG_CRIT))
		{
			value = float(critType);
			if(CustomAttrib_Get(weapon, "mod crit type on bosses", value))
				critType = RoundFloat(value);
		}
		
		value = CustomAttrib_FindOnWeapon(attacker, weapon, "charge outlines bosses");
		if(value > 0.0)
		{
			if(HasEntProp(weapon, Prop_Send, "m_flChargedDamage"))
			{
				value *= 1.0 + (GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") / 50.0);
			}
			else if(HasEntProp(weapon, Prop_Send, "m_flMinicritCharge"))
			{
				value *= 1.0 + (GetEntPropFloat(weapon, Prop_Send, "m_flMinicritCharge") / 50.0);
			}
			else
			{
				value *= 1.0 + ((GetEntPropFloat(attacker, Prop_Send, "m_flHypeMeter") + GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter")) / 50.0);
			}
			
			Gamemode_SetClientGlow(victim, value);
		}

		char buffer[36];
		if(CustomAttrib_GetString(weapon, "mod attribute hit stale", buffer, sizeof(buffer)))
		{
			char buffers[2][16];
			ExplodeString(buffer, ";", buffers, sizeof(buffers), sizeof(buffers[]));
			
			int attrib = StringToInt(buffers[0]);
			if(attrib)
			{
				SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
				
				float initial = 1.0;
				if(TF2ED_GetAttributeName(attrib, buffer, sizeof(buffer)))
				{
					Attrib_Get(weapon, buffer, initial);
					Attrib_Set(weapon, buffer, initial + StringToFloat(buffers[1]));
				}
			}
		}
		
		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod fire rate hit stale");
		if(value != 0.0)
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "fire rate penalty", initial);
			Attrib_Set(weapon, "fire rate penalty", initial + value);
		}

		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod reload time hit stale");
		if(value != 0.0)
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "Reload time increased", initial);
			Attrib_Set(weapon, "Reload time increased", initial + value);
		}

		if(GetEntityClassname(weapon, buffer, sizeof(buffer)))
		{
			int slot = TF2_GetClassnameSlot(buffer);
			if(slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee)
			{
				static const char AttribName[][] = { "primary damage vs bosses", "secondary damage vs bosses", "melee damage vs bosses" };
				value = CustomAttrib_FindOnPlayer(attacker, AttribName[slot], true);
				if(value != 1.0)
					damage *= value;
			}

			if(StrEqual(buffer, "tf_weapon_stickbomb"))
			{
				// Ullapool Caber gets a critical explosion
				if(!GetEntProp(weapon, Prop_Send, "m_iDetonated"))
				{
					damagetype |= DMG_CRIT;
					critType = 2;
					
					if(MultiBosses())
					{
						Bosses_PlaySoundToAll(victim, "sound_cabered", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
					}
					else
					{
						Bosses_PlaySoundToAll(victim, "sound_cabered", _, _, _, _, _, 2.0);
					}
				}
			}
		}
	}
	
	if((!critType && !(damagetype & DMG_CRIT)) && ((TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && Attrib_FindOnWeapon(attacker, weapon, "rocketjump attackrate bonus")) ||
	   ((TF2_IsPlayerInCondition(attacker, TFCond_Disguised) || TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved)) && Attrib_FindOnWeapon(attacker, weapon, "damage bonus while disguised"))))
	{
		critType = 1;
	}
}

void CustomAttrib_OnHitBossPost(int attacker, int newPlayerDamage, int lastPlayerDamage)
{
	float value = CustomAttrib_FindOnPlayer(attacker, "primary ammo from damage");
	if(value)
	{
		int ammo = DamageGoal(RoundFloat(value), newPlayerDamage, lastPlayerDamage);
		if(ammo)
		{
			if(value < 0.0)
				ammo = -ammo;
			
			ammo += GetEntProp(attacker, Prop_Data, "m_iAmmo", _, 1);
			if(ammo < 0)
				ammo = 0;
			
			SetEntProp(attacker, Prop_Data, "m_iAmmo", ammo, _, 1);
		}
	}

	value = CustomAttrib_FindOnPlayer(attacker, "secondary ammo from damage");
	if(value)
	{
		int ammo = DamageGoal(RoundFloat(value), newPlayerDamage, lastPlayerDamage);
		if(ammo)
		{
			if(value < 0.0)
				ammo = -ammo;
			
			ammo += GetEntProp(attacker, Prop_Data, "m_iAmmo", _, 2);
			if(ammo < 0)
				ammo = 0;
			
			SetEntProp(attacker, Prop_Data, "m_iAmmo", ammo, _, 2);
		}
	}
}

void CustomAttrib_OnAirblastBoss(int victim, int attacker)
{
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(weapon != -1)
	{
		float value;
		if(CustomAttrib_Get(weapon, "mod airblast stale", value))
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "mult airblast refire time", initial);
			Attrib_Set(weapon, "mult airblast refire time", initial + value);
		}

		if(CustomAttrib_Get(weapon, "mod airblast rage", value))
			ApplyRage(victim, attacker, value);
	}
}

void CustomAttrib_OnBackstabBoss(int victim, float &damage, int weapon, float &time = 0.0, float &multi = 0.0)
{
	if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		CustomAttrib_Get(weapon, "backstab damage percent", multi);
		if(multi > 0.0)
			damage = float(Client(victim).MaxHealth * Client(victim).MaxLives) * multi / 3.0;
		
		CustomAttrib_Get(weapon, "backstab stale restore", time);
		CustomAttrib_Get(weapon, "backstab stale multi", multi);
	}
}

void CustomAttrib_OnJarateBoss(int victim, int attacker, int weapon, float &jarate)
{
	float value;
	if(CustomAttrib_Get(weapon, "jarate is rage loss", value))
	{
		ApplyRage(victim, attacker, value);
		jarate = 0.0;
	}
}

void CustomAttrib_OnInventoryApplication(int userid)
{
	RequestFrame(WeaponSwitchFrame, userid);
}

void CustomAttrib_OnWeaponSwitch(int client)
{
	RequestFrame(WeaponSwitchFrame, GetClientUserId(client));
}

static void WeaponSwitchFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
		{
			TFClassType class = TF2_GetPlayerClass(client);

			switch(HasCritGlow[client])
			{
				case 1:
				{
					TF2_RemoveCondition(client, (class == TFClass_Scout || class == TFClass_Heavy) ? TFCond_Buffed : TFCond_CritCola);
				}
				case 2:
				{
					TF2_RemoveCondition(client, TFCond_CritOnDamage);
				}
			}
			
			float type = 0.0;
			CustomAttrib_Get(weapon, "mod crit type glow", type);
			switch(RoundFloat(type))
			{
				case 1:
				{
					TF2_AddCondition(client, (class == TFClass_Scout || class == TFClass_Heavy) ? TFCond_Buffed : TFCond_CritCola);
					HasCritGlow[client] = 1;
				}
				case 2:
				{
					TF2_AddCondition(client, TFCond_CritOnDamage);
					HasCritGlow[client] = 2;
				}
				default:
				{
					HasCritGlow[client] = 0;
				}
			}
		}
	}
}

void CustomAttrib_OnUberDeployed(int client)
{
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(weapon != -1)
	{
		char classname[36];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun"))
		{
			if(CustomAttrib_Get(weapon, "medigun charge adds crit boost"))
			{
				CreateTimer(0.4, UberTimer, EntIndexToEntRef(weapon), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

static Action UberTimer(Handle timer, int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if(weapon != -1)
	{
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if(client != -1 && IsPlayerAlive(client))
		{
			if(GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") > 0.05)
			{
				if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon)
				{
					TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);

					if(GetEntProp(weapon, Prop_Send, "m_bHealing"))
					{
						int target = GetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget");
						if(target != -1)
							TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					}
				}

				return Plugin_Continue;
			}
		}
	}
	
	return Plugin_Stop;
}

static void ApplyRage(int victim, int attacker, float amount)
{
	if(Client(victim).RageDamage > 0.0)
	{
		float rage = Client(victim).GetCharge(0);
		float maxrage = Client(victim).RageMax;
		if(rage < maxrage)
		{
			rage += amount;
			if(rage > maxrage)
			{
				Bosses_PlaySoundToAll(victim, "sound_full_rage", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
				rage = maxrage;
			}
			else if(rage < 0.0)
			{
				rage = 0.0;
			}
			
			Client(victim).SetCharge(0, rage);

			rage = amount / 100.0 * Client(victim).RageDamage;
			Client(attacker).Assist += RoundFloat(GetClientTeam(victim) == GetClientTeam(attacker) ? rage : -rage);
		}
	}
}

void CustomAttrib_CalcIsAttackCritical(int client, int weapon)
{
	float damage;
	if(CustomAttrib_Get(weapon, "melee sickle climb"))
	{
		float pos[3];
		float ang[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		
		Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SOLID, RayType_Infinite, TraceRay_DontHitSelf, client);

		if(TR_DidHit(trace) && TR_GetEntityIndex(trace) == 0)
		{
			float vec[3];
			TR_GetPlaneNormal(trace, vec);
			GetVectorAngles(vec, vec);

			if(vec[0] < 30.0 || vec[0] > 330.0)
			{
				if(vec[0] > -30.0)
				{
					TR_GetEndPosition(vec);

					if(GetVectorDistance(pos, vec, true) < 10000.0)
					{
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
						vec[2] = 600.0;
						TeleportEntity(client, _, _, vec);

						if(damage > 0.0)
							SDKHooks_TakeDamage(client, client, client, damage, DMG_CLUB, 0);

						ClientCommand(client, "playgamesound player/taunt_clip_spin.wav");
					}
				}
			}
		}

		delete trace;
	}
}

static bool TraceRay_DontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}
