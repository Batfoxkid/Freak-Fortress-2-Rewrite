/*
	void Weapons_PluginLoad()
	void Weapons_PluginStart()
	void Weapons_LibraryAdded(const char[] name)
	void Weapons_LibraryRemoved(const char[] name)
	bool Weapons_ConfigsExecuted(bool force = false)
	void Weapons_ChangeMenu(int client, int time = MENU_TIME_FOREVER)
	void Weapons_ShowChanges(int client, int entity)
	void Weapons_PlayerDeath(int client)
	void Weapons_OnHitBossPre(int attacker, int victim, float &damage, int weapon, int critType)
	float Weapons_PlayerHurt(int entity)
	void Weapons_EntityCreated(int entity, const char[] classname)
*/

#tryinclude <cwx>
#tryinclude <tf_custom_attributes>

#pragma semicolon 1

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
static int HasCritGlow[MAXTF2PLAYERS];

void Weapons_PluginLoad()
{
	#if defined __tf_custom_attributes_included
	MarkNativeAsOptional("TF2CustAttr_GetAttributeKeyValues");
	MarkNativeAsOptional("TF2CustAttr_GetFloat");
	MarkNativeAsOptional("TF2CustAttr_SetString");
	#endif
}

void Weapons_PluginStart()
{
	RegFreakCmd("classinfo", Weapons_ChangeMenuCmd, "View Weapon Changes", FCVAR_HIDDEN);
	RegFreakCmd("weapons", Weapons_ChangeMenuCmd, "View Weapon Changes");
	RegFreakCmd("weapon", Weapons_ChangeMenuCmd, "View Weapon Changes", FCVAR_HIDDEN);
	RegAdminCmd("ff2_refresh", Weapons_DebugRefresh, ADMFLAG_CHEATS, "Refreshes weapons and attributes");
	RegAdminCmd("ff2_reloadweapons", Weapons_DebugReload, ADMFLAG_RCON, "Reloads the weapons config");
	
	#if defined __cwx_included
	CWXLoaded = LibraryExists(CWX_LIBRARY);
	#endif
	
	#if defined __tf_custom_attributes_included
	TCALoaded = LibraryExists(TCA_LIBRARY);
	#endif
}

stock void Weapons_LibraryAdded(const char[] name)
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

stock void Weapons_LibraryRemoved(const char[] name)
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

public Action Weapons_ChangeMenuCmd(int client, int args)
{
	if(client)
	{
		Menu_Command(client);
		Weapons_ChangeMenu(client);
	}
	return Plugin_Handled;
}

bool Weapons_ConfigsExecuted(bool force = false)
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

void Weapons_ChangeMenu(int client, int time = MENU_TIME_FOREVER)
{
	if(Client(client).IsBoss)
	{
		//TODO: How did I not make the boss menu description yet
	}
	else if(WeaponCfg && !Client(client).Minion)
	{
		SetGlobalTransTarget(client);
		
		Menu menu = new Menu(Weapons_ChangeMenuH);
		menu.SetTitle("%t", "Weapon Menu");
		
		static const char SlotNames[][] = { "Primary", "Secondary", "Melee", "PDA", "Utility", "Building", "Action" };
		
		char buffer1[12], buffer2[32];
		for(int i; i < 6; i++)
		{
			FormatEx(buffer2, sizeof(buffer2), "%t", SlotNames[i]);
			
			int entity = GetPlayerWeaponSlot(client, i);
			if(entity != -1 && FindWeaponSection(entity))
			{
				IntToString(EntIndexToEntRef(entity), buffer1, sizeof(buffer1));
				menu.AddItem(buffer1, SlotNames[i]);
			}
			else
			{
				menu.AddItem(buffer1, SlotNames[i], ITEMDRAW_DISABLED);
			}
		}
		
		if(time == MENU_TIME_FOREVER)
		{
			menu.ExitBackButton = Menu_BackButton(client);
		}
		else
		{
			Menu_Command(client);
		}
		
		menu.Display(client, time);
	}
}

public int Weapons_ChangeMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
				Menu_MainMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[12];
			menu.GetItem(choice, buffer, sizeof(buffer));
			int entity = EntRefToEntIndex(StringToInt(buffer));
			if(entity != -1)
				Weapons_ShowChanges(client, entity);
			
			Weapons_ChangeMenu(client);
		}
	}
	return 0;
}

