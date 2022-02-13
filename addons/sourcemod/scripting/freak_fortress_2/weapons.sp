/*
	void Weapons_PluginStart()
	void Weapons_LibraryAdded(const char[] name)
	void Weapons_LibraryRemoved(const char[] name)
	bool Weapons_ConfigsExecuted(bool force=false)
	void Weapons_OnHitBossPre(int attacker, int victim, float &damage, int &damagetype, int weapon)
	void Weapons_EntityCreated(int entity, const char[] classname)
*/

#tryinclude <cwx>
#tryinclude <tf_custom_attributes>

#define CWX_LIBRARY		"cwx"
#define TCA_LIBRARY		"tf2custattr"
#define FILE_WEAPONS	"data/freak_fortress_2/weapons.cfg"

#if defined __cwx_included
static bool CWXLoaded;
#endif

#if defined __tf_custom_attributes_included
static bool TCALoaded;
#endif

static ConfigMap WeaponCfg;

void Weapons_PluginStart()
{
	RegAdminCmd("ff2_refresh", Weapons_DebugRefresh, ADMFLAG_CHEATS, "Refreshes weapons and attributes");
	RegAdminCmd("ff2_reloadweapons", Weapons_DebugReload, ADMFLAG_RCON, "Reloads the weapons config");
	
	#if defined __cwx_included
	CWXLoaded = LibraryExists(CWX_LIBRARY);
	#endif
	
	#if defined __tf_custom_attributes_included
	TCALoaded = LibraryExists(TCA_LIBRARY);
	#endif
}

void Weapons_LibraryAdded(const char[] name)
{
	#if defined __cwx_included
	if(!CWXLoaded)
		CWXLoaded = StrEqual(name, CWX_LIBRARY);
	#endif
	
	#if defined __tf_custom_attributes_included
	if(!TCALoaded)
		TCALoaded = StrEqual(name, TCA_LIBRARY);
	#endif
}

void Weapons_LibraryRemoved(const char[] name)
{
	#if defined __cwx_included
	if(CWXLoaded)
		CWXLoaded = !StrEqual(name, CWX_LIBRARY);
	#endif
	
	#if defined __tf_custom_attributes_included
	if(TCALoaded)
		TCALoaded = !StrEqual(name, TCA_LIBRARY);
	#endif
}

public Action Weapons_DebugRefresh(int client, int args)
{
	TF2_RemoveAllItems(client);
	
	int entity, i;
	while(TF2U_GetWearable(client, entity, i))
	{
		TF2_RemoveWearable(client, entity);
	}
	
	TF2_RegeneratePlayer(client);
	return Plugin_Handled;
}

public Action Weapons_DebugReload(int client, int args)
{
	if(Weapons_ConfigsExecuted(true))
	{
		FReplyToCommand(client, "Reloaded");
	}
	else if(client && CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON))
	{
		FReplyToCommand(client, "Config Error, use sm_rcon to print errors");
	}
	else
	{
		FReplyToCommand(client, "Config Error");
	}
	return Plugin_Handled;
}

bool Weapons_ConfigsExecuted(bool force=false)
{
	ConfigMap cfg;
	if(Enabled || force)
	{
		cfg = new ConfigMap(FILE_WEAPONS);
		if(!cfg)
			return false;
	}
	
	if(WeaponCfg)
	{
		DeleteCfg(WeaponCfg);
		WeaponCfg = null;
	}
	
	if(Enabled || force)
		WeaponCfg = cfg;
	
	return true;
}

stock void Weapons_OnHitBossPre(int attacker, int victim, float &damage, int &damagetype, int weapon)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded && weapon > MaxClients)
	{
		KeyValues kv = TF2CustAttr_GetAttributeKeyValues(weapon);
		if(kv)
		{
			float value = kv.GetFloat("damage vs bosses", 1.0);
			if(value != 1.0)
				damage *= value;
			
			value = kv.GetFloat("charge outlines bosses");
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
					value *= 1.0 + ((GetEntPropFloat(weapon, Prop_Send, "m_flHypeMeter") + GetEntPropFloat(weapon, Prop_Send, "m_flRageMeter")) / 50.0);
				}
				
				Gamemode_SetClientGlow(victim, value);
			}
			
			if(!(damagetype & DMG_CRIT))
			{
				int crit = kv.GetNum("mod crit type on bosses");
				if(crit > 1)
				{
					damagetype |= DMG_CRIT;
				}
				else if(crit)
				{
					TF2_AddCondition(attacker, TFCond_MiniCritOnKill, 0.001);
				}
			}
			
			char buffer[36];
			if(GetEntityClassname(weapon, buffer, sizeof(buffer)))
			{
				int slot = TF2_GetClassnameSlot(buffer);
				if(slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee)
				{
					int entity, i;
					while(TF2_GetItem(attacker, entity, i))
					{
						if(entity == weapon)
							continue;
						
						static const char AttribName[][] = { "primary damage vs bosses", "secondary damage vs bosses", "melee damage vs bosses" };
						value = TF2CustAttr_GetFloat(entity, AttribName[slot], 1.0);
						if(value != 1.0)
							damage *= value;
					}
				}
			}
		}
	}
	#endif
}

