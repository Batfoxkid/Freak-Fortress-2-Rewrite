#tryinclude <vscript>

#pragma semicolon 1
#pragma newdecls required

#define VSCRIPT_LIBRARY	"vscript"
#define SCRIPT_VERSION	2

static char ReturnString[256];
static float ReturnFloat;

#if defined _vscript_included
static bool Loaded;
static ScriptCall ScriptGetAttribute;
static ScriptCall ScriptSetAttribute;
static ScriptCall ScriptRemoveAttribute;
#if defined IS_MAIN_FF2
static ScriptCall ScriptFireScriptHook;
#endif
#endif

void VScript_PluginStart()
{
	HookEvent("tf_map_time_remaining", VScriptEvent, EventHookMode_Pre);
	
	#if defined _vscript_included
	Loaded = LibraryExists(VSCRIPT_LIBRARY);
	if(Loaded)
	{
		SetupCalls();
		#if defined IS_MAIN_FF2
		SetupFunctions();
		if(VScript_IsVMInitialized())
			VScript_OnVMInitialized();
		#endif
	}
	#endif

	int version;
	File file = OpenFile("scripts/vscripts/freak_fortress_2.nut", "r", true);
	if(file)
	{
		char buffer[24];
		file.ReadString(buffer, sizeof(buffer));
		int pos = StrContains(buffer, "SCRIPT_VERSION <- ");
		if(pos != -1)
		{
			version = StringToInt(buffer[pos + 18]);
			if(version == SCRIPT_VERSION)
				return;
		}
		
		delete file;
	}

	SetFailState("VScript file \"freak_fortress_2.nut\" is outdated (expected v%d, got v%d)", SCRIPT_VERSION, version);
}

#if defined _vscript_included
static void SetupCalls()
{
	ScriptSetAttribute = new ScriptCall("FF2_SetAttribute", ScriptField_Void, ScriptField_HScript, ScriptField_String, ScriptField_Float);
	ScriptGetAttribute = new ScriptCall("FF2_GetAttribute", ScriptField_Float, ScriptField_HScript, ScriptField_String, ScriptField_Float);
	ScriptRemoveAttribute = new ScriptCall("FF2_RemoveAttribute", ScriptField_Void, ScriptField_HScript, ScriptField_String);

	#if defined IS_MAIN_FF2
	ScriptFireScriptHook = new ScriptCall("FireScriptHook", ScriptField_Bool, ScriptField_String, ScriptField_HScript);
	#endif
}
#endif

public void VScript_LibraryAdded(const char[] name)
{
	#if defined _vscript_included
	if(!Loaded && StrEqual(name, VSCRIPT_LIBRARY))
	{
		Loaded = true;
		SetupCalls();
		#if defined IS_MAIN_FF2
		SetupFunctions();
		if(VScript_IsVMInitialized())
			VScript_OnVMInitialized();
		#endif
	}
	#endif
}

public void VScript_LibraryRemoved(const char[] name)
{
	#if defined _vscript_included
	if(Loaded && StrEqual(name, VSCRIPT_LIBRARY))
		Loaded = false;
	#endif
}

stock void VScript_PrintStatus()
{
	#if defined _vscript_included
	PrintToServer("'%s' is %sloaded", VSCRIPT_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", VSCRIPT_LIBRARY);
	#endif
}

static Action VScriptEvent(Event event, const char[] name, bool dontBroadcast)
{
	static char buffer[128];
	event.GetString("id", buffer, sizeof(buffer));
	if(StrEqual(buffer, "freak_fortress_2"))
	{
		event.GetString("event", buffer, sizeof(buffer));
		if(StrEqual(buffer, "returning"))
		{
			event.GetString("returnstring", ReturnString, sizeof(ReturnString));
			ReturnFloat = event.GetFloat("returnfloat");
		}
	}

	return Plugin_Continue;
}

stock bool VScript_GetAttribute(int entity, const char[] name, float &value)
{
	ReturnFloat = -999.9;	

	#if defined _vscript_included
	if(Loaded && ScriptGetAttribute)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity);
		if(hentity && ScriptGetAttribute.Execute(hentity, name, ReturnFloat) == ScriptStatus_Done)
			ReturnFloat = ScriptGetAttribute.GetReturnFloat();
	}
	else
	#endif
	{
		Format(ReturnString, sizeof(ReturnString), "_FF2_GetAttribute(\"%s\")", name);
		SetVariantString(ReturnString);
		AcceptEntityInput(0, "RunScriptCode", entity, entity);
	}

	if(ReturnFloat == -999.9)
		return false;
	
	value = ReturnFloat;
	return true;
}

