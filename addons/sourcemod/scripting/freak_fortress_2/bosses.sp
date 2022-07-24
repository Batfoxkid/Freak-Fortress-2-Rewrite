/*
	void Bosses_PluginStart()
	void Bosses_BuildPacks(int &charset, const char[] mapname)
	void Bosses_MapEnd()
	void Bosses_PluginEnd()
	int Bosses_GetCharset(int charset, char[] buffer, int length)
	int Bosses_GetCharsetLength()
	ConfigMap Bosses_GetConfig(int special)
	int Bosses_GetConfigLength()
	int Bosses_GetByName(const char[] name, bool exact = true, bool enabled = true, int lang = -1, const char[] string = "name")
	bool Bosses_CanAccessBoss(int client, int special, bool playing = false, int team = -1, bool enabled = true, bool &preview = false)
	bool Bosses_GetBossName(int special, char[] buffer, int length, int lang = -1, const char[] string = "name")
	bool Bosses_GetBossNameCfg(ConfigMap cfg, char[] buffer, int length, int lang = -1, const char[] string = "name")
	void Bosses_CreateFromSpecial(int client, int special, int team)
	void Bosses_CreateFromConfig(int client, ConfigMap cfg, int team)
	void Bosses_SetHealth(int client, int players)
	void Bosses_Equip(int client)
	void Bosses_UpdateHealth(int client)
	void Bosses_SetSpeed(int client)
	void Bosses_ClientDisconnect(int client)
	void Bosses_Remove(int client)
	int Bosses_GetBossTeam()
	void Bosses_PlayerRunCmd(int client, int buttons)
	void Bosses_UseSlot(int client, int low, int high)
	void Bosses_UseAbility(int client, const char[] plugin = "", const char[] ability, int slot, int buttonmode = 0)
	int Bosses_GetArgInt(int client, const char[] ability, const char[] argument, int &value, int base = 10)
	int Bosses_GetArgFloat(int client, const char[] ability, const char[] argument, float &value)
	int Bosses_GetArgString(int client, const char[] ability, const char[] argument, char[] value, int length)
	int Bosses_GetRandomSound(int client, const char[] key, SoundEnum sound, const char[] required = "")
	int Bosses_GetRandomSoundCfg(ConfigMap cfg, const char[] key, SoundEnum sound, const char[] required = "")
	int Bosses_GetSpecificSoundCfg(ConfigMap cfg, const char[] section, char[] key, int length, SoundEnum sound)
	bool Bosses_PlaySound(int boss, const int[] clients, int numClients, const char[] key, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
	bool Bosses_PlaySoundToClient(int boss, int client, const char[] key, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
	bool Bosses_PlaySoundToAll(int boss, const char[] key, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
*/

#pragma semicolon 1

static ArrayList BossList;
static ArrayList PackList;
static int DownloadTable;

void Bosses_PluginStart()
{
	RegAdminCmd("ff2_makeboss", Bosses_MakeBossCmd, ADMFLAG_CHEATS, "Force a specific boss on a player");
	RegAdminCmd("ff2_setcharge", Bosses_SetChargeCmd, ADMFLAG_CHEATS, "Give charge to a boss");
	RegAdminCmd("ff2_setrage", Bosses_SetChargeCmd, ADMFLAG_CHEATS, "Give charge to a boss", _, FCVAR_HIDDEN);
	RegAdminCmd("ff2_reloadcharset", Bosses_ReloadCharsetCmd, ADMFLAG_RCON, "Reloads the current boss pack");
	RegServerCmd("ff2_checkboss", Bosses_DebugCacheCmd, "Check's the boss config cache");
	RegServerCmd("ff2_loadsubplugins", Bosses_DebugLoadCmd, "Loads freak subplugins");
	RegServerCmd("ff2_unloadsubplugins", Bosses_DebugUnloadCmd, "Unloads freak subplugins");
}

public Action Bosses_DebugCacheCmd(int args)
{
	if(args)
	{
		int special = -1;
		char buffer[64];
		GetCmdArg(1, buffer, sizeof(buffer));
		if(buffer[0] == '#')
		{
			special = StringToInt(buffer[1]);
		}
		else
		{
			special = Bosses_GetByName(buffer, false, _, GetServerLanguage());
		}
		
		if(special == -1)
		{
			PrintToServer("[FF2] Invalid Boss Name/Index");
		}
		else
		{
			Bosses_GetConfig(special).ExportToFile("character", "bosscache.cfg");
			PrintToServer("[FF2] Exported to bosscache.cfg");
		}
	}
	else
	{
		PrintToServer("[SM] Usage: ff2_checkboss [boss name / #index]");
	}
	return Plugin_Handled;
}

public Action Bosses_DebugLoadCmd(int args)
{
	EnableSubplugins();
	return Plugin_Handled;
}

public Action Bosses_DebugUnloadCmd(int args)
{
	DisableSubplugins();
	return Plugin_Handled;
}

public Action Bosses_ReloadCharsetCmd(int client, int args)
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	Bosses_BuildPacks(Charset, mapname);
	return Plugin_Handled;
}

public Action Bosses_MakeBossCmd(int client, int args)
{
	if(args && args < 4)
	{
		char buffer[64];
		int special = -1;
		if(args > 1)
		{
			GetCmdArg(2, buffer, sizeof(buffer));
			if(buffer[0] == '#')
			{
				special = StringToInt(buffer[1]);
			}
			else
			{
				special = Bosses_GetByName(buffer, false, _, client ? GetClientLanguage(client) : GetServerLanguage());
			}
		}
		
		int team = -1;
		if(args > 2)
		{
			GetCmdArg(3, buffer, sizeof(buffer));
			team = StringToInt(buffer);
			if(team < -1 || team > 3)
				team = -1;
		}
		
		GetCmdArg(1, buffer, sizeof(buffer));
		
		bool lang;
		int matches;
		int[] target = new int[MaxClients];
		if((matches = ProcessTargetString(buffer, client, target, MaxClients, 0, buffer, sizeof(buffer), lang)) > 0)
		{
			for(int i; i < matches; i++)
			{
				if(!IsClientSourceTV(target[i]) && !IsClientReplay(target[i]))
				{
					if(args == 1)
					{
						if(Client(target[i]).IsBoss)
						{
							Bosses_Remove(target[i]);
							LogAction(client, target[i], "\"%L\" removed \"%L\" being a boss", client, target[i]);
							continue;
						}
					}
					
					int team2 = team;
					if(team2 == -1)
						team2 = GetClientTeam(target[i]);
					
					int special2 = special;
					if(special2 == -1)
					{
						special2 = Preference_PickBoss(target[i], team2);
						if(special2 == -1)
							continue;
					}
					
					Bosses_CreateFromSpecial(target[i], special2, team2);
					LogAction(client, target[i], "\"%L\" made \"%L\" a boss", client, target[i]);
				}
			}
			
			if(lang)
			{
				FShowActivity(client, "%t", "Created Boss On", buffer);
			}
			else
			{
				FShowActivity(client, "%t", "Created Boss On", "_s", buffer);
			}
		}
		else
		{
			ReplyToTargetError(client, matches);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: ff2_makeboss <client> [boss name / #index] [team]");
	}
	return Plugin_Handled;
}

public Action Bosses_SetChargeCmd(int client, int args)
{
	if(args && args < 4)
	{
		char buffer[64];
		float charge;
		if(args > 1)
		{
			GetCmdArg(2, buffer, sizeof(buffer));
			charge = StringToFloat(buffer);
		}
		
		int slot;
		if(args > 2)
		{
			GetCmdArg(3, buffer, sizeof(buffer));
			slot = StringToInt(buffer);
		}
		
		GetCmdArg(1, buffer, sizeof(buffer));
		
		bool lang;
		int matches;
		int[] target = new int[MaxClients];
		if((matches = ProcessTargetString(buffer, client, target, MaxClients, 0, buffer, sizeof(buffer), lang)) > 0)
		{
			bool found;
			for(int i; i < matches; i++)
			{
				if(!IsClientSourceTV(target[i]) && !IsClientReplay(target[i]) && Client(target[i]).IsBoss)
				{
					found = true;
					
					if(args == 1)
						charge = Client(target[i]).RageMax;
					
					Client(target[i]).SetCharge(slot, charge);
					LogAction(client, target[i], "\"%L\" set charge in slot \"%d\" to \"%f\" on \"%L\"", client, slot, charge, target[i]);
				}
			}
			
			if(!found)
			{
				ReplyToCommand(client, "[SM] %t", "Target must be boss");
			}
			else if(lang)
			{
				FShowActivity(client, "%t", "Set Charge On", buffer);
			}
			else
			{
				FShowActivity(client, "%t", "Set Charge On", "_s", buffer);
			}
		}
		else
		{
			ReplyToTargetError(client, matches);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: ff2_setcharge <client> [amount] [slot]");
	}
	return Plugin_Handled;
}

void Bosses_BuildPacks(int &charset, const char[] mapname)
{
	if(BossList)
	{
		int length = BossList.Length;
		for(int i; i < length; i++)
		{
			DeleteCfg(BossList.Get(i));
		}
		
		delete BossList;
	}
	
	BossList = new ArrayList();
	
	if(PackList)
		delete PackList;
	
	PackList = new ArrayList(64, 0);
	// TODO: Hidden boss packs or boss pack settings
	
	Music_ClearPlaylist();
	
	DownloadTable = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	
	char filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, sizeof(filepath), FILE_CHARACTERS);
	
	if(FileExists(filepath))
	{
		BuildPath(Path_SM, filepath, sizeof(filepath), FOLDER_CONFIGS);
		
		ConfigMap cfg = new ConfigMap(FILE_CHARACTERS);
		SortedSnapshot snap = CreateSortedSnapshot(cfg);
		
		int pack;
		PackVal val;
		int entries = snap.Length;
		if(charset != -1)
		{
			char name[64];
			if(ForwardOld_OnLoadCharacterSet(charset, name))
			{
				for(int i; i < entries; i++)	// Boss Packs
				{
					int length = snap.KeyBufferSize(i)+1;
					char[] packname = new char[length];
					snap.GetKey(i, packname, length);
					cfg.GetArray(packname, val, sizeof(val));
					if(val.tag != KeyValType_Section)
						continue;
					
					if(StrEqual(packname, name, false))
					{
						charset = pack;
						break;
					}
					
					ConfigMap cfgSub = val.cfg;
					if(!cfgSub)
						continue;
					
					StringMapSnapshot snapSub = cfgSub.Snapshot();
					if(!snapSub)
						continue;
					
					if(snapSub.Length)
						pack++;
					
					delete snapSub;
				}
				
				pack = 0;
			}
		}
		
		for(int i; i < entries; i++)	// Boss Packs
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] packname = new char[length];
			snap.GetKey(i, packname, length);
			cfg.GetArray(packname, val, sizeof(val));
			if(val.tag != KeyValType_Section)
				continue;
			
			ConfigMap cfgSub = val.cfg;
			if(!cfgSub)
				continue;
			
			SortedSnapshot snapSub = CreateSortedSnapshot(cfgSub);
			if(!snapSub)
				continue;
			
			int entriesSub = snapSub.Length;
			if(entriesSub)
			{
				bool precache = charset == pack;
				PackList.PushString(packname);
				
				for(int a; a < entriesSub; a++)	// Bosses in this Pack
				{
					length = snapSub.KeyBufferSize(a)+1;
					char[] bossname = new char[length];
					snapSub.GetKey(a, bossname, length);
					cfgSub.GetArray(bossname, val, sizeof(val));
					switch(val.tag)
					{
						case KeyValType_Section:
						{
							length = ReplaceString(bossname, length, "*", "");
							if(length)
							{
								LoadCharacterDirectory(filepath, bossname, length>1, pack, mapname, precache);
							}
							else
							{
								LoadCharacter(bossname, pack, mapname, precache);
							}
						}
						case KeyValType_Value:
						{
							if(length > val.size)	// "saxton_hale"	""
							{
								if(!StrEqual(bossname, "hidden"))
								{
									length = ReplaceString(bossname, length, "*", "");
									if(length)
									{
										LoadCharacterDirectory(filepath, bossname, length>1, pack, mapname, precache);
									}
									else
									{
										LoadCharacter(bossname, pack, mapname, precache);
									}
								}
							}
							else	// "1"	"saxton_hale"
							{
								length = ReplaceString(val.data, sizeof(val.data), "*", "");
								if(length)
								{
									LoadCharacterDirectory(filepath, val.data, length>1, pack, mapname, precache);
								}
								else
								{
									LoadCharacter(val.data, pack, mapname, precache);
								}
							}
						}
					}
				}
				
				pack++;
			}
			
			delete snapSub;
		}
		
		delete snap;
		DeleteCfg(cfg);
	}
	else
	{
		PackList.PushString("Freak Fortress 2");
		BuildPath(Path_SM, filepath, sizeof(filepath), FOLDER_CONFIGS);
		LoadCharacterDirectory(filepath, "", true, 0, mapname, charset>=0);
	}
	
	LockStringTables(save);
	
	PackVal val;
	int length = BossList.Length;
	for(int i; i < length; i++)
	{
		ConfigMap cfg = BossList.Get(i);
		if(cfg.GetVal("enabled", val))
		{
			if(cfg.GetVal("companion", val))
			{
				char[] companion = new char[val.size];
				strcopy(companion, val.size, val.data);
				
				bool found;
				for(int a; a < length; a++)
				{
					ConfigMap cfgsub = BossList.Get(a);
					if(cfgsub.GetVal("enabled", val))
					{
						if(cfgsub.GetVal("filename", val))
						{
							if(StrEqual(companion, val.data, false))
							{
								cfg.SetInt("companion", a);
								found = true;
								break;
							}
						}
						
						if(cfgsub.GetVal("name", val))
						{
							if(StrEqual(companion, val.data, false))
							{
								cfg.SetInt("companion", a);
								found = true;
								break;
							}
						}
					}
				}
				
				if(!found)
					cfg.DeleteSection("companion");
			}
		}
	}
}

