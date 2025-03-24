#tryinclude <cwx>

#pragma semicolon 1
#pragma newdecls required

#define CWX_LIBRARY		"cwx"
#define FILE_WEAPONS	"data/freak_fortress_2/loadout.cfg"

#if defined __cwx_included
static bool Loaded;
#endif

static ArrayList LoadoutList;

void Weapons_PluginStart()
{
	RegFreakCmd("classinfo", Weapons_ChangeMenuCmd, "View Weapon Changes", FCVAR_HIDDEN);
	RegFreakCmd("weapons", Weapons_ChangeMenuCmd, "View Weapon Changes");
	RegFreakCmd("weapon", Weapons_ChangeMenuCmd, "View Weapon Changes", FCVAR_HIDDEN);
	RegAdminCmd("ff2_refresh", Weapons_DebugRefresh, ADMFLAG_CHEATS, "Refreshes weapons and attributes");
	RegAdminCmd("ff2_reloadweapons", Weapons_DebugReload, ADMFLAG_RCON, "Reloads the weapons config");
	
	#if defined __cwx_included
	Loaded = LibraryExists(CWX_LIBRARY);
	#endif
}

public void Weapons_LibraryAdded(const char[] name)
{
	#if defined __cwx_included
	if(!Loaded && StrEqual(name, CWX_LIBRARY))
		Loaded = true;
	#endif
}

public void Weapons_LibraryRemoved(const char[] name)
{
	#if defined __cwx_included
	if(Loaded && StrEqual(name, CWX_LIBRARY))
		Loaded = false;
	#endif
}

void Weapons_PrintStatus()
{
	#if defined __cwx_included
	PrintToServer("'%s' is %sloaded", CWX_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", CWX_LIBRARY);
	#endif
}

static Action Weapons_DebugRefresh(int client, int args)
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

static Action Weapons_DebugReload(int client, int args)
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

static Action Weapons_ChangeMenuCmd(int client, int args)
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
	if(LoadoutList)
	{
		int length = LoadoutList.Length;
		for(int i; i < length; i++)
		{
			DeleteCfg(LoadoutList.Get(i));
		}

		delete LoadoutList;
	}

	if(Enabled || force)
	{
		ConfigMap cfg = new ConfigMap(FILE_WEAPONS);
		if(!cfg)
			return false;

		StringMapSnapshot snap = cfg.Snapshot();

		int entries = snap.Length;
		if(entries)
		{
			char buffer[PLATFORM_MAX_PATH];

			LoadoutList = new ArrayList();

			PackVal val;
			for(int i = 0; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i) + 1;

				char[] key = new char[length];
				snap.GetKey(i, key, length);

				cfg.GetArray(key, val, sizeof(val));

				if(val.tag == KeyValType_Section && val.cfg)
				{
					FormatEx(buffer, sizeof(buffer), "data/freak_fortress_2/%s.cfg", key);
					ConfigMap loadout = new ConfigMap(buffer);
					if(loadout)
					{
						loadout.Set("key", key);
						loadout.Set("name", key);
						ImportValuesIntoConfigMap(val.cfg, loadout);

						int pos = LoadoutList.Push(loadout);
						
						if(LoadoutList.Length > 1)
						{
							bool defaul;
							if(val.cfg.GetBool("default", defaul, false) && defaul)
							{
								LoadoutList.SwapAt(0, pos);
							}
						}
					}
				}
			}

			if(!LoadoutList.Length)
				delete LoadoutList;
		}

		delete snap;
		DeleteCfg(cfg);
	}
	
	return true;
}

bool Weapons_ConfigEnabled()
{
	return LoadoutList && (Attrib_Loaded() || VScript_Loaded());
}