void Weapons_ShowChanges(int client, int entity)
{
	if(!WeaponCfg)
		return;

	ConfigMap cfg = FindWeaponSection(entity);

	if(!cfg)
		return;

	int itemDefIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

	char localizedWeaponName[64];
	GetEntityClassname(entity, localizedWeaponName, sizeof(localizedWeaponName));

	if(!TF2ED_GetLocalizedItemName(itemDefIndex, localizedWeaponName, sizeof(localizedWeaponName), localizedWeaponName))
		return;

	SetGlobalTransTarget(client);
	
	bool found;
	char buffer2[64];
	
	if(cfg.GetBool("strip", found, false))
	{
		Format(buffer2, sizeof(buffer2), "{olive}[FF2] {default}%%s3 (%t):", "Weapon Stripped");
		CReplaceColorCodes(buffer2, client, _, sizeof(buffer2));
		PrintSayText2(client, client, true, buffer2, _, _, localizedWeaponName);
	}
	else
	{
		strcopy(buffer2, sizeof(buffer2), "{olive}[FF2] {default}%s3:");
		CReplaceColorCodes(buffer2, client, _, sizeof(buffer2));
		PrintSayText2(client, client, true, buffer2, _, _, localizedWeaponName);
	}

	char value[16];
	char description[64];
	char type[32];

	switch(cfg.GetKeyValType("attributes"))
	{
		case KeyValType_Value:
		{
			int current = 0;

			char attributes[512];
			cfg.Get("attributes", attributes, sizeof(attributes));

			do
			{
				int add = SplitString(attributes[current], ";", value, sizeof(value));
				if(add == -1)
					break;
				
				int attrib = StringToInt(value);
				if(!attrib)
					break;
				
				current += add;
				add = SplitString(attributes[current], ";", value, sizeof(value));
				found = add != -1;

				if(found)
					current += add;
				else
					strcopy(value, sizeof(value), attributes[current]);
				
				bool isHidden = (TF2ED_GetAttributeDefinitionString(attrib, "hidden", type, sizeof(type)) && StringToInt(type));
				bool doesDescriptionExist = TF2ED_GetAttributeDefinitionString(attrib, "description_string", description, sizeof(description));

				if(value[0] != 'R' && !isHidden && doesDescriptionExist)
				{
					TF2ED_GetAttributeDefinitionString(attrib, "description_format", type, sizeof(type));
					FormatValue(value, value, sizeof(value), type);
					PrintSayText2(client, client, true, description, value);
				}
			} while(found);
		}
		case KeyValType_Section:
		{
			cfg = cfg.GetSection("attributes");

			PackVal attributeValue;

			StringMapSnapshot snap = cfg.Snapshot();

			int entries = snap.Length;

			for(int i = 0; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i) + 1;

				char[] key = new char[length];
				snap.GetKey(i, key, length);
				
				cfg.GetArray(key, attributeValue, sizeof(attributeValue));

				if(attributeValue.tag == KeyValType_Value)
				{
					int attrib = TF2Econ_TranslateAttributeNameToDefinitionIndex(key);

					bool isHidden = (TF2ED_GetAttributeDefinitionString(attrib, "hidden", type, sizeof(type)) && StringToInt(type));
					bool doesDescriptionExist = TF2ED_GetAttributeDefinitionString(attrib, "description_string", description, sizeof(description));

					if(!isHidden && doesDescriptionExist)
					{
						TF2ED_GetAttributeDefinitionString(attrib, "description_format", type, sizeof(type));
						FormatValue(attributeValue.data, value, sizeof(value), type);
						PrintSayText2(client, client, true, description, value);
					}
				}
			}

			delete snap;
		}
	}

	cfg = cfg.GetSection("custom");

	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
			
		int entries = snap.Length;

		PackVal val;

		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i) + 1;

			char[] key = new char[length];
			snap.GetKey(i, key, length);
			
			cfg.GetArray(key, val, sizeof(val));

			if(val.tag == KeyValType_Value && TranslationPhraseExists(key))
			{
				FormatValue(val.data, value, sizeof(value), "value_is_percentage");
				FormatValue(val.data, description, sizeof(description), "value_is_inverted_percentage");
				FormatValue(val.data, type, sizeof(type), "value_is_additive_percentage");
				PrintToChat(client, "%t", key, value, description, type, val.data);
			}
		}
		
		delete snap;
	}
}