static void LoadCharacterDirectory(const char[] basepath, const char[] matching, bool full, int charset, const char[] map, bool precache, const char[] current = "")
{
	char filepath[PLATFORM_MAX_PATH];
	if(current[0])
	{
		FormatEx(filepath, sizeof(filepath), "%s/%s", basepath, current);
	}
	else
	{
		strcopy(filepath, sizeof(filepath), basepath);
	}
	
	DirectoryListing listing = OpenDirectory(filepath);
	if(!listing)
		return;
	
	FileType type;
	while(listing.GetNext(filepath, sizeof(filepath), type))
	{
		switch(type)
		{
			case FileType_File:
			{
				if(ReplaceString(filepath, sizeof(filepath), ".cfg", "", false) != 1)
					continue;
				
				if(current[0])
					Format(filepath, sizeof(filepath), "%s/%s", current, filepath);
				
				if(!matching[0] || (full && StrContains(filepath, matching) != -1) || (!full && !StrContains(filepath, matching)))
					LoadCharacter(filepath, charset, map, precache);
				
				continue;
			}
			case FileType_Directory:
			{
				if(!StrContains(filepath, "."))
					continue;
				
				if(current[0])
					Format(filepath, sizeof(filepath), "%s/%s", current, filepath);
				
				LoadCharacterDirectory(basepath, matching, full, charset, map, precache, filepath);
			}
		}
	}
	
	delete listing;
}