void Weapons_ChangeMenu(int client, int time = MENU_TIME_FOREVER, int page = 0)
{
	if(Client(client).IsBoss)
	{
		char buffer[512];
		if(Bosses_GetBossNameCfg(Client(client).Cfg, buffer, sizeof(buffer), GetClientLanguage(client), "description"))
		{
			Menu menu = new Menu(Weapons_ChangeMenuH);
			
			menu.SetTitle(buffer);
			
			if(time == MENU_TIME_FOREVER && Menu_BackButton(client))
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Back");
				menu.AddItem(NULL_STRING, buffer);
			}
			else
			{
				menu.AddItem(NULL_STRING, buffer, ITEMDRAW_SPACER);
			}
			
			menu.Display(client, time);
		}
	}
	else if(Weapons_ConfigEnabled() && !Client(client).Minion)
	{
		SetGlobalTransTarget(client);
		
		Menu menu = new Menu(Weapons_ChangeMenuH);
		
		char buffer1[32], buffer2[32], loadout[32];
		Client(client).GetLoadout(loadout, sizeof(loadout));
		int loadouts = LoadoutList.Length;

		if(loadouts > 1)
		{
			ConfigMap cfg = FindMatchingLoadout(loadout);
			
			int lang = GetClientLanguage(client);
			if(lang != -1)
			{
				GetLanguageInfo(lang, buffer1, sizeof(buffer1));
				Format(buffer1, sizeof(buffer1), "name_%s", buffer1);
				if(!cfg.Get(buffer1, buffer2, sizeof(buffer2)))
					cfg.Get("name", buffer2, sizeof(buffer2));
			}
			else
			{
				cfg.Get("name", buffer2, sizeof(buffer2));
			}

			menu.SetTitle("%t", "Weapon Menu Variant", buffer2);
		}
		else
		{
			menu.SetTitle("%t", "Weapon Menu");
		}
		
		static const char SlotNames[][] = { "Primary", "Secondary", "Melee", "PDA", "Utility", "Building", "Action" };
		for(int i; i < sizeof(SlotNames); i++)
		{
			FormatEx(buffer2, sizeof(buffer2), "%t", SlotNames[i]);
			
			int entity = TF2U_GetPlayerLoadoutEntity(client, i);
			
			if(entity != -1 && FindWeaponSection(entity, loadout))
			{
				IntToString(EntIndexToEntRef(entity), buffer1, sizeof(buffer1));
				menu.AddItem(buffer1, buffer2);
			}
			else
			{
				menu.AddItem(buffer1, buffer2, ITEMDRAW_DISABLED);
			}
		}
		
		if(loadouts > 1)
		{
			FormatEx(buffer2, sizeof(buffer2), "%t\n ", Client(client).NoChanges ? "Enable Weapon Changes" : "Disable Weapon Changes");
			menu.AddItem(NULL_STRING, buffer2);

			for(int i; i < loadouts; i++)
			{
				ConfigMap cfg = LoadoutList.Get(i);
				
				int lang = GetClientLanguage(client);
				if(lang != -1)
				{
					GetLanguageInfo(lang, buffer1, sizeof(buffer1));
					Format(buffer1, sizeof(buffer1), "name_%s", buffer1);
					if(!cfg.Get(buffer1, buffer2, sizeof(buffer2)))
						cfg.Get("name", buffer2, sizeof(buffer2));
				}
				else
				{
					cfg.Get("name", buffer2, sizeof(buffer2));
				}

				cfg.Get("key", buffer1, sizeof(buffer1));
				
				menu.AddItem(buffer1, buffer2, StrEqual(buffer1, loadout) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}

			menu.ExitBackButton = (time == MENU_TIME_FOREVER && Menu_BackButton(client));
			menu.ExitButton = true;
			menu.DisplayAt(client, page / 7 * 7, time);
		}
		else
		{
			if(time == MENU_TIME_FOREVER && Menu_BackButton(client))
			{
				FormatEx(buffer2, sizeof(buffer2), "%t", "Back");
				menu.AddItem(NULL_STRING, buffer2);
			}
			else
			{
				menu.AddItem(NULL_STRING, buffer1, ITEMDRAW_SPACER);
			}
			
			FormatEx(buffer2, sizeof(buffer2), "%t", Client(client).NoChanges ? "Enable Weapon Changes" : "Disable Weapon Changes");
			menu.AddItem("__nochanges", buffer2);
			
			menu.Pagination = 0;
			menu.ExitButton = true;
			menu.Display(client, time);
		}
	}
}