stock void VScript_SetAttribute(int entity, const char[] name, float value)
{
	#if defined _vscript_included
	if(Loaded && ScriptSetAttribute)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity, true);
		if(hentity)
			ScriptSetAttribute.Execute(hentity, name, value);
		
		return;
	}
	#endif
	
	Format(ReturnString, sizeof(ReturnString), "_FF2_SetAttribute(\"%s\", %f)", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_SetAttributeInt(int entity, const char[] name, int value)
{
	#if defined _vscript_included
	if(Loaded && ScriptSetAttribute)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity, true);
		if(hentity)
			ScriptSetAttribute.Execute(hentity, name, value);
		
		return;
	}
	#endif

	Format(ReturnString, sizeof(ReturnString), "_FF2_SetAttribute(\"%s\", casti2f(%d))", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

public void VScript_SetAttributeTable(int entity, const char[] name, float value)
{
	#if defined _vscript_included
	if(Loaded)
	{
		ScriptHandle scope = VScript_GetEntityScriptScope(entity, true);
		if(scope)
		{
			ScriptHandle table = VScript_GetValueHScript(scope, "ff2attributes");
			if(!table)
				table = VScript_CreateTable();
			
			VScript_SetValueFloat(table, name, value);

			delete table;
		}
		
		return;
	}
	#endif
}

stock void VScript_RemoveAttribute(int entity, const char[] name)
{
	#if defined _vscript_included
	if(Loaded && ScriptRemoveAttribute)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity);
		if(hentity)
			ScriptRemoveAttribute.Execute(hentity, name);
		
		return;
	}
	#endif

	Format(ReturnString, sizeof(ReturnString), "_FF2_RemoveAttribute(\"%s\")", name);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

public void VScript_UpdateKey(int client, const char[] key, const char[] value)
{
	#if defined _vscript_included
	if(Loaded)
	{
		ScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			char subkey[256];
			strcopy(subkey, sizeof(subkey), key);
			ScriptHandle table = FindTableKey(scope, subkey, sizeof(subkey), true);
			if(table)
			{
				VScript_SetValueString(table, subkey, value);
				delete table;
			}
		}
	}
	#endif
}

public void VScript_DeleteKey(int client, const char[] key)
{
	#if defined _vscript_included
	if(Loaded)
	{
		ScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			char subkey[256];
			strcopy(subkey, sizeof(subkey), key);
			ScriptHandle table = FindTableKey(scope, subkey, sizeof(subkey), false);
			if(table)
			{
				VScript_ClearValue(table, key);
				delete table;
			}
		}
	}
	#endif
}

public void VScript_WeaponChanged(int client, int weapon)
{
	#if defined _vscript_included
	if(Loaded && ScriptFireScriptHook)
	{
		ScriptHandle hclient = VScript_EntityToHScript(client);
		ScriptHandle hweapon = VScript_EntityToHScript(weapon);

		if(hclient && hweapon)
		{
			ScriptHandle params = VScript_CreateTable();
			VScript_SetValueHScript(params, "client", hclient);
			VScript_SetValueHScript(params, "weapon", hweapon);

			ScriptFireScriptHook.Execute("FF2_OnWeaponChanged", params);

			delete params;
		}
	}
	#endif
}

#if defined _vscript_included
public void VScript_UpdateKeyScript(int client, const char[] key, ScriptHandle value)
{
	if(Loaded)
	{
		ScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			char subkey[256];
			strcopy(subkey, sizeof(subkey), key);
			ScriptHandle table = FindTableKey(scope, subkey, sizeof(subkey), true);
			if(table)
			{
				VScript_SetValueHScript(table, subkey, value);
				delete table;
			}
		}
	}
}