static void LoadCharacter(const char[] character, int charset, const char[] map, bool precached)
{
	char buffer[PLATFORM_MAX_PATH];
	FormatEx(buffer, sizeof(buffer), "%s/%s.cfg", FOLDER_CONFIGS, character);
	
	ConfigMap full = new ConfigMap(buffer);
	if(!full)
	{
		LogError("[Boss] %s is not a boss character", character);
		DeleteCfg(full);
		return;
	}
	
	ConfigMap cfg = full.GetSection("character");
	if(!cfg)
	{
		LogError("[Boss] %s is not a boss character", character);
		DeleteCfg(full);
		return;
	}
	
	bool precache = precached;
	Action action = Forward_OnBossPrecache(cfg, precache);
	if(action == Plugin_Stop)
	{
		DeleteCfg(full);
		return;
	}
	
	if(action != Plugin_Handled)
	{
		int i;
		if(cfg.GetInt("version", i) && i != MAJOR_REVISION && i != 99)
		{
			if(i == 2)
			{
				LogError("[Boss] %s is only compatible with Official Freak Fortress 2.0 Branch", character);
			}
			else
			{
				LogError("[Boss] %s is only compatible with base FF2 v%d", character, i);
			}
			
			DeleteCfg(full);
			return;
		}
		
		if(cfg.GetInt("version_minor", i))
		{
			int stable = -1;
			cfg.GetInt("version_stable", stable);
			
			if(i > MINOR_REVISION || (i == MINOR_REVISION && stable > STABLE_REVISION))
			{
				if(stable < 0)
				{
					LogError("[Boss] %s is only compatible with base FF2 v%d.%d and newer", character, MAJOR_REVISION, i);
				}
				else
				{
					LogError("[Boss] %s is only compatible with base FF2 v%d.%d.%d and newer", character, MAJOR_REVISION, i, stable);
				}
				
				DeleteCfg(full);
				return;
			}
		}
		
		if(cfg.GetInt("fversion", i) && i != 2)
		{
			if(i == 1)
			{
				LogError("[Boss] %s is only compatible with Unofficial Freak Fortress", character);
			}
			else
			{
				LogError("[Boss] %s is only compatible with forked FF2 v%d", character, i);
			}
			
			DeleteCfg(full);
			return;
		}
	}
	
	// Delete the full ConfigMap but not our needed ConfigMap
	PackVal val;
	StringMapSnapshot snap = full.Snapshot();
	if(snap)
	{
		int entries = snap.Length;
		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] key = new char[length];
			snap.GetKey(i, key, length);
			full.GetArray(key, val, sizeof(val));
			
			if(val.tag == KeyValType_Section)
			{
				if(val.cfg != cfg)
					DeleteCfg(val.cfg);
			}
		}
		
		delete snap;
	}
	
	delete full;
	
	if(action != Plugin_Handled)
	{
		if(precache)
		{
			ConfigMap cfgsub = cfg.GetSection("map_listing");
			if(cfgsub)
			{
				snap = cfgsub.Snapshot();
				if(snap)
				{
					int entries = snap.Length;
					if(entries)
					{
						int size;
						for(int i; i < entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							if(size > length)
								continue;
							
							char[] mapname = new char[length];
							snap.GetKey(i, mapname, length);
							cfgsub.GetArray(mapname, val, sizeof(val));
							if(val.tag != KeyValType_Value)
								continue;
							
							int amount = ReplaceString(mapname, length, "*", "");
							if(StrEqual(map, mapname, false) || (amount == 1 && !StrContains(map, mapname, false)) || (amount > 1 && StrContains(map, mapname, false) != -1))
							{
								precache = view_as<bool>(StringToInt(val.data));
								size = length;
							}
						}
					}
					delete snap;
				}
			}
			else
			{
				// Backwards Compatibility Below
				cfgsub = cfg.GetSection("map_only");
				if(cfgsub)
				{
					snap = cfgsub.Snapshot();
					if(snap)
					{
						int entries = snap.Length;
						if(entries)
						{
							bool found;
							for(int i; i < entries; i++)
							{
								int length = snap.KeyBufferSize(i)+1;
								char[] key = new char[length];
								snap.GetKey(i, key, length);
								cfgsub.GetArray(key, val, sizeof(val));
								if(val.tag != KeyValType_Value)
									continue;
								
								if(!StrContains(map, val.data, false))
								{
									found = true;
									break;
								}
							}
							
							if(!found)
								precache = false;
						}
						delete snap;
					}
				}
				else
				{
					cfgsub = cfg.GetSection("map_exclude");
					if(cfgsub)
					{
						snap = cfgsub.Snapshot();
						if(snap)
						{
							int entries = snap.Length;
							if(entries)
							{
								for(int i; i < entries; i++)
								{
									int length = snap.KeyBufferSize(i)+1;
									char[] key = new char[length];
									snap.GetKey(i, key, length);
									cfgsub.GetArray(key, val, sizeof(val));
									if(val.tag != KeyValType_Value)
										continue;
									
									if(!StrContains(map, val.data, false))
									{
										precache = false;
										break;
									}
								}
							}
							delete snap;
						}
					}
				}
			}
		}
		
		if(precache && cfg.Get("model", buffer, sizeof(buffer)) && buffer[0])
			PrecacheModel(buffer);
	}
	
	if(action != Plugin_Handled)
	{
		int special = BossList.Length;
		bool clean = !CvarDebug.BoolValue;
		
		snap = cfg.Snapshot();
		if(snap)
		{
			int entries = snap.Length;
			if(entries)
			{
				char buffer2[PLATFORM_MAX_PATH];
				for(int i; i < entries; i++)
				{
					int length = snap.KeyBufferSize(i)+1;
					char[] section = new char[length];
					snap.GetKey(i, section, length);
					cfg.GetArray(section, val, sizeof(val));
					if(val.tag != KeyValType_Section)
						continue;
					
					ConfigMap cfgsub = val.cfg;
					if(!cfgsub)
						continue;
					
					if(!precache)
					{
						if(clean)
						{
							DeleteCfg(cfgsub);
							cfg.Remove(section);
						}
						continue;
					}
					
					StringMapSnapshot snapsub = cfgsub.Snapshot();
					if(!snapsub)
						continue;
					
					static const char MdlExts[][] = {"sw.vtx", "mdl", "dx80.vtx", "dx90.vtx", "vvd", "phy"};
					static const char MatExts[][] = {"vtf", "vmt"};
					
					int entriessub = snapsub.Length;
					switch(GetSectionType(section))
					{
						case Section_Ability:
						{
							if(!StrContains(section, "ability") && cfgsub.Get("name", buffer, sizeof(buffer)))
							{
								cfgsub.DeleteSection("name");
								cfg.Remove(section);
								cfg.SetArray(buffer, val, sizeof(val));
							}
						}
						case Section_Weapon:
						{
							if(cfgsub.Get("worldmodel", buffer, sizeof(buffer)) && buffer[0])
							{
								if(FileExists(buffer, true))
								{
									cfgsub.SetInt("worldmodel", PrecacheModel(buffer));
								}
								else
								{
									cfgsub.DeleteSection("worldmodel");
									LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
								}
							}
							
							/*if(!StrContains(section, "weapon") || !StrContains(section, "wearable"))
							{
								cfgsub.DeleteSection("name");
								cfg.Remove(section);
								if(!cfgsub.Get("name", buffer, sizeof(buffer)))
									strcopy(buffer, sizeof(buffer), "tf_wearable");
								
								cfg.SetArray(buffer, val, sizeof(val));
							}*/
						}
						case Section_Sound:
						{
							bool bgm = StrEqual(section, "sound_bgm");
							for(int a; a < entriessub; a++)
							{
								int length2 = snapsub.KeyBufferSize(a)+2;
								char[] key = new char[length2];
								snapsub.GetKey(a, key, length2);
								cfgsub.GetArray(key, val, sizeof(val));
								switch(val.tag)
								{
									case KeyValType_Section:
									{
										bool music = bgm;
										if(!music)
										{
											ConfigMap cfgsound = val.cfg;
											if(cfgsound)
												music = view_as<bool>(cfgsound.GetInt("time", length2));
										}
										
										if(StrContains(key, SndExts[0]) != -1 || StrContains(key, SndExts[1]) != -1)
										{
											if(music && StrContains(key, "#") != 0)	// Replace the tree with an added #
											{
												cfgsub.Remove(key);
												Format(key, length2, "#%s", key);
												cfgsub.SetArray(key, val, sizeof(val));
											}
											
											PrecacheSound(key);
										}
										else
										{
											PrecacheScriptSound(key);
										}
										
										if(music)
											Music_AddSong(special, section, key);
									}
									case KeyValType_Value:
									{
										if(IsNotExtraArg(key))
										{
											strcopy(buffer, sizeof(buffer), val.data);
											
											bool music = bgm;
											if(length2 > val.size)	// "example.mp3"	""
											{
												if(!music)
												{
													Format(buffer, sizeof(buffer), "%smusic", buffer);
													music = view_as<bool>(cfgsub.GetInt(section, length2));
												}
												
												if(StrContains(key, SndExts[0]) != -1 || StrContains(key, SndExts[1]) != -1)	// Check to make sure it's a sound
												{
													if(music && StrContains(key, "#") != 0)
													{
														cfgsub.Remove(key);
														Format(key, length2, "#%s", key);
														cfgsub.SetArray(key, val, sizeof(val));
													}
													
													PrecacheSound(key);
												}
												else
												{
													PrecacheScriptSound(key);
												}
											}
											else	// "1"	"example.mp3"
											{
												if(!music)
												{
													Format(buffer2, sizeof(buffer2), "%smusic", key);
													music = view_as<bool>(cfgsub.GetInt(buffer2, length2));
												}
												
												if(StrContains(buffer, SndExts[0]) != -1 || StrContains(buffer, SndExts[1]) != -1)	// Check to make sure it's a sound
												{
													if(music && StrContains(buffer, "#") != 0)
													{
														Format(buffer, sizeof(buffer), "#%s", buffer);
														cfgsub.Set(key, buffer);
													}
													
													PrecacheSound(buffer);
												}
												else
												{
													PrecacheScriptSound(buffer);
												}
												
												Format(buffer2, sizeof(buffer2), "slot%s", key);
												if(!cfgsub.GetInt(buffer2, length))
													cfgsub.SetInt(buffer2, 0);
											}
											
											if(music)
												Music_AddSong(special, section, key);
										}
									}
								}
							}
						}
						case Section_Precache:
						{
							for(int a; a < entriessub; a++)
							{
								length = snapsub.KeyBufferSize(a)+1;
								char[] key = new char[length];
								snapsub.GetKey(a, key, length);
								cfgsub.GetArray(key, val, sizeof(val));
								
								if(!key[0] || !IsNotExtraArg(key))
								{
									LogError("[Boss] '%s' has bad file '%s' in '%s'", character, key, section);
									continue;
								}
								
								switch(val.tag)
								{
									case KeyValType_Section:
									{
										if(!FileExists(key, true))
										{
											LogError("[Boss] '%s' is missing file '%s' in '%s'", character, key, section);
										}
										else if(StrContains(key, SndExts[0]) != -1 || StrContains(key, SndExts[1]) != -1)
										{
											PrecacheSound(key);
										}
										else
										{
											PrecacheModel(key);
										}
									}
									case KeyValType_Value:
									{
										if(length > val.size)	// "models/example.mdl"	"mdl"
										{
											if(val.data[0] == 'm')	// mdl, model, mat, material
											{
												PrecacheModel(key);
											}
											else if(val.data[0] == 'g' || val.data[2] == 'r')	// gs, gamesound, script
											{
												PrecacheScriptSound(key);
											}
											else if(val.data[0] == 's')
											{
												if(val.data[1] == 'e')	// sentence
												{
													PrecacheSentenceFile(key);
												}
												else	// snd, sound
												{
													PrecacheSound(key);
												}
											}
											else if(val.data[0] == 'd')	// decal
											{
												PrecacheDecal(key);
											}
											else if(val.data[0])	// generic
											{
												PrecacheGeneric(key);
											}
										}
										else			// "mdl"	"models/example.mdl"
										{
											if(key[0] == 'm')	// mdl, model, mat, material
											{
												PrecacheModel(val.data);
											}
											else if(key[0] == 'g' || key[2] == 'r')	// gs, gamesound, script
											{
												PrecacheScriptSound(val.data);
											}
											else if(key[0] == 's')
											{
												if(key[1] == 'e')	// sentence
												{
													PrecacheSentenceFile(val.data);
												}
												else	// snd, sound
												{
													PrecacheSound(val.data);
												}
											}
											else if(key[0] == 'd')	// decal
											{
												PrecacheDecal(val.data);
											}
											else if(key[0])	// generic
											{
												PrecacheGeneric(val.data);
											}
										}
									}
								}
							}
							
							if(clean)
							{
								DeleteCfg(cfgsub);
								cfg.Remove(section);
							}
						}
						case Section_ModCache:
						{
							for(int a; a < entriessub; a++)
							{
								length = snapsub.KeyBufferSize(a)+1;
								char[] key = new char[length];
								snapsub.GetKey(a, key, length);
								cfgsub.GetArray(key, val, sizeof(val));
								
								if(!key[0] || !IsNotExtraArg(key))
								{
									LogError("[Boss] '%s' has bad file '%s' in '%s'", character, key, section);
									continue;
								}
								
								switch(val.tag)
								{
									case KeyValType_Section:
									{
										if(FileExists(key, true))
										{
											PrecacheModel(key);
										}
										else
										{
											LogError("[Boss] '%s' is missing file '%s' in '%s'", character, key, section);
										}
									}
									case KeyValType_Value:
									{
										if(length > val.size)	// "models/example.mdl"	"mdl"
										{
											if(FileExists(key, true))
											{
												PrecacheModel(key);
											}
											else
											{
												LogError("[Boss] '%s' is missing file '%s' in '%s'", character, key, section);
											}
										}
										else if(val.data[0])	// "1"	"models/example.mdl"
										{
											if(FileExists(val.data, true))
											{
												PrecacheModel(val.data);
											}
											else
											{
												LogError("[Boss] '%s' is missing file '%s' in '%s'", character, val.data, section);
											}
										}
									}
								}
							}
							
							if(clean)
							{
								DeleteCfg(cfgsub);
								cfg.Remove(section);
							}
						}
						case Section_Download:
						{
							for(int a; a < entriessub; a++)
							{
								length = snapsub.KeyBufferSize(a)+1;
								char[] key = new char[length];
								snapsub.GetKey(a, key, length);
								cfgsub.GetArray(key, val, sizeof(val));
								
								if(!key[0] || !IsNotExtraArg(key))
								{
									LogError("[Boss] '%s' has bad file '%s' in '%s'", character, key, section);
									continue;
								}
								
								switch(val.tag)
								{
									case KeyValType_Section:
									{
										if(FileExists(key, true))
										{
											AddToStringTable(DownloadTable, key);
										}
										else
										{
											LogError("[Boss] '%s' is missing file '%s' in '%s'", character, key, section);
										}
									}
									case KeyValType_Value:
									{
										if(length > val.size)	// "models/example"	"mdl"
										{
											if(val.data[1] == 'a')	// mat, material
											{
												for(int b; b < sizeof(MatExts); b++)
												{
													FormatEx(buffer, sizeof(buffer), "%s.%s", key, MatExts[b]);
													if(FileExists(buffer, true))
													{
														AddToStringTable(DownloadTable, buffer);
													}
													else
													{
														LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
													}
												}
												continue;
											}
											else if(val.data[1] == 'd' || val.data[1] == 'o')	// mdl, model
											{
												for(int b; b < sizeof(MdlExts); b++)
												{
													FormatEx(buffer, sizeof(buffer), "%s.%s", key, MdlExts[b]);
													if(FileExists(buffer, true))
													{
														if(b)
															AddToStringTable(DownloadTable, buffer);
													}
													else if(b != sizeof(MdlExts)-1)
													{
														LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
														break;
													}
												}
											}
											else
											{
												if(FileExists(key, true))
												{
													AddToStringTable(DownloadTable, key);
												}
												else
												{
													LogError("[Boss] '%s' is missing file '%s' in '%s'", character, key, section);
												}
											}
										}
										else			// "1"	"sound/example.mp3"
										{
											if(FileExists(val.data, true))
											{
												AddToStringTable(DownloadTable, val.data);
											}
											else
											{
												LogError("[Boss] '%s' is missing file '%s' in '%s'", character, val.data, section);
											}
										}
									}
								}
							}
							
							if(clean)
							{
								DeleteCfg(cfgsub);
								cfg.Remove(section);
							}
						}
						case Section_Model:
						{
							for(int a; a < entriessub; a++)
							{
								length = snapsub.KeyBufferSize(a)+10;
								char[] key = new char[length];
								snapsub.GetKey(a, key, length);
								cfgsub.GetArray(key, val, sizeof(val));
								
								if(!key[0] || !IsNotExtraArg(key))
								{
									LogError("[Boss] '%s' has bad file '%s' in '%s'", character, key, section);
									continue;
								}
								
								switch(val.tag)
								{
									case KeyValType_Section:
									{
										for(int b; b < sizeof(MdlExts); b++)
										{
											FormatEx(buffer, sizeof(buffer), "%s.%s", key, MdlExts[b]);
											if(FileExists(buffer, true))
											{
												if(b)
													AddToStringTable(DownloadTable, buffer);
											}
											else if(b != sizeof(MdlExts)-1)
											{
												LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
												break;
											}
										}
									}
									case KeyValType_Value:
									{
										if(length > val.size)	// "models/example"	"mdl"
										{
											for(int b; b < sizeof(MdlExts); b++)
											{
												FormatEx(buffer, sizeof(buffer), "%s.%s", key, MdlExts[b]);
												if(FileExists(buffer, true))
												{
													if(b)
														AddToStringTable(DownloadTable, buffer);
												}
												else if(b != sizeof(MdlExts)-1)
												{
													LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
													break;
												}
											}
										}
										else			// "1"	"models/example"
										{
											for(int b; b < sizeof(MdlExts); b++)
											{
												FormatEx(buffer, sizeof(buffer), "%s.%s", val.data, MdlExts[b]);
												if(FileExists(buffer, true))
												{
													if(b)
														AddToStringTable(DownloadTable, buffer);
												}
												else if(b != sizeof(MdlExts)-1)
												{
													LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
													break;
												}
											}
										}
									}
								}
							}
							
							if(clean)
							{
								DeleteCfg(cfgsub);
								cfg.Remove(section);
							}
						}
						case Section_Material:
						{
							for(int a; a < entriessub; a++)
							{
								length = snapsub.KeyBufferSize(a)+5;
								char[] key = new char[length];
								snapsub.GetKey(a, key, length);
								cfgsub.GetArray(key, val, sizeof(val));
								
								if(!key[0] || !IsNotExtraArg(key))
								{
									LogError("[Boss] '%s' has bad file '%s' in '%s'", character, key, section);
									continue;
								}
								
								switch(val.tag)
								{
									case KeyValType_Section:
									{
										for(int b; b < sizeof(MatExts); b++)
										{
											FormatEx(buffer, sizeof(buffer), "%s.%s", key, MatExts[b]);
											if(FileExists(buffer, true))
											{
												AddToStringTable(DownloadTable, buffer);
											}
											else
											{
												LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
											}
										}
									}
									case KeyValType_Value:
									{
										if(length > val.size)	// "materials/example"	"mat"
										{
											for(int b; b < sizeof(MatExts); b++)
											{
												FormatEx(buffer, sizeof(buffer), "%s.%s", key, MatExts[b]);
												if(FileExists(buffer, true))
												{
													AddToStringTable(DownloadTable, buffer);
												}
												else
												{
													LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
												}
											}
										}
										else			// "1"	"materials/example"
										{
											for(int b; b < sizeof(MatExts); b++)
											{
												FormatEx(buffer, sizeof(buffer), "%s.%s", val.data, MatExts[b]);
												if(FileExists(buffer, true))
												{
													AddToStringTable(DownloadTable, buffer);
												}
												else
												{
													LogError("[Boss] '%s' is missing file '%s' in '%s'", character, buffer, section);
												}
											}
										}
									}
								}
							}
							
							if(clean)
							{
								DeleteCfg(cfgsub);
								cfg.Remove(section);
							}
						}
					}
					
					delete snapsub;
				}
			}
			
			delete snap;
		}
	}
	
	if(!cfg.GetVal("name", val))
		cfg.Set("name", character);
	
	cfg.Set("filename", character);
	cfg.SetInt("charset", charset);
	if(precache)
	{
		cfg.SetInt("enabled", 1);
	}
	else
	{
		cfg.DeleteSection("enabled");
	}
	
	TFClassType class = TFClass_Scout;
	if(cfg.Get("class", buffer, sizeof(buffer)))
		class = GetClassOfName(buffer);
	
	cfg.SetInt("class", view_as<int>(class));
	
	Forward_OnBossPrecached(cfg, precache, BossList.Push(cfg));
}