static void FormatValue(const char[] value, char[] buffer, int length, const char[] type)
{
	if(StrEqual(type, "value_is_percentage"))
	{
		float val = StringToFloat(value);
		if(val < 1.0 && val > -1.0)
		{
			Format(buffer, length, "%.0f", -(100.0 - (val * 100.0)));
		}
		else
		{
			Format(buffer, length, "%.0f", val * 100.0 - 100.0);
		}
	}
	else if(StrEqual(type, "value_is_inverted_percentage"))
	{
		float val = StringToFloat(value);
		if(val < 1.0 && val > -1.0)
		{
			Format(buffer, length, "%.0f", (100.0 - (val * 100.0)));
		}
		else
		{
			Format(buffer, length, "%.0f", val * 100.0 - 100.0);
		}
	}
	else if(StrEqual(type, "value_is_additive_percentage"))
	{
		float val = StringToFloat(value);
		Format(buffer, length, "%.0f", val * 100.0);
	}
	else if(StrEqual(type, "value_is_particle_index") || StrEqual(type, "value_is_from_lookup_table"))
	{
		buffer[0] = 0;
	}
	else
	{
		strcopy(buffer, length, value);
	}
}

void Weapons_PlayerDeath(int client)
{
	HasCritGlow[client] = 0;
}

stock void Weapons_OnHitBossPre(int attacker, int victim, float &damage, int weapon, int critType)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded && weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
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
			
			if(critType != 2)
				critType = kv.GetNum("mod crit type on bosses", critType);
			
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
		
		delete kv;
	}
	#endif
}

stock void Weapons_OnBackstabBoss(int victim, float &damage, int weapon)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded && weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		float multi = TF2CustAttr_GetFloat(weapon, "backstab damage percent");
		if(multi > 0.0)
			damage = float(Client(victim).MaxHealth * Client(victim).MaxLives) * multi / 3.0;
	}
	#endif
}