// @note            The returned handle must be closed when no longer needed.
static ScriptHandle FindTableKey(ScriptHandle scope, char[] key, int size, bool generate)
{
	ScriptHandle table = VScript_GetValueHScript(scope, "ff2boss");
	if(table)
	{
		for(int pos = 0;;)
		{
			int length = FindCharInString(key[pos], '.');
			if(length == -1)
			{
				strcopy(key, size, key[pos]);
				return table;
			}

			length++;
			char[] subkey = new char[length];
			strcopy(subkey, length, key[pos]);
			pos += length;

			ScriptHandle newTable;

			if(VScript_ValueExists(table, subkey))
			{
				newTable = VScript_GetValueHScript(table, subkey);
				if(!newTable)
					break;
			}
			else if(!generate)
			{
				break;
			}
			else
			{
				newTable = VScript_CreateTable();
				if(!newTable)
					break;
				
				VScript_SetValueHScript(table, subkey, newTable);
			}
			
			delete table;
			table = newTable;
		}
	}

	return null;
}
#endif

#if !defined IS_MAIN_FF2
	#endinput
#endif

stock void VScript_UseAbility(int client, const char[] name)
{
	#if defined _vscript_included
	if(Loaded && ScriptFireScriptHook)
	{
		ScriptHandle hclient = VScript_EntityToHScript(client);
		ScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(hclient && scope)
		{
			ScriptHandle boss = VScript_GetValueHScript(scope, "ff2boss");
			if(boss)
			{
				ScriptHandle ability = VScript_GetValueHScript(boss, name);
		
				ScriptHandle params = VScript_CreateTable();
				VScript_SetValueHScript(params, "client", hclient);
				VScript_SetValueHScript(params, "boss", boss);
				VScript_SetValueString(params, "name", name);
				VScript_SetValueHScript(params, "ability", ability);

				ScriptFireScriptHook.Execute("FF2_OnAbility", params);

				delete params;
				delete ability;
				delete boss;
			}
		}
	}
	#endif
}

public void VScript_CreateBoss(int client)
{
	#if defined _vscript_included
	if(Loaded && ScriptFireScriptHook)
	{
		ScriptHandle scope = VScript_GetEntityScriptScope(client, true);
		if(scope)
		{
			ScriptHandle boss = ExportConfig(Client(client).Cfg);
			VScript_SetValueHScript(scope, "ff2boss", boss);

			ScriptHandle hclient = VScript_EntityToHScript(client, true);
			if(hclient)
			{
				ScriptHandle params = VScript_CreateTable();
				VScript_SetValueHScript(params, "client", hclient);
				VScript_SetValueHScript(params, "boss", boss);

				ScriptFireScriptHook.Execute("FF2_OnBossCreated", params);

				delete params;
			}

			delete boss;
		}
	}
	#endif
}

stock void VScript_BossEquipped(int client)
{
	#if defined _vscript_included
	if(Loaded && ScriptFireScriptHook)
	{
		ScriptHandle hclient = VScript_EntityToHScript(client);
		ScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(hclient && scope)
		{
			ScriptHandle boss = VScript_GetValueHScript(scope, "ff2boss");
			
			ScriptHandle params = VScript_CreateTable();
			VScript_SetValueHScript(params, "client", hclient);
			VScript_SetValueHScript(params, "boss", boss);

			ScriptFireScriptHook.Execute("FF2_OnBossEquipped", params);

			delete params;
			delete boss;
		}
	}
	#endif
}

stock void VScript_BossRemoved(int client)
{
	#if defined _vscript_included
	if(Loaded && ScriptFireScriptHook)
	{
		ScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			ScriptHandle hclient = VScript_EntityToHScript(client);
			if(hclient)
			{
				ScriptHandle boss = VScript_GetValueHScript(scope, "ff2boss");
				
				ScriptHandle params = VScript_CreateTable();
				VScript_SetValueHScript(params, "client", hclient);
				VScript_SetValueHScript(params, "boss", boss);

				ScriptFireScriptHook.Execute("FF2_OnBossRemoved", params);

				delete params;
				delete boss;
			}

			VScript_ClearValue(scope, "ff2boss");
		}
	}
	#endif
}

#if !defined _vscript_included
	#endinput
#endif