void Bosses_MapEnd()
{
	Bosses_PluginEnd();
	DisableSubplugins();
}

void Bosses_PluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		Bosses_Remove(i);
	}
}

int Bosses_GetCharset(int charset, char[] buffer, int length)
{
	if(!PackList || charset<0 || charset>=PackList.Length)
		return 0;
	
	return PackList.GetString(charset, buffer, length);
}

int Bosses_GetCharsetLength()
{
	return PackList ? PackList.Length : 0;
}

ConfigMap Bosses_GetConfig(int special)
{
	if(!BossList || special<0 || special>=BossList.Length)
		return null;
	
	return BossList.Get(special);
}

int Bosses_GetConfigLength()
{
	return BossList.Length;
}

int Bosses_GetByName(const char[] name, bool exact = true, bool enabled = true, int lang = -1, const char[] string = "name")
{
	int similarBoss = -1;
	if(BossList)
	{
		int length = BossList.Length;
		int size1 = exact ? 0 : strlen(name);
		int similarChars;
		
		char language[5];
		if(lang != -1)
			GetLanguageInfo(lang, language, sizeof(language));
		
		bool found;
		for(int i; i < length; i++)
		{
			ConfigMap cfg = BossList.Get(i);
			if(!enabled || (cfg.GetBool("enabled", found) && found))
			{
				found = false;
				static char buffer[64];
				if(lang != -1)
				{
					Format(buffer, sizeof(buffer), "%s_%s", string, language);
					found = view_as<bool>(cfg.Get(buffer, buffer, sizeof(buffer)));
				}
				
				if(found || cfg.Get(string, buffer, sizeof(buffer)))
				{
					if(StrEqual(name, buffer, false))
						return i;
					
					if(!exact)
					{
						int bump = StrContains(buffer, name, false);
						if(bump == -1)
							bump = 0;
						
						int size2 = strlen(buffer) - bump;
						if(size2 > size1)
							size2 = size1;
						
						int amount;
						for(int c; c < size2; c++)
						{
							if(CharToLower(name[c]) == CharToLower(buffer[c + bump]))
								amount++;
						}
						
						if(amount > similarChars)
						{
							similarChars = amount;
							similarBoss = i;
						}
					}
				}
			}
		}
	}
	return similarBoss;
}

bool Bosses_CanAccessBoss(int client, int special, bool playing = false, int team = -1, bool enabled = true, bool &preview = false)
{
	ConfigMap cfg = Bosses_GetConfig(special);
	if(!cfg)
		return false;
	
	bool blocked;
	if(enabled && (!cfg.GetBool("enabled", blocked) || !blocked))
		return false;
	
	cfg.GetBool("preview", preview, false);
	
	static char buffer1[512];
	if(cfg.Get("steamid", buffer1, sizeof(buffer1)))
	{
		static char buffer2[64];
		return GetClientAuthId(client, AuthId_SteamID64, buffer2, sizeof(buffer2)) && StrContains(buffer1, buffer2, false) != -1;
	}
	
	blocked = false;
	if(cfg.GetBool("blocked", blocked, false) && blocked)
		return false;
	
	blocked = false;
	if(cfg.GetBool("owner", blocked, false) && blocked)
		return false;
	
	if(team != -1)
	{
		int value;
		if(cfg.GetInt("bossteam", value) && value > TFTeam_Spectator && team != value)
			return false;
	}
	
	bool admin = view_as<bool>(cfg.Get("admin", buffer1, sizeof(buffer1)));
	if(admin)
		blocked = (playing || !CheckCommandAccess(client, "ff2_all_bosses", ReadFlagString(buffer1), true));
	
	if(!admin || blocked)
	{
		if(cfg.Get("cvar", buffer1, sizeof(buffer1)))
		{
			// If a cvar, check if it's enabled
			ConVar cvar = FindConVar(buffer1);
			if(!cvar || !cvar.BoolValue)
				return false;
			
			blocked = false;
		}
		
		if(!playing)	// If have both "admin" and "hidden", allow playing the boss randomly
			cfg.GetBool("hidden", blocked, false);
	}
	
	return !blocked;
}

bool Bosses_GetBossName(int special, char[] buffer, int length, int lang = -1, const char[] string = "name")
{
	ConfigMap cfg = Bosses_GetConfig(special);
	if(!cfg)
		return false;
	
	return Bosses_GetBossNameCfg(cfg, buffer, length, lang, string);
}

bool Bosses_GetBossNameCfg(ConfigMap cfg, char[] buffer, int length, int lang = -1, const char[] string = "name")
{
	if(lang != -1)
	{
		GetLanguageInfo(lang, buffer, length);
		Format(buffer, length, "%s_%s", string, buffer);
		if(!cfg.Get(buffer, buffer, length) && !cfg.Get(string, buffer, length))
			buffer[0] = 0;
	}
	else if(!cfg.Get(string, buffer, length))
	{
		buffer[0] = 0;
	}
	
	ReplaceString(buffer, length, "\\n", "\n");
	ReplaceString(buffer, length, "\\t", "\t");
	ReplaceString(buffer, length, "\\r", "\r");
	return view_as<bool>(buffer[0]);
}

void Bosses_CreateFromSpecial(int client, int special, int team)
{
	ConfigMap cfg = Bosses_GetConfig(special);
	if(!cfg)
		return;
	
	static char buffer[128];
	cfg.Get("filename", buffer, sizeof(buffer));
	Client(client).SetLastPlayed(buffer);
	
	Bosses_CreateFromConfig(client, cfg, team);
	
	Client(client).Cfg.SetInt("special", special);
}