static int Weapons_ChangeMenuH(Menu menu, MenuAction action, int client, int choice)
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
			char buffer[32];
			menu.GetItem(choice, buffer, sizeof(buffer));
			if(buffer[0])
			{
				if(StrEqual(buffer, "__nochanges"))
				{
					Client(client).NoChanges = !Client(client).NoChanges;
					Weapons_ChangeMenu(client, _, choice);
				}
				else if(choice < 7)
				{
					int entity = EntRefToEntIndex(StringToInt(buffer));
					if(entity != INVALID_ENT_REFERENCE)
						Weapons_ShowChanges(client, entity);
					
					Weapons_ChangeMenu(client, _, choice);
				}
				else if(!Client(client).IsBoss && !Client(client).Minion)
				{
					Client(client).SetLoadout(buffer);

					if(!Enabled)
					{

					}
					else if(RoundStatus < 1)
					{
						TF2_RemoveAllItems(client);
						TF2_RespawnPlayer(client);
					}
					else
					{
						int entity, i;
						while(TF2_GetItem(client, entity, i))
						{
							if(IsPlayerAlive(client))
							{
								SetEntProp(entity, Prop_Send, "m_iAccountID", 0);
							}
							else
							{
								TF2_RemoveItem(client, entity);
							}
						}

						i = 0;
						while(TF2U_GetWearable(client, entity, i))
						{
							if(IsPlayerAlive(client))
							{
								SetEntProp(entity, Prop_Send, "m_iAccountID", 0);
							}
							else
							{
								TF2_RemoveWearable(client, entity);
							}
						}

						Weapons_ChangeMenu(client, _, choice);
					}
				}
			}
			else
			{
				Menu_MainMenu(client);
			}
		}
	}
	return 0;
}

void Weapons_ShowChanges(int client, int entity)
{
	if(!Weapons_ConfigEnabled())
		return;
	
	char cwx[64], loadout[32];
	Client(client).GetLoadout(loadout, sizeof(loadout));
	ConfigMap cfg = FindWeaponSection(entity, loadout, cwx);

	if(!cfg)
		return;

	char localizedWeaponName[64];

	SetGlobalTransTarget(client);
	
	bool found;
	char buffer2[64];

	#if defined __cwx_included
	if(cwx[0])
	{
		KeyValues kv = CWX_GetItemExtData(cwx, "name");
		if(!kv)
			return;
		
		kv.GetString(NULL_STRING, localizedWeaponName, sizeof(localizedWeaponName));
		
		if(cfg.GetBool("strip", found, false) && found)
		{
			CPrintToChat(client, "%t%s: (%t):", "Prefix", localizedWeaponName, "Weapon Stripped");
		}
		else
		{
			CPrintToChat(client, "%t%s:", "Prefix", localizedWeaponName);
		}

		delete kv;
	}
	else
	#endif
	{
		int itemDefIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

		GetEntityClassname(entity, localizedWeaponName, sizeof(localizedWeaponName));

		if(!TF2ED_GetLocalizedItemName(itemDefIndex, localizedWeaponName, sizeof(localizedWeaponName), localizedWeaponName))
			return;

		if(cfg.GetBool("strip", found, false) && found)
		{
			Format(buffer2, sizeof(buffer2), "%t%%s3 (%t):", "Prefix", "Weapon Stripped");
			CReplaceColorCodes(buffer2, client, _, sizeof(buffer2));
			PrintSayText2(client, client, true, buffer2, _, _, localizedWeaponName);
		}
		else
		{
			Format(buffer2, sizeof(buffer2), "%t%%s3:", "Prefix");
			CReplaceColorCodes(buffer2, client, _, sizeof(buffer2));
			PrintSayText2(client, client, true, buffer2, _, _, localizedWeaponName);
		}
	}

	char value[16];
	char desc[64];
	char type[64];

	switch(cfg.GetKeyValType("attributes"))
	{
		case KeyValType_Value:
		{
			int current = 0;

			char key[32];
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
				{
					current += add;
				}
				else
				{
					strcopy(value, sizeof(value), attributes[current]);
				}
				
				PrintThisAttrib(client, attrib, value, type, desc, buffer2, key, sizeof(key));
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
					int attrib = TF2ED_TranslateAttributeNameToDefinitionIndex(key);
					if(attrib != -1)
						PrintThisAttrib(client, attrib, value, type, desc, buffer2, key, length);
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
				FormatValue(val.data, desc, sizeof(desc), "value_is_inverted_percentage");
				FormatValue(val.data, type, sizeof(type), "value_is_additive_percentage");
				PrintToChat(client, "%t", key, value, desc, type, val.data);
			}
		}
		
		delete snap;
	}
}