public void VScript_OnVMInitialized()
{
	VScript_Run("function FF2_GetAttribute(entity, name, default_value) {\n" ...
		"local a = (\"GetCustomAttribute\" in entity) ? entity.GetCustomAttribute(name, default_value) : entity.GetAttribute(name, default_value)\n" ...
		"if(a == default_value) {\n" ...
			"local b = entity.GetScriptScope()\n" ...
			"if(b == null || !(\"ff2attributes\" in b) || !(name in b.ff2attributes)) { return default_value }\n" ...
			"a = b.ff2attributes[name]\n" ...
		"}\n" ...
		"return a\n" ...
	"}");

	VScript_Run("function FF2_SetAttribute(entity, name, value) {\n" ...
		"if(\"AddCustomAttribute\" in entity) { entity.AddCustomAttribute(name, value, -1.0) }\n" ...
		"else { entity.AddAttribute(name, value, -1.0) }\n" ...
		"entity.ValidateScriptScope()\n" ...
		"local a = entity.GetScriptScope()\n" ...
		"if(!(\"ff2attributes\" in a)) { a.ff2attributes <- {} }\n" ...
		"a.ff2attributes[name] <- value\n" ...
	"}");
	
	VScript_Run("function FF2_RemoveAttribute(entity, name) {\n" ...
		"if(\"RemoveCustomAttribute\" in entity) { entity.RemoveCustomAttribute(name) }\n" ...
		"else { entity.RemoveAttribute(name) }\n" ...
		"local a = entity.GetScriptScope()\n" ...
		"if(a != null && (\"ff2attributes\" in a) && (name in a.ff2attributes)) { delete a.ff2attributes[name] }\n" ...
	"}");
	
	VScript_Run("function FF2_GetBossConfig(player) {\n" ...
		"local a = player.GetScriptScope()\n" ...
		"return (a != null && (\"ff2boss\" in a)) ? a.ff2boss : null\n" ...
	"}");
}

void SetupFunctions()
{
	VScript_RegisterFunction("FF2_PullBossKey", VScriptPullBossKey, "", ScriptField_Variant, ScriptField_HScript, ScriptField_String);
	VScript_RegisterFunction("FF2_PushBossKey", VScriptPushBossKey, "", ScriptField_Void, ScriptField_HScript, ScriptField_String, ScriptField_Variant);
	VScript_RegisterFunction("FF2_PullBossConfig", VScriptPullBossConfig, "", ScriptField_HScript, ScriptField_HScript);
	VScript_RegisterFunction("FF2_PushBossConfig", VScriptPushBossConfig, "", ScriptField_Void, ScriptField_HScript);
	VScript_RegisterFunction("FF2_EmitBossSound", VScriptEmitBossSound, "", ScriptField_Bool, ScriptField_HScript, ScriptField_HScript);
	VScript_RegisterFunction("FF2_DoBossSlot", VScriptDoBossSlot, "", ScriptField_Void, ScriptField_HScript, ScriptField_Int, ScriptField_Int);
	VScript_RegisterFunction("FF2_SetClientMinion", VScriptSetClientMinion, "", ScriptField_Void, ScriptField_HScript, ScriptField_Int);
}

static void VScriptPullBossKey(ScriptContext context)
{
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients && Client(client).Cfg)
		{
			char key[256];
			context.GetArgString(1, key, sizeof(key));

			switch(Client(client).Cfg.GetKeyValType(key))
			{
				case KeyValType_Value:
				{
					char buffer[256];
					Client(client).Cfg.Get(key, buffer, sizeof(buffer));
					
					VScript_UpdateKey(client, key, buffer);
					context.SetReturnString(buffer);
					return;
				}
				case KeyValType_Section:
				{
					ScriptHandle table = ExportConfig(Client(client).Cfg.GetSection(key));

					VScript_UpdateKeyScript(client, key, table);
					context.SetReturnHScript(table);

					delete table;
					return;
				}
			}
		}
	}

	context.SetReturnNull();
}