void Bosses_CreateFromConfig(int client, ConfigMap cfg, int team)
{
	if(Client(client).Index < 0)
	{
		for(int i; ; i++)
		{
			if(FindClientOfBossIndex(i) == -1)
			{
				Client(client).Index = i;
				break;
			}
		}
	}
	
	if(Client(client).Cfg)
	{
		Forward_OnBossRemoved(client);
		DeleteCfg(Client(client).Cfg);
	}
	
	EnableSubplugins();
	
	Client(client).Cfg = cfg.Clone(ThisPlugin);
	
	if(GetClientTeam(client) != team)
		SDKCall_ChangeClientTeam(client, team);
	
	DHook_HookBoss(client);
	Events_CheckAlivePlayers(_, false);
	SDKHook_BossCreated(client);
	
	SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
	SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
	SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", 0);
	
	int i = 1;
	bool value = CvarSpecTeam.BoolValue;
	for(int t = CvarSpecTeam.BoolValue ? 0 : 2; t < 4; t++)
	{
		if(team != t)
			i += PlayersAlive[t];
	}
	
	Bosses_SetHealth(client, i);
	
	if(!Client(client).Cfg.GetInt("fversion", i) || i != 2)
	{
		if(!Client(client).Cfg.GetBool("triple", value, false))
			Client(client).Cfg.SetInt("triple", CvarBossTriple.IntValue);
		
		if(!Client(client).Cfg.GetBool("crits", value, false))
			Client(client).Cfg.SetInt("crits", CvarBossCrits.IntValue);
		
		if(!Client(client).Cfg.GetInt("knockback", i))
			Client(client).Cfg.SetInt("knockback", CvarBossKnockback.IntValue);
		
		if(!Client(client).Cfg.GetInt("healing", i))
			Client(client).Cfg.SetInt("healing", CvarBossHealing.IntValue);
	}
	
	static char buffer[512];
	bool active = GetRoundStatus() == 1;
	if(active && Client(client).Cfg.Get("command", buffer, sizeof(buffer)))
		ServerCommand(buffer);
	
	TF2_RegeneratePlayer(client);
	
	if(active)
	{
		Bosses_PlaySoundToAll(client, "sound_begin", _, _, _, _, _, 2.0);
		Music_RoundStart();
	}
	
	Forward_OnBossCreated(client, Client(client).Cfg, !active);
	
	Goomba_BossCreated(Client(client).Cfg);
	
	if(Client(client).Cfg.GetInt("companion", i))
	{
		bool disband;
		int companion = Preference_GetCompanion(client, i, team, disband);
		if(companion)
		{
			Bosses_CreateFromSpecial(companion, i, team);
			
			if(disband)
			{
				Preference_FinishParty(client);
				Preference_FinishParty(companion);
			}
		}
		else
		{
			i = RoundFloat(Client(client).MaxHealth * 2.8);
			Client(client).MaxHealth = i;
			Client(client).Cfg.SetInt("health_formula", i);
			
			if(IsPlayerAlive(client))
			{
				SetEntityHealth(client, i);
				Bosses_UpdateHealth(client);
			}
		}
	}
}

int Bosses_SetHealth(int client, int players)
{
	float ragedmg = 1900.0;
	static char buffer[1024];
	if(Client(client).Cfg.Get("ragedamage", buffer, sizeof(buffer)))
		ragedmg = ParseFormula(buffer, players);
	
	Client(client).RageDamage = ragedmg;
	
	int maxhealth;
	if(Client(client).Cfg.Get("health_formula", buffer, sizeof(buffer)))
		maxhealth = RoundFloat(ParseFormula(buffer, players));
	
	if(maxhealth < 1)
		maxhealth = RoundFloat(Pow((760.8 + players) * (players - 1.0), 1.0341) + 2046.0);
	
	Client(client).MaxHealth = maxhealth;
	
	int lives = Client(client).MaxLives;
	if(lives < 1)
	{
		lives = 1;
		Client(client).MaxLives = lives;
	}
	
	Client(client).Lives = lives;
	
	if(IsPlayerAlive(client))
	{
		SetEntityHealth(client, Client(client).MaxHealth);
		Bosses_UpdateHealth(client);
		Bosses_SetSpeed(client);
	}
	
	Gamemode_UpdateHUD(GetClientTeam(client));
	return maxhealth;
}

void Bosses_Equip(int client)
{
	EquipBoss(client, false);
	CreateTimer(0.1, Bosses_EquipTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Bosses_EquipTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && Client(client).IsBoss)
		EquipBoss(client, true);
	
	return Plugin_Continue;
}

static void EquipBoss(int client, bool weapons)
{
	TF2_RemovePlayerDisguise(client);
	TF2_RemoveAllItems(client);
	
	int i;
	Client(client).Cfg.GetInt("healing", i);			
	switch(i)
	{
		case 0:
			TF2Attrib_SetByDefIndex(client, 734, 0.0);
								
		case 1:
			TF2Attrib_SetByDefIndex(client, 740, 0.0);
	}
	
	any class;
	Client(client).Cfg.GetInt("class", class);
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))
		class = TFClass_Scout;
	
	if(class != TFClass_Unknown)
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));
	
	SetEntityHealth(client, Client(client).MaxHealth);
	Client(client).Lives = Client(client).MaxLives;
	
	bool value;
	Client(client).Cfg.GetBool("cosmetics", value, false);
	
	i = 0;
	int index;
	while(TF2U_GetWearable(client, index, i))
	{
		switch(GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:
			{
				// Action slot items
			}
			case 131, 133, 405, 406, 444, 608, 1099, 1144:
			{
				// Wearable weapons
				TF2_RemoveWearable(client, index);
			}
			default:
			{
				// Wearable cosmetics
				if(!value)
					TF2_RemoveWearable(client, index);
			}
		}
	}
	
	static char buffer[PLATFORM_MAX_PATH];
	if(Client(client).Cfg.Get("model", buffer, sizeof(buffer)))
	{
		SetVariantString(buffer);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	}
	
	if(weapons)
	{
		StringMapSnapshot snap = Client(client).Cfg.Snapshot();
		if(snap)
		{
			int entries = snap.Length;
			if(entries)
			{
				value = false;
				PackVal val;
				for(i = 0; i < entries; i++)
				{
					static char classname[36];
					snap.GetKey(i, classname, sizeof(classname));
					Client(client).Cfg.GetArray(classname, val, sizeof(val));
					if(val.tag != KeyValType_Section || GetSectionType(classname) != Section_Weapon)
						continue;
					
					ConfigMap cfg = val.cfg;
					if(!cfg)
						continue;
					
					if(StrContains(classname, "tf_") != 0 &&
					  !StrEqual(classname, "saxxy"))
					{
						if(!cfg.Get("name", classname, sizeof(classname)))
							strcopy(classname, sizeof(classname), "tf_wearable");
					}
					
					GetClassWeaponClassname(class, classname, sizeof(classname));
					bool wearable = StrContains(classname, "tf_weap") != 0;
					
					cfg.GetInt("index", index);
					
					int level = -1;
					cfg.GetInt("level", level);
					
					int quality = 5;
					cfg.GetInt("quality", quality);
					
					bool preserve;
					cfg.GetBool("preserve", preserve, false);
					
					bool override;
					cfg.GetBool("override", override, false);
					
					int kills = -1;
					if(!cfg.GetInt("rank", kills) && level == -1 && !override)
						kills = GetURandomInt() % 21;
					
					if(kills >= 0)
						kills = wearable ? GetKillsOfCosmeticRank(kills, index) : GetKillsOfWeaponRank(kills, index);
					
					if(level < 0 || level > 127)
						level = 101;
					
					bool found = (cfg.Get("attributes", buffer, sizeof(buffer)) && buffer[0]);
					
					if(!wearable && !override)
					{
						if(value)
						{
							if(found)
							{
								Format(buffer, sizeof(buffer), "2 ; 3.1 ; %s", buffer);
							}
							else
							{
								strcopy(buffer, sizeof(buffer), "2 ; 3.1");
							}
						}
						else if(found)
						{
							Format(buffer, sizeof(buffer), "2 ; 3.1 ; 275 ; 1 ; %s", buffer);
						}
						else
						{
							strcopy(buffer, sizeof(buffer), "2 ; 3.1 ; 275 ; 1");
						}
					}
					else if(!found)
					{
						buffer[0] = 0;
					}
					
					static char buffers[40][16];
					int count = ExplodeString(buffer, " ; ", buffers, sizeof(buffers), sizeof(buffers));
					
					if(count % 2)
						count--;
					
					int attribs;
					int entity = -1;
					if(wearable)
					{
						entity = CreateEntityByName(classname);
						if(IsValidEntity(entity))
						{
							SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
							SetEntProp(entity, Prop_Send, "m_bInitialized", true);
							SetEntProp(entity, Prop_Send, "m_iEntityQuality", quality);
							SetEntProp(entity, Prop_Send, "m_iEntityLevel", level);
							
							DispatchSpawn(entity);
							
							Debug("Created Wearable");
						}
						else
						{
							Client(client).Cfg.Get("filename", buffer, sizeof(buffer));
							LogError("[Boss] Invalid classname '%s' for '%s'", classname, buffer);
						}
					}
					else
					{
						Handle item = TF2Items_CreateItem(preserve ? (OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES) : (OVERRIDE_ALL|FORCE_GENERATION));
						TF2Items_SetClassname(item, classname);
						TF2Items_SetItemIndex(item, index);
						TF2Items_SetLevel(item, level);
						TF2Items_SetQuality(item, quality);
						TF2Items_SetNumAttributes(item, count/2 > 14 ? 15 : count/2);
						for(int a; attribs < count && a < 16; attribs += 2)
						{
							int attrib = StringToInt(buffers[attribs]);
							if(attrib)
							{
								TF2Items_SetAttribute(item, a++, attrib, StringToFloat(buffers[attribs+1]));
							}
							else
							{
								Client(client).Cfg.Get("filename", buffer, sizeof(buffer));
								LogError("[Boss] Bad weapon attribute passed for '%s' on '%s': %s ; %s", buffer, classname, buffers[attribs], buffers[attribs+1]);
							}
						}
						
						entity = TF2Items_GiveNamedItem(client, item);
						delete item;
					}
					
					if(entity != -1)
					{
						if(wearable)
						{
							TF2U_EquipPlayerWearable(client, entity);
						}
						else
						{
							EquipPlayerWeapon(client, entity);
						}
						
						for(; attribs < count; attribs += 2)
						{
							int attrib = StringToInt(buffers[attribs]);
							if(attrib)
							{
								TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(buffers[attribs+1]));
							}
							else
							{
								Client(client).Cfg.Get("filename", buffer, sizeof(buffer));
								LogError("[Boss] Bad weapon attribute passed for '%s' on '%s': %s ; %s", buffer, classname, buffers[attribs], buffers[attribs+1]);
							}
						}
						
						if(kills >= 0)
						{
							TF2Attrib_SetByDefIndex(entity, 214, view_as<float>(kills));
							if(wearable)
								TF2Attrib_SetByDefIndex(entity, 454, view_as<float>(64));
						}
						
						if(!wearable)
						{
							if(cfg.GetInt("clip", level))
								SetEntProp(entity, Prop_Data, "m_iClip1", level);
							
							if(cfg.GetInt("ammo", level))
							{
								int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
								if(type >= 0)
									SetEntProp(client, Prop_Data, "m_iAmmo", level, _, type);
							}
							
							if(index != 735 && StrEqual(classname, "tf_weapon_builder"))
							{
								for(level = 0; level < 4; level++)
								{
									SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", level != 3, _, level);
								}
							}
							else if(index == 735 || StrEqual(classname, "tf_weapon_sapper"))
							{
								SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
								SetEntProp(entity, Prop_Data, "m_iSubType", 3);
								
								for(level = 0; level < 4; level++)
								{
									SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", level == 3, _, level);
								}
							}
						}
						
						override = wearable;
						cfg.GetBool("show", override, false);
						if(override)
						{
							if(cfg.GetInt("worldmodel", index) && index)
							{
								SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", index);
								for(level = 0; level < 4; level++)
								{
									SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", index, _, level);
								}
							}
							
							SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
						}
						else
						{
							SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
							SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
						}
						
						level = 255;
						index = 255;
						kills = 255;
						count = 255;
						
						override = view_as<bool>(cfg.GetInt("alpha", level));
						override = (cfg.GetInt("red", index) || override);
						override = (cfg.GetInt("green", kills) || override);
						override = (cfg.GetInt("blue", count) || override);
						if(override)
						{
							SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
							SetEntityRenderColor(entity, index, kills, count, level);
						}
						
						SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
						
						if(!wearable && !value)
						{
							value = true;
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
						}
					}
				}
			}
			
			delete snap;
		}
	}
	
	Bosses_UpdateHealth(client);
	Bosses_SetSpeed(client);
	Gamemode_UpdateHUD(GetClientTeam(client));
}