static void PrintThisAttrib(int client, int attrib, char value[16], char type[64], char desc[64], char buffer2[64], char[] key, int length)
{
	// Not a "removed" attribute
	if(value[0] != 'R')
	{
		// Not a hidden attribute
		if(!TF2ED_GetAttributeDefinitionString(attrib, "hidden", type, sizeof(type)) || !StringToInt(type))
		{
			if(TF2ED_GetAttributeDefinitionString(attrib, "description_ff2_string", desc, sizeof(desc)))
			{
				if(TF2ED_GetAttributeDefinitionString(attrib, "description_ff2_file", type, sizeof(type)))
					LoadTranslations(type);
				
				if(TranslationPhraseExists(desc))
				{
					FormatValue(value, buffer2, sizeof(buffer2), "value_is_percentage");
					FormatValue(value, key, length, "value_is_inverted_percentage");
					FormatValue(value, type, sizeof(type), "value_is_additive_percentage");
					PrintToChat(client, "%t", desc, buffer2, key, type, value);
				}
			}
			else if(TF2ED_GetAttributeDefinitionString(attrib, "description_string", desc, sizeof(desc)))
			{
				TF2ED_GetAttributeDefinitionString(attrib, "description_format", type, sizeof(type));
				FormatValue(value, value, sizeof(value), type);
				PrintSayText2(client, client, true, desc, value);
			}
		}
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

void Weapons_EntityCreated(int entity, const char[] classname)
{
	if(Weapons_ConfigEnabled() && (!StrContains(classname, "tf_wea") || !StrContains(classname, "tf_powerup_bottle")))
		SDKHook(entity, SDKHook_SpawnPost, Weapons_Spawn);
}

static void Weapons_Spawn(int entity)
{
	RequestFrame(Weapons_SpawnFrame, EntIndexToEntRef(entity));
}

static void Weapons_SpawnFrame(int ref)
{
	if(!Weapons_ConfigEnabled())
		return;
	
	int entity = EntRefToEntIndex(ref);
	if(entity == INVALID_ENT_REFERENCE)
		return;
	
	if((HasEntProp(entity, Prop_Send, "m_bDisguiseWearable") && GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")) ||
		(HasEntProp(entity, Prop_Send, "m_bDisguiseWeapon") && GetEntProp(entity, Prop_Send, "m_bDisguiseWeapon")))
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client < 1 || client > MaxClients || Client(client).IsBoss || Client(client).Minion)
		return;
	
	char loadout[32];
	Client(client).GetLoadout(loadout, sizeof(loadout));
	ConfigMap cfg = FindWeaponSection(entity, loadout);
	if(!cfg)
		return;
	
	bool found;
	if(cfg.GetBool("strip", found, false) && found)
		SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);
	
	int current;
	
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
			char value[16], key[64];

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
				
				if(TF2ED_GetAttributeName(attrib, key, sizeof(key)))
				{
					Attrib_Set(entity, key, StringToFloat(value));
				}
				else
				{
					LogError("[Config] Attribute %d is invalid/unloaded in weapons config", attrib);
				}
				
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
				{
					if(!Attrib_SetString(entity, key, attributeValue.data))
						LogError("[Config] Attribute '%s' is invalid/unloaded in weapons config", key);
				}
			}

			delete snap;
		}
	}
	
	cfg = cfg.GetSection("custom");
	if(cfg)
		CustomAttrib_ApplyFromCfg(entity, cfg);
}

static ConfigMap FindMatchingLoadout(const char[] loadou)
{
	static char buffer[32];

	ConfigMap cfg;
	for(int i = LoadoutList.Length - 1; i >= 0; i--)
	{
		cfg = LoadoutList.Get(i);
		if(cfg.Get("key", buffer, sizeof(buffer)) && StrEqual(buffer, loadou))
			break;
	}

	return cfg;
}

static ConfigMap FindWeaponSection(int entity, const char[] loadou, char cwx[64] = "")
{
	char buffer1[64];

	ConfigMap loadout = FindMatchingLoadout(loadou);
	
	#if defined __cwx_included
	if(Loaded && CWX_GetItemUIDFromEntity(entity, cwx, sizeof(cwx)) && CWX_IsItemUIDValid(cwx))
	{
		Format(buffer1, sizeof(buffer1), "CWX.%s", cwx);
		ConfigMap cfg = loadout.GetSection(buffer1);
		if(cfg)
			return cfg;
	}
	#endif
	
	cwx[0] = 0;
	
	ConfigMap cfg = loadout.GetSection("Indexes");
	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
		
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
	
	GetEntityClassname(entity, buffer1, sizeof(buffer1));
	Format(buffer1, sizeof(buffer1), "Classnames.%s", buffer1);
	cfg = loadout.GetSection(buffer1);
	if(cfg)
		return cfg;
	
	return null;
}