static void VScriptPushBossKey(ScriptContext context)
{
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients && Client(client).IsBoss)
		{
			char key[256], value[256];
			context.GetArgString(1, key, sizeof(key));

			ScriptFieldType type = context.GetArgType(2);
			if(type == ScriptField_Void)
			{
				Client(client).Cfg.DeleteSection(key);
				VScript_DeleteKey(client, key);
			}
			else if(type == ScriptField_HScript)
			{
				ConfigMap cfg = Client(client).Cfg.GetSection(key);
				ScriptHandle table = context.GetArgHScript(2);

				TableToCfg(cfg, table);
				VScript_UpdateKeyScript(client, key, table);
			}
			else
			{
				switch(type)
				{
					case ScriptField_Float:
					{
						FloatToString(context.GetArgFloat(2), value, sizeof(value));
					}
					case ScriptField_Vector:
					{
						float vec[3];
						context.GetArgVector(2, vec);
						FormatEx(value, sizeof(value), "%f %f %f", vec[0], vec[1], vec[2]);
					}
					case ScriptField_Int:
					{
						IntToString(context.GetArgInt(2), value, sizeof(value));
					}
					case ScriptField_Bool:
					{
						IntToString(context.GetArgBool(2) ? 1 : 0, value, sizeof(value));
					}
					case ScriptField_String:
					{
						context.GetArgString(2, value, sizeof(value));
					}
					case ScriptField_Vector2D:
					{
						float vec[2];
						context.GetArgVector2D(2, vec);
						FormatEx(value, sizeof(value), "%f %f", vec[0], vec[1]);
					}
					case ScriptField_Quaternion:
					{
						float quat[4];
						context.GetArgQuaternion(2, quat);
						FormatEx(value, sizeof(value), "%f %f %f %f", quat[0], quat[1], quat[2], quat[3]);
					}
				}

				Client(client).Cfg.Set(key, value);
				VScript_UpdateKey(client, key, value);
			}
		}
	}
}

static void VScriptPullBossConfig(ScriptContext context)
{
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			if(Client(client).IsBoss)
			{
				ScriptHandle boss = ExportConfig(Client(client).Cfg);
				
				ScriptHandle scope = VScript_GetEntityScriptScope(client);
				if(scope)
				{
					VScript_SetValueHScript(scope, "ff2boss", boss);
				}

				context.SetReturnHScript(boss);
				delete boss;
			}
			else
			{
				ScriptHandle scope = VScript_GetEntityScriptScope(client);
				if(scope)
					VScript_ClearValue(scope, "ff2boss");
			}
		}
	}
}

static void VScriptPushBossConfig(ScriptContext context)
{
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			ScriptHandle boss;

			ScriptHandle scope = VScript_GetEntityScriptScope(client);
			if(scope)
				boss = VScript_GetValueHScript(scope, "ff2boss");
			
			ConfigMap cfg = ImportConfig(boss);

			if(cfg)
			{
				if(Client(client).Cfg)
				{
					DeleteCfg(Client(client).Cfg);
					Client(client).Cfg = cfg;
				}
				else
				{
					Bosses_CreateFromConfig(client, cfg, GetClientTeam(client), _, false);
				}
			}
			else if(Client(client).Cfg)
			{
				Bosses_Remove(client);
			}

			delete boss;
		}
	}
}

static void VScriptEmitBossSound(ScriptContext context)
{
	bool result;
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			ScriptHandle table = context.GetArgHScript(1);
			if(table)
			{
				char key[64];
				VScript_GetValueString(table, "sound_name", key, sizeof(key));
				if(key[0])
				{
					char required[256];
					if(VScript_ValueExists(table, "required"))
						VScript_GetValueString(table, "required", required, sizeof(required));
					
					int entity = SOUND_FROM_PLAYER;
					if(VScript_ValueExists(table, "entity"))
					{
						ScriptHandle hentity = VScript_GetValueHScript(table, "entity");
						entity = VScript_HScriptToEntity(hentity);
						delete hentity;
					}

					int channel = SNDCHAN_AUTO;
					if(VScript_ValueExists(table, "channel"))
						channel = VScript_GetValueInt(table, "channel");
					
					int level = SNDLEVEL_NORMAL;
					if(VScript_ValueExists(table, "sound_level"))
						level = VScript_GetValueInt(table, "sound_level");
					
					int flags = SND_NOFLAGS;
					if(VScript_ValueExists(table, "flags"))
						flags = VScript_GetValueInt(table, "flags");
					
					float volume = SNDVOL_NORMAL;
					if(VScript_ValueExists(table, "volume"))
						volume = VScript_GetValueFloat(table, "volume");
					
					int pitch = SNDPITCH_NORMAL;
					if(VScript_ValueExists(table, "pitch"))
						pitch = VScript_GetValueInt(table, "pitch");
					
					ScriptHandle hplayers = VScript_GetValueHScript(table, "players");
					if(hplayers)
					{
						int total;
						int[] clients = new int[MaxClients];
						char section[16];
						ScriptFieldType type;
						for(int i; (i = VScript_GetNextKey(hplayers, i, section, sizeof(section), type)) != -1; )
						{
							if(type == ScriptField_HScript)
							{
								ScriptHandle hentity = VScript_GetValueHScript(hplayers, section);
								clients[total++] = VScript_HScriptToEntity(hentity);
								delete hentity;
							}
						}

						delete hplayers;
						
						result = Bosses_PlaySound(client, clients, total, key, required, entity, channel, level, flags, volume, pitch);
					}
					else
					{
						result = Bosses_PlaySoundToAll(client, key, required, entity, channel, level, flags, volume, pitch);
					}
				}
			}
		}
	}

	context.SetReturnBool(result);
}

