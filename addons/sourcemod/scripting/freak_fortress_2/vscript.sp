#pragma semicolon 1
#pragma newdecls required

#define SCRIPT_VERSION	1

static char ReturnString[512];
static float ReturnFloat;

void VScript_PluginStart()
{
	HookEvent("tf_map_time_remaining", VScriptEvent, EventHookMode_Pre);

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
			if(version >= SCRIPT_VERSION)
				return;
		}
		
		delete file;
	}

	SetFailState("VScript file \"freak_fortress_2.nut\" is outdated (expected v%d, got v%d)", SCRIPT_VERSION, version);
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
#if defined IS_MAIN_FF2
		else if(StrEqual(buffer, "pushkey"))
		{
			int client = event.GetInt("client");
			if(client > 0 && client <= MaxClients)
			{
				event.GetString("key", buffer, sizeof(buffer));
				if(buffer[0])
				{
					event.GetString("value", ReturnString, sizeof(ReturnString));
					Client(client).Cfg.Set(buffer, ReturnString);
				}
			}
		}
		else if(StrEqual(buffer, "pullkey"))
		{
			int client = event.GetInt("client");
			if(client > 0 && client <= MaxClients)
			{
				event.GetString("key", buffer, sizeof(buffer));
				if(buffer[0])
				{
					Client(client).Cfg.Get(buffer, ReturnString, sizeof(ReturnString));
					VScript_UpdateKey(client, buffer, ReturnString);
				}
			}
		}
		else if(StrEqual(buffer, "deletekey"))
		{
			int client = event.GetInt("client");
			if(client > 0 && client <= MaxClients)
			{
				event.GetString("key", buffer, sizeof(buffer));
				if(buffer[0])
				{
					Client(client).Cfg.DeleteSection(buffer);
				}
			}
		}
		else if(StrEqual(buffer, "pushconfig"))
		{
			int client = event.GetInt("client");
			if(client > 0 && client <= MaxClients)
			{
				ConfigMap cfg = VScript_ImportConfig();

				if(Client(client).IsBoss)
				{
					if(cfg)
					{
						DeleteCfg(Client(client).Cfg);
						Client(client).Cfg = cfg;
					}
					else
					{
						Bosses_Remove(client);
					}
				}
				else if(cfg)
				{
					Bosses_CreateFromConfig(client, cfg, GetClientTeam(client), _, false);
				}
			}
		}
		else if(StrEqual(buffer, "pullconfig"))
		{
			int client = event.GetInt("client");
			if(client > 0 && client <= MaxClients)
			{
				VScript_ExportConfig(Client(client).Cfg);
			}
		}
#endif
	}

	return Plugin_Continue;
}

stock bool VScript_GetAttribute(int entity, const char[] name, float &value)
{
	ReturnFloat = -999.9;	

	Format(ReturnString, sizeof(ReturnString), "_FF2_GetAttribute(\"%s\")", name);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);

	if(ReturnFloat == -999.9)
		return false;
	
	value = ReturnFloat;
	return true;
}

stock void VScript_SetAttribute(int entity, const char[] name, float value)
{
	Format(ReturnString, sizeof(ReturnString), "_FF2_SetAttribute(\"%s\", %f)", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_SetAttributeInt(int entity, const char[] name, int value)
{
	Format(ReturnString, sizeof(ReturnString), "_FF2_SetAttribute(\"%s\", casti2f(%d))", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_RemoveAttribute(int entity, const char[] name)
{
	Format(ReturnString, sizeof(ReturnString), "_FF2_RemoveAttribute(\"%s\")", name);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_Call(const char[] func, int entity = -1)
{
	Format(ReturnString, sizeof(ReturnString), "%s()", func);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_UpdateKey(int client, const char[] key, const char[] value)
{
	Format(ReturnString, sizeof(ReturnString), "_FF2_UpdateKey(\"%s\", \"%s\")", key, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", client, client);
}

stock void VScript_DeleteKey(int client, const char[] key)
{
	Format(ReturnString, sizeof(ReturnString), "_FF2_DeleteKey(\"%s\")", key);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", client, client);
}

#if !defined IS_MAIN_FF2
	#endinput
#endif

stock void VScript_UseAbility(int client, const char[] name)
{
	Format(ReturnString, sizeof(ReturnString), "_FF2_UseAbility(\"%s\")", name);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", client, client);
}

stock void VScript_CreateBoss(int client)
{
	VScript_ExportConfig(Client(client).Cfg);

	Format(ReturnString, sizeof(ReturnString), "_FF2_BossCreated()");
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", client, client);
}

/*
	weapon
		classnamegoop
		index57
		attributes
			damage53.0
		
	
*/

stock void VScript_ExportConfig(ConfigMap cfg)
{
	char filepath[64];
	SDKKey_ScriptDataFolder(filepath, sizeof(filepath));
	StrCat(filepath, sizeof(filepath), "/ff2bosscache.dat");

	if(cfg == null)
	{
		DeleteFile(filepath);
		return;
	}

	char buffer[16384];
	CfgToString(buffer, cfg);

	File file = OpenFile(filepath, "w");
	if(file)
	{
		file.WriteString(buffer, true);
		delete file;
	}
}

static void CfgToString(char file[16384], ConfigMap cfg)
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
					Format(val.data, sizeof(val.data), "%s%s", key, val.data);
					StrCat(file, sizeof(file), val.data);
				}
				case KeyValType_Section:
				{
					FormatEx(val.data, sizeof(val.data), "%s", key);
					StrCat(file, sizeof(file), val.data);
					CfgToString(file, val.cfg);
					StrCat(file, sizeof(file), "");
				}
			}
		}
	}
	
	delete snap;
}

stock ConfigMap VScript_ImportConfig()
{
	char filepath[64];
	SDKKey_ScriptDataFolder(filepath, sizeof(filepath));
	StrCat(filepath, sizeof(filepath), "/ff2bosscache.dat");

	File file = OpenFile(filepath, "r");
	if(!file)
		return null;
	
	char buffer[16384];
	file.ReadString(buffer, sizeof(buffer));
	delete file;
	
	int pos;
	ConfigMap cfg = view_as<ConfigMap>(CreateTrie());
	StringToCfg(cfg, buffer, pos);
	return cfg;
}

static void StringToCfg(ConfigMap cfg, const char[] file, int &pos)
{
	for(;;)
	{
		int lengthV = FindCharInString(file[pos], '');
		if(lengthV == -1)
			break;

		// End of tree
		if(lengthV == 0)
		{
			pos++;
			break;
		}

		bool section = true;
		int length = FindCharInString(file[pos], '');
		if(length == -1 || length > lengthV)
		{
			// If "" is closer, assume that's it's key:value
			length = lengthV;
			section = false;
		}

		length++;
		char[] key = new char[length];
		strcopy(key, length, file[pos]);
		pos += length;

		if(section)
		{
			ConfigMap sub = cfg.SetSection(key);
			StringToCfg(sub, file, pos);
		}
		else
		{
			length = FindCharInString(file[pos], '');
			if(length == -1)
				break;
			
			length++;
			char[] value = new char[length];
			strcopy(value, length, file[pos]);
			pos += length;

			cfg.Set(key, value);
		}
	}
}