void Bosses_UpdateHealth(int client)
{
	int maxhealth = Client(client).MaxHealth;
	if(maxhealth > 0)
	{
		int defaul = 125;
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Soldier:
				defaul = 200;
			
			case TFClass_Pyro, TFClass_DemoMan:
				defaul = 175;
			
			case TFClass_Heavy:
				defaul = 300;
			
			case TFClass_Medic:
				defaul = 150;
		}
		
		TF2Attrib_SetByDefIndex(client, 26, float(maxhealth-defaul));
	}
	else
	{
		TF2Attrib_SetByDefIndex(client, 26, 0.0);
	}
}

void Bosses_SetSpeed(int client)
{
	float maxspeed = 340.0;
	Client(client).Cfg.GetFloat("maxspeed", maxspeed);
	
	if(maxspeed > 0.0)
	{
		float defaul = 300.0;
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:
				defaul = 400.0;
			
			case TFClass_Soldier:
				defaul = 240.0;
			
			case TFClass_DemoMan:
				defaul = 280.0;
			
			case TFClass_Heavy:
				defaul = 230.0;
			
			case TFClass_Medic, TFClass_Spy:
				defaul = 320.0;
		}
		
		// Total Health / (This Life Max Health + Other Lives Max Health)
		maxspeed += 70.0 - (70.0 * Client(client).Health / (SDKCall_GetMaxHealth(client) + (Client(client).MaxHealth * (Client(client).MaxLives - 1))));
		TF2Attrib_SetByDefIndex(client, 442, maxspeed/defaul);
		SDKCall_SetSpeed(client);
	}
	else
	{
		TF2Attrib_SetByDefIndex(client, 442, 1.0);
	}
}

void Bosses_ClientDisconnect(int client)
{
	Client(client).Index = -1;
	if(Client(client).IsBoss)
	{
		DHook_UnhookBoss(client);
		Forward_OnBossRemoved(client);
		DeleteCfg(Client(client).Cfg);
		Client(client).Cfg = null;
	}
}

void Bosses_Remove(int client)
{
	Client(client).Index = -1;
	if(Client(client).IsBoss)
	{
		DHook_UnhookBoss(client);
		Forward_OnBossRemoved(client);
		
		DeleteCfg(Client(client).Cfg);
		Client(client).Cfg = null;
		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", 0);
		
		if(!Enabled)
		{
			bool found;
			for(int i = 1; i <= MaxClients; i++)
			{
				if(Client(i).IsBoss)
				{
					found = true;
					break;
				}
			}
			
			if(!found)
				Music_PlaySongToAll();
		}
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
		
		TF2Attrib_SetByDefIndex(client, 442, 1.0);
		TF2Attrib_SetByDefIndex(client, 26, 0.0);
		TF2Attrib_SetByDefIndex(client, 734, 1.0);
		TF2Attrib_SetByDefIndex(client, 740, 1.0);
		
		TF2_RemoveAllItems(client);
		if(IsPlayerAlive(client))
		{
			SetEntityHealth(client, 1);
			TF2_RegeneratePlayer(client);
		}
	}
}

int Bosses_GetBossTeam()
{
	static int bossTeam = TFTeam_Blue;
	int client = FindClientOfBossIndex(0);
	if(client != -1)
		bossTeam = GetClientTeam(client);
	
	return bossTeam;
}

void Bosses_PlayerRunCmd(int client, int buttons)
{
	if((!Enabled || RoundStatus == 1) && Client(client).IsBoss && IsPlayerAlive(client))
	{
		float time = GetGameTime();
		if(Client(client).PassiveAt <= time)
		{
			Client(client).PassiveAt = time + 0.2;
			Bosses_UseSlot(client, 1, 3);
		}
		
		if(!Client(client).NoHud && !(buttons & IN_SCORE))
		{
			time = GetEngineTime();
			if(Client(client).RefreshAt < time)
			{
				Client(client).RefreshAt = time + 0.2;
				
				SetGlobalTransTarget(client);
				
				static char buffer[256];
				int maxlives = Client(client).MaxLives;
				if(maxlives > 1)
				{
					Format(buffer, sizeof(buffer), "%t", "Boss Lives Left", Client(client).Lives, maxlives);
				}
				else
				{
					buffer[0] = ' ';
					buffer[1] = 0;
				}
				
				float ragedamage = Client(client).RageDamage;
				if(ragedamage >= 0.0 && ragedamage < 99999.0)
				{
					float rage = Client(client).GetCharge(0);
					float ragemin = Client(client).RageMin;
					if(rage >= ragemin)
					{
						SetHudTextParams(-1.0, 0.78, 0.35, 255, 64, 64, 255, _, _, 0.01, 0.5);
						Format(buffer, sizeof(buffer), "%s\n%t", buffer, "Boss Rage Ready", RoundToFloor(rage));
					}
					else
					{
						SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, _, _, 0.01, 0.5);
						Format(buffer, sizeof(buffer), "%s\n%t", buffer, "Boss Rage Charge", RoundToFloor(rage));
					}
					
					if(rage < ragemin || Client(client).RageMode == 2)
					{
						ShowSyncHudText(client, PlayerHud, buffer);
					}
					else
					{
						ShowSyncHudText(client, PlayerHud, "%s%t", buffer, "Boss Rage Medic");
					}
				}
				else if(buffer[1])
				{
					SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, _, _, 0.01, 0.5);
					ShowSyncHudText(client, PlayerHud, buffer);
				}
			}
		}
	}
}

void Bosses_UseSlot(int client, int low, int high)
{
	char buffer[12];
	for(int slot = low; slot<=high; slot++)
	{
		if(slot < 1 || slot > 3)
		{
			IntToString(slot, buffer, sizeof(buffer));
			
			if(!Bosses_PlaySoundToAll(client, "sound_ability_serverwide", buffer, _, _, _, _, 2.0) && CvarSoundType.BoolValue)
			{
				Bosses_PlaySoundToAll(client, "sound_ability", buffer, _, _, _, _, 2.0);
			}
			else
			{
				Bosses_PlaySoundToAll(client, "sound_ability", buffer, client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, 2.0);
			}
		}
	}
	
	StringMapSnapshot snap = Client(client).Cfg.Snapshot();
	if(!snap)
		return;
	
	int entries = snap.Length;
	if(entries)
	{
		PackVal val;
		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] ability = new char[length];
			snap.GetKey(i, ability, length);
			Client(client).Cfg.GetArray(ability, val, sizeof(val));
			if(val.tag != KeyValType_Section || GetSectionType(ability) != Section_Ability)
				continue;
			
			ConfigMap cfg = val.cfg;
			if(!cfg)
				continue;
			
			int slot;
			if(!cfg.GetInt("slot", slot))
				cfg.GetInt("arg0", slot);
			
			if(slot < low || slot > high)
				continue;
			
			int button;
			cfg.GetInt("buttonmode", button);
			
			if(cfg.GetVal("plugin_name", val) && val.tag == KeyValType_Value)
			{
				UseAbility(client, cfg, val.data, ability, slot, button);
			}
			else
			{
				UseAbility(client, cfg, "", ability, slot, button);
			}
		}
	}
	
	delete snap;
}

void Bosses_UseAbility(int client, const char[] plugin = "", const char[] ability, int slot, int buttonmode = 0)
{
	ConfigMap cfg = Client(client).Cfg.GetSection(ability);
	if(cfg)
	{
		char buffer[64];
		if(plugin[0] && cfg.Get("plugin_name", buffer, sizeof(buffer)) && !StrEqual(buffer, plugin))
			return;
		
		UseAbility(client, cfg, plugin, ability, slot, buttonmode);
	}
}