static void VScriptDoBossSlot(ScriptContext context)
{
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			int low = context.GetArgInt(1);
			int high = context.ArgCount > 2 ? low : context.GetArgInt(2);
			if(high > low)
				high = low;
			
			Bosses_UseSlot(client, low, high);
		}
	}
}

static void VScriptSetClientMinion(ScriptContext context)
{
	ScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			Client(client).MinionType = context.GetArgInt(1);
		}
	}
}

static ScriptHandle ExportConfig(ConfigMap cfg)
{
	if(cfg == null)
		return null;
	
	ScriptHandle table = VScript_CreateTable();
	CfgToTable(table, cfg);
	return table;
}

static void CfgToTable(ScriptHandle table, ConfigMap cfg)
{
	StringMapSnapshot snap = cfg.Snapshot();
	
	int entries = snap.Length;
	if(entries)
	{
		PackVal val;
		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] key = new char[length];
			snap.GetKey(i, key, length);
			cfg.GetArray(key, val, sizeof(val));

			switch(val.tag)
			{
				case KeyValType_Value:
				{
					VScript_SetValueString(table, key, val.data);
				}
				case KeyValType_Section:
				{
					ScriptHandle subtable = VScript_CreateTable();
					CfgToTable(subtable, val.cfg);
					VScript_SetValueHScript(table, key, subtable);
					delete subtable;
				}
			}
		}
	}
	
	delete snap;
}

static ConfigMap ImportConfig(ScriptHandle table)
{
	if(table == null)
		return null;
	
	ConfigMap cfg = view_as<ConfigMap>(CreateTrie());
	TableToCfg(cfg, table);
	return cfg;
}

static void TableToCfg(ConfigMap cfg, ScriptHandle table)
{
	char key[256], value[256];
	ScriptFieldType type;
	for(int i; (i = VScript_GetNextKey(table, i, key, sizeof(key), type)) != -1;)
	{
		switch(type)
		{
			case ScriptField_Void:
			{
				cfg.Set(key, "");
			}
			case ScriptField_Float:
			{
				cfg.SetFloat(key, VScript_GetValueFloat(table, key));
			}
			case ScriptField_Vector:
			{
				float vec[3];
				VScript_GetValueVector(table, key, vec);
				Format(value, sizeof(value), "%f %f %f", vec[0], vec[1], vec[2]);
				cfg.Set(key, value);
			}
			case ScriptField_Int:
			{
				cfg.SetInt(key, VScript_GetValueInt(table, key));
			}
			case ScriptField_Bool:
			{
				cfg.SetInt(key, VScript_GetValueBool(table, key) ? 1 : 0);
			}
			case ScriptField_String:
			{
				VScript_GetValueString(table, key, value, sizeof(value));
				cfg.Set(key, value);
			}
			case ScriptField_HScript:
			{
				ConfigMap subcfg = cfg.SetSection(key);
				ScriptHandle subtable = VScript_GetValueHScript(table, key);
				TableToCfg(subcfg, subtable);
				delete subtable;
			}
			case ScriptField_Vector2D:
			{
				float vec[2];
				VScript_GetValueVector2D(table, key, vec);
				Format(value, sizeof(value), "%f %f", vec[0], vec[1]);
				cfg.Set(key, value);
			}
			case ScriptField_Quaternion:
			{
				float quat[4];
				VScript_GetValueQuaternion(table, key, quat);
				Format(value, sizeof(value), "%f %f %f %f", quat[0], quat[1], quat[2], quat[3]);
				cfg.Set(key, value);
			}
		}
	}
}
