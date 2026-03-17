#tryinclude <vscript>

#pragma semicolon 1
#pragma newdecls required

#define VSCRIPT_LIBRARY	"vscript"
#define SCRIPT_VERSION	2

static char ReturnString[256];
static float ReturnFloat;

#if defined _vscript_ext_included
static bool Loaded;
static VScriptCall ScriptGetAttribute;
static VScriptCall ScriptSetAttribute;
static VScriptCall ScriptRemoveAttribute;
#if defined IS_MAIN_FF2
static VScriptCall ScriptFireScriptHook;
#endif
#endif

void VScript_PluginStart()
{
	PrintToChatAll("???????");

	HookEvent("tf_map_time_remaining", VScriptEvent, EventHookMode_Pre);
	
	#if defined _vscript_ext_included
	Loaded = LibraryExists(VSCRIPT_LIBRARY);
	if(Loaded)
	{
		SetupCalls();
		#if defined IS_MAIN_FF2
		if(VScript_IsVMInitialized())
			VScript_OnVMInitialized();
		#endif
	}
	PrintToChatAll("Loaded: %d | VM: %d", Loaded, Loaded ? VScript_IsVMInitialized() : false);
	#endif
	PrintToChatAll("????");

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

#if defined _vscript_ext_included
static void SetupCalls()
{
	ScriptSetAttribute = new VScriptCall("FF2_SetAttribute", VScriptField_Void, VScriptField_HScript, VScriptField_String, VScriptField_Float);
	ScriptGetAttribute = new VScriptCall("FF2_GetAttribute", VScriptField_Float, VScriptField_HScript, VScriptField_String, VScriptField_Float);
	ScriptRemoveAttribute = new VScriptCall("FF2_RemoveAttribute", VScriptField_Void, VScriptField_HScript, VScriptField_String);

	#if defined IS_MAIN_FF2
	ScriptFireScriptHook = new VScriptCall("FireScriptHook", VScriptField_Bool, VScriptField_String, VScriptField_HScript);
	#endif
}
#endif

public void VScript_LibraryAdded(const char[] name)
{
	#if defined _vscript_ext_included
	if(!Loaded && StrEqual(name, VSCRIPT_LIBRARY))
	{
		Loaded = true;
		SetupCalls();
		#if defined IS_MAIN_FF2
		if(VScript_IsVMInitialized())
			VScript_OnVMInitialized();
		#endif
	}
	#endif
}

public void VScript_LibraryRemoved(const char[] name)
{
	#if defined _vscript_ext_included
	if(Loaded && StrEqual(name, VSCRIPT_LIBRARY))
		Loaded = false;
	#endif
}

stock void VScript_PrintStatus()
{
	#if defined _vscript_ext_included
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

	#if defined _vscript_ext_included
	if(Loaded && ScriptGetAttribute)
	{
		VScriptHandle hentity = VScript_EntityToHScript(entity);
		if(hentity && ScriptGetAttribute.Execute(hentity, name, ReturnFloat) == VScriptStatus_Done)
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
	#if defined _vscript_ext_included
	if(Loaded && ScriptSetAttribute)
	{
		VScriptHandle hentity = VScript_EntityToHScript(entity);
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
	#if defined _vscript_ext_included
	if(Loaded && ScriptSetAttribute)
	{
		VScriptHandle hentity = VScript_EntityToHScript(entity);
		if(hentity)
			ScriptSetAttribute.Execute(hentity, name, value);
		
		return;
	}
	#endif

	Format(ReturnString, sizeof(ReturnString), "_FF2_SetAttribute(\"%s\", casti2f(%d))", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_RemoveAttribute(int entity, const char[] name)
{
	#if defined _vscript_ext_included
	if(Loaded && ScriptRemoveAttribute)
	{
		VScriptHandle hentity = VScript_EntityToHScript(entity);
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
	#if defined _vscript_ext_included
	if(Loaded)
	{
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			char subkey[256];
			strcopy(subkey, sizeof(subkey), key);
			VScriptHandle table = FindTableKey(scope, subkey, sizeof(subkey), true);
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
	#if defined _vscript_ext_included
	if(Loaded)
	{
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			char subkey[256];
			strcopy(subkey, sizeof(subkey), key);
			VScriptHandle table = FindTableKey(scope, subkey, sizeof(subkey), false);
			if(table)
			{
				VScript_ClearValue(table, key);
				delete table;
			}
		}
	}
	#endif
}

#if defined _vscript_ext_included
public void VScript_UpdateKeyScript(int client, const char[] key, VScriptHandle value)
{
	if(Loaded)
	{
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			char subkey[256];
			strcopy(subkey, sizeof(subkey), key);
			VScriptHandle table = FindTableKey(scope, subkey, sizeof(subkey), true);
			if(table)
			{
				VScript_SetValueHScript(table, subkey, value);
				delete table;
			}
		}
	}
}

static VScriptHandle FindTableKey(VScriptHandle scope, char[] key, int size, bool generate)
{
	VScriptHandle table = VScript_GetValueHScript(scope, "ff2boss");
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

			VScriptHandle newTable;

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
	#if defined _vscript_ext_included
	if(Loaded && ScriptFireScriptHook)
	{
		VScriptHandle hclient = VScript_EntityToHScript(client);
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(hclient && scope)
		{
			VScriptHandle boss = VScript_GetValueHScript(scope, "ff2boss");
			if(boss)
			{
				VScriptHandle ability = VScript_GetValueHScript(boss, name);
		
				VScriptHandle params = VScript_CreateTable();
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
	#if defined _vscript_ext_included
	PrintToServer("VScript_CreateBoss");
	if(Loaded && ScriptFireScriptHook)
	{
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		PrintToServer("VScript_CreateBoss::scope=%x", scope);
		if(scope)
		{
			VScriptHandle boss = ExportConfig(Client(client).Cfg);
			VScript_SetValueHScript(scope, "ff2boss", boss);
			PrintToServer("VScript_CreateBoss::boss=%x", boss);

			VScriptHandle hclient = VScript_EntityToHScript(client);
			PrintToServer("VScript_CreateBoss::hclient=%x", hclient);
			if(hclient)
			{
				VScriptHandle params = VScript_CreateTable();
				VScript_SetValueHScript(params, "client", hclient);
				VScript_SetValueHScript(params, "boss", boss);

				PrintToServer("VScript_CreateBoss::params=%x", params);
				PrintToServer("VScript_CreateBoss::%d", ScriptFireScriptHook.Execute("FF2_OnBossCreated", params));

				delete params;
			}

			delete boss;
		}
	}
	#endif
}

stock void VScript_BossEquipped(int client)
{
	#if defined _vscript_ext_included
	if(Loaded && ScriptFireScriptHook)
	{
		VScriptHandle hclient = VScript_EntityToHScript(client);
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(hclient && scope)
		{
			VScriptHandle boss = VScript_GetValueHScript(scope, "ff2boss");
			
			VScriptHandle params = VScript_CreateTable();
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
	#if defined _vscript_ext_included
	if(Loaded && ScriptFireScriptHook)
	{
		VScriptHandle scope = VScript_GetEntityScriptScope(client);
		if(scope)
		{
			VScriptHandle hclient = VScript_EntityToHScript(client);
			if(hclient)
			{
				VScriptHandle boss = VScript_GetValueHScript(scope, "ff2boss");
				
				VScriptHandle params = VScript_CreateTable();
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

#if !defined _vscript_ext_included
	#endinput
#endif

public void VScript_OnVMInitialized()
{
	PrintToServer("VScript_OnVMInitialized");

	VScriptHandle code = VScript_CompileScript("function FF2_GetAttribute(entity, name, default_value) {\n" ...
		"local a = (\"GetCustomAttribute\" in entity) ? entity.GetCustomAttribute(name, default_value) : entity.GetAttribute(name, default_value)\n" ...
		"if(a == default_value) {\n" ...
			"local b = entity.GetScriptScope()\n" ...
			"if(b == null || !(\"ff2attributes\" in b) || !(name in b.ff2attributes)) { return default_value }\n" ...
			"a = m.ff2attributes[strName]\n" ...
		"}\n" ...
		"return a\n" ...
	"}");
	VScript_RunScript(code);
	delete code;

	code = VScript_CompileScript("function FF2_SetAttribute(entity, name, value) {\n" ...
		"if(\"AddCustomAttribute\" in entity) { entity.AddCustomAttribute(name, value, -1.0) }\n" ...
		"else { entity.AddAttribute(name, value, -1.0) }\n" ...
		"entity.ValidateScriptScope()\n" ...
		"local a = entity.GetScriptScope()\n" ...
		"if(!(\"ff2attributes\" in a)) { a.ff2attributes <- {} }\n" ...
		"a.ff2attributes[name] <- value\n" ...
	"}");
	VScript_RunScript(code);
	delete code;
	
	code = VScript_CompileScript("function FF2_RemoveAttribute(entity, name) {\n" ...
		"if(\"RemoveCustomAttribute\" in entity) { entity.RemoveCustomAttribute(name) }\n" ...
		"else { entity.RemoveAttribute(name) }\n" ...
		"local a = entity.GetScriptScope()\n" ...
		"if(a != null && (\"ff2attributes\" in a) && (name in a.ff2attributes)) { delete a.ff2attributes[name] }\n" ...
	"}");
	VScript_RunScript(code);
	delete code;
	
	code = VScript_CompileScript("function FF2_GetBossConfig(player) {\n" ...
		"local a = player.GetScriptScope()\n" ...
		"return (a != null && (\"ff2boss\" in a)) ? a.ff2boss : null\n" ...
	"}");
	VScript_RunScript(code);
	delete code;

	VScript_RegisterFunction("FF2_PullBossKey", VScriptPullBossKey, "", VScriptField_Void, VScriptField_HScript, VScriptField_String);
	VScript_RegisterFunction("FF2_PushBossKey", VScriptPushBossKey, "", VScriptField_Void, VScriptField_HScript, VScriptField_String, VScriptField_Void);
	VScript_RegisterFunction("FF2_PullBossConfig", VScriptPullBossConfig, "", VScriptField_HScript, VScriptField_HScript);
	VScript_RegisterFunction("FF2_PushBossConfig", VScriptPushBossConfig, "", VScriptField_HScript, VScriptField_HScript);
	VScript_RegisterFunction("FF2_EmitBossSound", VScriptEmitBossSound, "", VScriptField_Bool, VScriptField_HScript, VScriptField_HScript);
}

static void VScriptPullBossKey(VScriptContext context)
{
	VScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients && Client(client).Cfg)
		{
			char key[256];
			context.GetArgString(1, key, sizeof(key));

			ConfigMap cfg = Client(client).Cfg;
			switch(cfg.GetKeyValType(key))
			{
				case KeyValType_Value:
				{
					char buffer[256];
					cfg.Get(key, buffer, sizeof(buffer));
					
					VScript_UpdateKey(client, key, buffer);
					context.SetReturnString(buffer);
					return;
				}
				case KeyValType_Section:
				{
					VScriptHandle table = ExportConfig(cfg.GetSection(key));

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

static void VScriptPushBossKey(VScriptContext context)
{
	VScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients && Client(client).IsBoss)
		{
			char key[256], value[256];
			context.GetArgString(1, key, sizeof(key));

			VScriptFieldType type = context.GetArgType(2);
			if(type == VScriptField_Void)
			{
				Client(client).Cfg.DeleteSection(key);
				VScript_DeleteKey(client, key);
			}
			else if(type == VScriptField_HScript)
			{
				ConfigMap cfg = Client(client).Cfg.GetSection(key);
				VScriptHandle table = context.GetArgHScript(2);

				TableToCfg(cfg, table);
				VScript_UpdateKeyScript(client, key, table);

				delete table;
			}
			else
			{
				switch(type)
				{
					case VScriptField_Float:
					{
						FloatToString(context.GetArgFloat(2), value, sizeof(value));
					}
					case VScriptField_Vector:
					{
						float vec[3];
						context.GetArgVector(2, vec);
						FormatEx(value, sizeof(value), "%f %f %f", vec[0], vec[1], vec[2]);
					}
					case VScriptField_Int:
					{
						IntToString(context.GetArgInt(2), value, sizeof(value));
					}
					case VScriptField_Bool:
					{
						IntToString(context.GetArgBool(2) ? 1 : 0, value, sizeof(value));
					}
					case VScriptField_String:
					{
						context.GetArgString(2, value, sizeof(value));
					}
					case VScriptField_Vector2D:
					{
						float vec[2];
						context.GetArgVector2D(2, vec);
						FormatEx(value, sizeof(value), "%f %f", vec[0], vec[1]);
					}
					case VScriptField_Quaternion:
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

static void VScriptPullBossConfig(VScriptContext context)
{
	VScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			if(Client(client).IsBoss)
			{
				VScriptHandle boss = ExportConfig(Client(client).Cfg);
				
				VScriptHandle scope = VScript_GetEntityScriptScope(client);
				if(scope)
				{
					VScript_SetValueHScript(scope, "ff2boss", boss);
				}

				context.SetReturnHScript(boss);
				delete boss;
			}
			else
			{
				VScriptHandle scope = VScript_GetEntityScriptScope(client);
				if(scope)
					VScript_ClearValue(scope, "ff2boss");
			}
		}
	}
}

static void VScriptPushBossConfig(VScriptContext context)
{
	VScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			VScriptHandle boss;

			VScriptHandle scope = VScript_GetEntityScriptScope(client);
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

static void VScriptEmitBossSound(VScriptContext context)
{
	bool result;
	VScriptHandle hclient = context.GetArgHScript(0);
	if(hclient)
	{
		int client = VScript_HScriptToEntity(hclient);
		if(client > 0 && client <= MaxClients)
		{
			VScriptHandle table = context.GetArgHScript(1);
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
						VScriptHandle hentity = VScript_GetValueHScript(table, "entity");
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
					
					VScriptHandle hplayers = VScript_GetValueHScript(table, "players");
					if(hplayers)
					{
						int total;
						int[] clients = new int[MaxClients];
						char section[16];
						VScriptFieldType type;
						for(int i; (i = VScript_GetNextKey(hplayers, i, section, sizeof(section), type)) != -1; )
						{
							if(type == VScriptField_HScript)
							{
								VScriptHandle hentity = VScript_GetValueHScript(hplayers, section);
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

static VScriptHandle ExportConfig(ConfigMap cfg)
{
	if(cfg == null)
		return null;
	
	VScriptHandle table = VScript_CreateTable();
	CfgToTable(table, cfg);
	return table;
}

static void CfgToTable(VScriptHandle table, ConfigMap cfg)
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
					VScriptHandle subtable = VScript_CreateTable();
					CfgToTable(subtable, val.cfg);
					VScript_SetValueHScript(table, key, subtable);
					delete subtable;
				}
			}
		}
	}
	
	delete snap;
}

static ConfigMap ImportConfig(VScriptHandle table)
{
	if(table == null)
		return null;
	
	ConfigMap cfg = view_as<ConfigMap>(CreateTrie());
	TableToCfg(cfg, table);
	return cfg;
}

static void TableToCfg(ConfigMap cfg, VScriptHandle table)
{
	char key[256], value[256];
	VScriptFieldType type;
	for(int i; (i = VScript_GetNextKey(table, i, key, sizeof(key), type)) != -1;)
	{
		switch(type)
		{
			case VScriptField_Void:
			{
				cfg.Set(key, "");
			}
			case VScriptField_Float:
			{
				cfg.SetFloat(key, VScript_GetValueFloat(table, key));
			}
			case VScriptField_Vector:
			{
				float vec[3];
				VScript_GetValueVector(table, key, vec);
				Format(value, sizeof(value), "%f %f %f", vec[0], vec[1], vec[2]);
				cfg.Set(key, value);
			}
			case VScriptField_Int:
			{
				cfg.SetInt(key, VScript_GetValueInt(table, key));
			}
			case VScriptField_Bool:
			{
				cfg.SetInt(key, VScript_GetValueBool(table, key) ? 1 : 0);
			}
			case VScriptField_String:
			{
				VScript_GetValueString(table, key, value, sizeof(value));
				cfg.Set(key, value);
			}
			case VScriptField_HScript:
			{
				ConfigMap subcfg = cfg.SetSection(key);
				VScriptHandle subtable = VScript_GetValueHScript(table, key);
				TableToCfg(subcfg, subtable);
				delete subtable;
			}
			case VScriptField_Vector2D:
			{
				float vec[2];
				VScript_GetValueVector2D(table, key, vec);
				Format(value, sizeof(value), "%f %f", vec[0], vec[1]);
				cfg.Set(key, value);
			}
			case VScriptField_Quaternion:
			{
				float quat[4];
				VScript_GetValueQuaternion(table, key, quat);
				Format(value, sizeof(value), "%f %f %f %f", quat[0], quat[1], quat[2], quat[3]);
				cfg.Set(key, value);
			}
		}
	}
}