static void UseAbility(int client, ConfigMap cfg, const char[] plugin, const char[] ability, int slot, int buttonmode = 0)
{
	bool result = true;
	char buffer1[64];
	if(cfg.Get("life", buffer1, sizeof(buffer1)))
	{
		int life = Client(client).Lives;
		int current;
		char buffer2[12];
		do
		{
			int add = SplitString(buffer1[current], " ", buffer2, sizeof(buffer2));
			result = add != -1;
			if(result)
			{
				current += add;
			}
			else
			{
				strcopy(buffer2, sizeof(buffer2), buffer1[current]);
			}
			
			if(StringToInt(buffer2) == life)
			{
				result = true;
				break;
			}
		} while(result);
	}
	
	if(plugin[0])
	{
		FormatEx(buffer1, sizeof(buffer1), "%s.smx", plugin);
	}
	else
	{
		buffer1[0] = 0;
	}
	
	if(Forward_OnAbilityPre(client, ability, cfg, result))
	{
		if(!ForwardOld_PreAbility(client, buffer1, ability, slot))
			return;
	}
	
	if(!result)
		return;
	
	int status = 3;
	if(slot > 0 && slot < 4)
	{
		int button = IN_ATTACK2;
		switch(buttonmode)
		{
			case 1:
				button = IN_DUCK|IN_ATTACK2;

			case 2:
				button = IN_RELOAD;

			case 3:
				button = IN_ATTACK3;

			case 4:
				button = IN_DUCK;

			case 5:
				button = IN_SCORE;
		}
		
		float charge = Client(client).GetCharge(slot);
		
		if(GetClientButtons(client) & button)
		{
			if(charge >= 0.0)
			{
				status = 2;
				
				float time = 1.5;
				if(!cfg.GetFloat("charge time", time))
					cfg.GetFloat("arg1", time);
				
				if(time)
				{
					charge += 20.0/time;
					if(charge > 100.0)
						charge = 100.0;
				}
			}
			else
			{
				status = 1;
				charge += 0.2;
			}
		}
		else if(charge > 0.3)
		{
			float angles[3];
			GetClientEyeAngles(client, angles);
			if(angles[0] < -30.0)
			{
				status = 3;
				
				float cooldown = 5.0;
				if(!cfg.GetFloat("cooldown", cooldown))
					cfg.GetFloat("arg2", cooldown);
				
				DataPack data;
				CreateDataTimer(0.1, Bosses_UseBossCharge, data);
				data.WriteCell(client);
				data.WriteCell(slot);
				data.WriteFloat(cooldown * -1.0);
			}
			else
			{
				status = 0;
				charge = 0.0;
			}
		}
		else if(charge < 0.0)
		{
			status = 1;
			charge += 0.2;
		}
		else
		{
			status = 0;
		}
		
		Client(client).SetCharge(slot, charge);
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
	}
	
	Forward_OnAbility(client, ability, cfg, buffer1);
	ForwardOld_OnAbility(client, buffer1, ability, status);
	Forward_OnAbilityPost(client, ability, cfg);
}

public Action Bosses_UseBossCharge(Handle timer, DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	if(Client(client).IsBoss)
	{
		int slot = data.ReadCell();
		Client(client).SetCharge(slot, data.ReadFloat());
	}
	return Plugin_Continue;
}

int Bosses_GetArgInt(int client, const char[] ability, const char[] argument, int &value, int base = 10)
{
	ConfigMap cfg = Client(client).Cfg.GetSection(ability);
	if(!cfg)
		return 0;
	
	return cfg.GetInt(argument, value, base);
}

int Bosses_GetArgFloat(int client, const char[] ability, const char[] argument, float &value)
{
	ConfigMap cfg = Client(client).Cfg.GetSection(ability);
	if(!cfg)
		return 0;
	
	return cfg.GetFloat(argument, value);
}

int Bosses_GetArgBool(int client, const char[] ability, const char[] argument, bool &value)
{
	ConfigMap cfg = Client(client).Cfg.GetSection(ability);
	if(!cfg)
		return 0;
	
	return cfg.GetBool(argument, value, false);
}

int Bosses_GetArgString(int client, const char[] ability, const char[] argument, char[] value, int length)
{
	ConfigMap cfg = Client(client).Cfg.GetSection(ability);
	if(!cfg)
		return 0;
	
	return cfg.Get(argument, value, length);
}

int Bosses_GetRandomSound(int client, const char[] section, SoundEnum sound, const char[] required = "")
{
	return Bosses_GetRandomSoundCfg(Client(client).Cfg, section, sound, required);
}

int Bosses_GetRandomSoundCfg(ConfigMap full, const char[] section, SoundEnum sound, const char[] required = "")
{
	int size;
	
	ConfigMap cfg = full.GetSection(section);
	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
		if(snap)
		{
			PackVal val;
			int sounds;
			int entries = snap.Length;
			int[] list = new int[entries];
			char buffer[PLATFORM_MAX_PATH];
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] key = new char[length];
				snap.GetKey(i, key, length);
				cfg.GetArray(key, val, sizeof(val));
				switch(val.tag)
				{
					case KeyValType_Section:
					{
						if(required[0])
						{	
							if(!val.cfg.Get("key", key, length) || StrContains(required, key, false) != 0)
								continue;
						}
					}
					case KeyValType_Value:
					{
						if(!IsNotExtraArg(key))
						{
							continue;
						}
						else if(length > val.size)	// "example.mp3"	""
						{
							if(required[0])
							{
								strcopy(buffer, sizeof(buffer), val.data);
								
								if(!buffer[0])
									strcopy(buffer, sizeof(buffer), "0");
								
								if(StrContains(required, buffer, false) != 0)
									continue;
							}
						}
						else	// "1"	"example.mp3"
						{
							if(required[0])
							{
								FormatEx(buffer, sizeof(buffer), "slot%s", key);
								if(!cfg.Get(buffer, buffer, sizeof(buffer)))
								{
									FormatEx(buffer, sizeof(buffer), "vo%s", key);
									if(!cfg.Get(buffer, buffer, sizeof(buffer)))
										buffer[0] = 0;
								}
								
								if(!buffer[0])
									strcopy(buffer, sizeof(buffer), "0");
								
								if(StrContains(required, buffer, false) != 0)
									continue;
							}
						}
					}
					default:
					{
						continue;
					}
				}
				
				list[sounds++] = i;
			}

			if(sounds)
			{
				sounds = list[GetRandomInt(0, sounds - 1)];
				int length = snap.KeyBufferSize(sounds)+1;
				char[] key = new char[length];
				snap.GetKey(sounds, key, length);
				if(cfg.GetArray(key, val, sizeof(val)))
				{
					switch(val.tag)
					{
						case KeyValType_Section:
						{
							ConfigMap cfgsub = val.cfg;
							
							if(cfgsub.GetInt("mode", sound.Entity))
							{
								if(sound.Entity > SOUND_FROM_WORLD)
									sound.Entity = -sound.Entity;
								
								if(sound.Entity < SOUND_FROM_PLAYER)
									sound.Entity = SOUND_FROM_PLAYER;
							}
							
							if(StrContains(key, SndExts[0]) == -1 && StrContains(key, SndExts[1]) == -1)
							{
								if(GetGameSoundParams(key, sound.Channel, sound.Level, sound.Volume, sound.Pitch, sound.Sound, sizeof(sound.Sound), sound.Entity == SOUND_FROM_LOCAL_PLAYER ? SOUND_FROM_PLAYER : sound.Entity))
									size = strlen(sound.Sound);
							}
							else
							{
								size = strcopy(sound.Sound, sizeof(sound.Sound), key);
							}
							
							cfgsub.GetInt("channel", sound.Channel);
							cfgsub.GetInt("level", sound.Level);
							cfgsub.GetInt("flags", sound.Flags);
							cfgsub.GetFloat("volume", sound.Volume);
							cfgsub.GetInt("pitch", sound.Pitch);
							
							if(cfgsub.GetFloat("time", sound.Time))
							{
								cfgsub.Get("name", sound.Name, sizeof(sound.Name));
								cfgsub.Get("artist", sound.Artist, sizeof(sound.Artist));
							}
							
							if(cfgsub.Get("overlay", sound.Overlay, sizeof(sound.Overlay)))
								cfgsub.GetFloat("duration", sound.Duration);
						}
						case KeyValType_Value:
						{
							if(length > val.size)	// "example.mp3"	""
							{
								if(StrContains(key, SndExts[0]) == -1 && StrContains(key, SndExts[1]) == -1)
								{
									if(GetGameSoundParams(key, sound.Channel, sound.Level, sound.Volume, sound.Pitch, sound.Sound, sizeof(sound.Sound), sound.Entity == SOUND_FROM_LOCAL_PLAYER ? SOUND_FROM_PLAYER : sound.Entity))
										size = strlen(sound.Sound);
								}
								else
								{
									size = strcopy(sound.Sound, sizeof(sound.Sound), key);
								}
							}
							else	// "1"	"example.mp3"
							{
								ReplaceStringEx(key, length, "path", "");
								
								Format(sound.Sound, sizeof(sound.Sound), "%s_overlay", key);
								if(cfg.Get(sound.Sound, sound.Overlay, sizeof(sound.Overlay)))
								{
									Format(sound.Sound, sizeof(sound.Sound), "%s_overlay_time", key);
									cfg.GetFloat(sound.Sound, sound.Duration);
								}
								
								Format(sound.Sound, sizeof(sound.Sound), "time%s", key);
								if(cfg.GetFloat(sound.Sound, sound.Time))
								{
									Format(sound.Sound, sizeof(sound.Sound), "name%s", key);
									cfg.Get(sound.Sound, sound.Name, sizeof(sound.Name));
									
									Format(sound.Sound, sizeof(sound.Sound), "artist%s", key);
									cfg.Get(sound.Sound, sound.Artist, sizeof(sound.Artist));
								}
								else
								{
									Format(sound.Sound, sizeof(sound.Sound), "%smusic", key);
									if(cfg.GetFloat(sound.Sound, sound.Time))
									{
										Format(sound.Sound, sizeof(sound.Sound), "%sname", key);
										cfg.Get(sound.Sound, sound.Name, sizeof(sound.Name));
										
										Format(sound.Sound, sizeof(sound.Sound), "%sartist", key);
										cfg.Get(sound.Sound, sound.Artist, sizeof(sound.Artist));
									}
								}
								
								size = strcopy(sound.Sound, sizeof(sound.Sound), val.data);
								
								if(StrContains(sound.Sound, SndExts[0]) == -1 && StrContains(sound.Sound, SndExts[1]) == -1)
								{
									if(GetGameSoundParams(sound.Sound, sound.Channel, sound.Level, sound.Volume, sound.Pitch, sound.Sound, sizeof(sound.Sound), sound.Entity == SOUND_FROM_LOCAL_PLAYER ? SOUND_FROM_PLAYER : sound.Entity))
										size = strlen(sound.Sound);
								}
							}
						}
					}
				}
			}
			
			delete snap;
		}
	}
	
	if(!size)
		sound.Sound[0] = 0;
	
	return size;
}