stock float Weapons_PlayerHurt(int entity)
{
	float value = 1.0;
	
	/*#if defined __tf_custom_attributes_included
	if(TCALoaded)
		value = TF2CustAttr_GetFloat(entity, "multi boss rage", 1.0);
	#endif**/
	
	return value;
}

void Weapons_EntityCreated(int entity, const char[] classname)
{
	if(WeaponCfg && (!StrContains(classname, "tf_wea") || !StrContains(classname, "tf_powerup_bottle")))
		SDKHook(entity, SDKHook_SpawnPost, Weapons_Spawn);
}

public void Weapons_Spawn(int entity)
{
	RequestFrame(Weapons_SpawnFrame, EntIndexToEntRef(entity));
}

public void Weapons_SpawnFrame(int ref)
{
	if(WeaponCfg)
	{
		int entity = EntRefToEntIndex(ref);
		if(entity > MaxClients)
		{
			int client = GetEntPropEnt(client, Prop_Send, "m_hOwnerEntity");
			if(client > 0 && client <= MaxClients && !Client(client).IsBoss && !Client(client).Minion)
			{
				ConfigMap cfg = FindWeaponSection(entity);
				if(cfg)
				{
					bool found;
					if(cfg.GetBool("strip", found, false))	// TODO: If this strips SOC attribs, use TF2Attrib_GetSOCAttribs to give em back
						SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", found, 1);
					
					int current;
					if(cfg.GetInt("clip", current))
						SetEntProp(entity, Prop_Data, "m_iClip1", current);
					
					if(cfg.GetInt("ammo", current))
					{
						int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
						if(type >= 0)
							SetEntProp(client, Prop_Data, "m_iAmmo", current, _, type);
					}
					
					char attributes[512];
					if(cfg.Get("attributes", attributes, sizeof(attributes)))
					{
						current = 0;
						char buffer[16];
						do
						{
							int add = SplitString(attributes[current], ";", buffer, sizeof(buffer));
							if(add == -1)
								break;
							
							int attrib = StringToInt(buffer);
							if(!attrib)
								break;
							
							current += add;
							add = SplitString(attributes[current], ";", buffer, sizeof(buffer));
							found = add != -1;
							if(found)
							{
								current += add;
							}
							else
							{
								strcopy(buffer, sizeof(buffer), attributes[current]);
							}
							
							TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(buffer));
						} while(found);
					}
					
					#if defined __tf_custom_attributes_included
					if(TCALoaded)
					{
						cfg = cfg.GetSection("custom");
						if(cfg)
						{
							StringMapSnapshot snap = cfg.Snapshot();
							if(snap)
							{
								int entries = snap.Length;
								if(entries)
								{
									PackVal val;
									for(int i; i<entries; i++)
									{
										int length = snap.KeyBufferSize(i)+1;
										char[] key = new char[length];
										snap.GetKey(i, key, length);
										
										cfg.GetArray(key, val, sizeof(val));
										if(val.tag == KeyValType_Value)
											TF2CustAttr_SetString(entity, key, val.data);
									}
								}
								
								delete snap;
							}
						}
					}
					#endif
				}
			}
		}
	}
}

static ConfigMap FindWeaponSection(int entity)
{
	char buffer1[64];
	
	#if defined __cwx_included
	if(CWXLoaded && CWX_GetItemUIDFromEntity(entity, buffer1, sizeof(buffer1)) && CWX_IsItemUIDValid(buffer1))
	{
		Format(buffer1, sizeof(buffer1), "CWX.%s", buffer1);
		ConfigMap cfg = WeaponCfg.GetSection(buffer1);
		if(cfg)
			return cfg;
	}
	#endif
	
	ConfigMap cfg = WeaponCfg.GetSection("Indexes");
	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
		if(snap)
		{
			int entries = snap.Length;
			if(entries)
			{
				int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
				char buffer2[12];
				for(int i; i<entries; i++)
				{
					int length = snap.KeyBufferSize(i)+1;
					char[] key = new char[length];
					snap.GetKey(i, key, length);
					
					bool found;
					int current;
					do
					{
						int add = SplitString(key[current], " ", buffer2, sizeof(buffer2));
						found = add != -1;
						if(found)
						{
							current += add;
						}
						else
						{
							strcopy(buffer2, sizeof(buffer2), key[current]);
						}
						
						if(StringToInt(buffer2) == index)
						{
							PackVal val;
							cfg.GetArray(key, val, sizeof(val));
							if(val.tag == KeyValType_Section)
							{
								delete snap;
								return val.cfg;
							}
							
							break;
						}
					} while(found);
				}
			}
			
			delete snap;
		}
	}
	
	GetEntityClassname(entity, buffer1, sizeof(buffer1));
	Format(buffer1, sizeof(buffer1), "Classnames.%s", buffer1);
	cfg = WeaponCfg.GetSection(buffer1);
	if(cfg)
		return cfg;
	
	return null;
}