stock void Weapons_OnWeaponSwitch(int client, int weapon)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded && weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		switch(HasCritGlow[client])
		{
			case 1:
			{
				TF2_RemoveCondition(client, TF2_GetPlayerClass(client) == TFClass_Scout ? TFCond_Buffed : TFCond_CritCola);
			}
			case 2:
			{
				TF2_RemoveCondition(client, TFCond_CritOnDamage);
			}
		}
		
		int type = TF2CustAttr_GetInt(weapon, "mod crit type glow");
		switch(type)
		{
			case 1:
			{
				TF2_AddCondition(client, TF2_GetPlayerClass(client) == TFClass_Scout ? TFCond_Buffed : TFCond_CritCola);
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
	if(!WeaponCfg)
		return;

	int entity = EntRefToEntIndex(ref);

	if(entity == -1)
		return;

	if((HasEntProp(entity, Prop_Send, "m_bDisguiseWearable") && GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")) ||
		(HasEntProp(entity, Prop_Send, "m_bDisguiseWeapon") && GetEntProp(entity, Prop_Send, "m_bDisguiseWeapon")))
		return;

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!IsClientValid(client) || Client(client).IsBoss || Client(client).Minion)
		return;

	ConfigMap cfg = FindWeaponSection(entity);
	if(!cfg)
		return;

	bool found = false;
	if(cfg.GetBool("strip", found, false) && found)
	{
		TF2Attrib_RemoveAll(entity);

		char valueType[2];
		char valueFormat[64];

		int staticAttribs[16];
		float staticAttribsValues[16];

		int itemDefIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

		TF2Attrib_GetStaticAttribs(itemDefIndex, staticAttribs, staticAttribsValues);

		for(int i = 0; i < 16; i++)
		{
			if(staticAttribs[i] == 0)
				continue;

			// Probably overkill
			if(staticAttribs[i] == 796 || staticAttribs[i] == 724 || staticAttribs[i] == 817 || staticAttribs[i] == 834 
				|| staticAttribs[i] == 745 || staticAttribs[i] == 731 || staticAttribs[i] == 746)
				continue;

			// "stored_as_integer" is absent from the attribute schema if its type is "string".
			// TF2ED_GetAttributeDefinitionString returns false if it can't find the given string.
			if(!TF2ED_GetAttributeDefinitionString(staticAttribs[i], "stored_as_integer", valueType, sizeof(valueType)))
				continue;

			TF2ED_GetAttributeDefinitionString(staticAttribs[i], "description_format", valueFormat, sizeof(valueFormat));

			// Since we already know what we're working with and what we're looking for, we can manually handpick
			// the most significative chars to check if they match. Eons faster than doing StrEqual or StrContains.

			if(valueFormat[9] == 'a' && valueFormat[10] == 'd') // value_is_additive & value_is_additive_percentage
			{
				TF2Attrib_SetByDefIndex(entity, staticAttribs[i], 0.0);
			}
			else if((valueFormat[9] == 'i' && valueFormat[18] == 'p')
				|| (valueFormat[9] == 'p' && valueFormat[10] == 'e')) // value_is_percentage & value_is_inverted_percentage
			{
				TF2Attrib_SetByDefIndex(entity, staticAttribs[i], 1.0);
			}
			else if(valueFormat[9] == 'o' && valueFormat[10] == 'r') // value_is_or
			{
				TF2Attrib_SetByDefIndex(entity, staticAttribs[i], 0.0);
			}
		}
	}

	int current = 0;

	if(cfg.GetInt("clip", current))
	{
		SetEntProp(entity, Prop_Send, "m_iAccountID", 0);
		if(HasEntProp(entity, Prop_Data, "m_iClip1"))
			SetEntProp(entity, Prop_Data, "m_iClip1", current);
	}
	
	if(cfg.GetInt("ammo", current))
	{
		SetEntProp(entity, Prop_Send, "m_iAccountID", 0);
		
		if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
		{
			int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
			if(type >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", current, _, type);
		}
	}
	
	switch(cfg.GetKeyValType("attributes"))
	{
		case KeyValType_Value:
		{
			current = 0;
			char value[16];

			char attributes[512];
			cfg.Get("attributes", attributes, sizeof(attributes));

			do
			{
				int add = SplitString(attributes[current], ";", value, sizeof(value));
				if(add == -1)
					break;
				
				int attrib = StringToInt(value);
				if(!attrib)
					break;
				
				current += add;
				add = SplitString(attributes[current], ";", value, sizeof(value));
				found = add != -1;

				if(found)
					current += add;
				else
					strcopy(value, sizeof(value), attributes[current]);
				
				TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(value));
			} while(found);
		}
		case KeyValType_Section:
		{
			cfg = cfg.GetSection("attributes");

			StringMapSnapshot snap = cfg.Snapshot();
			int entries = snap.Length;

			PackVal attributeValue;

			for(int i = 0; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i) + 1;
				char[] key = new char[length];

				snap.GetKey(i, key, length);
				
				cfg.GetArray(key, attributeValue, sizeof(attributeValue));

				if(attributeValue.tag == KeyValType_Value)
					TF2Attrib_SetByName(entity, key, StringToFloat(attributeValue.data));
			}

			delete snap;
		}
	}
	
	cfg = cfg.GetSection("custom");

	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();

		int entries = snap.Length;

		PackVal attribute;

		for(int i = 0; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i) + 1;

			char[] key = new char[length];
			snap.GetKey(i, key, length);
				
			cfg.GetArray(key, attribute, sizeof(attribute));

			if(attribute.tag == KeyValType_Value)
			{
				#if defined __tf_custom_attributes_included
				if(TCALoaded)
				{
					TF2CustAttr_SetString(entity, key, attribute.data);
				}
				else
				#endif
				{
					if(StrEqual(key, "damage vs bosses"))
					{
						TF2Attrib_SetByDefIndex(entity, 476, StringToFloat(attribute.data));
					}
					else if(StrEqual(key, "mod crit type on bosses"))
					{
						TF2Attrib_SetByDefIndex(entity, 20, 1.0);
						TF2Attrib_SetByDefIndex(entity, 408, 1.0);

						if(StringToInt(attribute.data) == 1)
							TF2Attrib_SetByDefIndex(entity, 868, 1.0);
					}
				}
			}
		}
		
		delete snap;
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
				for(int i; i < entries; i++)
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