int Bosses_GetSpecificSoundCfg(ConfigMap full, const char[] section, char[] key, int length, SoundEnum sound)
{
	int size;
	
	ConfigMap cfg = full.GetSection(section);
	if(cfg)
	{
		PackVal val;
		cfg.GetArray(key, val, sizeof(val));
		switch(val.tag)
		{
			case KeyValType_Section:
			{
				ConfigMap cfgsub = val.cfg;
				
				if(cfgsub.GetInt("mode", sound.Entity))
				{
					if(sound.Entity > SOUND_FROM_WORLD)
						sound.Entity = -sound.Entity;
					
					if(sound.Entity < SOUND_FROM_PLAYER)
						sound.Entity = SOUND_FROM_PLAYER;
				}
				
				if(StrContains(key, SndExts[0]) == -1 && StrContains(key, SndExts[1]) == -1)
				{
					if(GetGameSoundParams(key, sound.Channel, sound.Level, sound.Volume, sound.Pitch, sound.Sound, sizeof(sound.Sound), sound.Entity == SOUND_FROM_LOCAL_PLAYER ? SOUND_FROM_PLAYER : sound.Entity))
						size = strlen(sound.Sound);
				}
				else
				{
					size = strcopy(sound.Sound, sizeof(sound.Sound), key);
				}
				
				cfgsub.GetInt("channel", sound.Channel);
				cfgsub.GetInt("level", sound.Level);
				cfgsub.GetInt("flags", sound.Flags);
				cfgsub.GetFloat("volume", sound.Volume);
				cfgsub.GetInt("pitch", sound.Pitch);
				
				if(cfgsub.GetFloat("time", sound.Time))
				{
					cfgsub.Get("name", sound.Name, sizeof(sound.Name));
					cfgsub.Get("artist", sound.Artist, sizeof(sound.Artist));
				}
				
				if(cfgsub.Get("overlay", sound.Overlay, sizeof(sound.Overlay)))
					cfgsub.GetFloat("duration", sound.Duration);
			}
			case KeyValType_Value:
			{
				if(strlen(key) > val.size)	// "example.mp3"	""
				{
					if(StrContains(key, SndExts[0]) == -1 && StrContains(key, SndExts[1]) == -1)
					{
						if(GetGameSoundParams(key, sound.Channel, sound.Level, sound.Volume, sound.Pitch, sound.Sound, sizeof(sound.Sound), sound.Entity == SOUND_FROM_LOCAL_PLAYER ? SOUND_FROM_PLAYER : sound.Entity))
							size = strlen(sound.Sound);
					}
					else
					{
						size = strcopy(sound.Sound, sizeof(sound.Sound), key);
					}
				}
				else	// "1"	"example.mp3"
				{
					ReplaceStringEx(key, length, "path", "");
					
					Format(sound.Sound, sizeof(sound.Sound), "%s_overlay", key);
					if(cfg.Get(sound.Sound, sound.Overlay, sizeof(sound.Overlay)))
					{
						Format(sound.Sound, sizeof(sound.Sound), "%s_overlay_time", key);
						cfg.GetFloat(sound.Sound, sound.Duration);
					}
					
					Format(sound.Sound, sizeof(sound.Sound), "time%s", key);
					if(cfg.GetFloat(sound.Sound, sound.Time))
					{
						Format(sound.Sound, sizeof(sound.Sound), "name%s", key);
						cfg.Get(sound.Sound, sound.Name, sizeof(sound.Name));
						
						Format(sound.Sound, sizeof(sound.Sound), "artist%s", key);
						cfg.Get(sound.Sound, sound.Artist, sizeof(sound.Artist));
					}
					else
					{
						Format(sound.Sound, sizeof(sound.Sound), "%smusic", key);
						if(cfg.GetFloat(sound.Sound, sound.Time))
						{
							Format(sound.Sound, sizeof(sound.Sound), "%sname", key);
							cfg.Get(sound.Sound, sound.Name, sizeof(sound.Name));
							
							Format(sound.Sound, sizeof(sound.Sound), "%sartist", key);
							cfg.Get(sound.Sound, sound.Artist, sizeof(sound.Artist));
						}
					}
					
					size = strcopy(sound.Sound, sizeof(sound.Sound), val.data);
					
					if(StrContains(sound.Sound, SndExts[0]) == -1 && StrContains(sound.Sound, SndExts[1]) == -1)
					{
						if(GetGameSoundParams(sound.Sound, sound.Channel, sound.Level, sound.Volume, sound.Pitch, sound.Sound, sizeof(sound.Sound), sound.Entity == SOUND_FROM_LOCAL_PLAYER ? SOUND_FROM_PLAYER : sound.Entity))
							size = strlen(sound.Sound);
					}
				}
			}
		}
	}
	
	if(!size)
		sound.Sound[0] = 0;
	
	return size;
}

bool Bosses_PlaySound(int boss, const int[] clients, int numClients, const char[] key, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
{
	SoundEnum sound;
	sound.Entity = entity;
	sound.Channel = channel;
	sound.Level = level;
	sound.Flags = flags;
	sound.Volume = volume;
	sound.Pitch = pitch;
	
	if(!Bosses_GetRandomSound(boss, key, sound, required))
		return false;
	
	if(sound.Time > 0)
	{
		Music_PlaySong(clients, numClients, sound.Sound, GetClientUserId(boss), sound.Name, sound.Artist, sound.Time, sound.Volume, sound.Pitch);
	}
	else
	{
		int[] clients2 = new int[numClients];
		int amount;
		
		for(int i; i < numClients; i++)
		{
			if(!Client(clients[i]).NoVoice)
				clients2[amount++] = clients[i];
		}
		
		if(amount)
		{
			if(sound.Entity == SOUND_FROM_LOCAL_PLAYER)
				sound.Entity = boss;
			
			int count = RoundToCeil(sound.Volume);
			if(count > 1)
				sound.Volume /= float(count);
			
			Client(boss).Speaking = true;
			for(int i; i < count; i++)
			{
				EmitSound(clients2, amount, sound.Sound, sound.Entity, sound.Channel, sound.Level, sound.Flags, sound.Volume, sound.Pitch, speakerentity, origin, dir, updatePos, soundtime);
			}
			Client(boss).Speaking = false;
		}
	}
	
	if(sound.Overlay[0])
	{
		sound.Duration += GetEngineTime();
		
		int cflags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", cflags & ~FCVAR_CHEAT);
		
		for(int i; i < numClients; i++)
		{
			if(clients[i] != boss)
			{
				Client(clients[i]).OverlayFor = sound.Duration;
				ClientCommand(clients[i], "r_screenoverlay \"%s\"", sound.Overlay);
			}
		}
		
		SetCommandFlags("r_screenoverlay", cflags);
	}
	return true;
}

bool Bosses_PlaySoundToClient(int boss, int client, const char[] key, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
{
	int clients[1];
	clients[0] = client;
	return Bosses_PlaySound(boss, clients, 1, key, required, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

bool Bosses_PlaySoundToAll(int boss, const char[] key, const char[] required = "", int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			clients[total++] = client;
	}
	
	return Bosses_PlaySound(boss, clients, total, key, required, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

static void EnableSubplugins()
{
	if(!PluginsEnabled)
	{
		PluginsEnabled = true;
		
		char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filepath1[PLATFORM_MAX_PATH], filepath2[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), "plugins/freaks");
		
		FileType filetype;
		DirectoryListing dir = OpenDirectory(path);
		if(dir)
		{
			while(dir.GetNext(filename, sizeof(filename), filetype))
			{
				if(filetype == FileType_File)
				{
					int pos = strlen(filename) - 4;
					if(pos > 0)
					{
						if(StrEqual(filename[pos], ".smx"))
						{
							FormatEx(filepath1, sizeof(filepath1), "%s/%s", path, filename);
							
							DataPack pack = new DataPack();
							pack.WriteString(filepath1);
							RequestFrame(Bosses_RenameSubplugin, pack);
						}
						else if(StrEqual(filename[pos], ".ff2"))
						{
							FormatEx(filepath1, sizeof(filepath1), "%s/%s", path, filename);
							
							strcopy(filename[pos], 5, ".smx");
							FormatEx(filepath2, sizeof(filepath2), "%s/%s", path, filename);
							
							if(FileExists(filepath2))
							{
								DeleteFile(filepath1);
							}
							else
							{
								RenameFile(filepath2, filepath1);
								InsertServerCommand("sm plugins load freaks/%s", filename);
							}
							
							DataPack pack = new DataPack();
							pack.WriteString(filepath2);
							RequestFrame(Bosses_RenameSubplugin, pack);
						}
					}
				}
			}
			
			ServerExecute();
		}
	}
}

public void Bosses_RenameSubplugin(DataPack pack)
{
	pack.Reset();
	
	char buffer1[PLATFORM_MAX_PATH], buffer2[PLATFORM_MAX_PATH];
	pack.ReadString(buffer1, sizeof(buffer1));
	
	delete pack;
	
	int pos = strcopy(buffer2, sizeof(buffer2), buffer1) - 4;
	strcopy(buffer2[pos], 5, ".ff2");
	
	RenameFile(buffer2, buffer1);
}

static void DisableSubplugins()
{
	if(PluginsEnabled)
	{
		PluginsEnabled = false;
		
		//TODO: Reverse
		ArrayList list = new ArrayList(PLATFORM_MAX_PATH);
		
		char filename[PLATFORM_MAX_PATH];
		Handle iter = GetPluginIterator();
		while(MorePlugins(iter))
		{
			Handle plugin = ReadPlugin(iter);
			GetPluginFilename(plugin, filename, sizeof(filename));
			if(!StrContains(filename, "freaks\\", false))
				list.PushString(filename);
		}
		delete iter;
		
		for(int i = list.Length-1; i >= 0; i--)
		{
			list.GetString(i, filename, sizeof(filename));
			InsertServerCommand("sm plugins unload %s", filename);
		}
		
		delete list;
		ServerExecute();
	}
}

static bool IsNotExtraArg(const char[] key)
{
	if(StrContains(key, "time") == 0 || StrContains(key, "name") != -1 || StrContains(key, "artist") != -1 || StrContains(key, "vo") == 0 || StrContains(key, "slot") == 0)
	{
		if(StrContains(key, "/") == -1 && StrContains(key, "\\") == -1 && StrContains(key, ".") == -1)
			return false;
	}
	return true;
}
